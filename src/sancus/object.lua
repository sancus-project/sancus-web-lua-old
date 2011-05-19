--

local setmetatable = setmetatable

module(...)

--
function Class(c)
	c = c or {}
	c.__index = c

	function c.new(o)
		o = o or {}
		setmetatable(o, c)
		return o
	end

	return c
end
