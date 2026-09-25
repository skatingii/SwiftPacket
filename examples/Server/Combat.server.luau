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

const CombatRules = require("../Rules/Combat")
const Configuration = require("../Network/Configuration")
const Packets = require("../Network/Packets")

const ReadyAt: { [Player]: number } = {}

const function RootOf(Character: Model): BasePart?
	const Root = Character:FindFirstChild("HumanoidRootPart")

	if Root and Root:IsA("BasePart") then
		return Root
	end

	return nil
end

Packets.Hit:SetServerInvoke(function(Player, Target)
	if Target == nil or not Target:IsA("Humanoid") or Target.Health <= 0 then
		return false, 0
	end

	const Character = Player.Character
	const Root = if Character then RootOf(Character) else nil
	const TargetRoot = Target.RootPart

	if Character == nil or Root == nil or TargetRoot == nil or Target:IsDescendantOf(Character) then
		return false, 0
	end

	const Now = os.clock()
	const Distance = (Root.Position - TargetRoot.Position).Magnitude

	if not CombatRules.CanHit(Distance, Now, ReadyAt[Player] or 0, Configuration.Combat.Range) then
		return false, 0
	end

	ReadyAt[Player] = CombatRules.NextReadyAt(Now, Configuration.Combat.Cooldown)
	Target:TakeDamage(Configuration.Combat.Damage)
	Packets.HitEffect:Fire(TargetRoot.Position, Configuration.Combat.Damage)

	return true, Configuration.Combat.Damage
end)

Players.PlayerRemoving:Connect(function(Player)
	ReadyAt[Player] = nil
end)
