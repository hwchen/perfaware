module sim86;
import std::io;
import std::io::file;
import decode;
import instruction;

fn int main(String[] args) {
	if (args.len != 2) {
		io::eprintn("Usage: sim86 <filepath>");
		return 1;
	}
	String path = args[1];
	char[4096 * 8] buf;
	char[]? instrs = file::load_buffer(path, &buf);
	if (catch err = instrs) {
		io::eprintfn("Error loading instructions: %s", err);
		return 1;
	}

	// disassemble
	io::printfn("; %s disassembly:\nbits 16", path);
	Instruction decoded;
	while (instrs.len > 0) {
		if (catch err = decode::next_instr(&instrs, &decoded)) {
			io::eprintfn("Error decoding instructions: %s", err);
			return 1;
		}
		//if (catch err = decoded.writen(io::stdout())) {
		//	io::eprintfn("Error writing disassembly: %s", err);
		//	return 1;
		//};
	}
	return 0;
}
