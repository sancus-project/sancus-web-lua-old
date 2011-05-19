--

require "sancus.utils"

local lpeg = require("lpeg")
local P,R,S,C,V = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.V

local assert = assert

local pp = function (...) print(sancus.utils.pprint(...)) end

module (...)

local function parser()
	local h, stack = {}, {}

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

	-- callbacks
	function h.literal(s) pp(s, "literal") end

	function h.predicate(s) pp(s, "predicate") end
	function h.name(s) pp(s, "name") end
	function h.option(s) pp(s, "option") end

	function h.begin_optional(s) pp(s, "begin optional") end
	function h.end_optional(s) pp(s, "end optional") end

	function h.eol(s) pp(s, "eol") end

	return P{URL,
		URL = Data^1 * EOL,
		Data = Optional
			+ Predicate/h.predicate
			+ any/h.literal,

		-- Optional <- "[" data "]"
		Optional = bo/h.begin_optional
			* Data^1
			* eo/h.end_optional,

		-- Predicate <- "{" name (":" option ("|" option)*) "}"
		Name = identifier/h.name,
		Option = (segment^1)/h.option,

		Predicate = P"{" * Name * (
			P":" * Option * (
				P"|" * Option
				)^0
			)^-1 * P"}",

		-- $<eos> or <eos>
		EOL = (eol * eos)/h.eol + eos,
	}
end
parser = assert(parser())

function TemplateCompiler(t)
	return { parser:match(t) }
end
