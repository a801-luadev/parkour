from urllib.parse import urlencode
from proxy_connector import Connection
import discord
import aiohttp
import re
import traceback
import os
import time
import asyncio
import sys
import io
import random
import string


class env:
	proxy_token = os.getenv("PROXY_TOKEN")
	proxy_ip = os.getenv("PROXY_IP")
	proxy_port = os.getenv("PROXY_PORT")

	token = os.getenv("DISCORD_TOKEN")

	guild_id = 669593764305829898
	tocu_id = 212634414021214209

	public_commands = 726716371018186802

	commands_channel = 694270110172446781
	private_channel = 686932761222578201
	lua_logs = 686933785933381680
	lua_unloads = 688784734813421579

	role_channel = 683847523558883446

	game_logs_channel = 681571711849594897

	whois_channel = 707358868090519632

	mod_chat = 711955597100056628
	mapper_chat = 722189771631231029

	map_perm_chat = 703701422910472192
	map_info_chat = 723583447976771595

	verifications_category = 752189155798286427
	verified_role = 694947893433466981


verification_messages = (
	(
		# EN
		"🇬🇧 Welcome to the official Parkour Discord! To gain access, "
		"you have to verify your Transformice account. "
		"__At the end of this message you'll find a text with a black background and a blue text.__\n"

		"**If you're online in Transformice**, you can copy the text with the black background "
		"and whisper `Parkour#8558` with that text.\n"

		"**If you're not online**, you can click the blue text and it will take you to the forum. "
		"It will show a blue button which says **Submit**, you have to click it!\n\n"

		# ES
		"🇪🇸 ¡Bienvenido al Discord oficial de Parkour! Para obtener acceso, "
		"debes verificar tu cuenta de Transformice. "
		"__Al final de este mensaje encontrarás un texto con fondo negro y un texto azul.__\n"

		"**Si estás conectado en Transformice**, podés copiar el texto con fondo negro "
		"y susurrar a `Parkour#8558` con ese texto.\n"

		"**Si no estás conectado**, podés hacer click en el texto azul y te llevará al foro. "
		"Te va a mostrar un botón azul el cual dice **Aceptar**, ¡debes hacerle click!\n\n"

		# BR
		"🇧🇷 Bem-vindo ao Discord oficial do Parkour! Para ter acesso, "
		"você deve verificar sua conta do Transformice. "

		"__Ao fim desta mensagem você irá encontrar um texto de cor azul com um fundo preto.__\n"
		"**Se você está online no Transformice**, você poderá copiar o texto de fundo preto "
		"e o cochichar para a conta `Parkour#8558`.\n"

		"**Se você não está online**, clique no texto de cor azul e você será redirecionado ao fórum. "
		"Haverá um botão azul escrito **Validar**, clique nele!\n\n"

		# FR
		"🇫🇷 Bienvenue sur le Discord officiel de Parkour ! Pour obtenir l'accès, "
		"vous devez vérifier votre compte Transformice. "
		"__À la fin de ce message, vous trouverez un texte avec un fond noir et un autre en bleu.__\n"

		"**Si vous êtes connecté sur Transformice**, copiez le texte avec le fond noir "
		"et envoyez-le à `Parkour#8558` par chuchotement.\n"

		"**Si vous n'êtes pas connecté**, vous pouvez cliquer sur le texte bleu et il "
		"vous amènera sur le forum. "
		"Cela vous affichera un bouton bleu **Envoyer**. Cliquez dessus pour vérifier votre compte !"
	),
	(
		# HU
		"🇭🇺 Üdvözlünk a Parkour hivatalos Discord szerverén! A hozzáféréshez igazolnod "
		"kell a Transformice felhasználódat. "
		"__Ennek az üzenetnek a végén egy fekete háttérrel ellátott szöveg és egy "
		"kék szöveg található.__\n"

		"**Ha online vagy a Transformice-on**, akkor másold ki a fekete háttérrel ellátott "
		"szöveget és ezt írd meg suttogásban `Parkour#8558`-nak.\n"

		"**Ha nem vagy online**, akkor kattints a kék szövegre, ezzel eljutsz a fórumra. "
		"Meg fog jelenni egy kék gomb **Küldés** felírattal, arra kell kattintanod!\n\n"

		# ID
		"🇮🇩 Selamat datang di Discord resmi Parkour! Untuk mendapatkan akses, "
		"kamu harus melakukan verifikasi akun Transformice kamu. "
		"__Di akhir teks ini, kamu akan melihat sebuah teks dengan dengan warna "
		"latar hitam dan sebuah teks biru.__\n"

		"**Jika kamu online di Transformice**, kamu bisa menyalin text dengan "
		"latar hitam dan bisik `Parkour#8558` dengan teks tersebut.\n"

		"**Jika kamu tidak online**, kamu bisa klik teks bewarna biru dan kamu akan diarahkan ke forum. "
		"Itu akan menampilkan sebuah tombol biru dimana terdapat **Submit**, kamu harus mengkliknya!\n\n"

		# RU
		"🇷🇺 Добро пожаловать на официальный форум Паркура в Discord! Чтобы получить доступ, "
		"вы должны подтвердить свою учетную запись Transformice. "
		"__В конце этого сообщения вы найдете текст с черным фоном и синим текстом.__\n"

		"**Если вы подключены к Transformice**, вы можете скопировать текст с "
		"черным фоном и прошептать ему `Parkour#8558`.\n"

		"**Если вы не в сети**, вы можете щелкнуть синий текст, и вы попадете на форум. "
		"Появится синяя кнопка с надписью **Отправить**, вы должны ее нажать!\n\n"

		# TR
		"🇹🇷 Resmi Parkour Discord'una hoş geldiniz! Erişim elde etmek için "
		"Transformice hesabınızı doğrulamanız gerekir. "
		"__Bu mesajın sonunda siyah arka planlı ve mavi yazılı bir metin bulacaksınız.__\n"

		"**Transformice'de çevrimiçiyseniz**, Siyah arka planlı metni kopyalayarak "
		"bu metini `Parkour#8558`a gönderebilirsiniz.\n"

		"**Çevrimiçi değilseniz**, Mavi metne tıklayarak foruma gittikten "
		"sonra **Gönder** yazan mavi düğmeye tıklamalısınız!"
	),
	(
		# PL
		"🇵🇱 Witamy na oficjalnym Discordzie Parkour!  Aby uzyskać dostęp, "
		"musisz zweryfikować swoje konto Transformice. "
		"__Na końcu tej wiadomości znajdziesz tekst z czarnym tłem i niebieskim tekstem.__\n"

		"**Jeśli jesteś online w Transformice**, możesz skopiować tekst z "
		"czarnym tłem i szeptać `Parkour#8558` z tym tekstem.\n"

		"**Jeśli nie jesteś dostępny**, możesz kliknąć niebieski tekst i "
		"przeniesie Cię na forum.  Pokaże się niebieski przycisk, który mówi "
		"**Zatwierdź**, musisz to kliknąć!\n\n"

		# CN
		"🇨🇳 歡迎來到官方 Parkour Discord 伺服器! 你需要認證你的 Transformice 帳戶來取得伺服權限。"
		"__你會在這則訊息的末端找到一段黑色背景的文字跟藍色的文字。__\n"

		"**如果你 Transformice 在線**, 你可以複製那段黑色背景的文字然後私聊 `Parkour#8558`。\n"

		"**如果你並不在線**, 你可以點擊藍色的文字而它將會連結到論壇上。它會展示一個寫著 **提交** 的藍色按鈕, 點擊它就好!"
	),
	(
		# RTL languages

		# HE
		"ברוכים הבאים לשרת הדיסקורד הרשמי של Parkour! כדי להשיג גישה, ע"
		"ליכם לאמת את משתמש ה-Transformice שלכם.\n"
		"__לאחר מכן, אתם תראו טקסט בצבע כחול עם רקע שחור.__\n"
		"**אם אתם מחוברים ל-Transformice**, אתם יכולים להעתיק את הטקסט עם הרקע"
		" השחור וללחוש ל-Parkour#8558 את הטקסט הזה.\n"
		"**אם אינכם מחוברים ל-Transformice**, אתם יכולים ללחוץ על הטקסט הכחול וזה יקח אתכם אל הפורום.\n"
		"זה יראה לכם כפתור כחול שאומר **אשר**, עליכם ללחוץ עליו!"
	)
)

