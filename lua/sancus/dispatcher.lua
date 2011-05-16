--

require "sancus.object"
require "sancus.urlparser"
require "sancus.utils"

local coroutine = coroutine
local pprint = sancus.utils.pprint
local Class = sancus.object.Class
local TemplateCompiler = sancus.urlparser.TemplateCompiler

module (...)

local M = Class{ compile = TemplateCompiler }

function M:add_regex(template, handler)
	self.patterns[template] = handler
end

function M:add(template, handler)
	expr = self.compile(template)
	return self:add_regex(expr, handler)
end

function M:make_app()
	return function (wsapi_env)
		local headers = { ["Content-Type"] = "text/plain" }

		local function env_dump()
			coroutine.yield(pprint(self, 'self'))
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
