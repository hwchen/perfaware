module sim86;

import std::io;
import std::io::file;
import std::core::string;

fn int main(String[] args) {
	if (args.len != 2) {
		io::eprintn("Usage: sim86 <filepath>");
		return 1;
	}
	String path = args[1];
	char[4096 * 8] buf;
	char[]! instrs = file::load_buffer(path, &buf);
	if (catch err = instrs) {
		io::eprintfn("Error loading instructions: %s", err);
		return 1;
	}
	if (catch err = decode(instrs, path)) {
		io::eprintfn("Error decoding instructions: %s", err);
		return 1;
	}
	return 0;
}

fn void! decode(char[] instrs, String label) {
	io::printfn("; %s disassembly:\nbits 16", label);
	int i = 0;
	while (i < instrs.len) {
		// opcode is highest 6 bits of first byte of instruction
		char opcode = instrs[i] >> 2;
		switch (opcode) {
			case 0b100010: // mov
				int d = 0b00000010 & instrs[i];
				int w = 0b00000001 & instrs[i];
				String reg = REGISTERS[(0b00111000 & instrs[i+1]) >> 3][w];
				int rm = 0b00000111 & instrs[i+1];
				// check MOD
				int mod = (0b11000000 & instrs[i+1]) >> 6;
				switch (mod) {
					case 0b11: // register-to-register
						String rrm = REGISTERS[rm][w];
						if (d) {
							// d bit is 1, reg is destination
							io::printfn("mov %s, %s", reg, rrm);
						} else {
							io::printfn("mov %s, %s", rrm, reg);
						}
						i += 2;
					default:
						int address_const;
						switch (mod) {
							case 0b00: address_const = 0;
							case 0b01: address_const = (int)instrs[i+2];
							case 0b10: address_const = (int)instrs[i+2] + (instrs[i+3] << 8);
						}
						String address_format = EFFECTIVE_ADDRESS[rm][(int)(mod>=1)];
						String address = string::tformat(address_format, address_const);
						if (d) {
							// d bit is 1, reg is destination
							io::printfn("mov %s, %s", reg, address);
						} else {
							io::printfn("mov %s, %s", address, reg);
						}
						switch (mod) {
							case 0b00: i += 2;
							case 0b01: i += 3 + w;
							case 0b10: i += 4;
						}
				}
			default:
				io::eprintfn("unrecognized opcode: %b", opcode);
				return DecodeError.UNRECOGNIZED_OPCODE?;
		}
	}
}

fault DecodeError {
	UNRECOGNIZED_OPCODE,
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
	[0b000] = { "[BX+SI]", "[BX+SI+%d]" },
	[0b001] = { "[BX+DI]", "[BX+DI+%d]" },
	[0b010] = { "[BP+SI]", "[BP+SI+%d]" },
	[0b011] = { "[BP+DI]", "[BP+DI+%d]" },
	[0b100] = { "[SI]",    "[SI+%d]" },
	[0b101] = { "[DI]",    "[DI+%d]" },
	[0b110] = { "[%d]",    "[BP+%d]" },
	[0b111] = { "[BX]",    "[BX+%d]" },
};
