do
local confirming = {}
local closeButton = Button.new()
NPCInterface = Interface.new(200, 35, 400, 350, true)
	:loadTemplate(WindowBackground)
	:setShowCheck(function(self, player)
		confirming[player] = nil
		return true
	end)

	:addTextArea({ -- Title
		x = 10, y = 5,
		width = 380, height = 30,
		canUpdate = true,
		text = function(self, player, data)
			return "<p align='center'><font size='20'><B><D>" .. data.name
		end,
		alpha = 0
	})

	:addTextArea({ -- Message Background
		x = 10, y = 45,
		width = 380, height = 40,
		alpha = 1,
		color = {0x314e57, 0x314e57},
		canUpdate = true,
		text = function(self, player, data, message)
			return '<p align="center">' ..  translatedMessage(message and message or data.message, player)
		end
	})

	:addTextArea({ -- Left Background
		x = 10, y = 105,
		width = 180, height = 200,
		alpha = 1,
		color = {0x314e57, 0x314e57}
	})
	:addImage({ -- Left Image
		image = function(self, player, data)
			return data.left_image
		end,
		target = "~10",
		x = 100, y = 195,
		anchorX = 0.5, anchorY = 0.5,
	})
	:addTextArea({ -- Left Amount
		x = 10, y = 105,
		width = 180, height = 20,
		alpha = 0,
		canUpdate = true,
		text = function(self, player, data)
			return "<p align='right'><font color='#ffffff' size='14' face='Verdana'><b>" .. (data.left_amount or "")
		end
	})
	:loadComponent(
		Button.new()
		:setText(function(self, player)
			local data = self.parent.args[player][1]
			if not data.left_button then return '' end
			if confirming[player] == true then return translatedMessage('yes', player) end
			return translatedMessage(data.left_button, player)
		end)
		:onClick(function(self, player)
			if eventTradeNPC then
				local data = self.parent.args[player][1]
				if confirming[player] ~= true then
					confirming[player] = true
					self.parent:update(player, data)
					return
				end
				eventTradeNPC(player, data.name, true)
			end
		end)
		:canUpdate(true):onUpdate(function(self, player)
			local data = self.parent.args[player][1]
			if data.left_disabled then
				self:disable(player)
			else
				self:enable(player)
			end
		end)
		:setPosition(25, 285):setSize(150, 15)
	)

	:addTextArea({ -- Right Background
		x = 210, y = 105,
		width = 180, height = 200,
		alpha = 1,
		color = {0x314e57, 0x314e57}
	})
	:addImage({ -- Right Image
		canUpdate = true,
		image = function(self, player, data)
			return data.right_image
		end,
		target = "~10",
		x = 300, y = 195,
		anchorX = 0.5, anchorY = 0.5,
	})
	:addTextArea({ -- Right Amount
		x = 210, y = 105,
		width = 180, height = 20,
		alpha = 0,
		canUpdate = true,
		text = function(self, player, data)
			return "<p align='right'><font color='#ffffff' size='14' face='Verdana'><b>" .. (data.right_amount or "")
		end
	})
	:loadComponent(
		Button.new()
		:setText(function(self, player)
			local data = self.parent.args[player][1]
			if not data.right_button then return '' end
			if confirming[player] == false then return translatedMessage('yes', player) end
			return translatedMessage(data.right_button, player)
		end)
		:onClick(function(self, player)
			if eventTradeNPC then
				local data = self.parent.args[player][1]
				if confirming[player] ~= false then
					confirming[player] = false
					self.parent:update(player, data)
					return
				end
				eventTradeNPC(player, data.name, false)
			end
		end)
		:canUpdate(true):onUpdate(function(self, player)
			local data = self.parent.args[player][1]
			if data.right_disabled then
				self:disable(player)
			else
				self:enable(player)
			end
		end)
		:setPosition(225, 285):setSize(150, 15)
	)

	-- Close Button
	:loadComponent(
		Button.new():setTranslation("close")
		:onClick(function(self, player)
			self.parent:remove(player)
		end)
		:setPosition(50, 325):setSize(300, 15)
	)
end