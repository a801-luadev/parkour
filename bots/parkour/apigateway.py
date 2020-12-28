"""
Handles communication with the API gateway
"""

import aiotfm


class ApiGateway(aiotfm.Client):
	async def handle_proxy_packet(self, client, packet):
		if await super().handle_proxy_packet(client, packet):
			return True

		if client == "tokens":
			if packet["type"] == "get_player_id":
				name = packet["name"]
				pid = await self.get_player_id(normalize_name(name))

				await self.proxy.sendTo({
					"type": "get_player_id",
					"name": name,
					"pid": pid
				}, client)

			else:
				return False

		elif client == "api":
			if packet["type"] == "get_roles":
				player = packet["player"]

				ranks = []
				for rank, has in self.get_player_rank(player).items():
					if has:
						ranks.append(rank)

				await self.proxy.sendTo({
					"type": "get_roles",
					"player": player,
					"roles": ranks
				}, client)

			elif packet["type"] == "profile":
				query = packet["query"]
				pid, name, online = await self.get_player_info(query)

				response = {
					"type": "profile",
					"id": pid,
					"name": name
				}
				# We have to return a response with the exact query
				if isinstance(query, int):
					response["id"] = query
				else:
					response["name"] = query

				if name is None:
					response["profile"] = None
					await self.proxy.sendTo(response, client)
					return True

				ranks = []
				for rank, has in self.get_player_rank(name).items():
					if has:
						ranks.append(rank)

				response["profile"] = profile = {
					"roles": ranks,
					"online": online
				}

				if online:
					profile["file"] = file = await self.load_player_file(
						name, online_check=False
					)

					if file is not None:
						profile.update({
							"leaderboard": { # not implemented yet
								"overall": None,
								"weekly": None
							},
							"hour_r": file["hour_r"] // 1000 - self.time_diff
						})

				await self.proxy.sendTo(response, client)

			else:
				return False
		else:
			return False
		return True