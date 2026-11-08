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

do
local ranks_permissions = {
	admin = {
		set_name_color = true,
		give_command = true,
		view_creators = true,
	}, -- will get every permission
	bot = {
	}, -- will get every permission
	manager = {
		force_stats = true,
		set_room_limit = true,
		set_map_time = true,
		hide = true,
		handle_map_polls = true,
		see_map_polls = true,
		see_hidden_staff = true,
		manage_maps = true,
	},
	mod = {
		view_creators = true,
		ping = true,
		ban = true,
		unban = true,
		spectate = true,
		set_spectate = true,
		get_player_room = true,
		load_custom_map = true,
		kill = true,
		see_private_maps = true,
		use_tracker = true,
		hide = true,
		see_hidden_staff = true,
		view_sanctions = true,
		skip_map = true,
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
		see_hidden_mapper = true,
		set_room_limit_review = true,
	},
	trainee = {
		ping = true,
		ban = true,
		kill = true,
		spectate = true,
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

-- !setrank changes waiting for the init file: name -> rank id, or false to remove
local rank_changes = {}

newCmd({ name = "setrank",
	rank = "admin",
	min_args = 2,
	fn = function(player, args)
	local targetPlayer = capitalize(args[1])
	local newRanks = {}
	local ID = 0

	if not string.find(targetPlayer, "#", 1, true) then
		targetPlayer = targetPlayer .. "#0000"
	end

	if args[2] ~= "none" then
		for i = 2, #args do
			if ranks_id[args[i]] then
				ID = ID + ranks_id[args[i]]
				newRanks[args[i]] = true
			else
				return tfm.exec.chatMessage("<v>[#] <r>Invalid rank: " .. args[i], player)
			end
		end
	end

	if ID == 0 then
		player_ranks[targetPlayer] = nil
		rank_changes[targetPlayer] = false
		tfm.exec.chatMessage("<v>[#] <r>All ranks removed from " .. targetPlayer, player)
	else
		player_ranks[targetPlayer] = newRanks
		rank_changes[targetPlayer] = ID
		tfm.exec.chatMessage("<v>[#] <r>Ranks has been set.", player)
	end

	logCmd(cmd, player, args)
end })

onEvent("GameDataLoaded", function(data, fileid)
	local save = maps.init_changed -- maps.lua's listener runs before this one
	maps.init_changed = nil

	-- applied before the rebuild, so the ranks in memory have them too
	if data.ranks and next(rank_changes) then
		for name, id in next, rank_changes do
			data.ranks[name] = id or nil
		end
		rank_changes = {}
		save = true
	end

	if save then
		eventSavingFile(fileid, data)
	end

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
				if bit32.band(rank, id) > 0 then
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
end