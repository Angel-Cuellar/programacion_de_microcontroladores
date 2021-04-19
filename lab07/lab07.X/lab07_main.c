/*
 * File:   lab07_main.c
 * Author: angel
 *
 * Created on 13 de abril de 2021, 11:02 AM
 */

// PIC16F887 Configuration Bit Settings

// 'C' source line config statements

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF        // Watchdog Timer Enable bit (WDT enabled)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF       // RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF       // Brown Out Reset Selection bits (BOR enabled)
#pragma config IESO = OFF        // Internal External Switchover bit (Internal/External Switchover mode is enabled)
#pragma config FCMEN = OFF       // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdint.h>

// declaración de variables ---------------------------------------------------

char cantidad = 0; 
char unidades = 0;
char decenas = 0;
char centenas = 0;
char display1 = 0;
char display2 = 0;
char display3 = 0;
int turno1 = 1;
int turno2 = 0;
int turno3 = 0;

//  codigo para subrutina de interrupción medinte el uso de timer0 y ON CHANGE 

void __interrupt()isr(void){
    // interrucion por medio de bandera de ON CHANGE para contador en el PORTA. 
    if (RBIF == 1){
        if (RB6 == 0){  
            PORTA++ ;    // si RB6 es cero, entonces incremento el PORTA. 
        }
        if (RB7 == 0){
            PORTA-- ;    // si RB7 es cero, entonces decremento el PORTA.
        }
    INTCONbits.RBIF = 0; // luego de todo esto, bajo la bandera de ON CHANGE. 
    }
    // interrucion por medio de bandera de timer0 para manejo de displays. 
    if (T0IF == 1){
        INTCONbits.T0IF = 0; // bajo la bandera del timer0 
        TMR0 = 100;          // reseteo el timer0 para que funcione a 5ms. 
        PORTD = 0b00000000;  // dejo en cero los pines del PORTD. 
        if (turno1 == 1){    
            PORTC = display1;    // si la variable "turno1" tiene valor 1,
            RD0 = 1;             // entonces enciendo el pin RD0 y muevo el 
            turno1 = 0;          // valor de la variable "display1" al PORTC. 
            turno2 = 1;          // luego dejo en cero "turno1" y "turno3" y
            turno3 = 0;          // le pongo el valor 1 a la variable "turno2". 
        }
        else if (turno2 == 1){ 
            PORTC = display2;    // si la variable "turno2" tiene valor 1,
            RD1 = 1;             // entonces enciendo el pin RD1 y muevo el
            turno1 = 0;          // valor de la variable "display2" al PORTC.
            turno2 = 0;          // luego dejo en cero "turno1" y "turno2" y
            turno3 = 1;          // le pongo el valor 1 a la variable "turno3".
        }
        else if (turno3 == 1){
            PORTC = display3;    // si la variable "turno3" tiene valor 1,
            RD2 = 1;             // entonces enciendo el pin RD2 y muevo el
            turno1 = 1;          // valor de la variable "display3" al PORTC.
            turno2 = 0;          // luego dejo en cero "turno2" y "turno3" y
            turno3 = 0;          // le pongo el valor 1 a la variable "turno1".
        } 
    } 
}


