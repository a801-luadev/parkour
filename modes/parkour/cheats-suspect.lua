local room = tfm.get.room

local players_file
local generated_at
local map_start
local last_level
local players_level

--[[
	SUSPECT TYPES:

-win
-follow
-vpn
-farm
-time
]]

local checkSuspects, addSuspect
if room.name == "*#parkour0maps" or is_tribe then
	function checkSuspects(player) end
	function addSuspect(player, s_type) end

else
	function checkSuspects(player)
		if not players_file[player] then return end
		local suspects = players_file[player].parkour.suspect
	end

	function addSuspect(player, s_type)
		if not players_file[player] then return end
		local suspects = players_file[player].parkour.suspect

		suspects[s_type] = suspects[s_type] + 1
	end

	onEvent("PlayerWon", function(player)
		local taken = (os.time() - (generated_at[player] or map_start)) / 1000

		if taken <= 60 then
			addSuspect(player, "time")
		end

		if players_level[player] ~= last_level then
			addSuspect(player, "win")
		end
	end)
end