--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const SwiftPacket = require("../../../src")

const Damage = SwiftPacket("Damage", SwiftPacket.U16, SwiftPacket.String)
Damage:Fire("ten", "reason")
