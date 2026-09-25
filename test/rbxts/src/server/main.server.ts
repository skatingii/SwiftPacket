import { Players } from "@rbxts/services";
import { Inventory, Packets } from "shared/packets";

Packets.Chat.Validate((player, message) => message.size() <= 200);

Packets.Chat.OnServerEvent.Connect((player, message) => {
	Packets.ChatMessage.Fire(player, message);
});

Packets.Hit.SetServerInvoke((player, target) => {
	if (target === undefined) {
		return $tuple(false, 0);
	}

	target.TakeDamage(10);

	return $tuple(true, 10);
});

Packets.Equip.SetServerInvoke((player, item) => item !== "Bow");

Packets.Ping.OnServerEvent.Connect((player) => print(player.Name));

Players.PlayerAdded.Connect((player) => {
	const inventory: Inventory = { Coins: 250, Items: new Map([["Sword", 1]]) };

	Packets.Inventory.FireClient(player, inventory);

	const [data] = Packets.Inventory.Serialize(inventory);
	const loaded = Packets.Inventory.Deserialize(data);
	const coins: number = loaded.Coins;

	const quality = Packets.GetQuality.FireClient(player);
	const known: "Low" | "Medium" | "High" = quality;

	print(coins, known, buffer.len(data));
});
