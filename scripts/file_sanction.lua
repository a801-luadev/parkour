local sanction = {}

for i=1, 2000 do
  sanction[tostring(i)] = {
    timestamp = os.time() + math.random(-100000, 10000),
    time = os.time() + 1000 * 60 * 60 * 24 * math.random(1, 30),
    info = 0,
    level = 1,
  }
end

sanction["5419276"] = {
  timestamp = os.time() + math.random(-100000, 10000),
  time = os.time() - 1000,
  info = 0,
  level = 1,
}

saveFile(43, {
  mods = { 'Lays#1146' },
  sanction = sanction,
})
