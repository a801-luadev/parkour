"""
Extracts quantity of players in official modules
"""

import asyncio
import aiotfm
from aiotfm.room import DropdownRoomEntry


class RoomGraphs(aiotfm.Client):
	def __init__(self, *args, **kwargs):
		super().__init__(*args, **kwargs)

		self.loop.create_task(self.check_module_list())

	async def check_module_list(self):
		while not self.main.open:
			await asyncio.sleep(3.0)

		while self.main.open:
			await asyncio.sleep(900.0)

			rooms = await self.getRoomList(aiotfm.GameMode.MODULES)
			modules = {}

			if rooms is not None:
				for room in rooms.pinned_rooms:
					if isinstance(room, DropdownRoomEntry):
						for entry in room.entries:
							if entry.player_count > 0:
								modules[entry.name] = entry.player_count

			await self.proxy.sendTo({
				"type": "room_graph",
				"modules": modules
			}, "tocubot")