# Types

Every argument of a packet has a type, and the type decides how the value is
written. Picking the smallest type that fits is how SwiftPacket saves
bandwidth. The full list, with sizes, is in the [type reference](../../api/types.md).

## Numbers

| Type | Bytes | Range |
| --- | --- | --- |
| `U8`, `U16`, `U24`, `U32` | 1, 2, 3, 4 | 0 to 255, 65535, 16777215, 4294967295 |
| `I8`, `I16`, `I24`, `I32` | 1, 2, 3, 4 | -128 to 127, and so on |
| `F16` | 2 | about 3 significant digits, up to 65504 |
| `F24` | 3 | about 5 significant digits, up to about 4.29 billion |
| `F32`, `F64` | 4, 8 | single and double precision |

Integers outside their range wrap, so use a type that fits.

## Tables

A table with one entry is an array, and a table with keys is a struct:

```luau
const Inventory = SwiftPacket("Inventory", {
    Coins = SwiftPacket.U32,
    Items = { SwiftPacket.String },
})
```

A struct writes only its values, in the sorted order of its keys, so the keys
cost nothing on the wire. The same can be written with `Struct()` and
`Array()`, which also takes a maximum length:

```luau
SwiftPacket.Struct({ Coins = SwiftPacket.U32 })
SwiftPacket.Array(SwiftPacket.String, 50)
SwiftPacket.Map(SwiftPacket.String, SwiftPacket.F32)
SwiftPacket.Optional(SwiftPacket.String)
```

## Fixed sets of values

`Static()` sends a value from a list as its index, in one byte for up to 256
values:

```luau
const State = SwiftPacket("State", SwiftPacket.Static({ "Idle", "Walk", "Run" }))
State:Fire("Run")
```

`Flags()` packs booleans into bits, and `EnumItem()` sends an item of one Roblox
enum in two bytes:

```luau
SwiftPacket.Flags({ "Sprinting", "Crouching", "Aiming" })
SwiftPacket.EnumItem(Enum.KeyCode)
```

## Text

`String` holds any text, with a length prefix of 1 byte for strings under 128
bytes. `Characters` packs each character into 6 bits, for names and codes that
only use letters, digits, spaces and dots. `Charset()` builds your own:

```luau
const Code = SwiftPacket.Charset("0123456789ABCDEF")
```

## Instances

`Instance` and `InstanceOf(className)` send a reference, not a copy. The value
is `nil` when the instance does not exist on the receiving side, and
`InstanceOf()` also gives `nil` when the instance is not of that class. Both are
typed as `Instance?`, so the type checker makes you handle it.

## Anything

`Any` sends a value of any supported type, including nested tables, with a one
byte tag in front of each value. Use it for data with no fixed shape; a typed
packet is always smaller.

## Next

[Security](7-security.md)
