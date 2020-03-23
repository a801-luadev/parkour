local timers = {}
local aliveTimers = false

local function addNewTimer(delay, fnc, argument)
	aliveTimers = true
	local list = timers[delay]
	if list then
		list._count = list._count + 1
		list[list._count] = {os.time() + delay, fnc, argument}
	else
		timers[delay] = {
			_count = 1,
			_pointer = 1,
			[1] = {os.time() + delay, fnc, argument}
		}
	end
end

onEvent("Loop", function()
	if aliveTimers then
		aliveTimers = false
		local now = os.time()
		local timer, newPointer
		for delay, list in next, timers do
			newPointer = list._pointer
			for index = newPointer, list._count do
				timer = list[index]

				if now >= timer[1] then
					timer[2](timer[3])
					newPointer = index + 1
				else
					break
				end
			end
			list._pointer = newPointer
			if newPointer <= list._count then
				aliveTimers = true
			end
		end
	end
end)

onEvent("NewGame", function()
	if aliveTimers then
		local timer
		for delay, list in next, timers do
			for index = list._pointer, list._count do
				timer = list[index]
				timer[2](timer[3])
			end
		end
	end
end)