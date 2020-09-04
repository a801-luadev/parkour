import os
import transformice.parkour as parkour
import asyncio

if __name__ == '__main__':
	loop = asyncio.get_event_loop()

	bot = parkour.Client(auto_restart=True, bot_role=True, loop=loop)

	loop.create_task(bot.start())

	try:
		loop.run_forever()
	except KeyboardInterrupt:
		print("stopping")
		bot.close()
