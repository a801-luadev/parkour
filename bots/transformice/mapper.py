import aiotfm
import transformice.aiotfmpatch as aiotfmpatch
import aiohttp
import asyncio
import hashlib
import random
import string
import time
import re
import os

SEND_OTHER = (1 << 8) + 255
SEND_ROOM = (2 << 8) + 255
SEND_WEBHOOK = (3 << 8) + 255
MODIFY_RANK = (4 << 8) + 255
SYNCHRONIZE = (5 << 8) + 255
HEARTBEAT = (6 << 8) + 255
CHANGE_MAP = (7 << 8) + 255
FILE_LOADED = (8 << 8) + 255
CURRENT_MODCHAT = (9 << 8) + 255
NEW_MODCHAT = (10 << 8) + 255
LOAD_MAP = (11 << 8) + 255
WEEKLY_RESET = (12 << 8) + 255

MODULE_CRASH = (255 << 8) + 255

class Client(aiotfmpatch.Client):
	heartbeat_death = None

	async def handle_packet(self, conn, packet):
		CCC = packet.readCode()
		if CCC == (29, 20):
			self.dispatch("lua_textarea", packet.read32(), packet.readUTF())

		elif CCC == (28, 5):
			packet.read16()
			if packet.readUTF() == "$CarteIntrouvable":
				self.dispatch("map_info", None, None, None)

		elif CCC == (6, 20):
			packet.readBool()
			data = packet.readUTF()
			match = re.search(r"(\+?[A-Za-z][A-Za-z0-9_]{2,20}(?:#\d{4})?) - (@\d+) - \d+ - \d+% - P(\d+)", data)

			if match is not None:
				self.dispatch("map_info", *match.group(1, 2), int(match.group(3)))

		elif CCC == (28, 46):
			packet.readBool()
			packet.readBool()
			packet.readBool()

			self.dispatch("ui_log", bytes(packet.readBytes(packet.read24())))

		elif CCC == (6, 10):
			self.dispatch("special_chat_msg", packet.read8(), packet.readUTF(), packet.readUTF())

		elif CCC == (28, 88):
			self.dispatch("server_reboot", packet.read32())

		packet.pos = 0
		await super().handle_packet(conn, packet)

	async def getMapInfo(self, mapcode, timeout=3.0):
		await self.sendCommand("info " + mapcode)
		return await self.wait_for("on_map_info", timeout=timeout)

	async def on_login_ready(self, *args):
		print("[MAPPER] Connected. Logging in...", flush=True)
		await self.login("Tocutoeltuco#5522", os.getenv("MAPPER_PASSWORD"), encrypted=False, room="*#parkour4bots")

	async def on_logged(self, *args):
		print("[MAPPER] Logged in!", flush=True)

	async def on_mod_chat(self, msg):
		await self.sendLuaCallback(SEND_OTHER, "modchat\x00" + msg)

	async def on_load_request(self, script):
		await self.loadLua(script)

	async def on_joined_room(self, room):
		if room.name == "*#parkour4bots":
			self.heartbeat_death = time.time() + 5
		else:
			self.heartbeat_death = None

	async def on_server_reboot(self, ms):
		seconds = ms // 1000

		if seconds == 120:
			try:
				await self.wait_for("special_chat_msg", timeout=5.0)
			except:
				pass
			await self.sendSpecialChatMsg(8, "noob bot ^")

	async def on_restart_request(self, room, channel):
		if self.room is None:
			return

		go_maps = False
		if room != self.room.name:
			await self.sendCommand("room* " + room)
			await asyncio.sleep(3.0)
			go_maps = True

		for attempt in range(6):
			try:
				code = await self.getModuleCode()
			except:
				continue
			await self.loadLua(code)

			if isinstance(channel, int):
				await self.sendSpecialChatMsg(channel, "Room restarted.")
			elif channel is not None:
				await channel.send("Room restarted.")
			break
		else:
			if isinstance(channel, int):
				await self.sendSpecialChatMsg(channel, "Could not restart the room.")
			elif channel is not None:
				await channel.send("Could not restart the room.")

		if go_maps:
			await asyncio.sleep(3.0)
			await self.sendCommand("room* *#parkour4bots")

		await asyncio.sleep(3.0)
		self.discord.busy = False

	async def sendSpecialChatMsg(self, chat, msg):
		return await self.main.send(aiotfm.Packet.new(6, 10).write8(chat).writeString(msg))

	async def on_special_chat_msg(self, chat, author, msg):
		args = msg.split(" ")
		cmd = args.pop(0).lower()

		if cmd == "!restart":
			room = " ".join(args)
			if re.match(r"^(?:(?:[a-z][a-z]|e2)-|\*)#parkour(?:$|\d.*)", room) is None:
				return await self.sendSpecialChatMsg(chat, "The given room is invalid. I can only restart #parkour rooms.")

			if self.discord.busy:
				return await self.sendSpecialChatMsg(chat, "The bot is busy right now. Try again later.")
			self.discord.busy = True

			self.dispatch("restart_request", room, chat)
			await self.sendSpecialChatMsg(chat, "Restarting the room soon.")

		elif cmd == "!join":
			room = " ".join(args)
			if re.match(r"^(?:(?:[a-z][a-z]|e2)-|\*)#parkour(?:$|\d.*)", room) is None:
				return await self.sendSpecialChatMsg(chat, "The given room is invalid. I can only let you join #parkour rooms.")

			await self.sendRoomPacket(0, room)
			await self.sendSpecialChatMsg(chat, "Room join request has been sent.")

	async def getModuleCode(self):
		await self.sendCommand(os.getenv("GETSCRIPT_CMD"))
		return await self.wait_for("on_ui_log", timeout=10.0)

	async def on_lua_log(self, msg):
		self.discord.dispatch("lua_log", msg)

	def sendLuaCallback(self, txt_id, text): # returns a coro
		return self.bulle.send(aiotfm.Packet.new(29, 21).write32(txt_id).writeString(text))

	def sendRoomPacket(self, packet_id, packet): # returns a coro
		if isinstance(packet, str):
			packet = packet.encode()
		return self.sendLuaCallback(SEND_ROOM, str(packet_id).encode() + b"\x00" + packet)

	async def watchMap(self, code, expected, every=1.0, timeout=15.0):
		start = self.loop.time()
		while self.loop.time() - start < timeout:
			next_one = self.loop.time() + every
			try:
				author, code, perm = await self.getMapInfo(code, timeout=every)
			except: # timeout
				continue

			if perm == expected:
				return True

			now = self.loop.time()
			if next_one - now > 0:
				await asyncio.sleep(next_one - now)
		return False

	async def changeMapPerm(self, code, perm, timeout=15.0):
		await self.whisper("Sharpiebot#0000", "p{} {}".format(perm, code))
		return await self.watchMap(code, int(perm), every=1.0, timeout=timeout)

	async def on_whisper(self, whisper):
		print(whisper)

	async def on_lua_textarea(self, txt_id, text):
		if txt_id & 255 != 255:
			return

		if txt_id == HEARTBEAT:
			self.heartbeat_death = time.time() + 5

		elif txt_id == SEND_OTHER:
			head, data = text.split("\x00", 1)

			if head == "fetchid":
				self.discord.dispatch("whois_request", data)

			elif head == "update":
				self.dispatch("game_update", data == "yes")

		elif txt_id == FILE_LOADED:
			self.dispatch("file_loaded", int(text))

	async def on_game_update(self, load):
		if load:
			async with aiohttp.ClientSession() as session:
				async with session.get("https://raw.githubusercontent.com/a801-luadev/parkour/master/builds/latest.lua") as resp:
					script = await resp.read()

			await self.loadLua(script)
			await asyncio.sleep(5.0)

		await self.sendLuaCallback(SEND_OTHER, "update") # trigger webhook!
		await self.sendRoomPacket(1, "")

		await asyncio.sleep(60.0)
		await self.sendCommand(os.getenv("LAUNCHPARKOUR_CMD"))

	async def on_whois_response(self, response):
		await self.sendLuaCallback(SEND_OTHER, "fetchid\x00" + response)

	async def on_heartbeat(self, taken):
		if self.heartbeat_death is not None and self.room is not None:
			if self.room.name == "*#parkour4bots" and time.time() >= self.heartbeat_death:
				self.discord.dispatch("bots_room_crash")
				self.heartbeat_death = None

	async def on_map_change(self, rotation, code, add):
		await self.sendLuaCallback(CHANGE_MAP, "{}\x00{}\x00{}".format(rotation, code, int(add)))