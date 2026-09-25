# Signal

`OnServerEvent` and `OnClientEvent` are signals. Handlers are run on reused
threads when a batch is read, in the order they were connected.

## Connect()

- **Type**

  ```luau
  function Signal:Connect(Callback: (A...) -> ()): Connection
  ```

## Once()

- **Type**

  ```luau
  function Signal:Once(Callback: (A...) -> ()): Connection
  ```

- **Details**

  Disconnects itself before the first call.

## Wait()

- **Type**

  ```luau
  function Signal:Wait(): A...
  ```

- **Details**

  Yields until the next message and returns its values.

## DisconnectAll()

- **Type**

  ```luau
  function Signal:DisconnectAll()
  ```

## Connection

- **Type**

  ```luau
  type Connection = {
      Connected: boolean,
      Disconnect: (self: Connection) -> (),
  }
  ```