void main(void) {
    
    /* esta es la seccion de configuracion de pines para el PIC */
    
ANSEL = 0x00;
ANSELH = 0x00;
            
TRISA = 0x00;

TRISB = 0b11000000;
OPTION_REGbits.nRBPU = 0;
IOCBbits.IOCB6 = 1; 
IOCBbits.IOCB7 = 1; 
WPUB = 0b11000000;

TRISC = 0x00;

TRISD = 0x00;

PORTA = 0x00;
PORTB = 0x00;
PORTC = 0x00;
PORTD = 0x00;

/*  configuracion de reloj interno */ 

OSCCONbits.IRCF2 = 1; 
OSCCONbits.IRCF1 = 1;  // configurando el clk interno a 4M hz 
OSCCONbits.IRCF0 = 0;
OSCCONbits.SCS = 1;

/*  configuracion del timer0 */

OPTION_REGbits.T0CS = 0; 
OPTION_REGbits.PSA = 0;
OPTION_REGbits.PS2 = 1;   // configurando para utilizar un pre_escaler de 1:32
OPTION_REGbits.PS1 = 0;
OPTION_REGbits.PS0 = 1;
TMR0= 100;

/*  habilitando las banderas de interrupcion */

INTCONbits.T0IE = 1;
INTCONbits.T0IF = 0;
INTCONbits.RBIE = 1;
INTCONbits.RBIF = 0;
INTCONbits.GIE = 1;

/* LOOP principal del codigo  */

while (1){ 
    /*  esta parte es para implementar la funcion para separa en unidades, 
     * decenas y centenas  */
    cantidad = PORTA; 
    unidades = 0; 
    decenas = 0; 
    centenas = 0; 
    while (cantidad >= 100) {
        cantidad = cantidad - 100; 
        centenas++; 
    }
    while (cantidad >= 10) {
        cantidad = cantidad - 10; 
        decenas++;     
    }
    if (cantidad < 10) {
        unidades = cantidad;
    }
  
    /*  esta parte es para poder alistar los valores que seran mostrados en los 
     *  displays de 7 segmentos   */
    
    switch (centenas){
        case (0) : display1 = 0b00111111; 
        break; 
        case (1) : display1 = 0b00000110;
        break;
        case (2) : display1 = 0b01011011;
        break;
        case (3) : display1 = 0b01001111;  
        break;
        case (4) : display1 = 0b01100110;
        break;
        case (5) : display1 = 0b01101101;
        break;
        case (6) : display1 = 0b01111101; 
        break;
        case (7) : display1 = 0b00000111;
        break;
        case (8) : display1 = 0b01111111;
        break;
        case (9) : display1 = 0b01100111; 
        break;
        case (10) : display1 = 0b01110111;
        break;
        case (11) : display1 = 0b01111100;
        break;
        case (12) : display1 = 0b00111001;
        break;
        case (13) : display1 = 0b01011110;
        break;
        case (14) : display1 = 0b01111001;
        break;
        case (15) : display1 = 0b01110001;
        break;
    }
    
    switch (decenas){
        case (0) : display2 = 0b00111111;  
        break;
        case (1) : display2 = 0b00000110;
        break;
        case (2) : display2 = 0b01011011;
        break;
        case (3) : display2 = 0b01001111;  
        break;
        case (4) : display2 = 0b01100110;
        break;
        case (5) : display2 = 0b01101101;
        break;
        case (6) : display2 = 0b01111101; 
        break;
        case (7) : display2 = 0b00000111;
        break;
        case (8) : display2 = 0b01111111;
        break;
        case (9) : display2 = 0b01100111; 
        break;
        case (10) : display2 = 0b01110111;
        break;
        case (11) : display2 = 0b01111100;
        break;
        case (12) : display2 = 0b00111001; 
        break;
        case (13) : display2 = 0b01011110;
        break;
        case (14) : display2 = 0b01111001;
        break;
        case (15) : display2 = 0b01110001;
        break;
    }
    
    switch (unidades){
        case (0) : display3 = 0b00111111; 
        break;
        case (1) : display3 = 0b00000110;
        break;
        case (2) : display3 = 0b01011011;
        break;
        case (3) : display3 = 0b01001111;  
        break;
        case (4) : display3 = 0b01100110;
        break;
        case (5) : display3 = 0b01101101;
        break;
        case (6) : display3 = 0b01111101; 
        break;
        case (7) : display3 = 0b00000111;
        break;
        case (8) : display3 = 0b01111111;
        break;
        case (9) : display3 = 0b01100111; 
        break;
        case (10) : display3 = 0b01110111;
        break;
        case (11) : display3 = 0b01111100;
        break;
        case (12) : display3 = 0b00111001;  
        break;
        case (13) : display3 = 0b01011110;
        break;
        case (14) : display3 = 0b01111001;
        break;
        case (15) : display3 = 0b01110001;
        break;
    }
}
return;
}