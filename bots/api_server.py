import os
import sys
import time
import string
import random
import asyncio
import traceback
from api.utils import MissingPrivileges, MalformedRequest, normalize_name
from sanic import Sanic, Blueprint
from sanic.response import json
from sanic.exceptions import NotFound
from sanic.views import HTTPMethodView
from proxy_connector import Connection


class env:
	proxy_token = os.getenv("PROXY_TOKEN")
	proxy_ip = os.getenv("PROXY_IP")
	proxy_port = os.getenv("PROXY_PORT")

	gateway_token = Os.getenv("GATEWAY_TOKEN")


app = Sanic("parkour_api")
app.tokens = {
	# tfm name, permissions, expiration time, expired
	env.gateway_token: ["Parkour#8558", ["bot"], None, False]
}
endpoints = Blueprint.group(, url_prefix="/parkour/api")


class Proxy(Connection):
	def __init__(self, *args, **kwargs):
		self.waiters = {}
		super().__init__(*args, **kwargs)

	async def connection_lost(self):
		await app.restart()

	async def received_proxy(self, client, packet):
		if client == "records":
			return

		if packet["type"] == "get_roles":
			self.dispatch("role_response", packet["player"], packet["roles"])

		elif packet["type"] == "discord_info":
			self.dispatch(
				"discord_response",
				packet["discord_id"],
				packet.get("nickname"),
				packet.get("name"),
				packet.get("roles")
			)

		elif packet["type"] == "whois":
			self.dispatch("whois_response", packet["id"], packet["name"])

		elif packet["type"] == "profile":
			self.dispatch(
				"profile_response",
				packet["id"], packet["name"], packet["profile"]
			)

	def dispatch(self, event, *args, **kwargs):
		if event not in self.waiters:
			return

		to_remove = []
		waiters = self.waiters[event]

		for i, (cond, fut) in enumerate(waiters):
			if fut.cancelled():
				to_remove.append(i)
				continue

			result = True
			if cond is not None:
				try:
					result = bool(cond(*args))
				except Exception as e:
					fut.set_exception(e)
					to_remove.append(i)
					continue

			if result:
				fut.set_result(args[0] if len(args) == 1 else args if len(args) > 0 else None)
				to_remove.append(i)

		if len(to_remove) == len(waiters):
			del self.waiters[event]

		else:
			for i in to_remove[::-1]:
				del waiters[i]

	def wait_for(self, event, condition=None, timeout=None):
		event = event.lower()
		future = self.loop.create_future()

		if event not in self.waiters:
			self.waiters[event] = []

		self.waiters[event].append((condition, future))

		return asyncio.wait_for(future, timeout)


@app.listener("before_server_start")
async def open_proxy(app, loop):
	print("Connecting with the proxy...")

	app.proxy = Proxy(app, env.proxy_token, "tocubot")
	try:
		await self.proxy.connect(env.proxy_ip, env.proxy_port)
	except Exception:
		print("Could not connect to the proxy. Restarting process in 10 seconds.")
		await asyncio.sleep(10.0)
		os.execl(sys.executable, sys.executable, *sys.argv)
	else:
		print("Connected!")

@app.listener("after_server_stop")
async def close_proxy(app, loop):
	app.proxy.close()

@app.middleware("request")
async def auth_check(request):
	header = request.headers.get("Authorization")

	if header is not None:
		token_type, token = header.split(" ", 1)

		if token_type.lower() == "bearer" and token in app.tokens:
			auth = app.tokens[token]

			if not auth[3] and (auth[2] is None or time.time() < auth[2]): # didn't expire
				request.auth = auth
				request.user, request.roles = auth[0], auth[1]
				# we return "peacefully" to continue with the request
				return

			else:
				del app.tokens[token]

	# one of the checks failed, so the client is unauthorized
	return json({
		"error": "Unauthorized",
		"message": "Please, provide an Authorization header with a valid Bearer token."
	}, status=403)


