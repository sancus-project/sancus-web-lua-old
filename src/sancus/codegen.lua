--

require "CodeGen"
require "lfs"

local lfs, CodeGen = lfs, CodeGen
local sformat, fopen = string.format, io.open
local assert = assert

module(...)

function loaddir_raw(dir, out, prefix)
	prefix = prefix or ""
	out = out or {}

	for fn in lfs.dir(dir) do
		if not fn:match("^[.]") then
			local ffn = sformat("%s/%s", dir, fn)
			if lfs.attributes(ffn, "mode") == "directory" then
				loaddir_raw(ffn, out, sformat("%s%s_", prefix, fn))
			else
				local bn = fn:match("^(.*)[.]([^.]+)$") or fn
				local f = assert(fopen(ffn, "r"))

				out[prefix..bn] = f:read("*all")
				f:close()
			end
		end
	end

	return out
end

function loaddir(dir, prefix)
	return CodeGen(loaddir_raw(dir, {}, prefix))
end
