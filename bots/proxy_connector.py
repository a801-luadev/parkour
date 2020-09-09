import asyncio
import json


class JSONProtocol(asyncio.Protocol):
	"""Represents a simple json protocol which is used to communicate with the proxy"""
	def __init__(self, client):
		self.packets = asyncio.Queue()
		self.client = client

	def connection_made(self, transport):
		self.transport = transport
		self.client.connected = True

	def eof_received(self):
		self.transport.close()

	def connection_lost(self, exc):
		self.client.loop.create_task(self.client.connection_lost())
		self.client.connected = False

	def close(self):
		if not self.transport.is_closing():
			self.transport.write_eof()
			self.transport.close()

	def data_received(self, data):
		self.packets.put_nowait(json.loads(data.decode()))

	async def receive(self):
		"""Blocks until there is a packet available, decodes and returns it"""
		return await self.packets.get()

	async def send(self, packet):
		"""Encodes a packet and sends it"""
		self.transport.write(json.dumps(packet).encode())


class Connection:
	"""Represents a connection with the proxy"""
	PROTOCOL = JSONProtocol

	def __init__(self, token, name, loop=None):
		self.loop = loop or asyncio.get_event_loop()

		self.token = token
		self.name = name

		self.protocol = None
		self.connected = False

	def _factory(self):
		return self.PROTOCOL(self)

	async def connect(self, host, port):
		"""Connects to the specified host and port, sends the identification packet
		and starts the reception loop"""
		transport, self.protocol = await self.loop.create_connection(self._factory, host, port)
		await self.send({"type": "identification", "token": self.token, "name": self.name})
		self.loop.create_task(self.receive_loop())

	async def connection_lost(self):
		"""Triggered when the connection is lost"""
		raise NotImplementedError

	async def received_proxy(self, client, packet):
		"""Triggered when other client in the server broadcast or sends a proxy packet
		to this client"""
		raise NotImplementedError

	async def receive_loop(self):
		"""Runs while the client is connected, receives packets and parses them."""
		while self.connected:
			packet = await self.protocol.receive()

			if packet["type"] == "proxy":
				await self.received_proxy(packet["client"], packet["packet"])

	async def send(self, packet):
		"""Shorthand for protocol.send"""
		if not self.connected:
			return

		await self.protocol.send(packet)

	async def sendTo(self, packet, target=None):
		"""Prepares a proxy packet to send to other client"""
		packet = {"type": "proxy", "packet": packet}
		if target is not None:
			packet["client"] = target

		await self.send(packet)

	def close(self):
		"""Closes the connection"""
		if self.connected:
			self.protocol.close()