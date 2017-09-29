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

			return {success = false, data = nil, error = string.format("[Parser] expected %s:%s, got %s:%s", expectedTypeName, contents, gotTypeName, self.currentToken.contents)}
		end

		local currentContents = self.currentToken.contents

		self:next()

		return {success = true, data = currentContents, error = nil}
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

		while (self.currentToken ~= nil) do
			local res = self:parseStatement()

			if (not res.success) then
				error(res.error)
			else
				table.insert(self.tree, res.data)
			end
		end
	end,

	parseStatement = function(self)
		local funcResult = self:parseFunction()
		if (not funcResult.success) then
			return funcResult
		end

		return {success = true, data = funcResult.data}
	end,

	parseFunction = function(self)
		if (not (self.currentToken.type == TokenType.KEYWORD and self.currentToken.contents == "function")) then
			return {success = false}
		end

		self:next()

		local nameRes = self:expect(TokenType.IDENTIFIER)
		if (not nameRes.success) then
			return nameRes
		end

		local func = newFunction(nameRes.data)

		do
			local result = self:expect(TokenType.OPERATOR, '(')
			if (not result.success) then
				return result
			end
		end

		while (not (self.currentToken.type == TokenType.OPERATOR and self.currentToken.contents == ')')) do
			if (#func.params >= 1) then
				local result = self:expect(TokenType.OPERATOR, ',')
				if (not result.success) then
					return result
				end
			end

			local paramNameRes = self:expect(TokenType.IDENTIFIER)
			if (not paramNameRes.success) then
				return paramNameRes
			end

			table.insert(func.params, paramNameRes.data)
		end

		do
			local result = self:expect(TokenType.OPERATOR, ')')
			if (not result.success) then
				return result
			end
		end

		do
			local result = self:expect(TokenType.OPERATOR, '{')
			if (not result.success) then
				return result
			end
		end

		while (self.currentToken.type ~= TokenType.OPERATOR and self.currentToken.contents ~= '}') do
			local stmtResult = self:parseStatement()
			if (not stmtResult.success) then
				return stmtResult
			end
		end

		do
			local res = self:expect(TokenType.OPERATOR, '}')
			if (not res.success) then
				return res
			end
		end

		return {success = true, data = func, error = nil}
	end
}

return setmetatable({}, {__index = parser})
