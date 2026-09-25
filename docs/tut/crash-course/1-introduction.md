# Introduction

SwiftPacket is a networking library for Roblox. You describe each message once,
with the types of the values it carries, and then fire it from the server or the
client as if you were calling a function.

```luau
const Damage = SwiftPacket("Damage", SwiftPacket.U16, SwiftPacket.InstanceOf("Humanoid"))

Damage:Fire(25, Humanoid)
```

## Why not plain remotes?

A `RemoteEvent` sends every call on its own, and each value is sent with extra
data describing its type. A number costs up to 9 bytes, even when it is a
health value between 0 and 100.

SwiftPacket does three things differently:

1. **It knows the types ahead of time.** A `U8` is written as exactly one byte,
   so there is nothing to describe on the wire.
2. **It batches.** Every packet fired during a frame is written into one
   buffer, and that buffer is sent once per frame, per player.
3. **It checks what clients send.** Every read from a client is bounds
   checked, and a batch that fails any check is dropped as a whole, before any
   of your handlers run.

## How it works

- There are only two remotes, one `RemoteEvent` and one `UnreliableRemoteEvent`,
  created by the server under the SwiftPacket module.
- Each packet gets a numeric id from the server, published as an attribute on
  the remote. The id is written in front of every message, and it takes one
  byte for the first 127 packets.
- The client learns ids as the attributes replicate. A packet fired before its
  id arrives is held and sent as soon as it does.
- Messages to one player always arrive in the order they were fired, whether
  they were sent with `Fire()`, `FireClient()` or `FireClients()`.
- A message for a packet the client has not defined yet is held, with the
  messages after it in the same batch, until the client defines it, for up to
  10 seconds. Other batches keep arriving meanwhile, and the held messages are
  delivered after the code that defined the packet has connected its handlers.

## Next

[Installation](2-installation.md)
