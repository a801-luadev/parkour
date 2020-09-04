local PowerTracker
do
	local nameCache = {}
	local function formatName(name)
		if nameCache[name] then
			return nameCache[name]
		end

		nameCache[name] = string.gsub(
			string.gsub(name, "(#%d%d%d%d)", "<font size='10'><g>%1</g></font>"),
			"([Hh]t)tp", "%1<>tp"
		)
		return nameCache[name]
	end

	PowerTracker = Interface.new(200, 50, 400, 300, true)
		:loadTemplate(WindowBackground)

		:addTextArea({
			alpha = 0,
			text = "<p align='center'><font size='14'><cep><b>Power Tracker</b></cep></font></p>"
		})

		:addTextArea({
			canUpdate = true,
			y = 25, height = 240,
			alpha = 0,

			text = function(self, player, powers)
				local pieces, count = {}, 0

				local power
				for index = powers._count, math.max(powers._count - 18, 1), -1 do
					power = powers[index]
					count = count + 1
					pieces[count] = formatName(power[1]) .. "<n> -> </n>" .. power[2]
				end

				return "<v>" .. table.concat(pieces, "\n")
			end
		})

		:loadComponent(
			Button.new():setTranslation("close")

			:onClick(function(self, player)
				self.parent:remove(player)
			end)

			:setPosition(10, 275):setSize(380, 15)
		)
end