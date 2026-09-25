--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Players = game:GetService("Players")

const Configuration = require("../Network/Configuration")
const InventoryRules = require("../Rules/Inventory")
const Packets = require("../Network/Packets")

const Inventories: { [Player]: Packets.Inventory } = {}

const function Load(Player: Player)
	const Inventory: Packets.Inventory = {
		Coins = Configuration.Inventory.StartingCoins,
		Items = table.clone(Configuration.Inventory.StartingItems),
	}

	Inventories[Player] = Inventory
	Packets.Inventory:FireClient(Player, Inventory)

	const SaveData = Packets.Inventory:Serialize(Inventory)
	print(`[inventory] {Player.Name}'s save data is {buffer.len(SaveData)} bytes, ready for a DataStore`)

	const Quality = Packets.GetQuality:FireClient(Player)
	print(`[inventory] {Player.Name} plays on {Quality} graphics`)
end

Packets.Equip:SetServerInvoke(function(Player, Item)
	const Inventory = Inventories[Player]

	if Inventory == nil or not InventoryRules.CanEquip(Inventory.Items, Item) then
		return false
	end

	Inventory.Equipped = Item
	Packets.Inventory:FireClient(Player, Inventory)

	return true
end)

Players.PlayerAdded:Connect(Load)

Players.PlayerRemoving:Connect(function(Player)
	Inventories[Player] = nil
end)

for Index, Player in Players:GetPlayers() do
	task.spawn(Load, Player)
end
