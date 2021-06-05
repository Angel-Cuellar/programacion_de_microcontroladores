/*
 * File:   pro_02_main.c
 * Author: angel
 *
 * Created on 18 de mayo de 2021, 10:43 AM
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
#pragma config LVP = OFF         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdint.h>
#include <string.h>
#define  _XTAL_FREQ 8000000

// declaración de variables para manejo de motores -----------------------------

char servo1 = 0; 
char servo2 = 0;
char servo3 = 0;
char cont = 0;
int direccion = 1;  
char cantidad = 0; 
char unidades = 0;
char decenas = 0;
char centenas = 0;  

// creacion de variables para comunicacion serial 

char nota_1[5] = "MENU" ; 
char nota_2[20] = "(1) Posicion servo1" ;
char nota_3[20] = "(2) Posicion servo2" ;
char nota_4[20] = "(3) Posicion servo3" ;
char nota_5[26] = "(4) Sentido de motor DC" ;
char nota_6[19] = "Posicion servo1 = " ;
char nota_7[19] = "Posicion servo2 = " ;
char nota_8[19] = "Posicion servo3 = " ;
char nota_9[19] = "Sentido giro es = " ;
char right[8] = "Horario" ; 
char left[14] = "Ante-horario" ;
char cambio[40] = "Quieres hacer un cambio__(1) si__(2) no";
char giro[29] = "1) Horario____2)Ante-horario";
char angulo[3]; 
int i = 0; 
int valor ; 

///*  codigo para subrutina de interrupción medinte el uso de la conversion por 
// * el modulo del ADC, por TIMER0 y por ON CHANGE*/ 
//
void __interrupt()isr(void){
    
    if (ADIF == 1) {
        if (ADCON0bits.CHS == 0) {   // si tenemos la convercion del canal CH0 
            servo1 = (ADRESH >> 4) + 4; 
            ADCON0bits.CHS = 1;      // cambiamos de canal para el CH1. 
        }
        else if (ADCON0bits.CHS == 1){ // si tenemos la convercion del canal CH1
            servo2 = (ADRESH >> 4) + 4;
            ADCON0bits.CHS = 2;      // cambiamos de canal para el CH2.
        }
        else if (ADCON0bits.CHS == 2){ // si tenemos la convercion del canal CH2
            servo3 = (ADRESH >> 4) + 4;
            ADCON0bits.CHS = 3;      // cambiamos de canal para el CH3.
        }
        else if (ADCON0bits.CHS == 3){ // si tenemos la convercion del canal CH3
            CCPR1L = ADRESH;
            ADCON0bits.CHS = 0;      // cambiamos de canal para el CH0.
        }
        PIR1bits.ADIF = 0;    // bajo la bandera de la interrupcion por el ADC
    }
    
    if (T0IF == 1){
        INTCONbits.T0IF = 0; // bajo la bandera del timer0 
        TMR0 = 206;          // reseteo el timer0 para que funcione a 0.1ms.
        cont++; 
        if (cont > servo1) {
            RC0 = 0; 
        }
        if (cont > servo2) {
            RC1 = 0; 
        }
        if (cont > servo3) {
            RC3 = 0; 
        }
        if (cont > 200) {
            RC0 = 1;
            RC1 = 1;
            RC3 = 1; 
            cont = 0;
        }
        ADCON0bits.GO = 1;  // activo para realiar una nueva conversion 
    }
    
    if (RBIF == 1){
        if (RB0 == 0){  
            CCP1CONbits.P1M = 0b01;    // girar a la derecha 
            direccion = 1;
            RD0 = 1; 
            RD1 = 0;
            
        }
        if (RB1 == 0){
            CCP1CONbits.P1M = 0b11;  // gira a la izquierda
            direccion = 0; 
            RD0 = 0; 
            RD1 = 1;
        }
    INTCONbits.RBIF = 0; // luego de todo esto, bajo la bandera de ON CHANGE. 
    }
    
    return; 
}

/* esta es la seccion de configuracion de pines para el PIC */

