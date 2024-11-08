module decode;
import std::io;
import std::core::string;
import instruction;
import register;

fault DecodeError {
	UNRECOGNIZED_OPCODE,
}

fn void! next_instr(char[]* instrs_input, Instruction* decoded) {
	char[] instrs = *instrs_input;
	$if $feature(DEBUG_TRACE_DECODE):
		io::eprintfn("<DEBUG> === Start decode one instruction ===");
		io::eprintfn("<DEBUG> first byte: %08b", instrs[0]);
	$endif
	int advance = 0;
	switch {
		case instrs[0] >> 2 == 0b100010: // mov
			int d = (0b00000010 & instrs[0]) >> 1;
			int w = 0b00000001 & instrs[0];
			String reg = REGISTERS[(0b00111000 & instrs[1]) >> 3][w];
			int rm = 0b00000111 & instrs[1];
			// check MOD
			int mod = (0b11000000 & instrs[1]) >> 6;
			switch (mod) {
				case 0b11: // rm is a register
					String rrm = REGISTERS[rm][w];
					if (d) {
						// d bit is 1, reg is destination
						io::printfn("mov %s, %s", reg, rrm);
					} else {
						io::printfn("mov %s, %s", rrm, reg);
					}
				default: // rm is effective address
					short address_const;
					switch (mod) {
						case 0b00:
							if (rm == 0b110) {
								address_const = bytes_to_short(instrs[2:2]);
							}
						case 0b01: address_const = bytes_to_short(instrs[2:1]);
						case 0b10: address_const = bytes_to_short(instrs[2:2]);
					}
					String address_format = EFFECTIVE_ADDRESS[rm][(int)(mod>=1)];
					String address = string::tformat(address_format, address_const);
					if (d) {
						// d bit is 1, reg is destination
						io::printfn("mov %s, %s", reg, address);
					} else {
						io::printfn("mov %s, %s", address, reg);
					}
			}
			switch (mod) {
				case 0b00:
					advance = 2;
					if (rm == 0b110) {
						advance = 4;
					}
				case 0b01: advance = 3;
				case 0b10: advance = 4;
				case 0b11: advance = 2;
				default: $$unreachable();
			}

		case instrs[0] >> 1 == 0b1100011: // mov immediate to register/memory
			int w = 0b00000001 & instrs[0];
			int rm = 0b00000111 & instrs[1];
			int mod = (0b11000000 & instrs[1]) >> 6;
			int displacement;
			switch (mod) {
				case 0b00:
					displacement = 0;
					if (rm == 0b110) {
						displacement = 2;
					}
				case 0b01: displacement = 1;
				case 0b10: displacement = 2;
				case 0b11: displacement = 0;
				default: $$unreachable();
			}
			short immediate;
			if (w) {
				immediate = bytes_to_short(instrs[2+displacement:2]);
			} else {
				immediate = bytes_to_short(instrs[2+displacement:1]);
			}
			String width = (w) ? "word" : "byte";
			// check MOD
			switch (mod) {
				case 0b11: // rm is a register
					String rrm = REGISTERS[rm][w];
					io::printfn("mov %s, %s %s", rrm, width, immediate);
				default: // rm is effective address
					short address_const;
					switch (mod) {
						case 0b00:
							if (rm == 0b110) {
								address_const = bytes_to_short(instrs[2:2]);
							}
						case 0b01: address_const = (ichar)instrs[2];
						case 0b10: address_const = bytes_to_short(instrs[2:2]);
					}
					String address_format = EFFECTIVE_ADDRESS[rm][(int)(mod>=1)];
					String address = string::tformat(address_format, address_const);
					io::printfn("mov %s, %s %s", address, width, immediate);
			}
			advance = 2 + displacement + w + 1;

		case instrs[0] >> 4 == 0b1011: // mov immediate-to-register
			int w = (0b00001000 & instrs[0]) >> 3;
			int reg_bits = 0b00000111 & instrs[0];
			Register reg = register::FIELD_ENCODING[reg_bits][w];
			*decoded = {
				.op = MOV,
				.dest = { .type = REGISTER, .register = reg },
				.source = { .type = IMMEDIATE, .immediate = bytes_to_short(instrs[1:w+1]) },
			};
			decoded.writen(io::stdout())!;
			advance = (w) ? 3 : 2;

		case instrs[0] >> 1 == 0b1010000: // mov mem to accumulator
		case instrs[0] >> 1 == 0b1010001: // mov accumulator to mem
			int w = 0b00000001 & instrs[0];
			Operand reg = { .type = REGISTER, .register = register::FIELD_ENCODING[0][w] };
			Operand address = {
				.type = ADDR_EXPR,
				.address = { .displacement = bytes_to_short(instrs[1:2]) }
			};
			decoded.op = MOV;
			switch {
				case instrs[0] >> 1 == 0b1010000: // mov mem to accumulator
					decoded.dest = reg;
					decoded.source = address;
				case instrs[0] >> 1 == 0b1010001: // mov accumulator to mem
					decoded.dest = address;
					decoded.source = reg;
			}
			decoded.writen(io::stdout())!;
			advance = 3;

		default:
			return DecodeError.UNRECOGNIZED_OPCODE?;
	}
	$if $feature(DEBUG_TRACE_DECODE):
		debug_bytes(instrs[0:advance]);
		io::eprintfn("<DEBUG> === End decode one instruction ===");
	$endif
	*instrs_input = instrs[advance..];
}

// w=0, w=1
distinct RegisterFieldEncoding = String[2];

// REG, w=0, w=1
const RegisterFieldEncoding[] REGISTERS = {
	[0b000] = { "al", "ax" },
	[0b001] = { "cl", "cx" },
	[0b010] = { "dl", "dx" },
	[0b011] = { "bl", "bx" },
	[0b100] = { "ah", "sp" },
	[0b101] = { "ch", "bp" },
	[0b110] = { "dh", "si" },
	[0b111] = { "bh", "di" },
};


distinct EffectiveAddressCalc = String[2];

// [R/M] = { MOD=00, MOD=01, MOD=10 }
// MOD=01: + D8
// MOD=10: + D16
const EffectiveAddressCalc[] EFFECTIVE_ADDRESS = {
	[0b000] = { "[bx+si]", "[bx+si+%d]" },
	[0b001] = { "[bx+di]", "[bx+di+%d]" },
	[0b010] = { "[bp+si]", "[bp+si+%d]" },
	[0b011] = { "[bp+di]", "[bp+di+%d]" },
	[0b100] = { "[si]",    "[si+%d]" },
	[0b101] = { "[di]",    "[di+%d]" },
	[0b110] = { "[%d]",    "[bp+%d]" },
	[0b111] = { "[bx]",    "[bx+%d]" },
};

fn short bytes_to_short(char[] bytes) @inline {
	assert(bytes.len > 0); // No reason to call if no bytes
	assert(bytes.len <= 2);
	if (bytes.len == 2) {
		// second byte is most significant
		return bytes[0] | (bytes[1] << 8);
	} else {
		return (ichar)bytes[0];
	}
}

fn void debug_bytes(char[] bytes) {
	io::eprintf("<DEBUG> bytes(%d): %08b", bytes.len, bytes[0]);
	foreach (byte : bytes[1..]) {
		io::eprintf("_%08b", byte);
	}
	io::eprintn("");
}
