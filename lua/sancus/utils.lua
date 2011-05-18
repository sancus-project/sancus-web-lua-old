--

local pairs, string, type, tostring = pairs, string, type, tostring
local debug, next = debug, next

local lfs = assert(require("lfs"))

module (...)

-- table.show() stolen from
-- http://lua-users.org/wiki/TableSerialization
--
function pprint(t, name, indent)
	local cart	-- a container
	local autoref	-- for self references

	-- (RiciLake) returns true if the table is empty
	local function isemptytable(t) return next(t) == nil end

	local function basicSerialize (o)
		local so = tostring(o)
		if o == nil then
			return "nil"
		elseif type(o) == "function" then
			local info = debug.getinfo(o, "S")
			-- info.name is nil because o is not a calling level
			if info.what == "C" then
				return string.format("%q", so .. ", C function")
			else
				-- the information is defined through lines
				return string.format("%q", so .. ", defined in (" ..
					info.linedefined .. "-" .. info.lastlinedefined ..
					")" .. info.source)
			end
		elseif type(o) == "boolean" then
			return o and "true" or "false"
		elseif type(o) == "number" then
			return so
		else
			return string.format("%q", so)
		end
	end

	local function addtocart (value, name, indent, saved, field)
		indent = indent or ""
		saved = saved or {}
		field = field or name

		cart = cart .. indent .. field

		if type(value) ~= "table" then
			cart = cart .. " = " .. basicSerialize(value) .. ";\n"
		elseif saved[value] then
			cart = cart .. " = {}; -- " .. saved[value] ..
				" (self reference)\n"
			autoref = autoref ..  name .. " = " .. saved[value] ..
				";\n"
		else
			saved[value] = name
			if isemptytable(value) then
				cart = cart .. " = {};\n"
			else
				cart = cart .. " = {\n"
				for k, v in pairs(value) do
					k = basicSerialize(k)
					local fname = string.format("%s[%s]", name, k)
					field = string.format("[%s]", k)
					-- three spaces between levels
					addtocart(v, fname, indent .. "   ", saved, field)
				end
				cart = cart .. indent .. "};\n"
			end
		end
	end

	name = name or "__unnamed__"
	if type(t) ~= "table" then
		return name .. " = " .. basicSerialize(t)
	end
	cart, autoref = "", ""
	addtocart(t, name, indent)
	return cart .. autoref
end

function sibling_modules()
	local source = debug.getinfo(2).source
	local basedir, me = source:match("^@(.*[/\\])([^/\\]+)$")
	local t = {}

	if basedir then
		for f in lfs.dir(basedir) do
			if f ~= me then
				local f, e = f:match("^(.*)%.([^.]+)$")
				if e == "lua" or e == "so" or e == "dll" then
					t[#t+1] = f
				end
			end
		end
	end
	return t
end
