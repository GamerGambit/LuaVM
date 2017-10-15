local lexer = require("lexer")
local infixOperators = require("parser_infixoperators")
local prefixParselets = require("parser_prefixparselets")
local suffixParselets = require("parser_suffixparselets")

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

	reconstruct = function(self)
		local function reconstructNode(node)
			if (string.sub(node.type, 1, 7) == "literal") then
				return node.value

			elseif (node.type == "identifier") then
				return node.identifier

			elseif (node.type == "unary-prefix") then
				return node.symbol .. reconstructNode(node.right)

			elseif (node.type == "subscript") then
				local str = reconstructNode(node.left) .. '['

				for k, v in ipairs(node.exprs) do
					if (k > 1) then str = str .. ", " end
					str = str .. reconstructNode(v)
				end

				str = str .. ']'
				return str

			elseif (node.type == "function-call") then
				local str = reconstructNode(node.funcExpr) .. '('

				for k, v in ipairs(node.args) do
					if (k > 1) then str = str .. ", " end
					str = str .. reconstructNode(v)
				end

				str = str .. ')'
				return str

			elseif (node.type == "unary-postfix") then
				return reconstructNode(node.left) .. node.symbol

			elseif (node.type == "binary-operator") then
				return reconstructNode(node.left) .. ' ' .. node.symbol .. ' ' .. reconstructNode(node.right)

			elseif (node.type == "ternary-operator") then
				return reconstructNode(node.condExpr) .. ") ? (" .. reconstructNode(node.thenExpr) .. " ) : (" .. reconstructNode(node.elseExpr)
			end
		end

		local str = ""
		for k, v in ipairs(self.tree) do
			str = str .. reconstructNode(v)
		end

		print(str)
	end,

	parse = function(self, source)
		self.tree = {}
		self.tokens = lexer:lex(source)
		self.tokenIndex = 0
		self:next()

		while (not self:eos()) do
			local res = self:parseExpression(0)

			if (res ~= nil) then
				table.insert(self.tree, res)
			else
				print("nil expression")
				break
			end
		end
	end,

	parseFunctionDefinition = function(self)
		if (self:eos() or not (self.currentToken.type == TokenType.KEYWORD and self.currentToken.contents == "function")) then return end

		self:next()

		local func = newFunctionDefinition(self:expect(TokenType.IDENTIFIER))

		self:expect(TokenType.BRK_PAREN, '(')

		while (not (self.currentToken.type == TokenType.BRK_PAREN and self.currentToken.contents == ')')) do
			if (#func.params >= 1) then
				self:expect(TokenType.COMMA)
			end

			table.insert(func.params, self:parseFunctionParameter().data)
		end

		self:expect(TokenType.BRK_PAREN, ')')
		self:expect(TokenType.OPERATOR, '{')

		while (self.currentToken.type ~= TokenType.OPERATOR and self.currentToken.contents ~= '}') do
			table.insert(func.eval, self:parseStatement().data)
		end

		self:expect(TokenType.OPERATOR, '}')

		return func
	end,

	parseFunctionParameter = function(self)
		if (self:eos()) then return end

		local funcParam = newFunctionParameter(self.currentToken.contents)

		self:next()

		if (self.currentToken.type == TokenType.OPERATOR and self.currentToken.contents == '=') then
			self:next()
			local exprRes = self:parseExpression(0, nil)
			if (not exprRes.success) then
				error("[Parser] Expected expression")
			else
				funcParam.default = exprRes.data
			end
		end

		return funcParam
	end,

	getPrefixExpression = function(self)
		if (self:eos()) then return end

		local token = self.currentToken

		for k,v in ipairs(prefixParselets) do
			if (v.token.type == token.type and (v.token.contents == nil or v.token.contents == token.contents)) then
				self:next()
				return v.func(self, token)
			end
		end
	end,

	getSuffixExpression = function(self, left, token)
		for k,v in ipairs(suffixParselets) do
			if (v.token.type == token.type and (v.token.contents == nil or v.token.contents == token.contents)) then
				return v.func(self, left, token)
			end
		end
	end,

	getCurrentTokenPrecedence = function(self)
		if (self:eos()) then return 0 end

		if (self.currentToken.type ~= TokenType.OPERATOR and self.currentToken.type ~= TokenType.BRK_PAREN and
			 self.currentToken.type ~= TokenType.BRK_SQUARE and self.currentToken.type ~= TokenType.DOT) then
			return 0
		end

		if (self.currentToken.type == TokenType.DOT) then
			return infixOperators['.'].precedence
		end

		if (type(infixOperators[self.currentToken.contents]) == "table") then
			return infixOperators[self.currentToken.contents].precedence
		end

		return 0
	end,

	parseExpression = function(self, precedence)
		local left = self:getPrefixExpression()
		if (left == nil) then return end

		while (not self:eos() and precedence < self:getCurrentTokenPrecedence()) do
			local token = self.currentToken
			self:next()

			left = self:getSuffixExpression(left, token)
		end

		return left
	end
}

return setmetatable({}, {__index = parser})
