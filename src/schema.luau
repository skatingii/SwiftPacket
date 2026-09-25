--!strict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

export type Cursor = {
	Buffer: buffer,
	Length: number,
	Offset: number,
	Instances: { any },
	InstancesOffset: number,
}

local ActiveCursor: Cursor? = nil
local ActiveBuffer: buffer = buffer.create(0)
local BufferLength = 0
local BufferOffset = 0
local Instances: { any } = {}
local InstancesOffset = 0
local Untrusted = false
local Writing = "a value"

const function WriteFailure(Message: string): never
	if Writing == "" then
		error(`[swiftpacket] {Message}`, 0)
	end

	error(`[swiftpacket] could not write {Writing}: {Message}`, 0)
end

const function NewCursor(Size: number?): Cursor
	const Length = Size or 128

	return {
		Buffer = buffer.create(Length),
		Length = Length,
		Offset = 0,
		Instances = {},
		InstancesOffset = 0,
	}
end

const function Import(Target: Cursor)
	ActiveCursor = Target
	ActiveBuffer = Target.Buffer
	BufferLength = Target.Length
	BufferOffset = Target.Offset
	Instances = Target.Instances
	InstancesOffset = Target.InstancesOffset
	Untrusted = false
end

const function Export(): Cursor
	const Target = ActiveCursor

	if Target == nil then
		error("[swiftpacket] there is no cursor to export, the active one is read only", 0)
	end

	Target.Buffer = ActiveBuffer
	Target.Length = BufferLength
	Target.Offset = BufferOffset
	Target.InstancesOffset = InstancesOffset

	return Target
end

const function Load(
	Source: buffer,
	SourceInstances: { any },
	IsUntrusted: boolean,
	Offset: number,
	StartInstances: number
)
	ActiveCursor = nil
	ActiveBuffer = Source
	BufferLength = buffer.len(Source)
	BufferOffset = Offset
	Instances = SourceInstances
	InstancesOffset = StartInstances
	Untrusted = IsUntrusted
end

const function Reset(Target: Cursor)
	Target.Offset = 0

	if Target.InstancesOffset > 0 then
		Target.InstancesOffset = 0
		table.clear(Target.Instances)
	end
end

const function Take(Target: Cursor): (buffer, { any }?)
	const Truncated = buffer.create(Target.Offset)
	buffer.copy(Truncated, 0, Target.Buffer, 0, Target.Offset)

	if Target.InstancesOffset == 0 then
		return Truncated, nil
	end

	return Truncated, table.move(Target.Instances, 1, Target.InstancesOffset, 1, table.create(Target.InstancesOffset))
end

const function Ended(): boolean
	return BufferOffset >= BufferLength
end

const function Remaining(): number
	return BufferLength - BufferOffset
end

const function RemainingInstances(): number
	return #Instances - InstancesOffset
end

const function Allocate(Bytes: number)
	const TargetLength = BufferOffset + Bytes

	if BufferLength >= TargetLength then
		return
	end

	while BufferLength < TargetLength do
		BufferLength *= 2
	end

	const Grown = buffer.create(BufferLength)
	buffer.copy(Grown, 0, ActiveBuffer, 0, BufferOffset)
	ActiveBuffer = Grown
end

const function Append(Source: Cursor)
	Allocate(Source.Offset)
	buffer.copy(ActiveBuffer, BufferOffset, Source.Buffer, 0, Source.Offset)
	BufferOffset += Source.Offset

	for Index = 1, Source.InstancesOffset do
		InstancesOffset += 1
		Instances[InstancesOffset] = Source.Instances[Index]
	end
end

const function CheckFloat(Value: number): number
	if Untrusted and (Value ~= Value or Value == math.huge or Value == -math.huge) then
		error("[swiftpacket] rejected a non-finite number", 0)
	end

	return Value
end

const function ReadU8(): number
	const Value = buffer.readu8(ActiveBuffer, BufferOffset)
	BufferOffset += 1

	return Value
end

const function WriteU8(Value: number)
	buffer.writeu8(ActiveBuffer, BufferOffset, Value)
	BufferOffset += 1
end

const function ReadI8(): number
	const Value = buffer.readi8(ActiveBuffer, BufferOffset)
	BufferOffset += 1

	return Value
end

const function WriteI8(Value: number)
	buffer.writei8(ActiveBuffer, BufferOffset, Value)
	BufferOffset += 1
end

const function ReadU16(): number
	const Value = buffer.readu16(ActiveBuffer, BufferOffset)
	BufferOffset += 2

	return Value
end

const function WriteU16(Value: number)
	buffer.writeu16(ActiveBuffer, BufferOffset, Value)
	BufferOffset += 2
end

const function ReadI16(): number
	const Value = buffer.readi16(ActiveBuffer, BufferOffset)
	BufferOffset += 2

	return Value
end

const function WriteI16(Value: number)
	buffer.writei16(ActiveBuffer, BufferOffset, Value)
	BufferOffset += 2
end

const function ReadU24(): number
	const Value = buffer.readbits(ActiveBuffer, BufferOffset * 8, 24)
	BufferOffset += 3

	return Value
end

const function WriteU24(Value: number)
	buffer.writebits(ActiveBuffer, BufferOffset * 8, 24, Value)
	BufferOffset += 3
end

const function ReadI24(): number
	const Value = buffer.readbits(ActiveBuffer, BufferOffset * 8, 24) - 8388608
	BufferOffset += 3

	return Value
end

