local ShopInterface
do	
	local shop_images = {}
	local coin_images = {}
	local isSave = {}
	local priceTAs = {}
	local consumableTAs = {}

	for i=1, 18 do
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

		-- Next Tab Button
		:loadComponent(
			Button.new():setText(">")
			:onClick(function(self, player)
				local tab = self.parent.args[player][2]
				tab = 1 + (tab % #shop_items)
				self.parent:update(player, 1, tab, filterShopItems(player, tab, self.parent.args[player][3]))
			end)
			:setPosition(595, 20):setSize(80, 18)
		)

		-- Prev Tab Button
		:loadComponent(
			Button.new():setText("&lt;")
			:onClick(function(self, player)
				local tab = self.parent.args[player][2]
				tab = tab == 1 and #shop_items or (tab - 1)
				self.parent:update(player, 1, tab, filterShopItems(player, tab, self.parent.args[player][3]))
			end)
			:setPosition(145, 20):setSize(80, 18)
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
			:setPosition(115, 323):setSize(465, 18)
		)

		-- Prev Page Button
		:loadComponent(
			Button.new():setText("&lt;")
			:onClick(function(self, player)
				local page = self.parent.args[player][1]
				local tab = self.parent.args[player][2]
				local data = self.parent.args[player][3]
				local count = data._len
				local newpage = page == 1 and (math.floor((count - 1) / 18) * 18 + 1) or (page - 18)
				if page == newpage then return end
				self.parent:update(player, newpage, tab, data)
			end)
			:setPosition(20, 323):setSize(80, 18)
			:canUpdate(true):onUpdate(function(self, player)
				local data = self.parent.args[player][3]
				if data._len <= 18 then
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
				local newpage = (page + 18) > count and 1 or (page + 18)
				if page == newpage then return end
				self.parent:update(player, newpage, tab, data)
			end)
			:setPosition(595, 323):setSize(80, 18)
			:canUpdate(true):onUpdate(function(self, player)
				local data = self.parent.args[player][3]
				if data._len <= 18 then
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

			local x = 70
			local y = 150
			local item
			local firstImage

			if tab == 4 and page == 1 and players_file[player].c >= 400 then
				firstImage = "173db16a824.png"
			end

			for index = 1, 18 do
				if page + index - 1 > data._len then
					break
				end
				item = data[page + index - 1]
				if item then
					images[index] = tfm.exec.addImage(index == 1 and firstImage or item.image, "~99", x + 30, y + (item.uses and 10 or 0), player, item.scale, item.scale, 0, 1, 0.5, 0.5)
					x = x + 75

					if index == 9 then
						y = y + 130
						x = 70
					end
				end
			end
		end)

		-- Item Prices
		:addTextArea({
			x = 0, y = 50,
			width = 700, height = 250,
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

				for index = 1, 18 do
					item = data[page + index - 1]
					if file and item and page + index - 1 <= data._len then
						local itemPrice = item.gifts or item.price or 0

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

						ui.addTextArea(
							priceTAs[index], "<b><p align='right'>"..itemPrice, player,
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
						if index == 9 then
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
			for index = 1, 18 do
				ui.removeTextArea(priceTAs[index], player)
				ui.removeTextArea(consumableTAs[index], player)
				tfm.exec.removeImage(shop_images[player][index])
				tfm.exec.removeImage(coin_images[player][index])
			end
		end)

	local buttonx = 22
	local buttony = 155

	for buyButton = 1, 18 do
		local component = Button.new()
		:setText(
			function(self, player, page, tab, data)
				local index = page + buyButton - 1
				local item = data[index]
				if index > data._len or not item then return "" end
				if players_file[player].cskins[tab] == item.id then
					return translatedMessage("equipped", player)
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
				if tab == 9 then
					file.cskins[8] = 1
				end
				file.cskins[tab] = itemID
				isSave[player] = true
				self.parent:update(player, page, tab, data)
				return
			end

			if item_price < 0 then return end
			if file.coins < item_price then
				tfm.exec.chatMessage("<v>[#] <r>You don't have enough coins.", player)
				return
			end

			if tab ~= 8 and #file.skins > 99 then
				return
			end

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
			if index > data._len or not data[index] or file.cskins[tab] == itemID or (data[index].price < 0 or file.coins < data[index].price) and not file:findShopItem(itemID, tab == 8) then
				self:disable(player)
			else
				self:enable(player)
			end 
		end)
		:setPosition(buttonx, buttony):setSize(55, 18)

		ShopInterface:loadComponent(component)
		buttonx = buttonx + 75

		if buyButton == 9 then
			buttony = 285
			buttonx = 22
		end
	end
end