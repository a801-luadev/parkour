import traceback
import discord
import asyncio
import aiohttp
import json
import re
import os

class Client(discord.Client):
	role_reaction_channel = 683847523558883446
	game_logs_channel = 681571711849594897
	started = False
	busy = False
	api_status = None

	async def on_ready(self):
		channel = self.get_channel(self.role_reaction_channel)
		async for message in channel.history():
			for line in message.content.split("\n"):
				if " ~> " in line:
					emoji = line.split(" ")[0]
					await message.add_reaction(emoji)


		async with aiohttp.ClientSession() as session:
			async with session.get("https://raw.githubusercontent.com/a801-luadev/parkour/master/tech/json/init.lua") as resp:
				self.json_script = await resp.read()

		print("[DISCORD] Ready!", flush=True)
		if not self.started:
			self.started = True
			asyncio.ensure_future(self.restart(), loop=self.loop)

	async def restart(self):
		channel = self.get_channel(686932761222578201)
		await channel.send("Restarting in an hour.")
		await asyncio.sleep(3600.0)
		print("Restarting transformice bot", flush=True)

	async def check_maps(self, msg, maps, adding):
		changes = {}

		for code in maps:
			if not code.isdigit():
				await msg.channel.send("Invalid syntax.")
				return

		for code in maps:
			await asyncio.sleep(3.0)
			try:
				author, code, perm = await self.mapper.getMapInfo("@" + code, timeout=15.0)
			except: # timeout
				await msg.channel.send("The map @" + code + " cold not be loaded.")
				return
			if perm != 41 and perm != 22:
				await msg.channel.send("The map " + code + " can't be in P" + str(perm) + ".")
				return

			if adding:
				if perm == 41:
					await msg.channel.send("The map " + code + " is already P41.")
				elif perm == 22:
					await msg.channel.send("Changing the perm of " + code + " to P41.")
					if not await self.mapper.changeMapPerm(code, "41"):
						await msg.channel.send("Could not change the perm of " + code + ".")
						return
			else:
				if perm == 22:
					await msg.channel.send("The map " + code + " is already P22.")
				elif perm == 41:
					await msg.channel.send("Changing the perm of " + code + " to P22.")
					if not await self.mapper.changeMapPerm(code, "22"):
						await msg.channel.send("Could not change the perm of " + code + ".")
						return

			changes[code[1:]] = True

		return changes

	async def on_whois_request(self, player):
		channel = self.get_channel(707358868090519632)
		await channel.send(player)

	async def on_bots_room_crash(self):
		channel = self.get_channel(686932761222578201)
		await channel.send("*#parkour4bots has crashed. restarting it")
		while self.busy:
			await asyncio.sleep(5.0)
		self.busy = True
		self.mapper.dispatch("restart_request", "*#parkour4bots", channel)

	async def on_message(self, msg):
		if msg.author.id == 683839314526077066:
			return

		if msg.channel.id == 707358868090519632:
			self.mapper.dispatch("whois_response", msg.content.replace(" ", "\x00"))

			await msg.delete()

		elif msg.channel.id in (711955597100056628, 722189771631231029):
			if msg.content.startswith("!m "):
				content = msg.content[3:]
			elif msg.content.startswith(","):
				content = msg.content[1:]
			else:
				return

			content = "[{}] {}".format(msg.author.display_name, content)
			content = re.sub(r"<a?:([^:]+):\d+>", r":\1:", content)

			for mention_char, display_char, mention_list, name_attr in (
				("@", "@", msg.mentions, "display_name"),
				("@!", "@", msg.mentions, "display_name"),
				("@&", "@", msg.role_mentions, "name"),
				("#", "#", msg.channel_mentions, "name")
			):
				for obj in mention_list:
					content = content.replace(
						"<{}{}>".format(mention_char, obj.id),
						"{}{}".format(display_char, getattr(obj, name_attr))
					)

			if len(content) > 255:
				return await msg.channel.send("The message is too long.")
			self.mapper.dispatch("send_chat", "mod" if msg.channel.id == 711955597100056628 else "mapper", content)

		elif msg.channel.id == 703701422910472192:
			args = msg.content.split(" ")
			cmd = args.pop(0).lower()

			if msg.author.id == 212634414021214209:
				available_perms = (20, 21, 22, 32, 34, 41, 42)
			else:
				available_perms = (22, 41, 42)

			for perm in available_perms:
				if cmd == "!p{}".format(perm):
					if len(args) < 1:
						return await msg.channel.send("Invalid syntax.")

					if args[0][0] == "@":
						code = args[0][1:]
					else:
						code = args[0]

					if not code.isdigit():
						return await msg.channel.send("Invalid syntax.")

					try:
						author, code, map_perm = await self.mapper.getMapInfo("@" + code, timeout=15.0)
					except: # timeout
						return await msg.channel.send("Could not load the map.")

					if author is None:
						return await msg.channel.send("Could not load the map.")

					if map_perm not in available_perms:
						return await msg.channel.send("The map is in P{}. You do not have the permission to change it.".format(map_perm))
					elif map_perm == perm:
						return await msg.channel.send("The map was already P{}.".format(perm))

					if await self.mapper.changeMapPerm(code, perm):
						return await msg.channel.send("Successfully changed the perm of the map {} : P{} -> P{}".format(code, map_perm, perm))

					return await msg.channel.send("Could not change the perm of the map {}. (it is P{})".format(code, map_perm))

			if cmd == "!rot":
				if len(args) < 3:
					return await msg.channel.send("Invalid syntax.")

				if "high" != args[0] != "low":
					return await msg.channel.send("Invalid syntax.")

				if "add" != args[1] != "rem":
					return await msg.channel.send("Invalid syntax.")

				maps = []
				for code in args[2:]:
					if code[0] == "@":
						code = code[1:]

					if not code.isdigit():
						return await msg.channel.send("The argument `{}` is not a valid map code.".format(code))
					maps.append(code)

				if self.busy:
					return await msg.channel.send("The bot is busy right now.")
				self.busy = True

				for code in maps:
					self.mapper.dispatch("map_change", args[0], code, args[1] == "add")

				file = 1 if args[0] == "high" else 10
				await msg.channel.send("The action should be applied within a minute.")
				try:
					await self.mapper.wait_for("on_file_loaded", lambda f: f == file, timeout=65.0)
				except: # timeout!
					self.busy = False
					return await msg.channel.send("Could not modify the rotation. Try again later.")

				self.busy = False
				await msg.channel.send("Rotation modified.")

		elif msg.channel.id == 686932761222578201 or msg.channel.id == 694270110172446781:
			args = msg.content.split(" ")
			cmd = args.pop(0).lower()

			if cmd == "!restart":
				if len(args) == 0:
					return await msg.channel.send("Invalid syntax.")

				room = " ".join(args)
				if re.match(r"^(?:(?:[a-z][a-z]|e2)-|\*)#parkour(?:$|\d.*)", room) is None:
					return await msg.channel.send("The given room is invalid. I can only restart #parkour rooms.")

				if self.busy:
					return await msg.channel.send("The bot is busy right now.")
				self.busy = True

				self.mapper.dispatch("restart_request", room, msg.channel)
				await msg.channel.send("Restarting the room soon.")

			elif msg.author.id == 212634414021214209 or msg.author.id == 436703225140346881 or msg.author.id == 204230471834533889:
				if cmd in ("!loadninja", "!launchninja"):
					if len(args) == 0 or args[0].startswith("http"):
						if len(args) > 0:
							link = args.pop(0)
						else:
							link = "https://raw.githubusercontent.com/extremq/ninja/master/builds/latest.lua"

						async with aiohttp.ClientSession() as session:
							async with session.get(link) as resp:
								script = await resp.read()
					else:
						script = re.match(r"^(`{1,3})(?:lua\n)?((?:.|\n)+)\1$", " ".join(args))

						if script is None:
							return await msg.channel.send("Invalid syntax. Can't match your script.")

						script = script.group(2)

					if self.busy:
						return await msg.channel.send("The bot is busy right now.")
					self.busy = True

					await self.mapper.sendCommand("room* *#ninja0update")
					await asyncio.sleep(3.0)
					await self.mapper.loadLua(script)
					await asyncio.sleep(3.0)

					if cmd == "!launchninja":
						await self.mapper.sendCommand(os.getenv("LAUNCHNINJA_CMD"))
						await asyncio.sleep(3.0)

					await self.mapper.sendCommand("room* *#parkour4bots")
					await asyncio.sleep(3.0)

					self.busy = False

				if msg.author.id == 204230471834533889:
					return

				if cmd == "!copyfile":
					if len(args) < 2 or (not args[0].isdigit()) or (not args[1].isdigit()):
						await msg.channel.send("Invalid syntax. Syntax: `!copyfile [original] [destination] (restart)`")

					if self.busy:
						return await msg.channel.send("The bot is busy right now.")
					self.busy = True

					await self.mapper.loadLua(f"""
						system.loadFile({args[0]})
						function eventFileLoaded(file, data)
							system.saveFile(data, {args[1]})
							print("Copied " .. #data .. " bytes.")
						end
					""")

					if len(args) > 2:
						await asyncio.sleep(3.0)
						self.mapper.dispatch("restart_request", "*#parkour4bots", msg.channel)
						await msg.channel.send("Restarting the room soon.")

					await asyncio.sleep(3.0)
					self.busy = False

				elif cmd == "!cmd":
					await self.mapper.sendCommand(" ".join(args))
					await msg.channel.send("Done.")

				elif cmd == "!update":
					if len(args) < 1:
						return await msg.channel.send("Invalid syntax.")

					if "yes" != args[0] != "no":
						return await msg.channel.send("Invalid syntax.")

					self.mapper.dispatch("game_update", args[0] == "yes")
					await msg.channel.send("Update alert sent.")

				elif cmd == "!load":
					if len(args) == 0 or args[0].startswith("http"):
						if len(args) > 0:
							link = args.pop(0)
						else:
							link = "https://raw.githubusercontent.com/a801-luadev/parkour/master/builds/latest.lua"

						async with aiohttp.ClientSession() as session:
							async with session.get(link) as resp:
								script = await resp.read()
					else:
						script = re.match(r"^(`{1,3})(?:lua\n)?((?:.|\n)+)\1$", " ".join(args))

						if script is None:
							return await msg.channel.send("Invalid syntax. Can't match your script.")

						script = script.group(2)

					if self.busy:
						return await msg.channel.send("The bot is busy right now.")
					self.busy = True

					self.mapper.dispatch("load_request", script)

					await asyncio.sleep(3.0)
					self.busy = False

				elif cmd == "!loadjson":
					if len(args) == 0 or args[0].startswith("http"):
						if len(args) > 0:
							link = args.pop(0)
						else:
							link = "https://raw.githubusercontent.com/a801-luadev/parkour/master/builds/latest.lua"

						async with aiohttp.ClientSession() as session:
							async with session.get(link) as resp:
								script = await resp.read()
					else:
						script = re.match(r"^(`{1,3})(?:lua\n)?((?:.|\n)+)\1$", " ".join(args))

						if script is None:
							return await msg.channel.send("Invalid syntax. Can't match your script.")

						script = script.group(2).encode()

					script = self.json_script + b"\n\n" + script

					if self.busy:
						return await msg.channel.send("The bot is busy right now.")
					self.busy = True

					self.mapper.dispatch("load_request", script)

					await asyncio.sleep(3.0)
					self.busy = False

				elif cmd == "!exec":
					if len(args) == 0:
						return await msg.channel.send("Invalid syntax. Can't match your script.")

					elif args[0].startswith("http"):
						async with aiohttp.ClientSession() as session:
							async with session.get(args.pop(0)) as resp:
								script = await resp.read()
					else:
						script = re.match(r"^(`{1,3})(?:python\n)?((?:.|\n)+)\1$", " ".join(args))

						if script is None:
							return await msg.channel.send("Invalid syntax. Can't match your script.")

						script = script.group(2).encode()

					try:
						exec(b"async def evaluate(self, msg):\n\t" + (script.replace(b"\n", b"\n\t")))
					except:
						return await msg.channel.send("Syntax error: ```python\n" + traceback.format_exc() + "```")

					try:
						await locals()["evaluate"](self, msg)
					except:
						return await msg.channel.send("Runtime error: ```python\n" + traceback.format_exc() + "```")

					return await msg.channel.send("Script ran successfully.")

	async def on_join_request_sent(self):
		channel = self.get_channel(704130876426158242)
		await channel.send("Room join requests have been sent.")

	async def on_lua_log(self, msg):
		match = re.match(r"^<V>\[(.+?)\]<BL> (.*)$", msg, flags=re.DOTALL)
		if match is None:
			channel = self.get_channel(686933785933381680)
			return await channel.send("Wrong match: `" + msg + "`")

		room, msg = match.group(1, 2)
		module = re.search(r"#([a-z]+)", room).group(1)

		if room == "*#parkour4bots" or room == "*#ninja0update" or module not in ("parkour", "ninja"):
			channel = 686932761222578201
		elif msg.startswith("Script terminated :"):
			msg = msg + "s."
			channel = 688784734813421579 if module == "parkour" else 720066652653223946
		else:
			channel = 686933785933381680 if module == "parkour" else 720066615022190592

		channel = self.get_channel(channel)

		await channel.send("`[" + room + "]` `" + msg + "`")

	async def get_reaction_role(self, payload):
		if payload.channel_id != self.role_reaction_channel:
			return None, None

		guild = self.get_guild(payload.guild_id)
		member = await guild.fetch_member(payload.user_id)

		if member.bot:
			return None, None

		channel = guild.get_channel(payload.channel_id)
		message = await channel.fetch_message(payload.message_id)

		emoji = str(payload.emoji)

		for line in message.content.split("\n"):
			if line.startswith(emoji):
				role_id = int(line.split(" ")[2][3:-1])

				for role in member.roles:
					if role.id == role_id:
						return member, role
				else:
					return member, role_id

		return None, None

	async def on_raw_reaction_add(self, payload):
		member, role = await self.get_reaction_role(payload)

		if isinstance(role, int):
			await member.add_roles(discord.Object(role), atomic=True)

	async def on_raw_reaction_remove(self, payload):
		member, role = await self.get_reaction_role(payload)

		if isinstance(role, discord.Role):
			await member.remove_roles(role, atomic=True)
