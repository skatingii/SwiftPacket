# Requests

`Response()` turns a packet into a request. It takes the types of the values
the other side sends back:

```luau
const GetLevel = SwiftPacket("GetLevel", SwiftPacket.String):Response(SwiftPacket.U8, SwiftPacket.Boolean)
```

## Answering

Set the handler with `SetServerInvoke()` on the server, or `SetClientInvoke()`
on the client. Whatever it returns is sent back:

```luau
GetLevel:SetServerInvoke(function(Player, Key)
    return 12, true
end)
```

The setters are checked by the type checker: the arguments are typed from the
packet and the return values must match `Response()`. Assigning
`OnServerInvoke` and `OnClientInvoke` directly also works, as in Packet, but
the type checker cannot check an assigned function.

## Asking

On the client, `Fire()` yields until the answer arrives. On the server, use
`FireClient()`:

```luau
const Level, Found = GetLevel:Fire("Hero")
const Answer = OtherRequest:FireClient(Player)
```

## Timeouts and failures

Every request has a timeout, 10 seconds unless you set one:

```luau
GetLevel:Timeout(5, 0, false)
```

The values after the number are returned when the call does not succeed. That
happens when:

- the timeout passes with no answer,
- the handler errors, or returns values that do not match the response types,
- the other side has no handler set,
- the server rejected the request through `RateLimit()` or `Validate()`,
- the player leaves while the server is waiting on them.

The caller never hangs past its timeout, and a failure on the other side is
answered straight away instead of waiting for it.

Up to 32768 requests can wait at once, per player on the server and in total on
the client.

## Next

[Types](6-types.md)
