module instruction;
import std::io;
import register;

struct Instruction {
	Operation op;
	Operand dest;
	Operand source;
}

enum Operation {
	NONE,
	MOV,
}

struct Operand {
	OperandType type;
	union {
		EffectiveAddressExpression address;
		Register register;
		short immediate;
	}
}

enum OperandType {
	EFFECTIVE_ADDRESS_EXPRESSION,
	REGISTER,
	IMMEDIATE,
}

struct EffectiveAddressExpression {
	Register[2] registers;
	short displacement;
}

struct Register {
	RegisterNames name;
	RegisterWidth width;
}

fn void! Instruction.write(&instr, OutStream out) {
	io::fprintf(out, "%s ", instr.op.nameof)!;
	instr.dest.write(out)!;
	io::fprintf(out, ", ")!;
	instr.source.write(out)!;
}

fn void! Operand.write(&operand, OutStream out) {
	switch (operand.type) {
		case EFFECTIVE_ADDRESS_EXPRESSION:
			io::fprintf(out, "[")!;
			operand.address.registers[0].write(out)!;
			// Hack to use ZERO as "null" since we dont write it out in instructions?
			if (operand.address.registers[1].name != RegisterNames.ZERO) {
				io::fprintf(out, "+")!;
				operand.address.registers[1].write(out)!;
			}
			io::fprintf(out, "+%d", operand.address.displacement)!;
			io::fprintf(out, "]")!;
		case REGISTER: operand.register.write(out)!;
		case IMMEDIATE: io::fprintf(out, "%d, ", operand.immediate)!;
	}
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

fn void test_instruction_write_register() @test {
	String expected = "MOV CX, BX";
	Instruction instr = {
		.op = MOV,
		.dest = {
			.type = REGISTER,
			.register = {
				.name = C,
				.width = X,
			},
		},
		.source = {
			.type = REGISTER,
			.register = {
				.name = B,
				.width = X,
			}
		},
	};
	ByteWriter wtr;
	wtr.temp_init();
	instr.write(&wtr)!!;
	String input = wtr.str_view();
	assert(input == expected, "Expected %s, found %s", expected, input);
}

fn void test_instruction_write_address() @test {
	String expected = "MOV CX, [SI+2555]";
	Instruction instr = {
		.op = MOV,
		.dest = {
			.type = REGISTER,
			.register = {
				.name = C,
				.width = X,
			},
		},
		.source = {
			.type = EFFECTIVE_ADDRESS_EXPRESSION,
			.address = {
				.registers = {
					{ .name = SI, .width = NONE },
					{ .name = ZERO, .width = NONE}
				},
				.displacement = 2555,
			}
		},
	};
	ByteWriter wtr;
	wtr.temp_init();
	instr.write(&wtr)!!;
	String input = wtr.str_view();
	assert(input == expected, "Expected %s, found %s", expected, input);
}

