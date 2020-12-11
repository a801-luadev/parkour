import aiotfm


def normalize_name(name):
	"""Normalizes a transformice nickname."""
	if isinstance(name, aiotfm.Player):
		name = name.username

	if name[0] == "+":
		name = "+" + (name[1:].capitalize())
	else:
		name = name.capitalize()
	if "#" not in name:
		name += "#0000"
	return name


def enlarge_name(name):
	"""Enlarges a parkour room name."""
	if name[0] == "*":
		return "*#parkour" + name[1:]
	else:
		return name[:2] + "-#parkour" + name[2:]


def shorten_name(name):
	"""Shortens a parkour room name."""
	if name[0] == "*":
		return name.replace("#parkour", "", 1)
	return name.replace("-#parkour", "", 1)