"""
Handles sanctions (power removals, bans)
"""

from parkour.env import env
import aiotfm


class Sanctions(aiotfm.Client):
	async def on_whisper_command(self, whisper, author, ranks, cmd, args):
		if await super().on_whisper_command(
			whisper, author, ranks, cmd, args
		):
			return True

		if cmd == "ban" or cmd == "unban":
			await self.ban_request(whisper, author, ranks, cmd, args)

		elif cmd == "kill":
			await self.kill_request(whisper, author, ranks, cmd, args)

		else:
			return False
		return True

	async def ban_request(self, whisper, author, ranks, cmd, args):
		# Argument check
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

		pid, name, online = await self.get_player_info(args[0])
		if name is None:
			return await whisper.reply("Could not get information of the player.")

		propagation = "pdata" if online else "file"

		# Sanction
		if minutes == 0:
			await self.send_webhook(
				env.webhooks.sanctions,
				"**`[BANS]:`** `{}` has unbanned `{}` (ID: `{}`) ({})"
				.format(author, name, pid, propagation)
			)
		elif minutes == 1:
			await self.send_webhook(
				env.webhooks.sanctions,
				"**`[BANS]:`** `{}` has permbanned `{}` (ID: `{}`) ({})"
				.format(author, name, pid, propagation)
			)
		else:
			await self.send_webhook(
				env.webhooks.sanctions,
				"**`[BANS]:`** `{}` has banned `{}` (ID: `{}`) for `{}` minutes. ({})"
				.format(author, name, pid, minutes, propagation)
			)

			minutes *= 60 * 1000 # make it milliseconds
			minutes += self.tfm_time() # sync it with transformice

		if online:
			file = await self.load_player_file(name, online_check=False)

			if minutes == 1:
				file["banned"] = 2
			else:
				file["banned"] = minutes

			await self.save_player_file(
				name, file, "banned",
				online_check=False
			)

		else:
			await self.broadcast_module(
				3,
				"{}\x00{}\x00{}"
				.format(name, pid, minutes)
			)

		await whisper.reply("Action applied.")

	async def kill_request(self, whisper, author, ranks, cmd, args):
		# Argument check
		if not ranks["admin"] and not ranks["mod"] and not ranks["trainee"]:
			return

		if len(args) < 1 or (len(args) > 1 and not args[1].isdigit()):
			return await whisper.reply("Invalid syntax.")
		elif len(args) > 1:
			minutes = int(args[1])
		else:
			minutes = None

		pid, name, online = await self.get_player_info(args[0])
		if name is None:
			return await whisper.reply("Could not get information of the player.")
		if not online:
			return await whisper.reply("That player ({}) is not online.".format(name))

		file = await self.load_player_file(name, online_check=False)
		if file is None:
			await whisper.reply("Could not get sanction information of the player.")

		sanction = file["kill"]
		if sanction == 0:
			if minutes is None:
				await whisper.reply(
					"That player ({}) apparently doesn't have a previous sanction. "
					"Double check on discord and then type the minutes here."
					.format(name)
				)
				try:
					response = await self.wait_for(
						"on_whisper",
						lambda resp: resp.author == whisper.author and resp.content.isdigit(),
						timeout=120.0
					)
				except Exception:
					await whisper.reply("You took too long to provide a valid response.")
					return

				minutes = int(response.content)

		elif sanction >= 200:
			await whisper.reply(
				"That player ({}) has already reached 200 minutes ({}); "
				"next sanction is supposed to be a ban. Check in discord their sanction log."
				.format(name, sanction)
			)
			if minutes is None:
				return

			await whisper.reply(
				"Do you want to override the sanction and kill them for {} minutes anyway? "
				"Reply with yes or no."
				.format(minutes)
			)
			try:
				response = await self.wait_for(
					"on_whisper",
					lambda resp: resp.author == whisper.author and resp.content.lower() in ("yes", "no"),
					timeout=120.0
				)
			except Exception:
				await whisper.reply("You took too long to provide a valid response.")
				return

			if response.content.lower() == "no":
				await whisper.reply("Kill cancelled.")
				return

		else:
			next_sanction = sanction + 40
			if minutes is not None and next_sanction != minutes:
				await whisper.reply(
					"The next sanction for the player {} is supposed to be {} minutes. "
					"Do you want to override the sanction and kill them for {} minutes anyway? "
					"Reply with yes or no."
					.format(name, next_sanction, minutes)
				)

				try:
					response = await self.wait_for(
						"on_whisper",
						lambda resp: resp.author == whisper.author and resp.content.lower() in ("yes", "no"),
						timeout=120.0
					)
				except Exception:
					await whisper.reply("You took too long to provide a valid response.")
					return

				if response.content.lower() == "yes":
					next_sanction = minutes

			if next_sanction >= 200:
				await whisper.reply("Please warn them that their next sanction is a tempban.")

			minutes = next_sanction

		# Check if they're still online!
		pid, name, online = await self.get_player_info(name)
		if not online:
			await whisper.reply(
				"That player ({}) has disconnected.".format(name)
			)

		# Sanction
		await self.send_webhook(
			env.webhooks.sanctions,
			"**`[KILL]:`** `{}` has killed `{}` (ID: `{}`) for `{}` minutes. (previous sanction: `{}`)"
			.format(author, name, pid, minutes, sanction)
		)
		await self.broadcast_module(2, "{}\x00{}".format(name, minutes))
		await whisper.reply(
			"Killed {} for {} minutes (last kill: {})"
			.format(name, minutes, sanction)
		)
