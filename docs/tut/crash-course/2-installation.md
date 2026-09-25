# Installation

SwiftPacket must live somewhere both the server and the client can require it,
which in practice means `ReplicatedStorage`.

## Wally

Add it to the `[dependencies]` of your `wally.toml`, then run `wally install`:

```toml
[dependencies]
SwiftPacket = "skatingii/swiftpacket@0.1.3"
```

Sync the `Packages` folder into `ReplicatedStorage` with Rojo, and require it:

```luau
const SwiftPacket = require("@game/ReplicatedStorage/Packages/SwiftPacket")
```

## roblox-ts

Install it from npm:

```sh
npm install @rbxts/swiftpacket
```

The package ships the same Luau source as the Wally package, with TypeScript
declarations beside it. Import it like any other roblox-ts package:

```ts
import SwiftPacket from "@rbxts/swiftpacket";

const Damage = SwiftPacket("Damage", SwiftPacket.U16, SwiftPacket.InstanceOf("Humanoid"));
```

A few things read differently from Luau:

- Packet methods are called with a dot, such as `Damage.Fire(25, humanoid)`, and
  roblox-ts turns them into method calls.
- A handler that answers with more than one value returns them with
  `$tuple(true, 10)`, and a request with more than one response type returns a
  tuple you destructure with `const [landed, damage] = Hit.Fire(humanoid)`.
- `SwiftPacket.Static(["Sword", "Shield"])` is typed as `"Sword" | "Shield"`, and
  `SwiftPacket.InstanceOf("Humanoid")` as `Humanoid | undefined`.
- In a struct built with `SwiftPacket.Struct()`, a field wrapped in `Optional()`
  may be left out of the object you send.

## Model file

Every release has a `SwiftPacket.rbxm` attached. Download it from the
[releases](https://github.com/skatingii/SwiftPacket/releases) and insert it
into `ReplicatedStorage`.

## Studio Script Sync or Rojo from source

Sync the `src` folder into `ReplicatedStorage` and name it `SwiftPacket`. The
folder has an `init.luau`, so it becomes a single ModuleScript with the other
files as its children.

## Tooling

The repository pins its tools with [Rokit](https://github.com/rojo-rbx/rokit):

```sh
rokit install
bash scripts/check.sh
```

`check.sh` runs StyLua, `luau-lsp analyze` on the new type solver, the type
tests, the Lute test suite and a Rojo build.

## Next

[Defining packets](3-packets.md)
