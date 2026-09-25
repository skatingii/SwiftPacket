--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Combat = {}

function Combat.CanHit(Distance: number, Now: number, ReadyAt: number, Range: number): boolean
	return Distance <= Range and Now >= ReadyAt
end

function Combat.NextReadyAt(Now: number, Cooldown: number): number
	return Now + Cooldown
end

return Combat
