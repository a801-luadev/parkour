import aiotfm
from proxy_connector import Connection
import random
import os
import time
import sys
import traceback
import asyncio
import re
import zlib
import aiohttp
import json


class env:
	proxy_token = os.getenv("PROXY_TOKEN")
	proxy_ip = os.getenv("PROXY_IP")
	proxy_port = os.getenv("PROXY_PORT")

	password = os.getenv("TOCU_PASSWORD")

	get_code = os.getenv("GET_CODE_CMD")
	join_room = os.getenv("JOIN_ROOM_CMD")
	set_limit = os.getenv("SET_LIMIT_CMD")
	update = os.getenv("UPDATE_CMD")

	records_webhook = os.getenv("RECORDS_WEBHOOK")

	private_channel = 686932761222578201
	lua_logs = 686933785933381680
	lua_unloads = 688784734813421579


class Commands:
	def add_command(self, name, command):
		setattr(self, name, command.format)


commands = Commands()
commands.add_command("get_code", env.get_code)
commands.add_command("join_room", env.join_room)
commands.add_command("set_limit", env.set_limit)
commands.add_command("update", env.update)

SEND_ROOM = (2 << 8) + 255
HEARTBEAT = (6 << 8) + 255
CHANGE_MAP = (7 << 8) + 255
FILE_LOADED = (8 << 8) + 255
LOAD_MAP = (11 << 8) + 255
RUNTIME = (20 << 8) + 255


class Proxy(Connection):
	def __init__(self, client, *args, **kwargs):
		self.client = client
		super().__init__(*args, **kwargs)

	async def connection_lost(self):
		await self.client.restart()

	async def received_proxy(self, client, packet):
		loop = self.client.loop

		if client == "records":
			return

		if packet["type"] == "runtime":
			loop.create_task(self.client.check_runtime(packet["channel"]))

		elif packet["type"] == "busy":
			# Shares the busy state between all the bots that need it
			self.client.busy = packet["state"]

		elif packet["type"] == "game_update":
			# Updates the module
			if packet["now"]:
				loop.create_task(self.client.send_update())
			else:
				self.client.dispatch("game_update", packet["load"])

		elif packet["type"] == "message":
			# If a client tries to send a message to a channel which is an int and is
			# less or equal to 10, it's a staff chat message and this bot should handle it
			if isinstance(packet["channel"], int) and packet["channel"] <= 10:
				loop.create_task(self.client.send_chat_msg(packet["channel"], packet["msg"]))

		elif packet["type"] == "perm":
			# Perms a specific map
			loop.create_task(self.client.request_map_perm(packet["map"], packet["perm"], packet["channel"]))

		elif packet["type"] == "map_info":
			# Gives information about a map
			loop.create_task(self.client.request_map_info(packet["map"]))

		elif packet["type"] == "restart":
			# Restarts a room
			self.client.dispatch("restart_request", packet["room"], packet["channel"])

		elif packet["type"] == "lua":
			# Loads a lua script
			loop.create_task(self.client.load_lua_script(packet))

		elif packet["type"] == "exec":
			# Executes arbitrary code in this bot
			loop.create_task(self.client.load_script(packet))

		elif packet["type"] == "command":
			# Executes a command
			loop.create_task(self.client.sendCommand(packet["command"]))

		elif packet["type"] == "rot_change":
			# Modifies game rotation
			loop.create_task(
				self.client.request_rot_change(
					packet["maps"],
					packet["rotation"] == "high", packet["action"] == "add",
					packet["channel"]
				)
			)


