module register;
import std::collections::enummap;

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
