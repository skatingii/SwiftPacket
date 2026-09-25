--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const StartingItems: { [string]: number } = {
	Sword = 1,
	Potion = 3,
}

return {
	Chat = {
		MaximumLength = 200,
		RateCount = 5,
		RateInterval = 10,
	},

	Combat = {
		Range = 12,
		Cooldown = 0.5,
		Damage = 10,
		RateCount = 10,
		RateInterval = 1,
		FlashSeconds = 0.25,
	},

	Cursor = {
		SendInterval = 1 / 15,
		BroadcastInterval = 1 / 10,
		MinimumMove = 0.1,
		MaximumDistance = 500,
		MaximumPlayers = 80,
		RateCount = 30,
		RateInterval = 1,
		MarkerSize = 0.6,
	},

	Inventory = {
		StartingCoins = 250,
		StartingItems = StartingItems,
		MaximumKinds = 64,
		QualityTimeout = 5,
	},
}
