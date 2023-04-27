# MEZ = Meow5 + ELF + Zig

This is a one-off utility (at least so far) written in Zig
to help me debug the 32-bit ELF executables I'm exporting
from
<a href="https://ratfactor.com/meow5/">Meow5</a>,
my toy language experiment.

This tool is highly specific to solving my bug.

    $ ./build.sh
    $ ./mez
    ELF HEADER
      e_ident - ei_mag0-3 (4 bytes of magic number): 7f454c46 GOOD!
    program entry addr: 0x08048000

NOTE: It assumes you've got a file to examine called `foo` in
the current working directory directory.
