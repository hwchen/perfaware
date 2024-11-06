@sim86-build *args="":
    c3c compile sim86.c3 {{args}} 1>&2

@sim86-test-decode:
    \fd 'decode' sim86-test --exclude '*.asm' -x just sim86-test-one

sim86-test-one path:
    #! /usr/bin/bash
    ./sim86 {{path}} > {{path}}.test.asm
    nasm {{path}}.test.asm
    cmp {{path}}.test {{path}}
    if [ $? -ne 0 ]; then
        # error
        echo "x - {{path}}"
    else
        echo ". - {{path}}"
    fi
    rm {{path}}.test.asm {{path}}.test
