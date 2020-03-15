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
		if msg.startswith("**`[CODE]:`**"):
			channel = self.game_logs_channel
		elif msg.startswith("**`[BANS]:`**"):
			channel = 688464365581893700
		elif msg.startswith("**`[RANKS]:`**"):
			channel = 688464206315651128

		channel = self.get_channel(channel)
		await channel.send(msg)

	async def on_message(self, msg):
		if msg.channel.id == 686932761222578201:
			args = msg.content.split(" ")
			cmd = args.pop(0).lower()

			if msg.author.id == 212634414021214209:
				if cmd == "!update":
					link = "https://raw.githubusercontent.com/a801-luadev/parkour/master/builds/latest.lua"

					if len(args) > 0:
						if args[0].startswith("http"):
							link = args.pop(0)

					update_msg = " ".join(args)

					await msg.channel.send("Uploading script from " + link + " - Message: `" + update_msg + "`")
					self.mapper.dispatch("update_ready", link, update_msg)

				elif cmd == "!load":
					if len(args) == 0:
						return await msg.channel.send("Invalid syntax.")

					if args[0].startswith("http"):
						async with aiohttp.ClientSession() as session:
							async with session.get(args.pop(0)) as resp:
								script = await resp.read()
					else:
						script = re.match(r"^(`{1,3})(?:lua\n)?((?:.|\n)+)\1$", " ".join(args))

						if script is None:
							return await msg.channel.send("Invalid syntax. Can't match your script.")

						script = script.group(2)

					self.mapper.dispatch("load_request", script)

			elif cmd == "!restart":
				return # TO-DO

				if len(args) == 0:
					return await msg.channel.send("Invalid syntax.")

				room = " ".join(args)
				if re.match(r"^(?:(?:[a-z][a-z]|e2)-|\*)#parkour(?:$|\d.*)", room) is None:
					return await msg.channel.send("The given room is invalid. You can only restart #parkour rooms.")

				self.mapper.dispatch("restart_request", room)
				await msg.channel.send("Restarting the room soon.")

	async def on_lua_log(self, msg):
		match = re.match(r"^<V>\[(.+?)\]<BL> (.+)$", msg)
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

		await channel.send("[`" + room + "`] `" + msg + "`")

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
