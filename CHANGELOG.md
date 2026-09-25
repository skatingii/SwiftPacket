# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

--------------------------------------------------------------------------------

## [0.1.2] - 2026-09-25

### Changed

- Firing is up to three times faster. Messages are written straight into the
  outgoing batch instead of into a scratch buffer that was then copied, without
  packing the arguments into a table first.
- `Fire()` on the server writes a message once for every player instead of once
  per player, and each player's batch is assembled from it at the end of the
  frame, so broadcasting no longer gets slower with more players. Messages to
  one player still arrive in the order they were fired.
- Reading a batch no longer creates a table for every message, which lowers the
  cost of receiving and removes the garbage collection pauses a large batch
  could cause.
- The byte reader and writer now live in the same module as the types, and every
  module is compiled with `--!optimize 2`, so the small read and write functions
  can be inlined.
- Every message in a batch from a client costs 8 bytes of the incoming budget on
  top of its size, so a batch of thousands of tiny messages is dropped instead
  of forcing thousands of handler calls.
- Errors from writing a value no longer pass through `pcall`. They name the
  packet as before, and a failed write still leaves the batch untouched.

### Fixed

- The Wally package failing to load without Rojo, such as with Studio Script
  Sync. The package root now has an `init.luau` that returns `src`, so the
  package folder is a ModuleScript that Wally's link file can require. Rojo
  still builds from `default.project.json` and is unaffected.
- A message for a packet the client had not defined yet stopped every batch
  after it for up to 10 seconds. Only the messages after it in the same batch
  are held now, and the rest of the traffic keeps flowing.
- Messages held for a packet defined late were delivered while the packet was
  still being created, before a handler could be connected, and were lost. They
  are now delivered on the next resumption cycle.

--------------------------------------------------------------------------------

## [0.1.1] - 2026-09-25

### Changed

- Module files are now lowercase, and the Wally package ships only
  `default.project.json`, `LICENSE` and `src`.

### Fixed

- Requests and responses being handled before events that arrived earlier in
  the same batch. Every message in a batch is now handled in the order it was
  fired.

--------------------------------------------------------------------------------

## [0.1.0] - 2026-09-25

### Added

- `SwiftPacket(name, ...types)` to define a packet, with its argument types
  inferred by the type checker.
- `Fire()`, `FireClient()`, `FireClients()` and `FireExcept()`.
- `OnServerEvent` and `OnClientEvent` signals with `Connect()`, `Once()`,
  `Wait()` and `DisconnectAll()`.
- `Response()` for requests that yield for a reply, with `SetServerInvoke()`,
  `SetClientInvoke()` and `Timeout()`.
- `Unreliable()` packets, split into fires of at most 900 bytes.
- `RateLimit()` and `Validate()` for packets sent by clients.
- `Serialize()` and `Deserialize()` for using a packet's types without sending.
- `Configure()` for logging, the incoming byte budget and the unreliable limit.
- Number types `U8` to `U32`, `I8` to `I32`, `F16`, `F24`, `F32` and `F64`.
- `String`, `Buffer`, `Characters` and `Charset()` with lengths of any size.
- Roblox types including `Vector3`, `CFrame`, `Color3`, `UDim2`,
  `NumberSequence`, `ColorSequence`, `DateTime`, `EnumItem()` and
  `InstanceOf()`.
- `Array()`, `Map()`, `Struct()`, `Optional()`, `Static()`, `Range()`,
  `Flags()` and `Any`, plus `{ T }` and `{ Key = T }` table shorthand.
