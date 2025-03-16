module register;
import std::collections::enummap;
import std::io;

struct Register {
	RegisterNames name;
	RegisterWidth width;
}

fn void? Register.write(&reg, OutStream out) {
	io::fprintf(out, "%s", reg.name.nameof)!;
	switch (reg.name) {
		case A:
		case B:
		case C:
		case D: io::fprintf(out, "%s", reg.width.nameof)!;
		default:
	}
}

const Register ZERO = { .name = ZERO,  .width = H };
const Register AH   = { .name = A,     .width = H };
const Register AL   = { .name = A,     .width = L };
const Register AX   = { .name = A,     .width = X };
const Register BH   = { .name = B,     .width = H };
const Register BL   = { .name = B,     .width = L };
const Register BX   = { .name = B,     .width = X };
const Register CH   = { .name = C,     .width = H };
const Register CL   = { .name = C,     .width = L };
const Register CX   = { .name = C,     .width = X };
const Register DH   = { .name = D,     .width = H };
const Register DL   = { .name = D,     .width = L };
const Register DX   = { .name = D,     .width = X };
const Register SP   = { .name = SP,    .width = NONE };
const Register BP   = { .name = BP,    .width = NONE };
const Register SI   = { .name = SI,    .width = NONE };
const Register DI   = { .name = DI,    .width = NONE };
const Register ES   = { .name = ES,    .width = NONE };
const Register CS   = { .name = CS,    .width = NONE };
const Register SS   = { .name = SS,    .width = NONE };
const Register DS   = { .name = DS,    .width = NONE };
const Register IP   = { .name = IP,    .width = NONE };

alias FieldEncodingRow = Register[2];

const FieldEncodingRow[] FIELD_ENCODING = {
	[0b000] = {AL, AX},
	[0b001] = {CL, CX},
	[0b010] = {DL, DX},
	[0b011] = {BL, BX},
	[0b100] = {AH, SP},
	[0b101] = {CH, BP},
	[0b110] = {DH, SI},
	[0b111] = {BH, DI},
};

enum RegisterNames {
	ZERO,
	A, // H,L,X
	B, // H,L,X
	C, // H,L,X
	D, // H,L,X
	SP,
	BP,
	SI,
	DI,
	ES,
	CS,
	SS,
	DS,
	IP,
}

// valid for A,B,C,D only
// Could use a validation fn on construction.
enum RegisterWidth {
	NONE,
	H, // hight
	L, // low
	X, // all
}

typedef RegisterState = EnumMap{RegisterNames, ushort};
