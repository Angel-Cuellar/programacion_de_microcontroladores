;Archivo:	contador1.S
;Dispositivo:	PIC16f887
;Autor:	Angel Arnoldo Cuellar 
;Compilador:	pic-as (v2.30), MPLABX V5.40
;
;Programa:	proyecto semaforos de tres vias. 
;Hardware:	push bottons en puerto_b, leds, displays, etc. 
;
;Creado:  20 marzo, 2021
;Última modificación: 07 abril, 2021

;//////////////////////////////////////////////////////////////////////////////
;Configuration word 1
; PIC16F887 Configuration Bit Settings
; Assembly source line config statements
;//////////////////////////////////////////////////////////////////////////////
    
PROCESSOR 16F887
#include <xc.inc>

; CONFIGURATION WORD1 
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIGATION WORD2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
;//////////////////////////////////////////////////////////////////////////////
;  Variables
;//////////////////////////////////////////////////////////////////////////////
 
 PSECT udata_bank0  ;common memory
    var:	   DS 1 ;1 byte
    banderas:      DS 1 ;1 byte
    nibble:        DS 2 ;2 byte
    display:       DS 2 ;2 byte 
    turno:         DS 2 ;1 byte
    modo:          DS 1 ;1 byte 
    t_conf:        DS 1 ;1 byte
    tiempo1:       DS 1 ;1 byte
    tiempo2:       DS 1 ;1 byte
    tiempo3:       DS 1 ;1 byte
    t_via1:        DS 1 ;1 byte
    t_via2:        DS 1 ;1 byte 
    t_via3:        DS 1 ;1 byte
    cont_via:      DS 1 ;1 byte
    cont_display:  DS 1 ;1 byte
    cont1:         DS 1 ;1 byte
    decenas:       DS 1 ;1 byte
    unidades:      DS 1 ;1 byte
    cantidad:      DS 1 ;1 byte
    tur_display:   DS 1 ;1 byte

    
;//////////////////////////////////////////////////////////////////////////////
;  Macros 
;//////////////////////////////////////////////////////////////////////////////
  
; convirtiendo el reset del timer0 en una macro.  
reset_timer0 macro  
    banksel     PORTA 
    movlw       131  
    movwf       TMR0   ; voy a tener un ciclo 1ms 
    bcf         T0IF 
    endm 
    
; convirtiendo el reset del timer1 en una macro.
reset_timer1 macro  
    banksel     PORTA 
    movlw       0xDC    ;el timmer contara a cada 0.50 segundos
    movwf       TMR1L   ;por lo que cargo 3036 en forma hexadecimal 0x0BDC
    movlw       0x0B
    movwf       TMR1H
    bcf	        PIR1, 0 ;bajo la bandera
    endm 
    
;//////////////////////////////////////////////////////////////////////////////
;  Variables
;//////////////////////////////////////////////////////////////////////////////
 
 PSECT udata_shr  ;common memory
    W_TEMP:	        DS 1 ;1 byte
    STATUS_TEMP:	DS 1 ;1 byte
   
;//////////////////////////////////////////////////////////////////////////////
;  Vector reset
;//////////////////////////////////////////////////////////////////////////////
    
 PSECT resVect, class=CODE, abs, delta=2
 ORG 00h    ;  posición 0000h para el reset
 resetVec:
    PAGESEL main
    goto main

;//////////////////////////////////////////////////////////////////////////////
;Vector interrupcion
;//////////////////////////////////////////////////////////////////////////////
    
PSECT code, delta=2, abs
 ORG 04h   ;posicion para el código de interrrupcion 
 
push: 
    movwf       W_TEMP
    swapf       STATUS, W
    movwf       STATUS_TEMP 

isr: 
    btfsc       RBIF    ; reviso el valor de la bandera del INTERRUMP ON CHANGE 
    call        inter_OC ;llamar a la funcion decrementar el tiempo en semaforos
   
    btfsc       T0IF ;reviso el valor de la bandera de interrupcion del timer0 
    call        inter_timer0     ; funcion de manejo de los displays duplexados
    
    btfsc       PIR1,0 ;reviso el valor de la bandera de interrupcion del timer1 
    call        inter_timer1     ;funcion de contador por medio del timer1
    
