local ShopInterface
do	
	local shop_images = {}
	local coin_images = {}
	local isSave = {}
	local priceTAs = {}
	local consumableTAs = {}
	local refundMode = newSessionTable()
	local confirmIndex = newSessionTable()
	local lastPageTab = newSessionTable()

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
			if not tabItems[i].hidden or pdata:findItem(tabItems[i].id, tab) then
				count = 1 + count
				ret[count] = tabItems[i]
			end
		end
		ret._len = count
		return ret
	end

	ShopInterface = Interface.new(0, 35, 800, 350, true)
		:loadTemplate(WindowBackground)
		:setShowCheck(function(self, player, page, tab, data)
			if not data then
				local pagetab = lastPageTab[player]
				if pagetab then
					tab = pagetab % 100
					page = math.floor(pagetab / 100)
				end
				confirmIndex[player] = nil
				self:show(player, page or 1, tab or 1, filterShopItems(player, tab or 1, { _len=0 }))
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
			x = 660, y = 10,
			width = 100, height = 20,
			canUpdate = true,
			text = function(self, player, page, tab)
				return '<p align="right"><b>' .. translatedMessage('refund', player)
			end,
			alpha = 0
		})
		:addTextArea({
			x = 595, y = 30,
			width = 200, height = 30,
			canUpdate = true,
			translation = 'refund_info',
			alpha = 0
		})
		:loadComponent(
			Toggle.new(770, 15, false)
			:onToggle(function(self, player, state)
				local page = self.parent.args[player][1]
				local tab = self.parent.args[player][2]
				local data = self.parent.args[player][3]
				refundMode[player] = state
				confirmIndex[player] = nil
				self.parent:update(player, page, tab, data)
			end)
			:onUpdate(function(self, player)
				local refund = refundMode[player]
				if (self.state[player] and not refund) or (not self.state[player] and refund) then
					self:toggle(player)
				end
			end)
		)

		-- Config Button
		:loadComponent(
			Button.new():setTranslation("settings")
			:onClick(function(self, player)
				local tab = self.parent.args[player][2]
				local power_id = shop_tab_to_power[tab]
				if not power_id then return end
				eventChatCommand(player, "powers " .. power_id)
			end)
			:setPosition(92 + 40 * 13, 323):setSize(25*4, 18)
			:canUpdate(true):onUpdate(function(self, player)
				local tab = self.parent.args[player][2]
				local power_id = shop_tab_to_power[tab]
				if power_id then
					self:enable(player)
				else
					self:disable(player)
				end
			end)
		)

		-- Close button
		:loadComponent(
			Button.new():setTranslation("close")
			:onClick(function(self, player)
				self.parent:remove(player)
			end)
			:setPosition(732, 323):setSize(55, 18)
		)

		-- Parkour Coin
		:addImage({
			image = "18b29f6977c.png",
			target = "&1",
			x = 130, y = 15
		})

		:addTextArea({
			x = 130, y = 15,
			width = 100, height = 30,
			canUpdate = true,
			text = function(self, player)
				return "<font size='18'><p align='right'>" .. (
					players_file[player].ownshop and "<rose>owner" or
					players_file[player]:tester() and "<rose>tester" or players_file[player].coins
				)
			end,
			alpha = 1,
			color = {0x204347, 0x204347}
		})

		-- Item Images
		:addTextArea({
			x = 130, y = 116,
			width = 10, height = 10,
			alpha = 0,
			canUpdate = true,
			text = function(self, player, page, tab, data)
			local images = shop_images[player] or {}
			shop_images[player] = images
			for index = 1, #images do
				tfm.exec.removeImage(images[index])
			end

			local x = self.x
			local y = self.y
			local item
			local firstImage

			for index = 1, 18 do
				if page + index - 1 > data._len then
					break
				end
				item = data[page + index - 1]
				if item then
					images[index] = tfm.exec.addImage(item.shop_img_fnc and item.shop_img_fnc(player) or item.shop_img or item.img, "&1", x + 30, y + (item.uses and 10 or 0), player, item.shop_scale, item.shop_scale, 0, 1, 0.5, 0.5)
					x = x + 75

					if index == 9 then
						y = self.y + 130
						x = self.x
					end
				end
			end

			return ""
		end})

		-- Item Prices
		:addTextArea({
			x = 110, y = 50,
			width = 10, height = 10,
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
				local color, currency

				for index = 1, 18 do
					item = data[page + index - 1]
					if file and item and page + index - 1 <= data._len then
						local itemPrice = item.price

						color = ''

						if refundMode[player] and tab ~= 8 and not item.currency and item.price > 0 then
							if tab ~= 0 then
								itemPrice = math.floor(itemPrice * 0.7)
							end

							if file:findItem(item.id, tab) then
								color = "<vp>"
							end
						end

						currency = shop_currencies[item.currency] or shop_currencies.coins
						images[index] = tfm.exec.addImage(currency[2], "&1", x+2, y+7, player, currency[3], currency[3], 0, 1, 0.5, 0.5)

						if itemPrice >= 100000 then
							itemPrice = tostring(itemPrice / 1000) .. "K"
						elseif itemPrice < 0 then
							itemPrice = "-"
						end

						ui.addTextArea(
							priceTAs[index], "<b><p align='right'>"..color..itemPrice, player,
							x-5, y, 60, 15,
							0x14282b, 0x14282b, 1,
							true
						)

						if file:tester() or file.ownshop then
							-- show item id for testers
							ui.addTextArea(
								consumableTAs[index], "<b><p align='right'><rose>" .. tostring(item.id), player,
								x, y - 20, 55, 15,
								0, 0, 0,
								true
							)
						else
							if item.uses then
								local uses = file:getItemAmount(item.id, tab)
								ui.addTextArea(
									consumableTAs[index], "<b><p align='right'>" .. uses .. "/" .. item.uses, player,
									x, y + 20, 55, 15,
									0, 0, 0,
									true
								)
							else
								ui.removeTextArea(consumableTAs[index], player)
							end
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
			if isSave[player] then
				savePlayerData(player)
				isSave[player] = nil
			end

			local page = self.args[player][1]
			local tab = self.args[player][2]
			if page and tab then
				lastPageTab[player] = page * 100 + tab
			end

			for index = 1, 18 do
				ui.removeTextArea(priceTAs[index], player)
				ui.removeTextArea(consumableTAs[index], player)
				tfm.exec.removeImage(shop_images[player][index])
				tfm.exec.removeImage(coin_images[player][index])
			end
		end)

	-- Tab buttons
	local buttonx = 10
	local buttony = 56

	for tabButton = 0, #shop_tabs do
		ShopInterface:loadComponent(
			Button.new():setTranslation(shop_tabs[tabButton])
			:onClick(function(self, player)
				confirmIndex[player] = nil
				self.parent:update(player, 1, tabButton, filterShopItems(player, tabButton, self.parent.args[player][3]))
			end)
			:setPosition(buttonx, buttony + (tabButton - 1) * 32):setSize(100, 18)
		)
	end

	-- Page buttons
	local buttonx = 22 + 110
	local buttony = 155

	for pageNumber = 1, 12 do
		local startIndex = 18 * pageNumber - 17
		ShopInterface:loadComponent(
			Button.new():setText(function(self, player)
				local data = self.parent.args[player][3]
				if startIndex > data._len then return "" end
				return pageNumber
			end)
			:onClick(function(self, player)
				local page = self.parent.args[player][1]
				local tab = self.parent.args[player][2]
				local data = self.parent.args[player][3]
				if page == startIndex then return end
				self.parent:update(player, startIndex, tab, data)
			end)
			:setPosition(92 + 40 * pageNumber, 323):setSize(25, 18)
			:canUpdate(true):onUpdate(function(self, player)
				local page = self.parent.args[player][1]
				local data = self.parent.args[player][3]
				if page == startIndex or startIndex > data._len then
					self:disable(player)
				else
					self:enable(player)
				end
			end)
		)
	end

	-- Item action buttons
	local buttonx = 22 + 110
	local buttony = 155

	for buyButton = 1, 18 do
		local component = Button.new()
		:setText(
			function(self, player, page, tab, data)
				local index = page + buyButton - 1
				local item = data[index]
				if index > data._len or not item then return "" end
				if confirmIndex[player] == item.id then
					return translatedMessage("yes", player)
				elseif refundMode[player] then
					if tab == 8 or not players_file[player]:findItem(item.id, tab) or item.price <= 0 or item.currency then
						return ""
					end
					return translatedMessage("refund", player)
				elseif tab == 0 then
					return ""
				elseif players_file[player]:isEquipped(tab, item.id) then
					return translatedMessage("equipped", player)
				elseif players_file[player]:findItem(item.id, tab) then
					return translatedMessage("equip", player)
				elseif item.price >= 0 and not item.currency then
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

			if file:findItem(itemID, tab) then
				if refundMode[player] then
					if data[index].currency or not item_price or item_price <= 0 or tab == 8 then return end

					if confirmIndex[player] ~= itemID then
						confirmIndex[player] = itemID
						self.parent:update(player, page, tab, data)
						return
					end

					confirmIndex[player] = nil

					if tab == 0 then
						if not file:updateItem(itemID, 0, -1) then
							return
						end
					elseif not file:removeItem(itemID, tab) then
						return
					end

					file.coins = file.coins + (tab == 0 and item_price or math.floor(item_price * 0.7))
					isSave[player] = true
					self.parent:update(player, page, tab, data)
					return
				end

				if tab == 0 then return end

				if file:isEquipped(tab, itemID) then
					if tab == 8 then return end
					file:unequip(tab, itemID)
				else
					if tab == 9 then
						file:equip(8, 1)
					end
					file:equip(tab, itemID)
				end

				isSave[player] = true
				self.parent:update(player, page, tab, data)
				return
			end

			if refundMode[player] or tab == 0 then return end
			if item_price < 0 then return end
			if file.coins < item_price then
				tfm.exec.chatMessage("<v>[#] <r>You don't have enough coins.", player)
				return
			end

			if tab ~= 8 and file:reachedSkinLimit() then
				return
			end

			if confirmIndex[player] ~= itemID then
				confirmIndex[player] = itemID
				self.parent:update(player, page, tab, data)
				return
			end

			confirmIndex[player] = nil

			if not file:updateItem(itemID, tab, data[index].uses) then
				return
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
			if index > data._len or not data[index] or tab == 8 and file:isEquipped(tab, itemID)
			or (refundMode[player] and (data[index].currency or data[index].price <= 0 or tab == 8))
			or (not refundMode[player] and tab == 0)
			or (refundMode[player] or data[index].currency or data[index].price < 0 or file.coins < data[index].price) and not file:findItem(itemID, tab) then
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
			buttonx = 22 + 110
		end
	end
end