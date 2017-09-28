TokenType = {
	INVALID 		= 0x0,
	IDENTIFIER	= 0x1,
	KEYWORD		= 0x2,
	OPERATOR		= 0x3,
	CONSTANT		= 0x4 -- string, number
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

	readString = function(self)
		-- NOP
	end,

	readIdentifier = function(self)
		-- NOP
	end,

	next = function(self)
		-- we have the last char already, set the current char to null
		if (self.currentIndex == #self.string) then
			self.currentChar = '\0'
			return
		elseif (self.currentIndex > #self.string) then
			error("Source underflow")
		end

		self.currentIndex = self.currentIndex + 1
		self.currentChar = string.sub(self.string, self.currentIndex, self.currentIndex)
		self.currentColumn = self.currentColumn + 1
	end,

	error = function(self, msg)
		error(string.format("[Lexer:%d:%d] %s", self.currentRow, self.currentColumn, msg))
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
			end
		end

		return self.tokens
	end
}

return setmetatable({}, {__index = lexer})
