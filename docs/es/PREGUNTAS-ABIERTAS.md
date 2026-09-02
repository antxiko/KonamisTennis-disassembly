# Preguntas abiertas

Todos los bytes del cartucho están explicados y el listado reensambla dando la
ROM exacta. Lo que sigue es lo que está explicado pero no entendido del todo, y
lo que no se ha visto pasar.

## La raqueta de 0x61F5

Está establecido que no la apunta nadie: la palabra no aparece en la ROM en
ninguno de los dos órdenes de byte. Lo que no está establecido es **por qué está
ahí**. ¿Una postura que se cayó? ¿Un primer boceto de una capa que acabó
dibujándose de otro modo? Está encajada entre dos patrones que sí se usan, así
que no es relleno de la cola.

## Los seis bytes de la tabla de sprites

Que 0x4272 pida 22 bytes donde hay 16 parece un descuido, y los seis que se
cuelan son inofensivos porque los patrones a los que apuntan están vacíos. Pero
lo de "inofensivos" se comprobó sobre los volcados que hay: los sprites 15 y 16
llevan esa basura y no se ve nada. No está descartado que alguna combinación de
patrones cargados más tarde pudiera hacerlos visibles.

## Los ocho bytes de 0x550A y los dieciocho de 0x5516

Los dos se leen y los dos están explicados por quien los lee —0x753B copia los
ocho primeros a las variables de la pelota al empezar un punto, y 0x5492 indexa
los segundos por la clase de golpe. Lo que significa cada valor suelto dentro de
la física de la pelota no está fijado uno por uno.

## Los treinta y seis bytes de 0x6AA7

Son la tabla de efectos del golpe, cuatro bytes por clase, y 0x69B0 los copia a
0xE0AA salteados de dos en dos. Los cuatro se usan como fuerza, efecto y dos
correcciones, pero cuál es cuál se ha deducido de cómo se consumen, no
demostrado en pantalla.

## Los dobles

El código de dobles está trazado entero —las parejas se cambian de lado
(0x6D12), se reparten los papeles de red y fondo (0x6E09) y se evitan entre
ellas (0x6CF7). No se ha jugado: la demostración sólo juega individuales.

## Las melodías

Las 25 melodías de 0x7C69 están descodificadas y el formato se conoce byte a
byte. Cuál es cuál dentro del juego sólo está emparejado para las que suenan en
la demostración.

## La marca que no está

El cartucho no lleva la marca oculta de Konami, y eso se comprobó sobre las
16.384 posiciones con un buscador validado contra cartuchos que sí la llevan. La
ROM llega llena de código y datos hasta 0x7FE8 con 23 bytes de relleno, que es
una razón plausible —pero es una razón, no una prueba de la intención.
