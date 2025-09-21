newCmd({ name = "event",
	rank = "admin",
	fn = function(player, args)
    if args._len == 0 then
      local names = {}
      for name in next, activeEvents do
        names[#names + 1] = name
      end
      sendChatFmt('Active events: <j>%s', player, table.concat(names, ' '))
      return
    end

    local name = args[1]
    local evt = activeEvents[name]

    if args._len == 1 then
      if evt then
        local rel = '-'
        if evt.timestamp then
          rel = math.ceil((evt.timestamp - os.time()) / 1000) / 60
          rel = ' (in ' .. rel .. ' minutes)'
        end
        sendChatFmt(
          '<j>rounds: <n>%s\n<j>timestamp: <n>%s%s', player,
          tostring(evt.rounds), tostring(evt.timestamp), rel
        )
        return
      end

      local file = players_file[name]
      if not file or not file.ec then
        return sendChatFmt('<r>Player not found', player)
      end
      return sendChatFmt('%s event coins: <n>%s', player, name,  table.concat(file.ec, ' '))
    end

    if not evt then
      return sendChatFmt('<r>Invalid event name', player)
    end

    if not evt.debug then
      return sendChatFmt('<r>Event has no debug function', player)
    end

    evt.debug(player, args[0], args._len, args)
  end
})

newCmd({ name = "snow",
	fn = function()
		tfm.exec.snow(0, 10)
	end })
