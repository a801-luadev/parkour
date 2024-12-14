local ShopInterface
do	
	local shop_images = {}
	local coin_images = {}
	local isSave = {}

	ShopInterface = Interface.new(50, 35, 700, 350, true)
		:setDefaultArgs("shop")
		:loadTemplate(WindowBackground)
		:setShowCheck(function(self, player, page, tab)
			if not tab then
				self:show(player, 1, 1)
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
				self.parent:update(player, 1, 1 + (tab % #shop_items))
			end)
			:setPosition(595, 20):setSize(80, 18)
		)

		-- Prev Tab Button
		:loadComponent(
			Button.new():setText("&lt;")
			:onClick(function(self, player)
				local tab = self.parent.args[player][2]
				self.parent:update(player, 1, tab == 1 and #shop_items or (tab - 1))
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
				local count = #shop_items[tab]
				local newpage = page == 1 and (math.floor((count - 1) / 18) * 18 + 1) or (page - 18)
				if page == newpage then return end
				self.parent:update(player, newpage, tab)
			end)
			:setPosition(20, 323):setSize(80, 18)
			:canUpdate(true):onUpdate(function(self, player)
				local tab = self.parent.args[player][2]
				local count = #shop_items[tab]
				if count <= 18 then
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
				local count = #shop_items[tab]
				local newpage = (page + 18) > count and 1 or (page + 18)
				if page == newpage then return end
				self.parent:update(player, newpage, tab)
			end)
			:setPosition(595, 323):setSize(80, 18)
			:canUpdate(true):onUpdate(function(self, player)
				local tab = self.parent.args[player][2]
				local count = #shop_items[tab]
				if count <= 18 then
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
		}):onUpdate(function(self, player, page, tab)
			local images = shop_images[player] or {}
			shop_images[player] = images
			for index = 1, #images do
				tfm.exec.removeImage(images[index])
			end

			local x = 70
			local y = 120
			local data = shop_items[tab]
			local item
			local firstImage

			if tab == 4 and page == 1 and players_file[player].c >= 400 then
				firstImage = "173db16a824.png"
			end

			for index = 1, 18 do
				item = data[page + index - 1]
				if item then
					images[index] = tfm.exec.addImage(index == 1 and firstImage or item.image, "&999", x, y, player, item.scale, item.scale)
					x = x + 75

					if index == 9 then
						y = 250
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
			text = function(self, player, page, tab)
				local images = coin_images[player] or {}
				coin_images[player] = images
				for index = 1, #images do
					tfm.exec.removeImage(images[index])
				end

				local x = self.x + 25
				local y = self.y + 15
				local data = shop_items[tab]
				local item
				for index = 1, 18 do
					item = data[page + index - 1]
					if item then
						local itemPrice = item.gifts or item.price or 0

						if itemPrice >= 10000 then
							local thousand = itemPrice / 1000
							itemPrice = tostring(thousand) .. "K"
						end

						if item.gifts then
							itemPrice = (players_file[player] and players_file[player].gifts or 0) .. "/" .. itemPrice
							images[index] = tfm.exec.addImage("18c73e40d6d.png", "&1000", x - 2, y - 2, player, 0.5, 0.5)
						else
							images[index] = tfm.exec.addImage("18b2a0bc298.png", "&1000", x - 2, y + 2, player)
						end

						ui.addTextArea(
							-10000 - index, "<b><p align='right'>"..itemPrice, player,
							x, y, 50, 15,
							0x14282b, 0x14282b, 1,
							true
						)

						x = x + 75 
						if index == 9 then
							y = self.y + 145
							x = self.x + 25
						end
					else
						ui.removeTextArea(-10000 - index, player)
					end
				end
				return ""
			end,
			alpha = 0
		}):onRemove(function(self, player)
			for index = 1, 18 do
				ui.removeTextArea(-10000 - index, player)
				tfm.exec.removeImage(shop_images[player][index])
				tfm.exec.removeImage(coin_images[player][index])
			end
		end)

	local buttonx = 22
	local buttony = 155

	for buyButton = 1, 18 do
		local component = Button.new()
		:setText(
			function(self, player, page, tab)				
				local item = shop_items[tab][page + buyButton - 1]
				if not item then return "-" end
				if players_file[player].cskins[tab] == item.id then
					return translatedMessage("equipped", player)
				elseif default_skins[item.id] or table_find(players_file[player].skins, item.id) then
					return translatedMessage("equip", player)
				elseif item.price > 0 then
					return translatedMessage("buy", player)
				else
					return "-"
				end

			end)
		:onClick(function(self, player)
			local page = self.parent.args[player][1]
			local tab = self.parent.args[player][2]
			local index = page + buyButton - 1
			local item_price = shop_items[tab][index].price
			local player_coin = players_file[player].coins
			local itemID = shop_items[tab][index].id

			if default_skins[itemID] or table_find(players_file[player].skins, itemID) then
				players_file[player].cskins[tab] = itemID
				isSave[player] = true
				self.parent:update(player, page, tab)
				return
			end

			if item_price < 0 then return end
			if player_coin >= item_price then
				table.insert(players_file[player].skins, itemID)
				players_file[player].coins = player_coin - item_price
				isSave[player] = true
				self.parent:update(player, page, tab)
			else
				tfm.exec.chatMessage("<v>[#] <r>You don't have enough coins.", player)
			end
		end)
		:canUpdate(true)
		:onUpdate(function(self, player)
			local page = self.parent.args[player][1]
			local tab = self.parent.args[player][2]
			local data = shop_items[tab]
			local index = page + buyButton - 1
			local itemID = data[index] and data[index].id
			if not data[index] or players_file[player].cskins[tab] == itemID or data[index].price == -1 and not table_find(players_file[player].skins, itemID) then
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