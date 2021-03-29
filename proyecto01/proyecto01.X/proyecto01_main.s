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
    cantidad:   DS 1 ;1 byte 
    unid:       DS 1 ;1 byte
    cent:       DS 1 ;1 byte 
    dece:       DS 1 ;1 byte 
    centenas:   DS 1 ;1 byte 
    decenas:    DS 1 ;1 byte 
    unidades:   DS 1 ;1 byte 
    
;//////////////////////////////////////////////////////////////////////////////
;  Macros 
;//////////////////////////////////////////////////////////////////////////////
  
; convirtiendo el reset del timer0 en una macro.  
reset_timer0 macro  
    banksel     PORTA 
    movlw       180  
    movwf       TMR0   ; voy a tener un ciclo aprox de 24ms 
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
    call        inter_timer0     ; llamar a la funcion de contador por medio del timer0 
    
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

;//////////////////////////////////////////////////////////////////////////////
;loop principal 
;//////////////////////////////////////////////////////////////////////////////

loop: 
 
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
    bsf         TRISB, 0    ; dejando como entrada el pin 0 del puerto B  
    bsf         TRISB, 1    ; dejando como entrada el pin 0 del puerto B 
    bcf         OPTION_REG, 7 ; activando las resitencias internas del puerto B 
    bsf         WPUB, 0       ; activar el PULL UP en el pin 0 del puerto B 
    bsf         WPUB, 1       ; activar el PULL UP en el pin 1 del puerto B 
    bsf         IOCB, 0       ; activar la interrupcion del ON CHANGE en el pin 0 del puerto B
    bsf         IOCB, 1       ; activar la interrupcion del ON CHANGE en el pin 1 del puerto B 
    
    clrf        TRISC       ; dejando como salidas los pines del puerto C
    
    clrf        TRISD       ; dejando como salidas los pines del puerto D
    bsf         TRISD, 5    ; dejando como entrada el pin 5 del puerto D
    bsf         TRISD, 6    ; dejando como entrada el pin 6 del puerto D
    bsf         TRISD, 7    ; dejando como entrada el pin 7 del puerto D
    
   
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
    bsf	        PS2
    bsf	        PS1 
    bcf	        PS0	    ;PS = 110 /1:128
    reset_timer0 
    return



