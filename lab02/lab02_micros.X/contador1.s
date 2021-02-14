;Archivo:	contador1.S
;Dispositivo:	PIC16f887
;Autor:	Angel Arnoldo Cuellar 
;Compilador:	pic-as (v2.30), MPLABX V5.40
;
;Programa:	contadores binarios y un sumador binario 
;Hardware:	push bottons en puertoA y leds en puerto B, C y D. 
;
;Creado: 9 feb, 2021
;Última modificación: 9 feb, 2021

;//////////////////////////////////////////////////////////////////////////////
;Configuration word 1
; PIC16F887 Configuration Bit Settings
; Assembly source line config statements
;//////////////////////////////////////////////////////////////////////////////
PROCESSOR 16F887
#include <xc.inc>
    
; CONFIGURATION WORD1 
  CONFIG  FOSC = XT             ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
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

; configuracion de pines ------------------------------------------------------

main: 
    banksel ANSEL  
    clrf    ANSEL   ; definiendo los puertos de RA0-RA7 como I/O digital
    clrf    ANSELH  ; definiendo los puertos de RB0-RB7 como I/O digital
    
    banksel TRISA 
    clrf    TRISA      ; definiendo como salidas digitales de RA0-RA7 
    bsf     TRISA  , 0 ; definiendo como entrada digital RA0 
    bsf     TRISA  , 1 ; definiendo como entrada digital RA1 
    bsf     TRISA  , 2 ; definiendo como entrada digital RA2 
    bsf     TRISA  , 3 ; definiendo como entrada digital RA3 
    bsf     TRISA  , 4 ; definiendo como entrada digital RA4
    
    clrf    TRISB
    bsf     TRISB  , 4 ; definiendo como entrada digital RB5
    bsf     TRISB  , 5 ; definiendo como entrada digital RB5
    bsf     TRISB  , 6 ; definiendo como entrada digital RB6
    bsf     TRISB  , 7 ; definiendo como entrada digital RB7
    
    clrf    TRISC 
    bsf     TRISC  , 4 ; definiendo como entrada digital RC5
    bsf     TRISC  , 5 ; definiendo como entrada digital RC5
    bsf     TRISC  , 6 ; definiendo como entrada digital RC6
    bsf     TRISC  , 7 ; definiendo como entrada digital RC7
    
    clrf    TRISD 
    bsf     TRISD  , 5 ; definiendo como entrada digital RD5
    bsf     TRISD  , 6 ; definiendo como entrada digital RD6
    bsf     TRISD  , 7 ; definiendo como entrada digital RD7
   
    banksel PORTA
    clrf    PORTA  ; dejando en cero los bits del puero A
    clrf    PORTB  ; dejando en cero los bits del puero A
    clrf    PORTC  ; dejando en cero los bits del puero A
    clrf    PORTD  ; dejando en cero los bits del puero A 
   
;///////////////////////////////////////////////////////////////////////////////  

; instrucciones que ejecutara el PIC indefinidamente 

loop:
    btfsc   PORTA, 0                   ; verificando el valor de entrada de RA0 
    call    anti_rebote_incremento_1
    btfsc   PORTA, 1                   ; verificando el valor de entrada de RA1 
    call    anti_rebote_decremento_1
    btfsc   PORTA, 2                   ; verificando el valor de entrada de RA2  
    call    anti_rebote_incremento_2
    btfsc   PORTA, 3                   ; verificando el valor de entrada de RA3  
    call    anti_rebote_decremento_2
    btfsc   PORTA, 4                   ; verificando el valor de entrada de RA4  
    call    anti_rebote_sumada_binaria 
    goto    loop 
 
;esta seccion sirve para analizar el push botton para aumentar el conteo para contador 1
    
anti_rebote_incremento_1: 
    btfsc   PORTA, 0 ; verificando el valor de entrada de RA0
    goto    $-1 
    incf    PORTB, F ; incremento en 1 el puerto B
    return 

;esta seccion sirve para analizar el push botton para disminuir el conteo para contador 1

anti_rebote_decremento_1: 
    btfsc   PORTA, 1 ; verificando el valor de entrada de RA1
    goto    $-1 
    decf    PORTB, F ; decrementando en 1 el puerto B
    return 
    
;esta seccion sirve para analizar el push botton para aumentar el conteo para contador 2
    
anti_rebote_incremento_2: 
    btfsc   PORTA, 2 ; verificando el valor de entrada de RA2
    goto    $-1 
    incf    PORTC, F ; incremento en 1 el puerto C
    return 

;esta seccion sirve para analizar el push botton para disminuir el conteo para contador 2 

anti_rebote_decremento_2: 
    btfsc   PORTA, 3 ; verificando el valor de entrada de RA3
    goto    $-1 
    decf    PORTC, F ; decrementando en 1 el puerto C
    return 

;esta seccion sirve para analizar el push botton 5 que sirve para poder sumar el 
;resultado del contador1 y el contador2 mostra el resultados y señalar si hay overflow 
    
anti_rebote_sumada_binaria: 
    btfsc   PORTA, 4 ; verificando el valor de entrada de RA4
    goto    $-1 
    movf    PORTC, 0 ; moviendo los datos del puerto C al registro W 
    addwf   PORTB, 0 ; sumando los datos del registro W con los datos del registro F que son los del puerto B, guardando la suma en el registro W 
    movwf   PORTD    ; moviendo los datos del registro W al puerto D
    return 
    
end 
