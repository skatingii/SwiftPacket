# Defining packets

A packet is defined by calling SwiftPacket with a name and the types of its
arguments:

```luau
const Chat = SwiftPacket("Chat", SwiftPacket.String)
const Damage = SwiftPacket("Damage", SwiftPacket.U16, SwiftPacket.InstanceOf("Humanoid"))
const Ping = SwiftPacket("Ping")
```

The type checker reads those arguments, so `Damage:Fire("ten", Humanoid)` is a
type error and a handler for `Damage` receives a `number` and an `Instance?`.

## One shared module

The server and the client must define the same packets with the same types.
The simplest way to guarantee that is to put every definition in one
ModuleScript in `ReplicatedStorage` and require it from both sides:

```luau
const SwiftPacket = require("@game/ReplicatedStorage/Packages/SwiftPacket")

return {
    Chat = SwiftPacket("Chat", SwiftPacket.String),
    Damage = SwiftPacket("Damage", SwiftPacket.U16, SwiftPacket.InstanceOf("Humanoid")),
}
```

If the server sends a packet the client has not defined yet, the client holds
that batch, and every batch after it, until the definition runs. A batch still
waiting after 10 seconds is dropped with a warning naming the missing id.

## Names

A name may contain letters, digits and underscores, must not start with a
digit or `RBX`, and can be up to 100 characters long. Defining the same name
twice returns the packet that already exists.

## Options

Options are methods that return the packet, so they chain onto the definition:

```luau
const Move = SwiftPacket("Move", SwiftPacket.Vector3F24):Unreliable()
const Attack = SwiftPacket("Attack", SwiftPacket.U8):RateLimit(10, 1)
const GetCoins = SwiftPacket("GetCoins"):Response(SwiftPacket.U32)
```

Call them in the shared module, so both sides agree. `Response()` in particular
changes how the packet is written, and a packet with a response on only one side
cannot be read by the other.

## Next

[Events](4-events.md)
