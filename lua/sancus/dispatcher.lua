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
	t = self.urls or {}
	if not self.urls then
		self.urls = t
	end

	t[#t+1] = {
		template = template,
		handler = handler,
	}
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

PathMapper = M.new
