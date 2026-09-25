--!strict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const Configuration = require("./configuration")
const Cursor = require("./cursor")
const RateLimit = require("./rate_limit")
const Registry = require("./registry")
const Schema = require("./schema")
const ThreadPool = require("./thread_pool")
const Wire = require("./wire")

type Definition = Registry.Definition
type Arguments = Schema.Arguments

type Channel = {
	Reliable: Cursor.Cursor,
	Unreliable: { Cursor.Cursor },
	UnreliableCount: number,
	Tracked: boolean,
	Marks: { number },
	MarkCount: number,
	SharedFrom: number,
	SharedInstancesFrom: number,
	LastShared: number,
	LastSharedInstances: number,
}

type PendingCall = {
	Thread: thread,
	Deadline: number,
	Definition: Definition,
}

type Budget = {
	Tokens: number,
	UpdatedAt: number,
}

type Window = {
	Count: number,
	EndsAt: number,
}

const Server = {}

const Channels: { [Player]: Channel } = {}
const PendingCalls: { [Player]: { [number]: PendingCall } } = {}
const NextCallIndex: { [Player]: number } = {}
const Budgets: { [Player]: Budget } = {}
const Windows: { [Definition]: { [Player]: Window } } = {}
const Everyone: { Player } = {}
const Scratch = Cursor.New()
const Shared = Cursor.New()
const Received = Wire.NewBatch()
const NoInstances: { any } = {}
const NoBytes = buffer.create(0)
const ResponseFlag = Wire.ResponseFlag
const EventIndex = Wire.EventIndex

local ReliableRemote: RemoteEvent? = nil
local UnreliableRemote: UnreliableRemoteEvent? = nil
local NextId = 1

const function GetChannel(Player: Player): Channel
	const Existing = Channels[Player]

	if Existing then
		return Existing
	end

	const Created: Channel = {
		Reliable = Cursor.New(),
		Unreliable = { Cursor.New(Configuration.UnreliableByteLimit) },
		UnreliableCount = 1,
		Tracked = false,
		Marks = {},
		MarkCount = 0,
		SharedFrom = Shared.Offset,
		SharedInstancesFrom = Shared.InstancesOffset,
		LastShared = Shared.Offset,
		LastSharedInstances = Shared.InstancesOffset,
	}

	Channels[Player] = Created

	return Created
end

const function Own(Channel: Channel): Cursor.Cursor
	if
		Channel.Tracked
		and (Shared.Offset ~= Channel.LastShared or Shared.InstancesOffset ~= Channel.LastSharedInstances)
	then
		const Marks = Channel.Marks
		const At = Channel.MarkCount * 4
		const Reliable = Channel.Reliable

		Marks[At + 1] = Shared.Offset
		Marks[At + 2] = Shared.InstancesOffset
		Marks[At + 3] = Reliable.Offset
		Marks[At + 4] = Reliable.InstancesOffset

		Channel.MarkCount += 1
		Channel.LastShared = Shared.Offset
		Channel.LastSharedInstances = Shared.InstancesOffset
	end

	return Channel.Reliable
end

const function GetId(Definition: Definition): number
	const Id = Definition.Id

	if Id == nil then
		error(`[swiftpacket] {Definition.Name} was never registered`, 0)
	end

	return Id
end

const function CheckUnreliable(Definition: Definition, Id: number)
	const Size = Wire.Size(Id, nil, Scratch)

	if Size > Configuration.UnreliableByteLimit then
		error(
			`[swiftpacket] {Definition.Name} is {Size} bytes, over the unreliable limit of {Configuration.UnreliableByteLimit}`,
			0
		)
	end
end

const function DeliverUnreliable(Channel: Channel, Id: number)
	const Size = Wire.Size(Id, nil, Scratch)
	local Segment = Channel.Unreliable[Channel.UnreliableCount]

	if Segment.Offset > 0 and Segment.Offset + Size > Configuration.UnreliableByteLimit then
		Channel.UnreliableCount += 1

		const Next = Channel.Unreliable[Channel.UnreliableCount]

		if Next then
			Segment = Next
		else
			Segment = Cursor.New(Configuration.UnreliableByteLimit)
			Channel.Unreliable[Channel.UnreliableCount] = Segment
		end
	end

	Wire.Deliver(Segment, Id, nil, nil, Scratch)
