do
	local settings_img = "1713705576b.png"
	local powers_img = "17136ef539e.png"
	local help_img = "17136f9eefd.png"

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
			canUpdate = true,
			image = function(self, player)
				local file = players_file[player].parkour
				if file.pbut == 1 then
					return powers_img
				elseif file.hbut == 1 then
					return help_img
				else
					return "a.png"
				end
			end,
			target = ":1",
			x = 744, y = 32
		})
		:addTextArea({
			canUpdate = true,
			text = function(self, player)
				local file = players_file[player].parkour
				if file.pbut == 1 then
					return "<a href='event:powers'><font size='50'>  </font></a>"
				elseif file.hbut == 1 then
					return "<a href='event:help_button'><font size='50'>  </font></a>"
				else
					return ""
				end
			end,
			x = 739, y = 32,
			height = 30, width = 32,
			alpha = 0
		})

		:addImage({
			canUpdate = true,
			image = function(self, player)
				local file = players_file[player].parkour
				if file.pbut == 1 and file.hbut == 1 then
					return help_img
				else
					return "a.png"
				end
			end,
			target = ":1",
			x = 714, y = 32
		})
		:addTextArea({
			canUpdate = true,
			text = function(self, player)
				local file = players_file[player].parkour
				if file.pbut == 1 and file.hbut == 1 then
					return "<a href='event:help_button'><font size='50'>  </font></a>"
				else
					return ""
				end
			end,
			x = 709, y = 32,
			height = 30, width = 32,
			alpha = 0
		})
end