pop:
    swapf       STATUS_TEMP, W
    movwf       STATUS
    swapf       W_TEMP, F
    swapf       W_TEMP, W
    retfie 

;//////////////////////////////////////////////////////////////////////////////
;sub-rutinas de interrupcion 
;//////////////////////////////////////////////////////////////////////////////

; menu de opciones a realizar segun el modo en que leeccionemos. 
; este funciona con las interrupciones ON CHANGE del PORTB. 
inter_OC:
;analizo el incremento en el cambio de modo en el que se encuentra el uC. 
    banksel     PORTA 
    btfsc       PORTB, 5	;button modo
    goto        incre_tiempo
    incf        modo 
    movf        modo, W
    sublw       5
    btfsc       CARRY
    goto	$+3
    movlw       1
    movf        modo 
; analizo si hago un incremento en el tiempo de configuración para el semaforo
;seleccionado. 
   incre_tiempo:
    btfsc       PORTB, 6
    goto        decre_tiempo
    incf        t_conf
    movf        t_conf, W
    sublw       20
    btfsc       CARRY 
    goto        decre_tiempo
    movlw       10
    movwf       t_conf
; analizo si hago un decremento en el tiempo de configuración para el semaforo
;seleccionado. 
    decre_tiempo:
    btfsc       PORTB, 7
    goto        exit_OC
    decf        t_conf
    movf        t_conf, W
    sublw       10
    btfss       CARRY 
    goto        exit_OC
    movlw       20
    movwf       t_conf
    ;salgo de la interrupción por ON CHANGE 
    exit_OC:
    bcf		RBIF
    return    

; esta sirve para poder controlar los displays de donde se mostrara el tiempo 
; de via de cada uno de los semaforos. 
 
inter_timer0: 
    reset_timer0
    clrf    PORTD 
    btfss   banderas, 0  ; testeo el valor de bandera en el bit 0 
    goto    display_0 
    btfss   banderas, 1  ; testeo el valor de bandera en el bit 1
    goto    display_1
    btfss   banderas, 2  ; testeo el valor de bandera en el bit 2
    goto    display_2 
    btfss   banderas, 3  ; testeo el valor de bandera en el bit 3
    goto    display_3 
    btfss   banderas, 4  ; testeo el valor de bandera en el bit 4
    goto    display_4
    btfss   banderas, 5  ; testeo el valor de bandera en el bit 4
    goto    display_5
    btfss   banderas, 6  ; testeo el valor de bandera en el bit 4
    goto    display_6
    btfss   banderas, 7  ; testeo el valor de bandera en el bit 4
    goto    display_7
    return
; en esta parte enviamos a cada display de 7 segmentos el calor correspondiente 
; de cada uno de los contador de manera que se vea ordenado. 

; en estos 2 displays se muestran el valor del contador hexadecimal. 
    display_0:
    movf    display, W 
    movwf   PORTC 
    bsf     PORTD, 1
    bsf	    banderas, 0 ;enciendo el bit-0 de bandera para ir al proximo display  
    return  
    display_1: 
    movf    display + 1, W 
    movwf   PORTC 
    bsf     PORTD, 0
    bsf	    banderas, 1 ;enciendo el bit-1 de bandera para ir al proximo display
    return 
    display_2:
    movf    display + 2, W 
    movwf   PORTC 
    bsf     PORTD, 3
    bsf	    banderas, 2 ;enciendo el bit-2 de bandera para ir al proximo display
    return 
    display_3:
    movf    display + 3, W 
    movwf   PORTC 
    bsf     PORTD, 2
    bsf	    banderas, 3 ;enciendo el bit-3 de bandera para ir al proximo display
    return 
    display_4:
    movf    display + 4, W 
    movwf   PORTC 
    bsf     PORTD, 5
    bsf	    banderas, 4 ;enciendo el bit-4 de bandera para ir al proximo display
    return 
    display_5:
    movf    display + 5, W 
    movwf   PORTC 
    bsf     PORTD, 4
    bsf     banderas, 5 ;enciendo el bit-5 de bandera para ir al proximo display
    return
    display_6:
    movf    display + 6, W 
    movwf   PORTC 
    bsf     PORTD, 7
    bsf	    banderas, 6 ;enciendo el bit-7 de bandera para ir al proximo display
    return 
    display_7:
    movf    display + 7, W 
    movwf   PORTC 
    bsf     PORTD, 6
    clrf    banderas   ;limpio los bits de bandera para ir al display inicial 
    return
    
