--[[
# subroutine
.foo
	LOADA 0 # load argument 0 onto the stack
	LOADA 1 # load argument 1 onto the stack
	ADDB    # binary add, pops 2 operands from the stack
	RET     # return value at top of stack
	
LOADG 1  # load .foo onto the stack
LOADK 0 # push literal 13 onto stack
LOADK 1 # push literal 37 onto stack
CALL 2   # call .foo with 2 arguments (pops the 2 arguments and .foo)
POP      # pop return value since its not used
LOADN    # push null onto the stack
RET      # return value at top of stack

]]

local vm = require("vm")

vm:addFunction(0, 0, {13, 37}, {
	{opcode = 0x01, operand = 2 },
	{opcode = 0x02, operand = 1},
	{opcode = 0x02, operand = 2},
	{opcode = 0x09, operand = 2 },
	--{opcode = 0x0B					 }, -- pop result
	--{opcode = 0x05					 }, -- push null
	{opcode = 0x0A					 }
})

vm:addFunction(2, 1, {50, 100}, {
	{opcode = 0x04, operand = 1 }, -- push L1 (arg1)
	{opcode = 0x04, operand = 2 }, -- push L2 (arg2)
	{opcode = 0x16					 }, -- pop 2 from the stack, push add result onto stack
	{opcode = 0x08, operand = 3 }, -- store result in L3
	{opcode = 0x04, operand = 3 }, -- push L3
	{opcode = 0x02, operand = 1 }, -- push K1
	{opcode = 0x0F					 }, -- pop 2 from the stack, push equality comparison onto the stack
	{opcode = 0x0E, operand = 11}, -- branch to instruction 11 if local3 and constant1 are not equal
	{opcode = 0x02, operand = 2 }, -- push K2
	{opcode = 0x08, operand = 3 }, -- store K2 into L3
	{opcode = 0x01, operand = 3 }, -- push G3
	{opcode = 0x04, operand = 3 }, -- push L3
	{opcode = 0x09, operand = 1 }, -- call
	{opcode = 0x0A					 }
})

vm:addFunction(1, 0, {2}, {
	{opcode = 0x04, operand = 1},
	{opcode = 0x04, operand = 1},
	{opcode = 0x18					}, -- square L1
	{opcode = 0x04, operand = 1},
	{opcode = 0x02, operand = 1},
	{opcode = 0x19					}, -- halve L1
	{opcode = 0x17					}, -- subtract half of L1 from L1 squared
	{opcode = 0x0A					}
})

--vm:dump()

print("Injecting Stack Frame...")
table.insert(vm.call_stack, {
	locals = {},
	func_addr = 1, -- index in vm.globals
	ret_ip = 0
})

--vm:dump()

print("Executing...")
while (#vm.call_stack > 0) do
	vm:tick()
end

vm:dump()
