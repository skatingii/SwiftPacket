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

const Cursor = require("./cursor")
const Registry = require("./registry")
const Schema = require("./schema")

export type Batch = {
	Count: number,
	Definitions: { Registry.Definition },
	CallIndices: { number },
	Successes: { boolean },
	Starts: { number },
	Counts: { number },
	Values: { any },
	StopOffset: number,
	StopInstances: number,
}

const Wire = {}

const ResponseFlag = 32768
const EventIndex = -1

const ReadVarint = Cursor.ReadVarint
const ReadU16 = Cursor.ReadU16
const ReadU8 = Cursor.ReadU8
const Ended = Cursor.Ended
const Position = Cursor.Position

const function VarintSize(Value: number): number
	return if Value < 128 then 1 elseif Value < 16384 then 2 elseif Value < 2097152 then 3 else 4
end

Wire.ResponseFlag = ResponseFlag
Wire.EventIndex = EventIndex

function Wire.Encode(
	Target: Cursor.Cursor,
	Schemas: { Schema.Schema },
	Values: Schema.Arguments,
	Offset: number,
	Name: string
)
	Cursor.Reset(Target)
	Cursor.Import(Target)
	Schema.WriteArguments(Schemas, Values, Offset, Name)
	Cursor.Export()
end

function Wire.Deliver(Target: Cursor.Cursor, Id: number, CallIndex: number?, Status: number?, Body: Cursor.Cursor?)
	Cursor.Import(Target)
	Cursor.WriteId(Id)

	if CallIndex then
		Cursor.Allocate(2)
		Cursor.WriteU16(CallIndex)
	end

	if Status then
		Cursor.Allocate(1)
		Cursor.WriteU8(Status)
	end

	if Body then
		Cursor.Append(Body)
	end

	Cursor.Export()
end

function Wire.DeliverResponse(Target: Cursor.Cursor, Id: number, CallIndex: number, Body: Cursor.Cursor?)
	if Body then
		Wire.Deliver(Target, Id, CallIndex + ResponseFlag, 1, Body)
	else
		Wire.Deliver(Target, Id, CallIndex + ResponseFlag, 0, nil)
	end
end

function Wire.EncodeResults(
	Target: Cursor.Cursor,
	Definition: Registry.Definition,
	Results: Schema.Arguments
): (boolean, string?)
	const Responses = Definition.Responses

	if Responses == nil then
		return false, `{Definition.Name} has no response types`
	end

	if Results[1] ~= true then
		return false, `the handler for {Definition.Name} errored: {tostring(Results[2])}`
	end

	const Ok, Problem = pcall(Wire.Encode, Target, Responses, Results, 1, "")

	if not Ok then
		return false, `could not write the response for {Definition.Name}: {tostring(Problem)}`
	end

	return true, nil
end

function Wire.Size(Id: number, CallIndex: number?, Body: Cursor.Cursor): number
	return VarintSize(Id) + (if CallIndex then 2 else 0) + Body.Offset
end

function Wire.NewBatch(): Batch
	return {
		Count = 0,
		Definitions = {},
		CallIndices = {},
		Successes = {},
		Starts = {},
		Counts = {},
		Values = {},
		StopOffset = 0,
		StopInstances = 0,
	}
end

function Wire.Decode(
	Target: Batch,
	Source: buffer,
	Instances: { any },
	Untrusted: boolean,
	Offset: number,
	StartInstances: number
): number?
	Cursor.Load(Source, Instances, Untrusted, Offset, StartInstances)

	const Definitions = Target.Definitions
	const CallIndices = Target.CallIndices
	const Successes = Target.Successes
	const Starts = Target.Starts
	const Counts = Target.Counts
	const Values = Target.Values

	local Count = 0
	local Top = 0

	Target.Count = 0

	while not Ended() do
		const Id = ReadVarint()
		const Definition = Registry.ById[Id]

		if Definition == nil then
			const Reached, ReachedInstances = Position()

			Target.StopOffset = Reached - VarintSize(Id)
			Target.StopInstances = ReachedInstances

			return Id
		end

		const Responses = Definition.Responses
		local CallIndex = EventIndex
		local Success = true
		local Schemas = Definition.Arguments

		if Responses then
			CallIndex = ReadU16()

			if CallIndex >= ResponseFlag then
				Success = ReadU8() == 1
				Schemas = Responses
			end
		end

		Count += 1
		Definitions[Count] = Definition
		CallIndices[Count] = CallIndex
		Successes[Count] = Success
		Starts[Count] = Top + 1

		if Success then
			const Size = #Schemas

			if Size == 1 then
				Top += 1
				Values[Top] = Schemas[1].Read()
			else
				for Index = 1, Size do
					Top += 1
					Values[Top] = Schemas[Index].Read()
				end
			end
		end

		Counts[Count] = Top + 1 - Starts[Count]
		Target.Count = Count
	end

	return nil
end

function Wire.Release(Target: Batch)
	table.clear(Target.Values)
	table.clear(Target.Definitions)
	Target.Count = 0
end

function Wire.Unpack(Values: Schema.Arguments): ...any
	return table.unpack(Values, 1, Values.n)
end

return Wire