; configurando el contador mediante el timer1   
inter_timer1: 
    reset_timer1          ; resetear el timer1
;/////en esta parte observo a cual de los semaforos le toca la via //////
    incf    cont1
    movf    cont1, W
    sublw   2	       ;500ms * 2 = 1s
    btfss   ZERO
    goto    exit_tmr1
    clrf    cont1      ;si ha pasado un segundo entonces incrementa la variable
    decf    cont_via       ;para indicar los segundo transcurridos
    decf    cont_display
    exit_tmr1:
    return
    
;//////////////////////////////////////////////////////////////////////////////
;  tabla para display de 7 segmentos 
;//////////////////////////////////////////////////////////////////////////////
    
PSECT code, delta=2, abs
 ORG 100h   ;posicion para el código
tabla_display: 
    clrf    PCLATH
    bsf	    PCLATH, 0	;PCLATH = 0
    addwf   PCL		;PC = PCL + PCLATH + w
    retlw   00111111B	;0  posicion 0
    retlw   00000110B	;1  posicion 1
    retlw   01011011B	;2  posicion 2
    retlw   01001111B	;3  posicion 3
    retlw   01100110B	;4  posicion 4
    retlw   01101101B	;5  posicion 5
    retlw   01111101B	;6  posicion 6
    retlw   00000111B	;7  posicion 7
    retlw   01111111B	;8  posicion 8
    retlw   01100111B	;9  posicion 9
    retlw   01110111B	;A  posicion 10
    retlw   01111100B	;B  posicion 11
    retlw   00111001B	;C  posicion 12
    retlw   01011110B	;D  posicion 13
    retlw   01111001B	;E  posicion 14
    retlw   01110001B	;F  posicion 15 

;//////////////////////////////////////////////////////////////////////////////
;configuraciones generales 
;//////////////////////////////////////////////////////////////////////////////
    
main: 
    ; configuraciónes generales, pines, clk interno y timers. 
    call        conf_pines   ; configuracion de pines tanto entradas y salidas
    call        conf_reloj   ; configurando el reloj para el timer0 
    call        conf_timer0  ; configuracion para el timer0
    call        conf_timer1  ; configuracion para el timer1
    ; configuracion para el interrump on change 
    bsf         RBIE 
    bcf         RBIF 
    ; configuracion para las banderas de interrupción del tmr0 y tmr1 . 
    banksel     TRISA 
    bsf         PIE1,0 
    banksel     PORTA
    bcf         PIR1,0
    bsf         PEIE 
    bsf         T0IE 
    bcf         T0IF 
    bsf         GIE
    banksel     PORTA
    ; inicializando valor de las variables de tiempo de las vias:
    clrf        cont1
    clrf        turno
    clrf	turno+1
    bsf         turno, 0 
    clrf        tur_display
    bsf         tur_display, 0 
    clrf	display
    movlw       1
    movwf       modo
    movlw       10
    movwf       t_via1
    movwf       t_via2
    movwf       t_via3
    movwf       t_conf
    movwf	cont_via
    movwf       cont_display
;//////////////////////////////////////////////////////////////////////////////
;loop principal 
;//////////////////////////////////////////////////////////////////////////////

loop: 
    ; modo de operacion 1 siempre funciona por defecto 
    call        modalidad_1	;semaforo normal
    ;control de displays para cada una de las vias 
    btfsc	tur_display, 0 
    call        via1_display 
    btfsc	tur_display, 1 
    call        via2_display 
    btfsc	tur_display, 2 
    call        via3_display 
    ;en esta parte veo que valor tiene la varibale "modo" para que asi, esta me
    ;lleve a la subrutina correspondiente a su funcionamiento respectivo.
    movf        modo, W 
    sublw       2
    btfsc       ZERO
    call        modalidad_2	;semaforo normal y confi semaforo1
   
    movf        modo, W 
    sublw       3
    btfsc       ZERO
    call        modalidad_3	;semaforo normal y confi semaforo2
    
    movf        modo, W
    sublw       4 
    btfsc       ZERO
    call        modalidad_4	;semaforo normal y confi semaforo3
    
    movf        modo, W 
    sublw       5
    btfsc       ZERO
    call        modalidad_5	;acepto las confi o no
    ;en esta sección mandamos a llamar las funciones que permiten alistar los 
    ;digitos que se mostraran en los displays de 7 segmentos.
    goto loop 

