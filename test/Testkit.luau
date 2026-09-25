--!strict

--[[
	Author: @skaterstudios
	Website: skaterstudios.com
	Discord Server: discord.gg/skaterstudios

	Licensed under the MIT License. You may use, modify, redistribute and sell
	this system freely, as long as this notice and the LICENSE file stay with it.
]]

const Testkit = {}

local Passed = 0
local Failed = 0

const function Describe(Value: any): string
	if type(Value) == "string" then
		return `"{Value}"`
	end

	return tostring(Value)
end

function Testkit.Test(Name: string, Callback: () -> ())
	const Ok, Problem = pcall(Callback)

	if Ok then
		Passed += 1
	else
		Failed += 1
		print(`FAIL {Name}: {tostring(Problem)}`)
	end
end

function Testkit.Equal(Actual: any, Expected: any)
	if Actual ~= Expected and not (Actual ~= Actual and Expected ~= Expected) then
		error(`expected {Describe(Expected)}, got {Describe(Actual)}`, 2)
	end
end

function Testkit.Near(Actual: number, Expected: number, Tolerance: number)
	if math.abs(Actual - Expected) > Tolerance then
		error(`expected {Expected} within {Tolerance}, got {Actual}`, 2)
	end
end

function Testkit.Truthy(Value: any)
	if not Value then
		error(`expected a truthy value, got {Describe(Value)}`, 2)
	end
end

function Testkit.Throws(Callback: () -> (), Pattern: string)
	const Ok, Problem = pcall(Callback)

	if Ok then
		error(`expected an error matching "{Pattern}"`, 2)
	end

	if string.find(tostring(Problem), Pattern, 1, true) == nil then
		error(`expected an error matching "{Pattern}", got "{tostring(Problem)}"`, 2)
	end
end

function Testkit.Finish()
	print(`{Passed} passed, {Failed} failed`)

	if Failed > 0 then
		error(`{Failed} tests failed`, 0)
	end
end

return Testkit
