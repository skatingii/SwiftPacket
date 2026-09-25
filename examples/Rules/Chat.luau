--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Chat = {}

function Chat.Clean(Message: string): string
	const Trimmed = string.match(Message, "^%s*(.-)%s*$")

	return Trimmed or ""
end

function Chat.IsAllowed(Message: string, MaximumLength: number): boolean
	const Length = utf8.len(Message)

	if Length == nil or Length == 0 or Length > MaximumLength then
		return false
	end

	return string.find(Message, "%c") == nil
end

return Chat
