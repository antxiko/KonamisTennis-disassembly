# El juego

Konami's Tennis es un cartucho de 1984 para MSX. Una pista, vista desde detrás
de la línea de fondo, y hasta cuatro jugadores en ella.

## Los dos menús

La pantalla de título ofrece **PLAY SELECT** con tres opciones: `1PLAYER`,
`2PLAYERS` y `DOUBLES`. La elegida va a 0xE00E, y es el número por el que
pregunta todo el cartucho después —0x5894 lo compara con 2 y 0x589A con 3, y
entre esas dos comparaciones se decide el juego entero si hay pareja en pista.

Si nadie toca nada, el reloj de 0xE001 se agota y la máquina juega contra sí
misma: eso es la demostración.

Después viene **GAME SELECT**, con 1, 2 o 3. Cae en 0xE0DA y elige cuál de las
tres curvas de dificultad usa el rival.

## Los cuatro jugadores

Cada jugador tiene una **ficha de 41 bytes**. Hay cuatro, en 0xE100, 0xE130,
0xE160 y 0xE190, y 0x57BE las copia de la tabla de 0x57EB al empezar el partido.
En la ficha viven la posición, la postura, las banderas, y los veinte bytes de
atributos de sprite que 0x5920 vuelca al VDP.

El bit 0 del byte 12 es lo que separa a un humano de la máquina: 0x588F lo
comprueba, y todas las rutinas que leen los mandos preguntan antes.

Los colores de las cinco capas también están en la ficha, y por eso las
jugadoras 3 y 4 llevan el **pelo magenta** donde las 1 y 2 lo llevan negro.

## El tanteo

0x7932 lleva la cuenta del tenis. 0xE030 y 0xE031 guardan los puntos de los dos,
y la rutina recorre la escalera: a tres iguales son iguales (0x79F1), a cuatro
es ventaja, y perderla devuelve a los dos a tres. Con seis se cierra el juego.

En el marcador se ven 00, 15, 30, 40 y A, sacados de la tabla de punteros de
0x76D7.

Los juegos ganados van a 0xE032 y 0xE035, y con seis se gana el set —que 0x7A48
apunta en 0xE048.

## Lo que hay en la pista

El juez en su silla, a la izquierda, y el recogepelotas a la derecha, no son
decoración del mismo modo: el **juez es de tiles**, un cuadro de 2x2 de la tabla
de nombres que cambia los ojos para seguir la pelota, y el **recogepelotas es de
sprites**, y sale cuando la pelota se queda rodando, va a por ella y vuelve a su
sitio.
