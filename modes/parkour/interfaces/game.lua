do
	local settings_img = "1713705576b.png"
	local powers_img = "17136ef539e.png"
	local help_img = "17136f9eefd.png"
	local shop_img = "18b597a932a.png"
	local quests_img = "18c3b94e9a4.png"

	GameInterface = Interface.new(0, 0, 800, 400, true)
		:addImage({
			image = settings_img,
			target = ":1",
			x = 772, y = 32
		})
		:addTextArea({
			text = "<a href='event:settings'><font size='50'>  </font></a>",
			x = 767, y = 32,
			height = 30, width = 32,
			alpha = 0
		})

		:addImage({
			image = shop_img,
			target = ":1",
			x = 744, y = 32
		})

		:addTextArea({
			text = "<a href='event:shop_button'><font size='50'>  </font></a>",
			x = 739, y = 32,
			height = 30, width = 32,
			alpha = 0
		})

		:addImage({
			image = quests_img,
			target = ":1",
			x = 714, y = 32
		})

		:addTextArea({
			text = "<a href='event:quests_button'><font size='50'>  </font></a>",
			x = 709, y = 32,
			height = 30, width = 32,
			alpha = 0
		})

		:addImage({
			canUpdate = true,
			image = function(self, player)
				local file = players_file[player]
				if file then
					if file.settings[4] == 1 then
						return powers_img
					end
					if file.settings[6] == 1 then
						return help_img
					end
				end
				return "a.png"
			end,
			target = ":1",
			x = 684, y = 32
		})
		:addTextArea({
			canUpdate = true,
			text = function(self, player)
				local file = players_file[player]
				if file then
					if file.settings[4] == 1 then
						return "<a href='event:powers'><font size='50'>  </font></a>"
					end
					if file.settings[6] == 1 then
						return "<a href='event:help_button'><font size='50'>  </font></a>"
					end
				end
				return ""
			end,
			x = 679, y = 32,
			height = 30, width = 32,
			alpha = 0
		})

		:addImage({
			canUpdate = true,
			image = function(self, player)
				local file = players_file[player]
				if file and file.settings[4] == 1 and file.settings[6] == 1 then
					return help_img
				else
					return "a.png"
				end
			end,
			target = ":1",
			x = 654, y = 32
		})
		:addTextArea({
			canUpdate = true,
			text = function(self, player)
				local file = players_file[player]
				if file.settings[4] == 1 and file.settings[6] == 1 then
					return "<a href='event:help_button'><font size='50'>  </font></a>"
				else
					return ""
				end
			end,
			x = 649, y = 32,
			height = 30, width = 32,
			alpha = 0
		})
end