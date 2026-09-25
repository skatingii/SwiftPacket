--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Configuration = require("./Configuration")
const SwiftPacket = require("../../src")

const Item = SwiftPacket.Static({ "Sword", "Shield", "Potion", "Bow" })
const Quality = SwiftPacket.Static({ "Low", "Medium", "High" })

const Inventory = SwiftPacket.Struct({
	Coins = SwiftPacket.U32,
	Equipped = SwiftPacket.Optional(Item),
	Items = SwiftPacket.Map(Item, SwiftPacket.U16, Configuration.Inventory.MaximumKinds),
})

const Cursor = SwiftPacket.Struct({
	Player = SwiftPacket.InstanceOf("Player"),
	Position = SwiftPacket.Vector3F24,
})

export type Inventory = typeof(Inventory)
export type Cursor = typeof(Cursor)

return {
	Chat = SwiftPacket("Chat", SwiftPacket.String):RateLimit(
		Configuration.Chat.RateCount,
		Configuration.Chat.RateInterval
	),
	ChatMessage = SwiftPacket("ChatMessage", SwiftPacket.InstanceOf("Player"), SwiftPacket.String),

	Hit = SwiftPacket("Hit", SwiftPacket.InstanceOf("Humanoid"))
		:Response(SwiftPacket.Boolean, SwiftPacket.U16)
		:Timeout(2, false, 0)
		:RateLimit(Configuration.Combat.RateCount, Configuration.Combat.RateInterval),
	HitEffect = SwiftPacket("HitEffect", SwiftPacket.Vector3F24, SwiftPacket.U16),

	CursorMove = SwiftPacket("CursorMove", SwiftPacket.Vector3F24)
		:Unreliable()
		:RateLimit(Configuration.Cursor.RateCount, Configuration.Cursor.RateInterval),
	Cursors = SwiftPacket("Cursors", SwiftPacket.Array(Cursor, Configuration.Cursor.MaximumPlayers)):Unreliable(),

	Inventory = SwiftPacket("Inventory", Inventory),
	Equip = SwiftPacket("Equip", Item):Response(SwiftPacket.Boolean),
	GetQuality = SwiftPacket("GetQuality"):Response(Quality):Timeout(Configuration.Inventory.QualityTimeout, "Medium"),
}
