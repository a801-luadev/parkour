"""
Gets players' information (id, name, is online?)
Loads and saves players' file
"""

from parkour.utils import normalize_name
import aiohttp
import asyncio
import aiotfm
import re

try:
	import ujson as json
except ImportError:
	import json


VERSION_MISMATCH = (15 << 8) + 255
LOAD_PLAYER_FILE = (29 << 8) + 255
SAVE_PLAYER_FILE = (30 << 8) + 255


class Whois(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		super().__init__(*args, **kwargs)

		self.loop.create_task(self.limit_whois_cache())

	async def fetch_player_name(self, pid):
		pid = int(pid)

		for attempt in range(3):
			try:
				async with self.forum_session.get(
					"https://atelier801.com/profile?pr={}".format(pid)
				) as resp:
					match = re.search(
						rb'> ([^<]+)<span class="nav-header-hashtag">'
						rb'(#\d{4})<\/span>',
						await resp.read()
					)

					if match is None:
						return

					return normalize_name(
						(match.group(1) + match.group(2)).decode()
					)

			except Exception:
				await self.forum_session.close()
				self.forum_session = aiohttp.ClientSession()

	async def get_player_name(self, pid):
		pid = int(pid)
		friend = self.friends.get_friend(pid)
		if friend is None:
			name = await self.fetch_player_name(pid)
			if name is None:
				return

			try:
				friend = await self.friends.add(name)
			except Exception:
				return

		return normalize_name(friend.name)

	async def get_player_id(self, name):
		friend = self.friends.get_friend(name)
		if friend is None:
			try:
				friend = await self.friends.add(name)
			except Exception:
				return

		return friend.id

	async def get_player_info(self, query):
		if isinstance(query, str) and query.isdigit():
			query = int(query)

		friend = self.friends.get_friend(query)
		if friend is None:
			if isinstance(query, int):
				name = await self.fetch_player_name(query)
				if name is None:
					return (None, None, None)

			else:
				name = query

			try:
				friend = await self.friends.add(name)
			except Exception:
				return (None, None, None)

		return (
			friend.id,
			normalize_name(friend.name),
			friend.isConnected
		)

	async def load_player_file(self, name, online_check=True):
		name = normalize_name(name)
		if online_check:
			pid, name, online = await self.get_player_info(name)
			if not online:
				return

		await self.send_callback(LOAD_PLAYER_FILE, name)
		try:
			name, data = await self.wait_for(
				"on_player_file_loaded",
				lambda player, data: name == player,
				timeout=1.0
			)
		except Exception:
			return

		return json.loads(data) if data else None

	async def save_player_file(self, name, file, update, online_check=True):
		name = normalize_name(name)
		if online_check:
			pid, name, online = await self.get_player_info(name)
			if not online:
				return False

		await self.send_callback(
			SAVE_PLAYER_FILE,
			"{}\x00{}\x00{}"
			.format(
				name, json.dumps(file),
				"\x01".join(update) if isinstance(update, tuple) else update
			)
		)
		return True

	async def handle_module_packet(self, tid, packet):
		if await super().handle_module_packet(tid, packet):
			return True

		if tid == LOAD_PLAYER_FILE or tid == VERSION_MISMATCH:
			if tid == LOAD_PLAYER_FILE:
				player, file = packet.split("\x00", 1)
				self.dispatch("player_file_loaded", player, file)
			else:
				self.dispatch("player_file_loaded", packet, None)

		else:
			return False
		return True

	async def limit_whois_cache(self):
		while not self.main.open:
			await asyncio.sleep(3.0)

		while self.main.open:
			await asyncio.sleep(300.0)

			if self.friends is None or len(self.friends.friends) < 400:
				continue

			count, friends, required = 0, [], len(self.friends.friends) - 350

			for friend in self.friends.friends:
				if (friend.isSoulmate
					or normalize_name(friend.name) in self.player_ranks):
					continue

				count += 1
				friends.append(friend)
				if count >= required:
					break

			for friend in friends:
				await friend.remove()
				await asyncio.sleep(1.0)

	async def friend_staff(self):
		for player in self.player_ranks:
			if player == "Parkour#8558":
				continue

			friend = self.friends.get_friend(player)
			if friend is None:
				await self.friends.add(player)
				await asyncio.sleep(1.0)

	async def on_module_synchronization(self):
		if self.friends is not None:
			await self.friend_staff()

	async def on_friends_loaded(self, friends):
		if self.player_ranks is not None:
			await self.friend_staff()

		self.forum_session = aiohttp.ClientSession()