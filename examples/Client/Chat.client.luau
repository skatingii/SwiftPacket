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
const UserInputService = game:GetService("UserInputService")

const Packets = require("../Network/Packets")

const LocalPlayer = Players.LocalPlayer

Packets.ChatMessage.OnClientEvent:Connect(function(Sender, Message)
	const Name = if Sender and Sender:IsA("Player") then Sender.DisplayName else "someone who left"

	print(`[chat] {Name}: {Message}`)
end)

UserInputService.InputBegan:Connect(function(Input: InputObject, Processed: boolean)
	if Processed or Input.KeyCode ~= Enum.KeyCode.G then
		return
	end

	Packets.Chat:Fire(`hello from {LocalPlayer.DisplayName}`)
end)
