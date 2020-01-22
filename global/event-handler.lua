local onEvent
do
	local events = {}

	function onEvent(name, callback)
		local evt
		if events[name] then
			evt = events[name]
		else
			evt = {_count = 0}
			events[name] = evt

			_G["event" .. name] = function(...)
				for index = 1, evt._count do
					if evt[index](...) == "break" then
						return
					end
				end
			end
		end

		evt._count = evt._count + 1
		evt[evt._count] = callback
	end
end