# SwiftPacket

The table returned by `require`. Calling it defines a packet; its fields are the
[types](types.md) and the functions below.

## SwiftPacket()

Defines a packet, or returns the packet already defined with that name.

- **Type**

  ```luau
  function SwiftPacket<A...>(Name: string, A...): Event<A...>
  ```

- **Details**

  Each argument after the name is a [type](types.md). The type checker infers
  the packet's argument types from them, so `Fire()` and every handler are
  checked.

  The name may use letters, digits and underscores, must not start with a
  digit or `RBX`, and can be up to 100 characters. The same packets must be
  defined on the server and the client.

  On the client, requiring SwiftPacket waits up to 10 seconds for the server to
  create its remotes, and errors if they never appear.

- **Example**

  ```luau
  const Damage = SwiftPacket("Damage", SwiftPacket.U16, SwiftPacket.InstanceOf("Humanoid"))
  ```

## Configure()

Changes library wide settings.

- **Type**

  ```luau
  function Configure(Options: {
      Logging: boolean?,
      IncomingBytesPerSecond: number?,
      UnreliableByteLimit: number?,
  })
  ```

- **Details**

  | Option | Default | Meaning |
  | --- | --- | --- |
  | `Logging` | `true` in Studio | Warn about rejected batches, rate limits and ignored responses. |
  | `IncomingBytesPerSecond` | `64000` | The byte budget each player may send the server per second, where every message also costs 8 bytes. At least 1000. |
  | `UnreliableByteLimit` | `900` | The most bytes put in one unreliable fire, from 64 to 900. |

  Unknown options and options of the wrong type are errors. Errors from your
  own handlers are always reported, whatever `Logging` is set to.

## Version

The version of the library, as a string such as `"0.1.3"`.
