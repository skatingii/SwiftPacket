# Security

Anything a client sends can be forged. SwiftPacket assumes every batch from a
client may be malicious and checks it before any handler sees it.

## What is checked for you

- The batch must be a buffer, and the instance list must be a table.
- Each player has a budget of incoming bytes, 64000 per second by default.
  Every message in a batch also costs 8 bytes of it, so a batch of thousands of
  tiny messages cannot force thousands of handler calls. Batches over the
  budget are dropped.
- Every read is bounds checked. A length or count that claims more data than the
  batch holds is rejected before anything is allocated.
- Unknown packet ids, unknown `Any` tags, indices outside a `Static()` list and
  values outside a `Range()` are rejected.
- `F16`, `F24`, `F32` and `F64` values from a client may not be NaN or infinite.
- `Any` tables may not be nested deeper than 16 levels.
- A reply is only accepted for a request the server actually sent to that
  player, for the same packet.

If any check fails, the whole batch is dropped, so a half-read batch never
reaches your handlers.

## What you still have to check

SwiftPacket checks that a message is well formed, not that it makes sense. A
client can still send a valid `Humanoid` that belongs to someone else, or a
damage value of 65535.

Bound what you can in the types:

```luau
const Emote = SwiftPacket("Emote", SwiftPacket.Range(SwiftPacket.U8, 1, 12))
const Report = SwiftPacket("Report", SwiftPacket.Array(SwiftPacket.String, 5))
```

Limit how often a packet may be sent:

```luau
const Attack = SwiftPacket("Attack", SwiftPacket.U8):RateLimit(10, 1)
```

And reject anything else before it reaches a handler:

```luau
Attack:Validate(function(Player, Slot)
    return Player.Character ~= nil and Slot <= 4
end)
```

A rejected event is dropped. A rejected request is answered with its timeout
values straight away.

## Logging

Rejections are logged as warnings while `Logging` is on. It defaults to on in
Studio and off in a live game:

```luau
SwiftPacket.Configure({ Logging = true })
```

## Next

[Migrating from Packet](8-migrating-from-packet.md)
