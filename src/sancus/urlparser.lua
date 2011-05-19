--

require "sancus.utils"

local lpeg = require("lpeg")
local P,R,S,C,V = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.V

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

	-- Grammar
	local URL, EOL = V"URL", V"EOL"
	local Data = V"Data"
	local Predicate, Name, Option = V"Predicate", V"Name", V"Option"
	local Optional = V"Optional"

	local function token(t)
		return function(s)
			if s == "" then
				s = nil
			end
			pp(s, t)
		end
	end

	return P{URL,
		URL = Data * EOL,
		Data = (Optional + Predicate + any)^1,

		-- Optional <- "[" data "]"
		Optional = (P"[" * Data * P"]")/token("optional"),

		-- Predicate <- "{" name (":" option ("|" option)*) "}"
		Name = identifier/token("name"),
		Option = (segment^1)/token("option"),
		Predicate = P"{" * Name * (
			P":" * Option * (
				P"|" * Option
				)^0
			)^-1 * P"}",

		-- $<eos> or <eos>
		EOL = (eol * eos)/token("eol") + eos,
	}
end
parser = assert(parser())

function TemplateCompiler(t)
	return { parser:match(t) }
end
