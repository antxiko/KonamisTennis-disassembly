; ==========================================================================
; KONAMI'S TENNIS - Konami - MSX1 - cartucho RC-720 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: AB, y la direccion de INIT; el resto a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,0409bh,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ======================================================================
; CODIGO 0x4010..0x430f  (767 bytes)
; ======================================================================


interrupcion:		; Un cuadro entero del juego; lo engancha INIT en H.KEYI
	call 0013eh		;4010   ; BIOS RDVDP - Reads VDP status register | lee el estado del VDP, que es lo que reconoce la interrupcion
	ld hl,0e01dh		;4013   ; 0xE01D avisa de que el VDP esta ocupado con la interrupcion
	ld (hl),001h		;4016
	inc hl			;4018
	ld a,(hl)			;4019   ; si 0xE01E esta puesto, alguien esta a medias con el VDP y no se toca
	or a			;401a
	ret nz			;401b
	call lee_para_el_menu		;401c   ; lee los dos mandos y el teclado
	ld a,(0e002h)		;401f   ; si hay menu en marcha, va por su rutina y no por la del juego
	or a			;4022
	jr z,interrupcion_sin_menu		;4023
	call mueve_al_humano		;4025
	jr interrupcion_sonido		;4028
interrupcion_sin_menu:		; No hay menu en marcha: se atiende la pista
	ld a,(0e060h)		;402a   ; 0xE060 corta el juego mientras dura un aviso
	or a			;402d
	jr nz,interrupcion_sonido		;402e
	call lee_los_mandos		;4030
interrupcion_sonido:		; El sonido corre en todos los cuadros
	call reproduce		;4033   ; el sonido suena en todos los cuadros, pase lo que pase
	di			;4036
	ld a,(0e00ch)		;4037   ; 0xE00C lo pone a uno el final de la interrupcion anterior
	or a			;403a
	jr z,interrupcion_fin		;403b
	xor a			;403d
	ld (0e00ch),a		;403e
	ld hl,0e000h		;4041   ; 0xE000 es el contador de cuadros
	inc (hl)			;4044
	ld a,(hl)			;4045
	and 01fh		;4046   ; cada 32 cuadros baja el reloj de 0xE001
	jr nz,interrupcion_con_partida		;4048
	inc hl			;404a
	dec (hl)			;404b
	ld a,(0e0e1h)		;404c   ; 0xE0E1 es otra cuenta atras, la del aviso
	or a			;404f
	jr z,interrupcion_con_partida		;4050
	dec a			;4052
	ld (0e0e1h),a		;4053
interrupcion_con_partida:		; A partir de aqui, solo si hay partida
	ld a,(0e003h)		;4056   ; 0xE003 dice si hay partida en marcha
	or a			;4059
	jr z,interrupcion_comprueba_cuadro		;405a
	ld a,(0e0d9h)		;405c   ; 0xE0D9 reparte el trabajo entre cuadros: no todo cabe en uno
	or a			;405f
	jr nz,interrupcion_tareas		;4060
	ld a,(0e0dah)		;4062   ; 0xE0DA guarda la opcion elegida en el menu
	ld hl,05512h		;4065   ; la dificultad sale de la tabla de 0x5512, indexada por esa opcion
	call suma_a_hl		;4068
	ld a,(hl)			;406b
interrupcion_tareas:		; Las nueve tareas del cuadro, en su orden
	dec a			;406c
	ld (0e0d9h),a		;406d
	call cambia_de_lado		;4070   ; y a partir de aqui, las nueve tareas del cuadro, en orden
	call turno_de_los_jugadores		;4073   ; mueve la pelota
	call rota_las_parejas		;4076
	call juega_la_maquina		;4079
	call decide_el_rival		;407c   ; dibuja las figuras
	call mueve_la_pelota		;407f   ; pinta lo que haya cambiado en la pantalla
	call mira_el_juez		;4082
	call reparte_el_tanteo		;4085
	call espera_a_todos		;4088
interrupcion_comprueba_cuadro:		; Si la interrupcion se comio el cuadro, se repite
	call 0013eh		;408b   ; BIOS RDVDP - Reads VDP status register | si la interrupcion se ha comido el cuadro entero, vuelve a empezar
	rlca			;408e
	jp c,interrupcion		;408f
interrupcion_fin:		; Deja pedido el trabajo del cuadro siguiente
	ld a,001h		;4092   ; deja 0xE00C a uno para que el siguiente cuadro haga el trabajo
	ld (0e01dh),a		;4094
	ld (0e00ch),a		;4097
	ret			;409a
init:		; Engancha la interrupcion, limpia la RAM y arranca el cartucho
	di			;409b   ; nada de interrupciones hasta tener el gancho puesto
	ld hl,0fd9ah		;409c   ; H.KEYI (0xFD9A) es el gancho de la BIOS para la interrupcion
	ld (hl),0c3h		;409f   ; un 0xC3 es un jp, y detras va la direccion
	ld hl,interrupcion		;40a1   ; el manejador es 0x4010
	ld (0fd9bh),hl		;40a4
	ld hl,0e000h		;40a7   ; borra de 0xE000 a 0xE3FE con el truco del ldir solapado
	ld de,0e001h		;40aa
	ld bc,003feh		;40ad
	ld (hl),l			;40b0   ; el primer byte a cero, y el ldir lo arrastra
	ldir		;40b1
	ld sp,hl			;40b3   ; y la pila se queda justo encima de lo borrado
	ld a,0b8h		;40b4   ; 0xE210 arranca con 0xB8
	ld (0e210h),a		;40b6
	call escribe_registro_7		;40b9
	ld a,008h		;40bc   ; apaga los tres canales de tono del PSG
	ld e,000h		;40be
	ld b,003h		;40c0
init_apaga_psg:		; Los tres volumenes del PSG a cero
	call 00093h		;40c2   ; BIOS WRTPSG - Writes data to PSG-register | registros 8, 9 y 10: los volumenes
	inc a			;40c5
	djnz init_apaga_psg		;40c6
	ld de,081a2h		;40c8
	call pon_escritura		;40cb
	ld a,00fh		;40ce   ; el registro 15 del PSG es el que manda al puerto de los mandos
	ld e,0cfh		;40d0
	call 00093h		;40d2   ; BIOS WRTPSG - Writes data to PSG-register
	call 00132h		;40d5   ; BIOS CHGCAP - Alternates the CAPS lamp status | apaga el piloto de CAPS, por si venia encendido
	im 1		;40d8   ; modo 1 de interrupcion, el del MSX
	ld hl,07aa8h		;40da
	ld (0e008h),hl		;40dd
	ld a,001h		;40e0
	ld (0e00ah),a		;40e2
	ld l,0a7h		;40e5
	ld (0e010h),hl		;40e7
	ld (0e012h),a		;40ea
init_pantalla:		; Deja la pantalla en SCREEN 2 y sin sprites
	xor a			;40ed   ; 0xE003 a cero: todavia no hay partida
	ld (0e003h),a		;40ee
	call borra_la_pantalla		;40f1   ; pone la pantalla en SCREEN 2
	call esconde_sprites		;40f4   ; esconde los 32 sprites
	di			;40f7
	ld hl,0e020h		;40f8   ; limpia 256 bytes de 0xE020
	ld bc,00100h		;40fb
	call borra_ram		;40fe
	ld hl,00000h		;4101
	ld (0e00eh),hl		;4104
	ld de,04000h		;4107   ; borra la tabla de nombres a base de escribir 0 tres veces 256
	call pon_escritura		;410a
init_borra_nombres:		; Tres vueltas de 256 tiles a cero
	ld b,e			;410d
	ld a,e			;410e
	call rellena		;410f
	dec d			;4112
	jr nz,init_borra_nombres		;4113
	call 00096h		;4115   ; BIOS RDPSG - Reads value from PSG-register | lee el PSG para dejarlo en un estado conocido
	ld a,001h		;4118
	ld (0e01eh),a		;411a
	ld hl,045c9h		;411d   ; los ocho registros del VDP, de la tabla de 0x45C9
	ld d,008h		;4120
	ld c,000h		;4122
init_registros_vdp:		; Los ocho registros, de la tabla de 0x45C9
	ld b,(hl)			;4124   ; WRTVDP quiere el valor en B y el numero de registro en C
	call 00047h		;4125   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;4128
	inc c			;4129
	dec d			;412a
	jr nz,init_registros_vdp		;412b
	xor a			;412d   ; 0xE01E libre otra vez: ya se puede usar el VDP
	ld (0e01eh),a		;412e
	ei			;4131
	inc a			;4132
	call manda_orden		;4133   ; manda la orden 1 a la interrupcion y espera a que la haga
	di			;4136
	ld hl,04686h		;4137   ; el guion de la portada: patrones y colores del rotulo
	call ejecuta_guion		;413a
	ld de,00000h		;413d   ; y aqui el truco: copia 4095 bytes de VRAM a VRAM, solapados
	ld hl,04800h		;4140   ; los colores del primer tercio se replican en los otros dos
	call replica_vram		;4143
	ld de,02000h		;4146   ; y lo mismo con los patrones, que estan en 0x2000
	ld hl,06800h		;4149
	call replica_vram		;414c
	ld a,00dh		;414f   ; orden 13 a la interrupcion: la musica del titulo
	ld (0e001h),a		;4151
	ei			;4154
	ld a,(0e006h)		;4155   ; 0xE006 dice si venimos de una partida o del arranque
	or a			;4158
	jr nz,menu_de_jugadores		;4159
	ld hl,07a8bh		;415b
	ld (0e260h),hl		;415e
espera_del_titulo:		; Deja el rotulo puesto y va borrando la pantalla por filas
	ld hl,0e000h		;4161   ; 0xE000 es el contador de cuadros
	ld a,(hl)			;4164
	and 003h		;4165   ; solo actua uno de cada cuatro cuadros
	jr nz,titulo_mira_el_mando		;4167
	inc (hl)			;4169   ; y adelanta el contador dos, para no repetir
	inc (hl)			;416a
	ld de,(0e260h)		;416b   ; 0xE260 es la fila de la tabla de nombres que toca borrar
	ld hl,0786bh		;416f   ; cuando llega a 0x386B ya no queda pantalla que borrar
	xor a			;4172
	sbc hl,de		;4173
	jr z,titulo_mira_el_reloj		;4175
	di			;4177
	xor a			;4178
	ld b,003h		;4179   ; apaga los canales 3, 11 y 12 del PSG
	call escribe_tira		;417b
	ld b,00bh		;417e
	call escribe_tira		;4180
	ld b,00ch		;4183
	call escribe_tira		;4185
	ld b,00ch		;4188
	call pon_escritura		;418a
	xor a			;418d
	call rellena_desde		;418e   ; borra la fila entera
	ei			;4191
	ld hl,0e260h		;4192   ; y sube una fila: 0x20 bytes menos
	ld a,(hl)			;4195
	sub 020h		;4196
	ld (hl),a			;4198
	jr nc,titulo_mira_el_reloj		;4199   ; si se pasa por abajo, se acabo
	inc hl			;419b
	dec (hl)			;419c
titulo_mira_el_reloj:		; Si el reloj se agota, entra la demostracion
	ld a,(0e001h)		;419d
	or a			;41a0
	jr z,menu_de_jugadores		;41a1
titulo_mira_el_mando:		; Y si se toca algo, se pasa al menu
	ld a,(0e005h)		;41a3
	and 03fh		;41a6
	jr z,espera_del_titulo		;41a8
menu_de_jugadores:		; El PLAY SELECT: uno, dos o dobles
	ld hl,045d1h		;41aa   ; pinta las cuatro listas de tiles del titulo
	call pinta_cuatro_listas		;41ad
	ld de,0e008h		;41b0   ; 0xE008 lleva el cursor de este menu
	di			;41b3
	call pinta_el_cursor		;41b4
	ei			;41b7
	ld a,008h		;41b8   ; ocho unidades de reloj para decidir
	ld (0e001h),a		;41ba
menu_jugadores_bucle:		; Espera mientras el reloj y el mando lo permitan
	ld hl,0e00bh		;41bd   ; mientras haya reloj, atiende al mando
	ld de,0e008h		;41c0
	call mueve_el_cursor		;41c3
	ld hl,0e002h		;41c6   ; 0xE002 se queda a 1 si el jugador ha elegido de verdad
	ld (hl),000h		;41c9
	jr c,menu_jugadores_opcion		;41cb
	ld (hl),001h		;41cd
	ld a,(0e001h)		;41cf   ; si el reloj se agota sin tocar nada, entra la demostracion
	or a			;41d2
	jp z,menu_de_partido		;41d3
	jr menu_jugadores_bucle		;41d6
menu_jugadores_opcion:		; Coge la opcion en la que quedo el cursor
	ld hl,0e00ah		;41d8   ; 0xE00A guarda cuantos jugadores hay
	bit 0,(hl)		;41db
	jr nz,menu_jugadores_guarda		;41dd
menu_jugadores_guarda:		; La deja en 0xE00E y resalta su rotulo
	ld a,(hl)			;41df
	ld (0e00eh),a		;41e0
	ld hl,0461fh		;41e3   ; y segun eso resalta 1PLAYER, 2PLAYERS o DOUBLES
	dec a			;41e6
	jr z,menu_jugadores_confirma		;41e7
	ld hl,0462ah		;41e9
	dec a			;41ec
	jr z,menu_jugadores_confirma		;41ed
	ld hl,04636h		;41ef
menu_jugadores_confirma:		; Parpadea hasta que el jugador acepta
	call espera_confirmacion		;41f2   ; deja la eleccion parpadeando hasta que se confirme
	ei			;41f5
menu_de_partido:		; El GAME SELECT: a cuantos juegos se juega
	ld a,(0e002h)		;41f6   ; si nadie eligio jugadores, este menu se salta
	or a			;41f9
	jr nz,monta_la_pista		;41fa
	ld hl,04641h		;41fc   ; pinta el rotulo GAME SELECT
	call pinta_cuatro_listas		;41ff
	ld hl,045d1h		;4202   ; y debajo, otra vez las tres opciones
	call pinta_lista_de_tiles		;4205
	ld de,0e010h		;4208   ; 0xE010 lleva el cursor de este otro menu
	call pinta_el_cursor		;420b
	ei			;420e
menu_partido_bucle:		; Lo mismo para el numero de juegos
	ld hl,0e013h		;420f
	ld de,0e010h		;4212
	call mueve_el_cursor		;4215
	jr nc,menu_partido_bucle		;4218
	ld hl,0e012h		;421a   ; 0xE012 es el numero de juegos elegido
	ld a,(hl)			;421d
	ld (0e0dah),a		;421e   ; y se copia a 0xE0DA, que es de donde lo lee la interrupcion
	ld a,(hl)			;4221
	ld hl,04650h		;4222   ; resalta la opcion elegida
	dec a			;4225
	jr z,menu_partido_confirma		;4226
	ld hl,04662h		;4228
	dec a			;422b
	jr z,menu_partido_confirma		;422c
	ld hl,04674h		;422e
menu_partido_confirma:		; Parpadea el GAME SELECT elegido
	call espera_confirmacion		;4231
monta_la_pista:		; Deja la pantalla del partido lista y arranca el juego
	call borra_la_pantalla		;4234   ; borra la tabla de nombres
	di			;4237
	ld a,094h		;4238   ; la musica de empezar
	call suena		;423a
	ei			;423d
	ld hl,049b5h		;423e   ; el primer byte de 0x49B5 dice cuantos guiones seguidos hay
	ld b,(hl)			;4241
	inc hl			;4242
pista_bucle_guiones:		; Ejecuta los guiones de la pista, uno a uno
	push bc			;4243
	di			;4244
	call ejecuta_guion		;4245   ; y cada uno se ejecuta con las interrupciones cortadas
	ei			;4248
	pop bc			;4249
	djnz pista_bucle_guiones		;424a
	ld de,00000h		;424c   ; otra vez la replica solapada, ahora para la pista
	ld hl,04800h		;424f
	call replica_vram		;4252
	ei			;4255
	ld de,02000h		;4256
	ld hl,06800h		;4259
	call replica_vram		;425c
	ei			;425f
	call esconde_sprites		;4260
	ld hl,04ff1h		;4263   ; y encima, la tabla de nombres de la pista
	call pinta_lista_de_tiles		;4266
	call pinta_los_dos_bandos		;4269   ; coloca a los jugadores donde toca
	ld hl,0d84fh		;426c   ; 0xE03A arranca en 0xD84F
	ld (0e03ah),hl		;426f
	ld hl,07890h		;4272   ; los atributos de los sprites de la derecha
	ld de,07b2ch		;4275   ; a la VRAM 0x3B2C, o sea a partir del sprite 11
	ld b,016h		;4278   ; OJO: pide 22 bytes y en 0x7890 solo hay 16 de datos
	call escribe_bloque_en		;427a
	call coloca_al_recogepelotas		;427d   ; carga los patrones de esas figuras
	call reparte_las_fichas		;4280
pista_espera_sonido:		; No arranca hasta que la musica calla
	ei			;4283
	ld a,(0e213h)		;4284   ; espera a que 0xE213 diga que ya esta todo puesto
	or a			;4287
	jr nz,pista_espera_sonido		;4288
	inc a			;428a
	ld (0e003h),a		;428b   ; 0xE003 a uno: ya hay partida
	jp arranca_el_punto		;428e
lee_joystick:		; Devuelve los ocho sentidos y el disparo del mando que se pida
	ld e,08fh		;4291   ; el mando 1 se selecciona con 0x8F y el 2 con 0xCF
	jr nc,lee_joystick_puerto		;4293
	ld e,0cfh		;4295
lee_joystick_puerto:		; Entra con el puerto ya elegido en E
	ld a,00fh		;4297   ; el registro 15 del PSG elige que mando se lee
	call 00093h		;4299   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;429c   ; y el 14 devuelve lo que tiene
	call 00096h		;429e   ; BIOS RDPSG - Reads value from PSG-register
	cpl			;42a1   ; el PSG da los bits al reves, asi que se invierten
	ret			;42a2
lee_teclado_como_mando:		; Las flechas y el espacio, en el formato del joystick
	ld de,00205h		;42a3   ; las filas 2, 5, 3 y 6 de la matriz son donde caen las teclas
	ld hl,00306h		;42a6
	ld a,e			;42a9
	call 00141h		;42aa   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | SNSMAT devuelve una fila entera de ocho teclas
	cpl			;42ad   ; la matriz tambien da los bits al reves
	and 090h		;42ae
	ld e,a			;42b0
	ld a,d			;42b1
	call 00141h		;42b2   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42b5
	and 040h		;42b6
	or e			;42b8
	ld e,a			;42b9
	ld a,h			;42ba
	call 00141h		;42bb   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42be
	bit 1,a		;42bf
	jr z,teclado_recoloca		;42c1
	set 5,e		;42c3
teclado_recoloca:		; Rota los bits para que salgan como los del mando
	ld a,e			;42c5
	rlca			;42c6   ; recoloca los bits para que salgan como los del mando
	rlca			;42c7
	rlca			;42c8
	rlca			;42c9
	ld e,a			;42ca
	and 005h		;42cb   ; y arregla los dos que no encajan del todo
	bit 1,e		;42cd
	jr z,teclado_bit_3		;42cf
	set 3,a		;42d1
teclado_bit_3:		; Copia el bit 3 al 1
	bit 3,e		;42d3
	jr z,teclado_ultima_fila		;42d5
	set 1,a		;42d7
teclado_ultima_fila:		; La cuarta fila, la del disparo
	ld e,a			;42d9
	ld a,l			;42da
	call 00141h		;42db   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42de
	bit 0,a		;42df
	jr z,teclado_devuelve		;42e1
	set 4,e		;42e3
teclado_devuelve:		; La mascara ya montada
	ld a,e			;42e5
	ret			;42e6
lee_una_fila:		; Lee la fila E, la traduce, y le suma el disparo de la fila D
	ld a,e			;42e7
	call 00141h		;42e8   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42eb
	call traduce_direccion		;42ec   ; traduce los cuatro bits de direccion
	ld e,a			;42ef
	ld a,d			;42f0
	call 00141h		;42f1   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42f4
	and 040h		;42f5   ; el disparo viene de otra fila distinta
	rrca			;42f7
	or e			;42f8
	ret			;42f9
traduce_direccion:		; Los cuatro bits de las flechas, a un sentido de ocho
	ld c,000h		;42fa   ; C acumula el bit del disparo
	rrca			;42fc   ; el primer bit que sale es el de disparo
	jr nc,traduce_direccion_nibble		;42fd
	set 4,c		;42ff
traduce_direccion_nibble:		; Baja los cuatro bits de las flechas
	rrca			;4301   ; y los cuatro siguientes son las flechas
	rrca			;4302
	rrca			;4303
	and 00fh		;4304
	ld hl,0430fh		;4306   ; la tabla de 0x430F tiene una entrada por combinacion
	call suma_a_hl		;4309
	ld a,(hl)			;430c
	or c			;430d   ; y se le devuelve el disparo pegado
	ret			;430e

; ----------------------------------------------------------------------
; DATOS tabla_de_bits: Un valor por cada combinacion de cuatro bits, para
;   0x4306
;   0x430f..0x431f  (16 bytes)
DATA_tabla_de_bits:
	defb 000h,004h,001h,005h,002h,006h,00fh,00fh,008h,00fh,009h,00fh,00ah,00fh,00fh,00fh	; 430f  ................

; ======================================================================
; CODIGO 0x431f..0x43d0  (177 bytes)
; ======================================================================


lee_los_mandos:		; Deja en 0xE105 y 0xE135 lo que hacen los dos jugadores
	ld b,002h		;431f   ; dos vueltas, una por jugador
	ld hl,0e105h		;4321   ; 0xE105 es el mando del primero
lee_los_mandos_bucle:		; Una vuelta por jugador
	call lee_joystick		;4324
	and 03fh		;4327   ; se queda con los seis bits que importan
	ld (hl),a			;4329
	ld hl,0e135h		;432a   ; 0xE135 es el del segundo
	scf			;432d
	djnz lee_los_mandos_bucle		;432e
	ld de,00008h		;4330   ; y el teclado tambien vale como mando del primero
	call lee_una_fila		;4333
	ld d,a			;4336
	ld a,(0e105h)		;4337   ; se mezcla con lo que dijo el joystick
	or d			;433a
	ld (0e105h),a		;433b
	call lee_teclado_como_mando		;433e   ; el segundo jugador usa las otras teclas
	ld d,a			;4341
	ld a,(0e135h)		;4342
	or d			;4345
	ld (0e135h),a		;4346
	ld b,002h		;4349   ; y ahora, guardar tambien lo que habia antes
	ld hl,0e105h		;434b
lee_los_mandos_flanco:		; Compara con lo del cuadro anterior
	ld a,(hl)			;434e   ; para saber si una direccion es nueva o venia de antes
	inc hl			;434f
	cp (hl)			;4350
	ld c,a			;4351
	jr nz,lee_los_mandos_guarda		;4352
	inc hl			;4354
	ld (hl),a			;4355
	dec hl			;4356
lee_los_mandos_guarda:		; Deja lo de ahora y lo de antes
	ld (hl),c			;4357
	ld hl,0e135h		;4358
	djnz lee_los_mandos_flanco		;435b
	ret			;435d
lee_para_el_menu:		; Lo mismo, pero para moverse por las opciones
	or a			;435e
	call lee_joystick		;435f   ; el mando manda
	and 03fh		;4362
	ld (0e005h),a		;4364   ; 0xE005 es lo que ve el menu
	or a			;4367   ; si el mando no dice nada, se prueba el teclado
	ret nz			;4368
	ld de,00708h		;4369   ; las filas 7 y 8, que son las de las flechas
	call lee_una_fila		;436c
	ld (0e005h),a		;436f
	ret			;4372
mueve_el_cursor:		; Sube o baja la opcion elegida, y la resalta
	ld a,(0e005h)		;4373   ; si no se toca nada, no hay nada que hacer
	or a			;4376
	jr nz,cursor_ya_movido		;4377
	ld (hl),a			;4379
	ret			;437a
cursor_ya_movido:		; El bit 0 dice que ya se movio con esta pulsacion
	bit 0,(hl)		;437b   ; el bit 0 marca que ya se movio con esta pulsacion
	ret nz			;437d
	ld a,(0e005h)		;437e
	and 030h		;4381   ; los bits 4 y 5 son disparo: eso es elegir, no mover
	or a			;4383
	scf			;4384
	ret nz			;4385
	ld a,(0e005h)		;4386
	and 003h		;4389   ; los bits 0 y 1 son arriba y abajo
	set 0,(hl)		;438b   ; deja la marca de que ya se ha movido
	dec a			;438d
	jr nz,cursor_baja		;438e
	dec hl			;4390   ; la opcion baja de una en una
	ld a,(hl)			;4391
	dec a			;4392
	or a			;4393
	ld b,040h		;4394   ; y el cursor sube 0x40 en la tabla de nombres
	jr nz,cursor_sube		;4396
	ld b,080h		;4398   ; si se sale por arriba, vuelve a la tercera
	ld a,003h		;439a
cursor_sube:		; Una opcion menos, y el cursor 0x40 mas arriba
	ld (hl),a			;439c   ; la opcion nueva
	dec hl			;439d
	dec hl			;439e
	ld a,(hl)			;439f   ; dos bytes atras esta la fila del cursor
	sub b			;43a0
	ld (hl),a			;43a1
	jr pinta_el_cursor		;43a2
cursor_baja:		; Una opcion mas
	dec hl			;43a4   ; y por el otro lado, igual
	ld a,(hl)			;43a5
	inc a			;43a6
	cp 004h		;43a7   ; hay tres opciones, de 1 a 3
	ld b,040h		;43a9
	jr nz,cursor_guarda		;43ab
	ld b,080h		;43ad
	ld a,001h		;43af
cursor_guarda:		; Deja la opcion y baja el cursor
	ld (hl),a			;43b1   ; la opcion nueva, ya dada la vuelta
	dec hl			;43b2
	dec hl			;43b3
	ld a,(hl)			;43b4   ; y el cursor baja lo que toque
	add a,b			;43b5
	ld (hl),a			;43b6
pinta_el_cursor:		; Deja la flecha en la fila que toca
	di			;43b7
	ex de,hl			;43b8
	ld e,(hl)			;43b9   ; DE sale de la variable que se le pasa
	inc hl			;43ba
	ld d,(hl)			;43bb
	ld hl,043d0h		;43bc   ; la flecha son parejas de tiles, hasta el 0xFF
pinta_el_cursor_bucle:		; Parejas de tiles hasta el 0xFF
	ld a,(hl)			;43bf
	cp 0ffh		;43c0
	ret z			;43c2
	ld b,002h		;43c3
	di			;43c5
	call escribe_bloque_simple		;43c6   ; dos tiles por fila
	ei			;43c9
	ld a,040h		;43ca   ; y la siguiente fila, 0x40 mas abajo
	add a,e			;43cc
	ld e,a			;43cd
	jr pinta_el_cursor_bucle		;43ce

; ----------------------------------------------------------------------
; DATOS cursor_del_menu: Los tiles de la flecha, de dos en dos, hasta el 0xFF
;   0x43d0..0x43db  (11 bytes)
DATA_cursor_del_menu:
	defb 000h,000h,000h,000h,0b6h,0b7h,000h,000h,000h,000h,0ffh	; 43d0  ...........

; ======================================================================
; CODIGO 0x43db..0x45c9  (494 bytes)
; ======================================================================


pinta_cuatro_listas:		; Borra la pantalla y pinta cuatro listas seguidas
	push hl			;43db
	call borra_la_pantalla		;43dc   ; primero deja la tabla de nombres a cero
	pop hl			;43df
	ld b,004h		;43e0   ; las listas del titulo son cuatro, una detras de otra
cuatro_listas_bucle:		; Las cuatro listas, una detras de otra
	push bc			;43e2
	call pinta_lista_de_tiles		;43e3
	pop bc			;43e6
	djnz cuatro_listas_bucle		;43e7
	ret			;43e9
pinta_lista_de_tiles:		; Vuelca una lista de tiles en la tabla de nombres
	exx			;43ea
	ld a,(00007h)		;43eb   ; el puerto de datos del VDP, guardado en el juego alterno
	ld c,a			;43ee
	exx			;43ef
	di			;43f0
	call pon_destino		;43f1   ; cada entrada empieza por su direccion de VRAM
lista_siguiente_byte:		; El byte que toca de la entrada
	inc hl			;43f4
sigue_la_lista:		; Entra en el bucle de la lista de tiles sin volver a colocar el puntero
	ld a,(hl)			;43f5   ; un 0xFE es la orden de repetir
	cp 0feh		;43f6
	jr nz,lista_fin_entrada		;43f8
lista_repite:		; El 0xFE: n veces el mismo byte
	inc hl			;43fa
	ld b,(hl)			;43fb   ; cuantas veces
	inc hl			;43fc
	ld a,(hl)			;43fd   ; y que byte
	call rellena		;43fe
	inc hl			;4401
	ld a,(hl)			;4402
	cp 0feh		;4403
	jr z,lista_repite		;4405
lista_fin_entrada:		; El 0xFF cierra la entrada
	cp 0ffh		;4407   ; un 0xFF cierra la entrada
	jr z,lista_fin_lista		;4409
	exx			;440b
	out (c),a		;440c   ; y si no era ninguno de los dos, el byte va tal cual
	exx			;440e
	jr lista_siguiente_byte		;440f
lista_fin_lista:		; Y otro 0xFF seguido cierra la lista
	inc hl			;4411   ; dos 0xFF seguidos cierran la lista entera
	ld a,(hl)			;4412
	cp 0ffh		;4413
	jr nz,pinta_lista_de_tiles		;4415
	inc hl			;4417
	ei			;4418
	ret			;4419
borra_la_pantalla:		; Deja los 768 tiles de la tabla de nombres a cero
	di			;441a
	ld de,07800h		;441b   ; la tabla de nombres empieza en 0x3800
	call pon_escritura		;441e
	ld h,003h		;4421   ; tres vueltas
	xor a			;4423
borra_pantalla_bucle:		; Tres vueltas de 256
	ld b,a			;4424   ; con B a cero, el djnz da 256: 3 x 256 = 768
	call rellena		;4425
	dec h			;4428
	jr nz,borra_pantalla_bucle		;4429
	ei			;442b
	ret			;442c
replica_vram:		; Copia de VRAM a VRAM byte a byte, y de paso replica los tercios
	ld bc,00fffh		;442d   ; 4095 bytes, uno menos que un bloque entero
	exx			;4430
	ld a,(00007h)		;4431   ; se guardan los dos puertos del VDP en el juego alterno
	ld d,a			;4434   ; el de escritura
	ld a,(00006h)		;4435
	ld e,a			;4438   ; y el de lectura
	exx			;4439
replica_vram_bucle:		; Un byte: leer de un sitio y escribir en el otro
	call pon_lectura		;443a   ; coloca el puntero de lectura
	inc de			;443d
	exx			;443e
	ld c,e			;443f
	in a,(c)		;4440   ; y saca el byte
	exx			;4442
	ex de,hl			;4443   ; ahora le toca al otro puntero
	push af			;4444
	call pon_escritura		;4445   ; coloca el de escritura
	inc de			;4448
	pop af			;4449
	exx			;444a
	ld c,d			;444b
	out (c),a		;444c   ; y lo suelta
	exx			;444e
	ex de,hl			;444f   ; vuelve a cambiar, que el bucle sigue
	dec bc			;4450
	ld a,b			;4451
	or c			;4452
	jr nz,replica_vram_bucle		;4453   ; el destino va 0x800 por delante del origen, asi que a mitad
	ret			;4455   ; de camino esta leyendo lo que el mismo acaba de escribir
manda_orden:		; Deja una orden en 0xE001 y no vuelve hasta que la interrupcion la hace
	ld hl,0e001h		;4456
	ld (hl),a			;4459   ; 0xE001 es el buzon
manda_orden_espera:		; Da vueltas hasta que la interrupcion vacia el buzon
	ld a,(hl)			;445a   ; y aqui se espera a que lo vacien
	or a			;445b
	jr nz,manda_orden_espera		;445c
	ret			;445e
ejecuta_guion:		; El interprete de guiones: monta una pantalla entera
	ld b,(hl)			;445f   ; el primer byte dice cuantos bloques hay
	inc hl			;4460
guion_bloque:		; Un bloque del guion, con su comando
	push bc			;4461
	ld a,(hl)			;4462   ; y cada bloque empieza por su comando
	inc hl			;4463
	or a			;4464
	jr z,guion_bytes_crudos		;4465   ; el 0 son bytes crudos
	dec a			;4467
	jr z,guion_patrones		;4468   ; el 1, patrones por indice
	dec a			;446a
	dec a			;446b
	jr z,guion_relleno		;446c   ; el 3, pares de relleno
	jp guion_patron_repetido		;446e   ; y cualquier otro, un patron repetido
guion_siguiente_bloque:		; Descuenta y sigue
	pop bc			;4471
	djnz guion_bloque		;4472   ; hasta agotar los bloques
	ret			;4474
guion_bytes_crudos:		; Comando 0: bytes al VDP, con repeticion
	ld b,(hl)			;4475   ; cuantos sub-bloques
	inc hl			;4476
guion_sub_bloque:		; Un sub-bloque: direccion, longitud y datos
	push bc			;4477
	call pon_destino		;4478   ; cada uno con su direccion de VRAM
	inc hl			;447b
	ld c,(hl)			;447c   ; y su longitud; un 0 aqui significa 256
	inc hl			;447d
guion_byte:		; El byte que toca, o la orden de repetir
	ld a,(hl)			;447e
	cp 011h		;447f   ; un 0x11 es la orden de repetir
	jr z,guion_repite_byte		;4481
	ex af,af'			;4483
	exx			;4484
	ld a,(00007h)		;4485   ; el puerto de escritura, del juego alterno
	ld c,a			;4488
	ex af,af'			;4489
	out (c),a		;448a
	exx			;448c
	inc hl			;448d
	dec c			;448e   ; descuenta del total del sub-bloque
	jr nz,guion_byte		;448f
guion_fin_sub_bloque:		; Descuenta el sub-bloque y sigue
	pop bc			;4491
	djnz guion_sub_bloque		;4492   ; y al siguiente
	jr guion_siguiente_bloque		;4494
guion_repite_byte:		; El 0x11 del comando 0: N veces el mismo byte
	inc hl			;4496
	ld b,(hl)			;4497   ; cuantas veces
	inc hl			;4498
	ld a,(hl)			;4499   ; y que byte
	inc hl			;449a
guion_repite_bucle:		; Suelta el mismo byte, sin pasarse del total
	ex af,af'			;449b
	exx			;449c
	ld a,(00007h)		;449d
	ld c,a			;44a0
	ex af,af'			;44a1
	out (c),a		;44a2
	exx			;44a4
	dec c			;44a5   ; el total del sub-bloque manda sobre la cuenta de repeticiones
	jr z,guion_fin_sub_bloque		;44a6
	djnz guion_repite_bucle		;44a8   ; y si no, se repite lo que diga
	jr guion_byte		;44aa
guion_patrones:		; Comando 1: patrones pedidos por su numero
	ld b,(hl)			;44ac   ; cuantos grupos
guion_patrones_grupo:		; Un grupo: su direccion y sus indices
	push bc			;44ad
	inc hl			;44ae
	call pon_destino		;44af   ; la direccion de VRAM del grupo
	inc hl			;44b2
guion_patrones_indice:		; El numero de patron que toca
	ld b,(hl)			;44b3   ; y aqui el numero de patron
	push hl			;44b4
	ld hl,0489dh		;44b5   ; la tabla vive en 0x489D
	ld a,b			;44b8
	or a			;44b9
	jr z,guion_patrones_suelta		;44ba
guion_patrones_desplaza:		; Ocho bytes por patron, tantas veces como el indice
	ld a,008h		;44bc   ; ocho bytes por patron, asi que se avanza de ocho en ocho
	add a,l			;44be
	ld l,a			;44bf
	jr nc,guion_patrones_sigue		;44c0
	inc h			;44c2
guion_patrones_sigue:		; Otra vuelta de ocho
	djnz guion_patrones_desplaza		;44c3
guion_patrones_suelta:		; Los ocho bytes del patron
	ld b,008h		;44c5   ; y se sueltan los ocho
	call escribe_bloque		;44c7
	pop hl			;44ca
	inc hl			;44cb   ; hasta que aparezca un 0xFF
	ld a,0ffh		;44cc
	cp (hl)			;44ce
	jr nz,guion_patrones_indice		;44cf
	pop bc			;44d1
	djnz guion_patrones_grupo		;44d2
	inc hl			;44d4   ; el 0xFF del ultimo grupo tambien hay que saltarlo
guion_patrones_fin:		; Salta el 0xFF final y vuelve
	jr guion_siguiente_bloque		;44d5
guion_relleno:		; Comando 3: una direccion y pares de cuenta y valor
	ld b,(hl)			;44d7   ; cuantos pares
	inc hl			;44d8
	call pon_destino		;44d9   ; y una sola direccion para todos
guion_relleno_par:		; Un par de cuenta y valor
	push bc			;44dc
	inc hl			;44dd
	ld b,(hl)			;44de   ; la cuenta
	inc hl			;44df
	ld a,(hl)			;44e0   ; y el valor
	call rellena		;44e1
	pop bc			;44e4
	djnz guion_relleno_par		;44e5
	inc hl			;44e7
	jr guion_patrones_fin		;44e8
guion_patron_repetido:		; Cualquier otro comando: un patron, muchas veces
	call pon_destino		;44ea
	inc hl			;44ed
	ld b,(hl)			;44ee   ; cuantas veces
	inc hl			;44ef
	ld e,(hl)			;44f0   ; y de donde sale el patron
	inc hl			;44f1
	ld d,(hl)			;44f2
	push hl			;44f3
	push de			;44f4
	pop hl			;44f5
guion_repetido_vuelta:		; El mismo patron, una vez mas
	push bc			;44f6
	push hl			;44f7
	ld b,008h		;44f8   ; ocho bytes cada vez
	call escribe_bloque		;44fa
	pop hl			;44fd   ; sin avanzar: es siempre el mismo
	pop bc			;44fe
	djnz guion_repetido_vuelta		;44ff
	pop hl			;4501
	inc hl			;4502
	jr guion_patrones_fin		;4503
pon_destino:		; Lee una direccion de VRAM de dos bytes y deja el VDP escribiendo ahi
	ld d,(hl)			;4505
	inc hl			;4506
	ld e,(hl)			;4507
	jp pon_escritura		;4508
escribe_tira:		; Suelta B tiles consecutivos y baja una fila
	push af			;450b
	call pon_escritura		;450c   ; coloca el puntero
	pop af			;450f
escribe_tira_bucle:		; Tiles consecutivos, uno mas cada vez
	ex af,af'			;4510
	exx			;4511
	ld a,(00007h)		;4512
	ld c,a			;4515
	ex af,af'			;4516
	out (c),a		;4517   ; cada tile, uno mas que el anterior
	exx			;4519
	inc a			;451a
	djnz escribe_tira_bucle		;451b
	ex de,hl			;451d
	ld de,00020h		;451e   ; y al acabar, 32 bytes mas abajo: la fila siguiente
	add hl,de			;4521
	ex de,hl			;4522
	ret			;4523
borra_ram:		; Deja BC bytes a cero desde HL
	push hl			;4524
	pop de			;4525
	inc de			;4526
	ld (hl),000h		;4527   ; el primero a mano, y el ldir arrastra
	ldir		;4529
	ret			;452b
esconde_sprites:		; Manda los 32 sprites fuera de la pantalla
	ld de,07b00h		;452c   ; los atributos empiezan en 0x3B00
	ld bc,080cfh		;452f   ; 128 bytes con 0xCF, que es una fila que no se ve
	jp rellena_en		;4532
espera_confirmacion:		; Deja el rotulo parpadeando hasta que el jugador confirme
	xor a			;4535
	ld (0e000h),a		;4536   ; 0xE000 lleva la cuenta de cuadros
confirmacion_bucle:		; Espera mirando el contador y el mando
	ei			;4539
	ld a,(0e000h)		;453a
	bit 3,a		;453d   ; el bit 3 del contador es el que hace el parpadeo
	di			;453f
	jr z,confirmacion_atiende		;4540
	push hl			;4542
	ld d,(hl)			;4543
	inc hl			;4544
	ld e,(hl)			;4545
	inc hl			;4546
	ld b,01ah		;4547   ; 26 tiles de ancho
	ld c,000h		;4549
	call rellena_desde		;454b
	pop hl			;454e
	jr confirmacion_bucle		;454f
confirmacion_atiende:		; Sigue leyendo mandos mientras parpadea
	push hl			;4551
	call pinta_lista_de_tiles		;4552   ; mientras tanto, sigue leyendo los mandos
	ld hl,0e000h		;4555
	bit 6,(hl)		;4558   ; el bit 6 de 0xE000 dice que ya se ha confirmado
	pop hl			;455a
	jr z,confirmacion_bucle		;455b
	ret			;455d
suma_a_hl:		; HL += A, que es como se indexa todo en este cartucho
	add a,l			;455e
	ld l,a			;455f
	ret nc			;4560
	inc h			;4561
	ret			;4562
pon_escritura_con_reintento:		; SETWRT, y si la interrupcion se cuela, otra vez
	xor a			;4563
	ld (0e01dh),a		;4564   ; 0xE01D lo pone la interrupcion cuando toca el VDP
	inc a			;4567
	ld (0e01eh),a		;4568   ; 0xE01E avisa de que estamos a medias
	ex de,hl			;456b
	call 00053h		;456c   ; BIOS SETWRT - Enables VDP to write | SETWRT de la BIOS quiere la direccion en HL
	di			;456f
	ex de,hl			;4570
	ld a,(0e01dh)		;4571   ; si la interrupcion movio el puntero, se repite
	or a			;4574
	jr nz,pon_escritura_con_reintento		;4575
	ld (0e01eh),a		;4577
	ret			;457a
pon_lectura:		; SETRD, con el mismo reintento
	xor a			;457b
	ld (0e01dh),a		;457c
	ex de,hl			;457f
	call 00050h		;4580   ; BIOS SETRD - Enables VDP to read | SETRD de la BIOS
	di			;4583
	ex de,hl			;4584
	ld a,(0e01dh)		;4585
	or a			;4588
	jr nz,pon_lectura		;4589
	ret			;458b
pon_escritura:		; SETWRT, con el mismo reintento
	xor a			;458c
	ld (0e01dh),a		;458d
	ex de,hl			;4590
	call 00053h		;4591   ; BIOS SETWRT - Enables VDP to write | SETWRT de la BIOS
	di			;4594
	ex de,hl			;4595
	ld a,(0e01dh)		;4596
	or a			;4599
	jr nz,pon_escritura		;459a
	ret			;459c
escribe_bloque_en:		; Coloca el puntero y suelta B bytes desde HL
	call pon_escritura_con_reintento		;459d
escribe_bloque:		; Suelta B bytes desde HL, donde este el puntero
	push bc			;45a0
	ld a,(00007h)		;45a1   ; el puerto de datos del VDP
	ld c,a			;45a4
	ld a,(hl)			;45a5
	out (c),a		;45a6   ; y adentro
	inc hl			;45a8
	pop bc			;45a9
	djnz escribe_bloque		;45aa
	ret			;45ac
escribe_bloque_simple:		; Como el anterior, con la version corta de SETWRT
	call pon_escritura		;45ad
	jr escribe_bloque		;45b0
rellena_en:		; Coloca el puntero y repite el byte C, B veces
	call pon_escritura_con_reintento		;45b2
	ld a,c			;45b5
rellena:		; Repite el byte A, B veces, donde este el puntero
	push bc			;45b6
	push af			;45b7
	ld a,(00007h)		;45b8   ; el puerto de datos del VDP, que hay que leer de la BIOS
	ld c,a			;45bb
	pop af			;45bc
	out (c),a		;45bd   ; y el mismo byte, tantas veces como diga B
	pop bc			;45bf
	djnz rellena		;45c0
	ret			;45c2
rellena_desde:		; Coloca el puntero y repite el byte C, B veces
	call pon_escritura		;45c3
	ld a,c			;45c6
	jr rellena		;45c7

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho que carga 0x411D: SCREEN 2, patrones en
;   0x2000 y colores en 0x0000
;   0x45c9..0x45d1  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 45c9  .....v..

; ----------------------------------------------------------------------
; DATOS pantalla_titulo: Konami's Tennis y (c)KONAMI 1984
;   0x45d1..0x4611  (64 bytes)
DATA_pantalla_titulo:
	defb 078h,085h,040h,041h,042h,043h,044h,045h,046h,047h,048h,063h,049h,04ah,000h,04bh	; 45d1  x.@ABCDEFGHcIJ.K
	defb 04ch,04dh,04eh,04fh,050h,064h,051h,0ffh,078h,0a5h,040h,052h,053h,054h,055h,056h	; 45e1  LMNOPdQ.x.@RSTUV
	defb 057h,058h,059h,05ah,05bh,05ch,000h,05dh,05eh,05fh,055h,060h,061h,062h,05ch,0ffh	; 45f1  WXYZ[\.]^_U`ab\.
	defb 078h,0eah,0eah,0dbh,0dfh,0deh,0d1h,0ddh,0d9h,000h,0f1h,0f9h,0f8h,0f4h,0ffh,0ffh	; 4601  x...............

; ----------------------------------------------------------------------
; DATOS rotulo_play_select: PLAY SELECT y la opcion 1PLAYER
;   0x4611..0x462a  (25 bytes)
DATA_rotulo_play_select:
	defb 079h,0aah,0e0h,0dch,0d1h,0e7h,000h,0e2h,0d5h,0dch,0d5h,0d3h,0e3h,0ffh,07ah,02bh	; 4611  y.............z+
	defb 0a1h,0adh,0aeh,0afh,0b0h,0b1h,0b2h,0ffh,0ffh	; 4621  .........

; ----------------------------------------------------------------------
; DATOS rotulo_2players: La opcion 2PLAYERS
;   0x462a..0x4636  (12 bytes)
DATA_rotulo_2players:
	defb 07ah,06bh,0a2h,0adh,0aeh,0afh,0b0h,0b1h,0b2h,0b3h,0ffh,0ffh	; 462a  zk..........

; ----------------------------------------------------------------------
; DATOS rotulo_doubles: La opcion DOUBLES
;   0x4636..0x4641  (11 bytes)
DATA_rotulo_doubles:
	defb 07ah,0abh,0a6h,0a8h,0ach,0a5h,0aeh,0b1h,0b3h,0ffh,0ffh	; 4636  z..........

; ----------------------------------------------------------------------
; DATOS rotulo_game_select: GAME SELECT, para el segundo menu
;   0x4641..0x4650  (15 bytes)
DATA_rotulo_game_select:
	defb 079h,0abh,0d7h,0d1h,0ddh,0d5h,000h,0e2h,0d5h,0dch,0d5h,0d3h,0e3h,0ffh,0ffh	; 4641  y..............

; ----------------------------------------------------------------------
; DATOS rotulo_game_select_1: GAME SELECT con el 1
;   0x4650..0x4662  (18 bytes)
DATA_rotulo_game_select_1:
	defb 07ah,02ah,0d7h,0d1h,0ddh,0d5h,000h,0e2h,0d5h,0dch,0d5h,0d3h,0e3h,000h,000h,0f1h	; 4650  z*..............
	defb 0ffh,0ffh	; 4660

; ----------------------------------------------------------------------
; DATOS rotulo_game_select_2: GAME SELECT con el 2
;   0x4662..0x4674  (18 bytes)
DATA_rotulo_game_select_2:
	defb 07ah,06ah,0d7h,0d1h,0ddh,0d5h,000h,0e2h,0d5h,0dch,0d5h,0d3h,0e3h,000h,000h,0f2h	; 4662  zj..............
	defb 0ffh,0ffh	; 4672

; ----------------------------------------------------------------------
; DATOS rotulo_game_select_3: GAME SELECT con el 3
;   0x4674..0x4686  (18 bytes)
DATA_rotulo_game_select_3:
	defb 07ah,0aah,0d7h,0d1h,0ddh,0d5h,000h,0e2h,0d5h,0dch,0d5h,0d3h,0e3h,000h,000h,0f3h	; 4674  z...............
	defb 0ffh,0ffh	; 4684

; ----------------------------------------------------------------------
; DATOS guion_de_la_portada: Lo ejecuta INIT en 0x4137: patrones y colores del
;   rotulo
;   0x4686..0x489d  (535 bytes)
DATA_guion_de_la_portada:
	defb 005h,000h,00fh,065h,0b0h,010h,000h,00fh,0bfh,0ffh,0ffh,0ffh,0bfh,00fh,000h,000h	; 4686  ...e............
	defb 0fch,0c0h,0c0h,080h,080h,000h,067h,050h,008h,03ch,042h,099h,0a1h,0a1h,099h,042h	; 4696  ......gP.<B....B
	defb 03ch,060h,00eh,002h,007h,00fh,060h,016h,01ah,0f8h,0f0h,011h,004h,03eh,011h,004h	; 46a6  <`....`......>..
	defb 03fh,01fh,03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,03eh	; 46b6  ?.?............>
	defb 03eh,060h,035h,003h,01fh,07fh,0fbh,060h,03dh,003h,00fh,0cfh,0efh,060h,045h,003h	; 46c6  >`5....`=....`E.
	defb 078h,0fch,0bch,060h,04dh,003h,03fh,07fh,0f3h,060h,055h,003h,087h,0c7h,0c7h,060h	; 46d6  x..`M.?..`U....`
	defb 05dh,003h,0bch,0feh,0dfh,060h,065h,06bh,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h	; 46e6  ]....`ekx..`..`.
	defb 0f0h,0f0h,0f0h,03fh,03fh,011h,006h,03eh,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h	; 46f6  ...??..>....?...
	defb 03eh,03eh,03eh,07eh,0fch,0fch,0f8h,0e0h,011h,005h,0f1h,0fbh,07fh,01fh,011h,006h	; 4706  >>>~............
	defb 0efh,0cfh,00fh,011h,008h,01eh,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,011h,008h	; 4716  ........?.......
	defb 0e7h,011h,008h,08fh,011h,008h,01eh,0f1h,0f2h,011h,004h,0f5h,0f2h,0f1h,0e0h,010h	; 4726  ................
	defb 0c8h,068h,0c8h,028h,010h,0e0h,062h,000h,000h,011h,008h,007h,087h,08fh,09fh,0beh	; 4736  .h.(..b.........
	defb 0fch,0f8h,0f0h,0f0h,0c0h,080h,000h,000h,000h,003h,007h,007h,011h,004h,000h,0f0h	; 4746  ................
	defb 0fch,0feh,09eh,011h,005h,000h,03bh,03fh,03fh,011h,005h,000h,081h,0e1h,0f0h,011h	; 4756  ......;??.......
	defb 005h,000h,0fch,0feh,01eh,011h,005h,000h,073h,07fh,07fh,011h,005h,000h,09ch,0ffh	; 4766  ........s.......
	defb 0ffh,038h,038h,038h,018h,010h,011h,003h,000h,011h,004h,000h,07ch,0feh,0feh,0e2h	; 4776  .888........|...
	defb 011h,003h,03fh,011h,005h,003h,0fch,0fch,0fch,0c0h,0c0h,0c0h,0c1h,0c1h,011h,005h	; 4786  ..?.............
	defb 000h,078h,0feh,0ceh,011h,005h,000h,03bh,03fh,03fh,011h,005h,000h,083h,0e3h,0e3h	; 4796  .x.....;??......
	defb 011h,005h,000h,0b8h,0feh,0ffh,011h,004h,000h,07ch,0feh,0feh,0e2h,0f8h,0fch,0beh	; 47a6  .........|......
	defb 09fh,08fh,087h,083h,081h,011h,004h,00fh,087h,0c7h,0e3h,0f0h,011h,004h,00fh,09eh	; 47b6  ................
	defb 0feh,0fch,0f0h,03ch,011h,007h,038h,0f0h,071h,011h,005h,073h,071h,00eh,0feh,0feh	; 47c6  ...<..8.q..sq...
	defb 08eh,08eh,0feh,0feh,0efh,07bh,011h,007h,071h,0f7h,011h,007h,0e3h,011h,008h,09ch	; 47d6  .....{..q.......
	defb 011h,004h,000h,001h,001h,000h,000h,0f8h,07eh,03fh,007h,087h,0ffh,0feh,07ch,011h	; 47e6  ........~?....|.
	defb 008h,003h,011h,005h,0c3h,0c1h,0c1h,0c0h,087h,0ffh,0ffh,080h,0c1h,0ffh,0ffh,07eh	; 47f6  ...............~
	defb 063h,000h,028h,0f3h,011h,007h,073h,0cfh,011h,007h,087h,011h,004h,038h,039h,039h	; 4806  c.(...s......899
	defb 038h,038h,01ch,02ah,02ah,01ch,000h,01ch,01ch,09ch,038h,054h,054h,038h,000h,038h	; 4816  88.**.....8TT8.8
	defb 038h,038h,042h,000h,000h,011h,000h,030h,043h,000h,028h,011h,018h,030h,011h,004h	; 4826  88B....0C.(..0..
	defb 0a0h,011h,004h,030h,011h,004h,0a0h,011h,004h,030h,001h,003h,065h,008h,001h,002h	; 4836  ...0.....0..e...
	defb 003h,004h,00ch,00eh,014h,019h,01dh,013h,00dh,01eh,01ah,016h,00bh,021h,00fh,01bh	; 4846  .............!..
	defb 01ch,0ffh,067h,080h,000h,001h,002h,003h,004h,005h,006h,007h,008h,009h,0ffh,066h	; 4856  ..g............f
	defb 088h,00bh,00ch,00dh,00eh,00fh,010h,011h,012h,013h,014h,015h,016h,017h,018h,019h	; 4866  ................
	defb 01ah,01bh,01ch,01dh,01eh,01fh,020h,021h,022h,023h,0ffh,003h,006h,045h,008h,0a8h	; 4876  ...... !"#...E..
	defb 070h,0a8h,0f0h,0c0h,0f0h,098h,0f0h,008h,090h,020h,0f0h,003h,001h,040h,008h,000h	; 4886  p........ ...@..
	defb 0f0h,003h,001h,041h,000h,0a8h,050h	; 4896

; ----------------------------------------------------------------------
; DATOS tabla_de_patrones: 35 patrones de ocho bytes, que el comando 1 pide
;   por indice
;   0x489d..0x49b5  (280 bytes)
DATA_tabla_de_patrones:
	defb 000h,01ch,022h,063h,063h,063h,022h,01ch	; 489d  .."ccc".
	defb 000h,018h,038h,018h,018h,018h,018h,07eh	; 48a5  ..8....~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh	; 48ad  .>c..<p.
	defb 000h,03eh,063h,003h,00eh,003h,063h,03eh	; 48b5  .>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h	; 48bd  ...6ff..
	defb 000h,07fh,060h,07eh,063h,003h,063h,03eh	; 48c5  ..`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh	; 48cd  .>c`~cc>
	defb 000h,07fh,063h,006h,00ch,018h,018h,018h	; 48d5  ..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh	; 48dd  .>cc>cc>
	defb 000h,03eh,063h,063h,03fh,003h,063h,03eh	; 48e5  .>cc?.c>
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 48ed  ........
	defb 000h,01ch,036h,063h,063h,07fh,063h,063h	; 48f5  ..6cc.cc
	defb 000h,07eh,063h,063h,07eh,063h,063h,07eh	; 48fd  .~cc~cc~
	defb 000h,03eh,063h,060h,060h,060h,063h,03eh	; 4905  .>c```c>
	defb 000h,07ch,066h,063h,063h,063h,066h,07ch	; 490d  .|fcccf|
	defb 000h,07fh,060h,060h,07eh,060h,060h,07fh	; 4915  ..``~``.
	defb 000h,07fh,060h,060h,07eh,060h,060h,060h	; 491d  ..``~```
	defb 000h,03eh,063h,060h,067h,063h,063h,03fh	; 4925  .>c`gcc?
	defb 000h,063h,063h,063h,07fh,063h,063h,063h	; 492d  .ccc.ccc
	defb 000h,03ch,018h,018h,018h,018h,018h,03ch	; 4935  .<.....<
	defb 000h,01fh,006h,006h,006h,006h,066h,03ch	; 493d  ......f<
	defb 000h,063h,066h,06ch,078h,07ch,06eh,067h	; 4945  .cflx|ng
	defb 000h,060h,060h,060h,060h,060h,060h,07fh	; 494d  .``````.
	defb 000h,063h,077h,07fh,07fh,06bh,063h,063h	; 4955  .cw..kcc
	defb 000h,063h,073h,07bh,07fh,06fh,067h,063h	; 495d  .cs{.ogc
	defb 000h,03eh,063h,063h,063h,063h,063h,03eh	; 4965  .>ccccc>
	defb 000h,07eh,063h,063h,063h,07eh,060h,060h	; 496d  .~ccc~``
	defb 000h,07eh,063h,063h,062h,07ch,066h,063h	; 4975  .~ccb|fc
	defb 000h,03eh,063h,060h,03eh,003h,063h,03eh	; 497d  .>c`>.c>
	defb 000h,07eh,018h,018h,018h,018h,018h,018h	; 4985  .~......
	defb 000h,063h,063h,063h,063h,063h,063h,03eh	; 498d  .cccccc>
	defb 000h,063h,063h,063h,063h,036h,01ch,008h	; 4995  .cccc6..
	defb 000h,063h,063h,06bh,06bh,07fh,077h,022h	; 499d  .cckk.w"
	defb 000h,066h,066h,07eh,03ch,018h,018h,018h	; 49a5  .ff~<...
	defb 000h,063h,076h,03ch,01ch,01eh,037h,063h	; 49ad  .cv<..7c

; ----------------------------------------------------------------------
; DATOS guion_de_la_pista: Un solo guion, que 0x423E ejecuta para montar la
;   pista
;   0x49b5..0x4ff1  (1596 bytes)
DATA_guion_de_la_pista:
	defb 001h,002h,000h,012h,060h,008h,040h,011h,004h,0f0h,011h,005h,0e0h,011h,005h,0c0h	; 49b5  ....`.@.........
	defb 011h,005h,080h,011h,005h,000h,011h,005h,001h,011h,005h,003h,011h,005h,007h,011h	; 49c5  ................
	defb 005h,00fh,011h,005h,01fh,011h,005h,03fh,011h,005h,07fh,011h,005h,0ffh,060h,048h	; 49d5  .......?......`H
	defb 040h,011h,004h,0f0h,011h,005h,0f8h,011h,005h,0fch,011h,005h,0feh,011h,005h,0ffh	; 49e5  @...............
	defb 011h,005h,080h,011h,005h,0c0h,011h,005h,0e0h,011h,005h,0f0h,011h,005h,0f8h,011h	; 49f5  ................
	defb 005h,0fch,011h,005h,0feh,011h,005h,0ffh,060h,088h,028h,080h,080h,000h,011h,00ah	; 4a05  ........`.(.....
	defb 001h,011h,005h,003h,011h,005h,007h,011h,005h,00fh,011h,005h,01fh,011h,005h,03fh	; 4a15  ...............?
	defb 07fh,07fh,060h,0b0h,028h,011h,003h,001h,011h,00ah,080h,011h,005h,0c0h,011h,005h	; 4a25  ..`.(...........
	defb 0e0h,011h,005h,0f0h,011h,005h,0f8h,011h,005h,0fch,0feh,0feh,060h,0d8h,050h,003h	; 4a35  ............`.P.
	defb 011h,006h,006h,011h,006h,00ch,011h,006h,018h,011h,006h,030h,060h,060h,07fh,07fh	; 4a45  ...........0``..
	defb 060h,060h,011h,006h,0c0h,011h,003h,080h,011h,005h,000h,011h,003h,001h,011h,003h	; 4a55  ``..............
	defb 080h,011h,005h,000h,011h,003h,001h,011h,006h,003h,011h,006h,006h,011h,006h,00ch	; 4a65  ................
	defb 011h,003h,018h,061h,028h,050h,0c0h,011h,006h,060h,011h,006h,030h,011h,006h,018h	; 4a75  ...a(P...`..0...
	defb 011h,006h,00ch,006h,006h,0feh,0feh,006h,006h,011h,006h,003h,011h,003h,001h,011h	; 4a85  ................
	defb 005h,000h,011h,003h,080h,011h,003h,001h,011h,005h,000h,011h,003h,080h,011h,006h	; 4a95  ................
	defb 0c0h,011h,006h,060h,011h,006h,030h,011h,003h,018h,061h,078h,028h,011h,003h,080h	; 4aa5  ...`..0...ax(...
	defb 011h,005h,000h,001h,011h,006h,002h,011h,006h,004h,008h,008h,00fh,008h,008h,008h	; 4ab5  ................
	defb 011h,006h,010h,011h,006h,020h,040h,061h,0a0h,028h,011h,003h,001h,011h,005h,000h	; 4ac5  ..... @a.(......
	defb 080h,011h,006h,040h,011h,006h,020h,010h,010h,0f0h,010h,010h,010h,011h,006h,008h	; 4ad5  ...@.. .........
	defb 011h,006h,004h,002h,061h,0c8h,028h,011h,008h,001h,011h,008h,080h,011h,003h,000h	; 4ae5  ....a.(.........
	defb 0ffh,0ffh,011h,003h,000h,011h,003h,001h,0ffh,0ffh,011h,003h,000h,011h,003h,080h	; 4af5  ................
	defb 0ffh,0ffh,011h,003h,000h,061h,0f0h,038h,011h,005h,000h,011h,003h,001h,011h,005h	; 4b05  .....a.8........
	defb 000h,011h,003h,080h,011h,007h,000h,0ffh,011h,008h,001h,011h,008h,080h,001h,011h	; 4b15  ................
	defb 007h,000h,080h,011h,007h,000h,062h,028h,030h,001h,001h,011h,006h,000h,0ffh,0ffh	; 4b25  ......b(0.......
	defb 011h,006h,000h,080h,080h,011h,00dh,000h,0ffh,011h,010h,000h,062h,068h,0f0h,011h	; 4b35  ............bh..
	defb 004h,000h,007h,007h,00fh,00fh,011h,008h,000h,011h,008h,000h,080h,080h,080h,011h	; 4b45  ................
	defb 005h,000h,011h,004h,040h,011h,004h,000h,011h,004h,002h,011h,004h,000h,001h,001h	; 4b55  ....@...........
	defb 001h,011h,005h,000h,011h,004h,000h,0e0h,0e0h,0f0h,0f0h,011h,007h,00fh,08fh,011h	; 4b65  ................
	defb 002h,011h,01fh,011h,002h,011h,01fh,011h,002h,011h,011h,002h,011h,0ffh,011h,002h	; 4b75  ................
	defb 011h,0ffh,011h,002h,011h,011h,002h,011h,0ffh,011h,002h,011h,0ffh,011h,002h,011h	; 4b85  ................
	defb 010h,010h,0f0h,010h,010h,0f0h,010h,010h,011h,008h,0f0h,0cfh,0cfh,0cfh,086h,011h	; 4b95  ................
	defb 004h,000h,01fh,011h,001h,011h,013h,0fch,011h,003h,000h,003h,0ffh,011h,001h,011h	; 4ba5  ................
	defb 001h,00fh,007h,007h,007h,00fh,0ffh,011h,003h,011h,011h,004h,003h,0ffh,011h,002h	; 4bb5  ................
	defb 011h,011h,005h,003h,0ffh,011h,002h,011h,011h,005h,000h,0ffh,011h,003h,011h,011h	; 4bc5  ................
	defb 004h,0c0h,0ffh,011h,002h,011h,011h,004h,0e0h,0f0h,0f0h,010h,090h,07fh,011h,004h	; 4bd5  ................
	defb 000h,0f0h,0f0h,0f0h,060h,011h,004h,000h,011h,004h,001h,011h,004h,000h,011h,004h	; 4be5  ....`...........
	defb 080h,011h,004h,000h,013h,013h,0ffh,013h,013h,0ffh,013h,013h,0d1h,0d1h,0ffh,0d1h	; 4bf5  ................
	defb 0d1h,0ffh,0d1h,0d1h,0ffh,003h,003h,081h,011h,004h,001h,0ffh,0c0h,0c0h,081h,011h	; 4c05  ................
	defb 004h,080h,063h,060h,0c0h,000h,001h,003h,007h,00fh,01fh,03fh,07fh,000h,080h,0c0h	; 4c15  ..c`.......?....
	defb 0e0h,0f0h,0f8h,0feh,0ffh,0ffh,0feh,0feh,0fch,0f8h,0f8h,0f0h,0e0h,0e0h,0c0h,080h	; 4c25  ................
	defb 080h,011h,004h,000h,011h,005h,0ffh,0feh,0feh,0fch,0f8h,0f8h,0f0h,0e0h,0e0h,0c0h	; 4c35  ................
	defb 080h,080h,0ffh,07fh,07fh,03fh,01fh,01fh,00fh,007h,007h,003h,001h,001h,011h,004h	; 4c45  .....?..........
	defb 000h,011h,005h,0ffh,07fh,07fh,03fh,01fh,01fh,00fh,007h,007h,003h,001h,001h,011h	; 4c55  ......?.........
	defb 006h,000h,006h,00eh,000h,080h,000h,011h,005h,080h,000h,000h,000h,000h,001h,003h	; 4c65  ................
	defb 000h,001h,01ah,03ah,02ah,02ah,0a8h,0a8h,0a8h,0a0h,080h,001h,001h,003h,007h,007h	; 4c75  ...:**..........
	defb 00fh,01fh,000h,004h,00ch,018h,018h,030h,031h,073h,003h,01ah,03ah,02bh,02bh,0aah	; 4c85  .......01s..:++.
	defb 0a8h,0a8h,0a0h,080h,080h,000h,000h,001h,001h,003h,000h,001h,011h,006h,003h,062h	; 4c95  ...............b
	defb 062h,06ah,0eah,0cah,0cbh,0cbh,088h,0a8h,0a8h,0a0h,0a0h,080h,080h,000h,000h,011h	; 4ca5  bj..............
	defb 008h,003h,0c8h,0f8h,078h,030h,011h,004h,000h,003h,002h,002h,011h,005h,000h,064h	; 4cb5  ....x0.........d
	defb 020h,070h,011h,005h,000h,002h,003h,003h,001h,001h,003h,003h,001h,001h,000h,000h	; 4cc5   p..............
	defb 0c0h,0e0h,0b0h,0d0h,0c0h,0e0h,0f0h,0c0h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch,03fh	; 4cd5  ...............?
	defb 000h,081h,080h,0c0h,0e0h,0e0h,0f0h,0f8h,061h,0f9h,0fdh,031h,019h,03fh,00fh,004h	; 4ce5  ........a..1.?..
	defb 0e0h,0f0h,011h,006h,0f8h,00fh,003h,003h,001h,001h,080h,080h,0c0h,0f0h,060h,000h	; 4cf5  ..............`.
	defb 080h,0edh,0fdh,0efh,0cdh,011h,005h,000h,0a4h,0b6h,0b2h,0f6h,0dfh,08ch,08eh,00eh	; 4d05  ................
	defb 006h,000h,000h,000h,0f0h,0f0h,011h,005h,000h,011h,008h,080h,011h,008h,001h,064h	; 4d15  ...............d
	defb 0a0h,040h,011h,007h,000h,0c0h,011h,00fh,000h,003h,0c0h,000h,00fh,00fh,00fh,011h	; 4d25  .@..............
	defb 00bh,000h,003h,000h,0f0h,0f0h,0f0h,011h,003h,000h,011h,008h,0c0h,011h,008h,003h	; 4d35  ................
	defb 064h,0e8h,040h,011h,003h,000h,011h,005h,00fh,011h,003h,000h,011h,005h,0ffh,011h	; 4d45  d.@.............
	defb 003h,000h,011h,005h,0f0h,011h,008h,0f0h,011h,008h,00fh,0f0h,0ffh,07fh,011h,005h	; 4d55  ................
	defb 000h,011h,003h,0ffh,011h,005h,000h,00fh,0ffh,0feh,011h,005h,000h,065h,028h,020h	; 4d65  .............e( 
	defb 018h,021h,063h,0e3h,0cch,09ch,099h,060h,018h,021h,063h,0e3h,0cch,09ch,099h,060h	; 4d75  .!c....`.!c....`
	defb 018h,084h,0c6h,0c7h,033h,039h,098h,006h,018h,084h,0c6h,0c7h,033h,039h,098h,006h	; 4d85  ....39......39..
	defb 065h,048h,0a8h,000h,000h,00fh,01fh,01fh,01fh,01dh,01fh,011h,003h,000h,0c0h,080h	; 4d95  eH..............
	defb 000h,000h,000h,01eh,03eh,07fh,080h,080h,0ffh,086h,0c6h,011h,003h,000h,0f0h,008h	; 4da5  ....>...........
	defb 000h,0e0h,0f0h,07fh,03fh,03fh,03fh,011h,004h,028h,011h,004h,018h,011h,004h,098h	; 4db5  ....???..(......
	defb 03fh,011h,003h,028h,03fh,028h,028h,02fh,0fch,03ch,034h,036h,0f6h,01bh,01bh,0fdh	; 4dc5  ?..(?((/.<46....
	defb 028h,028h,07fh,0f8h,0f0h,060h,000h,000h,005h,007h,0feh,00fh,00fh,006h,000h,000h	; 4dd5  ((...`..........
	defb 000h,000h,00eh,01fh,01fh,01fh,015h,01fh,000h,000h,00fh,011h,005h,01fh,007h,003h	; 4de5  ................
	defb 001h,001h,000h,000h,0ffh,003h,011h,008h,000h,000h,000h,000h,080h,080h,011h,003h	; 4df5  ................
	defb 000h,000h,001h,001h,003h,007h,007h,000h,03fh,01eh,03fh,0ffh,03fh,02fh,07fh,03fh	; 4e05  ........?.?.?/.?
	defb 01fh,011h,005h,01fh,037h,03fh,03fh,000h,080h,011h,005h,0c0h,080h,033h,033h,033h	; 4e15  ....7??......333
	defb 071h,011h,004h,000h,080h,0b0h,0f0h,0f0h,011h,004h,000h,000h,00ah,040h,008h,0d0h	; 4e25  q............@..
	defb 011h,018h,026h,011h,068h,062h,026h,026h,011h,006h,0f6h,011h,020h,062h,026h,026h	; 4e35  ..&.hb&&.... b&&
	defb 026h,011h,005h,0f6h,011h,020h,062h,040h,0d8h,0f0h,011h,0f0h,0f6h,041h,0c8h,0a0h	; 4e45  &.... b@.....A..
	defb 011h,060h,0f6h,011h,018h,0f2h,011h,008h,0f2h,011h,010h,0f6h,011h,010h,022h,042h	; 4e55  .`............"B
	defb 068h,0f0h,011h,00ch,002h,011h,003h,00fh,000h,011h,004h,006h,00fh,00fh,00fh,000h	; 4e65  h...............
	defb 011h,004h,026h,00fh,00fh,00fh,000h,011h,004h,0f6h,00fh,00fh,00fh,000h,011h,004h	; 4e75  ..&.............
	defb 0f6h,00fh,00fh,00fh,000h,011h,004h,026h,00fh,00fh,00fh,000h,011h,008h,002h,011h	; 4e85  .......&........
	defb 008h,042h,011h,010h,0f2h,011h,008h,0f6h,011h,008h,0f2h,011h,010h,042h,0f2h,0f2h	; 4e95  .B...........B..
	defb 002h,002h,011h,004h,022h,0f2h,0f2h,0f1h,012h,011h,004h,062h,0f6h,0f6h,0f6h,000h	; 4ea5  ...."......b....
	defb 011h,004h,0f6h,0f6h,0f6h,0f6h,000h,011h,004h,0f6h,0f6h,0f6h,0f6h,000h,011h,004h	; 4eb5  ................
	defb 006h,0f6h,0f6h,0f6h,000h,011h,004h,0f6h,0f2h,0f2h,000h,002h,011h,004h,062h,0f2h	; 4ec5  ..............b.
	defb 0f2h,011h,006h,002h,011h,008h,042h,011h,004h,0f6h,0ffh,0ffh,0ffh,000h,011h,004h	; 4ed5  ......B.........
	defb 0f6h,0ffh,0ffh,0ffh,000h,011h,010h,0f6h,0f6h,0f6h,0f1h,016h,011h,004h,0f6h,0f6h	; 4ee5  ................
	defb 0f6h,0f1h,016h,011h,004h,0f6h,043h,060h,050h,011h,008h,04fh,011h,008h,04fh,011h	; 4ef5  ......C`P..O..O.
	defb 040h,042h,043h,0b0h,070h,011h,021h,0f4h,011h,007h,024h,011h,015h,0f4h,011h,003h	; 4f05  @BC.p.!...$.....
	defb 024h,011h,030h,0f4h,044h,020h,078h,011h,018h,024h,011h,007h,04fh,04bh,011h,010h	; 4f15  $.0.D x..$..OK..
	defb 024h,011h,008h,0b4h,011h,008h,024h,0b4h,0b4h,011h,01eh,024h,011h,018h,014h,044h	; 4f25  $.....$....$...D
	defb 0a0h,088h,011h,006h,002h,00fh,0f7h,011h,006h,002h,00fh,007h,011h,006h,002h,00fh	; 4f35  ................
	defb 0f7h,0f7h,00fh,0e2h,0e2h,0e2h,002h,002h,002h,007h,00fh,00eh,00eh,00eh,002h,002h	; 4f45  ................
	defb 002h,0f7h,00fh,0e2h,0e2h,0e2h,002h,002h,002h,011h,008h,0f0h,011h,008h,0f0h,007h	; 4f55  ................
	defb 00fh,05eh,05eh,011h,004h,0e2h,011h,018h,07fh,011h,010h,0f0h,0f7h,011h,007h,0f2h	; 4f65  .^^.............
	defb 073h,011h,007h,0f2h,0f7h,011h,007h,0f2h,045h,028h,020h,00fh,03fh,03fh,03fh,0dfh	; 4f75  s.......E( .???.
	defb 0dfh,0dfh,00fh,07fh,0bfh,0bfh,0bfh,08fh,08fh,08fh,07fh,00fh,03fh,03fh,03fh,0dfh	; 4f85  ............???.
	defb 0dfh,0dfh,00fh,07fh,0bfh,0bfh,0bfh,08fh,08fh,08fh,07fh,045h,048h,0a8h,011h,005h	; 4f95  ...........EH...
	defb 0f2h,011h,003h,092h,011h,008h,0f2h,092h,072h,072h,011h,004h,0f7h,0f4h,011h,005h	; 4fa5  ........rr......
	defb 0f2h,011h,003h,042h,011h,022h,0f2h,011h,006h,002h,0f2h,0f2h,011h,006h,002h,011h	; 4fb5  ...B."..........
	defb 005h,0f2h,011h,003h,092h,011h,006h,0f2h,012h,092h,011h,006h,042h,0f7h,0f7h,011h	; 4fc5  ............B...
	defb 010h,0f2h,011h,006h,024h,07fh,07fh,011h,003h,0f2h,011h,005h,0b2h,011h,005h,042h	; 4fd5  ....$..........B
	defb 011h,003h,0f2h,011h,005h,042h,011h,003h,0f2h,011h,010h,0f2h	; 4fe5  .....B......

; ----------------------------------------------------------------------
; DATOS tiles_de_la_pista: La tabla de nombres de la pista, en el formato de
;   0x43EA
;   0x4ff1..0x51fe  (525 bytes)
DATA_tiles_de_la_pista:
	defb 078h,000h,0a6h,0a5h,0a6h,0a5h,0a6h,0a5h,0a6h,0a5h,09dh,0feh,005h,09eh,0f1h,09eh	; 4ff1  x...............
	defb 09eh,0f2h,09eh,09eh,0f3h,09eh,09eh,09fh,0a7h,0a8h,0a7h,0a8h,0a7h,0a8h,0a7h,0a7h	; 5001  ................
	defb 0a5h,0a6h,0a5h,0a6h,0a5h,0a6h,06ch,090h,0a0h,0e0h,0dch,0e7h,000h,000h,0f0h,000h	; 5011  ......l.........
	defb 000h,0f0h,000h,000h,0f0h,000h,000h,0a1h,091h,06dh,0a8h,0a7h,0a8h,0a7h,0a8h,0a7h	; 5021  .........m......
	defb 0a6h,0a5h,0a6h,0a5h,0a6h,06ch,092h,090h,0a0h,0d3h,0e0h,0e4h,000h,000h,0f0h,000h	; 5031  .....l..........
	defb 000h,0f0h,000h,000h,0f0h,000h,000h,0a1h,091h,092h,06dh,0a8h,0a7h,0a8h,0a7h,0a8h	; 5041  ..........m.....
	defb 0a5h,0a6h,0a5h,0a6h,06ch,092h,06eh,04bh,0a2h,0feh,00eh,0a3h,0a4h,04bh,072h,092h	; 5051  ....l.nK.....Kr.
	defb 06dh,0a8h,0a7h,0a8h,0a7h,0a6h,0a5h,0a6h,06ch,092h,070h,06fh,04bh,04bh,04bh,0feh	; 5061  m.......l.poKKK.
	defb 00ch,048h,04bh,04bh,04bh,073h,074h,084h,06dh,0a8h,0a7h,0a8h,0a5h,0a6h,06ch,076h	; 5071  .HKKKst.m.....lv
	defb 077h,071h,0feh,004h,04bh,011h,02fh,04ah,04ah,04ah,043h,044h,04ah,04ah,04ah,034h	; 5081  wq..K./JJJCDJJJ4
	defb 016h,0feh,004h,04bh,075h,085h,086h,087h,0a8h,0a7h,0a6h,06ch,078h,079h,07ah,0feh	; 5091  ...Ku......lxyz.
	defb 004h,04bh,012h,030h,0feh,00ah,04ah,035h,017h,0feh,004h,04bh,088h,089h,08ah,06dh	; 50a1  .K.0..J5...K...m
	defb 0a8h,06ch,07bh,07ch,07dh,06fh,0feh,004h,04bh,013h,031h,0feh,00ah,040h,036h,018h	; 50b1  .l{|}o..K.1..@6.
	defb 04bh,094h,095h,095h,0b5h,08bh,08ch,08dh,06dh,07eh,07fh,080h,071h,0a9h,0aah,04bh	; 50c1  K.......m~..q..K
	defb 04bh,04bh,014h,032h,0feh,004h,04ah,041h,042h,0feh,004h,04ah,037h,019h,04bh,09ah	; 50d1  KK.2..JAB..J7.K.
	defb 000h,000h,09bh,075h,092h,08eh,08fh,081h,082h,06eh,04bh,0abh,0ach,04bh,04bh,04bh	; 50e1  ...u.....nK..KKK
	defb 015h,033h,0feh,004h,04ah,041h,042h,0feh,004h,04ah,038h,01ah,04bh,097h,098h,098h	; 50f1  .3..JAB..J8.K...
	defb 099h,04bh,072h,092h,092h,083h,070h,06fh,04bh,0adh,0aeh,04dh,04eh,04eh,050h,051h	; 5101  .Kr...poK..MNNPQ
	defb 0feh,004h,04fh,065h,066h,0feh,004h,04fh,052h,053h,04eh,04eh,054h,04bh,0b9h,04bh	; 5111  ..Oef..ORSNNTK.K
	defb 073h,074h,092h,092h,071h,04bh,04bh,0afh,0b0h,055h,056h,057h,0feh,006h,058h,067h	; 5121  st..qKK..UVW..Xg
	defb 068h,0feh,006h,058h,057h,059h,05ah,04bh,0bah,0bbh,04bh,075h,092h,06eh,04bh,04bh	; 5131  h..XWYZK..Ku.nKK
	defb 04bh,0b1h,0b2h,05bh,05ch,05dh,05eh,0feh,005h,060h,069h,06ah,0feh,005h,060h,061h	; 5141  K..[\]^..`ij..`a
	defb 062h,063h,064h,04bh,0bch,0bdh,04bh,04bh,072h,06fh,0feh,007h,04bh,001h,01bh,0feh	; 5151  bcdK..KKro..K...
	defb 005h,04ah,039h,03ah,0feh,005h,04ah,025h,009h,0feh,007h,04bh,073h,0feh,008h,04bh	; 5161  .J9:..J%...Ks..K
	defb 002h,01ch,0feh,005h,04ah,039h,03ah,0feh,005h,04ah,026h,00ah,04bh,04bh,094h,095h	; 5171  ....J9:..J&.KK..
	defb 095h,095h,096h,04bh,0feh,008h,04bh,003h,01dh,0feh,005h,04ah,039h,03ah,0feh,005h	; 5181  ...K..K....J9:..
	defb 04ah,027h,00bh,04bh,04bh,09ah,000h,000h,000h,09bh,04bh,0feh,007h,04bh,004h,04ah	; 5191  J'.KK.....K..K.J
	defb 01eh,0feh,005h,03bh,03ch,03dh,0feh,005h,03bh,028h,04ah,00ch,04bh,097h,098h,098h	; 51a1  ...;<=..;(J.K...
	defb 098h,099h,04bh,0feh,007h,04bh,005h,020h,01fh,0feh,00ch,04ah,029h,02ah,00dh,0feh	; 51b1  ..K..K. ...J)*..
	defb 007h,04bh,0feh,007h,04bh,006h,022h,021h,0feh,00ch,04ah,02bh,02ch,00eh,0feh,007h	; 51c1  .K..K."!..J+,...
	defb 04bh,0feh,007h,04bh,007h,023h,0feh,00eh,04ah,02dh,00fh,0feh,007h,04bh,0feh,007h	; 51d1  K..K.#..J-...K..
	defb 04bh,008h,024h,0feh,006h,04ah,03eh,03fh,0feh,006h,04ah,02eh,010h,0feh,007h,04bh	; 51e1  K.$..J>?..J....K
	defb 0feh,006h,04bh,045h,0feh,012h,046h,047h,0feh,046h,04bh,0ffh,0ffh	; 51f1  ..KE..FG.FK..

; ======================================================================
; CODIGO 0x51fe..0x550a  (780 bytes)
; ======================================================================


mueve_la_pelota:		; Un paso del vuelo: avanza, rebota y decide donde cae
	ld a,(0e0d8h)		;51fe   ; 0xE0D8 dice si hay pelota en juego
	or a			;5201
	ret z			;5202
	ld a,(0e045h)		;5203   ; 0xE045 corta el vuelo mientras haya un aviso en pantalla
	or a			;5206
	ret z			;5207
	ld a,(0e0d9h)		;5208   ; 0xE0D9 reparte el trabajo entre cuadros
	or a			;520b
	jp nz,dibuja_la_pelota		;520c   ; si toca la mitad de abajo, solo se redibuja
recalcula_la_trayectoria:		; Vuelve a montar la parabola desde los parametros del golpe
	ld hl,0e0dbh		;520f   ; 0xE0DB pide recalcular la trayectoria desde cero
	xor a			;5212
	cp (hl)			;5213
	jp z,sigue_el_vuelo		;5214
	ld (hl),a			;5217   ; y se apaga en cuanto se atiende
	ld (0e0a9h),a		;5218
	ld (0e0a6h),a		;521b
	ld l,0d7h		;521e   ; 0xE0D7 lleva el sentido del avance y se invierte en cada golpe
	ld a,(hl)			;5220
	cpl			;5221
	ld (hl),a			;5222
	call parametros_del_golpe		;5223   ; saca de la tabla los parametros de este golpe
trayectoria_desde_el_bote:		; Rehace la parabola tras un bote
	call bota_dentro_o_fuera		;5226
	ld hl,(0e0abh)		;5229   ; 0xE0AB es la fuerza con la que sale
	ld (0e0d0h),hl		;522c
	ld hl,(0e0adh)		;522f   ; y 0xE0AD la componente que le toca a un eje
	call multiplica_y_devuelve		;5232   ; multiplica una por otra
	ld (0e0b1h),hl		;5235
	ld hl,(0e0abh)		;5238
	ld (0e0d0h),hl		;523b
	ld hl,(0e0afh)		;523e   ; y lo mismo con el otro eje
	call multiplica_y_devuelve		;5241
	ld (0e0b3h),hl		;5244
	ld hl,00000h		;5247   ; 0xE0B5 acumula el recorrido, y empieza a cero
	ld (0e0b5h),hl		;524a
	ld hl,0e0d2h		;524d   ; 0xE0D2 es el acumulador de la multiplicacion
	ld (hl),000h		;5250
	inc hl			;5252
	ld (hl),007h		;5253
	call multiplica_8		;5255   ; aqui se hace la cuenta
	ld a,(0e0d2h)		;5258
	ld (0e0d3h),a		;525b
	ld hl,(0e0b1h)		;525e   ; el resultado del primer eje pasa a ser el multiplicando
	ld (0e0d0h),hl		;5261
	xor a			;5264
	ld (0e0d2h),a		;5265
	call multiplica_y_devuelve_alto		;5268   ; y otra vuelta
	ld (hl),028h		;526b
	call multiplica_8		;526d
	ld a,(0e0d2h)		;5270
	ld c,a			;5273
	ld a,(0e0bbh)		;5274   ; 0xE0BB es la altura de la sombra, la que se queda en el suelo
	ld b,a			;5277
	ld a,(0e0b7h)		;5278   ; 0xE0B7 es la de la pelota; su resta ES la altura del bote
	sub b			;527b
	ld hl,0e0d0h		;527c
	ld (hl),000h		;527f
	inc hl			;5281
	ld (hl),a			;5282
	inc hl			;5283
	ld (hl),000h		;5284
	inc hl			;5286
	ld (hl),00ah		;5287   ; diez, que es la gravedad de este cartucho
	call multiplica_y_devuelve_alto		;5289
	ld a,(0e0aah)		;528c
	ld (hl),a			;528f
	call multiplica_8		;5290
	ld a,(0e0d2h)		;5293
	add a,c			;5296
	ld c,a			;5297
	call divide_por_restas		;5298   ; divide para repartir el avance entre los cuadros
	ld a,(0e0d7h)		;529b   ; segun el sentido, el avance suma o resta
	or a			;529e
	ld a,c			;529f
	jr nz,avance_con_signo		;52a0
	neg		;52a2
avance_con_signo:		; Suma o resta el avance segun el sentido
	ld hl,0e0b7h		;52a4   ; 0xE0DD queda con la posicion nueva
	add a,(hl)			;52a7
	ld (0e0ddh),a		;52a8
	inc hl			;52ab
	ld a,b			;52ac
	add a,(hl)			;52ad
	ld (0e0dch),a		;52ae
	ld a,(0e0b7h)		;52b1
	sub 054h		;52b4   ; 0x54 es la altura de la red
	jr nc,avance_del_otro_eje		;52b6
	neg		;52b8
avance_del_otro_eje:		; Y lo mismo por el otro eje
	call divide_por_restas		;52ba
	ld a,(0e0b8h)		;52bd
	add a,b			;52c0
	ld (0e0deh),a		;52c1
	jp avanza_un_paso		;52c4
la_pelota_se_para:		; Se acabo el punto: suena, se apunta y se recoloca
	ld a,001h		;52c7   ; el sonido de fin de punto
	call suena		;52c9
	ld hl,0e0a6h		;52cc   ; 0xE0A6 marca que la pelota ya no vuela
	ld (hl),000h		;52cf
	inc hl			;52d1
	inc hl			;52d2
	inc hl			;52d3
	inc (hl)			;52d4   ; sube el contador de botes
	ld a,001h		;52d5
	cp (hl)			;52d7
	jr nc,rozamiento		;52d8
	ld a,(0e062h)		;52da   ; 0xE062 evita que se cuente el punto dos veces
	or a			;52dd
	ld a,001h		;52de
	jr nz,rozamiento		;52e0
	ld (0e062h),a		;52e2
	ld (0e041h),a		;52e5
	ld a,(0e042h)		;52e8   ; 0xE042 dice si el punto lo gano el de arriba o el de abajo
	or a			;52eb
	jr z,rozamiento		;52ec
	ld a,(0e0c3h)		;52ee
	ld (0e045h),a		;52f1
rozamiento:		; Elige cuanto frena la pelota segun donde este
	inc hl			;52f4
	inc hl			;52f5
	inc hl			;52f6
	ld b,014h		;52f7   ; 0x14 es el rozamiento normal
	ld a,(0e0c0h)		;52f9   ; 0xE0C0 sube el rozamiento cuando la pelota va por el suelo
	or a			;52fc
	jr nz,resta_el_rozamiento		;52fd
	ld a,(0e044h)		;52ff
	or a			;5302
	jr nz,resta_el_rozamiento		;5303
	ld b,028h		;5305   ; y en la hierba frena el doble
	ld a,(0e042h)		;5307
	or a			;530a
	jr nz,resta_el_rozamiento		;530b
	ld a,(0e04fh)		;530d   ; 0xE04F es el saque
	or a			;5310
	jr nz,rozamiento_maximo		;5311
	ld b,00ah		;5313   ; con lo que casi no frena
	ld a,(0e0aah)		;5315
	cp 005h		;5318
	jr z,resta_el_rozamiento		;531a
rozamiento_maximo:		; El frenazo mas fuerte
	ld b,030h		;531c   ; y el maximo frenazo
resta_el_rozamiento:		; Se lo quita a lo que quedaba de recorrido
	ld a,(hl)			;531e   ; resta el rozamiento a lo que quedaba de recorrido
	sub b			;531f
	ld (hl),a			;5320
	jp c,pelota_fuera_de_juego		;5321   ; si se pasa de cero, la pelota se para del todo
	ld hl,0e0aeh		;5324
	ld a,0b3h		;5327   ; 0xB3 es el tope por abajo de la pista
	cp (hl)			;5329
	jr nc,vuelve_a_la_trayectoria		;532a
	ld (hl),a			;532c
	inc hl			;532d
	inc hl			;532e
	ld (hl),a			;532f
vuelve_a_la_trayectoria:		; Con lo que queda, otra parabola
	jp trayectoria_desde_el_bote		;5330
pelota_fuera_de_juego:		; 0xE0D8 a cero y punto cerrado
	xor a			;5333   ; 0xE0D8 a cero: fuera de juego
	ld (0e0d8h),a		;5334
	ld a,(0e062h)		;5337
	or a			;533a
	ret nz			;533b
	ld l,041h		;533c   ; y 0xE041 avisa de que hay que repartir el punto
	set 0,(hl)		;533e
	ret			;5340
sigue_el_vuelo:		; Un cuadro mas de la parabola
	ld a,(0e0a6h)		;5341   ; si ya se paro, va por el otro lado
	or a			;5344
	jr nz,la_pelota_se_para		;5345
avanza_un_paso:		; Suma el paso del cuadro a la posicion y comprueba la red
	ld hl,(0e0b2h)		;5347   ; 0xE0B2 lleva la direccion del golpe
	ld a,(0e0a4h)		;534a   ; 0xE0A4 es el angulo, que va girando
	call suma_a_hl		;534d
	ld a,h			;5350   ; intercambia los dos bytes: el alto pasa a bajo
	ld h,l			;5351
	ld l,a			;5352
	call prepara_multiplicacion		;5353
	call pon_28_y_multiplica		;5356
	ld a,(0e0d0h)		;5359   ; el angulo nuevo se guarda para el cuadro siguiente
	ld (0e0a4h),a		;535c
	ld a,(0e0d2h)		;535f
	ld b,a			;5362
	ld a,(0e0d7h)		;5363   ; 0xE0D7 vuelve a decidir el signo
	or a			;5366
	ld a,b			;5367
	jr nz,suma_el_paso		;5368
	neg		;536a
suma_el_paso:		; El paso del cuadro a la pelota y a su sombra
	push af			;536c
	ld hl,0e0b7h		;536d   ; suma el paso a la pelota
	add a,(hl)			;5370
	ld (hl),a			;5371
	pop af			;5372
	ld hl,0e0bbh		;5373   ; y el mismo paso a su sombra
	add a,(hl)			;5376
	ld (hl),a			;5377
	ld ix,0e0a0h		;5378   ; 0xE0A0 es el bloque de la velocidad que va cayendo
	ld a,(ix+000h)		;537c
	sub b			;537f   ; la velocidad baja en cada cuadro
	ld (ix+000h),a		;5380
	ld b,000h		;5383
	jr z,recarga_la_velocidad		;5385
	jr nc,comprueba_los_lados		;5387
recarga_la_velocidad:		; Cuando se agota, del escalon siguiente
	ld a,(ix+002h)		;5389   ; y cuando se agota, se recarga del siguiente escalon
	add a,b			;538c
	ld b,a			;538d
	ld a,(ix+001h)		;538e
	add a,(ix+000h)		;5391   ; con el resto de la division anterior
	ld (ix+000h),a		;5394
	rlca			;5397   ; hasta que no quede acarreo
	jr c,recarga_la_velocidad		;5398
comprueba_los_lados:		; Si se sale por un lado o por el otro, punto
	ld hl,0e0b8h		;539a   ; 0xE0B8 es la coordenada del otro eje
	ld a,b			;539d
	add a,(hl)			;539e
	cp 004h		;539f   ; si se sale por un lado o por el otro, punto
	jr c,pelota_fuera_de_juego		;53a1
	cp 0fch		;53a3
	jr nc,pelota_fuera_de_juego		;53a5
	ld (hl),a			;53a7
	ld (0e0bch),a		;53a8
	ld hl,(0e0b5h)		;53ab   ; 0xE0B5 acumula la caida: catorce por cuadro
	ld a,00eh		;53ae
	call suma_a_hl		;53b0
	ld (0e0b5h),hl		;53b3
	ex de,hl			;53b6
	ld hl,(0e0b3h)		;53b7   ; 0xE0B3 es la altura de salida
	ld a,l			;53ba   ; y otra vez el intercambio de bytes
	ld l,h			;53bb
	ld h,a			;53bc
	ld a,(0e0bfh)		;53bd
	call suma_a_hl		;53c0
	xor a			;53c3   ; 0xE0A7 marca si la resta salio negativa
	ld (0e0a7h),a		;53c4
	ld b,h			;53c7
	ld c,l			;53c8
	sbc hl,de		;53c9   ; la altura de ahora menos lo que ha caido
	jr nc,monta_la_altura		;53cb
	ld h,b			;53cd
	ld l,c			;53ce
	ex de,hl			;53cf
	xor a			;53d0
	sbc hl,de		;53d1   ; si salio al reves, se le da la vuelta y se apunta
	inc a			;53d3
	ld (0e0a7h),a		;53d4
monta_la_altura:		; Deja la altura para la cuenta siguiente
	ex de,hl			;53d7
	ld hl,0e0d0h		;53d8   ; 0xE0D0 recibe el resultado para la siguiente cuenta
	ld (hl),d			;53db
	inc hl			;53dc
	ld (hl),e			;53dd
	inc hl			;53de
	ld (hl),000h		;53df
	inc hl			;53e1
	call pon_28_y_multiplica		;53e2
	ld a,(0e0d0h)		;53e5   ; 0xE0BF guarda el alto de la parabola
	ld (0e0bfh),a		;53e8
	ld a,(0e0d2h)		;53eb
	ld hl,0e0a7h		;53ee
	bit 0,(hl)		;53f1   ; y aqui se recupera el signo
	jr z,comprueba_la_sombra		;53f3
	neg		;53f5
comprueba_la_sombra:		; Mira si la pelota alcanza al suelo
	ld l,a			;53f7
	ld a,(0e0b7h)		;53f8   ; 0xD0 significa que la pelota no esta en la pista
	cp 0d0h		;53fb
	jp nc,pelota_fuera_de_juego		;53fd
	ld b,a			;5400
	ld a,(0e0bbh)		;5401   ; compara la pelota con su sombra
	sub l			;5404
	cp b			;5405
	jr c,pega_la_sombra		;5406
	cp 0d0h		;5408
	jr nc,pega_la_sombra		;540a
	ld a,001h		;540c   ; 0xE0A6 a uno: la pelota ha tocado el suelo
	ld (0e0a6h),a		;540e
	ld a,b			;5411
pega_la_sombra:		; La sombra se pone donde la pelota
	ld (0e0bbh),a		;5412   ; y la sombra se pone donde la pelota
	ret			;5415
dibuja_la_pelota:		; La pinta del tamano que le toca segun lo alta que vaya
	ld b,000h		;5416   ; B contara el escalon de tamano
	ld a,(0e0bbh)		;5418   ; si no hay sombra, no hay pelota que pintar
	cp 0d0h		;541b
	ret z			;541d
	ld d,a			;541e
	ld a,(0e0b7h)		;541f   ; la altura es la pelota menos su sombra
	sub d			;5422
	cp 021h		;5423   ; tres escalones: 0x21, 0x0F y 0x06
	jr nc,tamano_por_el_punto		;5425
	inc b			;5427   ; cuanto mas alta, mas pequena se ve
	cp 00fh		;5428
	jr nc,tamano_por_el_punto		;542a
	inc b			;542c
	cp 006h		;542d
	jr nc,tamano_por_el_punto		;542f
	inc b			;5431
	ld a,d			;5432   ; 0x38 es el fondo de la pista
	cp 038h		;5433
	jr nc,tamano_por_el_punto		;5435
	inc b			;5437
tamano_por_el_punto:		; Dos escalones mas cuando el punto ya esta decidido
	ld a,(0e042h)		;5438   ; 0xE042 dice de quien es el punto
	or a			;543b
	jr z,busca_el_tamano		;543c
	ld a,b			;543e
	cp 002h		;543f   ; y en ese caso se salta dos escalones
	inc b			;5441
	inc b			;5442
	jr c,busca_el_tamano		;5443
	ld b,003h		;5445   ; sin pasar del cuarto
busca_el_tamano:		; Coge el par de punteros del escalon
	ld hl,05528h		;5447   ; la tabla de 0x5528 tiene un par de punteros por escalon
	ld a,b			;544a
	rlca			;544b   ; cuatro bytes por entrada
	rlca			;544c
	call suma_a_hl		;544d
	ld e,(hl)			;5450
	inc hl			;5451
	ld d,(hl)			;5452
	inc hl			;5453
	push hl			;5454
	ex de,hl			;5455
	ld de,05800h		;5456   ; el primero va a la VRAM 0x1800: el patron de la pelota
	call descomprime_sprite		;5459
	pop hl			;545c
	ld e,(hl)			;545d
	inc hl			;545e
	ld d,(hl)			;545f
	ex de,hl			;5460
	ld de,05be0h		;5461   ; y el segundo a 0x1BE0, que es su sombra
	call descomprime_sprite		;5464
	ld a,(0e0b7h)		;5467
	cp 0d0h		;546a   ; 0xD0 otra vez: fuera de la pista, nada que colocar
	ret z			;546c
coloca_la_pelota:		; Deja los atributos de los dos sprites de la pelota y su sombra
	ld hl,0e0b7h		;546d
	ld de,07b7ch		;5470   ; los atributos del sprite 31, el ultimo
	call pon_atributos		;5473
	ld de,07b00h		;5476   ; y los del sprite 0, el primero
pon_atributos:		; Deja los cuatro bytes de un sprite en la VRAM
	ld b,004h		;5479   ; y, x, patron y color
	jp escribe_bloque_en		;547b
divide_por_restas:		; Divide contando cuantas veces cabe, que es lo que hay sin divisor
	ld de,0e0a3h		;547e   ; 0xE0A3 es el resto que va quedando
	ld (de),a			;5481
	ld hl,0e0a1h		;5482   ; y 0xE0A1 el divisor
	ld b,000h		;5485
divide_vuelta:		; Una resta mas mientras quepa
	ld a,(de)			;5487   ; mientras quepa, una vez mas
	sub (hl)			;5488
	ret c			;5489   ; y en cuanto no cabe, se acabo
	ld (de),a			;548a
	dec de			;548b
	ld a,(de)			;548c
	inc de			;548d
	add a,b			;548e   ; va sumando el paso de cada vuelta
	ld b,a			;548f
	jr divide_vuelta		;5490
parametros_del_golpe:		; Saca de la tabla la fuerza y el efecto de este golpe
	ld hl,05516h		;5492   ; la tabla vive en 0x5516
	ld a,(0e0d6h)		;5495   ; 0xE0D6 es la clase de golpe
	rlca			;5498   ; dos bytes por entrada
	call suma_a_hl		;5499
	ld a,(hl)			;549c
	ld de,0e0a0h		;549d   ; 0xE0A0 recibe los tres valores
	ld (de),a			;54a0
	inc de			;54a1
	ld (de),a			;54a2
	inc hl			;54a3
	inc de			;54a4
	ld a,(hl)			;54a5
	ld (de),a			;54a6
	ret			;54a7
pon_28_y_multiplica:		; Deja un 0x28 y entra en la multiplicacion corta
	ld (hl),028h		;54a8
multiplica_8:		; Multiplica a base de desplazar y restar, ocho vueltas
	exx			;54aa
	ld c,008h		;54ab   ; ocho bits, ocho vueltas
multiplica_8_vuelta:		; Un bit del multiplicador
	ld hl,0e0d2h		;54ad   ; 0xE0D2 es el acumulador
	or a			;54b0
	ld b,003h		;54b1   ; tres bytes de ancho
multiplica_8_desplaza:		; Desplaza los tres bytes del acumulador
	rl (hl)		;54b3   ; desplaza el acumulador entero un bit
	dec hl			;54b5
	djnz multiplica_8_desplaza		;54b6   ; byte a byte, con el acarreo pasando de uno a otro
	inc hl			;54b8
	ex de,hl			;54b9
	ld hl,0e0d3h		;54ba   ; 0xE0D3 es el divisor de esta vuelta
	ld a,(de)			;54bd
	sub (hl)			;54be   ; si cabe, se resta
	jr c,multiplica_8_sigue		;54bf
	ld (de),a			;54c1
	dec hl			;54c2
	set 0,(hl)		;54c3   ; y se apunta el bit del cociente
multiplica_8_sigue:		; Hasta agotar los ocho
	dec c			;54c5   ; hasta agotar los ocho
	jr nz,multiplica_8_vuelta		;54c6
	exx			;54c8
	ret			;54c9
multiplica_16:		; Lo mismo, pero con dieciseis vueltas y sumando
	exx			;54ca
	ld b,010h		;54cb   ; dieciseis bits
multiplica_16_vuelta:		; Un bit de los dieciseis
	ld hl,0e0d2h		;54cd
	or a			;54d0
	rl (hl)		;54d1   ; desplaza los tres bytes del acumulador
	dec hl			;54d3
	rl (hl)		;54d4
	dec hl			;54d6
	rl (hl)		;54d7
	jr nc,multiplica_16_sigue		;54d9   ; y solo suma cuando sale un uno
	ld hl,0e0d3h		;54db   ; el sumando, empezando por el byte bajo
	ld a,(hl)			;54de
	dec hl			;54df
	add a,(hl)			;54e0
	ld (hl),a			;54e1
	dec hl			;54e2
	ld a,(hl)			;54e3
	adc a,000h		;54e4   ; y los acarreos hacia arriba
	ld (hl),a			;54e6
	dec hl			;54e7
	ld a,(hl)			;54e8
	adc a,000h		;54e9
	ld (hl),a			;54eb
multiplica_16_sigue:		; Hasta los dieciseis
	djnz multiplica_16_vuelta		;54ec   ; hasta las dieciseis
	exx			;54ee
	ret			;54ef
multiplica_y_devuelve:		; Multiplica y deja el resultado en HL
	ld (0e0d2h),hl		;54f0
	call multiplica_16		;54f3
	ld hl,(0e0d0h)		;54f6
	ret			;54f9
multiplica_y_devuelve_alto:		; Igual, pero devuelve la parte alta
	call multiplica_16		;54fa
	ld hl,(0e0d1h)		;54fd
prepara_multiplicacion:		; Coloca el multiplicando y pone el acumulador a cero
	ld (0e0d0h),hl		;5500
	ld hl,0e0d2h		;5503   ; 0xE0D2 empieza siempre limpio
	ld (hl),000h		;5506
	inc hl			;5508
	ret			;5509

; ----------------------------------------------------------------------
; DATOS datos_550a: Ocho bytes que lee 0x753B
;   0x550a..0x5512  (8 bytes)
DATA_datos_550a:
	defb 020h,080h,07ch,001h,020h,080h,000h,00fh	; 550a   .|. ...

; ----------------------------------------------------------------------
; DATOS tabla_de_dificultad: Un valor por opcion de menu, que lee la
;   interrupcion en 0x4065
;   0x5512..0x5516  (4 bytes)
DATA_5512:
	defb 000h,003h,002h,002h	; 5512

; ----------------------------------------------------------------------
; DATOS datos_5516: Dieciocho bytes que lee 0x5492
;   0x5516..0x5528  (18 bytes)
DATA_datos_5516:
	defb 002h,001h,003h,001h,006h,001h,006h,000h,006h,0ffh,003h,0ffh,002h,0ffh,002h,0feh,002h,002h	; 5516  ..................

; ----------------------------------------------------------------------
; DATOS tabla_de_la_pelota: Cinco pares de punteros: la pelota crece con la
;   altura
;   0x5528..0x553c  (20 bytes)
DATA_tabla_de_la_pelota:
	defb 03ch,055h,045h,055h	; 5528
	defb 045h,055h,04dh,055h	; 552c
	defb 04dh,055h,04dh,055h	; 5530
	defb 053h,055h,053h,055h	; 5534
	defb 059h,055h,059h,055h	; 5538

; ----------------------------------------------------------------------
; DATOS patrones_de_la_pelota: Los cinco tamanos, comprimidos para 0x5932
;   0x553c..0x555d  (33 bytes)
DATA_patrones_de_la_pelota:
	defb 038h,07ch,0feh,0feh,0feh,07ch,038h,000h,019h,018h,03ch,07eh,07eh,03ch,018h,000h	; 553c  8|...|8...<~~<..
	defb 01ah,018h,03ch,03ch,018h,000h,01ch,008h,01ch,01ch,008h,000h,01ch,018h,018h,000h	; 554c  ..<<............
	defb 01eh	; 555c

; ======================================================================
; CODIGO 0x555d..0x57eb  (654 bytes)
; ======================================================================


turno_de_los_jugadores:		; Le da un cuadro a cada jugador que este en la pista
	ld h,0e1h		;555d   ; las fichas viven todas en la pagina 0xE1
	call hay_dos_jugadores		;555f   ; con dos jugadores no hay pareja que mover
	jr z,turno_del_segundo		;5562
	ld a,(0e000h)		;5564   ; el contador de cuadros reparte el trabajo
	ld l,060h		;5567   ; 0xE160 es el tercero
	and 003h		;5569   ; uno de cada cuatro cuadros
	ld c,a			;556b
	call mueve_un_jugador		;556c
	call hay_dobles		;556f   ; y el cuarto solo existe en dobles
	jr nz,turno_del_segundo		;5572
	dec c			;5574
	ld l,090h		;5575   ; 0xE190
	call mueve_un_jugador		;5577
turno_del_segundo:		; Al segundo le toca en otro cuadro
	ld a,(0e000h)		;557a   ; el segundo va en otro cuadro distinto
	and 003h		;557d
	ld c,a			;557f
	dec c			;5580
	dec c			;5581
	ld l,000h		;5582   ; 0xE100, el primero
	call mueve_un_jugador		;5584
	ld a,(0e00eh)		;5587   ; 0xE00E dice cuantos jugadores hay
	dec a			;558a   ; con uno solo, aqui se acaba
	ret z			;558b
	ld l,030h		;558c   ; 0xE130, el segundo
	dec c			;558e
mueve_un_jugador:		; Un cuadro de un jugador: decide, anda y golpea
	push hl			;558f
	push bc			;5590
	push hl			;5591
	pop ix		;5592   ; IX es la ficha, y asi se queda hasta el final
	jr nz,jugador_solo_mueve		;5594   ; si le toca a este, va por el camino largo
	call piensa_y_mueve		;5596   ; pensar, andar y pegarle a la pelota
	push ix		;5599
	pop hl			;559b
	call mueve_y_dibuja		;559c   ; y dibujarlo
	pop bc			;559f
	pop hl			;55a0
	ret			;55a1
jugador_solo_mueve:		; Se mueve sin recargarle la postura
	ld a,(hl)			;55a2   ; los dos bits de arriba son hacia donde mira
	and 0c0h		;55a3
	push af			;55a5
	call anda		;55a6   ; mueve sin redibujar
	pop af			;55a9
	ld b,a			;55aa
	ld a,(ix+000h)		;55ab   ; conserva los bits de estado y le pone la cara nueva
	and 03bh		;55ae
	or b			;55b0
	ld (ix+000h),a		;55b1
	push ix		;55b4
	pop hl			;55b6
	call coloca_los_sprites		;55b7   ; y coloca sus cinco sprites
	pop bc			;55ba
	pop hl			;55bb
	ret			;55bc
piensa_y_mueve:		; Las cuatro cosas que hace un jugador en un cuadro
	call anda		;55bd   ; andar
	call pasa_de_cuadro		;55c0   ; cambiar de cuadro de animacion
	call elige_el_dibujo		;55c3   ; elegir el dibujo
	jp golpea		;55c6   ; y pegarle si toca
anda:		; Lee el mando -o la maquina- y adelanta al jugador
	push ix		;55c9
	pop hl			;55cb
	bit 0,(hl)		;55cc   ; el bit 0 marca al jugador que esta parado
	jr nz,quien_lo_lleva		;55ce
	call lo_lleva_la_maquina		;55d0   ; con dos jugadores, el segundo lo lleva la maquina
	jr nz,quien_lo_lleva		;55d3
	ld a,(hl)			;55d5
	and 03fh		;55d6   ; se le quitan los bits de direccion
	ld (hl),a			;55d8
quien_lo_lleva:		; Decide si el mando o la maquina
	call lo_lleva_la_maquina		;55d9   ; y aqui se decide quien manda sobre este
	jr z,direccion_pedida		;55dc
	ld a,(0e0a8h)		;55de   ; 0xE0A8 congela a todos mientras dura una jugada
	or a			;55e1
	ret nz			;55e2
direccion_pedida:		; Los cuatro bits de abajo del byte 7
	ld a,(ix+007h)		;55e3   ; el byte 7 de la ficha trae lo que se ha pedido
	and 00fh		;55e6   ; los cuatro bits de abajo son la direccion
	ret z			;55e8   ; si no hay direccion, no anda
	cp 00fh		;55e9   ; y 0x0F es la combinacion imposible
	ret z			;55eb
	inc hl			;55ec
	inc hl			;55ed
	ld b,a			;55ee
	ld a,(0e060h)		;55ef   ; 0xE060 congela la pista durante un aviso
	or a			;55f2
	ld a,b			;55f3
	jr nz,calcula_el_paso		;55f4
	call lo_lleva_la_maquina		;55f6
	jr nz,salta_los_bits		;55f9
calcula_el_paso:		; Saca el paso de la direccion pedida
	push hl			;55fb
	push af			;55fc
	call solo_direccion		;55fd   ; calcula el paso
	push af			;5600
	ld a,(ix+000h)		;5601   ; y le limpia los bits de cara
	and 03fh		;5604
	ld (ix+000h),a		;5606
	pop af			;5609
	pop af			;560a
	pop hl			;560b
salta_los_bits:		; Se queda con los dos de la cara
	inc hl			;560c
	rrca			;560d
	rrca			;560e
solo_direccion:		; Se queda con los dos bits que dicen izquierda o derecha
	and 003h		;560f
	jr paso_lateral		;5611
paso_lateral:		; Mueve al jugador un pixel a un lado y le pone la cara
	or a			;5613
	ret z			;5614   ; sin direccion no hay paso
	ld c,001h		;5615   ; a la derecha, uno mas
	ld d,040h		;5617   ; y mirando a la derecha
	rrca			;5619   ; el otro bit es el otro lado
	jr nc,pon_la_cara		;561a
	ld d,080h		;561c   ; mirando a la izquierda
	ld c,0ffh		;561e   ; y un pixel menos
pon_la_cara:		; Conserva el estado y le pone hacia donde mira
	ld a,03fh		;5620   ; conserva el estado y le pone la cara
	and (ix+000h)		;5622
	or d			;5625
	ld (ix+000h),a		;5626
	ld b,c			;5629
	ld a,(hl)			;562a   ; la posicion nueva
	add a,c			;562b
	ld c,a			;562c
	push hl			;562d
	ld a,006h		;562e   ; el byte 6 de la ficha trae los topes por donde no puede pasar
	call suma_a_hl		;5630
	ld d,(hl)			;5633
	inc hl			;5634
	inc hl			;5635
	ld e,(hl)			;5636
	pop hl			;5637
	call lo_lleva_la_maquina		;5638   ; si es humano, se le deja mas sitio
	jr z,comprueba_los_topes		;563b
	ld a,(0e060h)		;563d
	or a			;5640
	jr nz,comprueba_los_topes		;5641
	ld a,(ix+000h)		;5643   ; la mitad de la pista decide el limite
	and 03fh		;5646
	push bc			;5648
	ld b,a			;5649
	ld a,(ix+002h)		;564a
	cp 050h		;564d   ; 0x50 es la altura de la red
	ld a,040h		;564f
	jr nc,limite_por_la_red		;5651
	ld a,080h		;5653
limite_por_la_red:		; El tope cambia segun de que lado de la red este
	or b			;5655
	ld (ix+000h),a		;5656
	pop bc			;5659
	ld a,068h		;565a   ; 0x68 y 0x79 son dos columnas donde no se puede estar
	cp c			;565c
	ret z			;565d
	ld a,079h		;565e
	cp c			;5660
	ret z			;5661
	push de			;5662
	ld a,(ix+002h)		;5663
	ld de,030b0h		;5666   ; y estos otros dos topes van segun de que lado este
	cp 070h		;5669
	jr nc,compara_los_topes		;566b
	ld de,0449ch		;566d
compara_los_topes:		; Contra los dos que le tocan
	ld a,c			;5670
	cp d			;5671
	jr z,topes_iguales		;5672
	cp e			;5674
topes_iguales:		; Si coincide con alguno, no se mueve
	pop de			;5675
	ret z			;5676
comprueba_los_topes:		; Por un lado y por el otro
	ld a,d			;5677   ; si se sale por un lado, no se mueve
	sub c			;5678
	ret c			;5679
	ld a,e			;567a   ; ni por el otro
	sub c			;567b
	ret nc			;567c
	call hay_dobles		;567d   ; en dobles hay que mirar tambien a la pareja
	jr nz,apunta_el_paso		;5680
	ld a,(0e060h)		;5682
	or a			;5685
	jr nz,apunta_el_paso		;5686
	ld a,030h		;5688   ; el companero puede estar delante o detras
	bit 4,l		;568a
	jr z,mira_al_companero		;568c
	ld a,0d0h		;568e
mira_al_companero:		; Saca la posicion del otro de su ficha
	push de			;5690   ; se guarda todo, que hacen falta los tres pares
	push bc			;5691
	push hl			;5692
	push hl			;5693
	add a,l			;5694   ; saca su posicion de la ficha del otro
	ld l,a			;5695
	res 0,l		;5696   ; la ficha de la pareja empieza en direccion par
	ld e,(hl)			;5698   ; su fila y su columna
	inc hl			;5699
	ld d,(hl)			;569a
	pop hl			;569b
	bit 0,l		;569c
	jr nz,companero_delante		;569e
	inc hl			;56a0
	ld b,(hl)			;56a1
	jr margen_de_la_figura		;56a2
companero_delante:		; El companero va delante
	ld b,c			;56a4
	dec hl			;56a5
	ld c,(hl)			;56a6
margen_de_la_figura:		; Dieciseis por lado, que es lo que ocupa
	ld a,d			;56a7   ; dieciseis de margen por cada lado: lo que ocupa una figura
	add a,010h		;56a8
	ld d,a			;56aa
	ld a,b			;56ab
	add a,010h		;56ac
	ld b,a			;56ae
	ld a,003h		;56af   ; comprueba si chocan
	call hay_contacto		;56b1
	pop hl			;56b4
	pop bc			;56b5
	pop de			;56b6
	ret c			;56b7   ; y si chocan, no se mueve
apunta_el_paso:		; Guarda la posicion nueva y arrastra la pelota
	set 2,(ix+000h)		;56b8   ; el bit 2 marca que este cuadro se ha movido
	ld (hl),c			;56bc   ; guarda la posicion nueva
	call lo_lleva_la_maquina		;56bd
	ret z			;56c0
	ld a,(0e060h)		;56c1
	or a			;56c4
	ret nz			;56c5
	ld hl,0e0b8h		;56c6   ; 0xE0B8 es la pelota, que se arrastra con el jugador que la lleva
	ld a,(hl)			;56c9
	add a,b			;56ca
	ld (hl),a			;56cb
	ld hl,0e0bch		;56cc   ; y 0xE0BC su sombra
	ld a,(hl)			;56cf
	add a,b			;56d0
	ld (hl),a			;56d1
	ret			;56d2
pasa_de_cuadro:		; Alterna la pierna cada pocos cuadros, para que ande
	push ix		;56d3
	pop hl			;56d5
	bit 0,(hl)		;56d6   ; el jugador parado no anima
	ret nz			;56d8
	ld a,(hl)			;56d9
	and 0c0h		;56da   ; si esta mirando a un lado, siempre anima
	jr nz,anima_si_se_movio		;56dc
	bit 2,(hl)		;56de   ; y si se movio en este cuadro, tambien
	jr nz,anima_si_se_movio		;56e0
	ld a,(0e000h)		;56e2   ; si no, uno de cada ocho cuadros
	and 01ch		;56e5
	jr z,pierna_siguiente		;56e7
anima_si_se_movio:		; Solo cambia de pierna si hubo paso
	bit 2,(hl)		;56e9
	ret z			;56eb
pierna_siguiente:		; El bit 0 del byte 4 alterna
	inc hl			;56ec
	inc hl			;56ed
	inc hl			;56ee
	inc hl			;56ef
	bit 0,(hl)		;56f0   ; y el bit 0 del byte 4 va cambiando: una pierna y la otra
	jr nz,pierna_anterior		;56f2
	set 0,(hl)		;56f4
	ret			;56f6
pierna_anterior:		; Y vuelve
	res 0,(hl)		;56f7
	ret			;56f9
elige_el_dibujo:		; Compone el numero de postura con lo que el jugador esta haciendo
	push ix		;56fa
	pop hl			;56fc
	bit 0,(hl)		;56fd   ; el parado no cambia de dibujo
	ret nz			;56ff
	ld a,(hl)			;5700
	and 0c0h		;5701   ; los dos bits de la cara
	ld c,a			;5703
	inc hl			;5704
	inc hl			;5705
	inc hl			;5706
	inc hl			;5707
	ld a,(hl)			;5708   ; el byte 4 es el numero de postura
	push af			;5709
	and 0e0h		;570a   ; se conservan los tres bits de arriba
	ld e,a			;570c
	pop af			;570d
	set 1,a		;570e   ; y se le meten los que dicen que esta andando
	set 3,a		;5710
	ld b,000h		;5712
	jr z,junta_la_postura		;5714
	ld b,002h		;5716   ; mirando a un lado
	sla c		;5718   ; y si son los dos bits, mirando de frente
	jr nc,junta_la_postura		;571a
	ld b,008h		;571c
junta_la_postura:		; El bit de la pierna con los de la cara
	ld a,(hl)			;571e
	and 001h		;571f   ; el bit 0 es la pierna
	or e			;5721
	ld e,a			;5722
	ld a,b			;5723
	or e			;5724
	ld (hl),a			;5725   ; y a la ficha
	ret			;5726
golpea:		; Prepara el golpe cuando el jugador aprieta el boton
	ld a,(0e060h)		;5727   ; 0xE060 congela durante un aviso
	or a			;572a
	jr nz,golpe_en_marcha		;572b
	ld a,(0e0a8h)		;572d   ; 0xE0A8 dice que hay una jugada en marcha
	or a			;5730
	ret z			;5731
golpe_en_marcha:		; El que ya esta golpeando va por otro lado
	push ix		;5732
	pop hl			;5734
	bit 0,(hl)		;5735   ; el parado esta en medio de un golpe
	jr nz,cuenta_atras_del_golpe		;5737
	ld a,(ix+007h)		;5739   ; los cuatro bits de arriba del byte 7 son el disparo
	and 0f0h		;573c
	jr nz,empieza_el_golpe		;573e
	res 1,(hl)		;5740   ; sin disparo, se le quita la marca
	ret			;5742
empieza_el_golpe:		; Deja el estado en 7 y elige la fuerza
	bit 1,(hl)		;5743   ; y si ya estaba golpeando, no se repite
	ret nz			;5745
	res 7,(ix+00ch)		;5746   ; el bit 7 del byte 12 se apaga al empezar el golpe
	ld a,(hl)			;574a
	and 03fh		;574b
	or 007h		;574d   ; deja el estado en 7: golpeando
	ld (hl),a			;574f
	inc hl			;5750
	inc hl			;5751
	inc hl			;5752
	ld b,(hl)			;5753   ; el byte 3 es la columna del jugador
	ld a,(0e0b8h)		;5754   ; 0xE0B8 es donde esta la pelota
	cp 050h		;5757   ; 0x50 y 0xA0 parten la pista en tres
	jr c,golpe_largo		;5759
	cp 0a0h		;575b
	jr nc,golpe_corto		;575d
	add a,0f5h		;575f
	cp b			;5761
golpe_corto:		; Dos cuadros y catorce de fuerza
	ld bc,00e02h		;5762   ; golpe corto: dos cuadros y catorce de fuerza
	ld e,040h		;5765
	jr nc,guarda_la_fuerza		;5767
golpe_largo:		; Ocho cuadros y veinte
	ld bc,01408h		;5769   ; golpe largo: ocho cuadros y veinte de fuerza
	ld e,080h		;576c
guarda_la_fuerza:		; El bit de direccion con el estado
	ld a,e			;576e   ; y el bit de la direccion del golpe
	or (ix+000h)		;576f
	ld (ix+000h),a		;5772
	inc hl			;5775
	ex de,hl			;5776
	push ix		;5777
	pop hl			;5779
	bit 3,(hl)		;577a   ; el bit 3 marca al que saca
	jr z,golpe_de_la_maquina		;577c
	ld c,b			;577e
golpe_de_la_maquina:		; A la maquina se le da otro angulo
	call lo_lleva_la_maquina		;577f   ; otra vez, humano o maquina
	push af			;5782
	jr z,cierra_el_golpe		;5783
	inc hl			;5785
	ld (hl),008h		;5786   ; la maquina tarda ocho cuadros en soltar
	dec hl			;5788
	ld c,010h		;5789   ; y le sale con mas o menos angulo
	ld a,(ix+002h)		;578b
	cp 050h		;578e   ; segun de que lado de la red este
	jr nc,cierra_el_golpe		;5790
	ld c,016h		;5792
cierra_el_golpe:		; Deja el angulo en su sitio
	pop af			;5794
	set 2,(hl)		;5795   ; el bit 2: ya ha golpeado
	ex de,hl			;5797
	ld a,(hl)			;5798   ; y el angulo se mete en el byte que toca
	and 0e0h		;5799
	or c			;579b
	ld (hl),a			;579c
	ret			;579d
cuenta_atras_del_golpe:		; Va gastando los cuadros que dura el golpe
	inc hl			;579e
	dec (hl)			;579f   ; un cuadro menos
	jr z,acaba_el_golpe		;57a0
	ld a,004h		;57a2   ; los cuatro ultimos son los del impacto
	cp (hl)			;57a4
	ret nc			;57a5
	inc (ix+004h)		;57a6   ; y el dibujo avanza con ellos
	ret			;57a9
acaba_el_golpe:		; Devuelve al jugador a su postura de espera
	res 7,(ix+00ch)		;57aa   ; apaga el bit 7 del byte 12
	dec hl			;57ae
	ld a,(hl)			;57af
	and 03eh		;57b0   ; le quita los bits del golpe
	ld (hl),a			;57b2
	inc hl			;57b3
	ld (hl),00ah		;57b4   ; diez cuadros de descanso
	inc hl			;57b6
	inc hl			;57b7
	inc hl			;57b8
	ld a,(hl)			;57b9
	and 0e0h		;57ba   ; y le deja la postura limpia
	ld (hl),a			;57bc
	ret			;57bd
reparte_las_fichas:		; Copia las cuatro fichas de salida a la RAM
	ld de,0e100h		;57be   ; la primera ficha va a 0xE100
	ld hl,057ebh		;57c1   ; y las cuatro salen de la tabla de 0x57EB
	ld b,004h		;57c4   ; cuatro jugadores
fichas_bucle:		; Una ficha de 41 bytes por vuelta
	push bc			;57c6
	ld bc,00029h		;57c7   ; 41 bytes cada uno
	ldir		;57ca
	ld a,e			;57cc   ; la siguiente ficha empieza en la decena redonda de despues
	and 0f0h		;57cd
	add a,010h		;57cf
	ld e,a			;57d1
	pop bc			;57d2
	djnz fichas_bucle		;57d3
	call hay_dos_jugadores		;57d5   ; si no son dobles, sobran dos jugadores
	jr nz,fichas_fin		;57d8
	ld de,0e130h		;57da   ; asi que el tercero se copia encima del segundo
	ld hl,0e160h		;57dd
	ld bc,00030h		;57e0
	ldir		;57e3
	ld hl,0e130h		;57e5
	ld (hl),004h		;57e8   ; y al segundo se le pone el estado 4
fichas_fin:		; Con dobles no sobra ninguna
	ret			;57ea

; ----------------------------------------------------------------------
; DATOS fichas_de_los_jugadores: Cuatro fichas de 41 bytes, una por jugador
;   0x57eb..0x588f  (164 bytes)
DATA_fichas_de_los_jugadores:
	defb 004h,00ah,070h,050h,000h,000h,000h,000h,0a8h,0ceh,04ah,010h,000h,000h,000h,000h,0cfh,000h,004h,001h,0cfh,000h,008h,00bh,0cfh,000h,00ch,001h,0cfh,000h,010h,00fh,0cfh,000h,014h,00bh,0cfh,020h,058h,004h,07bh	; 57eb  ..pP......J.......................... X.{
	defb 014h,00ah,090h,0a0h,000h,000h,000h,000h,0a8h,0ceh,04ah,010h,000h,000h,000h,000h,0cfh,000h,018h,001h,0cfh,000h,01ch,00bh,0cfh,000h,020h,001h,0cfh,000h,024h,007h,0cfh,000h,028h,00bh,0cfh,0c0h,058h,018h,07bh	; 5814  ..........J............... ...$...(...X.{
	defb 034h,00ah,018h,058h,020h,000h,000h,000h,038h,0b8h,002h,038h,000h,000h,000h,000h,0cfh,000h,04ch,00dh,0cfh,000h,050h,00bh,0cfh,000h,054h,001h,0cfh,000h,058h,009h,0cfh,000h,05ch,00bh,0cfh,060h,05ah,04ch,07bh	; 583d  4..X ...8..8......L...P...T...X...\..`ZL{
	defb 024h,00ah,030h,098h,020h,000h,000h,000h,038h,0b8h,002h,038h,000h,000h,000h,000h,0cfh,000h,060h,00dh,0cfh,000h,064h,00bh,0cfh,000h,068h,001h,0cfh,000h,06ch,00fh,0cfh,000h,070h,00bh,0cfh,000h,05bh,060h,07bh	; 5866  $.0. ...8..8......`...d...h...l...p...[`{

; ======================================================================
; CODIGO 0x588f..0x5961  (210 bytes)
; ======================================================================


lo_lleva_la_maquina:		; El bit 0 del byte 12 de la ficha separa al humano del rival
	bit 0,(ix+00ch)		;588f
	ret			;5893
hay_dos_jugadores:		; Compara 0xE00E con 2
	ld a,(0e00eh)		;5894
	cp 002h		;5897
	ret			;5899
hay_dobles:		; Compara 0xE00E con 3
	ld a,(0e00eh)		;589a
	cp 003h		;589d
	ret			;589f
mueve_y_dibuja:		; Coloca la figura y le pone sus cinco sprites
	push hl			;58a0
	call carga_la_postura		;58a1
	pop hl			;58a4
	call coloca_los_sprites		;58a5
	ret			;58a8
carga_la_postura:		; Descomprime en la VRAM los cinco sprites de la postura
	push hl			;58a9
	pop ix		;58aa   ; IX es la ficha
	ld e,(ix+025h)		;58ac   ; los bytes 0x25 y 0x26 dicen a que parte de la VRAM van
	ld d,(ix+026h)		;58af
	ld a,(ix+004h)		;58b2   ; el byte 4 es el numero de postura
	rlca			;58b5   ; dos bytes por entrada de la tabla
	call busca_en_tabla		;58b6   ; y de ahi sale la descripcion de doce bytes
	ld b,005h		;58b9   ; CINCO sprites: una figura son cinco capas
capa_de_la_postura:		; Una de las cinco, descomprimida en la VRAM
	push bc			;58bb
	push hl			;58bc
	ld a,(hl)			;58bd   ; cada puntero apunta a un patron comprimido
	inc hl			;58be
	ld h,(hl)			;58bf
	ld l,a			;58c0
	call descomprime_sprite		;58c1   ; 32 bytes por capa
	ld hl,00020h		;58c4   ; la siguiente capa va 32 bytes mas alla en la VRAM
	add hl,de			;58c7
	ex de,hl			;58c8
	pop hl			;58c9
	inc hl			;58ca   ; y el puntero siguiente, dos bytes mas alla
	inc hl			;58cb
	pop bc			;58cc
	djnz capa_de_la_postura		;58cd
	res 2,(ix+000h)		;58cf   ; el bit 2 se apaga: ya esta cargada
	ret			;58d3
coloca_los_sprites:		; Suma la posicion del jugador a las cinco parejas (y,x)
	push hl			;58d4
	pop ix		;58d5
	ld a,(ix+004h)		;58d7   ; el byte 4 otra vez, la postura
	rlca			;58da
	call busca_en_tabla		;58db   ; la misma descripcion de doce bytes
	ld a,00ah		;58de   ; y se salta los cinco punteros para llegar al sexto
	call suma_a_hl		;58e0
	ld e,(hl)			;58e3   ; que apunta a las cinco parejas
	inc hl			;58e4
	ld d,(hl)			;58e5
	push ix		;58e6
	pop hl			;58e8
	ld bc,00010h		;58e9   ; los atributos empiezan en el byte 0x10 de la ficha
	add hl,bc			;58ec
	push hl			;58ed
	exx			;58ee
	ld b,005h		;58ef   ; cinco sprites
	exx			;58f1
	ld b,(ix+002h)		;58f2   ; los bytes 2 y 3 son la fila y la columna del jugador
	ld c,(ix+003h)		;58f5
	exx			;58f8
sprite_escondido:		; El 0xCF no lleva suma
	exx			;58f9
	ld a,(de)			;58fa   ; la y de la pareja
	cp 0cfh		;58fb   ; un 0xCF la esconde, y entonces no se le suma nada
	jr z,guarda_la_y		;58fd
	add a,b			;58ff   ; y si no, se le suma la del jugador
guarda_la_y:		; Y ahora la x, que si se suma siempre
	ld (hl),a			;5900
	inc hl			;5901
	inc de			;5902
	ld a,(de)			;5903
	add a,c			;5904   ; y lo mismo con la x
	ld (hl),a			;5905
	inc de			;5906
	inc hl			;5907
	inc hl			;5908
	inc hl			;5909   ; cuatro bytes por sprite: y, x, patron y color
	exx			;590a
	djnz sprite_escondido		;590b
	exx			;590d
	pop hl			;590e
vuelca_los_atributos:		; Los veinte bytes al VDP
	ld e,(ix+027h)		;590f   ; los bytes 0x27 y 0x28 dicen donde van los atributos
	ld d,(ix+028h)		;5912
	push ix		;5915
	pop hl			;5917
	ld a,010h		;5918   ; los veinte bytes empiezan en el 0x10
	call suma_a_hl		;591a
	call pon_escritura_con_reintento		;591d
	ld e,005h		;5920   ; cinco sprites
	ld a,(00007h)		;5922
	ld c,a			;5925
atributos_sprite:		; Cuatro bytes por sprite
	ld b,004h		;5926   ; de cuatro bytes cada uno
atributos_byte:		; Byte a byte, al puerto de datos
	ld a,(hl)			;5928   ; cuatro bytes por sprite
	inc hl			;5929
	out (c),a		;592a   ; directos al puerto de datos
	djnz atributos_byte		;592c
	dec e			;592e
	jr nz,atributos_sprite		;592f
	ret			;5931
descomprime_sprite:		; Deja en la VRAM los 32 bytes de un sprite de 16x16
	push de			;5932
	push bc			;5933
	call pon_escritura_con_reintento		;5934   ; coloca el puntero de escritura
	ld a,(00007h)		;5937   ; el puerto de datos del VDP
	ld c,a			;593a
	ld e,020h		;593b   ; 32 bytes, siempre
byte_comprimido:		; Un cero es la orden de repetir
	ld a,(hl)			;593d   ; un cero es la orden de repetir
	or a			;593e
	jr nz,suelta_byte		;593f
	inc e			;5941   ; el inc compensa el dec de la vuelta
	inc hl			;5942
	ld b,(hl)			;5943   ; cuantos ceros; un 0 aqui vale 256
suelta_ceros:		; Los ceros que diga la cuenta
	out (c),a		;5944
	dec e			;5946
	jr z,descomprime_fin		;5947   ; si se llega al final, se acabo
	djnz suelta_ceros		;5949
	inc hl			;594b
	jr descomprime_sigue		;594c
suelta_byte:		; Y si no, el byte tal cual
	outi		;594e   ; y si no era cero, el byte va tal cual
descomprime_sigue:		; Hasta los 32
	dec e			;5950
	jr nz,byte_comprimido		;5951
descomprime_fin:		; Devuelve lo guardado
	pop bc			;5953
	pop de			;5954
	ret			;5955
busca_en_tabla:		; HL = la palabra que hay en la tabla, indexada por A
	ld hl,05961h		;5956
busca_en_tabla_desde:		; Entra en la busqueda con la tabla ya puesta en HL
	call suma_a_hl		;5959   ; dos bytes por entrada, que el que llama ya ha doblado
	ld a,(hl)			;595c   ; y de la tabla sale un puntero, en little endian
	inc hl			;595d
	ld h,(hl)			;595e
	ld l,a			;595f
	ret			;5960

; ----------------------------------------------------------------------
; DATOS tabla_de_posturas: 58 punteros a descripcion; los indices 26 a 31
;   estan a cero
;   0x5961..0x59d5  (116 bytes)
DATA_tabla_de_posturas:
	defw 059d5h,059e1h,059edh,059f9h,05a05h,05a11h,05a1dh,05a1dh	; 5961
	defw 05a29h,05a35h,05a29h,05a41h,05a4dh,05a59h,059edh,059edh	; 5971
	defw 05a65h,05a65h,05a65h,05a71h,05a29h,05a29h,05a29h,05a7dh	; 5981
	defw 05a89h,05a95h,00000h,00000h,00000h,00000h,00000h,00000h	; 5991
	defw 05aa1h,05aadh,05af5h,05b01h,05b0dh,05b19h,05b25h,05b31h	; 59a1
	defw 05ab9h,05ad1h,05ac5h,05ad1h,05addh,05ae9h,05af5h,05af5h	; 59b1
	defw 05b6dh,05b79h,05b85h,05b31h,05ab9h,05ab9h,05b3dh,05b49h	; 59c1
	defw 05b55h,05b61h	; 59d1  -> DATA_descripcion_5b55 DATA_descripcion_5b61

; ----------------------------------------------------------------------
; DATOS descripcion_59d5: Cinco punteros a patron y uno a las parejas (y,x)
;   0x59d5..0x59e1  (12 bytes)
DATA_descripcion_59d5:
	defw 05b91h,05b9bh,05bb1h,05bbdh,05bdbh,05be2h	; 59d5

; ----------------------------------------------------------------------
; DATOS descripcion_59e1: Cinco punteros a patron y uno a las parejas (y,x)
;   0x59e1..0x59ed  (12 bytes)
DATA_descripcion_59e1:
	defw 05b91h,05b9bh,05bb1h,05bech,05c06h,05c0dh	; 59e1

; ----------------------------------------------------------------------
; DATOS descripcion_59ed: Cinco punteros a patron y uno a las parejas (y,x)
;   0x59ed..0x59f9  (12 bytes)
DATA_descripcion_59ed:
	defw 05c17h,05c24h,05c3eh,05c4bh,05c67h,05c79h	; 59ed

; ----------------------------------------------------------------------
; DATOS descripcion_59f9: Cinco punteros a patron y uno a las parejas (y,x)
;   0x59f9..0x5a05  (12 bytes)
DATA_descripcion_59f9:
	defw 05c17h,05c24h,05c3eh,05c83h,05ca1h,05caeh	; 59f9

; ----------------------------------------------------------------------
; DATOS descripcion_5a05: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a05..0x5a11  (12 bytes)
DATA_descripcion_5a05:
	defw 05c17h,05cb8h,064c1h,05cdah,05cf2h,05d03h	; 5a05

; ----------------------------------------------------------------------
; DATOS descripcion_5a11: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a11..0x5a1d  (12 bytes)
DATA_descripcion_5a11:
	defw 05d0dh,05d1ah,05d36h,05d49h,05d5ch,05d69h	; 5a11

; ----------------------------------------------------------------------
; DATOS descripcion_5a1d: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a1d..0x5a29  (12 bytes)
DATA_descripcion_5a1d:
	defw 05d73h,05d7fh,05d92h,05d9dh,05db8h,05dc7h	; 5a1d

; ----------------------------------------------------------------------
; DATOS descripcion_5a29: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a29..0x5a35  (12 bytes)
DATA_descripcion_5a29:
	defw 05dd1h,05ddeh,05df1h,05e07h,05e1dh,05e2bh	; 5a29

; ----------------------------------------------------------------------
; DATOS descripcion_5a35: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a35..0x5a41  (12 bytes)
DATA_descripcion_5a35:
	defw 05dd1h,05ddeh,05df1h,05e35h,05e4fh,05e56h	; 5a35

; ----------------------------------------------------------------------
; DATOS descripcion_5a41: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a41..0x5a4d  (12 bytes)
DATA_descripcion_5a41:
	defw 05e60h,05e6dh,05e84h,05e94h,05eb0h,05ebfh	; 5a41

; ----------------------------------------------------------------------
; DATOS descripcion_5a4d: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a4d..0x5a59  (12 bytes)
DATA_descripcion_5a4d:
	defw 05e60h,05ec9h,05edeh,05eedh,05f05h,05f0ch	; 5a4d

; ----------------------------------------------------------------------
; DATOS descripcion_5a59: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a59..0x5a65  (12 bytes)
DATA_descripcion_5a59:
	defw 05f16h,05f23h,05f3dh,05f4dh,05f65h,05f6dh	; 5a59

; ----------------------------------------------------------------------
; DATOS descripcion_5a65: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a65..0x5a71  (12 bytes)
DATA_descripcion_5a65:
	defw 05f77h,05f83h,05fa0h,05fb3h,05fc6h,05fd4h	; 5a65

; ----------------------------------------------------------------------
; DATOS descripcion_5a71: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a71..0x5a7d  (12 bytes)
DATA_descripcion_5a71:
	defw 05fdeh,05feah,05ff8h,06004h,0601bh,06027h	; 5a71

; ----------------------------------------------------------------------
; DATOS descripcion_5a7d: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a7d..0x5a89  (12 bytes)
DATA_descripcion_5a7d:
	defw 06031h,0603ch,06053h,0605eh,06070h,06078h	; 5a7d

; ----------------------------------------------------------------------
; DATOS descripcion_5a89: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a89..0x5a95  (12 bytes)
DATA_descripcion_5a89:
	defw 06082h,0608ch,060a1h,060b3h,060c6h,060ceh	; 5a89

; ----------------------------------------------------------------------
; DATOS descripcion_5a95: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5a95..0x5aa1  (12 bytes)
DATA_descripcion_5a95:
	defw 060d8h,060e2h,060f8h,06104h,0611ch,06127h	; 5a95

; ----------------------------------------------------------------------
; DATOS descripcion_5aa1: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5aa1..0x5aad  (12 bytes)
DATA_descripcion_5aa1:
	defw 06131h,06143h,06168h,06173h,06187h,0618eh	; 5aa1

; ----------------------------------------------------------------------
; DATOS descripcion_5aad: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5aad..0x5ab9  (12 bytes)
DATA_descripcion_5aad:
	defw 06131h,06143h,06168h,06198h,061b7h,061beh	; 5aad

; ----------------------------------------------------------------------
; DATOS descripcion_5ab9: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5ab9..0x5ac5  (12 bytes)
DATA_descripcion_5ab9:
	defw 061c8h,061dah,05c3eh,061feh,06219h,06225h	; 5ab9

; ----------------------------------------------------------------------
; DATOS descripcion_5ac5: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5ac5..0x5ad1  (12 bytes)
DATA_descripcion_5ac5:
	defw 0622fh,0623bh,05edeh,0625dh,06272h,06280h	; 5ac5

; ----------------------------------------------------------------------
; DATOS descripcion_5ad1: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5ad1..0x5add  (12 bytes)
DATA_descripcion_5ad1:
	defw 061c8h,0628ah,05c3eh,0629fh,062b2h,062b9h	; 5ad1

; ----------------------------------------------------------------------
; DATOS descripcion_5add: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5add..0x5ae9  (12 bytes)
DATA_descripcion_5add:
	defw 062c3h,062ceh,062ech,062fah,0630ch,06318h	; 5add

; ----------------------------------------------------------------------
; DATOS descripcion_5ae9: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5ae9..0x5af5  (12 bytes)
DATA_descripcion_5ae9:
	defw 0622fh,06322h,06339h,06343h,06358h,0635fh	; 5ae9

; ----------------------------------------------------------------------
; DATOS descripcion_5af5: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5af5..0x5b01  (12 bytes)
DATA_descripcion_5af5:
	defw 06369h,06373h,06389h,06396h,063adh,063b4h	; 5af5

; ----------------------------------------------------------------------
; DATOS descripcion_5b01: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b01..0x5b0d  (12 bytes)
DATA_descripcion_5b01:
	defw 06369h,06373h,06389h,063beh,063d3h,063dah	; 5b01

; ----------------------------------------------------------------------
; DATOS descripcion_5b0d: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b0d..0x5b19  (12 bytes)
DATA_descripcion_5b0d:
	defw 063e4h,063eeh,06405h,0640fh,06425h,06433h	; 5b0d

; ----------------------------------------------------------------------
; DATOS descripcion_5b19: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b19..0x5b25  (12 bytes)
DATA_descripcion_5b19:
	defw 0643dh,06448h,06462h,06476h,0648dh,06494h	; 5b19

; ----------------------------------------------------------------------
; DATOS descripcion_5b25: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b25..0x5b31  (12 bytes)
DATA_descripcion_5b25:
	defw 0649eh,064a9h,064c1h,064cdh,064e2h,064efh	; 5b25

; ----------------------------------------------------------------------
; DATOS descripcion_5b31: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b31..0x5b3d  (12 bytes)
DATA_descripcion_5b31:
	defw 064f9h,06509h,06526h,06534h,0654bh,06558h	; 5b31

; ----------------------------------------------------------------------
; DATOS descripcion_5b3d: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b3d..0x5b49  (12 bytes)
DATA_descripcion_5b3d:
	defw 06562h,06573h,06589h,06591h,065a0h,065a7h	; 5b3d

; ----------------------------------------------------------------------
; DATOS descripcion_5b49: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b49..0x5b55  (12 bytes)
DATA_descripcion_5b49:
	defw 065b1h,065bah,065d2h,065ddh,065f1h,065f9h	; 5b49

; ----------------------------------------------------------------------
; DATOS descripcion_5b55: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b55..0x5b61  (12 bytes)
DATA_descripcion_5b55:
	defw 06603h,0660ch,06624h,06631h,06641h,06648h	; 5b55

; ----------------------------------------------------------------------
; DATOS descripcion_5b61: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b61..0x5b6d  (12 bytes)
DATA_descripcion_5b61:
	defw 06652h,0665ch,06671h,0667bh,06692h,0669ch	; 5b61

; ----------------------------------------------------------------------
; DATOS descripcion_5b6d: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b6d..0x5b79  (12 bytes)
DATA_descripcion_5b6d:
	defw 066a6h,066b0h,066c2h,066cbh,066ddh,066e4h	; 5b6d

; ----------------------------------------------------------------------
; DATOS descripcion_5b79: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b79..0x5b85  (12 bytes)
DATA_descripcion_5b79:
	defw 066eeh,066feh,0670eh,0671ah,0672ch,06734h	; 5b79

; ----------------------------------------------------------------------
; DATOS descripcion_5b85: Cinco punteros a patron y uno a las parejas (y,x)
;   0x5b85..0x5b91  (12 bytes)
DATA_descripcion_5b85:
	defw 0673eh,06748h,0675eh,0676bh,0677ch,06783h	; 5b85

; ----------------------------------------------------------------------
; DATOS patron_5b91: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5b91..0x5b9b  (10 bytes)
DATA_patron_5b91:
	defb 000h,019h,03eh,000h,001h,07fh,07fh,07fh,07fh,03eh	; 5b91  ..>......>

; ----------------------------------------------------------------------
; DATOS patron_5b9b: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5b9b..0x5bb1  (22 bytes)
DATA_patron_5b9b:
	defb 000h,003h,003h,000h,006h,004h,00ch,01ch,01ch,00ch,000h,004h,0f8h,000h,005h,004h	; 5b9b  ................
	defb 00eh,00eh,007h,007h,003h,003h	; 5bab

; ----------------------------------------------------------------------
; DATOS patron_5bb1: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5bb1..0x5bbd  (12 bytes)
DATA_patron_5bb1:
	defb 000h,016h,003h,003h,005h,005h,005h,007h,00eh,00eh,008h,008h	; 5bb1  ............

; ----------------------------------------------------------------------
; DATOS patron_5bbd: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5bbd..0x5bdb  (30 bytes)
DATA_patron_5bbd:
	defb 03fh,03fh,03fh,03fh,03fh,03fh,07fh,07fh,0ffh,000h,002h,001h,001h,001h,01ch,01ch	; 5bbd  ??????..........
	defb 080h,000h,005h,080h,080h,0c0h,000h,002h,080h,0c0h,0c0h,0c0h,000h,001h	; 5bcd  ..............

; ----------------------------------------------------------------------
; DATOS patron_5bdb: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5bdb..0x5be2  (7 bytes)
DATA_patron_5bdb:
	defb 0feh,0fch,0f0h,0e0h,0e0h,000h,01bh	; 5bdb

; ----------------------------------------------------------------------
; DATOS parejas_5be2: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5be2..0x5bec  (10 bytes)
DATA_parejas_5be2:
	defb 0ffh,004h	; 5be2
	defb 006h,007h	; 5be4
	defb 006h,00bh	; 5be6
	defb 00fh,00bh	; 5be8
	defb 018h,00eh	; 5bea

; ----------------------------------------------------------------------
; DATOS patron_5bec: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5bec..0x5c06  (26 bytes)
DATA_patron_5bec:
	defb 03fh,03fh,03fh,03fh,03fh,03fh,07fh,07fh,0ffh,000h,002h,018h,038h,038h,033h,003h	; 5bec  ??????......883.
	defb 080h,000h,005h,080h,080h,0c0h,000h,005h,080h,080h	; 5bfc  ..........

; ----------------------------------------------------------------------
; DATOS patron_5c06: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5c06..0x5c0d  (7 bytes)
DATA_patron_5c06:
	defb 0feh,07eh,01eh,00eh,00eh,000h,01bh	; 5c06

; ----------------------------------------------------------------------
; DATOS parejas_5c0d: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5c0d..0x5c17  (10 bytes)
DATA_parejas_5c0d:
	defb 0ffh,003h	; 5c0d
	defb 006h,006h	; 5c0f
	defb 006h,00ah	; 5c11
	defb 00fh,00ah	; 5c13
	defb 018h,00ch	; 5c15

; ----------------------------------------------------------------------
; DATOS patron_5c17: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5c17..0x5c24  (13 bytes)
DATA_patron_5c17:
	defb 000h,008h,03eh,000h,001h,0ffh,0fah,0f0h,0f0h,0f0h,078h,000h,010h	; 5c17  ..>.......x..

; ----------------------------------------------------------------------
; DATOS patron_5c24: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5c24..0x5c3e  (26 bytes)
DATA_patron_5c24:
	defb 000h,003h,007h,000h,007h,047h,0efh,07fh,07eh,03ch,000h,003h,0f0h,000h,001h,050h	; 5c24  .....G..~<.....P
	defb 0f8h,0f0h,0e0h,040h,003h,00fh,00eh,00ch,000h,002h	; 5c34  ...@......

; ----------------------------------------------------------------------
; DATOS patron_5c3e: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5c3e..0x5c4b  (13 bytes)
DATA_patron_5c3e:
	defb 000h,00ah,001h,000h,00dh,0f0h,0a8h,014h,0fah,096h,052h,03eh,003h	; 5c3e  ..........R>.

; ----------------------------------------------------------------------
; DATOS patron_5c4b: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5c4b..0x5c67  (28 bytes)
DATA_patron_5c4b:
	defb 007h,001h,001h,001h,003h,007h,00fh,01fh,01fh,000h,004h,001h,081h,0f0h,080h,0c0h	; 5c4b  ................
	defb 0e0h,0e0h,0e0h,0c0h,0c0h,0e0h,0c0h,000h,005h,0e0h,000h,001h	; 5c5b  ............

; ----------------------------------------------------------------------
; DATOS patron_5c67: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5c67..0x5c79  (18 bytes)
DATA_patron_5c67:
	defb 000h,001h,00fh,01eh,01ch,038h,038h,030h,000h,009h,018h,03ch,03ch,01ch,038h,070h	; 5c67  .....880...<<.8p
	defb 000h,00ah	; 5c77

; ----------------------------------------------------------------------
; DATOS parejas_5c79: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5c79..0x5c83  (10 bytes)
DATA_parejas_5c79:
	defb 000h,00ch	; 5c79
	defb 006h,008h	; 5c7b
	defb 002h,0f9h	; 5c7d
	defb 010h,009h	; 5c7f
	defb 018h,008h	; 5c81

; ----------------------------------------------------------------------
; DATOS patron_5c83: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5c83..0x5ca1  (30 bytes)
DATA_patron_5c83:
	defb 00fh,003h,003h,003h,007h,00fh,03fh,07fh,07fh,000h,003h,003h,003h,07dh,0feh,000h	; 5c83  ......?......}..
	defb 001h,080h,0c0h,0c0h,0c0h,080h,080h,0c0h,0c0h,000h,004h,080h,080h,080h	; 5c93  ..............

; ----------------------------------------------------------------------
; DATOS patron_5ca1: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5ca1..0x5cae  (13 bytes)
DATA_patron_5ca1:
	defb 07fh,07fh,07fh,073h,0f1h,000h,00bh,080h,0c0h,0c0h,080h,000h,00ch	; 5ca1  ...s.........

; ----------------------------------------------------------------------
; DATOS parejas_5cae: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5cae..0x5cb8  (10 bytes)
DATA_parejas_5cae:
	defb 000h,00ch	; 5cae
	defb 006h,008h	; 5cb0
	defb 002h,0f9h	; 5cb2
	defb 010h,00ah	; 5cb4
	defb 019h,00bh	; 5cb6

; ----------------------------------------------------------------------
; DATOS patron_5cb8: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5cb8..0x5cda  (34 bytes)
DATA_patron_5cb8:
	defb 000h,002h,00fh,000h,002h,001h,001h,001h,000h,002h,003h,013h,033h,071h,0e0h,0c0h	; 5cb8  ............3q..
	defb 000h,002h,0e0h,000h,001h,0a0h,0f0h,0e0h,0c0h,080h,000h,001h,080h,0c0h,0e0h,0f0h	; 5cc8  ................
	defb 078h,010h	; 5cd8

; ----------------------------------------------------------------------
; DATOS patron_5cda: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5cda..0x5cf2  (24 bytes)
DATA_patron_5cda:
	defb 00fh,018h,018h,018h,01ch,01fh,01fh,03fh,07fh,000h,004h,003h,0c3h,0f0h,000h,006h	; 5cda  .......?........
	defb 080h,0c0h,080h,000h,005h,0c0h,000h,001h	; 5cea  ........

; ----------------------------------------------------------------------
; DATOS patron_5cf2: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5cf2..0x5d03  (17 bytes)
DATA_patron_5cf2:
	defb 000h,001h,07bh,079h,071h,0e3h,0e1h,040h,000h,009h,080h,0c0h,0e0h,0c0h,080h,000h	; 5cf2  ..{yq..@........
	defb 00bh	; 5d02

; ----------------------------------------------------------------------
; DATOS parejas_5d03: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5d03..0x5d0d  (10 bytes)
DATA_parejas_5d03:
	defb 000h,00ch	; 5d03
	defb 007h,009h	; 5d05
	defb 00ah,013h	; 5d07
	defb 010h,00ah	; 5d09
	defb 018h,00bh	; 5d0b

; ----------------------------------------------------------------------
; DATOS patron_5d0d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d0d..0x5d1a  (13 bytes)
DATA_patron_5d0d:
	defb 000h,008h,03eh,000h,001h,0ffh,0feh,0fch,0fch,0fch,07ch,000h,010h	; 5d0d  ..>.......|..

; ----------------------------------------------------------------------
; DATOS patron_5d1a: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d1a..0x5d36  (28 bytes)
DATA_patron_5d1a:
	defb 000h,002h,007h,000h,008h,010h,030h,070h,0e0h,0c0h,000h,002h,0f0h,000h,001h,010h	; 5d1a  ......0p........
	defb 030h,030h,020h,000h,001h,0c0h,0e0h,0e0h,0f3h,07fh,03eh,010h	; 5d2a  00 .......>.

; ----------------------------------------------------------------------
; DATOS patron_5d36: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d36..0x5d49  (19 bytes)
DATA_patron_5d36:
	defb 000h,009h,001h,006h,005h,00bh,00ch,038h,0ffh,000h,009h,0e0h,090h,0f0h,090h,0a0h	; 5d36  .......8........
	defb 0c0h,000h,001h	; 5d46

; ----------------------------------------------------------------------
; DATOS patron_5d49: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d49..0x5d5c  (19 bytes)
DATA_patron_5d49:
	defb 038h,078h,078h,078h,07ch,07eh,07fh,0ffh,000h,005h,030h,0f6h,0e7h,000h,007h,080h	; 5d49  8xxx|~....0.....
	defb 000h,007h,080h	; 5d59

; ----------------------------------------------------------------------
; DATOS patron_5d5c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d5c..0x5d69  (13 bytes)
DATA_patron_5d5c:
	defb 0feh,0efh,0e7h,0e3h,0c7h,08eh,002h,000h,00bh,080h,080h,000h,00ch	; 5d5c  .............

; ----------------------------------------------------------------------
; DATOS parejas_5d69: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5d69..0x5d73  (10 bytes)
DATA_parejas_5d69:
	defb 000h,00ch	; 5d69
	defb 007h,008h	; 5d6b
	defb 004h,018h	; 5d6d
	defb 010h,00bh	; 5d6f
	defb 018h,00ch	; 5d71

; ----------------------------------------------------------------------
; DATOS patron_5d73: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d73..0x5d7f  (12 bytes)
DATA_patron_5d73:
	defb 000h,009h,07ch,000h,001h,0feh,0feh,0feh,0feh,07eh,000h,010h	; 5d73  ..|......~..

; ----------------------------------------------------------------------
; DATOS patron_5d7f: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d7f..0x5d92  (19 bytes)
DATA_patron_5d7f:
	defb 000h,001h,018h,03fh,010h,000h,005h,00ch,01ch,01ch,01ch,03ch,0f8h,0f0h,000h,002h	; 5d7f  ...?.......<....
	defb 0e0h,000h,00dh	; 5d8f

; ----------------------------------------------------------------------
; DATOS patron_5d92: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d92..0x5d9d  (11 bytes)
DATA_patron_5d92:
	defb 000h,017h,070h,0c8h,0a8h,0d4h,06ch,036h,01eh,006h,001h	; 5d92  ..p...l6...

; ----------------------------------------------------------------------
; DATOS patron_5d9d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5d9d..0x5db8  (27 bytes)
DATA_patron_5d9d:
	defb 01fh,00fh,00fh,00fh,00fh,00fh,01fh,03fh,000h,005h,0f0h,070h,000h,001h,0c0h,0c0h	; 5d9d  .......?...p....
	defb 0c0h,0c0h,0c0h,0c0h,0c0h,0e0h,000h,005h,080h,0f0h,070h	; 5dad  ..........p

; ----------------------------------------------------------------------
; DATOS patron_5db8: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5db8..0x5dc7  (15 bytes)
DATA_patron_5db8:
	defb 07fh,0f3h,0e3h,0e1h,0e1h,000h,00bh,080h,080h,080h,0c0h,0c0h,0e0h,000h,00ah	; 5db8  ...............

; ----------------------------------------------------------------------
; DATOS parejas_5dc7: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5dc7..0x5dd1  (10 bytes)
DATA_parejas_5dc7:
	defb 0ffh,00ch	; 5dc7
	defb 007h,008h	; 5dc9
	defb 0f9h,0fbh	; 5dcb
	defb 00fh,00ah	; 5dcd
	defb 017h,00bh	; 5dcf

; ----------------------------------------------------------------------
; DATOS patron_5dd1: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5dd1..0x5dde  (13 bytes)
DATA_patron_5dd1:
	defb 000h,008h,07ch,000h,001h,0ffh,05fh,00fh,00eh,00eh,01ch,000h,010h	; 5dd1  ..|..._......

; ----------------------------------------------------------------------
; DATOS patron_5dde: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5dde..0x5df1  (19 bytes)
DATA_patron_5dde:
	defb 000h,002h,07fh,000h,001h,050h,0f8h,078h,038h,010h,000h,002h,022h,062h,0e0h,08fh	; 5dde  .....P.x8..."b..
	defb 07eh,000h,010h	; 5dee

; ----------------------------------------------------------------------
; DATOS patron_5df1: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5df1..0x5e07  (22 bytes)
DATA_patron_5df1:
	defb 000h,007h,001h,001h,003h,00eh,01fh,01bh,01bh,03fh,070h,000h,007h,0e0h,030h,090h	; 5df1  .........?p...0.
	defb 0d0h,0b0h,060h,0c0h,000h,002h	; 5e01

; ----------------------------------------------------------------------
; DATOS patron_5e07: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5e07..0x5e1d  (22 bytes)
DATA_patron_5e07:
	defb 00ch,008h,008h,008h,000h,003h,00fh,01fh,000h,005h,078h,0f8h,000h,005h,040h,0e0h	; 5e07  ..........x...@.
	defb 0f0h,0f0h,000h,005h,007h,00fh	; 5e17

; ----------------------------------------------------------------------
; DATOS patron_5e1d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5e1d..0x5e2b  (14 bytes)
DATA_patron_5e1d:
	defb 07dh,0f0h,0e0h,0e0h,070h,000h,00bh,0f0h,0f0h,078h,01ch,00eh,000h,00bh	; 5e1d  }...p....x....

; ----------------------------------------------------------------------
; DATOS parejas_5e2b: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5e2b..0x5e35  (10 bytes)
DATA_parejas_5e2b:
	defb 000h,00bh	; 5e2b
	defb 007h,00ah	; 5e2d
	defb 006h,00ah	; 5e2f
	defb 010h,009h	; 5e31
	defb 019h,00ah	; 5e33

; ----------------------------------------------------------------------
; DATOS patron_5e35: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5e35..0x5e4f  (26 bytes)
DATA_patron_5e35:
	defb 0c0h,080h,080h,080h,000h,001h,004h,00eh,0ffh,0ffh,000h,003h,001h,003h,03bh,07ch	; 5e35  ..............;|
	defb 000h,008h,080h,000h,002h,080h,080h,080h,000h,002h	; 5e45  ..........

; ----------------------------------------------------------------------
; DATOS patron_5e4f: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5e4f..0x5e56  (7 bytes)
DATA_patron_5e4f:
	defb 0fch,0feh,07eh,074h,070h,000h,01bh	; 5e4f

; ----------------------------------------------------------------------
; DATOS parejas_5e56: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5e56..0x5e60  (10 bytes)
DATA_parejas_5e56:
	defb 000h,00bh	; 5e56
	defb 007h,00ah	; 5e58
	defb 006h,00ah	; 5e5a
	defb 010h,00ch	; 5e5c
	defb 019h,00dh	; 5e5e

; ----------------------------------------------------------------------
; DATOS patron_5e60: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5e60..0x5e6d  (13 bytes)
DATA_patron_5e60:
	defb 000h,008h,07ch,000h,001h,0ffh,07fh,03fh,01fh,01fh,01eh,000h,010h	; 5e60  ..|....?.....

; ----------------------------------------------------------------------
; DATOS patron_5e6d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5e6d..0x5e84  (23 bytes)
DATA_patron_5e6d:
	defb 000h,002h,03fh,000h,001h,020h,070h,038h,018h,008h,000h,001h,00eh,02eh,02eh,06eh	; 5e6d  ..?.. p8.......n
	defb 0feh,07ch,000h,002h,080h,000h,00dh	; 5e7d

; ----------------------------------------------------------------------
; DATOS patron_5e84: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5e84..0x5e94  (16 bytes)
DATA_patron_5e84:
	defb 000h,009h,001h,01fh,02bh,05eh,0b2h,094h,078h,000h,008h,020h,0c0h,080h,000h,005h	; 5e84  ....+^..x.. ....

; ----------------------------------------------------------------------
; DATOS patron_5e94: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5e94..0x5eb0  (28 bytes)
DATA_patron_5e94:
	defb 00fh,001h,001h,001h,001h,001h,003h,01fh,03fh,000h,005h,078h,0f9h,000h,001h,080h	; 5e94  ........?..x....
	defb 080h,080h,080h,0c0h,0c0h,0e0h,0c0h,000h,004h,030h,0e0h,0c0h	; 5ea4  .........0..

; ----------------------------------------------------------------------
; DATOS patron_5eb0: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5eb0..0x5ebf  (15 bytes)
DATA_patron_5eb0:
	defb 0ffh,0f7h,0e7h,0e3h,070h,000h,00bh,080h,000h,001h,080h,0e0h,080h,000h,00bh	; 5eb0  ....p..........

; ----------------------------------------------------------------------
; DATOS parejas_5ebf: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5ebf..0x5ec9  (10 bytes)
DATA_parejas_5ebf:
	defb 000h,00ch	; 5ebf
	defb 007h,00ah	; 5ec1
	defb 00ch,001h	; 5ec3
	defb 010h,00ah	; 5ec5
	defb 019h,00bh	; 5ec7

; ----------------------------------------------------------------------
; DATOS patron_5ec9: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5ec9..0x5ede  (21 bytes)
DATA_patron_5ec9:
	defb 000h,003h,01fh,000h,001h,010h,038h,01ch,00ch,004h,0e0h,0feh,03eh,00eh,07eh,0fch	; 5ec9  ......8.....>.~.
	defb 000h,003h,0c0h,000h,00ch	; 5ed9

; ----------------------------------------------------------------------
; DATOS patron_5ede: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5ede..0x5eed  (15 bytes)
DATA_patron_5ede:
	defb 000h,008h,078h,0ceh,093h,08dh,0fbh,045h,075h,01eh,000h,00dh,080h,0c0h,060h	; 5ede  ..x....Eu.....`

; ----------------------------------------------------------------------
; DATOS patron_5eed: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5eed..0x5f05  (24 bytes)
DATA_patron_5eed:
	defb 01eh,003h,003h,003h,003h,007h,07fh,07fh,07fh,000h,005h,071h,0f3h,000h,005h,080h	; 5eed  ...........q....
	defb 080h,0c0h,080h,000h,004h,040h,0c0h,0c0h	; 5efd  .....@..

; ----------------------------------------------------------------------
; DATOS patron_5f05: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5f05..0x5f0c  (7 bytes)
DATA_patron_5f05:
	defb 0feh,0fch,0feh,0efh,0e7h,000h,01bh	; 5f05

; ----------------------------------------------------------------------
; DATOS parejas_5f0c: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5f0c..0x5f16  (10 bytes)
DATA_parejas_5f0c:
	defb 000h,00eh	; 5f0c
	defb 006h,00ch	; 5f0e
	defb 001h,000h	; 5f10
	defb 010h,00dh	; 5f12
	defb 019h,00eh	; 5f14

; ----------------------------------------------------------------------
; DATOS patron_5f16: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5f16..0x5f23  (13 bytes)
DATA_patron_5f16:
	defb 000h,008h,07eh,000h,001h,0ffh,0ffh,0ffh,0ffh,0ffh,07eh,000h,010h	; 5f16  ..~.......~..

; ----------------------------------------------------------------------
; DATOS patron_5f23: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5f23..0x5f3d  (26 bytes)
DATA_patron_5f23:
	defb 000h,001h,00fh,000h,007h,00ch,01ch,01ch,03ch,07ch,0f8h,0e0h,000h,001h,0f0h,000h	; 5f23  ........<|......
	defb 002h,003h,003h,003h,007h,00fh,006h,004h,000h,005h	; 5f33  ..........

; ----------------------------------------------------------------------
; DATOS patron_5f3d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5f3d..0x5f4d  (16 bytes)
DATA_patron_5f3d:
	defb 000h,004h,03ch,044h,0aah,0aah,0b2h,0b2h,0aah,042h,038h,010h,010h,010h,000h,010h	; 5f3d  ..<D.....B8.....

; ----------------------------------------------------------------------
; DATOS patron_5f4d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5f4d..0x5f65  (24 bytes)
DATA_patron_5f4d:
	defb 07fh,01fh,01fh,01fh,01fh,01fh,03fh,07fh,000h,006h,07bh,0ffh,080h,0c0h,0c0h,0c0h	; 5f4d  ......?...{.....
	defb 0c0h,0c0h,0c0h,0e0h,000h,006h,0c0h,0c0h	; 5f5d  ........

; ----------------------------------------------------------------------
; DATOS patron_5f65: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5f65..0x5f6d  (8 bytes)
DATA_patron_5f65:
	defb 0ffh,0ffh,0ffh,07fh,077h,077h,000h,01ah	; 5f65  ....ww..

; ----------------------------------------------------------------------
; DATOS parejas_5f6d: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5f6d..0x5f77  (10 bytes)
DATA_parejas_5f6d:
	defb 000h,00ch	; 5f6d
	defb 008h,008h	; 5f6f
	defb 0fdh,013h	; 5f71
	defb 010h,00bh	; 5f73
	defb 018h,00ch	; 5f75

; ----------------------------------------------------------------------
; DATOS patron_5f77: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5f77..0x5f83  (12 bytes)
DATA_patron_5f77:
	defb 000h,008h,038h,066h,0dfh,0bfh,07fh,0ffh,07ch,030h,000h,010h	; 5f77  ..8f....|0..

; ----------------------------------------------------------------------
; DATOS patron_5f83: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5f83..0x5fa0  (29 bytes)
DATA_patron_5f83:
	defb 004h,018h,020h,040h,080h,000h,001h,003h,000h,001h,020h,060h,070h,070h,070h,030h	; 5f83  .. @...... `ppp0
	defb 000h,002h,018h,018h,018h,038h,038h,0f0h,0f0h,030h,020h,000h,007h	; 5f93  .....88..0 ..

; ----------------------------------------------------------------------
; DATOS patron_5fa0: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5fa0..0x5fb3  (19 bytes)
DATA_patron_5fa0:
	defb 000h,001h,038h,06ch,0c6h,0b2h,0aeh,0a2h,0b2h,0c6h,064h,03ch,018h,008h,008h,008h	; 5fa0  ..8l......d<....
	defb 018h,000h,010h	; 5fb0

; ----------------------------------------------------------------------
; DATOS patron_5fb3: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5fb3..0x5fc6  (19 bytes)
DATA_patron_5fb3:
	defb 07eh,0feh,0feh,07eh,07fh,07fh,07fh,07fh,07ch,000h,006h,071h,000h,006h,080h,080h	; 5fb3  ~..~....|..q....
	defb 000h,007h,0c0h	; 5fc3

; ----------------------------------------------------------------------
; DATOS patron_5fc6: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5fc6..0x5fd4  (14 bytes)
DATA_patron_5fc6:
	defb 007h,0ffh,0f7h,077h,063h,0e3h,0e3h,000h,00dh,080h,080h,080h,000h,009h	; 5fc6  ...wc.........

; ----------------------------------------------------------------------
; DATOS parejas_5fd4: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x5fd4..0x5fde  (10 bytes)
DATA_parejas_5fd4:
	defb 001h,00dh	; 5fd4
	defb 009h,00dh	; 5fd6
	defb 0f9h,015h	; 5fd8
	defb 010h,010h	; 5fda
	defb 018h,011h	; 5fdc

; ----------------------------------------------------------------------
; DATOS patron_5fde: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5fde..0x5fea  (12 bytes)
DATA_patron_5fde:
	defb 000h,009h,07ch,000h,001h,0feh,0feh,0feh,0feh,07ch,000h,010h	; 5fde  ..|......|..

; ----------------------------------------------------------------------
; DATOS patron_5fea: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5fea..0x5ff8  (14 bytes)
DATA_patron_5fea:
	defb 07fh,000h,006h,020h,070h,070h,070h,070h,070h,070h,0f0h,0e0h,000h,010h	; 5fea  ... pppppp....

; ----------------------------------------------------------------------
; DATOS patron_5ff8: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x5ff8..0x6004  (12 bytes)
DATA_patron_5ff8:
	defb 038h,046h,0fbh,091h,0e3h,046h,038h,000h,00bh,080h,000h,00dh	; 5ff8  8F...F8.....

; ----------------------------------------------------------------------
; DATOS patron_6004: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6004..0x601b  (23 bytes)
DATA_patron_6004:
	defb 0f8h,0fch,07ch,07eh,07eh,07fh,07fh,0f8h,000h,004h,001h,033h,073h,070h,000h,006h	; 6004  ..|~~......3sp..
	defb 080h,000h,005h,080h,080h,000h,002h	; 6014

; ----------------------------------------------------------------------
; DATOS patron_601b: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x601b..0x6027  (12 bytes)
DATA_patron_601b:
	defb 007h,0feh,0feh,077h,077h,072h,040h,000h,00dh,080h,000h,00bh	; 601b  ...wwr@.....

; ----------------------------------------------------------------------
; DATOS parejas_6027: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6027..0x6031  (10 bytes)
DATA_parejas_6027:
	defb 000h,00dh	; 6027
	defb 00ah,00ch	; 6029
	defb 015h,003h	; 602b
	defb 010h,00fh	; 602d
	defb 017h,00fh	; 602f

; ----------------------------------------------------------------------
; DATOS patron_6031: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6031..0x603c  (11 bytes)
DATA_patron_6031:
	defb 000h,018h,07ch,000h,001h,0ffh,05fh,00fh,00fh,00fh,01eh	; 6031  ..|..._....

; ----------------------------------------------------------------------
; DATOS patron_603c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x603c..0x6053  (23 bytes)
DATA_patron_603c:
	defb 000h,004h,005h,01fh,00fh,00eh,002h,01ch,079h,0f9h,0a1h,001h,006h,003h,000h,00ah	; 603c  ........y.......
	defb 0c0h,0c0h,0c0h,0c0h,080h,000h,001h	; 604c

; ----------------------------------------------------------------------
; DATOS patron_6053: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6053..0x605e  (11 bytes)
DATA_patron_6053:
	defb 000h,017h,080h,0dch,072h,049h,06fh,059h,02dh,012h,00ch	; 6053  ....rIoY-..

; ----------------------------------------------------------------------
; DATOS patron_605e: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x605e..0x6070  (18 bytes)
DATA_patron_605e:
	defb 03ch,062h,062h,062h,000h,001h,006h,087h,087h,000h,003h,004h,006h,004h,038h,078h	; 605e  <bbb..........8x
	defb 000h,010h	; 606e

; ----------------------------------------------------------------------
; DATOS patron_6070: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6070..0x6078  (8 bytes)
DATA_patron_6070:
	defb 0d0h,050h,0b0h,060h,0e0h,0e0h,000h,01ah	; 6070  .P.`....

; ----------------------------------------------------------------------
; DATOS parejas_6078: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6078..0x6082  (10 bytes)
DATA_parejas_6078:
	defb 0fch,007h	; 6078
	defb 003h,00bh	; 607a
	defb 008h,004h	; 607c
	defb 00ch,00fh	; 607e
	defb 014h,011h	; 6080

; ----------------------------------------------------------------------
; DATOS patron_6082: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6082..0x608c  (10 bytes)
DATA_patron_6082:
	defb 000h,019h,03eh,000h,001h,07fh,03fh,03fh,03fh,03fh	; 6082  ..>...????

; ----------------------------------------------------------------------
; DATOS patron_608c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x608c..0x60a1  (21 bytes)
DATA_patron_608c:
	defb 000h,003h,007h,000h,001h,004h,044h,0f4h,0fch,03ch,007h,007h,00eh,01ch,078h,070h	; 608c  ......D..<....xp
	defb 000h,003h,0f0h,000h,00ch	; 609c

; ----------------------------------------------------------------------
; DATOS patron_60a1: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x60a1..0x60b3  (18 bytes)
DATA_patron_60a1:
	defb 000h,008h,001h,001h,001h,001h,000h,00ah,070h,08ch,066h,032h,0fah,012h,096h,07eh	; 60a1  ........p.f2...~
	defb 003h,001h	; 60b1

; ----------------------------------------------------------------------
; DATOS patron_60b3: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x60b3..0x60c6  (19 bytes)
DATA_patron_60b3:
	defb 03eh,00fh,00fh,01fh,03eh,07eh,07fh,0ffh,000h,004h,003h,003h,01ch,03ch,000h,007h	; 60b3  >...>~.......<..
	defb 080h,000h,008h	; 60c3

; ----------------------------------------------------------------------
; DATOS patron_60c6: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x60c6..0x60ce  (8 bytes)
DATA_patron_60c6:
	defb 0f8h,0f0h,0f0h,078h,070h,070h,000h,01ah	; 60c6  ...xpp..

; ----------------------------------------------------------------------
; DATOS parejas_60ce: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x60ce..0x60d8  (10 bytes)
DATA_parejas_60ce:
	defb 000h,006h	; 60ce
	defb 007h,00ah	; 60d0
	defb 0feh,0fbh	; 60d2
	defb 010h,00eh	; 60d4
	defb 018h,010h	; 60d6

; ----------------------------------------------------------------------
; DATOS patron_60d8: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x60d8..0x60e2  (10 bytes)
DATA_patron_60d8:
	defb 000h,019h,03eh,000h,001h,07fh,07fh,07fh,07fh,03eh	; 60d8  ..>......>

; ----------------------------------------------------------------------
; DATOS patron_60e2: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x60e2..0x60f8  (22 bytes)
DATA_patron_60e2:
	defb 000h,003h,03fh,000h,005h,030h,030h,070h,070h,0f0h,0e0h,0c0h,000h,003h,080h,000h	; 60e2  ..?..00pp.......
	defb 005h,033h,03fh,03eh,000h,004h	; 60f2

; ----------------------------------------------------------------------
; DATOS patron_60f8: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x60f8..0x6104  (12 bytes)
DATA_patron_60f8:
	defb 000h,016h,01ch,022h,055h,053h,059h,075h,032h,01ch,008h,008h	; 60f8  ..."USYu2...

; ----------------------------------------------------------------------
; DATOS patron_6104: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6104..0x611c  (24 bytes)
DATA_patron_6104:
	defb 03fh,03fh,03fh,03fh,03eh,07eh,0ffh,0ffh,000h,004h,001h,003h,073h,0f0h,000h,007h	; 6104  ????>~......s...
	defb 080h,000h,004h,080h,080h,080h,000h,001h	; 6114  ........

; ----------------------------------------------------------------------
; DATOS patron_611c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x611c..0x6127  (11 bytes)
DATA_patron_611c:
	defb 07fh,0f7h,0f7h,0f7h,072h,070h,000h,00dh,080h,000h,00ch	; 611c  ....rp.....

; ----------------------------------------------------------------------
; DATOS parejas_6127: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6127..0x6131  (10 bytes)
DATA_parejas_6127:
	defb 000h,004h	; 6127
	defb 007h,00bh	; 6129
	defb 000h,00eh	; 612b
	defb 010h,00dh	; 612d
	defb 018h,00dh	; 612f

; ----------------------------------------------------------------------
; DATOS patron_6131: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6131..0x6143  (18 bytes)
DATA_patron_6131:
	defb 000h,00ah,001h,001h,001h,001h,001h,000h,009h,07ch,000h,001h,0ffh,0abh,083h,083h	; 6131  .........|......
	defb 083h,0c6h	; 6141

; ----------------------------------------------------------------------
; DATOS patron_6143: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6143..0x6168  (37 bytes)
DATA_patron_6143:
	defb 000h,002h,003h,000h,001h,001h,001h,001h,001h,000h,001h,004h,00ch,01ch,01ch,01ch	; 6143  ................
	defb 01ch,00eh,000h,002h,0f8h,000h,001h,050h,0f0h,0f0h,0f0h,0e0h,0e6h,007h,000h,001h	; 6153  .......P........
	defb 006h,001h,002h,000h,001h	; 6163

; ----------------------------------------------------------------------
; DATOS patron_6168: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6168..0x6173  (11 bytes)
DATA_patron_6168:
	defb 000h,00dh,007h,000h,00ch,03eh,042h,0fdh,099h,0e6h,07ch	; 6168  .....>B...|

; ----------------------------------------------------------------------
; DATOS patron_6173: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6173..0x6187  (20 bytes)
DATA_patron_6173:
	defb 063h,07fh,07ch,07bh,070h,006h,031h,0f8h,000h,004h,003h,070h,070h,000h,00bh,080h	; 6173  c.|{p.1....pp...
	defb 080h,080h,000h,003h	; 6183

; ----------------------------------------------------------------------
; DATOS patron_6187: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6187..0x618e  (7 bytes)
DATA_patron_6187:
	defb 07fh,07fh,077h,073h,070h,000h,01bh	; 6187

; ----------------------------------------------------------------------
; DATOS parejas_618e: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x618e..0x6198  (10 bytes)
DATA_parejas_618e:
	defb 000h,006h	; 618e
	defb 007h,008h	; 6190
	defb 008h,009h	; 6192
	defb 010h,00dh	; 6194
	defb 018h,00dh	; 6196

; ----------------------------------------------------------------------
; DATOS patron_6198: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6198..0x61b7  (31 bytes)
DATA_patron_6198:
	defb 071h,07fh,07eh,07dh,078h,003h,018h,07ch,000h,002h,080h,080h,0e0h,003h,003h,000h	; 6198  q.~}x..|........
	defb 001h,080h,080h,000h,001h,080h,000h,002h,080h,000h,006h,080h,080h,000h,001h	; 61a8  ...............

; ----------------------------------------------------------------------
; DATOS patron_61b7: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x61b7..0x61be  (7 bytes)
DATA_patron_61b7:
	defb 0ffh,0ffh,0e7h,0c7h,007h,000h,01bh	; 61b7

; ----------------------------------------------------------------------
; DATOS parejas_61be: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x61be..0x61c8  (10 bytes)
DATA_parejas_61be:
	defb 000h,005h	; 61be
	defb 007h,007h	; 61c0
	defb 008h,008h	; 61c2
	defb 010h,00ch	; 61c4
	defb 018h,00dh	; 61c6

; ----------------------------------------------------------------------
; DATOS patron_61c8: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x61c8..0x61da  (18 bytes)
DATA_patron_61c8:
	defb 000h,00ah,001h,001h,001h,001h,001h,000h,009h,0fch,000h,001h,0feh,057h,007h,007h	; 61c8  .............W..
	defb 087h,0ceh	; 61d8

; ----------------------------------------------------------------------
; DATOS patron_61da: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x61da..0x61f5  (27 bytes)
DATA_patron_61da:
	defb 000h,003h,03fh,000h,001h,02ah,03eh,03eh,01eh,0cch,0f0h,033h,003h,007h,07fh,07fh	; 61da  ..?..*>>...3....
	defb 000h,003h,080h,000h,007h,080h,080h,080h,080h,000h,001h	; 61ea  ...........

; ----------------------------------------------------------------------
; DATOS raqueta_sin_usar: Se descomprime a un sprite valido -una raqueta
;   pequena- pero ninguna descripcion de postura lo apunta: sobra en el
;   cartucho
;   0x61f5..0x61fe  (9 bytes)
DATA_raqueta_sin_usar:
	defb 000h,019h,038h,074h,05ah,06eh,02ah,01eh,001h	; 61f5  ..8tZn*..

; ----------------------------------------------------------------------
; DATOS patron_61fe: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x61fe..0x6219  (27 bytes)
DATA_patron_61fe:
	defb 01fh,018h,038h,030h,000h,001h,001h,03fh,07fh,000h,005h,070h,0f0h,000h,005h,080h	; 61fe  ..80...?...p....
	defb 080h,080h,0c0h,000h,003h,020h,060h,060h,0c0h,000h,001h	; 620e  ..... ``...

; ----------------------------------------------------------------------
; DATOS patron_6219: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6219..0x6225  (12 bytes)
DATA_patron_6219:
	defb 0feh,0ffh,0efh,0e3h,0e1h,001h,000h,00ch,080h,080h,000h,00ch	; 6219  ............

; ----------------------------------------------------------------------
; DATOS parejas_6225: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6225..0x622f  (10 bytes)
DATA_parejas_6225:
	defb 000h,005h	; 6225
	defb 006h,00bh	; 6227
	defb 0ffh,0fbh	; 6229
	defb 010h,00ch	; 622b
	defb 018h,00dh	; 622d

; ----------------------------------------------------------------------
; DATOS patron_622f: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x622f..0x623b  (12 bytes)
DATA_patron_622f:
	defb 000h,009h,07ch,000h,001h,0feh,0abh,083h,083h,0c7h,000h,010h	; 622f  ..|.........

; ----------------------------------------------------------------------
; DATOS patron_623b: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x623b..0x625d  (34 bytes)
DATA_patron_623b:
	defb 000h,002h,007h,000h,001h,005h,007h,007h,003h,003h,008h,008h,018h,03bh,07bh,0f0h	; 623b  .............;{.
	defb 0e0h,000h,002h,0e0h,000h,001h,040h,0c0h,0c0h,080h,0b0h,030h,070h,0f0h,0e0h,0c0h	; 624b  ......@....0p...
	defb 000h,002h	; 625b

; ----------------------------------------------------------------------
; DATOS patron_625d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x625d..0x6272  (21 bytes)
DATA_patron_625d:
	defb 044h,07ch,078h,070h,040h,042h,0ffh,0ffh,0ffh,000h,005h,038h,079h,000h,008h,080h	; 625d  D|xp@B.....8y...
	defb 000h,004h,020h,0e0h,0e0h	; 626d

; ----------------------------------------------------------------------
; DATOS patron_6272: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6272..0x6280  (14 bytes)
DATA_patron_6272:
	defb 0f7h,0e3h,0e1h,070h,038h,000h,00bh,080h,080h,0c0h,0c0h,0c0h,000h,00bh	; 6272  ...p8.........

; ----------------------------------------------------------------------
; DATOS parejas_6280: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6280..0x628a  (10 bytes)
DATA_parejas_6280:
	defb 0ffh,00dh	; 6280
	defb 007h,009h	; 6282
	defb 004h,0feh	; 6284
	defb 00fh,00dh	; 6286
	defb 018h,00dh	; 6288

; ----------------------------------------------------------------------
; DATOS patron_628a: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x628a..0x629f  (21 bytes)
DATA_patron_628a:
	defb 03fh,000h,001h,02ah,03eh,03eh,01eh,0cch,0f0h,037h,037h,037h,00fh,01eh,03ch,038h	; 628a  ?..*>>...777..<8
	defb 000h,001h,080h,000h,00fh	; 629a

; ----------------------------------------------------------------------
; DATOS patron_629f: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x629f..0x62b2  (19 bytes)
DATA_patron_629f:
	defb 03ch,022h,062h,062h,042h,007h,00fh,01fh,000h,003h,001h,001h,073h,0f0h,000h,008h	; 629f  <"bbB.......s...
	defb 080h,000h,008h	; 62af

; ----------------------------------------------------------------------
; DATOS patron_62b2: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x62b2..0x62b9  (7 bytes)
DATA_patron_62b2:
	defb 07ch,078h,0fch,0ech,0ech,000h,01bh	; 62b2

; ----------------------------------------------------------------------
; DATOS parejas_62b9: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x62b9..0x62c3  (10 bytes)
DATA_parejas_62b9:
	defb 000h,005h	; 62b9
	defb 009h,00bh	; 62bb
	defb 0ffh,0fbh	; 62bd
	defb 010h,00dh	; 62bf
	defb 018h,00eh	; 62c1

; ----------------------------------------------------------------------
; DATOS patron_62c3: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x62c3..0x62ce  (11 bytes)
DATA_patron_62c3:
	defb 000h,018h,03eh,000h,001h,07fh,02fh,00fh,007h,007h,00eh	; 62c3  ..>.../....

; ----------------------------------------------------------------------
; DATOS patron_62ce: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x62ce..0x62ec  (30 bytes)
DATA_patron_62ce:
	defb 01fh,000h,001h,014h,03ch,01eh,00eh,004h,010h,031h,071h,0e0h,0c0h,000h,002h,019h	; 62ce  ....<....1q.....
	defb 000h,001h,0c0h,000h,007h,0c0h,0e0h,0e0h,070h,0f0h,0e0h,0c0h,000h,001h	; 62de  ........p.....

; ----------------------------------------------------------------------
; DATOS patron_62ec: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x62ec..0x62fa  (14 bytes)
DATA_patron_62ec:
	defb 000h,009h,03ch,042h,0bdh,099h,0a5h,042h,03ch,000h,00ch,0f8h,000h,003h	; 62ec  ..<B...B<.....

; ----------------------------------------------------------------------
; DATOS patron_62fa: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x62fa..0x630c  (18 bytes)
DATA_patron_62fa:
	defb 03eh,038h,038h,03ch,03eh,03ch,078h,018h,000h,005h,071h,0f3h,000h,00eh,0c0h,0c0h	; 62fa  >88<><x...q.....
	defb 000h,001h	; 630a

; ----------------------------------------------------------------------
; DATOS patron_630c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x630c..0x6318  (12 bytes)
DATA_patron_630c:
	defb 067h,0f7h,0e7h,0e3h,061h,070h,000h,00dh,080h,080h,000h,00bh	; 630c  g...ap......

; ----------------------------------------------------------------------
; DATOS parejas_6318: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6318..0x6322  (10 bytes)
DATA_parejas_6318:
	defb 000h,004h	; 6318
	defb 009h,00ah	; 631a
	defb 007h,0fdh	; 631c
	defb 010h,00ch	; 631e
	defb 017h,00ch	; 6320

; ----------------------------------------------------------------------
; DATOS patron_6322: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6322..0x6339  (23 bytes)
DATA_patron_6322:
	defb 07fh,000h,001h,02ah,03eh,03eh,01ch,05ch,0e1h,0e1h,0e1h,071h,07fh,03fh,000h,00bh	; 6322  ...*>>.\...q.?..
	defb 080h,080h,0c0h,080h,080h,000h,003h	; 6332

; ----------------------------------------------------------------------
; DATOS patron_6339: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6339..0x6343  (10 bytes)
DATA_patron_6339:
	defb 000h,018h,00eh,015h,02fh,03ah,024h,038h,040h,080h	; 6339  ..../:$8@.

; ----------------------------------------------------------------------
; DATOS patron_6343: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6343..0x6358  (21 bytes)
DATA_patron_6343:
	defb 080h,078h,078h,078h,038h,000h,002h,0feh,0ffh,000h,003h,001h,001h,071h,0f0h,000h	; 6343  .xxx8........q..
	defb 00ch,080h,080h,080h,080h	; 6353

; ----------------------------------------------------------------------
; DATOS patron_6358: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6358..0x635f  (7 bytes)
DATA_patron_6358:
	defb 0fch,0fch,0feh,0ech,0e4h,000h,01bh	; 6358

; ----------------------------------------------------------------------
; DATOS parejas_635f: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x635f..0x6369  (10 bytes)
DATA_parejas_635f:
	defb 0ffh,00bh	; 635f
	defb 009h,00ah	; 6361
	defb 003h,00bh	; 6363
	defb 00fh,00ch	; 6365
	defb 018h,00dh	; 6367

; ----------------------------------------------------------------------
; DATOS patron_6369: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6369..0x6373  (10 bytes)
DATA_patron_6369:
	defb 000h,019h,03eh,000h,001h,07fh,0ebh,0e1h,0e1h,073h	; 6369  ..>......s

; ----------------------------------------------------------------------
; DATOS patron_6373: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6373..0x6389  (22 bytes)
DATA_patron_6373:
	defb 0feh,000h,001h,028h,03ch,03ch,018h,000h,001h,073h,071h,071h,078h,039h,01ch,00ch	; 6373  ...(<<...sqqx9..
	defb 000h,00dh,080h,0c0h,000h,003h	; 6383

; ----------------------------------------------------------------------
; DATOS patron_6389: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6389..0x6396  (13 bytes)
DATA_patron_6389:
	defb 000h,00eh,003h,006h,000h,009h,01eh,033h,04dh,0d9h,097h,0e6h,07ch	; 6389  .......3M...|

; ----------------------------------------------------------------------
; DATOS patron_6396: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6396..0x63ad  (23 bytes)
DATA_patron_6396:
	defb 00eh,006h,007h,007h,002h,000h,001h,011h,039h,07fh,000h,003h,0c0h,0e0h,0e1h,071h	; 6396  ........9......q
	defb 000h,008h,080h,000h,005h,0c0h,0e0h	; 63a6

; ----------------------------------------------------------------------
; DATOS patron_63ad: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x63ad..0x63b4  (7 bytes)
DATA_patron_63ad:
	defb 07eh,07fh,0f7h,0e7h,047h,000h,01bh	; 63ad

; ----------------------------------------------------------------------
; DATOS parejas_63b4: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x63b4..0x63be  (10 bytes)
DATA_parejas_63b4:
	defb 0ffh,004h	; 63b4
	defb 009h,00dh	; 63b6
	defb 005h,00ch	; 63b8
	defb 00fh,00ch	; 63ba
	defb 018h,00dh	; 63bc

; ----------------------------------------------------------------------
; DATOS patron_63be: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x63be..0x63d3  (21 bytes)
DATA_patron_63be:
	defb 00eh,006h,007h,007h,002h,000h,001h,011h,039h,07fh,000h,001h,060h,060h,060h,040h	; 63be  ........9...```@
	defb 007h,007h,000h,00fh,080h	; 63ce

; ----------------------------------------------------------------------
; DATOS patron_63d3: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x63d3..0x63da  (7 bytes)
DATA_patron_63d3:
	defb 0fch,0fch,0fch,0f8h,038h,000h,01bh	; 63d3

; ----------------------------------------------------------------------
; DATOS parejas_63da: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x63da..0x63e4  (10 bytes)
DATA_parejas_63da:
	defb 0ffh,004h	; 63da
	defb 009h,00dh	; 63dc
	defb 005h,00ch	; 63de
	defb 00fh,00bh	; 63e0
	defb 018h,00dh	; 63e2

; ----------------------------------------------------------------------
; DATOS patron_63e4: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x63e4..0x63ee  (10 bytes)
DATA_patron_63e4:
	defb 000h,019h,03eh,000h,001h,07fh,0d9h,0c1h,0c1h,0e3h	; 63e4  ..>.......

; ----------------------------------------------------------------------
; DATOS patron_63ee: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x63ee..0x6405  (23 bytes)
DATA_patron_63ee:
	defb 000h,005h,003h,000h,001h,001h,001h,001h,000h,00bh,0f8h,000h,001h,050h,0f0h,0f0h	; 63ee  .............P..
	defb 0e0h,000h,001h,0e0h,0fbh,07fh,03eh	; 63fe

; ----------------------------------------------------------------------
; DATOS patron_6405: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6405..0x640f  (10 bytes)
DATA_patron_6405:
	defb 000h,018h,00ch,012h,009h,00fh,015h,00eh,004h,004h	; 6405  ..........

; ----------------------------------------------------------------------
; DATOS patron_640f: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x640f..0x6425  (22 bytes)
DATA_patron_640f:
	defb 01eh,030h,030h,038h,01ch,01eh,03eh,03fh,07fh,000h,003h,0c0h,0c0h,0c0h,080h,000h	; 640f  .008..>?........
	defb 008h,080h,000h,005h,0c0h,0e0h	; 641f

; ----------------------------------------------------------------------
; DATOS patron_6425: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6425..0x6433  (14 bytes)
DATA_patron_6425:
	defb 03fh,03bh,079h,030h,020h,000h,00bh,080h,0c0h,0c0h,0c0h,0c0h,000h,00bh	; 6425  ?;y0 .........

; ----------------------------------------------------------------------
; DATOS parejas_6433: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6433..0x643d  (10 bytes)
DATA_parejas_6433:
	defb 0ffh,001h	; 6433
	defb 004h,004h	; 6435
	defb 001h,006h	; 6437
	defb 00fh,008h	; 6439
	defb 018h,008h	; 643b

; ----------------------------------------------------------------------
; DATOS patron_643d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x643d..0x6448  (11 bytes)
DATA_patron_643d:
	defb 000h,018h,03eh,000h,001h,0ffh,0f5h,0f0h,0f0h,0f0h,078h	; 643d  ..>.......x

; ----------------------------------------------------------------------
; DATOS patron_6448: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6448..0x6462  (26 bytes)
DATA_patron_6448:
	defb 000h,003h,007h,000h,008h,008h,018h,07ch,070h,000h,003h,0f0h,000h,001h,0a0h,0f0h	; 6448  .......|p.......
	defb 0f0h,0e0h,040h,000h,001h,0e0h,0e0h,0f2h,07fh,03fh	; 6458  ..@......?

; ----------------------------------------------------------------------
; DATOS patron_6462: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6462..0x6476  (20 bytes)
DATA_patron_6462:
	defb 000h,00ah,001h,001h,001h,003h,007h,008h,000h,006h,01ch,02ah,053h,0b1h,0fbh,0eeh	; 6462  ...........*S...
	defb 04ch,0f0h,000h,002h	; 6472

; ----------------------------------------------------------------------
; DATOS patron_6476: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6476..0x648d  (23 bytes)
DATA_patron_6476:
	defb 01eh,038h,038h,038h,01ch,01eh,03fh,07fh,000h,003h,080h,080h,0c3h,0e3h,000h,008h	; 6476  .888..?.........
	defb 080h,000h,005h,080h,0c0h,000h,001h	; 6486

; ----------------------------------------------------------------------
; DATOS patron_648d: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x648d..0x6494  (7 bytes)
DATA_patron_648d:
	defb 03eh,07eh,0ffh,0efh,0c7h,000h,01bh	; 648d

; ----------------------------------------------------------------------
; DATOS parejas_6494: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6494..0x649e  (10 bytes)
DATA_parejas_6494:
	defb 000h,004h	; 6494
	defb 006h,008h	; 6496
	defb 004h,013h	; 6498
	defb 010h,00bh	; 649a
	defb 018h,00ch	; 649c

; ----------------------------------------------------------------------
; DATOS patron_649e: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x649e..0x64a9  (11 bytes)
DATA_patron_649e:
	defb 000h,018h,03eh,000h,001h,07fh,0ebh,0e1h,0e1h,0e1h,073h	; 649e  ..>.......s

; ----------------------------------------------------------------------
; DATOS patron_64a9: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x64a9..0x64c1  (24 bytes)
DATA_patron_64a9:
	defb 000h,006h,00ch,00ch,00fh,007h,003h,000h,007h,0feh,000h,001h,028h,03ch,03ch,03ch	; 64a9  ............(<<<
	defb 018h,080h,0b8h,038h,03ch,01ch,01fh,00fh	; 64b9  ...8<...

; ----------------------------------------------------------------------
; DATOS patron_64c1: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x64c1..0x64cd  (12 bytes)
DATA_patron_64c1:
	defb 000h,00ch,01fh,000h,00ch,03ch,042h,0ffh,089h,095h,042h,03ch	; 64c1  .....<B...B<

; ----------------------------------------------------------------------
; DATOS patron_64cd: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x64cd..0x64e2  (21 bytes)
DATA_patron_64cd:
	defb 00fh,008h,018h,018h,01ch,01ch,03eh,07eh,000h,004h,0e0h,0f0h,000h,009h,080h,000h	; 64cd  ......>~........
	defb 005h,0e0h,0f0h,000h,001h	; 64dd

; ----------------------------------------------------------------------
; DATOS patron_64e2: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x64e2..0x64ef  (13 bytes)
DATA_patron_64e2:
	defb 03fh,03bh,079h,0f0h,000h,00ch,080h,0c0h,0e0h,0e0h,0e0h,000h,00bh	; 64e2  ?;y..........

; ----------------------------------------------------------------------
; DATOS parejas_64ef: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x64ef..0x64f9  (10 bytes)
DATA_parejas_64ef:
	defb 000h,005h	; 64ef
	defb 007h,006h	; 64f1
	defb 00ch,011h	; 64f3
	defb 010h,00bh	; 64f5
	defb 018h,00bh	; 64f7

; ----------------------------------------------------------------------
; DATOS patron_64f9: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x64f9..0x6509  (16 bytes)
DATA_patron_64f9:
	defb 000h,00ch,001h,001h,001h,001h,000h,009h,07ch,000h,001h,0feh,0abh,083h,083h,0c7h	; 64f9  ........|.......

; ----------------------------------------------------------------------
; DATOS patron_6509: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6509..0x6526  (29 bytes)
DATA_patron_6509:
	defb 000h,004h,007h,000h,001h,003h,003h,003h,001h,00dh,01ch,01ch,008h,008h,000h,005h	; 6509  ................
	defb 0f0h,000h,001h,0a0h,0e0h,0e0h,0c0h,0c0h,010h,018h,01ch,00fh,007h	; 6519  .............

; ----------------------------------------------------------------------
; DATOS patron_6526: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6526..0x6534  (14 bytes)
DATA_patron_6526:
	defb 000h,014h,01ch,036h,03ah,02eh,02ah,036h,01ah,01eh,006h,002h,003h,001h	; 6526  ...6:.*6......

; ----------------------------------------------------------------------
; DATOS patron_6534: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6534..0x654b  (23 bytes)
DATA_patron_6534:
	defb 011h,01fh,01fh,01fh,01fh,03fh,03fh,03fh,07fh,000h,004h,080h,0e1h,0e1h,000h,006h	; 6534  .....???........
	defb 080h,080h,0c0h,000h,005h,0c0h,0e0h	; 6544

; ----------------------------------------------------------------------
; DATOS patron_654b: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x654b..0x6558  (13 bytes)
DATA_patron_654b:
	defb 03fh,03bh,079h,071h,061h,000h,00ch,080h,080h,080h,080h,000h,00bh	; 654b  ?;yqa........

; ----------------------------------------------------------------------
; DATOS parejas_6558: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6558..0x6562  (10 bytes)
DATA_parejas_6558:
	defb 0ffh,005h	; 6558
	defb 005h,008h	; 655a
	defb 004h,0fch	; 655c
	defb 00fh,00bh	; 655e
	defb 018h,00bh	; 6560

; ----------------------------------------------------------------------
; DATOS patron_6562: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6562..0x6573  (17 bytes)
DATA_patron_6562:
	defb 000h,00bh,001h,001h,001h,001h,001h,000h,009h,0f8h,000h,001h,0feh,057h,003h,003h	; 6562  .............W..
	defb 087h	; 6572

; ----------------------------------------------------------------------
; DATOS patron_6573: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6573..0x6589  (22 bytes)
DATA_patron_6573:
	defb 000h,00dh,001h,001h,000h,003h,07fh,000h,001h,02ah,03fh,03fh,01eh,00ch,000h,001h	; 6573  .........*??....
	defb 0c7h,0e7h,0e7h,0dch,0c0h,080h	; 6583

; ----------------------------------------------------------------------
; DATOS patron_6589: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6589..0x6591  (8 bytes)
DATA_patron_6589:
	defb 000h,01ah,01fh,012h,02eh,052h,054h,038h	; 6589  .....RT8

; ----------------------------------------------------------------------
; DATOS patron_6591: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6591..0x65a0  (15 bytes)
DATA_patron_6591:
	defb 024h,07eh,071h,001h,001h,047h,07eh,0feh,0ffh,000h,005h,03eh,07eh,000h,010h	; 6591  $~q..G~....>~..

; ----------------------------------------------------------------------
; DATOS patron_65a0: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x65a0..0x65a7  (7 bytes)
DATA_patron_65a0:
	defb 07eh,07ch,07ch,03ch,03eh,000h,01bh	; 65a0

; ----------------------------------------------------------------------
; DATOS parejas_65a7: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x65a7..0x65b1  (10 bytes)
DATA_parejas_65a7:
	defb 0ffh,005h	; 65a7
	defb 007h,003h	; 65a9
	defb 00ch,0fbh	; 65ab
	defb 00fh,00ch	; 65ad
	defb 018h,00ch	; 65af

; ----------------------------------------------------------------------
; DATOS patron_65b1: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x65b1..0x65ba  (9 bytes)
DATA_patron_65b1:
	defb 000h,019h,07ch,0feh,0abh,083h,083h,0c7h,0c6h	; 65b1  ..|......

; ----------------------------------------------------------------------
; DATOS patron_65ba: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x65ba..0x65d2  (24 bytes)
DATA_patron_65ba:
	defb 000h,004h,0c5h,0c7h,0c7h,0c3h,0e3h,07bh,079h,010h,000h,008h,040h,0c0h,0c0h,080h	; 65ba  .......{y...@...
	defb 080h,0a0h,030h,038h,038h,01ch,00eh,007h	; 65ca  ..088...

; ----------------------------------------------------------------------
; DATOS patron_65d2: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x65d2..0x65dd  (11 bytes)
DATA_patron_65d2:
	defb 000h,00ch,030h,000h,00dh,01ch,002h,00fh,005h,003h,01eh	; 65d2  ..0........

; ----------------------------------------------------------------------
; DATOS patron_65dd: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x65dd..0x65f1  (20 bytes)
DATA_patron_65dd:
	defb 044h,06ch,0fch,0fch,0feh,07eh,07fh,07fh,0ffh,000h,005h,010h,073h,000h,008h,080h	; 65dd  Dl...~......s...
	defb 000h,005h,080h,080h	; 65ed

; ----------------------------------------------------------------------
; DATOS patron_65f1: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x65f1..0x65f9  (8 bytes)
DATA_patron_65f1:
	defb 0feh,0feh,0eeh,0efh,0e7h,0c6h,000h,01ah	; 65f1  ........

; ----------------------------------------------------------------------
; DATOS parejas_65f9: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x65f9..0x6603  (10 bytes)
DATA_parejas_65f9:
	defb 0ffh,004h	; 65f9
	defb 006h,008h	; 65fb
	defb 0ffh,008h	; 65fd
	defb 00fh,00ch	; 65ff
	defb 018h,00dh	; 6601

; ----------------------------------------------------------------------
; DATOS patron_6603: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6603..0x660c  (9 bytes)
DATA_patron_6603:
	defb 000h,019h,07ch,0feh,0abh,083h,083h,047h,046h	; 6603  ..|....GF

; ----------------------------------------------------------------------
; DATOS patron_660c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x660c..0x6624  (24 bytes)
DATA_patron_660c:
	defb 000h,003h,008h,01ah,01bh,01bh,01dh,00dh,00dh,004h,000h,009h,0a0h,0e0h,0e0h,0c0h	; 660c  ................
	defb 0c0h,0c0h,090h,018h,01ch,01eh,00fh,003h	; 661c  ........

; ----------------------------------------------------------------------
; DATOS patron_6624: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6624..0x6631  (13 bytes)
DATA_patron_6624:
	defb 000h,015h,01ch,022h,055h,04dh,04dh,055h,022h,01ch,008h,008h,008h	; 6624  ..."UMMU"....

; ----------------------------------------------------------------------
; DATOS patron_6631: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6631..0x6641  (16 bytes)
DATA_patron_6631:
	defb 020h,036h,07eh,07eh,03eh,03eh,07eh,0ffh,000h,004h,070h,077h,077h,007h,000h,010h	; 6631   6~~>>~...pww...

; ----------------------------------------------------------------------
; DATOS patron_6641: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6641..0x6648  (7 bytes)
DATA_patron_6641:
	defb 07fh,077h,077h,077h,007h,000h,01bh	; 6641

; ----------------------------------------------------------------------
; DATOS parejas_6648: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6648..0x6652  (10 bytes)
DATA_parejas_6648:
	defb 0ffh,005h	; 6648
	defb 006h,008h	; 664a
	defb 0fah,0ffh	; 664c
	defb 00fh,00ch	; 664e
	defb 017h,00ch	; 6650

; ----------------------------------------------------------------------
; DATOS patron_6652: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6652..0x665c  (10 bytes)
DATA_patron_6652:
	defb 000h,019h,07eh,000h,001h,0ffh,0d9h,0c1h,0c1h,063h	; 6652  ..~......c

; ----------------------------------------------------------------------
; DATOS patron_665c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x665c..0x6671  (21 bytes)
DATA_patron_665c:
	defb 000h,00ah,001h,001h,001h,000h,006h,0feh,000h,001h,054h,07ch,07ch,038h,038h,092h	; 665c  ..........T||88.
	defb 0c3h,0e3h,0e3h,073h,061h	; 666c

; ----------------------------------------------------------------------
; DATOS patron_6671: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6671..0x667b  (10 bytes)
DATA_patron_6671:
	defb 000h,018h,080h,040h,03ch,02ah,03dh,027h,011h,00eh	; 6671  ...@<*='..

; ----------------------------------------------------------------------
; DATOS patron_667b: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x667b..0x6692  (23 bytes)
DATA_patron_667b:
	defb 011h,01bh,00fh,007h,007h,023h,063h,07dh,0feh,000h,004h,039h,039h,001h,000h,006h	; 667b  .....#c}...99...
	defb 080h,080h,000h,005h,080h,0c0h,080h	; 668b

; ----------------------------------------------------------------------
; DATOS patron_6692: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6692..0x669c  (10 bytes)
DATA_patron_6692:
	defb 03eh,03eh,03ah,039h,000h,00eh,080h,040h,000h,00ch	; 6692  >>:9...@..

; ----------------------------------------------------------------------
; DATOS parejas_669c: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x669c..0x66a6  (10 bytes)
DATA_parejas_669c:
	defb 0ffh,004h	; 669c
	defb 006h,005h	; 669e
	defb 00dh,008h	; 66a0
	defb 00fh,00bh	; 66a2
	defb 018h,00bh	; 66a4

; ----------------------------------------------------------------------
; DATOS patron_66a6: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x66a6..0x66b0  (10 bytes)
DATA_patron_66a6:
	defb 000h,019h,01fh,000h,001h,07fh,075h,070h,070h,038h	; 66a6  ......upp8

; ----------------------------------------------------------------------
; DATOS patron_66b0: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x66b0..0x66c2  (18 bytes)
DATA_patron_66b0:
	defb 000h,005h,003h,000h,00fh,0f8h,000h,001h,0a0h,0f0h,0f0h,060h,000h,001h,070h,07bh	; 66b0  ...........`..p{
	defb 07fh,03eh	; 66c0

; ----------------------------------------------------------------------
; DATOS patron_66c2: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x66c2..0x66cb  (9 bytes)
DATA_patron_66c2:
	defb 000h,019h,004h,002h,003h,001h,00dh,007h,002h	; 66c2  .........

; ----------------------------------------------------------------------
; DATOS patron_66cb: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x66cb..0x66dd  (18 bytes)
DATA_patron_66cb:
	defb 01fh,038h,038h,038h,03ch,03eh,07eh,07fh,0ffh,000h,002h,080h,0c0h,0e0h,07ch,01eh	; 66cb  .888<>~.......|.
	defb 000h,010h	; 66db

; ----------------------------------------------------------------------
; DATOS patron_66dd: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x66dd..0x66e4  (7 bytes)
DATA_patron_66dd:
	defb 03eh,03eh,07ch,03ch,01ch,000h,01bh	; 66dd

; ----------------------------------------------------------------------
; DATOS parejas_66e4: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x66e4..0x66ee  (10 bytes)
DATA_parejas_66e4:
	defb 0ffh,001h	; 66e4
	defb 004h,005h	; 66e6
	defb 001h,004h	; 66e8
	defb 00fh,009h	; 66ea
	defb 018h,009h	; 66ec

; ----------------------------------------------------------------------
; DATOS patron_66ee: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x66ee..0x66fe  (16 bytes)
DATA_patron_66ee:
	defb 000h,00bh,001h,001h,001h,001h,000h,00ah,07ch,000h,001h,0ffh,0ebh,0e0h,0e0h,0f0h	; 66ee  ........|.......

; ----------------------------------------------------------------------
; DATOS patron_66fe: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x66fe..0x670e  (16 bytes)
DATA_patron_66fe:
	defb 000h,006h,003h,000h,00fh,0f8h,000h,001h,050h,078h,078h,033h,003h,03fh,07eh,070h	; 66fe  ........Pxx3.?~p

; ----------------------------------------------------------------------
; DATOS patron_670e: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x670e..0x671a  (12 bytes)
DATA_patron_670e:
	defb 000h,016h,00ch,00eh,00ah,00bh,001h,001h,001h,003h,002h,002h	; 670e  ............

; ----------------------------------------------------------------------
; DATOS patron_671a: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x671a..0x672c  (18 bytes)
DATA_patron_671a:
	defb 00fh,01ch,038h,038h,03eh,07eh,07eh,0ffh,07fh,000h,002h,0c0h,0c0h,0c0h,08ch,007h	; 671a  ..88>~~.........
	defb 000h,010h	; 672a

; ----------------------------------------------------------------------
; DATOS patron_672c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x672c..0x6734  (8 bytes)
DATA_patron_672c:
	defb 03eh,03eh,03eh,03eh,00eh,002h,000h,01ah	; 672c  >>>>....

; ----------------------------------------------------------------------
; DATOS parejas_6734: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6734..0x673e  (10 bytes)
DATA_parejas_6734:
	defb 0ffh,004h	; 6734
	defb 003h,006h	; 6736
	defb 0feh,006h	; 6738
	defb 00fh,00ah	; 673a
	defb 018h,00ah	; 673c

; ----------------------------------------------------------------------
; DATOS patron_673e: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x673e..0x6748  (10 bytes)
DATA_patron_673e:
	defb 000h,019h,03eh,000h,001h,0ffh,0f5h,0f0h,0f0h,078h	; 673e  ..>......x

; ----------------------------------------------------------------------
; DATOS patron_6748: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x6748..0x675e  (22 bytes)
DATA_patron_6748:
	defb 000h,006h,007h,000h,004h,030h,03ch,01ch,00ch,000h,007h,0f0h,000h,001h,0a0h,0f0h	; 6748  .....0<.........
	defb 0f0h,060h,002h,07fh,07eh,060h	; 6758

; ----------------------------------------------------------------------
; DATOS patron_675e: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x675e..0x676b  (13 bytes)
DATA_patron_675e:
	defb 000h,015h,006h,00dh,009h,009h,009h,00dh,006h,006h,004h,004h,004h	; 675e  .............

; ----------------------------------------------------------------------
; DATOS patron_676b: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x676b..0x677c  (17 bytes)
DATA_patron_676b:
	defb 01eh,038h,038h,038h,03eh,07ch,07ch,0feh,07eh,000h,003h,0c0h,0d0h,0dch,05eh,000h	; 676b  .888>||.~.....^.
	defb 010h	; 677b

; ----------------------------------------------------------------------
; DATOS patron_677c: Un sprite de 16x16 comprimido, 32 bytes al descomprimir
;   0x677c..0x6783  (7 bytes)
DATA_patron_677c:
	defb 07ch,07ch,07ch,03ch,02ch,000h,01bh	; 677c

; ----------------------------------------------------------------------
; DATOS parejas_6783: Las cinco (y,x) de una figura, con signo; 0xCF esconde
;   el sprite
;   0x6783..0x678d  (10 bytes)
DATA_parejas_6783:
	defb 0ffh,003h	; 6783
	defb 003h,007h	; 6785
	defb 000h,009h	; 6787
	defb 00fh,00bh	; 6789
	defb 018h,00bh	; 678b

; ======================================================================
; CODIGO 0x678d..0x6aa7  (794 bytes)
; ======================================================================


decide_el_rival:		; Elige a que jugador le toca ir a por la pelota y con que golpe
	ld a,(0e0a8h)		;678d   ; 0xE0A8 dice que hay una jugada viva
	or a			;6790
	ret z			;6791
	ld a,(0e0a9h)		;6792   ; 0xE0A9 cuenta los botes: al segundo, ya no hay nada que hacer
	cp 002h		;6795
	ret nc			;6797
	ld a,(0e044h)		;6798   ; 0xE044 congela la decision mientras haya un aviso
	or a			;679b
	ret nz			;679c
	ld a,(0e0a9h)		;679d   ; antes del primer bote, todos quietos
	or a			;67a0
	jr z,rival_elige_ficha		;67a1
	ld a,(0e043h)		;67a3   ; 0xE043 avisa de que la pelota viene hacia este lado
	or a			;67a6
	ret z			;67a7
rival_elige_ficha:		; El de arriba o el de abajo, segun el bando
	ld hl,0e100h		;67a8   ; el jugador de abajo
	ld de,0e160h		;67ab   ; y el de arriba
	call hay_dos_jugadores		;67ae   ; con dos jugadores, la pareja es la otra ficha
	jr nz,rival_elige_bando		;67b1
	ld e,030h		;67b3
rival_elige_bando:		; 0xE0D7 dice hacia donde va la pelota
	ld a,(0e0d7h)		;67b5   ; 0xE0D7 dice hacia donde va la pelota
	or a			;67b8
	jr nz,rival_mira_la_cara		;67b9
	ex de,hl			;67bb   ; y con eso se elige campo
rival_mira_la_cara:		; Y el byte 4 hacia donde mira el jugador
	ld a,(0e104h)		;67bc   ; el byte 4 de la ficha, con los bits de arriba
	and 0e0h		;67bf
	jr z,rival_manda_al_primero		;67c1
	ex de,hl			;67c3
rival_manda_al_primero:		; Primero el que esta mas cerca
	push hl			;67c4
	call manda_a_por_la_pelota		;67c5   ; primero el que esta mas cerca
	pop hl			;67c8
	call hay_dobles		;67c9   ; en dobles, tambien decide el companero
	ret nz			;67cc
	bit 7,(ix+00ch)		;67cd   ; si ya esta golpeando, no se le manda otra cosa
	ret nz			;67d1
	ld a,030h		;67d2   ; 0x30 es lo que ocupa una ficha
	call suma_a_hl		;67d4
	jr manda_a_por_la_pelota		;67d7
manda_a_por_la_pelota:		; Le dice a un jugador que vaya y con que golpe
	push hl			;67d9
	pop ix		;67da   ; IX es la ficha de este
	bit 7,(ix+00ch)		;67dc   ; el bit 7 del byte 12: ya esta a lo suyo
	ret nz			;67e0
	call lo_lleva_la_maquina		;67e1   ; humano o maquina
	jr nz,rival_comprueba_estado		;67e4
	ld a,(0e042h)		;67e6   ; 0xE042 dice de quien es el punto
	or a			;67e9
	jr z,rival_comprueba_estado		;67ea
	ld a,(0e0a9h)		;67ec   ; y si aun no ha botado, se espera
	or a			;67ef
	ret z			;67f0
	ld a,(0e0c0h)		;67f1   ; 0xE0C0 marca la pelota rodando por el suelo
	or a			;67f4
	ret nz			;67f5
	call hay_dobles		;67f6   ; en dobles hay una comprobacion mas
	jr nz,rival_comprueba_estado		;67f9
	bit 4,(hl)		;67fb   ; el bit 4 dice que ese ya va
	ret nz			;67fd
rival_comprueba_estado:		; El bit 0 separa al que juega del que mira
	ld a,(hl)			;67fe
	bit 0,a		;67ff   ; el bit 0 separa al que juega del que mira
	ret z			;6801
	push hl			;6802
	call posicion_de_la_pelota		;6803   ; saca la posicion de la pelota
	bit 3,a		;6806   ; el bit 3 es el que saca
	jr z,rival_acerca		;6808
	ld a,004h		;680a   ; con el saque se acerca poco
	jr rival_prueba_alcance		;680c
rival_acerca:		; Dieciseis mas, para llegar con margen
	ld a,010h		;680e   ; y si no, dieciseis mas
	add a,d			;6810
	ld d,a			;6811
	call donde_esta_la_pelota		;6812
	xor a			;6815
	pop hl			;6816
	bit 5,(hl)		;6817   ; el bit 5 cambia el modo de acercarse
	push hl			;6819
	jr z,rival_prueba_alcance		;681a
	ld a,002h		;681c
rival_prueba_alcance:		; Mira si ya la alcanza
	call hay_contacto		;681e   ; mira si ya la alcanza
	pop hl			;6821
	ret nc			;6822   ; si no llega, se acabo por este cuadro
	bit 5,(ix+000h)		;6823   ; el bit 5 del estado
	jr z,busca_la_franja		;6827
	ld a,(0e200h)		;6829   ; 0xE200 lleva las banderas del partido
	bit 6,a		;682c
	ret nz			;682e
busca_la_franja:		; Parte la pista en cuatro franjas y coloca al jugador en la suya
	push hl			;682f
	inc hl			;6830
	inc hl			;6831
	inc hl			;6832
	inc hl			;6833
	ld a,(hl)			;6834   ; el byte 4 es la postura
	push hl			;6835
	ld hl,00a04h		;6836   ; las cuatro franjas, con su ancho y su centro
	ld de,00406h		;6839
	ld b,e			;683c
	and 01fh		;683d   ; los cinco bits de abajo de la postura
	cp 008h		;683f   ; la primera franja llega hasta 8
	ld c,007h		;6841
	jr c,franja_centro		;6843
	ex de,hl			;6845
	ld c,00dh		;6846
	cp 00eh		;6848   ; la segunda hasta 14
	jr c,franja_centro		;684a
	ld de,01006h		;684c
	ld c,013h		;684f
	cp 014h		;6851   ; la tercera hasta 20
	jr c,franja_centro		;6853
	ld de,01604h		;6855   ; y la cuarta el resto
	ld c,019h		;6858
franja_centro:		; Compara con el centro de su franja
	pop hl			;685a
	ld a,(hl)			;685b
	and 01fh		;685c
	cp c			;685e   ; si ya esta en el centro de su franja, no se mueve
	jr z,franja_ya_esta		;685f
	sub d			;6861   ; y si no, se acerca
	jr nc,elige_la_fuerza		;6862
franja_ya_esta:		; Si ya esta, no se mueve
	pop hl			;6864
	ret			;6865
elige_la_fuerza:		; Segun donde este la pelota, con cuanta fuerza le da
	bit 5,(ix+000h)		;6866   ; el bit 5 lleva a la version corta
	jr z,iguala		;686a
	call lo_lleva_la_maquina		;686c   ; humano o maquina, otra vez
	jr nz,elige_el_efecto		;686f
	dec hl			;6871
	ld a,(hl)			;6872
	ld bc,00605h		;6873   ; seis y cinco de fuerza
	ld d,0ffh		;6876
	cp 070h		;6878   ; 0x70 parte la pista por la mitad
	jr nc,fuerza_por_el_punto		;687a
	ld bc,00100h		;687c   ; y en la otra mitad, uno y cero
	ld d,b			;687f
fuerza_por_el_punto:		; El punto decidido cambia los limites
	ld a,(0e042h)		;6880   ; 0xE042 dice de quien es el punto
	or a			;6883
	jr z,fuerza_mira_al_companero		;6884
	ld a,(hl)			;6886
	ld e,001h		;6887
	cp 043h		;6889   ; 0x43 y 0xA0 son las dos rayas de fondo
	jr c,clase_de_golpe		;688b
	ld e,005h		;688d
	cp 0a0h		;688f
	jr nc,clase_de_golpe		;6891
fuerza_mira_al_companero:		; 0x5D bytes atras esta su posicion
	push ix		;6893   ; y aqui se mira a la pareja
	pop hl			;6895
	ld a,l			;6896
	sub 05dh		;6897   ; 0x5D bytes mas atras esta su posicion
	ld l,a			;6899
	ld a,(hl)			;689a
	ld e,a			;689b
	cp 070h		;689c
	ld a,b			;689e
	jr nc,fuerza_signo		;689f
	ld a,c			;68a1
fuerza_signo:		; El bit 7 dice de que lado queda
	ld c,a			;68a2
	ld a,e			;68a3
	bit 7,a		;68a4   ; el bit 7 dice si la diferencia es negativa
	jr nz,fuerza_escalones		;68a6
	cpl			;68a8   ; y en ese caso se le da la vuelta
fuerza_escalones:		; Tres escalones, 0x20 y 0x40
	ld b,000h		;68a9
	and 07fh		;68ab
	cp 020h		;68ad   ; tres escalones: 0x20 y 0x40
	jr c,fuerza_aplica		;68af
	inc b			;68b1
	cp 040h		;68b2
	jr c,fuerza_aplica		;68b4
	inc b			;68b6
fuerza_aplica:		; Suma el paso tantas veces como escalones
	ld a,c			;68b7
	inc b			;68b8   ; y se suma el paso tantas veces como escalones
	dec b			;68b9
	jr z,fuerza_postura		;68ba
fuerza_suma:		; Una vez mas
	add a,d			;68bc
	djnz fuerza_suma		;68bd
fuerza_postura:		; Con la postura baja, un paso extra
	ld e,a			;68bf
	ld a,(ix+004h)		;68c0   ; con la postura por debajo de 8, un paso mas
	cp 008h		;68c3
	jr nc,fuerza_fin		;68c5
	ld a,e			;68c7
	add a,d			;68c8
	ld e,a			;68c9
fuerza_fin:		; Y a elegir la clase de golpe
	jr clase_de_golpe		;68ca
iguala:		; Acerca dos valores de uno en uno hasta que coinciden
	inc e			;68cc
	inc a			;68cd
iguala_vuelta:		; Un paso de acercamiento
	dec e			;68ce
	dec a			;68cf
	jr nz,iguala_vuelta		;68d0
elige_el_efecto:		; Saca de la tabla el efecto segun donde va a caer
	dec hl			;68d2
	ld a,(hl)			;68d3
	ld hl,06ac3h		;68d4   ; los umbrales estan en 0x6AC3
	push af			;68d7
	ld a,(ix+002h)		;68d8   ; el byte 2 es la fila del jugador
	cp 050h		;68db   ; 0x50 es la red
	jr nc,efecto_umbrales		;68dd
	ld a,004h		;68df   ; y del otro lado se usan los otros cuatro umbrales
	call suma_a_hl		;68e1
efecto_umbrales:		; Siete, y va bajando por cada uno que pase
	pop af			;68e4
	ld d,007h		;68e5   ; siete es el efecto mas fuerte
	cp (hl)			;68e7   ; y va bajando segun se pasa cada umbral
	jr nc,efecto_solo_maquina		;68e8
	inc hl			;68ea
	dec d			;68eb
	cp (hl)			;68ec
	jr nc,efecto_solo_maquina		;68ed
	dec d			;68ef
	cp 070h		;68f0   ; 0x70 es la mitad de la pista
	jr nc,efecto_solo_maquina		;68f2
	ld d,001h		;68f4   ; aqui empieza la otra escala
	inc hl			;68f6
	cp (hl)			;68f7
	jr nc,efecto_rebaja		;68f8
	inc hl			;68fa
	dec d			;68fb
	cp (hl)			;68fc
	jr nc,efecto_rebaja		;68fd
	ld d,008h		;68ff   ; ocho, el otro extremo
efecto_rebaja:		; Al humano se le quitan dos
	ld a,e			;6901   ; al humano se le rebaja dos
	dec a			;6902
	dec a			;6903
	ld e,a			;6904
efecto_solo_maquina:		; La rebaja solo vale si lo lleva la maquina
	call lo_lleva_la_maquina		;6905   ; pero solo si lo lleva la maquina
	jr z,clase_de_golpe		;6908
	ld e,d			;690a
clase_de_golpe:		; Deja en 0xE0D6 que golpe toca, mirando la altura de la pelota
	ld a,e			;690b
	ld (0e0d6h),a		;690c   ; 0xE0D6 es lo que luego lee 0x5492
	ld a,(0e0bbh)		;690f   ; 0xE0BB es la sombra
	ld d,a			;6912
	ld a,(0e0b7h)		;6913   ; y 0xE0B7 la pelota
	cp 0a0h		;6916   ; 0xA0 es el fondo de la pista
	jr c,golpe_por_la_altura		;6918
	call lo_lleva_la_maquina		;691a
	jr nz,golpe_por_la_altura		;691d
	ld e,004h		;691f   ; golpe 4: el de arriba del todo
	jp parametros_del_efecto		;6921
golpe_por_la_altura:		; La altura es la pelota menos su sombra
	sub d			;6924   ; la altura es la resta de las dos
	ld e,002h		;6925   ; golpe 2 por omision
	call lo_lleva_la_maquina		;6927
	jr nz,golpe_del_humano		;692a
	bit 3,(ix+000h)		;692c   ; el bit 3 es el saque, que va aparte
	jr nz,saca		;6930
	ld e,000h		;6932   ; pelota baja, golpe 0
	cp 006h		;6934   ; hasta seis de alto
	jr c,parametros_del_efecto		;6936
	inc e			;6938
	cp 00dh		;6939   ; golpe 1 hasta trece
	jr c,parametros_del_efecto		;693b
	ld hl,0e0dah		;693d   ; 0xE0DA es la opcion de partido elegida
	bit 0,(hl)		;6940
	jr z,golpe_tope		;6942
	ld e,006h		;6944   ; golpe 6 en la mas dificil
golpe_tope:		; Por encima de 0x20 ya no hay golpe que valga
	cp 020h		;6946   ; y por encima de 0x20 no se llega
	jr c,parametros_del_efecto		;6948
golpe_ninguno:		; Se sale sin elegir nada
	pop hl			;694a
	ret			;694b
golpe_del_humano:		; Al humano le tocan otros escalones
	ld e,003h		;694c   ; golpe 3 para el humano
	cp 00eh		;694e   ; entre catorce y cuarenta
	jr c,golpe_ninguno		;6950
	cp 028h		;6952
	jr nc,golpe_ninguno		;6954
	cp 01fh		;6956   ; y a partir de 0x1F, golpe 5
	jr nc,parametros_del_efecto		;6958
	ld e,005h		;695a
	jr parametros_del_efecto		;695c
saca:		; El saque tiene sus propias alturas
	push af			;695e
	ld a,(0e0b7h)		;695f   ; la altura a la que esta la pelota
	ld b,014h		;6962   ; veinte de margen
	cp 060h		;6964   ; 0x60 parte el saque en dos
	jr c,saque_comprueba		;6966
	ld b,020h		;6968   ; y arriba, treinta y dos
saque_comprueba:		; Con el margen que le toque
	pop af			;696a
	cp b			;696b
	jr nc,golpe_ninguno		;696c
	ld a,(0e0bbh)		;696e   ; otra vez la sombra
	ld b,a			;6971
	ld a,(0e0b7h)		;6972
	ld c,a			;6975
	sub b			;6976   ; y la altura
	push af			;6977
	ld b,008h		;6978   ; ocho de margen por abajo
	ld a,(0e0dah)		;697a   ; en la opcion 3 y con dos jugadores
	cp 003h		;697d
	jr nz,saque_recoloca		;697f
	call hay_dos_jugadores		;6981
	jr z,saque_recoloca		;6984
	ld a,(0e032h)		;6986   ; 0xE032 y 0xE033 son los tanteos de los dos
	cp 006h		;6989   ; con seis puntos, el margen se va a cero
	jr z,saque_sin_margen		;698b
	ld a,(0e033h)		;698d
	cp 006h		;6990
	jr nz,saque_recoloca		;6992
saque_sin_margen:		; Con seis puntos, cero margen
	ld b,000h		;6994
saque_recoloca:		; Ajusta la sombra si se queda corta
	pop af			;6996
	cp b			;6997
	jr c,golpe_ninguno		;6998
	cp 016h		;699a   ; por debajo de 0x16 la sombra se recoloca
	jr nc,saque_recoloca_alto		;699c
	push af			;699e
	ld a,c			;699f
	sub 016h		;69a0   ; restandole 0x16
	ld (0e0bbh),a		;69a2
	pop af			;69a5
saque_recoloca_alto:		; Y si se pasa por arriba
	cp 019h		;69a6   ; y por encima de 0x19, 0x18
	jr c,parametros_del_efecto		;69a8
	ld a,c			;69aa
	sub 018h		;69ab
	ld (0e0bbh),a		;69ad
parametros_del_efecto:		; Copia de la tabla los cuatro valores del golpe elegido
	ld a,e			;69b0   ; E trae la clase de golpe
	or a			;69b1
	rlca			;69b2   ; cuatro bytes por entrada
	rlca			;69b3
	ld hl,06aa7h		;69b4   ; la tabla vive en 0x6AA7
	call suma_a_hl		;69b7
	ld de,0e0aah		;69ba   ; y van a 0xE0AA, salteados de dos en dos
	ld b,004h		;69bd   ; cuatro valores
efecto_copia:		; Los cuatro valores, salteados de dos en dos
	ld a,(hl)			;69bf
	ld (de),a			;69c0
	inc hl			;69c1
	inc de			;69c2
	inc de			;69c3
	djnz efecto_copia		;69c4
	call lo_lleva_la_maquina		;69c6   ; el humano no lleva correccion
	jr z,correccion_por_la_zona		;69c9
	push ix		;69cb
	pop hl			;69cd
	ld a,090h		;69ce   ; 0x90 es la ficha del cuarto jugador
	cp l			;69d0
	ld d,0f4h		;69d1
	jr z,aplica_la_correccion		;69d3
correccion_por_la_zona:		; La correccion depende de por donde ande la pelota
	ld a,(0e0b7h)		;69d5   ; 0xE0B7 es la pelota
	cp 040h		;69d8   ; entre 0x40 y 0xA0 esta el centro de la pista
	jr c,correccion_por_la_altura		;69da
	cp 0a0h		;69dc
	jr nc,correccion_por_la_altura		;69de
	cp 087h		;69e0   ; y de ahi salen las correcciones de punteria
	ld d,010h		;69e2
	jr nc,aplica_la_correccion		;69e4
	ld d,030h		;69e6
	cp 06ah		;69e8
	jr nc,aplica_la_correccion		;69ea
	cp 05eh		;69ec
	jr c,correccion_minima		;69ee
	bit 3,(ix+000h)		;69f0   ; el bit 3 es el saque, que no se corrige
	jr nz,aplica_la_correccion		;69f4
	ld d,040h		;69f6
	jr aplica_la_correccion		;69f8
correccion_minima:		; Dieciseis, la mas suave
	ld d,010h		;69fa
aplica_la_correccion:		; Se le resta a 0xE0AC
	ld hl,0e0ach		;69fc
	ld a,(hl)			;69ff
	sub d			;6a00
	ld (hl),a			;6a01
correccion_por_la_altura:		; Y otra mas si la pelota va muy baja
	ld a,(0e0b7h)		;6a02   ; 0xE0B7 otra vez, para la correccion de altura
	call lo_lleva_la_maquina		;6a05
	jr z,golpe_de_que_lado		;6a08
	cp 028h		;6a0a   ; por debajo de 0x28 la pelota va muy baja
	jr nc,golpe_de_que_lado		;6a0c
	ld hl,0e0ach		;6a0e
	ld a,(hl)			;6a11
	sub 014h		;6a12   ; y se le rebaja el efecto veinte
	ld (hl),a			;6a14
golpe_de_que_lado:		; El bit 5 dice de que lado sale
	pop hl			;6a15
	bit 5,(hl)		;6a16   ; el bit 5 dice de que lado sale
	ld b,001h		;6a18
	jr z,golpe_con_dos		;6a1a
	inc b			;6a1c
golpe_con_dos:		; Con dos jugadores hay una vuelta mas
	call hay_dos_jugadores		;6a1d   ; con dos jugadores hay una vuelta mas
	jr nz,golpe_apunta		;6a20
	ld a,l			;6a22
	cp 030h		;6a23   ; 0x30 es la ficha del segundo
	jr nz,golpe_apunta		;6a25
	ld b,002h		;6a27
golpe_apunta:		; Deja pedida la trayectoria nueva
	ld a,b			;6a29
	ld (0e045h),a		;6a2a   ; 0xE045 corta el vuelo mientras se recalcula
	ld (0e0dbh),a		;6a2d   ; y 0xE0DB pide la trayectoria nueva
	ld b,a			;6a30
	ld a,(0e204h)		;6a31   ; 0xE204 lleva la cuenta de golpes seguidos
	cp 008h		;6a34
	jr c,golpe_banderas		;6a36
	ld a,b			;6a38
	and 001h		;6a39   ; a partir de ocho, solo cuenta la paridad
	ld b,a			;6a3b
golpe_banderas:		; Las banderas de los dos bandos
	ld a,b			;6a3c
	ld (0e200h),a		;6a3d   ; 0xE200 son las banderas del punto
	ld (0e205h),a		;6a40
	ld (0e240h),a		;6a43
	set 7,(ix+00ch)		;6a46   ; el bit 7 del byte 12: este ya ha golpeado
	ld a,002h		;6a4a
	call suena		;6a4c   ; el sonido de la raqueta
	ld a,(0e0aah)		;6a4f
	cp 015h		;6a52   ; 0x15 es el efecto que no lleva sonido extra
	jr z,golpe_mira_el_saque		;6a54
	ld a,004h		;6a56
	call suena		;6a58   ; y si no, suena tambien el segundo
golpe_mira_el_saque:		; Solo la maquina comprueba el saque
	call lo_lleva_la_maquina		;6a5b
	jr z,golpe_limpia		;6a5e
	and 0f8h		;6a60
	ld a,(ix+003h)		;6a62   ; el byte 3 es la columna del que golpea
	cp 058h		;6a65   ; 0x58 y 0x88 son las dos posiciones de saque
	jr z,saque_bueno		;6a67
	cp 088h		;6a69
	jr nz,golpe_limpia		;6a6b
saque_bueno:		; 0x86 es la altura del saque valido
	ld a,(0e0bbh)		;6a6d   ; y 0x86 la altura del saque bueno
	and 0feh		;6a70
	cp 086h		;6a72
	jr nz,golpe_limpia		;6a74
	ld a,(0e200h)		;6a76
	set 6,a		;6a79   ; el bit 6 de las banderas marca el saque valido
	ld (0e200h),a		;6a7b
golpe_limpia:		; Deja las banderas del punto como estaban
	xor a			;6a7e
	ld (0e0c0h),a		;6a7f   ; 0xE0C0 a cero: la pelota deja de rodar
	ld (0e04dh),a		;6a82
	ld (0e043h),a		;6a85   ; 0xE043 a cero: ya no viene hacia aqui
	ld (0e0a9h),a		;6a88   ; y 0xE0A9 reinicia la cuenta de botes
	ld (0e0c4h),a		;6a8b
	call lo_lleva_la_maquina		;6a8e   ; humano o maquina
	jr nz,golpe_del_rival		;6a91
	xor a			;6a93
	ld (0e042h),a		;6a94   ; 0xE042 a cero: el punto vuelve a estar abierto
	ld a,(0e20ah)		;6a97   ; 0xE20A cuenta los golpes del humano
	inc a			;6a9a
	ld (0e20ah),a		;6a9b
	jp recalcula_la_trayectoria		;6a9e   ; y se recalcula la trayectoria
golpe_del_rival:		; Al rival se le sube el contador del byte 12
	inc (ix+00ch)		;6aa1   ; el byte 12 del rival sube uno
	jp recalcula_la_trayectoria		;6aa4

; ----------------------------------------------------------------------
; DATOS efectos_del_golpe: Cuatro bytes por clase de golpe: los que 0x69B0
;   copia a 0xE0AA
;   0x6aa7..0x6ac3  (28 bytes)
DATA_efectos_del_golpe:
	defb 015h,0ffh,06ch,0e7h	; 6aa7
	defb 008h,0d4h,0b3h,0b3h	; 6aab
	defb 005h,0b0h,0ffh,004h	; 6aaf
	defb 004h,0c8h,0feh,01bh	; 6ab3
	defb 007h,0e0h,0a4h,0c3h	; 6ab7
	defb 006h,0c0h,0ddh,080h	; 6abb
	defb 003h,0e0h,0e7h,06ch	; 6abf

; ----------------------------------------------------------------------
; DATOS umbrales_del_efecto: Ocho umbrales, cuatro por cada lado de la red,
;   que lee 0x68D4
;   0x6ac3..0x6acb  (8 bytes)
DATA_umbrales_del_efecto:
	defb 0a2h,07ah,060h,034h	; 6ac3
	defb 09ah,088h,060h,057h	; 6ac7

; ======================================================================
; CODIGO 0x6acb..0x6b09  (62 bytes)
; ======================================================================


hay_contacto:		; Dice si dos cosas se tocan, comparando la distancia con un rectangulo
	ld hl,06b09h		;6acb   ; los rectangulos estan en 0x6B09
	or a			;6ace
	rlca			;6acf   ; cuatro bytes por entrada
	rlca			;6ad0
	call suma_a_hl		;6ad1
	ld a,d			;6ad4   ; la distancia en un eje
	sub b			;6ad5
	push hl			;6ad6
	call dentro_del_margen		;6ad7   ; se prueba contra los dos primeros
	pop hl			;6ada
	ret nc			;6adb   ; si ese eje ya no encaja, no hay contacto
	inc hl			;6adc   ; y ahora los otros dos bytes
	inc hl			;6add
	ld a,e			;6ade   ; la distancia en el otro eje
	sub c			;6adf
dentro_del_margen:		; Comprueba que un valor cae entre dos limites, con signo
	jr c,margen_negativo		;6ae0   ; si la resta salio negativa, va por el otro camino
	inc hl			;6ae2
	bit 7,(hl)		;6ae3   ; el bit 7 dice que el limite es negativo
	jr nz,margen_fuera		;6ae5
	cp (hl)			;6ae7   ; por arriba
	ret nc			;6ae8
	dec hl			;6ae9
	bit 7,(hl)		;6aea
	ret nz			;6aec
	cp (hl)			;6aed   ; y por abajo
	jr c,margen_fuera		;6aee
	scf			;6af0   ; dentro: acarreo puesto
	ret			;6af1
margen_fuera:		; Acarreo limpio: no hay contacto
	or a			;6af2   ; y fuera: acarreo limpio
	ret			;6af3
margen_negativo:		; El mismo rango, cuando la distancia salio del otro lado
	bit 7,(hl)		;6af4   ; con el limite positivo no hay nada que hacer
	jr z,margen_negativo_fuera		;6af6
	inc hl			;6af8
	bit 7,(hl)		;6af9   ; y aqui los dos son negativos
	jr nz,margen_negativo_arriba		;6afb
	dec hl			;6afd
	cp (hl)			;6afe   ; se comparan al reves
	ccf			;6aff
	ret			;6b00
margen_negativo_arriba:		; El limite de arriba, con los dos negativos
	cp (hl)			;6b01   ; el de arriba
	jr c,margen_negativo_fuera		;6b02
	dec hl			;6b04
	cp (hl)			;6b05   ; y el de abajo
	ret c			;6b06
margen_negativo_fuera:		; Y fuera
	or a			;6b07
	ret			;6b08

; ----------------------------------------------------------------------
; DATOS rectangulos_de_alcance: Siete rectangulos de cuatro bytes con signo,
;   para 0x6ACB
;   0x6b09..0x6b25  (28 bytes)
DATA_rectangulos_de_alcance:
	defb 0eeh,016h,0f0h,0dbh	; 6b09
	defb 0e0h,00ah,0f0h,0dch	; 6b0d
	defb 0d0h,01fh,0f8h,0e0h	; 6b11
	defb 0ech,014h,0e8h,018h	; 6b15
	defb 0e0h,008h,0fah,0e6h	; 6b19
	defb 0e0h,006h,0f0h,0d4h	; 6b1d
	defb 0deh,003h,0f0h,004h	; 6b21

; ======================================================================
; CODIGO 0x6b25..0x6e61  (828 bytes)
; ======================================================================


juega_la_maquina:		; Le pone al rival la pulsacion que le tocaria a un humano
	call hay_dos_jugadores		;6b25   ; con un solo jugador no hay nada de esto
	ret z			;6b28
	ld a,(0e060h)		;6b29   ; 0xE060 congela durante un aviso
	or a			;6b2c
	ret nz			;6b2d
	call puede_golpear		;6b2e   ; primero mira si ya puede golpear
	ld ix,0e160h		;6b31   ; 0xE160 es el jugador de arriba
	ld iy,0e100h		;6b35   ; y 0xE100 el de abajo, que es su referencia
	ld hl,0e200h		;6b39   ; 0xE200 son sus banderas
	call busca_el_destino		;6b3c
	call hay_dobles		;6b3f   ; en dobles hay una pareja mas
	ret nz			;6b42
	ld ix,0e190h		;6b43   ; 0xE190
	ld iy,0e130h		;6b47
	ld hl,0e205h		;6b4b
busca_el_destino:		; Decide a que punto de la pista tiene que ir el rival
	ld a,(hl)			;6b4e
	rrca			;6b4f   ; el bit 0 de las banderas: ya tiene destino
	jr c,destino_espera		;6b50
	ld bc,0086ah		;6b52   ; 0x6A y 0x08 son el punto de espera
	push af			;6b55
	call hay_dobles		;6b56   ; en dobles se reparten la pista
	jr nz,destino_ya_puesto		;6b59
	bit 4,(ix+000h)		;6b5b   ; el bit 4 dice que este va a por la pelota
	jr z,destino_ya_puesto		;6b5f
	ld b,030h		;6b61   ; y el companero se queda mas atras
destino_ya_puesto:		; Si ya tenia destino, se salta la decision
	pop af			;6b63
	res 2,(hl)		;6b64   ; el bit 2 se limpia en cada decision
	rrca			;6b66
	jr nc,destino_pulsa		;6b67
	jr destino_apunta		;6b69
destino_espera:		; Con la pelota de frente, se queda quieto
	ld a,(0e0d7h)		;6b6b   ; 0xE0D7 dice hacia donde va la pelota
	or a			;6b6e
	ret nz			;6b6f   ; si viene de frente, se espera
	ld a,(hl)			;6b70
	and 0f1h		;6b71   ; se limpian los bits de movimiento
	ld (hl),a			;6b73
	push hl			;6b74
	pop de			;6b75
	call lo_lleva_la_maquina		;6b76
	jr nz,destino_donde_cae		;6b79
	ex de,hl			;6b7b
	inc hl			;6b7c
	inc hl			;6b7d
	inc hl			;6b7e
	dec (hl)			;6b7f   ; el byte 3 de las banderas es una cuenta atras
	ex de,hl			;6b80
	jr nz,destino_pulsa		;6b81   ; hasta que llega a cero no se decide otra vez
	ex de,hl			;6b83
	inc hl			;6b84
	ld a,(hl)			;6b85
	rlca			;6b86   ; y entonces se recarga girando el byte siguiente
	rlca			;6b87
	rlca			;6b88
	dec hl			;6b89
	ld (hl),a			;6b8a
	ex de,hl			;6b8b
destino_donde_cae:		; Se va a donde va a caer la pelota
	ld a,(hl)			;6b8c
	and 0f0h		;6b8d
	ld (hl),a			;6b8f
	ld a,(0e0deh)		;6b90   ; 0xE0DE es donde va a caer la pelota
	ld c,a			;6b93
	ld b,050h		;6b94   ; 0x50 es la altura a la que se coloca
	call hay_dobles		;6b96
	jr nz,destino_por_el_punto		;6b99
	bit 4,(ix+000h)		;6b9b   ; el bit 4 otra vez: quien va a por ella
	jr nz,destino_margen		;6b9f
	jr destino_a_la_red		;6ba1
destino_por_el_punto:		; El punto decidido cambia el sitio
	ld a,(0e042h)		;6ba3   ; 0xE042 dice de quien es el punto
	or a			;6ba6
	jr nz,destino_a_la_red		;6ba7
	ld a,(0e0ddh)		;6ba9   ; 0xE0DD es la columna donde cae
	cp 0c0h		;6bac   ; por encima de 0xC0 se planta arriba del todo
	jr c,destino_se_queda		;6bae
	ld b,010h		;6bb0
	jr destino_margen		;6bb2
destino_se_queda:		; Por debajo de 0x42 no se mueve
	cp 042h		;6bb4   ; y por debajo de 0x42, se queda donde esta
	jr nc,destino_margen		;6bb6
destino_a_la_red:		; 0xD5 es la fila de la red
	ld d,0d5h		;6bb8   ; 0xD5 es la fila de la red vista desde arriba
	ld bc,(0e0dch)		;6bba   ; 0xE0DC trae la caida ya calculada
	ld a,d			;6bbe
	add a,b			;6bbf
	cp 0a0h		;6bc0   ; sin pasarse de 0xA0
	jr c,destino_tope		;6bc2
	ld a,001h		;6bc4
destino_tope:		; Sin pasarse de 0xA0
	ld b,a			;6bc6
destino_margen:		; Diez menos, para llegar con margen
	ld a,c			;6bc7
	sub 00ah		;6bc8   ; y diez menos, para llegar con margen
	ld c,a			;6bca
destino_apunta:		; Guarda cuanto le falta
	push hl			;6bcb
	call apunta_al_destino		;6bcc
	pop hl			;6bcf
	ld a,(hl)			;6bd0   ; deja el bit 3: ya tiene a donde ir
	and 0f2h		;6bd1
	or 008h		;6bd3
	ld (hl),a			;6bd5
destino_pulsa:		; Y de ahi salen las direcciones del mando
	jr pulsa_por_el		;6bd6
apunta_al_destino:		; Guarda cuanto le falta al rival para llegar, con su pizca de fallo
	ld d,(ix+002h)		;6bd8   ; el byte 2 es su fila
	ld a,b			;6bdb   ; lo que le falta en ese eje
	sub d			;6bdc
	inc hl			;6bdd
	ld (hl),a			;6bde
	ld e,(ix+003h)		;6bdf   ; y el byte 3 su columna
	ld a,c			;6be2
	sub e			;6be3
	call lo_lleva_la_maquina		;6be4   ; al humano no se le pone fallo
	jr z,apunta_el_eje		;6be7
	ld a,r		;6be9   ; el registro de refresco de la memoria, que el Z80 mueve solo:
	rrca			;6beb   ; es de donde sale el temblor de la punteria del rival
	rrca			;6bec
	ld b,a			;6bed
	ld a,(0e000h)		;6bee   ; 0xE000 es el contador de cuadros
	cp 080h		;6bf1   ; y en la mitad de los cuadros no falla nada
	jr c,fallo_del_rival		;6bf3
	ld b,000h		;6bf5
fallo_del_rival:		; El temblor que le pone el registro R
	ld a,b			;6bf7
apunta_el_eje:		; Lo que falta por el segundo eje
	inc hl			;6bf8
	ld (hl),a			;6bf9
	ret			;6bfa
pulsa_por_el:		; Convierte la distancia que falta en direcciones de mando
	bit 0,(ix+000h)		;6bfb   ; el bit 0: este esta parado
	jr nz,pulsacion_ninguna		;6bff
	ld b,000h		;6c01
	ld a,(hl)			;6c03
	and 00eh		;6c04   ; los tres bits de la distancia
	ld a,b			;6c06
	jr z,pulsacion_nueva		;6c07
	push hl			;6c09
	ld b,002h		;6c0a   ; el eje de las filas
	call acerca_un_paso		;6c0c
	ld c,b			;6c0f
	ld b,008h		;6c10   ; y el de las columnas
	call acerca_un_paso		;6c12
	ld a,c			;6c15
	or b			;6c16   ; si no falta nada por ninguno, ya esta colocado
	pop hl			;6c17
	or a			;6c18
	jr nz,pulsacion_nueva		;6c19
	bit 1,(hl)		;6c1b   ; el bit 1 es el que ya llego
	jr nz,pulsacion_nueva		;6c1d
	push hl			;6c1f
	ld hl,0e0a9h		;6c20   ; 0xE0A9 lleva la cuenta de botes
	cp (hl)			;6c23
	pop hl			;6c24
	jr nz,pulsacion_nueva		;6c25
	ld a,(hl)			;6c27
	and 0f0h		;6c28   ; se le limpian los bits de direccion
	ld (hl),a			;6c2a
	call lo_lleva_la_maquina		;6c2b
	jr z,pulsacion_nueva		;6c2e
	set 0,(hl)		;6c30   ; y el bit 0 marca que este se planta
pulsacion_nueva:		; Compara con lo que se pidio el cuadro anterior
	cp (ix+006h)		;6c32   ; el byte 6 guarda lo que se pidio el cuadro anterior
	ld (ix+006h),a		;6c35
	jr z,pulsacion_disparo		;6c38
pulsacion_ninguna:		; Sin direccion
	xor a			;6c3a
pulsacion_disparo:		; Y el bit 4, que es el boton
	bit 4,(hl)		;6c3b   ; el bit 4 es el disparo
	jr z,pulsacion_guarda		;6c3d
	set 4,a		;6c3f
pulsacion_guarda:		; Todo junto al byte 7 de la ficha
	ld (ix+007h),a		;6c41   ; y todo junto va al byte 7, que es el que lee 0x55C9
	ret			;6c44
acerca_un_paso:		; Da un paso hacia el destino por un eje, y devuelve si ya llego
	inc hl			;6c45
	ld a,(hl)			;6c46
	ld e,a			;6c47
	ld a,(0e060h)		;6c48   ; 0xE060 congela durante un aviso
	or a			;6c4b
	ld a,e			;6c4c
	jr nz,paso_de_la_maquina		;6c4d
	call lo_lleva_la_maquina		;6c4f   ; al humano se le dejan mas bits
	jr z,paso_de_la_maquina		;6c52
	and 00fh		;6c54
	jr paso_ninguno		;6c56
paso_de_la_maquina:		; A la maquina se le dejan siete bits
	and 07fh		;6c58   ; y a la maquina, siete
paso_ninguno:		; Si no falta nada, no hay paso
	jr nz,paso_hacia_atras		;6c5a   ; si no falta nada, no hay paso
	ld b,a			;6c5c
	ret			;6c5d
paso_hacia_atras:		; Uno menos
	bit 7,(hl)		;6c5e   ; el bit 7 dice hacia que lado
	jr nz,paso_hacia_delante		;6c60
	dec (hl)			;6c62   ; uno menos
	ret			;6c63
paso_hacia_delante:		; Uno mas, con el paso a la mitad
	srl b		;6c64   ; o uno mas, y con el paso a la mitad
	inc (hl)			;6c66
	ret			;6c67
puede_golpear:		; Mira si el rival tiene la pelota al alcance de la raqueta
	ld hl,0e160h		;6c68   ; 0xE160, el de arriba
	ld de,0e200h		;6c6b
	call prueba_el_alcance		;6c6e
	call hay_dobles		;6c71   ; en dobles, tambien el companero
	ret nz			;6c74
	ld hl,0e190h		;6c75   ; 0xE190
	ld de,0e205h		;6c78
prueba_el_alcance:		; Compara la pelota con la raqueta y enciende el bit 4
	ld a,(0e0d7h)		;6c7b   ; 0xE0D7: si la pelota va hacia el otro lado, no hay nada que hacer
	or a			;6c7e
	ret nz			;6c7f
	push hl			;6c80
	pop ix		;6c81
	push de			;6c83
	call posicion_de_la_pelota		;6c84   ; la posicion de la pelota
	ld a,001h		;6c87
	bit 2,(ix+000h)		;6c89   ; el bit 2 amplia el alcance
	jr z,alcance_prueba		;6c8d
	ld a,005h		;6c8f
alcance_prueba:		; Con el rectangulo que le toque
	call hay_contacto		;6c91   ; rectangulo 1 o rectangulo 5
	pop hl			;6c94
	jr c,alcance_si		;6c95
alcance_no:		; Bit 4 apagado: no llega
	res 4,(hl)		;6c97   ; fuera de alcance: bit 4 apagado
	ret			;6c99
alcance_si:		; Bit 4 encendido
	set 4,(hl)		;6c9a   ; y dentro: encendido
	call lo_lleva_la_maquina		;6c9c
	ret z			;6c9f
	ld a,(0e0a8h)		;6ca0   ; 0xE0A8 dice si la jugada esta viva
	or a			;6ca3
	jr nz,alcance_ritmo		;6ca4
	ld a,(0e000h)		;6ca6   ; con la jugada parada, el rival no se lanza
	and 0ffh		;6ca9
	jr nz,alcance_no		;6cab
	ret			;6cad
alcance_ritmo:		; Con la jugada viva, uno de cada pocos cuadros
	ld a,(0e000h)		;6cae
	and 006h		;6cb1   ; y con ella viva, uno de cada pocos cuadros
	jr z,alcance_no		;6cb3
	ld a,(0e0bbh)		;6cb5   ; la sombra
	ld b,a			;6cb8
	ld a,(0e0b7h)		;6cb9   ; y la pelota: su resta es la altura
	sub b			;6cbc
	cp 018h		;6cbd   ; entre 0x18 y 0x28 de alto es la banda buena para pegarle
	jr c,alcance_no		;6cbf
	cp 028h		;6cc1
	jr nc,alcance_no		;6cc3
	ret			;6cc5
mira_a_la_pareja:		; Compara las dos fichas de un bando para no estorbarse
	ld hl,0e100h		;6cc6   ; el de abajo
	ld de,0e130h		;6cc9   ; y el de arriba
	ld b,008h		;6ccc   ; el byte 8
	ld a,(0e0d7h)		;6cce   ; 0xE0D7 elige que bando se mira
	or a			;6cd1
	jr nz,pareja_mira_la_cara		;6cd2
	ld l,060h		;6cd4   ; 0xE160
	ld b,006h		;6cd6
	call hay_dos_jugadores		;6cd8   ; con dos jugadores, la otra ficha es 0xE130
	jr nz,pareja_mira_la_cara		;6cdb
	ld l,030h		;6cdd
	ld e,000h		;6cdf
pareja_mira_la_cara:		; El byte 4 con los bits de arriba
	ld a,(0e104h)		;6ce1   ; el byte 4 con los bits de arriba
	and 0e0h		;6ce4
	jr z,pareja_compara		;6ce6
	ex de,hl			;6ce8
pareja_compara:		; Y se mira si estan juntos
	push bc			;6ce9
	call estan_juntos		;6cea
	pop bc			;6ced
	call hay_dobles		;6cee   ; en dobles hay una pareja mas
	ret nz			;6cf1
	ld a,030h		;6cf2
	call suma_a_hl		;6cf4
estan_juntos:		; Enciende el bit 3 si los dos estan a menos de diez
	push hl			;6cf7
	inc hl			;6cf8
	inc hl			;6cf9
	ld e,(hl)			;6cfa   ; el byte 2 del primero
	ld a,b			;6cfb
	call suma_a_hl		;6cfc   ; y el mismo byte del otro
	ld a,(hl)			;6cff
	sub e			;6d00   ; la distancia entre los dos
	jp p,juntos_al_parado		;6d01   ; en valor absoluto
	neg		;6d04
juntos_al_parado:		; Al parado no se le toca
	pop hl			;6d06
	bit 0,(hl)		;6d07   ; al parado no se le toca
	ret nz			;6d09
	res 3,(hl)		;6d0a   ; el bit 3 se apaga
	cp 00ah		;6d0c   ; y solo se enciende si estan a menos de diez
	ret nc			;6d0e
	set 3,(hl)		;6d0f
	ret			;6d11
cambia_de_lado:		; En dobles, los dos de cada bando se intercambian el sitio
	call hay_dobles		;6d12   ; esto solo pasa en dobles
	ret nz			;6d15
	ld hl,0e127h		;6d16   ; el byte 0x27 de la primera pareja
	ld de,0e157h		;6d19   ; y el de la segunda
	call intercambia_puestos		;6d1c
	ld hl,0e187h		;6d1f   ; la otra pareja
	ld de,0e1b7h		;6d22
intercambia_puestos:		; Cambia el destino de VRAM de dos jugadores y los redibuja
	ld a,(hl)			;6d25   ; se guarda el de uno
	ex af,af'			;6d26
	ld a,(de)			;6d27   ; se le pone el del otro
	ld (hl),a			;6d28
	ex af,af'			;6d29
	ld (de),a			;6d2a   ; y al otro el del primero
	push de			;6d2b
	call redibuja_ficha		;6d2c
	pop hl			;6d2f
redibuja_ficha:		; Retrocede al principio de la ficha y le vuelca los atributos
	ld a,l			;6d30
	sub 027h		;6d31   ; 0x27 bytes atras esta el principio
	ld l,a			;6d33
	push hl			;6d34
	pop ix		;6d35
	jp vuelca_los_atributos		;6d37
prepara_el_saque:		; Decide quien saca, de que lado, y recoloca a todos
	call hay_dobles		;6d3a
	ld e,001h		;6d3d   ; en individuales el turno alterna entre dos
	jr nz,saque_primero		;6d3f
	ld e,003h		;6d41   ; y en dobles, entre cuatro
saque_primero:		; Al empezar, saca el cuarto
	ld a,(0e042h)		;6d43   ; 0xE042 dice si el punto ya esta cerrado
	or a			;6d46
	ld c,004h		;6d47   ; al empezar, saca el cuarto
	jr z,saque_recorre_fichas		;6d49
	ld a,(0e050h)		;6d4b   ; 0xE050 lleva de quien es el saque
	and e			;6d4e
	ld e,a			;6d4f
	cp 001h		;6d50
	jr nz,saque_dos_jugadores		;6d52
	ld e,002h		;6d54   ; y va rotando
	ex af,af'			;6d56
	call hay_dos_jugadores		;6d57   ; con dos jugadores, uno menos
	jr nz,saque_ajusta		;6d5a
	dec e			;6d5c
saque_ajusta:		; Con dos jugadores, uno menos
	ex af,af'			;6d5d
saque_dos_jugadores:		; El turno alterna de dos en dos
	cp 002h		;6d5e
	jr nz,saque_guarda_turno		;6d60
	ld e,001h		;6d62
saque_guarda_turno:		; El turno elegido
	ld a,e			;6d64
	ld c,a			;6d65
	ld d,a			;6d66
saque_recorre_fichas:		; Las cuatro, una a una
	ld hl,0e0dch		;6d67   ; 0xE0DC en adelante, las cuatro fichas
	ld b,004h		;6d6a   ; cuatro jugadores
	inc c			;6d6c
saque_ficha:		; 0x24 bytes hasta el byte de estado
	ld a,024h		;6d6d   ; 0x24 bytes hasta el byte de estado
	call suma_a_hl		;6d6f
	ld a,(hl)			;6d72
	and 032h		;6d73   ; se le deja el estado en 4: esperando
	or 004h		;6d75
	ld (hl),a			;6d77
	inc hl			;6d78
	ld (hl),00ah		;6d79   ; diez cuadros de espera
	inc hl			;6d7b
	inc hl			;6d7c
	inc hl			;6d7d
	ld a,(hl)			;6d7e
	and 0e0h		;6d7f   ; y la postura limpia
	ld (hl),a			;6d81
	ld a,008h		;6d82   ; ocho bytes mas alla
	call suma_a_hl		;6d84
	xor a			;6d87
	ld (hl),a			;6d88
	dec c			;6d89   ; al que le toca sacar se le pone a uno
	jr nz,saque_siguiente_ficha		;6d8a
	inc a			;6d8c
	ld (hl),a			;6d8d
	push bc			;6d8e
	push hl			;6d8f
	ld a,l			;6d90
	and 0f0h		;6d91   ; el principio de su ficha
	ld l,a			;6d93
	ld b,080h		;6d94   ; 0x80 es el bit de un lado
	push hl			;6d96
	inc hl			;6d97
	inc hl			;6d98
	bit 7,(hl)		;6d99   ; y el bit 7 del byte 2 elige entre los dos
	pop hl			;6d9b
	jr z,saque_marca_el_lado		;6d9c
	ld b,040h		;6d9e   ; 0x40 es el otro
saque_marca_el_lado:		; 0x80 o 0x40, segun el lado
	ld a,(hl)			;6da0
	or b			;6da1
	ld (hl),a			;6da2
	pop hl			;6da3
	pop bc			;6da4
saque_siguiente_ficha:		; Y a por la siguiente
	djnz saque_ficha		;6da5   ; y vuelta con el siguiente jugador
	xor a			;6da7
	ld (0e20ah),a		;6da8   ; 0xE20A a cero: empieza a contarse el peloteo
	ld a,(0e042h)		;6dab   ; si el punto no estaba cerrado, aqui se acaba
	or a			;6dae
	ret z			;6daf
	ld c,d			;6db0
	ld hl,0e200h		;6db1   ; 0xE200 y 0xE205 son las banderas de los dos bandos
	ld de,0e205h		;6db4
	ld a,(0e16ch)		;6db7   ; el byte 12 del tercero dice quien lleva la iniciativa
	bit 0,a		;6dba
	jr nz,saque_banderas		;6dbc
	ex de,hl			;6dbe
saque_banderas:		; Al que saca se le pone el bit 3
	ld (hl),008h		;6dbf   ; al que saca se le pone el bit 3
	xor a			;6dc1
	ld (de),a			;6dc2   ; y al otro se le limpia
	push de			;6dc3
	push hl			;6dc4
	inc hl			;6dc5
	inc hl			;6dc6
	inc hl			;6dc7
	inc de			;6dc8
	inc de			;6dc9
	inc de			;6dca
	ld a,010h		;6dcb   ; dieciseis cuadros de cuenta atras a los dos
	ld (hl),a			;6dcd
	ld (de),a			;6dce
	pop hl			;6dcf
	pop de			;6dd0
	xor a			;6dd1
	ld (0e0e2h),a		;6dd2   ; 0xE0E2 a cero
	call hay_dobles		;6dd5   ; lo de abajo es solo de dobles
	ret nz			;6dd8
	bit 1,c		;6dd9   ; el bit 1 del turno
	jr nz,saque_pareja_de_abajo		;6ddb
	xor a			;6ddd
	ld (de),a			;6dde
	ld (hl),a			;6ddf
saque_pareja_de_abajo:		; Los dos de abajo, a repartirse
	ld hl,0e100h		;6de0   ; los dos del bando de abajo
	ld de,0e130h		;6de3
	call quien_esta_delante		;6de6   ; se mira cual esta mas adelantado
	ld b,000h		;6de9   ; y se reparten los papeles segun eso
	jr c,saque_pareja_de_arriba		;6deb
	ld b,010h		;6ded
saque_pareja_de_arriba:		; Y los de arriba
	call reparte_papeles		;6def
	ld l,090h		;6df2   ; 0xE190 y 0xE160, los de arriba
	ld e,060h		;6df4
	call quien_esta_delante		;6df6
	ld b,020h		;6df9
	jr nc,saque_reparte		;6dfb
	ld b,030h		;6dfd
saque_reparte:		; Con el papel que le toca a cada uno
	jr reparte_papeles		;6dff
quien_esta_delante:		; Compara el byte 2 de dos fichas
	inc hl			;6e01
	inc hl			;6e02
	inc de			;6e03
	inc de			;6e04
	ld c,(hl)			;6e05   ; el de la primera
	ld a,(de)			;6e06   ; y el de la segunda
	cp c			;6e07
	ret			;6e08
reparte_papeles:		; Marca cual de los dos es el de red y cual el de fondo
	dec hl			;6e09
	dec hl			;6e0a
	dec de			;6e0b
	dec de			;6e0c
	ld a,b			;6e0d
	ld c,a			;6e0e
	ld a,(hl)			;6e0f   ; al primero se le pone el bit que le toque
	and 0efh		;6e10
	or b			;6e12
	ld (hl),a			;6e13
	ld a,(de)			;6e14   ; y al segundo el contrario
	and 0efh		;6e15
	ld b,a			;6e17
	ld a,c			;6e18
	cpl			;6e19   ; invirtiendo el bit 4
	and 010h		;6e1a
	or b			;6e1c
	ld (de),a			;6e1d
	ret			;6e1e
posturas_de_dobles:		; Deja a la pareja de arriba mirando como toca
	call hay_dobles		;6e1f   ; solo en dobles
	ret nz			;6e22
	ld a,(0e050h)		;6e23   ; 0xE050 dice de quien es el saque
	ld de,03424h		;6e26   ; los dos estados posibles
	rrca			;6e29
	jr nc,dobles_guarda_posturas		;6e2a
	rrca			;6e2c
	jr c,dobles_guarda_posturas		;6e2d
	ld a,e			;6e2f   ; y segun el turno se intercambian
	ld e,d			;6e30
	ld d,a			;6e31
dobles_guarda_posturas:		; Una para cada uno de los de arriba
	ld a,d			;6e32
	ld (0e160h),a		;6e33   ; 0xE160
	ld a,e			;6e36
	ld (0e190h),a		;6e37   ; y 0xE190
	ret			;6e3a
pon_la_dificultad:		; La dificultad sube con lo que dura el peloteo
	ld a,(0e0dah)		;6e3b   ; 0xE0DA es la opcion elegida en el GAME SELECT
	dec a			;6e3e
	sla a		;6e3f   ; dos bytes por entrada
	ld hl,06e61h		;6e41   ; y la tabla de 0x6E61 tiene una curva por opcion
	call busca_en_tabla_desde		;6e44
	ld a,005h		;6e47   ; cinco de base
	ld c,a			;6e49
	ld a,(0e20ah)		;6e4a   ; 0xE20A cuenta los golpes que lleva el peloteo
	srl a		;6e4d   ; de dos en dos
	cp 00fh		;6e4f   ; y a partir del golpe treinta ya no sube mas
	jr c,dificultad_busca		;6e51
	ld a,00fh		;6e53
dificultad_busca:		; El paso de la curva que toque
	call suma_a_hl		;6e55   ; se busca en la curva
	ld a,(hl)			;6e58
	add a,c			;6e59
	ld (0e204h),a		;6e5a   ; 0xE204 y 0xE209 son la dificultad de cada bando
	ld (0e209h),a		;6e5d
	ret			;6e60

; ----------------------------------------------------------------------
; DATOS tabla_de_dificultad: Un puntero por opcion del GAME SELECT
;   0x6e61..0x6e67  (6 bytes)
DATA_6E61:
	defw 06e67h,06e77h,06e87h	; 6e61  -> DATA_curvas_de_dificultad 0x6e77 0x6e87

; ----------------------------------------------------------------------
; DATOS curvas_de_dificultad: Tres curvas de dieciseis pasos: la dificultad
;   sube con lo que dura el peloteo
;   0x6e67..0x6e97  (48 bytes)
DATA_curvas_de_dificultad:
	defb 000h,003h,004h,005h,004h,003h,002h,001h,002h,001h,003h,005h,007h,009h,00bh,009h	; 6e67  ................
	defb 0fch,001h,000h,0ffh,002h,001h,001h,0ffh,0feh,0fdh,000h,001h,003h,004h,000h,007h	; 6e77  ................
	defb 0fch,0fch,0fch,0fch,0fch,0fch,0fch,0feh,0feh,0ffh,000h,000h,001h,002h,003h,006h	; 6e87  ................

; ======================================================================
; CODIGO 0x6e97..0x715d  (710 bytes)
; ======================================================================


rota_las_parejas:		; Cambia de sitio a los cuatro jugadores entre puntos
	call mira_a_la_pareja		;6e97
	jr $-95		;6e9a
intercambia_la_pareja:		; Cambia de sitio a los dos jugadores de un bando
	ld de,0e160h		;6e9c   ; 0xE160
	ld hl,0e100h		;6e9f   ; y 0xE100
	call copia_media_ficha		;6ea2   ; copia dieciseis bytes de una ficha a la otra
	ld e,000h		;6ea5
	ld l,030h		;6ea7
	push de			;6ea9
	pop ix		;6eaa
	push hl			;6eac
	pop iy		;6ead
	ld b,(ix+027h)		;6eaf   ; el byte 0x27 dice a que sprites va cada uno
	ld c,(iy+027h)		;6eb2
	ld (ix+027h),c		;6eb5   ; y esos si se intercambian, no se copian
	ld (iy+027h),b		;6eb8
	call copia_media_ficha		;6ebb
	ld e,030h		;6ebe
	ld l,060h		;6ec0
copia_media_ficha:		; Los primeros dieciseis bytes de una ficha a otra
	ld bc,00010h		;6ec2
	ldir		;6ec5
	ret			;6ec7
posicion_de_la_pelota:		; Devuelve en DE el destino y en BC donde esta ahora
	inc hl			;6ec8
	inc hl			;6ec9
	ld e,(hl)			;6eca   ; los bytes 2 y 3 de la ficha
	inc hl			;6ecb
	ld d,(hl)			;6ecc
donde_esta_la_pelota:		; Devuelve en BC la posicion de la pelota
	ld bc,(0e0b7h)		;6ecd   ; 0xE0B7 y 0xE0B8, la pelota
	ret			;6ed1
mira_el_juez:		; El juez de silla sigue la pelota con los ojos
	ld a,(0e0b7h)		;6ed2   ; 0xE0B7 es donde esta la pelota
	ld b,000h		;6ed5   ; B sera cual de las tres caras toca
	cp 048h		;6ed7   ; 0x48 y 0x78 parten la pista en tres franjas
	jr c,juez_pinta		;6ed9
	inc b			;6edb
	cp 078h		;6edc
	jr c,juez_pinta		;6ede
	inc b			;6ee0
juez_pinta:		; Los cuatro tiles de la cara, en dos filas
	ld de,07904h		;6ee1   ; la cara ocupa 2x2 tiles: arriba en la VRAM 0x3904
	call pon_escritura_con_reintento		;6ee4
	ld hl,0715dh		;6ee7   ; y las tres caras estan en la tabla de 0x715D
	ld a,b			;6eea
	rlca			;6eeb   ; cuatro tiles por cara
	rlca			;6eec
	call suma_a_hl		;6eed
	ld b,002h		;6ef0   ; los dos de arriba
	call vuelca_tiles		;6ef2
	ld de,07924h		;6ef5   ; y los dos de abajo, en 0x3924
	call pon_escritura_con_reintento		;6ef8
	ld b,002h		;6efb
	call vuelca_tiles		;6efd   ; que son los otros dos
arbitra:		; Decide si el punto sigue, y quien lo gana
	ld a,(0e045h)		;6f00   ; 0xE045 congela mientras hay un aviso
	or a			;6f03
	jp nz,pasa_la_red		;6f04
	ld a,(0e0d8h)		;6f07   ; 0xE0D8 dice si hay pelota en juego
	or a			;6f0a
	jp z,pasa_la_red		;6f0b
	ld a,(0e0a8h)		;6f0e   ; 0xE0A8 dice si la jugada esta viva
	or a			;6f11
	jr nz,la_pelota_en_el_aire		;6f12
	call dibuja_la_pelota		;6f14   ; con la jugada parada, solo se repinta
	ld ix,0e0c3h		;6f17   ; 0xE0C3 lleva de quien es el saque que viene
	ld (ix+000h),001h		;6f1b
	ld hl,0e051h		;6f1f   ; 0xE051 y 0xE050 llevan el turno
	ld a,(0e00eh)		;6f22   ; 0xE00E, cuantos jugadores hay
	cp 002h		;6f25
	jr z,saque_de_dos		;6f27
	ld a,001h		;6f29
	bit 0,(hl)		;6f2b   ; el bit 0 dice de que lado se saca
	jr z,saque_lado_izquierdo		;6f2d
	ld a,003h		;6f2f
saque_lado_izquierdo:		; El bit 0 dice de que lado se saca
	dec hl			;6f31
	and (hl)			;6f32
	ld hl,0e107h		;6f33   ; 0xE107 es el byte 7 del primer jugador
	dec a			;6f36
	jp m,saque_espera_boton		;6f37
	ld (ix+000h),002h		;6f3a
	ld l,067h		;6f3e   ; 0xE167, el del tercero
	jr z,saque_espera_boton		;6f40
	dec (ix+000h)		;6f42
	dec a			;6f45
	ld l,037h		;6f46   ; 0xE137, el del segundo
	jr z,saque_espera_boton		;6f48
	inc (ix+000h)		;6f4a
	ld l,097h		;6f4d   ; y 0xE197 el del cuarto
saque_espera_boton:		; Hasta que el que saca aprieta
	ld (0e05bh),hl		;6f4f   ; 0xE05B se queda con la ficha del que saca
	bit 4,(hl)		;6f52   ; el bit 4 es el disparo: aqui es donde saca
	jr z,pasa_la_red		;6f54
	ld a,l			;6f56
	sub 007h		;6f57   ; siete bytes atras esta el byte de estado
	ld l,a			;6f59
	set 1,(hl)		;6f5a   ; y se le pone el bit 1: sacando
	xor a			;6f5c
	ld (0e05dh),a		;6f5d   ; 0xE05D a cero
	inc a			;6f60
	ld (0e0dbh),a		;6f61   ; 0xE0DB pide la trayectoria nueva
	ld (0e0a8h),a		;6f64   ; 0xE0A8 a uno: la jugada arranca
	ld hl,0e0d7h		;6f67   ; y 0xE0D7 se invierte: la pelota cambia de sentido
	ld a,(hl)			;6f6a
	cpl			;6f6b
	ld (hl),a			;6f6c
	jp punto_repinta		;6f6d
saque_de_dos:		; Con dos jugadores el turno es mas simple
	dec hl			;6f70
	bit 0,(hl)		;6f71   ; el bit 0 del turno
	ld hl,0e107h		;6f73   ; 0xE107
	jr z,saque_dos_guarda		;6f76
	inc (ix+000h)		;6f78
	ld l,037h		;6f7b
saque_dos_guarda:		; Con dos jugadores, la otra ficha
	jr saque_espera_boton		;6f7d
la_pelota_en_el_aire:		; Mira si el saque llega o se queda corto
	ld a,(0e000h)		;6f7f   ; uno de cada dos cuadros
	rrca			;6f82
	jr c,pasa_la_red		;6f83
	ld a,(0e05dh)		;6f85   ; 0xE05D marca el saque ya resuelto
	or a			;6f88
	jr nz,punto_repinta		;6f89
	ld a,(0e0bbh)		;6f8b   ; 0xE0BB, la sombra
	cp 0b0h		;6f8e   ; por encima de 0xB0 se le da la vuelta
	jr c,saque_corto		;6f90
	neg		;6f92
saque_corto:		; El saque no llega
	ld b,a			;6f94
	ld a,(0e0b7h)		;6f95   ; y 0xE0B7 la pelota, con diez de margen
	sub 010h		;6f98
	cp b			;6f9a
	jr nc,saque_comprueba_valido		;6f9b
	cp 060h		;6f9d   ; 0x60 parte la pista
	ld a,013h		;6f9f   ; la altura a la que se queda
	jr c,saque_baja_la_sombra		;6fa1
	ld a,099h		;6fa3
saque_baja_la_sombra:		; Y se le deja la altura que le toca
	ld (0e0bbh),a		;6fa5   ; y se le baja la sombra
	ld (0e05dh),a		;6fa8
	xor a			;6fab
	ld (0e0a8h),a		;6fac   ; 0xE0A8 a cero: la jugada se para
saque_comprueba_valido:		; Mira si el saque valia
	ld hl,(0e05bh)		;6faf   ; 0xE05B, la ficha del que sacaba
	ld a,0f9h		;6fb2   ; siete bytes atras
	add a,l			;6fb4
	ld l,a			;6fb5
	bit 0,(hl)		;6fb6   ; el bit 0 dice si el saque valia
	jr z,punto_repinta		;6fb8
	inc a			;6fba
	ld (0e05dh),a		;6fbb
punto_repinta:		; Recalcula y vuelve a pintar la pelota
	call recalcula_la_trayectoria		;6fbe
	call dibuja_la_pelota		;6fc1
pasa_la_red:		; Comprueba si la pelota pasa la red o se la come
	ld hl,0e0d8h		;6fc4
	bit 0,(hl)		;6fc7   ; el bit 0 de 0xE0D8: no hay pelota
	ret z			;6fc9
	ld a,(0e0d7h)		;6fca   ; 0xE0D7 dice hacia donde va
	or a			;6fcd
	jr nz,toca_la_red		;6fce
	ld l,04fh		;6fd0   ; 0xE04F es el saque
	bit 0,(hl)		;6fd2
	jr nz,toca_la_red		;6fd4
	ld a,(0e0b7h)		;6fd6   ; 0xE0B7 otra vez
	cp 018h		;6fd9   ; por debajo de 0x18 ya esta en el fondo
	jr nc,toca_la_red		;6fdb
	set 0,(hl)		;6fdd   ; y se marca
	ld a,003h		;6fdf
	call suena		;6fe1   ; el sonido del bote
	xor a			;6fe4
	jr bote_frena		;6fe5
toca_la_red:		; Mira si la pelota se queda en la red y con que angulo llega
	ld a,(0e04ch)		;6fe7   ; 0xE04C marca la red ya tocada
	or a			;6fea
	jr nz,bota_en_el_suelo		;6feb
	ld a,(0e0b7h)		;6fed   ; 0xE0B7
	cp 06ch		;6ff0   ; 0x6C es donde esta la red
	jr nc,bota_en_el_suelo		;6ff2
	ld b,a			;6ff4
	ld a,070h		;6ff5   ; 0x70 menos la altura da lo que le falta
	sub b			;6ff7
	ld hl,0e0d0h		;6ff8   ; 0xE0D0 monta la cuenta
	ld (hl),000h		;6ffb
	inc hl			;6ffd
	ld (hl),a			;6ffe
	inc hl			;6fff
	ld (hl),000h		;7000
	inc hl			;7002
	ld (hl),0aah		;7003   ; 0xAA es la pendiente con la que se compara
	call multiplica_16		;7005   ; y se multiplica
	ld a,(0e0d1h)		;7008   ; 0xE0D1 trae el resultado
	ld hl,0e0b8h		;700b   ; 0xE0B8, la columna de la pelota
	cp (hl)			;700e
	jr nc,red_frena		;700f
	neg		;7011   ; en valor absoluto
	cp (hl)			;7013
	jr nc,bota_en_el_suelo		;7014   ; si no llega, pasa de largo
red_frena:		; 0xE0AC se parte por la mitad
	ld l,0ach		;7016   ; 0xE0AC se parte por la mitad: la pelota pierde fuerza
	srl (hl)		;7018
	ld l,0d6h		;701a   ; y 0xE0D6 se queda con el golpe de red
	cp 080h		;701c
	ld a,008h		;701e
	jr c,red_apunta		;7020
	dec a			;7022
red_apunta:		; 0xE04C: la red ya esta contada
	ld (hl),a			;7023
	ld (0e04ch),a		;7024   ; 0xE04C: la red ya esta contada
	jp parametros_del_golpe		;7027   ; y se recargan los parametros del golpe
bota_en_el_suelo:		; Comprueba el bote, y de que lado de la raya cae
	ld a,(0e044h)		;702a   ; 0xE044 congela durante un aviso
	or a			;702d
	ret nz			;702e
	ld a,(0e0c4h)		;702f   ; 0xE0C4 marca el bote ya contado
	or a			;7032
	ret nz			;7033
	ld a,(0e0b8h)		;7034   ; 0xE0B8, la columna
	cp 030h		;7037   ; entre 0x30 y 0xD0 esta la pista
	ret c			;7039
	cp 0d0h		;703a
	ret nc			;703c
	ld a,(0e0bbh)		;703d   ; 0xE0BB y 0xE0B7, la sombra y la pelota
	ld b,a			;7040
	ld a,(0e0b7h)		;7041
	cp 060h		;7044   ; entre 0x60 y 0x66 esta la banda de la red
	ret c			;7046
	cp 066h		;7047
	ret nc			;7049
	sub b			;704a   ; la altura otra vez
	cp 010h		;704b   ; y con menos de dieciseis, roza
	ld hl,0e0c4h		;704d
	set 0,(hl)		;7050   ; el bit 0 de 0xE0C4: el bote ya esta contado
	ret nc			;7052
bote_frena:		; Otra vez la mitad
	ld hl,0e0ach		;7053   ; 0xE0AC pierde la mitad en cada bote
	srl (hl)		;7056
	inc hl			;7058
	inc hl			;7059
	cp 00fh		;705a   ; con menos de quince ya casi no rebota
	ld a,001h		;705c
	ld (0e0dbh),a		;705e   ; 0xE0DB pide recalcular la trayectoria
	jr nc,bote_largo		;7061
	ld (hl),02ch		;7063   ; el rebote corto
	inc hl			;7065
	inc hl			;7066
	ld (hl),0fbh		;7067
	ld a,(0e04fh)		;7069   ; 0xE04F es el saque
	or a			;706c
	jr nz,bote_suena		;706d
	inc a			;706f
	ld (0e044h),a		;7070   ; 0xE044 congela mientras se resuelve
	jr bote_suena		;7073
bote_largo:		; La pelota sale rodando y cambia de sentido
	ld de,0e0c0h		;7075   ; 0xE0C0 marca la pelota rodando
	ld (de),a			;7078
	ld e,0d7h		;7079   ; y 0xE0D7 se invierte: el rebote cambia de sentido
	ld a,(de)			;707b
	cpl			;707c
	ld (de),a			;707d
	ld (hl),016h		;707e   ; el rebote largo
	inc hl			;7080
	inc hl			;7081
	ld (hl),0feh		;7082
bote_suena:		; Y se recalcula la trayectoria
	ld a,003h		;7084
	call suena		;7086   ; y suena el bote
	jp recalcula_la_trayectoria		;7089
bota_dentro_o_fuera:		; Mira la casilla donde cayo y decide si la pelota es buena
	ld a,(0e044h)		;708c   ; 0xE044 congela durante un aviso
	or a			;708f
	ret nz			;7090
	ld hl,0e04dh		;7091   ; 0xE04D marca el bote ya juzgado
	bit 0,(hl)		;7094
	ret nz			;7096
	ld a,(0e0a9h)		;7097   ; esto solo se hace en el primer bote
	dec a			;709a
	ret nz			;709b
	set 0,(hl)		;709c   ; y se apunta para no repetirlo
	ld de,0e0b7h		;709e   ; 0xE0B7, donde cayo
	ld a,(0e042h)		;70a1   ; 0xE042 dice si el punto ya esta cerrado
	or a			;70a4
	jr z,bota_en_el_saque		;70a5
	ld a,001h		;70a7
	ld hl,0e051h		;70a9   ; 0xE051 y 0xE050 llevan el turno de saque
	bit 0,(hl)		;70ac
	dec hl			;70ae
	jr z,bote_lado		;70af
	ld a,003h		;70b1
bote_lado:		; El bit 0 dice de que lado se juzga
	and (hl)			;70b3
	bit 0,(hl)		;70b4
	jr z,bote_limites		;70b6
	inc a			;70b8
	ld hl,0e00eh		;70b9   ; 0xE00E, cuantos jugadores hay
	bit 0,(hl)		;70bc
	jr z,bote_limites		;70be
	add a,002h		;70c0
bote_limites:		; Los limites que se copiaron a 0xE052
	ld hl,0e052h		;70c2   ; 0xE052 son los limites que se copiaron al empezar
	add a,l			;70c5
	ld l,a			;70c6
	ld a,(hl)			;70c7
	inc hl			;70c8
	cp 060h		;70c9   ; 0x60 parte la pista por la red
	ld a,(de)			;70cb
	jr c,bote_medio_campo		;70cc
	cp 03dh		;70ce   ; el pasillo de saque de este lado va de 0x3D a 0x63
	ret c			;70d0
	cp 063h		;70d1
	ret nc			;70d3
	inc de			;70d4
	ld a,(hl)			;70d5   ; y ahora el otro eje
	cp 080h		;70d6   ; 0x80 lo parte por la mitad
	ld a,(de)			;70d8
	jr c,bote_lateral_derecho		;70d9
	cp 07ch		;70db   ; el lateral de un lado, de 0x4F a 0x7C
	ret nc			;70dd
	cp 04fh		;70de
	ret c			;70e0
bote_bueno:		; 0xE043: la pelota entro
	ld hl,0e043h		;70e1   ; 0xE043: la pelota es buena y viene hacia aca
	set 0,(hl)		;70e4
	ret			;70e6
bote_lateral_derecho:		; El pasillo de 0x7A a 0xAA
	cp 07ah		;70e7   ; y el del otro, de 0x7A a 0xAA
	ret c			;70e9
	cp 0aah		;70ea
	ret nc			;70ec
	jr bote_bueno		;70ed
bote_medio_campo:		; El otro medio campo
	cp 085h		;70ef   ; el otro medio campo, hasta 0x85
	ret nc			;70f1
	cp 063h		;70f2   ; y desde 0x63
	ret c			;70f4
	inc de			;70f5
	ld a,(hl)			;70f6
	cp 080h		;70f7
	ld a,(de)			;70f9
	jr c,bote_lateral_izquierdo		;70fa
	cp 07ch		;70fc
	ret nc			;70fe
	cp 047h		;70ff   ; los limites de ese lado, de 0x47 a 0x7C
	ret c			;7101
	jr bote_bueno		;7102
bote_lateral_izquierdo:		; Y el de 0x7A a 0xB1
	cp 07ah		;7104   ; y los del otro, de 0x7A a 0xB1
	ret c			;7106
	cp 0b1h		;7107
	ret nc			;7109
	jr bote_bueno		;710a
bota_en_el_saque:		; El saque tiene su propio cuadro, y va en diagonal
	ex de,hl			;710c
	ld a,(hl)			;710d   ; la posicion de la pelota
	cp 0aah		;710e   ; por encima de 0xAA se sale por el fondo
	ret nc			;7110
	cp 025h		;7111   ; y por debajo de 0x25, por el otro
	ret c			;7113
	ld a,0aah		;7114   ; lo que le falta hasta el fondo
	sub (hl)			;7116
	push hl			;7117
	ld hl,0e0d0h		;7118   ; 0xE0D0 monta la multiplicacion
	ld (hl),000h		;711b
	inc hl			;711d
	ld (hl),a			;711e
	inc hl			;711f
	ld (hl),000h		;7120
	inc hl			;7122
	ld (hl),028h		;7123   ; 0x28 es la pendiente del pasillo de saque
	ld b,03dh		;7125   ; y 0x3D donde empieza
	ld a,(0e051h)		;7127   ; 0xE051 dice de que lado se saca
	or a			;712a
	jr z,saque_calcula		;712b
	ld (hl),030h		;712d   ; del otro lado, otra pendiente y otro origen
	ld b,031h		;712f
saque_calcula:		; La diagonal del pasillo de saque
	call multiplica_16		;7131   ; y se hace la cuenta
	pop hl			;7134
	inc hl			;7135
	ld a,(0e0d1h)		;7136   ; 0xE0D1 trae el resultado
	add a,b			;7139
	cp (hl)			;713a   ; si se pasa de la raya, el saque es malo
	ret nc			;713b
	neg		;713c
	sub 00ah		;713e   ; diez de margen por el otro lado
	cp (hl)			;7140
	ret c			;7141
	ld a,(0e052h)		;7142   ; 0xE052, el limite guardado
	cp 060h		;7145
	ld a,(0e045h)		;7147   ; 0xE045 lleva la cuenta de saques
	jr nc,saque_lado_alto		;714a
	dec a			;714c
saque_lado_alto:		; 0x63 parte la pista
	dec a			;714d
	ld a,(0e0b7h)		;714e   ; 0xE0B7 otra vez
	jr nz,saque_lado_bajo		;7151
	cp 063h		;7153   ; y 0x63 es la mitad de la pista
	jr c,bote_bueno		;7155
	ret			;7157
saque_lado_bajo:		; Y del otro lado, al reves
	cp 063h		;7158
	jr nc,bote_bueno		;715a
	ret			;715c

; ----------------------------------------------------------------------
; DATOS posturas_del_juez: Las tres caras del juez de silla, de 2x2 tiles: los
;   ojos a un lado, al otro y cerrados
;   0x715d..0x7169  (12 bytes)
DATA_posturas_del_juez:
	defb 0b4h,0b7h,0abh,0ach	; 715d
	defb 0a9h,0aah,0abh,0ach	; 7161
	defb 0b3h,0b6h,0abh,0ach	; 7165

; ======================================================================
; CODIGO 0x7169..0x763a  (1233 bytes)
; ======================================================================


vuelca_tiles:		; Suelta B bytes al puerto de datos del VDP con outi
	ld a,(00007h)		;7169   ; el puerto de escritura
	ld c,a			;716c
vuelca_tiles_bucle:		; Un byte por vuelta, con su nop
	nop			;716d   ; el nop da al VDP el respiro que necesita entre bytes
	outi		;716e   ; outi escribe, avanza y descuenta, todo en una
	jr nz,vuelca_tiles_bucle		;7170
	ret			;7172
arranca_el_punto:		; Coloca a todos, saca, y no vuelve hasta que el punto acaba
	di			;7173
	ld a,020h		;7174   ; 0xE0B7 y 0xE0E0 arrancan en 0x20
	ld (0e0b7h),a		;7176
	ld (0e0e0h),a		;7179
	ld hl,076ffh		;717c   ; los puestos de individuales
	call hay_dobles		;717f   ; y en dobles, los otros
	jr z,punto_guarda_menu		;7182
	cp 002h		;7184
	ld a,000h		;7186
	jr nz,punto_guarda_menu		;7188
	ld hl,0771fh		;718a   ; la tabla de 0x771F
punto_guarda_menu:		; Se queda con lo que se eligio
	ld (0e051h),a		;718d   ; 0xE051 a cero: primer saque
	ld a,(0e002h)		;7190   ; 0xE002 dice que el jugador eligio en el menu
	or a			;7193
	jr z,coloca_a_todos		;7194
	ld (0e00eh),a		;7196   ; 0xE00E se queda con cuantos jugadores hay
	ld (0e050h),a		;7199
	inc a			;719c
	ld (0e0dah),a		;719d   ; y 0xE0DA con la opcion de partido
	ld hl,07707h		;71a0   ; con la demostracion se usan otros puestos
coloca_a_todos:		; Copia los ocho bytes de puestos a las cuatro fichas
	ld de,0e052h		;71a3   ; 0xE052 recibe los ocho
	ld bc,00008h		;71a6   ; dos por jugador
	ldir		;71a9
	ld e,052h		;71ab
	ld b,004h		;71ad   ; cuatro jugadores
	ld hl,0e102h		;71af   ; 0xE102, la fila del primero
coloca_bucle:		; Una ficha por vuelta
	ld a,(de)			;71b2
	ld (hl),a			;71b3   ; la fila
	inc hl			;71b4
	inc de			;71b5
	ld a,(de)			;71b6
	ld (hl),a			;71b7   ; y la columna
	inc de			;71b8
	ld a,02fh		;71b9   ; 0x2F bytes hasta la ficha siguiente
	call suma_a_hl		;71bb
	djnz coloca_bucle		;71be
	call pinta_el_tanteo		;71c0   ; pinta el marcador
	call empieza_el_punto		;71c3   ; y los rotulos del partido
punto_recoloca:		; Si toca, se recolocan todos
	ld a,(0e049h)		;71c6   ; 0xE049 dice si hay que recolocar
	or a			;71c9
	jp z,sigue_el_partido		;71ca
	ld a,(0e0e2h)		;71cd   ; 0xE0E2 y 0xE04E cortan la recolocacion
	or a			;71d0
	jr nz,resuelve_el_punto		;71d1
	ld a,(0e04eh)		;71d3
	or a			;71d6
	jr nz,resuelve_el_punto		;71d7
	ld a,(0e051h)		;71d9   ; 0xE051, de que lado toca sacar
	or a			;71dc
	jr nz,gira_por_el_turno		;71dd
	ld hl,0e053h		;71df   ; 0xE053 y 0xE057 son las columnas de los dos
	ld de,0e057h		;71e2
	ld a,(0e00eh)		;71e5   ; 0xE00E otra vez
	dec a			;71e8
	jr z,gira_al_jugador		;71e9
	ld e,055h		;71eb   ; con dos jugadores, la otra ficha
gira_al_jugador:		; Se le da la vuelta y se le resta 0x20
	ld a,(hl)			;71ed
	neg		;71ee   ; se les da la vuelta y se les resta 0x20
	sub 020h		;71f0
	ld (hl),a			;71f2
	ld a,(de)			;71f3
	neg		;71f4
	sub 020h		;71f6
	ld (de),a			;71f8
	jr resuelve_el_punto		;71f9
gira_por_el_turno:		; Con el turno decide a quien le toca girar
	ld a,(0e050h)		;71fb   ; 0xE050, el turno
	rrca			;71fe
	ld hl,0e052h		;71ff   ; 0xE052 y 0xE057
	ld de,0e057h		;7202
	jr c,gira_dos		;7205
	ex de,hl			;7207
	dec hl			;7208
	inc de			;7209
gira_dos:		; Dos jugadores por bando
	ld b,002h		;720a   ; dos jugadores por bando
gira_uno:		; Un jugador
	ld a,(de)			;720c
	neg		;720d   ; el mismo giro
	sub 020h		;720f
	ld (de),a			;7211
	inc de			;7212
	inc de			;7213
	djnz gira_uno		;7214
	ld b,(hl)			;7216   ; y los dos de un bando se intercambian la columna
	inc hl			;7217
	inc hl			;7218
	ld a,(hl)			;7219
	ld (hl),b			;721a
	dec hl			;721b
	dec hl			;721c
	ld (hl),a			;721d
resuelve_el_punto:		; Suena el aviso, espera a que la pelota se pare y reparte
	ld a,(0e043h)		;721e   ; 0xE043 dice si la pelota entro
	or a			;7221
	jr z,punto_suena		;7222
	ld a,(0e0c0h)		;7224   ; 0xE0C0 marca la pelota rodando
	or a			;7227
	jr z,punto_pinta		;7228
punto_suena:		; Suena lo que 0xE05A diga
	ld a,(0e05ah)		;722a   ; 0xE05A es la musica que toca
	call suena		;722d
punto_pinta:		; El tanteo y los rotulos nuevos
	call pinta_el_rotulo		;7230   ; pinta el tanteo nuevo
	ld a,001h		;7233   ; orden 1 a la interrupcion
	call manda_orden		;7235
	call pinta_el_tanteo		;7238   ; y otra vez los rotulos
punto_espera_pelota:		; Hasta que la pelota se para
	ld a,(0e0d8h)		;723b   ; 0xE0D8: no se sigue hasta que la pelota se para
	or a			;723e
	jr nz,punto_espera_pelota		;723f
	xor a			;7241
	ld (0e003h),a		;7242   ; 0xE003 a cero: la partida se detiene un momento
	ld a,(0e0c0h)		;7245   ; 0xE0C0 otra vez
	or a			;7248
	jr nz,sale_el_recogepelotas		;7249
	ld a,(0e044h)		;724b   ; y 0xE044, el aviso
	or a			;724e
	jp z,reparte_el_punto		;724f
sale_el_recogepelotas:		; La figura de la derecha va a por la pelota y vuelve
	ld hl,0774fh		;7252   ; los tiles de 0x774F, que le hacen sitio
	call pinta_tres_filas		;7255
	ld a,001h		;7258   ; 0xE03C es en que paso va
	ld (0e03ch),a		;725a
	call coloca_al_recogepelotas		;725d   ; le carga las posturas de la tabla de 0x776C
	ld a,009h		;7260
	call suena		;7262   ; y suena mientras corre
recogepelotas_ida:		; Un cuadro de la ida
	ld a,(0e000h)		;7265   ; espera al cuadro siguiente
	bit 0,a		;7268
	jr z,recogepelotas_ida		;726a
	inc a			;726c
	ld (0e000h),a		;726d   ; con el contador puesto a mano, porque la partida esta parada
	and 007h		;7270
	cp 006h		;7272   ; cada seis cuadros cambia de paso
	jr nz,recogepelotas_rumbo		;7274
	xor a			;7276
	ld (0e000h),a		;7277
	ld a,(0e03ch)		;727a
	rrca			;727d   ; y alterna entre los dos de andar
	jr nc,recogepelotas_paso		;727e
	ld a,002h		;7280
recogepelotas_paso:		; Alterna entre los dos pasos de andar
	ld (0e03ch),a		;7282
recogepelotas_rumbo:		; Dos de paso, y de que lado esta la pelota
	ld bc,00264h		;7285   ; dos de paso y 0x64 de meta
	ld a,(0e0b7h)		;7288   ; 0xE0B7 dice de que lado quedo la pelota
	cp 063h		;728b   ; 0x63 es la mitad de la pista
	ld a,(0e03ah)		;728d   ; 0xE03A es su columna
	jr nc,recogepelotas_avanza		;7290
	ld bc,0febbh		;7292   ; y si es del otro lado, el paso va al reves
	neg		;7295
recogepelotas_avanza:		; Un paso hacia ella
	cp c			;7297
	jr nc,recogepelotas_atributos		;7298
	ld a,(0e03ah)		;729a
	add a,b			;729d   ; un paso mas
	ld (0e03ah),a		;729e
	jr recogepelotas_repinta		;72a1
recogepelotas_atributos:		; Sus cuatro sprites, a la VRAM 0x3B3C
	ld hl,0773fh		;72a3   ; los atributos de sus cuatro sprites
	ld de,07b3ch		;72a6   ; a la VRAM 0x3B3C, o sea a partir del sprite 15
	ld b,010h		;72a9   ; dieciseis bytes: cuatro sprites
	call escribe_bloque_en		;72ab
	ld a,(0e0b8h)		;72ae   ; 0xE0B8 es la columna de la pelota
	sub 008h		;72b1
	ld hl,0e03bh		;72b3   ; 0xE03B es su fila
	cp (hl)			;72b6
	jr nc,recoge_y_vuelve		;72b7
	dec (hl)			;72b9   ; y se le acerca de dos en dos
	dec (hl)			;72ba
recogepelotas_repinta:		; Le vuelve a colocar los sprites
	call coloca_al_recogepelotas		;72bb
	jr recogepelotas_ida		;72be
recoge_y_vuelve:		; Se lleva la pelota y desanda el camino
	ld a,(0e0b7h)		;72c0   ; 0xE0C2 guarda donde estaba la pelota
	ld (0e0c2h),a		;72c3
	ld a,0cfh		;72c6   ; 0xCF la esconde
	ld (0e0b7h),a		;72c8   ; la pelota
	ld (0e0bbh),a		;72cb   ; y su sombra
	call coloca_la_pelota		;72ce   ; le quita los sprites a la pelota
	ld a,003h		;72d1   ; 0xE03C pasa al paso 3: la vuelta
	ld (0e03ch),a		;72d3
	call coloca_al_recogepelotas		;72d6   ; y otra vez sus posturas
recogepelotas_vuelta:		; Un cuadro de la vuelta
	ld a,(0e000h)		;72d9
	bit 0,a		;72dc
	jr z,recogepelotas_vuelta		;72de
	inc a			;72e0
	ld (0e000h),a		;72e1
	and 007h		;72e4   ; seis cuadros por paso, igual que a la ida
	cp 006h		;72e6
	jr nz,recogepelotas_sube		;72e8
	xor a			;72ea
	ld (0e000h),a		;72eb
	ld a,(0e03ch)		;72ee
	cpl			;72f1   ; pero ahora la postura se invierte
	and 007h		;72f2
	ld (0e03ch),a		;72f4
recogepelotas_sube:		; Deshace la fila que bajo
	ld hl,0e03bh		;72f7   ; 0xE03B, su fila
	ld a,0d6h		;72fa   ; hasta 0xD6, que es de donde salio
	cp (hl)			;72fc
	jr c,recogepelotas_columna		;72fd
	inc (hl)			;72ff
	inc (hl)			;7300
	jr recogepelotas_pinta_vuelta		;7301
recogepelotas_columna:		; Y la columna, hacia donde salio
	dec hl			;7303
	ld b,002h		;7304   ; dos de paso, como a la ida
	ld a,(0e0c2h)		;7306   ; 0xE0C2, donde recogio la pelota
	cp 063h		;7309   ; 0x63 es la mitad de la pista
	jr nc,recogepelotas_llega		;730b
	ld b,0feh		;730d   ; y del otro lado, el paso al reves
recogepelotas_llega:		; Al llegar a 0x4F, se guarda
	ld a,(hl)			;730f
	cp 04fh		;7310   ; 0x4F es su sitio de siempre
	jr z,guarda_al_recogepelotas		;7312
	sub b			;7314
	ld (hl),a			;7315
recogepelotas_pinta_vuelta:		; Sus sprites, otra vez
	call coloca_al_recogepelotas		;7316   ; y mientras anda, sus posturas
	jr recogepelotas_vuelta		;7319
guarda_al_recogepelotas:		; Al llegar a su sitio, se le quitan los sprites
	ld de,07b3ch		;731b   ; los atributos de sus cuatro sprites
	ld bc,010cfh		;731e   ; dieciseis bytes a 0xCF, o sea escondidos
	call rellena_en		;7321
	xor a			;7324
	ld (0e03ch),a		;7325   ; 0xE03C a cero: ya no esta en escena
	call coloca_al_recogepelotas		;7328
	ld hl,07755h		;732b   ; los tiles de 0x7755, que le devuelven el fondo
	call pinta_tres_filas		;732e
	ld a,097h		;7331   ; y suena la vuelta
	di			;7333
	call suena		;7334
	call reproduce		;7337
	ei			;733a
reparte_el_punto:		; Decide a quien va el punto, lo anuncia y prepara el siguiente
	xor a			;733b
	ld (0e040h),a		;733c   ; 0xE040 es el numero de rotulo que toca
	call pinta_el_rotulo		;733f   ; borra el que hubiera
	ld hl,0e046h		;7342   ; 0xE046 marca la falta
	xor a			;7345
	cp (hl)			;7346
	jr z,punto_mira_el_juego		;7347
	ld (hl),a			;7349
	ld a,004h		;734a
	ld (0e040h),a		;734c   ; rotulo 4
	ld a,00dh		;734f   ; y su sonido
	call suena		;7351
	call pinta_el_rotulo		;7354
	ld a,004h		;7357
	call manda_orden		;7359   ; orden 4 a la interrupcion
	ld (0e040h),a		;735c
	call pinta_el_rotulo		;735f
punto_mira_el_juego:		; 0xE04A dice si el juego se cerro
	ld hl,0e04ah		;7362   ; 0xE04A marca el punto cerrado
	xor a			;7365
	cp (hl)			;7366
	jr z,punto_mira_el_set		;7367
	ld (hl),a			;7369
	ld a,(0e050h)		;736a   ; 0xE050, el turno de saque
	inc a			;736d   ; y pasa al siguiente, de cuatro en cuatro
	and 003h		;736e
	ld (0e050h),a		;7370
	push af			;7373
	call posturas_de_dobles		;7374   ; en dobles hay que recolocar la pareja
	ld b,001h		;7377   ; con dos jugadores el turno alterna de dos en dos
	ld a,(0e00eh)		;7379
	ld c,a			;737c
	bit 1,a		;737d   ; y en dobles, de cuatro en cuatro
	jr z,juego_indice		;737f
	ld b,003h		;7381
juego_indice:		; Ocho bytes por bloque de puestos
	pop af			;7383
	and b			;7384
	rlca			;7385   ; ocho bytes por bloque de puestos
	rlca			;7386
	rlca			;7387
	ld hl,076ffh		;7388   ; los puestos de individuales
	push af			;738b
	ld a,c			;738c
	cp 002h		;738d
	jr nz,juego_copia_puestos		;738f
	ld hl,0771fh		;7391   ; y estos los de dobles
	ld a,(0e050h)		;7394   ; 0xE050 otra vez
	rrca			;7397
	jr nc,juego_copia_puestos		;7398
	exx			;739a
	call intercambia_la_pareja		;739b   ; en la mitad de los turnos se cambian de lado
	exx			;739e
juego_copia_puestos:		; Los ocho a 0xE052
	pop af			;739f
	call suma_a_hl		;73a0
	ld de,0e052h		;73a3   ; 0xE052 recibe los ocho bytes
	ld bc,00008h		;73a6
	ldir		;73a9
	call acaba_el_juego		;73ab   ; pinta el tanteo
	ld a,004h		;73ae
	call manda_orden		;73b0   ; orden 4 a la interrupcion
	ld h,a			;73b3
	ld l,a			;73b4
	ld (0e030h),hl		;73b5   ; 0xE030 y 0xE031, los tanteos de los dos
	call pinta_el_tanteo		;73b8   ; y los rotulos
punto_mira_el_set:		; 0xE048 dice si ademas se acabo el partido
	ld hl,0e048h		;73bb   ; 0xE048 dice si se acabo el juego
	xor a			;73be
	cp (hl)			;73bf
	jr nz,fin_del_partido		;73c0
	dec hl			;73c2
	cp (hl)			;73c3
	jr z,punto_siguiente		;73c4
	ld l,038h		;73c6   ; 0xE038 cuenta los juegos ganados
	inc (hl)			;73c8
	ld l,0e0h		;73c9   ; y 0xE0E0 el set
	inc (hl)			;73cb
punto_siguiente:		; Y a por el punto que viene
	call empieza_el_punto		;73cc
sigue_el_partido:		; Vuelve a por el punto siguiente, o cierra el partido
	ld hl,0e003h		;73cf   ; 0xE003, la partida en marcha
	set 0,(hl)		;73d2
	ld a,(0e0e0h)		;73d4   ; 0xE0E0: si se acabo el set, se anuncia
	or a			;73d7
	call nz,anuncia_el_set		;73d8
	ld a,(0e002h)		;73db   ; 0xE002 dice si hay alguien jugando
	or a			;73de
demostracion_repite:		; En la demostracion, vuelta a empezar
	jp z,punto_recoloca		;73df   ; en la demostracion, vuelta a empezar
	ld a,(0e005h)		;73e2   ; 0xE005 es lo que se pulso
	ld (0e006h),a		;73e5   ; y 0xE006 lo recuerda para el arranque
	or a			;73e8
	jr nz,partido_suena_final		;73e9
	ld a,(0e032h)		;73eb   ; 0xE032 y 0xE035, los juegos de cada uno
	or a			;73ee
	jr nz,partido_suena_final		;73ef
	ld a,(0e035h)		;73f1
	or a			;73f4
	jr z,demostracion_repite		;73f5
partido_suena_final:		; La musica de cierre
	di			;73f7
	ld a,097h		;73f8   ; la musica de final
	call suena		;73fa
	ei			;73fd
	jr final_vuelve_al_titulo		;73fe
fin_del_partido:		; Rotulo de cierre y vuelta al titulo
	ld a,00ch		;7400   ; rotulo 12
	ld (0e040h),a		;7402
	call pinta_el_rotulo		;7405
	ld a,091h		;7408   ; y su musica
	call suena		;740a
final_espera_musica:		; Hasta que 0xE213 la deja terminar
	ld a,(0e213h)		;740d   ; espera a que 0xE213 diga que ha terminado de sonar
	or a			;7410
	jr nz,final_espera_musica		;7411
final_vuelve_al_titulo:		; Orden 3 y de vuelta al principio
	ld a,003h		;7413
	call manda_orden		;7415   ; orden 3 a la interrupcion
	jp init_pantalla		;7418   ; y se vuelve al principio de todo
anuncia_el_set:		; Escribe el rotulo del set que se acaba de ganar
	ld a,(0e038h)		;741b   ; 0xE038, los juegos ganados
	add a,009h		;741e   ; los rotulos del set empiezan en el 9
	ld (0e040h),a		;7420
	call pinta_el_rotulo		;7423
	ld a,004h		;7426
	call manda_orden		;7428   ; orden 4 a la interrupcion
	ld (0e040h),a		;742b   ; y se limpian las dos variables
	ld (0e0e0h),a		;742e
pinta_el_rotulo:		; Borra el rotulo de en medio y pone el que toque
	di			;7431
	ld de,078e4h		;7432   ; los rotulos van a la VRAM 0x38E4
	call pon_escritura_con_reintento		;7435
	ld hl,0763ah		;7438   ; la tabla de mensajes de 0x763A
	xor a			;743b   ; el 0 es el que borra
	call escribe_el_rotulo		;743c
	ld de,078e4h		;743f   ; y ahora el de verdad, en el mismo sitio
	call pon_escritura_con_reintento		;7442
	ld hl,0763ah		;7445
	ld a,(0e040h)		;7448   ; 0xE040 dice cual
escribe_el_rotulo:		; Busca el mensaje en la tabla y lo vuelca
	rlca			;744b   ; dos bytes por entrada
	call suma_a_hl		;744c
	ld a,(hl)			;744f   ; y de ahi sale el puntero al texto
	inc hl			;7450
	ld h,(hl)			;7451
	ld l,a			;7452
	exx			;7453
	ld a,(00007h)		;7454   ; el puerto de datos del VDP
	ld c,a			;7457
	exx			;7458
	call sigue_la_lista		;7459   ; y lo pinta con el interprete de listas de tiles
	ei			;745c
	ret			;745d
pinta_el_tanteo:		; Escribe los dos tanteos, y hace parpadear el aviso de falta
	ld a,(0e040h)		;745e   ; 0xE040, el rotulo que hay puesto
	dec a			;7461   ; el 1 es el de falta, que ademas parpadea
	jr nz,tanteo_escribe		;7462
	ld a,(0e0c0h)		;7464   ; 0xE0C0 marca la pelota rodando
	or a			;7467
	jr nz,tanteo_escribe		;7468
	ld a,00ah		;746a
	call suena		;746c   ; y suena
aviso_parpadea:		; Alterna los dos juegos de color del rotulo
	ld hl,0790ah		;746f   ; los colores de 0x790A
	ld de,04528h		;7472   ; a la VRAM 0x0528, que aqui es la tabla de COLORES
	ld b,020h		;7475   ; cuatro tiles, ocho bytes cada uno
	ld a,(0e000h)		;7477   ; el contador de cuadros marca el ritmo
	and 00fh		;747a
	or a			;747c
	jr z,aviso_escribe_color		;747d
	cp 007h		;747f   ; cada siete cuadros se cambia
	jr nz,aviso_parpadea		;7481
	ld hl,07912h		;7483   ; y al otro juego de colores: eso es el parpadeo
aviso_escribe_color:		; Suelta los ocho bytes del juego de color
	di			;7486
	call escribe_bloque_en		;7487
	ei			;748a
	ld a,(0e229h)		;748b   ; 0xE229 corta el parpadeo cuando acaba el aviso
	or a			;748e
	jr nz,aviso_parpadea		;748f
tanteo_escribe:		; Los dos tanteos, arriba y abajo
	di			;7491
	ld de,07919h		;7492   ; el tanteo de arriba va a la VRAM 0x3919
	call pon_escritura_con_reintento		;7495
	ld hl,076d7h		;7498   ; la tabla de tanteos de 0x76D7
	ld a,(0e031h)		;749b   ; 0xE031 es el punto que lleva
	call escribe_el_rotulo		;749e
	ld de,079fbh		;74a1   ; y el de abajo a 0x39FB
	call pon_escritura_con_reintento		;74a4
	ld hl,076d7h		;74a7
	ld a,(0e030h)		;74aa   ; 0xE030, el otro
	call escribe_el_rotulo		;74ad
	di			;74b0
	ld a,001h		;74b1
	ld (0e003h),a		;74b3   ; 0xE003: la partida sigue
	ld (0e060h),a		;74b6   ; 0xE060 congela la pista
	dec a			;74b9
	ld (0e0a8h),a		;74ba   ; 0xE0A8 a cero: la jugada se detiene
	ld (0e061h),a		;74bd
	ld hl,0e250h		;74c0   ; y se limpian dieciseis bytes de 0xE250
	ld bc,00010h		;74c3
	call borra_ram		;74c6
	ei			;74c9
tanteo_espera:		; Hasta que 0xE061 dice que la interrupcion acabo
	ld a,(0e061h)		;74ca   ; 0xE061 lo pone la interrupcion cuando ha terminado
	or a			;74cd
	jr z,tanteo_espera		;74ce
	xor a			;74d0
	ld (0e061h),a		;74d1
	ret			;74d4
acaba_el_juego:		; Anuncia el juego ganado y actualiza los juegos de cada uno
	ld a,001h		;74d5   ; orden 1 a la interrupcion
	call manda_orden		;74d7
	ld a,007h		;74da
	ld (0e040h),a		;74dc   ; rotulo 7, el de juego ganado
	call pinta_el_rotulo		;74df
	ld a,(0e048h)		;74e2   ; 0xE048 dice si ademas se acabo el set
	or a			;74e5
	jr nz,juego_marcador		;74e6
	ld a,08eh		;74e8   ; la musica del juego
	call suena		;74ea
juego_suena:		; La musica del juego ganado
	call parpadea_el_bando		;74ed
	ei			;74f0
	ld a,(0e213h)		;74f1   ; espera a que termine de sonar
	or a			;74f4
	jr nz,juego_suena		;74f5
	call pinta_los_dos_bandos		;74f7
juego_marcador:		; Los juegos de los dos bandos
	ld b,002h		;74fa   ; dos bandos
	ld de,0782eh		;74fc   ; los juegos de arriba van a la VRAM 0x382E
	ld hl,0e032h		;74ff   ; 0xE032, los juegos del primero
juego_bando:		; Un bando por vuelta
	push bc			;7502
	ld a,(0e038h)		;7503   ; 0xE038 cuenta los sets
juego_busca_casilla:		; Tres bytes por casilla del marcador
	sub 001h		;7506
	jr c,juego_escribe_cifra		;7508
	inc de			;750a   ; tres bytes por casilla del marcador
	inc de			;750b
	inc de			;750c
	inc hl			;750d
	jr juego_busca_casilla		;750e
juego_escribe_cifra:		; Los digitos son 0xF0 mas la cifra
	ld a,(hl)			;7510
	or 0f0h		;7511   ; los digitos son 0xF0 mas la cifra
	ld c,a			;7513
	ld b,001h		;7514
	call rellena_en		;7516
	ld de,0784eh		;7519   ; y los de abajo a la VRAM 0x384E
	ld hl,0e035h		;751c   ; 0xE035, los del segundo
	pop bc			;751f
	djnz juego_bando		;7520
	ei			;7522
	xor a			;7523
	ld (0e040h),a		;7524   ; y se borra el rotulo
	jp pinta_el_rotulo		;7527
empieza_el_punto:		; Deja limpias las variables del punto y coloca la pelota
	ld hl,0e0a0h		;752a   ; 0xE0A0, 0x35 bytes de variables de la jugada
	ld bc,00035h		;752d
	call borra_ram		;7530
	ld l,043h		;7533   ; 0xE043, doce mas
	ld bc,0000ch		;7535
	call borra_ram		;7538
	ld hl,0550ah		;753b   ; los ocho valores de arranque de 0x550A
	ld e,0b7h		;753e   ; van a 0xE0B7, que es la pelota
	ld bc,00008h		;7540
	ldir		;7543
	ld hl,0775bh		;7545   ; y los cinco de 0x775B
	ld e,0ach		;7548   ; a 0xE0AC
	ld c,005h		;754a
	ldir		;754c
	xor a			;754e
	ld (0e062h),a		;754f   ; 0xE062 a cero
	inc a			;7552
	ld hl,0e051h		;7553   ; 0xE051 y 0xE050 llevan el turno
	bit 0,(hl)		;7556
	jr z,punto_lado_del_saque		;7558
	ld a,003h		;755a   ; en dobles el turno da cuatro vueltas
punto_lado_del_saque:		; El bit 0 dice de que lado se saca
	dec hl			;755c   ; la casilla de antes es el turno
	push hl			;755d
	and (hl)			;755e
	bit 0,a		;755f   ; el bit 0 dice de que lado se saca
	jr z,punto_busca_columna		;7561
	inc a			;7563
	push hl			;7564
	ld l,00eh		;7565   ; 0xE00E, cuantos jugadores hay
	bit 0,(hl)		;7567
	jr z,punto_recupera		;7569
	add a,002h		;756b
punto_recupera:		; Vuelve al principio de la tabla
	pop hl			;756d
punto_busca_columna:		; Tres bytes hasta las columnas
	inc hl			;756e   ; tres bytes hasta la tabla de columnas
	inc hl			;756f
	inc hl			;7570
	call suma_a_hl		;7571   ; y de ahi sale la columna del que saca
	ld a,(hl)			;7574
	pop hl			;7575
	push af			;7576
	ld bc,014ffh		;7577   ; 0x14 de altura y 0xFF de marca
	ld d,0aah		;757a   ; 0xAA es la fila desde la que se saca
	call hay_dos_jugadores		;757c   ; con dos jugadores se mira el bit 1
	jr nz,punto_lado_alto		;757f
	bit 1,(hl)		;7581
	jr z,punto_coloca_pelota		;7583
	jr punto_altura_alta		;7585
punto_lado_alto:		; El otro lado de la pista
	bit 0,(hl)		;7587   ; y con uno, el bit 0
	jr z,punto_coloca_pelota		;7589
punto_altura_alta:		; Diez de altura y 0x23 de fila
	ld bc,00a00h		;758b   ; del otro lado, diez de altura
	ld d,023h		;758e   ; y 0x23, la fila de arriba
punto_coloca_pelota:		; Deja la pelota y su sombra en su sitio
	pop af			;7590
	add a,b			;7591
	ld ix,0e0b7h		;7592   ; 0xE0B7 es la pelota
	ld (ix+001h),a		;7596   ; su columna
	ld (ix+005h),a		;7599   ; y la de su sombra
	ld (ix+000h),d		;759c   ; la fila
	ld a,d			;759f
	sub 00dh		;75a0   ; la sombra, trece mas abajo
	ld (ix+004h),a		;75a2
	ld (ix+020h),c		;75a5   ; y 0xE0D7 dice hacia donde sale
	ld a,0ffh		;75a8
	ld (0e0dfh),a		;75aa   ; 0xE0DF a 0xFF
	ld hl,0e042h		;75ad   ; 0xE042 sube uno: hay punto en marcha
	inc (hl)			;75b0
	xor a			;75b1
	ld (0e060h),a		;75b2   ; 0xE060 a cero: la pista se descongela
	inc a			;75b5
	ld (0e0d8h),a		;75b6   ; 0xE0D8 a uno: ya hay pelota
	call prepara_el_saque		;75b9   ; y a colocar a todos para el saque
	ei			;75bc
	ret			;75bd
pinta_tres_filas:		; Suelta parejas de tiles en tres filas seguidas de la VRAM
	ld c,003h		;75be   ; tres filas
	ld de,0795bh		;75c0   ; empezando en la VRAM 0x395B
tres_filas_bucle:		; Dos tiles, y la fila siguiente
	ld b,002h		;75c3   ; dos tiles por fila
	call escribe_bloque_en		;75c5
	push hl			;75c8
	inc hl			;75c9
	inc hl			;75ca
	ld hl,00020h		;75cb   ; y la fila siguiente, 0x20 bytes mas abajo
	add hl,de			;75ce
	ex de,hl			;75cf
	pop hl			;75d0
	dec c			;75d1
	jr nz,tres_filas_bucle		;75d2
	ret			;75d4
parpadea_el_bando:		; Enciende y apaga el rotulo del que le toca sacar
	ld hl,07760h		;75d5   ; PLY y MSX
	call hay_dos_jugadores		;75d8   ; o 1UP y 2UP si juegan dos personas
	jr nz,bando_elige_casilla		;75db
	ld hl,07766h		;75dd
bando_elige_casilla:		; 0xE0C6 dice cual de los dos parpadea
	ld de,07829h		;75e0   ; el de arriba va a la VRAM 0x3829
	ld a,(0e0c6h)		;75e3   ; 0xE0C6 dice cual de los dos parpadea
	or a			;75e6
	jr z,bando_ritmo		;75e7
	ld a,003h		;75e9   ; tres tiles de diferencia entre uno y otro
	call suma_a_hl		;75eb
	ld e,049h		;75ee   ; y el de abajo, en 0x3849
bando_ritmo:		; El bit 4 del contador marca el ritmo
	ld b,003h		;75f0   ; tres tiles
	ld a,(0e000h)		;75f2   ; el bit 4 del contador marca el ritmo
	bit 4,a		;75f5
	jr z,bando_enciende		;75f7
	xor a			;75f9
	ld (0e0c7h),a		;75fa   ; 0xE0C7 y 0xE0C8 evitan repetir el mismo paso
	ld a,(0e0c8h)		;75fd
	or a			;7600
	ret nz			;7601
	ld c,a			;7602   ; apagado: se escribe el tile vacio
	inc a			;7603
	ld (0e0c8h),a		;7604
	jp rellena_en		;7607   ; tres tiles a cero
bando_enciende:		; Y aqui se vuelve a escribir el rotulo
	xor a			;760a
	ld (0e0c8h),a		;760b   ; y aqui el encendido
	ld a,(0e0c7h)		;760e
	or a			;7611
	ret nz			;7612
	inc a			;7613
	ld (0e0c7h),a		;7614
	jp escribe_bloque_en		;7617   ; con el rotulo de verdad
pinta_los_dos_bandos:		; Deja los dos rotulos puestos, sin parpadeo
	ld c,002h		;761a   ; dos bandos
	ld hl,07760h		;761c   ; PLY y MSX
	ld de,07829h		;761f   ; el primero en la VRAM 0x3829
	call hay_dos_jugadores		;7622   ; o 1UP y 2UP con dos jugadores
	jr nz,bandos_bucle		;7625
	ld hl,07766h		;7627
bandos_bucle:		; Un bando por vuelta, una fila mas abajo
	ld b,003h		;762a   ; tres tiles cada uno
	call escribe_bloque_en		;762c
	ex de,hl			;762f
	ld a,020h		;7630   ; y el segundo una fila mas abajo
	call suma_a_hl		;7632
	ex de,hl			;7635
	dec c			;7636
	jr nz,bandos_bucle		;7637
	ret			;7639

; ----------------------------------------------------------------------
; DATOS tabla_de_mensajes: 13 punteros a los rotulos del partido
;   0x763a..0x7654  (26 bytes)
DATA_tabla_de_mensajes:
	defw 07654h,07668h,0766fh,07677h,0767fh,07686h,07692h,076a2h	; 763a
	defw 076a8h,076b0h,076bdh,076cah,07699h	; 764a

; ----------------------------------------------------------------------
; DATOS mensajes_del_partido: DOUBLE FAULT, IN, OUT, NET, DEUCE, GAME, LET,
;   1ST, 2ND, FINAL
;   0x7654..0x76d7  (131 bytes)
DATA_mensajes_del_partido:
	defb 06fh,0feh,004h,04bh,0ffh,078h,0c4h,07ah,0feh,004h,04bh,012h,0ffh,079h,006h,04bh	; 7654  o..K.x.z..K..y.K
	defb 04bh,04bh,0ffh,0ffh,0ffh,079h,006h,0d9h,0deh,0ffh,0ffh,0ffh,079h,006h,0dfh,0e4h	; 7664  KK...y......y...
	defb 0e3h,0ffh,0ffh,0ffh,079h,006h,0deh,0d5h,0e3h,0ffh,0ffh,0d4h,0d5h,0e4h,0d3h,0d5h	; 7674  ....y...........
	defb 0ffh,0ffh,0ffh,078h,0c4h,0d4h,0dfh,0e4h,0d2h,0dch,0d5h,0ffh,078h,0e4h,0d6h,0d1h	; 7684  ...x........x...
	defb 0e4h,0dch,0e3h,0ffh,0ffh,0ffh,078h,0e4h,0e2h,0d5h,0e3h,0ffh,078h,0c4h,0d7h,0d1h	; 7694  ......x.....x...
	defb 0ddh,0d5h,0ffh,0ffh,0ffh,079h,006h,0dch,0d5h,0e3h,0ffh,0ffh,06fh,04bh,0f1h,0e2h	; 76a4  .....y......oK..
	defb 0e3h,0ffh,079h,006h,0e2h,0d5h,0e3h,0ffh,0ffh,06fh,04bh,0f2h,0deh,0d4h,0ffh,079h	; 76b4  ..y......oK....y
	defb 006h,0e2h,0d5h,0e3h,0ffh,0ffh,0d6h,0d9h,0deh,0d1h,0dch,0ffh,079h,006h,0e2h,0d5h	; 76c4  ............y...
	defb 0e3h,0ffh,0ffh	; 76d4

; ----------------------------------------------------------------------
; DATOS tabla_de_tanteos: 18 punteros, uno por punto del juego
;   0x76d7..0x76fb  (36 bytes)
DATA_tabla_de_tanteos:
	defw 076fbh,076ebh,076efh,076f3h,076e7h,076f7h,076f7h,076fbh	; 76d7
	defw 00000h,0ffffh,0f5f1h,0ffffh,0f0f3h,0ffffh,0f0f4h,0ffffh	; 76e7
	defw 0d100h,0ffffh	; 76f7

; ----------------------------------------------------------------------
; DATOS tanteos: Los cinco del tenis: 00, 15, 30, 40 y la A de ventaja
;   0x76fb..0x76ff  (4 bytes)
DATA_tanteos:
	defb 0f0h,0f0h,0ffh,0ffh	; 76fb

; ----------------------------------------------------------------------
; DATOS puestos_individuales: Cuatro bloques de ocho: las parejas (y,x) de
;   salida
;   0x76ff..0x771f  (32 bytes)
DATA_puestos_individuales:
	defb 090h,090h,070h,050h,00ah,050h,024h,090h	; 76ff  ..pP.P$.
	defb 088h,090h,070h,050h,005h,050h,024h,090h	; 7707  ..pP.P$.
	defb 070h,050h,090h,090h,00ah,050h,024h,090h	; 770f  pP...P$.
	defb 070h,050h,088h,090h,024h,090h,005h,050h	; 7717  pP..$..P

; ----------------------------------------------------------------------
; DATOS puestos_dobles: Lo mismo para el modo de dobles
;   0x771f..0x773f  (32 bytes)
DATA_puestos_dobles:
	defb 090h,090h,010h,050h,0cfh,0cfh,0cfh,0cfh	; 771f  ...P....
	defb 010h,050h,090h,090h,0cfh,090h,0cfh,0cfh	; 7727  .P......
	defb 005h,050h,098h,090h,0cfh,0cfh,0cfh,0cfh	; 772f  .P......
	defb 088h,090h,005h,050h,0cfh,050h,0cfh,0cfh	; 7737  ...P.P..

; ----------------------------------------------------------------------
; DATOS atributos_de_la_derecha: Cuatro sprites en x=216, con los patrones
;   0x3C a 0x48
;   0x773f..0x774f  (16 bytes)
DATA_atributos_de_la_derecha:
	defb 054h,0d8h,03ch,000h	; 773f
	defb 054h,0d8h,040h,000h	; 7743
	defb 054h,0d8h,044h,000h	; 7747
	defb 054h,0d8h,048h,000h	; 774b

; ----------------------------------------------------------------------
; DATOS tiles_recogepelotas_sale: Los seis tiles que le abren hueco al salir
;   0x774f..0x7755  (6 bytes)
DATA_tiles_recogepelotas_sale:
	defb 04bh,04bh,04bh,04bh,04bh,04bh	; 774f

; ----------------------------------------------------------------------
; DATOS tiles_recogepelotas_vuelve: Los seis que devuelven el fondo al
;   recogerse
;   0x7755..0x775b  (6 bytes)
DATA_tiles_recogepelotas_vuelve:
	defb 0b9h,04bh,0bah,0bbh,0bch,0bdh	; 7755

; ----------------------------------------------------------------------
; DATOS arranque_de_la_pelota: Los cinco valores que 0x7545 copia a 0xE0AC al
;   empezar el punto
;   0x775b..0x7760  (5 bytes)
DATA_arranque_de_la_pelota:
	defb 0b0h,000h,000h,000h,0ffh	; 775b

; ----------------------------------------------------------------------
; DATOS rotulos_del_marcador: PLY y MSX, los dos bandos del tanteo; la pista
;   viene con CPU escrito y esto lo tapa
;   0x7760..0x7766  (6 bytes)
DATA_rotulos_del_marcador:
	defb 0e0h,0dch,0e7h	; 7760
	defb 0ddh,0e2h,0e8h	; 7763

; ----------------------------------------------------------------------
; DATOS rotulos_de_dos_jugadores: 1UP y 2UP, los que sustituyen a PLY y MSX
;   cuando juegan dos personas
;   0x7766..0x776c  (6 bytes)
DATA_rotulos_de_dos_jugadores:
	defb 0f1h,0e4h,0e0h,0f2h,0e4h,0e0h	; 7766

; ----------------------------------------------------------------------
; DATOS tabla_de_figuras_2: 5 punteros a grupo
;   0x776c..0x7776  (10 bytes)
DATA_tabla_de_figuras_2:
	defw 07776h,07781h,07797h,0778ch,077a2h	; 776c

; ----------------------------------------------------------------------
; DATOS grupo_7776: Cuantas capas dibujar y los cinco punteros
;   0x7776..0x7781  (11 bytes)
DATA_grupo_7776:
	defb 004h,0afh,077h,0bfh,077h,0c1h,077h,0adh,077h,0c3h,077h	; 7776  ..w.w.w.w.w

; ----------------------------------------------------------------------
; DATOS grupo_7781: Cuantas capas dibujar y los cinco punteros
;   0x7781..0x778c  (11 bytes)
DATA_grupo_7781:
	defb 004h,0dfh,077h,0f8h,077h,0f1h,077h,0cbh,077h,0ffh,077h	; 7781  ..w.w.w.w.w

; ----------------------------------------------------------------------
; DATOS grupo_778c: Cuantas capas dibujar y los cinco punteros
;   0x778c..0x7797  (11 bytes)
DATA_grupo_778c:
	defb 004h,045h,078h,0f8h,077h,055h,078h,031h,078h,05ch,078h	; 778c  .Ex.wUx1x\x

; ----------------------------------------------------------------------
; DATOS grupo_7797: Cuantas capas dibujar y los cinco punteros
;   0x7797..0x77a2  (11 bytes)
DATA_grupo_7797:
	defb 004h,018h,078h,0f8h,077h,022h,078h,007h,078h,029h,078h	; 7797  ..x.w"x.x)x

; ----------------------------------------------------------------------
; DATOS grupo_77a2: Cuantas capas dibujar y los cinco punteros
;   0x77a2..0x77ad  (11 bytes)
DATA_grupo_77a2:
	defb 004h,077h,078h,0f8h,077h,081h,078h,064h,078h,088h,078h	; 77a2  .wx.w.xdx.x

; ----------------------------------------------------------------------
; DATOS patron2_77ad: Un sprite de 16x16 comprimido
;   0x77ad..0x77af  (2 bytes)
DATA_patron2_77ad:
	defb 000h,020h	; 77ad

; ----------------------------------------------------------------------
; DATOS patron2_77af: Un sprite de 16x16 comprimido
;   0x77af..0x77bf  (16 bytes)
DATA_patron2_77af:
	defb 000h,003h,03fh,02fh,07fh,03fh,01eh,000h,001h,00ch,01ch,018h,038h,030h,000h,012h	; 77af  ..?/.?......80..

; ----------------------------------------------------------------------
; DATOS patron2_77bf: Un sprite de 16x16 comprimido
;   0x77bf..0x77c1  (2 bytes)
DATA_patron2_77bf:
	defb 000h,020h	; 77bf

; ----------------------------------------------------------------------
; DATOS patron2_77c1: Un sprite de 16x16 comprimido
;   0x77c1..0x77c3  (2 bytes)
DATA_patron2_77c1:
	defb 000h,020h	; 77c1

; ----------------------------------------------------------------------
; DATOS patron2_77c3: Un sprite de 16x16 comprimido
;   0x77c3..0x77c5  (2 bytes)
DATA_patron2_77c3:
	defb 000h,000h	; 77c3

; ----------------------------------------------------------------------
; DATOS sin_alcanzar_77c5: Seis bytes entre patrones a los que no apunta nadie
;   0x77c5..0x77cb  (6 bytes)
DATA_sin_alcanzar_77c5:
	defb 004h,000h,004h,000h,004h,000h	; 77c5

; ----------------------------------------------------------------------
; DATOS patron2_77cb: Un sprite de 16x16 comprimido
;   0x77cb..0x77df  (20 bytes)
DATA_patron2_77cb:
	defb 03eh,03eh,0feh,000h,007h,003h,007h,007h,006h,006h,00eh,000h,009h,0f0h,0f0h,0f0h	; 77cb  >>..............
	defb 070h,078h,038h,01ch	; 77db

; ----------------------------------------------------------------------
; DATOS patron2_77df: Un sprite de 16x16 comprimido
;   0x77df..0x77f1  (18 bytes)
DATA_patron2_77df:
	defb 000h,008h,0ach,0fch,0dbh,0dbh,078h,010h,078h,078h,000h,00ah,0c0h,0e0h,060h,060h	; 77df  ......x.xx....``
	defb 000h,002h	; 77ef

; ----------------------------------------------------------------------
; DATOS patron2_77f1: Un sprite de 16x16 comprimido
;   0x77f1..0x77f8  (7 bytes)
DATA_patron2_77f1:
	defb 000h,01bh,004h,004h,00fh,01fh,00ch	; 77f1

; ----------------------------------------------------------------------
; DATOS patron2_77f8: Un sprite de 16x16 comprimido
;   0x77f8..0x77ff  (7 bytes)
DATA_patron2_77f8:
	defb 000h,01ch,005h,000h,001h,002h,002h	; 77f8

; ----------------------------------------------------------------------
; DATOS patron2_77ff: Un sprite de 16x16 comprimido
;   0x77ff..0x7807  (8 bytes)
DATA_patron2_77ff:
	defb 0fbh,001h,0f7h,0f5h,0fah,0fah,000h,000h	; 77ff  ........

; ----------------------------------------------------------------------
; DATOS patron2_7807: Un sprite de 16x16 comprimido
;   0x7807..0x7818  (17 bytes)
DATA_patron2_7807:
	defb 03ch,03eh,0feh,000h,007h,001h,001h,000h,00ch,020h,060h,0e0h,0e0h,0e0h,060h,060h	; 7807  <>....... `...``
	defb 0e0h	; 7817

; ----------------------------------------------------------------------
; DATOS patron2_7818: Un sprite de 16x16 comprimido
;   0x7818..0x7822  (10 bytes)
DATA_patron2_7818:
	defb 000h,018h,0ach,0fch,0dch,0dch,078h,006h,01eh,01ch	; 7818  ......x...

; ----------------------------------------------------------------------
; DATOS patron2_7822: Un sprite de 16x16 comprimido
;   0x7822..0x7829  (7 bytes)
DATA_patron2_7822:
	defb 000h,01bh,004h,006h,00fh,073h,002h	; 7822

; ----------------------------------------------------------------------
; DATOS patron2_7829: Un sprite de 16x16 comprimido
;   0x7829..0x7831  (8 bytes)
DATA_patron2_7829:
	defb 0fbh,0f9h,0f7h,0f5h,0fah,0fah,000h,000h	; 7829  ........

; ----------------------------------------------------------------------
; DATOS patron2_7831: Un sprite de 16x16 comprimido
;   0x7831..0x7845  (20 bytes)
DATA_patron2_7831:
	defb 000h,009h,00fh,00fh,00fh,00eh,01eh,01ch,038h,07ch,07ch,07fh,000h,007h,0c0h,0e0h	; 7831  ........8||.....
	defb 0e0h,060h,060h,070h	; 7841

; ----------------------------------------------------------------------
; DATOS patron2_7845: Un sprite de 16x16 comprimido
;   0x7845..0x7855  (16 bytes)
DATA_patron2_7845:
	defb 000h,00ah,003h,007h,006h,006h,000h,00ah,035h,03fh,0bbh,0bbh,01eh,008h,01eh,01eh	; 7845  ........5?......

; ----------------------------------------------------------------------
; DATOS patron2_7855: Un sprite de 16x16 comprimido
;   0x7855..0x785c  (7 bytes)
DATA_patron2_7855:
	defb 000h,01bh,080h,080h,0c0h,0e0h,080h	; 7855

; ----------------------------------------------------------------------
; DATOS patron2_785c: Un sprite de 16x16 comprimido
;   0x785c..0x7863  (7 bytes)
DATA_patron2_785c:
	defb 0fbh,0ffh,0f7h,0feh,0fah,000h,000h	; 785c

; ----------------------------------------------------------------------
; DATOS sin_alcanzar_7863: Un byte entre patrones al que no apunta nadie
;   0x7863..0x7864  (1 bytes)
DATA_sin_alcanzar_7863:
	defb 000h	; 7863

; ----------------------------------------------------------------------
; DATOS patron2_7864: Un sprite de 16x16 comprimido
;   0x7864..0x7877  (19 bytes)
DATA_patron2_7864:
	defb 000h,008h,004h,006h,007h,007h,007h,006h,006h,007h,03ch,07ch,07fh,000h,007h,080h	; 7864  ..........<|....
	defb 080h,000h,004h	; 7874

; ----------------------------------------------------------------------
; DATOS patron2_7877: Un sprite de 16x16 comprimido
;   0x7877..0x7881  (10 bytes)
DATA_patron2_7877:
	defb 000h,018h,035h,03fh,03bh,03bh,01eh,060h,078h,038h	; 7877  ..5?;;.`x8

; ----------------------------------------------------------------------
; DATOS patron2_7881: Un sprite de 16x16 comprimido
;   0x7881..0x7888  (7 bytes)
DATA_patron2_7881:
	defb 000h,01bh,010h,030h,078h,067h,020h	; 7881

; ----------------------------------------------------------------------
; DATOS patron2_7888: Un sprite de 16x16 comprimido
;   0x7888..0x7890  (8 bytes)
DATA_patron2_7888:
	defb 0fbh,0ffh,0f7h,0feh,0fah,0fdh,000h,000h	; 7888  ........

; ----------------------------------------------------------------------
; DATOS atributos_del_recogepelotas: Cuatro sprites escondidos (y=0xCF) con
;   los patrones 0x2C a 0x38. OJO: 0x4272 pide 22 bytes y aqui solo hay 16,
;   asi que se lleva a la VRAM los seis primeros de 0x78A0
;   0x7890..0x78a0  (16 bytes)
DATA_atributos_del_recogepelotas:
	defb 0cfh,0cfh,02ch,00bh	; 7890
	defb 0cfh,0cfh,030h,001h	; 7894
	defb 0cfh,0cfh,034h,004h	; 7898
	defb 0cfh,0cfh,038h,00fh	; 789c

; ======================================================================
; CODIGO 0x78a0..0x790a  (106 bytes)
; ======================================================================


coloca_al_recogepelotas:		; Le carga las posturas y le coloca sus cuatro sprites
	exx			;78a0
	ld hl,07b2ch		;78a1   ; sus atributos viven en la VRAM 0x3B2C
	ld de,05960h		;78a4   ; y sus patrones en la 0x1960, o sea a partir del sprite 0x2C
	ld bc,0e03ch		;78a7   ; 0xE03C es su paso
	ld a,(bc)			;78aa
	dec bc			;78ab   ; dos bytes atras estan 0xE03A y 0xE03B: su sitio
	dec bc			;78ac
	push bc			;78ad
	push hl			;78ae
	ld hl,0776ch		;78af   ; la tabla de grupos de 0x776C
	rlca			;78b2   ; dos bytes por entrada
	call busca_en_tabla_desde		;78b3
	ld b,(hl)			;78b6   ; el primer byte del grupo dice cuantas capas se dibujan
	inc hl			;78b7
recogepelotas_capa:		; Una de las cinco capas
	push bc			;78b8
	push hl			;78b9
	ld a,(hl)			;78ba   ; y detras van los cinco punteros
	inc hl			;78bb
	ld h,(hl)			;78bc
	ld l,a			;78bd
	xor a			;78be
	cp h			;78bf   ; un puntero con el byte alto a cero es una capa vacia
	jr z,recogepelotas_capa_sigue		;78c0
	call descomprime_sprite		;78c2   ; y si no, se descomprimen sus 32 bytes
recogepelotas_capa_sigue:		; Treinta y dos bytes mas alla
	ld hl,00020h		;78c5   ; la capa siguiente va 32 bytes mas alla
	add hl,de			;78c8
	ex de,hl			;78c9
	pop hl			;78ca
	inc hl			;78cb   ; y el puntero siguiente, dos mas
	inc hl			;78cc
	pop bc			;78cd
	djnz recogepelotas_capa		;78ce
	ld a,(hl)			;78d0   ; el sexto puntero lleva a las parejas (y,x)
	inc hl			;78d1
	ld h,(hl)			;78d2
	ld l,a			;78d3
	pop de			;78d4
	pop bc			;78d5
	exx			;78d6
	push bc			;78d7
	ld a,(00007h)		;78d8   ; el puerto de datos del VDP
	ld c,a			;78db
	exx			;78dc
	ld a,004h		;78dd   ; cuatro sprites
recogepelotas_sprite:		; Un sprite: su y, su x y lo demas
	ex af,af'			;78df
	call pon_escritura_con_reintento		;78e0   ; coloca el puntero de escritura
	ld a,(hl)			;78e3
	cp 0cfh		;78e4   ; un 0xCF en la y esconde ese sprite
	jr z,recogepelotas_suelta_x		;78e6
	ld a,(bc)			;78e8   ; y si no, se le suma la posicion del recogepelotas
	add a,(hl)			;78e9
	cp 0d0h		;78ea   ; 0xD0 es el valor que le dice al VDP que pare
	jr nz,recogepelotas_suelta_y		;78ec
	ld a,0cfh		;78ee   ; asi que se cambia por 0xCF, que es la fila de al lado
recogepelotas_suelta_y:		; La y ya sumada
	exx			;78f0
	out (c),a		;78f1
	exx			;78f3
	inc bc			;78f4
	inc hl			;78f5
	ld a,(bc)			;78f6   ; y ahora la x, con su suma
	add a,(hl)			;78f7
	dec bc			;78f8
recogepelotas_suelta_x:		; Y la x
	exx			;78f9
	out (c),a		;78fa
	exx			;78fc
	inc hl			;78fd
	inc de			;78fe   ; cuatro bytes por sprite: y, x, patron y color
	inc de			;78ff
	inc de			;7900
	inc de			;7901
	ex af,af'			;7902
	dec a			;7903   ; hasta los cuatro
	jr nz,recogepelotas_sprite		;7904
	exx			;7906
	pop bc			;7907
	ei			;7908
	ret			;7909

; ----------------------------------------------------------------------
; DATOS colores_del_aviso: Dos juegos de cuatro tiles: 0x746F los alterna y
;   asi parpadea el rotulo de falta
;   0x790a..0x7932  (40 bytes)
DATA_colores_del_aviso:
	defb 07fh,0bfh,0bfh,0bfh,08fh,08fh,08fh,07fh	; 790a  ........
	defb 00fh,03fh,03fh,03fh,0dfh,0dfh,0dfh,00fh	; 7912  .???....
	defb 07fh,0bfh,0bfh,0bfh,08fh,08fh,08fh,07fh	; 791a  ........
	defb 00fh,03fh,03fh,03fh,0dfh,0dfh,0dfh,00fh	; 7922  .???....
	defb 07fh,0bfh,0bfh,0bfh,08fh,08fh,08fh,07fh	; 792a  ........

; ======================================================================
; CODIGO 0x7932..0x7c5d  (811 bytes)
; ======================================================================


reparte_el_tanteo:		; La cuenta del tenis: 15, 30, 40, iguales y ventaja
	xor a			;7932
	ld hl,0e041h		;7933   ; 0xE041 pide repartir el punto
	cp (hl)			;7936
	ret z			;7937
	ld (hl),a			;7938   ; y se apaga en cuanto se atiende
	ld ix,0e040h		;7939   ; 0xE040 en adelante, los rotulos
	ld (ix+000h),000h		;793d
	ld a,(0e0c0h)		;7941   ; 0xE0C0 marca la pelota rodando
	or a			;7944
	jr z,tanteo_pelota_fuera		;7945
	ld a,(0e042h)		;7947   ; 0xE042 dice si el punto seguia abierto
	or a			;794a
	jr z,tanteo_pelota_fuera		;794b
	inc hl			;794d
	inc hl			;794e
	bit 0,(hl)		;794f   ; el bit 0 de 0xE043: la pelota entro
	jr z,tanteo_mira_la_falta		;7951
	ld (0e0e2h),a		;7953   ; 0xE0E2 marca el punto ya repartido
	dec a			;7956
	ld (0e042h),a		;7957   ; 0xE042 a cero
	ld (ix+000h),008h		;795a   ; rotulo 8
	ld (ix+01ah),005h		;795e
	jr tanteo_pide_recolocar		;7962
tanteo_pelota_fuera:		; Rotulo 7: la pelota se fue
	ld (ix+01ah),007h		;7964   ; rotulo 7 y sonido 1
	ld (ix+000h),001h		;7968
	inc hl			;796c
	inc hl			;796d
	bit 0,(hl)		;796e   ; 0xE045 dice si la falta fue de saque
	jr z,tanteo_mira_la_falta		;7970
	cpl			;7972
	ld (0e04bh),a		;7973   ; 0xE04B se queda con quien pierde el punto
	inc (ix+01ah)		;7976
	jr tanteo_apunta		;7979
tanteo_mira_la_falta:		; Si hubo falta, otro rotulo
	dec hl			;797b   ; y aqui la pelota que se fue fuera
	ld a,(hl)			;797c
	or a			;797d
	jr z,tanteo_sin_falta		;797e
	ld (ix+01ah),006h		;7980   ; rotulo 5, con su sonido
	ld (ix+000h),005h		;7984
	dec a			;7988
	jr nz,tanteo_apunta		;7989
	inc (ix+000h)		;798b
tanteo_pide_recolocar:		; 0xE049 y 0xE04E lo piden
	inc a			;798e
	ld (0e049h),a		;798f   ; 0xE049 y 0xE04E piden recolocar a todos
	ld (0e04eh),a		;7992
	ret			;7995
tanteo_sin_falta:		; El punto se resuelve sin aviso
	inc hl			;7996   ; el bit 0 de la casilla siguiente
	inc hl			;7997
	inc (ix+000h)		;7998
	bit 0,(hl)		;799b
	jr nz,tanteo_rodando		;799d
	ld a,(0e0c0h)		;799f   ; 0xE0C0 otra vez
	or a			;79a2
	jr z,tanteo_apunta		;79a3
tanteo_rodando:		; Con la pelota rodando, otro rotulo
	inc (ix+000h)		;79a5
	ld (ix+01ah),005h		;79a8
tanteo_apunta:		; Deja pedida la recolocacion
	xor a			;79ac
	ld (ix+002h),a		;79ad
	inc a			;79b0
	ld (0e049h),a		;79b1   ; 0xE049: hay que recolocar
	ld hl,0e030h		;79b4   ; 0xE030 y 0xE031 son los puntos de los dos
	ld de,0e031h		;79b7
	ld a,(0e045h)		;79ba   ; 0xE045 dice de quien fue la falta
	rrca			;79bd
	jr c,tanteo_quien_pierde		;79be
	ex de,hl			;79c0
tanteo_quien_pierde:		; 0xE04B se queda con el que lo pierde
	ld a,(0e04bh)		;79c1   ; 0xE04B, quien pierde
	or a			;79c4
	jr nz,tanteo_turno		;79c5
	ex de,hl			;79c7
tanteo_turno:		; Con dos jugadores hay que mirar el turno
	call hay_dos_jugadores		;79c8   ; con dos jugadores hay que mirar el turno
	jr nz,tanteo_sube_el_punto		;79cb
	ld a,(0e050h)		;79cd   ; 0xE050, de quien es el saque
	and 003h		;79d0
	jr z,tanteo_sube_el_punto		;79d2
	cp 003h		;79d4
	jr z,tanteo_sube_el_punto		;79d6
	ex de,hl			;79d8
tanteo_sube_el_punto:		; El que gana sube uno
	inc (hl)			;79d9   ; y el que gana sube un punto
	ld a,(hl)			;79da
	cp 003h		;79db   ; con tres puntos, el juego esta al borde
	jr nz,tanteo_mira_el_juego		;79dd
	ld a,(de)			;79df   ; si los dos van a tres, son iguales
	cp 003h		;79e0
	jr z,tanteo_iguales		;79e2
tanteo_mira_el_juego:		; Con seis, el juego esta ganado
	ld a,(hl)			;79e4
	cp 006h		;79e5   ; con seis, se acabo el juego
	jr z,apunta_el_juego		;79e7
	cp 005h		;79e9   ; el cinco es la ventaja
	jr nz,tanteo_cuarenta		;79eb
	ld a,003h		;79ed   ; y si la pierde, vuelven a tres: iguales otra vez
	ld (hl),a			;79ef
	ld (de),a			;79f0
tanteo_iguales:		; Los dos a tres: iguales
	ld (0e046h),a		;79f1   ; 0xE046 avisa de la falta
	ret			;79f4
tanteo_cuarenta:		; El cuatro es el 40
	cp 004h		;79f5   ; el cuatro es el 40
	ret nz			;79f7
	ld a,(de)			;79f8
	cp 003h		;79f9   ; y si el otro esta en tres, se va a ventaja
	jr nz,tanteo_pierde_ventaja		;79fb
	inc (hl)			;79fd
	inc a			;79fe
	ld (de),a			;79ff
	ret			;7a00
tanteo_pierde_ventaja:		; Se vuelve al que estaba
	dec (hl)			;7a01
apunta_el_juego:		; Sube el juego al que lo gana, y mira si con eso cierra el set
	ld a,(0e00eh)		;7a02   ; 0xE00E, cuantos jugadores hay
	cp 002h		;7a05
	jr nz,juego_elige_casilla		;7a07
	ld a,(0e050h)		;7a09   ; 0xE050, el turno de saque
	or a			;7a0c
	jr z,juego_elige_casilla		;7a0d
	cp 003h		;7a0f
	jr z,juego_elige_casilla		;7a11
	ld a,l			;7a13   ; en dobles se le da la vuelta al bando
	rrca			;7a14
	ccf			;7a15
	rla			;7a16
	ld l,a			;7a17
juego_elige_casilla:		; 0x30 es la casilla de arriba
	ld a,l			;7a18
	ld hl,0e032h		;7a19   ; 0xE032 son los juegos del primero
	cp 030h		;7a1c   ; 0x30 es la casilla de arriba
	ld a,000h		;7a1e
	jr z,juego_apunta		;7a20
	inc a			;7a22
	ld l,035h		;7a23   ; y 0xE035 los del segundo
juego_apunta:		; El juego sube uno en el marcador
	ld (0e0c6h),a		;7a25   ; 0xE0C6 dice cual de los dos rotulos parpadea
	ld a,(0e038h)		;7a28   ; 0xE038 es el set que se juega
	ld b,a			;7a2b
	call suma_a_hl		;7a2c
	inc (hl)			;7a2f   ; y el juego sube uno
	xor a			;7a30   ; el cero que se va a escribir
	ld (0409ah),a		;7a31   ; PROTECCION ANTICOPIA: 0x409A es el `ret` del manejador de interrupcion
	ld a,006h		;7a34   ; en ROM no pasa nada, pero en RAM ese `ret` se vuelve `nop` y cae en INIT
	ld (0e04ah),a		;7a36   ; 0xE04A marca el juego cerrado
	cp (hl)			;7a39   ; con seis juegos se gana el set
	ret nz			;7a3a
	ld (0e047h),a		;7a3b   ; 0xE047 lo anuncia
	dec b			;7a3e   ; y en el ultimo set hay que mirar tambien al otro
	jr nz,set_comprueba		;7a3f
	dec hl			;7a41
	cp (hl)			;7a42
	jr z,set_ganado		;7a43
	ret			;7a45
set_comprueba:		; Y en el ultimo, tambien al otro
	dec b			;7a46
	ret nz			;7a47
set_ganado:		; 0xE048: se acabo el partido
	ld (0e048h),a		;7a48   ; 0xE048: se acabo el partido
	ret			;7a4b
suena:		; Pide una musica o un efecto, si el momento lo permite
	push af			;7a4c
	dec a			;7a4d   ; los sonidos 1, 2 y 3 suenan siempre
	jr z,sonido_reserva		;7a4e
	dec a			;7a50
	jr z,sonido_reserva		;7a51
	cp 002h		;7a53
	jr z,sonido_reserva		;7a55
	ld a,(0e002h)		;7a57   ; 0xE002 dice si hay alguien jugando
	or a			;7a5a
	jr z,sonido_reserva		;7a5b   ; y en la demostracion, todo lo demas se calla
	pop af			;7a5d
	ret			;7a5e
sonido_reserva:		; Guarda los pares y va a reservar canal
	pop af			;7a5f
	push hl			;7a60   ; se guardan los dos pares que la melodia va a tocar
	push de			;7a61
	call arranca_sonido		;7a62   ; y a reservar canal
	pop de			;7a65
	pop hl			;7a66
	ret			;7a67
arranca_sonido:		; Reserva los canales que hagan falta y engancha la melodia
	ld hl,0e213h		;7a68   ; 0xE213 es la prioridad del primer canal
	ld b,003h		;7a6b   ; tres canales por omision
	ld c,a			;7a6d
	cp 081h		;7a6e   ; por encima de 0x81 es una musica: se lleva los tres
	jr nc,cabe_el_sonido		;7a70
	ld b,001h		;7a72   ; y si no, es un efecto de un solo canal
	cp 00ah		;7a74   ; el sonido 10 es el que va en dos canales
	jr nz,sonido_tercer_canal		;7a76
	call cabe_el_sonido		;7a78   ; se prueba primero con uno
	ret c			;7a7b
	ld c,04bh		;7a7c   ; y si cabe, se le anaden los canales 0x4B y 0x4C
	inc b			;7a7e
	call engancha_melodia		;7a7f
	inc c			;7a82
	inc b			;7a83
	call engancha_melodia		;7a84
	ret			;7a87
sonido_tercer_canal:		; 0xE229 es la prioridad del tercero
	ld l,029h		;7a88   ; 0xE229 es la prioridad del tercero
cabe_el_sonido:		; Solo deja entrar al que tenga mas prioridad que el que suena
	ld e,(hl)			;7a8a
	ld a,e			;7a8b
	and 03fh		;7a8c   ; los seis bits de abajo son la prioridad
	ld (hl),a			;7a8e
	ld a,c			;7a8f
	and 03fh		;7a90   ; y se comparan con la del que pide
	cp (hl)			;7a92
	ld (hl),e			;7a93   ; se guarda la nueva
	ret c			;7a94   ; si el que sonaba mandaba mas, se acabo
	add a,a			;7a95   ; dos bytes por melodia
	ld de,07c67h		;7a96   ; la tabla vive en 0x7C67
	ex de,hl			;7a99
	call suma_a_hl		;7a9a
	ex de,hl			;7a9d
	dec hl			;7a9e
	dec hl			;7a9f
engancha_melodia:		; Deja el canal listo para empezar a leer la melodia
	ld (hl),001h		;7aa0   ; la cuenta atras arranca en uno: suena ya
	inc hl			;7aa2
	ld (hl),001h		;7aa3   ; y el paso, tambien
	inc hl			;7aa5
	ld (hl),c			;7aa6   ; la prioridad
	inc hl			;7aa7
	ld a,(de)			;7aa8   ; y el puntero a la melodia, byte a byte
	ld (hl),a			;7aa9
	inc hl			;7aaa
	inc de			;7aab
	ld a,(de)			;7aac
	ld (hl),a			;7aad
	ld a,005h		;7aae   ; cinco bytes mas alla esta el resto del estado
	call suma_a_hl		;7ab0
	ld (hl),000h		;7ab3   ; que empieza a cero
	inc hl			;7ab5
	inc hl			;7ab6
	inc de			;7ab7
	djnz engancha_melodia		;7ab8   ; y otra vez con el canal siguiente
	ret			;7aba
sube_de_octava:		; El 0xFE de una melodia: cambia la octava y sigue
	inc hl			;7abb
	ld a,(ix+009h)		;7abc   ; el byte 9 lleva la octava
	inc a			;7abf
	cp (hl)			;7ac0   ; si llega al tope, la melodia se acaba
	jp z,calla_el_canal		;7ac1
	jp m,octava_vuelve_a_enganchar		;7ac4
	dec a			;7ac7
octava_vuelve_a_enganchar:		; Con la octava nueva, otra vez
	ex af,af'			;7ac8
	ld a,(ix+002h)		;7ac9   ; el byte 2 es la prioridad, que se conserva
	push bc			;7acc
	call arranca_sonido		;7acd   ; y se vuelve a enganchar con la octava nueva
	pop bc			;7ad0
	ex af,af'			;7ad1
	ld (ix+009h),a		;7ad2
	ret			;7ad5
enciende_canal:		; Toca el registro 7 del PSG para dejar sonar o callar un canal
	ld a,(0e210h)		;7ad6   ; 0xE210 es la copia del registro 7
	ld e,a			;7ad9
	ld a,c			;7ada   ; el canal 1 no se desplaza
	cp 001h		;7adb
	jr z,canal_desplaza		;7add
	dec a			;7adf
canal_desplaza:		; Tres bits por canal
	rlca			;7ae0   ; y los demas, tres bits por canal
	rlca			;7ae1
	rlca			;7ae2
	dec d			;7ae3   ; segun D, se enciende o se apaga
	jr z,canal_enciende		;7ae4
	cpl			;7ae6
	and e			;7ae7
	jr canal_ruido		;7ae8
canal_enciende:		; Deja el bit puesto
	or e			;7aea
canal_ruido:		; El bit 2, salvo que el 5 pida ruido
	set 2,a		;7aeb   ; el bit 2 siempre puesto: el tercer canal de ruido
	bit 5,a		;7aed   ; salvo si el bit 5 pide ruido de verdad
	jr z,escribe_registro_7		;7aef
	res 2,a		;7af1
escribe_registro_7:		; Guarda la copia y la manda al registro 7 del PSG
	ld (0e210h),a		;7af3   ; se guarda la copia
	ld e,a			;7af6
	ld a,007h		;7af7
	jp 00093h		;7af9   ; BIOS WRTPSG - Writes data to PSG-register | y al registro 7 del PSG
reproduce:		; Un cuadro de sonido: los tres canales, uno detras de otro
	ld a,(0e210h)		;7afc   ; la copia del registro 7
	call escribe_registro_7		;7aff
	di			;7b02
	ld c,001h		;7b03   ; el canal 1
	ld ix,0e211h		;7b05   ; 0xE211 es el estado del primero
	exx			;7b09
	ld b,003h		;7b0a   ; tres canales
	ld de,0000bh		;7b0c   ; once bytes por canal
canal_siguiente:		; Once bytes hasta el estado del siguiente
	exx			;7b0f
	ld a,(ix+002h)		;7b10   ; el byte 2 a cero significa canal libre
	or a			;7b13
	call nz,canal		;7b14
	di			;7b17
	inc c			;7b18   ; dos registros de PSG por canal
	inc c			;7b19
	exx			;7b1a
	add ix,de		;7b1b   ; y al estado del canal siguiente
	djnz canal_siguiente		;7b1d
	ret			;7b1f
canal:		; Avanza un canal: la nota, el volumen y lo que pida la melodia
	di			;7b20
	bit 6,a		;7b21   ; el bit 6 pide que no suene
	ld d,001h		;7b23
	call z,enciende_canal		;7b25   ; y si no, se enciende
	di			;7b28
	ld a,(ix+002h)		;7b29   ; el byte 2, la prioridad
	or a			;7b2c
	jp m,gasta_la_nota		;7b2d   ; con el bit 7 puesto es un efecto, que va por otro lado
	dec (ix+000h)		;7b30   ; el byte 0 es lo que le queda a la nota
	ret nz			;7b33   ; mientras dure, no se lee nada
canal_lee_melodia:		; El byte que toca de la melodia
	ld l,(ix+003h)		;7b34   ; los bytes 3 y 4 son el puntero a la melodia
	ld h,(ix+004h)		;7b37
	ld a,(hl)			;7b3a
	cp 0feh		;7b3b   ; un 0xFE cambia de octava
	jp z,sube_de_octava		;7b3d
	jr nc,calla_el_canal		;7b40   ; y por encima, la melodia se acaba
	bit 7,(ix+002h)		;7b42   ; el bit 7 del byte 2, otra vez
	jp nz,manda_de_la_melodia		;7b46
	and 0f0h		;7b49   ; el nibble alto manda: un 2 pone el volumen
	cp 020h		;7b4b
	jr nz,canal_mira_duracion		;7b4d
	ld a,(hl)			;7b4f
	and 00fh		;7b50
	ld (ix+001h),a		;7b52   ; y el byte 1 se lo queda
	inc hl			;7b55
canal_mira_duracion:		; Un 1 en el nibble alto es la duracion
	ld a,(hl)			;7b56
	and 0f0h		;7b57   ; un 1 es la duracion
	cp 010h		;7b59
	jr nz,canal_solo_ruido		;7b5b
	ld a,006h		;7b5d
	ld a,(hl)			;7b5f
	and 01fh		;7b60   ; los cinco bits de abajo son el ruido
	ld e,a			;7b62
	ld a,006h		;7b63
	call 00093h		;7b65   ; BIOS WRTPSG - Writes data to PSG-register | registro 6 del PSG: el periodo del ruido
	di			;7b68
	ld d,000h		;7b69
	call enciende_canal		;7b6b   ; y se enciende el canal
	di			;7b6e
	inc hl			;7b6f
	ld a,(hl)			;7b70
canal_solo_ruido:		; El bit 6 es el canal que solo hace ruido
	bit 6,(ix+002h)		;7b71   ; el bit 6 del byte 2 es el canal de solo ruido
	jr z,nota_nueva		;7b75
	ld a,c			;7b77
	cp 005h		;7b78   ; el canal 5 es el que lo lleva
	ld a,(hl)			;7b7a
	jr nz,nota_nueva		;7b7b
	inc hl			;7b7d
	ld (ix+003h),l		;7b7e   ; y se guarda por donde iba la melodia
	ld (ix+004h),h		;7b81
	call arranca_la_nota		;7b84
	ret			;7b87
nota_nueva:		; Lee la nota de la melodia y la manda al PSG
	and 0f0h		;7b88   ; el nibble alto es el semitono
	ld b,a			;7b8a
	xor (hl)			;7b8b   ; y el bajo, lo que dura
	ld d,a			;7b8c
	inc hl			;7b8d
	ld e,(hl)			;7b8e   ; el segundo byte de la nota
	inc hl			;7b8f
	ld (ix+003h),l		;7b90   ; se apunta por donde va la melodia
	ld (ix+004h),h		;7b93
	ex de,hl			;7b96
	call manda_periodo		;7b97   ; y se manda al PSG
	ld a,b			;7b9a   ; el semitono queda en el nibble bajo
	rrca			;7b9b
	rrca			;7b9c
	rrca			;7b9d
	rrca			;7b9e
arranca_la_nota:		; Recarga la cuenta atras y el volumen de la nota
	ld h,a			;7b9f
	ld a,(ix+001h)		;7ba0   ; el byte 1 es lo que dura
	ld (ix+000h),a		;7ba3   ; el byte 0 la va gastando
	add a,003h		;7ba6   ; y el byte 8 va tres por delante: el ataque
	ld (ix+008h),a		;7ba8
	jr pon_volumen		;7bab
calla_el_canal:		; Deja el canal libre al acabarse la melodia
	xor a			;7bad
	ld (ix+009h),a		;7bae   ; el byte 9, la octava, a cero
	ld d,001h		;7bb1
	call enciende_canal		;7bb3   ; se apaga
	di			;7bb6
	xor a			;7bb7
	ld (ix+002h),a		;7bb8   ; y el byte 2 a cero: canal libre
	ld h,a			;7bbb
	jr pon_volumen		;7bbc
gasta_la_nota:		; Baja la cuenta atras y va apagando el volumen
	dec (ix+000h)		;7bbe   ; el byte 0
	jp z,canal_lee_melodia		;7bc1   ; y al llegar a cero, a por la nota siguiente
	dec (ix+008h)		;7bc4   ; el byte 8 es el que dibuja la caida del volumen
	ld a,(ix+008h)		;7bc7
	cp (ix+000h)		;7bca
	jr nz,nota_gasta_ataque		;7bcd
	cp 003h		;7bcf
	jr c,nota_baja_volumen		;7bd1
	ret			;7bd3
nota_gasta_ataque:		; Un paso mas de la caida
	dec (ix+008h)		;7bd4
nota_baja_volumen:		; Y el volumen, hasta cero
	ld a,(ix+007h)		;7bd7   ; el byte 7 es el volumen de ahora
	dec a			;7bda
	ret m			;7bdb   ; y por debajo de cero, no baja mas
	ld (ix+007h),a		;7bdc
	ld h,a			;7bdf
pon_volumen:		; Escribe el volumen del canal en el registro que le toca
	ld a,c			;7be0
	rrca			;7be1
	add a,088h		;7be2   ; los registros 8, 9 y 10 del PSG
	ld e,h			;7be4
	jp 00093h		;7be5   ; BIOS WRTPSG - Writes data to PSG-register
manda_de_la_melodia:		; Los bytes de control: vibrato, octava y ancho
	and 0f0h		;7be8   ; el nibble alto manda
	cp 0d0h		;7bea   ; un 0xD es el paso del vibrato
	ld a,(hl)			;7bec
	jr nz,melodia_ancho		;7bed
	and 00fh		;7bef
	ld (ix+00ah),a		;7bf1   ; y va al byte 0x0A
	inc hl			;7bf4
	ld a,(hl)			;7bf5
melodia_ancho:		; Un 0xF es el ancho del vibrato
	cp 0f0h		;7bf6   ; un 0xF es el ancho
	jr c,melodia_octava		;7bf8
	and 00fh		;7bfa
	ld (ix+006h),a		;7bfc   ; que va al byte 6
	inc hl			;7bff
	ld a,(hl)			;7c00
melodia_octava:		; Un 0xE la octava
	cp 0e0h		;7c01   ; y un 0xE la octava
	jr c,melodia_pasos		;7c03
	and 00fh		;7c05
	ld (ix+005h),a		;7c07   ; al byte 5
	inc hl			;7c0a
	ld a,(hl)			;7c0b
melodia_pasos:		; Los pasos que se le suman
	and 00fh		;7c0c   ; el nibble bajo dice cuantos pasos
	ld b,a			;7c0e
	ld a,(ix+00ah)		;7c0f   ; y el paso se suma tantas veces
	jr z,nota_con_vibrato		;7c12
melodia_suma_paso:		; Uno mas
	add a,(ix+00ah)		;7c14   ; uno por vuelta
	djnz melodia_suma_paso		;7c17
nota_con_vibrato:		; La misma nota, pero con la duracion y el ataque puestos
	ld (ix+001h),a		;7c19   ; el byte 1, la duracion
	ld a,(hl)			;7c1c
	inc hl			;7c1d
	ld (ix+003h),l		;7c1e   ; se apunta por donde va la melodia
	ld (ix+004h),h		;7c21
	and 0f0h		;7c24   ; el nibble alto es el semitono
	rrca			;7c26
	rrca			;7c27
	rrca			;7c28
	rrca			;7c29
	ld b,a			;7c2a
	sub 00ch		;7c2b   ; doce semitonos tiene la escala
	ld (ix+007h),a		;7c2d   ; el byte 7 es el volumen
	jr z,pon_la_nota		;7c30
	ld a,(ix+006h)		;7c32   ; y si no llega, se coge el ancho del byte 6
	ld (ix+007h),a		;7c35
pon_la_nota:		; Busca el periodo del semitono y lo sube de octava
	call arranca_la_nota		;7c38
	ld a,b			;7c3b
	ld hl,07c5dh		;7c3c   ; la escala de doce vive en 0x7C5D
	call suma_a_hl		;7c3f
	ld l,(hl)			;7c42   ; el periodo de la nota
	ld h,000h		;7c43
	ld a,(ix+005h)		;7c45   ; el byte 5 es la octava
	or a			;7c48
	jr z,manda_periodo		;7c49
	ld b,a			;7c4b
nota_dobla_octava:		; Cada octava es doblar el periodo
	add hl,hl			;7c4c   ; y cada octava es doblar el periodo
	djnz nota_dobla_octava		;7c4d
manda_periodo:		; Escribe el periodo de dieciseis bits en los dos registros del canal
	ld a,c			;7c4f
	ld e,h			;7c50   ; primero el byte alto
	call 00093h		;7c51   ; BIOS WRTPSG - Writes data to PSG-register
	di			;7c54
	ld a,c			;7c55
	dec a			;7c56
	ld e,l			;7c57   ; y luego el bajo
	call 00093h		;7c58   ; BIOS WRTPSG - Writes data to PSG-register
	di			;7c5b
	ret			;7c5c

; ----------------------------------------------------------------------
; DATOS escala_cromatica: Los doce semitonos, del mas grave al mas agudo
;   0x7c5d..0x7c69  (12 bytes)
DATA_escala_cromatica:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 7c5d  jd_YTPKGC?<8

; ----------------------------------------------------------------------
; DATOS tabla_de_melodias: 25 punteros; 0x7A96 indexa desde 0x7C67, o sea que
;   la entrada 0 se pisa con las dos ultimas notas y no se usa
;   0x7c69..0x7c9b  (50 bytes)
DATA_tabla_de_melodias:
	defw 07cedh,07c9bh,07cdeh,07cfdh,07d25h,07d2eh,07d3dh,07d49h	; 7c69
	defw 07d50h,07e51h,07ec2h,07e72h,07d0dh,07e24h,07e35h,07e44h	; 7c79
	defw 07daeh,07dcdh,07de8h,07d5ch,07d7bh,07d98h,07ee8h,07ee8h	; 7c89
	defw 07ee8h	; 7c99

; ----------------------------------------------------------------------
; DATOS melodias: Las musicas y los efectos del partido
;   0x7c9b..0x7ee9  (590 bytes)
DATA_melodias:
	defb 021h,0c0h,0fdh,0b0h,0fch,0a0h,0fbh,090h,0fah,080h,0f9h,070h,0f8h,060h,0f7h,050h	; 7c9b  !..........p.`.P
	defb 0f6h,040h,0f5h,023h,090h,0f8h,090h,0f4h,090h,0f0h,090h,0edh,090h,0e4h,090h,0ddh	; 7cab  .@.#............
	defb 022h,080h,0d0h,080h,0c8h,080h,0c0h,080h,0b8h,070h,0c0h,070h,0c8h,070h,0cdh,022h	; 7cbb  "........p.p.p."
	defb 070h,0d0h,070h,0d4h,060h,0d8h,060h,0ddh,060h,0e0h,060h,0e4h,060h,0e8h,060h,0edh	; 7ccb  p.p.`.`.`.`.`.`.
	defb 060h,0f0h,0ffh,021h,0c0h,0d8h,0c0h,0e5h,021h,0c0h,0d6h,0b0h,0ddh,0a0h,09dh,0a0h	; 7cdb  `..!....!.......
	defb 0bbh,0ffh,021h,0c1h,0b0h,0a1h,0a8h,091h,0a0h,081h,09ch,081h,098h,081h,090h,081h	; 7ceb  ..!.............
	defb 080h,0ffh,021h,0c2h,080h,0d0h,096h,0a0h,09dh,080h,090h,000h,000h,0b0h,096h,090h	; 7cfb  ..!.............
	defb 09dh,0ffh,025h,0d0h,095h,023h,0d0h,098h,022h,0d0h,09ch,0d0h,09eh,0c0h,0a2h,0c0h	; 7d0b  ..%..#..".......
	defb 0a4h,022h,0a0h,0c8h,023h,0a0h,0cdh,090h,0d0h,0ffh,024h,0d0h,0e5h,023h,000h,000h	; 7d1b  ."..#.....$..#..
	defb 0d0h,0edh,0ffh,025h,0d0h,0e0h,022h,000h,000h,023h,0c0h,0e2h,023h,000h,000h,0d1h	; 7d2b  ...%.."..#..#...
	defb 030h,0ffh,023h,0d0h,0b4h,023h,0c0h,0bah,024h,000h,000h,0d0h,0f0h,0ffh,024h,0b0h	; 7d3b  0.#..#..$.....$.
	defb 0a0h,022h,0b0h,0adh,0ffh,021h,0a0h,0e0h,000h,000h,090h,0d0h,024h,000h,000h,0feh	; 7d4b  ."...!......$...
	defb 0ffh,0d6h,0fch,0e1h,002h,000h,001h,0e2h,0b1h,0e1h,001h,053h,001h,022h,020h,021h	; 7d5b  ...........S." !
	defb 011h,021h,073h,021h,042h,030h,041h,071h,0e0h,001h,0e1h,0a1h,091h,071h,05bh,0ffh	; 7d6b  .!s!B0Aq.....q[.
	defb 0d6h,0fbh,0e2h,092h,090h,091h,081h,091h,093h,091h,0a2h,0a0h,0a1h,091h,0a1h,0a3h	; 7d7b  ................
	defb 0a1h,0a2h,0a0h,0a1h,0a1h,0e1h,041h,021h,001h,0e2h,0a1h,09bh,0ffh,0d6h,0fbh,0e3h	; 7d8b  ......A!........
	defb 053h,003h,053h,003h,073h,023h,073h,023h,073h,003h,023h,043h,052h,050h,091h,0e2h	; 7d9b  S.S.s#s#s.#CRP..
	defb 001h,053h,0ffh,0d6h,0fch,0e1h,002h,020h,005h,0e2h,091h,0a1h,0e1h,001h,022h,020h	; 7dab  .S..... ......" 
	defb 005h,0e2h,091h,0a1h,0e1h,001h,022h,020h,002h,000h,052h,050h,002h,000h,023h,043h	; 7dbb  ......" ..RP..#C
	defb 053h,0ffh,0d6h,0fbh,0e2h,092h,0a0h,095h,051h,071h,091h,0a2h,0a0h,095h,051h,071h	; 7dcb  S.......Qq....Qq
	defb 091h,0a2h,0a0h,092h,090h,092h,090h,092h,090h,0b3h,0a3h,093h,0ffh,0d6h,0fbh,0e3h	; 7ddb  ................
	defb 051h,0e2h,001h,0e3h,051h,0e2h,001h,0e3h,051h,0e2h,001h,0e3h,001h,0e2h,001h,0e3h	; 7deb  Q...Q...Q.......
	defb 051h,0e2h,051h,0e3h,051h,0e2h,001h,0e3h,051h,0e2h,001h,0e3h,051h,0e2h,001h,0e3h	; 7dfb  Q.Q.Q...Q...Q...
	defb 051h,0e2h,051h,0e3h,051h,0e2h,001h,0e3h,051h,0e2h,001h,0e3h,051h,0e2h,051h,0c0h	; 7e0b  Q.Q.Q...Q...Q.Q.
	defb 070h,060h,050h,040h,020h,001h,0e3h,053h,0ffh,0d6h,0fch,0e3h,091h,090h,090h,0d8h	; 7e1b  p`P@ ..S........
	defb 090h,0e2h,020h,060h,070h,030h,0a0h,0d6h,09bh,0ffh,0d6h,0fbh,0e3h,061h,060h,060h	; 7e2b  .. `p0.......a``
	defb 063h,0d8h,0a0h,070h,0e2h,030h,0d6h,06bh,0ffh,0d6h,0fbh,0e3h,021h,020h,020h,023h	; 7e3b  c..p.0.k....!  #
	defb 0d8h,031h,070h,0d6h,02bh,0ffh,024h,0b0h,0a0h,022h,0b0h,0adh,029h,000h,000h,026h	; 7e4b  .1p.+.$.."..)..&
	defb 090h,021h,090h,020h,090h,021h,090h,020h,02fh,000h,000h,000h,000h,026h,080h,021h	; 7e5b  .!. .!. /....&.!
	defb 080h,020h,080h,021h,080h,020h,0ffh,021h,014h,006h,006h,007h,007h,007h,008h,008h	; 7e6b  . .!. .!........
	defb 008h,008h,008h,008h,009h,008h,009h,008h,009h,008h,009h,008h,009h,008h,009h,008h	; 7e7b  ................
	defb 00ah,008h,00ah,008h,00ah,008h,00ah,008h,00ah,008h,00ah,008h,00ah,008h,00ah,008h	; 7e8b  ................
	defb 00ah,008h,00ah,008h,00ah,009h,008h,009h,008h,009h,008h,009h,008h,009h,008h,009h	; 7e9b  ................
	defb 008h,008h,007h,008h,007h,008h,024h,007h,007h,007h,022h,007h,024h,006h,006h,006h	; 7eab  ......$...".$...
	defb 005h,005h,022h,005h,026h,004h,0ffh,02fh,018h,000h,000h,023h,081h,040h,071h,040h	; 7ebb  ..".&../...#.@q@
	defb 081h,000h,071h,000h,091h,040h,071h,040h,091h,000h,071h,000h,091h,040h,071h,040h	; 7ecb  ..q..@q@..q..@q@
	defb 091h,000h,071h,000h,091h,040h,071h,040h,081h,000h,071h,000h,0ffh,0ffh	; 7edb  ..q..@q@..q...

; ======================================================================
; CODIGO 0x7ee9..0x7fe9  (256 bytes)
; ======================================================================


mueve_al_humano:		; Entre puntos, lleva al jugador de vuelta a su puesto
	ld a,(0e060h)		;7ee9   ; 0xE060 solo deja pasar cuando la pista esta congelada
	or a			;7eec
	ret nz			;7eed
	ld ix,0e100h		;7eee   ; 0xE100, el primero
	ld hl,0e240h		;7ef2   ; 0xE240 lleva su estado
	push hl			;7ef5
	call alcanza_la_pelota		;7ef6   ; primero mira si ya alcanza la pelota
	pop hl			;7ef9
	ld a,(hl)			;7efa
	and 00fh		;7efb   ; los cuatro bits de abajo del estado
	jr z,anda_hacia_el_puesto		;7efd
	rrca			;7eff   ; el bit 0
	ld bc,0847ah		;7f00   ; 0x7A y 0x84 son el puesto de espera
	jr c,apunta_al_puesto		;7f03
	ld bc,(0e0dch)		;7f05   ; y si no, se va a donde cae la pelota
apunta_al_puesto:		; Guarda cuanto le falta para llegar a su sitio
	ld a,(0e060h)		;7f09   ; 0xE060 otra vez
	or a			;7f0c
	jr nz,puesto_calcula		;7f0d
	dec b			;7f0f   ; dos filas menos
	dec b			;7f10
	ld a,0f4h		;7f11   ; y doce columnas
	add a,c			;7f13
	ld c,a			;7f14
puesto_calcula:		; Lo que falta por cada eje
	ld d,(ix+002h)		;7f15   ; el byte 2 es su fila
	ld a,b			;7f18
	sub d			;7f19   ; lo que le falta por ese eje
	inc hl			;7f1a
	ld (hl),a			;7f1b
	ld e,(ix+003h)		;7f1c   ; y el byte 3 su columna
	ld a,c			;7f1f
	sub e			;7f20
	inc hl			;7f21
	ld (hl),a			;7f22
	dec hl			;7f23
	dec hl			;7f24
	ld a,(hl)			;7f25
	and 0f0h		;7f26   ; se le limpian los bits de abajo del estado
	ld (hl),a			;7f28
	ret			;7f29
anda_hacia_el_puesto:		; Convierte lo que falta en direcciones de mando
	push hl			;7f2a
	ld b,002h		;7f2b   ; el eje de las filas
	call acerca_un_paso		;7f2d
	ld c,b			;7f30
	ld b,008h		;7f31   ; y el de las columnas
	call acerca_un_paso		;7f33
	ld a,c			;7f36
	or b			;7f37   ; si no falta nada por ninguno, ya esta
	pop hl			;7f38
	bit 4,(hl)		;7f39   ; el bit 4 es el disparo
	jr z,puesto_guarda_pulsacion		;7f3b
	set 4,a		;7f3d
puesto_guarda_pulsacion:		; Al byte 7, como si fuera un mando
	ld (ix+007h),a		;7f3f   ; y todo junto al byte 7 de la ficha
	ret			;7f42
alcanza_la_pelota:		; Enciende el bit 4 si la pelota le queda a mano
	res 4,(hl)		;7f43   ; se apaga antes de mirar
	push hl			;7f45
	push ix		;7f46
	pop hl			;7f48
	call posicion_de_la_pelota		;7f49   ; saca donde esta la pelota
	ld a,006h		;7f4c   ; rectangulo 6, el del alcance a mano
	call hay_contacto		;7f4e
	pop hl			;7f51
	ret nc			;7f52   ; fuera: se queda apagado
	set 4,(hl)		;7f53   ; y dentro, encendido
	ret			;7f55
espera_a_todos:		; No deja seguir hasta que los cuatro estan en su sitio
	ld a,(0e060h)		;7f56   ; 0xE060: solo mientras la pista esta congelada
	or a			;7f59
	ret z			;7f5a
	call reparte_los_puestos		;7f5b   ; manda a cada uno a su puesto
	ld hl,0e250h		;7f5e   ; 0xE250 son los cuatro estados
	ld b,004h		;7f61   ; cuatro jugadores
espera_uno:		; Mira si este ya llego
	ld a,002h		;7f63   ; el 2 es "ya llegue"
	cp (hl)			;7f65
	ret nz			;7f66   ; y si alguno no lo esta, se espera
	inc hl			;7f67   ; tres bytes por jugador
	inc hl			;7f68
	inc hl			;7f69
	djnz espera_uno		;7f6a
	ld hl,0e250h		;7f6c   ; y cuando estan los cuatro, se limpian los dieciseis
	ld bc,00010h		;7f6f
	call borra_ram		;7f72
	xor a			;7f75
	ld (0e049h),a		;7f76   ; 0xE049 a cero: ya no hay que recolocar
	inc a			;7f79
	ld (0e061h),a		;7f7a   ; y 0xE061 avisa de que ha terminado
	ret			;7f7d
reparte_los_puestos:		; Da por colocados a los que no juegan
	call hay_dos_jugadores		;7f7e   ; con dos jugadores sobran dos
	jr nz,puestos_dobles		;7f81
	ld a,002h		;7f83
	ld (0e256h),a		;7f85   ; asi que 0xE256 y 0xE259 se ponen a 2 de salida
	ld (0e259h),a		;7f88
	jp puestos_reparte		;7f8b
puestos_dobles:		; Con dobles no sobra ninguno
	call hay_dobles		;7f8e   ; y con dobles, ninguno sobra
	jr z,puestos_reparte		;7f91
	ld a,002h		;7f93
	ld (0e253h),a		;7f95   ; en la demostracion sobran otros dos
	ld (0e259h),a		;7f98
puestos_reparte:		; Los cuatro, uno a uno
	ld ix,0e100h		;7f9b   ; 0xE100, el primero
	ld hl,0e250h		;7f9f   ; y 0xE250 su estado
	ld bc,(0e052h)		;7fa2   ; 0xE052 son los puestos que se copiaron
	call lleva_a_su_puesto		;7fa6
	ld ix,0e130h		;7fa9   ; 0xE130, el segundo
	ld l,053h		;7fad
	ld bc,(0e054h)		;7faf
	call lleva_a_su_puesto		;7fb3
	ld ix,0e160h		;7fb6   ; 0xE160, el tercero
	ld l,056h		;7fba
	ld bc,(0e056h)		;7fbc
	call lleva_a_su_puesto		;7fc0
	ld ix,0e190h		;7fc3   ; y 0xE190 el cuarto
	ld l,059h		;7fc7
	ld bc,(0e058h)		;7fc9
lleva_a_su_puesto:		; Un paso de un jugador hacia el sitio que le toca
	ld a,b			;7fcd   ; se le da la vuelta a la pareja de coordenadas
	ld b,c			;7fce
	ld c,a			;7fcf
	ld a,(hl)			;7fd0   ; el estado: 0 es recien empezado
	or a			;7fd1
	jr nz,puesto_ya_llego		;7fd2
	push hl			;7fd4
	call apunta_al_puesto		;7fd5   ; se le apunta el destino
	pop hl			;7fd8
	ld (hl),001h		;7fd9   ; y pasa al estado 1: andando
	ret			;7fdb
puesto_ya_llego:		; Al que ya esta no se le toca
	cp 002h		;7fdc   ; el 2 es que ya llego, y entonces no se le toca
	ret z			;7fde
	push hl			;7fdf
	call anda_hacia_el_puesto		;7fe0   ; un paso mas
	pop hl			;7fe3
	or a			;7fe4   ; y cuando no falta nada, estado 2
	ret nz			;7fe5
	ld (hl),002h		;7fe6
	ret			;7fe8

; ----------------------------------------------------------------------
; DATOS relleno_final: Veintitres bytes a 0xFF: lo que sobra del cartucho
;   0x7fe9..0x8000  (23 bytes)
DATA_relleno_final:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fe9  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7ff9
