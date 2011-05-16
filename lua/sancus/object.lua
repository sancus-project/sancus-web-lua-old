--

module(...)

function Class(o)
	o = o or {}
	o.__index = o

	return o
end
