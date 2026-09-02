# Open questions

Every byte of the cartridge is accounted for and the listing reassembles into
the exact ROM. What follows is what is explained but not fully understood, and
what has not been watched happen.

## The racket at 0x61F5

It is established that nothing points at it: the word does not appear in the
ROM in either byte order. What is not established is **why it is there**. A pose
that was cut? A first draft of a layer that ended up drawn differently? It sits
between two patterns that are used, so it is not tail-end filler.

## The six bytes of the sprite table

0x4272 asking for 22 bytes where there are 16 looks like a slip, and the six
that leak through are harmless because the patterns they point at are empty. But
"harmless" was checked on the dumps at hand: sprites 15 and 16 hold that rubbish
and nothing is seen. Whether some combination of patterns loaded later could
make them show has not been ruled out.

## The eight bytes at 0x550A and the eighteen at 0x5516

Both are read and both are explained by who reads them — 0x753B copies the first
eight to the ball's variables when a point starts, and 0x5492 indexes the second
by the class of shot. What each individual value means in the ball's physics is
not pinned down one by one.

## The thirty-six bytes at 0x6AA7

They are the shot's effect table, four bytes per class, and 0x69B0 copies them
into 0xE0AA spaced two apart. The four are used as force, spin and two
corrections, but which is which has been deduced from how they are consumed, not
proved on the screen.

## Doubles

The doubles code is fully traced — the pairs swap sides (0x6D12), share out the
net and baseline roles (0x6E09) and keep from getting in each other's way
(0x6CF7). It has not been played through: the demo only ever plays singles.

## The tunes

The 25 tunes at 0x7C69 are decoded and the format is known byte by byte. Which
tune is which in the game has only been matched for the ones the demo plays.

## The mark that is not there

The cartridge does not carry Konami's hidden mark, and that was checked over all
16,384 positions with a finder validated against cartridges that do carry it.
The ROM runs full of code and data to 0x7FE8 with 23 bytes of filler left, which
is a plausible reason — but it is a reason, not a proof of intent.
