do	

	local isQuestSkipped = {}
	local function checkQuestSkipped(player)
		if not players_file[player].quests then return end

		isQuestSkipped[player] = {
			weekly = false,
			daily = false,
		}

		for i = 1, #players_file[player].quests do
			if players_file[player].quests[i].skp and players_file[player].quests[i].skp > 1 then
				if i <= 4 then
					isQuestSkipped[player].daily = true
				else
					isQuestSkipped[player].weekly = true
				end
			end
		end

	end

	local closeButton = Button.new()
	QuestsInterface = Interface.new(200, 35, 400, 350, true)
		:loadTemplate(WindowBackground)
		:setShowCheck(function(self, player, page, data)
			checkQuestSkipped(player)
			if not players_file[player].quests then
				tfm.exec.chatMessage("<c> No quest data.", player)
				return false
			end
			if not data then
				local getPage = page and page or 1
				self:show(player, getPage, players_file[player].quests)
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
				self.parent:update(player, 1)
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == 1 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(20, 15):setSize(170, 18)
		)

		:loadComponent( -- Weekly button
			Button.new():setTranslation("weekly_q")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "weekly_quest_button", 3000) then return end
				self.parent:update(player, 2)
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == 2 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(210, 15):setSize(170, 18)
		)

		:addTextArea({ -- Reset Time
			x = 10, y = 42,
			width = 120, height = 40,
			canUpdate = true,
			text = function(self, player, page)
				local currentTime = os.time() + 60 * 60 * 1000
				local reset_time = getQuestsResetTime() -- reset_time = {last_daily_reset, last_weekly_reset, next_daily_reset, next_weekly_reset}

				local day = 24 * 60 * 60 * 1000
				local hour = 1 * 60 * 60 * 1000
				local minute = 1 * 60 * 1000

				local weekly_diff = reset_time[4] - currentTime
				local daily_diff = reset_time[3] - currentTime

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
				else
					return translatedMessage("weekly_quests", player)
				end
			end,
			alpha = 0
		})

		:addTextArea({ -- Quest 1
			x = 10, y = 85,
			width = 380, height = 40,
			alpha = 1,
			color = {0x314e57, 0x314e57}
		})
		:addImage({ -- Coin Image
			image = "18b29f6977c.png",
			target = "~8",
			x = 25, y = 82
		})
		:addTextArea({ -- Prize
			x = 15, y = 110,
			width = 50, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and players_file[player].quests[1].id or players_file[player].quests[5].id
				local isWeekly = (page ~= 1)

				return string.format(
					"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s", quests[questID].prize(player, isWeekly)
				)
			end
		})
		:addTextArea({ -- Quest 1 Description
			x = 80, y = 85,
			width = 270, height = 40,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and players_file[player].quests[1].id or players_file[player].quests[5].id
				local isWeekly = (page ~= 1)

				return quests[questID].description(player, isWeekly)
			end
		})
		:addImage({
			canUpdate = true,
			image = function(self, player, page, data)
				local questCompleted = false
				if (page == 1 and players_file[player].quests[1].ts) or (page == 2 and players_file[player].quests[5].ts) then
					questCompleted = true
				end

				local questSkipped = false
				if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
					questSkipped = true
				end

				if questCompleted then
					return "18bdfe01bb3.png"
				elseif questSkipped then
					return "a.png"
				else
					return "18bab04d3a9.png"
				end
			end,
			
			target = "~10",
			x = 360, y = 95,
		})
		:addTextArea({ -- Change TA
			x = 360, y = 95,
			width = 20, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and 1 or 5

				local questCompleted = false
				if players_file[player].quests[questID].ts then
					questCompleted = true
				end

				local questSkipped = false
				if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
					questSkipped = true
				end

				if questSkipped or questCompleted then return "" end
				
				return string.format("<a href='event:change_quest:%s:%s'><font size='50'>  </font></a>", questID, page)
			end
		})


		:addTextArea({ -- Quest 2
			x = 10, y = 145,
			width = 380, height = 40,
			alpha = 1,
			color = {0x314e57, 0x314e57}
		})
		:addImage({ -- Coin Image
			image = "18b29f6977c.png",
			target = "~8",
			x = 25, y = 142
		})
		:addTextArea({ -- Prize
			x = 15, y = 170,
			width = 50, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and players_file[player].quests[2].id or players_file[player].quests[6].id
				local isWeekly = (page ~= 1)

				return string.format(
					"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s", quests[questID].prize(player, isWeekly)
				)
			end
		})
		:addTextArea({ -- Quest 2 Description
			x = 80, y = 145,
			width = 270, height = 40,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and players_file[player].quests[2].id or players_file[player].quests[6].id
				local isWeekly = (page ~= 1)

				return quests[questID].description(player, isWeekly)
			end
		})
		:addImage({
			canUpdate = true,
			image = function(self, player, page, data)
				local questCompleted = false
				if (page == 1 and players_file[player].quests[2].ts) or (page == 2 and players_file[player].quests[6].ts) then
					questCompleted = true
				end

				local questSkipped = false
				if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
					questSkipped = true
				end

				if questCompleted then
					return "18bdfe01bb3.png"
				elseif questSkipped then
					return "a.png"
				else
					return "18bab04d3a9.png"
				end
			end,
			
			target = "~20",
			x = 360, y = 155,
		})
		:addTextArea({ -- Change TA
			x = 360, y = 155,
			width = 20, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and 2 or 6

				local questCompleted = false
				if players_file[player].quests[questID].ts then
					questCompleted = true
				end

				local questSkipped = false
				if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
					questSkipped = true
				end

				if questSkipped or questCompleted then return "" end

				return string.format("<a href='event:change_quest:%s:%s'><font size='50'>  </font></a>", questID, page)
			end
		})


		:addTextArea({ -- Quest 3
			x = 10, y = 205,
			width = 380, height = 40,
			alpha = 1,
			color = {0x314e57, 0x314e57}
		})
		:addImage({ -- Coin Image
			image = "18b29f6977c.png",
			target = "~8",
			x = 25, y = 202
		})
		:addTextArea({ -- Prize
			x = 15, y = 230,
			width = 50, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and players_file[player].quests[3].id or players_file[player].quests[7].id
				local isWeekly = (page ~= 1)

				return string.format(
					"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s", quests[questID].prize(player, isWeekly)
				)
			end
		})
		:addTextArea({ -- Quest 3 Description
			x = 80, y = 205,
			width = 270, height = 40,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and players_file[player].quests[3].id or players_file[player].quests[7].id
				local isWeekly = (page ~= 1)

				return quests[questID].description(player, isWeekly)
			end
		})
		:addImage({
			canUpdate = true,
			image = function(self, player, page, data)
				local questCompleted = false
				if (page == 1 and players_file[player].quests[3].ts) or (page == 2 and players_file[player].quests[7].ts) then
					questCompleted = true
				end

				local questSkipped = false
				if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
					questSkipped = true
				end

				if questCompleted then
					return "18bdfe01bb3.png"
				elseif questSkipped then
					return "a.png"
				else
					return "18bab04d3a9.png"
				end
			end,
			
			target = "~30",
			x = 360, y = 215,
		})
		:addTextArea({ -- Change TA
			x = 360, y = 215,
			width = 20, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and 3 or 7

				local questCompleted = false
				if players_file[player].quests[questID].ts then
					questCompleted = true
				end

				local questSkipped = false
				if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
					questSkipped = true
				end

				if questSkipped or questCompleted then return "" end

				return string.format("<a href='event:change_quest:%s:%s'><font size='50'>  </font></a>", questID, page)
			end
		})


		:addTextArea({ -- Quest 4
			x = 10, y = 265,
			width = 380, height = 40,
			alpha = 1,
			color = {0x314e57, 0x314e57}
		})
		:addImage({ -- Coin Image
			image = "18b29f6977c.png",
			target = "~8",
			x = 25, y = 262
		})
		:addTextArea({ -- Prize
			x = 15, y = 290,
			width = 50, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and players_file[player].quests[4].id or players_file[player].quests[8].id
				local isWeekly = (page ~= 1)

				return string.format(
					"<p align='center'><font color='#ffffff' size='14' face='Verdana'><b>%s", quests[questID].prize(player, isWeekly)
				)
			end
		})
		:addTextArea({ -- Quest 4 Description
			x = 80, y = 265,
			width = 270, height = 40,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and players_file[player].quests[4].id or players_file[player].quests[8].id
				local isWeekly = (page ~= 1)

				return quests[questID].description(player, isWeekly)
			end
		})
		:addImage({
			canUpdate = true,
			image = function(self, player, page, data)
				local questCompleted = false
				if (page == 1 and players_file[player].quests[4].ts) or (page == 2 and players_file[player].quests[8].ts) then
					questCompleted = true
				end

				local questSkipped = false
				if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
					questSkipped = true
				end

				if questCompleted then
					return "18bdfe01bb3.png"
				elseif questSkipped then
					return "a.png"
				else
					return "18bab04d3a9.png"
				end
			end,
			
			target = "~40",
			x = 360, y = 275,
		})
		:addTextArea({ -- Change TA
			x = 360, y = 275,
			width = 20, height = 20,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, data)
				local questID = page == 1 and 4 or 8

				local questCompleted = false
				if players_file[player].quests[questID].ts then
					questCompleted = true
				end

				local questSkipped = false
				if (page == 1 and isQuestSkipped[player].daily) or (page == 2 and isQuestSkipped[player].weekly) then
					questSkipped = true
				end

				if questSkipped or questCompleted then return "" end

				return string.format("<a href='event:change_quest:%s:%s'><font size='50'>  </font></a>", questID, page)
			end
		})
	
end