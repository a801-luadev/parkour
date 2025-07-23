do
	NewBadgeInterface = Interface.new(340, 130, 120, 140, true)
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