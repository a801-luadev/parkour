class MissingPrivileges(Exception):
	"""Thrown when the token does not have the required roles."""


class MalformedRequest(Exception):
	"""Thrown when the request is malformed."""


def normalize_name(name):
	"""Normalizes a transformice nickname."""
	if name[0] == "+":
		name = "+" + (name[1:].capitalize())
	else:
		name = name.capitalize()
	if "#" not in name:
		name += "#0000"
	return name