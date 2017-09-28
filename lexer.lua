TokenType = {
	INVALID 		= 0x0,
	IDENTIFIER	= 0x1,
	KEYWORD		= 0x2,
	OPERATOR		= 0x3,
	LITERAL_N	= 0x4,
	LITERAL_S	= 0x5
}

Keywords = {
	"function",
	"if"
}

local function newToken(type, contents)
	return {
		type = type,
		contents = contents
	}
end

local lexer = {
	string = "",
	currentIndex = 0,
	currentChar = '\0',
	currentRow = 1,
	currentColumn = 1,

	tokens = {},

	readNumber = function(self)
		-- NOP
	end,

	readString = function(self, terminatingChar)
		local startRow = self.currentRow
		local startCol = self.currentColumn

		self:next() -- skip opening

		local str = ""

		while (self.currentChar ~= '\0' and self.currentChar ~= terminatingChar) do
			str = str .. self.currentChar
			self:next()
		end

		if (self.currentChar == '\0') then
			self:error("Unfinished string", startRow, startCol)
		end

		self:next() -- it was a finished string, skip over the closer

		table.insert(self.tokens, newToken(TokenType.LITERAL_S, str))
	end,

	readIdentifier = function(self)
		-- NOP
	end,

	next = function(self)
		-- we have the last char already, set the current char to null
		if (self.currentIndex + 1 == #self.string + 1) then
			self.currentChar = '\0'
			return
		elseif (self.currentIndex > #self.string + 1) then
			error("Source underflow")
		end

		self.currentIndex = self.currentIndex + 1
		self.currentChar = string.sub(self.string, self.currentIndex, self.currentIndex)
		self.currentColumn = self.currentColumn + 1
	end,

	error = function(self, msg, row, col)
		error(string.format("[Lexer:%d:%d] %s", row or self.currentRow, col or self.currentColumn, msg))
	end,

	lex = function(self, str)
		if (type(str) ~= "string" or #str < 1) then
			self:error("Input must be a string containing at least 1 character")
		end

			self.string = str
			self:next()

		while (self.currentChar ~= '\0') do
			if (self.currentChar == '\n') then
				self.currentRow = self.currentRow + 1
				self.currentColumn = 1
				self:next()

			elseif (self.currentChar == '\t' or self.currentChar == ' ') then
				self.currentColumn = self.currentColumn + 1
				self:next()

			elseif (self.currentChar == '+') then
				self:next()

				if (self.currentChar == '+' or self.currentChar == '=') then
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '+' .. self.currentChar))
					self:next()
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '+'))
				end

			elseif (self.currentChar == '-') then
					self:next()

					if (self.currentChar == '-' or self.currentChar == '=') then
						table.insert(self.tokens, newToken(TokenType.OPERATOR, '-' .. self.currentChar))
						self:next()
					else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '-'))
					end

			elseif (self.currentChar == '*') then
				self:next()

				if (self.currentChar == '*' or self.currentChar == '=') then
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '*' .. self.currentChar))
					self:next()
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '*'))
				end

			elseif (self.currentChar == '/') then
				self:next()

				if (self.currentChar == '/' or self.currentChar == '=') then
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '*' .. self.currentChar))
					self:next()
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '/'))
				end

			elseif (self.currentChar == '%') then
				self:next()

				if (self.currentChar == '=') then
					table.insert(self.tokens, newToken(TokenType.OPERATOR, "%="))
					self:next()
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '%'))
				end

			elseif (self.currentChar == '^') then
				self:next()

				if (self.currentChar == '^' or self.currentChar == '=') then
					if (self.currentChar == '^') then
						self:next()

						if (self.currentChar == '=') then
							self:next()
							table.insert(self.tokens, newToken(TokenType.OPERATOR, "^^="))
						else
							table.insert(self.tokens, newToken(TokenType.OPERATOR, "^^"))
						end
					else
						self:next()
						table.insert(self.tokens, newToken(TokenType.OPERATOR, "^="))
					end
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '^'))
				end

			elseif (self.currentChar == '&') then
				self:next()

				if (self.currentChar == '&' or self.currentChar == '=') then
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '&' .. self.currentChar))
					self:next()
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '&'))
				end

			elseif (self.currentChar == '|') then
				self:next()

				if (self.currentChar == '|' or self.currentChar == '=') then
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '|' .. self.currentChar))
					self:next()
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '|'))
				end

			elseif (self.currentChar == '~') then
				self:next()

				if (self.currentChar == '=') then
					self:next()
					table.insert(self.tokens, newToken(TokenType.OPERATOR, "~="))
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '~'))
				end

			elseif (self.currentChar == '<') then
				self:next()

				if (self.currentChar == '<' or self.currentChar == '=') then
					if (self.currentChar == '<') then
						self:next()

						if (self.currentChar == '=') then
							self:next()
							table.insert(self.tokens, newToken(TokenType.OPERATOR, "<<="))
						else
							table.insert(self.tokens, newToken(TokenType.OPERATOR, "<<"))
						end
					else
						table.insert(self.tokens, newToken(TokenType.OPERATOR, "<="))
						self:next()
					end
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '<'))
				end

			elseif (self.currentChar == '>') then
				self:next()

				if (self.currentChar == '>' or self.currentChar == '=') then
					if (self.currentChar == '>') then
						self:next()

						if (self.currentChar == '=') then
							self:next()
							table.insert(self.tokens, newToken(TokenType.OPERATOR, ">>="))
						else
							table.insert(self.tokens, newToken(TokenType.OPERATOR, ">>"))
						end
					else
						table.insert(self.tokens, newToken(TokenType.OPERATOR, ">="))
						self:next()
					end
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '>'))
				end

			elseif (self.currentChar == '=') then
				self:next()

				if (self.currentChar == '=') then
					self:next()
					table.insert(self.tokens, newToken(TokenType.OPERATOR, "=="))
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '='))
				end

			elseif (self.currentChar == '!') then
				self:next()

				if (self.currentChar == '=') then
					self:next()
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '!='))
				else
					table.insert(self.tokens, newToken(TokenType.OPERATOR, '!'))
				end

			elseif (self.currentChar == ',' or self.currentChar == '.' or self.currentChar == '(' or
					  self.currentChar == ')' or self.currentChar == '{' or self.currentChar == '}' or
					  self.currentChar == '[' or self.currentChar == ']' or self.currentChar == '#' or
					  self.currentChar == '@') then
				table.insert(self.tokens, newToken(TokenType.OPERATOR, self.currentChar))
				self:next()

			elseif (self.currentChar == '"' or self.currentChar == '\'') then
				self:readString(self.currentChar)
			end
		end

		return self.tokens
	end
}

return setmetatable({}, {__index = lexer})
