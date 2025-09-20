# Import required modules
import datetime
import json
import os
import re
import sys

if '--ui' in sys.argv:
	with open("scripts/testui.lua", "rb") as file:
		script = file.read()

elif '--migrate' in sys.argv:
	with open("scripts/migrate.lua", "rb") as file:
		script = file.read()

else:
	# Reading the script
	with open("init.lua", "rb") as file:
		script = file.read()

if '--polyfill' in sys.argv or '--dev' in sys.argv:
	with open("scripts/polyfill.lua", "rb") as file:
		script = file.read() + script

# Evaluating tags (building the code)
def eval_tag(data, indent):
	if data["type"] == "require-file":
		content = b"--[[ File {file_name} ]]--\n".replace(b"{file_name}", data["file"].encode())
		with open(data["file"], "rb") as file:
			content += file.read()
		content = content.strip() + b"\n--[[ End of file {file_name} ]]--".replace(b"{file_name}", data["file"].encode())

	elif data["type"] == "require-dir":
		content = b"--[[ Directory {dir_name} ]]--".replace(b"{dir_name}", data["dir"].encode())
		for file in os.listdir(data["dir"]):
			path = data["dir"] + "/" + file

			if os.path.isfile(path):
				content += b"\n" + eval_tag({"type": "require-file", "file": path}, b"")
			elif data["recursive"]:
				content += b"\n" + eval_tag({"type": "require-dir", "dir": path, "recursive": True}, b"")
		content += b"\n--[[ End of directory {dir_name} ]]--".replace(b"{dir_name}", data["dir"].encode())

	elif data["type"] == "require-package":
		content = b"--[[ Package {pkg_name} ]]--".replace(b"{pkg_name}", data["package"].encode())
		for tag in json.load(open(data["package"] + "/package.json", "rb")):
			content += b"\n" + eval_tag(tag, b"")
		content += b"\n--[[ End of package {pkg_name} ]]--".replace(b"{pkg_name}", data["package"].encode())

	else:
		raise TypeError("Unknown tag in package: {}".format(data["type"]))

	return content.replace(b"\n", b"\n" + indent)

for indent, _open, tag, close in re.findall(rb"\n((?:\t| )*)(\{%\s*)(.+?)(\s*%\})", script):
	args = tag.split(b" ")
	cmd = args.pop(0).lower().decode()

	if cmd.startswith("require-"):
		script = script.replace(_open + tag + close, eval_tag({
			"type": cmd,
			cmd[8:]: eval(b" ".join(args))
		}, indent), 1)

	else:
		raise TypeError("Unknown tag in init.lua: {}".format(cmd))

# Trim spaces before newlines
script = re.sub(rb"[\t ]+\n", b"\n", script.strip())

# Create directory if it does not exist.
now = datetime.datetime.utcnow()
month_year = now.strftime("%m-%Y")
if not os.path.isdir("builds"):
	os.mkdir("builds")
if not os.path.isdir("builds/" + month_year):
	os.mkdir("builds/" + month_year)

# Save built script
with open("builds/latest.lua", "wb") as file:
	file.write(script)