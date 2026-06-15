do
local floor, ceil, random, tonumber = math.floor, math.ceil, math.random, tonumber
local os_time, table_remove = os.time, table.remove

local a_day = 24 * 60 * 60 * 1000
local a_week = 7 * a_day

Quests = {}

local static_reset_delta = os_time()

local function get_last_reset_delta()
	local ts = os_time() + static_reset_delta
	local delta = ts - WEEKLY_RESET_INIT
	local daily = WEEKLY_RESET_INIT + a_day * floor(delta / a_day)
	local weekly = WEEKLY_RESET_INIT + a_week * floor(delta / a_week)
	return daily, weekly
end

local function get_last_reset_actual()
	local ts = os_time()
	local delta = ts - WEEKLY_RESET_INIT
	local daily = WEEKLY_RESET_INIT + a_day * floor(delta / a_day)
	local weekly = WEEKLY_RESET_INIT + a_week * floor(delta / a_week)
	return daily, weekly
end

local get_last_reset = get_last_reset_actual

local function get_recent_reset(is_weekly)
	local daily, weekly = get_last_reset()

	if is_weekly then
		return weekly - a_week, weekly
	end

	return daily - a_day, daily
end

function Quests.get_next_reset()
	local daily, weekly = get_last_reset()
	return daily + a_day, weekly + a_week
end

local ALLOWED_POWERS = { 4, 6, 7, 8, 9, 10, 11, 12, 13 }

