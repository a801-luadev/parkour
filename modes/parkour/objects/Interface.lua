local Interface
do
	local all_interfaces = {}

	Interface = {}
	Interface.__index = Interface

	function Interface.new(x, y, width, height, fixed)
		local self = setmetatable({
			x = x, y = y,
			width = width, height = height,
			fixed = fixed,

			textarea_count = 0,
			textareas = {},

			image_count = 0,
			images = {},

			args = {},
			defaultArgs = {},

			open = {},

			elements = {},

			updateCallback = nil,
			removeCallback = nil,
			showCheck = nil,

			checkArguments = false
		}, Interface)
		all_interfaces[#all_interfaces + 1] = self
		return self
	end

	function Interface:setShowCheck(callback)
		self.showCheck = callback
		return self
	end

	function Interface:setDefaultArgs(...)
		self.defaultArgs = {...}
		return self
	end

	function Interface:avoidDoubleUpdates()
		self.checkArguments = true
		return self
	end

	function Interface:loadTemplate(template)
		template(self)
		return self
	end

	function Interface:loadComponent(component)
		component:asTemplate(self)
		return self
	end

	function Interface:onUpdate(callback)
		self.updateCallback = callback
		return self
	end

	function Interface:onRemove(callback)
		self.removeCallback = callback
		return self
	end

	function Interface:addTextArea(data)
		if data.name then
			self.elements[data.name] = data
		end

		data.id = allocateId("textarea")

		data.parent = self
		data.x = (data.x or 0) + self.x
		data.y = (data.y or 0) + self.y
		data.width = data.width or self.width
		data.height = data.height or self.height

		if not data.text then
			data.text_str = ""
		elseif type(data.text) == "function" then
			data.text_fnc = data.text
		else
			data.text_str = tostring(data.text)
		end

		if data.color then
			data.background = data.color[1]
			data.border = data.color[2]
			data.alpha = data.color[3]
		end

		self.textarea_count = self.textarea_count + 1
		self.textareas[self.textarea_count] = data

		return self
	end

	function Interface:addImage(data)
		if data.name then
			self.elements[data.name] = data
		end

		data.players = {}

		data.parent = self
		data.x = (data.x or 0) + self.x
		data.y = (data.y or 0) + self.y

		assert(data.image, "an image should have the image id")
		assert(data.target, "an image should have the image target")

		if type(data.image) == "function" then
			data.image_fnc = data.image
		else
			data.image_str = data.image
		end
		if type(data.target) == "function" then
			data.target_fnc = data.target
		else
			data.target_str = data.target
		end

		self.image_count = self.image_count + 1
		self.images[self.image_count] = data

		return self
	end

	function Interface:showDefault(player, arg1, arg2, arg3, arg4)
		return self:show(
			player,
			arg1 or self.defaultArgs[1],
			arg2 or self.defaultArgs[2],
			arg3 or self.defaultArgs[3],
			arg4 or self.defaultArgs[4]
		)
	end

	-- only to be called by show and update functions
	function Interface:_renderImages(player, isUpdate, arg1, arg2, arg3, arg4)
		local data
		for index = 1, self.image_count do
			data = self.images[index]

			if not isUpdate or data.canUpdate then
				if data.players[player] then
					tfm.exec.removeImage(data.players[player])
				end

				data.players[player] = tfm.exec.addImage(
					data.image_str and data.image_str or
					data:image_fnc(player, arg1, arg2, arg3, arg4),

					data.target_str and data.target_str or
					data:target_fnc(player, arg1, arg2, arg3, arg4),

					data.x, data.y,
					player,

					data.scaleX, data.scaleY, data.rotation, data.alpha,
					data.anchorX, data.anchorY, data.fadeIn
				)

				if data.onUpdate then
					data:onUpdate(player, arg1, arg2, arg3, arg4)
				end
			end
		end
	end

	function Interface:show(player, arg1, arg2, arg3, arg4)
		if self.showCheck and not self:showCheck(player, arg1, arg2, arg3, arg4) then return end
		if self.open[player] then return end

		local args
		if self.args[player] then
			args = self.args[player]
		else
			args = {}
			self.args[player] = args
		end
		args[1] = arg1
		args[2] = arg2
		args[3] = arg3
		args[4] = arg4

		local data
		for index = 1, self.textarea_count do
			data = self.textareas[index]

			ui.addTextArea(
				data.id,

				data.translation and translatedMessage(data.translation, player) or
				data.text_str and data.text_str or
				data:text_fnc(player, arg1, arg2, arg3, arg4),

				player,

				data.x, data.y,
				data.width, data.height,

				data.background, data.border, data.alpha,

				self.fixed
			)

			if data.onUpdate then
				data:onUpdate(player, arg1, arg2, arg3, arg4)
			end
		end

		self:_renderImages(player, false, arg1, arg2, arg3, arg4)

		if self.updateCallback then
			self:updateCallback(player, arg1, arg2, arg3, arg4)
		end
		self.open[player] = true
		-- it is at the end to let updateCallback know if it is an update or a show
	end

	function Interface:updatePartial(player, index, value)
		if not self.open[player] then return end
		self:update(
			player,
			index == 1 and value or self.args[player][1],
			index == 2 and value or self.args[player][2],
			index == 3 and value or self.args[player][3],
			index == 4 and value or self.args[player][4]
		)
	end

	function Interface:update(player, arg1, arg2, arg3, arg4)
		if not self.open[player] then return end

		local args = self.args[player]
		if self.checkArguments then
			if args[1] == arg1 and args[2] == arg2 and args[3] == arg3 and args[4] == arg4 then
				return
			end
		end
		args[1] = arg1
		args[2] = arg2
		args[3] = arg3
		args[4] = arg4

		local data
		for index = 1, self.textarea_count do
			data = self.textareas[index]

			if data.canUpdate then
				ui.updateTextArea(
					data.id,

					data.translation and translatedMessage(data.translation, player) or
					data.text_str and data.text_str or
					data:text_fnc(player, arg1, arg2, arg3, arg4),

					player
				)

				if data.onUpdate then
					data:onUpdate(player, arg1, arg2, arg3, arg4)
				end
			end
		end

		self:_renderImages(player, true, arg1, arg2, arg3, arg4)

		if self.updateCallback then
			self:updateCallback(player, arg1, arg2, arg3, arg4)
		end
	end

	function Interface:remove(player)
		self.open[player] = nil

		for index = 1, self.textarea_count do
			ui.removeTextArea(self.textareas[index].id, player)
		end

		local data
		for index = 1, self.image_count do
			data = self.images[index].players

			if data[player] then
				tfm.exec.removeImage(data[player])
				data[player] = nil
			end
		end

		if self.removeCallback then
			self:removeCallback(player)
		end
	end

	onEvent("PlayerLeft", function(player)
		for index = 1, #all_interfaces do
			all_interfaces[index].open[player] = nil
		end
	end)
end