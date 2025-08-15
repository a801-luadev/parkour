local Profile
do
	local nameCache = {}
	local function formatName(name)
		if nameCache[name] then
			return nameCache[name]
		end

		nameCache[name] = string.gsub(
			string.gsub(name, "(#%d%d%d%d)", "<font size='15'><g>%1</g></font>"),
			"([Hh]t)tp", "%1<->tp"
		)
		return nameCache[name]
	end

	local staff = {
		{"admin", "172e0cf7ce5.png"},
		{"bot", "172e0cf7ce5.png"},
		{"mod", "173eeb6cd94.png"},
		{"mapper", "17323cc35d1.png"},
		{"translator", "173f3263916.png"}
	}
	local images = {}
	local badgeTAs = {}

	for i=1, #badges do
		badgeTAs[i] = allocateId("textarea", 20000)
	end

	Profile = Interface.new(200, 50, 400, 360, true)
		:setShowCheck(function(self, player, profile, data)
			local file = data or players_file[profile]
			return (file
					and file.v == data_version)
		end)

		:addImage({
			image = "178de11fd0c.png",
			target = ":1",
			x = -5, y = -5
		})

		:addTextArea({
			alpha = 0,
			x = 5, y = 5,
			height = 100,
			canUpdate = true,
			text = function(self, player, profile)
				return "<font size='20' face='Verdana'><v><b>" .. formatName(profile)
			end
		})
		:addTextArea({
			x = 10, y = 45, height = 1, width = 380,
			border = 0x9d7043
		})
		:addTextArea({
			x = 5, y = 47, height = 1, width = 390,
			color = {0x1c3a3e, 0x1c3a3e, 1}
		})

		:onUpdate(function(self, player, profile, data)
			local container = images[player]
			if not container then
				container = {_count = 0}
				images[player] = container
			else
				for index = 1, container._count do
					tfm.exec.removeImage(container[index])
				end
				container._count = 0
			end

			local x = self.x + 370
			if not (data or players_file[profile]).hidden then
				for index = 1, #staff do
					if ranks[ staff[index][1] ][profile] then
						container._count = container._count + 1
						container[ container._count ] = tfm.exec.addImage(staff[index][2], "~1", x, self.y + 10, player)
						x = x - 25
					end
				end
			end

			x = self.x + 15
			local limit = x + 40 * 9
			local y = self.y + 205
			local pbg = (data or players_file[profile]).badges
			if pbg then
				local badge
				for index = 1, #badges do
					if pbg[index] and pbg[index] > 0 then
						badge = badges[index][pbg[index]]

						container._count = container._count + 1
						container[ container._count ] = tfm.exec.addImage(badge[2], ":2", x, y, player)
						ui.addTextArea(
							badgeTAs[index],
							"<a href='event:big_badge:" .. index .. ":" .. pbg[index] .. "'>\n\n\n\n\n\n",
							player, x, y, 30, 30,
							0, 0, 0, true
						)

						x = x + 40
						if x >= limit then
							x = self.x + 15
							y = y + 40
						end
					else
						ui.removeTextArea(badgeTAs[index], player)
					end
				end
			end
		end)
		:onRemove(function(self, player, profile)
			for index = 1, images[player]._count do
				tfm.exec.removeImage(images[player][index])
			end
			for index = 1, #badges do
				ui.removeTextArea(badgeTAs[index], player)
			end
			images[player]._count = 0
		end)

		:addTextArea({
			x = 5, y = 50,
			canUpdate = true,
			text = function(self, player, profile, data)
				local file = (data or players_file[profile])
				local displayStats = (not file.private_maps or player == profile or (perms[player] and perms[player].see_private_maps))

				return translatedMessage(
					"profile", player,
					file.private_maps and translatedMessage("private_maps", player) or "",

					displayStats and translatedMessage("map_count", player, file.c, file.week[1], #file.hour) or "",

					profile == player and string.format(
						"<a href='event:prof_maps:%s'><j>[%s]</j></a>",
						file.private_maps and "public" or "private",
						translatedMessage(file.private_maps and "make_public" or "make_private", player)
					) or "",

					leaderboard[profile] and ("#" .. leaderboard[profile]) or "N/A",

					weekleaderboard[profile] and ("#" .. weekleaderboard[profile]) or "N/A",

					displayStats and translatedMessage("title_count", player, file.tc, file.cc) or ""
				)
			end,
			alpha = 0, height = 150
		})

		:addTextArea({
			x = 5, y = 175,
			canUpdate = true,
			text = function(self, player, profile, data)
				local count = 0
				local pbg = (data or players_file[profile]).badges
				if pbg then
					for index = 1, #badges do
						if pbg[index] and pbg[index] > 0 then
							count = count + 1
						end
					end
				end
				return translatedMessage("badges", player, count)
			end,
			height = 20,
			alpha = 0
		})

		:loadComponent(
			Button.new():setTranslation("close")
			:onClick(function(self, player)
				self.parent:remove(player)
			end)
			:setPosition(10, 300):setSize(380, 15)
		)

	onEvent("ParsedTextAreaCallback", function(id, player, action, args)
		if action == "big_badge" then
			if not checkCooldown(player, "big_badge", 2000) then return end
			local group, badge = args:match("(%d+):(%d+)")
			group = tonumber(group)
			badge = tonumber(badge)
			if not group or not badge or not badges[group] or not badges[group][badge] then
				return
			end
			NewBadgeInterface:show(player, group, badge)
		elseif action == "prof_maps" then
			if not checkCooldown(player, "mapsToggle", 500) then return end
			if not players_file[player] then return end

			if args == "public" then
				players_file[player].private_maps = nil
			else
				players_file[player].private_maps = true
			end

			savePlayerData(player)

			if Profile.open[player] then
				Profile:update(player, player)
			end
		end
	end)
end