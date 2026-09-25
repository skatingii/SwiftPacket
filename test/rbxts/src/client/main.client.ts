import { Players } from "@rbxts/services";
import { Packets } from "shared/packets";

Packets.ChatMessage.OnClientEvent.Connect((sender, message) => {
	print(`${sender?.DisplayName ?? "someone"}: ${message}`);
});

Packets.Chat.Fire("hello");
Packets.Ping.Fire();

const [landed, damage] = Packets.Hit.Fire(Players.LocalPlayer.Character?.FindFirstChildOfClass("Humanoid"));
const equipped: boolean = Packets.Equip.Fire("Sword");

Packets.GetQuality.SetClientInvoke(() => "High");

Packets.Cursors.OnClientEvent.Connect((cursors) => {
	for (const cursor of cursors) {
		print(cursor.Player?.Name, cursor.Position.X);
	}
});

Packets.Inventory.OnClientEvent.Connect((inventory) => {
	print(inventory.Coins, inventory.Equipped ?? "nothing", inventory.Items.get("Sword"));
});

Packets.Material.Fire(Enum.Material.Plastic);
Packets.Settings.Fire({ Music: true, Effects: false });

print(landed, damage, equipped);
