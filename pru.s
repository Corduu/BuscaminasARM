.data

/* Códigos de color ANSI para terminal */
color_reset:    .asciz "\033[0m"
color_verde:    .asciz "\033[32m"
color_rojo:     .asciz "\033[31m"
color_amarillo: .asciz "\033[33m"
color_azul:     .asciz "\033[34m"
color_cyan:     .asciz "\033[36m"
color_magenta:  .asciz "\033[35m"
msg_separador:  .asciz "\n================================================\n"


/* UTIL PARA FLOOD_FILL*/
es_primera_jugada: .word 1


/* Tablero 8x8 según requisitos */
tablero: .ascii "........\n........\n........\n........\n........\n........\n........\n........\n"
long_tablero = . - tablero

/* Matriz de minas 8x8 (1=mina, 0=libre) */
minas: .space 64

/* Matriz de casillas descubiertas */
descubiertas: .space 64

/* Variables del juego */
tamano_tablero: .word 8
total_minas: .word 0
jugadas_realizadas: .word 0
objetivo_descubrir: .word 10
nivel_dificultad: .word 1

/* MODO TEST: 0 = normal, 1 = test (ganar en 1 jugada) */
modo_test: .word 0      // Cambia a 0 para modo normal
semilla: .word 0

/* Variables de tiempo */
TIEMPO_INICIO: .space 8
TIEMPO_FIN: .space 8
nombre_usuario: .space 50

/* Mensajes */
msg_inicio: .asciz "\n  ____  _    _  _____  _____          __  __ _____ _   _           _____ \n |  _ \\| |  | |/ ____|/ ____|   /\\   |  \\/  |_   _| \\ | |   /\\    / ____|\n | |_) | |  | | (___ | |       /  \\  | \\  / | | | |  \\| |  /  \\  | (___  \n |  _ <| |  | |\\___ \\| |      / /\\ \\ | |\\/| | | | | . ` | / /\\ \\  \\___ \\ \n | |_) | |__| |____) | |____ / ____ \\| |  | |_| |_| |\\  |/ ____ \\ ____) |\n |____/ \\____/|_____/ \\_____/_/    \\_\\_|  |_|_____|_| \\_/_/    \\_\\_____/\n\nDescubre las casillas sin minas. Cuidado con las explosiones!\n"
msg_nombre: .asciz "Ingrese su nombre: " 
msg_seleccionar_nivel: .asciz "Seleccione nivel de dificultad:\n1. Inicial (%20 minas)\n2. Intermedio (30% minas)\n3. Difícil (50% minas)\n4. Personalizado\nOpción: "
msg_ingrese_minas: .asciz "Ingrese cantidad de minas (1-63): "
msg_fila: .asciz "Ingrese fila (0-7): "
msg_columna: .asciz "Ingrese columna (0-7): "
msg_mina: .asciz "\n╔══════════════════════════╗\n║   💥💥💥 ¡BOOM! 💥💥💥   ║\n║        Has perdido.      ║\n╚══════════════════════════╝\nLas minas estaban en:\n"
msg_safe: .asciz " 🌟 ¡Seguro! 🌟\n\n"
msg_gana: .asciz "\n╔═════════════════════════════╗\n║ 🎉 ¡FELICITACIONES! GANASTE ║\n╚═════════════════════════════╝\n"
msg_minas_restantes: .asciz " 🧮 Casillas por descubrir: "
msg_nueva_linea: .asciz "\n"
msg_dos_puntos: .asciz ": "
msg_numero_invalido: .asciz "⚠ Número inválido. Intente nuevamente.\n"
msg_coordenadas_invalidas: .asciz " ❗❗❗ Coordenadas fuera de rango. Intente nuevamente.\n"
msg_casilla_repetida: .asciz "⚠ Esta casilla ya fue descubierta. Intente otra.\n"
msg_generando: .asciz "\n ¡El juego ya comenzó! 🎮\n─────────────✧─────────────\n  ⌛ Generando minas...\n─────────────✧─────────────\n"
msg_tiempo_juego: .asciz " 💡 Tiempo de juego para "
msg_tiempo_segundos: .asciz " seg\n"
msg_gracias: .asciz "\n+----------------------------------------------+\n|                                              |\n|        ¡Gracias por jugar! 🙌                |\n|      Desarrollado por Grupo 02 💻            |\n|   https://github.com/Corduu/BuscaminasARM    |\n|                                              |\n+----------------------------------------------+\n\n"

