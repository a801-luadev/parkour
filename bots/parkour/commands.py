"""
Handles a few commands
Dispatches according events when a command is received through whispers
"""

from parkour.env import env
from parkour.utils import normalize_name, shorten_name
import aiotfm
import time
import re


MODIFY_RANK = (4 << 8) + 255
ROOM_PASSWORD = (13 << 8) + 255


class Commands(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		self.next_available_restart = time.time() + 600.0

		super().__init__(*args, **kwargs)

	async def on_whisper(self, whisper):
		author = normalize_name(whisper.author)
		if author == "Parkour#8558":
			return

		if whisper.content[0] == ".":
			args = whisper.content.split(" ")
			cmd = args.pop(0).lower()[1:]
			ranks = self.get_player_rank(author)

			self.dispatch(
				"whisper_command",
				whisper, author, ranks, cmd, args
			)

	async def on_whisper_command(self, whisper, author, ranks, cmd, args):
		if await super().on_whisper_command(
			whisper, author, ranks, cmd, args
		):
			return True

		if cmd == "announce":
			# Sends an announcement to the server
			if not ranks["admin"] and not ranks["manager"]:
				return True
			if not args:
				await whisper.reply("Invalid syntax.")
				return True

			await self.broadcast_module(4, " ".join(args))
			await whisper.reply("Announced!")
			await self.send_webhook(
				env.webhooks.default,
				"**`[ANNOUNCEMENT]:`** **{}** announced `{}` to all the rooms"
				.format(author, " ".join(args))
			)

		elif cmd == "cannounce":
			# Sends an announcement to the specific community
			if not ranks["admin"] and not ranks["manager"]:
				return True
			if len(args) < 2:
				await whisper.reply("Invalid syntax.")
				return True

			commu = args.pop(0).lower()
			await self.broadcast_module(
				5,
				"{}\x00{}".format(commu, " ".join(args))
			)
			await whisper.reply("Announced!")
			await self.send_webhook(
				env.webhooks.default,
				"**`[ANNOUNCEMENT]:`** **{}** announced `{}` "
				"to the community {}"
				.format(author, " ".join(args), commu)
			)

		elif cmd == "pw":
			# Gets the password of a room
			if not ranks["admin"] and not ranks["manager"]:
				return True
			if not args:
				await whisper.reply("Invalid syntax.")
				return True

			room = " ".join(args)
			shortName = shorten_name(room)
			await self.broadcast_module(6, shortName)
			await whisper.reply("Requesting room password.")
			await self.send_webhook(
				env.webhooks.default,
				"**`[ROOMPW]:`** **{}** requested the password "
				"of the room `{}`."
				.format(author, room)
			)

			try:
				_, txt = await self.wait_for(
					"on_lua_textarea",
					lambda txt_id, txt: (
						txt_id == ROOM_PASSWORD
						and txt.startswith(shortName + "\x00")
					),
					timeout=60.0
				)
			except Exception:
				await whisper.reply(
					"Could not get the password of the room. Is it alive?"
				)
				return True

			data = txt.split("\x00")
			if len(data) == 3:
				await whisper.reply(
					"The room password has been set by {} and it is {}"
					.format(data[2], data[1])
				)
			else:
				await whisper.reply("The room does not have a password.")

		elif cmd == "update":
			# Sends an update to the game
			if not ranks["admin"]:
				return True
			if not args:
				await whisper.reply("Invalid syntax.")
				return True

			packet = {"type": "game_update"}
			if args[0].lower() == "now":
				packet["now"] = True

			elif len(args) < 2:
				await whisper.reply("Invalid syntax.")
				return True

			else:
				packet["now"] = False
				packet["load"] = args[1].lower() == "load"

			await self.proxy.sendTo(packet, "tocubot")
			await whisper.reply("Updating the game.")

		elif cmd == "rank":
			# Edits the ranks of a player
			if not ranks["admin"] and not ranks["manager"]:
				return True
			if len(args) < 3:
				await whisper.reply("Invalid syntax.")
				return True

			# Argument check
			action = args[0].lower()
			if action not in ("add", "rem"):
				await whisper.reply("Invalid action: '{}'.".format(action))
				return True

			rank = args[2].lower()
			if rank not in self.ranks:
				await whisper.reply("Invalid rank: '{}'.".format(rank))
				return True

			# Editing ranks
			player = normalize_name(args[1])
			packet = [player, None, rank]

			if action == "add":
				if player not in self.player_ranks:
					self.player_ranks[player] = self.ranks.copy()
				self.player_ranks[player][rank] = True

				webhook, action, preposition = "now", "Added", "to"
				packet[1] = "1"

			else:
				if player in self.player_ranks:
					self.player_ranks[player][rank] = False

				webhook, action, preposition = "no longer", "Removed", "from"
				packet[1] = "0"

			await self.send_callback(MODIFY_RANK, "\x00".join(packet))

			# Sending messages
			await self.send_webhook(
				env.webhooks.ranks,
				"**`[RANKS]:`** `{}` is {} a `parkour-{}` (changed by `{}`)"
				.format(player, webhook, rank, author)
			)
			await whisper.reply(
				"{} rank '{}' {} '{}'."
				.format(action, rank, preposition, player)
			)

		elif cmd == "whois":
			# Gives name and id of the player (either by name or id)
			if (not ranks["admin"]
				and not ranks["mod"]
				and not ranks["trainee"]):
				return
			if not args:
				return await whisper.reply("Invalid syntax.")

			pid, name, online = await self.get_player_info(args[0])
			if name is None:
				return await whisper.reply(
					"Could not get information of the player."
				)

			await whisper.reply(
				"Name: {}, ID: {}, online: {}".format(name, pid, online)
			)

		elif cmd == "reboot":
			# Reboots the bot
			if ranks["admin"]:
				pass
			elif not ranks["mod"] and not ranks["trainee"]:
				return True
			elif time.time() < self.next_available_restart:
				await whisper.reply(
					"You need to wait {} seconds to restart the bot. "
					"Call an admin otherwise."
					.format(round(self.next_available_restart - time.time()))
				)
				return True

			await self.send_webhook(
				env.webhooks.default,
				"**`[REBOOTS]:`** **{}** requested a parkour bot reboot."
				.format(author)
			)
			await whisper.reply("Rebooting.")
			await self.restart()

		elif cmd == "join":
			if (not ranks["admin"]
				and not ranks["mod"]
				and not ranks["trainee"]):
				return True
			if not args:
				await whisper.reply("Invalid syntax.")
				return True

			room = " ".join(args)
			await self.send_webhook(
				env.webhooks.join,
				"**`[JOIN]:`** `{}` requested to join `{}`."
				.format(author, room)
			)
			await self.handle_join_request(room, author)

		elif cmd == "whoami":
			total = 0
			ranks_list = []
			for rank, has in ranks.items():
				if has:
					total += 1
					ranks_list.append(rank)

			if total > 0:
				await whisper.reply(
					"You are {}. You have {} rank(s) and they are: {}."
					.format(author, total, ", ".join(ranks_list))
				)

		else:
			return False
		return True

	async def handle_proxy_packet(self, client, packet):
		if await super().handle_proxy_packet(client, packet):
			return True

		if client == "tocubot":
			if packet["type"] == "join":
				await self.handle_join_request(
					packet["room"], packet["channel"]
				)

			else:
				return False
		else:
			return False
		return True

	async def handle_join_request(self, room, channel):
		validity = re.match(r"^(?:[a-z]{2}-|\*)#parkour(?:$|[^a-zA-Z])", room)
		if validity is None:
			return await self.send_channel(
				channel,
				"The given room is invalid. You can only join #parkour rooms."
			)

		await self.broadcast_module(0, shorten_name(room))
		await self.send_channel(channel, "Room join request has been sent.")