@endpoints.route("/token", methods=frozenset({"POST"}))
async def create_token(request):
	if "bot" not in request.roles:
		raise MissingPrivileges

	info = request.json
	if (not isinstance(info, dict)
		or not isinstance(info.get("user"), str)
		or not info["user"].isdigit() # discord id
		or not isinstance(info.get("duration"), int)):
		raise MalformedRequest

	discord, duration = int(info["user"]), info["duration"]
	await app.proxy.sendTo({
		"type": "discord_info",
		"discord_id": discord
	}, "discord")
	discord, user, discord_name, _roles = await app.proxy.wait_for(
		"discord_response",
		lambda id, name, _name, _roles: id == discord,
		3.0
	)

	if user is None:
		return json({
			"success": False,
			"error": "The given discord id is either not a member of the server or not verified"
		}, status=400)

	to_remove = []
	exists = False
	now = time.time()
	for token, (owner, roles, expiration, expired) in app.tokens.items():
		if expired or (expiration is not None and now >= expiration):
			to_remove.append(token)
			continue

		if owner == user:
			app.tokens[token][2] = now + duration
			exists = True
			break

	for token in to_remove:
		del app.tokens[token]

	if exists:
		return json({
			"success": True,
			"user": user,
			"token": token,
			"roles": roles
		})

	await app.proxy.sendTo({
		"type": "get_roles",
		"player": user
	}, "parkour")
	user, roles = await app.proxy.wait_for(
		"role_response",
		lambda player, roles: player == user,
		1.0
	)

	if not roles:
		return json({
			"success": False,
			"error": "This user does not have any parkour role."
		}, status=400)

	characters = string.ascii_letters + string.digits + "_."
	token = "".join([random.choice(characters) for _ in range(50)])
	app.tokens[token] = [user, roles, time.time() + duration, False]

	return json({
		"success": True,
		"user": user,
		"token": token,
		"roles": roles
	})

class TokenAuthorizer(HTTPMethodView):
	def assert_privileges(self, request):
		if "bot" not in request.roles:
			raise MissingPrivileges

	def get(self, request, token):
		self.assert_privileges(request)

		if token in app.tokens:
			user, roles, expiration, expired = app.tokens[token]
			now = time.time()

			if not expired and (expiration is None or now < expiration):
				return json({
					"exists": True,
					"user": user,
					"roles": roles,
					"duration": expiration - now if expiration is not None else None
				})

			del app.tokens[token]

		return json({
			"exists": False
		}, status=404)

	def delete(self, request, token):
		self.assert_privileges(request)

		if token in app.tokens:
			# if there is an open websocket connection, we have to notify it
			app.tokens[token] = True
			del app.tokens[token]

		return json({})

endpoints.add_route(TokenAuthorizer.as_view(), "/token/<token:string>")

@app.exception(NotFound)
async def not_found(request, exception):
	return json({
		"error": "Not found",
		"message": "Could not find the resource you're looking for."
	}, status=404)

@app.exception(MissingPrivileges)
async def missing_privileges(request, exception):
	return json({
		"error": "Missing privileges",
		"message": "You don't have permissions to do that!"
	}, status=403)

@app.exception(MalformedRequest)
async def malformed_request(request, exception):
	return json({
		"error": "Malformed request",
		"message": "Your request seems to be malformed."
	}, status=400)

@app.exception(asyncio.TimeoutError)
async def timeout(request, exception):
	return json({
		"error": "Timeout",
		"message": "The server timed out to provide a proper response."
	}, status=504)

app.blueprint(endpoints)


if __name__ == '__main__':
	kwargs = {
		"host": "127.0.0.1", "port": 8182
	}

	if "debug" not in sys.argv:
		kwargs.update({
			"host": True,
			"access_log": True
		})

	try:
		app.run(**kwargs)
	except KeyboardInterrupt:
		print(end="\r") # remove ^C
		print("Press CTRL+C again to fully stop the server.")
	except Exception:
		print("An exception occurred:")
		traceback.print_exc()
	finally:
		print("Restarting process in 10 seconds.")
		time.sleep(10.0)
		os.execl(sys.executable, sys.executable, *sys.argv)