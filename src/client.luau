--!strict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const RunService = game:GetService("RunService")

const Configuration = require("./configuration")
const Cursor = require("./cursor")
const Registry = require("./registry")
const Schema = require("./schema")
const ThreadPool = require("./thread_pool")
const Wire = require("./wire")

type Definition = Registry.Definition
type Arguments = Schema.Arguments

type PendingCall = {
	Thread: thread,
	Deadline: number,
	Definition: Definition,
}

type Held = {
	Source: buffer,
	Instances: { any },
	Offset: number,
	InstancesOffset: number,
	MissingId: number,
	ReceivedAt: number,
}

const Client = {}

const Reliable = Cursor.New()
const Unreliable: { Cursor.Cursor } = { Cursor.New(Configuration.UnreliableByteLimit) }
const PendingCalls: { [number]: PendingCall } = {}
const Definitions: { [string]: Definition } = {}
const Queued: { [Definition]: { Cursor.Cursor } } = {}
const Waiting: { [Definition]: { thread } } = {}
const HeldBatches: { Held } = {}
const Scratch = Cursor.New()
const Incoming = Wire.NewBatch()
const NoInstances: { any } = {}
const ResponseFlag = Wire.ResponseFlag
const EventIndex = Wire.EventIndex

local ReliableRemote: RemoteEvent? = nil
local UnreliableRemote: UnreliableRemoteEvent? = nil
local UnreliableCount = 1
local NextCallIndex = 0
local Elapsed = 0
local RetryScheduled = false

const function Deliver(Definition: Definition, Id: number, Body: Cursor.Cursor)
	if Definition.Reliable then
		Wire.Deliver(Reliable, Id, nil, nil, Body)

		return
	end

	const Size = Wire.Size(Id, nil, Body)

	if Size > Configuration.UnreliableByteLimit then
		error(
			`[swiftpacket] {Definition.Name} is {Size} bytes, over the unreliable limit of {Configuration.UnreliableByteLimit}`,
			0
		)
	end

	local Segment = Unreliable[UnreliableCount]

	if Segment.Offset > 0 and Segment.Offset + Size > Configuration.UnreliableByteLimit then
		UnreliableCount += 1

		const Next = Unreliable[UnreliableCount]

		if Next then
			Segment = Next
		else
			Segment = Cursor.New(Configuration.UnreliableByteLimit)
			Unreliable[UnreliableCount] = Segment
		end
	end

	Wire.Deliver(Segment, Id, nil, nil, Body)
end

function Client.Send(Definition: Definition, ...: any)
	const Id = Definition.Id

	if Id == nil then
		const Body = Cursor.New()
		Schema.WriteBody(Body, Definition.Name, Definition.Arguments, ...)

		const Bodies = Queued[Definition] or {}
		table.insert(Bodies, Body)
		Queued[Definition] = Bodies

		return
	end

	if Definition.Reliable then
		Schema.WriteEvent(Reliable, Id, Definition.Name, Definition.Arguments, ...)

		return
	end

	Schema.WriteBody(Scratch, Definition.Name, Definition.Arguments, ...)
	Deliver(Definition, Id, Scratch)
end

const function FindCallIndex(): number
	local CallIndex = NextCallIndex

	for Attempt = 1, Configuration.CallCapacity do
		if PendingCalls[CallIndex] == nil then
			return CallIndex
		end

		CallIndex = (CallIndex + 1) % Configuration.CallCapacity
	end

	error("[swiftpacket] too many calls are waiting on a response", 0)
end

function Client.Invoke(Definition: Definition, ...: any): ...any
	local CallIndex = 0

	if Definition.Id == nil then
		const Body = Cursor.New()
		Schema.WriteBody(Body, Definition.Name, Definition.Arguments, ...)

		const Threads = Waiting[Definition] or {}
		table.insert(Threads, coroutine.running())
		Waiting[Definition] = Threads

		coroutine.yield()

		const Id = Definition.Id

		if Id == nil then
			error(`[swiftpacket] {Definition.Name} has no id`, 0)
		end

		CallIndex = FindCallIndex()
		Wire.Deliver(Reliable, Id, CallIndex, nil, Body)
	else
		CallIndex = FindCallIndex()
		Schema.WriteRequest(Reliable, Definition.Id, CallIndex, Definition.Name, Definition.Arguments, ...)
	end

	NextCallIndex = (CallIndex + 1) % Configuration.CallCapacity
	PendingCalls[CallIndex] = {
		Thread = coroutine.running(),
		Deadline = os.clock() + Definition.TimeoutSeconds,
		Definition = Definition,
	}

	return coroutine.yield()
