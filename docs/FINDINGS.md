# Findings

## The screen's three thirds, with a single loop

0x442D copies VRAM to VRAM byte by byte, and is asked for **4,095** bytes from
0x0000 to 0x0800. Since the destination runs 0x800 ahead of the source, past the
first block it is reading what it has just written. One loop, three identical
thirds, 4 KB saved. Done twice: colours, then patterns.

## The colour table underneath the pattern table

`R4 = 0x07` puts the patterns at 0x2000 and `R3 = 0x7F` the colours at 0x0000,
because in SCREEN 2 those registers are a base bit and a mask, not an address.

Read the other way, the symptom is deceptive: the shapes still come out — the
two blocks are symmetric — but the colours arrive in bands.

## The chair umpire follows the ball with his eyes

He is 2x2 tiles of the name table, not a sprite. 0x6ED2 reads the ball's
position in 0xE0B7, splits the court into three with 0x48 and 0x78, and picks
one of the three faces at 0x715D. Only the eyes differ.

## A figure is five sprites

Every pose is five stacked 16x16 sprites. 0x5961 has 58 entries pointing at 37
twelve-byte descriptions — five pattern pointers and one to the five (y,x)
pairs — which between them spend 189 patterns.

The colour is not there: it comes from the player's record, which is why players
3 and 4 have magenta hair where 1 and 2 have black.

## The opponent misses using the refresh register

0x6BE9 does `ld a,r`. R is the DRAM refresh counter, which the Z80 advances on
every instruction, so it cannot be predicted. Rotated twice, it is the wobble in
the opponent's aim — and 0x6BEE leaves it at zero on half the frames.

## The difficulty rises with the rally

0xE20A counts the strokes. 0x6E3B halves it, caps it at fifteen, and looks it up
in one of the three sixteen-step curves at 0x6E67. The longer the point runs,
the better the machine plays.

## Six bytes of code in the sprite table

0x4272 asks for 22 bytes of sprite attributes from 0x7890, where there are only
16 of data. The six that follow are the start of the routine at 0x78A0, and they
go straight into VRAM at 0x3B3C, where they stay for the whole match. It does
not show, because the patterns they point at are empty.

## A racket nobody draws

Nine bytes at 0x61F5 decompress into a valid 16x16 sprite. The word 0x61F5
appears nowhere in the ROM, in either byte order, and every pattern pointer is a
16-bit word. It matches none of the 189 patterns that are drawn.

## Every counter at zero means 256

The scripts are full of zero lengths, and they are not empty blocks: `djnz` with
B at zero runs 256 times. Read them as zeros and the script goes out of step
within a few blocks.

## PLY and MSX, or 1UP and 2UP

With one player the board reads PLY and MSX; with two people, 1UP and 2UP — the
six tiles at 0x7760 and the six at 0x7766. The court script leaves **CPU**
written in that cell and the game paints over it.

The alphabet is not ASCII: A is 0xD1 and on from there, with no Q, and with **X
out of order at 0xE8**, behind the Y. Digits are 0xF0 plus the digit.

## The copy protection does not fire on boot: it fires on winning a game

The striking part is not that it has one — Konami put these in many of its
cartridges, and the RC-701 uses the same idea with an `ldir` — but **when it
fires**. The check is not at boot, where you would look for it: it is at 0x7A31,
inside the routine that records a game won. So a copy **boots fine, shows the
title, lets you choose and lets you play**, and only breaks once somebody takes
the first game. By then whoever copied it has already called it good.

The mechanism is one instruction: it writes a zero into **0x409A**, the `ret`
that ends the interrupt handler, with INIT starting at 0x409B. In ROM it does
nothing, because ROM will not take a write; in RAM that `ret` becomes a `nop`,
the interrupt runs straight on into INIT, and **the game restarts on every
frame**. It is the ROM's only write into its own page, and here it is
unpatched.

## It does not carry Konami's hidden mark

Konami hid its catalogue number and the title in katakana at the end of many
cartridges, at offset 0x3FF0; **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)) found it. This one does
not have it, and not for want of looking: all 16,384 positions were scanned with
a finder first validated against cartridges of the same family that do carry it.
