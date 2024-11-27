local Button
do
	local callbacks = {}
	local lastId = -1

	Button = {}
	Button.__index = Button

	function Button.new()
		lastId = lastId + 1
		return setmetatable({
			callback = "component_button_" .. lastId
		}, Button)
	end

	function Button:setText(text)
		if type(text) == "function" then
			self.text_fnc = text
		else
			self.text_str = text .. "\n"
		end
		return self
	end

	function Button:setTranslation(translation)
		self.translation = translation
		return self
	end

	function Button:canUpdate(enabled)
		self.update = enabled
		return self
	end

	function Button:onClick(callback)
		self.clickCallback = callback
		return self
	end

	function Button:onUpdate(callback)
		self.updateCallback = callback
		return self
	end

	function Button:setPosition(x, y)
		self.x = x
		self.y = y
		return self
	end

	function Button:setSize(width, height)
		self.width = width
		self.height = height
		return self
	end

	function Button:asTemplate(interface)
		local enabled_prefix = "<a href='event:" .. self.callback .. "'><p align='center'>" 
		local disabled_prefix = "<p align='center'>"
		local textarea = {
			x = self.x, y = self.y,
			width = self.width, height = self.height,

			canUpdate = self.update,
			text = "",
			color = {0x314e57, 0x314e57, 1},
			onUpdate = self.updateCallback,

			enabled = {},
			disable = function(self, player)
				self.enabled[player] = false
				ui.addTextArea(
					self.id,
					self.text_str,
					player,

					self.x, self.y,
					self.width, self.height,

					0x2a424b, 0x2a424b, self.alpha,
					interface.fixed
				)
			end,
			enable = function(self, player)
				self.enabled[player] = true
				ui.addTextArea(
					self.id,
					self.text_str,
					player,

					self.x, self.y,
					self.width, self.height,

					self.background, self.border, self.alpha,
					interface.fixed
				)
			end
		}
		local text = {
			x = self.x, y = self.y,
			width = self.width, height = self.height + 2,

			canUpdate = self.update,
			text = function(txt, player, arg1, arg2, arg3, arg4)
				if textarea.enabled[player] == nil then
					textarea.enabled[player] = true
				end

				local prefix = textarea.enabled[player] and enabled_prefix or disabled_prefix
				if self.translation then
					return prefix .. translatedMessage(self.translation, player) .. "\n"
				elseif self.text_fnc then
					return prefix .. self.text_fnc(textarea, player, arg1, arg2, arg3, arg4) .. "\n"
				else
					return prefix .. self.text_str
				end
			end,
			alpha = 0,

			disable = function(self, player)
				return textarea:disable(player)
			end,
			enable = function(self, player)
				return textarea:enable(player)
			end
		}
		callbacks[self.callback] = {
			fnc = self.clickCallback,
			class = textarea
		}

		interface:addTextArea({
			x = self.x - 1, y = self.y - 1,
			width = self.width, height = self.height,

			canUpdate = self.update,
			color = {0x7a8d93, 0x7a8d93, 1}
		}):addTextArea({
			x = self.x + 1, y = self.y + 1,
			width = self.width, height = self.height,

			canUpdate = self.update,
			color = {0x0e1619, 0x0e1619, 1}
		}):addTextArea(textarea):addTextArea(text)
	end

	onEvent("TextAreaCallback", function(id, player, cb)
		if not checkCooldown(player, "tacallback", 1000) then return end

		local callback = callbacks[cb]
		if callback and callback.class.enabled and callback.class.parent.open[player] then
			callback.fnc(callback.class, player)
		end
	end)
end