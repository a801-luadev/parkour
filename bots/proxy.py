import asyncio
import json
import os
import traceback
import aiohttp


tokens = {
	os.getenv("PROXY_TOKEN"): ("parkour", "tocubot", "discord"),
	os.getenv("RECORDS_TOKEN"): ("records",)
}
permissions = {
	"parkour": ("proxy", "exec", "reboot"),
	"tocubot": ("proxy", "exec", "reboot"),
	"discord": ("proxy", "exec", "reboot"),

	"records": ("proxy",)
}


class JSONProtocol(asyncio.Protocol):
	"""Represents a simple json protocol which is used to communicate with the proxy"""
	def __init__(self, server):
		self.packets = asyncio.Queue()
		self.client = None
		self.server = server

	def connection_made(self, transport):
		self.transport = transport

		self.server.connection_made(self)

	def eof_received(self):
		self.transport.close()
		self.client.loop.create_task(self.client.connection_lost())

	def connection_lost(self, exc):
		self.client.loop.create_task(self.client.connection_lost())

	def close(self):
		if not self.transport.is_closing():
			self.transport.write_eof()
			self.transport.close()

	def set_client(self, client):
		self.client = client

	def parse_packet(self, packet):
		if len(packet) < 3:
			return

		length = (packet[0] << 16) + (packet[1] << 8) + packet[2]
		yield packet[3:3 + length]
		yield from self.parse_packet(packet[3 + length:])

	def data_received(self, data):
		for packet in self.parse_packet(data):
			if len(packet) > 1:
				self.packets.put_nowait(packet)

	async def receive(self):
		"""Blocks until there is a packet available, decodes and returns it"""
		return json.loads(await self.packets.get())

	async def send(self, packet):
		"""Encodes a packet and sends it"""
		data = json.dumps(packet).encode()
		data = bytes((len(data) >> 16 & 255, len(data) >> 8 & 255, len(data) & 255)) + data
		self.transport.write(data)


class Client:
	"""Represents a client that has been connected to the proxy"""
	def __init__(self, server, protocol, loop=None):
		self.loop = loop or asyncio.get_event_loop()

		self.server = server
		self.protocol = protocol

		self.connected = False
		self.name = None

		self.permissions = ()

	def close(self):
		if self.connected:
			self.protocol.close()
			self.loop.create_task(self.connection_lost())

	async def send(self, packet):
		"""Shorthand for protocol.send"""
		await self.protocol.send(packet)

	async def load_script(self, packet):
		if "link" in packet:
			async with aiohttp.ClientSession() as session:
				async with session.get(packet["link"]) as resp:
					script = (await resp.read()).decode()

		else:
			script = packet["script"]
		channel = packet["channel"]

		packet = {
			"type": "proxy",
			"client": "proxy",
			"packet": {
				"type": "message",
				"channel": channel
			}
		}

		try:
			exec("async def evaluate(self):\n\t" + (script.replace("\n", "\n\t")))
		except Exception:
			packet["packet"]["msg"] = "Syntax error: ```python\n" + traceback.format_exc() + "```"
			await self.send(packet)
			return

		try:
			await locals()["evaluate"](self)
		except Exception:
			packet["packet"]["msg"] = "Runtime error: ```python\n" + traceback.format_exc() + "```"
			await self.send(packet)
			return

		packet["packet"]["msg"] = "Script ran successfully."
		await self.send(packet)

	async def receive_loop(self):
		"""Runs while the client is connected, receives packets and parses them."""
		while self.connected:
			packet = await self.protocol.receive()
			print("recv", self.name, packet)

			if packet["type"] not in self.permissions:
				print("not in permissions")
				continue

			# Sends the packet to other clients
			if packet["type"] == "proxy":
				client = packet.get("client") # defaults to None / null

				# Packet data
				sending = {
					"type": "proxy",
					"client": self.name,
					"packet": packet["packet"]
				}

				# When client is None, the packet is broadcasted
				if client is None:
					for client in self.server.clients.values():
						await client.send(sending)

				elif client in self.server.clients:
					await self.server.clients.get(client).send(sending)

			# Executes arbitrary code in the server
			elif packet["type"] == "exec":
				self.loop.create_task(self.load_script(packet))

			# Closes all the connections (the clients detect them and reboot)
			elif packet["type"] == "reboot":
				self.loop.create_task(self.server.close_clients())

	async def connection_lost(self):
		if self.connected:
			self.connected = False
			await self.server.connection_lost(self)

	async def wait_identification(self):
		"""Waits for the client to identificate, and closes the connection
		if it takes more than 5 seconds or if the identification packet is
		incorrect."""
		try:
			packet = await asyncio.wait_for(self.protocol.receive(), 5.0)
		except asyncio.TimeoutError:
			self.close()
			return

		if packet["type"] == "identification" and isinstance(packet.get("token"), str):
			if isinstance(packet.get("name"), str):
				if packet["token"] in tokens and packet["name"] in tokens[packet["token"]]:
					print("identified", packet)
					self.permissions = permissions[packet["name"]]
					self.connected = True
					self.name = packet["name"]
					await self.server.client_identified(self)
					return

		self.close()


class Server:
	"""Represents the proxy server"""

	PROTOCOL = JSONProtocol

	def __init__(self, loop=None):
		self.loop = loop or asyncio.get_event_loop()

		self.clients = {}

		self._server_coro = None
		self.server = None

	def _factory(self):
		return self.PROTOCOL(self)

	def bind(self, host, port):
		"""Binds the server to the specified host and port"""
		self._server_coro = self.loop.create_server(self._factory, host, port)

	async def start(self):
		self.server = await self._server_coro
		self._server_coro = None

	async def close_clients(self):
		"""Closes all the connections (the clients detect them and reboot)"""
		for client in self.clients.values():
			client.close()

	def close(self):
		"""Stops the server and closes all the connections"""
		self.server.close()

		for client in self.clients.values():
			client.close()

	def wait_closed(self):
		"""Returns a coroutine that waits until the server is closed"""
		return self.server.wait_closed()

	def connection_made(self, protocol):
		"""Triggered when a client is connected (waiting for identification)"""
		client = Client(self, protocol, loop=self.loop)
		protocol.set_client(client)
		self.loop.create_task(client.wait_identification())

	async def client_identified(self, client):
		"""Triggered when a client has identificated correctly"""
		if client.name in self.clients:
			client.close()
			return

		self.clients[client.name] = client

		self.loop.create_task(client.receive_loop())

	async def connection_lost(self, client):
		del self.clients[client.name]


if __name__ == '__main__':
	server = Server()

	print("Starting server...")
	server.bind("0.0.0.0", 6666)
	server.loop.run_until_complete(server.start())
	print("Server running.")

	try:
		server.loop.run_forever()
	except KeyboardInterrupt:
		print("Stopping...")
	finally:
		server.close()
		server.loop.run_until_complete(server.wait_closed())
		server.loop.close()