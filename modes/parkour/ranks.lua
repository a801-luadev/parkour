local band = (bit or bit32).band
local bxor = (bit or bit32).bxor

local ranks = {
	admin = {_count = 0},
	manager = {_count = 0},
	mod = {_count = 0},
	mapper = {_count = 0}
}
local ranks_id = {
	admin = 2 ^ 0,
	manager = 2 ^ 1,
	mod = 2 ^ 2,
	mapper = 2 ^ 3
}
local ranks_permissions = {
	admin = {
		show_update = true
	},
	manager = {
		set_player_rank = true,
		perm_map = true
	},
	mod = {
		ban = true,
		unban = true,
		delete_comments = true
	},
	mapper = {
		vote_map = true
	}
}
local perms = {}
local saving_ranks = false
local ranks_update
local updater

for rank, perms in next, ranks_permissions do
	if rank ~= "admin" then
		for perm_name, allowed in next, perms do
			ranks_permissions.admin[perm_name] = allowed
		end
	end
end

onEvent("GameDataLoaded", function(data)
	if saving_ranks then
		if not data.ranks then
			data.ranks = {}
		end

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

			-- TODO: Send a webhook

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

	if data.ranks then
		ranks, perms = {
			admin = {_count = 0},
			manager = {_count = 0},
			mod = {_count = 0},
			mapper = {_count = 0}
		}, {}
		local player_perms
		for player, rank in next, data.ranks do
			player_perms = {}
			for name, id in next, ranks_id do
				if band(rank, id) > 0 then
					ranks[name][player] = true
					ranks[name]._count = ranks[name]._count + 1
					for perm, enabled in next, ranks_permissions[name] do
						player_perms[perm] = enabled
					end
				end
			end
			perms[player] = player_perms
		end
	end
end)