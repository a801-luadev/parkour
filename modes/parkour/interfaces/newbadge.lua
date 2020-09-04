do
	local big_badges = {
		[1] = "", -- former staff
		[2] = "1745a88ffce.png", -- overall lb page 1
		[3] = "1745a892d25.png", -- overall lb page 2
		[4] = "1745a89eb17.png", -- overall lb page 3
		[5] = "1745a89bc52.png", -- overall lb page 4
		[6] = "1745a899776.png", -- overall lb page 5
		[7] = "1745a6bfa2c.png", -- weekly podium on reset
		[8] = "", -- hour record (30)
		[9] = "", -- hour record (35)
		[10] = "", -- hour record (40)
		[11] = "", -- hour record (45)
		[12] = "", -- hour record (50)
		[13] = "", -- hour record (55)
		[14] = "", -- verified discord
	}

	NewBadgeInterface = Interface.new(340, 130, 120, 140, true)
		:loadTemplate(WindowBackground)

		:setShowCheck(function(self, player, badge)
			if self.open[player] then
				self:update(player, badge)
				return false
			end
			return true
		end)

		:addImage({
			image = function(self, player, badge)
				return big_badges[badge]
			end,
			target = "&1",
			x = 10, y = 5
		})

		:loadComponent(
			Button.new():setTranslation("close")

			:onClick(function(self, player)
				self.parent:remove(player)
			end)

			:setSize(100, 15):setPosition(10, 115)
		)
end