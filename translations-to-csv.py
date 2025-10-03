import csv
import os

def parse_lang(lang):
  with open("translations/parkour/"+lang+".lua", encoding="utf-8") as f:
    lines = f.readlines()
    keys = {}
    comma_key = None

    lines = [line.strip() for line in lines]
    lines = [line for line in lines if line]

    for line in lines[1:-1]:
      if comma_key:
        key = comma_key

        if line.endswith(','):
          comma_key = None
          line = line[:-1]

        if line.endswith(' ..'):
          line = line[:-3]

        if line.endswith(')'):
          line = line[:-1]

        if line.startswith('"') or line.startswith("'"):
          line = line[1:]

        if line.endswith('"') or line.endswith("'"):
          escape = line[-1]
          line = line[:-1].replace('\\' + escape, escape).replace('\\n', '\n')

        keys[key] += line

        continue

      if '=' in line:
        left, right = line.split('=', 1)
        left = left.strip()
        right = right.strip()

        if right.startswith('('):
          right = right[1:]

        if right.startswith('"') or right.startswith("'"):
          right = right[1:]

        if line.endswith(','):
          comma_key = None
          right = right[:-1]

        elif right.endswith(' ..'):
          comma_key = left
          right = right[:-4]

        if right.endswith('"') or right.endswith("'"):
          escape = right[-1]
          right = right[:-1].replace('\\' + escape, escape).replace('\\n', '\n')

        keys[left] = right

      else:
        keys[line] = ''

  return keys

def convert_keys(keys_list):
  rows = []
  key_in_rows = {}
  first = True

  for keys in keys_list:
    for key, value in keys.items():
      if key in key_in_rows:
        index = key_in_rows[key]
        rows[index] += [value]

      else:
        index = len(rows)
        key_in_rows[key] = index
        rows += [[key, value]]

    if not first:
      for key, index in key_in_rows.items():
        if key not in keys.keys():
          rows[index] += ['']

    first = False

  return rows

def save(rows):
  print(rows)

  with open('translation.csv', 'w', newline='', encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerows(rows)

keys_list = []

for file in os.listdir('translations/parkour'):
  if file.endswith('.lua'):
    filename = file[:-4]
    keys = parse_lang(filename)
    keys_list += [keys]

en_index = [i for i, keys in enumerate(keys_list) if keys['name'] == 'en'][0]
en = keys_list[en_index]
keys_list = [en] + keys_list[:en_index] + keys_list[en_index+1:]

rows = convert_keys(keys_list)
save(rows)
