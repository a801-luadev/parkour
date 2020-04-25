import traceback
import discord
import asyncio
import aiohttp
import re

class Client(discord.Client):
	role_reaction_channel = 683847523558883446
	game_logs_channel = 681571711849594897
	started = False

	async def on_ready(self):
		channel = self.get_channel(self.role_reaction_channel)
		async for message in channel.history():
			for line in message.content.split("\n"):
				if " ~> " in line:
					emoji = line.split(" ")[0]
					await message.add_reaction(emoji)

		print("[DISCORD] Ready!", flush=True)
		if not self.started:
			self.started = True
			asyncio.ensure_future(self.restart(), loop=self.loop)

	async def restart(self):
		channel = self.get_channel(686932761222578201)
		await channel.send("Restarting in an hour.")
		await asyncio.sleep(3600.0)
		print("Restarting transformice bot", flush=True)

	async def on_transformice_logs(self, msg):
		if msg.startswith("**`[BANS]:`**") or msg.startswith("**`[KILL]:`**"):
			channel = 688464365581893700
		elif msg.startswith("**`[RANKS]:`**"):
			channel = 688464206315651128
		else:
			channel = self.game_logs_channel

		channel = self.get_channel(channel)
		await channel.send(msg)

	async def on_message(self, msg):
		if msg.channel.id == 700443631135359016:
			await msg.add_reaction("👎")
			await msg.add_reaction("👍")

		elif msg.channel.id == 686932761222578201 or msg.channel.id == 694270110172446781:
			args = msg.content.split(" ")
			cmd = args.pop(0).lower()

			if msg.author.id == 212634414021214209 or msg.author.id == 436703225140346881:
				if cmd == "!copyfile":
					if len(args) < 2 or (not args[0].isdigit()) or (not args[1].isdigit()):
						await msg.channel.send("Invalid syntax. Syntax: `!copyfile [original] [destination] (restart)`")

					await self.mapper.loadLua(f"""
						system.loadFile({args[0]})
						function eventFileLoaded(file, data)
							system.saveFile(data, {args[1]})
							print("Copied " .. #data .. " bytes.")
						end
					""")

					if len(args) > 2:
						await asyncio.sleep(3.0)
						self.mapper.dispatch("restart_request", "*#parkour0maps")
						await msg.channel.send("Restarting the room soon.")

				elif cmd == "!update":
					link = "https://raw.githubusercontent.com/a801-luadev/parkour/master/builds/latest.lua"

					if len(args) > 0:
						if args[0].startswith("http"):
							link = args.pop(0)

					update_msg = " ".join(args)

					await msg.channel.send("Uploading script from " + link + " - Message: `" + update_msg + "`")
					self.mapper.dispatch("update_ready", link, update_msg)

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

					self.mapper.dispatch("load_request", script)

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

					async with aiohttp.ClientSession() as session:
						async with session.get("https://raw.githubusercontent.com/a801-luadev/parkour/master/tech/json/init.lua") as resp:
							script = (await resp.read()) + b"\n\n" + script

					self.mapper.dispatch("load_request", script)

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

			if cmd == "!restart":
				if len(args) == 0:
					return await msg.channel.send("Invalid syntax.")

				room = " ".join(args)
				if re.match(r"^(?:(?:[a-z][a-z]|e2)-|\*)#parkour(?:$|\d.*)", room) is None:
					return await msg.channel.send("The given room is invalid. I can only restart #parkour rooms.")

				self.mapper.dispatch("restart_request", room)
				await msg.channel.send("Restarting the room soon.")

			elif cmd == "!join":
				if len(args) == 0:
					return await msg.channel.send("Invalid syntax.")

				room = " ".join(args)
				if re.match(r"^(?:(?:[a-z][a-z]|e2)-|\*)#parkour(?:$|\d.*)", room) is None:
					return await msg.channel.send("The given room is invalid. You can only join #parkour rooms.")

				self.mapper.dispatch("join_request", room)

	async def on_join_request_sent(self):
		channel = self.get_channel(694270110172446781)
		await channel.send("Room join requests have been sent.")

	async def on_join_request_activated(self, room, expire):
		channel = self.get_channel(694270110172446781)
		await channel.send(f"Room join request for room `{room}` activated. Disabling it in **{round(expire)}** seconds.")

	async def on_lua_log(self, msg):
		match = re.match(r"^<V>\[(.+?)\]<BL> (.+)$", msg, flags=re.DOTALL)
		if match is None:
			channel = self.get_channel(686933785933381680)
			return await channel.send("Wrong match: `" + msg + "`")

		room, msg = match.group(1, 2)
		if room == "*#parkour0maps":
			channel = 686932761222578201
		elif msg.startswith("Script terminated :"):
			channel = 688784734813421579
		else:
			channel = 686933785933381680

		channel = self.get_channel(channel)

		await channel.send("`[" + room + "]` `" + msg + "`")

	async def on_map_perm(self, msg):
		channel = self.get_channel(687804716364857401)
		await channel.send(msg)

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
