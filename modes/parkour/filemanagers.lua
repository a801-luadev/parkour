local filemanagers = {
	["17"] = FileManager.new({
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

	["77"] = FileManager.new({
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

	["63"] = FileManager.new({
		type = "dictionary",
		map = {
			{
				name = "sanction",
				type = "dictionary",
				map = {
					{ name = "ts", type = "number" },
					{ name = "mods", type = "array", objects = { type = "string" } },
					{ name = "data", type = "string" },
				}
			}
		}
	}):disableValidityChecks():prepare(),

	["54"] = FileManager.new({
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

	["51"] = FileManager.new({
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