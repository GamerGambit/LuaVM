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

local function newUnaryPrefix(symbol, right)
	return {
		type = "unary-prefix",
		symbol = symbol,
		right = right
	}
end

return {
	{
		token = { type = TokenType.OPERATOR, contents = '-' },
		func = function(parser, token) return newUnaryPrefix('-', parser:parseExpression(14)) end
	},

	{
		token = { type = TokenType.OPERATOR, contents = "--" },
		func = function(parser, token) return newUnaryPrefix("--", parser:parseExpression(14)) end
	},

	{
		token = { type = TokenType.OPERATOR, contents = '+' },
		func = function(parser, token) return newUnaryPrefix('+', parser:parseExpression(14)) end
	},

	{
		token = { type = TokenType.OPERATOR, contents = "++" },
		func = function(parser, token) return newUnaryPrefix("++", parser:parseExpression(14)) end
	},

	{
		token = { type = TokenType.OPERATOR, contents = '~' },
		func = function(parser, token) return newUnaryPrefix('!', parser:parseExpression(14)) end
	},

	{
		token = { type = TokenType.OPERATOR, contents = '!' },
		func = function(parser, token) return newUnaryPrefix('!', parser:parseExpression(14)) end
	},

	{
		token = { type = TokenType.OPERATOR, contents = '#' },
		func = function(parser, token) return newUnaryPrefix('#', parser:parseExpression(14)) end
	},

	{
		token = { type = TokenType.BRK_PAREN, contents = '(' },
		func = function(parser, token)
			local expr = parser:parseExpression(0)
			parser:expect(TokenType.BRK_PAREN, ')')
			return expr
		end
	},

	{
		token = { type = TokenType.IDENTIFIER },
		func = function(parser, token) return newIdentifier(token.contents) end
	},

	{
		token = { type = TokenType.LITERAL_N },
		func = function(parser, token) return newLiteral("number", token.contents) end
	},

	{
		token = { type = TokenType.LITERAL_S },
		func = function(parser, token) return newLiteral("string", token.contents) end
	},

	{
		token = { type = TokenType.KEYWORD, contents = "true" },
		func = function(parser, token) return newLiteral("boolean", token.contents) end
	},

	{
		token = { type = TokenType.KEYWORD, contents = "false" },
		func = function(parser, token) return newLiteral("boolean", token.contents) end
	},

	{
		token = { type = TokenType.KEYWORD, contents = "null" },
		func = function(parser, token) return newLiteral("null") end
	}
}
