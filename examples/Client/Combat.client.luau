--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Debris = game:GetService("Debris")
const Players = game:GetService("Players")
const UserInputService = game:GetService("UserInputService")

const Configuration = require("../Network/Configuration")
const Packets = require("../Network/Packets")

const LocalPlayer = Players.LocalPlayer
const Mouse = LocalPlayer:GetMouse()

const function HumanoidUnderMouse(): Humanoid?
	const Target = Mouse.Target
	const Model = if Target then Target:FindFirstAncestorOfClass("Model") else nil

	if Model == nil then
		return nil
	end

	return Model:FindFirstChildOfClass("Humanoid")
end

const function Flash(Position: Vector3)
	const Part = Instance.new("Part")
	Part.Shape = Enum.PartType.Ball
	Part.Size = Vector3.one * 2
	Part.Material = Enum.Material.Neon
	Part.Color = Color3.fromRGB(255, 80, 80)
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CastShadow = false
	Part.Position = Position
	Part.Parent = workspace

	Debris:AddItem(Part, Configuration.Combat.FlashSeconds)
end

Packets.HitEffect.OnClientEvent:Connect(function(Position, Damage)
	Flash(Position)
end)

UserInputService.InputBegan:Connect(function(Input: InputObject, Processed: boolean)
	if Processed or Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	const Target = HumanoidUnderMouse()

	if Target == nil then
		return
	end

	const Landed, Damage = Packets.Hit:Fire(Target)

	print(if Landed then `[combat] hit for {Damage}` else "[combat] missed, out of range or on cooldown")
end)
