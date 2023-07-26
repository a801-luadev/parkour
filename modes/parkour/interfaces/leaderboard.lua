local LeaderboardInterface
do
	local community_images = {}
	local communities = {
		xx = "1651b327097.png",
		ar = "1651b32290a.png",
		bg = "1651b300203.png",
		br = "1651b3019c0.png",
		cn = "1651b3031bf.png",
		cz = "1651b304972.png",
		de = "1651b306152.png",
		ee = "1651b307973.png",
		en = "1723dc10ec2.png",
		e2 = "1723dc10ec2.png",
		es = "1651b309222.png",
		fi = "1651b30aa94.png",
		fr = "1651b30c284.png",
		gb = "1651b30da90.png",
		hr = "1651b30f25d.png",
		hu = "1651b310a3b.png",
		id = "1651b3121ec.png",
		he = "1651b3139ed.png",
		it = "1651b3151ac.png",
		jp = "1651b31696a.png",
		lt = "1651b31811c.png",
		lv = "1651b319906.png",
		nl = "1651b31b0dc.png",
		ph = "1651b31c891.png",
		pl = "1651b31e0cf.png",
		pt = "17459ce7e29.png",
		ro = "1651b31f950.png",
		ru = "1651b321113.png",
		tr = "1651b3240e8.png",
		vk = "1651b3258b3.png"
	}
	local separator = string.rep("¯", 50)

	LeaderboardInterface = Interface.new(168, 46, 465, 330, true)
		:avoidDoubleUpdates()
		:loadTemplate(WindowBackground)
		:setShowCheck(function(self, player, data, page, weekly)
			if not loaded_leaderboard then
				translatedChatMessage("leaderboard_not_loaded", player)
				return false
			end
			if not data then
				self:show(player, leaderboard, 0, false)
				return false
			end
			return true
		end)

		-- Titles
		:addTextArea({
			text = function(self, player)
				return string.format(
					"<p align='center'><font size='28'><B><D>%s</D></B></font>\n<font color='#32585E'>%s</font></p>",
					translatedMessage("leaderboard", player),
					separator
				)
			end,
			alpha = 0
		}):addTextArea({
			x = 12, y = 54,
			width = 50, height = 20,
			translation = "position",
			alpha = 0
		}):addTextArea({
			x = 78, y = 54,
			width = 176, height = 20,
			translation = "username",
			alpha = 0
		}):addTextArea({
			x = 267, y = 54,
			width = 70, height = 20,
			translation = "community",
			alpha = 0
		}):addTextArea({
			x = 350, y = 54,
			width = 105, height = 20,
			translation = "completed",
			alpha = 0
		})

		-- Position
		:addTextArea({
			x = 15, y = 84,
			width = 50, height = 200,

			canUpdate = true,
			text = function(self, player, data, page, weekly)
				local positions = {}
				for index = 1, 14 do
					positions[index] = 14 * page + index
				end
				return "<font size='12'><p align='center'><v>#" .. table.concat(positions, "\n#")
			end,
			color = {0x203F43, 0x193E46, 1}
		})

		-- Player names
		:addTextArea({
			x = 78, y = 84,
			width = 176, height = 200,

			canUpdate = true,
			text = function(self, player, data, page, weekly)
				local names = {}
				local row, name, unknown
				for index = 1, 14 do
					row = data[14 * page + index]

					if not row then
						if not unknown then
							unknown = translatedMessage("unknown", player)
						end
						names[index] = unknown
					else
						names[index] = row[2]
					end
				end

				if page == 0 then
					names[1] = "<cs>" .. names[1] .. "</cs>"
					names[2] = "<n>" .. names[2] .. "</n>"
					names[3] = "<ce>" .. names[3] .. "</ce>"
				end

				return "<font size='12'><p align='center'><t>" .. table.concat(names, "\n")
			end,
			color = {0x203F43, 0x193E46, 1}
		})

		-- Community
		:addTextArea({
			x = 267, y = 84,
			width = 70, height = 200,
			color = {0x203F43, 0x193E46, 1}
		}):onUpdate(function(self, player, data, page, weekly)
			if not community_images[player] then
				community_images[player] = {}
			else
				for index = 1, 14 do
					tfm.exec.removeImage(community_images[player][index])
				end
			end

			local x = self.x + 292
			local nextY = self.y + 88
			local row, image
			for index = 1, 14 do
				row = data[14 * page + index]

				if not row then
					image = communities.xx
				else
					image = communities[row[4]] or communities.xx
				end

				community_images[player][index] = tfm.exec.addImage(image, "&1", x, nextY, player)
				nextY = nextY + 14
			end
		end):onRemove(function(self, player)
			for index = 1, 14 do
				tfm.exec.removeImage(community_images[player][index])
			end
		end)
		
		-- Map count
		:addTextArea({
			x = 350, y = 84,
			width = 100, height = 200,

			canUpdate = true,
			text = function(self, player, data, page, weekly)
				local maps = {}
				for index = 1, 14 do
					row = data[14 * page + index]

					if not row then
						maps[index] = 0
					else
						maps[index] = row[3]
					end
				end
				return "<font size='12'><p align='center'><vp>" .. table.concat(maps, "\n")
			end,
			color = {0x203F43, 0x193E46, 1}
		})

		-- Pagination buttons
		:loadComponent( -- Left arrow
			Button.new():setText("&lt;")

			:onClick(function(self, player)
				local args = self.parent.args[player]
				self.parent:update(player, args[1], math.max(args[2] - 1, 0), args[3])
			end)

			:canUpdate(true):onUpdate(function(self, player, data, page)
				if page == 0 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(17, 300):setSize(40, 20)
		):loadComponent( -- Right arrow
			Button.new():setText("&gt;")

			:onClick(function(self, player, data, page, weekly)
				local args = self.parent.args[player]
				self.parent:update(player, args[1], math.min(args[2] + 1, args[3] and 1 or 4), args[3])
			end)

			:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
				if page == (weekly and 1 or 4) then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(412, 300):setSize(40, 20)
		)

		-- Leaderboard type
		:loadComponent( -- Overall button
			Button.new():setTranslation("overall_lb")

			:onClick(function(self, player)
				local args = self.parent.args[player]
				self.parent:update(player, leaderboard, 0, false)
			end):canUpdate(true)
			:onUpdate(function(self, player, data, page, weekly)
				if not weekly then
					self:disable(player)
				else
					self:enable(player)
				end
			end):setPosition(72, 300):setSize(155, 20)
		):loadComponent( -- Weekly button
			Button.new():setTranslation("weekly_lb")

			:onClick(function(self, player)
				local args = self.parent.args[player]
				self.parent:update(player, weekleaderboard, 0, true)
			end)

			:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
				if weekly then
					self:disable(player)
				else
					self:enable(player)
				end
			end) 

			:setPosition(242, 300):setSize(155, 20)
		)
end