;//////////////////////////////////////////////////////////////////////////////
;sub-rutinas generales 
;//////////////////////////////////////////////////////////////////////////////

; configuraciones de pines como entradas y salidas del PIC     
conf_pines: 
    
    banksel     ANSEL       ; seleccionando el banco donde estan los ANSEL
    clrf        ANSEL       ; dejando como I/O digital los pines del puerto A
    clrf        ANSELH      ; dejando como I/O digital los pines del puerto B 
    
    banksel     TRISA       ; seleccionando el banco donde estan los TRIS
    
    clrf        TRISA       ; dejando como salidas los pines del puerto A 
   
    clrf        TRISB       ; dejando como salidas los pines del puerto B 
    bsf         TRISB, 5    ; dejando como entrada el pin 5 del puerto B 
    bsf         TRISB, 6    ; dejando como entrada el pin 6 del puerto B  
    bsf         TRISB, 7    ; dejando como entrada el pin 7 del puerto B 
    bcf         OPTION_REG, 7 ; activando las resitencias internas del puerto B 
    bsf         WPUB, 5       ; activar el PULL UP en el pin 6 del puerto B
    bsf         WPUB, 6       ; activar el PULL UP en el pin 6 del puerto B 
    bsf         WPUB, 7       ; activar el PULL UP en el pin 7 del puerto B 
    bsf         IOCB, 5       ; activar ON CHANGE en el pin 0 del puerto B
    bsf         IOCB, 6       ; activar ON CHANGE en el pin 0 del puerto B
    bsf         IOCB, 7       ; activar ON CHANGE en el pin 1 del puerto B 
    
    clrf        TRISC       ; dejando como salidas los pines del puerto C
    
    clrf        TRISD       ; dejando como salidas los pines del puerto D
    
    banksel     PORTA  ; seleccionando el banco donde estan los puertos 
    clrf        PORTA  ; dejando en cero todos los pines del puerto A
    clrf        PORTB  ; dejando en cero todos los pines del puerto B
    clrf        PORTC  ; dejando en cero todos los pines del puerto C
    clrf        PORTD  ; dejando en cero todos los pines del puerto D
    return 
    
; configuracion del reloj interno par utilizar el timer0 
conf_reloj: 
    banksel     OSCCON
    bsf	        IRCF2      ;4MHZ = 110
    bsf	        IRCF1
    bcf	        IRCF0
    bsf         SCS        ; reloj interno activo
    return 

; configurando las caracteristicas del timer0 
conf_timer0: 
    banksel     TRISB 
    bcf         T0CS       ; usar el reloj interno, temporizador
    bcf	        PSA	    ;usar prescaler
    bcf	        PS2
    bsf	        PS1 
    bcf	        PS0	    ;PS = 010 /1:8
    reset_timer0 
    return

; configurando las caracteristicas del timer1 
conf_timer1: 
    banksel     PORTA 
    bcf         TMR1GE
    bsf	        T1CKPS1     ;usar prescaler
    bsf	        T1CKPS0     ;PS = 11 /1:8
    bcf         T1OSCEN
    bcf         T1SYNC
    bcf         TMR1CS      
    bsf         TMR1ON
    reset_timer1 
    return
    
;modalidades a escoger segun la opción seleccionada al inicio. 
    
