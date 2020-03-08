import transformice
import discord_bot
import asyncio

# from signal import signal, SIGPIPE, SIG_DFL
# signal(SIGPIPE,SIG_DFL)

if __name__ == '__main__':
	loop = asyncio.get_event_loop()

	discord = discord_bot.setup(loop)
	mapper, migrator = transformice.setup(loop)

	mapper.discord = discord
	migrator.discord = discord
	discord.mapper = mapper
	discord.migrator = migrator

	try:
		loop.run_forever()
	except KeyboardInterrupt:
		transformice.stop(loop, mapper, migrator)
		discord_bot.stop(loop, discord)