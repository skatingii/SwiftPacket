--!strict
--!optimize 2

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const RateLimit = {}

function RateLimit.Refill(Tokens: number, Elapsed: number, Rate: number, Capacity: number): number
	return math.min(Capacity, Tokens + math.max(Elapsed, 0) * Rate)
end

function RateLimit.Window(
	Count: number,
	EndsAt: number,
	Now: number,
	Limit: number,
	Interval: number
): (boolean, number, number)
	if Now >= EndsAt then
		return true, 1, Now + Interval
	end

	if Count >= Limit then
		return false, Count, EndsAt
	end

	return true, Count + 1, EndsAt
end

return RateLimit
