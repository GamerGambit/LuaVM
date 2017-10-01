local lexer = require("lexer")

local LOWEST_PRECEDENCE = 16
local CLOSE_PAREN_IGNORE = 0
local CLOSE_PAREN_TERMINATE = 1

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

local function newLiteral(type, value)
	return {
		type = "literal-" .. type,
		value = value
	}
end

local function newIdentifier(identifier)
	return {
		type = "identifier",
		identifier = identifier
	}
end

local parser = {
	tree = {},

	tokens = {},
	tokenIndex = 0,
	currentToken = nil,

	-- end of stream
	eos = function(self)
		return self.currentToken == nil
	end,

	expect = function(self, type, contents, msg)
		if (self:eos()) then error("[Parser] Unexpected end of file") end

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

		while (not self:eos()) do
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
				self:expect(TokenType.COMMA)
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

		if (self.currentToken.type == TokenType.OPERATOR and self.currentToken.contents == '=') then
			self:next()
			local exprRes = self:parseExpression(LOWEST_PRECEDENCE, nil, CLOSE_PAREN_IGNORE)
			if (not exprRes.success) then
				error("[Parser] Expected expression")
			else
				funcParam.default = exprRes.data
			end
		end

		return {success = true, data = funcParam}
	end,

	parseExpression = function(self, precedence, prevExpr, closeParenTreatment)
		if (self.currentToken == nil) then
			return {success = false}
		end

		precedence = precedence or 0

		local expr

		-- keyword
		if (self.currentToken.type == TokenType.KEYWORD) then
			-- `true` or `false`
			if (self.currentToken.contents == "true" or self.currentToken.contents == "false") then
				expr = newLiteralBoolean(self.currentToken.contents)
				self:next()
			end

		-- ( and )
		elseif (self.currentToken.type == TokenType.OPERATOR) then
				-- (
				 if (self.currentToken.contents == '(') then
					self:next()
					local res = self:parseExpression(LOWEST_PRECEDENCE, nil, CLOSE_PAREN_TERMINATE)
					if (not res.success) then
						error("[Parser] Expected statement")
					else
						expr = res.data
					end
				-- )
				elseif (self.currentToken.contents == ')') then
					if (closeParenTreatment == CLOSE_PAREN_TERMINATE) then
						self:next()
						return {success = true, data = prevExpr}
					elseif (closeParenTreatment == CLOSE_PAREN_IGNORE) then
						return {success = false}
					end
				else
					return {success = false}
				end

		-- identifier
		elseif (self.currentToken.type == TokenType.IDENTIFIER) then
			expr = newIdentifier(self.currentToken.contents)
			self:next()

		-- literal_n
		elseif (self.currentToken.type == TokenType.LITERAL_N) then
			expr = newLiteral("number", self.currentToken.contents)
			self:next()

		-- literal_s
		elseif (self.currentToken.type == TokenType_LITERAL_S) then
			expr = newLiteral("string", self.currentToken.contents)
			self:next()

		-- token is assumed to be an operator
		-- TODO precedence-based parsing
		end

		if (expr == nil) then
			return {success = false}
		end

		local nextExpr = {success = true, data = expr, precedence = exprPrecedence}
		repeat
			-- TODO associativity
			local res = self:parseExpression(0, nextExpr.data, closeParenTreatment)
			if (not res.success) then
				break
			else
				nextExpr = res
			end
		until (nextExpr.precedence >= exprPrecedence)

		return {success = true, data = nextExpr.data, closeParenTreatment = closeParenTreatment, precedence = exprPrecedence}
	end
}

return setmetatable({}, {__index = parser})
