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
	currentIndex = 1,
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
		-- NOP
	end,

	error = function(self, msg)
		error(string.format("[Lexer:%d:%d] %s", self.currentRow, self.currentColumn, msg))
	end,

	lex = function(self, str)
		if (type(str) ~= "string" or #str < 1) then
			self:error("Input must be a string containing at least 1 character")
		end

		self.string = str
		self.currentChar = self.string[1]

		while (self.currentChar) do
			-- NOP
			break
		end
	end
}

return setmetatable({}, {__index = lexer})
