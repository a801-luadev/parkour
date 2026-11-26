local files = {
	init = 17, -- ranks, maps, maps2, maps3, maps4, maps5, map_polls
	leaderboard = 77, -- ranking, weekly
	sanction = 84, -- sanction
	shop = 54, -- shop
	npc = 51, -- npc, xml
}

local filemanagers = {
	[tostring(files.init)] = FileManager.new({
		type = "dictionary",
		map = {
			{
				name = "ranks",
				type = "dictionary",
				objects = {
					type = "number"
				}
			},
			{
				name = "maps",
				type = "array",
				objects = {
					type = "number"
				}
			},
			{
				name = "maps2",
				type = "array",
				objects = {
					type = "number"
				}
			},
			{
				name = "maps3",
				type = "array",
				objects = {
					type = "number"
				}
			},
			{
				name = "maps4",
				type = "array",
				objects = {
					type = "number"
				}
			},
			{
				name = "maps5",
				type = "array",
				objects = {
					type = "number"
				}
			},
			{
				name = "map_polls",
				type = "array",
				objects = {
					type = "number"
				}
			},
		}
	}):disableValidityChecks():prepare(),

	[tostring(files.leaderboard)] = FileManager.new({
		type = "dictionary",
		map = {
			{
				name = "ranking",
				type = "string",
			},
			{
				name = "weekly",
				type = "dictionary",
				map = {
					{
						name = "ranks",
						type = "string",
					},
					{
						name = "ts",
						type = "string"
					},
					{
						name = "wl",
						type = "dictionary",
						objects = {
							type= "number"
						}
					}
				}
			},
			{
				name = "coinranking",
				type = "string",
			},
			{
				name = "diff1ranking",
				type = "string",
			},
			{
				name = "diff2ranking",
				type = "string",
			},
			{
				name = "diff3ranking",
				type = "string",
			},
		}
	}):disableValidityChecks():prepare(),

	[tostring(files.sanction)] = FileManager.new({
		type = "dictionary",
		map = {
			{
				name = "sanction",
				type = "dictionary",
				map = {
					{ name = "ts", type = "number" },
					{ name = "mods", type = "array", objects = { type = "string" } },
					{ name = "legacy", type = "string" },
					{ name = "perma", type = "string" },
					{ name = "temp", type = "string" },
					{ name = "data", type = "string" },
					{ name = "archived", type = "number" },
				}
			}
		}
	}):disableValidityChecks():prepare(),

	[tostring(files.shop)] = FileManager.new({
		type = "dictionary",
		map = {
			{
				name = "shop",
				type = "dictionary",
				map = {
					{
						name = "ts",
						type = "number",
					},
					{
						name = "last_id",
						type = "number",
					},
					{
						name = "skins",
						type = "string"
					},
				}
			}
		}
	}):disableValidityChecks():prepare(),

	[tostring(files.npc)] = FileManager.new({
		type = "dictionary",
		map = {
			{
				name = "npc",
				type = "dictionary",
				objects = { -- key is npc name
					type = "dictionary",
					map = {
						{
							name = "action",
							type = "string"
						},
						{
							name = "param",
							type = "string"
						},
						{
							name = "active",
							type = "number"
						},
						{
							name = "look",
							type = "string"
						},
						{
							name = "definition",
							type = "string"
						},
					}
				}
			}
		}
	}):disableValidityChecks():prepare(),
}