local ranks, perms
local newCmd, execCmd, logCmd, chatlogCmd

do
  local gmatch, lower = string.gmatch, string.lower
  local commands = {}

  logCmd = function(cmd, player, args)
    if args.logged then return end
    args.logged = true
    sendPacket("common", 7, room.shortName .. "\000" .. player .. "\000" .. args[-1])
  end

  chatlogCmd = function(cmd, player, args, extraTbl)
    if args.chatlogged then return end
    args.chatlogged = true

    local msg = "<BL>Ξ [" .. player .. "]<N2> !" .. args[-1]
    for name in next, room.playerList do
      if ranks.admin[name] or ranks.mod[name] or extraTbl and extraTbl[name] then
        tfm.exec.chatMessage(msg, name)
      end
    end
  end

  newCmd = function(cmd)
    assert(type(cmd.name) == "string" or type(cmd.name) == "table", "Command name must be a string or a table")
    assert(type(cmd.fn) == "function", "Command function must be a function")
    assert(type(cmd.min_args or 0) == "number", "Command min_args must be a number")
    assert(not cmd.perm or type(cmd.perm) == "string", "Command perm must be a string")
    assert(not cmd.rank or type(cmd.rank) == "string", "Command rank must be a string")
    assert(not cmd.log or type(cmd.log) == "boolean", "Command log must be a boolean")
    assert(not cmd.chatlog or type(cmd.chatlog) == "boolean", "Command chatlog must be a boolean")

    cmd.min_args = cmd.min_args or 0

    local names, name = cmd.name
    names = type(names) == "table" and names or { names }
    cmd.name = names

    for i=1, #names do
      name = names[i]
      assert(type(name) == "string", "Each command name must be a string")

      name = lower(name)
      names[i] = name

      assert(commands[name] == nil, "Command '" .. name .. "' is already registered")
      commands[name] = cmd
    end
  end

  execCmd = function(player, args)
    local cmd = commands[args[0]]
    if not cmd then return end
    if not ranks.admin[player] and not ranks.bot[player] then
      if cmd.perm and not (perms[player] and perms[player][cmd.perm]) then return end
      if cmd.rank and not ranks[cmd.rank][player] then return end
    end

    if args._len < cmd.min_args then
      return translatedChatMessage("invalid_syntax", player)
    end

    cmd.fn(player, args, cmd)

    if cmd.chatlog then
      chatlogCmd(cmd, player, args)
    end

    if cmd.log then
      logCmd(cmd, player, args)
    end
  end

  onEvent("ChatCommand", function(player, msg)
    local args, argc = { [-1] = msg }, -1
    for arg in gmatch(msg, "%S+") do
      argc = argc + 1
      args[argc] = arg
    end

    args[0] = lower(args[0])
    args._len = argc
    execCmd(player, args)
  end)

  system.disableChatCommandDisplay(nil)
end
