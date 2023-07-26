local PowersInterface
do
	local selection, power
	for index = 1, #powers do
		selection = 1
		power = powers[index]
		if power.default then
			power.key = keyboard.keys[ power.default[1] ][ power.default[2] ]

			for layer = 1, power.default[1] - 1 do
				selection = selection + #keyboard.keys[layer]
			end

			power.default = selection + power.default[2]
		end
	end

	local images = {}

	local function getPlayerPower(player, power)
		local upgrades = power.upgrades
		if upgrades then
			local completed = players_file[player].c
			local pos = leaderboard[player] or max_leaderboard_rows + 1
			for index = #upgrades, 1, -1 do
				if upgrades[index].ranking then
					if pos <= upgrades[index].ranking then
						return upgrades[index]
					end
				elseif upgrades[index].maps <= completed then
					return upgrades[index]
				end
			end
		end
		return power
	end

	local function rebindKeys(player, power, old, new)
		power = getPowerUpgrade(
			players_file[player].c,
			leaderboard[player] or max_leaderboard_rows + 1,
			powers[power], true
		)
		if not power then return end

		local triggers = keys.triggers[player]
		local oldPowers = triggers[old]
		if oldPowers then
			if oldPowers._count == 1 then
				triggers[old] = nil
				bindKeyboard(player, old, true, false)
			else
				for index = 1, oldPowers._count do
					if oldPowers[index] == power then
						oldPowers[index] = nil
						break
					end
				end

				local delete = true
				for index = 1, oldPowers._count do
					if oldPowers[index] then
						delete = false
						break
					end
				end
				if delete then
					triggers[old] = nil
					bindKeyboard(player, old, true, false)
				end
			end
		end

		if not triggers[new] then
			triggers[new] = {_count = 1, [1] = power}
			bindKeyboard(player, new, true, true)
		else
			triggers[new]._count = triggers[new]._count + 1
			triggers[new][ triggers[new]._count ] = power
		end
	end

	local defaultKeyToggle
	PowersInterface = Interface.new(55, 28, 685, 366, true)
		:setDefaultArgs(1)

		:addImage({
			image = "173d539e4a0.png",
			target = ":1",
			y = -5, x = -5
		})

		:addTextArea({
			text = function(self, player, power)
				return translatedMessage("maps_info", player, players_file[player].c)
			end,
			alpha = 0,
			x = 525, y = 5,
			width = 150, height = 50
		})

		:addTextArea({
			text = function(self, player, power)
				return translatedMessage("weekly_info", player, weekleaderboard[player] and ("#" .. weekleaderboard[player]) or "N/A")
			end,
			alpha = 0,
			x = 525, y = 45,
			width = 150, height = 50
		})

		:addTextArea({
			text = function(self, player, power)
				return translatedMessage("overall_info", player, leaderboard[player] and ("#" .. leaderboard[player]) or "N/A")
			end,
			alpha = 0,
			x = 520, y = 85,
			width = 160, height = 50
		})

		:addTextArea({
			canUpdate = true,
			text = function(self, player, power)
				local upgrades, completed = powers[power].upgrades, players_file[player].c
				local pos = leaderboard[player] or max_leaderboard_rows + 1
				local cond
				if powers[power].ranking then
					cond = pos <= powers[power].ranking
				else
					cond = completed >= powers[power].maps
				end

				if cond then
					if upgrades then
						for index = 1, #upgrades do
							if upgrades[index].ranking then
								if pos > upgrades[index].ranking then
									return translatedMessage(
										"upgrade_power_rank", player,
										"#" .. upgrades[index].ranking, translatedMessage(upgrades[index].name, player)
									)
								end
							elseif completed < upgrades[index].maps then
								return translatedMessage(
									"upgrade_power", player,
									upgrades[index].maps, translatedMessage(upgrades[index].name, player)
								)
							end
						end
					end
					return ""
				end

				if powers[power].ranking then
					return translatedMessage(
						"unlock_power_rank", player,
						"#" .. powers[power].ranking, translatedMessage(powers[power].name, player)
					)
				end
				return translatedMessage(
					"unlock_power", player,
					powers[power].maps, translatedMessage(powers[power].name, player)
				)
			end,
			alpha = 0,
			x = 5, y = 70,
			width = 185, height = 70
		})

		:addTextArea({
			canUpdate = true,
			text = function(self, player, power)
				local name = getPlayerPower(player, powers[power]).name
				return "<p align='center'><font size='20'><vp><b>" .. translatedMessage(name, player)
			end,
			alpha = 0,
			height = 50, width = 485,
			x = 100
		})

		:addTextArea({
			x = 37, y = 5,
			alpha = 0,
			width = 400,
			translation = "power_options",
			canUpdate = false
		})
		:loadComponent(
			Toggle.new(10, 10, false)
			:onToggle(function(self, player, state)
				if Keyboard.open[player] then
					local power = self.parent.args[player][1]
					if keys[player][power] then
						Keyboard:update(player, state, nil, keyboard.bindings[ keys[player][power] ])
					else
						Keyboard:update(player, state, powers[power].default)
					end
				elseif Keyboard.args[player] then
					Keyboard.args[player][1] = state
				end

				players_file[player].settings[5] = state and 1 or 0

				if victory[player] then
					unbind(player)
					if not no_powers[player] then
						bindNecessary(player)
					end
				end

				savePlayerData(player)
			end)
			:onUpdate(function(self, player)
				local state = not not self.state[player]
				local setting = players_file[player].settings[5] == 1
				if state ~= setting then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(10, 36, false)
			:onToggle(function(self, player, state)
				eventParsedTextAreaCallback(0, player, "prof_maps", state and "private" or "public")
			end)
			:onUpdate(function(self, player)
				local state = not not self.state[player]
				local setting = not not players_file[player].private_maps
				if state ~= setting then
					self:toggle(player)
				end
			end)
		)
		:loadComponent(
			Toggle.new(10, 62, false)
			:onToggle(function(self, player, state)
				if not state or not Keyboard.open[player] then
					self:toggle(player)

				else
					local power = PowersInterface.args[player][1]
					local pkeys = players_file[player].keys

					local key
					if powers[power].key[1] then -- variation qwerty/azerty
						local setting = players_file[player].settings[5] + 1
						key = powers[power].key[setting]
					else
						key = powers[power].key
					end
					local old = keys[player][power]
					local new = keyboard.bindings[key]

					keys[player][power] = new
					pkeys[power] = 0

					for index = 1, power do
						if not pkeys[index] then
							pkeys[index] = 0
						end
					end

					savePlayerData(player)

					Keyboard:update(player, Keyboard.args[player][1], nil, key)

					if not keys.triggers[player] then return end
					rebindKeys(player, power, old, new)
				end
			end)
			:onUpdate(function(self, player)
				if not self.canUpdate then
					defaultKeyToggle = self

					local textareas = self.parent.textareas
					local clickable = textareas[ self.id - textareas[1].id + 2 ]

					self.canUpdate = true
					clickable.canUpdate = true
				end

				local power = PowersInterface.args[player][1]
				local key = players_file[player].keys[power]

				local state = key == 0 or not key

				if (not not self.state[player]) ~= state then
					self:toggle(player)
				end
			end)
		)

		:onUpdate(function(self, player, power)
			if not images[player] then
				images[player] = {}
			else
				for idx = 1, 4 do
					if images[player][idx] then
						tfm.exec.removeImage(images[player][idx])
					end
				end
			end

			if powers[power].click then
				if Keyboard.open[player] then
					Keyboard:remove(player)
				end
				images[player][4] = tfm.exec.addImage(
					"173de7d5a5c.png", ":7",
					self.x + 250, self.y + 140, player
				)

			else
				local numkey = powers[power].default
				local keyname
				if keys[player][power] then
					numkey = nil
					keyname = keyboard.bindings[ keys[player][power] ]
				end

				if not Keyboard.open[player] then
					local qwerty = (self.open[player] and Keyboard.args[player][1] or
									players_file[player].settings[5] == 1)

					Keyboard:show(player, qwerty, numkey, keyname)
				else
					Keyboard:update(player, Keyboard.args[player][1], numkey, keyname)
				end
			end

			local completed = players_file[player].c
			local pos = leaderboard[player] or max_leaderboard_rows + 1
			local img, cond
			if power > 1 then
				if powers[power - 1].ranking then
					cond = pos <= powers[power - 1].ranking
				else
					cond = completed >= powers[power - 1].maps
				end

				if cond then
					img = getPlayerPower(player, powers[power - 1])
				else
					img = powers[power - 1]
				end
				images[player][1] = tfm.exec.addImage(
					img[(not cond) and "lockedSmall" or "small"],
					":2", self.x + 240 - img.smallX, self.y + 50 + img.smallY, player
				)
			end

			if powers[power].ranking then
				cond = pos <= powers[power].ranking
			else
				cond = completed >= powers[power].maps
			end

			if cond then
				img = getPlayerPower(player, powers[power])
			else
				img = powers[power]
			end
			images[player][2] = tfm.exec.addImage(
				img[(not cond) and "lockedBig" or "big"],
				":3", self.x + 300 + img.bigX, self.y + 30 + img.bigY, player
			)

			if power < #powers then
				if powers[power + 1].ranking then
					cond = pos <= powers[power + 1].ranking
				else
					cond = completed >= powers[power + 1].maps
				end

				if cond then
					img = getPlayerPower(player, powers[power + 1])
				else
					img = powers[power + 1]
				end
				images[player][3] = tfm.exec.addImage(
					img[(not cond) and "lockedSmall" or "small"],
					":4", self.x + 380 + img.smallX, self.y + 50 + img.smallY, player
				)
			end
		end)
		:onRemove(function(self, player)
			Keyboard:remove(player)

			for idx = 1, 4 do
				if images[player][idx] then
					tfm.exec.removeImage(images[player][idx])
				end
			end
		end)

		:addImage({
			image = "173d9bf80a1.png",
			target = ":5",
			x = 195, y = 50
		})
		:addTextArea({
			canUpdate = true,
			x = 193, y = 47,
			text = function(self, player, power)
				if power > 1 then
					return "<a href='event:power:" .. (power - 1) .. "'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
				end
				return ""
			end,
			width = 26, height = 55,
			alpha = 0
		})

		:addImage({
			image = "173d9bfa12a.png",
			target = ":6",
			x = 460, y = 50
		})
		:addTextArea({
			canUpdate = true,
			x = 458, y = 47,
			text = function(self, player, power)
				if power < #powers then
					return "<a href='event:power:" .. (power + 1) .. "'>\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
				end
				return ""
			end,
			width = 26, height = 55,
			alpha = 0
		})

	onEvent("ParsedTextAreaCallback", function(id, player, action, args)
		if not PowersInterface.open[player] then return end

		if action == "power" then
			if not checkCooldown(player, "showpowers", 1000) then return end
			page = tonumber(args)

			if page > 0 and page <= #powers then
				PowersInterface:update(player, page)
			end
		elseif Keyboard.open[player] and action == "keyboard" then
			if not checkCooldown(player, "changeKeys", 1000) then return end

			local binding = keyboard.bindings[args]
			if binding then
				Keyboard:update(player, Keyboard.args[player][1], nil, args)

				if defaultKeyToggle and defaultKeyToggle.state[player] then
					defaultKeyToggle:toggle(player)
				end

				local power = PowersInterface.args[player][1]
				local old = keys[player][power]
				if old == binding then return end

				if not old then
					if powers[power].key[1] then -- variation qwerty/azerty
						old = keyboard.bindings[ powers[power].key[ players_file[player].settings[5] + 1 ] ]
					else
						old = keyboard.bindings[ powers[power].key ]
					end
				end

				local pkeys = players_file[player].keys
				local count = 0
				for index = 1, #pkeys do
					if pkeys[index] == binding then
						count = count + 1
					end
				end

				if count >= 2 then
					return translatedChatMessage("max_power_keys", player, 2)
				end

				pkeys[power] = binding
				for index = 1, power do
					if not pkeys[index] then
						pkeys[index] = 0
					end
				end

				keys[player][power] = binding
				savePlayerData(player)

				if not keys.triggers[player] then return end
				rebindKeys(player, power, old, binding)
			end
		end
	end)
end