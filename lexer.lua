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

local numberType = {
	BINARY		= 2,
	DECIMAL		= 10,
	HEXADECIMAL	= 16,
	OCTAL			= 8,
	SCIENTIFIC	= 0
}

local function newToken(type, contents)
	return {
		type = type,
		contents = contents
	}
end

local function isDigit(char)
	local byte = string.byte(char)
	return byte >= 48 and byte <= 57
end

local function isHexDigit(char)
	local byte = string.byte(char)
	return isDigit(char) or (byte >= 65 and byte <= 70) or (byte >= 97 and byte <= 103)
end

local function isAlpha(char)
	local byte = string.byte(char)
	return (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)
end

local lexer = {
	string = "",
	currentIndex = 0,
	currentChar = '\0',
	currentRow = 1,
	currentColumn = 1,

	tokens = {},

	readNumber = function(self)
		local startRow = self.currentRow
		local startCol = self.currentColumn
		local numStr = ""
		local numType = numberType.DECIMAL

		if (self.currentChar == '0') then
			self:next()

			if (self.currentChar == 'x') then
				self:next()
				numType = numberType.HEXADECIMAL
			elseif (self.currentChar == 'o') then
				self:next()
				numType = numberType.OCTAL
			elseif (self.currentChar == 'b') then
				self:next()
				numType = numberType.BINARY
			else
				numStr = "0"
			end

			if (numType ~= numberType.DECIMAL and self.currentChar == '_') then
				self:error("Invalid use of digit separator")
			end
		end

		local lastWasUnderscore = false

		while (self.currentChar ~= '\0' and (isDigit(self.currentChar) or isHexDigit(self.currentChar) or
				self.currentChar == '+' or self.currentChar == '-' or self.currentChar == '.' or
				self.currentChar == 'e' or self.currentChar == 'E' or self.currentChar == '_')) do
			if (self.currentChar == '_') then
				local lastNumChar = string.sub(numStr, #numStr, #numStr)
				if (not isDigit(lastNumChar) and not isHexDigit(lastNumChar)) then
					print(lastNumChar)
					self:error("Invalid use of digit separator")
				end

				lastWasUnderscore = true
			else
				if (self.currentChar == 'e' or self.currentChar == 'E' or
					 self.currentChar == '+' or self.currentChar == '-') then
					if (lastWasUnderscore) then
						self:error("Invalid use of digit separator")
					end

					numType = numberType.SCIENTIFIC
				end

				numStr = numStr .. self.currentChar
				lastWasUnderscore = false
			end

			self:next()
		end

		if (lastWasUnderscore) then
			self:error("Invalid use of digit separator")
		end

		local num
		if (numType == numberType.SCIENTIFIC or numType == numberType.DECIMAL) then
			num = tonumber(numStr)
		else
			num = tonumber(numStr, numType)
		end

		if (type(num) ~= "number") then
			local numTypeStr = "decimal"
			if (numType == numberType.BINARY) then
				numTypeStr = "binary"
			elseif (numType == numberType.HEXADECIMAL) then
				numTypeStr = "hexadecimal"
			elseif (numType == numberType.OCTAL) then
				numTypeStr = "octal"
			elseif (numType == numberType.SCIENTIFIC) then
				numTypeStr = "scientific"
			end

			self:error(string.format("Invalid %s number type (%s)", numTypeStr, numStr), startRow, startCol)
		end

		table.insert(self.tokens, newToken(TokenType.LITERAL_N, num))
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
			elseif (isDigit(self.currentChar)) then
				self:readNumber()
			end
		end

		return self.tokens
	end
}

return setmetatable({}, {__index = lexer})
