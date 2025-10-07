local filemanagers = {
	["40"] = FileManager.new({
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
		}
	}):disableValidityChecks():prepare(),

	["21"] = FileManager.new({
		type = "dictionary",
		map = {
			{
				name = "ranking",
				type = "array",
				objects = {
					type = "array",
					map = {
						{
							type = "number"
						},
						{
							type = "string",
						},
						{
							type = "number"
						},
						{
							type = "string",
							length = 2
						}
					}
				}
			},
			{
				name = "weekly",
				type = "dictionary",
				map = {
					{
						name = "ranks",
						type = "array",
						objects = {
							type = "array",
							map = {
								{
									type = "number"
								},
								{
									type = "string",
								},
								{
									type = "number"
								},
								{
									type = "string",
									length = 2
								}
							}
						}
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
			}
		}
	}):disableValidityChecks():prepare(),

	["43"] = SanctionFileManager,

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