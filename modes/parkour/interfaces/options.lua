local no_help
local OptionsInterface = Interface.new(168, 46, 465, 330, true)
	:loadTemplate(WindowBackground)

	:addTextArea({
		translation = "options",
		alpha = 0
	})
	:loadComponent(
		Button.new():setTranslation("close")
		:onClick(function(self, player)
			self.parent:remove(player)
		end)
		:setPosition(10, 305):setSize(445, 15)
	)
	:onRemove(function(self, player)
		savePlayerData(player)
	end)

	:loadComponent(
		Toggle.new(435, 55, false)
		:onToggle(function(self, player, state) -- particles or images for checkpoints
			players_file[player].parkour.ckpart = state and 1 or 0
			ck.particles[player] = state

			if state then
				if ck.images[player] then
					tfm.exec.removeImage(ck.images[player])
				end
			else
				addCheckpointImage(player)
			end
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].parkour.ckpart == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 81, false)
		:onToggle(function(self, player, state) -- qwerty or azerty keyboard
			players_file[player].parkour.keyboard = state and 1 or 0

			if victory[player] then
				unbind(player)
				if not no_powers[player] then
					bindNecessary(player)
				end
			end
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].parkour.keyboard == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 107, false)
		:onToggle(function(self, player, state) -- M or DEL for mort
			players_file[player].parkour.mort = state and 1 or 0

			if state then
				bindKeyboard(player, 77, true, true)
				bindKeyboard(player, 46, true, false)
			else
				bindKeyboard(player, 77, true, false)
				bindKeyboard(player, 46, true, true)
			end
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].parkour.mort == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 133, false)
		:onToggle(function(self, player, state) -- powers cooldown
			players_file[player].parkour.pcool = state and 1 or 0
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].parkour.pcool == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 159, false)
		:onToggle(function(self, player, state) -- powers button
			players_file[player].parkour.pbut = state and 1 or 0

			GameInterface:update(player)
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].parkour.pbut == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 185, false)
		:onToggle(function(self, player, state) -- help button
			players_file[player].parkour.hbut = state and 1 or 0

			GameInterface:update(player)
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].parkour.hbut == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 211, false)
		:onToggle(function(self, player, state) -- congrats messages
			players_file[player].parkour.congrats = state and 1 or 0
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].parkour.congrats == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 238, false)
		:onToggle(function(self, player, state) -- no help indicator
			players_file[player].parkour.help = state and 1 or 0

			if not state then
				if no_help[player] then
					tfm.exec.removeImage(no_help[player])
					no_help[player] = nil
				end
			else
				no_help[player] = tfm.exec.addImage("1722eeef19f.png", "$" .. player, -10, -35)
			end
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].parkour.help == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)