;Archivo:	contador1.S
;Dispositivo:	PIC16f887
;Autor:	Angel Arnoldo Cuellar 
;Compilador:	pic-as (v2.30), MPLABX V5.40
;
;Programa:	contadores binarios y hexadecimal por medio de interrupciones del ON CHANGE y TIMER0 
;Hardware:	push bottons en puertoB y leds en puerto A, C y D. 
;
;Creado:  03 marzo, 2021
;Última modificación: 06 marzo, 2021

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
    var:	DS 1 ;1 byte
    banderas:   DS 1 ;1 byte
    nibble:     DS 2 ;2 byte
    display:    DS 2 ;2 byte  
    cont1:      DS 1 ;1 byte 
    cont2:      DS 1 ;1 byte
    sep:        DS 1 ;1 byte
    
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
    btfsc       T0IF             ; reviso el valor de la bandera de la interrupcion del timer0 
    call        inter_timer0     ; llamar a la funcion de contador por medio del timer0 
    
    btfsc       PIR1,0           ; reviso el valor de la bandera de la interrupcion del timer1 
    call        inter_timer1     ; llamar a la funcion de contador por medio del timer1
    
    btfsc       PIR1,1           ; reviso el valor de la bandera de la interrupcion del timer2 
    call        inter_timer2     ; llamar a la funcion de contador por medio del timer2
    
pop:
    swapf       STATUS_TEMP, W
    movwf       STATUS
    swapf       W_TEMP, F
    swapf       W_TEMP, W
    retfie 

;//////////////////////////////////////////////////////////////////////////////
;sub-rutinas de interrupcion 
;//////////////////////////////////////////////////////////////////////////////

; configuracion de displays mostrados por el tmr0 
inter_timer0: 
    reset_timer0
    clrf    PORTD 
    btfsc   banderas, 0  ; testeo el valor de bandera en el bit 0 
    goto    display_1    ; voy a donde desplegare el valor del display 1
    
; en esta parte enviamos a cada display de 7 segmentos el valor correspondiente de 
; que se realizaran en el contador de tmr1.  
    
    display_0:
    movf    display, W 
    movwf   PORTC 
    bsf     PORTD, 1
    goto    siguiente_display
    display_1: 
    movf    display + 1, W 
    movwf   PORTC 
    bsf     PORTD, 0
    siguiente_display:
    movlw   1 
    xorwf   banderas, F 
    return 
    
; configurando el contador mediante el timer1   
inter_timer1: 
    reset_timer1          ; resetear el timer1
    incf    cont1
    movwf   cont1, W
    sublw   2	          ;500ms * 2 = 1s
    btfss   ZERO
    goto    ret1
    clrf    cont1	;si ha pasado un segundo then incrementa la variable
    incf    sep   	;para indicar los segundo transcurridos
    ret1:
    return 

inter_timer2: 
    clrf    TMR2    ;Bajo banderas
    bcf	    PIR1,1  ; TMR2IF
    incf    cont2
    movwf   cont2, W
    sublw   10	          ;25ms * 10 = 250ms 
    btfss   ZERO
    goto    ret2
    clrf    cont2	;si ha pasado un segundo then incrementa la variable
    btfsc   PORTA,0 	;para indicar los segundo transcurridos
    goto    off_led
    bsf     PORTA,0
    goto    ret2
    off_led:
    bcf     PORTA,0
    ret2:
    return 
 
;//////////////////////////////////////////////////////////////////////////////
;  tabla para display de 7 segmentos 
;//////////////////////////////////////////////////////////////////////////////
    
PSECT code, delta=2, abs
ORG 100h   ;posicion para el código
tabla_display: 
    clrf    PCLATH
    bsf	    PCLATH, 0	;PCLATH = 01
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
    call        conf_pines   ; configuracion de pines tanto entradas y salidas
    call        conf_reloj   ; configurando el reloj interno 
    call        conf_timer0  ; configuracion para el timer0
    call        conf_timer1  ; configuracion para el timer1
    call        conf_timer2  ; configuracion para el timer2
    ; configuracion para banderas de interrupcion de tmr0, tmr1 y tmr2 
    banksel     TRISA 
    bsf         PIE1,0 
    bsf         PIE1,1
    banksel     PORTA
    bcf         PIR1,0
    bcf         PIR1,1
    bsf         PEIE 
    bsf         T0IE 
    bcf         T0IF 
    bsf         GIE
    banksel     PORTA
  
