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
const RunService = game:GetService("RunService")

const Configuration = require("../Network/Configuration")
const CursorRules = require("../Rules/Cursor")
const Packets = require("../Network/Packets")

const Positions: { [Player]: Vector3 } = {}

local Elapsed = 0

Packets.CursorMove:Validate(function(Player, Position)
	const Character = Player.Character

	if Character == nil then
		return false
	end

	return CursorRules.IsReasonable(
		(Character:GetPivot().Position - Position).Magnitude,
		Configuration.Cursor.MaximumDistance
	)
end)

Packets.CursorMove.OnServerEvent:Connect(function(Player, Position)
	Positions[Player] = Position
end)

Players.PlayerRemoving:Connect(function(Player)
	Positions[Player] = nil
end)

RunService.Heartbeat:Connect(function(DeltaTime: number)
	Elapsed += DeltaTime

	if Elapsed < Configuration.Cursor.BroadcastInterval then
		return
	end

	Elapsed = 0

	const Snapshot: { Packets.Cursor } = {}

	for Player, Position in Positions do
		if #Snapshot >= Configuration.Cursor.MaximumPlayers then
			break
		end

		table.insert(Snapshot, { Player = Player, Position = Position })
	end

	if #Snapshot > 0 then
		Packets.Cursors:Fire(Snapshot)
	end
end)
