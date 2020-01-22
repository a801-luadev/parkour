import os
import aiotfm
import asyncio

class Bot(aiotfm.Client):
	def __init__(self, api_id, api_token, name, password, cmd, module_name, *args, **kwargs):
		super().__init__(*args, **kwargs)

		self.api_id = api_id
		self.api_token = api_token
		self.name = name
		self.password = password
		self.cmd = cmd + " " + module_name
		self.init_room = "*#" + module_name
		self.on_complete_future = self.loop.create_future()

	async def start_running(self):
		print("Connecting")
		await self.start(self.api_id, self.api_token)

	async def on_login_ready(self, *args):
		print("Connected to transformice.")
		await self.login(self.name, self.password, encrypted=False, room=self.init_room)

	async def on_login_result(self, *args):
		self.on_complete_future.set_exception(Exception("Could not login.", *args))

	async def on_logged(self, *args):
		print("Logged in.")

	async def on_joined_room(self, room):
		print("Joined the room.")
		await asyncio.sleep(3.0)
		await self.host()

	async def host(self):
		print("Hosting the module.")
		with open("builds/latest.lua", "rb") as file:
			script = file.read()
		with open("builds/hosted.lua", "wb") as file:
			file.write(script)
		await self.loadLua(script)
		print("Loaded the script.")

		await asyncio.sleep(3.0)
		await self.sendCommand(self.cmd)
		print("Hosted the module.")
		await asyncio.sleep(3.0)
		self.on_complete_future.set_result(True)

if __name__ == '__main__':
	api_id = os.getenv("TRANSFROMAGE_ID")
	api_token = os.getenv("TRANSFROMAGE_TOKEN")
	if api_id is None or not api_id.isdigit():
		raise TypeError("TRANSFROMAGE_ID environment variable must exist and be a number.")
	if api_token is None:
		raise TypeError("TRANSFROMAGE_TOKEN environment variable must exist.")

	name = os.getenv("ATELIER_BOT_NAME")
	password = os.getenv("ATELIER_BOT_PASS")
	if name is None:
		raise TypeError("ATELIER_BOT_NAME environment variable must exist.")
	if password is None:
		raise TypeError("ATELIER_BOT_PASS environment variable must exist.")

	host_cmd = os.getenv("HOST_COMMAND")
	module_name = os.getenv("MODULE_NAME")
	if host_cmd is None:
		raise TypeError("HOST_COMMAND environment variable must exist.")
	if password is None:
		raise TypeError("MODULE_NAME environment variable must exist.")

	print("Starting the bot.")
	loop = asyncio.get_event_loop()
	bot = Bot(api_id, api_token, name, password, host_cmd, module_name, loop=loop)
	loop.run_until_complete(bot.start_running())
	print("Started.")
	loop.run_until_complete(bot.on_complete_future)
	bot.close()