class Client(aiotfm.Client):
	busy = False
	bots_room = "*#parkour4bots"
	module_code = None
	proxy = None
	received_reboot = False
	lua_death = None
	next_mute_check = time.time() + 30
	mute_confirmed = None
	next_bot_restart = time.time() + 60 # wait 1 minute before starting again

	async def sendHandshake(self):
		"""|coro|
		Sends the handshake packet so the server recognizes this socket as a player.
		"""
		packet = aiotfm.Packet.new(28, 1)
		if self.bot_role:
			packet.write16(666).write16(8)
		else:
			packet.write16(self.keys.version).write16(8)
			packet.writeString('en').writeString(self.keys.connection)

		packet.writeString('Desktop').writeString('-').write32(0x1fbd).writeString('')
		packet.writeString('74696720697320676f6e6e61206b696c6c206d7920626f742e20736f20736164')
		packet.writeString(
			"A=t&SA=t&SV=t&EV=t&MP3=t&AE=t&VE=t&ACC=t&PR=t&SP=f&SB=f&DEB=f&V=LNX 29,0,0,140&M=Adobe"
			" Linux&R=1920x1080&COL=color&AR=1.0&OS=Linux&ARCH=x86&L=en&IME=t&PR32=t&PR64=t&LS=en-U"
			"S&PT=Desktop&AVD=f&LFD=f&WD=f&TLS=t&ML=5.1&DP=72")
		packet.write32(0).write32(0x6257).writeString('')

		await self.main.send(packet)

	async def start(self, *args, **kwargs):
		try:
			await super().start(*args, **kwargs)
		except Exception:
			traceback.print_exc()
		finally:
			await self.restart()

	async def on_login_ready(self, *a):
		print("Connected")

		self.proxy = Proxy(self, env.proxy_token, "tocubot")
		try:
			await self.proxy.connect(env.proxy_ip, env.proxy_port)
		except Exception:
			await self.restart()

		await self.login("Tocutoeltuco#5522", env.password, encrypted=False, room=self.bots_room)

	async def on_logged(self, *a):
		print("Logged!")

	async def check_runtime(self, channel):
		if not await self.set_busy(True, channel):
			return

		await self.send_callback(RUNTIME, "")
		try:
			id, text = await self.wait_for("on_lua_textarea", lambda id, text: id == RUNTIME, timeout=10.0)
		except Exception:
			await self.send_channel(channel, "request timed out")
			return await self.set_busy(False)

		current, total, cycles = map(int, text.split("\x00"))
		await self.send_channel(
			channel,
			"Runtime usage: `{}ms` current, `{}ms` total, `{}ms` average (`{}` cycles)"
			.format(current, total, total / max(1, cycles), cycles)
		)

		await self.set_busy(False)

	async def load_lua_script(self, packet):
		for field in ("json", "link"):
			if field in packet:
				async with aiohttp.ClientSession() as session:
					async with session.get(packet[field]) as resp:
						packet[field] = (await resp.read()).decode()

		if "link" in packet:
			script = packet["link"]
		else:
			script = packet["script"]

		if "json" in packet:
			script = packet["json"] + "\n" + script

		await self.loadLua(script)

	async def load_script(self, packet):
		if "link" in packet:
			async with aiohttp.ClientSession() as session:
				async with session.get(packet["link"]) as resp:
					script = (await resp.read()).decode()

		else:
			script = packet["script"]
		channel = packet["channel"]

		try:
			exec("async def evaluate(self):\n\t" + (script.replace("\n", "\n\t")))
		except Exception:
			return await self.send_channel(channel, "Syntax error: ```python\n" + traceback.format_exc() + "```")

		try:
			await locals()["evaluate"](self)
		except Exception:
			return await self.send_channel(
				channel, "Runtime error: ```python\n" + traceback.format_exc() + "```"
			)

		return await self.send_channel(channel, "Script ran successfully.")

	async def restart(self):
		# Restarts the process.
		required_time = self.next_bot_restart - time.time()
		if required_time > 0:
			await asyncio.sleep(required_time)

		os.execl(sys.executable, sys.executable, *sys.argv)

	async def on_connection_error(self, conn, exc):
		if conn.name == "main":
			# If the main connection with tfm is lost, we need to restart
			await self.restart()

		elif conn.name == "bulle":
			# If the connection to the room is lost, we need to join another room
			# and come back.
			await self.sendCommand(commands.join_room("en-1"))
			await asyncio.sleep(3.0)
			await self.sendCommand(commands.join_room("int-" + self.bots_room))

	async def handle_packet(self, conn, packet):
		CCC = packet.readCode()

		if CCC == (29, 20):
			self.dispatch(
				"lua_textarea",
				packet.read32(),
				re.sub(r"(ht)<(tp)", r"\1\2", packet.readUTF(), flags=re.I)
			)

		elif CCC == (28, 5): # Translated message
			packet.read16()
			if packet.readUTF() == "$CarteIntrouvable":
				# The map has not been loaded in the server or doesn't exist
				self.dispatch("map_info", None, None, None)

		elif CCC == (6, 20): # Server message
			packet.readBool()
			data = packet.readUTF()
			match = re.search(
				r"(\+?[A-Za-z][A-Za-z0-9_]{2,20}(?:#\d{4})?) - (@\d+) - \d+ - \d+% - P(\d+)", data
			)

			if match is not None:
				# Map information
				self.dispatch("map_info", *match.group(1, 2), int(match.group(3)))

		elif CCC == (28, 46):
			packet.readBool()
			packet.readBool()
			packet.readBool()

			self.dispatch("ui_log", bytes(packet.readBytes(packet.read24())))

		elif CCC == (6, 10):
			self.dispatch("chat_msg", packet.read8(), packet.readUTF(), packet.readUTF())

		elif CCC == (28, 88):
			self.dispatch("server_reboot", packet.read32())

		elif CCC == (5, 2): # Map change packet
			packet.read32() # map code
			packet.read16() # room players
			packet.read8() # round code
			packet.read16() # ???
			compressed_xml = packet.readString()

			if len(compressed_xml) == 0:
				self.map_xml = None
			else:
				self.map_xml = zlib.decompress(compressed_xml).decode()

			self.dispatch("map_loaded")

		packet.pos = 0
		await super().handle_packet(conn, packet)

	async def set_busy(self, busy=True, channel=None):
		"""Sets the busy state and sends a message to the channel if needed.
		Returns True if the state could be set, False otherwise"""
		if busy:
			if self.busy:
				await self.send_channel(channel, "The bot is busy right now. Try again later.")
				return False
			self.busy = True

		else:
			self.busy = False

		await self.proxy.sendTo({"type": "busy", "state": busy})
		return True

	# Module communication
	async def send_callback(self, id, text):
		"""Sends a callback to the room"""
		return await self.bulle.send(aiotfm.Packet.new(29, 21).write32(id).writeString(text))

	async def broadcast_module(self, id, text):
		"""Sends a callback to the room that broadcasts to the whole module"""
		if isinstance(text, str):
			text = text.encode()
		return await self.send_callback(SEND_ROOM, str(id).encode() + b"\x00" + text)

	async def on_lua_textarea(self, id, text):
		if id & 255 != 255:
			return

		if id == FILE_LOADED:
			self.dispatch("file_loaded", int(text))

		elif id == HEARTBEAT:
			# Room heartbeat
			self.lua_death = time.time() + 60

	# Chat system
	async def send_chat_msg(self, chat, msg):
		"""Sends a message to the specified chat"""
		return await self.main.send(aiotfm.Packet.new(6, 10).write8(chat).writeString(msg))

	async def send_channel(self, channel, msg):
		"""Sends a message to the specified channel (discord, whisper or staff chat)"""
		if not channel:
			return

		if isinstance(channel, str):
			await self.proxy.sendTo({"type": "message", "channel": channel, "msg": msg}, "parkour")
		elif channel <= 10:
			await self.send_chat_msg(channel, msg)
		else:
			await self.proxy.sendTo({"type": "message", "channel": channel, "msg": msg}, "discord")

	async def on_lua_log(self, msg):
		match = re.match(r"^<V>\[(.+?)\]<BL> (.*)$", msg, flags=re.DOTALL)
		if match is None:
			return await self.send_channel(env.private_channel, "Wrong match: `" + msg + "`")

		room, msg = match.group(1, 2)
		module = re.search(r"#([a-z]+)", room)
		if module is not None:
			module = module.group(1)

		if room == self.bots_room or (module != "parkour" and module is not None) or room == self.room.name:
			channel = env.private_channel
		elif msg.startswith("Script terminated :"):
			channel = env.lua_unloads
		else:
			channel = env.lua_logs

		await self.send_channel(channel, "`[" + room + "]` `" + msg + "`")

	async def on_chat_msg(self, chat, author, msg):
		"""Triggered when someone sends a message to a staff chat"""
		args = msg.split(" ")
		cmd = args.pop(0).lower()

		if cmd == "!restart":
			room = " ".join(args)
			self.dispatch("restart_request", room, chat)

		elif cmd == "!join":
			room = " ".join(args)
			await self.proxy.sendTo({"type": "join", "room": room, "channel": chat}, "parkour")

	async def on_server_reboot(self, ms):
		if self.received_reboot:
			return
		self.received_reboot = True

		messages = ("of course duh", "maybe", "probably", "very unlikely", "no", "marry me sharpie")
		try:
			await self.wait_for("special_chat_msg", timeout=5.0)
		except Exception:
			pass
		await self.send_chat_msg(8, random.choice(messages))

	# Maps system
	async def load_map(self, map_code, timeout=3.0):
		"""Used to load a map on the room. Returns True if it has been loaded, False otherwise"""
		if self.room.name != self.bots_room:
			return False

		await self.send_callback(LOAD_MAP, map_code)
		try:
			await self.wait_for("on_map_loaded", timeout=timeout)
		except Exception:
			return False
		return True

	async def get_map_info(self, map_code, load=False, timeout=3.0):
		"""Gets map information. If load is True, returns the xml too"""
		if load:
			# tell the server to load the map into ram so /info works
			if not await self.load_map(map_code, timeout=timeout):
				return (None,) * 4

		await self.sendCommand("info " + map_code)
		author, map_code, perm = await self.wait_for("on_map_info", timeout=timeout)
		if author is None: # map doesn't exist
			return (None,) * (4 if load else 3)

		if load:
			return author, map_code, perm, self.map_xml
		return author, map_code, perm

	async def watch_map(self, map_code, expected, every=1.0, timeout=15.0):
		"""Blocks until a map changes its perm. Returns True if it did, False otherwise"""
		start = self.loop.time()

		while self.loop.time() - start < timeout:
			next_check = self.loop.time() + every
			try:
				author, map_code, perm = await self.get_map_info(map_code, timeout=every)
			except Exception: # timeout
				continue

			if perm == expected:
				return True

			elif next_check - self.loop.time() > 0:
				await asyncio.sleep(max(next_check - self.loop.time(), 0.0))

		return False

	async def change_map_perm(self, map_code, perm, timeout=15.0):
		"""Tries to change the map perm, returns True if it did, False otherwise"""
		await self.whisper("Sharpiebot#0000", "p{} {}".format(perm, map_code))
		return await self.watch_map(map_code, int(perm), every=1.0, timeout=timeout)

	async def request_map_info(self, map_code):
		author, map_code, perm, xml = await self.get_map_info(map_code, load=True)
		await self.proxy.sendTo(
			{"type": "map_info", "author": author, "code": map_code, "perm": perm, "xml": xml},
			"discord"
		)

	async def request_rot_change(self, maps, high, add, channel):
		"""Modifies the module map rotation."""
		if not await self.set_busy(True, channel):
			return

		for code in maps:
			await self.send_callback(
				CHANGE_MAP,
				"{}\x00{}\x00{}".format("high" if high else "low", code, int(add))
			)

		file = 20 if high else 22
		await self.send_channel(channel, "The action should be applied withing a minute.")
		try:
			await self.wait_for("on_file_loaded", lambda f: f == file, timeout=65.0)
		except Exception:
			await self.set_busy(False)
			await self.send_channel(channel, "Could not modify the rotation. Try again later.")
			return

		async with aiohttp.ClientSession() as session:
			await session.post(env.records_webhook, json={
				"content": json.dumps({
					"type": "rotation",
					"maps": maps,
					"action": "add" if add else "remove",
					"priority": "high" if high else "low"
				})
			}, headers={
				"Content-Type": "application/json"
			})

		await self.send_channel(channel, "Rotation modified.")
		await self.set_busy(False)

	async def request_map_perm(self, map_code, perm, channel):
		"""Answers a request to change a map perm."""
		try:
			author, map_code, old_perm = await self.get_map_info(map_code)
		except Exception:
			author = None

		if author is None:
			return await self.send_channel(channel, "Could not load the map.")

		if not await self.change_map_perm(map_code, perm):
			return await self.send_channel(
				channel,
				"Could not change the perm of the map {}. (it is P{})".format(map_code, old_perm)
			)
		await self.send_channel(
			channel,
			"Successfully changed the perm of the map {} : P{} -> P{}".format(map_code, old_perm, perm)
		)

	# Restart system / room fix system
	async def get_module_code(self, timeout=10.0):
		"""Returns the code that is currently running in the module. Caches it."""
		if self.module_code is None:
			await self.sendCommand(commands.get_code("parkour"))
			self.module_code = await self.wait_for("on_ui_log", timeout=timeout)
		return self.module_code

	async def check_room_state(self, timeout=1.0):
		"""Checks if the room is alive. Returns True if it is."""
		check_id = (1 << 24) + 255

		await self.send_callback(check_id, "room_state_check")
		try:
			id, text = await self.wait_for("on_lua_textarea", lambda id, text: id == check_id, timeout=timeout)
		except Exception:
			return False
		return map(int, text.split("\x00"))

	async def on_restart_request(self, room, channel=None):
		"""Restarts a room if it is dead, sets the room limit to 11 otherwise."""
		if self.room is None:
			return

		if re.match(r"^(?:[a-z]{2}-|\*)#parkour(?:$|[^a-zA-Z])", room) is None:
			return await self.send_channel(
				channel, "The given room is invalid. I can only restart #parkour rooms."
			)

		if not await self.set_busy(True, channel):
			return
		await self.send_channel(channel, "Restarting the room soon.")

		joining_room = room
		if "*" == room[0]:
			joining_room = "int-" + room

		go_bots = self.room.name != room
		if room != self.room.name:
			await self.sendCommand(commands.join_room(joining_room))
			await asyncio.sleep(3.0)

			if room != self.room.name:
				await self.send_channel(channel, "Could not join the room.")
				if go_bots:
					await self.sendCommand(commands.join_room("int-" + self.bots_room))
					await self.set_busy(False)
					return

		result = await self.check_room_state(timeout=1.0)
		if result:
			current, total, cycles = result

			await self.sendCommand(commands.set_limit(11))
			await self.send_channel(
				channel,
				"Fixed room (set room limit to 11). "
				"Runtime usage: `{}ms` current, `{}ms` total, `{}ms` average (`{}` cycles)"
				.format(current, total, total / max(1, cycles), cycles)
			)

		else:
			for attempt in range(6):
				try:
					code = await self.get_module_code()
				except Exception:
					continue
				await self.loadLua(code)

				await self.send_channel(channel, "Room restarted.")
				break

			else:
				await self.send_channel(channel, "Could not restart the room.")

		if go_bots:
			await asyncio.sleep(3.0)
			await self.sendCommand(commands.join_room("int-" + self.bots_room))

		await self.set_busy(False)

	# Mute & bot room state check
	async def on_whisper(self, whisper):
		"""Checks if Parkour#8558 can still send whispers (automatic restart if it can't)"""
		if whisper.author == "Parkour#8558":
			self.next_mute_check = time.time() + 120
			self.mute_confirmed = None
			await self.proxy.sendTo({"type": "mutecheck", "alive": True}, "parkour")

	async def on_joined_room(self, room):
		if room.name == self.bots_room:
			self.lua_death = time.time() + 60
		else:
			self.lua_death = None

	async def on_heartbeat(self, taken):
		now = time.time()
		if self.lua_death is not None and now >= self.lua_death:
			await self.send_channel(env.private_channel, self.bots_room + " has crashed. restarting it")
			self.dispatch("restart_request", self.bots_room, env.private_channel)

		if self.next_mute_check is not None and now >= self.next_mute_check:
			self.next_mute_check = None
			self.mute_confirmed = time.time() + 10
			await self.proxy.sendTo({"type": "mutecheck", "request": True}, "parkour")

		if self.mute_confirmed is not None and now >= self.mute_confirmed:
			self.next_mute_check = time.time() + 30
			self.mute_confirmed = None
			await self.proxy.sendTo({"type": "mutecheck", "alive": False}, "parkour")

	# Game update
	async def on_game_update(self, load):
		"""Loads the new code if needed, sends the update alert to the whole server
		and 1 minute later updates the game."""
		if load:
			async with aiohttp.ClientSession() as session:
				async with session.get(
					"https://raw.githubusercontent.com/a801-luadev/parkour/master/builds/latest.lua"
				) as resp:
					script = await resp.read()

			await self.loadLua(script)
			await asyncio.sleep(5.0)

		await self.broadcast_module(1, "")

		await asyncio.sleep(60.0)
		await self.send_update()

	async def send_update(self):
		"""Sends an update to the game. Deletes module code cache."""
		self.module_code = None
		await self.sendCommand(commands.update("parkour"))
		await self.proxy.sendTo({"type": "game_update"}, "discord")


if __name__ == '__main__':
	loop = asyncio.get_event_loop()

	bot = Client(bot_role=True, loop=loop)
	loop.create_task(bot.start())

	try:
		loop.run_forever()
	except KeyboardInterrupt:
		print(end="\r") # remove ^C
		print("stopping")
		bot.close()