scripts = {
	"copyfile": 752932696782667877,
	"migrate": 752932834607628348
}

categories = {
	0: "Normal",
	1: "Locked",
	3: "Bootcamp",
	4: "Shaman",
	5: "Art",
	6: "Mechanism",
	7: "No Shaman",
	8: "Double Shaman",
	9: "Miscellaneous",
	10: "Survivor",
	11: "Vampire Survivor",
	13: "Generic Bootcamp",
	17: "Racing",
	18: "Defilante",
	19: "Music",
	20: "Survivor (out of rotation)",
	21: "Vampire (out of rotation)",
	22: "Tribe House",
	23: "Bootcamp (out of rotation)",
	32: "Double Shaman (out of rotation)",
	34: "Double Shaman Survivor (out of rotation)",
	38: "Racing (out of rotation)",
	41: "Module",
	42: "No Shaman (out of rotation)",
	43: "High Deleted",
	44: "Deleted",
	87: "Vanilla"
}


def normalize_name(self, name):
	"""Normalizes a transformice nickname."""
	if name[0] == "+":
		name = "+" + (name[1:].capitalize())
	else:
		name = name.capitalize()
	if "#" not in name:
		name += "#0000"
	return name


class Proxy(Connection):
	def __init__(self, client, *args, **kwargs):
		self.client = client
		super().__init__(*args, **kwargs)

	async def connection_lost(self):
		await self.client.restart()

	async def received_proxy(self, client, packet):
		loop = self.client.loop

		if packet["type"] == "busy":
			# Shares the busy state between all the bots that need it
			self.client.busy = packet["state"]

		elif packet["type"] == "game_update":
			# Sends update message
			self.client.dispatch("game_update")

		elif packet["type"] == "message":
			# If a client tries to send a message to a channel which is an int and is
			# greatear than 10, it's a channel id
			if isinstance(packet["channel"], int) and packet["channel"] > 10:
				loop.create_task(self.client.send_channel(packet["channel"], packet["msg"]))

		elif packet["type"] == "whois":
			# When Parkour bot asks who is someone, we send the request to other bot
			loop.create_task(self.client.send_channel(env.whois_channel, packet["user"]))

		elif packet["type"] == "map_info":
			# Map info response
			self.client.dispatch("map_info", packet["author"], packet["code"], packet["perm"], packet["xml"])

		elif packet["type"] == "exec":
			# Executes arbitrary code in this bot
			loop.create_task(self.client.load_script(packet["script"], packet["channel"]))

		elif packet["type"] == "verification":
			# Checks if the player sent a valid token and verifies
			loop.create_task(self.client.check_token(packet["username"], packet["token"]))


