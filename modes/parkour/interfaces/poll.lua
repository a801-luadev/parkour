local polls
do
	polls = {}

	local pollSizes = {
		tiny = {
			{200, 130, 400, 140, true},
			minOptions = 2,
			maxOptions = 2,
			optionY = 85
		},

		small = {
			{200, 100, 400, 200, true},
			minOptions = 2,
			maxOptions = 4,
			optionY = 85
		},

		medium = {
			{200, 80, 400, 260, true},
			minOptions = 2,
			maxOptions = 6,
			optionY = 85
		},

		big = {
			{200, 50, 400, 320, true},
			minOptions = 2,
			maxOptions = 8,
			optionY = 85
		}
	}

	local poll, offset
	for name, data in next, pollSizes do
		polls[name] = {}

		for options = data.minOptions, data.maxOptions do
			local text_fnc = function(self, player, translation, title)
				local text
				if translation then
					text = translatedMessage(title, player)
				else
					text = title
				end
				return "<font size='13'><v>[#parkour]</v> " .. text
			end

			result = Interface.new(table.unpack(data[1]))
			result.y = result.y - 15

			result.height = result.height + 30
			result:loadTemplate(WindowBackground)
				:addTextArea({
					alpha = 0, y = 0,
					text = text_fnc
				})

			poll = Interface.new(table.unpack(data[1]))
				:loadTemplate(WindowBackground)
				:addTextArea({
					alpha = 0, y = 0,
					text = text_fnc
				})

			offset = data.optionY + 30 * (data.maxOptions - options)

			for button = 1, options do
				local component = Button.new():setText(function(self, player, translation, title, buttons, results)
						local text
						if translation then
							text = translatedMessage(buttons[button], player)
						else
							text = buttons[button]
						end

						if results then
							local percentage = 100 * results[button] / results.total
							if percentage ~= percentage then -- NaN
								percentage = 0
							end

							return string.format(text .. " - %.2f%% (%s)", percentage, results[button])
						end
						return text
					end)

					:canUpdate(true):onUpdate(function(self, player, translation, title, buttons, results)
						if results then
							self:disable(player)
						else
							self:enable(player)
						end
					end)

					:onClick(function(self, player)
						if eventPollVote then
							eventPollVote(self.parent, player, button)
						end
					end)

					:setPosition(10, offset):setSize(poll.width - 20, 15)

				result:loadComponent(component)
				poll:loadComponent(component)
				offset = offset + 30
			end

			result:loadComponent(
				Button.new():setTranslation("close")

				:onClick(function(self, player)
					self.parent:remove(player)
				end)

				:setPosition(10, offset):setSize(poll.width - 20, 15)
			)

			poll.closer = result
			polls[name][options] = poll
		end
	end
end