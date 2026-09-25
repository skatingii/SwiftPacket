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

export type Options = {
	Logging: boolean?,
	IncomingBytesPerSecond: number?,
	UnreliableByteLimit: number?,
}

const Configuration = {
	Logging = RunService:IsStudio(),
	IncomingBytesPerSecond = 64000,
	UnreliableByteLimit = 900,
	FlushRate = 1 / 60,
	MessageCost = 8,
	HoldSeconds = 10,
	CallCapacity = 32768,
}

const OptionTypes: { [string]: string } = {
	Logging = "boolean",
	IncomingBytesPerSecond = "number",
	UnreliableByteLimit = "number",
}

function Configuration.Configure(Options: { [string]: any })
	for Key, Value in Options do
		const Expected = OptionTypes[Key]

		if Expected == nil then
			error(`[swiftpacket] unknown option {Key}`, 2)
		end

		if type(Value) ~= Expected then
			error(`[swiftpacket] option {Key} must be a {Expected}, got {typeof(Value)}`, 2)
		end
	end

	const Logging = Options.Logging
	const IncomingBytesPerSecond = Options.IncomingBytesPerSecond
	const UnreliableByteLimit = Options.UnreliableByteLimit

	if Logging ~= nil then
		Configuration.Logging = Logging
	end

	if IncomingBytesPerSecond ~= nil then
		Configuration.IncomingBytesPerSecond = math.max(IncomingBytesPerSecond, 1000)
	end

	if UnreliableByteLimit ~= nil then
		Configuration.UnreliableByteLimit = math.clamp(UnreliableByteLimit, 64, 900)
	end
end

function Configuration.Warn(Message: string)
	if Configuration.Logging then
		warn(Message)
	end
end

return Configuration
