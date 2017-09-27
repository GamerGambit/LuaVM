local opcodes = require("opcodes")

local function newStackFrame(func_addr, ret_ip)
	return {
		locals = {},
		func_addr = func_addr, -- index in vm.globals
		ret_ip = ret_ip
	}
end

local vm = {
	globals = {},
	memory = {},
	
	stack = {},
	call_stack = {},
	
	ip = 1,
	sfp = 1,
	
	addFunction = function(self, numParameters, numLocals, constants, bytecode)
		table.insert(self.globals, {
			addr = #self.globals + 1,
			numParameters = numParameters,
			numLocals = numLocals,
			constants = constants,
			bytecode = bytecode
		})
	end,
	
	dump = function(self)
		print()
		print("======== DUMP ========")
		print("Globals:")
		for k, v in ipairs(self.globals) do
			print(string.format("       > %s\t%s", k, tostring(v)))
			if (type(v) == "table") then
				print(string.format("               > Address: %s", v.addr))
				print(string.format("               > Parameters #: %d", v.numParameters))
				print(string.format("               > Locals #: %d", v.numLocals))
				
				print(string.format("               > Constants:"))
				for a, b in ipairs(v.constants) do
					print(string.format("                       > %s\t%s", a, tostring(b)))
				end
				print()
				
				print(string.format("               > Bytecode:"))
				for a, b in ipairs(v.bytecode) do
					-- find name of byte
					local name = "[INVALID OPCODE]"
					for n, c in pairs(opcodes) do
						if (c == b.opcode) then
							name = n
							break;
						end
					end
					
					local ipStr = ((self.call_stack[self.sfp] or {func_addr = 0}).func_addr == v.addr and self.ip == a) and "\t<-- [Instruction Pointer]" or ""
					print(string.format("                       > %s\t%s\t%s" .. ipStr, a, name, b.operand or ""))
				end
			end
		end
		print()
		
		print("Memory:")
		for k, v in ipairs(self.memory) do
			print(string.format("       > %s\t%s", k, v))
		end
		print()
		
		print("Stack:")
		for k, v in ipairs(self.stack) do
			print(string.format("       > %s\t%s", k, v))
		end
		print()
		
		print("Call Stack:")
		for k, v in ipairs(self.call_stack) do
			local sfpStr = self.sfp == k and "\t\t\t\t\t<-- [Stack Frame Pointer]" or ""
			print(string.format("       > %s" .. sfpStr, k))
			
			print("               > Locals")
			for a, b in ipairs(v.locals) do
				print(string.format("                       > %s\t%s", a, tostring(b)))
			end
			print()
			
			print(string.format("               > Function Address  : %s", v.func_addr))
			print(string.format("               > Return Instruction: %s", v.ret_ip))
		end
		print()
		
		print("Stack Frame Pointer: " .. tostring(self.sfp))
		print("Instruction Pointer: " .. tostring(self.ip))
		print("======== DUMP ========")
		print()
	end,
	
	tick = function(self)
		if (#self.call_stack == 0) then return end
		
		local sf = self.call_stack[self.sfp]
		local func = self.globals[sf.func_addr]
		local instruction = func.bytecode[self.ip]
		local opcode = instruction.opcode
		local op = instruction.operand
		
		if (opcode == opcodes.LOAD) then
			self.ip = self.ip + 1
			table.insert(self.stack, memory[op])
		
		elseif (opcode == opcodes.LOADG) then
			self.ip = self.ip + 1
			table.insert(self.stack, self.globals[op])
		
		elseif (opcode == opcodes.LOADK) then
			self.ip = self.ip + 1
			table.insert(self.stack, func.constants[op])
		
		elseif (opcode == opcodes.LOADL) then
			self.ip = self.ip + 1
			table.insert(self.stack, sf.locals[op])
		
		elseif (opcode == opcodes.LOADN) then
			self.ip = self.ip + 1
			table.insert(self.stack, nil)
		
		elseif (opcode == opcodes.STORE) then
			self.ip = self.ip + 1
			self.memory[op] = table.remove(self.stack)
		
		elseif (opcode == opcodes.STOREG) then
			self.ip = self.ip + 1
			self.globals[op] = table.remove(self.stack)
		
		elseif (opcode == opcodes.STOREL) then
			self.ip = self.ip + 1
			sf.locals[op] = table.remove(self.stack)
		
		elseif (opcode == opcodes.CALL) then
			local newFunc = self.globals[func.bytecode[self.ip - op - 1].operand]
			table.insert(self.call_stack, newStackFrame(newFunc.addr, self.ip + 1))
			local index = #self.call_stack
			
			for l = 1, (func.numParameters + func.numLocals) do
				table.insert(self.call_stack[index].locals, nil)
			end
			
			for arg = 1, op do
				self.call_stack[index].locals[arg] = table.remove(self.stack) -- pop argument
			end
			
			table.remove(self.stack) -- pop function
			
			self.sfp = self.sfp + 1
			self.ip = 1
		
		elseif (opcode == opcodes.RET) then
			self.ip = sf.ret_ip
			self.sfp = self.sfp - 1
			table.remove(self.call_stack)
		
		elseif (opcode == opcodes.POP) then
			self.ip = self.ip + 1
			table.remove(self.stack)
		
		elseif (opcode == opcodes.BR) then
			self.ip = op

		elseif (opcode == opcodes.BRT) then
			if (table.remove(self.stack) == true) then
				self.ip = op
			else
				self.ip = self.ip + 1
			end
		
		elseif (opcode == opcodes.BRF) then
			if (table.remove(self.stack) == false) then
				self.ip = op
			else
				self.ip = self.ip + 1
			end
		
		elseif (opcode == opcodes.CMP_EQ) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 == op2)
		
		elseif (opcode == opcodes.CMP_NEQ) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 ~= op2)
		
		elseif (opcode == opcodes.CMP_LT) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 < op2)
		
		elseif (opcode == opcodes.CMP_LE) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 <= op2)
		
		elseif (opcode == opcodes.CMP_GT) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 > op2)
		
		elseif (opcode == opcodes.CMP_GE) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 >= op2)
		
		elseif (opcode == opcodes.ADDB) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 + op2)
			
		elseif (opcode == opcodes.SUBB) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 - op2)
		
		elseif (opcode == opcodes.MUL) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 * op2)
		
		elseif (opcode == opcodes.DIV) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 / op2)
		
		elseif (opcode == opcodes.MOD) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, op1 % op2)
		
		elseif (opcode == opcodes.BAND) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, bit.band(op1, op2))
		
		elseif (opcode == opcodes.BOR) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, bit.bor(op1, op2))
		
		elseif (opcode == opcodes.BXOR) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, bit.bxor(op1, op2))
		
		elseif (opcode == opcodes.BNEG) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, bit.bnot(op1, op2))
		
		elseif (opcode == opcodes.BSHL) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, bit.lshift(op1, op2))
		
		elseif (opcode == opcodes.BSHR) then
			self.ip = self.ip + 1
			local op2 = table.remove(self.stack)
			local op1 = table.remove(self.stack)
			table.insert(self.stack, bit.rshift(op1, op2))
		end
	end
}

return setmetatable({}, {__index = vm})
