local Toggle
do
	local callbacks = {}
	local lastId = -1

	Toggle = {}
	Toggle.__index = Toggle

	function Toggle.new(x, y, default, name)
		lastId = lastId + 1
		return setmetatable({
			x = x,
			y = y,
			default = default,

			name = name,

			toggleCallback = nil,
			updateCallback = nil,
			callback = "component_toggle_" .. lastId
		}, Toggle)
	end

	function Toggle:onToggle(callback)
		self.toggleCallback = callback
		return self
	end

	function Toggle:onUpdate(callback)
		self.updateCallback = callback
		return self
	end

	function Toggle:asTemplate(interface)
		local click = {
			x = self.x - 7, y = self.y - 7,
			width = 30, height = 20,
			text = "<a href='event:" .. self.callback .. "'>\n\n\n",
			alpha = 0
		}
		local switch = {
			name = self.name,
			default = self.default,

			y = self.y + 3,
			width = 1, height = 1,

			state = {},
			toggle = function(txt, player)
				local states = txt.state
				if states[player] == nil then
					states[player] = self.default
				end
				states[player] = not states[player]

				txt:checkState(player)
			end,
			onToggle = function(txt, player)
				txt:toggle(player)

				if self.toggleCallback then
					self.toggleCallback(txt, player, txt.state[player])
				end
			end,
			checkState = function(txt, player)
				local states = txt.state

				if states[player] then -- on
					ui.addTextArea(
						txt.id, "", player,
						interface.x + self.x + 16, txt.y,
						txt.width, txt.height,
						0x9bc346, 0x9bc346, 1,
						interface.fixed
					)
				else
					ui.addTextArea(
						txt.id, "", player,
						interface.x + self.x + 3, txt.y,
						txt.width, txt.height,
						0xb84c36, 0xb84c36, 1,
						interface.fixed
					)
				end

				ui.updateTextArea(click.id, click.text, player)
			end,
			onUpdate = function(txt, player)
				txt:checkState(player)
				if self.updateCallback then
					self.updateCallback(txt, player)
				end
			end
		}
		callbacks[self.callback] = {
			fnc = switch.onToggle,
			class = switch
		}

		if self.default then -- on
			switch.x = self.x + 16
			switch.color = {0x9bc346, 0x9bc346, 1}
		else -- off
			switch.x = self.x + 3
			switch.color = {0xb84c36, 0xb84c36, 1}
		end

		interface:addTextArea({
			x = self.x, y = self.y,
			width = 20, height = 7,
			color = {0x232a35, 0x232a35, 1}
		}):addTextArea(switch):addTextArea(click)
	end

	onEvent("RawTextAreaCallback", function(id, player, cb)
		local callback = callbacks[cb]
		if callback and callback.class.parent.open[player] then
			if not checkCooldown(player, "simpleToggle", 500) then return end

			callback.fnc(callback.class, player)
		end
	end)
end