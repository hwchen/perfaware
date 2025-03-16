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
		AddrExpr address;
		Register register;
		short immediate;
	}
}

enum OperandType {
	ADDR_EXPR,
	REGISTER,
	IMMEDIATE,
}

struct AddrExpr {
	Register[2] registers;
	short displacement;
}

fn void? Instruction.write(&instr, OutStream out) {
	io::fprintf(out, "%s ", instr.op.nameof)!;
	instr.dest.write(out)!;
	io::fprintf(out, ", ")!;
	instr.source.write(out)!;
}

fn void? Instruction.writen(&instr, OutStream out) {
	instr.write(out)!;
	io::printfn("", out)!;
}

fn void? Operand.write(&operand, OutStream out) {
	switch (operand.type) {
		case ADDR_EXPR:
			io::fprintf(out, "[")!;
			// Hack to use ZERO as "null" since we dont write it out in instructions?
			if (operand.address.registers[0].name != RegisterNames.ZERO) {
				operand.address.registers[0].write(out)!;
			}
			if (operand.address.registers[1].name != RegisterNames.ZERO) {
				io::fprintf(out, "+")!;
				operand.address.registers[1].write(out)!;
			}
			io::fprintf(out, "+%d", operand.address.displacement)!;
			io::fprintf(out, "]")!;
		case REGISTER: operand.register.write(out)!;
		case IMMEDIATE: io::fprintf(out, "%d", operand.immediate)!;
	}
}

fn void test_instruction_write_register() @test {
	String expected = "MOV CX, BX";
	Instruction instr = {
		.op = MOV,
		.dest = { .type = REGISTER, .register = register::REG_CX },
		.source = { .type = REGISTER, .register = register::REG_BX },
	};
	ByteWriter wtr;
	wtr.tinit();
	instr.write(&wtr)!!;
	String input = wtr.str_view();
	assert(input == expected, "Expected %s, found %s", expected, input);
}

fn void test_instruction_write_address() @test {
	String expected = "MOV CX, [SI+2555]";
	Instruction instr = {
		.op = MOV,
		.dest = { .type = REGISTER, .register = register::REG_CX },
		.source = {
			.type = ADDR_EXPR,
			.address = {
				.registers = { register::REG_SI, register::REG_ZERO },
				.displacement = 2555,
			}
		},
	};
	ByteWriter wtr;
	wtr.tinit();
	instr.write(&wtr)!!;
	String input = wtr.str_view();
	assert(input == expected, "Expected %s, found %s", expected, input);
}
