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

const SwiftPacket = require("../../src")

const Damage = SwiftPacket("Damage", SwiftPacket.U16, SwiftPacket.InstanceOf("BasePart"))

Damage.OnServerEvent:Connect(function(Player, Amount, Part)
	const Total: number = Amount + 1
	const Name: string = Player.Name

	if Part then
		print(Total, Name, Part:GetFullName())
	end
end)

Damage:Fire(25, workspace)

const Inventory = SwiftPacket("Inventory", {
	Coins = SwiftPacket.U32,
	Items = { SwiftPacket.String },
	Equipped = SwiftPacket.Optional(SwiftPacket.String),
	Stats = SwiftPacket.Map(SwiftPacket.String, SwiftPacket.F32),
})

Inventory.OnClientEvent:Connect(function(Data)
	const Coins: number = Data.Coins
	const First: string = Data.Items[1]
	const Equipped: string? = Data.Equipped

	print(Coins, First, Equipped, Data.Stats.Speed)
end)

Inventory:FireClient(Players.LocalPlayer, {
	Coins = 10,
	Items = { "Sword" },
	Equipped = nil,
	Stats = { Speed = 16 },
})

const Move =
	SwiftPacket("Move", SwiftPacket.Vector3F24, SwiftPacket.Range(SwiftPacket.U8, 0, 100)):Unreliable():RateLimit(30, 1)
Move:Fire(Vector3.zero, 50)

const GetLevel =
	SwiftPacket("GetLevel", SwiftPacket.String):Response(SwiftPacket.U8, SwiftPacket.Boolean):Timeout(5, 0, false)

GetLevel:SetServerInvoke(function(Player, Key)
	return #Key + Player.UserId % 10, true
end)

const Level, Found = GetLevel:Fire("Hero")
const LevelNumber: number = Level
const FoundBoolean: boolean = Found

print(LevelNumber, FoundBoolean)

const Mode = SwiftPacket("Mode", SwiftPacket.Static({ "Idle", "Walk", "Run" }), SwiftPacket.EnumItem(Enum.KeyCode))
Mode:Fire("Walk", Enum.KeyCode.W)

SwiftPacket.Configure({ Logging = true, IncomingBytesPerSecond = 32000 })

const Data, Instances = Damage:Serialize(10, nil)
const Amount, Part = Damage:Deserialize(Data, Instances)
const AmountNumber: number = Amount

print(AmountNumber, Part)
