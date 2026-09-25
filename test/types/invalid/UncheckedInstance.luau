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

const Hit = SwiftPacket("Hit", SwiftPacket.Instance)

Hit.OnServerEvent:Connect(function(Player, Target)
	print(Player, Target.Name)
end)