class Client(discord.Client):
	verifications = None

	async def on_ready(self):
		self.proxy = Proxy(self, env.proxy_token, "discord")
		await self.proxy.connect(env.proxy_ip, env.proxy_port)

		async with aiohttp.ClientSession() as session:
			async with session.get(
				"https://raw.githubusercontent.com/a801-luadev/parkour/master/tech/json/init.lua"
			) as resp:
				self.json_script = await resp.read()

		self.loop.create_task(self.check_reaction_roles())
		self.loop.create_task(self.check_verifications())

		await self.get_channel(env.private_channel).send("Ready!")
		print("Ready!")

	async def set_busy(self, busy=True, channel=None):
		"""Sets the busy state and sends a message to the channel if needed.
		Returns True if the state could be set, False otherwise"""
		if busy:
			if self.busy:
				await self.send_channel(channel, "The bot is busy right now. Try again later.")
				return False
			self.busy = True

		else:
			self.busy = False

		await self.proxy.sendTo({"type": "busy", "state": busy})
		return True

	async def restart(self):
		# Restarts the process.
		required_time = self.next_bot_restart - time.time()
		if required_time > 0:
			await asyncio.sleep(required_time)

		os.execl(sys.executable, sys.executable, *sys.argv)

	async def on_game_update(self):
		await self.send_channel(env.game_logs_channel, "`[UPDATE]:` The game is updating.")

	async def load_script(self, script, channel):
		try:
			exec(b"async def evaluate(self):\n\t" + (script.replace(b"\n", b"\n\t")))
		except Exception:
			return self.send_channel(channel, "Syntax error: ```python\n" + traceback.format_exc() + "```")

		try:
			await locals()["evaluate"](self)
		except Exception:
			return await self.send_channel(
				channel, "Runtime error: ```python\n" + traceback.format_exc() + "```"
			)

		return await self.send_channel(channel, "Script ran successfully.")

	# Chat system
	async def send_channel(self, channel, msg):
		"""Sends a message to the specified channel (discord, whisper or staff chat)"""
		if not channel:
			return

		if isinstance(channel, str):
			await self.proxy.sendTo({"type": "message", "channel": channel, "msg": msg}, "parkour")
			return

		elif isinstance(channel, int): # We can receive a Channel instance
			if channel <= 10:
				await self.proxy.sendTo({"type": "message", "channel": channel, "msg": msg}, "tocubot")
				return

			channel = self.get_channel(channel)

		if channel is not None:
			await channel.send(msg)

	async def on_message(self, msg):
		args = msg.content.split(" ")
		cmd = args.pop(0).lower()

		if msg.author.id == self.user.id:
			return

		elif msg.channel.id == env.role_channel:
			await self.check_reaction_roles_msg(msg)

		elif msg.channel.id == env.whois_channel:
			# The other bot answered our whois response
			if " " not in msg.content:
				name, id = msg.content.split(" ")
				id = int(id)
			else:
				name, id = msg.content, None
			await self.proxy.sendTo({"type": "whois", "user": name, "id": id}, "parkour")

			await msg.delete()

		elif msg.channel.id in (env.mod_chat, env.mapper_chat):
			# Message prefixes
			if msg.content.startswith("!m "):
				content = msg.content[3:]
			elif msg.content.startswith(","):
				content = msg.content[1:]
			else:
				return

			# Format the content
			content = "[{}] {}".format(msg.author.display_name.split(" ")[0], content)

			# Can't send custom emojis ingame! Send the name instead.
			content = re.sub(r"<a?:([^:]+):\d+>", r":\1:", content)

			# Replace all the mentions with their names
			for mention_char, display_char, mention_list, name_attr in (
				("@", "@", msg.mentions, "display_name"), # User mention
				("@!", "@", msg.mentions, "display_name"), # User mention
				("@&", "@", msg.role_mentions, "name"), # Role mention
				("#", "#", msg.channel_mentions, "name") # Channel mention
			):
				for obj in mention_list:
					content = content.replace(
						"<{}{}>".format(mention_char, obj.id),
						"{}{}".format(display_char, getattr(obj, name_attr))
					)

			if len(content) > 255:
				# The message ended up being too long...
				return await msg.channel.send("The message is too long.")

			if msg.channel.id == env.mod_chat:
				channel = "#mod"
			else:
				channel = "#mapper"

			await self.proxy.sendTo({"type": "message", "channel": channel, "msg": content}, "parkour")

		elif msg.channel.id == env.map_perm_chat:
			if msg.author.id == env.tocu_id:
				available_perms = (20, 21, 22, 32, 34, 41, 42)
			else:
				available_perms = (22, 41, 42)

			if cmd == "!rot":
				# Argument check
				if len(args) < 3:
					return await msg.channel.send("Invalid syntax.")

				if "high" != args[0] != "low":
					return await msg.channel.send("Invalid syntax.")

				if "add" != args[1] != "rem":
					return await msg.channel.send("Invalid syntax.")

				maps = []
				for code in args[2:]:
					if code[0] == "@":
						code = code[1:]

					if not code.isdigit():
						return await msg.channel.send("The argument `{}` is not a valid map code.".format(code))
					maps.append(code)

				if not await self.set_busy(True, msg.channel):
					return

				# Sends the modification to Tocubot
				await self.proxy.sendTo(
					{
						"type": "rot_change",
						"maps": maps,
						"rotation": args[0],
						"action": args[1],
						"channel": msg.channel.id
					},
					"tocubot"
				)
				return

			for perm in available_perms:
				if cmd == "!p{}".format(perm): # if it is a perm command
					# argument check
					if len(args) < 1:
						return await msg.channel.send("Invalid syntax.")

					code = args[0]
					if code[0] != "@":
						code = "@" + code
					if not code[1:].isdigit():
						return await msg.channel.send("Invalid syntax.")

					# sends the request to tocubot
					await self.proxy.sendTo(
						{"type": "perm", "map": code, "perm": perm, "channel": msg.channel.id},
						"tocubot"
					)
					return

		elif msg.channel.id == env.map_info_chat:
			if cmd in ("!info", "!render", "!map"):
				# argument check
				if not args:
					return await msg.channel.send("Invalid syntax.")

				code = args[0]
				if code[0] != "@":
					code = "@" + code
				if not code[1:].isdigit():
					return await msg.channel.send("Invalid syntax.")

				if not await self.set_busy(True, msg.channel):
					return

				# get map info
				await self.proxy.sendTo({"type": "map_info", "map": code})
				try:
					author, code, perm, xml = await self.wait_for("map_info", timeout=5.0)
				except Exception:
					author = None

				if author is None:
					await msg.channel.send("The map does not exist or can't be loded.")
					await self.set_busy(False)
					return

				# try to draw it if needed
				file_format = "xml"
				file_content = xml
				if cmd in ("!render", "!map"):
					try:
						async with aiohttp.ClientSession(conn_timeout=15.0, read_timeout=15.0) as session:
							async with session.post(
								"https://xml-drawer.herokuapp.com/",
								headers={"Content-Type": "application/x-www-form-urlencoded"},
								data=urlencode({"xml": xml}).encode()
							) as resp:
								file_content = await resp.read()
						file_format = "png"
					except Exception:
						await msg.channel.send("Could not render the map. Here is the XML instead.")

				# send the result
				await msg.channel.send(
					content=msg.author.mention,
					embed=discord.Embed(
						description="`[{}]` - **P{}**\n{} - **{}**"
						.format(
							categories.get(perm, "Unknown"),
							perm, code, author
						)
					),
					file=discord.File(
						filename="{}.{}".format(code, file_format),
						fp=io.BytesIO(file_content)
					)
				)

				await self.set_busy(False)

		elif msg.channel.id in (env.commands_channel, env.private_channel):
			if cmd == "!restart":
				# Room restart request
				await self.proxy.sendTo(
					{"type": "restart", "room": " ".join(args), "channel": msg.channel.id},
					"tocubot"
				)
				return

			if msg.channel.id != env.private_channel:
				return

			if cmd == "!busy":
				# Sets busy state (or checks it)
				if not args:
					if self.busy:
						await msg.channel.send("The bot is busy.")
					else:
						await msg.channel.send("The bot is free.")
					return

				if args[0] == "y":
					if not await self.set_busy(True):
						await msg.channel.send("Could not set busy state to true: the bot is already busy.")
					else:
						await msg.channel.send("Set busy state to true.")
					return

				elif args[0] == "n":
					await self.set_busy(False)
					await msg.channel.send("Set busy state to false.")
					return

				await msg.channel.send(
					"Unknown value: **{}**. Has to be either **y** or **n**.".format(args[0])
				)

			elif cmd == "!cmd":
				# Executes a command in tocubot
				await self.proxy.sendTo({"type": "command", "command": " ".join(args)}, "tocubot")
				await msg.channel.send("Done.")

			elif cmd == "!update":
				# Sends an update to the game
				if not args:
					return await msg.channel.send("Invalid syntax.")

				if args[0] == "now":
					await self.proxy.sendTo({"type": "game_update", "now": True}, "tocubot")

				elif len(args) < 2:
					return await msg.channel.send("Invalid syntax.")

				elif args[1] == "load":
					await self.proxy.sendTo({"type": "game_update", "now": False, "load": True}, "tocubot")

				await msg.channel.send("Updating the game.")

			elif cmd == "!exec":
				# Executes a custom script
				if len(args) < 2:
					return await msg.channel.send("Invalid syntax.")

				await self.execute_code(msg.channel, args)

			elif cmd == "!reboot":
				# Reboots all the bots
				await msg.channel.send("Sending reboot order to all the bots.")
				await self.proxy.send({"type": "reboot"})

			elif cmd == "!script":
				# Loads a script from a premade one.
				if not args:
					return await msg.channel.send("Invalid syntax.")

				if args[0] not in scripts:
					return await msg.channel.send(
						"Invalid script: **{}**. Valid ones: {}.".format(args[0], ", ".join(scripts.keys()))
					)

				message = await msg.channel.fetch_message(scripts[args[0]])
				content = message.content.format(*args[1:])
				await self.execute_code(msg.channel, content.split(" "))

		elif msg.channel.id == env.public_commands:
			if cmd == "!badge":
				# request verified badge
				await self.proxy.sendTo(
					{
						"type": "give_badge",
						"player": msg.author.display_name.split(" ")[0],
						"discord": msg.author.id,
						"channel": msg.channel.id
					},
					"parkour"
				)

	async def execute_code(self, channel, args):
		# Selects an environment
		env = args.pop(0)
		environments = ("discord", "tocubot", "parkour", "proxy", "tfm")
		if env not in environments:
			await channel.send(
				"Invalid environment: **{}**, valid ones: {}.".format(env, environments.join(", "))
			)
			return

		# If it is tfm, we need to mark the bot as busy
		if env == "tfm" and not await self.set_busy(True, channel):
			return

		# If the first arg is `json`, it will append the json script at the start if it is gonna run in
		# tfm.
		# If we provide a script, the bot has to access the page treat the content as the script.
		if args[0].startswith("http") or (args[0] == "json" and args[1].startswith("http")):
			if args[0] == "json":
				link = args[1]
			else:
				link = args[0]

			async with aiohttp.ClientSession() as session:
				async with session.get(link) as resp:
					script = await resp.read()

		# If we don't provide a link, we need to check for the script in the message
		else:
			script = re.match(r"(`{1,3})(?:lua\n|python\n)?((?:.|\n)+)\1", " ".join(args))
			if script is None:
				return await channel.send("Can't match your script.")
			script = script.group(2)

		if env == "tfm":
			# Append json script
			if len(args) > 1 and args[0] == "json":
				script = self.json_script + "\n" + script

			await self.proxy.sendTo({"type": "lua", "script": script}, "tocubot")
			await asyncio.sleep(3.0)
			await self.set_busy(False)

		elif env == "proxy":
			await self.proxy.send({"type": "exec", "script": script, "channel": channel.id})

		else:
			await self.proxy.sendTo({"type": "exec", "script": script, "channel": channel.id}, env)

	# Reaction roles
	async def check_reaction_roles_msg(self, msg):
		"""Reacts with all the needed emojis in the specific message"""
		for line in msg.content.split("\n"):
			if " ~> " in line:
				emoji = line.split(" ")[0]
				await msg.add_reaction(emoji)

	async def check_reaction_roles(self):
		"""Reacts with all the needed emojis in the messages that give roles by reaction."""
		channel = self.get_channel(env.role_channel)

		async for message in channel.history():
			await self.check_reaction_roles_msg(message)

	async def on_raw_message_edit(self, payload):
		"""When a message is edited in the role reaction channel, we need to add the new reaction!"""
		if payload.channel_id == env.role_channel:
			await self.check_reaction_roles_msg(
				await self.get_channel(payload.channel_id).fetch_message(payload.message_id)
			)

	async def get_reaction_role(self, payload):
		"""Receives a discord payload that gets triggered when someone adds a reaction or removes it.

		This function checks if the reaction corresponds to a reaction role message.

		Returns the Member instance of who reacted, and if they have the specific role,
		a Role instance too. If they don't have it, it gives an int representing the role id.

		Returns a tuple of two None if the user is a bot or the reaction is invalid."""
		if payload.channel_id != self.role_reaction_channel:
			return None, None

		guild = self.get_guild(payload.guild_id)
		member = await guild.fetch_member(payload.user_id)

		if member.bot:
			return None, None

		channel = guild.get_channel(payload.channel_id)
		message = await channel.fetch_message(payload.message_id)

		emoji = str(payload.emoji)

		for line in message.content.split("\n"):
			if line.startswith(emoji):
				role_id = int(line.split(" ")[2][3:-1])

				for role in member.roles:
					if role.id == role_id:
						return member, role
				else:
					return member, role_id

		return None, None

	async def on_raw_reaction_add(self, payload):
		member, role = await self.get_reaction_role(payload)

		if isinstance(role, int):
			await member.add_roles(discord.Object(role), atomic=True)

	async def on_raw_reaction_remove(self, payload):
		member, role = await self.get_reaction_role(payload)

		if isinstance(role, discord.Role):
			await member.remove_roles(role, atomic=True)

	# Verification system
	async def check_verifications(self):
		"""Fetch all the tokens from discord"""
		self.verifications = []
		deleting = []

		for channel in self.get_channel(env.verifications_category).text_channels:
			async for message in channel.history(limit=1, oldest_first=False):
				# Last message
				if message.author.id != self.user.id:
					continue

				token = re.search(r"`([^`]+)`", message.content)
				if token is not None:
					token = token.group(1)
					break
			else:
				continue

			async for message in channel.history(limit=100, oldest_first=True):
				# First message
				if message.author.id != self.user.id:
					continue

				user = re.search(r"<@!(\d+)>", message.content)
				if user is not None:
					user = int(user.group(1))
					break
			else:
				continue

			for member in channel.members:
				if member.id == user:
					# If the user is still in the channel the token is still valid
					self.verifications.append((token, user, channel.id))
					break
			else:
				# If the user is not in the channel, the token is invalid
				# and the channel can be deleted
				deleting.append(channel)

		for channel in deleting:
			await channel.delete()

	async def on_member_join(self, member):
		if member.guild.id != env.guild_id:
			return

		# Creates a verification channel when a member joins
		channel = await member.guild.create_text_channel(
			member.name,
			overwrites={
				member.guild.get_role(env.verified_role): discord.PermissionOverwrite(read_messages=False),
				member: discord.PermissionOverwrite(read_messages=True)
			},
			category=self.get_channel(env.verifications_category)
		)

		for index, msg in enumerate(verification_messages):
			if index == 0:
				msg = "<@!{}>:\n{}".format(member.id, msg)
			await channel.send(msg)

		token = "tfm" + ("".join(random.choice(string.ascii_letters + "._-") for x in range(50)))
		link = (
			"https://atelier801.com/new-dialog"
			"?destinataire=Parkour%238558"
			"&subject=%5BV%5D%20{}"
			"&message=Verification"
		).format(token)
		await channel.send("`{}`\n{}".format(token, link))

		self.verifications.append((token, member.id, channel.id))

	async def on_member_leave(self, member):
		if member.guild.id != env.guild_id:
			return

		# Deletes the verification channel of the member if there is any
		for index, data in enumerate(self.verifications):
			if data[1] == member.id:
				await self.get_channel(data[2]).delete()
				del self.verifications[index]
				break

	async def check_token(self, player, token):
		"""Checks if a token is valid, and if so, verifies the player"""
		player = normalize_name(player)

		guild = self.get_guild(env.guild_id)
		for member in await guild.query_members(player, cache=False):
			if member.nick.startswith(player):
				# Player already verified
				return

		for index, data in enumerate(self.verifications):
			if data[0] == token:
				# Give verified role and change nickname
				member = await guild.fetch_member(data[1])
				await member.edit(
					nick=player,
					roles=[guild.get_role(env.verified_role)]
				)

				# Delete channel and token
				await self.get_channel(data[2]).delete()
				del self.verifications[index]

				# Try to give the verified badge ingame
				await self.proxy.sendTo(
					{
						"type": "give_badge",
						"player": player,
						"discord": member.id,
						"channel": env.public_commands
					},
					"parkour"
				)

				break


if __name__ == '__main__':
	loop = asyncio.get_event_loop()

	bot = Client(
		max_messages=None,
		fetch_offline_members=False,
		loop=loop
	)
	loop.create_task(bot.start(env.token))

	try:
		loop.run_forever()
	except KeyboardInterrupt:
		print(end="\r") # remove ^C
		print("stopping")
		loop.run_until_complete(bot.close())