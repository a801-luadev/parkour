keyboard = {}
local Keyboard
do
	local selection = {}
	keyboard.keys = {
		[1] = {
			"|", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BACKSPACE"
		},

		[2] = {
			"Tab",
			{"A", "Q"},
			{"Z", "W"},
			"E", "R", "T", "Y", "U", "I", "O", "P",
			{"^", "["},
			{"$", "]"}
		},

		[3] = {
			"Caps\nLock",
			{"Q", "A"},
			"S", "D", "F", "G", "H", "J", "K", "L",
			{"M", ";"},
			{"%", "'"},
			{"*", "\\"}
		},

		[4] = {
			"Shift", ">",
			{"W", "Z"},
			"X", "C", "V", "B", "N",
			{"?", "M"},
			{".", ","},
			{"/", "."},
			{"!", "/"},
			"RShift"
		},

		[5] = {
			"Ctrl", "LWin", "Alt", "SPACE", "Alt Gr", "RWin", "OPT", "RCtrl"
		}
	}
	keyboard.bindings = {
		BACKSPACE = 8, [8] = "BACKSPACE",
		Tab = 9, [9] = "Tab",
		Shift = 16, [16] = "Shift",
		Ctrl = 17, [17] = "Ctrl",
		Alt = 18, [18] = "Alt",
		["Caps\nLock"] = 20, [20] = "Caps\nLock",
		SPACE = 32, [32] = "SPACE",
		["0"] = 48, [48] = "0",
		["1"] = 49, [49] = "1",
		["2"] = 50, [50] = "2",
		["3"] = 51, [51] = "3",
		["4"] = 52, [52] = "4",
		["5"] = 53, [53] = "5",
		["6"] = 54, [54] = "6",
		["7"] = 55, [55] = "7",
		["8"] = 56, [56] = "8",
		["9"] = 57, [57] = "9",
		A = 65, [65] = "A",
		B = 66, [66] = "B",
		C = 67, [67] = "C",
		D = 68, [68] = "D",
		E = 69, [69] = "E",
		F = 70, [70] = "F",
		G = 71, [71] = "G",
		H = 72, [72] = "H",
		I = 73, [73] = "I",
		J = 74, [74] = "J",
		K = 75, [75] = "K",
		L = 76, [76] = "L",
		M = 77, [77] = "M",
		N = 78, [78] = "N",
		O = 79, [79] = "O",
		P = 80, [80] = "P",
		Q = 81, [81] = "Q",
		R = 82, [82] = "R",
		S = 83, [83] = "S",
		T = 84, [84] = "T",
		U = 85, [85] = "U",
		V = 86, [86] = "V",
		W = 87, [87] = "W",
		X = 88, [88] = "X",
		Y = 89, [89] = "Y",
		Z = 90, [90] = "Z",
		LWin = 91, [91] = "LWin",
		RWin = 92, [92] = "RWin",
		[";"] = 186, [186] = ";",
		[","] = 188, [188] = ",",
		["."] = 190, [190] = ".",
		["/"] = 191, [191] = "/",
		["["] = 219, [219] = "[",
		["\\"] = 220, [220] = "\\",
		["]"] = 221, [221] = "]",
		["'"] = 222, [222] = "'"
	}

	Keyboard = Interface.new(65, 170, 665, 215, true)
		:addTextArea({
			name = "enter_key",

			x = 610, y = 45,
			width = 55, height = 80,

			text = "<a href='event:keyboard:enter'>ENTER\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",

			border = 0x1c3a3e
		})
		:addTextArea({
			x = 587, y = 88,
			width = 35, height = 37,

			color = {0x1c3a3e, 0x1c3a3e, 1}
		})

		-- Layer 1
		:addTextArea({
			x = 0, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 45, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 90, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 135, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 180, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 225, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 270, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 315, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 360, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 405, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 450, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 495, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 540, y = 0,
			width = 35, height = 35
		})
		:addTextArea({
			x = 585, y = 0,
			width = 80, height = 35
		})

		-- Layer 2
		:addTextArea({
			x = 0, y = 45,
			width = 60, height = 35
		})
		:addTextArea({
			x = 70, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 115, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 160, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 205, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 250, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 295, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 340, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 385, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 430, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 475, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 520, y = 45,
			width = 35, height = 35
		})
		:addTextArea({
			x = 565, y = 45,
			width = 35, height = 35
		})

		-- Layer 3
		:addTextArea({
			x = 0, y = 90,
			width = 80, height = 35
		})
		:addTextArea({
			x = 90, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 135, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 180, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 225, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 270, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 315, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 360, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 405, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 450, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 495, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 540, y = 90,
			width = 35, height = 35
		})
		:addTextArea({
			x = 585, y = 90,
			width = 35, height = 35
		})

		-- Layer 4
		:addTextArea({
			x = 0, y = 135,
			width = 45, height = 35
		})
		:addTextArea({
			x = 55, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 100, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 145, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 190, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 235, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 280, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 325, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 370, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 415, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 460, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 505, y = 135,
			width = 35, height = 35
		})
		:addTextArea({
			x = 550, y = 135,
			width = 115, height = 35
		})

		-- Layer 5
		:addTextArea({
			x = 0, y = 180,
			width = 65, height = 35
		})
		:addTextArea({
			x = 75, y = 180,
			width = 45, height = 35
		})
		:addTextArea({
			x = 130, y = 180,
			width = 45, height = 35
		})
		:addTextArea({
			x = 185, y = 180,
			width = 240, height = 35
		})
		:addTextArea({
			x = 435, y = 180,
			width = 45, height = 35
		})
		:addTextArea({
			x = 490, y = 180,
			width = 45, height = 35
		})
		:addTextArea({
			x = 545, y = 180,
			width = 45, height = 35
		})
		:addTextArea({
			x = 600, y = 180,
			width = 65, height = 35
		})
		:onUpdate(function(self, player, qwerty, numkey, keyname)
			local txt
			if selection[player] then
				txt = selection[player]
				ui.addTextArea(
					txt.id,
					txt.text_str and txt.text_str or
					txt:text_fnc(player, qwerty),
					player,
					txt.x, txt.y,
					txt.width, txt.height,
					txt.background, txt.border, txt.alpha,
					true
				)
				selection[player] = nil
			end

			if numkey then
				local text_id = self.elements.enter_key.id + numkey

				for index = 1, self.textarea_count do
					txt = self.textareas[index]
					if txt.id == text_id then
						selection[player] = txt
						break
					end
				end
			elseif keyname then
				for index = 1, self.textarea_count do
					txt = self.textareas[index]
					if txt.key == keyname then
						selection[player] = txt
						break
					end
				end
			end

			if not selection[player] then return end

			ui.addTextArea(
				txt.id,
				txt.text_str and txt.text_str or
				txt:text_fnc(player, qwerty),
				player,
				txt.x, txt.y,
				txt.width, txt.height,
				0x232a35, 0x1c3a3e, 1,
				true
			)
		end)

	local newlines = string.rep("\n", 10)
	local key = 2
	local txt
	for i = 1, #keyboard.keys do
		for j = 1, #keyboard.keys[i] do
			key = key + 1
			txt = Keyboard.textareas[key]

			txt.border = 0x1c3a3e

			if keyboard.keys[i][j][1] then -- variation
				txt.canUpdate = true
				txt.text_str = nil

				txt.text_fnc = function(self, player, qwerty)
					self.key = keyboard.keys[i][j][qwerty and 2 or 1]
					return "<a href=\"event:keyboard:" .. self.key .. "\">" .. self.key .. newlines
				end
			else
				txt.key = keyboard.keys[i][j]
				txt.text_str = "<a href=\"event:keyboard:" .. txt.key .. "\">" .. txt.key .. newlines
			end
		end
	end
end