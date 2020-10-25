from aiotfm.utils import shakikoo
import aiohttp
import re
import json


class ForumClient:
	"""A very basic forum client.
	Logs in, checks inbox messages and marks them as read."""

	link = "https://atelier801.com/"
	session = None
	logged = False

	async def start(self):
		"""Creates an aiohttp session. Closes the previous if there was one."""
		await self.close()
		self.session = aiohttp.ClientSession(headers={
			"User-Agent": (
				"Mozilla/5.0 (Windows NT 6.1) "
				"AppleWebKit/537.36 (KHTML, like Gecko) "
				"Chrome/68.0.3440.106 Safari/537.36"
			),
			"Accept-Language": "en-US,en;q=0.9"
		})
		self.logged = False

	async def close(self):
		"""Closes the aiohttp session, if possible."""
		if self.session is not None:
			await self.session.close()
			self.session = None
			self.logged = False

	async def get_page(self, page):
		"""Gets a page from the forum."""
		return await self.session.get(self.link + page)

	async def _get_keys(self, page=None):
		"""Gets keys from a page to perform an action."""
		response = await self.get_page(page or "index")
		html = await response.read()

		search = re.search(rb'<input type="hidden" name="(.+?)" value="(.+?)">', html)
		if search is not None:
			name, value = search.group(1, 2)
			return name.decode(), value.decode()

	async def perform_action(self, data, page, referer=None):
		"""Performs an action in the forum."""
		keys = await self._get_keys(referer)
		if keys is None:
			raise Exception("Could not get secret keys.")

		data[keys[0]] = keys[1]

		headers = None
		if referer is not None:
			headers = {
				"Accept": "application/json, text/javascript, */*; q=0.01",
				"X-Requested-With": "XMLHttpRequest",
				"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
				"Referer": self.link + referer
			}

		return await self.session.post(self.link + page, headers=headers, data=data)

	async def login(self, user, password, encrypted=True):
		"""Logs in with the specified user."""
		if self.logged:
			raise Exception("Already logged in.")

		if not encrypted:
			password = shakikoo(password).decode()

		response = await self.perform_action({
			"rester_connecte": "on",
			"id": user,
			"pass": password,
			"redirect": self.link[:-1]
		}, "identification", "login")
		data = json.loads(await response.read())

		if "supprime" in data and data["supprime"] == "*":
			self.logged = True
			return True
		return False

	async def check_inbox(self):
		"""Checks the inbox and returns messages."""
		if not self.logged:
			raise Exception("You need to be logged in first.")

		response = await self.get_page("conversations")

		messages = []
		for groups in re.findall(
			br'img src="img\/icones\/16\/on-offbis[12]\.png".+?>([^< ]+?)<span.+?> (#\d{4})<.+?'
			# author (1, 2)

			br'img18 espace-2-2" \/>  (.+?) <\/a>.+?' # title (3)
			br'nombre-messages-(.+?)" href="(.+?)"', # state, link (4, 5)
			await response.read()
		):
			messages.append({
				"author": (groups[0] + groups[1]).decode(),
				"title": groups[2].decode(),
				"state": 0 if groups[3] == b"lu" else 1 if groups[3] == b"reponses" else 2,
				"id": re.search(rb"\?co=(\d+)", groups[4]).group(1).decode()
			})

		return messages

	async def inbox_read(self, conv_id):
		"""Marks the conversation as (partially) read."""
		if not self.logged:
			raise Exception("You need to be logged in first.")

		return await self.get_page("conversation?co={}".format(conv_id))