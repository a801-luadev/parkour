import asyncio

from parkour.apigateway import ApiGateway
from parkour.base import Base
from parkour.chat import Chat
from parkour.commands import Commands
from parkour.logs import Logs
from parkour.records import Records
from parkour.reports import Reports
from parkour.sanctions import Sanctions
from parkour.verification import Verification
from parkour.whois import Whois


class ParkourBot(
		ApiGateway,

		Records,
		Verification,
		Reports,
		Sanctions,
		Commands,
		Chat,
		Logs,
		Whois,
		Base
	):
	pass


if __name__ == '__main__':
	loop = asyncio.get_event_loop()

	bot = ParkourBot(bot_role=True, loop=loop)
	loop.create_task(bot.start())

	try:
		loop.run_forever()
	except KeyboardInterrupt:
		print(end="\r") # remove ^C
		print("stopping")
		bot.close()