/* Archivo de ranking */
ranking_filename: .asciz "ranking.txt"
msg_ranking_header: .asciz "\n╔══════════════════════════════════╗\n║       🏆 RANKING GANADORES       ║\n╚══════════════════════════════════╝\n"
ranking_line: .space 2048      // Buffer temporal para armar la línea a guardar
/* Buffer para ranking */
ranking_buffer: .space 2048    // Para leer hasta 3 líneas del archivo

/* Buffer para entrada */
buffer_input: .space 50

// Etiquetas para el ranking
.data
nombre_label:   .asciz "Nombre: "
tiempo_label:   .asciz " | Tiempo: "
segundos_label: .asciz " seg | Nivel: "

.text

/*----------------------------------------------------------*/
/* Obtener tiempo usando syscall gettimeofday */
obtener_tiempo:
    push {r1, r7, lr}
    mov r1, #0
    mov r7, #78
    swi 0
    pop {r1, r7, lr}
    bx lr

/*----------------------------------------------------------*/
/* Calcular diferencia de tiempo en segundos */
calcular_tiempo_transcurrido:
    push {r1-r4, lr}
    ldr r1, =TIEMPO_INICIO
    ldr r2, [r1]
    ldr r3, =TIEMPO_FIN
    ldr r4, [r3]
    sub r0, r4, r2
    pop {r1-r4, lr}
    bx lr

/*----------------------------------------------------------*/
/* Leer nombre de usuario */
leer_nombre_usuario:
    push {r1, r2, r7, lr}
    ldr r1, =msg_nombre
    bl imprimir_string
    mov r7, #3
    mov r0, #0
    ldr r1, =nombre_usuario
    mov r2, #49
    swi 0
    ldr r1, =nombre_usuario
    mov r2, #0
buscar_newline:
    ldrb r3, [r1, r2]
    cmp r3, #10
    beq eliminar_newline
    cmp r3, #0
    beq fin_leer_nombre
    add r2, #1
    cmp r2, #49
    blt buscar_newline
    b fin_leer_nombre
eliminar_newline:
    mov r3, #0
    strb r3, [r1, r2]
fin_leer_nombre:
    pop {r1, r2, r7, lr}
    bx lr

/*----------------------------------------------------------*/
/* Imprimir nombre de usuario */
imprimir_nombre_usuario:
    push {r0-r2, r7, lr}
    ldr r1, =nombre_usuario
    mov r2, #0
contar_chars:
    ldrb r0, [r1, r2]
    cmp r0, #0
    beq fin_contar
    add r2, #1
    cmp r2, #49
    blt contar_chars
fin_contar:
    mov r7, #4
    mov r0, #1
    ldr r1, =nombre_usuario
    swi 0
    pop {r0-r2, r7, lr}
    bx lr

