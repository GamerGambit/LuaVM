local lexer = require("lexer")

local ASSOCIATIVITY_LEFT = 0
local ASSOCIATIVITY_RIGHT = 0
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

local function newUnaryPostfix(symbol, operand)
	return {
		type = "unary-postfix",
		symbol = symbol,
		operand = operand
	}
end

local function newArray(sequenceExpr)
	return{
		type = "array-definition",
		sequenceExpr = sequenceExp
	}
end

local function newSubScript(operand, expr)
	return {
		type = "subscript",
		operand = operand,
		expr = expr
	}
end

local function newUnaryPrefix(symbol, operand)
	return {
		type = "unary-prefix",
		operand = operand
	}
end

local function newBinaryOperator(symbol, left, right)
	return {
		type = "binary-operator",
		symbol = symbol,
		left = left,
		right = right
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

			error(string.format("[Parser] expected %s, got %s:%s", (msg and msg) or (expectedTypeName .. (contents and ":" .. contents or "")), gotTypeName, self.currentToken.contents))
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
			local exprRes = self:parseExpression(0, nil, CLOSE_PAREN_IGNORE)
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

		local expr
		local exprPrecedence

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
					local res = self:parseExpression(0, nil, CLOSE_PAREN_TERMINATE)
					if (not res.success) then
						error("[Parser] Expected statement")
					else
						expr = res.data
					end
				-- )
				elseif (self.currentToken.contents == ')') then
					if (closeParenTreatment == CLOSE_PAREN_TERMINATE) then
						self:next()
						return {success = true, data = prevExpr, precedence = 0}
					elseif (closeParenTreatment == CLOSE_PAREN_IGNORE) then
						return {success = false}
					end
				end

				if (precedence < 1) then
					-- TODO add function call
					if (self.currentToken.contents == "++" or self.currentToken.contents == "--") then
						if (prevExpr ~= nil) then
							expr = newUnaryPostfix(self.currentToken.contents, prevExpr)
							exprPrecedence = 0
							self:next()
						end

					elseif (self.currentToken.contents == '[') then
						self:next()

						local res = self:parseExpression(0, nil, closeParenTreatment)

						if (prevExpr == nil) then
							expr = newArray(res.data)
						else
							expr = newSubScript(prevExpr, res.data)
						end

						self:expect(TokenType.OPERATOR, ']')
						exprPrecedence = 0

					elseif (self.currentToken.contents == '.') then
						self:next()
						if (prevExpr == nil) then
							error("[Parser] expected expressions")
						else
							expr = newBinaryOperator('.', prevExpr, newLiteral("string", self:expect(TokenType.IDENTIFIER)))
							exprPrecedence = 0
						end
					end
				end

				if (expr == nil and precedence < 2 and (self.currentToken.contents == '!' or
						  self.currentToken.contents == "++" or self.currentToken.contents == "--" or
						  self.currentToken.contents == '-' or self.currentToken.contents == '+' or
						  self.currentToken.contents == '~' or self.currentToken.contents == '#')) then
					local currentContents = self.currentToken.contents
					self:next()
					local res = self:parseExpression(0, nil, closeParenTreatment)
					if (not res.success) then
						error("[Parser] expected expression")
					else
						expr = newUnaryPrefix(currentContents, res.data)
						exprPrecedence = 1
					end
				end

				if (expr == nil and precedence < 3 and self.currentToken.contents == "**") then
					self:next()
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator("**", prevExpr, res.data)
							exprPrecedence = 2
						end
					end
				end

				if (expr == nil and precedence < 4 and (self.currentToken.contents == '*' or
					 self.currentToken.contents == '/' or self.currentToken.contents == '%')) then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						local currentContents = self.currentToken.contents
						self:next()
						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator(currentContents, prevExpr, res.data)
							exprPrecedence = 3
						end
					end
				end

				if (expr == nil and precedence < 5 and (
					self.currentToken.contents == '-' or self.currentToken.contents == '+'
					)) then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						local currentContents = self.currentToken.contents
						self:next()
						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator(currentContents, prevExpr, res.data)
							exprPrecedence = 4
						end
					end
				end

				if (expr == nil and precedence < 6 and (
					self.currentToken.contents == "<<" or self.currentToken.contents == ">>"
					)) then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						local currentContents = self.currentToken.contents
						self:next()
						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator(currentContents, prevExpr, res.data)
							exprPrecedence = 5
						end
					end
				end

				if (expr == nil and precedence < 7 and (
					self.currentToken.contents == '>' or self.currentToken.contents == '<' or
					self.currentToken.contents == ">=" or self.currentToken.contents == "<=")) then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						local currentContents = self.currentToken.contents
						self:next()

						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression ")
						else
							expr = newBinaryOperator(currentContents, prevExpr, res.data)
							exprPrecedence = 6
						end
					end
				end

				if (expr == nil and precedence < 8 and (
					self.currentToken.contents == "==" or self.currentToken.contents == "!="
					)) then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						local currentContents = self.currentToken.contents
						self:next()

						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator(currentContents, prevExpr, res.data)
							exprPrecedence = 7
						end
					end
				end

				if (expr == nil and precedence < 9 and self.currentToken.contents == '&') then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						self:next()
						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator('&', prevExpr, res.data)
							exprPrecedence = 8
						end
					end
				end

				if (expr == nil and precedence < 10 and self.currentToken.contents == '^') then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						self:next()

						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator('^', prevExpr, res.data)
							exprPrecedence = 9
						end
					end
				end

				if (expr == nil and precedence < 11 and self.currentToken.contents == '&') then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						self:next()

						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator('&', prevExpr, res.data)
							exprPrecedence = 10
						end
					end
				end

				if (expr == nil and precedence < 12 and self.currentToken.contents == "&&") then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						self:next()

						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator("&&", prevExpr, res.data)
							exprPrecedence = 11
						end
					end
				end

				if (expr == nil and precedence < 13 and self.currentToken.contents == "^^") then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						self:next()

						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator("^^", prevExpr, res.data)
							exprPrecedence = 12
						end
					end
				end

				if (expr == nil and precedence < 14 and self.currentToken.contents == "||") then
					if (prevExpr == nil) then
						error("[Parser] expected expression")
					else
						self:next()

						local res = self:parseExpression(0, nil, closeParenTreatment)
						if (not res.success) then
							error("[Parser] expected expression")
						else
							expr = newBinaryOperator("||", prevExpr, res.data)
							exprPrecedence = 13
						end
					end
				end

				if (expr == nil) then
					return {success = false}
				end

		-- identifier
		elseif (self.currentToken.type == TokenType.IDENTIFIER) then
			expr = newIdentifier(self.currentToken.contents)
			exprPrecedence = 0
			self:next()

		-- literal_n
		elseif (self.currentToken.type == TokenType.LITERAL_N) then
			expr = newLiteral("number", self.currentToken.contents)
			exprPrecedence = 0
			self:next()

		-- literal_s
		elseif (self.currentToken.type == TokenType_LITERAL_S) then
			expr = newLiteral("string", self.currentToken.contents)
			exprPrecedence = 0
			self:next()

		-- token is assumed to be an operator
		-- TODO precedence-based parsing
		end

		if (expr == nil) then
			return {success = false}
		end

		local associativity = ASSOCIATIVITY_LEFT
		if (exprPrecedence == 2 or exprPrecedence == 3 or exprPrecedence == 15) then
			associativity = ASSOCIATIVITY_RIGHT
		end

		local nextExpr = {success = true, data = expr, precedence = exprPrecedence}
		repeat
			local res = self:parseExpression((associativity == ASSOCIATIVITY_LEFT) and nextExpr.precedence or nextExpr.precedence - 1, nextExpr.data, closeParenTreatment)
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
