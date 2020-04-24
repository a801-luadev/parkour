local band = (bit or bit32).band
local bxor = (bit or bit32).bxor

local ranks = {
	admin = {_count = 0},
	manager = {_count = 0},
	mod = {_count = 0},
	mapper = {_count = 0},
	trainee = {_count = 0}
}
local ranks_id = {
	admin = 2 ^ 0,
	manager = 2 ^ 1,
	mod = 2 ^ 2,
	mapper = 2 ^ 3,
	trainee = 2 ^ 4
}
local ranks_permissions = {
	admin = {
		show_update = true,
		announce = true
	},
	manager = {
		set_player_rank = true,
		perm_map = true
	},
	mod = {
		ban = true,
		unban = true,
		delete_comments = true,
		spectate = true,
		get_player_room = true,
		change_map = true,
		kill = true,
		overkill = true
	},
	mapper = {
		vote_map = true,
		change_map = true,
		enable_review = true
	},
	trainee = {
		kill = true
	}
}
local player_ranks = {}
local perms = {}
local saving_ranks = false
local ranks_update
local updater
local ranks_order = {"admin", "manager", "mod", "mapper", "trainee"}

for rank, perms in next, ranks_permissions do
	if rank ~= "admin" then
		for perm_name, allowed in next, perms do
			ranks_permissions.admin[perm_name] = allowed
		end
	end
end

onEvent("GameDataLoaded", function(data)
	if data.ranks then
		if saving_ranks then
			local added, removed, not_changed
			for player, rank in next, ranks_update do
				if data.ranks[player] then
					not_changed = band(data.ranks[player], rank)
					removed = bxor(not_changed, data.ranks[player])
					added = bxor(not_changed, rank)
				else
					removed = 0
					added = rank
				end

				if added > 0 then
					local new
					for rank, id in next, ranks_id do
						if band(id, added) > 0 then
							if new then
								new = new .. "*, *parkour-" .. rank
							else
								new = "parkour-" .. rank
							end
						end
					end

					webhooks._count = webhooks._count + 1
					webhooks[webhooks._count] = "**`[RANKS]:`** **" .. player .. "** is now a **" .. new .. "**."
				end
				if removed > 0 then
					local old
					for rank, id in next, ranks_id do
						if band(id, removed) > 0 then
							if old then
								old = old .. "*, *parkour-" .. rank
							else
								old = "parkour-" .. rank
							end
						end
					end

					webhooks._count = webhooks._count + 1
					webhooks[webhooks._count] = "**`[RANKS]:`** **" .. player .. "** is no longer a **" .. old .. "**."
				end

				if rank == 0 then
					data.ranks[player] = nil
				else
					data.ranks[player] = rank
				end
			end

			translatedChatMessage("data_saved", updater)
			ranks_update = nil
			updater = nil
			saving_ranks = false
		end

		ranks, perms, player_ranks = {
			admin = {_count = 0},
			manager = {_count = 0},
			mod = {_count = 0},
			mapper = {_count = 0},
			trainee = {_count = 0}
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
