local ShopInterface
do	
	local shop_images = {}
	local coin_images = {}
	local isSave = {}
	local priceTAs = {}
	local consumableTAs = {}
	local refundMode = newSessionTable()
	local confirmIndex = newSessionTable()

	for i=1, 14 do
		priceTAs[i] = allocateId("textarea", 30000)
		consumableTAs[i] = allocateId("textarea", 30000)
	end

	local function filterShopItems(player, tab, ret)
		local tabItems = shop_items[tab]
		local pdata = players_file[player]
		if not tabItems or not pdata then return ret end

		local count = 0
		for i=1, #tabItems do
			if not tabItems[i].hidden or pdata:findShopItem(tabItems[i].id, tab == 8) then
				count = 1 + count
				ret[count] = tabItems[i]
			end
		end
		ret._len = count
		return ret
	end

	ShopInterface = Interface.new(50, 35, 700, 350, true)
		:loadTemplate(WindowBackground)
		:setShowCheck(function(self, player, page, tab, data)
			if not data then
				confirmIndex[player] = nil
				self:show(player, 1, 1, filterShopItems(player, 1, { _len=0 }))
				return false
			end
			return true
		end)

		:addTextArea({ -- Title
			x = 240, y = 15,
			width = 340, height = 30,
			canUpdate = true,
			text = function(self, player, page, tab)
				return "<p align='center'><font size='20'><B><D>" .. translatedMessage(shop_tabs[tab], player)
			end,
			alpha = 0
		})

		-- Refund button
		:addTextArea({
			x = 555, y = 10,
			width = 100, height = nil,
			canUpdate = true,
			text = function(self, player, page, tab)
				return '<p align="right"><b>' .. translatedMessage('refund', player)
			end,
			alpha = 0
		})
		:addTextArea({
			x = 525, y = 25,
			width = 160, height = nil,
			canUpdate = true,
			text = function(self, player, page, tab)
				return translatedMessage('refund_info', player)
			end,
			alpha = 0
		})
		:loadComponent(
			Toggle.new(660, 15, false)
			:onToggle(function(self, player, state)
				local page = self.parent.args[player][1]
				local tab = self.parent.args[player][2]
				local data = self.parent.args[player][3]
				refundMode[player] = state
				self.parent:update(player, page, tab, data)
			end)
			:onUpdate(function(self, player)
				local refund = refundMode[player]
				if (self.state[player] and not refund) or (not self.state[player] and refund) then
					self:toggle(player)
				end
			end)
		)

		-- Close button
		:loadComponent(
			Button.new():setTranslation("close")
			:onClick(function(self, player)
				if isSave[player] then
					savePlayerData(player)
					isSave[player] = nil
				end

				self.parent:remove(player)
			end)
			:setPosition(115 + 150, 323):setSize(465 - 150, 18)
		)

		-- Prev Page Button
		:loadComponent(
			Button.new():setText("&lt;")
			:onClick(function(self, player)
				local page = self.parent.args[player][1]
				local tab = self.parent.args[player][2]
				local data = self.parent.args[player][3]
				local count = data._len
				local newpage = page == 1 and (math.floor((count - 1) / 14) * 14 + 1) or (page - 14)
				if page == newpage then return end
				self.parent:update(player, newpage, tab, data)
			end)
			:setPosition(20 + 150, 323):setSize(80, 18)
			:canUpdate(true):onUpdate(function(self, player)
				local data = self.parent.args[player][3]
				if data._len <= 14 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)
		)

		-- Next Page Button
		:loadComponent(
			Button.new():setText(">")
			:onClick(function(self, player)
				local page = self.parent.args[player][1]
				local tab = self.parent.args[player][2]
				local data = self.parent.args[player][3]
				local count = data._len
				local newpage = (page + 14) > count and 1 or (page + 14)
				if page == newpage then return end
				self.parent:update(player, newpage, tab, data)
			end)
			:setPosition(595, 323):setSize(80, 18)
			:canUpdate(true):onUpdate(function(self, player)
				local data = self.parent.args[player][3]
				if data._len <= 14 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)
		)

		:addImage({
			image = "18b29f6977c.png",
			target = "&99",
			x = 25, y = 15
		})

		:addTextArea({ -- Parkour Coin
			x = 25, y = 15,
			width = 100, height = 30,
			canUpdate = true,
			text = function(self, player)
				return ("<font size='18'><p align='right'>"..players_file[player].coins)
			end,
			alpha = 1,
			color = {0x204347, 0x204347}
		})

		-- Item Images
		:addTextArea({
			x = 0, y = 50,
			width = 700, height = 250,
			alpha = 0,
		}):onUpdate(function(self, player, page, tab, data)
			local images = shop_images[player] or {}
			shop_images[player] = images
			for index = 1, #images do
				tfm.exec.removeImage(images[index])
			end

			local x = 70 + 150
			local y = 150
			local item
			local firstImage

			if tab == 4 and page == 1 and players_file[player].c >= 400 then
				firstImage = "173db16a824.png"
			end

			for index = 1, 14 do
				if page + index - 1 > data._len then
					break
				end
				item = data[page + index - 1]
				if item then
					images[index] = tfm.exec.addImage(index == 1 and firstImage or item.image, "~99", x + 30, y + (item.uses and 10 or 0), player, item.scale, item.scale, 0, 1, 0.5, 0.5)
					x = x + 75

					if index == 7 then
						y = y + 130
						x = 70 + 150
					end
				end
			end
		end)

		-- Item Prices
		:addTextArea({
			x = 150, y = 50,
			width = 700 - 150, height = 250,
			canUpdate = true,
			text = function(self, player, page, tab, data)
				local images = coin_images[player] or {}
				coin_images[player] = images
				for index = 1, #images do
					tfm.exec.removeImage(images[index])
				end

				local x = self.x + 25
				local y = self.y + 15
				local item
				local file = players_file[player]
				local color

				for index = 1, 14 do
					item = data[page + index - 1]
					if file and item and page + index - 1 <= data._len then
						local itemPrice = item.gifts or item.price or 0

						if refundMode[player] and item.price and item.price > 0 then
							itemPrice = math.floor(itemPrice * 0.7)
						end

						if item.gifts then
							itemPrice = (file.gifts or 0) .. "/" .. itemPrice
							images[index] = tfm.exec.addImage("18c73e40d6d.png", "&1000", x - 4, y - 2, player, 0.5, 0.5)
						else
							if itemPrice >= 100000 then
								local thousand = itemPrice / 1000
								itemPrice = tostring(thousand) .. "K"
							end

							images[index] = tfm.exec.addImage("18b2a0bc298.png", "&1000", x - 4, y + 2, player)
						end

						if refundMode[player] and file:findShopItem(item.id, tab == 8) and itemPrice > 0 then
							color = "<vp>"
						else
							color = ''
						end

						ui.addTextArea(
							priceTAs[index], "<b><p align='right'>"..color..itemPrice, player,
							x-5, y, 60, 15,
							0x14282b, 0x14282b, 1,
							true
						)

						if tab == 8 then
							local uses = file:getPowerUse(item.id)
							if item.uses then
								ui.addTextArea(
									consumableTAs[index], "<b><p align='right'>" .. (uses or 0) .. "/" .. item.uses, player,
									x, y + 20, 55, 15,
									0, 0, 0,
									true
								)
							end
						else
							ui.removeTextArea(consumableTAs[index], player)
						end

						x = x + 75 
						if index == 7 then
							y = self.y + 145
							x = self.x + 25
						end
					else
						ui.removeTextArea(priceTAs[index], player)
						ui.removeTextArea(consumableTAs[index], player)
					end
				end
				return ""
			end,
			alpha = 0
		}):onRemove(function(self, player)
			for index = 1, 14 do
				ui.removeTextArea(priceTAs[index], player)
				ui.removeTextArea(consumableTAs[index], player)
				tfm.exec.removeImage(shop_images[player][index])
				tfm.exec.removeImage(coin_images[player][index])
			end
		end)

	local buttonx = 22
	local buttony = 65

	for tabButton = 1, #shop_tabs do
		ShopInterface:loadComponent(
			Button.new():setText(function(self, player, page, tab, data)
				return translatedMessage(shop_tabs[tabButton], player)
			end)
			:onClick(function(self, player)
				self.parent:update(player, 1, tabButton, filterShopItems(player, tabButton, self.parent.args[player][3]))
			end)
			:setPosition(buttonx, buttony + (tabButton - 1) * 32):setSize(130, 18)
		)
	end

	local buttonx = 22 + 150
	local buttony = 155

	for buyButton = 1, 14 do
		local component = Button.new()
		:setText(
			function(self, player, page, tab, data)
				local index = page + buyButton - 1
				local item = data[index]
				if index > data._len or not item then return "" end
				if confirmIndex[player] == buyButton then
					return translatedMessage("yes", player)
				end
				if players_file[player].cskins[tab] == item.id then
					return translatedMessage("equipped", player)
				elseif refundMode[player] then
					if not players_file[player]:findShopItem(item.id, tab == 8) or item.price <= 0 then
						return ""
					end
					return translatedMessage("refund", player)
				elseif players_file[player]:findShopItem(item.id, tab == 8) then
					return translatedMessage("equip", player)
				elseif item.price >= 0 then
					return translatedMessage("buy", player)
				else
					return ""
				end

			end)
		:onClick(function(self, player)
			local page = self.parent.args[player][1]
			local tab = self.parent.args[player][2]
			local data = self.parent.args[player][3]
			local index = page + buyButton - 1
			if index > data._len then return end
			local item_price = data[index].price
			local file = players_file[player]
			local itemID = data[index].id

			if file:findShopItem(itemID, tab == 8) then
				if refundMode[player] then
					if not item_price or item_price <= 0 or tab == 8 then return end

					if confirmIndex[player] ~= buyButton then
						confirmIndex[player] = buyButton
						self.parent:update(player, page, tab, data)
						return
					end

					confirmIndex[player] = nil
	
					if not file:removeShopItem(itemID, tab == 8) then
						return
					end

					file.coins = file.coins + math.floor(item_price * 0.7)

					for i = #file.cskins, 1, -1 do
						if file.cskins[i] == itemID then
							file.cskins[i] = shop_items[tab][1].id
						end
					end

					self.parent:update(player, page, tab, data)
					return
				end

				if tab == 9 then
					file.cskins[8] = 1
				end
				file.cskins[tab] = itemID
				isSave[player] = true
				self.parent:update(player, page, tab, data)
				return
			end

			if refundMode[player] then return end
			if item_price < 0 then return end
			if file.coins < item_price then
				tfm.exec.chatMessage("<v>[#] <r>You don't have enough coins.", player)
				return
			end

			if tab ~= 8 and #file.skins > 99 then
				return
			end

			if confirmIndex[player] ~= buyButton then
				confirmIndex[player] = buyButton
				self.parent:update(player, page, tab, data)
				return
			end

			confirmIndex[player] = nil

			if tab == 8 and data[index].uses then
				if not file:updatePower(itemID, data[index].uses) then
					return
				end
			else
				if not file:addShopItem(itemID, tab == 8) then
					return
				end
			end

			file.coins = file.coins - item_price
			isSave[player] = true
			self.parent:update(player, page, tab, data)
		end)
		:canUpdate(true)
		:onUpdate(function(self, player)
			local page = self.parent.args[player][1]
			local tab = self.parent.args[player][2]
			local data = self.parent.args[player][3]
			local index = page + buyButton - 1
			local itemID = data[index] and data[index].id
			local file = players_file[player]
			if index > data._len or not data[index] or file.cskins[tab] == itemID
			or (refundMode[player] and (data[index].price <= 0 or tab == 8))
			or (refundMode[player] or data[index].price < 0 or file.coins < data[index].price) and not file:findShopItem(itemID, tab == 8) then
				self:disable(player)
			else
				self:enable(player)
			end 
		end)
		:setPosition(buttonx, buttony):setSize(55, 18)

		ShopInterface:loadComponent(component)
		buttonx = buttonx + 75

		if buyButton == 7 then
			buttony = 285
			buttonx = 22 + 150
		end
	end
end