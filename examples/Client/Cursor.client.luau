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

const LocalPlayer = Players.LocalPlayer
const Mouse = LocalPlayer:GetMouse()
const Markers: { [Player]: BasePart } = {}

local Elapsed = 0
local LastSent: Vector3? = nil

const function MarkerFor(Player: Player): BasePart
	const Existing = Markers[Player]

	if Existing then
		return Existing
	end

	const Marker = Instance.new("Part")
	Marker.Name = `{Player.Name}Cursor`
	Marker.Shape = Enum.PartType.Ball
	Marker.Size = Vector3.one * Configuration.Cursor.MarkerSize
	Marker.Material = Enum.Material.Neon
	Marker.Color = Color3.fromHSV(Player.UserId % 360 / 360, 0.8, 1)
	Marker.Anchored = true
	Marker.CanCollide = false
	Marker.CanQuery = false
	Marker.CastShadow = false
	Marker.Parent = workspace

	Markers[Player] = Marker

	return Marker
end

Packets.Cursors.OnClientEvent:Connect(function(Cursors)
	for Index, Cursor in Cursors do
		const Player = Cursor.Player

		if Player and Player:IsA("Player") and Player ~= LocalPlayer then
			MarkerFor(Player).Position = Cursor.Position
		end
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	const Marker = Markers[Player]

	if Marker then
		Marker:Destroy()
		Markers[Player] = nil
	end
end)

RunService.Heartbeat:Connect(function(DeltaTime: number)
	Elapsed += DeltaTime

	if Elapsed < Configuration.Cursor.SendInterval then
		return
	end

	Elapsed = 0

	const Character = LocalPlayer.Character

	if Character == nil then
		return
	end

	const Position = Mouse.Hit.Position
	const Distance = (Character:GetPivot().Position - Position).Magnitude

	if not CursorRules.IsReasonable(Distance, Configuration.Cursor.MaximumDistance) then
		return
	end

	if CursorRules.HasMoved(LastSent, Position, Configuration.Cursor.MinimumMove) then
		LastSent = Position
		Packets.CursorMove:Fire(Position)
	end
end)