void main(void) {
    
ANSEL = 0b00001111;
ANSELH = 0x00;
            
TRISA = 0b00001111;
TRISB = 0b00000011;
TRISC = 0b10000000;
TRISD = 0x00; 

PORTA = 0x00;
PORTB = 0x00;
PORTC = 0x00;
PORTD = 0x00; 

RD0 = 1; // inicializando el led de derecha 

// configuracion de PULL UP internos en PORTB///////////////////////////////////

OPTION_REGbits.nRBPU = 0;
IOCBbits.IOCB0 = 1; 
IOCBbits.IOCB1 = 1;
WPUB = 0b00000011;

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

CCP1CONbits.P1M = 0b01; // configurando el PWM ENHANCED en modo HALF BRIDGE
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


/*  configuracion de reloj interno */ 

OSCCONbits.IRCF2 = 1; 
OSCCONbits.IRCF1 = 1;  // configurando el clk interno a 8M hz 
OSCCONbits.IRCF0 = 1;
OSCCONbits.SCS = 1;

/*  configuracion del timer0 */

OPTION_REGbits.T0CS = 0; 
OPTION_REGbits.PSA = 0;
OPTION_REGbits.PS = 0b001; // configurando para utilizar un pre_escaler de 1:4
TMR0= 206;

/*  habilitando las banderas de interrupcion */

INTCONbits.RBIE = 1;
INTCONbits.RBIF = 0;  // interrupciones del ON CHANGE 
INTCONbits.PEIE = 1; 
PIE1bits.ADIE = 1;  // activo la interrupcion por el ADC
PIR1bits.ADIF = 0;  // bajo la bandera de interrupcion del ADC
INTCONbits.T0IE = 1; 
INTCONbits.T0IF = 0; // banderas de interrupcion del timer0
INTCONbits.GIE = 1;

////////////////////     LOOP PRINCIPAL DEL PROGRAMA ///////////////////////////

while (1) {
    
     //comunicación serial del brazo robotico //////////////////////////////////

for (i = 0; i <= strlen(nota_1); i++) {
    __delay_ms(5);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_1"
        TXREG = nota_1[i];
    }
}

TXREG = '\n';          // hago un saltos de linea

for (i = 0; i < strlen(nota_2); i++) {
    __delay_ms(5);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_2"
        TXREG = nota_2[i];
    }
}

TXREG = '\n';         // hago un saltos de linea

for (i = 0; i < strlen(nota_3); i++) {
    __delay_ms(5);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_3"
        TXREG = nota_3[i];
    }
}

TXREG = '\n';         // hago un saltos de linea 

for (i = 0; i < strlen(nota_4); i++) {
    __delay_ms(5);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_4"
        TXREG = nota_4[i];
    }
}

TXREG = '\n';         // hago un saltos de linea 

for (i = 0; i < strlen(nota_5); i++) {
    __delay_ms(5);
    if (TXIF == 1) {          // despliego el mensaje de la variable "nota_4"
        TXREG = nota_5[i];
    }
}

TXREG = '\n';              // hago dos saltos de linea para tener un espacio
__delay_ms(5);         // vacio entre cada mensaje
TXREG = '\n';

while (RCIF == 0) ; /* me quedo quieto hasta recibir una señal para hacer la 
                     * recepcion de datos*/ 

valor = RCREG;   // recibo los datos y los paso a la variable "valor"

