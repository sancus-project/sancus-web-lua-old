--

require "sancus.utils"

local lpeg = require("lpeg")
local P,R,S,V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local C,Cg,Ct,Cp = lpeg.C, lpeg.Cg, lpeg.Ct, lpeg.Cp

local assert, type, ipairs = assert, type, ipairs

module (...)


local function patt_concat(...)
	local p
	for i, x in ipairs({...}) do
		if type(x) == "string" then
			x = P(x) -- literal patterns
		end

		if p then
			p = p * x
		else
			p = x
		end
	end
	return p
end

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
	local Lookup, Name, Option = V"Lookup", V"Name", V"Option"
	local Optional = V"Optional"

	-- Callbacks
	local h = {}

	function h.lookup(name, ...)
		local q
		for _, x in ipairs({...}) do
			if type(x) == "string" then
				x = P(x) -- literal patterns
			end

			if q then
				q = q + x
			else
				q = x
			end
		end

		return Cg(q or (segment^1), name) -- given options or any
	end

	function h.optional(...) return patt_concat(...)^-1 end
	function h.eol(_) return eos end

	return P{URL,
		URL = Data^1 * EOL,
		Data = Optional
			+ Lookup
			+ C(any),

		-- Optional <- "[" data "]"
		Optional = (bo * Data^1 * eo)/h.optional,

		-- Lookup <- "{" name (":" option ("|" option)*) "}"
		Name = C(identifier),
		Option = C(segment^1),

		Lookup = (P"{" * Name * (
			P":" * Option * (
				P"|" * Option
				)^0
			)^-1 * P"}")/h.lookup,

		-- $<eos> or <eos>
		EOL = (eol * eos)/h.eol + eos,
	}
end
parser = assert(parser())

function TemplateCompiler(t)
	p = patt_concat(parser:match(t))
	if p then
		return Ct(p) * Cp()
	end
end
