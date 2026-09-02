# The cartridge

16 KB in page 1, 0x4000–0x7FFF. The `AB` header declares **only INIT**, and
puts it at 0x409B — the first ten bytes are `41 42 9B 40 00 00 00 00 00 00`.

## What INIT does

It hooks the interrupt before anything else: it writes a 0xC3 into H.KEYI
(0xFD9A) and the address 0x4010 behind it, so **the whole game hangs off the
interrupt** and a static trace cannot reach it on its own. That is why
0x4010 is declared in `src/tennis.entries`.

Then it clears 0xE000–0xE3FE with an overlapping `ldir`, leaves the stack just
above it, silences the PSG, and loads the VDP's eight registers from the table
at 0x45C9.

## The screen

SCREEN 2, with those eight registers: `02 E2 0E 7F 07 76 03 E1`.

    R2 = 0x0E   name table ............. 0x3800
    R3 = 0x7F   colours ................ 0x0000
    R4 = 0x07   patterns ............... 0x2000
    R5 = 0x76   sprite attributes ...... 0x3B00
    R6 = 0x03   sprite patterns ........ 0x1800

R3 and R4 are the ones worth care: in SCREEN 2 the TMS9918 reads them as a base
bit and a mask, not as an address, so this cartridge ends up with **the colour
table underneath the pattern table** — the reverse of the usual layout.

## The map of the ROM

    0x4000  cartridge header
    0x4010  interrupt handler
    0x409B  INIT
    0x430F  four-bit direction table
    0x45C9  the VDP's eight registers
    0x45D1  the title screen's tile lists
    0x4686  the title screen script
    0x489D  35 eight-byte patterns, asked for by index
    0x49B5  the court script
    0x4FF1  the court's tile list
    0x5528  the ball's five sizes
    0x5961  58 pose entries, 37 descriptions, 189 patterns
    0x6AA7  the shot's effect table
    0x6E61  three difficulty curves
    0x715D  the umpire's three faces
    0x763A  the match messages and the scores
    0x776C  the ball boy's five groups
    0x7C5D  the twelve semitones and 25 tunes
    0x7FE9  23 bytes of 0xFF filler

## The hidden mark

Konami hid its catalogue number and the title in katakana at the end of many of
its cartridges — a find by **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)). This one does not carry
it. All 16,384 positions were scanned with `tools/busca_marca_konami.py`, a
finder first validated against cartridges of the same family that do carry it.