;//////////////////////////////////////////////////////////////////////////////
;loop principal 
;//////////////////////////////////////////////////////////////////////////////

loop: 
;esta lineas son para ejecutar la parte 3 de la guia. 
    call        separar_nibbles 
    call        alistar_displays
    movf        sep, W    ;mover el valor del sep a la variable var para mostrarse en los display 
    movwf       var
;esta lineas son para ejecutar la parte 4 de la guia.
    call        inter_display0
    call        inter_display1
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
    
    clrf        TRISC       ; dejando como salidas los pines del puerto C
    
    clrf        TRISD       ; dejando como salidas los pines del puerto D
    bsf         TRISD, 2    ; dejando como entrada el pin 0 del puerto D  
    bsf         TRISD, 3    ; dejando como entrada el pin 0 del puerto D
    bsf         TRISD, 4    ; dejando como entrada el pin 0 del puerto D  
    bsf         TRISD, 5    ; dejando como entrada el pin 5 del puerto D
    bsf         TRISD, 6    ; dejando como entrada el pin 6 del puerto D
    bsf         TRISD, 7    ; dejando como entrada el pin 7 del puerto D
    
   
    banksel     PORTA  ; seleccionando el banco donde estan los puertos 
    clrf        PORTA  ; dejando en cero todos los pines del puerto A
    clrf        PORTB  ; dejando en cero todos los pines del puerto B
    clrf        PORTC  ; dejando en cero todos los pines del puerto C
    clrf        PORTD  ; dejando en cero todos los pines del puerto D
    return 
    
; configuracion del reloj interno a utilizar  
conf_reloj: 
    banksel     OSCCON
    bsf	        IRCF2      ;4MHZ = 110
    bsf	        IRCF1
    bcf	        IRCF0
    bsf         SCS        ; reloj interno activo
    return 
    
;configurando las caracteristicas del timer0   
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

; configurando las caracteristicas del timer2
conf_timer2: 
    banksel     PORTA 
    bsf         T2CON,7
    bsf         TOUTPS0      
    bcf	        TOUTPS1     ;usar post-scaler  
    bcf	        TOUTPS2     ;POS = 1001 / 1:10
    bsf	        TOUTPS3
    bsf	        TMR2ON           
    bsf         T2CKPS0     ;usar prescaler
    bsf         T2CKPS1     ;PS = 01 / 1:16 
    banksel     TRISA
    movlw       156         ;valor a comparar, cuenta aproximadamenre a cada 25ms 
    movwf       PR2
    BANKSEL     PORTA
    clrf        TMR2
    bcf	        PIR1, 1     ;TRM2IF
    return


    
; configurando la separacion de nibbles
separar_nibbles: 
    movf        var, W 
    andlw       0x0f 
    movwf       nibble 
    swapf       var, W 
    andlw       0x0f 
    movwf       nibble + 1 
    return 

; configurando valores para mostrar en displays 
alistar_displays: 
    movf       nibble, W 
    call       tabla_display
    movwf      display 
    movf       nibble + 1, W 
    call       tabla_display
    movwf      display + 1  
    return 

; esto sirve para controlar la intermitencia del display0 a cada 250ms 
inter_display0: 
    btfss      PORTA,0 ; verifico si la led esta encendida o apagada 
    goto       retu
    btfss      PORTD,0 ; verifico si el pin PORTD,0 se encuentra activado o no.  
    goto       off_display0
    goto       retu
    off_display0:  
    clrf       PORTC
    retu:
    return
    
; esto sirve para controlar la intermitencia del display0 a cada 250ms 
inter_display1: 
    btfss      PORTA,0 ; verifico si la led esta encendida o apagada 
    goto       retur
    btfss      PORTD,1 ; verifico si el pin PORTD,0 se encuentra activado o no. 
    goto       off_display1 
    goto       retur
    off_display1:  
    clrf       PORTC
    retur:
    return
end 