const function WriteI24(Value: number)
	buffer.writebits(ActiveBuffer, BufferOffset * 8, 24, Value + 8388608)
	BufferOffset += 3
end

const function ReadU32(): number
	const Value = buffer.readu32(ActiveBuffer, BufferOffset)
	BufferOffset += 4

	return Value
end

const function WriteU32(Value: number)
	buffer.writeu32(ActiveBuffer, BufferOffset, Value)
	BufferOffset += 4
end

const function ReadI32(): number
	const Value = buffer.readi32(ActiveBuffer, BufferOffset)
	BufferOffset += 4

	return Value
end

const function WriteI32(Value: number)
	buffer.writei32(ActiveBuffer, BufferOffset, Value)
	BufferOffset += 4
end

const function ReadF32(): number
	const Value = buffer.readf32(ActiveBuffer, BufferOffset)
	BufferOffset += 4

	return CheckFloat(Value)
end

const function WriteF32(Value: number)
	buffer.writef32(ActiveBuffer, BufferOffset, Value)
	BufferOffset += 4
end

const function ReadF64(): number
	const Value = buffer.readf64(ActiveBuffer, BufferOffset)
	BufferOffset += 8

	return CheckFloat(Value)
end

const function WriteF64(Value: number)
	buffer.writef64(ActiveBuffer, BufferOffset, Value)
	BufferOffset += 8
end

const function ReadBits(BitOffset: number, Count: number): number
	return buffer.readbits(ActiveBuffer, BufferOffset * 8 + BitOffset, Count)
end

const function WriteBits(BitOffset: number, Count: number, Value: number)
	buffer.writebits(ActiveBuffer, BufferOffset * 8 + BitOffset, Count, Value)
end

const function Skip(Bytes: number)
	BufferOffset += Bytes
end

const function ReadVarint(): number
	local Value = 0
	local Scale = 1

	for Index = 1, 4 do
		const Byte = buffer.readu8(ActiveBuffer, BufferOffset)
		BufferOffset += 1

		if Index == 4 or Byte < 128 then
			return Value + Byte * Scale
		end

		Value += (Byte - 128) * Scale
		Scale *= 128
	end

	return Value
end

const function WriteVarint(Value: number)
	if Value < 0 or Value >= 268435456 or Value % 1 ~= 0 then
		WriteFailure(`length {Value} must be a whole number from 0 to 268435455`)
	end

	local Left = Value

	while Left >= 128 do
		buffer.writeu8(ActiveBuffer, BufferOffset, Left % 128 + 128)
		BufferOffset += 1
		Left //= 128
	end

	buffer.writeu8(ActiveBuffer, BufferOffset, Left)
	BufferOffset += 1
end

const function ReadString(Length: number): string
	const Value = buffer.readstring(ActiveBuffer, BufferOffset, Length)
	BufferOffset += Length

	return Value
end

const function WriteString(Value: string)
	buffer.writestring(ActiveBuffer, BufferOffset, Value)
	BufferOffset += #Value
end

const function ReadBuffer(Length: number): buffer
	const Value = buffer.create(Length)
	buffer.copy(Value, 0, ActiveBuffer, BufferOffset, Length)
	BufferOffset += Length

	return Value
end

const function WriteBuffer(Value: buffer)
	buffer.copy(ActiveBuffer, BufferOffset, Value)
	BufferOffset += buffer.len(Value)
end

const function ReadInstance(): Instance?
	InstancesOffset += 1

	const Value = Instances[InstancesOffset]

	if typeof(Value) == "Instance" then
		return Value
	end

	return nil
end

const function WriteInstance(Value: Instance?)
	InstancesOffset += 1
	Instances[InstancesOffset] = if Value == nil then false else Value
end

const function WriteId(Id: number)
	if Id < 128 then
		Allocate(1)
		buffer.writeu8(ActiveBuffer, BufferOffset, Id)
		BufferOffset += 1
	else
		Allocate(4)
		WriteVarint(Id)
	end
end

const CursorLibrary = {
	New = NewCursor,
	Import = Import,
	Export = Export,
	Load = Load,
	Reset = Reset,
	Take = Take,
	Ended = Ended,
	Remaining = Remaining,
	RemainingInstances = RemainingInstances,
	Allocate = Allocate,
	Append = Append,
	CheckFloat = CheckFloat,
	ReadU8 = ReadU8,
	WriteU8 = WriteU8,
	ReadI8 = ReadI8,
	WriteI8 = WriteI8,
	ReadU16 = ReadU16,
	WriteU16 = WriteU16,
	ReadI16 = ReadI16,
	WriteI16 = WriteI16,
	ReadU24 = ReadU24,
	WriteU24 = WriteU24,
	ReadI24 = ReadI24,
	WriteI24 = WriteI24,
	ReadU32 = ReadU32,
	WriteU32 = WriteU32,
	ReadI32 = ReadI32,
	WriteI32 = WriteI32,
	ReadF32 = ReadF32,
	WriteF32 = WriteF32,
	ReadF64 = ReadF64,
	WriteF64 = WriteF64,
	ReadBits = ReadBits,
	WriteBits = WriteBits,
	Skip = Skip,
	ReadVarint = ReadVarint,
	WriteVarint = WriteVarint,
	WriteId = WriteId,
	ReadString = ReadString,
	WriteString = WriteString,
	ReadBuffer = ReadBuffer,
	WriteBuffer = WriteBuffer,
	ReadInstance = ReadInstance,
	WriteInstance = WriteInstance,
}

