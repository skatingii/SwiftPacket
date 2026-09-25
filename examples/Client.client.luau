--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const RunService = game:GetService("RunService")

const Packets = require("./Packets")

Packets.Chat.OnClientEvent:Connect(function(Message)
	print(Message)
end)

Packets.Inventory.OnClientEvent:Connect(function(Data)
	print(`{Data.Coins} coins, {#Data.Items} items`)
end)

Packets.Chat:Fire("hello from the client")
print(`the server says we have {Packets.GetCoins:Fire()} coins`)

RunService.Heartbeat:Connect(function()
	const Camera = workspace.CurrentCamera

	if Camera then
		Packets.Move:Fire(Camera.CFrame.Position)
	end
end)
