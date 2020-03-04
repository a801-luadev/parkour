import aiotfm
import os

PLAYER_DATA = (1 << 8) + 255

class Client(aiotfm.Client):
	async def handle_packet(self, conn, packet):
		CCC = packet.readCode()
		if CCC == (29, 20):
			self.dispatch("lua_textarea", packet.read32(), packet.readString())

		packet.pos = 0
		await super().handle_packet(conn, packet)

	async def on_login_ready(self, *args):
		print("[MIGRATOR] Connected. Logging in...")
		await self.login("Tocutoeltuco#6919", os.getenv("MIGRATOR_PASSWORD"), encrypted=False, room="*#drawbattle0migration")

	async def on_logged(self, *args):
		print("[MIGRATOR] Logged in!")

	async def sendLuaCallback(self, txt_id, text):
		packet = aiotfm.Packet.new(29, 21)
		await self.bulle.send(packet.write32(txt_id).writeString(text))

	async def on_migrating_data(self, player):
		await self.sendLuaCallback(PLAYER_DATA, player)

	async def on_lua_textarea(self, txt_id, text):
		if txt_id & 255 != 255:
			return

		if txt_id == PLAYER_DATA:
			self.parkour.dispatch("migrating_data", text)