end

function Server.Register(Definition: Definition)
	const Remote = ReliableRemote

	if Remote == nil then
		error("[swiftpacket] the server transport has not started", 0)
	end

	const Id = NextId
	NextId += 1

	Definition.Id = Id
	Registry.ById[Id] = Definition
	Remote:SetAttribute(Definition.Name, Id)
end

function Server.SendTo(Player: Player, Definition: Definition, ...: any)
	const Id = GetId(Definition)

	if Player.Parent == nil then
		return
	end

	if Definition.Reliable then
		Schema.WriteEvent(Own(GetChannel(Player)), Id, Definition.Name, Definition.Arguments, ...)

		return
	end

	Schema.WriteBody(Scratch, Definition.Name, Definition.Arguments, ...)
	CheckUnreliable(Definition, Id)
	DeliverUnreliable(GetChannel(Player), Id)
end

function Server.SendMany(Recipients: { Player }, Excluded: Player?, Definition: Definition, ...: any)
	const Id = GetId(Definition)

	Schema.WriteBody(Scratch, Definition.Name, Definition.Arguments, ...)

	if not Definition.Reliable then
		CheckUnreliable(Definition, Id)
	end

	for Index = 1, #Recipients do
		const Player = Recipients[Index]

		if Player == Excluded or Player.Parent == nil then
			continue
		end

		const Channel = GetChannel(Player)

		if Definition.Reliable then
			Wire.Deliver(Own(Channel), Id, nil, nil, Scratch)
		else
			DeliverUnreliable(Channel, Id)
		end
	end
end

function Server.Broadcast(Definition: Definition, Excluded: Player?, ...: any)
	if Excluded == nil and Definition.Reliable then
		Schema.WriteEvent(Shared, GetId(Definition), Definition.Name, Definition.Arguments, ...)

		return
	end

	Server.SendMany(Everyone, Excluded, Definition, ...)
end

function Server.Invoke(Player: Player, Definition: Definition, ...: any): ...any
	const Id = GetId(Definition)

	if Player.Parent == nil then
		return Wire.Unpack(Definition.TimeoutValues)
	end

	const Calls = PendingCalls[Player] or {}
	PendingCalls[Player] = Calls

	local CallIndex = NextCallIndex[Player] or 0
	local Found = false

	for Attempt = 1, Configuration.CallCapacity do
		if Calls[CallIndex] == nil then
			Found = true
			break
		end

		CallIndex = (CallIndex + 1) % Configuration.CallCapacity
	end

	if not Found then
		error(`[swiftpacket] {Player.Name} has too many calls waiting on a response`, 0)
	end

	Schema.WriteRequest(Own(GetChannel(Player)), Id, CallIndex, Definition.Name, Definition.Arguments, ...)

	NextCallIndex[Player] = (CallIndex + 1) % Configuration.CallCapacity
	Calls[CallIndex] = {
		Thread = coroutine.running(),
		Deadline = os.clock() + Definition.TimeoutSeconds,
		Definition = Definition,
	}

	return coroutine.yield()
end

const function Respond(Player: Player, Definition: Definition, CallIndex: number, ...: any)
	const Handler = Definition.OnServerInvoke
	local Results: Arguments = { n = 0 }

	if Handler then
		Results = table.pack(pcall(Handler, Player, ...))
	else
		Results = { n = 2, false, "no OnServerInvoke was set" }
	end

	if Player.Parent == nil then
		return
	end

	const Ok, Problem = Wire.EncodeResults(Scratch, Definition, Results)

	if not Ok then
		warn(`[swiftpacket] call from {Player.Name} failed: {Problem}`)
	end

	Wire.DeliverResponse(Own(GetChannel(Player)), GetId(Definition), CallIndex, if Ok then Scratch else nil)
end

