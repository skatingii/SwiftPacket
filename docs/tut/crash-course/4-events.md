# Events

## Sending

On the client, `Fire()` sends to the server:

```luau
Packets.Chat:Fire("hello")
```

On the server there is a method for every set of recipients:

```luau
Packets.Chat:Fire("to everyone")
Packets.Chat:FireClient(Player, "to one player")
Packets.Chat:FireClients({ PlayerA, PlayerB }, "to a list of players")
Packets.Chat:FireExcept(Player, "to everyone but one player")
```

`Fire()` never yields for an event. The values are written into the batch
straight away and sent at the end of the frame.

## Receiving

Each packet has a signal for each side:

```luau
Packets.Chat.OnServerEvent:Connect(function(Player, Message)
    print(Player.Name, Message)
end)

Packets.Chat.OnClientEvent:Connect(function(Message)
    print(Message)
end)
```

Signals also have `Once()`, `Wait()` and `DisconnectAll()`, and `Connect()`
returns a connection with `Disconnect()`.

Handlers run on reused threads, so they may yield without holding up any other
handler. Handlers are started in the order the messages were fired, including
requests and replies, so an event fired before a request is handled before it.

## Unreliable packets

Values that are replaced every frame, such as a position, do not need to arrive
if a newer one is on the way. Mark those packets unreliable:

```luau
const Move = SwiftPacket("Move", SwiftPacket.Vector3F24):Unreliable()
```

Unreliable packets use the `UnreliableRemoteEvent`. They can be dropped and
they can arrive out of order, both with each other and with reliable packets.
Each fire is kept under 900 bytes: packets are split across several fires when
needed, and a single packet over the limit is an error when you fire it.

## Next

[Requests](5-requests.md)
