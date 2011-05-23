--

require "coroutine"
local coroutine = coroutine

module (...)

local function generate_plain_handler(status, text)
	local headers = { ["Content-Type"] = "text/plain" }
	local f = function () coroutine.yield(text) end

	-- we cannot resume dead coroutine, so wrap f each time
	return function(wsapi_env) return status, headers, coroutine.wrap(f) end
end

handle404 = generate_plain_handler(404, "Not Found")
