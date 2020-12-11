from sanic import Blueprint
from sanic.response import json
from api.utils import MalformedRequest, normalize_name


bp = Blueprint("player")

@bp.route(r"/player/<name:string>/profile")
async def profile(request, name):
	app = request.app

	if name[0] == ":":
		pid = name[1:]
		if not pid.isdigit():
			raise MalformedRequest

		query = int(pid)

	elif name[0] == "@":
		query = normalize_name(name[1:])

	else:
		raise MalformedRequest

	await app.proxy.sendTo({
		"type": "profile",
		"query": query
	}, "parkour")
	pid, name, profile = await app.proxy.wait_for(
		"profile_response",
		lambda pid, name, profile: query in (pid, name),
		2
	)

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
		if file is None:
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

			req_roles = request.ctx.roles
			has_auth = "mod" in req_roles or "admin" in req_roles
			if not file.get("private_maps") or has_auth:
				hour_r = profile["hour_r"] # UTC in seconds, normalized by parkour

				response["parkour"]["maps"] = {
					"private": file.get("private_maps", False),
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
					"ban": profile.get("ban_info"),
					"power_removal": profile.get("kill_info"),
					"spec": file.get("spec", False),
					"hide": file.get("hidden", False)
				})

	# await app.proxy.sendTo({
	# 	"type": "discord_info",
	# 	"nickname": name
	# }, "discord")
	# discord_id, name, discord_name, roles = await app.proxy.wait_for(
	# 	"discord_response",
	# 	lambda discord_id, nickname, discord_name, roles: nickname == name,
	# 	3.0
	# )

	discord_id = None
	if discord_id is not None: # has been found
		response["discord"] = {
			"id": str(discord_id),
			"name": discord_name,
			"roles": roles
		}

	return json(response)