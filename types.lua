local base = {
	type = "base",
	__index = function(self, key) error(string.format("%s not implemented for %s", key, self.type)) end
}

function newNumber(n)
	return setmetatable({
		value = n,
		type = "number",
		tostring = function(self) return tostring(self.value) end,
		tonumber = function(self) return self.value end,
		add = function(self, other)
			assert(other.type == "number", string.format("Cannot add %s to number", other.type))
			return self.value + other.value
		end,
		sub = function(self, other)
			assert(other.type == "number", string.format("Cannot subtract %s from number", other.type))
			return self.value - other.value
		end,
		mul = function(self, other)
			assert(other.type == "number", string.format("Cannot multiply number by %s", other.type))
			return self.value * other.value
		end,
		div = function(self, other)
			assert(other.type == "number", string.format("Cannot divide number by %s", other.type))
			return self.value / other.value
		end,
		mod = function(self, other)
			assert(other.typer == "number", string.format("Cannot modulo number by %s", other.type))
			return self.value % other.value
		end,
		exp = function(self, other)
			assert(other.type == "number", string.format("Cannot raise number by %s", other.type))
			return self.value ^ other.value
		end,

		eq = function(self, other)
			return other.type == "number" and self.value == other.value
		end,
		neq = function(self, other)
			return self:eq(other) == false
		end,
		lt = function(self, other)
			return other.type == "number" and self.value < other.value
		end,
		le = function(self, other)
			return other.type == "number" and self.value <= other.value
		end,
		gt = function(self, other)
			return other.type == "number" and self.value > other.value
		end,
		ge = function(self, other)
			return other.type == "number" and self.value >= other.value
		end,

		band = function(self, other)
			assert(other.type == "number", string.format("Cannot bitwise and %s and number", other.type))
			return bit.band(self.value, other.value)
		end,
		bor = function(self, other)
			assert(other.type == "number", string.format("Cannot bitwise or %s and number", other.type))
			return bit.bor(self.value, other.value)
		end,
		bxor = function(self, other)
			assert(other.type == "number", string.format("Cannot bitwise xor %s and number", other.type))
			return bit.bxor(self.value, other.value)
		end,
		bneg = function(self, other)
			assert(other.type == "number", string.format("Cannot bitwise negate %s and number", other.type))
			return bit.bnot(self.value, other.value)
		end,
		bshl = function(self, other)
			assert(other.type == "number", string.format("Cannot bitwise left shift %s and number", other.type))
			return bit.lshift(self.value, other.value)
		end,
		bshr = function(self, other)
			assert(other.type == "number", string.format("Cannot bitwise right shift %s and number", other.type))
			return bit.rshift(self.value, other.value)
		end
	}, base)
end

function newString(str)
	return setmetatable({
		value = str,
		type = "string",
		tostring = function(self) return self.value end,
		tonumber = function(self) return tostring(self.value) end,
		eq = function(self, other)
			return other.type == "string" and self.value == other.value
		end,
		neq = function(self, other)
			return self:eq(other) == false
		end,
		concat = function(self, other)
			assert(other.type == "string", string.format("Cannot concatenate string with %s", other.type))
			return self.value .. other.value
		end,
		hash = function(self)
			return #self.value
		end
	}, base)
end

function newFunction(addr, numLocals, parameters, constants, bytecode)
	return setmetatable({
		type = "function",
		addr = addr,
		constants = constants,
		parameters = parameters,
		numLocals = numLocals,
		bytecode = bytecode,
		eq = function(self, other)
			return other.type == "function" and self.addr == other.addr
		end,
		neq = function(self, other)
			return self:eq(other) == false
		end,
		tostring = function(self)
			local paramStr = ""

			for i, p in ipairs(self.parameters) do
				if (i > 1) then paramStr = paramStr .. ", " end
				paramStr = paramStr .. p
			end

			return string.format("function %#02x(%s)", self.addr, paramStr)
		end
	}, base)
end

function newBoolean(b)
	return setmetatable({
		type = "bool",
		value = b,
		tostring = function(self) return tostring(self.value) end,
		eq = function(self, other)
			return other.type == "bool" and self.value == other.value
		end,
		neq = function(self, other)
			return self:eq(other) == false
		end
	}, base)
end

function copyType(t, ...)
	if (type(t) == "number") then
		return newNumber(t)
	elseif (type(t) == "string") then
		return newString(t)
	elseif (type(t) == "bool") then
		return newBool(t)
	elseif (t.type == "number") then
		return newNumber(...)
	elseif (t.type == "string") then
		return newString(...)
	elseif (t.type == "function") then
		return newFunction(...)
	elseif (t.type == "bool") then
		return newBoolean(...)
	end
end
