import SwiftPacket from "@skating/swiftpacket";

const Item = SwiftPacket.Static(["Sword", "Shield", "Potion", "Bow"]);

const Inventory = SwiftPacket.Struct({
	Coins: SwiftPacket.U32,
	Equipped: SwiftPacket.Optional(Item),
	Items: SwiftPacket.Map(Item, SwiftPacket.U16, 64),
});

const Cursor = SwiftPacket.Struct({
	Player: SwiftPacket.InstanceOf("Player"),
	Position: SwiftPacket.Vector3F24,
});

export type Inventory = typeof Inventory;

export const Packets = {
	Chat: SwiftPacket("Chat", SwiftPacket.String).RateLimit(5, 10),
	ChatMessage: SwiftPacket("ChatMessage", SwiftPacket.InstanceOf("Player"), SwiftPacket.String),
	Hit: SwiftPacket("Hit", SwiftPacket.InstanceOf("Humanoid"))
		.Response(SwiftPacket.Boolean, SwiftPacket.U16)
		.Timeout(2, false, 0),
	Cursors: SwiftPacket("Cursors", SwiftPacket.Array(Cursor, 80)).Unreliable(),
	Inventory: SwiftPacket("Inventory", Inventory),
	Equip: SwiftPacket("Equip", Item).Response(SwiftPacket.Boolean),
	GetQuality: SwiftPacket("GetQuality")
		.Response(SwiftPacket.Static(["Low", "Medium", "High"]))
		.Timeout(5, "Medium"),
	Material: SwiftPacket("Material", SwiftPacket.EnumItem(Enum.Material)),
	Settings: SwiftPacket("Settings", SwiftPacket.Flags(["Music", "Effects"])),
	Ping: SwiftPacket("Ping"),
};

SwiftPacket.Configure({ Logging: true });
