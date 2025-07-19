do
	CompletedQuestsInterface = Interface.new(480, 350, 300, 40, true)
		:loadTemplate(WindowBackground)
        :setShowCheck(function(self, player, isWeekly, data)
			if not data then
				return false
			end
			return true
		end)

		:addImage({
            image = "18b29f6977c.png",
			target = "&1",
			x = 10, y = 0
		})

        :addTextArea({
            x = 10, y = 26,
            width = 30, height = 20,
            alpha = 0,
            canUpdate = true,
            text = function(self, player, isWeekly, data)
                return string.format("<p align='center'><b>%s</b></p>", data)
            end
        })

        :addTextArea({
            x = 50, y = 4,
            width = 250, height = 40,
            alpha = 0,
            canUpdate = true,
            text = function(self, player, isWeekly, data)
                local text = isWeekly and translatedMessage("weekly_q", player) or translatedMessage("daily_q", player)
                text = text:lower()

                return translatedMessage("quest_completed", player, text)
            end
        })
end