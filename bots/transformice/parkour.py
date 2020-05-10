from aiotfm.connection import TFMProtocol

import aiohttp
import aiotfm
import time
import re
import os

SEND_PACKET  = (1 << 8) + 255
SEND_WEBHOOK = (2 << 8) + 255
MODIFY_RANK  = (3 << 8) + 255
RANK_DATA    = (4 << 8) + 255
FETCH_ID     = (5 << 8) + 255
TIME_SYNC    = (6 << 8) + 255

class CustomProtocol(TFMProtocol):
	def connection_lost(self, exc):
		super().connection_lost(exc)
		if self.client.auto_restart and exc is None:
			self.client.loop.create_task(self.client.restart_soon())

class Connection(aiotfm.Connection):
	PROTOCOL = CustomProtocol

	def _factory(self):
		return Connection.PROTOCOL(self)

class Client(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		super().__init__(*args, **kwargs)

		self.time_diff = 0
		self.player_ranks = {}
		self.ranks = {}
		self.waiting_ids = []
		self.webhook_links = {
			"**`[UPDATE]:`**": os.getenv("GAME_LOGS_WEBHOOK"),
			"**`[CRASH]:`**": os.getenv("GAME_LOGS_WEBHOOK"),
			"**`[SUS]:`**": os.getenv("SUSPECT_WEBHOOK"),
			"**`[BANS]:`**": os.getenv("SANCTIONS_WEBHOOK"),
			"**`[KILL]:`**": os.getenv("SANCTIONS_WEBHOOK"),
			"**`[RANKS]:`**": os.getenv("RANKS_WEBHOOK"),
			"**`[JOIN]:`**": os.getenv("JOIN_WEBHOOK")
		}
		self.default_webhook = os.getenv("DEFAULT_WEBHOOK")
		self.next_available_restart = 0
		self.restarting = False

	def tfm_time(self):
		return (time.time() + self.time_diff) * 1000

	def close(self, *args):
		if not self.restarting:
			return super().close(*args)
		self.restarting = False

	async def restart(self, *args):
		self.close()
		self.restarting = True
		self.main = Connection("main", self, self.loop)
		return await super().restart(*args)

	async def handle_packet(self, conn, packet):
		CCC = packet.readCode()
		if CCC == (29, 20):
			self.dispatch("lua_textarea", packet.read32(), packet.readString())

		packet.pos = 0
		await super().handle_packet(conn, packet)

	async def on_login_ready(self, *args):
		print("[PARKOUR] Connected. Logging in...", flush=True)
		await self.login("Parkour#8558", os.getenv("PARKOUR_PASSWORD"), encrypted=False, room="*#parkour0maps")

	async def on_logged(self, *args):
		print("[PARKOUR] Logged in!", flush=True)
		self.next_available_restart = time.time() + 600

	async def sendLuaCallback(self, txt_id, text):
		packet = aiotfm.Packet.new(29, 21)
		await self.bulle.send(packet.write32(txt_id).writeString(text))

	def sendLuaPacket(self, packet_id, packet): # returns a coro
		return self.sendLuaCallback(SEND_PACKET, str(packet_id).encode() + b"," + (packet.encode() if isinstance(packet, str) else packet))

	async def on_lua_textarea(self, txt_id, text):
		if txt_id & 255 != 255:
			return

		if txt_id == SEND_WEBHOOK:
			self.dispatch("send_webhook", text)

		elif txt_id == RANK_DATA:
			self.player_ranks = {}
			self.ranks = {}
			for idx, part in enumerate(text.decode().split("\x00")):
				if idx == 0:
					for rank in part.split("\x01"):
						self.ranks[rank] = False
					continue

				player, *ranks = part.split("\x01")
				player = player.capitalize()
				self.player_ranks[player] = self.ranks.copy()
				for rank in ranks:
					self.player_ranks[player][rank] = True

		elif txt_id == FETCH_ID:
			data = text.decode().split(" ")
			if data[0] in self.waiting_ids:
				self.waiting_ids.remove(data[0])
			if len(data) == 1:
				self.dispatch("player_id_response", data[0], None)
			else:
				self.dispatch("player_id_response", data[0], int(data[1]))

		elif txt_id == TIME_SYNC:
			now = time.time()
			self.time_diff = int(text) // 1000 - now

	async def get_player_id(self, player_name):
		player_name = player_name.replace("#", "%23").replace("+", "%2B")
		if player_name not in self.waiting_ids:
			self.waiting_ids.append(player_name)

			await self.sendCommand("profile Tocutoeltuco#5522")
			try:
				profile = await self.wait_for("on_profile", lambda p: p.username == "Tocutoeltuco#5522", timeout=3.0)
			except:
				return

			await self.sendLuaCallback(FETCH_ID, player_name)

		try:
			n, i = await self.wait_for("on_player_id_response", lambda n, i: n == player_name, timeout=10.0)
			return i
		except:
			return

	async def get_player_name(self, player_id):
		async with aiohttp.ClientSession() as session:
			async with session.get("https://atelier801.com/profile?pr={}".format(player_id)) as resp:
				match = re.search(
					rb'> ([^<]+)<span class="nav-header-hashtag">(#\d{4})<\/span>',
					await resp.read()
				)
				if match is None:
					return
				return match.group(1).decode() + match.group(2).decode()

	async def on_send_webhook(self, text):
		if isinstance(text, bytes):
			text = text.decode()

		head = text.split(" ")[0]
		if head in self.webhook_links:
			link = self.webhook_links[head]
		else:
			link = self.default_webhook

		async with aiohttp.ClientSession() as session:
			await session.post(link, json={
				"content": text
			}, headers={
				"Content-Type": "application/json"
			})

	def normalize_name(self, name):
		if name[0] == "+":
			name = "+" + (name[1:].capitalize())
		else:
			name = name.capitalize()
		if "#" not in name:
			name += "#0000"
		return name

	async def on_whisper(self, whisper):
		args = whisper.content.split(" ")
		cmd = args.pop(0).lower()
		if not cmd.startswith("."):
			return
		cmd = cmd[1:]

		author = whisper.author.username.capitalize()
		ranks = self.player_ranks[author] if author in self.player_ranks else self.ranks

		if cmd == "announce":
			if not ranks["admin"]:
				return
			if not args:
				return await whisper.reply("Invalid syntax.")

			await self.sendLuaPacket(4, " ".join(args))
			await whisper.reply("Announced!")

		elif cmd == "update":
			if not ranks["admin"]:
				return
			await self.sendLuaPacket(1, b"")
			await whisper.reply("Update alert sent.")
			self.dispatch("send_webhook", "**`[UPDATE]:`** The game is gonna update soon.")

		elif cmd == "rank":
			if not ranks["admin"] and not ranks["manager"]:
				return
			if len(args) < 3:
				return await whisper.reply("Invalid syntax.")

			action = args[0].lower()
			if action not in ("add", "rem"):
				return await whisper.reply("Invalid action: '{}'.".format(action))

			rank = args[2].lower()
			if rank not in self.ranks:
				return await whisper.reply("Invalid rank: '{}'.".format(rank))

			player = args[1].capitalize()
			if action == "add":
				if player not in self.player_ranks:
					self.player_ranks[player] = self.ranks.copy()
				self.player_ranks[player][rank] = True

				self.dispatch("send_webhook", "**`[RANKS]:`** `{}` is now a `parkour-{}` (changed by `{}`)".format(player, rank, author))
				await self.sendLuaCallback(MODIFY_RANK, ",".join((rank, "1", player)))
				await whisper.reply("Added rank '{}' to '{}'.".format(rank, player))
			else:
				if player in self.player_ranks:
					self.player_ranks[player][rank] = False

				self.dispatch("send_webhook", "**`[RANKS]:`** `{}` is no longer a `parkour-{}` (changed by `{}`)".format(player, rank, author))
				await self.sendLuaCallback(MODIFY_RANK, ",".join((rank, "0", player)))
				await whisper.reply("Removed rank '{}' from '{}'.".format(rank, player))

		elif cmd == "ban" or cmd == "unban":
			if not ranks["admin"] and not ranks["mod"]:
				return

			if cmd == "unban":
				if not args:
					return await whisper.reply("Invalid syntax.")

				minutes = 0
			elif len(args) < 2 or not args[1].isdigit():
				return await whisper.reply("Invalid syntax.")
			else:
				minutes = int(args[1])

			if args[0].isdigit():
				id = int(args[0])
				name = await self.get_player_name(id)
				if name is None:
					return await whisper.reply("Could not find that player.")
			elif re.match(r"^\+?[a-z0-9_]+(?:#\d{4})?", args[0].lower()) is None:
				return await whisper.reply("Invalid name.")
			else:
				name = args[0].capitalize()
				id = await self.get_player_id(name)
				if id is None:
					return await whisper.reply("Could not get the ID of the player.")

			name = self.normalize_name(name)
			if minutes == 0:
				self.dispatch("send_webhook", "**`[BANS]:`** `{}` has unbanned `{}` (ID: `{}`)".format(author, name, id))
			elif minutes == 1:
				self.dispatch("send_webhook", "**`[BANS]:`** `{}` has permbanned `{}` (ID: `{}`)".format(author, name, id))
			else:
				self.dispatch("send_webhook", "**`[BANS]:`** `{}` has banned `{}` (ID: `{}`) for `{}` minutes.".format(author, name, id, minutes))
				minutes *= 60 * 1000 # make it milliseconds
				minutes += self.tfm_time() # sync it with transformice

			await self.sendLuaPacket(3, "\x00".join((name, str(id), str(minutes))))
			await whisper.reply("Action applied.")

		elif cmd == "kill":
			if not ranks["admin"] and not ranks["mod"] and not ranks["trainee"]:
				return

			if len(args) < 2 or not args[1].isdigit():
				return await whisper.reply("Invalid syntax.")
			else:
				minutes = int(args[1])

			if args[0].isdigit():
				id = int(args[0])
				name = await self.get_player_name(id)
				if name is None:
					return await whisper.reply("Could not find that player.")
			elif re.match(r"^\+?[a-z0-9_]+(?:#\d{4})?", args[0].lower()) is None:
				return await whisper.reply("Invalid name.")
			else:
				name = args[0].capitalize()
				id = await self.get_player_id(name)
				if id is None:
					id = "unknown"

			name = self.normalize_name(name)
			await self.sendCommand("profile " + name)
			try:
				profile = await self.wait_for("on_profile", lambda p: self.normalize_name(p.username) == name, timeout=3.0)
			except:
				return await whisper.reply("That player is not online.")

			self.dispatch("send_webhook", "**`[KILL]:`** `{}` has killed `{}` (ID: `{}`) for `{}` minutes.".format(author, name, id, minutes))
			await self.sendLuaPacket(2, "\x00".join((name, str(minutes))))
			await whisper.reply("Action applied.")

		elif cmd == "whois":
			if not ranks["admin"] and not ranks["mod"] and not ranks["trainee"]:
				return
			if not args:
				return await whisper.reply("Invalid syntax.")

			if args[0].isdigit():
				name = await self.get_player_name(args[0])
				if name is None:
					return await whisper.reply("Could not get the name of the player.")
				await whisper.reply(name)

			else:
				if re.match(r"^\+?[a-z0-9_]+(?:#\d{4})?", args[0].lower()) is None:
					return await whisper.reply("Invalid name.")

				id = await self.get_player_id(args[0].capitalize())
				if id is None:
					return await whisper.reply("Could not get the ID of the player.")
				await whisper.reply(str(id))

		elif cmd == "join":
			if not ranks["admin"] and not ranks["mod"] and not ranks["trainee"]:
				return
			if not args:
				return await whisper.reply("Invalid syntax.")

			room = " ".join(args)
			if re.match(r"^(?:(?:[a-z][a-z]|e2)-|\*)#parkour(?:$|\d.*)", room) is None:
				return await whisper.reply("The given room is invalid. You can only join #parkour rooms.")

			self.dispatch("send_webhook", "**`[JOIN]:`** `{}` requested to join `{}`.".format(author, room))
			await self.sendLuaPacket(0, room)
			await whisper.reply("Room join request has been sent.")

		elif cmd == "reboot":
			if ranks["admin"]:
				pass
			elif not ranks["mod"] and not ranks["trainee"]:
				return
			elif time.time() < self.next_available_restart:
				return whisper.reply(
					"You need to wait {} seconds to restart the bot. Call an admin otherwise.".format(self.next_available_restart - time.time())
				)

			self.loop.create_task(self.restart_soon())