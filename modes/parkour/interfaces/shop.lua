local ShopInterface
do	
	local shop_images = {}
	local coin_images = {}
	local shopPage = {}
	
	local closeButton = Button.new()
	ShopInterface = Interface.new(50, 35, 700, 350, true)
		:setDefaultArgs("shop")
		:loadTemplate(WindowBackground)
		:setShowCheck(function(self, player, page, data)
			if not data then
				shopPage[player] = 1
				self:show(player, 1, shop_items[1])
				return false
			end
			return true
		end)

		-- Close button
		:loadComponent(
			closeButton:setText("")
			:onClick(function(self, player)
				savePlayerData(player)
				self.parent:remove(player)
			end)
			:setPosition(150, 330):setSize(400, 10)
		)
		
		:addTextArea({
			x = 150, y = 326,
			width = 400, height = 15,
			text = function(self, player)
				return ("<a href='event:" .. closeButton.callback ..
						"'><p align='center'>".. translatedMessage("close", player))
			end,
			alpha = 0
		})

		:addImage({
			image = "18b29f6977c.png",
			target = "&99",
			x = 25, y = 15
		})

		:addTextArea({ -- Parkour Coin
			x = 25, y = 15,
			width = 100, height = 30,
			canUpdate = true,
			text = function(self, player, page, data)
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
		}):onUpdate(function(self, player, page, data)
			if not shop_images[player] then
				shop_images[player] = {}
			else
				for index = 1, 18 do
					tfm.exec.removeImage(shop_images[player][index])
				end
			end

			local x = 70
			local y = 120

			for index = 1, #data do
				shop_images[player][index] = tfm.exec.addImage(data[index].image, "&999", x, y, player)
				
                x = x + 75

				if index == 9 then
					y = 250
					x = 70
				end
			end
		end)

		-- Item Prices
		:addTextArea({
			x = 0, y = 50,
			width = 700, height = 250,
			canUpdate = true,
			text = function(self, player, page, data)
				if not coin_images[player] then
					coin_images[player] = {}
				else
					for index = 1, 18 do
						tfm.exec.removeImage(coin_images[player][index])
					end
				end

				local x = self.x + 25
				local y = self.y + 15
				for index = 1, #data do
					local itemPrice = data[index].price or 0

					--[[
					if itemPrice >= 1000 then
						local numString = tostring(itemPrice)
						local numLength = string.len(numString)
						if numLength == 4 then
							itemPrice = numString:sub(1, 1) .. "K"
						elseif numLength == 5 then
							itemPrice = numString:sub(1, 2) .. "K"
						elseif numLength == 6 then
							itemPrice = numString:sub(1, 3) .. "K"
						else
							itemPrice = itemPrice
						end
					elseif itemPrice == -1 then
						itemPrice = "-"
					end
					]]--

					coin_images[player][index] = tfm.exec.addImage("18b2a0bc298.png", "&1000", x - 2, y + 2, player)
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
				end
				return ""
			end,
			alpha = 0
		}):onRemove(function(self, player, page, data)
			for index = 1, 18 do
				ui.removeTextArea(-10000 - index, player)
				tfm.exec.removeImage(shop_images[player][index])
				tfm.exec.removeImage(coin_images[player][index])
			end
		end)

		-- Tabs
		:loadComponent( -- Small Box
			Button.new():setTranslation("smallbox")

			:onClick(function(self, player, page, data)
				local args = self.parent.args[player]
				shopPage[player] = 1
				self.parent:update(player, 1, shop_items[1])
			end)

			:canUpdate(true):onUpdate(function(self, player, page, data)
				if page == 1 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(200, 20):setSize(80, 18)
		)
		:loadComponent( -- Box
			Button.new():setTranslation("bigBox")

			:onClick(function(self, player, page, data)
				local args = self.parent.args[player]
				shopPage[player] = 2
				self.parent:update(player, 2, shop_items[2])
			end)

			:canUpdate(true):onUpdate(function(self, player, page, data)
				if page == 2 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(300, 20):setSize(80, 18)
		)
		:loadComponent( -- Trampoline
			Button.new():setTranslation("trampoline")

			:onClick(function(self, player, page, data)
				local args = self.parent.args[player]
				shopPage[player] = 3
				self.parent:update(player, 3, shop_items[3])
			end)

			:canUpdate(true):onUpdate(function(self, player, page, data)
				if page == 3 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(400, 20):setSize(80, 18)
		)
		:loadComponent( -- Baloon
			Button.new():setTranslation("balloon")

			:onClick(function(self, player, page, data)
				local args = self.parent.args[player]
				shopPage[player] = 4
				self.parent:update(player, 4, shop_items[4])
			end)

			:canUpdate(true):onUpdate(function(self, player, page, data)
				if page == 4 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(500, 20):setSize(80, 18)
		)
		:loadComponent( -- Choco
			Button.new():setTranslation("choco")

			:onClick(function(self, player, page, data)
				local args = self.parent.args[player]
				shopPage[player] = 5
				self.parent:update(player, 5, shop_items[5])
			end)

			:canUpdate(true):onUpdate(function(self, player, page, data)
				if page == 5 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(600, 20):setSize(80, 18)
		)
		

	local buttonx = 22
	local buttony = 155

	for buyButton = 1, #shop_items[1] do
		local component = Button.new()
        
		:setText(
			function(self, player, page, data)				
				local itemID = shop_items[shopPage[player]][buyButton].id
				itemID = tostring(itemID)

				if players_file[player].cskins[shopPage[player]] == tonumber(itemID) then
					return translatedMessage("equipped", player)
				elseif players_file[player].skins[itemID] == 1 then
					return translatedMessage("equip", player)
				else
					return translatedMessage("buy", player)
				end

			end)

		:onClick(function(self, player, page, data)
			if not checkCooldown(player, "buybutton", 1000) then return end

			local item_price = shop_items[shopPage[player]][buyButton].price
			local player_coin = players_file[player].coins
			local itemID = shop_items[shopPage[player]][buyButton].id
			itemID = tostring(itemID)

			local args = self.parent.args[player]

			if players_file[player].skins[itemID] == 1 then
				players_file[player].cskins[shopPage[player]] = tonumber(itemID)
				self.parent:update(player, args[1], args[2], 3)
				return
			end

			if player_coin >= item_price then
				players_file[player].skins[itemID] = 1
				players_file[player].coins = player_coin - item_price
				self.parent:update(player, args[1], args[2], 1)
			else
				tfm.exec.chatMessage("<v>[#] <r>You don't have enough coins.", player)
			end
		end)
	
		:canUpdate(true):onUpdate(function(self, player, page, data)
			if players_file[player].cskins[page] == shop_items[page][buyButton].id or shop_items[page][buyButton].price == -1 then
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