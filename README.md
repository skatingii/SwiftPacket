# SwiftPacket

[![CI](https://github.com/skatingii/SwiftPacket/actions/workflows/ci.yml/badge.svg)](https://github.com/skatingii/SwiftPacket/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/skatingii/SwiftPacket)](LICENSE)

A fast, fully typed, buffer-batched networking library for Roblox.

Describe each packet once, with the types of the values it carries, then fire it
like a function. SwiftPacket writes every message into one buffer per player,
sends it once per frame, and checks everything a client sends before your code
sees it.

- **Typed**: `Fire()`, handlers and responses are checked by the Luau type
  checker, without a single cast.
- **Small**: every value is written in the fewest bytes its type allows, with no
  type tags on the wire.
- **Batched**: one remote call per player per frame, for reliable and unreliable
  packets.
- **Ordered**: messages to a player arrive in the order they were fired, events
  and requests alike.
- **Hardened**: bounds checks, rejection of NaN and infinity, a per-player byte
  budget, rate limits and validators.

## Installation

With [Wally](https://wally.run), add SwiftPacket to your `wally.toml`:

```toml
[dependencies]
SwiftPacket = "skatingii/swiftpacket@0.1.3"
```

Or download `SwiftPacket.rbxm` from the
[latest release](https://github.com/skatingii/SwiftPacket/releases/latest) and put
it in `ReplicatedStorage`.

## Example

Define your packets in one module that both the server and the client require:

```luau
const SwiftPacket = require("@game/ReplicatedStorage/Packages/SwiftPacket")

return {
    Chat = SwiftPacket("Chat", SwiftPacket.String):RateLimit(5, 1),
    Move = SwiftPacket("Move", SwiftPacket.Vector3F24):Unreliable(),
    GetCoins = SwiftPacket("GetCoins"):Response(SwiftPacket.U32),
    Inventory = SwiftPacket("Inventory", {
        Coins = SwiftPacket.U32,
        Items = { SwiftPacket.String },
    }),
}
```

On the server:

```luau
const Packets = require("@game/ReplicatedStorage/Packets")

Packets.Chat.OnServerEvent:Connect(function(Player, Message)
    Packets.Chat:FireExcept(Player, `{Player.Name}: {Message}`)
end)

Packets.GetCoins:SetServerInvoke(function(Player)
    return 100
end)
```

On the client:

```luau
const Packets = require("@game/ReplicatedStorage/Packets")

Packets.Chat:Fire("hello")

const Coins = Packets.GetCoins:Fire()
```

## Documentation

- [Crash course](docs/tut/crash-course/1-introduction.md): packets, events,
  requests, types and security, one page each.
- [API reference](docs/api/swiftpacket.md): every function and type.
- [Migrating from Packet](docs/tut/crash-course/8-migrating-from-packet.md):
  what changes if you are coming from Packet.

## Security

Please do not report a vulnerability in a public issue. See
[SECURITY.md](SECURITY.md) for how to report one privately.

---

SwiftPacket is released under the [MIT License](LICENSE) by
[skaterstudios](https://skaterstudios.com).
