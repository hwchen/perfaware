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
		$if $feature(DEBUG_TRACE_DECODE):
			io::eprintfn("<DEBUG> === Start decode one instruction ===");
			io::eprintfn("<DEBUG> first byte: %08b", instrs[i]);
		$endif
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
						int address_const;
						switch (mod) {
							case 0b00:
								if (rm == 0b110) {
									address_const = instrs[i+2] + (instrs[i+3] << 8);
								}
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
				}
				int advance;
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
				$if $feature(DEBUG_TRACE_DECODE):
					debug_bytes(instrs[i:advance]);
				$endif
				i += advance;
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
				int immediate = instrs[i+2+displacement];
				if (w) immediate += (instrs[i+2+displacement] << 8);
				// check MOD
				switch (mod) {
					case 0b11: // rm is a register
						String rrm = REGISTERS[rm][w];
						io::printfn("mov %s, %s", rrm, immediate);
					default: // rm is effective address
						int address_const;
						switch (mod) {
							case 0b00:
								if (rm == 0b110) {
									address_const = instrs[i+2] + (instrs[i+3] << 8);
								}
							case 0b01: address_const = instrs[i+2];
							case 0b10: address_const = instrs[i+2] + (instrs[i+3] << 8);
						}
						String address_format = EFFECTIVE_ADDRESS[rm][(int)(mod>=1)];
						String address = string::tformat(address_format, address_const);
						io::printfn("mov %s, %s", address, immediate);
				}
				int advance = 2 + displacement + w + 1;
				$if $feature(DEBUG_TRACE_DECODE):
					debug_bytes(instrs[i:advance]);
				$endif
				i += advance;
			case instrs[i] >> 4 == 0b1011: // mov immediate-to-register
				int w = (0b00001000 & instrs[i]) >> 3;
				String reg = REGISTERS[0b00000111 & instrs[i]][w];
				int immediate = (int)instrs[i+1];
				if (w) immediate += instrs[i+2] << 8;
				io::printfn("mov %s, %d", reg, immediate);
				int advance = (w) ? 3 : 2;
				$if $feature(DEBUG_TRACE_DECODE):
					debug_bytes(instrs[i:advance]);
				$endif
				i += advance;
			default:
				return DecodeError.UNRECOGNIZED_OPCODE?;
		}
		$if $feature(DEBUG_TRACE_DECODE):
			io::eprintfn("<DEBUG> === End decode one instruction ===");
		$endif
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
	[0b000] = { "[bx+si]", "[bx+si+%d]" },
	[0b001] = { "[bx+di]", "[bx+di+%d]" },
	[0b010] = { "[bp+si]", "[bp+si+%d]" },
	[0b011] = { "[bp+di]", "[bp+di+%d]" },
	[0b100] = { "[si]",    "[si+%d]" },
	[0b101] = { "[di]",    "[di+%d]" },
	[0b110] = { "[%d]",    "[bp+%d]" },
	[0b111] = { "[bx]",    "[bx+%d]" },
};

fn void debug_bytes(char[] bytes) {
	io::printf("<DEBUG> bytes(%d): %08b", bytes.len, bytes[0]);
	foreach (byte : bytes[1..]) {
		io::printf("_%08b", byte);
	}
	io::printn();
}
