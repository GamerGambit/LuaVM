--[[
function bar(x)
	return (x * x) - (x / 2)
end

function foo(x, y)
	local v = x + y
	if (v == 50) then
		v = #("ye" .. "man")
	end

	return bar(v)
end

function main()
	return foo(13, 37)
end
]]

local vm = require("vm")

table.insert(vm.globals, newFunction(1, 0, {}, {newNumber(13), newNumber(37)}, {
	{opcode = 0x01, operand = 2 },
	{opcode = 0x02, operand = 1 },
	{opcode = 0x02, operand = 2 },
	{opcode = 0x08, operand = 2 },
	--{opcode = 0x0B					 }, -- pop result
	--{opcode = 0x05					 }, -- push null
	{opcode = 0x09					 }
}))

table.insert(vm.globals, newFunction(2, 1, {"x", "y"}, {newNumber(50), newString("ye"), newString("man")}, {
	{opcode = 0x03, operand = 1 }, -- push L1 (arg1)
	{opcode = 0x03, operand = 2 }, -- push L2 (arg2)
	{opcode = 0x16					 }, -- pop 2 from the stack, push add result onto stack
	{opcode = 0x07, operand = 3 }, -- store result in L3
	{opcode = 0x03, operand = 3 }, -- push L3
	{opcode = 0x02, operand = 1 }, -- push K1
	{opcode = 0x10					 }, -- pop 2 from the stack, push equality comparison onto the stack
	{opcode = 0x0D, operand = 14}, -- branch to instruction 11 if local3 and constant1 are not equal
	{opcode = 0x02, operand = 2 }, -- push K2
	{opcode = 0x02, operand = 3 }, -- push K3
	{opcode = 0x0E					 }, -- concate K3 to K2
	{opcode = 0x0F					 }, -- push #(K2 .. K3)
	{opcode = 0x07, operand = 3 }, -- store K2 into L3
	{opcode = 0x01, operand = 3 }, -- push G3
	{opcode = 0x03, operand = 3 }, -- push L3
	{opcode = 0x08, operand = 1 }, -- call
	{opcode = 0x09					 }
}))

table.insert(vm.globals, newFunction(3, 0, {"x"}, {newNumber(2)}, {
	{opcode = 0x03, operand = 1},
	{opcode = 0x03, operand = 1},
	{opcode = 0x18					}, -- square L1
	{opcode = 0x03, operand = 1},
	{opcode = 0x02, operand = 1},
	{opcode = 0x19					}, -- halve L1
	{opcode = 0x17					}, -- subtract half of L1 from L1 squared
	{opcode = 0x09					}
}))

--vm:dump()

print("Injecting Stack Frame...")
table.insert(vm.call_stack, {
	locals = {},
	func_addr = 1, -- index in vm.globals
	ret_ip = 0
})

vm:dump()

print("Executing...")
while (#vm.call_stack > 0) do
	vm:tick()
end

vm:dump()
