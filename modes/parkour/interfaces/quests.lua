local QuestsInterface

do
	local closeButton = Button.new()

	QuestsInterface = Interface.new(200, 35, 400, 350, true)
		:loadTemplate(WindowBackground)
		:setShowCheck(function(self, player, page, data)
			if not data then
				data = players_file[player]

				if data then
					self:show(player, page or 1, data)
				end

				return false
			end

			return true
		end)

		:loadComponent( -- Close button
			closeButton:setText("")
			:onClick(function(self, player)
				self.parent:remove(player)
			end)
			:setPosition(50, 330):setSize(300, 10)
		)
		:addTextArea({
			x = 50, y = 326,
			width = 300, height = 15,
			text = function(self, player)
				return ("<a href='event:" .. closeButton.callback ..
						"'><p align='center'>".. translatedMessage("close", player))
			end,
			alpha = 0
		})

		:loadComponent( -- Daily button
			Button.new():setTranslation("daily_q") 

			:onClick(function(self, player, page)
				if not checkCooldown(player, "daily_quest_button", 3000) then return end
				if not players_file[player] then return end

				self.parent:update(player, 1, players_file[player])
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == 1 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(10, 15):setSize(120, 18)
		)

		:loadComponent( -- Weekly button
			Button.new():setTranslation("weekly_q")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "weekly_quest_button", 3000) then return end
				if not players_file[player] then return end

				self.parent:update(player, 2, players_file[player])
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == 2 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(150, 15):setSize(110, 18)
		)

		:loadComponent( -- Milestone button
			Button.new():setTranslation("milestone_q")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "milestone_quest_button", 3000) then return end
				if not players_file[player] then return end

				self.parent:update(player, 3, players_file[player])
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == 3 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(280, 15):setSize(110, 18)
		)

		:addTextArea({ -- Reset Time
			x = 10, y = 42,
			width = 120, height = 40,
			canUpdate = true,
			text = function(self, player, page)
				if page == 3 then return "" end

				local currentTime = os.time()
				local next_daily, next_weekly = Quests.get_next_reset()

				local day = 24 * 60 * 60 * 1000
				local hour = 1 * 60 * 60 * 1000
				local minute = 1 * 60 * 1000

				local daily_diff = next_daily - currentTime
				local weekly_diff = next_weekly - currentTime

				local weekly_days = math.floor(weekly_diff / day)
				local weekly_hours = math.floor((weekly_diff % day) / hour)
				local weekly_minutes = math.floor((weekly_diff % hour) / minute)

				local daily_hours = math.floor(daily_diff / hour)
				local daily_minutes = math.floor((daily_diff % hour) / minute)

				local daily_coming = string.format("%sh %sm", daily_hours, daily_minutes)
				local weekly_coming = string.format("%sd %sh %sm", weekly_days, weekly_hours, weekly_minutes)

				if page == 1 then
					return translatedMessage("next_reset", player, daily_coming)
				else
					return translatedMessage("next_reset", player, weekly_coming)
				end
			end,
			alpha = 0
		})

		:addTextArea({ -- Title
			x = 10, y = 40,
			width = 380, height = 30,
			canUpdate = true,
			text = function(self, player, page)
				if page == 1 then
					return translatedMessage("daily_quests", player)
				elseif page == 2 then
					return translatedMessage("weekly_quests", player)
				else
					return translatedMessage("milestone_quests", player)
				end
			end,
			alpha = 0
		})

	for i=1, 4 do
		QuestsInterface
		:addTextArea({ -- Background
			x = 10, y = 25 + 60 * i,
			width = 380, height = 40,
			alpha = 0,
			color = {0x314e57, 0x314e57}
		})
		:addImage({ -- Reward Image
			canUpdate = true,
			target = "~8",
			x = 25, y = 22 + 60 * i,
			image = function(self, player, page, data)
				if page == 3 then
					return "01010101010.png"
				end
				return "18b29f6977c.png"
			end,
		})
		:addTextArea({ -- Prize
			x = 15, y = 50 + 60 * i,
			width = 50, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				if page == 3 then
					return ""
				end

				local index = i + (page == 2 and 4 or 0)
				return string.format(
					"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s",
					Quests[data:quest_id(index)].prize(player, data, index)
				)
			end
		})
		:addTextArea({ -- Description
			x = 10, y = 25 + 60 * i,
			width = 340, height = 40,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				if page == 3 then
					return "<textformat leftMargin='0'>" .. Milestones[i].description(player, data)
				end

				local index = i + (page == 2 and 4 or 0)
				return "<textformat leftMargin='70'>" .. Quests[data:quest_id(index)].description(player, data, index)
			end
		})
		:addImage({ -- Milestone Image
			canUpdate = true,
			image = function(self, player, page, data)
				if page ~= 3 then
					return "01010101010.png"
				end

				local completed = Milestones[i].completed(player, data)
				if completed == nil then return "01010101010.png" end
				return completed and "17797d878fa.png" or "17797d860b6.png"
			end,

			target = "~10",
			x = 370, y = 45 + 60 * i,
			anchorX = 0.5, anchorY = 0.5,
		})
		:addImage({ -- Skip Button Image
			canUpdate = true,
			image = function(self, player, page, data)
				if page == 3 then
					return "01010101010.png"
				end

				local index = i + (page == 2 and 4 or 0)

				-- completed
				if data:quest_ts(index) > 0 then
					return "18bdfe01bb3.png"
				end

				-- skipped
				if Quests.skipped(data, index) then
					return "img@199ac2e9c66"
				end

				return "18bab04d3a9.png"
			end,

			target = "~10",
			x = 360, y = 35 + 60 * i,
		})
		:addTextArea({ -- Skip Button
			x = 360, y = 35 + 60 * i,
			width = 20, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				if page == 3 then return "" end

				local index = i + (page == 2 and 4 or 0)

				-- skipped
				if Quests.skipped(data, index) then return "" end

				local ts = data:quest_ts(index)

				-- completed
				if ts > 0 then return "" end

				return string.format("<a href='event:change_quest:%s'><font size='50'>  </font></a>", index)
			end
		})
	end
end