/*----------------------------------------------------------*/
/* Mostrar tiempo final de juego con color en r2 */
mostrar_tiempo_final_color:
    push {r0-r3, lr}
    mov r3, r2         // r2=color (puntero)
    ldr r1, [sp, #16]  // backup de lr (por si acaso)
    ldr r1, =color_reset
    // Imprime color recibido
    mov r1, r3
    bl imprimir_string
    ldr r1, =msg_tiempo_juego
    bl imprimir_string
    bl imprimir_nombre_usuario
    ldr r1, =msg_dos_puntos
    bl imprimir_string
    bl calcular_tiempo_transcurrido
    bl imprimir_numero
    ldr r1, =msg_tiempo_segundos
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    pop {r0-r3, lr}
    bx lr

/*----------------------------------------------------------*/
/* Genera y retorna un numero aleatorio usando syscall getrandom */
generar_aleatorio:
    push {r1-r2, r7, lr}
    mov r7, #384
    ldr r0, =semilla
    mov r1, #4
    mov r2, #0
    swi 0
    ldr r0, =semilla
    ldr r0, [r0]
    pop {r1-r2, r7, lr}
    bx lr

/*----------------------------------------------------------*/
/* Limpiar matriz de minas */
limpiar_minas:
    push {r0-r2, lr}
    ldr r0, =minas
    mov r1, #0
    mov r2, #64
limpiar_loop:
    strb r1, [r0], #1
    subs r2, r2, #1
    bne limpiar_loop
    pop {r0-r2, lr}
    bx lr

/*----------------------------------------------------------*/
/* Limpiar matriz de casillas descubiertas */
limpiar_descubiertas:
    push {r0-r2, lr}
    ldr r0, =descubiertas
    mov r1, #0
    mov r2, #64
limpiar_desc_loop:
    strb r1, [r0], #1
    subs r2, r2, #1
    bne limpiar_desc_loop
    pop {r0-r2, lr}
    bx lr

/*----------------------------------------------------------*/
/* Generar minas aleatorias según nivel */
generar_minas_aleatorias:
    push {r0-r8, lr}
    ldr r1, =msg_generando
    bl imprimir_string
    bl limpiar_minas
    ldr r0, =nivel_dificultad
    ldr r0, [r0]
    mov r7, #64         // total de casillas

    cmp r0, #4
    beq usar_personalizado

    cmp r0, #1
    moveq r6, r7
    moveq r5, #20
    beq calcular_porcentaje
    cmp r0, #2
    moveq r6, r7
    moveq r5, #30
    beq calcular_porcentaje
    cmp r0, #3
    moveq r6, r7
    moveq r5, #50
    beq calcular_porcentaje

    b set_total_minas

usar_personalizado:
    ldr r6, =total_minas
    ldr r6, [r6]
    b set_total_minas

calcular_porcentaje:
    // r6 = total casillas, r5 = porcentaje
    mul r8, r6, r5     // r8 = total_casillas * porcentaje
    mov r6, r8         // r6 = resultado
    mov r5, #100
    udiv r6, r6, r5    // r6 = (casillas * porcentaje) / 100

set_total_minas:
    ldr r7, =total_minas
    str r6, [r7]
    mov r0, #64
    sub r0, r0, r6        // objetivo_descubrir = 64 - minas
    ldr r7, =objetivo_descubrir
    str r0, [r7]
    // MODO TEST: fuerza objetivo_descubrir a 1 si modo_test=1
    ldr r0, =modo_test
    ldr r0, [r0]
    cmp r0, #1
    bne skip_modo_test
    mov r0, #1
    ldr r7, =objetivo_descubrir
    str r0, [r7]
skip_modo_test:
    mov r8, #0
colocar_minas_loop:
    cmp r8, r6
    bge fin_generar_minas
    bl generar_aleatorio
    and r0, r0, #7
    mov r4, r0
    bl generar_aleatorio
    and r0, r0, #7
    mov r5, r0
    mov r0, r4
    mov r1, r5
    bl verificar_mina_simple
    cmp r0, #1
    beq colocar_minas_loop
    mov r2, #8
    mul r3, r4, r2
    add r3, r3, r5
    ldr r7, =minas
    mov r0, #1
    strb r0, [r7, r3]
    add r8, r8, #1
    b colocar_minas_loop
fin_generar_minas:
    pop {r0-r8, lr}
    bx lr
    


/*----------------------------------------------------------*/
/* Rutina para imprimir string hasta \0 */
imprimir_string:
    push {r0, r1, r2, r7, lr}
    mov r2, #0
contar_largo:
    ldrb r3, [r1, r2]
    cmp r3, #0
    beq imprimir
    add r2, #1
    b contar_largo
imprimir:
    mov r7, #4
    mov r0, #1
    swi 0
    pop {r0, r1, r2, r7, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para imprimir un carácter */
imprimir_char:
    push {r1, r2, lr}
    sub sp, #4
    strb r0, [sp]
    mov r1, sp
    mov r2, #1
    mov r7, #4
    mov r0, #1
    swi 0
    add sp, #4
    pop {r1, r2, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para imprimir un número (hasta 3 dígitos) */
imprimir_numero:
    push {r1, r2, r3, r4, r5, r6, lr}
    mov r1, #100
    cmp r0, r1
    blt decenas_num
    // Centenas
    mov r2, r0
    udiv r3, r2, r1      // r3 = centenas
    add r5, r3, #'0'
    mov r0, r5
    bl imprimir_char
    mov r4, #100
    mul r6, r3, r4        // r6 = r3 * 100
    sub r0, r2, r6        // r0 = original - centenas*100

decenas_num:
    mov r1, #10
    cmp r0, r1
    blt unidades_num
    mov r2, r0
    udiv r3, r2, r1      // r3 = decenas
    add r5, r3, #'0'
    mov r0, r5
    bl imprimir_char
    mov r4, #10
    mul r6, r3, r4        // r6 = r3 * 10
    sub r0, r2, r6        // r0 = original - decenas*10

unidades_num:
    add r0, r0, #'0'
    bl imprimir_char
    pop {r1, r2, r3, r4, r5, r6, lr}
    bx lr





/*----------------------------------------------------------*/
/* Rutina para mostrar el tablero */
// FUNCIONA
mostrar_tablero:
    push {r0, r1, r2, r3, r4, lr}
    mov r0, #' '
    bl imprimir_char
    mov r0, #' '
    bl imprimir_char
    mov r3, #0
encabezado_loop:
    mov r0, r3
    bl imprimir_numero
    mov r0, #' '
    bl imprimir_char
    add r3, #1
    cmp r3, #8
    blt encabezado_loop
    mov r0, #10
    bl imprimir_char
    mov r3, #0
fila_loop:
    mov r0, r3
    bl imprimir_numero
    mov r0, #' '
    bl imprimir_char
    mov r4, #0
columna_loop:
    mov r0, #9
    mul r1, r3, r0
    add r1, r4
    ldr r2, =tablero
    ldrb r0, [r2, r1]
    bl imprimir_char
    mov r0, #' '
    bl imprimir_char
    add r4, #1
    cmp r4, #8
    blt columna_loop
    mov r0, #10
    bl imprimir_char
    add r3, #1
    cmp r3, #8
    blt fila_loop
    pop {r0, r1, r2, r3, r4, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para leer un número */
leer_numero:
    push {r1, r2, r3, r4, lr}
    mov r7, #3
    mov r0, #0
    ldr r1, =buffer_input
    mov r2, #10
    swi 0

    ldr r1, =buffer_input
    ldrb r2, [r1]        // primer caracter
    cmp r2, #'0'
    blt numero_invalido
    cmp r2, #'9'
    bgt numero_invalido
    sub r2, #'0'         // r2 = primer dígito numérico

    ldrb r3, [r1, #1]    // segundo caracter
    cmp r3, #10          // salto de línea?
    beq un_digito_leer
    cmp r3, #'0'
    blt un_digito_leer
    cmp r3, #'9'
    bgt un_digito_leer
    sub r3, #'0'         // r3 = segundo dígito numérico

    // dos dígitos
    mov r4, r2           // r4 = primer dígito
    mov r0, r4
    mov r1, #10
    mul r0, r4, r1       // r0 = primer_digito * 10
    add r0, r0, r3       // r0 = r0 + segundo_digito
    b fin_leer_numero

un_digito_leer:
    mov r0, r2
    b fin_leer_numero

numero_invalido:
    mov r0, #-1

fin_leer_numero:
    pop {r1, r2, r3, r4, lr}
    bx lr


/*----------------------------------------------------------*/
/* Rutina para verificar si hay mina en posición */
verificar_mina_simple:
    push {r2, r3, r4, lr}
    mov r2, #8
    mul r3, r0, r2
    add r3, r3, r1
    ldr r4, =minas
    ldrb r0, [r4, r3]
    pop {r2, r3, r4, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para verificar si casilla ya fue descubierta */
verificar_casilla_repetida:
    push {r2, r3, r4, lr}
    mov r2, #8
    mul r3, r0, r2
    add r3, r3, r1
    ldr r4, =descubiertas
    ldrb r0, [r4, r3]
    pop {r2, r3, r4, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para marcar casilla como descubierta */
marcar_casilla_descubierta:
    push {r2, r3, r4, r5, lr}
    mov r2, #8
    mul r3, r0, r2
    add r3, r3, r1
    ldr r4, =descubiertas
    ldrb r5, [r4, r3]
    cmp r5, #1
    beq ya_descubierta
    mov r5, #1
    strb r5, [r4, r3]
    // Aumentar jugadas_realizadas SOLO si no estaba descubierta
    ldr r4, =jugadas_realizadas
    ldr r5, [r4]
    add r5, r5, #1
    str r5, [r4]
ya_descubierta:
    pop {r2, r3, r4, r5, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para marcar en tablero visual */
marcar_tablero:
    push {r3, r4, r5, lr}
    mov r3, #9
    mul r4, r0, r3
    add r4, r4, r1
    ldr r5, =tablero
    strb r2, [r5, r4]
    pop {r3, r4, r5, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para calcular minas cercanas (solo vertical/horizontal) */
calcular_minas_cercanas:
    push {r4, r5, r6, r7, r8, lr}
    mov r6, r0
    mov r7, r1
    mov r8, #0
    cmp r6, #0
    beq skip_arriba
    sub r0, r6, #1
    mov r1, r7
    bl verificar_mina_simple
    add r8, r0
skip_arriba:
    cmp r6, #7
    beq skip_abajo
    add r0, r6, #1
    mov r1, r7
    bl verificar_mina_simple
    add r8, r0
skip_abajo:
    cmp r7, #0
    beq skip_izquierda
    mov r0, r6
    sub r1, r7, #1
    bl verificar_mina_simple
    add r8, r0
skip_izquierda:
    cmp r7, #7
    beq skip_derecha
    mov r0, r6
    add r1, r7, #1
    bl verificar_mina_simple
    add r8, r0
skip_derecha:
    mov r0, r8
    pop {r4, r5, r6, r7, r8, lr}
    bx lr

/*----------------------------------------------------------*/
/* Marcar todas las minas en el tablero con asteriscos */
mostrar_todas_las_minas:
    push {r0, r1, r2, r3, r4, lr}
    mov r3, #0
buscar_minas_fila:
    mov r4, #0
buscar_minas_columna:
    mov r0, r3
    mov r1, r4
    bl verificar_mina_simple
    cmp r0, #1
    bne siguiente_posicion
    mov r0, r3
    mov r1, r4
    mov r2, #'*'
    bl marcar_tablero
siguiente_posicion:
    add r4, #1
    cmp r4, #8
    blt buscar_minas_columna
    add r3, #1
    cmp r3, #8
    blt buscar_minas_fila
    pop {r0, r1, r2, r3, r4, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para mostrar cantidad de casillas restantes */
mostrar_progreso:
    push {r0, r1, r2, lr}
    ldr r1, =color_cyan
    bl imprimir_string
    ldr r1, =msg_minas_restantes
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    ldr r0, =objetivo_descubrir
    ldr r0, [r0]
    ldr r1, =jugadas_realizadas
    ldr r1, [r1]
    sub r0, r1
    bl imprimir_numero
    mov r0, #10
    bl imprimir_char
    pop {r0, r1, r2, lr}
    bx lr

/*----------------------------------------------------------*/
/* Rutina para guardar en el ranking */
guardar_en_ranking:
    push {r0-r7, lr}
    // Abrir archivo en modo append (O_WRONLY|O_CREAT|O_APPEND = 0x441)
    ldr r0, =ranking_filename
    mov r1, #0x441
    mov r2, #0666
    mov r7, #5      // syscall open
    swi 0
    mov r6, r0      // fd

    // Armar línea: "Nombre: " + nombre + " | Tiempo: " + tiempo + " segundos | Nivel: " + nivel + "\n"
    ldr r1, =ranking_line
    mov r3, #0

    // "Nombre: "
    ldr r2, =nombre_label
    bl copiar_texto

    // nombre_usuario
    ldr r2, =nombre_usuario
    bl copiar_texto

    // " | Tiempo: "
    ldr r2, =tiempo_label
    bl copiar_texto

    // tiempo (en segundos)
    bl calcular_tiempo_transcurrido
    mov r4, r0
    mov r0, r4
    ldr r1, =ranking_line
    add r1, r1, r3
    bl int_a_ascii
    add r3, r3, r0

    // " segundos | Nivel: "
    ldr r2, =segundos_label
    bl copiar_texto

    // nivel
    ldr r0, =nivel_dificultad
    ldr r0, [r0]
    ldr r1, =ranking_line
    add r1, r1, r3
    bl int_a_ascii
    add r3, r3, r0

    // salto de línea y fin de string
    mov r4, #10
    ldr r1, =ranking_line
    add r1, r1, r3
    strb r4, [r1]
    add r3, #1
    mov r4, #0
    ldr r1, =ranking_line
    add r1, r1, r3
    strb r4, [r1]

    // Escribir en archivo
    mov r0, r6
    ldr r1, =ranking_line
    mov r2, r3
    mov r7, #4      // syscall write
    swi 0

    // Cerrar archivo
    mov r0, r6
    mov r7, #6      // syscall close
    swi 0

    pop {r0-r7, lr}
    bx lr



/*----------------------------------------------------------*/
/* Mostrar los últimos 3 ganadores del ranking */
mostrar_ranking:
    push {r0-r7, lr}
    // Abrir archivo en modo solo lectura
    ldr r0, =ranking_filename
    mov r1, #0      // O_RDONLY
    mov r2, #0
    mov r7, #5      // syscall open
    swi 0
    mov r6, r0      // fd

    // Leer todo el archivo en un buffer temporal
    ldr r1, =ranking_buffer
    mov r2, #2048    // 4 líneas de 64 bytes
    mov r7, #3      // syscall read
    swi 0
    mov r5, r0      // cantidad leída

    // Mostrar header
    ldr r1, =color_magenta
    bl imprimir_string
    ldr r1, =msg_ranking_header
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string

    // Si no hay datos, salir
    cmp r5, #0
    beq fin_mostrar_ranking

    // Buscar inicio de las últimas 4 líneas
    ldr r1, =ranking_buffer
    mov r2, r5
    mov r3, #0      // contador de saltos de línea

buscar_ultimas:
    cmp r2, #0
    beq mostrar_encontradas
    sub r2, #1
    ldrb r4, [r1, r2]
    cmp r4, #10     // '\n'
    bne buscar_ultimas
    add r3, #1
    cmp r3, #4      // buscamos 4 saltos de línea (para mostrar hasta 4 líneas)
    blt buscar_ultimas
mostrar_encontradas:
    // Si hay menos de 4 líneas, ajusta el inicio
    cmp r2, #0
    bgt tiene_4_lineas
    mov r2, #0
tiene_4_lineas:
    // Mostrar desde r2 hasta r5
    ldr r1, =ranking_buffer
    add r1, r1, r2
    mov r4, r5
mostrar_lineas:
    cmp r2, r4
    bge fin_mostrar_ranking
    ldrb r0, [r1], #1
    bl imprimir_char
    add r2, #1
    b mostrar_lineas

fin_mostrar_ranking:
    // Cerrar archivo
    mov r0, r6
    mov r7, #6      // syscall close
    swi 0
    pop {r0-r7, lr}
    bx lr


/*---------------------------------------------------------------*/
/* Copia texto de r2 a ranking_line en r1, usando r3 como offset */
copiar_texto:
    push {r4, r5}
    mov r4, r2
copiar_texto_loop:
    ldrb r5, [r4], #1
    cmp r5, #0
    beq copiar_texto_fin
    ldr r1, =ranking_line
    add r1, r1, r3
    strb r5, [r1]
    add r3, #1
    b copiar_texto_loop
copiar_texto_fin:
    pop {r4, r5}
    bx lr

/*-------------------------------------------------------------------------*/
/* Convierte entero en r0 a ascii en r1, retorna cantidad de dígitos en r0 */
int_a_ascii:
    push {r2, r3, r4, r5, r6, r7, lr}
    mov r2, r0      // valor original
    mov r3, #0      // contador de dígitos
    mov r4, r1      // puntero de escritura

    mov r5, #100
    cmp r2, r5
    blt decenas
    mov r6, r2
    udiv r0, r6, r5
    add r0, #'0'
    strb r0, [r4], #1
    sub r7, r0, #'0'    // r7 = valor numérico del dígito
    mov r1, r7
    mul r1, r5          // r1 = centenas * 100
    sub r2, r6, r1
    add r3, #1

decenas:
    mov r5, #10
    cmp r2, r5
    blt unidades
    mov r6, r2
    udiv r0, r6, r5
    add r0, #'0'
    strb r0, [r4], #1
    sub r7, r0, #'0'    // r7 = valor numérico del dígito
    mov r1, r7
    mul r1, r5          // r1 = decenas * 10
    sub r2, r6, r1
    add r3, #1

unidades:
    add r0, r2, #'0'
    strb r0, [r4], #1
    add r3, #1
    mov r0, r3      // cantidad de dígitos escritos
    pop {r2, r3, r4, r5, r6, r7, lr}
    bx lr




/*----------------------------------------------------------*/
/* Descubre en cascada todas las casillas vacías conectadas (solo + - direcciones) */
flood_fill:
    push {r4-r12, lr}
    mov r10, r0      // fila
    mov r11, r1      // columna

    // Limites del tablero
    cmp r10, #0
    blt flood_fin
    cmp r10, #8
    bge flood_fin
    cmp r11, #0
    blt flood_fin
    cmp r11, #8
    bge flood_fin

    // Si ya está descubierta, salir
    mov r0, r10
    mov r1, r11
    bl verificar_casilla_repetida
    cmp r0, #1
    beq flood_fin

    // Marcar como descubierta
    mov r0, r10
    mov r1, r11
    bl marcar_casilla_descubierta

    // Calcular minas cercanas (solo vertical/horizontal)
    mov r0, r10
    mov r1, r11
    bl calcular_minas_cercanas
    mov r12, r0

    // Si hay minas cercanas, mostrar el número y salir
    cmp r12, #0
    bne flood_numero

    // Si no hay minas cercanas, marcar 'O'
    mov r2, #'O'
    mov r0, r10
    mov r1, r11
    bl marcar_tablero

    // Solo expandir a las 4 direcciones (no diagonales)
    // Arriba
    mov r0, r10
    sub r0, #1
    mov r1, r11
    bl flood_fill
    // Abajo
    mov r0, r10
    add r0, #1
    mov r1, r11
    bl flood_fill
    // Izquierda
    mov r0, r10
    mov r1, r11
    sub r1, #1
    bl flood_fill
    // Derecha
    mov r0, r10
    mov r1, r11
    add r1, #1
    bl flood_fill

    b flood_fin

flood_numero:
    add r2, r12, #'0'
    mov r0, r10
    mov r1, r11
    bl marcar_tablero

flood_fin:
    pop {r4-r12, lr}
    bx lr

    



/*----------------------------------------------------------*/
/* Rutina principal del juego */
.global main
main:
    bl generar_aleatorio
    ldr r1, =color_azul
    bl imprimir_string
    ldr r1, =msg_inicio
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    bl leer_nombre_usuario
    ldr r0, =TIEMPO_INICIO
    bl obtener_tiempo
    ldr r1, =color_magenta
    bl imprimir_string
    ldr r1, =msg_seleccionar_nivel
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
seleccionar_nivel:
    bl leer_numero
    cmp r0, #1
    blt nivel_invalido
    cmp r0, #4
    bgt nivel_invalido
    ldr r1, =nivel_dificultad
    str r0, [r1]
    cmp r0, #4
    bne iniciar_juego

    // Si es personalizado, pedir cantidad de minas
pedir_minas_personalizado:
    ldr r1, =color_amarillo
    bl imprimir_string
    ldr r1, =msg_dos_puntos
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    ldr r1, =msg_numero_invalido
    // Mensaje: "Ingrese cantidad de minas (1-63): "
    ldr r1, =msg_nueva_linea
    bl imprimir_string
    ldr r1, =color_cyan
    bl imprimir_string
    ldr r1, =msg_ingrese_minas
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    bl leer_numero
    cmp r0, #1
    blt pedir_minas_personalizado
    cmp r0, #63
    bgt pedir_minas_personalizado
    ldr r1, =total_minas
    str r0, [r1]
    mov r1, #64
    sub r1, r1, r0
    ldr r2, =objetivo_descubrir
    str r1, [r2]
    b iniciar_juego

nivel_invalido:
    ldr r1, =color_amarillo
    bl imprimir_string
    ldr r1, =msg_numero_invalido
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    b seleccionar_nivel
iniciar_juego:
    bl limpiar_descubiertas
    bl generar_minas_aleatorias
    ldr r0, =es_primera_jugada
    mov r1, #1           // <-- Inicializa en 1 (primera jugada)
    str r1, [r0]
    bl mostrar_tablero
    bl mostrar_progreso

juego_loop:
    ldr r0, =jugadas_realizadas
    ldr r0, [r0]
    ldr r1, =objetivo_descubrir
    ldr r1, [r1]
    cmp r0, r1
    bge ganar
    ldr r1, =msg_fila
    bl imprimir_string
    bl leer_numero
    cmp r0, #-1
    beq coordenadas_invalidas
    cmp r0, #7
    bgt coordenadas_invalidas
    mov r8, r0
    ldr r1, =msg_columna
    bl imprimir_string
    bl leer_numero
    cmp r0, #-1
    beq coordenadas_invalidas
    cmp r0, #7
    bgt coordenadas_invalidas
    mov r9, r0
    mov r0, r8
    mov r1, r9
    bl verificar_casilla_repetida
    cmp r0, #1
    beq casilla_repetida
    mov r0, r8
    mov r1, r9
    bl verificar_mina_simple
    cmp r0, #1
    beq perder

    // --- BLOQUE DE CONTROL DE FLOOD_FILL SEGÚN REGLA PERSONALIZADA ---
    // Si es la primera jugada, calcular minas cercanas y decidir flood_fill
    // Si flood_fill está habilitado, marcar casilla y continuar
    // Si flood_fill está deshabilitado, marcar casilla y continuar
    mov r0, r8
    mov r1, r9
    bl calcular_minas_cercanas
    mov r7, r0                // r7 = minas cercanas
    ldr r0, =es_primera_jugada
    ldr r0, [r0]
    cmp r0, #1
    bne no_flood
    // Si flood_fill está habilitado
    cmp r7, #0
    bne marcar_numero_y_continuar
    // Si minas cercanas == 0, flood_fill y deshabilitar para el resto del juego
    mov r0, r8
    mov r1, r9
    bl flood_fill
    ldr r0, =es_primera_jugada
    mov r1, #0
    str r1, [r0]
    b continuar_juego

marcar_numero_y_continuar:
    // Si minas cercanas != 0, marcar la casilla y dejar flood_fill habilitado
    mov r2, r7
    add r2, #'0'
    mov r0, r8
    mov r1, r9
    bl marcar_casilla_descubierta
    bl marcar_tablero
    // flood_fill sigue habilitado (no se cambia es_primera_jugada)
    b continuar_juego

no_flood:
    // flood_fill ya está deshabilitado, comportamiento normal
    mov r2, r7
    add r2, #'0'
    mov r0, r8
    mov r1, r9
    bl marcar_casilla_descubierta
    bl marcar_tablero
    b continuar_juego

continuar_juego:
    ldr r1, =msg_safe
    bl imprimir_string
    bl mostrar_tablero
    bl mostrar_progreso
    b juego_loop
    
coordenadas_invalidas:
    ldr r1, =color_amarillo
    bl imprimir_string
    ldr r1, =msg_coordenadas_invalidas
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    b juego_loop
casilla_repetida:
    ldr r1, =color_amarillo
    bl imprimir_string
    ldr r1, =msg_casilla_repetida
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    b juego_loop
// ...existing code...
perder:
    ldr r0, =TIEMPO_FIN
    bl obtener_tiempo
    ldr r1, =color_rojo
    bl imprimir_string
    ldr r1, =msg_mina
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    bl mostrar_todas_las_minas
    bl mostrar_tablero
    ldr r2, =color_rojo
    bl mostrar_tiempo_final_color
    b fin

ganar:
    ldr r0, =TIEMPO_FIN
    bl obtener_tiempo
    ldr r1, =color_verde
    bl imprimir_string
    ldr r1, =msg_gana
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    ldr r2, =color_verde
    bl mostrar_tiempo_final_color
    bl guardar_en_ranking
    ldr r1, =color_magenta
    bl imprimir_string
    bl mostrar_ranking
    ldr r1, =color_magenta
    bl imprimir_string
    ldr r1, =msg_separador
    bl imprimir_string
    ldr r1, =color_reset
    bl imprimir_string
    b fin

fin:
    ldr r1, =msg_gracias      
    bl imprimir_string        
    mov r7, #1
    swi 0
