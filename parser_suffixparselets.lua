local infixOperators = require("parser_infixoperators")

local function newSubscript(left)
	return {
		type = "subscript",
		left = left,
		exprs = {}
	}
end

local function newFunctionCall(funcExpr)
	return {
		type = "function-call",
		funcExpr = funcExpr,
		args = {}
	}
end

local function newUnaryPostfix(left, symbol)
	return {
		type = "unary-postfix",
		left = left,
		symbol = symbol
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

local function newTernaryOperator(condExpr, thenExpr, elseExpr)
	return {
		type = "ternary-operator",
		condExpr = condExpr,
		thenExpr = thenExpr,
		elseExpr = elseExpr
	}
end

return {
	{
		token = { type = TokenType.OPERATOR },
		func = function(parser, left, token)
			if (token.contents == "--" or token.contents == "++") then
				return newUnaryPostfix(left, token.contents)
			end

			local operator = infixOperators[token.contents]
			assert(operator ~= nil, "Invalid infix operator " .. tostring(token.contents))

			local right = parser:parseExpression(math.max(0, operator.precedence - (operator.rightAssociative and 1 or 0)))

			if (token.contents == '?') then
				parser:expect(TokenType.OPERATOR, ':')
				local elseExpr = parser:parseExpression(0)
				return newTernaryOperator(left, right, elseExpr)
			end

			return newBinaryOperator(token.contents, left, right)
		end
	},

	{
		token = { type = TokenType.BRK_PAREN, contents = '(' },
		func = function(parser, left, token)
			local funcCall = newFunctionCall(left)

			if (not parser:eos() and not (parser.currentToken.type == TokenType.BRK_PAREN and parser.currentToken.contents == ')')) then
				repeat
					table.insert(funcCall.args, parser:parseExpression(0))
				until (parser:eos() or parser.currentToken.type ~= TokenType.COMMA)
			end

			parser:expect(TokenType.BRK_PAREN, ')')

			return funcCall
		end
	},

	{
		token = { type = TokenType.BRK_SQUARE, contents == '[' },
		func = function(parser, left, token)
			local subscript = newSubscript(left)

			if (parser:eos() or parser.currentToken.type == TokenType.BRK_SQUARE and parser.currentToken.contents == ']') then
				error("[Parser] expected expression")
			end

			repeat
				table.insert(subscript.exprs, parser:parseExpression(0))
			until (parser:eos() or parser.currentToken.type ~= TokenType.COMMA)

			parser:expect(TokenType.BRK_SQUARE, ']')

			return subscript
		end
	},

	{
		token = { type = TokenType.DOT },
		func = function(parser, left, token)
			return newBinaryOperator('.', left, { type = "identifier", identifier = parser:expect(TokenType.IDENTIFIER) })
		end
	}
}
