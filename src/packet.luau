--!strict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const RunService = game:GetService("RunService")

const Client = require("./client")
const Registry = require("./registry")
const Schema = require("./schema")
const Server = require("./server")
const Signal = require("./signal")

const IsServer = RunService:IsServer()

const Packet = {}
Packet.__index = Packet

export type Packet = setmetatable<Registry.Definition, typeof(Packet)>

const Packets: { [string]: Packet } = {}
const NoInstances: { any } = {}

const function RequireServer(self: Packet, Method: string)
	if not IsServer then
		error(`[swiftpacket] {Method} on {self.Name} can only be called on the server`, 3)
	end
end

const function RequireEvent(self: Packet, Method: string)
	if self.Responses then
		error(`[swiftpacket] {self.Name} expects a response, so {Method} cannot be used with it`, 3)
	end
end

function Packet.New(Name: string, Parameters: Schema.Arguments): Packet
	if #Name > 100 or string.match(Name, "^[%a_][%w_]*$") == nil or string.sub(Name, 1, 3) == "RBX" then
		error(`[swiftpacket] "{Name}" is not a valid packet name, use letters, digits and underscores`, 3)
	end

	const Existing = Packets[Name]

	if Existing then
		return Existing
	end

	const State: Registry.Definition = {
		Name = Name,
		Arguments = Schema.CompileList(Parameters),
		TimeoutSeconds = 10,
		TimeoutValues = { n = 0 },
		Reliable = true,
		OnServerEvent = Signal.New(),
		OnClientEvent = Signal.New(),
	}

	const self: Packet = setmetatable(State, Packet)
	Packets[Name] = self

	if IsServer then
		Server.Register(self)
	else
		Client.Register(self)
	end

	return self
end

function Packet.Fire(self: Packet, ...: any): ...any
	if IsServer then
		RequireEvent(self, "Fire")
		Server.Broadcast(self, nil, ...)

		return
	end

	if self.Responses then
		return Client.Invoke(self, ...)
	end

	Client.Send(self, ...)

	return
end

function Packet.FireClient(self: Packet, Player: Player, ...: any): ...any
	RequireServer(self, "FireClient")

	if self.Responses then
		return Server.Invoke(Player, self, ...)
	end

	Server.SendTo(Player, self, ...)

	return
end

function Packet.FireClients(self: Packet, Recipients: { Player }, ...: any)
	RequireServer(self, "FireClients")
	RequireEvent(self, "FireClients")
	Server.SendMany(Recipients, nil, self, ...)
end

function Packet.FireExcept(self: Packet, Excluded: Player, ...: any)
	RequireServer(self, "FireExcept")
	RequireEvent(self, "FireExcept")
	Server.Broadcast(self, Excluded, ...)
end

function Packet.Response(self: Packet, ...: any): Packet
	if not self.Reliable then
		error(`[swiftpacket] {self.Name} is unreliable and cannot expect a response`, 2)
	end

	self.Responses = Schema.CompileList(table.pack(...))

	return self
end

function Packet.Timeout(self: Packet, Seconds: number, ...: any): Packet
	if Seconds <= 0 then
		error(`[swiftpacket] timeout for {self.Name} must be above zero`, 2)
	end

	self.TimeoutSeconds = Seconds
	self.TimeoutValues = table.pack(...)

	return self
end

function Packet.Unreliable(self: Packet): Packet
	if self.Responses then
		error(`[swiftpacket] {self.Name} expects a response and cannot be unreliable`, 2)
	end

	self.Reliable = false

	return self
end

function Packet.RateLimit(self: Packet, Count: number, Interval: number): Packet
	if Count < 1 or Interval <= 0 then
		error(`[swiftpacket] rate limit for {self.Name} needs a count of at least 1 and an interval above zero`, 2)
	end

	self.RateLimitCount = Count
	self.RateLimitInterval = Interval

	return self
end

function Packet.Validate(self: Packet, Validator: (Player, ...any) -> boolean): Packet
	self.Validator = Validator

	return self
end

function Packet.SetServerInvoke(self: Packet, Handler: (Player, ...any) -> ...any): Packet
	self.OnServerInvoke = Handler

	return self
end

function Packet.SetClientInvoke(self: Packet, Handler: (...any) -> ...any): Packet
	self.OnClientInvoke = Handler

	return self
end

function Packet.Serialize(self: Packet, ...: any): (buffer, { any }?)
	return Schema.Serialize(self.Name, self.Arguments, ...)
end

function Packet.Deserialize(self: Packet, Source: buffer, Instances: { any }?): ...any
	return Schema.Deserialize(self.Arguments, Source, Instances or NoInstances)
end

return Packet
