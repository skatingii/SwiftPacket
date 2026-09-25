--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Cursor = require("../src/cursor")
const RateLimit = require("../src/rate_limit")
const Registry = require("../src/registry")
const Schema = require("../src/schema")
const Signal = require("../src/signal")
const Testkit = require("./Testkit")
const Wire = require("../src/wire")

const Test = Testkit.Test
const Equal = Testkit.Equal
const Near = Testkit.Near
const Truthy = Testkit.Truthy
const Throws = Testkit.Throws

const function Encode(Definition: Schema.Schema, Value: any): (buffer, { any })
	const Target = Cursor.New(1)
	Cursor.Import(Target)
	Definition.Write(Value)

	const Data, Instances = Cursor.Truncate()

	return Data, Instances or {}
end

const function Decode(Definition: Schema.Schema, Data: buffer, Instances: { any }, Untrusted: boolean): any
	Cursor.Load(Data, Instances, Untrusted, 0, 0)

	const Value = Definition.Read()

	if not Cursor.Ended() then
		error(`decode left {Cursor.Remaining()} bytes unread`, 0)
	end

	return Value
end

const function RoundTrip(Definition: Schema.Schema, Value: any): any
	const Data, Instances = Encode(Definition, Value)

	return Decode(Definition, Data, Instances, false)
end