const function Admit(Player: Player, Definition: Definition, ...: any): boolean
	const Limit = Definition.RateLimitCount
	const Interval = Definition.RateLimitInterval

	if Limit and Interval then
		const PerPlayer = Windows[Definition] or {}
		Windows[Definition] = PerPlayer

		const Current = PerPlayer[Player] or { Count = 0, EndsAt = 0 }
		const Allowed, Count, EndsAt = RateLimit.Window(Current.Count, Current.EndsAt, os.clock(), Limit, Interval)

		Current.Count = Count
		Current.EndsAt = EndsAt
		PerPlayer[Player] = Current

		if not Allowed then
			Configuration.Warn(`[swiftpacket] {Player.Name} hit the rate limit on {Definition.Name}`)

			return false
		end
	end

	const Validator = Definition.Validator

	if Validator then
		const Ok, Valid = pcall(Validator, Player, ...)

		if not Ok or Valid ~= true then
			Configuration.Warn(`[swiftpacket] validation rejected {Definition.Name} from {Player.Name}`)

			return false
		end
	end

	return true
end

const function Resolve(Player: Player, Definition: Definition, CallIndex: number, Success: boolean, ...: any)
	const Calls = PendingCalls[Player]
	const Call = if Calls then Calls[CallIndex] else nil

	if Calls == nil or Call == nil or Call.Definition ~= Definition then
		Configuration.Warn(`[swiftpacket] ignored an unexpected response to {Definition.Name} from {Player.Name}`)

		return
	end

	Calls[CallIndex] = nil

	if Success then
		task.defer(Call.Thread, ...)
	else
		task.defer(Call.Thread, Wire.Unpack(Definition.TimeoutValues))
	end
end

const function Charge(Player: Player, Cost: number): boolean
	const Now = os.clock()
	const Rate = Configuration.IncomingBytesPerSecond
	const Current = Budgets[Player] or { Tokens = Rate, UpdatedAt = Now }
	const Tokens = RateLimit.Refill(Current.Tokens, Now - Current.UpdatedAt, Rate, Rate)

	Current.UpdatedAt = Now
	Budgets[Player] = Current

	if Tokens < Cost then
		Current.Tokens = Tokens

		return false
	end

	Current.Tokens = Tokens - Cost

	return true
end

const function Dispatch(Player: Player)
	const Values = Received.Values

	for Index = 1, Received.Count do
		const Definition = Received.Definitions[Index]
		const CallIndex = Received.CallIndices[Index]
		const First = Received.Starts[Index]
		const Last = First + Received.Counts[Index] - 1

		if CallIndex >= ResponseFlag then
			Resolve(
				Player,
				Definition,
				CallIndex - ResponseFlag,
				Received.Successes[Index],
				table.unpack(Values, First, Last)
			)

			continue
		end

		if
			(Definition.RateLimitCount or Definition.Validator)
			and not Admit(Player, Definition, table.unpack(Values, First, Last))
		then
			if CallIndex ~= EventIndex then
				Wire.DeliverResponse(Own(GetChannel(Player)), GetId(Definition), CallIndex, nil)
			end

			continue
		end

		if CallIndex ~= EventIndex then
			ThreadPool.Defer(Respond, Player, Definition, CallIndex, table.unpack(Values, First, Last))
		elseif First == Last then
			Definition.OnServerEvent:Fire(Player, Values[First])
		else
			Definition.OnServerEvent:Fire(Player, table.unpack(Values, First, Last))
		end
	end
end

