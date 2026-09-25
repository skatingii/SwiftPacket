--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Players = game:GetService("Players")

const Packets = require("./Packets")

Packets.Chat.OnServerEvent:Connect(function(Player, Message)
	Packets.Chat:FireExcept(Player, `{Player.Name}: {Message}`)
end)

Packets.Damage.OnServerEvent:Connect(function(Player, Amount, Humanoid)
	if Humanoid and Humanoid:IsA("Humanoid") then
		Humanoid:TakeDamage(math.min(Amount, 50))
	end
end)

Packets.GetCoins:SetServerInvoke(function(Player)
	return Player.UserId % 1000
end)

Players.PlayerAdded:Connect(function(Player)
	Packets.Inventory:FireClient(Player, {
		Coins = 100,
		Items = { "Sword", "Shield" },
	})
end)
