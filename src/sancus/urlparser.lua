--

require "sancus.utils"

local lpeg = require("lpeg")
local P,R,S,V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local C,Cf,Cg,Ct = lpeg.C, lpeg.Cf, lpeg.Cg, lpeg.Ct

local assert, type, ipairs = assert, type, ipairs

local pp = function (...) print(sancus.utils.pprint(...)) end

module (...)

local function parser()
	local p

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

	-- Callbacks
	local h = {}

	function h.predicate(name, ...)
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

		return Cg(p or (segment^1), name) -- given options or any
	end

	function h.fold_literals(t)
		local r = {}

		for _, x in ipairs(t) do
			if type(x) == "string" and type(r[#r]) == "string" then
				r[#r] = r[#r] .. x
			else
				r[#r+1] = x
			end
		end

		for i, x in ipairs(r) do
			if type(x) == "string" then
				r[i] = P(x)
			end
		end
		return r
	end

	function h.fold(t)
		local q

		for _, x in ipairs(h.fold_literals(t)) do
			if q then
				q = q * x
			else
				q = x
			end
		end
		return q
	end

	function h.optional(...) return h.fold({...})^-1 end
	function h.eol(_) return eos end

	p = P{URL,
		URL = Data^1 * EOL,
		Data = Optional
			+ Predicate
			+ C(any),

		-- Optional <- "[" data "]"
		Optional = (bo * Data^1 * eo)/h.optional,

		-- Predicate <- "{" name (":" option ("|" option)*) "}"
		Name = C(identifier),
		Option = C(segment^1),

		Predicate = (P"{" * Name * (
			P":" * Option * (
				P"|" * Option
				)^0
			)^-1 * P"}")/h.predicate,

		-- $<eos> or <eos>
		EOL = (eol * eos)/h.eol + eos,
	}
	return Ct(p)/h.fold
end
parser = assert(parser())

function TemplateCompiler(t)
	return parser:match(t)
end