modalidad_1:
    btfsc   turno, 0
    call    verde1
    btfsc   turno, 1
    call    verde1_titileo
    btfsc   turno, 2
    call    amarillo1
    btfsc   turno, 3
    call    verde2
    btfsc   turno, 4
    call    verde2_titileo
    btfsc   turno, 5
    call    amarillo2
    btfsc   turno, 6
    call    verde3
    btfsc   turno, 7
    call    verde3_titileo
    btfsc   turno+1, 0
    call    amarillo3
    return
    ; subrutinas del semaforo1 en su funcionamiento. 
 verde1:
    ;luces del semaforo1
    bcf         PORTA, 0
    bcf         PORTA, 1
    bsf         PORTA, 2
    ;luces del semaforo2
    bsf         PORTA, 3
    bcf         PORTA, 4
    bcf         PORTA, 5
    ;luces del semaforo3
    bsf         PORTA, 6
    bcf         PORTA, 7
    bcf         PORTB, 0
; en esta parte me encargo de pasar de la luz verde estatica a la titilancia de 
; la luz verde
    movlw   7
    subwf   cont_via, W
    btfss   ZERO
    return
    movlw   00000010B
    movwf   turno
    return

verde1_titileo:
    btfsc       cont1, 0
    bsf         PORTA, 2  ; enciendo y apago la luz verde a cada 500ms gracias
    btfss       cont1, 0  ; al timer1 
    bcf         PORTA, 2
; en esta parte me encargo de pasar de la titilancia de la luz verde a la luz
; amarilla
    movlw   4
    subwf   cont_via, W
    btfss   ZERO
    return
    movlw   00000100B
    movwf   turno
    return 
    
amarillo1:
    bcf         PORTA, 2    ;apago verde
    bsf         PORTA, 1    ;enciendo amarillo
; me aseguro que el conteo del tiempo llegue a cero y cuando sea asi cargo el
; el tiempo del proximo semaforo que es el semaforo1
    movlw   1
    subwf   cont_via, W
    btfss   ZERO
    return
    movlw   00001000B
    movwf   turno
    movf    t_via2, W
    movwf   cont_display
    movwf   cont_via 
    bcf         tur_display, 0
    bsf         tur_display, 1
    bcf         tur_display, 2
    return 
    
; subrutinas del semaforo2 en su funcionamiento. 
 verde2:
    ;luces del semaforo1
    bsf         PORTA, 0
    bcf         PORTA, 1
    bcf         PORTA, 2
    ;luces del semaforo2
    bcf         PORTA, 3
    bcf         PORTA, 4
    bsf         PORTA, 5
    ;luces del semaforo3
    bsf         PORTA, 6
    bcf         PORTA, 7
    bcf         PORTB, 0
; en esta parte me encargo de pasar de la luz verde estatica a la titilancia de 
; la luz verde
    movlw   7
    subwf   cont_via, W
    btfss   ZERO
    return
    movlw   00010000B
    movwf   turno

    return

verde2_titileo:
    btfsc       cont1, 0
    bsf         PORTA, 5   ; enciendo y apago la luz verde a cada 500ms gracias
    btfss       cont1, 0   ; al timer1
    bcf         PORTA, 5
; en esta parte me encargo de pasar de la titilancia de la luz verde a la luz
; amarilla
    movlw   4
    subwf   cont_via, W
    btfss   ZERO
    return
    movlw   00100000B
    movwf   turno
    return 
    
amarillo2:
    bcf         PORTA, 5    ;verde
    bsf         PORTA, 4    ;amarillo
; me aseguro que el conteo del tiempo llegue a cero y cuando sea asi cargo el
; el tiempo del proximo semaforo que es el semaforo3
    movlw   1
    subwf   cont_via, W
    btfss   ZERO
    return
    movlw   01000000B
    movwf   turno
    movf    t_via3, W
    movwf   cont_display
    movwf   cont_via
    bcf         tur_display, 0
    bcf         tur_display, 1
    bsf         tur_display, 2 
    return 
    
; subrutinas del semaforo3 en su funcionamiento. 
 verde3:
    ;luces del semaforo1
    bsf         PORTA, 0
    bcf         PORTA, 1
    bcf         PORTA, 2
    ;luces del semaforo2
    bsf         PORTA, 3
    bcf         PORTA, 4
    bcf         PORTA, 5
    ;luces del semaforo3
    bcf         PORTA, 6
    bcf         PORTA, 7
    bsf         PORTB, 0