function CursorLibrary.Truncate(): (buffer, { any }?)
	return Take(Export())
end

function CursorLibrary.Position(): (number, number)
	return BufferOffset, InstancesOffset
end

export type Schema = {
	Read: () -> any,
	Write: (Value: any) -> (),
	MinimumSize: number,
}

export type Arguments = { n: number, [number]: any }

const Schema = {}

const Registered: { [any]: boolean } = setmetatable({}, { __mode = "k" })

function Schema.Define(Read: () -> any, Write: (Value: any) -> (), MinimumSize: number): Schema
	const Definition: Schema = {
		Read = Read,
		Write = Write,
		MinimumSize = MinimumSize,
	}

	Registered[Definition] = true

	return Definition
end

function Schema.Is(Value: any): boolean
	return Registered[Value] == true
end

const Define = Schema.Define

const function CheckCount(Count: number, MinimumSize: number, MaximumCount: number?)
	if MaximumCount and Count > MaximumCount then
		error(`[swiftpacket] count {Count} is over the maximum of {MaximumCount}`, 0)
	end

	if MinimumSize > 0 then
		if Count * MinimumSize > Remaining() then
			error(`[swiftpacket] count {Count} is larger than the data left in the batch`, 0)
		end
	elseif Count > Remaining() + RemainingInstances() then
		error(`[swiftpacket] count {Count} is larger than the data left in the batch`, 0)
	end
end

const function CheckLength(Length: number, MaximumLength: number?)
	if MaximumLength and Length > MaximumLength then
		error(`[swiftpacket] length {Length} is over the maximum of {MaximumLength}`, 0)
	end

	if Length > Remaining() then
		error(`[swiftpacket] length {Length} is larger than the data left in the batch`, 0)
	end
end

const function CountEntries(Value: { [any]: any }): number
	local Count = 0

	for Key in Value do
		Count += 1
	end

	return Count
end

