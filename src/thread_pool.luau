--!strict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	GitHub: github.com/skatingii/SwiftPacket
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const ThreadPool = {}

const Threads: { thread } = {}

const function Call(Callback: (...any) -> (), ...: any)
	Callback(...)
	table.insert(Threads, coroutine.running())
end

const function Loop()
	while true do
		Call(coroutine.yield())
	end
end

const function Acquire(): thread
	return table.remove(Threads) or task.spawn(Loop)
end

function ThreadPool.Defer(Callback: (...any) -> (), ...: any)
	task.defer(Acquire(), Callback, ...)
end

return ThreadPool
