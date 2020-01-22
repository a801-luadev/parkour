local translations, global_translations
translations = setmetatable({}, {
	__index = function()
		return translations.en
	end
})
global_translations = setmetatable({}, {
	__index = function()
		return global_translations.en
	end
})
