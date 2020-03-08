import aiotfm
import asyncio

class Client(aiotfm.Client):
	async def restart(self, keys=None):
		"""Restarts the client.
		:param keys:"""
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

			await self.connect()
			await self.sendHandshake()
			await self.locale.load()
		except:
			asyncio.ensure_future(self.restart_soon(), loop=self.loop)