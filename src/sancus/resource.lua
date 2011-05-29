--

require "sancus.object"

local coroutine = coroutine
local tconcat = table.concat
local pairs, type = pairs, type

local Class = sancus.object.Class

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

		local headers = {
			["Content-Type"] = "text/plain",
			["Allow"] = self._methods_allow,
		}

		local function h(_)
			return 200, headers, function() end
		end

		self._methods[method], handler = h, h
	end

	-- 405
	if not handler then
		if not self._handle405 then
			if not self._methods_allow then
				self._methods_allow = _allows(self._methods)
			end

			local headers = {
				["Content-Type"] = "text/plain",
				["Allow"] = self._methods_allow,
			}

			local function f405()
				coroutine.yield("Method Not Allowed")
			end

			local function h(_)
				return 405, headers, coroutine.wrap(f405)
			end

			self._handle405 = h
		end
		handler = self._handle405
	end

	return handler(wsapi_env)
end

Resource = C
