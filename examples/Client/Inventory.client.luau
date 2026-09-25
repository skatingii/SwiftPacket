--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const UserInputService = game:GetService("UserInputService")

const InventoryRules = require("../Rules/Inventory")
const Packets = require("../Network/Packets")

const Hotbar: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.One] = "Sword",
	[Enum.KeyCode.Two] = "Shield",
	[Enum.KeyCode.Three] = "Potion",
	[Enum.KeyCode.Four] = "Bow",
}

Packets.Inventory.OnClientEvent:Connect(function(Inventory)
	const Owned: { string } = {}

	for Item, Count in Inventory.Items do
		table.insert(Owned, `{Count}x {Item}`)
	end

	table.sort(Owned)
	print(
		`[inventory] {Inventory.Coins} coins, {table.concat(Owned, ", ")}, equipped {Inventory.Equipped or "nothing"}`
	)
end)

Packets.GetQuality:SetClientInvoke(function()
	const Settings = UserSettings():GetService("UserGameSettings")

	return InventoryRules.QualityName(Settings.SavedQualityLevel.Value)
end)

UserInputService.InputBegan:Connect(function(Input: InputObject, Processed: boolean)
	const Item = Hotbar[Input.KeyCode]

	if Processed or Item == nil then
		return
	end

	if not Packets.Equip:Fire(Item) then
		print(`[inventory] you do not own a {Item}`)
	end
end)