; en esta parte me encargo de pasar de la luz verde estatica a la titilancia de 
; la luz verde
    movlw   7
    subwf   cont_via, W
    btfss   ZERO
    goto    $+3
    return
    movlw   10000000B
    movwf   turno
    return

verde3_titileo:
    btfsc       cont1, 0
    bsf         PORTB, 0   ; enciendo y apago la luz verde a cada 500ms gracias
    btfss       cont1, 0   ; al timer1
    bcf         PORTB, 0
; en esta parte me encargo de pasar de la titilancia de la luz verde a la luz
; amarilla 
    movlw   4
    subwf   cont_via, W
    btfss   ZERO
    return
    clrf    turno    
    bsf	    turno+1, 0	
    return 
    
amarillo3:
    bcf         PORTB, 0    ;verde
    bsf         PORTA, 7    ;amarillo
; me aseguro que el conteo del tiempo llegue a cero y cuando sea asi cargo el
; el tiempo del proximo semaforo que es el semaforo1
    movlw   1
    subwf   cont_via, W
    btfss   ZERO
    return 
    bcf	    turno+1, 0 
    bsf	    turno, 0	
    movf    t_via1, W
    movwf   cont_display
    movwf   cont_via
    bsf         tur_display, 0
    bcf         tur_display, 1
    bcf         tur_display, 2
    return 

; en esta manejo el nuevo tiempo a cargar para el semaforo1 sin interrumpir el 
; funcionamiento actual de los mismo. 
modalidad_2:
    bsf         PORTB, 1    
    bcf         PORTB, 2    ; estos leds indican en que modo estoy trabajando
    bcf         PORTB, 3
    movf        t_conf, W   ; carga el nuevo tiempo a una variable temporal 
    movwf       tiempo1     ; antes de moverlos y guardarlo definitivamente. 
    movf        tiempo1, W
    movwf       cantidad
    call        tiempo_decimal
    call        display_conf
    return

; en esta manejo el nuevo tiempo a cargar para el semaforo2 sin interrumpir el 
; funcionamiento actual de los mismo.
modalidad_3:
    bcf         PORTB, 1	
    bsf         PORTB, 2    ; estos leds indican en que modo estoy trabajando
    bcf         PORTB, 3
    movf        t_conf, W
    movwf       tiempo2     ; carga el nuevo tiempo a una variable temporal
    movf        tiempo2, W  ; antes de moverlos y guardarlo definitivamente.
    movwf       cantidad
    call        tiempo_decimal
    call        display_conf
    return 
    
; en esta manejo el nuevo tiempo a cargar para el semaforo3 sin interrumpir el 
; funcionamiento actual de los mismo.
modalidad_4:
    bcf         PORTB, 1    
    bcf         PORTB, 2     ; estos leds indican en que modo estoy trabajando
    bsf         PORTB, 3
    movf        t_conf, W
    movwf       tiempo3
    movf        tiempo3, W   ; carga el nuevo tiempo a una variable temporal
    movwf       cantidad     ; antes de moverlos y guardarlo definitivamente.
    call        tiempo_decimal
    call        display_conf
    return

modalidad_5: 
    bsf         PORTB, 1    
    bsf         PORTB, 2   ; estos leds me indican el modo actual 
    bsf         PORTB, 3
; verifico si hay un cambio en el botton para aceptar cambios. 
    btfss       PORTB, 6 
    goto        nuevos_valores
    btfss       PORTB, 7
    goto        exit_modalidad5 
    return 
; si acepto los cambios actualizo los tiempos de funcionamiento y reseteo los
; semaforos para poder iniciar de nuevo con estos valores, iniciando con el 
; primer semaforo y luego asi con los demas. 
    nuevos_valores:
    movf        tiempo1, W 
    movwf       t_via1
    movf        tiempo2, W 
    movwf       t_via2
    movf        tiempo3, W 
    movwf       t_via3
    bcf         PORTB, 1    ;leds de estado
    bcf         PORTB, 2
    bcf         PORTB, 3
    movlw       1
    movwf       modo
    clrf        turno      ; me aseguro de empezar la secuencia nuevamente con 
    bsf         turno, 0   ; el semaforo1 y con su nuevo tiempo de configuracion
    clrf        display + 6
    clrf        display + 7
    movf    t_via1, W
    movwf   cont_display
    movwf   cont_via
    reset_timer0
    reset_timer1
    return
