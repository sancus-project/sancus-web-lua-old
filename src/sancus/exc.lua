--

require "coroutine"
local coroutine = coroutine

module (...)

function plain_handler_generator(status, text, headers)
	local f = function () coroutine.yield(text) end

	headers = headers or {}
	headers["Content-Type"] = "text/plain; charset=UTF-8"

	-- we cannot resume dead coroutine, so wrap f each time
	return function(wsapi_env) return status, headers, coroutine.wrap(f) end
end

handle404 = plain_handler_generator(404, "Not Found")
