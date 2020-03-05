import os
import transformice.mapper as mapper
import transformice.migrator as migrator

def setup(loop):
	API_CREDENTIALS = (int(os.getenv("API_ID")), os.getenv("API_TOKEN"))

	mapper_bot = mapper.Client(auto_restart=True, loop=loop)
	migrator_bot = migrator.Client(auto_restart=True, loop=loop)

	mapper_bot.drawbattle = migrator_bot
	migrator_bot.parkour = mapper_bot

	loop.create_task(mapper_bot.start(*API_CREDENTIALS))
	loop.create_task(migrator_bot.start(*API_CREDENTIALS))

	return mapper_bot, migrator_bot

def stop(loop, mapper_bot, migrator_bot):
	mapper_bot.close()
	migrator_bot.close()