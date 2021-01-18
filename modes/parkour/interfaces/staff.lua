local Staff
do
	local nameCache = {}
	local function formatName(name)
		if nameCache[name] then
			return nameCache[name]
		end

		nameCache[name] = "<a href='event:msg:/w " .. name .. "'>" .. string.gsub(
			string.gsub(name, "(#%d%d%d%d)", "<font size='11'><g>%1</g></font>"),
			"([Hh]t)tp", "%1<->tp"
		) .. "</a>"
		return nameCache[name]
	end
	local tab = {}
	local images = {
		{},
		{},
		{}
	}
	local communities = {
		xx = "1651b327097.png",
		ar = "1651b32290a.png",
		bg = "1651b300203.png",
		br = "1651b3019c0.png",
		cn = "1651b3031bf.png",
		cz = "1651b304972.png",
		de = "1651b306152.png",
		ee = "1651b307973.png",
		en = "1723dc10ec2.png",
		e2 = "1723dc10ec2.png",
		es = "1651b309222.png",
		fi = "1651b30aa94.png",
		fr = "1651b30c284.png",
		gb = "1651b30da90.png",
		hr = "1651b30f25d.png",
		hu = "1651b310a3b.png",
		id = "1651b3121ec.png",
		he = "1651b3139ed.png",
		it = "1651b3151ac.png",
		jp = "1651b31696a.png",
		lt = "1651b31811c.png",
		lv = "1651b319906.png",
		nl = "1651b31b0dc.png",
		ph = "1651b31c891.png",
		pl = "1651b31e0cf.png",
		pt = "17459ce7e29.png",
		ro = "1651b31f950.png",
		ru = "1651b321113.png",
		tr = "1651b3240e8.png",
		vk = "1651b3258b3.png"
	}
	local community_list = {
		"xx", "en", "e2", "ar", "bg", "br", "cn", "cz", "de", "ee", "es", "fi", "fr", "gb", "hr",
		"hu", "id", "he", "it", "jp", "lt", "lv", "nl", "ph", "pl", "ro", "ru", "tr", "vk"
	}

	local function names(container, x, start)
		return function(self, player)
			local image_x, image_y = self.parent.x + x, self.parent.y + 56
			local imgs = images[container][player]
			local show_hidden = perms[player] -- true for staff peeps

			if not imgs then
				imgs = {_count = 0}
				images[container][player] = imgs
			else
				for index = 1, imgs._count do
					tfm.exec.removeImage(imgs[index])
				end
			end

			local rank = self.parent.sorted_members[
				tab[player] == 0 and "mod" or
				tab[player] == 1 and "mapper" or
				tab[player] == 2 and "manager" or
				"admin"
			]
			local names = {}

			local commu_list = {}
			local commu, member
			for index = 1 + start, math.min(17 + start, rank._count) do
				member = rank[index]

				if hidden[member] then -- hidden
					if not show_hidden then
						break
					end
					names[index - start] = "<r>" .. formatName(member) .. "</r>"
					commu = hidden[member]
				else
					names[index - start] = formatName(member)
					commu = online[member]
				end

				imgs[index - start] = tfm.exec.addImage(communities[ commu ], "&1", image_x, image_y, player)
				image_y = image_y + 12
				imgs._count = index - start
			end

			return "<font face='Lucida Console' size='12'><v>" .. table.concat(names, "\n")
		end
	end

	Staff = Interface.new(163, 50, 474, 300, true)
		:loadTemplate(WindowBackground)

		:loadComponent(
			Button.new():setTranslation("moderators")

			:onClick(function(self, player)
				tab[player] = 0
				self.parent:update(player)
			end)

			:canUpdate(true):onUpdate(function(self, player)
				if not tab[player] then tab[player] = 0 end
				if tab[player] == 0 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(10, 10):setSize(100, 15)
		)
		:loadComponent(
			Button.new():setTranslation("mappers")

			:onClick(function(self, player)
				tab[player] = 1
				self.parent:update(player)
			end)

			:canUpdate(true):onUpdate(function(self, player)
				if tab[player] == 1 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(123, 10):setSize(100, 15)
		)
		:loadComponent(
			Button.new():setTranslation("managers")

			:onClick(function(self, player)
				tab[player] = 2
				self.parent:update(player)
			end)

			:canUpdate(true):onUpdate(function(self, player)
				if tab[player] == 2 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(236, 10):setSize(100, 15)
		)
		:loadComponent(
			Button.new():setTranslation("administrators")

			:onClick(function(self, player)
				tab[player] = 3
				self.parent:update(player)
			end)

			:canUpdate(true):onUpdate(function(self, player)
				if tab[player] == 3 then
					self:disable(player)
				else
					self:enable(player)
				end
			end)

			:setPosition(349, 10):setSize(100, 15)
		)

		:addTextArea({
			y = 35, x = 5,
			height = 230, width = 449,
			translation = "staff_power",
			alpha = 0
		})

		:addTextArea({
			y = 55, x = 22,
			height = 210, width = 135,
			canUpdate = true,
			text = names(1, 5, 0),
			alpha = 0
		})

		:addTextArea({
			y = 55, x = 177,
			height = 210, width = 135,
			canUpdate = true,
			text = names(2, 160, 17),
			alpha = 0
		})

		:addTextArea({
			y = 55, x = 332,
			height = 210, width = 135,
			canUpdate = true,
			text = names(3, 315, 34),
			alpha = 0
		})

		:onRemove(function(self, player)
			local cont
			for container = 1, 3 do
				cont = images[container][player]
				if cont then
					for index = 1, cont._count do
						tfm.exec.removeImage(cont[index])
					end
				end
			end
		end)

		:loadComponent(
			Button.new():setTranslation("close")

			:onClick(function(self, player)
				self.parent:remove(player)
			end)

			:setPosition(10, 275):setSize(439, 15)
		)

	Staff.sorted_members = {}
end