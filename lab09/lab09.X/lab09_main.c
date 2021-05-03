/*
 * File:   lab09_main.c
 * Author: angel
 *
 * Created on 27 de abril de 2021, 10:01 AM
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
#define  _XTAL_FREQ 8000000

/*  codigo para subrutina de interrupción medinte el uso de la conversion por 
 * el modulo del ADC*/ 

void __interrupt()isr(void){
    
    if (ADIF == 1) {
        if (ADCON0bits.CHS == 0) {   // si tenemos la convercion del canal CH0 
            CCPR1L = (ADRESH >> 1) + 124; // hacemos que varie entre los 0-255 
            CCP1CONbits.DC1B1 = (ADRESH & 0b01); // configuro la mejor presicion
            CCP1CONbits.DC1B0 = (ADRESL >> 7);   // para que vaya de -90° a 90°
            ADCON0bits.CHS = 4;      // cambiamos de canal para el CH4. 
        }
        else if (ADCON0bits.CHS == 4){ // si tenemos la convercion del canal CH0
            CCPR2L = (ADRESH >> 1) + 124; // hacemos que varie entre los 0-255
            CCP2CONbits.DC2B1 = (ADRESH & 0b01); // configuro la mejor presicion
            CCP2CONbits.DC2B0 = (ADRESL >> 7);   // para que vaya de -90° a 90°
            ADCON0bits.CHS = 0;      // cambiamos de canal para el CH0.
        }
        PIR1bits.ADIF = 0;    // bajo la bandera de la interrupcion por el ADC
    }
}

/* esta es la seccion de configuracion de pines para el PIC */

void main(void) {
    
ANSEL = 0b00010001;
ANSELH = 0x00;
            
TRISA = 0b00100001;
TRISB = 0x00;   
TRISD = 0x00; 

PORTA = 0x00;
PORTB = 0x00;
PORTC = 0x00;
PORTD = 0x00; 

// configuracion del modulo ADC ////////////////////////////////////////////////

ADCON0bits.ADCS1 = 1;  // seleccionando el FOSC/32 = 10 para tener 4 micro_seg
ADCON0bits.ADCS0 = 0;
ADCON0bits.CHS = 0;    // selecionando como canal principal el pin RA0 = AN0
ADCON0bits.ADON = 1;   // activando el modulo ADC 
__delay_us(50); 
ADCON0bits.GO = 1;     // empezando la coversion de valores 

ADCON1bits.ADFM = 0;   // formato de los datos agrupados hacia la izquierda 
ADCON1bits.VCFG1 = 0;  // selecionando como voltajes de refenrencia 5v = Vdd y
ADCON1bits.VCFG0 = 0;  // como voltaje inferior 0v. 

ADRESH = 0x00; 
ADRESL = 0x00; 

// configuracion del modulo PWM con el CCP1CON con salida en el CCP1 ///////////

CCP1CONbits.P1M = 0;  // configurando que el PWM tenga una solo señal de salida
CCP1CONbits.CCP1M = 0b1100;  /* Escogiendo el modo del PWM con P1A, P1B, PIC 
                              * y P1D como active-high*/

CCPR1L = 0x0f;        // inicializando la variable de registro para el CCP1
CCP1CONbits.DC1B = 0;    // seleccionando el modo de PWM 

PIR1bits.TMR2IF = 0; 
T2CONbits.T2CKPS = 0b11;  // configuracion del timer2 para poder tener un duty 
T2CONbits.TMR2ON = 1;     // cicle que varie hasta los 20ms 
PR2 = 255;

while (PIR1bits.TMR2IF == 0);  // dejando siempre en cero la de interrupcion del
PIR1bits.TMR2IF = 0;         // timer2 para que esta no interfiera en el codigo. 

TRISCbits.TRISC2 = 0;        // definiendo como salida el PIN RC2 = CCP1

// configuracion del modulo PWM con el CCP2CON con salida en el CCP2 ///////////

CCP2CONbits.CCP2M = 0b1100;  //Escogiendo el modo del PWM 

CCPR2L = 0x0f;           // inicializando la variable de registro para el CCP2
CCP2CONbits.DC2B1 = 0;     
CCP2CONbits.DC2B0 = 0;    // seleccionando el modo de PWM

TRISCbits.TRISC1 = 0;        // definiendo como salida el PIN RC1 = CCP1

/*  configuracion de reloj interno */ 

OSCCONbits.IRCF2 = 1; 
OSCCONbits.IRCF1 = 1;  // configurando el clk interno a 8M hz 
OSCCONbits.IRCF0 = 1;
OSCCONbits.SCS = 1;

/*  habilitando las banderas de interrupcion */

INTCONbits.PEIE = 1; 
PIE1bits.ADIE = 1;  // activo la interrupcion por el ADC
PIR1bits.ADIF = 0;  // bajo la bandera de interrupcion del ADC
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
}
return;    
}

