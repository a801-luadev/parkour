import os
import transformice.mapper as mapper

def setup(loop):
	mapper_bot = mapper.Client(auto_restart=True, bot_role=True, loop=loop)

	loop.create_task(mapper_bot.start())

	return mapper_bot

def stop(loop, mapper_bot):
	mapper_bot.close()