# El código

7.882 bytes de código y 8.502 de datos. 492 rutinas con nombre, 1.368
comentarios anclados, el 32,4 % del listado comentado y ninguna rutina por
debajo del 10 %.

## Todo cuelga de la interrupción

0x4010 es un cuadro entero del juego. Lee el estado del VDP, marca 0xE01D para
que nadie le toque el VDP por detrás, lee los mandos, corre el sonido —que suena
en todos los cuadros, pase lo que pase— y luego, si hay partida, las nueve
tareas del cuadro, en orden, desde 0x4070:

    0x6D12  cambiar de lado a las parejas de dobles
    0x555D  darle su cuadro a cada jugador
    0x6E97  rotar las parejas entre puntos
    0x6B25  jugar por la máquina
    0x678D  decidir su golpe
    0x51FE  mover la pelota
    0x6ED2  los ojos del juez
    0x7932  repartir el punto
    0x7F56  volver a colocar a todos

0xE0D9 reparte ese trabajo entre cuadros: no cabe todo en uno.

## Los dos intérpretes de pantalla

El cartucho no guarda las pantallas como volcados de VRAM. Guarda **guiones**.

Las **listas de tiles** (0x43EA) son las sencillas: cada entrada empieza por su
dirección de VRAM en dos bytes y sigue con bytes que van al puerto de datos, con
`0xFE n b` para repetir y `0xFF` para cerrar. Dos `0xFF` seguidos cierran la
lista.

Los **guiones** (0x445F) empiezan por el número de bloques, y cada bloque lleva
un comando:

    0    bytes crudos, con 0x11 n b para repetir
    1    patrones por índice en la tabla de 0x489D, ocho bytes cada uno
    3    una dirección y luego pares de cuenta y valor
    *    una dirección, cuántas veces, y un puntero a un patrón de ocho bytes

Y una regla que lo atraviesa todo: **cualquier contador a cero vale 256**,
porque el Z80 decrementa antes de comprobar.

## Las figuras

Una postura son cinco sprites de 16x16 apilados. 0x5961 es una tabla de 58
entradas; cada una apunta a una descripción de doce bytes —cinco punteros a
patrón más un puntero a las cinco parejas (y,x). 0x58A9 carga los patrones y
0x58D4 los coloca.

El descompresor de sprites es 0x5932 y escribe siempre 32 bytes, con una sola
regla: `0x00 n` escribe n bytes a cero, y el resto pasa tal cual.

## La aritmética

El Z80 no multiplica ni divide, así que el cartucho se lo monta: 0x54AA desplaza
y resta ocho veces, 0x54CA desplaza y suma dieciséis, y 0x547E divide contando
cuántas veces cabe el divisor. El vuelo de la pelota está hecho con esas tres.

## El sonido

Tres canales, once bytes de estado cada uno desde 0xE211. Una melodía se lee por
el nibble alto de cada byte: `0x1x` duración, `0x2x` volumen, `0xDx` paso del
vibrato, `0xEx` octava, `0xFx` ancho del vibrato, `0xFE` sube una octava, `0xFF`
se acabó. Cualquier otro byte es una nota —nibble alto el semitono, bajo la
duración— y el periodo sale de la escala de doce de 0x7C5D, doblado una vez por
octava.
