local lexer = require("lexer")

local function newFunction(name)
	return {
		type = "function",
		name = name,
		params = {}
	}
end

local parser = {
	tree = {},

	tokens = {},
	tokenIndex = 0,
	currentToken = nil,

	expect = function(self, type, contents)
		if (self.currentToken == nil) then error("[Parser] Unexpected end of file") end

		if (self.currentToken.type ~= type and (contents ~= nil and self.currentToken.contents == contents or true)) then
			local expectedTypeName = "[Invalid Type]"
			local gotTypeName = "[Invalid Type]"
			for k,v in pairs(TokenType) do
				if (v == type) then expectedTypeName = k end
				if (v == self.currentToken.type) then gotTypeName = k end
			end

			error(string.format("[Parser] expected %s:%s, got %s:%s", expectedTypeName, contents, gotTypeName, self.currentToken.contents))
		end

		local currentContents = self.currentToken.contents

		self:next()

		return currentContents
	end,

	next = function(self)
		if (self.tokenIndex + 1 == #self.tokens + 1) then
			self.currentToken = nil
			return
		elseif (self.tokenIndex > #self.tokens + 1) then
			error("Parser token underflow")
		end

		self.tokenIndex = self.tokenIndex + 1
		self.currentToken = self.tokens[self.tokenIndex]
	end,

	parse = function(self, source)
		self.tree = {}
		self.tokens = lexer:lex(source)
		self.tokenIndex = 0
		self:next()

		self:parseStatement()
	end,

	parseStatement = function(self)
		if (self.currentToken.type == TokenType.KEYWORD) then
			if (self.currentToken.contents == "function") then
				self:next()
				self:parseFunction()
			end
		end
	end,

	parseFunction = function(self)
		table.insert(self.tree, newFunction(self:expect(TokenType.IDENTIFIER)))
		local func = self.tree[#self.tree]

		self:expect(TokenType.OPERATOR, '(')

		while (not (self.currentToken.type == TokenType.OPERATOR and self.currentToken.contents == ')')) do
			if (#func.params >= 1) then
				self:expect(TokenType.OPERATOR, ',')
			end

			table.insert(func.params, self:expect(TokenType.IDENTIFIER))
		end

		self:expect(TokenType.OPERATOR, ')')
		self:expect(TokenType.OPERATOR, '{')

		while (self.currentToken.type ~= TokenType.OPERATOR and self.currentToken.contents ~= '}') do
			self:parseStatement()
		end

		self:expect(TokenType.OPERATOR, '}')
	end
}

return setmetatable({}, {__index = parser})
