from sanic import Blueprint
from sanic.response import json
from api.utils import MalformedRequest, normalize_name


bp = Blueprint("player")

@bp.route(r"/player/<user:string>@<name:[a-zA-Z0-9_+]#\d{4}>/profile")
async def profile(request, name):
	app = request.app

	if name[0] == ":":
		pid = name[1:]

		if not pid.isdigit():
			raise MalformedRequest

		await app.proxy.sendTo({
			"type": "profile",
			"id": int(pid)
		}, "parkour")
		pid, name, profile = await app.proxy.wait_for(
			"profile_response",
			lambda _pid, name, profile: _pid == pid,
			3.0
		)

	elif name[1] == "@":
		name = normalize_name(name[1:])

		await app.proxy.sendTo({
			"type": "profile",
			"name": name
		}, "parkour")
		pid, name, profile = await app.proxy.wait_for(
			"profile_response",
			lambda pid, _name, profile: _name == name,
			3.0
		)

	else:
		raise MalformedRequest

	if profile is None:
		return json({
			"error": "Not found",
			"message": "Could not find the player you're looking for."
		}, status=404)
	
	response = {
		"name": name,
		"id": pid,
		"roles": profile["roles"],
		"online": profile["online"],
		"parkour": None,
		"discord": None
	}

	if profile["online"]:
		file = profile["file"]
		if profile["outdated"]:
			response["parkour"] = {
				"outdated": True
			}

		else:
			response["parkour"] = {
				"version": file["v"],
				"outdated": False,
				"leaderboard": profile["leaderboard"],
				"badges": file["badges"]
			}

			has_auth = "mod" in request.roles or "admin" in request.roles
			if not file.get("private_maps") or has_auth:
				hour_r = profile["hour_r"] # UTC in seconds, normalized by parkour

				response["parkour"]["maps"] = {
					"private": file.get("private_maps", False)
					"all": file["c"],
					"week": file["week"],
					"hour": [
						date * 10 + hour_r
						for date in file["hour"]
					]
				}
			else:
				response["parkour"]["maps"] = {
					"private": True
				}

			if has_auth:
				response["parkour"].update({
					"language": file.get("langue"),
					"room": file["room"],
					"can_report": file["report"],
					"ban": parkour["ban_info"],
					"power_removal": parkour["kill_info"],
					"spec": file.get("spec", False),
					"hide": file.get("hidden", False)
				})

	await app.proxy.sendTo({
		"type": "discord_info",
		"nickname": name
	})
	discord_id, name, discord_name, roles = await app.proxy.wait_for(
		"discord_response",
		lambda discord_id, nickname, discord_name, roles: nickname == name,
		3.0
	)

	if discord_id is not None: # has been found
		response["discord"] = {
			"id": str(discord_id),
			"name": discord_name,
			"roles": roles
		}

	return json(response)