switch (valor) {
    case('1'):
        for (i = 0; i < strlen(nota_6); i++) {
        __delay_ms(5);
        if (TXIF == 1) {         // despliego el mensaje de la variable "nota_6"
            TXREG = nota_6[i];
        }
        }
        cantidad = (((servo1 - 4)*180)/15) ; 
        unidades = 48; 
        decenas = 48; 
        centenas = 48; 
        while (cantidad >= 100) {
            cantidad = cantidad - 100; 
            centenas++; 
        }
        while (cantidad >= 10) {
            cantidad = cantidad - 10; 
            decenas++;     
        }
        if (cantidad < 10) {
            unidades = unidades + cantidad;
        }
        angulo[0] = centenas; 
        angulo[1] = decenas;
        angulo[2] = unidades;
        for (i = 0; i < strlen(angulo); i++) {
        __delay_ms(5);
        if (TXIF == 1) {         // despliego el mensaje de la variable "nota_6"
            TXREG = angulo[i];
        }
        }
        TXREG = '\n';          // hago dos saltos de linea para tener un espacio
        __delay_ms(5);         // vacio entre cada mensaje
        TXREG = '\n';
        
    break;
    
    case('2'):
        for (i = 0; i < strlen(nota_7); i++) {
        __delay_ms(5);
        if (TXIF == 1) {         // despliego el mensaje de la variable "nota_7"
            TXREG = nota_7[i];
        }
        }
        cantidad = (((servo2 - 4)*180)/15) ; 
        unidades = 48; 
        decenas = 48; 
        centenas = 48; 
        while (cantidad >= 100) {
            cantidad = cantidad - 100; 
            centenas++; 
        }
        while (cantidad >= 10) {
            cantidad = cantidad - 10; 
            decenas++;     
        }
        if (cantidad < 10) {
            unidades = unidades + cantidad;
        }
        angulo[0] = centenas; 
        angulo[1] = decenas;
        angulo[2] = unidades;
        for (i = 0; i < strlen(angulo); i++) {
        __delay_ms(5);
        if (TXIF == 1) {         // despliego el mensaje de la variable "nota_6"
            TXREG = angulo[i];
        }
        }
        TXREG = '\n';          // hago dos saltos de linea para tener un espacio
        __delay_ms(5);         // vacio entre cada mensaje
        TXREG = '\n';
    break; 
    
    case('3'):
        for (i = 0; i < strlen(nota_8); i++) {
        __delay_ms(5);
        if (TXIF == 1) {         // despliego el mensaje de la variable "nota_8"
            TXREG = nota_8[i];
        }
        }
        cantidad = (((servo3 - 4)*180)/15) ; 
        unidades = 48; 
        decenas = 48; 
        centenas = 48; 
        while (cantidad >= 100) {
            cantidad = cantidad - 100; 
            centenas++; 
        }
        while (cantidad >= 10) {
            cantidad = cantidad - 10; 
            decenas++;     
        }
        if (cantidad < 10) {
            unidades = unidades + cantidad;
        }
        angulo[0] = centenas; 
        angulo[1] = decenas;
        angulo[2] = unidades;
        for (i = 0; i < strlen(angulo); i++) {
        __delay_ms(5);
        if (TXIF == 1) {         // despliego el mensaje de la variable "nota_6"
            TXREG = angulo[i];
        }
        }
        TXREG = '\n';          // hago dos saltos de linea para tener un espacio
        __delay_ms(5);         // vacio entre cada mensaje
        TXREG = '\n';
   break;
   
    case('4'):
        for (i = 0; i < strlen(nota_9); i++) {
        __delay_ms(5);
        if (TXIF == 1) {         // despliego el mensaje de la variable "nota_8"
            TXREG = nota_9[i];
        }
        }
        if (direccion == 1) {
            for (i = 0; i < strlen(right); i++) {
            __delay_ms(5);
            if (TXIF == 1) {        // despliego el mensaje de la variable RIGHT
                TXREG = right[i];
            }
            }
        }
        else {
            for (i = 0; i < strlen(left); i++) {
            __delay_ms(5);
            if (TXIF == 1) {        // despliego el mensaje de la variable LEFT
                TXREG = left[i];
            }
            }
        }
        TXREG = '\n';          // hago dos saltos de linea para tener un espacio
        __delay_ms(5);         // vacio entre cada mensaje
        TXREG = '\n';
        for (i = 0; i < strlen(cambio); i++) {
            __delay_ms(5);
            if (TXIF == 1) {        // despliego el mensaje de la variable LEFT
                TXREG = cambio[i];
        }
        }
        
        TXREG = '\n';          // hago dos saltos de linea para tener un espacio
        __delay_ms(5);         // vacio entre cada mensaje
        TXREG = '\n';
        
        while (RCIF == 0) ; // me quedo quieto hasta recibir una señal 
        valor = RCREG;   // recibo los datos y los paso a la variable "valor"
        
        if (valor == '1') {
            for (i = 0; i < strlen(giro); i++) {
                __delay_ms(5);
                if (TXIF == 1) {        // despliego el mensaje de la variable LEFT
                    TXREG = giro[i];
            }
            }
            
            TXREG = '\n';          // hago dos saltos de linea para tener un espacio
            __delay_ms(5);         // vacio entre cada mensaje
            TXREG = '\n';
            
            while (RCIF == 0) ; // me quedo quieto hasta recibir una señal 
            valor = RCREG;   // recibo los datos y los paso a la variable "valor"
            if (valor == '1') {
                CCP1CONbits.P1M = 0b01; //horario
                RD0 = 1; 
                RD1 = 0;
            }
            else {
                CCP1CONbits.P1M = 0b11; //ante-horario
                RD0 = 0; 
                RD1 = 1;
            }
        }
   break;   
}

}
return;    
}


