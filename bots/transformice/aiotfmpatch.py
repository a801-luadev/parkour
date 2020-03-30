import aiotfm
import asyncio
import random

class Client(aiotfm.Client):
	async def connect(self):
		"""|coro|
		Creates a connection with the main server.
		"""

		for port in random.sample([13801, 11801, 12801, 14801], 4):
			try:
				await self.main.connect('94.23.193.229', port)
			except Exception:
				pass
			else:
				break
		else:
			raise aiotfm.errors.ServerUnreachable('Unable to connect to the server.')

		while not self.main.open:
			await asyncio.sleep(.1)
	
	async def restart(self, keys=None):
		"""Restarts the client.
		:param keys:"""
		print("Restarting transformice bot", flush=True)

		self.dispatch("restart")

		try:
			self.close()
		except:
			pass

		try:
			if keys is not None:
				self.keys = keys
			else:
				self.keys = keys = await get_keys(self.api_tfmid, self.api_token)

			self.main = aiotfm.Connection("main", self, self.loop)
			self.bulle = None
			await self.connect()
			await self.sendHandshake()
			await self.locale.load()
		except:
			asyncio.ensure_future(self.restart_soon(), loop=self.loop)
