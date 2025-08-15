do
	NewBadgeInterface = Interface.new(320, 100, 200, 200, true)
		:loadTemplate(WindowBackground)

		:setShowCheck(function(self, player, group, badge)
			if self.open[player] then
				self:update(player, group, badge)
				return false
			end
			return true
		end)

		:addImage({
			image = function(self, player, group, badge)
				return badges[group][badge][3]
			end,
			target = "~10",
			x = 100, y = 55,
			anchorX = 0.5, anchorY = 0.5,
			canUpdate = true,
		})

		:addTextArea({
			alpha = 0,
			x = 5, y = 110,
			width = 190,
			height = 60,
			canUpdate = true,
			text = function(self, player, group, badge)
				return "<v>" .. translatedMessage("help_badge_" .. badges[group][badge][1], player)
			end
		})

		:loadComponent(
			Button.new():setTranslation("close")

			:onClick(function(self, player)
				self.parent:remove(player)
			end)

			:setSize(180, 15):setPosition(10, 175)
		)
end