; si decido descartar los cambios no los guardo y solamente me salgo del modo
; sin reseter los semaforos y conservo sus tiempos actuales de funcinamineto 
    exit_modalidad5:
    bcf         PORTB, 1    ;leds de estado
    bcf         PORTB, 2
    bcf         PORTB, 3
    clrf        display + 6
    clrf        display + 7
    movlw       1           ; regreso a modo1 y no altero nada sigo igual como 
    movwf       modo        ; me encuentro actualmente y no reseteo la secuencia
    return
    
; alistando los displays para el semaforo 1     
via1_display:
    movlw       00111111B 
    movwf       display + 2
    movwf       display + 3
    movwf       display + 4     ; dejo los displays de los demas semaforos en 
    movwf       display + 5     ; en cero 
    movf        cont_display, W
    movwf       cantidad 
    call        tiempo_decimal
    call        display_via1
    return

; alistando los displays para el semaforo 2
via2_display:
    movlw       00111111B 
    movwf       display 
    movwf       display + 1     ; dejo los displays de los demas semaforos en 
    movwf       display + 4     ; en cero
    movwf       display + 5
    movf        cont_display, W
    movwf       cantidad 
    call        tiempo_decimal
    call        display_via2
    return
  
; alistando los displays para el semaforo 3
via3_display:
    movlw       00111111B 
    movwf       display 
    movwf       display + 1     ; dejo los displays de los demas semaforos en
    movwf       display + 2     ; en cero
    movwf       display + 3
    movf        cont_display, W
    movwf       cantidad 
    call        tiempo_decimal
    call        display_via3
    return
     
; esta parte sirve para mostrar de manera decimal el tiempo configurado en cada
; uno de los tres semaforos. 
tiempo_decimal: 
    clrf       decenas
    movlw      10 
    subwf      cantidad, F 
    btfss      STATUS, 0   ;si carry es 0 entonces 10 es mayor a cantidad 
    goto       $+3         
    incf       decenas ;carry es 1 entonces incrementamos la cantidad de decenas
    goto       $-5       ; repetir el proceso por si cantidad aun es mayor a 10. 
    movlw      10        ; sumamos 10 para obtemer el valor original antes de la
    addwf      cantidad  ; ultima resta de cantidad - 10. 
    clrf       unidades 
    movf       cantidad, W ;cantidad es un numero menor a 10, entoces solo 
    movwf      unidades    ; pasamos ese numero a la cantidad de unidades. 
    return 
    
;esta sirve para mostrar los nuevos tiempos de via a configurar en los semaforos
display_conf: 
    ;configuro para las decenas a mostrar en el display de configuración
    movf       decenas, W 
    call       tabla_display
    movwf      display + 6
    ;configuro para las unidades a mostrar en el display de configuración
    movf       unidades, W
    call       tabla_display
    movwf      display + 7
    return 
    
;esta sirve para mostrar el tiempo de via en el semaforo 1
display_via1: 
    ;configuro para las decenas a mostrar en el display de la via1
    movf       decenas, W 
    call       tabla_display
    movwf      display 
    ;configuro para las unidades a mostrar en el display de la via1
    movf       unidades, W 
    call       tabla_display
    movwf      display + 1
    return 

;esta sirve para mostrar el tiempo de via en el semaforo 2
display_via2: 
    ;configuro para las decenas a mostrar en el display de la via2
    movf       decenas, W 
    call       tabla_display
    movwf      display + 2 
    ;configuro para las unidades a mostrar en el display de la via2
    movf       unidades, W 
    call       tabla_display
    movwf      display + 3
    return 

;esta sirve para mostrar el tiempo de via en el semaforo 3
display_via3: 
    ;configuro para las decenas a mostrar en el display de la via3
    movf       decenas, W 
    call       tabla_display
    movwf      display + 4 
    ;configuro para las unidades a mostrar en el display de la via3
    movf       unidades, W 
    call       tabla_display
    movwf      display + 5
    return 
    
end 


