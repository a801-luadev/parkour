local ReportValidReasons = { "troll", "force", "hack", "cheat" }
local ReportInterface = Interface.new(168, 46, 500, 330, true)
	:loadTemplate(WindowBackground)
	:setShowCheck(function(player)
		return true
	end)
	:addTextArea({
		translation = 'report_window',
		x = 10,
		width = 480,
		alpha = 0,
	})
	:addTextArea({
		text = function(self, player, reason, selected)
			local list, count = {}, 0

			for name in next, in_room do
				if name ~= player then
					count = count + 1
					list[count] = '<a href="event:report:' .. name .. '">' .. name .. '</a>'

					if selected == name then
						list[count] = '<r>' .. list[count] .. '</r>'
					end
				end
			end

			list = table.concat(list, '\n')

			return '<v><p align="center">' .. list ..'</p></v>'
		end,
		y = 150,
		width = 240,
		height = 130,
		canUpdate = true,
		alpha = 0,
	})
	:addTextArea({
		text = function(self, player, reason)
			if not reason then return "" end
			return translatedMessage("report_" .. reason .. "_desc", player)
		end,
		x = 250,
		y = 150,
		width = 240,
		height = 130,
		alpha = 0,
		canUpdate = true,
	})
	:loadComponent(
		Button.new()
			:setTranslation("close")
			:onClick(function(self, player)
				self.parent:remove(player)
			end)
			:setPosition(10, 305)
			:setSize(230, 15)
	)
	:loadComponent(
		Button.new()
			:setTranslation("report_send")
			:onClick(function(self, player)
				local reason = self.parent.args[player][1]
				local selected = self.parent.args[player][2]
				if not reason or not selected then return end
				eventChatCommand(player, "report " .. selected .. " " .. reason)
				self.parent:remove(player)
			end)
			:setPosition(260, 305)
			:setSize(230, 15)
			:canUpdate(true)
			:onUpdate(function(self, player, reason, selected)
				if reason and selected then
					self:enable(player)
				else
					self:disable(player)
				end
			end)
	)

local reason_list = ReportValidReasons
ReportValidReasons = {}

local count = #reason_list
local offset = 120

for i=1, count do
	ReportValidReasons[reason_list[i]] = true
	ReportInterface:loadComponent(
		Button.new()
			:setText(function(self, player)
				local reason = self.parent.args[player][1]
				local text = translatedMessage("report_" .. reason_list[i], player)
				if reason == reason_list[i] then
					return '<r><b>' .. text .. '</b></r>'
				end
				return text
			end)
			:onClick(function(self, player)
				self.parent:updatePartial(player, 1, reason_list[i])
			end)
			:setPosition(20 + (offset * (i - 1)), 120)
			:setSize(100, 15)
			:canUpdate(true)
	)
end

onEvent("ParsedTextAreaCallback", function(id, player, action, args)
	if action == "report" then
		ReportInterface:updatePartial(player, 2, args)
	end
end)
