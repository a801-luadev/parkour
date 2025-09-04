local default_skins_by_cat = {1, 2, 7, 28, 46, 57, 90, 1, 34}
local default_skins = {}

do
	for i=1, #default_skins_by_cat do
		default_skins[default_skins_by_cat[i]] = true
	end
end

local function findValueTbl(arr, key, val)
	for i=1, #arr do
		if arr[i][key] == val then
			return arr[i]
		end
	end
end

local shop_currencies = {
	-- ec index, image, scale
	coins = { 0, "18b2a0bc298.png" },
	gifts = { 1, "18c73e40d6d.png", 0.5 },
	lemonade = { 2, "img@198008a0320" },
	ice = { 3, "img@197ed411401" },
	sugar = { 4, "img@197ed41077c" },
	water = { 5, "img@197ed410214" },
	lemon = { 6, "img@197ed3a7e0a" },
}
local shop_tabs = { [0]="event", "smallbox", "bigBox", "trampoline", "balloon", "choco", "cloud", "rip", "powers", "snowball" }
local shop_tab_to_power = { 6, 10, 11, 4, 9, 7, 8, 3, 3 }
local shop_items = {
	[0] = { -- Event
		{
			price = 1,
			img = "18c73e40d6d.png",
			id = 1,
			uses = 100,
		},
		{
			price = 1,
			img = "img@197ed411401",
			id = 3,
			uses = 10,
		},
		{
			price = 1,
			img = "img@197ed41077c",
			id = 4,
			uses = 10,
		},
		{
			price = 1,
			img = "img@197ed410214",
			id = 5,
			uses = 10,
		},
		{
			price = 1,
			img = "img@197ed3a7e0a",
			id = 6,
			uses = 10,
		},
		{
			price = 5,
			img = "img@198008a0cb4",
			id = 2,
			uses = 100,
		},
	},
	{ -- smallbox
	},
	{ -- bigbox
	},
	{ -- trampoline
	},
	{ -- balloon
	},
	{ -- plank
	},
	{ -- cloud
	},
	{ -- tombstone
	},
	{ -- shop power
		{
			price = 0,
			img = "173db111ba4.png",
			id = 1,
			shop_scale = 0.6,
		},
		{
			price = 0,
			img = "1507c1da0e8.png",
			id = 2,
			shop_scale = 0.6,
			hidden = true,
		},
		{
			price = 10,
			img = "16d67f42439.png",
			uses = 10,
			id = 6,
		},
		{
			price = 20,
			img = "173dee98c61.png",
			id = 4,
			uses = 10,
			shop_scale = 0.7,
		},
		{
			price = 50,
			img = "img@1943409e46e",
			id = 5,
			uses = 10,
		},
		{
			price = 100,
			img = "149c068e42f.png",
			id = 3,
			uses = 10,
			shop_scale = 0.8,
		},
		{
			price = 200,
			img = "img@198c8bc6054",
			id = 7,
			uses = 10,
			hidden = true,
		},
	},
	{ -- snowball
	},
}

local shop_migrate_ids = {
['2.2'] = 132,
['2.3'] = 191,
['2.4'] = 50,
['2.5'] = 40,
['28.2'] = 6,
['28.3'] = 75,
['28.4'] = 39,
['28.5'] = 54,
['28.6'] = 19,
['28.7'] = 204,
['28.8'] = 173,
['28.9'] = 55,
['28.11'] = 71,
['34.1'] = 68,
['34.2'] = 94,
['34.3'] = 212,
['34.4'] = 148,
['34.5'] = 104,
['34.6'] = 110,
['34.7'] = 72,
['34.8'] = 51,
['34.9'] = 97,
['34.11'] = 123,
['34.12'] = 65,
['34.13'] = 70,
['57.1'] = 4,
['57.2'] = 199,
['57.3'] = 178,
['57.4'] = 63,
['57.5'] = 69,
['57.6'] = 145,
['57.7'] = 11,
['57.8'] = 29,
['57.9'] = 27,
['57.11'] = 209,
['57.12'] = 208,
['57.13'] = 102,
['57.14'] = 115,
['57.15'] = 207,
['90.1'] = 198,
['90.2'] = 206,
['90.3'] = 205,
['90.4'] = 38,
['90.5'] = 14,
['90.6'] = 18,
['90.7'] = 193,
['100.1'] = 182,
['100.2'] = 109,
['100.3'] = 103,
['109'] = 83,
['116'] = 56,
['138'] = 23,
['140'] = 127,
['142'] = 82,
['147'] = 32,
['154'] = 16,
['157'] = 98,
['162'] = 121,
['164'] = 36,
['165'] = 43,
['172'] = 159,
['180'] = 139,
['181'] = 85,
['200.1'] = 5,
['203'] = 118,
['212'] = 114,
['219'] = 113,
['222'] = 35,
['228'] = 84,
['229'] = 122,
['230'] = 124,
['241'] = 211,
['244'] = 78,
['246'] = 117,
['248'] = 45,
['249'] = 74,
['250'] = 183,
['251'] = 26,
['253'] = 175,
['256'] = 162,
['257'] = 172,
['260'] = 203,
['261'] = 151,
['263'] = 201,
['273'] = 105,
['274'] = 196,
['275'] = 189,
['279'] = 157,
['280'] = 138,
['281'] = 194,
['309'] = 192,
['313'] = 177,
['314'] = 180,
['317'] = 52,
['319'] = 116,
['324'] = 176,
['325'] = 188,
['327'] = 66,
['333'] = 171,
['336'] = 181,
['347'] = 190,
['350'] = 164,
['351'] = 25,
['355'] = 22,
['358'] = 186,
['360'] = 202,
['361'] = 152,
['701'] = 89,
['702'] = 80,
['703'] = 101,
['704'] = 210,
['705'] = 91,
['706'] = 136,
['707'] = 96,
['708'] = 111,
['709'] = 81,
['710'] = 129,
['711'] = 120,
['712'] = 170,
['713'] = 59,
['714'] = 119,
['715'] = 112,
['716'] = 58,
['717'] = 53,
['718'] = 135,
['719'] = 169,
['720'] = 168,
['721'] = 47,
['722'] = 41,
['723'] = 73,
['724'] = 155,
['1028'] = 3,
['2800.1'] = 76,
['2801'] = 88,
['2805'] = 106,
['2806'] = 93,
['2807'] = 165,
['2820'] = 87,
['2823'] = 79,
['2824'] = 99,
['2825'] = 8,
['2827'] = 187,
['2833'] = 48,
['2838'] = 13,
['2840'] = 12,
['2841'] = 30,
['2842'] = 61,
['2844'] = 107,
['2855'] = 141,
['2857'] = 137,
['2859'] = 134,
['2863'] = 60,
['2864'] = 92,
['2866'] = 142,
['2867'] = 184,
['2868'] = 143,
['2869'] = 49,
['2870'] = 44,
['2871'] = 108
}

