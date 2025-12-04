local PowerTracker = {}
do
	local pageIndex = {}

	local nameCache = {}
	local function formatName(name)
		if nameCache[name] then
			return nameCache[name]
		end

		nameCache[name] = string.gsub(
			string.gsub(name, "(#%d%d%d%d)", "<font size='10'><g>%1</g></font>"),
			"([Hh]t)tp", "%1<->tp"
		)
		return nameCache[name]
	end

	for i=1, 3 do
		PowerTracker[i] = Interface.new(-200 + 400 * (i - 1), 50, 400, 320, true)
			:addTextArea({
				color = {0x333333, 0x444444, 0.7}
			})

			:addTextArea({
				alpha = 0,
				text = "<p align='center'><font size='14'><cep><b>Power Tracker</b></cep></font></p>"
			})

			:addTextArea({
				canUpdate = true,
				y = 25, height = 260,
				alpha = 0,

				text = function(self, player, powers)
					local pieces, count = {}, 0

					local power
					local start = math.min(pageIndex[player] or powers._count, powers._count)
					if start == powers._count then
						pageIndex[player] = nil
					end
					for index = start, math.max(start - 18, 1), -1 do
						power = powers[index]
						count = count + 1
						if power == '-' then
							pieces[count] = '<p align="center"><R>------ NEW ROUND ------</R></p>'
						else
							pieces[count] = formatName(power[1]) .. "<n> -> </n><a href='event:showpow:" .. power[3] .. ":" .. power[4] .. "'>" .. power[2] .. "</a>"
						end
					end

					return "<v>" .. table.concat(pieces, "\n")
				end
			})

			:loadComponent(
				Button.new():setText("&lt;")

				:onClick(function(self, player)
					if i == 1 or not checkCooldown(player, "settrackpos", 1000) then
						return
					end
					self.parent:remove(player)
					PowerTracker[1]:show(player, self.parent.args[player][1])
					players_file[player].tracki = 1
					savePlayerData(player)
				end)

				:setPosition(10, 295):setSize(30, 15)
			)

			:loadComponent(
				Button.new():setText("_")

				:onClick(function(self, player)
					if i == 2 or not checkCooldown(player, "settrackpos", 1000) then
						return
					end
					self.parent:remove(player)
					PowerTracker[2]:show(player, self.parent.args[player][1])
					players_file[player].tracki = 1
					savePlayerData(player)
				end)

				:setPosition(55, 295):setSize(30, 15)
			)

			:loadComponent(
				Button.new():setText(">")

				:onClick(function(self, player)
					if i == 3 or not checkCooldown(player, "settrackpos", 1000) then
						return
					end
					self.parent:remove(player)
					PowerTracker[3]:show(player, self.parent.args[player][1])
					players_file[player].tracki = 3
					savePlayerData(player)
				end)

				:setPosition(100, 295):setSize(30, 15)
			)

			:loadComponent(
				Button.new():setTranslation("close")

				:onClick(function(self, player)
					self.parent:remove(player)
				end)

				:setPosition(170, 295):setSize(60, 15)
			)

			:loadComponent(
				Button.new():setText("^")

				:onClick(function(self, player)
					local powers = self.parent.args[player][1]
					pageIndex[player] = math.min((pageIndex[player] or powers._count) + 18, powers._count)
					self.parent:update(player, powers)
				end)

				:setPosition(315, 295):setSize(30, 15)
			)
			:loadComponent(
				Button.new():setText("v")

				:onClick(function(self, player)
					local powers = self.parent.args[player][1]
					pageIndex[player] = math.max((pageIndex[player] or powers._count) - 18, 1)
					self.parent:update(player, powers)
				end)

				:setPosition(360, 295):setSize(30, 15)
			)
			
			:onRemove(function(self, player)
				pageIndex[player] = nil
			end)
	end
end