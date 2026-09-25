# Migrating from Packet

SwiftPacket keeps the shape of Packet's API, so most code changes only by name.

## Definitions and methods

| Packet | SwiftPacket |
| --- | --- |
| `Packet("Name", ...)` | `SwiftPacket("Name", ...)` |
| `packet:Fire(...)` | `packet:Fire(...)` |
| `packet:FireClient(player, ...)` | `packet:FireClient(player, ...)` |
| `packet.OnServerEvent` / `OnClientEvent` | the same |
| `packet:Response(...)` | the same |
| `packet.OnServerInvoke = fn` | the same, or `packet:SetServerInvoke(fn)` to have it type checked |
| `packet.ResponseTimeout = 5` | `packet:Timeout(5, ...)` |
| `packet:Serialize(...)` / `Deserialize()` | the same |
| none | `FireClients()`, `FireExcept()`, `Unreliable()`, `RateLimit()`, `Validate()` |

## Types

| Packet | SwiftPacket |
| --- | --- |
| `NumberU8` to `NumberU32` | `U8` to `U32` |
| `NumberS8` to `NumberS32` | `I8` to `I32` |
| `NumberF16` to `NumberF64` | `F16` to `F64` |
| `String`, `StringLong` | `String`, with no 255 byte limit |
| `Buffer`, `BufferLong` | `Buffer`, with no 255 byte limit |
| `Boolean8` | `Boolean` |
| `Boolean1` | `Flags({ ... })` |
| `Vector3F32`, `Vector3F24`, `Vector3S16` | `Vector3`, `Vector3F24`, `Vector3I16` |
| `CFrameF32U16`, `CFrameF24U8` | `CFrame`, `CFrameF24` |
| `Static1`, `Static2`, `Static3` | `Static({ ... })`, as many as you need |
| `EnumItem` with an `Enums` list | `EnumItem(Enum.KeyCode)` |
| `Characters` | `Characters`, or `Charset("...")` for your own |
| `{ Type }` and `{ Key = Type }` | the same |

## Behaviour that changed

- **CFrames are more precise.** Rotation is sent as a quaternion instead of
  three quantized angles, so `CFrame` and `CFrameF24` no longer drift.
- **Order is kept per player.** Packet sent broadcasts before messages to one
  player within a frame; SwiftPacket sends them in the order you fired them.
- **Failures do not hang.** A request whose handler errors is answered with the
  timeout values straight away, and pending requests to a player who leaves are
  released.
- **Nil instances do not shift the others.** A `nil` Instance used to cut off
  every instance after it in the same batch.
- **`Any` numbers are exact.** Packet sent fractions as `F32`; SwiftPacket sends
  them as `F64`.
- **More than 256 packets.** Ids are variable length instead of one byte.
