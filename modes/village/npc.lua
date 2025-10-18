local parkour_npc
local npc_actions = {}

local function split(str)
  local arr, len = {}, 0
  for val in string.gmatch(str, '[^;]+') do
    len = len + 1
    arr[len] = val
  end
  return arr, len
end

onEvent("NewPlayer", function(player, init)
  if init then return end
  if not parkour_npc then return end

  for name, npc in next, parkour_npc do
    if npc.active then
      tfm.exec.addNPC(name, npc, player)
    end
  end
end)

onEvent("GameDataLoaded", function(data)
	if data.ranks then -- init file loaded
    if parkour_npc then return end
    scheduleFile("npc")
    return
	end

	if data.npc then
		parkour_npc = data.npc

    -- changes 4 times a day (6 hour intervals)
    local now = os.time()
    local counter = math.floor(now / (1000 * 60 * 60 * 6))
    local day, month, year = os.date("%d"), os.date("%m"), os.date("%Y")
    local def, start_ts, end_ts

    for name, npc in next, parkour_npc do
      if npc.active == 0 then
        npc.active = false
      elseif npc.active == 1 then
        npc.active = true
      elseif npc.active > 200000000 then
        npc.active = now < npc.active
      elseif npc.active > 100000000 then
        ms, ds, me, de = tostring(npc.active):match('1(%d%d)(%d%d)(%d%d)(%d%d)')
        start_ts = os.time({ year=year, month=ms, day=ds })
        end_ts = os.time({ year=year, month=me, day=de })
        npc.active = now > start_ts and now < end_ts
      else
        npc.active = (counter % npc.active) == 0
      end

      if npc.active then
        def = split(npc.definition)
        npc.name = name
        npc.param = split(npc.param)
        npc.x = tonumber(def[1])
        npc.y = tonumber(def[2])
        npc.title = tonumber(def[3])
        npc.female = def[4] == "1"
        npc.lookAtPlayer = true
        npc.interactive = true
        tfm.exec.addNPC(name, npc)
      end
    end
	end
end)

onEvent("TalkToNPC", function(player, name)
  if not parkour_npc then return end
  local npc = parkour_npc[name]
  if not npc or not npc.active then return end
  local action = npc_actions[npc.action]
  if not action then return end
  action(player, npc)
end)
