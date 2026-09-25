# Types

Every type is a field of SwiftPacket. At the type level each one is the Luau
type of the value it carries, which is why packets are typed without casts:
`SwiftPacket.U8` has the type `number`, and `{ SwiftPacket.String }` has the
type `{ string }`.

Sizes are in bytes. Every message also carries its packet id, which is 1 byte
for the first 127 packets, and requests add 2 bytes (3 for an answer).

## Primitives

| Type | Luau type | Size | Notes |
| --- | --- | --- | --- |
| `Nil` | `nil` | 0 | |
| `Boolean` | `boolean` | 1 | |
| `U8` | `number` | 1 | 0 to 255 |
| `U16` | `number` | 2 | 0 to 65535 |
| `U24` | `number` | 3 | 0 to 16777215 |
| `U32` | `number` | 4 | 0 to 4294967295 |
| `I8` | `number` | 1 | -128 to 127 |
| `I16` | `number` | 2 | -32768 to 32767 |
| `I24` | `number` | 3 | -8388608 to 8388607 |
| `I32` | `number` | 4 | -2147483648 to 2147483647 |
| `F16` | `number` | 2 | Half precision, up to 65504 |
| `F24` | `number` | 3 | 17 bit mantissa, up to about 4.29e9 |
| `F32` | `number` | 4 | Single precision |
| `F64` | `number` | 8 | Double precision, exact for any Luau number |
| `String` | `string` | 1 to 4 + length | Any length up to 268435455 |
| `Characters` | `string` | 1 to 4 + 6 bits per character | Letters, digits, space and `.` |
| `Buffer` | `buffer` | 1 to 4 + length | |
| `Instance` | `Instance?` | 0 | Sent as a reference beside the buffer |
| `Any` | `any` | 1 + value | Any value below, and tables of them |

## Roblox types

| Type | Luau type | Size | Notes |
| --- | --- | --- | --- |
| `Vector2` | `Vector2` | 8 | `F32` components |
| `Vector2F16` | `Vector2` | 4 | `F16` components |
| `Vector2I16` | `Vector2` | 4 | Rounded to whole numbers |
| `Vector3` | `Vector3` | 12 | `F32` components |
| `Vector3F24` | `Vector3` | 9 | `F24` components |
| `Vector3F16` | `Vector3` | 6 | `F16` components |
| `Vector3I16` | `Vector3` | 6 | Rounded to whole numbers |
| `CFrame` | `CFrame` | 19 | `F32` position, 7 byte quaternion |
| `CFrameF24` | `CFrame` | 16 | `F24` position, 7 byte quaternion |
| `Color3` | `Color3` | 3 | 0 to 255 per channel |
| `BrickColor` | `BrickColor` | 2 | |
| `UDim` | `UDim` | 8 | |
| `UDim2` | `UDim2` | 16 | |
| `Rect` | `Rect` | 16 | |
| `NumberRange` | `NumberRange` | 8 | |
| `NumberSequence` | `NumberSequence` | 1 + 12 per keypoint | Up to 20 keypoints |
| `ColorSequence` | `ColorSequence` | 1 + 7 per keypoint | Up to 20 keypoints |
| `DateTime` | `DateTime` | 8 | Millisecond precision |

## Constructors

### Array()

```luau
function Array<T>(Element: T, MaximumLength: number?): { T }
```

A length of 1 to 4 bytes, then each element. `{ T }` is the same without a
maximum.

### Map()

```luau
function Map<K, V>(Key: K, Value: V, MaximumCount: number?): { [K]: V }
```

A count of 1 to 4 bytes, then each key and value.

### Struct()

```luau
function Struct<T>(Shape: T): T
```

Each field in the sorted order of its key, with no keys on the wire.
`{ Key = T }` is the same.

### Optional()

```luau
function Optional<T>(Inner: T): T?
```

One byte, then the value when it is not `nil`.

### Static()

```luau
function Static<T>(Values: { T }): T
```

The index of the value in the list: 1 byte for up to 256 values, 2 bytes for up
to 65536. Sending a value that is not in the list is an error.

### Range()

```luau
function Range(Inner: number, Minimum: number, Maximum: number): number
```

The inner type, with values outside the range rejected on both sides.

### Flags()

```luau
function Flags(Names: { string }): { [string]: boolean }
```

One bit per name, up to 64 names.

### Charset()

```luau
function Charset(Characters: string): string
```

A string that may only use the given characters, each packed into as few bits
as the set needs: 4 bits for 16 characters, 6 bits for 64.

### InstanceOf()

```luau
function InstanceOf(ClassName: string): Instance?
```

An `Instance` that is received as `nil` unless it `IsA(ClassName)`. Sending an
instance of another class is an error.

### EnumItem()

```luau
function EnumItem(EnumType: Enum): EnumItem
```

An item of one enum, sent as its `Value` in 2 bytes.
