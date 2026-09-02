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
        aviso="<b>Aqui no hay ninguna captura.</b> Todas las imagenes estan "
              "<b>dibujadas desde los bytes de la ROM</b>, ejecutando en Python "
              "los mismos interpretes que corre el Z80, y comprobadas contra la "
              "VRAM del emulador: <b>cero diferencias en 137.260 bytes</b>. El "
              "listado y las cifras se reproducen con <code>make</code>.",
        claim="Los tres tercios de la pantalla pintados con un solo bucle "
              "que se lee a si mismo, la tabla de colores debajo de la de "
              "patrones, y cada tenista montado con cinco sprites apilados.",
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
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the ROM</b>, by running in Python the same "
              "interpreters the Z80 runs, and checked against the emulator's "
              "VRAM: <b>zero differences across 137,260 bytes</b>. The listing "
              "and the numbers are reproducible with <code>make</code>.",
        claim="The screen's three thirds painted with a single loop that "
              "reads its own output, the colour table underneath the pattern "
              "table, and every player built from five stacked sprites.",
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
        ('Los tres tercios de la pantalla, con un solo bucle',
         '<p>SCREEN 2 son tres tercios independientes, y para que los tres '
         'tengan lo mismo hay que escribirlo tres veces. 0x442D copia de '
         'VRAM a VRAM byte a byte, y le mandan <b>4.095</b> bytes de '
         '0x0000 a 0x0800: como el destino va 0x800 por delante, pasado el '
         'primer bloque esta leyendo lo que el mismo acaba de escribir. Un '
         'bucle, tres tercios iguales, 4 KB ahorrados. Se hace dos veces: '
         'colores y patrones.</p>'),
        ('La tabla de colores va debajo de la de patrones',
         '<p>En SCREEN 2 el TMS9918 no lee R3 y R4 como una direccion, '
         'sino como un bit de base y una mascara. Con <code>R4 = '
         '0x07</code> los patrones quedan en <b>0x2000</b> y con <code>R3 '
         '= 0x7F</code> los colores en <b>0x0000</b>, al reves de lo '
         'habitual.</p><p>Leerlo del otro modo tiene un sintoma que '
         'engana: las formas se siguen reconociendo -los dos bloques son '
         'simetricos- pero los colores salen a franjas.</p>'),
        ('El juez de silla sigue la pelota con los ojos',
         '<p>No es un sprite: son <b>2x2 tiles</b> de la tabla de nombres. '
         '0x6ED2 mira donde esta la pelota, parte la pista en tres con '
         '0x48 y 0x78, y elige una de las <b>tres caras</b> de 0x715D. '
         'Solo cambian los ojos.</p>'),
        ('Una figura no es un sprite: son cinco',
         '<p>Cada postura son <b>cinco sprites de 16x16 apilados</b>. La '
         'tabla de 0x5961 tiene 58 entradas que apuntan a <b>37 '
         'descripciones</b> de doce bytes -cinco punteros a patron y uno a '
         'las cinco parejas (y,x)-, y entre todas gastan <b>189 '
         'patrones</b>.</p><p>El color no esta ahi: sale de la ficha del '
         'jugador, y por eso las jugadoras 3 y 4 llevan el pelo '
         '<b>magenta</b> donde las 1 y 2 lo llevan negro.</p>'),
        ('El rival falla con el registro de refresco',
         '<p>0x6BE9 hace <code>ld a,r</code>. R es el contador de refresco '
         'de la DRAM, que el Z80 adelanta en cada instruccion, asi que no '
         'se puede predecir. Rotado dos veces, es el temblor de la '
         'punteria del rival -y 0x6BEE lo deja a cero en la mitad de los '
         'cuadros.</p>'),
        ('La dificultad sube con lo que dura el peloteo',
         '<p>0xE20A cuenta los golpes del punto. 0x6E3B lo divide por dos, '
         'lo topa en quince y lo busca en una de las <b>tres curvas de '
         'dieciseis pasos</b> de 0x6E67, una por opcion del GAME SELECT. '
         'Cuanto mas se alarga el punto, mejor juega la maquina; pasado el '
         'golpe treinta ya no sube.</p>'),
        ('Seis bytes de codigo en la tabla de sprites',
         '<p>0x4272 pide <b>22 bytes</b> de atributos desde 0x7890, donde '
         'solo hay <b>16</b> de datos: lo que sigue en 0x78A0 ya es '
         'codigo. Asi que los seis primeros bytes de esa rutina acaban en '
         'la VRAM 0x3B3C, y ahi se quedan toda la partida. No se nota '
         'porque los patrones a los que apuntan estan vacios.</p>'),
        ('Una raqueta que no dibuja nadie',
         '<p>Nueve bytes en 0x61F5 se descomprimen a un sprite valido de '
         '16x16. No la apunta nadie, y no es una impresion: la palabra '
         '0x61F5 <b>no aparece en toda la ROM</b> en ninguno de los dos '
         'ordenes de byte, y todos los punteros a patron son palabras de '
         '16 bits. Tampoco coincide con ninguno de los 189 patrones que si '
         'se dibujan.</p>'),
        ('Todo contador a cero vale 256',
         '<p>Los guiones estan llenos de longitudes a cero, y no son '
         'bloques vacios: el Z80 decrementa antes de comprobar, asi que un '
         '<code>djnz</code> con B a cero da 256 vueltas. Es como se '
         'escribe 256 en un byte. Leerlas como ceros descuadra el guion a '
         'los pocos bloques.</p>'),
        ('El marcador cambia de nombre segun quien juegue',
         '<p>Con un jugador pone <b>PLY</b> y <b>MSX</b>; con dos '
         'personas, <b>1UP</b> y <b>2UP</b> -los seis tiles de 0x7760 y '
         'los seis de 0x7766. El guion de la pista deja escrito <b>CPU</b> '
         'ahi, y el juego lo tapa despues.</p><p>El alfabeto tampoco es '
         'ASCII: la A es 0xD1 y de ahi seguido, sin la Q, y con la <b>X '
         'fuera de orden en 0xE8</b>, detras de la Y.</p>'),
        ('La proteccion anticopia no salta al arrancar: salta al ganar un juego',
         '<p>Lo llamativo no es que la lleve -Konami la ponia en muchos de sus '
         'cartuchos, y el <b>RC-701</b> gasta la misma idea con un <code>ldir</code>- '
         'sino <b>cuando salta</b>. La comprobacion no esta en el arranque, donde se '
         'esperaria: esta en 0x7A31, dentro de la rutina que apunta un juego ganado. '
         'O sea que una copia <b>arranca bien, ensena el titulo, deja elegir y deja '
         'jugar</b>, y solo se rompe cuando alguien se lleva el primer juego. Para '
         'entonces quien la ha copiado ya la ha dado por buena.</p>'
         '<p>El mecanismo es de una sola instruccion: escribe un cero en <b>0x409A</b>, '
         'que es el <code>ret</code> con el que acaba el manejador de interrupcion, y '
         'en 0x409B empieza INIT. En ROM no hace nada, porque no se deja escribir; en '
         'RAM ese <code>ret</code> se vuelve un <code>nop</code>, la interrupcion sigue '
         'de largo y cae en INIT, con lo que <b>el juego se reinicia en cada cuadro</b>. '
         'Es la unica escritura de toda la ROM a su propia pagina, y aqui esta sin '
         'parchear.</p>'),
        ('No lleva la marca oculta de Konami',
         '<p>Konami escondia su numero de catalogo y el titulo en katakana '
         'al final de muchos cartuchos, en el offset 0x3FF0; lo descubrio '
         '<b>Manuel Pazos</b> (<a '
         'href="https://twitter.com/ManuelPazosMSX">@ManuelPazosMSX</a>). '
         'Este no la lleva, y no por no mirar: se rastrearon las 16.384 '
         'posiciones con un buscador validado antes contra cartuchos de la '
         'misma familia que si la llevan, que es la unica manera de fiarse '
         'de un negativo.</p>'),
    ],
    "en": [
        ("The screen's three thirds, with a single loop",
         '<p>SCREEN 2 is three independent thirds, and for all three to '
         'hold the same thing you have to write it three times. 0x442D '
         'copies VRAM to VRAM byte by byte, and is given <b>4,095</b> '
         'bytes from 0x0000 to 0x0800: since the destination runs 0x800 '
         'ahead, past the first block it is reading what it has just '
         'written. One loop, three identical thirds, 4 KB saved. Done '
         'twice: colours and patterns.</p>'),
        ('The colour table sits underneath the pattern table',
         '<p>In SCREEN 2 the TMS9918 does not read R3 and R4 as an '
         'address, but as a base bit and a mask. With <code>R4 = '
         '0x07</code> the patterns land at <b>0x2000</b> and with <code>R3 '
         '= 0x7F</code> the colours at <b>0x0000</b>, the reverse of the '
         'usual layout.</p><p>Reading it the other way has a deceptive '
         'symptom: the shapes still read -the two blocks are symmetric- '
         'but the colours come out in bands.</p>'),
        ('The chair umpire follows the ball with his eyes',
         '<p>He is not a sprite: he is <b>2x2 tiles</b> of the name table. '
         '0x6ED2 looks at where the ball is, splits the court into three '
         'with 0x48 and 0x78, and picks one of the <b>three faces</b> at '
         '0x715D. Only the eyes change.</p>'),
        ('A figure is not one sprite: it is five',
         '<p>Every pose is <b>five stacked 16x16 sprites</b>. The table at '
         '0x5961 has 58 entries pointing at <b>37</b> twelve-byte '
         'descriptions -five pattern pointers and one to the five (y,x) '
         'pairs- which between them spend <b>189 patterns</b>.</p><p>The '
         "colour is not there: it comes from the player's record, which is "
         'why players 3 and 4 have <b>magenta</b> hair where 1 and 2 have '
         'black.</p>'),
        ('The opponent misses using the refresh register',
         '<p>0x6BE9 does <code>ld a,r</code>. R is the DRAM refresh '
         'counter, which the Z80 advances on every instruction, so it '
         'cannot be predicted. Rotated twice, it is the wobble in the '
         "opponent's aim -and 0x6BEE leaves it at zero on half the "
         'frames.</p>'),
        ('The difficulty rises with the rally',
         "<p>0xE20A counts the point's strokes. 0x6E3B halves it, caps it "
         'at fifteen and looks it up in one of the <b>three sixteen-step '
         'curves</b> at 0x6E67, one per GAME SELECT option. The longer the '
         'point runs, the better the machine plays; past the thirtieth '
         'stroke it stops.</p>'),
        ('Six bytes of code in the sprite table',
         '<p>0x4272 asks for <b>22 bytes</b> of attributes from 0x7890, '
         'where there are only <b>16</b> of data: what follows at 0x78A0 '
         'is already code. So the first six bytes of that routine end up '
         'in VRAM at 0x3B3C, and there they stay for the whole match. It '
         'does not show, because the patterns they point at are empty.</p>'),
        ('A racket nobody draws',
         '<p>Nine bytes at 0x61F5 decompress into a valid 16x16 sprite. '
         'Nothing points at it, and that is not an impression: the word '
         '0x61F5 <b>appears nowhere in the ROM</b> in either byte order, '
         'and every pattern pointer is a 16-bit word. Nor does it match '
         'any of the 189 patterns that are drawn.</p>'),
        ('Every counter at zero means 256',
         '<p>The scripts are full of zero lengths, and they are not empty '
         'blocks: the Z80 decrements before it tests, so a '
         '<code>djnz</code> with B at zero runs 256 times. It is how you '
         'write 256 in one byte. Read them as zeros and the script goes '
         'out of step within a few blocks.</p>'),
        ('The scoreboard changes its names depending on who is playing',
         '<p>With one player it reads <b>PLY</b> and <b>MSX</b>; with two '
         'people, <b>1UP</b> and <b>2UP</b> -the six tiles at 0x7760 and '
         'the six at 0x7766. The court script leaves <b>CPU</b> written '
         'there, and the game paints over it.</p><p>The alphabet is not '
         'ASCII either: A is 0xD1 and on from there, with no Q, and with '
         '<b>X out of order at 0xE8</b>, behind the Y.</p>'),
        ('The copy protection does not fire on boot: it fires on winning a game',
         '<p>The striking part is not that it has one -Konami put these in many of '
         'its cartridges, and the <b>RC-701</b> uses the same idea with an '
         '<code>ldir</code>- but <b>when it fires</b>. The check is not at boot, where '
         'you would look for it: it is at 0x7A31, inside the routine that records a '
         'game won. So a copy <b>boots fine, shows the title, lets you choose and lets '
         'you play</b>, and only breaks once somebody takes the first game. By then '
         'whoever copied it has already called it good.</p>'
         '<p>The mechanism is one instruction: it writes a zero into <b>0x409A</b>, the '
         '<code>ret</code> that ends the interrupt handler, with INIT starting at 0x409B. '
         'In ROM it does nothing, because ROM will not take a write; in RAM that '
         '<code>ret</code> becomes a <code>nop</code>, the interrupt runs straight on '
         'into INIT, and <b>the game restarts on every frame</b>. It is the ROM&rsquo;s '
         'only write into its own page, and here it is unpatched.</p>'),
        ("It does not carry Konami's hidden mark",
         '<p>Konami hid its catalogue number and the title in katakana at '
         'the end of many cartridges, at offset 0x3FF0; <b>Manuel '
         'Pazos</b> (<a '
         'href="https://twitter.com/ManuelPazosMSX">@ManuelPazosMSX</a>) '
         'found it. This one does not have it, and not for want of '
         'looking: all 16,384 positions were scanned with a finder first '
         'validated against cartridges of the same family that do carry '
         'it, which is the only way to trust a negative.</p>'),
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
