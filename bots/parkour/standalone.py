"""
Handles standalone requests
"""

import aiotfm


class StandaloneGateway(aiotfm.Client):
	async def handle_proxy_packet(self, client, packet):
		if await super().handle_proxy_packet(client, packet):
			return True

		if client != "tokens":
			return False

		if packet["type"] == "get_player_id":
			name = packet["name"]
			pid = await self.get_player_id(name)

			await self.proxy.sendTo({
				"type": "get_player_id",
				"name": name,
				"pid": pid
			}, client)

		elif packet["type"] == "get_reports":
			await self.proxy.sendTo({
				"type": "reports",
				"reports": self.reports
			}, client)

		elif packet["type"] == "get_chats":
			await self.proxy.sendTo({
				"type": "chats",
				"chats": {
					"mod": self.mod_chat.channel_name,
					"mapper": self.mapper_chat.channel_name
				}
			}, client)

		else:
			return False