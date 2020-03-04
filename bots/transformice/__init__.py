import transformice.mapper as mapper
import transformice.migrator as migrator

def setup(loop):
	API_CREDENTIALS = (51058033, "2e234ed900-5c469db-114d3d91600-d6c0451b-116c")

	mapper_bot = mapper.Client(loop=loop)
	migrator_bot = migrator.Client(loop=loop)

	mapper_bot.drawbattle = migrator_bot
	migrator_bot.parkour = mapper_bot

	loop.create_task(mapper_bot.start(*API_CREDENTIALS))
	loop.create_task(migrator_bot.start(*API_CREDENTIALS))

	return mapper_bot, migrator_bot

def stop(loop, mapper_bot, migrator_bot):
	mapper_bot.close()
	migrator_bot.close()