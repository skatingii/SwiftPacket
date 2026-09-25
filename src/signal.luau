--!strict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const ThreadPool = require("./thread_pool")

const Signal = {}
Signal.__index = Signal

const Connection = {}
Connection.__index = Connection

export type SignalFields = {
	Head: Connection?,
	Tail: Connection?,
}

export type ConnectionFields = {
	Connected: boolean,
	Once: boolean,
	Callback: ((...any) -> ())?,
	Thread: thread?,
	Owner: Signal,
	Previous: Connection?,
	Next: Connection?,
}

export type Signal = setmetatable<SignalFields, typeof(Signal)>
export type Connection = setmetatable<ConnectionFields, typeof(Connection)>

function Signal.New(): Signal
	const State: SignalFields = {}

	const self: Signal = setmetatable(State, Signal)

	return self
end

const function Attach(Owner: Signal, Callback: ((...any) -> ())?, Thread: thread?, Once: boolean): Connection
	const State: ConnectionFields = {
		Connected = true,
		Once = Once,
		Callback = Callback,
		Thread = Thread,
		Owner = Owner,
		Previous = Owner.Tail,
	}

	const Node: Connection = setmetatable(State, Connection)
	const Tail = Owner.Tail

	if Tail then
		Tail.Next = Node
	else
		Owner.Head = Node
	end

	Owner.Tail = Node

	return Node
end

function Signal.Connect(self: Signal, Callback: (...any) -> ()): Connection
	return Attach(self, Callback, nil, false)
end

function Signal.Once(self: Signal, Callback: (...any) -> ()): Connection
	return Attach(self, Callback, nil, true)
end

function Signal.Wait(self: Signal): ...any
	Attach(self, nil, coroutine.running(), true)

	return coroutine.yield()
end

function Signal.Fire(self: Signal, ...: any)
	local Node = self.Head

	while Node do
		if Node.Connected then
			if Node.Once then
				Node:Disconnect()
			end

			const Callback = Node.Callback
			const Thread = Node.Thread

			if Callback then
				ThreadPool.Defer(Callback, ...)
			elseif Thread then
				task.defer(Thread, ...)
			end
		end

		Node = Node.Next
	end
end

function Signal.DisconnectAll(self: Signal)
	local Node = self.Head

	while Node do
		Node.Connected = false
		Node = Node.Next
	end

	self.Head = nil
	self.Tail = nil
end

function Connection.Disconnect(self: Connection)
	if not self.Connected then
		return
	end

	self.Connected = false

	const Owner = self.Owner
	const Previous = self.Previous
	const Next = self.Next

	if Previous then
		Previous.Next = Next
	else
		Owner.Head = Next
	end

	if Next then
		Next.Previous = Previous
	else
		Owner.Tail = Previous
	end
end

return Signal
