local translations
translations = setmetatable({}, {
	__index = function()
		return translations.en
	end
})