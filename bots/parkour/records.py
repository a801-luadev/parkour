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
		self.pending_title_victory_cache = {}

		super().__init__(*args, **kwargs)

	async def handle_module_packet(self, tid, packet):
		if await super().handle_module_packet(tid, packet):
			return True

		if tid == RECORD_SUBMISSION:
			code, name, player, taken, room, checkpoint = packet.split("\x00")
			player = int(player)
			taken = int(taken)
			checkpoint = int(checkpoint)
			room = enlarge_name(room)

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
			packet = packet.encode()

			if packet[0] == 0:
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
				player, map_code, taken = packet[1:5], packet[5:9], packet[9:12]
				name = packet[12:].decode()

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
			elif packet[0] == 1:
				#unpack data
				player, fieldValue, sumValue = packet[1:5], packet[5:9], packet[9:12]
				name = packet[12:].decode()
				fieldName, name = name[-2:], name[:-2]

				player = (player[0] << (7 * 3)) + \
						(player[1] << (7 * 2)) + \
						(player[2] << (7 * 1)) + \
						player[3]

				fieldValue = (fieldValue[0] << (7 * 3)) + \
							(fieldValue[1] << (7 * 2)) + \
							(fieldValue[2] << (7 * 1)) + \
							fieldValue[3]

				sumValue = (sumValue[0] << (7 * 2)) + \
						(sumValue[1] << (7 * 1)) + \
						sumValue[2]

				# handle victory
				self.loop.create_task(
					self.handle_player_title_victory(
						player, name, fieldValue, sumValue, fieldName
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

	async def handle_player_title_victory(self, pid, name, field_value, sum_value, field_name):
		if self.pending_title_victory_cache.get(pid) is None:
			self.pending_title_victory_cache[pid] = { }

		pid_cache = self.pending_title_victory_cache[pid]
		pid_cache[field_name] = {
			"field_value": field_value,
			"sum_value": sum_value
		}

		tc = pid_cache.get("tc")
		cc = pid_cache.get("cc")
		if not (tc and cc):
			return None

		msg = (
			"**`[SUS]:`** `{name}` (`{pid}`) got +{tc_sum_value} TC (title map count), "
			"totalizing {tc_field_value} and +{cc_sum_value} CC (title checkpoints count), "
			"totalizing {cc_field_value}."
		)

		await self.send_webhook(env.webhooks.game_title_data, msg.format(
			name=name, pid=pid,
			tc_sum_value = tc["sum_value"],
			tc_field_value = tc["field_value"],
			cc_sum_value = cc["sum_value"],
			cc_field_value = cc["field_value"]
		))

	async def on_whisper_command(self, whisper, author, ranks, cmd, args):
		if await super().on_whisper_command(
			whisper, author, ranks, cmd, args
		):
			return True

		if cmd == "recbadge":
			if not ranks["admin"]:
				return True

			if len(args) < 2 or not args[1].isdigit():
				await whisper.reply("Invalid syntax.")
				return True

			name = args[0]
			records = int(args[1])

			if records >= 9 * 5 or not (records == 1 or records % 5 == 0):
				await whisper.reply("Invalid records badge.")
				return True

			await self.send_callback(
				RECORD_BADGES,
				"{}\x00{}"
				.format(name, records)
			)
			await whisper.reply("Gave {} records badge to {}.".format(records, name))

		else:
			return False

		return True

	async def handle_proxy_packet(self, client, packet):
		if await super().handle_proxy_packet(client, packet):
			return True

		if client == "discord":
			if packet["type"] == "send-records-badge":
				name = packet["name"]
				records = packet["records"]

				if records >= 9 * 5 or not (records == 1 or records % 5 == 0):
					return True

				await self.send_callback(
					RECORD_BADGES,
					"{}\x00{}"
					.format(name, records)
				)

			else:
				return False

		elif client == "records":
			if packet["type"] == "records":
				name = packet["name"] # name
				records = packet["records"] # records quantity

				if records >= 0 and (records == 1 or records % 5 == 0):
					await self.send_webhook(
						env.webhooks.record_badges,
						"**`[BADGE]:`** **{}**, **{}**"
						.format(name, records)
					)

					if records >= 9 * 5:
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
