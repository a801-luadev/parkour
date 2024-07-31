local band = (bit or bit32).band
local bxor = (bit or bit32).bxor

ranks = {
	admin = {_count = 0},
	bot = {_count = 0},
	manager = {_count = 0},
	mod = {_count = 0},
	mapper = {_count = 0},
	trainee = {_count = 0},
	translator = {_count = 0},
	hidden = {_count = 0}
}
local ranks_id = {
	admin = 2 ^ 0,
	manager = 2 ^ 1,
	mod = 2 ^ 2,
	mapper = 2 ^ 3,
	trainee = 2 ^ 4,
	translator = 2 ^ 5,
	bot = 2 ^ 6,
	hidden = 2 ^ 7
}
local ranks_permissions = {
	admin = {
		set_checkpoint_version = true,
		set_name_color = true,
		give_command = true
	}, -- will get every permission
	bot = {
		set_checkpoint_version = true
	}, -- will get every permission
	manager = {
		force_stats = true,
		set_room_limit = true,
		set_map_time = true,
		hide = true,
		handle_map_polls = true,
		see_map_polls = true,
		change_roommod = true,
		see_hidden_staff = true,
	},
	mod = {
		ban = true,
		unban = true,
		spectate = true,
		get_player_room = true,
		change_map = true,
		load_custom_map = true,
		kill = true,
		see_private_maps = true,
		use_tracker = true,
		hide = true,
		change_roommod = true,
		see_hidden_staff = true,
		view_sanctions = true,
	},
	mapper = {
		change_map = true,
		load_custom_map = true,
		enable_review = true,
		hide = true,
		spectate = true,
		start_round_poll = true,
		see_map_polls = true,
		set_map_time_review = true,
		change_roommod = true,
		see_hidden_staff = true,
	},
	trainee = {
		ban = true,
		kill = true,
		spectate = true,
		change_map = true,
		get_player_room = true,
		see_private_maps = true,
		use_tracker = true,
		see_hidden_staff = true,
		view_sanctions = true,
	},
	translator = {
		hide = true
	},
	hidden = {}
}
player_ranks = {}
perms = {}

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
			translator = {_count = 0},
			hidden = {_count = 0}
		}, {}, {}
		local player_perms, _player_ranks
		for player, rank in next, data.ranks do
			player_perms, _player_ranks = {}, {}
			for name, id in next, ranks_id do
				if band(rank, id) > 0 then
					_player_ranks[name] = true
					ranks[name][player] = true
					ranks[name]._count = ranks[name]._count + 1
					ranks[name][ ranks[name]._count ] = player
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
