local band = (bit or bit32).band
local bxor = (bit or bit32).bxor

local ranks = {
	admin = {_count = 0},
	bot = {_count = 0},
	manager = {_count = 0},
	mod = {_count = 0},
	mapper = {_count = 0},
	trainee = {_count = 0},
	translator = {_count = 0}
}
local ranks_id = {
	admin = 2 ^ 0,
	manager = 2 ^ 1,
	mod = 2 ^ 2,
	mapper = 2 ^ 3,
	trainee = 2 ^ 4,
	translator = 2 ^ 5,
	bot = 2 ^ 6
}
local ranks_permissions = {
	admin = {}, -- will get every permission
	bot = {}, -- will get every permission
	manager = {},
	mod = {
		ban = true,
		unban = true,
		spectate = true,
		get_player_room = true,
		change_map = true,
		load_custom_map = true,
		kill = true
	},
	mapper = {
		change_map = true,
		load_custom_map = true,
		enable_review = true
	},
	trainee = {
		kill = true,
		spectate = true,
		get_player_room = true
	},
	translator = {
		change_map = true
	}
}
player_ranks = {}
local perms = {}
local hidden_ranks = {
	bot = true,
	translator = true
}
local ranks_order = {"admin", "manager", "mod", "mapper", "trainee"}

for rank, perms in next, ranks_permissions do
	if rank ~= "admin" and rank ~= "bot" then
		for perm_name, allowed in next, perms do
			ranks_permissions.admin[perm_name] = allowed
			ranks_permissions.bot[perm_name] = allowed
		end
	end
end

onEvent("GameDataLoaded", function(data)
	if data.ranks then
		ranks, perms, player_ranks = {
			admin = {_count = 0},
			bot = {_count = 0},
			manager = {_count = 0},
			mod = {_count = 0},
			mapper = {_count = 0},
			trainee = {_count = 0},
			translator = {_count = 0}
		}, {}, {}
		local player_perms, _player_ranks
		for player, rank in next, data.ranks do
			player_perms, _player_ranks = {}, {}
			for name, id in next, ranks_id do
				if band(rank, id) > 0 then
					_player_ranks[name] = true
					ranks[name][player] = true
					ranks[name]._count = ranks[name]._count + 1
					for perm, enabled in next, ranks_permissions[name] do
						player_perms[perm] = enabled
					end
				end
			end
			player_ranks[player] = _player_ranks
			perms[player] = player_perms
		end
	end
end)
