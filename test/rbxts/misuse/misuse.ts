import { Packets } from "shared/packets";

// @ts-expect-error
Packets.Chat.Fire(5);
// @ts-expect-error
Packets.Equip.Fire("Axe");
// @ts-expect-error
Packets.Hit.SetServerInvoke(() => $tuple("yes", 0));
// @ts-expect-error
const wrong: string = Packets.Equip.Fire("Sword");
// @ts-expect-error
Packets.Inventory.Fire({ Coins: "many", Items: new Map() });
// @ts-expect-error
Packets.Material.Fire(Enum.KeyCode.A);
// @ts-expect-error
Packets.GetQuality.Timeout(5, "Ultra");
// @ts-expect-error
Packets.Chat.OnServerEvent.Connect((player, message: number) => {});
// @ts-expect-error
Packets.Ping.Fire(1);

export = wrong;
