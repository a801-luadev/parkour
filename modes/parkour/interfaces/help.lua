local HelpInterface
do
	local texts = { -- name, max chars
		{"help", nil},
		{"staff", 700},
		{"contribute", nil},
		{"changelog", nil},
		{"rules", 800},
		{"rules2", 800},
		{"rules3", 800},
		{"rules4", 800},
		{"rules5", 800},
	}
	local extra_chars = {
		ru = 250,
		he = 250
	}
	local page_info = {}
	local scroll_info = {}
	local images = {}

	for lang, translation in next, translations do
		page_info[ lang ] = {}

		for index = 1, #texts do
			local info = texts[index]
			local text = translation["help_" .. info[1]] or translations.en["help_" .. info[1]]
			local data = {}

			if #text > 1300 and info[2] then
				text = "\n" .. text

				local breakpoint = info[2] + (extra_chars[lang] or 0)

				for slice = 1, #text, breakpoint do
					local page = string.sub(text, slice, slice + 1999)
					local newline = string.find(page, "\n")

					if newline then
						repeat
							newline = newline + 1
						until string.find(page, "\n", newline) ~= 1

						page = string.sub(page, newline)
						data[(slice - 1) / breakpoint + 1] = page
					else
						break
					end
				end

				if not data[2] then
					data = data[1]
				end
			else
				data = text
			end

			if data[1] then
				data.scrollable = true
			end
			page_info[ lang ][ info[1] ] = data
		end
	end

	local closeButton = Button.new()
	HelpInterface = Interface.new(50, 50, 700, 330, true)
		:setDefaultArgs("help")
		:loadTemplate(WindowBackground)

		:onUpdate(function(self, player)
			if not self.open[player] then -- first update (show)
				bindKeyboard(player, 1, true, true)
				bindKeyboard(player, 3, true, true)
				scroll_info[player] = 1
			end
		end)
		:onRemove(function(self, player)
			bindKeyboard(player, 1, true, false)
			bindKeyboard(player, 3, true, false)
			scroll_info[player] = nil

			if images[player] then
				for i = 1, 2 do
					tfm.exec.removeImage(images[player][i])
				end
				images[player] = nil
			end
		end)

		-- Tabs
		:loadComponent( -- Help
			Button.new():setTranslation("help")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "help")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "help" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(10, 15):setSize(80, 18)
		)
		:loadComponent( -- Staff
			Button.new():setTranslation("staff")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "staff")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "staff" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(10, 50):setSize(80, 18)
		)
		:loadComponent( -- Contribute
			Button.new():setTranslation("contribute")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "contribute")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "contribute" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(10, 85):setSize(80, 18)
		)
		:loadComponent( -- Changelog
			Button.new():setTranslation("changelog")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "changelog")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "changelog" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(10, 120):setSize(80, 18)
		)
		:loadComponent( -- Rules
			Button.new():setTranslation("rules")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "rules")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "rules" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(10, 155):setSize(80, 18)
		)
		:loadComponent( -- Rules Page 2
			Button.new():setTranslation("report_troll")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "rules2")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "rules2" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(20, 190):setSize(70, 18)
		)
		:loadComponent( -- Rules Page 3
			Button.new():setTranslation("tab_misc")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "rules3")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "rules3" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(20, 225):setSize(70, 18)
		)
		:loadComponent( -- Rules Page 4
			Button.new():setTranslation("report_hack")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "rules4")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "rules4" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(20, 260):setSize(70, 18)
		)
		:loadComponent( -- Rules Page 5
			Button.new():setTranslation("tab_ban")

			:onClick(function(self, player, page)
				if not checkCooldown(player, "helpbuttons", 1500) then return end
				scroll_info[player] = 1
				self.parent:update(player, "rules5")
			end)

			:canUpdate(true):onUpdate(function(self, player, page)
				if page == "rules5" then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(20, 295):setSize(70, 18)
		)

		:addTextArea({
			x = 100, y = 0,
			width = 0, height = 330,
			canUpdate = true,
			text = function(self, player, page)
				local info = page_info[ player_langs[player].name ][ page ]
				local img = images[player]
				local parent = self.parent

				if info.scrollable then
					if not img then
						img = {
							[1] = tfm.exec.addImage(
								"1719e0e550a.png", "~10",
								HelpInterface.x + 685,
								HelpInterface.y + 50,
								player
							) -- scroll frame
						}
						images[player] = img
					end

					local scroll = scroll_info[player]

					if img[2] then
						tfm.exec.removeImage(img[2])
					end
					img[2] = tfm.exec.addImage(
						"1719e173ac6.png", "~10",
						HelpInterface.x + 685,
						HelpInterface.y + 50 + (125 / (#info - 1)) * (scroll - 1),
						player
					)

					local desiredWidth = 570
					if self.width ~= desiredWidth then
						self.width = desiredWidth
						ui.addTextArea(
							self.id, "", player,
							self.x, self.y, self.width, self.height,
							self.background, self.border, self.alpha,
							parent.fixed
						)

						local txt
						for index = 1, parent.textarea_count do
							txt = parent.textareas[index]

							if txt.isScrollArrow then
								txt.text_str = txt.text
							end
						end
					end

					return info[scroll]
				end

				if img then
					for i = 1, 2 do
						tfm.exec.removeImage(img[i])
					end
					images[player] = nil
				end

				local desiredWidth = 580
				if self.width ~= desiredWidth then
					self.width = desiredWidth
					ui.addTextArea(
						self.id, "", player,
						self.x, self.y, self.width, self.height,
						self.background, self.border, self.alpha,
						parent.fixed
					)

					local txt
					for index = 1, parent.textarea_count do
						txt = parent.textareas[index]

						if txt.isScrollArrow then
							txt.text_str = ""
						end
					end
				end

				return info
			end,
			alpha = 0
		})

		-- Scroll buttons
		:addTextArea({
			isScrollArrow = true,

			canUpdate = true,
			x = 680, y = 25,
			width = 20, height = 20,
			text = "<a href='event:help_scroll_up'>/\\",
			alpha = 0
		})
		:addTextArea({
			isScrollArrow = true,

			canUpdate = true,
			x = 680, y = 305,
			width = 20, height = 20,
			text = "<a href='event:help_scroll_down'>\\/\n",
			alpha = 0
		})

		-- Close button
		:addTextArea({
			text = "<a href='event:close_help'><font color='#b84c36' size='15'><b>X</b></font></a>",
			alpha = 0,
			x = 680, y = 0,
			width = 20, height = 20
		})

	local function scrollHelp(player, up)
		if not HelpInterface.open[player] then return end

		local page = HelpInterface.args[player][1]
		local info = page_info[ player_langs[player].name ][ page ]
		if not info.scrollable then return end

		if up then -- up
			scroll_info[player] = math.max(scroll_info[player] - 1, 1)
		else -- down
			scroll_info[player] = math.min(scroll_info[player] + 1, #info)
		end
		HelpInterface:update(player, page)
	end

	onEvent("RawTextAreaCallback", function(id, player, cb)
		if cb == "close_help" then
		if not checkCooldown(player, "close_help", 1000) then return end
			HelpInterface:remove(player)
			return
		end
		if not checkCooldown(player, "helpscroll", 2000) then return end
		if cb == "help_scroll_up" then
			scrollHelp(player, true)
		elseif cb == "help_scroll_down" then
			scrollHelp(player, false)
		end
	end)

	onEvent("Keyboard", function(player, key, down)
		if not checkCooldown(player, "helpscroll", 2000) then return end
		if key ~= 1 and key ~= 3 then return end
		if not down then return end
		scrollHelp(player, key == 1)
	end)
end