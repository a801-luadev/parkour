import os
import transformice.parkour as parkour
import asyncio

if __name__ == '__main__':
	loop = asyncio.get_event_loop()

	API_CREDENTIALS = (int(os.getenv("API_ID")), os.getenv("API_TOKEN"))
	bot = parkour.Client(auto_restart=True, loop=loop)

	loop.create_task(bot.start(*API_CREDENTIALS))

	try:
		loop.run_forever()
	except KeyboardInterrupt:
		print("stopping")
		bot.close()