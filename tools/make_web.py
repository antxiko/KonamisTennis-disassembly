#!/usr/bin/env python3
"""Genera la portada de la web de Konami's Tennis, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/graficos.py a
partir de los propios bytes de la ROM, ejecutando en Python los mismos
interpretes y descompresores que corre el Z80, y estan comprobadas byte a byte
contra la VRAM de openMSX. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo:
# 16384 = 7882 + 8502, que es lo que imprime tools/presupuesto.py (make sanity).
# RUTINAS son las etiquetas con nombre propio, las mismas que cuenta el .notes
# con su directiva L. POSTURAS y PATRONES los cuenta tools/sprites.py.
CODIGO = 7882
DATOS = 8502
RUTINAS = 492
POSTURAS = 37
PATRONES = 189
DENSIDAD = "32,4"
DENSIDAD_EN = "32.4"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Konami's Tennis - desensamblado comentado",
        aviso="<b>Aqui no hay ninguna ilustracion ni captura.</b> El rotulo, "
              "la pista, los tenistas y hasta la cara del juez estan "
              "<b>dibujados desde los bytes de la ROM</b>, ejecutando en "
              "Python los mismos interpretes que corre el Z80, y comprobados "
              "byte a byte contra la VRAM del emulador: <b>cero diferencias "
              "en 137.260 bytes</b>, repartidos en doce volcados. El listado y "
              "las cifras salen del binario y se reproducen con <code>make</code>.",
        claim="Un cartucho de 16 KB que se defiende de las copias "
              "escribiendo en si mismo, pinta los tres tercios de la pantalla "
              "con un solo bucle, guarda la tabla de colores debajo de la de "
              "patrones y le pone al juez de silla tres caras para que siga la "
              "pelota con los ojos.",
        ficha=["Konami - <b>(c) Konami 1984</b>",
               "Cartucho <b>RC-720</b>, 16 KB",
               "MSX1 - <b>pagina 1</b>", "Volcado <b>68bec817...</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El codigo"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que aparecio al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas con nombre"),
                (DENSIDAD + " %", "del listado comentado"),
                (mil(CODIGO, "es"), "bytes de codigo"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen esta de donde sale y que se esta "
                 "viendo.",
        pie_leg="Esto es trabajo de documentacion y preservacion: el codigo y "
                "los graficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Konami's Tennis - a commented disassembly",
        aviso="<b>There is not one illustration or capture here.</b> The "
              "wordmark, the court, the players and even the umpire's face are "
              "<b>drawn from the bytes of the ROM</b>, by running in Python "
              "the same interpreters the Z80 runs, and checked byte for byte "
              "against the emulator's VRAM: <b>zero differences across "
              "137,260 bytes</b>, spread over twelve dumps. The listing and "
              "the numbers come from the binary and are reproducible with "
              "<code>make</code>.",
        claim="A 16 KB cartridge that defends itself against copies by "
              "writing on itself, paints the screen's three thirds with a "
              "single loop, keeps the colour table underneath the pattern "
              "table, and gives the chair umpire three faces so he can follow "
              "the ball with his eyes.",
        ficha=["Konami - <b>(c) Konami 1984</b>",
               "An <b>RC-720</b> 16 KB cartridge",
               "MSX1 - <b>page 1</b>", "Dump <b>68bec817...</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "named routines"),
                (DENSIDAD_EN + "%", "of the listing commented"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Se defiende de las copias escribiendo en si mismo",
         "<p>En toda la ROM hay <b>una sola</b> instruccion que escribe en la "
         "pagina del propio cartucho, y esta en 0x7A31: <code>ld "
         "(0409ah),a</code>, con A a cero. La direccion no es cualquiera: "
         "<b>0x409A es el <code>ret</code> con el que acaba el manejador de "
         "interrupcion</b>, y justo detras, en 0x409B, empieza INIT.</p>"
         "<p>En un cartucho no pasa nada, porque la ROM no se deja escribir. "
         "Pero en una copia cargada en RAM ese <code>ret</code> se convierte "
         "en un <code>nop</code>: la interrupcion sigue de largo, cae en INIT "
         "y <b>el juego se reinicia en cada cuadro</b>. No comprueba nada ni "
         "avisa de nada; simplemente deja de funcionar.</p>"
         "<p>Y salta tarde, al <b>ganar un juego</b>, con lo que una copia "
         "parece buena durante un buen rato. Es la misma idea que gasta el "
         "<b>RC-701</b> de esta misma serie, que alli va con un "
         "<code>ldir</code> sobre el despachador; en este cartucho esta "
         "<b>sin parchear y funcionando</b>.</p>"),
        ("Los tres tercios de la pantalla, con un solo bucle",
         "<p>SCREEN 2 del MSX son tres tercios independientes, y para que los "
         "tres tengan lo mismo hay que escribirlo tres veces. 0x442D no lo "
         "hace: copia de VRAM a VRAM byte a byte, y le mandan copiar "
         "<b>4.095</b> bytes de 0x0000 a 0x0800.</p>"
         "<p>Como el destino va 0x800 por delante del origen, cuando la copia "
         "pasa del primer bloque esta leyendo <b>lo que ella misma acaba de "
         "escribir</b>. Un solo bucle deja los tres tercios iguales, y el "
         "cartucho se ahorra 4 KB de datos. Se hace dos veces: una para los "
         "colores y otra para los patrones.</p>"),
        ("La tabla de colores va DEBAJO de la de patrones",
         "<p>Los ocho registros del VDP salen de la tabla de 0x45C9: "
         "<code>02 E2 0E 7F 07 76 03 E1</code>. Los dos del medio son los que "
         "enganan: en SCREEN 2 el TMS9918 no toma R3 y R4 como una direccion, "
         "sino como <b>un bit de base y una mascara</b>.</p>"
         "<p>Con R4 = 0x07 los <b>patrones</b> quedan en <b>0x2000</b>, y con "
         "R3 = 0x7F los <b>colores</b> en <b>0x0000</b>: al reves de la "
         "colocacion habitual. Leerlo del otro modo tiene un sintoma "
         "reconocible - las formas se siguen reconociendo, porque los dos "
         "bloques son simetricos, pero los colores salen a franjas.</p>"),
        ("El juez de silla sigue la pelota con los ojos",
         "<p>El juez no es un sprite: es un cuadro de <b>2x2 tiles</b> de la "
         "tabla de nombres. Y cambia. 0x6ED2 mira donde esta la pelota "
         "(0xE0B7), parte la pista en tres franjas con <b>0x48 y 0x78</b>, y "
         "con eso elige una de las <b>tres caras</b> que hay en la tabla de "
         "0x715D.</p>"
         "<p>Las tres solo se diferencian en los ojos: mirando a un lado, al "
         "otro, y al frente. Cuatro tiles reescritos y el juez sigue el "
         "peloteo.</p>"),
        ("Una figura no es un sprite: son cinco",
         "<p>Cada postura del tenista son <b>cinco sprites de 16x16 "
         "apilados</b>. 0x58A9 recorre cinco punteros seguidos "
         "(<code>ld b,005h</code>) descomprimiendo 32 bytes en cada vuelta, y "
         "0x58D4 salta esos diez bytes para llegar al sexto, que apunta a las "
         "cinco parejas (y,x) con el sitio de cada capa.</p>"
         "<p>La tabla de 0x5961 tiene 58 entradas -seis a cero, que son huecos "
         "de verdad- y apuntan a <b>%d descripciones</b> distintas de doce "
         "bytes, que entre todas gastan <b>%d patrones</b>. El color de cada "
         "capa no esta ahi: sale de la ficha del jugador, y por eso las "
         "jugadoras 3 y 4 llevan el pelo <b>magenta</b> donde las 1 y 2 lo "
         "llevan negro.</p>" % (POSTURAS, PATRONES)),
        ("El rival falla a proposito, con el registro de refresco",
         "<p>Cuando la maquina decide a que punto de la pista ir, 0x6BE9 hace "
         "<code>ld a,r</code>. R es el contador de refresco de la DRAM: lo "
         "lleva el propio Z80 y avanza con cada instruccion, asi que su valor "
         "en un instante cualquiera es impredecible. Rotado dos veces, es el "
         "<b>temblor de la punteria del rival</b>.</p>"
         "<p>Y no siempre: 0x6BEE mira el contador de cuadros y en la mitad de "
         "los casos deja el fallo a cero. Sin generador de aleatorios, sin "
         "semilla y sin una tabla que ocupe sitio.</p>"),
        ("La dificultad sube con lo que dura el peloteo",
         "<p>0xE20A cuenta los golpes que lleva el punto. 0x6E3B lo divide "
         "por dos, lo topa en quince y con eso busca en una de las <b>tres "
         "curvas de dieciseis pasos</b> de 0x6E67 - una por cada opcion del "
         "GAME SELECT.</p>"
         "<p>O sea que la maquina no juega igual todo el rato: <b>cuanto mas "
         "se alarga el punto, mejor juega</b>. Y a partir del golpe treinta ya "
         "no sube mas.</p>"),
        ("Un descuido que deja seis bytes de codigo en la tabla de sprites",
         "<p>0x4272 vuelca los atributos de los sprites del recogepelotas: "
         "<code>ld hl,07890h / ld de,07b2ch / ld b,016h</code>. Pide "
         "<b>22 bytes</b>. Pero en 0x7890 solo hay <b>16</b> de datos - cuatro "
         "sprites de cuatro bytes -, y lo que sigue en 0x78A0 ya es codigo.</p>"
         "<p>Asi que a la VRAM se van <b>los seis primeros bytes de la rutina "
         "de 0x78A0</b> (<code>D9 21 2C 7B 11 60</code>), y ahi se quedan toda "
         "la partida: se ven en el volcado del emulador, en 0x3B3C. Los "
         "sprites 15 y 16 quedan con esa basura por atributos. No se nota "
         "porque los patrones a los que apuntan estan <b>vacios</b>.</p>"),
        ("Una raqueta que no dibuja nadie",
         "<p>En 0x61F5 hay nueve bytes que se descomprimen a un sprite "
         "perfectamente valido de 16x16: una raqueta pequena, con su aro y su "
         "cordaje. Esta encajada entre dos patrones que si se usan.</p>"
         "<p>Pero <b>no la apunta nadie</b>, y eso no es una impresion: la "
         "palabra 0x61F5 <b>no aparece en ningun sitio de la ROM</b>, ni en "
         "little endian ni en big endian, y todos los punteros a patron son "
         "palabras de 16 bits. Tampoco coincide con ninguno de los %d "
         "patrones que si se dibujan. Sobra en el cartucho.</p>" % PATRONES),
        ("Todo contador a cero vale 256",
         "<p>Los guiones de pantalla estan llenos de longitudes a cero, y no "
         "son bloques vacios: el Z80 <b>decrementa antes de comprobar</b>, "
         "asi que un <code>djnz</code> con B a cero da 256 vueltas.</p>"
         "<p>Es la manera de escribir 256 en un byte, y el cartucho la usa en "
         "todas partes: en las longitudes de los sub-bloques, en las cuentas "
         "de repeticion, en el borrado de la tabla de nombres (0x441A, tres "
         "vueltas de 256) y en el relleno de los patrones. Leer esos ceros "
         "como ceros descuadra el guion entero a los pocos bloques.</p>"),
        ("El marcador cambia de nombre segun quien juegue",
         "<p>Con un jugador el marcador pone <b>PLY</b> y <b>MSX</b>; con dos "
         "personas, <b>1UP</b> y <b>2UP</b>. Son los seis tiles de 0x7760 y "
         "los seis de 0x7766, y 0x761A elige entre unos y otros.</p>"
         "<p>Y hay un detalle: el guion de la pista deja escrito <b>CPU</b> en "
         "esa casilla, y lo que se ve encima lo pinta el juego despues. El "
         "alfabeto tampoco es ASCII - la A es 0xD1 y de ahi seguido, sin la Q, "
         "y con la <b>X fuera de orden en 0xE8</b>, detras de la Y.</p>"),
        ("No lleva la marca oculta de Konami",
         "<p>Konami escondia al final de muchos cartuchos su numero de "
         "catalogo y el titulo en katakana; lo descubrio <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "y el bloque vive en el offset 0x3FF0. <b>Este no la lleva</b>, y no "
         "por no mirar: se rastrearon las 16.384 posiciones de la ROM con un "
         "buscador <b>validado antes contra cartuchos de la misma familia que "
         "si la llevan</b> - los RC-718 y RC-729 de la serie sueltan la suya "
         "al primer intento -, que es la unica manera de fiarse de un "
         "negativo.</p>"),
    ],
    "en": [
        ("It defends itself against copies by writing on itself",
         "<p>In the whole ROM there is <b>exactly one</b> instruction that "
         "writes into the cartridge's own page, and it sits at 0x7A31: "
         "<code>ld (0409ah),a</code>, with A zero. The address is not just "
         "any address: <b>0x409A is the <code>ret</code> that ends the "
         "interrupt handler</b>, and right behind it, at 0x409B, INIT "
         "begins.</p>"
         "<p>In a cartridge nothing happens, because ROM will not take a "
         "write. But in a copy loaded into RAM that <code>ret</code> becomes a "
         "<code>nop</code>: the interrupt runs straight on, falls into INIT, "
         "and <b>the game restarts on every frame</b>. It checks nothing and "
         "warns of nothing; it simply stops working.</p>"
         "<p>And it fires late, on <b>winning a game</b>, so a copy looks fine "
         "for a good while. It is the same idea the <b>RC-701</b> of this "
         "series uses, where it goes with an <code>ldir</code> over the "
         "dispatcher; in this cartridge it is <b>unpatched and working</b>.</p>"),
        ("The screen's three thirds, with a single loop",
         "<p>The MSX's SCREEN 2 is three independent thirds, and for all three "
         "to hold the same thing you have to write it three times. 0x442D does "
         "not: it copies VRAM to VRAM byte by byte, and is told to copy "
         "<b>4,095</b> bytes from 0x0000 to 0x0800.</p>"
         "<p>Since the destination runs 0x800 ahead of the source, once the "
         "copy passes the first block it is reading <b>what it has just "
         "written itself</b>. One loop leaves the three thirds identical, and "
         "the cartridge saves 4 KB of data. It is done twice: once for the "
         "colours and once for the patterns.</p>"),
        ("The colour table sits UNDERNEATH the pattern table",
         "<p>The VDP's eight registers come from the table at 0x45C9: "
         "<code>02 E2 0E 7F 07 76 03 E1</code>. The two in the middle are the "
         "deceptive ones: in SCREEN 2 the TMS9918 does not read R3 and R4 as "
         "an address, but as <b>a base bit and a mask</b>.</p>"
         "<p>With R4 = 0x07 the <b>patterns</b> land at <b>0x2000</b>, and "
         "with R3 = 0x7F the <b>colours</b> at <b>0x0000</b>: the reverse of "
         "the usual layout. Reading it the other way has a recognisable "
         "symptom - the shapes still read, because the two blocks are "
         "symmetric, but the colours come out in bands.</p>"),
        ("The chair umpire follows the ball with his eyes",
         "<p>The umpire is not a sprite: he is a <b>2x2 tile</b> block of the "
         "name table. And he changes. 0x6ED2 looks at where the ball is "
         "(0xE0B7), splits the court into three bands with <b>0x48 and "
         "0x78</b>, and picks one of the <b>three faces</b> in the table at "
         "0x715D.</p>"
         "<p>The three differ only in the eyes: looking one way, the other, "
         "and straight ahead. Four tiles rewritten and the umpire follows the "
         "rally.</p>"),
        ("A figure is not one sprite: it is five",
         "<p>Every player pose is <b>five stacked 16x16 sprites</b>. 0x58A9 "
         "walks five consecutive pointers (<code>ld b,005h</code>) "
         "decompressing 32 bytes each time round, and 0x58D4 skips those ten "
         "bytes to reach the sixth, which points at the five (y,x) pairs "
         "giving each layer its place.</p>"
         "<p>The table at 0x5961 has 58 entries - six of them zero, which are "
         "real gaps - pointing at <b>%d</b> distinct twelve-byte descriptions, "
         "which between them spend <b>%d patterns</b>. The colour of each "
         "layer is not there: it comes from the player's record, which is why "
         "players 3 and 4 have <b>magenta</b> hair where 1 and 2 have "
         "black.</p>" % (POSTURAS, PATRONES)),
        ("The opponent misses on purpose, using the refresh register",
         "<p>When the machine decides which spot on the court to head for, "
         "0x6BE9 does <code>ld a,r</code>. R is the DRAM refresh counter: the "
         "Z80 keeps it itself and it advances with every instruction, so its "
         "value at any given moment is unpredictable. Rotated twice, it is the "
         "<b>wobble in the opponent's aim</b>.</p>"
         "<p>And not always: 0x6BEE checks the frame counter and half the time "
         "leaves the error at zero. No random generator, no seed, and no table "
         "taking up room.</p>"),
        ("The difficulty rises with how long the rally lasts",
         "<p>0xE20A counts the strokes in the current point. 0x6E3B halves it, "
         "caps it at fifteen and uses that to index one of the <b>three "
         "sixteen-step curves</b> at 0x6E67 - one per GAME SELECT option.</p>"
         "<p>So the machine does not play the same all the way through: "
         "<b>the longer the point runs, the better it plays</b>. Past the "
         "thirtieth stroke it stops rising.</p>"),
        ("A slip that leaves six bytes of code in the sprite table",
         "<p>0x4272 dumps the ball boy's sprite attributes: <code>ld "
         "hl,07890h / ld de,07b2ch / ld b,016h</code>. It asks for <b>22 "
         "bytes</b>. But at 0x7890 there are only <b>16</b> of data - four "
         "sprites of four bytes - and what follows at 0x78A0 is already "
         "code.</p>"
         "<p>So <b>the first six bytes of the routine at 0x78A0</b> "
         "(<code>D9 21 2C 7B 11 60</code>) go into VRAM, and there they stay "
         "for the whole match: you can see them in the emulator dump, at "
         "0x3B3C. Sprites 15 and 16 end up with that rubbish for attributes. "
         "It does not show, because the patterns they point at are "
         "<b>empty</b>.</p>"),
        ("A racket nobody draws",
         "<p>At 0x61F5 there are nine bytes that decompress into a perfectly "
         "valid 16x16 sprite: a small racket, with its head and its strings. "
         "It is wedged between two patterns that are used.</p>"
         "<p>But <b>nothing points at it</b>, and that is not an impression: "
         "the word 0x61F5 <b>appears nowhere in the ROM</b>, neither little "
         "endian nor big endian, and every pattern pointer is a 16-bit word. "
         "Nor does it match any of the %d patterns that are drawn. It is spare "
         "in the cartridge.</p>" % PATRONES),
        ("Every counter at zero means 256",
         "<p>The screen scripts are full of zero lengths, and they are not "
         "empty blocks: the Z80 <b>decrements before it tests</b>, so a "
         "<code>djnz</code> with B at zero runs 256 times.</p>"
         "<p>It is how you write 256 in one byte, and the cartridge uses it "
         "everywhere: in sub-block lengths, in repeat counts, in clearing the "
         "name table (0x441A, three rounds of 256) and in padding patterns. "
         "Read those zeros as zeros and the whole script goes out of step "
         "within a few blocks.</p>"),
        ("The scoreboard changes its names depending on who is playing",
         "<p>With one player the board reads <b>PLY</b> and <b>MSX</b>; with "
         "two people, <b>1UP</b> and <b>2UP</b>. They are the six tiles at "
         "0x7760 and the six at 0x7766, and 0x761A picks between them.</p>"
         "<p>And there is a detail: the court script leaves <b>CPU</b> written "
         "in that cell, and what you see on top the game paints afterwards. "
         "The alphabet is not ASCII either - A is 0xD1 and on from there, with "
         "no Q, and with <b>X out of order at 0xE8</b>, behind the Y.</p>"),
        ("It does not carry Konami's hidden mark",
         "<p>At the end of many cartridges Konami hid its catalogue number and "
         "the title in katakana; <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "found it, and the block lives at offset 0x3FF0. <b>This one does not "
         "have it</b>, and not for want of looking: all 16,384 positions were "
         "scanned with a finder <b>first validated against cartridges of the "
         "same family that do carry it</b> - the RC-718 and RC-729 of this "
         "series give theirs up on the first try - which is the only way to "
         "trust a negative.</p>"),
    ],
}

GALERIA = [
    ("portada.png",
     "<b>La pantalla del titulo</b>, montada con los pasos del propio "
     "cartucho: el guion de 0x4686 deja los patrones y los colores, la copia "
     "solapada de 0x442D replica los tres tercios y las cuatro listas de "
     "tiles de 0x45D1 escriben el rotulo, el copyright y las tres opciones. "
     "Comparada con la VRAM del emulador, <b>cero diferencias</b>",
     "<b>The title screen</b>, built with the cartridge's own steps: the "
     "script at 0x4686 lays down the patterns and colours, the overlapping "
     "copy at 0x442D replicates the three thirds, and the four tile lists at "
     "0x45D1 write the wordmark, the copyright and the three options. "
     "Compared against the emulator's VRAM, <b>zero differences</b>"),
    ("pista.png",
     "<b>La pista</b>, con la tierra batida, la red, el publico, el juez de "
     "silla y el recogepelotas. La monta el guion de 0x49B5 y la remata la "
     "lista de tiles de 0x4FF1. El marcador esta vacio porque los tanteos no "
     "estan en el guion: los pinta el juego cuando hay partida",
     "<b>The court</b>, with its clay, the net, the crowd, the chair umpire "
     "and the ball boy. The script at 0x49B5 builds it and the tile list at "
     "0x4FF1 finishes it. The scoreboard is empty because the scores are not "
     "in the script: the game paints them once a match is on"),
    ("posturas_1.png",
     "Las <b>52 posturas</b> del tenista, cada una montada capa a capa como "
     "las monta 0x58A9: cinco sprites de 16x16 colocados con las parejas "
     "(y,x) de su descripcion. Correr, sacar, la derecha, el reves y la "
     "volea",
     "The player's <b>52 poses</b>, each assembled layer by layer the way "
     "0x58A9 does it: five 16x16 sprites placed with the (y,x) pairs from "
     "their description. Running, serving, forehand, backhand and volley"),
    ("posturas_3.png",
     "Las mismas figuras con los colores de la <b>tercera ficha</b>. Los "
     "dibujos son identicos; lo que cambia son los cinco colores de sprite "
     "que trae la ficha del jugador (0x57EB), y por eso esta lleva el pelo "
     "<b>magenta</b> y la ropa roja",
     "The same figures with the <b>third record's</b> colours. The artwork is "
     "identical; what changes are the five sprite colours the player's record "
     "carries (0x57EB), which is why this one has <b>magenta</b> hair and red "
     "clothes"),
    ("juez.png",
     "Las <b>tres caras del juez de silla</b>. No es un sprite: son 2x2 tiles "
     "de la tabla de nombres, y 0x6ED2 elige entre las tres segun en cual de "
     "las tres franjas de la pista este la pelota. Solo cambian los ojos",
     "The <b>chair umpire's three faces</b>. He is not a sprite: he is 2x2 "
     "tiles of the name table, and 0x6ED2 picks between the three depending "
     "on which of the court's three bands the ball is in. Only the eyes "
     "change"),
    ("recogepelotas.png",
     "Los <b>cinco pasos del recogepelotas</b>, que si es de sprites: 0x78A0 "
     "descomprime sus capas en la VRAM 0x1960 y les suma su posicion. Sale "
     "cuando la pelota se queda rodando, va a por ella y vuelve a su sitio",
     "The <b>ball boy's five steps</b> - he really is made of sprites: 0x78A0 "
     "decompresses his layers into VRAM 0x1960 and adds his position to them. "
     "He comes out when the ball is left rolling, fetches it and walks back"),
    ("pelota.png",
     "La pelota en sus <b>cinco tamanos</b>, con su sombra debajo. 0x5416 "
     "resta la altura de la pelota y la de su sombra y compara con "
     "<b>0x21, 0x0F y 0x06</b>: cuanto mas alta va, mas pequena se dibuja",
     "The ball at its <b>five sizes</b>, with its shadow underneath. 0x5416 "
     "subtracts the ball's height from its shadow's and compares against "
     "<b>0x21, 0x0F and 0x06</b>: the higher it flies, the smaller it is "
     "drawn"),
    ("raqueta_sin_usar.png",
     "La <b>raqueta que no dibuja nadie</b>: nueve bytes en 0x61F5 que se "
     "descomprimen a un sprite valido y al que no apunta ninguna de las "
     "descripciones de postura. La palabra 0x61F5 no aparece en toda la ROM",
     "The <b>racket nobody draws</b>: nine bytes at 0x61F5 that decompress "
     "into a valid sprite and that no pose description points at. The word "
     "0x61F5 appears nowhere in the ROM"),
    ("tiles.png",
     "Los <b>256 tiles</b> del primer tercio de la pista con su color, tal "
     "como quedan en la VRAM despues del guion y de la copia solapada",
     "The court's first third's <b>256 tiles</b> with their colour, as they "
     "sit in VRAM after the script and the overlapping copy"),
    ("fuente.png",
     "La fuente con la que se escribe todo. No es ASCII: la A es 0xD1 y de "
     "ahi seguido, <b>sin la Q</b>, y con la <b>X fuera de orden en "
     "0xE8</b>; las cifras son 0xF0 mas el digito",
     "The font everything is written with. It is not ASCII: A is 0xD1 and on "
     "from there, <b>with no Q</b>, and with <b>X out of order at 0xE8</b>; "
     "the digits are 0xF0 plus the digit"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta en su pantalla de titulo, dibujado desde la
    # ROM por graficos.py. Si el PNG no esta, el trabajo NO esta hecho: se cae
    # al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Konami&#39;s Tennis">'
                if os.path.exists(ruta_logo) else "<h1>Konami&#39;s Tennis</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' - '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
