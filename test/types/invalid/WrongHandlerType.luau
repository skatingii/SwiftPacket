--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const SwiftPacket = require("../../../src")

const Damage = SwiftPacket("Damage", SwiftPacket.U16)

Damage.OnServerEvent:Connect(function(Player, Amount)
	const Text: string = Amount

	print(Player, Text)
end)