local function get_powers(map_count)
	local available = {}

  for _, id in ipairs(ALLOWED_POWERS) do
		if map_count >= powers[id].maps then
			available[1 + #available] = id
		end
	end

	return available
end

local function get_available(data, reset_time, min, max)
	local excluded = {}
	local ts

	for i = min, max do
		ts = data:quest_ts(i)

		-- not completed (includes skipped quest) or done during this reset period
		if ts == 0 or ts > reset_time then
			excluded[data:quest_id(i)] = true
		end
	end

	local power_ids = get_powers(data.c)

	if #power_ids == 0 then
		excluded[6] = true
	end

	local quest_ids = {}

	for i = 1, #Quests do
		if not excluded[i] then
			quest_ids[1 + #quest_ids] = i
		end
	end

	return quest_ids, power_ids
end

local function assign_quest(data, slot, available, power_ids, weekly)
	local randomIndex = random(#available)
	local randomQuest = available[randomIndex]
	local quest = Quests[randomQuest]
	local extra

	if quest.extra then
		extra = quest.extra(weekly, power_ids)
		data:quest_extra(slot, extra)
	end

	data:quest_id(slot, randomQuest)
	data:quest_ts(slot, 0)
	data:quest_target(slot, quest.target(weekly, extra))
	data:quest_progress(slot, 0)

	table_remove(available, randomIndex)
end

local function fill_quests(data, weekly)
	local daily_reset, weekly_reset = get_last_reset()
	local reset_time = weekly and weekly_reset or daily_reset

	local min = weekly and 5 or 1
	local max = weekly and 8 or 4

	local available, power_ids = get_available(data, reset_time, min, max)
	local ts, ret

	for i = min, max do
		ts = data:quest_ts(i)

		-- init pdata or completed before last reset
		if data:quest_id(i) == 0 or ts > 0 and ts < reset_time then
			assign_quest(data, i, available, power_ids, weekly)
			ret = true
		end
	end

	return ret
end

function Quests.skipped(data, index)
	local daily_reset, weekly_reset = get_last_reset()
	local reset_time = index > 4 and weekly_reset or daily_reset

	return data:quest_skipped(index) >= reset_time
end

function Quests.skip(data, index)
	if index < 1 or index > 8 then return end

	-- completed
	if data:quest_ts(index) > 0 then return end

	local weekly = index > 4
	local daily_reset, weekly_reset = get_last_reset()
	local reset_time = weekly and weekly_reset or daily_reset

	if data:quest_skipped(index) >= reset_time then return end

	local min = weekly and 5 or 1
	local max = weekly and 8 or 4

	local available, power_ids = get_available(data, reset_time, min, max)

	assign_quest(data, index, available, power_ids, weekly)
	data:quest_skipped(index, os_time())
	savePlayerData(player)

	return true
end

local function check_reset(player, data, index)
	if fill_quests(data, index > 4) then
		translatedChatMessage(
			"quest_reset",
			player,
			translatedMessage(
				index > 4 and "weekly_q" or "daily_q",
				player
			):lower()
		)
	end

	local prev_reset, last_reset = get_recent_reset(index > 4)
	local streak_ts = data:quest_streak_ts(index)
	local streak = data:quest_streak(index)

	if streak_ts > 0 and streak > 0 then
		if streak_ts > prev_reset then
			if streak > 1 and streak_ts <= last_reset then
				translatedChatMessage(
					index > 4 and "quest_weekly_streak" or "quest_daily_streak",
					player, streak
				)
			end
		else
			if streak > 1 then
				translatedChatMessage(
					index > 4 and "quest_weekly_streak_reset" or "quest_daily_streak_reset",
					player, data:quest_streak(index)
				)
			end

			data:quest_streak(index, 0)
			savePlayerData(player)
		end
	end
end

function Quests.trigger_load(player, data)
	check_reset(player, data, 1)
	check_reset(player, data, 5)
end

function Quests.trigger_map(player)
	local data = players_file[player]
	if not data then return end
	if #maps[1].list == 1 then return end -- list not loaded yet

	local difficulty, index

	for i=1, 8 do
		if data:quest_id(i) == 5 and data:quest_ts(i) == 0 then
			difficulty = i > 4 and 3 or 1
			index = 1 + ((data:quest_target(i) - 1) % maps[difficulty].count)

			if maps[difficulty].list[index] == tonumber(current_map) then
				return translatedChatMessage("quest_map", player, current_map)
			end
		end
	end
end

function Quests.trigger_power(player, power_id)
	local data = players_file[player]
	if not data then return end

	for i=1, 8 do
		-- quest not completed and has power quest for matching power
		if data:quest_ts(i) == 0 and data:quest_id(i) == 6 and data:quest_extra(i) == power_id then
			if Quests[6].progress_power(player, data, i) then
				savePlayerData(player)
			end
		end
	end
end

-- pdata is saved after this
function Quests.trigger_completion(player, data)
	local quest

	for i = 1, 8 do
		-- quest not completed
		if data:quest_ts(i) == 0 then
			quest = Quests[data:quest_id(i)]

			if quest.progress_completion then
				quest.progress_completion(player, data, i)
			end
		end
	end
end

local function removeCompletedQuestUI(player)
	if CompletedQuestsInterface.open[player] then
		CompletedQuestsInterface:remove(player)
	end
end

local function completeQuest(player, data, index)
	if not room.playerList[player] then return end

	-- already completed
	if data:quest_ts(index) > 0 then return end

	if QuestsInterface.open[player] then
		QuestsInterface:remove(player)
	end

	local quest = Quests[data:quest_id(index)]
	if not quest then return end

	local prize = quest.prize(player, data, index)
	if not prize then return end

	local now = os_time()
	local prev_reset, last_reset = get_recent_reset(index > 4)
	local streak_ts = data:quest_streak_ts(index)

	if streak_ts == 0 or streak_ts > prev_reset and streak_ts <= last_reset then
		data:quest_streak(index, 1, true)
		data:quest_streak_ts(index, now)
	end

	data:quest_completions(index, 1, true)
	data:quest_ts(index, now)
	data.coins = data.coins + prize

	if not CompletedQuestsInterface.open[player] then
		CompletedQuestsInterface:show(player, index > 4, prize) 
		addNewTimer(5000, removeCompletedQuestUI, player)
	end
end

local fieldMapping = {
	id = "quest_id",
	ts = "quest_ts",
	skip = "quest_skipped",
	progress = "quest_progress",
	target = "quest_target",
	extra = "quest_extra",
	streak = "quest_streak",
	streak_ts = "quest_streak_ts",
	completions = "quest_completions",
}
local triggerMapping = {
	load = "trigger_load",
	map = "trigger_map",
	power = "trigger_power",
	completion = "trigger_completion",
}

newCmd({ name = {"aquest", "aq"},
	rank = "admin",
	fn = function(player, args, cmd)
		if not args[1] then
			return sendChatFmt("!aquest setreset/raw/view/edit/trigger/skip", player)
		end

		local action = args[1]:lower()

		if action == "setreset" then
			local value = args[2]

			if value == "revert" then
				get_last_reset = get_last_reset_actual
				return
			end

			value = tonumber(value)

			if not value then
				return sendChatFmt("!aquest setreset [+ms/-ms]/revert", player)
			end

			get_last_reset = get_last_reset_delta
			static_reset_delta = value
			sendChatFmt("static_reset_delta = %s", player, tostring(value))
			chatlogCmd(cmd, player, args)

			return
		end

		local target = args[2]

		if not target then
			return sendChatFmt("<r>You must specify the target player.", player)
		end

		local data = players_file[target]

		if not in_room[target] or not data then
			return sendChatFmt("<r>%s is not here.", player, tostring(target))
		end

		if action == "raw" then
			sendChatFmt(
				"Raw quest data for %s: %s",
				player,
				target,
				table.concat(data.quests, ' ')
			)
			return
		elseif action == "view" then
			sendChatFmt(
				"Quest data for %s:\ndaily skip: %s %s\nweekly skip: %s %s\ncompletions: %s %s\nstreak ts: %s %s\nstreak: %s %s",
				player,
				target,
				data:quest_skipped(1), Quests.skipped(data, 1) and "skipped" or "available",
				data:quest_skipped(5), Quests.skipped(data, 5) and "skipped" or "available",
				data:quest_completions(1), data:quest_completions(5),
				data:quest_streak_ts(1), data:quest_streak_ts(5),
				data:quest_streak(1), data:quest_streak(5)
			)

			local mapIndex, mapList, mapCode, target, id

			for i = 1, 8 do
				id = data:quest_id(i)
				target = data:quest_target(i)

				if id == 5 then
					mapIndex = target
					mapList = maps[i > 4 and 3 or 1]
					mapCode = mapList.list[1 + ((mapIndex - 1) % mapList.count)]

					if mapCode then
						target = target .. " (@" .. mapCode .. ")"
					end
				end

				sendChatFmt(
					"[%s %s] id:%s ts:%s pg:%s tg:%s extra:%s",
					player,
					i > 4 and "weekly" or "daily",
					i > 4 and (i - 4) or i,

					id,
					data:quest_ts(i),
					data:quest_progress(i),
					target,
					data:quest_extra(i)
				)
			end
			return
		elseif action == "edit" then
			local index = tonumber(args[3])
			local field = args[4]
			local value = tonumber(args[5])
			local fn = data[fieldMapping[field]]

			if not index or index < 1 or index > 8 or floor(index) ~= index or not fn or not value then
				return sendChatFmt("!aquest edit %s [1-8] id/ts/skip/progress/target/extra/streak/streak_ts/completions [value]", player, target)
			end

			if field == "id" and (value < 1 or value > #Quests or floor(value) ~= value) then
				return sendChatFmt("Invalid id, must be an integer between 1-%s", player, 1, #Quests)
			end

			local old_value = fn(data, index)
			local new_value = fn(data, index, value)

			sendChatFmt("%s.quests[%s].%s: %s -> %s", player, target, index, field, tostring(old_value), tostring(new_value))
		elseif action == "trigger" then
			local trigger = args[3]
			local powerId = tonumber(args[4])
			local fn = Quests[triggerMapping[trigger]]

			if not fn then
				return sendChatFmt("!aquest trigger %s load/map/power/completion ([power id])", player, target)
			end

			if trigger == "power" and not powerId then
				return sendChatFmt("Invalid power id, must be an integer", player)
			end

			fn(target, trigger == "power" and powerId or data)
			sendChatFmt("Triggered %s for %s with parameter of %s", player, trigger, target, tostring(powerId))
		elseif action == "skip" then
			local index = tonumber(args[3])

			if not index or index < 1 or index > 8 or floor(index) ~= index then
				return sendChatFmt("!aquest skip %s [1-8]", player, target)
			end

			local yes = Quests.skip(data, index)

			sendChatFmt("Attempted to skip %s's quest-%s: %s", player, target, index, yes and "success" or "failed")
		end

		chatlogCmd(cmd, player, args)
	end
})

local function linear_progress(player, data, index)
	local target = data:quest_target(index)
	local new = 1 + data:quest_progress(index)

	data:quest_progress(index, new)

	if new >= target then
		completeQuest(player, data, index)
		return true
	end
end

Quests[1] = {
	description = function(player, data, index)
		return translatedMessage("quest_1", player, data:quest_progress(index), data:quest_target(index))
	end,

	target = function(weekly)
		return weekly and random(20, 50) or random(5, 10)
	end,

	prize = function(player, data, index)
		local coins = data:quest_target(index) * (index > 4 and 1.5 or 2)
		return ceil(coins / 5) * 5 -- per map
	end,

	progress_completion = linear_progress,
}

Quests[2] = {
	description = function(player, data, index)
		return translatedMessage("quest_2", player, data:quest_progress(index), data:quest_target(index))
	end,

	target = function(weekly)
		return weekly and random(100, 180) or random(30, 60)
	end,

	prize = function(player, data, index)
		local coins = data:quest_target(index) * (index > 4 and 0.2 or 0.3)
		return ceil(coins / 5) * 5 -- per cp
	end,

	progress_completion = function(player, data, index)
		local target = data:quest_target(index)
		local new = #levels - 1 + data:quest_progress(index)

		data:quest_progress(index, new)

		if new >= target then
			completeQuest(player, data, index)
			return true
		end
	end,
}

Quests[3] = {
	description = function(player, data, index)
		return translatedMessage("quest_3", player, data:quest_progress(index), data:quest_target(index))
	end,

	target = function(weekly)
		return weekly and random(25, 50) or random(5, 10)
	end,

	prize = function(player, data, index)
		local coins = data:quest_target(index) * (index > 4 and 6 or 9)
		return ceil(coins / 5) * 5 -- per map
	end,

	progress_completion = function(player, data, index)
		if first_player ~= player then return end

		local target = data:quest_target(index)
		local new = 1 + data:quest_progress(index)

		data:quest_progress(index, new)

		if new >= target then
			completeQuest(player, data, index)
			return true
		end
	end,
}

Quests[4] = {
	description = function(player, data, index)
		return translatedMessage("quest_4", player, data:quest_target(index))
	end,

	target = function(isWeekly)
		return isWeekly and 40 or 60
	end,

	prize = function(player, data, index)
		return index > 4 and 100 or 75
	end,

	progress_completion = function(player, data, index)
		local taken = (os_time() - (times.generated[player] or times.map_start)) / 1000
		local target = data:quest_target(index)

		if taken < target then
			completeQuest(player, data, index)
			return true
		end
	end,
}

Quests[5] = {
	description = function(player, data, index)
		local mapIndex = data:quest_target(index)
		local mapList = maps[index > 4 and 3 or 1]
		local mapCode = mapList.list[1 + ((mapIndex - 1) % mapList.count)] or "N/A"
		return translatedMessage("quest_5", player, mapCode)
	end,

	target = function()
		return random(1000)
	end,

	prize = function(player, data, index)
		return index > 4 and 200 or 100
	end,

	progress_completion = function(player, data, index)
		local mapIndex = data:quest_target(index)
		local mapList = maps[index > 4 and 3 or 1]
		local mapCode = mapList.list[1 + ((mapIndex - 1) % mapList.count)]

		if mapCode == tonumber(current_map) then
			completeQuest(player, data, index)
			return true
		end
	end,
}

Quests[6] = {
	description = function(player, data, index)
		local power = powers[data:quest_extra(index)]
		if not power then return "N/A" end

		local powerName = translatedMessage(power.name, player)
		return translatedMessage("quest_6", player, powerName, data:quest_progress(index), data:quest_target(index))
	end,

	target = function(weekly)
		return weekly and random(20, 30) or random(4, 10)
	end,

	prize = function(player, data, index)
		local coins = data:quest_target(index) * (index > 4 and 1 or 1.5)
		return ceil(coins / 5) * 5 -- per use
	end,

	extra = function(weekly, power_ids)
		return power_ids[random(#power_ids)]
	end,

	progress_power = linear_progress,
}

Quests[7] = {
	description = function(player, data, index)
		local colortag = difficulty_color[current_difficulty] or 'fc'
		return translatedMessage(
			"quest_7",
			player,
			data:quest_progress(index),
			data:quest_target(index),
			colortag,
			('★'):rep(data:quest_extra(index) or 1),
			colortag
		)
	end,

	target = function(weekly, difficulty)
		if difficulty == 1 then
			return weekly and random(30, 60) or random(8, 15)
		elseif difficulty == 3 then
			return weekly and random(10, 25) or random(3, 5)
		end
		return weekly and random(20, 50) or random(5, 10)
	end,

	prize = function(player, data, index)
		local diff = data:quest_extra(index)
		local target = data:quest_target(index)
		local mult = 1

		if diff == 2 then
			mult = index > 4 and 1.5 or 2
		elseif diff == 3 then
			mult = index > 4 and 3.5 or 5
		end

		local coins = target * mult
		return ceil(coins / 5) * 5 -- per map
	end,

	extra = function(weekly, power_ids)
		return weekly and random(1, 3) or random(1, 2)
	end,

	progress_completion = function(player, data, index)
		if current_difficulty ~= data:quest_extra(index) then return end

		local target = data:quest_target(index)
		local new = 1 + data:quest_progress(index)

		data:quest_progress(index, new)

		if new >= target then
			completeQuest(player, data, index)
			return true
		end
	end,
}

local feature_mapping = { 'acid', 'water', 'honey' }

Quests[8] = {
	description = function(player, data, index)
		local feature = data:quest_extra(index)
		return translatedMessage(
			"quest_8",
			player,
			data:quest_progress(index),
			data:quest_target(index),
			translatedMessage("quest_8_" .. feature, player)
		)
	end,

	target = function(weekly)
		return weekly and random(5, 25) or random(1, 5)
	end,

	prize = function(player, data, index)
		local coins = data:quest_target(index) * (index > 4 and 2 or 3)
		return ceil(coins / 5) * 5 -- per map
	end,

	extra = function()
		return random(1, 3)
	end,

	progress_completion = function(player, data, index)
		if not map_features[feature_mapping[data:quest_extra(index)]] then return end

		local target = data:quest_target(index)
		local new = 1 + data:quest_progress(index)

		data:quest_progress(index, new)

		if new >= target then
			completeQuest(player, data, index)
			return true
		end
	end,
}
end
