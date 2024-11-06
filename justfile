@sim86-run *args="":
    just sim86-build && ./sim86 {{args}}

@sim86-build *args="":
    c3c compile sim86.c3 {{args}} 1>&2
