;Archivo:	main.S
;Dispositivo:	PIC16f887
;Autor:	Angel Arnoldo Cuellar 
;Compilador:	pic-as (v2.30), MPLABX V5.40
;
;Programa:	contador en el puerto A
;Hardware:	LEDs en el puerto A
;
;Creado: 2 feb, 2021
;Última modificación: 2 feb, 2021

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
    cont_small:	DS 1 ;1 byte
    cont_big:	DS 1
    
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
;  Configuracion microprcesador
;//////////////////////////////////////////////////////////////////////////////
 
 main:
    bsf	    STATUS, 5   ;banco11
    bsf	    STATUS, 6
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6
    clrf    TRISA	;port A como salida
    
    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6
    
;//////////////////////////////////////////////////////////////////////////////
;  loop principal
;//////////////////////////////////////////////////////////////////////////////
 
 loop:	
    incf    PORTA, 1
    call    delay_big
    goto    loop	; loop forever

;//////////////////////////////////////////////////////////////////////////////
;	sub rutinas
;	delay
             ;//////////////////////////////////////////////////////////////////////////////
 
 delay_big:
    movlw   225    ;valor inicial
    movwf   cont_big	    
    call    delay_small	    ;rutina de delay
    decfsz  cont_big, 1	    ;decrementar el contador
    goto    $-2		    ;ejecutar dos líneas atrás
    return

 delay_small:
    movlw   222		    ;valor inicial del contador
    movwf   cont_small
    decfsz  cont_small, 1   ;decrementar el contador
    goto    $-1		    ;ejecutar línea anterior
    return
 
 return


