local WindowBackground = function(self)
	self:addTextArea({
		color = {0x78462b, 0x78462b, 1}
	}):addTextArea({
		y = self.height / 4,
		height = self.height / 2,
		color = {0x9d7043, 0x9d7043, 1}
	}):addTextArea({
		x = self.width / 4,
		width = self.width / 2,
		color = {0x9d7043, 0x9d7043, 1}
	}):addTextArea({
		width = 20, height = 20,
		color = {0xbeb17d, 0xbeb17d, 1}
	}):addTextArea({
		x = self.width - 20,
		width = 20, height = 20,
		color = {0xbeb17d, 0xbeb17d, 1}
	}):addTextArea({
		y = self.height - 20,
		width = 20, height = 20,
		color = {0xbeb17d, 0xbeb17d, 1}
	}):addTextArea({
		x = self.width - 20,
		y = self.height - 20,
		width = 20, height = 20,
		color = {0xbeb17d, 0xbeb17d, 1}
	}):addTextArea({
		x = 3, y = 3,
		width = self.width - 6, height = self.height - 6,
		color = {0x1c3a3e, 0x232a35, 1}
	})
end