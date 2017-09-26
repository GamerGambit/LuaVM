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

vm:addFunction(0, {13, 37}, {
	{opcode = 0x01, operand = 2 },
	{opcode = 0x02, operand = 1},
	{opcode = 0x02, operand = 2},
	{opcode = 0x09, operand = 2 },
	--{opcode = 0x0B					 },
	--{opcode = 0x05					 },
	{opcode = 0x0A					 }
})

vm:addFunction(2, {}, {
	{opcode = 0x04, operand = 1},
	{opcode = 0x04, operand = 2},
	{opcode = 0x14					},
	{opcode = 0x0A					},
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
