# El cartucho

16 KB en la página 1, 0x4000–0x7FFF. La cabecera `AB` declara **solo INIT**, y
lo pone en 0x409B —los diez primeros bytes son `41 42 9B 40 00 00 00 00 00 00`.

## Lo que hace INIT

Engancha la interrupción antes que nada: escribe un 0xC3 en H.KEYI (0xFD9A) y
la dirección 0x4010 detrás, con lo que **todo el juego cuelga de la
interrupción** y un trazado estático no puede llegar solo. Por eso 0x4010 está
declarado en `src/tennis.entries`.

Después borra 0xE000–0xE3FE con un `ldir` solapado, deja la pila justo encima,
calla el PSG y carga los ocho registros del VDP de la tabla de 0x45C9.

## La pantalla

SCREEN 2, con esos ocho registros: `02 E2 0E 7F 07 76 03 E1`.

    R2 = 0x0E   tabla de nombres ....... 0x3800
    R3 = 0x7F   colores ................ 0x0000
    R4 = 0x07   patrones ............... 0x2000
    R5 = 0x76   atributos de sprite .... 0x3B00
    R6 = 0x03   patrones de sprite ..... 0x1800

R3 y R4 son los que hay que mirar con cuidado: en SCREEN 2 el TMS9918 los lee
como un bit de base y una máscara, no como una dirección, así que este cartucho
acaba con **la tabla de colores debajo de la de patrones** —al revés de la
colocación habitual.

## El mapa de la ROM

    0x4000  cabecera del cartucho
    0x4010  manejador de interrupción
    0x409B  INIT
    0x430F  tabla de las direcciones de cuatro bits
    0x45C9  los ocho registros del VDP
    0x45D1  las listas de tiles del título
    0x4686  el guion de la pantalla de título
    0x489D  35 patrones de ocho bytes, pedidos por índice
    0x49B5  el guion de la pista
    0x4FF1  la lista de tiles de la pista
    0x5528  los cinco tamaños de la pelota
    0x5961  58 entradas de postura, 37 descripciones, 189 patrones
    0x6AA7  la tabla de efectos del golpe
    0x6E61  las tres curvas de dificultad
    0x715D  las tres caras del juez
    0x763A  los mensajes del partido y los tanteos
    0x776C  los cinco grupos del recogepelotas
    0x7C5D  los doce semitonos y 25 melodías
    0x7FE9  23 bytes de relleno 0xFF

## La marca oculta

Konami escondía su número de catálogo y el título en katakana al final de
muchos de sus cartuchos —un hallazgo de **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)). Éste no la lleva. Se
rastrearon las 16.384 posiciones con `tools/busca_marca_konami.py`, un buscador
validado antes contra cartuchos de la misma familia que sí la llevan.
