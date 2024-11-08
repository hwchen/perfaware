module register;
import std::collections::enummap;
import std::io;

struct Register {
	RegisterNames name;
	RegisterWidth width;
}

fn void! Register.write(&reg, OutStream out) {
	io::fprintf(out, "%s", reg.name.nameof)!;
	switch (reg.name) {
		case A:
		case B:
		case C:
		case D: io::fprintf(out, "%s", reg.width.nameof)!;
		default:
	}
}

const Register REG_ZERO = { .name = ZERO,  .width = H };
const Register REG_AH   = { .name = A,     .width = H };
const Register REG_AL   = { .name = A,     .width = L };
const Register REG_AX   = { .name = A,     .width = X };
const Register REG_BH   = { .name = B,     .width = H };
const Register REG_BL   = { .name = B,     .width = L };
const Register REG_BX   = { .name = B,     .width = X };
const Register REG_CH   = { .name = C,     .width = H };
const Register REG_CL   = { .name = C,     .width = L };
const Register REG_CX   = { .name = C,     .width = X };
const Register REG_DH   = { .name = D,     .width = H };
const Register REG_DL   = { .name = D,     .width = L };
const Register REG_DX   = { .name = D,     .width = X };
const Register REG_SP   = { .name = SP,    .width = NONE };
const Register REG_BP   = { .name = BP,    .width = NONE };
const Register REG_SI   = { .name = SI,    .width = NONE };
const Register REG_DI   = { .name = DI,    .width = NONE };
const Register REG_ES   = { .name = ES,    .width = NONE };
const Register REG_CS   = { .name = CS,    .width = NONE };
const Register REG_SS   = { .name = SS,    .width = NONE };
const Register REG_DS   = { .name = DS,    .width = NONE };
const Register REG_IP   = { .name = IP,    .width = NONE };

def RegisterFieldEncodingRow = Register[2];

const RegisterFieldEncodingRow[] REGISTER_FIELD_ENCODING = {
	[0b000] = {REG_AL, REG_AX},
	[0b001] = {REG_CL, REG_CX},
	[0b010] = {REG_DL, REG_DX},
	[0b011] = {REG_BL, REG_BX},
	[0b100] = {REG_AH, REG_SP},
	[0b101] = {REG_CH, REG_BP},
	[0b110] = {REG_DH, REG_SI},
	[0b111] = {REG_BH, REG_DI},
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

distinct RegisterState = EnumMap(<RegisterNames, ushort>);
