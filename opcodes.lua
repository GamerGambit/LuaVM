return {
	LOAD		= 0x00, -- load from memory
	LOADG		= 0x01, -- load global
	LOADK		= 0x02, -- load constant
	LOADL		= 0x04, -- load local
	LOADN		= 0x05, -- load null
	
	STORE		= 0x06, -- store in memory
	STOREG	= 0x07, -- store global
	STOREL	= 0x08, -- store local
	
	CALL		= 0x09, -- call subroutine
	RET		= 0x0A, -- return from subroutine
	
	POP		= 0x0B, -- pop value from the top of the stack
	
	BR			= 0x0C, -- branch to instruction
	BRT		= 0x0D, -- branch to instruction if TOP is true
	BRF		= 0x0E, -- branch to instruction if TOP is false
	
	ADDU		= 0x0F, -- unary addition
	ADDB		= 0x10, -- binary addition
}
