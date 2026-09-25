--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const TextService = game:GetService("TextService")

const ChatRules = require("../Rules/Chat")
const Configuration = require("../Network/Configuration")
const Packets = require("../Network/Packets")

const function Filter(Player: Player, Message: string): string?
	const Ok, Result = pcall(function(): string
		return TextService:FilterStringAsync(Message, Player.UserId):GetNonChatStringForBroadcastAsync()
	end)

	if not Ok then
		warn(`[chat] could not filter a message from {Player.Name}: {Result}`)

		return nil
	end

	return Result
end

Packets.Chat:Validate(function(Player, Message)
	return ChatRules.IsAllowed(ChatRules.Clean(Message), Configuration.Chat.MaximumLength)
end)

Packets.Chat.OnServerEvent:Connect(function(Player, Message)
	const Filtered = Filter(Player, ChatRules.Clean(Message))

	if Filtered then
		Packets.ChatMessage:Fire(Player, Filtered)
	end
end)
