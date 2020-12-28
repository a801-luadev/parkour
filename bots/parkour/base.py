"""
Connects to the game
Connects to the proxy
Synchronizes with the module
Handles player ranks
Handles webhooks
Handles restarts
"""

from proxy_connector import Connection
from parkour.env import env
from parkour.utils import normalize_name
import traceback
import asyncio
import aiotfm
import aiohttp
import time
import re


SEND_ROOM = (2 << 8) + 255
SYNCHRONIZE = (5 << 8) + 255


class Proxy(Connection):
	def __init__(self, client, *args, **kwargs):
		self.client = client

		super().__init__(*args, **kwargs)

	async def connection_lost(self):
		await self.client.restart()

	async def received_proxy(self, client, packet):
		coro = self.client.handle_proxy_packet(client, packet)

		if self.loop == self.client.loop:
			self.loop.create_task(coro)
		else:
			asyncio.run_coroutine_threadsafe(coro, self.client.loop)


class Base(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		self.bots_room = "*#parkour4bots"
		self.time_diff = 0
		self.ranks = {}
		self.player_ranks = {}
		self.webhooks_session = None

		super().__init__(*args, **kwargs)

	def tfm_time(self):
		return (time.time() + self.time_diff) * 1000

	def get_player_rank(self, player):
		return self.player_ranks.get(
			normalize_name(player),
			self.ranks
		)

	async def start(self, *args, **kwargs):
		try:
			await super().start(*args, **kwargs)
		except Exception:
			traceback.print_exc()
		finally:
			await self.restart()

	async def restart(self):
		# The bot runs in a heroku dyno, we need to restart it.
		async with aiohttp.ClientSession() as session:
			await session.delete(
				"https://api.heroku.com/apps/parkour-bot/dynos/parkour",
				headers={
					"Content-Type": "application/json",
					"Accept": "application/vnd.heroku+json; version=3",
					"Authorization": "Bearer " + env.heroku_token
				}
			)

	async def send_channel(self, channel, msg):
		"""Sends a message to the specified channel (discord, whisper or staff chat)"""
		if not channel:
			return

		if isinstance(channel, str):
			await self.whisper(channel, msg)
		elif channel <= 10:
			await self.proxy.sendTo({"type": "message", "channel": channel, "msg": msg}, "tocubot")
		else:
			await self.proxy.sendTo({"type": "message", "channel": channel, "msg": msg}, "discord")

	async def on_login_ready(self, *a):
		print("Connected")

		self.webhooks_session = aiohttp.ClientSession()

		# Connects to the proxy
		self.proxy = Proxy(self, env.proxy_token, "parkour")
		try:
			await self.proxy.connect(env.proxy_ip, env.proxy_port)
		except Exception:
			await self.restart()

		# Logs into transformice
		await self.login("Parkour#8558", env.password, encrypted=False, room=self.bots_room)

	async def on_logged(self, *a):
		print("Logged in!")

	async def on_connection_error(self, conn, exc):
		if conn.name == "main":
			# If the main connection with tfm is lost, we need to restart
			await self.restart()

		elif conn.name == "bulle":
			# If the connection to the room is lost, we need to join another room
			# and come back.
			await self.sendCommand("mjj 1")
			await asyncio.sleep(3.0)
			await self.joinRoom(self.bots_room)

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
			return await self.send_channel(
				channel,
				"Syntax error: ```python\n" + traceback.format_exc() + "```"
			)

		try:
			await locals()["evaluate"](self)
		except Exception:
			return await self.send_channel(
				channel,
				"Runtime error: ```python\n" + traceback.format_exc() + "```"
			)

		return await self.send_channel(channel, "Script ran successfully.")

	async def send_webhook(self, link, message, call_soon=True):
		if call_soon:
			self.loop.create_task(self.send_webhook(link, message, call_soon=False))
			return

		if isinstance(message, bytes):
			message = message.decode()

		for attempt in range(3):
			try:
				await self.webhooks_session.post(link, json={
					"content": message
				}, headers={
					"Content-Type": "application/json"
				})
				break
			except Exception:
				await self.webhooks_session.close()
				self.webhooks_session = aiohttp.ClientSession()

	async def send_callback(self, tid, packet):
		"""Sends a callback to the room"""
		return await self.bulle.send(
			aiotfm.Packet.new(29, 21).write32(tid).writeString(packet)
		)

	async def broadcast_module(self, pid, packet):
		"""Sends a callback to the room that broadcasts to the whole module"""
		return await self.send_callback(SEND_ROOM, str(pid) + "\x00" + packet)

	async def handle_proxy_packet(self, client, packet):
		if client in ("discord", "tocubot"):
			if packet["type"] == "exec":
				self.loop.create_task(self.load_script(packet))

			else:
				return False
		else:
			return False

		return True

	async def handle_module_packet(self, tid, packet):
		if tid == SYNCHRONIZE:
			# Synchronizes the game and the bot
			now = time.time()

			lua_time, ranks, staff = packet.split("\x00", 2)
			self.time_diff = int(lua_time) // 1000 - now

			self.player_ranks = {}
			self.ranks = {}

			for rank in ranks.split("\x01"):
				self.ranks[rank] = False

			for data in staff.split("\x00"):
				player, *ranks = data.split("\x01")
				player = normalize_name(player)

				self.player_ranks[player] = self.ranks.copy()
				for rank in ranks:
					self.player_ranks[player][rank] = True

			self.dispatch("module_synchronization")

		else:
			return False

		return True

	async def handle_packet(self, conn, packet):
		CCC = packet.readCode()

		if CCC == (29, 20):
			tid = packet.read32()

			if not tid & 255:
				return

			self.loop.create_task(self.handle_module_packet(
				tid, re.sub(r"(ht)<(tp)", r"\1\2", packet.readUTF(), flags=re.I)
			))

		else:
			packet.pos = 0
			return await super().handle_packet(conn, packet)

		return True