import discord_bot.bot as discord
import os

def setup(loop):
	bot = discord.Client(
		max_messages=None,
		fetch_offline_members=False,
		loop=loop
	)

	loop.create_task(bot.start(os.getenv("DISCORD_TOKEN")))

	return bot

def stop(loop, bot):
	loop.run_until_complete(bot.close())