--!strict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Schema = require("./schema")
const Signal = require("./signal")

export type Definition = {
	Name: string,
	Id: number?,
	Arguments: { Schema.Schema },
	Responses: { Schema.Schema }?,
	TimeoutSeconds: number,
	TimeoutValues: Schema.Arguments,
	Reliable: boolean,
	RateLimitCount: number?,
	RateLimitInterval: number?,
	Validator: ((Player, ...any) -> boolean)?,
	OnServerEvent: Signal.Signal,
	OnClientEvent: Signal.Signal,
	OnServerInvoke: ((Player, ...any) -> ...any)?,
	OnClientInvoke: ((...any) -> ...any)?,
}

const ById: { [number]: Definition } = {}

const Registry = {
	ById = ById,
}

return Registry
