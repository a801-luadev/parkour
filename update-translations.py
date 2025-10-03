URL = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRknFKm8_SxH0eIFVpHXs9T42h4itEqXKq4x319dX7njhSvVLqHsarZF0PfPnZXPpTvtBSxWyEPtbfL/pub?gid=1657710783&single=true&output=csv'

import urllib.request
import csv
import io

def csv_url_to_lua(url):
	with urllib.request.urlopen(url) as response:
		data = response.read().decode("utf-8")

	reader = csv.reader(io.StringIO(data))
	headers = next(reader)  # first row: ["name", "en", "br", ...]

	languages = headers[1:]  # skip first col (key)
	translations = {lang: {
		"name": lang,
	} for lang in languages}

	for row in reader:
		key = row[0].strip()
		if not key:
			continue

		for i, lang in enumerate(languages, start=1):
			if key.startswith("--"):
				translations[lang][key] = True
				continue

			value = row[i]
			if value:
				translations[lang][key] = value.replace('\n', '\\n').replace('"', '\\"')

	for lang, pairs in translations.items():
		with open(f"translations/parkour/{lang}.lua", "w", encoding="utf-8") as f:
			f.write(f"translations.{lang} = {{\n")
			for k, v in pairs.items():
				if v == True:
					f.write(f"\n\t{k}\n")
				else:
					f.write(f"\t{k} = \"{v}\",\n")
			f.write("}\n")

			if lang == "br":
				f.write("translations.pt = translations.br\n")

			elif lang == "cn":
				f.write("translations.ch = translations.cn\n")

csv_url_to_lua(URL)
