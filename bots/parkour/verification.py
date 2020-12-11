"""
Handles discord verification
"""

from parkour.env import env
from parkour.utils import normalize_name
from forum import ForumClient
import asyncio
import aiotfm


class Verification(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		super().__init__(*args, **kwargs)

		self.loop.create_task(self.check_forum())

	async def handle_proxy_packet(self, client, packet):
		if await super().handle_proxy_packet(client, packet):
			return True

		if client == "discord":
			if packet["type"] == "give_badge":
				# Gives discord verified badge to the user
				await self.give_discord_badge(
					packet["player"], packet["discord"], packet["channel"]
				)

			else:
				return False
		else:
			return False
		return True

	async def on_whisper(self, whisper):
		await super().on_whisper(whisper)

		if whisper.content.startswith("tfm"):
			await self.proxy.sendTo({
				"type": "verification",
				"username": normalize_name(whisper.author),
				"token": whisper.content
			}, "discord")

	async def check_forum(self):
		"""Checks for new messages every minute."""
		while not self.main.open:
			await asyncio.sleep(3.0)

		forum = ForumClient()

		need_login = True
		while self.main.open:
			if need_login:
				await forum.start()
				if await forum.login(
					"Parkour#8558", env.password, encrypted=False
				):
					print("Logged into the forum!")
					need_login = False
				else:
					print("Could not log into the forum.")

			if not need_login:
				messages = await forum.check_inbox()

				if not messages:
					need_login = True
					print("Connection lost in the forums.")

				else:
					for message in messages:
						if message["state"] == 2: # New message
							if message["title"].startswith("[V] tfm"):
								self.loop.create_task(
									forum.inbox_read(message["id"])
								)

								await self.proxy.sendTo(
									{
										"type": "verification",
										"username": message["author"],
										"token": message["title"][4:]
									},
									"discord"
								)

			await asyncio.sleep(60.0)

	async def give_discord_badge(self, player, discord_id, channel):
		"""Tries to give the discord verified badge."""
		file = await self.load_player_file(player)
		if file is None:
			return await self.send_channel(
				channel,
				"<@!{}>: Could not give your ingame badge. Try using the "
				"command `!badge` when you're online and in a parkour room."
				.format(discord_id)
			)

		file["badges"][4] = 1
		await self.save_player_file(
			player, file, "badges",
			online_check=False
		)
		await self.send_channel(
			channel,
			"<@!{}>: You've received your ingame badge!".format(discord_id)
		)