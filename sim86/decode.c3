module decode;
import std::io;
import std::core::string;
import instruction;
import register;

fault DecodeError {
	UNRECOGNIZED_OPCODE,
}

fn void! decode(char[] instrs, String label) {
	io::printfn("; %s disassembly:\nbits 16", label);
	int i = 0;
	while (i < instrs.len) {
		$if $feature(DEBUG_TRACE_DECODE):
			io::eprintfn("<DEBUG> === Start decode one instruction ===");
			io::eprintfn("<DEBUG> first byte: %08b", instrs[i]);
		$endif
		int advance = 0;
		switch {
			case instrs[i] >> 2 == 0b100010: // mov
				int d = (0b00000010 & instrs[i]) >> 1;
				int w = 0b00000001 & instrs[i];
				String reg = REGISTERS[(0b00111000 & instrs[i+1]) >> 3][w];
				int rm = 0b00000111 & instrs[i+1];
				// check MOD
				int mod = (0b11000000 & instrs[i+1]) >> 6;
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
									address_const = bytes_to_short(instrs[i+2:2]);
								}
							case 0b01: address_const = bytes_to_short(instrs[i+2:1]);
							case 0b10: address_const = bytes_to_short(instrs[i+2:2]);
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
			case instrs[i] >> 1 == 0b1100011: // mov immediate to register/memory
				int w = 0b00000001 & instrs[i];
				int rm = 0b00000111 & instrs[i+1];
				int mod = (0b11000000 & instrs[i+1]) >> 6;
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
					immediate = bytes_to_short(instrs[i+2+displacement:2]);
				} else {
					immediate = bytes_to_short(instrs[i+2+displacement:1]);
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
									address_const = bytes_to_short(instrs[i+2:2]);
								}
							case 0b01: address_const = (ichar)instrs[i+2];
							case 0b10: address_const = bytes_to_short(instrs[i+2:2]);
						}
						String address_format = EFFECTIVE_ADDRESS[rm][(int)(mod>=1)];
						String address = string::tformat(address_format, address_const);
						io::printfn("mov %s, %s %s", address, width, immediate);
				}
				advance = 2 + displacement + w + 1;
			case instrs[i] >> 4 == 0b1011: // mov immediate-to-register
				int w = (0b00001000 & instrs[i]) >> 3;
				int reg_bits = 0b00000111 & instrs[i];
				Register reg = register::REGISTER_FIELD_ENCODING[reg_bits][w];
				Instruction decoded = {
					.op = MOV,
					.dest = { .type = REGISTER, .register = reg },
					.source = { .type = IMMEDIATE, .immediate = bytes_to_short(instrs[i+1:w+1]) },
				};
				decoded.writen(io::stdout())!;
				advance = (w) ? 3 : 2;
			case instrs[i] >> 1 == 0b1010000: // mov mem to accumulator
				int w = 0b00000001 & instrs[i];
				String reg = (w) ? "ax" : "al";
				short address = bytes_to_short(instrs[i+1:2]);
				io::printfn("mov %s, [%d]", reg, address);
				advance = 3;
			case instrs[i] >> 1 == 0b1010001: // mov accumulator to mem
				int w = 0b00000001 & instrs[i];
				String reg = (w) ? "ax" : "al";
				short address = bytes_to_short(instrs[i+1:2]);
				io::printfn("mov [%d], %s", address, reg);
				advance = 3;
			default:
				return DecodeError.UNRECOGNIZED_OPCODE?;
		}
		$if $feature(DEBUG_TRACE_DECODE):
			debug_bytes(instrs[i:advance]);
			io::eprintfn("<DEBUG> === End decode one instruction ===");
		$endif
		i += advance;
	}
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
