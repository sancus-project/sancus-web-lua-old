--

require "sancus.object"
require "sancus.exc"

local coroutine = coroutine
local tconcat = table.concat
local pairs, type = pairs, type

local Class = sancus.object.Class
local plain_handler_generator = sancus.exc.plain_handler_generator

module (...)

local C = Class()

local function _methods(o)
	local t = {}
	for _, method in pairs{"GET", "POST", "PUT", "DELETE"} do
		if o[method] then
			t[method] = o[method]
		end
	end
	t["HEAD"] = o["HEAD"] or t["GET"]
	t["OPTIONS"] = true
	return t
end

local function _allows(handlers)
	local t = {}
	for k,_ in pairs(handlers) do
		t[#t+1] = k
	end
	return tconcat(t, ", ")
end

function C:__call(wsapi_env)
	local method = wsapi_env.headers["REQUEST_METHOD"]
	local handler

	-- supported methods
	if not self._methods then
		self._methods = _methods(self)
	end

	handler = self._methods[method]

	-- OPTIONS is special
	if method == "OPTIONS" and type(handler) ~= "function" then
		if not self._methods_allow then
			self._methods_allow = _allows(self._methods)
		end

		local h = plain_handler_generator(200, nil, {
			["Allow"] = self._methods_allow,
			})

		self._methods[method], handler = h, h
	end

	-- 405
	if not handler then
		if not self._handle405 then
			if not self._methods_allow then
				self._methods_allow = _allows(self._methods)
			end

			self._handle405 = plain_handler_generator(
				405, "Method Not Allowed", {
					["Allow"] = self._methods_allow,
				})
		end
		handler = self._handle405
	end

	return handler(wsapi_env)
end

Resource = C
