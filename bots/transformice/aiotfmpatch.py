import aiotfm
import asyncio
import random

class Client(aiotfm.Client):
	async def restart(self, *args, **kwargs):
		print("Restarting transformice bot", flush=True)

		return await super().restart(*args, **kwargs)