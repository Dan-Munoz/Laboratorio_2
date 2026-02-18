;
; Lab_2.asm
;
; Created: 17/02/2026 22:53:35
; Author : User
;



// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)
.cseg
.org 0x0000

// Configuración de la pila
	LDI  R16, LOW(RAMEND)
	OUT  SPL, R16
	LDI  R16, HIGH(RAMEND)
	OUT  SPH, R16
//Apagar UART RX/TX
	LDI  R16, 0x00
	STS  UCSR0B, R16 

// Table with values for 7-segment display (display 0, 1, 2, ....
table7seg: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

RJMP SETUP

SETUP:


	// Configurar B0-3 como salidas del contador de 4 bits
    LDI R16, 0b00001111     
    OUT DDRB, R16
	CLR	R16				// Poner en 0 las salidas
    OUT PORTB, R16

	// Configurar D0-D6 para display de 7 segmentos
	LDI R16, 0b01111111
	OUT DDRD, R16
	CLR R16				// Poner en 0 las salidas
	OUT PORTD, R16

	LDI	R16, 0b00000001
	OUT	DDRC, R16
	CLR	R16
	OUT PORTC, R16


    LDI R16, 0x00
    OUT TCCR0A, R16         ; modo normal
    LDI R16, 0b00000101
    OUT TCCR0B, R16         ; prescaler = 1024

    LDI R16, 98             ; 256 - 158
    OUT TCNT0, R16

	CLR	R16
	CLR R17
	CLR R18
	CLR R19
	CLR R20

LOOP:
	CALL CONTADOR
    CALL TIMER0
    RJMP LOOP

;================ TIMER0 10 ms =================
TIMER0:
ESPERAR:
    IN  R16, TIFR0
    SBRS R16, TOV0
    RJMP ESPERAR

    ; limpiar
    LDI R16, (1<<TOV0)
    OUT TIFR0, R16

    ; recargar timer
    LDI R16, 98
    OUT TCNT0, R16

    INC R17
    CPI R17, 100  
    BRNE FIN

	CLR R17
	INC R18
	
	// Comparar R18 (valor del contador de 4 bits) con R19 (valor del contador del display)
	MOV R16, R18
	CP R16, R19
	BRLO CONTINUA        ; si R18 < R19 sigue
	BREQ CONTINUA        ; si R18 == R19 sigue
	
	CLR R18              ; si R18 > R19 reiniciar

	// Toggle
	SBI PINC, 0
	
	CONTINUA:
	MOV R16, R18
	OUT PORTB, R16

FIN:
    RET

//*********************************************************************************************

CONTADOR:
	SBIC	PINC, 4			; Revisa si PinC4 está presionado (0) entonces incrementa R19
	RJMP	REVISAR		; Si no está presionado revisa el otro botón
	INC		R19

ESPERA_SUMA:	; Si PinC4 está presionado (0) espera a que se deje de presionar para mostrar el valor
	SBIS	PINC, 4	
	RJMP	ESPERA_SUMA
	RJMP	MOSTRAR

REVISAR:		; Revisa si PinC5 está presionado (0) entonces resta R19-1, si no solo muestra R19
	SBIC	PINC, 5
	RJMP	MOSTRAR
	DEC		R19

ESPERA_RESTA:	; Si PinC5 se presionó (0) espera a que se deje de presionar para mostrar el valor de R19
	SBIS	PINC, 5
	RJMP	ESPERA_RESTA

MOSTRAR:
	ANDI	R19, 0x0F		; Limitamos el contador a 15
	LDI		ZH, HIGH(Table7seg<<1)	// Cargamos a Z la primera dirección del Table7seg, donde se guardaron los valores del display
	LDI		ZL, LOW(Table7seg<<1)
	ADD		ZL, R19					// Sumar el valor del contador a Z para dirigir al valor del display deseado
	LPM		R20, Z					// Guardar el valor que está en la dirección Z en R20
	OUT		PORTD, R20	; Mostramos el valor del display en los bits de salida de PortD0-D6
	RET
