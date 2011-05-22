--

require "sancus.object"
require "sancus.urlparser"
require "sancus.utils"

local coroutine, pairs, assert = coroutine, pairs, assert
local pprint = sancus.utils.pformat
local format = string.format
local Class = sancus.object.Class
local TemplateCompiler = sancus.urlparser.TemplateCompiler

module (...)

local M = Class{ compile = TemplateCompiler }

function M:add_regex(template, handler)
	self.patterns[template] = handler
end

function M:add(template, handler)
	expr = self.compile(template)
	assert(expr ~= nil, format("invalid template: %s", template))
	return self:add_regex(expr, handler)
end

function M:make_app()
	return function (wsapi_env)
		local headers = { ["Content-Type"] = "text/plain" }

		local function env_dump()
			local path_info = wsapi_env.headers["PATH_INFO"] or ""

			coroutine.yield(pprint(self, 'self'))
			for regex, handler in pairs(self.patterns) do
				local c, p = regex:match(path_info)
				if p then
					coroutine.yield(pprint(c, handler))
					break
				end
			end
			coroutine.yield(pprint(wsapi_env.headers, 'env'))
		end

		return 200, headers, coroutine.wrap(env_dump)
	end
end

function PathMapper(o)
	o = M.new(o)
	o.patterns = o.patterns or {}
	return o
end
