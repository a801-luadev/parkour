do
	local settings_img = "1713705576b.png"
	local powers_img = "17136ef539e.png"
	local help_img = "17136f9eefd.png"
	local shop_img = "18b597a932a.png"
	local quests_img = "18c3b94e9a4.png"
	local report_img = "img@1996c1e72c9"

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
			image = powers_img,
			target = ":1",
			x = 684, y = 32
		})
		:addTextArea({
			text = "<a href='event:powers'><font size='50'>  </font></a>",
			x = 679, y = 32,
			height = 30, width = 32,
			alpha = 0
		})

		:addImage({
			image = help_img,
			target = ":1",
			x = 654, y = 32
		})
		:addTextArea({
			text = "<a href='event:help_button'><font size='50'>  </font></a>",
			x = 649, y = 32,
			height = 30, width = 32,
			alpha = 0
		})

		:addImage({
			image = report_img,
			target = ":1",
			x = 629, y = 35
		})
		:addTextArea({
			text = "<a href='event:report_button'><font size='50'>  </font></a>",
			x = 624, y = 32,
			height = 30, width = 32,
			alpha = 0
		})
end