const function FloatCodec(ExponentBits: number, MantissaBits: number)
	const Bias = 2 ^ (ExponentBits - 1) - 1
	const MaximumExponent = 2 ^ ExponentBits - 1
	const MantissaScale = 2 ^ MantissaBits
	const SignScale = 2 ^ (ExponentBits + MantissaBits)
	const SubnormalScale = 2 ^ (1 - Bias - MantissaBits)

	const function Encode(Value: number): number
		if Value ~= Value then
			return MaximumExponent * MantissaScale + 1
		end

		local Sign = 0
		local Magnitude = Value

		if Magnitude < 0 or (Magnitude == 0 and 1 / Magnitude < 0) then
			Sign = SignScale
			Magnitude = -Magnitude
		end

		if Magnitude == 0 then
			return Sign
		end

		if Magnitude == math.huge then
			return Sign + MaximumExponent * MantissaScale
		end

		const Mantissa, Exponent = math.frexp(Magnitude)
		local Biased = Exponent - 1 + Bias
		local Fraction: number

		if Biased <= 0 then
			Fraction = math.round(Magnitude / SubnormalScale)
			Biased = 0

			if Fraction >= MantissaScale then
				Fraction = 0
				Biased = 1
			end
		else
			Fraction = math.round((Mantissa * 2 - 1) * MantissaScale)

			if Fraction >= MantissaScale then
				Fraction = 0
				Biased += 1
			end
		end

		if Biased >= MaximumExponent then
			return Sign + MaximumExponent * MantissaScale
		end

		return Sign + Biased * MantissaScale + Fraction
	end

	const function Decode(Bits: number): number
		const Fraction = Bits % MantissaScale
		const Biased = (Bits // MantissaScale) % (MaximumExponent + 1)
		const Sign = if Bits >= SignScale then -1 else 1

		if Biased == MaximumExponent then
			return CheckFloat(if Fraction == 0 then Sign * math.huge else 0 / 0)
		end

		if Biased == 0 then
			return Sign * Fraction * SubnormalScale
		end

		return Sign * (1 + Fraction / MantissaScale) * 2 ^ (Biased - Bias)
	end

	return Encode, Decode
end

const EncodeF16, DecodeF16 = FloatCodec(5, 10)
const EncodeF24, DecodeF24 = FloatCodec(6, 17)

const function ReadF16(): number
	return DecodeF16(ReadU16())
end

const function WriteF16(Value: number)
	WriteU16(EncodeF16(Value))
end

const function ReadF24(): number
	return DecodeF24(ReadU24())
end

const function WriteF24(Value: number)
	WriteU24(EncodeF24(Value))
end

const RotationScale = 65535 / math.sqrt(2)
const RotationOffset = 32767.5

const function WriteRotation(Value: CFrame)
	const Axis, Angle = Value:ToAxisAngle()
	const Sine = math.sin(Angle / 2)
	const Components = { Axis.X * Sine, Axis.Y * Sine, Axis.Z * Sine, math.cos(Angle / 2) }

	local Largest = 1

	for Index = 2, 4 do
		if math.abs(Components[Index]) > math.abs(Components[Largest]) then
			Largest = Index
		end
	end

	const Flip = if Components[Largest] < 0 then -1 else 1

	WriteU8(Largest - 1)

	for Index = 1, 4 do
		if Index ~= Largest then
			WriteU16(math.clamp(math.round(Components[Index] * Flip * RotationScale + RotationOffset), 0, 65535))
		end
	end
end

const function ReadRotation(): (number, number, number, number)
	const Largest = ReadU8() + 1

	if Largest > 4 then
		error("[swiftpacket] rejected an invalid rotation", 0)
	end

	const Components = { 0, 0, 0, 0 }
	local Sum = 0

	for Index = 1, 4 do
		if Index ~= Largest then
			const Component = (ReadU16() - RotationOffset) / RotationScale
			Components[Index] = Component
			Sum += Component * Component
		end
	end

	Components[Largest] = math.sqrt(math.max(0, 1 - Sum))

	return Components[1], Components[2], Components[3], Components[4]
end

const function WriteNumberSequence(Value: NumberSequence)
	const Keypoints = Value.Keypoints

	Allocate(4 + #Keypoints * 12)
	WriteVarint(#Keypoints)

	for Index = 1, #Keypoints do
		const Keypoint = Keypoints[Index]

		WriteF32(Keypoint.Time)
		WriteF32(Keypoint.Value)
		WriteF32(Keypoint.Envelope)
	end
end

const function ReadNumberSequence(): NumberSequence
	const Count = ReadVarint()
	CheckCount(Count, 12, 20)

	const Keypoints: { NumberSequenceKeypoint } = {}

	for Index = 1, Count do
		Keypoints[Index] = NumberSequenceKeypoint.new(ReadF32(), ReadF32(), ReadF32())
	end

	return NumberSequence.new(Keypoints)
end

const function WriteColorSequence(Value: ColorSequence)
	const Keypoints = Value.Keypoints

	Allocate(4 + #Keypoints * 7)
	WriteVarint(#Keypoints)

	for Index = 1, #Keypoints do
		const Keypoint = Keypoints[Index]

		WriteF32(Keypoint.Time)
		WriteU8(math.round(Keypoint.Value.R * 255))
		WriteU8(math.round(Keypoint.Value.G * 255))
		WriteU8(math.round(Keypoint.Value.B * 255))
	end
end

const function ReadColorSequence(): ColorSequence
	const Count = ReadVarint()
	CheckCount(Count, 7, 20)

	const Keypoints: { ColorSequenceKeypoint } = {}

	for Index = 1, Count do
		Keypoints[Index] = ColorSequenceKeypoint.new(ReadF32(), Color3.fromRGB(ReadU8(), ReadU8(), ReadU8()))
	end

	return ColorSequence.new(Keypoints)
end

Schema.Nil = Define(function()
	return nil
end, function() end, 0)

Schema.Boolean = Define(function()
	return ReadU8() ~= 0
end, function(Value: boolean)
	Allocate(1)
	WriteU8(if Value then 1 else 0)
end, 1)

Schema.U8 = Define(ReadU8, function(Value: number)
	Allocate(1)
	WriteU8(Value)
end, 1)

Schema.U16 = Define(ReadU16, function(Value: number)
	Allocate(2)
	WriteU16(Value)
end, 2)

Schema.U24 = Define(ReadU24, function(Value: number)
	Allocate(3)
	WriteU24(Value)
end, 3)

Schema.U32 = Define(ReadU32, function(Value: number)
	Allocate(4)
	WriteU32(Value)
end, 4)

Schema.I8 = Define(ReadI8, function(Value: number)
	Allocate(1)
	WriteI8(Value)
end, 1)

Schema.I16 = Define(ReadI16, function(Value: number)
	Allocate(2)
	WriteI16(Value)
end, 2)

Schema.I24 = Define(ReadI24, function(Value: number)
	Allocate(3)
	WriteI24(Value)
end, 3)

Schema.I32 = Define(ReadI32, function(Value: number)
	Allocate(4)
	WriteI32(Value)
end, 4)

Schema.F16 = Define(ReadF16, function(Value: number)
	Allocate(2)
	WriteF16(Value)
end, 2)

Schema.F24 = Define(ReadF24, function(Value: number)
	Allocate(3)
	WriteF24(Value)
end, 3)

Schema.F32 = Define(ReadF32, function(Value: number)
	Allocate(4)
	WriteF32(Value)
end, 4)

Schema.F64 = Define(ReadF64, function(Value: number)
	Allocate(8)
	WriteF64(Value)
end, 8)

Schema.String = Define(function()
	const Length = ReadVarint()
	CheckLength(Length)

	return ReadString(Length)
end, function(Value: string)
	Allocate(4 + #Value)
	WriteVarint(#Value)
	WriteString(Value)
end, 1)

Schema.Buffer = Define(function()
	const Length = ReadVarint()
	CheckLength(Length)

	return ReadBuffer(Length)
end, function(Value: buffer)
	Allocate(4 + buffer.len(Value))
	WriteVarint(buffer.len(Value))
	WriteBuffer(Value)
end, 1)

Schema.Instance = Define(ReadInstance, WriteInstance, 0)

Schema.Vector2 = Define(function()
	return Vector2.new(ReadF32(), ReadF32())
end, function(Value: Vector2)
	Allocate(8)
	WriteF32(Value.X)
	WriteF32(Value.Y)
end, 8)

Schema.Vector2F16 = Define(function()
	return Vector2.new(ReadF16(), ReadF16())
end, function(Value: Vector2)
	Allocate(4)
	WriteF16(Value.X)
	WriteF16(Value.Y)
end, 4)

Schema.Vector2I16 = Define(function()
	return Vector2.new(ReadI16(), ReadI16())
end, function(Value: Vector2)
	Allocate(4)
	WriteI16(math.round(Value.X))
	WriteI16(math.round(Value.Y))
end, 4)

Schema.Vector3 = Define(function()
	return Vector3.new(ReadF32(), ReadF32(), ReadF32())
end, function(Value: Vector3)
	Allocate(12)
	WriteF32(Value.X)
	WriteF32(Value.Y)
	WriteF32(Value.Z)
end, 12)

Schema.Vector3F24 = Define(function()
	return Vector3.new(ReadF24(), ReadF24(), ReadF24())
end, function(Value: Vector3)
	Allocate(9)
	WriteF24(Value.X)
	WriteF24(Value.Y)
	WriteF24(Value.Z)
end, 9)

Schema.Vector3F16 = Define(function()
	return Vector3.new(ReadF16(), ReadF16(), ReadF16())
end, function(Value: Vector3)
	Allocate(6)
	WriteF16(Value.X)
	WriteF16(Value.Y)
	WriteF16(Value.Z)
end, 6)

Schema.Vector3I16 = Define(function()
	return Vector3.new(ReadI16(), ReadI16(), ReadI16())
end, function(Value: Vector3)
	Allocate(6)
	WriteI16(math.round(Value.X))
	WriteI16(math.round(Value.Y))
	WriteI16(math.round(Value.Z))
end, 6)

Schema.CFrame = Define(function()
	const X, Y, Z = ReadF32(), ReadF32(), ReadF32()
	const QuaternionX, QuaternionY, QuaternionZ, QuaternionW = ReadRotation()

	return CFrame.new(X, Y, Z, QuaternionX, QuaternionY, QuaternionZ, QuaternionW)
end, function(Value: CFrame)
	Allocate(19)
	WriteF32(Value.X)
	WriteF32(Value.Y)
	WriteF32(Value.Z)
	WriteRotation(Value)
end, 19)

Schema.CFrameF24 = Define(function()
	const X, Y, Z = ReadF24(), ReadF24(), ReadF24()
	const QuaternionX, QuaternionY, QuaternionZ, QuaternionW = ReadRotation()

	return CFrame.new(X, Y, Z, QuaternionX, QuaternionY, QuaternionZ, QuaternionW)
end, function(Value: CFrame)
	Allocate(16)
	WriteF24(Value.X)
	WriteF24(Value.Y)
	WriteF24(Value.Z)
	WriteRotation(Value)
end, 16)

Schema.Color3 = Define(function()
	return Color3.fromRGB(ReadU8(), ReadU8(), ReadU8())
end, function(Value: Color3)
	Allocate(3)
	WriteU8(math.round(math.clamp(Value.R, 0, 1) * 255))
	WriteU8(math.round(math.clamp(Value.G, 0, 1) * 255))
	WriteU8(math.round(math.clamp(Value.B, 0, 1) * 255))
end, 3)

Schema.BrickColor = Define(function()
	return BrickColor.new(ReadU16())
end, function(Value: BrickColor)
	Allocate(2)
	WriteU16(Value.Number)
end, 2)

Schema.UDim = Define(function()
	return UDim.new(ReadF32(), ReadI32())
end, function(Value: UDim)
	Allocate(8)
	WriteF32(Value.Scale)
	WriteI32(Value.Offset)
end, 8)

Schema.UDim2 = Define(function()
	return UDim2.new(ReadF32(), ReadI32(), ReadF32(), ReadI32())
end, function(Value: UDim2)
	Allocate(16)
	WriteF32(Value.X.Scale)
	WriteI32(Value.X.Offset)
	WriteF32(Value.Y.Scale)
	WriteI32(Value.Y.Offset)
end, 16)

Schema.Rect = Define(function()
	return Rect.new(ReadF32(), ReadF32(), ReadF32(), ReadF32())
end, function(Value: Rect)
	Allocate(16)
	WriteF32(Value.Min.X)
	WriteF32(Value.Min.Y)
	WriteF32(Value.Max.X)
	WriteF32(Value.Max.Y)
end, 16)

Schema.NumberRange = Define(function()
	return NumberRange.new(ReadF32(), ReadF32())
end, function(Value: NumberRange)
	Allocate(8)
	WriteF32(Value.Min)
	WriteF32(Value.Max)
end, 8)

Schema.NumberSequence = Define(ReadNumberSequence, WriteNumberSequence, 1)

Schema.ColorSequence = Define(ReadColorSequence, WriteColorSequence, 1)

Schema.DateTime = Define(function()
	return DateTime.fromUnixTimestampMillis(ReadF64())
end, function(Value: DateTime)
	Allocate(8)
	WriteF64(Value.UnixTimestampMillis)
end, 8)

const AnyReads: { [number]: (Depth: number) -> any } = {}
const AnyWrites: { [string]: (Value: any, Depth: number) -> () } = {}
local EnumsByName: { [string]: Enum }? = nil

const function ReadAnyAt(Depth: number): any
	const Tag = ReadU8()
	const Reader = AnyReads[Tag]

	if Reader == nil then
		error(`[swiftpacket] rejected an unknown value tag {Tag}`, 0)
	end

	return Reader(Depth)
end

const function WriteAnyAt(Value: any, Depth: number)
	const Kind = typeof(Value)
	const Writer = AnyWrites[Kind]

	if Writer == nil then
		WriteFailure(`cannot send a value of type {Kind}`)
	end

	Writer(Value, Depth)
end

const function WriteTag(Tag: number, Bytes: number)
	Allocate(1 + Bytes)
	WriteU8(Tag)
end

const function BuildEnums(): { [string]: Enum }
	const Built: { [string]: Enum } = {}
	const Enums = Enum:GetEnums()

	for Index = 1, #Enums do
		Built[tostring(Enums[Index])] = Enums[Index]
	end

	return Built
end

const function FindEnum(Name: string): Enum
	const Lookup = EnumsByName or BuildEnums()
	EnumsByName = Lookup

	const EnumType = Lookup[Name]

	if EnumType == nil then
		error(`[swiftpacket] rejected an unknown enum type {Name}`, 0)
	end

	return EnumType
end

AnyReads[0] = function()
	return nil
end

AnyWrites["nil"] = function()
	WriteTag(0, 0)
end

AnyReads[1] = function()
	return false
end

AnyReads[2] = function()
	return true
end

AnyWrites.boolean = function(Value: boolean)
	WriteTag(if Value then 2 else 1, 0)
end

AnyReads[3] = ReadU8
AnyReads[4] = ReadU16
AnyReads[5] = ReadU32

AnyReads[6] = function()
	return -ReadU8()
end

AnyReads[7] = function()
	return -ReadU16()
end

AnyReads[8] = function()
	return -ReadU32()
end

AnyReads[9] = ReadF64

AnyWrites.number = function(Value: number)
	if Value % 1 ~= 0 or math.abs(Value) >= 4294967296 then
		WriteTag(9, 8)
		WriteF64(Value)
	elseif Value >= 0 then
		if Value < 256 then
			WriteTag(3, 1)
			WriteU8(Value)
		elseif Value < 65536 then
			WriteTag(4, 2)
			WriteU16(Value)
		else
			WriteTag(5, 4)
			WriteU32(Value)
		end
	else
		const Magnitude = -Value

		if Magnitude < 256 then
			WriteTag(6, 1)
			WriteU8(Magnitude)
		elseif Magnitude < 65536 then
			WriteTag(7, 2)
			WriteU16(Magnitude)
		else
			WriteTag(8, 4)
			WriteU32(Magnitude)
		end
	end
end

const function AnyDatatype(Tag: number, Kind: string, Datatype: Schema)
	const Read, Write = Datatype.Read, Datatype.Write

	AnyReads[Tag] = function()
		return Read()
	end

	AnyWrites[Kind] = function(Value: any)
		WriteTag(Tag, 0)
		Write(Value)
	end
end

AnyDatatype(10, "string", Schema.String)
AnyDatatype(11, "buffer", Schema.Buffer)
AnyDatatype(12, "Instance", Schema.Instance)
AnyDatatype(13, "Vector2", Schema.Vector2)
AnyDatatype(14, "Vector3", Schema.Vector3)
AnyDatatype(15, "CFrame", Schema.CFrame)
AnyDatatype(16, "Color3", Schema.Color3)
AnyDatatype(17, "BrickColor", Schema.BrickColor)
AnyDatatype(18, "UDim", Schema.UDim)
AnyDatatype(19, "UDim2", Schema.UDim2)
AnyDatatype(20, "Rect", Schema.Rect)
AnyDatatype(21, "NumberRange", Schema.NumberRange)
AnyDatatype(22, "NumberSequence", Schema.NumberSequence)
AnyDatatype(23, "ColorSequence", Schema.ColorSequence)
AnyDatatype(24, "DateTime", Schema.DateTime)

AnyReads[25] = function()
	const EnumType = FindEnum(Schema.String.Read())
	const Item = EnumType:FromValue(ReadU16())

	if Item == nil then
		error(`[swiftpacket] rejected an unknown {tostring(EnumType)} value`, 0)
	end

	return Item
end

AnyWrites.EnumItem = function(Value: EnumItem)
	WriteTag(25, 0)
	Schema.String.Write(tostring(Value.EnumType))
	Allocate(2)
	WriteU16(Value.Value)
end

AnyReads[26] = function(Depth: number)
	if Depth >= 16 then
		error("[swiftpacket] table nesting is deeper than 16 levels", 0)
	end

	const Count = ReadVarint()
	CheckCount(Count, 2)

	const Value = {}

	for Index = 1, Count do
		const Key = ReadAnyAt(Depth + 1)
		const Entry = ReadAnyAt(Depth + 1)

		if Key == nil or Key ~= Key then
			error(`[swiftpacket] rejected an invalid key in table entry {Index}`, 0)
		end

		Value[Key] = Entry
	end

	return Value
end

AnyWrites.table = function(Value: { [any]: any }, Depth: number)
	if Depth >= 16 then
		WriteFailure("table nesting is deeper than 16 levels")
	end

	WriteTag(26, 4)
	WriteVarint(CountEntries(Value))

	for Key, Entry in Value do
		WriteAnyAt(Key, Depth + 1)
		WriteAnyAt(Entry, Depth + 1)
	end
end

Schema.Any = Define(function()
	return ReadAnyAt(0)
end, function(Value: any)
	WriteAnyAt(Value, 0)
end, 1)

function Schema.Charset(Characters: string): Schema
	if #Characters < 2 or #Characters > 256 then
		error("[swiftpacket] a charset needs from 2 to 256 characters", 2)
	end

	const Bits = math.ceil(math.log(#Characters, 2))
	const Lookup: { [string]: number } = {}
	const Alphabet: { string } = {}

	for Index = 1, #Characters do
		const Character = string.sub(Characters, Index, Index)

		if Lookup[Character] then
			error(`[swiftpacket] charset repeats the character "{Character}"`, 2)
		end

		Lookup[Character] = Index - 1
		Alphabet[Index] = Character
	end

	return Define(function()
		const Length = ReadVarint()
		const Bytes = math.ceil(Length * Bits / 8)
		CheckLength(Bytes)

		const Output: { string } = {}

		for Index = 1, Length do
			const Character = Alphabet[ReadBits((Index - 1) * Bits, Bits) + 1]

			if Character == nil then
				error("[swiftpacket] rejected a character outside the charset", 0)
			end

			Output[Index] = Character
		end

		Skip(Bytes)

		return table.concat(Output)
	end, function(Value: string)
		const Length = #Value
		const Bytes = math.ceil(Length * Bits / 8)

		Allocate(4 + Bytes)
		WriteVarint(Length)

		for Index = 1, Length do
			const Character = string.sub(Value, Index, Index)
			const Code = Lookup[Character]

			if Code == nil then
				WriteFailure(`"{Character}" is not in the charset`)
			end

			WriteBits((Index - 1) * Bits, Bits, Code)
		end

		Skip(Bytes)
	end, 1)
end

Schema.Characters = Schema.Charset(" .0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")

const function Compile(Parameter: any): Schema
	if Registered[Parameter] then
		return Parameter
	end

	if type(Parameter) ~= "table" then
		error(`[swiftpacket] {tostring(Parameter)} is not a swiftpacket type`, 0)
	end

	if #Parameter == 1 and next(Parameter, 1) == nil then
		return Schema.Array(Parameter[1])
	end

	return Schema.Struct(Parameter)
end

Schema.Compile = Compile

function Schema.Array(Element: any, MaximumLength: number?): Schema
	const Item = Compile(Element)
	const ReadItem, WriteItem = Item.Read, Item.Write
	const ItemSize = Item.MinimumSize

	return Define(function()
		const Length = ReadVarint()
		CheckCount(Length, ItemSize, MaximumLength)

		const Values = {}

		for Index = 1, Length do
			Values[Index] = ReadItem()
		end

		return Values
	end, function(Values: { any })
		const Length = #Values

		if MaximumLength and Length > MaximumLength then
			WriteFailure(`array length {Length} is over the maximum of {MaximumLength}`)
		end

		Allocate(4)
		WriteVarint(Length)

		for Index = 1, Length do
			WriteItem(Values[Index])
		end
	end, 1)
end

function Schema.Map(Key: any, Value: any, MaximumCount: number?): Schema
	const KeySchema, ValueSchema = Compile(Key), Compile(Value)
	const ReadKey, WriteKey = KeySchema.Read, KeySchema.Write
	const ReadValue, WriteValue = ValueSchema.Read, ValueSchema.Write
	const EntrySize = KeySchema.MinimumSize + ValueSchema.MinimumSize

	return Define(function()
		const Count = ReadVarint()
		CheckCount(Count, EntrySize, MaximumCount)

		const Values = {}

		for Index = 1, Count do
			const EntryKey = ReadKey()
			const EntryValue = ReadValue()

			if EntryKey == nil or EntryKey ~= EntryKey then
				error(`[swiftpacket] rejected an invalid key in map entry {Index}`, 0)
			end

			Values[EntryKey] = EntryValue
		end

		return Values
	end, function(Values: { [any]: any })
		const Count = CountEntries(Values)

		if MaximumCount and Count > MaximumCount then
			WriteFailure(`map count {Count} is over the maximum of {MaximumCount}`)
		end

		Allocate(4)
		WriteVarint(Count)

		for EntryKey, EntryValue in Values do
			WriteKey(EntryKey)
			WriteValue(EntryValue)
		end
	end, 1)
end

function Schema.Struct(Shape: { [any]: any }): Schema
	const Keys: { string } = {}

	for Key in Shape do
		if type(Key) ~= "string" then
			error(`[swiftpacket] struct key {tostring(Key)} must be a string`, 0)
		end

		table.insert(Keys, Key)
	end

	table.sort(Keys)

	const Readers: { () -> any } = {}
	const Writers: { (Value: any) -> () } = {}
	local MinimumSize = 0

	for Index, Key in Keys do
		const Field = Compile(Shape[Key])
		Readers[Index] = Field.Read
		Writers[Index] = Field.Write
		MinimumSize += Field.MinimumSize
	end

	return Define(function()
		const Values = {}

		for Index, Reader in Readers do
			Values[Keys[Index]] = Reader()
		end

		return Values
	end, function(Values: { [string]: any })
		for Index, Writer in Writers do
			Writer(Values[Keys[Index]])
		end
	end, MinimumSize)
end

function Schema.Optional(Inner: any): Schema
	const InnerSchema = Compile(Inner)
	const ReadInner, WriteInner = InnerSchema.Read, InnerSchema.Write

	return Define(function()
		if ReadU8() == 0 then
			return nil
		end

		return ReadInner()
	end, function(Value: any)
		Allocate(1)

		if Value == nil then
			WriteU8(0)
		else
			WriteU8(1)
			WriteInner(Value)
		end
	end, 1)
end

function Schema.Static(Values: { any }): Schema
	const Count = #Values

	if Count < 1 or Count > 65536 then
		error("[swiftpacket] a static list needs from 1 to 65536 values", 2)
	end

	const Indices: { [any]: number } = {}

	for Index, Value in Values do
		Indices[Value] = Index - 1
	end

	const Wide = Count > 256

	return Define(function()
		const Value = Values[(if Wide then ReadU16() else ReadU8()) + 1]

		if Value == nil then
			error("[swiftpacket] rejected an index outside the static list", 0)
		end

		return Value
	end, function(Value: any)
		const Index = Indices[Value]

		if Index == nil then
			WriteFailure(`{tostring(Value)} is not in the static list`)
		end

		if Wide then
			Allocate(2)
			WriteU16(Index)
		else
			Allocate(1)
			WriteU8(Index)
		end
	end, if Wide then 2 else 1)
end

function Schema.Flags(Names: { string }): Schema
	const Count = #Names

	if Count < 1 or Count > 64 then
		error("[swiftpacket] flags need from 1 to 64 names", 2)
	end

	const Bytes = math.ceil(Count / 8)

	return Define(function()
		const Values: { [string]: boolean } = {}

		for Index, Name in Names do
			Values[Name] = ReadBits(Index - 1, 1) == 1
		end

		Skip(Bytes)

		return Values
	end, function(Values: { [string]: boolean })
		Allocate(Bytes)

		for Index, Name in Names do
			WriteBits(Index - 1, 1, if Values[Name] then 1 else 0)
		end

		Skip(Bytes)
	end, Bytes)
end

function Schema.Range(Inner: any, Minimum: number, Maximum: number): Schema
	const InnerSchema = Compile(Inner)
	const ReadInner, WriteInner = InnerSchema.Read, InnerSchema.Write

	if Minimum > Maximum then
		error("[swiftpacket] range minimum is larger than its maximum", 2)
	end

	return Define(function()
		const Value = ReadInner()

		if type(Value) ~= "number" or Value < Minimum or Value > Maximum then
			error(`[swiftpacket] rejected {tostring(Value)} outside the range {Minimum} to {Maximum}`, 0)
		end

		return Value
	end, function(Value: number)
		if Value < Minimum or Value > Maximum then
			WriteFailure(`{Value} is outside the range {Minimum} to {Maximum}`)
		end

		WriteInner(Value)
	end, InnerSchema.MinimumSize)
end

function Schema.InstanceOf(ClassName: string): Schema
	return Define(function()
		const Value = ReadInstance()

		if Value and Value:IsA(ClassName) then
			return Value
		end

		return nil
	end, function(Value: Instance?)
		if Value and not Value:IsA(ClassName) then
			WriteFailure(`{Value:GetFullName()} is not a {ClassName}`)
		end

		WriteInstance(Value)
	end, 0)
end

function Schema.EnumItem(EnumType: Enum): Schema
	return Define(function()
		const Item = EnumType:FromValue(ReadU16())

		if Item == nil then
			error(`[swiftpacket] rejected an unknown {tostring(EnumType)} value`, 0)
		end

		return Item
	end, function(Value: EnumItem)
		if Value.EnumType ~= EnumType then
			WriteFailure(`{tostring(Value)} is not a {tostring(EnumType)}`)
		end

		Allocate(2)
		WriteU16(Value.Value)
	end, 2)
end

function Schema.CompileList(Parameters: Arguments): { Schema }
	const Compiled: { Schema } = {}

	for Index = 1, Parameters.n do
		Compiled[Index] = Compile(Parameters[Index])
	end

	return Compiled
end

const function WriteValues(Schemas: { Schema }, ...: any)
	const Count = #Schemas

	if Count == 1 then
		Schemas[1].Write((...))
	elseif Count == 2 then
		const First, Second = ...

		Schemas[1].Write(First)
		Schemas[2].Write(Second)
	elseif Count > 2 then
		const Values = { ... }

		for Index = 1, Count do
			Schemas[Index].Write(Values[Index])
		end
	end
end

function Schema.WriteEvent(Target: Cursor, Id: number, Name: string, Schemas: { Schema }, ...: any)
	Writing = Name
	Import(Target)
	WriteId(Id)
	WriteValues(Schemas, ...)
	Export()
end

function Schema.WriteRequest(Target: Cursor, Id: number, CallIndex: number, Name: string, Schemas: { Schema }, ...: any)
	Writing = Name
	Import(Target)
	WriteId(Id)
	Allocate(2)
	WriteU16(CallIndex)
	WriteValues(Schemas, ...)
	Export()
end

function Schema.WriteBody(Target: Cursor, Name: string, Schemas: { Schema }, ...: any)
	Writing = Name
	Reset(Target)
	Import(Target)
	WriteValues(Schemas, ...)
	Export()
end

function Schema.WriteArguments(Schemas: { Schema }, Values: Arguments, Offset: number, Name: string)
	Writing = Name

	for Index, Definition in Schemas do
		Definition.Write(Values[Index + Offset])
	end
end

const SerializeScratch = NewCursor()

function Schema.Serialize(Name: string, Schemas: { Schema }, ...: any): (buffer, { any }?)
	Schema.WriteBody(SerializeScratch, Name, Schemas, ...)

	const Data, Attached = Take(SerializeScratch)
	Reset(SerializeScratch)

	return Data, Attached
end

function Schema.Deserialize(Schemas: { Schema }, Source: buffer, SourceInstances: { any }): ...any
	Load(Source, SourceInstances, false, 0, 0)

	const Count = #Schemas

	if Count == 1 then
		return Schemas[1].Read()
	elseif Count == 2 then
		const First = Schemas[1].Read()
		const Second = Schemas[2].Read()

		return First, Second
	end

	const Values = table.create(Count)

	for Index = 1, Count do
		Values[Index] = Schemas[Index].Read()
	end

	return table.unpack(Values, 1, Count)
end

Schema.Cursor = CursorLibrary

return Schema
