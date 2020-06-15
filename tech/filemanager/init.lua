local FileManager
do
	FileManager = {}
	FileManager.__index = FileManager

	local string_byte = string.byte
	local string_char = string.char
	local string_sub = string.sub

	local parsers
	parsers = {
		["dictionary"] = function(str, obj, idx)
			local result = {}
			if obj.length then -- premade dict!
				local child
				for i = 1, obj.length do
					child = obj.map[i]
					result[child.name], idx = parsers[child.type](str, child, idx)
				end
			else
				local length
				length, idx = parsers.number(str, nil, idx)

				local strparser = parsers.string
				local parser, child = parsers[obj.objects.type], obj.objects
				local name
				for i = 1, length do
					name, idx = strparser(str, nil, idx)
					result[name], idx = parser(str, child, idx)
				end
			end
			return result, idx
		end,

		["array"] = function(str, obj, idx)
			local result = {}
			if obj.length then -- premade map!
				local child
				for i = 1, obj.length do
					child = obj.map[i]
					result[i], idx = parsers[child.type](str, child, idx)
				end
			else
				local length
				length, idx = parsers.number(str, nil, idx)

				local parser, child = parsers[obj.objects.type], obj.objects
				for i = 1, length do
					result[i], idx = parser(str, child, idx)
				end
			end
			return result, idx
		end,

		["boolean"] = function(str, obj, idx)
			return string_sub(str, idx, idx) == "1", idx + 1
		end,

		["string"] = function(str, obj, idx)
			local length = obj and obj.length
			if not length then
				length, idx = parsers.number(str, nil, idx)
			end

			return string_sub(str, idx, idx - 1 + length), idx + length
		end,

		["number"] = function(str, obj, idx)
			local length = string_byte(str, idx)
			return tonumber(string_sub(str, idx + 1, idx + length)), idx + 1 + length
		end
	}

	local writers
	writers = {
		["dictionary"] = function(data, obj, str)
			if obj.length then -- premade map
				local child
				for i = 1, obj.length do
					child = obj.map[i]
					str = writers[child.type](data[child.name], child, str)
				end
			else
				local _str = ""
				local length = 0

				local strwriter = writers.string
				local writer, child = writers[obj.objects.type], obj.objects
				for key, value in next, data do
					_str = strwriter(key, nil, _str)
					_str = writer(value, child, _str)
					length = length + 1
				end

				str = writers.number(length, nil, str) .. _str
			end
			return str
		end,

		["array"] = function(data, obj, str)
			if obj.length then -- premade map
				local child
				for i = 1, obj.length do
					child = obj.map[i]
					str = writers[child.type](data[i], child, str)
				end
			else
				local length = #data
				str = writers.number(length, nil, str)

				local writer, child = writers[obj.objects.type], obj.objects
				for i = 1, #data do
					str = writer(data[i], child, str)
				end
			end
			return str
		end,

		["boolean"] = function(data, obj, str)
			return str .. (data and "1" or "0")
		end,

		["string"] = function(data, obj, str)
			if not (obj and obj.length) then
				str = writers.number(#data, nil, str)
			end
			return str .. data
		end,

		["number"] = function(data, obj, str)
			local encoded = tostring(data)
			return str .. string_char(#encoded) .. encoded
		end
	}

	local prepare_object
	function prepare_object(obj)
		assert(obj.type, "every object must have a type")

		if obj.type == "dictionary" then
			assert(obj.objects or obj.map, "a dictionary must have either a premade map or an objects list")
			assert(not (obj.objects and obj.map), "a dictionary can't have both a premade map and an objects list")
			assert(not obj.length, "a dictionary can't have the length variable set to it")

			if obj.map then
				obj.length = #obj.map

				local child
				for index = 1, obj.length do
					child = obj.map[index]
					assert(child.name, "every object in the map of a dictionary must have a name")

					prepare_object(child)
				end
			else
				assert(not obj.objects.name, "the object type in a dynamic dictionary can't have a premade name")

				prepare_object(obj.objects)
			end

		elseif obj.type == "array" then
			assert(obj.objects or obj.map, "an array must have either a premade map or an objects list")
			assert(not (obj.objects and obj.map), "an array can't have both a premade map and an objects list")
			assert(not obj.length, "an array can't have the length variable set to it")

			if obj.map then
				obj.length = #obj.map

				local child
				for index = 1, obj.length do
					prepare_object(obj.map[index])
				end
			else
				prepare_object(obj.objects)
			end

		elseif obj.type == "boolean" then
			-- nothing

		elseif obj.type == "string" then
			if obj.length then
				assert(type(obj.length) == "number", "length attribute of a string must be either nil or a number")
			end

		elseif obj.type == "number" then
			-- nothing

		else
			error("unknown object type: '" .. obj.type .. "'")
		end
	end

	local validity_checks
	function validity_checks(data, obj)
		local data_type = type(data)

		if obj.type == "dictionary" then
			assert(data_type == "table", "object must be a table in order to be casted to a dictionary")
			if obj.length then
				local length = 0

				local valid
				for key, value in next, data do
					valid = false
					length = length + 1
					for i = 1, obj.length do
						if obj.map[i].name == key then
							valid = true
							validity_checks(value, obj.map[i])
							break
						end
					end
					assert(valid, "table must have the same keys as the premade dictionary map")
				end

				assert(length == obj.length, "table must have the same length as the premade dictionary map")
			else
				local object = obj.objects
				for key, value in next, data do
					assert(type(key) == "string", "table indexes must be strings in order to be casted to a dynamic dictionary")
					validity_checks(value, object)
				end
			end

		elseif obj.type == "array" then
			assert(data_type == "table", "object must be a table in order to be casted to a array")
			if obj.length then
				assert(#data == obj.length, "table must have the same length as the premade array map")

				for i = 1, #data do
					validity_checks(data[i], obj.map[i])
				end
			else
				local object = obj.objects
				for i = 1, #data do
					validity_checks(data[i], object)
				end
			end

		elseif obj.type == "boolean" then
			-- no specific type needed

		elseif obj.type == "string" then
			assert(data_type == "string", "object must be a string in order to be written as one")
			if obj.length then
				assert(#data == obj.length, "string must have the same length as the allocated for the string")
			end

		elseif obj.type == "number" then
			assert(data_type == "number", "object must be a number in order to be written as one")
		end
	end

	function FileManager.new(struct)
		return setmetatable({
			ready = false,
			struct = struct,
			validity = true
		}, FileManager)
	end

	function FileManager:disableValidityChecks()
		self.validity = false
		return self
	end

	function FileManager:prepare()
		prepare_object(self.struct)
		self.ready = true
		return self
	end

	function FileManager:load(string)
		assert(self.ready, "FileManager needs to be prepared before using it")
		return parsers[self.struct.type](string, self.struct, 1)
	end

	function FileManager:check(data)
		validity_checks(data, self.struct)
		return self
	end

	function FileManager:dump(data)
		assert(self.ready, "FileManager needs to be prepared before using it")

		if self.validity then
			self:check(data)
		end

		return writers[self.struct.type](data, self.struct, "")
	end
end