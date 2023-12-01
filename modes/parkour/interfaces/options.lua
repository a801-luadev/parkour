local no_help
local OptionsInterface = Interface.new(168, 46, 465, 330, true)
OptionsInterface
	:loadTemplate(WindowBackground)
	:addTextArea({
		text = function(self, player)
			return translatedMessage("options", player)
				:format(string.char(
					players_file[player].settings[2] == 46 and 77
					or players_file[player].settings[2]
				))
		end,
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
		:onToggle(function(self, player, state) -- qwerty or azerty keyboard
			players_file[player].settings[5] = state and 1 or 0

			if victory[player] then
				unbind(player)
				if not no_powers[player] then
					bindNecessary(player)
				end
			end
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].settings[5] == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 81, false)
		:onToggle(function(self, player, state) -- Any or M or DEL for mort
			local previous_key = players_file[player].settings[2]
			local key = state and (previous_key ~= 46 and previous_key or 77) or 46
			players_file[player].settings[2] = key

			if state then
				bindKeyboard(player, key, true, true)
				bindKeyboard(player, 46, true, false)
			else
				bindKeyboard(player, previous_key, true, false)
				bindKeyboard(player, 46, true, true)
			end

			OptionsInterface:remove(player)
			OptionsInterface:show(player)
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].settings[2] ~= 46
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 107, false)
		:onToggle(function(self, player, state) -- powers cooldown
			players_file[player].settings[3] = state and 1 or 0
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].settings[3] == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 133, false)
		:onToggle(function(self, player, state) -- powers button
			players_file[player].settings[4] = state and 1 or 0

			GameInterface:update(player)
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].settings[4] == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 159, false)
		:onToggle(function(self, player, state) -- help button
			players_file[player].settings[6] = state and 1 or 0

			GameInterface:update(player)
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].settings[6] == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 185, false)
		:onToggle(function(self, player, state) -- congrats messages
			players_file[player].settings[7] = state and 1 or 0
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].settings[7] == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 211, false)
		:onToggle(function(self, player, state) -- no help indicator
			players_file[player].settings[8] = state and 1 or 0

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
			local setting = players_file[player].settings[8] == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)
	:loadComponent(
		Toggle.new(435, 237, false)
		:onToggle(function(self, player, state) -- disable ui hotkeys
			players_file[player].settings[9] = state and 1 or nil
		end)
		:onUpdate(function(self, player)
			local setting = players_file[player].settings[9] == 1
			if (self.state[player] and not setting) or (not self.state[player] and setting) then
				self:toggle(player)
			end
		end)
	)

onEvent("ParsedTextAreaCallback", function(id, player, action, args)
	if not OptionsInterface.open[player] then return end

	if action == "keyboardmort" then
		if not checkCooldown(player, "changeKeys", 1000) then return end

		if Keyboard.open[player] then
			Keyboard:remove(player)
			return
		end

		local qwerty = players_file[player].settings[5] == 1

		Keyboard:show(player, qwerty, numkey, keyname) -- numkey, keyname
	elseif Keyboard.open[player] and action == "keyboard" then
		if not checkCooldown(player, "changeKeys", 1000) then return end

		local binding = keyboard.bindings[args]
		if not binding then return end

		local previous_key = players_file[player].settings[2]
		players_file[player].settings[2] = binding

		bindKeyboard(player, previous_key, true, false)
		bindKeyboard(player, binding, true, true)

		savePlayerData(player)

		Keyboard:remove(player)

		-- Update key
		OptionsInterface:remove(player)
		OptionsInterface:show(player)
	end
end)