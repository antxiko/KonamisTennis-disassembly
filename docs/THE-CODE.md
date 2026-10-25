# The code

7,882 bytes of code and 8,502 of data. 492 named routines, 1,368 anchored
comments, 32.4% of the listing commented and no routine under 10%.

## Everything hangs off the interrupt

0x4010 is a whole frame of the game. It reads the VDP status, marks 0xE01D so
nobody else touches the VDP behind its back, reads the controls, runs the sound
— which plays on every frame, whatever else happens — and then, if there is a
match on, the nine tasks of the frame, in order, from 0x4070:

    0x6D12  swap the doubles pairs
    0x555D  give each player his frame
    0x6E97  rotate the pairs between points
    0x6B25  play the opponent
    0x678D  decide his shot
    0x51FE  move the ball
    0x6ED2  the umpire's eyes
    0x7932  award the point
    0x7F56  put everyone back in place

0xE0D9 spreads that work over frames: not all of it fits in one.

## The two screen interpreters

The cartridge does not store screens as VRAM dumps. It stores **scripts**.

**Tile lists** (0x43EA) are the simple one: each entry starts with its VRAM
address in two bytes and then bytes that go to the data port, with `0xFE n b`
to repeat and `0xFF` to close. Two `0xFF` in a row close the list.

**Scripts** (0x445F) start with a block count, and each block carries a command:

    0    raw bytes, with 0x11 n b to repeat
    1    patterns by index into the table at 0x489D, eight bytes each
    3    one address and then pairs of count and value
    *    one address, a repeat count, and a pointer to an eight-byte pattern

And a rule that runs through all of it: **any counter at zero means 256**,
because the Z80 decrements before it tests.

## The figures

A pose is five stacked 16x16 sprites. 0x5961 is a table of 58 entries; each
points at a twelve-byte description — five pattern pointers plus one pointer to
the five (y,x) pairs. 0x58A9 loads the patterns, 0x58D4 places them.

The sprite decompressor is 0x5932 and always writes 32 bytes, with one rule:
`0x00 n` writes n zero bytes, everything else goes through as it is.

## The arithmetic

There is no multiply or divide on a Z80, so the cartridge builds its own:
0x54AA shifts and subtracts eight times, 0x54CA shifts and adds sixteen, and
0x547E divides by counting how many times the divisor fits. The ball's flight
is built out of those three.

## The sound

Three channels, eleven bytes of state each from 0xE211. A tune is read by the
high nibble of each byte: `0x1x` duration, `0x2x` volume, `0xDx` vibrato step,
`0xEx` octave, `0xFx` vibrato width, `0xFE` up an octave, `0xFF` end. Anything
else is a note — high nibble the semitone, low nibble the duration — and the
period comes from the twelve-entry scale at 0x7C5D, doubled once per octave.

## Code shared with other Konami cartridges

This disassembly has been compared, instruction by instruction, with
every other Konami one in the series. A block counts when the same
instructions, at least six of them from a label to its `ret` or its
unconditional jump, are in both cartridges; the addresses are left
aside, because they change from one cartridge to the next. Of the
other 57, **33** have at least one block in common with this one;
these are the ones that share the most:

| Cartridge | Blocks | Instructions | For example (here = there) |
|---|---:|---:|---|
| [Konami's Baseball](https://antxiko.github.io/KonamisBaseball-disassembly/) | 32 | 518 | `manda_de_la_melodia` (0x7BE8) = `lee_una_nota_larga` |
| [Konami's Golf](https://antxiko.github.io/KonamisGolf-disassembly/) | 25 | 405 | `manda_de_la_melodia` (0x7BE8) = `corre_el_canal_nota_larga` |
| [Hyper Olympic 1](https://antxiko.github.io/HyperOlympic1-disassembly/) | 22 | 312 | `replica_vram` (0x442D) = `COPIA_VRAM_A_VRAM` |
| [Hyper Olympic 2](https://antxiko.github.io/HyperOlympic2-disassembly/) | 22 | 312 | `replica_vram` (0x442D) = `COPIA_VRAM_A_VRAM` |
| [Konami's Ping Pong](https://antxiko.github.io/KonamisPingPong-disassembly/) | 5 | 49 | `enciende_canal` (0x7AD6) = `pon_el_mezclador` |

The whole matrix, the 58 cartridges against each other, is on
[The routines](https://antxiko.github.io/MSX-disassembly-database/THE-ROUTINES.html) in the series database, along
with the method and the program that measures it.
