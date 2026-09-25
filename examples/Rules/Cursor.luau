--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Cursor = {}

function Cursor.IsReasonable(Distance: number, MaximumDistance: number): boolean
	return Distance <= MaximumDistance
end

function Cursor.HasMoved(Previous: Vector3?, Current: Vector3, MinimumMove: number): boolean
	return Previous == nil or (Current - Previous).Magnitude >= MinimumMove
end

return Cursor