end

const function Respond(Definition: Definition, CallIndex: number, ...: any)
	const Handler = Definition.OnClientInvoke
	local Results: Arguments = { n = 0 }

	if Handler then
		Results = table.pack(pcall(Handler, ...))
	else
		Results = { n = 2, false, "no OnClientInvoke was set" }
	end

	const Id = Definition.Id

	if Id == nil then
		return
	end

	const Ok, Problem = Wire.EncodeResults(Scratch, Definition, Results)

	if not Ok then
		warn(`[swiftpacket] call from the server failed: {Problem}`)
	end

	Wire.DeliverResponse(Reliable, Id, CallIndex, if Ok then Scratch else nil)
end

const function Resolve(Definition: Definition, CallIndex: number, Success: boolean, ...: any)
	const Call = PendingCalls[CallIndex]

	if Call == nil or Call.Definition ~= Definition then
		Configuration.Warn(`[swiftpacket] ignored an unexpected response to {Definition.Name}`)

		return
	end

	PendingCalls[CallIndex] = nil

	if Success then
		task.defer(Call.Thread, ...)
	else
		task.defer(Call.Thread, Wire.Unpack(Definition.TimeoutValues))
	end
end

const function Dispatch()
	const Values = Incoming.Values

	for Index = 1, Incoming.Count do
		const Definition = Incoming.Definitions[Index]
		const CallIndex = Incoming.CallIndices[Index]
		const First = Incoming.Starts[Index]
		const Last = First + Incoming.Counts[Index] - 1

		if CallIndex >= ResponseFlag then
			Resolve(Definition, CallIndex - ResponseFlag, Incoming.Successes[Index], table.unpack(Values, First, Last))
		elseif CallIndex ~= EventIndex then
			ThreadPool.Defer(Respond, Definition, CallIndex, table.unpack(Values, First, Last))
		elseif First == Last then
			Definition.OnClientEvent:Fire(Values[First])
		else
			Definition.OnClientEvent:Fire(table.unpack(Values, First, Last))
		end
	end
end

const function Process(Source: buffer, Attached: { any }, Offset: number, StartInstances: number): number?
	const Ok, Result = pcall(Wire.Decode, Incoming, Source, Attached, false, Offset, StartInstances)

	if not Ok then
		Wire.Release(Incoming)
		warn(`[swiftpacket] could not read a batch from the server: {tostring(Result)}`)

		return nil
	end

	Dispatch()
	Wire.Release(Incoming)

	return Result
end

const function Retry()
	RetryScheduled = false

	local Index = 1

	while Index <= #HeldBatches do
		const Entry = HeldBatches[Index]

		if Registry.ById[Entry.MissingId] == nil then
			Index += 1

			continue
		end

		const MissingId = Process(Entry.Source, Entry.Instances, Entry.Offset, Entry.InstancesOffset)

		if MissingId then
			Entry.Offset = Incoming.StopOffset
			Entry.InstancesOffset = Incoming.StopInstances
			Entry.MissingId = MissingId
			Index += 1
		else
			table.remove(HeldBatches, Index)
		end
	end
end

const function ScheduleRetry()
	if RetryScheduled or HeldBatches[1] == nil then
		return
	end

	RetryScheduled = true
	task.defer(Retry)
end

const function Assign(Definition: Definition, Id: number)
	const Previous = Definition.Id

	if Previous and Registry.ById[Previous] == Definition then
		Registry.ById[Previous] = nil
	end

	Definition.Id = Id
	Registry.ById[Id] = Definition

	const Bodies = Queued[Definition]
	Queued[Definition] = nil

	if Bodies then
		for Index, Body in Bodies do
			Deliver(Definition, Id, Body)
		end
	end

	const Threads = Waiting[Definition]
	Waiting[Definition] = nil

	if Threads then
		for Index, Thread in Threads do
			task.spawn(Thread)
		end
	end

	ScheduleRetry()
end

