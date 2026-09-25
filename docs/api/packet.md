# Packet

A packet is an `Event<A...>` when it is defined. Calling `Response()` turns it
into a `Request<A..., B...>`, where `A...` are the argument types and `B...` the
response types.

## Sending events

### Fire()

- **Type**

  ```luau
  function Event:Fire(A...)
  ```

- **Details**

  On the client, sends to the server. On the server, sends to every player.

### FireClient()

- **Type**

  ```luau
  function Event:FireClient(Player: Player, A...)
  ```

- **Details**

  Server only. Sends to one player.

### FireClients()

- **Type**

  ```luau
  function Event:FireClients(Players: { Player }, A...)
  ```

- **Details**

  Server only. Sends to each player in the list. The values are written once
  and copied into each player's batch.

### FireExcept()

- **Type**

  ```luau
  function Event:FireExcept(Player: Player, A...)
  ```

- **Details**

  Server only. Sends to every player except one.

## Receiving events

### OnServerEvent

- **Type**

  ```luau
  Event.OnServerEvent: Signal<(Player, A...)>
  ```

### OnClientEvent

- **Type**

  ```luau
  Event.OnClientEvent: Signal<A...>
  ```

See [Signal](signal.md).

## Requests

### Response()

- **Type**

  ```luau
  function Event:Response<B...>(B...): Request<A..., B...>
  ```

- **Details**

  Makes the packet a request whose answer has the given types. Cannot be used
  on an unreliable packet.

### Fire() and FireClient()

- **Type**

  ```luau
  function Request:Fire(A...): B...
  function Request:FireClient(Player: Player, A...): B...
  ```

- **Details**

  `Fire()` on the client and `FireClient()` on the server send the request and
  yield until the answer arrives, the timeout passes or the call fails. On
  failure, the timeout values are returned.

### SetServerInvoke() and SetClientInvoke()

- **Type**

  ```luau
  function Request:SetServerInvoke(Handler: (Player, A...) -> B...): Request<A..., B...>
  function Request:SetClientInvoke(Handler: (A...) -> B...): Request<A..., B...>
  ```

- **Details**

  Sets the function that answers requests on that side. The handler may yield.
  The fields `OnServerInvoke` and `OnClientInvoke` hold the same functions and
  can be assigned directly, but only the setters are type checked.

### Timeout()

- **Type**

  ```luau
  function Request:Timeout(Seconds: number, B...): Request<A..., B...>
  ```

- **Details**

  Sets how long a caller waits, 10 seconds by default, and the values returned
  when a call does not succeed.

## Options

### Unreliable()

- **Type**

  ```luau
  function Event:Unreliable(): Event<A...>
  ```

- **Details**

  Sends the packet through the `UnreliableRemoteEvent`. It may be dropped or
  arrive out of order. A single packet over the unreliable limit is an error
  when fired.

### RateLimit()

- **Type**

  ```luau
  function Event:RateLimit(Count: number, Interval: number): Event<A...>
  ```

- **Details**

  Server side. Each player may send the packet `Count` times per `Interval`
  seconds. Messages over the limit are dropped, and requests over it are
  answered with the timeout values.

### Validate()

- **Type**

  ```luau
  function Event:Validate(Validator: (Player, A...) -> boolean): Event<A...>
  ```

- **Details**

  Server side. Runs before any handler for messages from clients. Anything
  other than `true`, including an error, rejects the message.

## Serialization

### Serialize()

- **Type**

  ```luau
  function Event:Serialize(A...): (buffer, { Instance }?)
  ```

- **Details**

  Writes the values with the packet's types without sending them. Useful for
  saving data in the same compact format.

### Deserialize()

- **Type**

  ```luau
  function Event:Deserialize(Data: buffer, Instances: { Instance }?): A...
  ```

- **Details**

  Reads values written by `Serialize()`.
