/*
 * File:   lab10_main.c
 * Author: angel
 *
 * Created on 4 de mayo de 2021, 10:37 AM
 */// PIC16F887 Configuration Bit Settings

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
#include <string.h>
#define  _XTAL_FREQ 8000000

// creacion de variables ////

char nota_1[26] = "Que accion desea ejecutar" ; 
char nota_2[35] = "(1) Desplegar cadena de caracteres" ;
char nota_3[18] = "(2) Cambiar PORTA" ;
char nota_4[18] = "(3) Cambiar PORTB" ;
char nota_5[44] = "La UVG es la univeridad #1 de Centroamerica" ;
char nota_6[35] = "Que valor desea desplegar en PORTA" ;
char nota_7[35] = "Que valor desea desplegar en PORTB" ;
int i = 0; 
int valor ; 

/* esta es la seccion de configuracion de pines para el PIC */

void main(void) {
    
ANSEL = 0x00;
ANSELH = 0x00;
            
TRISA = 0x00;
TRISB = 0x00;  
TRISD = 0x00; 

PORTA = 0x00;
PORTB = 0x00;
PORTC = 0x00;
PORTD = 0x00; 

/*  configuracion de reloj interno */ 

OSCCONbits.IRCF2 = 1; 
OSCCONbits.IRCF1 = 1;  // configurando el clk interno a 8M hz 
OSCCONbits.IRCF0 = 1;
OSCCONbits.SCS = 1;

/*  configuracion de EUSART ASINCRONO      */

TXSTAbits.TX9 = 0; 
TXSTAbits.TXEN = 1;   // configuracion de registro TXSTA 
TXSTAbits.SYNC = 0; 
TXSTAbits.BRGH = 1; 

RCSTAbits.SPEN = 1; 
RCSTAbits.RX9 = 0;    // configuracion de registro RCSTA 
RCSTAbits.CREN = 1; 

BAUDCTLbits.BRG16 = 1;   // configuracion de registro BAUDCTL

SPBRG = 207; 
SPBRGH = 0;           // configurando que opere a 9600 BAULIOS 

/*  habilitando las banderas de interrupcion */

INTCONbits.GIE = 1;
INTCONbits.PEIE = 1;
PIE1bits.RCIE = 1; 
PIR1bits.RCIF = 0; 

////////////////////     LOOP PRINCIPAL DEL PROGRAMA //////////////////////////

while (1) {

for (i = 0; i <= strlen(nota_1); i++) {
    __delay_ms(100);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_1"
        TXREG = nota_1[i];
    }
}

TXREG = 13;          // hago un saltos de linea

for (i = 0; i < strlen(nota_2); i++) {
    __delay_ms(100);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_2"
        TXREG = nota_2[i];
    }
}

TXREG = 13;         // hago un saltos de linea

for (i = 0; i < strlen(nota_3); i++) {
    __delay_ms(100);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_3"
        TXREG = nota_3[i];
    }
}

TXREG = 13;         // hago un saltos de linea 

for (i = 0; i < strlen(nota_4); i++) {
    __delay_ms(100);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_4"
        TXREG = nota_4[i];
    }
}

TXREG = 13;              // hago dos saltos de linea para tener un espacio
__delay_ms(100);         // vacio entre cada mensaje
TXREG = '\r';

while (RCIF == 0) ; /* me quedo quieto hasta recibir una señal para hacer la 
                     * recepcion de datos*/ 

valor = RCREG;   // recibo los datos y los paso a la variable "valor"

switch (valor) {
    case (49) :          // si la varibale "valor" = 49 decimal o 1 en ASCII   
        for (i = 0; i < strlen(nota_5); i++) {
            __delay_ms(100);
            if (TXIF == 1) {    // despliego el mensaje de la variable "nota_5"
                TXREG = nota_5[i];
            }
        }
        TXREG = 13;          // hago dos saltos de linea para tener un espacio
        __delay_ms(100);     // vacio entre cada mensaje
        TXREG = '\r';
        break;
    
    case (50) :        // si la varibale "valor" = 50 decimal o 2 en ASCII
        for (i = 0; i < strlen(nota_6); i++) {
            __delay_ms(100);
            if (TXIF == 1) {    // despliego el mensaje de la variable "nota_6"
                TXREG = nota_6[i];
            }
        }
        TXREG = 13;          // hago dos saltos de linea para tener un espacio
        __delay_ms(100);     // vacio entre cada mensaje
        TXREG = '\r';
        while (RCIF == 0) ;  // mietras no se active la señal para recibir datos
        PORTA = RCREG ;      // me quedo quieto esperando informacion 
        break;
        
    
    case (51) :        // si la varibale "valor" = 51 decimal o 3 en ASCII
        for (i = 0; i < strlen(nota_6); i++) {
            __delay_ms(100);
            if (TXIF == 1) {    // despliego el mensaje de la variable "nota_7"
                TXREG = nota_7[i];
            }
        }
        TXREG = 13;          // hago dos saltos de linea para tener un espacio
        __delay_ms(100);     // vacio entre cada mensaje
        TXREG = '\r';         
        while (RCIF == 0) ;  // mietras no se active la señal para recibir datos
        PORTB = RCREG ;      // me quedo quieto esperando informacion 
        break;      
} 
}
return;
}