function Client.Register(Definition: Definition)
	const Remote = ReliableRemote

	if Remote == nil then
		error("[swiftpacket] the client transport has not started", 0)
	end

	Definitions[Definition.Name] = Definition

	const Id = Remote:GetAttribute(Definition.Name)

	if type(Id) == "number" then
		Assign(Definition, Id)

		return
	end

	task.delay(5, function()
		if Definition.Id == nil then
			warn(`[swiftpacket] {Definition.Name} has no id after 5 seconds, define it on the server too`)
		end
	end)
end

const function Receive(Source: any, Instances: any)
	if typeof(Source) ~= "buffer" then
		return
	end

	const Attached = if type(Instances) == "table" then Instances else NoInstances
	const MissingId = Process(Source, Attached, 0, 0)

	if MissingId then
		table.insert(HeldBatches, {
			Source = Source,
			Instances = Attached,
			Offset = Incoming.StopOffset,
			InstancesOffset = Incoming.StopInstances,
			MissingId = MissingId,
			ReceivedAt = os.clock(),
		})
	end
end

const function FireSegment(Remote: RemoteEvent | UnreliableRemoteEvent, Segment: Cursor.Cursor)
	if Segment.Offset == 0 then
		return
	end

	const Data, Attached = Cursor.Take(Segment)
	Cursor.Reset(Segment)

	if Remote:IsA("RemoteEvent") then
		if Attached then
			Remote:FireServer(Data, Attached)
		else
			Remote:FireServer(Data)
		end
	elseif Remote:IsA("UnreliableRemoteEvent") then
		if Attached then
			Remote:FireServer(Data, Attached)
		else
			Remote:FireServer(Data)
		end
	end
end

const function Flush()
	const ReliableTarget = ReliableRemote
	const UnreliableTarget = UnreliableRemote

	if ReliableTarget == nil or UnreliableTarget == nil then
		return
	end

	FireSegment(ReliableTarget, Reliable)

	for Index = 1, UnreliableCount do
		FireSegment(UnreliableTarget, Unreliable[Index])
	end

	UnreliableCount = 1
end

const function Expire()
	const Now = os.clock()

	for CallIndex, Call in PendingCalls do
		if Now >= Call.Deadline then
			PendingCalls[CallIndex] = nil
			task.defer(Call.Thread, Wire.Unpack(Call.Definition.TimeoutValues))
		end
	end

	for Index = #HeldBatches, 1, -1 do
		const Entry = HeldBatches[Index]

		if Now - Entry.ReceivedAt >= Configuration.HoldSeconds then
			table.remove(HeldBatches, Index)
			warn(
				`[swiftpacket] dropped messages after the unknown packet id {Entry.MissingId}, define it on the client too`
			)
		end
	end
end

const function FindRemote(Root: Instance, Name: string): Instance
	const Remote = Root:WaitForChild(Name, 10)

	if Remote == nil then
		error(`[swiftpacket] could not find {Root:GetFullName()}.{Name}, require swiftpacket on the server first`, 0)
	end

	return Remote
end

function Client.Start(Root: Instance)
	if ReliableRemote then
		return
	end

	const ReliableInstance = FindRemote(Root, "Reliable")
	const UnreliableInstance = FindRemote(Root, "Unreliable")

	if not ReliableInstance:IsA("RemoteEvent") or not UnreliableInstance:IsA("UnreliableRemoteEvent") then
		error(`[swiftpacket] the remotes under {Root:GetFullName()} have the wrong classes`, 0)
	end

	ReliableRemote = ReliableInstance
	UnreliableRemote = UnreliableInstance

	ReliableInstance.OnClientEvent:Connect(Receive)
	UnreliableInstance.OnClientEvent:Connect(Receive)

	ReliableInstance.AttributeChanged:Connect(function(Name: string)
		const Definition = Definitions[Name]
		const Id = ReliableInstance:GetAttribute(Name)

		if Definition and type(Id) == "number" then
			Assign(Definition, Id)
		end
	end)

	RunService.Heartbeat:Connect(function(DeltaTime: number)
		Expire()
		Elapsed += DeltaTime

		if Elapsed >= Configuration.FlushRate then
			Elapsed %= Configuration.FlushRate
			task.defer(Flush)
		end
	end)
end

return Client
