import os
import transformice.mapper as mapper

def setup(loop):
	API_CREDENTIALS = (int(os.getenv("API_ID")), os.getenv("API_TOKEN"))

	mapper_bot = mapper.Client(auto_restart=True, loop=loop)

	loop.create_task(mapper_bot.start(*API_CREDENTIALS))

	return mapper_bot

def stop(loop, mapper_bot):
	mapper_bot.close()