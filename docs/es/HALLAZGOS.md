# Hallazgos

## Los tres tercios de la pantalla, con un solo bucle

0x442D copia de VRAM a VRAM byte a byte, y le piden **4.095** bytes de 0x0000 a
0x0800. Como el destino va 0x800 por delante del origen, pasado el primer bloque
está leyendo lo que él mismo acaba de escribir. Un bucle, tres tercios iguales,
4 KB ahorrados. Se hace dos veces: colores y luego patrones.

## La tabla de colores debajo de la de patrones

`R4 = 0x07` pone los patrones en 0x2000 y `R3 = 0x7F` los colores en 0x0000,
porque en SCREEN 2 esos registros son un bit de base y una máscara, no una
dirección.

Leído al revés el síntoma engaña: las formas siguen saliendo —los dos bloques
son simétricos— pero los colores llegan a franjas.

## El juez de silla sigue la pelota con los ojos

Es 2x2 tiles de la tabla de nombres, no un sprite. 0x6ED2 lee la posición de la
pelota en 0xE0B7, parte la pista en tres con 0x48 y 0x78, y elige una de las
tres caras de 0x715D. Sólo cambian los ojos.

## Una figura son cinco sprites

Cada postura son cinco sprites de 16x16 apilados. 0x5961 tiene 58 entradas que
apuntan a 37 descripciones de doce bytes —cinco punteros a patrón y uno a las
cinco parejas (y,x)—, y entre todas gastan 189 patrones.

El color no está ahí: sale de la ficha del jugador, y por eso las jugadoras 3 y
4 llevan el pelo magenta donde las 1 y 2 lo llevan negro.

## El rival falla con el registro de refresco

0x6BE9 hace `ld a,r`. R es el contador de refresco de la DRAM, que el Z80
adelanta en cada instrucción, así que no se puede predecir. Rotado dos veces, es
el temblor de la puntería del rival —y 0x6BEE lo deja a cero en la mitad de los
cuadros.

## La dificultad sube con el peloteo

0xE20A cuenta los golpes. 0x6E3B lo divide por dos, lo topa en quince y lo busca
en una de las tres curvas de dieciséis pasos de 0x6E67. Cuanto más se alarga el
punto, mejor juega la máquina.

## Seis bytes de código en la tabla de sprites

0x4272 pide 22 bytes de atributos desde 0x7890, donde sólo hay 16 de datos. Los
seis siguientes son el principio de la rutina de 0x78A0, y se van derechos a la
VRAM 0x3B3C, donde se quedan toda la partida. No se nota, porque los patrones a
los que apuntan están vacíos.

## Una raqueta que no dibuja nadie

Nueve bytes en 0x61F5 se descomprimen a un sprite válido de 16x16. La palabra
0x61F5 no aparece en toda la ROM, en ninguno de los dos órdenes de byte, y todos
los punteros a patrón son palabras de 16 bits. No coincide con ninguno de los
189 patrones que sí se dibujan.

## Todo contador a cero vale 256

Los guiones están llenos de longitudes a cero, y no son bloques vacíos: un
`djnz` con B a cero da 256 vueltas. Leerlas como ceros descuadra el guion a los
pocos bloques.

## PLY y MSX, o 1UP y 2UP

Con un jugador el marcador pone PLY y MSX; con dos personas, 1UP y 2UP —los seis
tiles de 0x7760 y los seis de 0x7766. El guion de la pista deja escrito **CPU**
en esa casilla, y el juego lo tapa después.

El alfabeto tampoco es ASCII: la A es 0xD1 y de ahí seguido, sin la Q, y con la
**X fuera de orden en 0xE8**, detrás de la Y. Las cifras son 0xF0 más el dígito.

## La protección anticopia no salta al arrancar: salta al ganar un juego

Lo llamativo no es que la lleve —Konami la ponía en muchos de sus cartuchos, y
el RC-701 gasta la misma idea con un `ldir`— sino **cuándo salta**. La
comprobación no está en el arranque, donde se esperaría: está en 0x7A31, dentro
de la rutina que apunta un juego ganado. O sea que una copia **arranca bien,
enseña el título, deja elegir y deja jugar**, y sólo se rompe cuando alguien se
lleva el primer juego. Para entonces quien la ha copiado ya la ha dado por
buena.

El mecanismo es de una sola instrucción: escribe un cero en **0x409A**, que es
el `ret` con el que acaba el manejador de interrupción, y en 0x409B empieza
INIT. En ROM no hace nada, porque no se deja escribir; en RAM ese `ret` se
vuelve un `nop`, la interrupción sigue de largo y cae en INIT, con lo que **el
juego se reinicia en cada cuadro**. Es la única escritura de toda la ROM a su
propia página, y aquí está sin parchear.

## No lleva la marca oculta de Konami

Konami escondía su número de catálogo y el título en katakana al final de muchos
cartuchos, en el offset 0x3FF0; lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)). Éste no la lleva, y no
por no mirar: se rastrearon las 16.384 posiciones con un buscador validado antes
contra cartuchos de la misma familia que sí la llevan.
