--

require "sancus.utils"

local lpeg = require("lpeg")
local P,R,S,V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local C,Cg,Ct = lpeg.C, lpeg.Cg, lpeg.Ct

local assert = assert

local pp = function (...) print(sancus.utils.pprint(...)) end

module (...)

local function parser()
	-- Lexical Elements
	local alpha = R("az","AZ")
	local num = R"09"
	local alpha_num = alpha + num
	local identifier = alpha * (alpha_num + P"_")^0
	local segment = alpha_num + S"-_.,%"
	local any = segment + P"/"

	local eol, eos = P"$", P(-1)
	local bo, eo = P"[", P"]"

	-- Grammar
	local URL, EOL = V"URL", V"EOL"
	local Data = V"Data"
	local Predicate, Name, Option = V"Predicate", V"Name", V"Option"
	local Optional = V"Optional"

	return P{URL,
		URL = Data^1 * EOL,
		Data = Optional
			+ Predicate
			+ C(any),

		-- Optional <- "[" data "]"
		Optional = Ct(bo * Data^1 * eo),

		-- Predicate <- "{" name (":" option ("|" option)*) "}"
		Name = C(identifier),
		Option = C(segment^1),

		Predicate = Ct(P"{" * Name * (
			P":" * Option * (
				P"|" * Option
				)^0
			)^-1 * P"}"),

		-- $<eos> or <eos>
		EOL = (eol * eos) + eos,
	}
end
parser = assert(parser())

function TemplateCompiler(t)
	local m = { parser:match(t) }

	if #m == 0 then
		return nil
	else
		return m
	end
end