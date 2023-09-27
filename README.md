# MEZ = Meow5 + ELF + Zig

**MOVED!** Hello, I am moving my repos to http://ratfactor.com/repos/
and setting them to read-only ("archived") on GitHub. Thank you, _-Dave_

This is a one-off utility (at least so far) written in Zig
to help me debug the 32-bit ELF executables I'm exporting
from
<a href="https://ratfactor.com/meow5/">Meow5</a>,
my toy language experiment.

This tool is highly specific to solving my bug.

(But, actually, I'm quite pleased with how nicely the
program LOAD segment display turned out. Now my little
brain can _see_ what is going on!)

Example output:

    $ ./build.sh
    $ ./mez
    -----------------------------------------
    Main ELF Header
      0-3 - four bytes of magic (0x7f,'ELF'): Matched!
        4 - 32-bit, as expected.
        5 - little-endian, as expected.
    24-27 - Program entry addr: 0x08048000
    28-31 - Program header offset (in this file): 0x34
    32-35 - Section header offset (in this file): 0x0
    40-41 - Size of this header: 52 bytes
    42-43 - Size of program header entries: 32 bytes
    44-45 - Number of program entries: 2
    -----------------------------------------
    Program Header @ 0x34
      Segment type: 1 ('load', as expected)
      File offset: 0x0
      File size: 4096 bytes
      Target memory start: 0x8048000
      Target memory size: 4096 bytes
      Memory mapping:
        +--------------------+     +--------------------+
        | File               | ==> | Memory             |
        |====================|     |====================|
        | 0x0                |     | 0x08048000         |
        |   Load: 4096       |     |   Alloc: 4096      |
        | 0x1000             |     | 0x08049000         |
        +--------------------+     +--------------------+
    -----------------------------------------
    Program Header @ 0x54
      Segment type: 1 ('load', as expected)
      File offset: 0x142
      File size: 5 bytes
      Target memory start: 0x8049000
      Target memory size: 10 bytes
      Memory mapping:
        +--------------------+     +--------------------+
        | File               | ==> | Memory             |
        |====================|     |====================|
        | 0x142              |     | 0x08049000         |
        |   Load: 5          |     |   Alloc: 10        |
        | 0x147              |     | 0x0804900a         |
        +--------------------+     +--------------------+

NOTE: Mez stupidly assumes you've got a file to examine called
`foo` in the current working directory directory.
