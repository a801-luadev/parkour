AfkInterface = Interface.new(100, 50, 600, 300, true)
	:loadTemplate(WindowBackground)
	:addTextArea({
		x = 0, y = 0,
		width = 600, height = 300,
		alpha = 0,
		translation = "afk_popup"
	})