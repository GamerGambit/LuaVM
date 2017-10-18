local lexer = require("lexer")
local infixOperators = require("parser_infixoperators")
local prefixParselets = require("parser_prefixparselets")
local suffixParselets = require("parser_suffixparselets")

local function newNamespaceDefinition(nameExpr)
	return {
		type = "namespace-definition",
		nameExpr = nameExpr,
		body = {}
	}
end

local function newFunctionDefinition(name)
	return {
		type = "function-definition",
		name = name,
		params = {},
		body = {}
	}
end

local function newFunctionParameter(name, default)
	return {
		type = "function-parameter",
		name = name,
		default = default
	}
end

local function newVariableDeclaration(type, name, expr)
	return {
		type = "vardecl-" .. type,
		name = name,
		expr = expr or { type = "literal-null" }
	}
end

local function newAssignment(leftExpr, symbol, rightExpr)
	return {
		type = "assignment",
		leftExpr = leftExpr,
		symbol = symbol,
		rightExpr = rightExpr
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

		if (self.currentToken.type ~= type and (contents == nil or self.currentToken.contents == contents)) then
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
		local function reconstructNode(node, indent)
			indent = indent or 0
			local ws = string.rep("    ", indent)

			if (string.sub(node.type, 1, 7) == "literal") then
				return node.value or "null"

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
				local s = node.symbol == '.' and '' or ' '
				return reconstructNode(node.left) .. s .. node.symbol .. s .. reconstructNode(node.right)

			elseif (node.type == "ternary-operator") then
				return reconstructNode(node.condExpr) .. ") ? (" .. reconstructNode(node.thenExpr) .. " ) : (" .. reconstructNode(node.elseExpr)

			elseif (string.sub(node.type, 1, 7) == "vardecl") then
				local str

				if (string.sub(node.type, 9) == "local") then
					str = "local"
				else
					str = "global"
				end

				str = str .. ' ' .. node.name
				str = str .. " = " .. reconstructNode(node.expr)
				return str

			elseif (node.type == "namespace-definition") then
				local str = "namespace " .. reconstructNode(node.nameExpr)
				str = str .. '\n' .. ws .. '{'

				for k,v in ipairs(node.body) do
					str = str .. '\n' .. ws .. "    "
					str = str .. reconstructNode(v, indent + 1)
				end

				str = str .. '\n' .. ws .. '}'
				return str

			elseif (node.type == "function-definition") then
				local str = "function " .. node.name .. '('

				for k,v in ipairs(node.params) do
					if (k > 1) then str = str .. ", " end
					str = str .. reconstructNode(v)
				end

				str = str .. ")\n" .. ws .. '{'

				for k,v in ipairs(node.body) do
					str = str .. '\n' .. ws .. "    "
					str = str .. reconstructNode(v)
				end

				str = str .. '\n' .. ws .. '}'

				return str

			elseif (node.type == "function-parameter") then
				local str = node.name

				if (node.default) then
					str = str .. " = " .. reconstructNode(node.default)
				end

				return str

			elseif (node.type == "assignment") then
				return reconstructNode(node.leftExpr) .. ' ' .. node.symbol .. ' ' .. reconstructNode(node.rightExpr)
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
			local res = self:parseGlobalVariableDeclaration() or
							self:parseLocalVariableDeclaration() or
							self:parseNamespaceDefinition() or
							self:parseFunctionDefinition()

			table.insert(self.tree, res)
		end
	end,

	parseLocalVariableDeclaration = function(self)
		if (self:eos()) then return end
		if (self.currentToken.type ~= TokenType.KEYWORD) then return end
		if (self.currentToken.contents ~= "local") then return end

		self:next()

		local vardecl = newVariableDeclaration("local", self:expect(TokenType.IDENTIFIER))

		if (not self:eos() and self.currentToken.type == TokenType.ASSIGNMENT) then
			self:expect(TokenType.ASSIGNMENT, '=')
			local res = self:parseExpression(0)
			if (res == nil) then error("[Parser] expected expression") end
			vardecl.expr = res
		end

		return vardecl
	end,

	parseGlobalVariableDeclaration = function(self)
		if (self:eos()) then return end
		if (self.currentToken.type ~= TokenType.KEYWORD) then return end
		if (self.currentToken.contents ~= "global") then return end

		self:next()

		local vardecl = newVariableDeclaration("global", self:expect(TokenType.IDENTIFIER))

		if (not self:eos() and self.currentToken.type == TokenType.ASSIGNMENT) then
			self:expect(TokenType.ASSIGNMENT, '=')
			local res = self:parseExpression(0)
			if (res == nil) then error("[Parser] expected expression") end
			vardecl.expr = res
		end

		return vardecl
	end,

	parseNamespaceDefinition = function(self)
		if (self:eos()) then return end
		if (self.currentToken.type ~= TokenType.KEYWORD) then return end
		if (self.currentToken.contents ~= "namespace") then return end

		self:next()

		local nameExpr = self:parseExpression(15)

		if (nameExpr.type ~= "identifier" and not (nameExpr.type == "binary-operator" and nameExpr.symbol == '.')) then
			error("[Parser] expected identifier")
		end

		local namespace = newNamespaceDefinition(nameExpr)
		self:expect(TokenType.BRK_CURL, '{')

		while (not self:eos() and not (self.currentToken.type == TokenType.BRK_CURL and self.currentToken.contents == '}')) do
			local res = self:parseNamespaceDefinition() or
						   self:parseFunctionDefinition()
			table.insert(namespace.body, res)
		end

		self:expect(TokenType.BRK_CURL, '}')
		return namespace
	end,

	parseFunctionDefinition = function(self)
		if (self:eos()) then return end
		if (self.currentToken.type ~= TokenType.KEYWORD) then return end
		if (self.currentToken.contents ~= "function") then return end

		self:next()

		local func = newFunctionDefinition(self:expect(TokenType.IDENTIFIER))

		self:expect(TokenType.BRK_PAREN, '(')

		while (not (self.currentToken.type == TokenType.BRK_PAREN and self.currentToken.contents == ')')) do
			if (#func.params >= 1) then
				self:expect(TokenType.COMMA)
			end

			table.insert(func.params, self:parseFunctionParameter())
		end

		self:expect(TokenType.BRK_PAREN, ')')
		self:expect(TokenType.BRK_CURL, '{')

		while (not (self.currentToken.type == TokenType.BRK_CURL and self.currentToken.contents == '}')) do
			local res = self:parseLocalVariableDeclaration() or
							self:parseAssignmentOrFunctionCall()
			table.insert(func.body, res)
		end

		self:expect(TokenType.BRK_CURL, '}')

		return func
	end,

	parseFunctionParameter = function(self)
		if (self:eos()) then return end
		if (self.currentToken.type ~= TokenType.IDENTIFIER) then return end

		local funcParam = newFunctionParameter(self:expect(TokenType.IDENTIFIER))

		self:next()

		if (self.currentToken.type == TokenType.OPERATOR and self.currentToken.contents == '=') then
			self:next()
			local exprRes = self:parseExpression(0, nil)
			if (not exprRes) then
				error("[Parser] Expected expression")
			else
				funcParam.default = exprRes
			end
		end

		return funcParam
	end,

	parseAssignmentOrFunctionCall = function(self)
		if (self:eos()) then return end
		if (self.currentToken.type ~= TokenType.IDENTIFIER) then return end

		local left = self:parseExpression(0)

		if (not (left.type == "binary-operator" and left.symbol == '.') and
			 left.type ~= "subscript" and
			 left.type ~= "identifier" and
			 left.type ~= "function-call") then
			error("[Parser] Invalid expression")
		end

		if (left.type == "function-call") then
			if (self:eos()) then return left end
			if (self.currentToken.type == TokenType.ASSIGNMENT) then
				error("[Parser] invalid assignment to function call")
			end

			return left
		end

		if (self.currentToken.type ~= TokenType.ASSIGNMENT) then
			error("[Parser] expected assignment")
		end

		local symbol = self:expect(TokenType.ASSIGNMENT)
		local right = self:parseExpression(0)

		if (right == nil) then
			error("[Parser] expected expression")
		end

		return newAssignment(left, symbol, right)
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
