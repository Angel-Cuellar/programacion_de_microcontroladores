;Archivo:	contador1.S
;Dispositivo:	PIC16f887
;Autor:	Angel Arnoldo Cuellar 
;Compilador:	pic-as (v2.30), MPLABX V5.40
;
;Programa:	contadores binarios por timer0 y por push bottons 
;Hardware:	push bottons en puertoA y leds en puerto B, C y D. 
;
;Creado:  16 feb, 2021
;Última modificación: 20 feb, 2021

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
    cont:	DS 1 ;1 byte
    delay:	DS 3 ;1 byte
    
;//////////////////////////////////////////////////////////////////////////////
;  Instrucciones
;//////////////////////////////////////////////////////////////////////////////
 
 PSECT resVect, class=CODE, abs, delta=2
 
;//////////////////////////////////////////////////////////////////////////////
;  Vector reset
;//////////////////////////////////////////////////////////////////////////////
 
 ORG 00h    ;  posición 0000h para el reset
 resetVec:
    PAGESEL main
    goto main

;//////////////////////////////////////////////////////////////////////////////
;  tabla para display de 7 segmentos 
;//////////////////////////////////////////////////////////////////////////////
    
PSECT code, delta=2, abs
 ORG 100h   ;posicion para el código
tabla_display: 
    clrf    PCLATH
    bsf	    PCLATH, 0	;PCLATH = 01
    andwf   0x0f	;me aseguro q solo pasen 4 bits
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
;  configuracion del microcontrolador 
;//////////////////////////////////////////////////////////////////////////////
    
main: 
    call        conf_reloj   ; configurando el reloj para el timer0 
    call        conf_pines   ; configuracion de pines tanto entradas y salidas
    call        conf_timer0  ; configuracion para el timer0 
    banksel     PORTB 
    movlw       0x00         ; inializando valor a la variable contador 
    movwf       cont         
    
;//////////////////////////////////////////////////////////////////////////////
;  configuracion del LOOP principal 
;//////////////////////////////////////////////////////////////////////////////
    
loop: 
; instrucciones para ejecutar el contador mediante el timer0
    btfss       T0IF 
    goto        $-1 
    call        reset_timer0 
    incf        PORTB  
;  instruccion par ejecutar el contador hexadecimal de 4bits 
    call        cont_hexadecimal 
;  instruccion para ejecutar la bandera de igualacion de contadores y reset del
;  contador por timer0 
    call        alarma_contadores
    goto        loop 
    
;//////////////////////////////////////////////////////////////////////////////
;  configuracion del sub-rutinas 
;//////////////////////////////////////////////////////////////////////////////

; configurando pines del PIC como entradas o salidas 
conf_pines: 
    banksel     PORTA  ; seleccionando el banco donde estan los puertos 
    clrf        PORTA  ; dejando en cero todos los pines del puerto A
    clrf        PORTB  ; dejando en cero todos los pines del puerto B
    clrf        PORTC  ; dejando en cero todos los pines del puerto C
    clrf        PORTD  ; dejando en cero todos los pines del puerto D
    
    banksel     TRISA       ; seleccionando el banco donde estan los TRIS
    clrf        TRISA       ; dejando como salidas los pines del puerto A 
    bsf         TRISA, 0    ; dejando como entrada el pin 0 del puerto A 
    bsf         TRISA, 1    ; dejando como entrada el pin 1 del puerto A
    clrf        TRISB       ; dejando como salidas los pines del puerto B
    bsf         TRISB, 4    ; dejando como entrada el pin 0 del puerto B  
    bsf         TRISB, 5    ; dejando como entrada el pin 0 del puerto B 
    bsf         TRISB, 6    ; dejando como entrada el pin 0 del puerto B 
    bsf         TRISB, 7    ; dejando como entrada el pin 0 del puerto B 
    clrf        TRISC       ; dejando como salidas los pines del puerto C
    clrf        TRISD       ; dejando como salidas los pines del puerto D
    
    banksel     ANSEL       ; seleccionando el banco donde estan los ANSEL
    clrf        ANSEL       ; dejando como I/O digital los pines del puerto A
    clrf        ANSELH      ; dejando como I/O digital los pines del puerto B
    return

; configuracion del reloj interno par utilizar el timer0 
conf_reloj: 
    banksel     OSCCON
    bcf         IRCF2      ; usando una frecuencia de 250k HZ 
    bsf         IRCF1
    bcf         IRCF0 
    bsf         SCS        ; reloj interno activo
    return 

; configurando las caracteristicas del timer0 
conf_timer0: 
    banksel     TRISB 
    bcf         T0CS       ; usar el reloj interno, temporizador
    bcf         PSA        ; usar prescaler
    bsf         PS2 
    bsf         PS1 
    bsf         PS0        ;PS = 111 /1:256
    banksel     PORTB 
    call reset_timer0 
    return 

; configuracion del rest para el timer0 
reset_timer0: 
    movlw       134   ; para lo que calculer este valor me acerca a un T aprox de 0.5 seg 
    movwf       TMR0 
    bcf         T0IF 
    return 

; configuracion para control del contador hexadecimal 
cont_hexadecimal: 
    btfsc       PORTA, 0   ; verificando el valor de entrada de RA0
    call        antirebote_incre  ; llamando al antirebote para el incremento del contador 
    btfsc       PORTA, 1   ; verificando el valor de entrada de RA1
    call        antirebote_decre  ; llamando al antirebote para el decremento del contador 
    return
    
;esta seccion sirve para analizar el push botton para aumentar el conteo del contador    
antirebote_incre: 
    btfsc   PORTA, 0 ; verificando el valor de entrada de RA0
    goto    $-1 
    incf    cont ; incremento en 1 la variable contador 
    movf    cont, W
    call    tabla_display  ; llamando a la tabla con los valores del display  
    movwf   PORTC          ; asignar el valor respectivo en hexadecimal para el display 
    return 

;esta seccion sirve para analizar el push botton para disminuir el conteo para contador 
antirebote_decre: 
    btfsc   PORTA, 1 ; verificando el valor de entrada de RA1
    goto    $-1 
    decf    cont ; decrementando en 1 la variable contador 
    movf    cont, W
    call    tabla_display  ; llamando a la tabla con los valores del display 
    movwf   PORTC          ; asignar el valor respectivo en hexadecimal para el display 
    return 

; esta seccion sirve para analizar si se igualan los valores de los contador 
alarma_contadores:
    movf    cont, W 
    subwf   PORTB, W     ; restar al valor de la variable contador el valor del contador del timer0 
    btfsc   STATUS, 2    ; analizando la bandera ZERO de la operacion de resta 
    call    bandera_led  
    btfsc   STATUS, 2    ; analizando la bandera ZERO de la operacion de resta
    bcf     PORTD, 0     ; apagando el led de bandera 
    return 
    
bandera_led: 
    bsf     PORTD, 0        ; encendiendo el led de bandera 
    call    reset_timer0    ; reseteo el contador del timer0 
    ; genero un delay de espera 
    movlw   700	       ;valor inicial del contador
    movwf   delay
    decfsz  delay, 1   ;decrementar el contador
    goto    $-1	       ;ejecutar línea anterior
    clrf    PORTB           ; apago el led de bandera 
    return 
end 