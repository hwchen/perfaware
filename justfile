@sim86-run *args="":
    just sim86-build && ./sim86 {{args}}

@sim86-build *args="":
    c3c compile sim86.c3 {{args}} 1>&2

sim86-test path:
    #! /usr/bin/bash
    just sim86-run {{path}} > {{path}}.test.asm
    nasm {{path}}.test.asm
    cmp {{path}}.test {{path}}
    rm {{path}}.test.asm {{path}}.test
    echo "Test successful: {{path}}"
