local lexer = require("lexer")

local parser = {
	tree = {},

	tokens = {},
	tokenIndex = 0,
	currentToken = nil,

	expect = function(self, type, contents)
		if (self.currentToken.type ~= type and (contents ~= nil and self.currentToken.contents == contents or true)) then
			local typeName = "[Invalid Type]"
			for k,v in pairs(TokenType) do
				if (v == type) then
					typeName = k
					break
				end
			end

			error("[Parser] expected %s:%s, got %s:%s", typeName, contents, self.currentToken.type, self.currentToken.contents)
		end

		return self.currentToken.contents
	end,

	next = function(self)
		if (self.tokenIndex + 1 == #self.tokens + 1) then
			currentToken = nil
			return
		elseif (self.tokenIndex > #self.tokens + 1) then
			error("Parser token underflow")
		end

		self.tokenIndex = self.tokenIndex + 1
		self.currentToken = self.tokens[self.tokenIndex]
	end,

	parse = function(self, source)
		self.tokens = lexer:lex(source)
		self:next()

		self:parseStatement()
	end,

	parseStatement = function(self)
		-- NOP
	end,


}

return setmetatable({}, {__index = parser})