const function Receive(Player: Player, Source: any, Instances: any)
	if typeof(Source) ~= "buffer" then
		Configuration.Warn(`[swiftpacket] rejected a batch from {Player.Name} that was not a buffer`)

		return
	end

	local Attached = NoInstances

	if Instances ~= nil then
		if type(Instances) ~= "table" then
			Configuration.Warn(`[swiftpacket] rejected a batch from {Player.Name} with invalid instances`)

			return
		end

		Attached = Instances
	end

	if not Charge(Player, buffer.len(Source) + #Attached * 8 + 64) then
		Configuration.Warn(`[swiftpacket] {Player.Name} is over the incoming byte budget, dropped a batch`)

		return
	end

	const Ok, Result = pcall(Wire.Decode, Received, Source, Attached, true, 0, 0)

	if not Ok or Result ~= nil then
		Wire.Release(Received)

		if Ok then
			Configuration.Warn(`[swiftpacket] rejected a batch from {Player.Name} with the unknown packet id {Result}`)
		else
			Configuration.Warn(`[swiftpacket] rejected a batch from {Player.Name}: {tostring(Result)}`)
		end

		return
	end

	const MessageCount = Received.Count

	if not Charge(Player, MessageCount * Configuration.MessageCost) then
		Wire.Release(Received)
		Configuration.Warn(`[swiftpacket] {Player.Name} sent too many messages, dropped a batch of {MessageCount}`)

		return
	end

	Dispatch(Player)
	Wire.Release(Received)
end

const function FireSegment(Remote: RemoteEvent | UnreliableRemoteEvent, Player: Player, Segment: Cursor.Cursor)
	if Segment.Offset == 0 then
		return
	end

	const Data, Attached = Cursor.Take(Segment)
	Cursor.Reset(Segment)

	if Remote:IsA("RemoteEvent") then
		if Attached then
			Remote:FireClient(Player, Data, Attached)
		else
			Remote:FireClient(Player, Data)
		end
	elseif Remote:IsA("UnreliableRemoteEvent") then
		if Attached then
			Remote:FireClient(Player, Data, Attached)
		else
			Remote:FireClient(Player, Data)
		end
	end
end

const function CopyBytes(Target: buffer, Written: number, Source: buffer, From: number, To: number): number
	if To <= From then
		return Written
	end

	buffer.copy(Target, Written, Source, From, To - From)

	return Written + To - From
end

const function CopyInstances(Target: { any }?, Written: number, Source: { any }, From: number, To: number): number
	if Target == nil then
		return Written
	end

	local Next = Written

	for Index = From + 1, To do
		Next += 1
		Target[Next] = Source[Index]
	end

	return Next
end

const function Compose(Channel: Channel): (buffer, { any }?)
	const Reliable = Channel.Reliable
	const Marks = Channel.Marks
	const InstanceCount = Shared.InstancesOffset - Channel.SharedInstancesFrom + Reliable.InstancesOffset
	const Data = buffer.create(Shared.Offset - Channel.SharedFrom + Reliable.Offset)
	const Attached: { any }? = if InstanceCount > 0 then table.create(InstanceCount) else nil

	local Written, InstancesWritten = 0, 0
	local OwnAt, OwnInstancesAt = 0, 0
	local SharedAt, SharedInstancesAt = Channel.SharedFrom, Channel.SharedInstancesFrom

	for Mark = 0, Channel.MarkCount - 1 do
		const At = Mark * 4
		const SharedTo, SharedInstancesTo = Marks[At + 1], Marks[At + 2]
		const OwnTo, OwnInstancesTo = Marks[At + 3], Marks[At + 4]

		Written = CopyBytes(Data, Written, Reliable.Buffer, OwnAt, OwnTo)
		InstancesWritten = CopyInstances(Attached, InstancesWritten, Reliable.Instances, OwnInstancesAt, OwnInstancesTo)
		Written = CopyBytes(Data, Written, Shared.Buffer, SharedAt, SharedTo)
		InstancesWritten =
			CopyInstances(Attached, InstancesWritten, Shared.Instances, SharedInstancesAt, SharedInstancesTo)

		OwnAt, OwnInstancesAt = OwnTo, OwnInstancesTo
		SharedAt, SharedInstancesAt = SharedTo, SharedInstancesTo
	end

	Written = CopyBytes(Data, Written, Reliable.Buffer, OwnAt, Reliable.Offset)
	InstancesWritten =
		CopyInstances(Attached, InstancesWritten, Reliable.Instances, OwnInstancesAt, Reliable.InstancesOffset)
	CopyBytes(Data, Written, Shared.Buffer, SharedAt, Shared.Offset)
	CopyInstances(Attached, InstancesWritten, Shared.Instances, SharedInstancesAt, Shared.InstancesOffset)

	return Data, Attached
end

const function FireData(Remote: RemoteEvent, Player: Player, Data: buffer, Attached: { any }?)
	if Attached then
		Remote:FireClient(Player, Data, Attached)
	else
		Remote:FireClient(Player, Data)
	end
end

const function ResetChannel(Channel: Channel)
	Cursor.Reset(Channel.Reliable)
	table.clear(Channel.Marks)

	Channel.MarkCount = 0
	Channel.SharedFrom = 0
	Channel.SharedInstancesFrom = 0
	Channel.LastShared = 0
	Channel.LastSharedInstances = 0
end

const function Flush()
	const Reliable = ReliableRemote
	const Unreliable = UnreliableRemote

	if Reliable == nil or Unreliable == nil then
		return
	end

	local SharedData = NoBytes
	local SharedAttached: { any }? = nil

	if Shared.Offset > 0 then
		SharedData, SharedAttached = Cursor.Take(Shared)
	end

	for Player, Channel in Channels do
		const SharedBytes = if Channel.Tracked then Shared.Offset - Channel.SharedFrom else 0

		if SharedBytes == 0 then
			FireSegment(Reliable, Player, Channel.Reliable)
		elseif Channel.Reliable.Offset == 0 and Channel.SharedFrom == 0 and Channel.SharedInstancesFrom == 0 then
			FireData(Reliable, Player, SharedData, SharedAttached)
		else
			const Data, Attached = Compose(Channel)
			FireData(Reliable, Player, Data, Attached)
		end

		ResetChannel(Channel)

		for Index = 1, Channel.UnreliableCount do
			FireSegment(Unreliable, Player, Channel.Unreliable[Index])
		end

		Channel.UnreliableCount = 1
	end

	Cursor.Reset(Shared)
end

const function Expire()
	const Now = os.clock()

	for Player, Calls in PendingCalls do
		for CallIndex, Call in Calls do
			if Now >= Call.Deadline then
				Calls[CallIndex] = nil
				task.defer(Call.Thread, Wire.Unpack(Call.Definition.TimeoutValues))
			end
		end
	end
end

const function Track(Player: Player)
	if table.find(Everyone, Player) == nil then
		table.insert(Everyone, Player)
	end

	const Channel = GetChannel(Player)

	if not Channel.Tracked then
		Channel.Tracked = true
		Channel.SharedFrom = Shared.Offset
		Channel.SharedInstancesFrom = Shared.InstancesOffset
		Channel.LastShared = Shared.Offset
		Channel.LastSharedInstances = Shared.InstancesOffset
	end
end

const function Cleanup(Player: Player)
	const Calls = PendingCalls[Player]

	if Calls then
		for CallIndex, Call in Calls do
			task.defer(Call.Thread, Wire.Unpack(Call.Definition.TimeoutValues))
		end
	end

	const Index = table.find(Everyone, Player)

	if Index then
		table.remove(Everyone, Index)
	end

	PendingCalls[Player] = nil
	NextCallIndex[Player] = nil
	Channels[Player] = nil
	Budgets[Player] = nil

	for Definition, PerPlayer in Windows do
		PerPlayer[Player] = nil
	end
end

function Server.Start(Root: Instance)
	if ReliableRemote then
		return
	end

	const Reliable = Instance.new("RemoteEvent")
	Reliable.Name = "Reliable"
	Reliable.Parent = Root

	const Unreliable = Instance.new("UnreliableRemoteEvent")
	Unreliable.Name = "Unreliable"
	Unreliable.Parent = Root

	ReliableRemote = Reliable
	UnreliableRemote = Unreliable

	Reliable.OnServerEvent:Connect(Receive)
	Unreliable.OnServerEvent:Connect(Receive)
	Players.PlayerAdded:Connect(Track)
	Players.PlayerRemoving:Connect(Cleanup)

	for Index, Player in Players:GetPlayers() do
		Track(Player)
	end

	RunService.Heartbeat:Connect(function()
		Expire()
		task.defer(Flush)
	end)
end

return Server
