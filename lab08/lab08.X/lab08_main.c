/*
 * File:   lab08_main.c
 * Author: angel cuellar 
 *
 * Created on 20 de abril de 2021, 10:08 AM
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
#define  _XTAL_FREQ 4000000

// declaración de variables ---------------------------------------------------

char cantidad = 0; 
char valor = 0; 
char unidades = 0;
char decenas = 0;
char centenas = 0;
char display1 = 0;
char display2 = 0;
char display3 = 0;
int turno1 = 1;
int turno2 = 0;
int turno3 = 0; 

/*  codigo para subrutina de interrupción medinte el uso de timer0 y de la 
 conversion por el modulo del ADC*/ 

void __interrupt()isr(void){
    
    if (ADIF == 1) {
        if (ADCON0bits.CHS == 0) {        // si estamos en el canal AN0 
            PORTB = ADRESH;               // paso el valor a los leds en PORTB
            ADCON0bits.CHS = 4;           // cambio el canal AN0 por el AN4 
        }
        else if (ADCON0bits.CHS == 4) {   // si estamos en el canal AN4
            valor = ADRESH;               // paso la conversion a la variable 
            ADCON0bits.CHS = 0;           // cambio el canal AN4 por el AN0
        }
    PIR1bits.ADIF = 0;                    // bajo la bandera de la interrupcion
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

/* esta es la seccion de configuracion de pines para el PIC */

void main(void) {
    
ANSEL = 0b00010001;
ANSELH = 0x00;
            
TRISA = 0b00100001;

// configuracion del modulo ADC 

ADCON0bits.ADCS1 = 0;  // seleccionando el FOSC/8 = 01 para tener 2 micro_seg
ADCON0bits.ADCS0 = 1;
ADCON0bits.CHS = 0;    // selecionando como canal principal el pin RA0 = AN0
ADCON0bits.ADON = 1;   // activando el modulo ADC 
__delay_us(50); 
ADCON0bits.GO = 1;     // empezando la coversion de valores 

ADCON1bits.ADFM = 0;   // formato de los datos agrupados hacia la izquierda 
ADCON1bits.VCFG1 = 0;  // selecionando como voltajes de refenrencia 5v = Vdd y
ADCON1bits.VCFG0 = 0;  // como voltaje inferior 0v. 

ADRESH = 0x00; 
ADRESL = 0x00; 

TRISB = 0x00; 
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

INTCONbits.PEIE = 1; 
PIE1bits.ADIE = 1;  // activo la interrupcion por el ADC
PIR1bits.ADIF = 0;  // bajo la bandera de interrupcion del ADC
INTCONbits.T0IE = 1;
INTCONbits.T0IF = 0;
INTCONbits.GIE = 1;

////////////////////     LOOP PRINCIPAL DEL PROGRAMA //////////////////////////

while (1) {
    
    /* esta parte me sirve cuando termina la conversion del ADC, se apaga el bit 
     de conteo "GO" y para que vuelva hacer otra conversion debo encerder de 
     nuevo el bit "GO".*/
    if (ADCON0bits.GO == 0) {
        __delay_us(50); 
        ADCON0bits.GO = 1;
    }
    /*  esta parte es para implementar la funcion para separa en unidades, 
     * decenas y centenas  */
    cantidad = valor; 
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
