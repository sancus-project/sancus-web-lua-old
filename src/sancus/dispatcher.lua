--

require "sancus.object"
require "sancus.urlparser"
require "sancus.utils"
require "sancus.exc"

local coroutine, pairs, assert = coroutine, pairs, assert
local pf, format = sancus.utils.pformat, string.format
local Class = sancus.object.Class
local TemplateCompiler = sancus.urlparser.TemplateCompiler
local handle404 = sancus.exc.handle404

module (...)

local M = Class{ compile = TemplateCompiler }

function M:add_regex(template, handler, default)
	self.patterns[template] = { handler = handler, default = default or {} }
end

function M:add(template, handler, default)
	expr = self.compile(template)
	assert(expr ~= nil, format("invalid template: %s", template))
	return self:add_regex(expr, handler, default)
end

function M:make_app()
	return function (wsapi_env)
		local handler = self:find_handler(wsapi_env) or handle404

		return handler(wsapi_env)
	end
end

function M:find_handler(env)
	local script_name = env.headers["SCRIPT_NAME"] or ""
	local path_info = env.headers["PATH_INFO"] or ""
	local routing_args = env.headers["sancus.routing_args"] or {}

	for regex, t in pairs(self.patterns) do
		local c, p = regex:match(path_info)

		if p then
			local matched_path_info = path_info:sub(1, p-1)
			local extra_path_info = path_info:sub(p)

			if #extra_path_info == 0 or
				(#extra_path_info > 0 and extra_path_info:sub(1,1) == "/") then
				-- good match

				-- import captures
				for k,v in pairs(c) do
					routing_args[k] = v
				end
				-- and import default fields
				for k,v in pairs(t.default) do
					if not routing_args[k] then
						routing_args[k] = v
					end
				end

				env.headers["sancus.routing_args"] = routing_args
				env.headers["SCRIPT_NAME"] = script_name .. matched_path_info
				env.headers["PATH_INFO"] = extra_path_info

				return t.handler
			end
		end
	end
end

function PathMapper(o)
	o = M(o)
	o.patterns = o.patterns or {}
	return o
end
