--

require "CodeGen"
require "lfs"

require "sancus.utils"

local lfs, coroutine, CodeGen = lfs, coroutine, CodeGen
local sformat, fopen = string.format, io.open
local assert, pairs = assert, pairs

local trim = sancus.utils.trim

module(...)

function loaddir_raw(dir, prefix, out)
	prefix = prefix or ""
	out = out or {}

	for fn in lfs.dir(dir) do
		if not fn:match("^[.]") then
			local ffn = sformat("%s/%s", dir, fn)
			if lfs.attributes(ffn, "mode") == "directory" then
				loaddir_raw(ffn, sformat("%s%s_", prefix, fn), out)
			else
				local bn = fn:match("^(.*)[.]([^.]+)$") or fn
				local f = assert(fopen(ffn, "r"))

				out[prefix..bn] = trim(f:read("*all"))
				f:close()
			end
		end
	end

	return out
end

function loaddir(dir, prefix, out)
	return CodeGen(loaddir_raw(dir, prefix or '', out or {}))
end

function renderer(env, default_headers)
	return function (template, data, status, headers)
		data = data or {}
		headers = headers or {}
		status = status or 200

		for k,v in pairs(default_headers) do
			if not headers[k] then
				headers[k] = v
			end
		end

		local function body()
			coroutine.yield(CodeGen(data, env)(template))
		end

		return status, headers, coroutine.wrap(body)
	end
end
