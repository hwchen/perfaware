module sim86;

import std::io;
import std::io::file;

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
				// mod always 11 for now, for register-to-register
				String reg = REGISTERS[(0b00111000 & instrs[i+1]) >> 3][w];
				String rm = REGISTERS[0b00000111 & instrs[i+1]][w];
				if (d) {
					// d bit is 1, reg is destination
					io::printfn("mov %s, %s", reg, rm);
				} else {
					io::printfn("mov %s, %s", rm, reg);
				}
				i += 2;
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
