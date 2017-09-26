return {
	LOAD		= 0x00, -- load from memory
	LOADG		= 0x01, -- load global
	LOADK		= 0x02, -- load constant
	LOADL		= 0x04, -- load local
	LOADN		= 0x05, -- load null
	
	STORE		= 0x06, -- store in memory
	STOREG	= 0x07, -- store global
	STOREV	= 0x08, -- store local
	
	CALL		= 0x09, -- call subroutine
	RET		= 0x0A, -- return from subroutine
	
	POP		= 0x0B, -- pop value from the top of the stack
	
	JMP		= 0x0C, -- jump to instruction
	JZ			= 0x0D, -- jump to instruction if TOP is 0
	JNZ		= 0x0E, -- jump to instruction if TOP is not 0
	JEQ		= 0x0D, -- jump to instruction if TOP is equal
	JNE		= 0x0E, -- jump to instruction if TOP is not equal
	JLT		= 0x0F, -- jump to instruction if TOP is less than
	JGT		= 0x10, -- jump to instruction if TOP is greater than
	JLE		= 0x11, -- jump to instruction if top is less than or equal to
	JGE		= 0x12, -- jump to instruction if top is greater than or equal to
	
	ADDU		= 0x13, -- unary addition
	ADDB		= 0x14, -- binary addition
}
