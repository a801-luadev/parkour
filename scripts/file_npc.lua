local parkour_npc = {
  Mckeydown = {
    active = 1,
    action = "sell_power",
    param = "0;450;100;npc_sell_power;18b29f6977c.png;img@1943409e46e;5",
    definition = "1684;527;348;0",
    look = "222;225_e1e1e1+ffffff+a4a4a4,0,0,0,103_bfbfbf+a2a6ac+9a9a9a+afafaf+aeaeaf+9d9d9e+23262a+a3a39e+9b9a96,130_bdbdbd+c2c0c0+bdb9b6+b3b2b0+d4d4d4+c9c9c9+d6d6d6,0,110,0,0,0,0",
  },
  Lays = {
    active = 1,
    action = "sell_power",
    param = "0;900;100;npc_sell_power;18b29f6977c.png;149c068e42f.png;3",
    definition = "2524;549;212;0",
    look = "8;12_f8a500+f8a500+f8a500+f8a500+f8a500+f8a500,0,18,24,0,0,0,5,9_e07323+3d1f07,0,0,0",
  },
}

saveFile(51, {
  npc = parkour_npc,
})
