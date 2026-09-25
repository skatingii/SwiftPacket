--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const SwiftPacket = require("../../../src")

const GetLevel = SwiftPacket("GetLevel", SwiftPacket.String):Response(SwiftPacket.U8)

GetLevel:SetServerInvoke(function(Player, Key)
	const Wrong: number = Key

	return Wrong
end)
