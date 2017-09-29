local lexer = require("lexer")

local function newFunctionDefinition(name)
	return {
		type = "function-definition",
		name = name,
		params = {},
		eval = {}
	}
end

local function newFunctionParameter(name, default)
	return {
		type = "function-parameter",
		name = name,
		default = default
	}
end

local parser = {
	tree = {},

	tokens = {},
	tokenIndex = 0,
	currentToken = nil,

	expect = function(self, type, contents, msg)
		if (self.currentToken == nil) then error("[Parser] Unexpected end of file") end

		if (self.currentToken.type ~= type and (contents ~= nil and self.currentToken.contents == contents or true)) then
			local expectedTypeName = "[Invalid Type]"
			local gotTypeName = "[Invalid Type]"
			for k,v in pairs(TokenType) do
				if (v == type) then expectedTypeName = k end
				if (v == self.currentToken.type) then gotTypeName = k end
			end

			return error(string.format("[Parser] expected %s, got %s:%s", msg and msg or expectedTypeName and (contents and ":" .. contents or ""), gotTypeName, self.currentToken.contents))
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
		local funcResult = self:parseFunctionDefinition()
		if (funcResult.success) then
			 return {success = true, data = funcResult.data}
		elseif (funcResult.error) then
			return funcResult
		end

		return {success = false}
	end,

	parseFunctionDefinition = function(self)
		if (not (self.currentToken.type == TokenType.KEYWORD and self.currentToken.contents == "function")) then
			return {success = false}
		end

		self:next()

		local func = newFunctionDefinition(self:expect(TokenType.IDENTIFIER))

		self:expect(TokenType.OPERATOR, '(')

		while (not (self.currentToken.type == TokenType.OPERATOR and self.currentToken.contents == ')')) do
			if (#func.params >= 1) then
				self:expect(TokenType.OPERATOR, ',')
			end

			table.insert(func.params, self:parseFunctionParameter().data)
		end

		self:expect(TokenType.OPERATOR, ')')
		self:expect(TokenType.OPERATOR, '{')

		while (self.currentToken.type ~= TokenType.OPERATOR and self.currentToken.contents ~= '}') do
			table.insert(func.eval, self:parseStatement().data)
		end

		self:expect(TokenType.OPERATOR, '}')

		return {success = true, data = func}
	end,

	parseFunctionParameter = function(self)
		if (self.currentToken.type ~= TokenType.IDENTIFIER) then
			return {success = false}
		end

		local funcParam = newFunctionParameter(self.currentToken.contents)

		self:next()

--[[
		-- TODO add parameter defaults when expression parsing is done
		if (self.currentToken.type == TokenType.OPERATOR and self.currentToken.contents == '=') then
			self:next()
			funcParam.default = self:parseExpression()
		end
]]

		return {success = true, data = funcParam}
	end
}

return setmetatable({}, {__index = parser})
