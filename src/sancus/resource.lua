--

require "sancus.object"

local coroutine = coroutine
local tconcat = table.concat
local pairs = pairs

local Class = sancus.object.Class

module (...)

local C = Class()
local C_new = C.new

function C:new(o)
	o = C_new(C, o)
	o.methods = {}
	for _, method in pairs{"GET", "POST", "PUT", "DELETE"} do
		if o[method] then
			o.methods[method] = o[method]
		end
	end
	o.methods["HEAD"] = o["HEAD"] or o.methods["GET"]
	return o
end

function C:__call(wsapi_env)
	local method = wsapi_env.headers["REQUEST_METHOD"]
	local handler = self.methods[method]

	-- 405
	if not handler then
		if not self._methods_allow then
			local allow = {}
			for k,_ in pairs(self.methods) do
				allow[#allow+1] = k
			end
			self._methods_allow = tconcat(allow, ", ")
		end

		local headers = {
			["Content-Type"] = "text/plain",
			["Allow"] = self._methods_allow,
		}

		local function f405()
			coroutine.yield("Method Not Allowed")
		end

		return 405, headers, coroutine.wrap(f405)
	end

	return handler(wsapi_env)
end

Resource = C
