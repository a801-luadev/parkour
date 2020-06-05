import transformice
import discord_bot
import asyncio

# from signal import signal, SIGPIPE, SIG_DFL
# signal(SIGPIPE,SIG_DFL)

if __name__ == '__main__':
	loop = asyncio.get_event_loop()

	discord = discord_bot.setup(loop)
	mapper = transformice.setup(loop)

	mapper.discord = discord
	discord.mapper = mapper

	try:
		loop.run_forever()
	except KeyboardInterrupt:
		transformice.stop(loop, mapper)
		discord_bot.stop(loop, discord)