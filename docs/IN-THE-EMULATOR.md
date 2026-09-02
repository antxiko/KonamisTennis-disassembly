# In the emulator

The pictures on the front page are drawn from the ROM, not captured. Looking at
them is not enough to call them right, so they are checked against the VRAM the
VDP really holds.

## The dump

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart tennis.rom -script tools/omsx_vram.tcl

`tools/omsx_vram.tcl` lets the game run and, at twelve moments, writes out the
16 KB of VRAM, the VDP's eight registers and the working variables that say what
was being drawn. It sets **no breakpoints**: the dumps go by emulated clock,
which is the only thing that does not choke the emulator.

The first ones are taken at nine seconds, not at three: before that the
cartridge is still halfway through painting the title and the VRAM is not
comparable with anything.

## The comparison

    python tools/graficos.py --comprueba tennis.rom 0x4000 work/omsx

    12 dumps, 137,260 bytes compared, 0 different

Two things are left out of the comparison, both with a reason. Dumps taken
before INIT has loaded the VDP registers, because the screen is not built yet.
And the 32 colour bytes of tiles 0xA5 to 0xA8, which are the fault message:
0x746F alternates two colour sets over them every seven frames, so their value
depends on the exact frame the dump was taken on.

## What that comparison found

It is what caught the pattern and colour tables being read the wrong way round.
The shapes came out fine — you could read "Konami's Tennis" — but the colours
arrived in bands. The VRAM matched byte for byte; the mistake was in reading it.

And it is what showed that the court script does not carry the font. Building
the court on an empty VRAM left 1,514 bytes different, all of them letters and
digits. The cartridge does not clear the patterns when it goes from the title to
the court: it only clears the name table, at 0x4234. Starting the court from the
title's VRAM, as the cartridge does, took those 1,514 differences to zero.

## Following the ball boy

`work/sigue_sprites.tcl` follows 0xE03A, 0xE03B and 0xE03C and the sprite
attributes at 0x3B3C. In two minutes of demo the ball boy never comes out: he
needs 0xE0C0 or 0xE044 set, and neither happens. Writing 0xE0C0 by hand from the
debugger brings him out, and his four sprites move with him — which is how
"he is made of sprites" stopped being a reading of the code and became something
seen.
