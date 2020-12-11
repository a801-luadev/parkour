"""
Sends basic logging information to discord
"""

from parkour.env import env
from parkour.utils import enlarge_name
import aiotfm
import time

WEEKLY_RECORDS_MSG = """<a:blob_cheer1:683845978553450576> **[{} - {}]** <a:blob_cheer2:683846001421058071>
Congratulations to the highest achieving Weekly Leaderboard players!

> 🥇 [{}] `{}`: **{}** completed maps
> 🥈 [{}] `{}`: **{}** completed maps
> 🥉 [{}] `{}`: **{}** completed maps"""

SEND_WEBHOOK = (3 << 8) + 255
WEEKLY_RESET = (12 << 8) + 255
COMMAND_LOG = (26 << 8) + 255

MODULE_CRASH = (255 << 8) + 255


class Logs(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		self.weekly_cooldown = 0

		super().__init__(*args, **kwargs)

	async def handle_module_packet(self, tid, packet):
		if await super().handle_module_packet(tid, packet):
			return True

		if tid == SEND_WEBHOOK:
			prefix, msg = packet.split(" ", 1)
			if prefix == "**`[CRASH]:`**":
				webhook = env.webhooks.game_logs
			elif prefix == "**`[SUS2]:`**":
				webhook = env.webhooks.suspects2
			else:
				webhook = env.webhooks.default

			await self.send_webhook(webhook, "{} {}".format(prefix, msg))

		elif tid == MODULE_CRASH:
			event, message = packet.split("\x00", 1)
			await self.send_webhook(
				env.webhooks.private,
				"**`[BOTCRASH]:`** <@212634414021214209>: `{}`, `{}`"
				.format(event, message)
			)

		elif tid == WEEKLY_RESET:
			if self.weekly_cooldown:
				if time.time() >= self.weekly_cooldown:
					self.weekly_cooldown = 0
				else:
					return

			date_start, date_end, *podium = packet.split("\x00")
			date_start, date_end = date_start[:5], date_end[:5]

			self.weekly_cooldown = time.time() + 600.0
			await self.send_webhook(
				env.webhooks.weekly_record,
				WEEKLY_RECORDS_MSG.format(date_start, date_end, *podium),
			)

		elif tid == COMMAND_LOG:
			room, player, command = packet.split("\x00")
			room = enlarge_name(room)

			await self.send_webhook(
				env.webhooks.commands,

				"**`[COMMAND]:`** `{}` `{}`: `!{}`"
				.format(room, player, command)
			)

		else:
			return False
		return True