const function Bytes(...: number): buffer
	const Values = { ... }
	const Data = buffer.create(#Values)

	for Index, Value in Values do
		buffer.writeu8(Data, Index - 1, Value)
	end

	return Data
end

const function MakeDefinition(
	Name: string,
	Arguments: { Schema.Schema },
	Responses: { Schema.Schema }?
): Registry.Definition
	return {
		Name = Name,
		Arguments = Arguments,
		Responses = Responses,
		TimeoutSeconds = 10,
		TimeoutValues = { n = 0 },
		Reliable = true,
		OnServerEvent = Signal.New(),
		OnClientEvent = Signal.New(),
	}
end

Test("varint round trips at every width boundary", function()
	for Index, Value in { 0, 1, 127, 128, 16383, 16384, 2097151, 2097152, 268435455 } do
		const Target = Cursor.New(1)
		Cursor.Import(Target)
		Cursor.Allocate(4)
		Cursor.WriteVarint(Value)

		const Data = Cursor.Truncate()
		Cursor.Load(Data, {}, false, 0, 0)

		Equal(Cursor.ReadVarint(), Value)
		Truthy(Cursor.Ended())
	end
end)

Test("varint rejects values it cannot hold", function()
	const Target = Cursor.New(8)
	Cursor.Import(Target)

	Throws(function()
		Cursor.WriteVarint(-1)
	end, "must be a whole number")

	Throws(function()
		Cursor.WriteVarint(268435456)
	end, "must be a whole number")

	Throws(function()
		Cursor.WriteVarint(1.5)
	end, "must be a whole number")
end)

Test("integers round trip at their limits", function()
	const Cases: { { any } } = {
		{ Schema.U8, 0, 255 },
		{ Schema.U16, 0, 65535 },
		{ Schema.U24, 0, 16777215 },
		{ Schema.U32, 0, 4294967295 },
		{ Schema.I8, -128, 127 },
		{ Schema.I16, -32768, 32767 },
		{ Schema.I24, -8388608, 8388607 },
		{ Schema.I32, -2147483648, 2147483647 },
	}

	for Index, Case in Cases do
		Equal(RoundTrip(Case[1], Case[2]), Case[2])
		Equal(RoundTrip(Case[1], Case[3]), Case[3])
	end
end)

Test("f32 and f64 round trip", function()
	Equal(RoundTrip(Schema.F64, math.pi), math.pi)
	Near(RoundTrip(Schema.F32, math.pi), math.pi, 1e-6)
	Equal(RoundTrip(Schema.F64, -0.1), -0.1)
end)

Test("f16 keeps exact halves and saturates to infinity", function()
	Equal(RoundTrip(Schema.F16, 0), 0)
	Equal(RoundTrip(Schema.F16, 1.5), 1.5)
	Equal(RoundTrip(Schema.F16, -2), -2)
	Equal(RoundTrip(Schema.F16, 65504), 65504)
	Equal(RoundTrip(Schema.F16, 100000), math.huge)
	Equal(RoundTrip(Schema.F16, -math.huge), -math.huge)
	Near(RoundTrip(Schema.F16, 0.1), 0.1, 1e-4)
	Near(RoundTrip(Schema.F16, 2 ^ -20), 2 ^ -20, 2 ^ -24)

	const Value = RoundTrip(Schema.F16, 0 / 0)
	Truthy(Value ~= Value)
end)

Test("f24 keeps more precision than f16", function()
	Near(RoundTrip(Schema.F24, 1234.5678), 1234.5678, 0.01)
	Equal(RoundTrip(Schema.F24, -0.5), -0.5)
	Near(RoundTrip(Schema.F24, 1e-5), 1e-5, 1e-9)
end)

Test("untrusted reads reject non-finite numbers", function()
	for Index, Definition in { Schema.F16, Schema.F24, Schema.F32, Schema.F64 } do
		const Data, Instances = Encode(Definition, 0 / 0)

		Throws(function()
			Decode(Definition, Data, Instances, true)
		end, "non-finite")

		const Infinite, InfiniteInstances = Encode(Definition, math.huge)

		Throws(function()
			Decode(Definition, Infinite, InfiniteInstances, true)
		end, "non-finite")
	end
end)

Test("strings and buffers round trip at any length", function()
	Equal(RoundTrip(Schema.String, ""), "")
	Equal(RoundTrip(Schema.String, "hello"), "hello")
	Equal(RoundTrip(Schema.String, string.rep("x", 5000)), string.rep("x", 5000))

	const Source = buffer.fromstring("\0\1\2\255")
	Equal(buffer.tostring(RoundTrip(Schema.Buffer, Source)), buffer.tostring(Source))
end)

Test("a string length past the end of the batch is rejected", function()
	Throws(function()
		Decode(Schema.String, Bytes(0x7F, 65, 66), {}, true)
	end, "larger than the data left")
end)

Test("booleans and nil round trip", function()
	Equal(RoundTrip(Schema.Boolean, true), true)
	Equal(RoundTrip(Schema.Boolean, false), false)
	Equal(RoundTrip(Schema.Nil, nil), nil)
end)

Test("structs, arrays, maps and optionals round trip", function()
	const Definition = Schema.Compile({
		Coins = Schema.U32,
		Items = { Schema.String },
		Equipped = Schema.Optional(Schema.String),
		Stats = Schema.Map(Schema.String, Schema.F64),
	})

	const Value = RoundTrip(Definition, {
		Coins = 1500,
		Items = { "Sword", "Shield" },
		Stats = { Speed = 16.5, Jump = 50 },
	})

	Equal(Value.Coins, 1500)
	Equal(#Value.Items, 2)
	Equal(Value.Items[2], "Shield")
	Equal(Value.Equipped, nil)
	Equal(Value.Stats.Speed, 16.5)
	Equal(Value.Stats.Jump, 50)

	Equal(RoundTrip(Schema.Optional(Schema.U8), 7), 7)
end)

Test("array and map maximums are enforced on both sides", function()
	const Bounded = Schema.Array(Schema.U8, 2)

	Throws(function()
		Encode(Bounded, { 1, 2, 3 })
	end, "over the maximum")

	Throws(function()
		Decode(Bounded, Bytes(3, 1, 2, 3), {}, true)
	end, "over the maximum")

	Throws(function()
		Encode(Schema.Map(Schema.U8, Schema.U8, 1), { [1] = 1, [2] = 2 })
	end, "over the maximum")
end)

Test("a huge array count with no data behind it is rejected", function()
	Throws(function()
		Decode(Schema.Array(Schema.U8), Bytes(0xFF, 0xFF, 0xFF, 0x7F), {}, true)
	end, "larger than the data left")

	Throws(function()
		Decode(Schema.Array(Schema.Nil), Bytes(0xFF, 0xFF, 0xFF, 0x7F), {}, true)
	end, "larger than the data left")
end)

Test("static lists send an index and reject unknown values", function()
	const Definition = Schema.Static({ "Idle", "Walk", "Run" })
	const Data = Encode(Definition, "Run")

	Equal(buffer.len(Data), 1)
	Equal(RoundTrip(Definition, "Walk"), "Walk")

	Throws(function()
		Encode(Definition, "Fly")
	end, "not in the static list")

	Throws(function()
		Decode(Definition, Bytes(9), {}, true)
	end, "outside the static list")
end)

Test("flags pack eight booleans into one byte", function()
	const Definition = Schema.Flags({ "A", "B", "C", "D", "E", "F", "G", "H", "I" })
	const Data = Encode(Definition, { A = true, C = true, I = true })

	Equal(buffer.len(Data), 2)

	const Value = RoundTrip(Definition, { B = true, H = true })
	Equal(Value.A, false)
	Equal(Value.B, true)
	Equal(Value.H, true)
	Equal(Value.I, false)
end)

Test("charsets pack characters into fewer bits", function()
	const Data = Encode(Schema.Characters, "Hello World")

	Equal(buffer.len(Data), 1 + math.ceil(11 * 6 / 8))
	Equal(RoundTrip(Schema.Characters, "Hello World"), "Hello World")

	Throws(function()
		Encode(Schema.Characters, "no!")
	end, "is not in the charset")
end)

Test("ranges reject values outside their bounds", function()
	const Definition = Schema.Range(Schema.U8, 1, 10)

	Equal(RoundTrip(Definition, 10), 10)

	Throws(function()
		Encode(Definition, 11)
	end, "outside the range")

	Throws(function()
		Decode(Definition, Bytes(200), {}, true)
	end, "outside the range")
end)

Test("any round trips nested values", function()
	const Value = RoundTrip(Schema.Any, {
		Name = "Hero",
		Level = 12,
		Debt = -70000,
		Ratio = 0.3,
		Big = 2 ^ 40,
		Alive = true,
		Tags = { "a", "b" },
	})

	Equal(Value.Name, "Hero")
	Equal(Value.Level, 12)
	Equal(Value.Debt, -70000)
	Equal(Value.Ratio, 0.3)
	Equal(Value.Big, 2 ^ 40)
	Equal(Value.Alive, true)
	Equal(Value.Tags[2], "b")
end)

Test("any refuses unsupported values and deep nesting", function()
	Throws(function()
		Encode(Schema.Any, function() end)
	end, "cannot send a value of type function")

	local Deep: { [string]: any } = {}

	for Index = 1, 20 do
		Deep = { Inner = Deep }
	end

	Throws(function()
		Encode(Schema.Any, Deep)
	end, "deeper than 16 levels")

	const Nested = buffer.create(40)

	for Index = 0, 19 do
		buffer.writeu8(Nested, Index * 2, 26)
		buffer.writeu8(Nested, Index * 2 + 1, 1)
	end

	Throws(function()
		Decode(Schema.Any, Nested, {}, true)
	end, "")

	Throws(function()
		Decode(Schema.Any, Bytes(200), {}, true)
	end, "unknown value tag")
end)

Test("a failed write leaves the cursor untouched", function()
	const Target = Cursor.New(4)
	Cursor.Import(Target)
	Schema.U8.Write(1)
	Cursor.Export()

	const Ok = pcall(function()
		Cursor.Import(Target)
		Schema.Compile({ Name = Schema.String, Mode = Schema.Static({ "A" }) }).Write({ Name = "x", Mode = "B" })
		Cursor.Export()
	end)

	Equal(Ok, false)
	Equal(Target.Offset, 1)
end)

Test("wire decodes a batch of events, requests and responses", function()
	const Event = MakeDefinition("Event", { Schema.U8, Schema.String })
	const Call = MakeDefinition("Call", { Schema.U16 }, { Schema.Boolean })

	Event.Id = 1
	Call.Id = 2
	Registry.ById[1] = Event
	Registry.ById[2] = Call

	const Batch = Cursor.New(1)
	const Body = Cursor.New(1)

	Schema.WriteEvent(Batch, 1, Event.Name, Event.Arguments, 7, "hi")
	Schema.WriteRequest(Batch, 2, 3, Call.Name, Call.Arguments, 500)

	Wire.Encode(Body, { Schema.Boolean }, { n = 1, true }, 0, "a test value")
	Wire.DeliverResponse(Batch, 2, 3, Body)

	Wire.DeliverResponse(Batch, 2, 4, nil)

	const Decoded = Wire.NewBatch()
	const MissingId = Wire.Decode(Decoded, Cursor.Take(Batch), {}, true, 0, 0)

	Equal(MissingId, nil)
	Equal(Decoded.Count, 4)
	Equal(Decoded.CallIndices[1], Wire.EventIndex)
	Equal(Decoded.Counts[1], 2)
	Equal(Decoded.Values[Decoded.Starts[1] + 1], "hi")
	Equal(Decoded.CallIndices[2], 3)
	Equal(Decoded.Values[Decoded.Starts[2]], 500)
	Equal(Decoded.CallIndices[3], 3 + Wire.ResponseFlag)
	Equal(Decoded.Successes[3], true)
	Equal(Decoded.Values[Decoded.Starts[3]], true)
	Equal(Decoded.Successes[4], false)
	Equal(Decoded.Counts[4], 0)

	Wire.Release(Decoded)
	Equal(#Decoded.Values, 0)
end)

Test("writing a message directly matches writing a body and delivering it", function()
	const Event = MakeDefinition("Direct", { Schema.U16, Schema.String })
	const Direct = Cursor.New(1)
	const Delivered = Cursor.New(1)
	const Body = Cursor.New(1)

	Schema.WriteEvent(Direct, 200, Event.Name, Event.Arguments, 513, "direct")
	Schema.WriteBody(Body, Event.Name, Event.Arguments, 513, "direct")
	Wire.Deliver(Delivered, 200, nil, nil, Body)

	Equal(buffer.tostring((Cursor.Take(Direct))), buffer.tostring((Cursor.Take(Delivered))))
end)

Test("a failed write leaves the batch as it was", function()
	const Event = MakeDefinition("Rollback", { Schema.U8, Schema.Range(Schema.U8, 1, 5) })
	const Target = Cursor.New(1)

	Schema.WriteEvent(Target, 1, Event.Name, Event.Arguments, 1, 2)

	const Before = buffer.tostring((Cursor.Take(Target)))

	Throws(function()
		Schema.WriteEvent(Target, 1, Event.Name, Event.Arguments, 1, 9)
	end, "could not write Rollback: 9 is outside the range")

	Equal(buffer.tostring((Cursor.Take(Target))), Before)
end)

Test("wire stops at unknown ids and resumes from where it stopped", function()
	const Known = MakeDefinition("Known", { Schema.U8 })
	const Later = MakeDefinition("Later", { Schema.U8 })

	Known.Id = 40
	Later.Id = 41
	Registry.ById[40] = Known
	Registry.ById[41] = nil

	const Batch = Cursor.New(1)

	Schema.WriteEvent(Batch, 40, Known.Name, Known.Arguments, 1)
	Schema.WriteEvent(Batch, 41, Later.Name, Later.Arguments, 2)
	Schema.WriteEvent(Batch, 40, Known.Name, Known.Arguments, 3)

	const Data = Cursor.Take(Batch)
	const Decoded = Wire.NewBatch()

	Equal(Wire.Decode(Decoded, Data, {}, false, 0, 0), 41)
	Equal(Decoded.Count, 1)
	Equal(Decoded.Values[1], 1)
	Equal(Decoded.StopOffset, 2)

	Registry.ById[41] = Later

	const Offset = Decoded.StopOffset
	Wire.Release(Decoded)

	Equal(Wire.Decode(Decoded, Data, {}, false, Offset, 0), nil)
	Equal(Decoded.Count, 2)
	Equal(Decoded.Definitions[1], Later)
	Equal(Decoded.Values[1], 2)
	Equal(Decoded.Values[2], 3)

	Registry.ById[40] = nil
	Registry.ById[41] = nil
end)

Test("wire rejects truncated batches", function()
	const Event = MakeDefinition("Truncated", { Schema.U32 })
	Registry.ById[7] = Event

	Throws(function()
		Wire.Decode(Wire.NewBatch(), Bytes(7, 1), {}, true, 0, 0)
	end, "")

	Registry.ById[7] = nil
end)

Test("serialize and deserialize round trip several values", function()
	const Schemas = { Schema.U8, Schema.String, Schema.Optional(Schema.U16) }
	const Data = Schema.Serialize("Several", Schemas, 5, "five", nil)
	const First, Second, Third = Schema.Deserialize(Schemas, Data, {})

	Equal(First, 5)
	Equal(Second, "five")
	Equal(Third, nil)
	Equal(Schema.Deserialize({ Schema.U16 }, (Schema.Serialize("Single", { Schema.U16 }, 700)), {}), 700)
end)

Test("results that do not match the response types become a failure", function()
	const Call = MakeDefinition("Checked", { Schema.U8 }, { Schema.String })
	const Body = Cursor.New()

	const Ok, Problem = Wire.EncodeResults(Body, Call, { n = 2, true, 5 })
	Equal(Ok, false)
	Truthy(string.find(tostring(Problem), "could not write the response", 1, true))

	const Errored = Wire.EncodeResults(Body, Call, { n = 2, false, "boom" })
	Equal(Errored, false)

	const Passed = Wire.EncodeResults(Body, Call, { n = 2, true, "fine" })
	Equal(Passed, true)
end)

Test("rate limit windows reset after their interval", function()
	local Count, EndsAt = 0, 0
	local Allowed = false

	for Index = 1, 3 do
		Allowed, Count, EndsAt = RateLimit.Window(Count, EndsAt, 10, 3, 1)
		Equal(Allowed, true)
	end

	Allowed, Count, EndsAt = RateLimit.Window(Count, EndsAt, 10.5, 3, 1)
	Equal(Allowed, false)

	Allowed, Count, EndsAt = RateLimit.Window(Count, EndsAt, 11, 3, 1)
	Equal(Allowed, true)
	Equal(Count, 1)
end)

Test("token buckets refill up to their capacity", function()
	Equal(RateLimit.Refill(0, 0.5, 100, 100), 50)
	Equal(RateLimit.Refill(90, 5, 100, 100), 100)
	Equal(RateLimit.Refill(10, -1, 100, 100), 10)
end)

Testkit.Finish()
