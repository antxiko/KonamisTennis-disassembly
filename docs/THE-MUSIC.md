# The music

Everything you hear here comes from running the cartridge's own sound engine (`reproduce`, 0x7AFC, and `arranca_sonido`, 0x7A68, which hands it the channels; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- game won (0x8E), whole, 146 frames;
- the end of the match (0x91), whole, 362 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`suena` takes the number in A: sounds 1, 2 and 3 always play and the rest only with someone playing (0xE002); `arranca_sonido` reserves the channels. Above 0x81 it is music and takes all three. The channels take 11 bytes each from 0xE211 and 0xE210 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; 0x8C and 0x8D, minutes long, and 0x97, which is silence, are left out.

## The tunes

**Game won** (0x8E)

Asked for by `acaba_el_juego`; lasts 2.4 s.

<audio controls preload="none" src="audio/musica_8E.mp3?v=8ee5b46c"></audio>

**The end of the match** (0x91)

Asked for by `fin_del_partido`: rótulo de cierre y vuelta al título; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_91.mp3?v=1d56e815"></audio>

**The start of the match** (0x94)

Asked for by `monta_la_pista`; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_94.mp3?v=9e9a038d"></audio>

**Table track 0x8F** (0x8F)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_8F.mp3?v=851023ac"></audio>

**Table track 0x90** (0x90)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_90.mp3?v=8c39e54f"></audio>

**Table track 0x92** (0x92)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_92.mp3?v=5c3e8ce7"></audio>

**Table track 0x93** (0x93)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=45eaa584"></audio>

**Table track 0x95** (0x95)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_95.mp3?v=c270a5bb"></audio>

**Table track 0x96** (0x96)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_96.mp3?v=d37589df"></audio>