local shop_skins = {
-- Defaults
[1] = {
	price = 0,
	shop_img = '18b59d0c458.png',
	shop_scale = 0.5,
	tab = 1
},
[2] = {
	price = 0,
	shop_img = '18b59d0c458.png',
	tab = 2
},
[7] = {
	price = 0,
	shop_img = '18b2b460ab3.png',
	tab = 3
},
[28] = {
	price = 0,
	shop_img = '18b31269b0a.png',
	shop_img_fnc = function(player, file)
		if file.c >= 400 then
			return "173db16a824.png"
		end
	end,
	tab = 4
},
[34] = {
	price = 0,
	shop_img = '173db111ba4.png',
	shop_scale = 0.4,
	tab = 9
},
[46] = {
	price = 0,
	shop_img = '173db2812bc.png',
	tab = 5
},
[57] = {
	price = 0,
	shop_img = '173db14a1d6.png',
	tab = 6
},
[90] = {
	price = 0,
	shop_img = '173db33602c.png',
	shop_scale = 0.65,
	tab = 7
},

-- Christmas
[3] = {
	currency = 'gifts',
	img = 'img@193c20b2a55',
	price = 30,
	shop_img = 'img@193c1e22110',
	shop_scale = 0.7,
	tab = 7
},
[4] = {
	currency = 'gifts',
	img = 'img@193b7a44117',
	price = 30,
	shop_scale = 0.7,
	tab = 6,
	y = 0.7
},
[5] = {
	currency = 'gifts',
	img = 'img@193c1beb7b2',
	price = 30,
	tab = 2
},

-- Lemonade
[213] = {
	currency = 'lemonade',
	img = 'img@197ed06bf10',
	price = 10,
	tab = 4
},
[214] = {
	currency = 'lemonade',
	img = 'img@197ed06d073',
	price = 20,
	shop_scale = 0.7,
	tab = 6
},
[215] = {
	currency = 'lemonade',
	img = 'img@197ecff508b',
	price = 30,
	shop_scale = 0.7,
	tab = 7,
	y = 0.55
},
}
local file_skins = {}
local shop_state = {}

do
	local sort, max = table.sort, math.max
	local in_shop, last_id = {}, 0

	local function prepareSkins()
		local tab
		for i=0, 9 do
			shop_items[i]._len = #shop_items[i]
		end
		for id, skin in next, shop_skins do
			skin.id = id
			skin.price = skin.price or -1
			skin.so = skin.so or default_skins_by_cat[skin.tab] or 0
			tab = shop_items[skin.tab]
			tab._len = tab._len + 1
			tab[tab._len] = skin
			in_shop[id] = true
			last_id = max(last_id, id)
		end
		shop_state.last_id = last_id
	end

	local function shopSorter(a, b)
		if default_skins_by_cat[a.tab] == a.id then
			return true
		end
		if default_skins_by_cat[b.tab] == b.id then
			return false
		end
		if a.currency and not b.currency then
			return false
		end
		if not a.currency and b.currency then
			return true
		end
		return a.price < b.price
	end

	local function reorderShop()
		for i=1, 7 do
			sort(shop_items[i], shopSorter)
		end
		sort(shop_items[9], shopSorter)
	end

	local function prepareFileSkins(skins, map, start, last)
		local tab, id, skin
		for i=start, last do
			id = map[i]
			if id and not in_shop[id] then
				skin = skins[id]
				tab = shop_items[skin.tab]
				tab._len = tab._len + 1
				tab[tab._len] = skin
				in_shop[id] = true
			end
		end
	end

	prepareSkins()
	reorderShop()

	onEvent("GameDataLoaded", function(data)
		if data.shop then
			if shop_state.parsed then
				if not SplitRW.shouldParse(data.shop, shop_state) then
					return
				end

				shop_state = {
					items = shop_state.items, -- reuse existing tables
				}
			end

			shop_state.ts = data.shop.ts
			shop_state.last_id = max(last_id, data.shop.last_id)
			file_skins = SplitRW.parse(data.shop.skins, shop_state, 300, "shop")

			prepareFileSkins(file_skins, shop_state.indexMap, shop_state.prev, shop_state.index - 1)
			reorderShop()

			if shop_state.parsed then
				translatedChatMessage("shop_loaded")
			end
		end
	end)
end
