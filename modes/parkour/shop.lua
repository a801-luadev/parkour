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
{
	id = 1,
	price = 0,
	shop_img = '18b59d0c458.png',
	shop_scale = 0.5,
	tab = 1
},
{
	id = 2,
	price = 0,
	shop_img = '18b59d0c458.png',
	tab = 2
},
{
	currency = 'gifts',
	id = 3,
	img = 'img@193c20b2a55',
	price = 30,
	shop_img = 'img@193c1e22110',
	shop_scale = 0.7,
	tab = 7
},
{
	currency = 'gifts',
	id = 4,
	img = 'img@193b7a44117',
	price = 30,
	shop_scale = 0.7,
	tab = 6,
	y = 0.7
},
{
	currency = 'gifts',
	id = 5,
	img = 'img@193c1beb7b2',
	price = 30,
	tab = 2
},
{
	id = 6,
	img = 'img@1943a239205',
	price = 8500,
	shop_scale = 0.8,
	tab = 4
},
{
	id = 7,
	price = 0,
	shop_img = '18b2b460ab3.png',
	tab = 3
},
{
	id = 8,
	price = 280,
	shop_img = '18b53f01a7d.png',
	so = 2825,
	tab = 4
},
{
	hidden = true,
	id = 9,
	img = '18b40083e91.png',
	tab = 1
},
{
	hidden = true,
	id = 10,
	img = '18b40135e54.png',
	tab = 2
},
{
	id = 11,
	img = 'img@1941613fa3d',
	price = 1000,
	shop_scale = 0.7,
	tab = 6
},
{
	id = 12,
	price = 2500,
	shop_img = '18b53f100e9.png',
	so = 2840,
	tab = 4
},
{
	id = 13,
	price = 140,
	shop_img = '18b53f0b3d7.png',
	so = 2838,
	tab = 4
},
{
	id = 14,
	img = '17123822449.png',
	price = 500,
	tab = 7
},
{
	hidden = true,
	id = 15,
	img = '18b400a6558.png',
	tab = 1
},
{
	id = 16,
	img = '18b4008dacf.png',
	price = 1960,
	shop_img = '18b53ea04c8.png',
	shop_scale = 0.5,
	tab = 1
},
{
	hidden = true,
	id = 17,
	img = '18b40158130.png',
	tab = 2
},
{
	id = 18,
	img = 'img@196b3750757',
	price = 100,
	tab = 7
},
{
	id = 19,
	img = 'img@194f8638d35',
	price = 100,
	tab = 4
},
{
	hidden = true,
	id = 20,
	img = '18b4007f075.png',
	tab = 1
},
{
	hidden = true,
	id = 21,
	img = '18b401448b8.png',
	tab = 2
},
{
	id = 22,
	img = '18b537c3559.png',
	price = 2240,
	shop_img = '18b53fc863d.png',
	tab = 5,
	y = 0.51
},
{
	id = 23,
	price = 280,
	shop_img = '18b53e880ff.png',
	shop_scale = 0.5,
	so = 138,
	tab = 1
},
{
	hidden = true,
	id = 24,
	img = '18b4019de68.png',
	tab = 4
},
{
	id = 25,
	img = '18b537be737.png',
	price = 1540,
	shop_img = '18b53fc35cd.png',
	tab = 5,
	y = 0.55
},
{
	id = 26,
	img = '18b40131024.png',
	price = 420,
	shop_img = '18b53e96b76.png',
	tab = 2,
	y = 0.65
},
{
	id = 27,
	img = 'img@1950ff9de7d',
	price = 9000,
	shop_scale = 0.7,
	tab = 6,
	x = 0.4,
	y = 0.5
},
{
	id = 28,
	price = 0,
	shop_img = '18b31269b0a.png',
	shop_img_fnc = function(player, file)
		if file.c >= 400 then
			return "173db16a824.png"
		end
	end,
	tab = 4
},
{
	id = 29,
	img = 'img@194f83fb43d',
	price = 100,
	shop_scale = 0.7,
	tab = 6
},
{
	id = 30,
	price = 1680,
	shop_img = '18b53f14dd2.png',
	so = 2841,
	tab = 4
},
{
	hidden = true,
	id = 31,
	img = '18b4011d953.png',
	tab = 2
},
{
	id = 32,
	img = '18b4006b7e6.png',
	price = 1540,
	shop_img = '18b53e96b76.png',
	shop_scale = 0.5,
	tab = 1,
	y = 0.6
},
{
	hidden = true,
	id = 33,
	img = '18b40057d3b.png',
	tab = 1
},
{
	id = 34,
	price = 0,
	shop_img = '173db111ba4.png',
	shop_scale = 0.4,
	tab = 9
},
{
	id = 35,
	price = 1960,
	shop_img = '18b53ecbbf5.png',
	so = 222,
	tab = 2
},
{
	id = 36,
	img = '18b400be9bc.png',
	price = 2500,
	shop_img = '18b53eb8e68.png',
	shop_scale = 0.5,
	tab = 1
},
{
	hidden = true,
	id = 37,
	img = '18b401703ee.png',
	tab = 2
},
{
	id = 38,
	img = 'img@196b3666fab',
	price = 700,
	tab = 7
},
{
	id = 39,
	img = 'img@1943a4d7328',
	price = 4000,
	tab = 4
},
{
	hidden = true,
	id = 40,
	img = '18d94566b19.png',
	tab = 2
},
{
	id = 41,
	img = '18b4010c62f.png',
	price = 1540,
	shop_img = '18b53f86b71.png',
	tab = 3
},
{
	hidden = true,
	id = 42,
	img = '18b4007060c.png',
	tab = 1
},
{
	id = 43,
	img = '18b400c3a16.png',
	price = 560,
	shop_img = '18b53ebdc65.png',
	shop_scale = 0.5,
	tab = 1
},
{
	id = 44,
	img = 'img@19405c72d7f',
	price = 12000,
	tab = 4
},
{
	id = 45,
	img = '18b401225c5.png',
	price = 6000,
	shop_img = 'img@1941031b5c8',
	shop_scale = 0.75,
	tab = 2,
	x = 0.6,
	y = 0.6
},
{
	id = 46,
	price = 0,
	shop_img = '173db2812bc.png',
	tab = 5
},
{
	id = 47,
	img = '18b40107833.png',
	price = 400,
	shop_img = 'img@196aef579bf',
	tab = 3
},
{
	id = 48,
	img = 'img@19405ced563',
	price = 5000,
	tab = 4
},
{
	id = 49,
	img = 'img@19405eeddfe',
	price = 7000,
	shop_scale = 0.9,
	tab = 4
},
{
	hidden = true,
	id = 50,
	img = '18b40153316.png',
	tab = 2
},
{
	id = 51,
	img = '1674802a592.png',
	price = 1000,
	tab = 9
},
{
	id = 52,
	img = '18b53792ac2.png',
	price = 2100,
	shop_img = '18b53f959a3.png',
	tab = 5,
	y = 0.5
},
{
	id = 53,
	img = '18b400f3f9a.png',
	price = 840,
	shop_img = '18b53f6e4cd.png',
	tab = 3
},
{
	hidden = true,
	id = 54,
	img = '18a1f4d198c.png',
	scale = 0.6,
	tab = 4
},
{
	id = 55,
	img = 'img@1975793006f',
	price = 3000,
	tab = 4
},
{
	id = 56,
	price = 420,
	shop_img = '18b53e74af5.png',
	shop_scale = 0.5,
	so = 116,
	tab = 1
},
{
	id = 57,
	price = 0,
	shop_img = '173db14a1d6.png',
	tab = 6
},
{
	id = 58,
	img = '18b400ef16c.png',
	price = 2100,
	shop_img = '18b53f69692.png',
	tab = 3
},
{
	id = 59,
	img = '18b400e070f.png',
	price = 1820,
	shop_img = '18b53f5ac35.png',
	tab = 3
},
{
	id = 60,
	img = 'img@19405c4d494',
	price = 9000,
	tab = 4
},
{
	id = 61,
	price = 840,
	shop_img = '18b53f19e40.png',
	so = 2842,
	tab = 4
},
{
	hidden = true,
	id = 62,
	img = '18b401a7ab1.png',
	tab = 4
},
{
	id = 63,
	img = 'img@19414bb8b28',
	price = 4000,
	shop_scale = 0.7,
	tab = 6
},
{
	hidden = true,
	id = 64,
	img = '18b401c0154.png',
	tab = 4
},
{
	id = 65,
	img = '185c2dc5d45.png',
	price = 900,
	scale = 0.6,
	shop_scale = 0.8,
	tab = 9
},
{
	id = 66,
	img = '18b537a649b.png',
	price = 1120,
	shop_img = '18b53fa9234.png',
	tab = 5
},
{
	hidden = true,
	id = 67,
	img = '18b4018f402.png',
	tab = 4
},
{
	id = 68,
	img = '169169d8479.png',
	price = 500,
	scale = 0.5,
	shop_scale = 0.5,
	tab = 9
},
{
	id = 69,
	img = 'img@19414c686fc',
	price = 2000,
	shop_scale = 0.7,
	tab = 6
},
{
	id = 70,
	img = '17161288bee.png',
	price = 1200,
	scale = 0.25,
	shop_scale = 0.4,
	tab = 9
},
{
	id = 71,
	img = 'img@19758475406',
	price = 3500,
	tab = 4
},
{
	id = 72,
	img = '188b5c0fec6.png',
	price = 200,
	scale = 0.8,
	tab = 9
},
{
	id = 73,
	img = 'img@194b09c105e',
	price = 3000,
	shop_img = 'img@19530dfc068',
	tab = 3
},
{
	id = 74,
	img = '18b401273e8.png',
	price = 5000,
	shop_img = 'img@1941032103f',
	shop_scale = 0.9,
	tab = 2
},
{
	id = 75,
	img = 'img@1943a307b36',
	price = 6500,
	tab = 4
},
{
	id = 76,
	img = 'img@194106e4426',
	price = 5500,
	scale = 0.5,
	shop_scale = 0.5,
	tab = 4
},
{
	hidden = true,
	id = 77,
	img = '18b4005cd84.png',
	tab = 1
},
{
	id = 78,
	price = 2240,
	shop_img = '18b53e8cf1c.png',
	so = 244,
	tab = 2
},
{
	id = 79,
	price = 700,
	shop_img = '18b53ef7e24.png',
	so = 2823,
	tab = 4
},
{
	id = 80,
	price = 1400,
	shop_img = '18b2b3cb12a.png',
	so = 702,
	tab = 3
},
{
	id = 81,
	price = 280,
	shop_img = '18b2b404911.png',
	so = 709,
	tab = 3
},
{
	id = 82,
	price = 1680,
	shop_img = '18b53e91d53.png',
	shop_scale = 0.5,
	so = 142,
	tab = 1
},
{
	id = 83,
	price = 2240,
	shop_img = '18b53ec28e7.png',
	shop_scale = 0.5,
	so = 109,
	tab = 1
},
{
	id = 84,
	price = 1820,
	shop_img = '18b53ed0943.png',
	so = 228,
	tab = 2
},
{
	id = 85,
	img = 'img@193d0ba33aa',
	price = 5000,
	shop_img = 'img@193d0bdee01',
	shop_scale = 0.1,
	tab = 1
},
{
	hidden = true,
	id = 86,
	img = '18b40061bab.png',
	tab = 1
},
{
	id = 87,
	price = 2240,
	shop_img = '18b53ef3008.png',
	so = 2820,
	tab = 4
},
{
	id = 88,
	price = 2100,
	shop_img = '18b53eee190.png',
	so = 2801,
	tab = 4
},
{
	id = 89,
	price = 140,
	shop_img = '173db3307ed.png',
	so = 701,
	tab = 3
},
{
	id = 90,
	price = 0,
	shop_img = '173db33602c.png',
	shop_scale = 0.65,
	tab = 7
},
{
	id = 91,
	price = 1680,
	shop_img = '18b2b3f017e.png',
	so = 705,
	tab = 3
},
{
	id = 92,
	img = 'img@19405cab7bc',
	price = 10000,
	shop_scale = 0.9,
	tab = 4
},
{
	id = 93,
	price = 1540,
	shop_img = '18b53f3720d.png',
	so = 2806,
	tab = 4
},
{
	id = 94,
	img = 'img@193c5d9f045',
	price = 850,
	tab = 9
},
{
	hidden = true,
	id = 95,
	img = '18b40180a6f.png',
	tab = 4
},
{
	id = 96,
	price = 2240,
	shop_img = '18b2b3fa678.png',
	so = 707,
	tab = 3
},
{
	id = 97,
	img = '16748031acc.png',
	price = 250,
	tab = 9
},
{
	id = 98,
	img = '18b4009c9a6.png',
	price = 840,
	shop_img = '18b53ea55cf.png',
	shop_scale = 0.5,
	tab = 1
},
{
	id = 99,
	price = 980,
	shop_img = '18b53efcc53.png',
	so = 2824,
	tab = 4
},
{
	hidden = true,
	id = 100,
	img = '18b400928fa.png',
	tab = 1
},
{
	id = 101,
	price = 2500,
	shop_img = '18b2b3de757.png',
	so = 703,
	tab = 3
},
{
	id = 102,
	img = 'img@1968a228731',
	price = 7000,
	shop_scale = 0.7,
	tab = 6
},
{
	id = 103,
	img = 'img@19784fc011b',
	price = 3000,
	tab = 1
},
{
	id = 104,
	img = '188b5c017d4.png',
	price = 300,
	scale = 0.7,
	tab = 9
},
{
	id = 105,
	img = 'img@1941033203c',
	price = 7000,
	shop_scale = 0.8,
	tab = 2,
	y = 0.6
},
{
	id = 106,
	price = 1400,
	shop_img = '18b53f23963.png',
	so = 2805,
	tab = 4
},
{
	id = 107,
	price = 1960,
	shop_img = '18b53f1eb4e.png',
	so = 2844,
	tab = 4
},
{
	id = 108,
	img = 'img@19405c9b390',
	price = 7500,
	shop_scale = 0.9,
	tab = 4,
	y = 0.6
},
{
	hidden = true,
	id = 109,
	img = '18c73e40d6d.png',
	tab = 1
},
{
	id = 110,
	img = '1507c172145.png',
	price = 700,
	scale = 0.8,
	tab = 9
},
{
	id = 111,
	price = 700,
	shop_img = '18b2b3ff965.png',
	so = 708,
	tab = 3
},
{
	id = 112,
	img = '18b400ea34c.png',
	price = 500,
	shop_img = 'img@196aef89969',
	tab = 3
},
{
	id = 113,
	price = 140,
	shop_img = '18b53e74af5.png',
	so = 219,
	tab = 2
},
{
	id = 114,
	price = 2500,
	shop_img = '18b53ec28e7.png',
	so = 212,
	tab = 2
},
{
	id = 115,
	img = 'img@19784b8916b',
	price = 2500,
	scale = 0.92,
	shop_scale = 0.7,
	tab = 6,
	y = 0.6
},
{
	id = 116,
	img = '18b53797a1a.png',
	price = 700,
	shop_img = '18b53f9a7d1.png',
	tab = 5,
	y = 0.65
},
{
	id = 117,
	price = 1540,
	shop_img = '18b53e91d53.png',
	so = 246,
	tab = 2
},
{
	id = 118,
	price = 1120,
	shop_img = '18b53e831e7.png',
	so = 203,
	tab = 2
},
{
	id = 119,
	img = '18b400e5535.png',
	price = 300,
	shop_img = 'img@196aefaaf03',
	tab = 3
},
{
	id = 120,
	img = '18b400d6acd.png',
	price = 250,
	shop_img = 'img@196aefaa45a',
	tab = 3
},
{
	id = 121,
	img = '18b400b4fb8.png',
	price = 1260,
	shop_img = '18b53eb403f.png',
	shop_scale = 0.5,
	tab = 1
},
{
	id = 122,
	price = 980,
	shop_img = '18b53ed5760.png',
	so = 229,
	tab = 2
},
{
	hidden = true,
	id = 123,
	img = '177fc32bd99.png',
	price = 900,
	scale = 0.15,
	shop_scale = 0.2,
	tab = 9
},
{
	id = 124,
	price = 560,
	shop_img = '18b53e7e4e4.png',
	so = 230,
	tab = 2
},
{
	id = 125,
	price = 700,
	shop_img = '18b53e797ee.png',
	shop_scale = 0.5,
	so = 125,
	tab = 1
},
{
	id = 126,
	price = 1120,
	shop_img = '18b53e7e4e4.png',
	shop_scale = 0.5,
	so = 126,
	tab = 1
},
{
	id = 127,
	price = 2100,
	shop_img = '18b53e8cf1c.png',
	shop_scale = 0.5,
	so = 140,
	tab = 1
},
{
	id = 128,
	price = 980,
	shop_img = '18b53e831e7.png',
	shop_scale = 0.5,
	so = 128,
	tab = 1
},
{
	id = 129,
	img = '18b400d1c43.png',
	price = 560,
	shop_img = '18b53f4c31b.png',
	tab = 3,
	y = 0.7
},
{
	hidden = true,
	id = 130,
	img = '18b401668cc.png',
	tab = 2
},
{
	hidden = true,
	id = 131,
	img = '18b40194226.png',
	tab = 4
},
{
	id = 132,
	img = 'img@1943a219514',
	price = 5250,
	shop_scale = 0.9,
	tab = 2,
	y = 0.5
},
{
	hidden = true,
	id = 133,
	img = '18b40199045.png',
	tab = 4
},
{
	id = 134,
	img = '18b401c4f6e.png',
	price = 420,
	shop_img = '18b53f323ca.png',
	tab = 4
},
{
	id = 135,
	img = '18b400f8dbd.png',
	price = 1120,
	shop_img = '18b53f732dd.png',
	tab = 3
},
{
	id = 136,
	price = 1260,
	shop_img = '18b2b3f54d8.png',
	so = 706,
	tab = 3
},
{
	id = 137,
	img = '18b401bb336.png',
	price = 560,
	shop_img = '18b53f2d5a7.png',
	tab = 4
},
{
	id = 138,
	img = 'img@194103433ec',
	price = 8500,
	tab = 2
},
{
	id = 139,
	img = 'img@194103c3eea',
	price = 7000,
	tab = 1
},
{
	hidden = true,
	id = 140,
	img = '18b4013fa8f.png',
	tab = 2
},
{
	id = 141,
	img = '18b401b16f0.png',
	price = 1820,
	shop_img = '18b53f28793.png',
	tab = 4
},
{
	id = 142,
	img = 'img@19405c6163d',
	price = 11000,
	tab = 4
},
{
	id = 143,
	img = 'img@19405c83dc8',
	price = 8000,
	scale = 0.8,
	shop_scale = 0.8,
	tab = 4
},
{
	hidden = true,
	id = 144,
	img = '18b401ac8c7.png',
	tab = 4
},
{
	id = 145,
	img = 'img@19416277202',
	price = 3000,
	shop_scale = 0.7,
	tab = 6
},
{
	hidden = true,
	id = 146,
	img = '18b400669c6.png',
	nomigrate = true,
	tab = 1
},
{
	hidden = true,
	id = 147,
	img = '18b401a2c83.png',
	tab = 4
},
{
	id = 148,
	img = '17d483107d9.png',
	price = 1500,
	scale = 0.8,
	tab = 9
},
{
	hidden = true,
	id = 149,
	img = '18b40075436.png',
	nomigrate = true,
	tab = 1
},
{
	id = 150,
	img = '18b4007a243.png',
	price = 1820,
	shop_img = '18b53e9b7d7.png',
	shop_scale = 0.5,
	tab = 1
},
{
	id = 151,
	img = '18b40161bc6.png',
	price = 840,
	shop_img = '18b53ee41df.png',
	tab = 2
},
{
	id = 152,
	img = '18b537d1fde.png',
	price = 1400,
	shop_img = '18b53fd74a2.png',
	tab = 5,
	y = 0.55
},
{
	hidden = true,
	id = 153,
	img = '18b40088cb4.png',
	nomigrate = true,
	tab = 1
},
{
	hidden = true,
	id = 154,
	img = '18b4018a633.png',
	tab = 4
},
{
	id = 155,
	img = 'img@196aeed5a8f',
	price = 900,
	shop_img = 'img@196aeed4fe4',
	tab = 3
},
{
	hidden = true,
	id = 156,
	img = '18b40097712.png',
	nomigrate = true,
	tab = 1
},
{
	id = 157,
	img = 'img@1941033f671',
	price = 8000,
	tab = 2
},
{
	id = 158,
	img = '18b400a173a.png',
	price = 140,
	shop_img = '18b53eaa3f9.png',
	shop_scale = 0.5,
	tab = 1
},
{
	id = 159,
	img = 'img@194103b8808',
	price = 5500,
	tab = 1
},
{
	hidden = true,
	id = 160,
	img = '18b400ab37d.png',
	nomigrate = true,
	tab = 1
},
{
	id = 161,
	img = '18b400b019a.png',
	price = 1400,
	shop_img = '18b53eaf1f7.png',
	shop_scale = 0.5,
	tab = 1
},
{
	id = 162,
	img = '18b401496c6.png',
	price = 280,
	shop_img = '18b53ea55cf.png',
	tab = 2
},
{
	hidden = true,
	id = 163,
	img = '18b400b9ccf.png',
	nomigrate = true,
	tab = 1
},
{
	id = 164,
	img = '18b537b99d5.png',
	price = 980,
	shop_img = '18b53fbd2c8.png',
	tab = 5
},
{
	id = 165,
	price = 1120,
	shop_img = '18b53f3c01d.png',
	so = 2807,
	tab = 4
},
{
	hidden = true,
	id = 166,
	img = '18b400c8838.png',
	nomigrate = true,
	tab = 1
},
{
	id = 167,
	img = 'img@194103b4ea2',
	price = 7500,
	tab = 1
},
{
	id = 168,
	img = '18b401029ff.png',
	price = 420,
	shop_img = '18b53f7cf22.png',
	tab = 3
},
{
	id = 169,
	img = '18b400fdcbc.png',
	price = 750,
	shop_img = 'img@196aef3a7ff',
	tab = 3
},
{
	id = 170,
	img = '18b400db8e9.png',
	price = 980,
	shop_img = '18b53f55e23.png',
	tab = 3
},
{
	id = 171,
	img = '18b537ab2af.png',
	price = 140,
	shop_img = '18b53fae10e.png',
	tab = 5,
	x = 0.48
},
{
	id = 172,
	img = '18b4014e4f2.png',
	price = 1260,
	shop_img = '18b53eaa3f9.png',
	tab = 2
},
{
	id = 173,
	img = 'img@195a2571468',
	price = 4500,
	tab = 4
},
{
	id = 174,
	img = 'img@194103bc560',
	price = 6000,
	tab = 1
},
{
	id = 175,
	img = '18b4013ac6c.png',
	price = 1400,
	shop_img = '18b53eda58d.png',
	tab = 2
},
{
	id = 176,
	img = '18b5379c6d5.png',
	price = 280,
	shop_img = '18b53f9f5ef.png',
	tab = 5,
	y = 0.4
},
{
	id = 177,
	img = '18b537890e5.png',
	price = 420,
	shop_img = '18b53f8bc53.png',
	tab = 5,
	x = 0.45,
	y = 0.68
},
{
	id = 178,
	img = 'img@1941041eb1e',
	price = 10000,
	shop_scale = 0.7,
	tab = 6,
	y = 0.5
},
{
	id = 179,
	img = 'img@194103c0751',
	price = 6500,
	tab = 1
},
{
	id = 180,
	img = '18b5378dddb.png',
	price = 560,
	shop_img = '18b53f908cb.png',
	tab = 5,
	y = 0.53
},
{
	id = 181,
	img = '18b537affdb.png',
	price = 840,
	shop_img = '18b53fb2e85.png',
	tab = 5,
	y = 0.7
},
{
	hidden = true,
	id = 182,
	img = 'img@193cd8077a3',
	scale = 0.25,
	shop_scale = 0.2,
	tab = 1,
	y = 0.7
},
{
	id = 183,
	img = '18b4012c205.png',
	price = 5500,
	shop_img = 'img@19410329b00',
	shop_scale = 0.9,
	tab = 2
},
{
	id = 184,
	img = 'img@19405cc23fa',
	price = 6000,
	tab = 4
},
{
	hidden = true,
	id = 185,
	img = '18b40153316.png',
	tab = 2
},
{
	id = 186,
	img = '18b537c8378.png',
	price = 1820,
	shop_img = '18b53fcd4e9.png',
	tab = 5,
	y = 0.55
},
{
	id = 187,
	price = 1260,
	shop_img = '18b53f066f1.png',
	so = 2827,
	tab = 4
},
{
	id = 188,
	img = '18b537a13cd.png',
	price = 1680,
	shop_img = '18b53fa440f.png',
	tab = 5,
	y = 0.55
},
{
	id = 189,
	img = 'img@19410339b6b',
	price = 7500,
	tab = 2
},
{
	id = 190,
	img = '18b537b4cdb.png',
	price = 1960,
	shop_img = '18b53fb85b8.png',
	tab = 5,
	y = 0.55
},
{
	id = 191,
	img = 'img@1942f8d266f',
	price = 4000,
	shop_scale = 0.9,
	tab = 2,
	y = 0.5
},
{
	id = 192,
	img = '18b53784421.png',
	price = 2500,
	shop_img = '18b53fdc2c8.png',
	tab = 5,
	y = 0.5
},
{
	hidden = true,
	id = 193,
	img = 'img@196b59ef6a3',
	scale = 0.75,
	shop_scale = 0.8,
	tab = 7
},
{
	id = 194,
	img = 'img@194103472c9',
	price = 9000,
	tab = 2
},
{
	hidden = true,
	id = 195,
	img = '18b40185865.png',
	tab = 4
},
{
	id = 196,
	img = 'img@194103363f6',
	price = 6500,
	tab = 2
},
{
	hidden = true,
	id = 197,
	img = '18b40175208.png',
	tab = 2
},
{
	id = 198,
	img = 'img@196b352834b',
	price = 200,
	tab = 7,
	y = 0.55
},
{
	id = 199,
	img = 'img@1940598ffcb',
	price = 5000,
	shop_scale = 0.7,
	tab = 6,
	y = 0.45
},
{
	hidden = true,
	id = 200,
	img = '18b401b65eb.png',
	tab = 4
},
{
	id = 201,
	img = '18b4016b5c0.png',
	price = 2100,
	shop_img = '18b53ee8fda.png',
	tab = 2
},
{
	id = 202,
	img = '18b537cd1ac.png',
	price = 1260,
	shop_img = '18b53fd2286.png',
	tab = 5,
	y = 0.65
},
{
	id = 203,
	img = '18b4015cf4e.png',
	price = 1680,
	shop_img = '18b53edf1d0.png',
	tab = 2
},
{
	id = 204,
	img = 'img@194f875f282',
	price = 100,
	tab = 4
},
{
	id = 205,
	img = 'img@196b362c7f4',
	price = 800,
	tab = 7
},
{
	hidden = true,
	id = 206,
	img = 'img@196b35d55d8',
	size = 1.2,
	tab = 7,
	y = 0.4
},
{
	id = 207,
	img = 'img@1974d859e00',
	price = 3500,
	shop_scale = 0.7,
	tab = 6
},
{
	id = 208,
	img = 'img@1968a225b50',
	price = 6000,
	shop_scale = 0.7,
	tab = 6
},
{
	id = 209,
	img = 'img@1950c2b3fe4',
	price = 9001,
	scale = 0.9,
	shop_scale = 0.6,
	tab = 6,
	x = 0.6,
	y = 0.5
},
{
	id = 210,
	price = 1960,
	shop_img = '18b2b3eafa5.png',
	so = 704,
	tab = 3
},
{
	id = 211,
	price = 700,
	shop_img = '18b53e880ff.png',
	so = 241,
	tab = 2
},
{
	id = 212,
	img = '165df84aad8.png',
	price = 800,
	scale = 0.6,
	shop_scale = 0.8,
	tab = 9
},
{
	id = 213,
	currency = 'lemonade',
	img = 'img@197ed06bf10',
	price = 10,
	tab = 4
},
{
	id = 214,
	currency = 'lemonade',
	img = 'img@197ed06d073',
	price = 20,
	shop_scale = 0.7,
	tab = 6
},
{
	id = 215,
	currency = 'lemonade',
	img = 'img@197ecff508b',
	price = 30,
	shop_scale = 0.7,
	tab = 7,
	y = 0.55
},
{
	id = 216,
	img = 'img@1983034c811',
	price = 4500,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 217,
	img = 'img@198302259f6',
	price = 1500,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 218,
	img = 'img@198302242f9',
	price = 10001,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 219,
	img = 'img@19830222adb',
	price = 3250,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 220,
	img = 'img@198302200f5',
	price = 1750,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 221,
	img = 'img@1983021eb2e',
	price = 4500,
	shop_scale = 0.7,
	tab = 6,
},
{
	hidden = true,
	id = 222,
	img = 'img@198299bd98f',
	price = -1,
	tab = 2,
},
{
	id = 223,
	img = 'img@19825f0bf31',
	price = 3750,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 224,
	img = 'img@19816a5052f',
	price = 5500,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 225,
	img = 'img@19816994826',
	price = 3900,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 226,
	img = 'img@1981696737d',
	price = 2900,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 227,
	img = 'img@198168a9c15',
	price = 2800,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 228,
	img = 'img@19839733112',
	shop_img = 'img@19839732c2e',
	price = 4000,
	tab = 3,
	y = 0.4,
},
{
	id = 229,
	img = 'img@197edbff9b0',
	price = 8000,
	shop_scale = 0.7,
	tab = 6,
},
{
	id = 230,
	img = 'img@198c9786028',
	price = 1500,
	tab = 7,
	x = 0.55,
	y = 0.6,
},
{
	id = 231,
	img = 'img@198cd50b191',
	price = 1000,
	tab = 7,
},
}

do
	local skin
	for i=1, #shop_skins do
		skin = shop_skins[i]
		if skin.id ~= i then
			error('Shop skin ID mismatch: expected ' .. i .. ', got ' .. skin.id)
		end
		skin.price = skin.price or -1
		skin.so = skin.so or default_skins_by_cat[skin.tab] or 0
		table.insert(shop_items[skin.tab], skin)
	end
	for i=1, 9 do
		if i ~= 8 then
			table.sort(shop_items[i], function(a, b)
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
			end)
		end
	end
end
