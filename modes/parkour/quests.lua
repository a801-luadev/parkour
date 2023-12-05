local function getPlayerQuest(player, questID, isWeekly)
	if not players_file[player] or not players_file[player].quests then
		return false
	end

	local min = isWeekly and 5 or 1
	local max = isWeekly and 8 or 4

	local playerQuests = players_file[player].quests

	for i = min, max do
		if playerQuests[i] and playerQuests[i].id == questID then
			return playerQuests[i]
		end
	end
end

local function removeCompletedQuestUI(player)
	if CompletedQuestsInterface.open[player] then
		CompletedQuestsInterface:remove(player)
	end
end

local function completeQuest(player, questData, isWeekly, questID)
	if not questData then return end

	if QuestsInterface.open[player] then
		QuestsInterface:remove(player)
	end

	local file = players_file[player]
	local questPrize = quests[questID].prize(player, isWeekly)

	questData.ts = os.time()
	file.coins = file.coins + questPrize

	if not CompletedQuestsInterface.open[player] then
		CompletedQuestsInterface:show(player, isWeekly, questPrize) 
		addNewTimer(5000, removeCompletedQuestUI, player)
	end
end

quests = {
	{
		description = function(player, isWeekly)
			local questData = getPlayerQuest(player, 1, isWeekly)
			if not questData then return end

			return translatedMessage("quest_1", player, questData.pg, questData.tg)
	  	end,

		target = function(isWeekly)
			local questTarget = isWeekly and math.random(100, 250) or math.random(25, 50)
			questTarget = math.floor(questTarget / 5) * 5

            return tonumber(questTarget)
		end,

		prize = function(player, isWeekly)
			local questData = getPlayerQuest(player, 1, isWeekly)
			if not questData then return end

			local prize = questData.tg * 0.75
			return math.floor(prize / 5) * 5 -- per map
		end,

		updateProgress = function(player, questData, isWeekly)
			if questData and questData.ts then return end
			questData.pg = questData.pg + 1
			
			if questData.pg >= questData.tg then
				completeQuest(player, questData, isWeekly, 1)
			end

		end,
	},
	{
		description = function(player, isWeekly)
			local questData = getPlayerQuest(player, 2, isWeekly)
			if not questData then return end

			return translatedMessage("quest_2", player, questData.pg, questData.tg)
	  	end,

		target = function(isWeekly)
			local questTarget = isWeekly and math.random(500, 900) or math.random(150, 300)
			questTarget = math.floor(questTarget / 5) * 5

            return tonumber(questTarget)
		end,

		prize = function(player, isWeekly)
			local questData = getPlayerQuest(player, 2, isWeekly)
			if not questData then return end

			local prize = questData.tg * 0.1
			return math.floor(prize / 5 ) * 5 -- per cp
		end,

		updateProgress = function(player, questData, isWeekly)
			if questData and questData.ts then return end
			questData.pg = questData.pg + #levels - 1

			if questData.pg >= questData.tg then
				completeQuest(player, questData, isWeekly, 2)
			end
		end,
		
	},
	{
		description = function(player, isWeekly)
			local questData = getPlayerQuest(player, 3, isWeekly)
			if not questData then return end

			return translatedMessage("quest_3", player, questData.pg, questData.tg)
	  	end,

		target = function(isWeekly)
			local questTarget = isWeekly and math.random(25, 50) or math.random(5, 10)

            return tonumber(questTarget)
		end,

		prize = function(player, isWeekly)
			local questData = getPlayerQuest(player, 3, isWeekly)
			if not questData then return end

			local prize = questData.tg * 3
			return math.floor(prize / 5 ) * 5 -- per map
		end,

		updateProgress = function(player, questData, isWeekly)
			if questData and questData.ts then return end
			
			if first_player == player then
				questData.pg = questData.pg + 1 
			end

			if questData.pg >= questData.tg then
				completeQuest(player, questData, isWeekly, 3)
			end
		end,
	},
	{
		description = function(player, isWeekly)
			local questData = getPlayerQuest(player, 4, isWeekly)
			if not questData then return end

			return translatedMessage("quest_4", player, questData.tg)
	  	end,

		target = function(isWeekly)
			local questTarget = isWeekly and 40 or 60

            return tonumber(questTarget)
		end,

		prize = function(player, isWeekly)
			local questData = getPlayerQuest(player, 4, isWeekly)
			if not questData then return end

			if isWeekly then
				return 50
			else
				return 25
			end
		end,

		updateProgress = function(player, questData, isWeekly)
			if questData and questData.ts then return end
			local taken = (os.time() - (times.generated[player] or times.map_start)) / 1000
			if taken < questData.tg	then
				questData.pg = questData.tg

				if questData.pg >= questData.tg then
					completeQuest(player, questData, isWeekly, 4)
				end	
			end
		end,
	},
	{
		description = function(player, isWeekly)
			local questData = getPlayerQuest(player, 5, isWeekly)
			if not questData then return end

			local mapCode = maps.list_high[((questData.tg-1)%#maps.list_high) + 1 ] or "N/A"

			return translatedMessage("quest_5", player, mapCode)
	  	end,

		target = function(isWeekly)
			local mapIndex = math.random(1000)
			
			local questTarget = mapIndex
            return tonumber(questTarget)
		end,

		prize = function(player, isWeekly)
			local questData = getPlayerQuest(player, 5, isWeekly)
			if not questData then return end

			return 50
		end,
		
		updateProgress = function(player, questData, isWeekly)
			if questData and questData.ts then return end
			if maps.list_high[((questData.tg - 1)%#maps.list_high) + 1 ] == tonumber(current_map) then
				questData.pg = questData.tg

				if questData.pg >= questData.tg then
					completeQuest(player, questData, isWeekly, 5)
				end	
			end
		end,
	},
	{
		description = function(player, isWeekly)
			local questData = getPlayerQuest(player, 6, isWeekly)
			if not questData then return end
			local powerName = translatedMessage(powers[questData.pr].name, player)
			
			return translatedMessage("quest_6", player, powerName, questData.pg, questData.tg )
	  	end,

		target = function(isWeekly)
			local questTarget = isWeekly and math.random(100, 150) or math.random(20, 50)
			questTarget = math.floor(questTarget / 5) * 5

            return tonumber(questTarget)
		end,

		prize = function(player, isWeekly)
			local questData = getPlayerQuest(player, 6, isWeekly)
			if not questData then return end

			local prize = questData.tg * 0.5
			return math.floor(prize / 5) * 5 -- per use
		end,

		updateProgress = function(player, questData, isWeekly)
			if questData and questData.ts then return end
			
			questData.pg = questData.pg + 1

			if questData.pg >= questData.tg then
				completeQuest(player, questData, isWeekly, 6)

				if isWeekly then
					power_quest[player].w = nil
					power_quest[player].wi = nil
				else
					power_quest[player].d = nil
					power_quest[player].di = nil
				end
			end
		end,
	}
}

local function getPowerList(data)
	if not data then return end
	local availablePowers = {4,6,7,8,9,10,11,12,13}
	local playerPowers = {}

	for i = 1, #availablePowers do
		if data.c >= powers[availablePowers[i]].maps then
			table.insert(playerPowers, availablePowers[i])
		end
	end

	return playerPowers
end

function fillQuests(data, questList, isWeekly, skipQuest)
	local reset_times = getQuestsResetTime()
	local reset_time = isWeekly and reset_times[2] or reset_times[1]

	local min = isWeekly and 5 or 1
	local max = isWeekly and 8 or 4

	local availableQuests = {}
	for i = 1, #quests do
		availableQuests[i] = i
	end

	for i = min, max do
		if not questList[i] then break end
		if not questList[i].ts or (questList[i].ts > reset_time) or (skipQuest and questList[i].skp and questList[i].skp == 0) then
			availableQuests[questList[i].id] = -1
		end
	end

	local listOfPowers = getPowerList(data)

	if #listOfPowers < 1 then
		availableQuests[6] = -1
	end

	for i = #quests, 1, -1 do
		if availableQuests[i] == -1 then
			table.remove(availableQuests, i)
		end
	end

	for i = min, max do
		if (not skipQuest and questList[i] and questList[i].skp and questList[i].skp ~= 0 and questList[i].skp < reset_time) then
			if questList[i].skp then
				questList[i].skp = nil 
			end
		end

		if not questList[i] or (not skipQuest and (questList[i].ts and questList[i].ts < reset_time)) or (skipQuest and questList[i].skp and questList[i].skp == 0) then

			local randomIndex = math.random(#availableQuests)
			local randomQuest = availableQuests[randomIndex]

			if randomQuest == 6 then
				local randomIdx = math.random(#listOfPowers)
				local randomPower = listOfPowers[randomIdx]

				questList[i] = {
					id = randomQuest,
					tg = quests[randomQuest].target(isWeekly),
					pg = 0,
					pr = randomPower,
				}
			else
				questList[i] = {
					id = randomQuest,
					tg = quests[randomQuest].target(isWeekly),
					pg = 0,
				}
			end

			table.remove(availableQuests, randomIndex)
		end
	end
	return questList
end