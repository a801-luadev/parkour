"""
Handles records (badges, submissions)
Logs suspects and records information
"""

from parkour.env import env
from parkour.utils import enlarge_name
import aiotfm
import json
import time
import math


RECORD_BADGES = (17 << 8) + 255
RECORD_SUBMISSION = (16 << 8) + 255
PLAYER_VICTORY = (21 << 8) + 255


class Records(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		self.victory_cache = {}

		super().__init__(*args, **kwargs)

	async def handle_module_packet(self, tid, packet):
		if await super().handle_module_packet(tid, packet):
			return True

		if tid == RECORD_SUBMISSION:
			code, player, taken, room, checkpoint = packet.split("\x00")
			player = int(player)
			taken = int(taken)
			checkpoint = int(checkpoint)
			room = enlarge_name(room)
			name = await self.get_player_name(player)

			# send to records website
			await self.send_webhook(
				env.webhooks.records,
				json.dumps({
					"type": "record",
					"mapID": int(code),
					"name": name,
					"playerID": player,
					"time": taken,
					"room": room,
					"cp": checkpoint
				})
			)

			taken /= 100

			# log record in parkour server
			await self.send_webhook(
				env.webhooks.parkour_records
				if taken > 45 else
				env.webhooks.record_suspects,

				"**`[RECORD]:`** `{}` (`{}`) completed the map `@{}` "
				"in the room `{}` in `{}` seconds."
				.format(name, player, code, room, taken)
			)

		elif tid == PLAYER_VICTORY:
			now = time.time()

			# check for cache
			if packet in self.victory_cache: # duplicated
				to_delete = []

				for victory_data, expire in self.victory_cache.items():
					if now >= expire:
						to_delete.append(victory_data)

				for victory_data in to_delete:
					del self.victory_cache[victory_data]

				if packet in self.victory_cache: # didn't expire
					return

			self.victory_cache[packet] = now + 600.0 # cache for 10 minutes

			# unpack data
			packet = packet.encode()
			player, map_code, taken = packet[:4], packet[4:8], packet[8:11]
			name = packet[11:].decode()

			player = (player[0] << (7 * 3)) + \
					(player[1] << (7 * 2)) + \
					(player[2] << (7 * 1)) + \
					player[3]

			map_code = (map_code[0] << (7 * 3)) + \
						(map_code[1] << (7 * 2)) + \
						(map_code[2] << (7 * 1)) + \
						map_code[3]

			taken = (taken[0] << (7 * 2)) + \
					(taken[1] << (7 * 1)) + \
					taken[2]

			# handle victory
			self.loop.create_task(
				self.handle_player_victory(
					player, name, map_code, taken / 1000
				)
			)

		else:
			return False
		return True

	async def handle_player_victory(self, pid, name, code, taken):
		records = await self.get_map_records(code)

		msg = (
			"**`[SUS]:`** `{name}` (`{pid}`) (`{maps}` maps/hour) "
			"completed the map `@{code}` in the room `{room}` "
			"in `{taken}` seconds. - "
			"Map record: `{record}` (threshold `{threshold}`)"
		)

		if not records:
			webhook = env.webhooks.suspects_norecord
			record, threshold = "none", 45

		else:
			webhook = env.webhooks.suspects
			record = records[0]["time"] / 100

			# first record + 15% of the time, remove some decimals
			threshold = round(record * 1.15 * 1000) / 1000

		room = None
		if taken > threshold:
			webhook = env.webhooks.game_victory

		else:
			file = await self.load_player_file(name)
			if file is not None:
				room, hour_maps = file["room"], len(file["hour"])

		if room is None:
			room, hour_maps = "unknown", "unknown"

		await self.send_webhook(webhook, msg.format(
			name=name, pid=pid,
			code=code, taken=taken,
			record=record, threshold=threshold,
			room=room, maps=hour_maps
		))

	async def handle_proxy_packet(self, client, packet):
		if await super().handle_proxy_packet(client, packet):
			return True

		if client == "records":
			if packet["type"] == "records":
				name = packet["name"] # name
				records = packet["records"] # records quantity

				if records >= 0 and (records == 1 or records % 5 == 0):
					await self.send_webhook(
						env.webhooks.record_badges,
						"**`[BADGE]:`** **{}**, **{}**"
						.format(name, records)
					)

					if badge >= 9 * 5:
						return True

					await self.send_callback(
						RECORD_BADGES,
						"{}\x00{}"
						.format(name, records)
					)

			elif packet["type"] == "map-records":
				self.dispatch("map_records", packet["map"], packet["records"])

			else:
				return False
		else:
			return False
		return True

	async def get_map_records(self, code):
		await self.proxy.sendTo({"type": "map-records", "map": code}, "records")
		try:
			code, records = await self.wait_for(
				"on_map_records",
				lambda map_code, records: map_code == code,
				timeout=10.0
			)
		except Exception:
			return ()
		return records
