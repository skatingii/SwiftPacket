--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const SwiftPacket = require("@self/src")

export type Options = SwiftPacket.Options
export type Connection = SwiftPacket.Connection
export type Signal<A...> = SwiftPacket.Signal<A...>
export type Request<A..., B...> = SwiftPacket.Request<A..., B...>
export type Event<A...> = SwiftPacket.Event<A...>
export type Fields = SwiftPacket.Fields
export type SwiftPacket = SwiftPacket.SwiftPacket

return SwiftPacket
