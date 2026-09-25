--!nonstrict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const RunService = game:GetService("RunService")

const Client = require("@self/client")
const Configuration = require("@self/configuration")
const Packet = require("@self/packet")
const Schema = require("@self/schema")
const Server = require("@self/server")

export type Options = Configuration.Options

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<A...> = {
	Connect: (self: Signal<A...>, Callback: (A...) -> ()) -> Connection,
	Once: (self: Signal<A...>, Callback: (A...) -> ()) -> Connection,
	Wait: (self: Signal<A...>) -> A...,
	DisconnectAll: (self: Signal<A...>) -> (),
}

export type Request<A..., B...> = {
	Name: string,
	OnServerInvoke: ((Player: Player, A...) -> B...)?,
	OnClientInvoke: ((A...) -> B...)?,
	Fire: (self: Request<A..., B...>, A...) -> B...,
	FireClient: (self: Request<A..., B...>, Player: Player, A...) -> B...,
	SetServerInvoke: (self: Request<A..., B...>, Handler: (Player: Player, A...) -> B...) -> Request<A..., B...>,
	SetClientInvoke: (self: Request<A..., B...>, Handler: (A...) -> B...) -> Request<A..., B...>,
	Timeout: (self: Request<A..., B...>, Seconds: number, B...) -> Request<A..., B...>,
	RateLimit: (self: Request<A..., B...>, Count: number, Interval: number) -> Request<A..., B...>,
	Validate: (self: Request<A..., B...>, Validator: (Player: Player, A...) -> boolean) -> Request<A..., B...>,
	Serialize: (self: Request<A..., B...>, A...) -> (buffer, { Instance }?),
	Deserialize: (self: Request<A..., B...>, Data: buffer, Instances: { Instance }?) -> A...,
}

export type Event<A...> = {
	Name: string,
	OnServerEvent: Signal<(Player, A...)>,
	OnClientEvent: Signal<A...>,
	Fire: (self: Event<A...>, A...) -> (),
	FireClient: (self: Event<A...>, Player: Player, A...) -> (),
	FireClients: (self: Event<A...>, Players: { Player }, A...) -> (),
	FireExcept: (self: Event<A...>, Player: Player, A...) -> (),
	Response: <B...>(self: Event<A...>, B...) -> Request<A..., B...>,
	Unreliable: (self: Event<A...>) -> Event<A...>,
	RateLimit: (self: Event<A...>, Count: number, Interval: number) -> Event<A...>,
	Validate: (self: Event<A...>, Validator: (Player: Player, A...) -> boolean) -> Event<A...>,
	Serialize: (self: Event<A...>, A...) -> (buffer, { Instance }?),
	Deserialize: (self: Event<A...>, Data: buffer, Instances: { Instance }?) -> A...,
}

export type Fields = {
	Version: string,
	Configure: (Options: Options) -> (),

	Any: any,
	Nil: nil,
	Boolean: boolean,

	U8: number,
	U16: number,
	U24: number,
	U32: number,
	I8: number,
	I16: number,
	I24: number,
	I32: number,
	F16: number,
	F24: number,
	F32: number,
	F64: number,

	String: string,
	Characters: string,
	Buffer: buffer,
	Instance: Instance?,

	Vector2: Vector2,
	Vector2F16: Vector2,
	Vector2I16: Vector2,
	Vector3: Vector3,
	Vector3F24: Vector3,
	Vector3F16: Vector3,
	Vector3I16: Vector3,
	CFrame: CFrame,
	CFrameF24: CFrame,

	Color3: Color3,
	BrickColor: BrickColor,
	UDim: UDim,
	UDim2: UDim2,
	Rect: Rect,
	NumberRange: NumberRange,
	NumberSequence: NumberSequence,
	ColorSequence: ColorSequence,
	DateTime: DateTime,

	Array: <T>(Element: T, MaximumLength: number?) -> { T },
	Map: <K, V>(Key: K, Value: V, MaximumCount: number?) -> { [K]: V },
	Struct: <T>(Shape: T) -> T,
	Optional: <T>(Inner: T) -> T?,
	Static: <T>(Values: { T }) -> T,
	Range: (Inner: number, Minimum: number, Maximum: number) -> number,
	Flags: (Names: { string }) -> { [string]: boolean },
	Charset: (Characters: string) -> string,
	InstanceOf: (ClassName: string) -> Instance?,
	EnumItem: (EnumType: Enum) -> EnumItem,
}

export type SwiftPacket = setmetatable<Fields, {
	__call: <A...>(self: Fields, Name: string, A...) -> Event<A...>,
}>

if RunService:IsServer() then
	Server.Start(script)
else
	Client.Start(script)
end

const Library = {
	Version = "0.1.2",
	Configure = Configuration.Configure,

	Any = Schema.Any,
	Nil = Schema.Nil,
	Boolean = Schema.Boolean,

	U8 = Schema.U8,
	U16 = Schema.U16,
	U24 = Schema.U24,
	U32 = Schema.U32,
	I8 = Schema.I8,
	I16 = Schema.I16,
	I24 = Schema.I24,
	I32 = Schema.I32,
	F16 = Schema.F16,
	F24 = Schema.F24,
	F32 = Schema.F32,
	F64 = Schema.F64,

	String = Schema.String,
	Characters = Schema.Characters,
	Buffer = Schema.Buffer,
	Instance = Schema.Instance,

	Vector2 = Schema.Vector2,
	Vector2F16 = Schema.Vector2F16,
	Vector2I16 = Schema.Vector2I16,
	Vector3 = Schema.Vector3,
	Vector3F24 = Schema.Vector3F24,
	Vector3F16 = Schema.Vector3F16,
	Vector3I16 = Schema.Vector3I16,
	CFrame = Schema.CFrame,
	CFrameF24 = Schema.CFrameF24,

	Color3 = Schema.Color3,
	BrickColor = Schema.BrickColor,
	UDim = Schema.UDim,
	UDim2 = Schema.UDim2,
	Rect = Schema.Rect,
	NumberRange = Schema.NumberRange,
	NumberSequence = Schema.NumberSequence,
	ColorSequence = Schema.ColorSequence,
	DateTime = Schema.DateTime,

	Array = Schema.Array,
	Map = Schema.Map,
	Struct = Schema.Struct,
	Optional = Schema.Optional,
	Static = Schema.Static,
	Range = Schema.Range,
	Flags = Schema.Flags,
	Charset = Schema.Charset,
	InstanceOf = Schema.InstanceOf,
	EnumItem = Schema.EnumItem,
}

const SwiftPacket: SwiftPacket = setmetatable(Library, {
	__call = function(Target, Name: string, ...)
		return Packet.New(Name, table.pack(...))
	end,
})

return SwiftPacket
