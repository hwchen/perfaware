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

const Register REG_AH = { .name = A,  .width = H };
const Register REG_AL = { .name = A,  .width = L };
const Register REG_AX = { .name = A,  .width = X };
const Register REG_BH = { .name = B,  .width = H };
const Register REG_BL = { .name = B,  .width = L };
const Register REG_BX = { .name = B,  .width = X };
const Register REG_CH = { .name = C,  .width = H };
const Register REG_CL = { .name = C,  .width = L };
const Register REG_CX = { .name = C,  .width = X };
const Register REG_DH = { .name = D,  .width = H };
const Register REG_DL = { .name = D,  .width = L };
const Register REG_DX = { .name = D,  .width = X };
const Register REG_SP = { .name = SP, .width = NONE };
const Register REG_BP = { .name = BP, .width = NONE };
const Register REG_SI = { .name = SI, .width = NONE };
const Register REG_DI = { .name = DI, .width = NONE };
const Register REG_ES = { .name = ES, .width = NONE };
const Register REG_CS = { .name = CS, .width = NONE };
const Register REG_SS = { .name = SS, .width = NONE };
const Register REG_DS = { .name = DS, .width = NONE };
const Register REG_IP = { .name = IP, .width = NONE };

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
