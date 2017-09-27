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

	CMP_EQ	= 0x0F, -- compare the top 2 for equality
	CMP_NEQ	= 0x10, -- compare the top 2 for inequality
	CMP_LT	= 0x11, -- compare the top 2, push true if the second is less than the first
	CMP_LE	= 0x12, -- compare the top 2, push true if the second is less than or equal to the first
	CMP_GT	= 0x13, -- compare the top 2, push true if the second is greater than the first
	CMP_GE	= 0x14, -- compare the top 2, push true if the second is greater than or equal to the first

	ADDB		= 0x16, -- binary addition
	SUBB		= 0x17, -- binary subtraction
	MUL		= 0x18, -- [binary] multiplication
	DIV		= 0x19, -- [binary] division
	MOD		= 0x1A, -- [binary] modulo

	BAND		= 0x1B, -- bitwiseand
	BOR		= 0x1C, -- bitwise or
	BXOR		= 0x1D, -- bitwise exclusive or
	BNEG		= 0x1E, -- bitwise negation/not/flip/complement
	BSHL		= 0x1F, -- bitwise left shift
	BSHR		= 0x20, -- bitwise right shift
}
