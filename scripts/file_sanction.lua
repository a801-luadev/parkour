local sanction = {}
local concat = table.concat

for i=1, 2000 do
  sanction[i] = concat({
    tostring(i),
    os.time() + math.random(-100000, 10000),
    os.time() + 1000 * 60 * 60 * 24 * math.random(1, 30),
    1,
    1,
  }, '\2')
end

sanction[2001] = concat({
  "5419276",
  os.time() + math.random(-100000, 10000),
  os.time() - 1000,
  1,
  1,
}, '\2')

saveFile(63, {
  sanction = {
    ts = os.time(),
    mods = { 'Lays#1146' },
    data = concat(sanction, '\1'),
  },
})
