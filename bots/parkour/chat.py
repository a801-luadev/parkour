"""
Handles staff chats
"""

from parkour.env import env
from parkour.utils import normalize_name
from aiotfm.enums import Game
import asyncio
import aiotfm
import string
import random
import re


CURRENT_CHAT = (9 << 8) + 255
NEW_CHAT = (10 << 8) + 255


class Channel:
	def __init__(self, name, ranks, announcement, chat):
		self.name = name
		self.ranks = ranks
		self.announcement_webhook = announcement
		self.chat_webhook = chat

		self.loaded = False
		self.channel_name = None
		self.channel = None
		self.players = []


class Chat(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		self.mod_chat = Channel(
			"mod", ("admin", "manager", "mod", "trainee"),
			env.webhooks.mod_chat_announcement, env.webhooks.mod_chat
		)
		self.mapper_chat = Channel(
			"mapper", ("admin", "manager", "mapper"),
			env.webhooks.mapper_chat_announcement, env.webhooks.mapper_chat
		)

		super().__init__(*args, **kwargs)

		self.loop.create_task(self.check_intruders())

	async def handle_proxy_packet(self, client, packet):
		if await super().handle_proxy_packet(client, packet):
			return True

		if client in ("discord", "tocubot"):
			if packet["type"] == "message":
				# If a client tries to send a message to a channel which is a
				# string, it is a whisper and this bot should handle it
				if isinstance(packet["channel"], str):
					if packet["channel"][0] == "#": # Parkour staff chat
						mod_chat = packet["channel"] == "#mod"
						chat = self.mod_chat if mod_chat else self.mapper_chat

						if chat.loaded:
							await chat.channel.send(packet["msg"])
					else:
						await self.whisper(packet["channel"], packet["msg"])

			elif packet["type"] == "mutecheck":
				# Checks if this bot is muted or not
				if "request" in packet:
					text = "".join(
						random.choice(string.ascii_letters + " ")
						for x in range(50)
					)
					await self.whisper("Tocutoeltuco#5522", text)

				elif not packet["alive"]:
					await self.client.restart()

			elif packet["type"] == "who_chat":
				# Request player list in a chat
				mod_chat = packet["chat"] == "mod"
				chat = self.mod_chat if mod_chat else self.mapper_chat

				if chat.loaded:
					players = chat.players
				else:
					players = ()

				await self.send_webhook(
					chat.chat_webhook,
					"/who: `{}`".format(
						"`, `".join(players or ("not loaded",))
					)
				)

			else:
				return False
		else:
			return False
		return True

	async def handle_module_packet(self, tid, packet):
		if await super().handle_module_packet(tid, packet):
			return True

		if tid == CURRENT_CHAT:
			# sets the chat name
			chat, name = packet.split("\x00", 1)

			chat = self.mod_chat if chat == "mod" else self.mapper_chat

			if chat.channel_name == name:
				return

			if chat.loaded:
				await chat.channel.leave()

			chat.loaded = False
			chat.channel_name = name
			await asyncio.sleep(5.0)
			await self.joinChannel(name, permanent=False)

		else:
			return False
		return True

	async def on_whisper_command(self, whisper, author, ranks, cmd, args):
		if cmd in ("modchat", "mapperchat"):
			# Get current mod or mapper chat
			chat = self.mod_chat if cmd == "modchat" else self.mapper_chat

			for rank in chat.ranks:
				if ranks[rank]:
					break
			else:
				return True

			if not chat.loaded:
				await whisper.reply("Could not connect to the chat.")
			else:
				await whisper.reply(
					"The current chat is {}".format(chat.channel_name)
				)

		elif cmd == "newchat":
			# Generate new chat
			if not ranks["admin"] and not ranks["manager"]:
				return True

			if not args:
				await whisper.reply("Invalid syntax.")
				return True

			desired = args[0].lower()
			if desired not in ("mod", "mapper"):
				await whisper.reply("Invalid chat.")
				return True

			await self.generate_new_chat(
				self.mod_chat if desired == "mod" else self.mapper_chat
			)

		else:
			return False
		return True

	async def on_friend_update(self, old, new):
		if (old.isConnected and new.isConnected
			and old.isAddedBack and not new.isAddedBack
			and old.game == new.game == Game.INVALID):
			# Transformice community platform has a weird functionality.
			# This condition checks for players that didn't add Parkour#8558
			# to their friendlist, but they just connected.
			self.dispatch("friend_connected", new)

	async def on_friend_connected(self, friend):
		if friend.isSoulmate:
			return
		name = normalize_name(friend.name)

		# Check which chats this player should be in
		ranks = self.get_player_rank(name)
		chats = []

		for chat in (self.mod_chat, self.mapper_chat):
			for rank in chat.ranks:
				if ranks[rank]:
					break
			else:
				continue

			chats.append(chat)

		# Wait for the chats to loop and update their players/members
		while chats:
			updated = await self.wait_for("on_chat_loop")

			for chat in updated:
				if chat in chats:
					chats.remove(chat)

					if name not in chat.players:
						await self.whisper(
							name,
							"Please join the {} chat: /chat {}"
							.format(chat.name, chat.channel_name)
						)

	async def on_channel_joined(self, channel):
		for chat in (self.mod_chat, self.mapper_chat):
			if chat.channel_name == channel.name:
				chat.channel = channel
				chat.loaded = True
				break

	async def on_channel_message(self, msg):
		# send the message to discord
		for chat in (self.mod_chat, self.mapper_chat):
			if msg.channel != chat.channel:
				continue

			content = re.sub(
				r"`(https?://(?:-\.)?(?:[^\s/?\.#-]+\.?)+(?:/[^\s]*)?)`",
				r"\1",

				"`" + msg.content.replace("`", "'")
				.replace("&lt;", "<")
				.replace("&amp;", "&")
				.replace(" ", "` `") + "`"
			)
			author = normalize_name(msg.author)

			await self.send_webhook(
				chat.chat_webhook,
				"`[{}]` `[{}]` {}".format(
					msg.community.name, author, content
				)
			)

			if author != "Parkour#8558" and msg.content[0] == ".":
				args = msg.content.split(" ")
				cmd = args.pop(0).lower()[1:]
				ranks = self.get_player_rank(author)

				self.dispatch(
					"channel_command",
					msg.channel, chat.name, author, ranks, cmd, args
				)

			break

	async def generate_new_chat(self, chat):
		name = "".join(random.choice(string.ascii_letters) for x in range(10))

		await self.send_webhook(
			chat.announcement_webhook,
			"@everyone There's a new {} chat: `{}`".format(chat.name, name)
		)
		await self.send_webhook(chat.chat_webhook, "Switching chats.")

		if chat.loaded:
			await chat.channel.send(
				"There's a new chat. It's been posted in discord. "
				"Please leave this one as soon as possible."
			)

		await self.send_callback(NEW_CHAT, chat.name + "\x00" + name)

	async def check_intruders(self):
		while not self.main.open:
			await asyncio.sleep(3.0)

		while self.main.open:
			await asyncio.sleep(15.0)

			updated = []
			for chat in (self.mod_chat, self.mapper_chat):
				if not chat.loaded:
					continue

				try:
					players = await chat.channel.who()
				except Exception: # timeout
					continue

				chat.players = []
				updated.append(chat)

				for player in players:
					player = normalize_name(player.username)
					chat.players.append(player) # append normalized names
					if player == "Parkour#8558":
						continue

					ranks = self.get_player_rank(player)
					for rank in chat.ranks:
						if ranks[rank]:
							break
					else:
						# intruder!
						await chat.channel.send(
							"Intruder alert: {}".format(player)
						)
						await asyncio.sleep(3.0)
						await self.generate_new_chat(chat)

			self.dispatch("chat_loop", updated)