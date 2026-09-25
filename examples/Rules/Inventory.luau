--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Inventory = {}

function Inventory.CanEquip(Items: { [string]: number }, Item: string): boolean
	const Count = Items[Item]

	return Count ~= nil and Count > 0
end

function Inventory.QualityName(Level: number): string
	if Level == 0 then
		return "Medium"
	elseif Level <= 3 then
		return "Low"
	elseif Level <= 7 then
		return "Medium"
	end

	return "High"
end

return Inventory
