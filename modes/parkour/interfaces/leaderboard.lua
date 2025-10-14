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
			if not loaded_leaderboard and data ~= roomleaderboard then
				self:show(player, roomleaderboard, 0, 3)
				return false
			end
			if not data then
				self:show(player, leaderboard, 0, 2)
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
			canUpdate = true,
			text = function(self, player, data, page, weekly)
				local header

				if weekly == 3 then
					header = translatedMessage("time", player)
				elseif weekly == 4 then
					header = translatedMessage("coins", player)
				else
					header = translatedMessage("completed", player)
				end

				return "<V><p align='center'>" .. header
			end,
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
				local hide_names = weekly == 4 and not ranks.admin[player]
				local names = {}
				local row, name, unknown, anonymous
				for index = 1, 14 do
					row = data[14 * page + index]

					if not row then
						if not unknown then
							unknown = translatedMessage("unknown", player)
						end
						names[index] = unknown
					elseif hide_names then
						if not anonymous then
							anonymous = translatedMessage("hidden_player", player)
						end
						names[index] = anonymous
					else
						names[index] = '<a href="event:profile:' .. row[2] .. '">' .. row[2] .. '</a>'
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

				community_images[player][index] = tfm.exec.addImage(image, "~10", x, nextY, player)
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

		:addTextArea({
			text = "<a href='event:leaderboard_button'><font color='#b84c36' size='15'><b>X</b></font></a>",
			alpha = 0,
			x = 440, y = 5,
			width = 20, height = 20
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

			:onClick(function(self, player)
				local args = self.parent.args[player]
				local data = args[1]
				local page = args[2]
				local weekly = args[3]
				page = math.min(page + 1, weekly == 1 and 1 or (weekly == 2 or weekly == 4) and 4 or weekly == 3 and 6)
				self.parent:update(player, data, page, weekly)
			end)

			:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
				if (page == 1 and weekly == 1) or (page == 4 and (weekly == 2 or weekly == 4)) or (page == 6 and weekly == 3) then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(412, 300):setSize(40, 20)
		)

		-- Leaderboard type
		:loadComponent( -- Overall button
			Button.new()

			:onClick(function(self, player)
				local args = self.parent.args[player]
				local lbtype = args[3]
				if lbtype == 2 then return end
				if not loaded_leaderboard then
					translatedChatMessage("leaderboard_not_loaded", player)
					return
				end
				self.parent:update(player, leaderboard, 0, 2)
			end):canUpdate(true)
			:onUpdate(function(self, player, data, page, weekly)
				if weekly == 2 then
					self:disable(player)
				else
					self:enable(player)
				end
			end):setPosition(140, 290)
			:setImage({
				image = function(self, player)
					if self.button.enabled[player] then
						return "img@199eabf6f71"
					else
						return "img@199eabf292b"
					end
				end,
				canUpdate = true,
			}, 30, 30)
		):loadComponent( -- Weekly button
			Button.new()

			:onClick(function(self, player)
				local args = self.parent.args[player]
				local lbtype = args[3]
				if lbtype == 1 then return end
				if not loaded_leaderboard then
					translatedChatMessage("leaderboard_not_loaded", player)
					return
				end
				self.parent:update(player, weekleaderboard, 0, 1)
			end)

			:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
				if weekly == 1 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(190, 290)
			:setImage({
				image = function(self, player)
					if self.button.enabled[player] then
						return "img@199eabf55f0"
					else
						return "img@199eabf32ef"
					end
				end,
				canUpdate = true,
			}, 30, 30)
		):loadComponent( -- Coin button
			Button.new()

			:onClick(function(self, player)
				local args = self.parent.args[player]
				local lbtype = args[3]
				if lbtype == 4 then return end
				if not loaded_leaderboard then
					translatedChatMessage("leaderboard_not_loaded", player)
					return
				end
				self.parent:update(player, coinleaderboard, 0, 4)
			end)

			:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
				if weekly == 4 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)
			:setPosition(240, 290)
			:setImage({
				image = function(self, player)
					if self.button.enabled[player] then
						return "img@199eac6e20c"
					else
						return "img@199eac6d471"
					end
				end,
				canUpdate = true,
			}, 30, 30)
		):loadComponent( -- Room button
			Button.new()

			:onClick(function(self, player)
				local args = self.parent.args[player]
				local lbtype = args[3]
				if lbtype == 3 then return end
				self.parent:update(player, roomleaderboard, 0, 3)
			end)

			:canUpdate(true):onUpdate(function(self, player, data, page, weekly)
				if weekly == 3 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(290, 290)
			:setImage({
				image = function(self, player)
					if self.button.enabled[player] then
						return "img@199eabf7749"
					else
						return "img@199eabf3fc7"
					end
				end,
				canUpdate = true,
			}, 30, 30)
		)
end