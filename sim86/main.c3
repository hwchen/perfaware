module sim86;
import std::io;
import std::io::file;
import decode;

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
	if (catch err = decode::decode(instrs, path)) {
		io::eprintfn("Error decoding instructions: %s", err);
		return 1;
	}
	return 0;
}
