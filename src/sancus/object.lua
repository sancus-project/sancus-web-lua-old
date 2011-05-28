--

local setmetatable = setmetatable

module(...)

local _class = {
	__call = function (c, ...) return c:new(...) end,
}

function Class(c)
	c = c or {}
	c.__index = c

	function c:new(o)
		o = o or {}
		setmetatable(o, c)
		return o
	end

	setmetatable(c, _class)

	return c
end
