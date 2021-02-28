;Archivo:	contador1.S
;Dispositivo:	PIC16f887
;Autor:	Angel Arnoldo Cuellar 
;Compilador:	pic-as (v2.30), MPLABX V5.40
;
;Programa:	contadores binarios y hexadecimal por medio de interrupciones del ON CHANGE y TIMER0 
;Hardware:	push bottons en puertoB y leds en puerto A, C y D. 
;
;Creado:  23 feb, 2021
;Última modificación: 27 feb, 2021

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
    display:    DS 1 ;1 byte  
    
;//////////////////////////////////////////////////////////////////////////////
;  Macros 
;//////////////////////////////////////////////////////////////////////////////
  
; convirtiendo el reset del timer0 en una macro.  
reset_timer0 macro  
    banksel     PORTA 
    movlw       61   
    movwf       TMR0   ; voy a tener un ciclo aprox de 50ms 
    bcf         T0IF 
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
    btfsc       RBIF         ; reviso el valor de la bandera del INTERRUMP ON CHANGE 
    call        incre_decre  ; llamar a la funcion de incrementar o decrementar el contador binario. 
    
    btfsc       T0IF             ; reviso el valor de la bandera de la interrupcion del timer0 
    call        contador_timer0  ; llamar a la funcion de contador por medio del timer0 

pop:
    swapf       STATUS_TEMP, W
    movwf       STATUS
    swapf       W_TEMP, F
    swapf       W_TEMP, W
    retfie 
 
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
    retlw   0111111B	;0  posicion 0
    retlw   0000110B	;1  posicion 1
    retlw   1011011B	;2  posicion 2
    retlw   1001111B	;3  posicion 3
    retlw   1100110B	;4  posicion 4
    retlw   1101101B	;5  posicion 5
    retlw   1111101B	;6  posicion 6
    retlw   0000111B	;7  posicion 7
    retlw   1111111B	;8  posicion 8
    retlw   1100111B	;9  posicion 9
    retlw   1110111B	;A  posicion 10
    retlw   1111100B	;B  posicion 11
    retlw   0111001B	;C  posicion 12
    retlw   1011110B	;D  posicion 13
    retlw   1111001B	;E  posicion 14
    retlw   1110001B	;F  posicion 15       


;//////////////////////////////////////////////////////////////////////////////
;  configuracion del microcontrolador 
;//////////////////////////////////////////////////////////////////////////////

main: 
    call        conf_pines   ; configuracion de pines tanto entradas y salidas
    call        conf_reloj   ; configurando el reloj para el timer0 
    call        conf_timer0  ; configuracion para el timer0
    bsf         GIE
    ; configuracion para el interrump on change 
    bsf         RBIE 
    bcf         RBIF 
    ; configuracion para el timer0 
    bsf         T0IE 
    bcf         T0IF 
    banksel     PORTA 
    
loop: 
    ; manejo del display de 7 segmentos para el puerto C por el contador 
    ; del Interrupt On Change del puerto B. 
    movf        PORTA, W 
    call        tabla_display  ; llamando a la tabla con los valores del display  
    movwf       PORTC          ; asignar el valor respectivo en hexadecimal para el display 
    
    ; manejo del display de 7 segmentos para el puerto D por el contador 
    ; de la interrupcion del timer0
    call        control_conteo  ; llamo a la funcion control de contro del timer0 para evitar desbordamiento. 
    movf        display, W
    call        tabla_display  ; llamando a la tabla con los valores del display  
    movwf       PORTD          ; asignar el valor respectivo en hexadecimal para el display 
    goto loop 
    
conf_pines: 
    
    banksel     ANSEL       ; seleccionando el banco donde estan los ANSEL
    clrf        ANSEL       ; dejando como I/O digital los pines del puerto A
    clrf        ANSELH      ; dejando como I/O digital los pines del puerto B 
    
    banksel     TRISA       ; seleccionando el banco donde estan los TRIS
    clrf        TRISA       ; dejando como salidas los pines del puerto A 
    bsf         TRISA, 4    ; dejando como entrada el pin 4 del puerto A 
    bsf         TRISA, 5    ; dejando como entrada el pin 5 del puerto A
    bsf         TRISA, 6    ; dejando como entrada el pin 6 del puerto A 
    bsf         TRISA, 7    ; dejando como entrada el pin 7 del puerto A
    
    clrf        TRISB       ; dejando como salidas los pines del puerto B
    bsf         TRISB, 0   ; dejando como entrada el pin 0 del puerto B  
    bsf         TRISB, 1    ; dejando como entrada el pin 0 del puerto B 
    bcf         OPTION_REG, 7 ; activando las resitencias internas del puerto B 
    bsf         WPUB, 0       ; activar el PULL UP en el pin 0 del puerto B 
    bsf         WPUB, 1       ; activar el PULL UP en el pin 1 del puerto B 
    bsf         IOCB, 0       ; activar la interrupcion del ON CHANGE en el pin 0 del puerto B
    bsf         IOCB, 1       ; activar la interrupcion del ON CHANGE en el pin 1 del puerto B 
    
    clrf        TRISC       ; dejando como salidas los pines del puerto C
    clrf        TRISD       ; dejando como salidas los pines del puerto D
    
    banksel     PORTA  ; seleccionando el banco donde estan los puertos 
    clrf        PORTA  ; dejando en cero todos los pines del puerto A
    clrf        PORTB  ; dejando en cero todos los pines del puerto B
    clrf        PORTC  ; dejando en cero todos los pines del puerto C
    clrf        PORTD  ; dejando en cero todos los pines del puerto D
    
    movlw       0x000  ; inicializando la variable contador en 0 
    movwf       cont 
    return 
 
; configurando el incremento o decremento del contador del puerto A. 
incre_decre: 
    banksel     PORTA 
    btfss       PORTB, 0 ; testeo el valor del pin 0 en el puerto B 
    incf        PORTA ; incremento en 1 la variable contador 
    btfss       PORTB, 1 ; testeo el valor del pin 0 en el puerto B 
    decf        PORTA ; decrementando en 1 la variable contador 
    bcf         RBIF 
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
    bcf         PSA        ; usar prescaler
    bsf         PS2 
    bsf         PS1 
    bsf         PS0        ;PS = 111 /1:256
    reset_timer0 
    return
    
; configurando el contador mediante el timer0   
contador_timer0: 
    reset_timer0     ; resetear el timer0 
    banksel     PORTA 
    incf        cont ; incremento en 1 la variable contador 
    movf        cont, W 
    sublw       20   ; multiplicar 10*50ms = 1000ms 
    btfss       ZERO ; testeando la bandera de ZERO 
    goto        ret 
    clrf        cont ; limpiando la variable contador 
    incf        display ; incrementar la variable del display  
    ret:
    return 
 
; configurando el control del desbordamineto para el contador del timer0 
control_conteo:
    movlw      16            ; asignando la literal a registro W 
    subwf      display, W    ; restar al valor de la variable display el valor del registro W 
    btfsc      STATUS, 2     ; testeando el valor de la bandera ZERO 
    clrf       display       ; resetear a cero la variable display 
    return    
end 
    
    
    
    



