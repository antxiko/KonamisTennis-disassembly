# Getting started

A commented disassembly of **Konami's Tennis**, Konami's RC-720 for the MSX, a
16 KB cartridge mapped into page 1 (0x4000–0x7FFF). It reassembles into the
exact ROM, byte for byte, and every one of its 16,384 bytes is accounted for.

## The cartridge is not here

No repository distributes the game. Put your own dump in the root as
`tennis.rom`, 16384 bytes, sha256

    68bec8172d816025a21dd47482e9413fd8bd726b2cafb49236ca58a65c73e07f

`make comprueba` checks it.

## What each command does

    make            traces the flow, builds the listing, reassembles it and runs the tests
    make verify     the test that decides: reassembling must give the ROM back
    make sanity     that not one byte is left unexplained, and no data comes out as code
    make densidad   how much is commented, routine by routine
    make web        rebuilds this site from the ROM and the notes

## How it is put together

The listing is not hand-edited: `tools/mkasm.py` builds it from a flow trace and
a file of address-anchored notes, so the comments survive a re-trace. The tracer
follows the flow from the entry points; the ones it cannot deduce on its own —the
interrupt hook above all— are declared in `src/tennis.entries`, each with its
reason.

The pictures on the front page are not captures. `tools/graficos.py` draws them
by running in Python the cartridge's own steps: the two screen interpreters of
`tools/guiones.py`, the VRAM-to-VRAM copy at 0x442D and the sprite decompressor
at 0x5932. And they are not taken on trust: `graficos.py --comprueba` dumps the
emulator's VRAM and compares it byte for byte.
