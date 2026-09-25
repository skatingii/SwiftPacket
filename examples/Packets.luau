--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const SwiftPacket = require("../src")

return {
	Chat = SwiftPacket("Chat", SwiftPacket.String),
	Damage = SwiftPacket("Damage", SwiftPacket.U16, SwiftPacket.InstanceOf("Humanoid")):RateLimit(20, 1),
	Move = SwiftPacket("Move", SwiftPacket.Vector3F24):Unreliable(),
	GetCoins = SwiftPacket("GetCoins"):Response(SwiftPacket.U32),
	Inventory = SwiftPacket("Inventory", {
		Coins = SwiftPacket.U32,
		Items = { SwiftPacket.String },
	}),
}
