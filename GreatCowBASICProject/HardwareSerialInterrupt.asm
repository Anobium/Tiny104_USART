;Program compiled by Great Cow BASIC (0.98.<<>> 2020-07-07 (Windows 64 bit))
;Need help? See the GCBASIC forums at http://sourceforge.net/projects/gcbasic/forums,
;check the documentation or email w_cholmondeley at users dot sourceforge dot net.

;********************************************************************************

;Chip Model: TINY104
;Assembler header file
.INCLUDE "tn104def.inc"

;SREG bit names (for AVR Assembler compatibility, GCBASIC uses different names)
#define C 0
#define H 5
#define I 7
#define N 2
#define S 4
#define T 6
#define V 3
#define Z 1

;********************************************************************************

;Set aside memory locations for variables
.EQU	SAVESREG=64
.EQU	SAVESYSTEMP1=65
.EQU	SAVESYSVALUECOPY=66
.EQU	SERDATA=67

;********************************************************************************

;Register variables
.DEF	SYSVALUECOPY=r21
.DEF	SYSTEMP1=r16
.DEF	SYSTEMP2=r17

;********************************************************************************

;Vectors
;Interrupt vectors
.ORG	0
	rjmp	BASPROGRAMSTART ;Reset
.ORG	1
	reti	;INT0
.ORG	2
	reti	;PCINT0
.ORG	3
	reti	;PCINT1
.ORG	4
	reti	;TIM0_CAPT
.ORG	5
	reti	;TIM0_OVF
.ORG	6
	reti	;TIM0_COMPA
.ORG	7
	reti	;TIM0_COMPB
.ORG	8
	reti	;ANA_COMP
.ORG	9
	reti	;WDT
.ORG	10
	reti	;VLM
.ORG	11
	reti	;ADC
.ORG	12
	reti	;USART_RXS
.ORG	13
	rjmp	IntUSART_RXC ;USART_RXC
.ORG	14
	reti	;USART_UDRE
.ORG	15
	reti	;USART_TX

;********************************************************************************

;Start of program memory page 0
.ORG	17
BASPROGRAMSTART:
;Initialise stack
	ldi	SysValueCopy,high(RAMEND)
	out	SPH, SysValueCopy
	ldi	SysValueCopy,low(RAMEND)
	out	SPL, SysValueCopy
;Call initialisation routines
	rcall	INITSYS
	rcall	INITUSART
;Enable interrupts
	sei

;Start of the main program
;''A demonstration program for GCB
;''---------------------------------------------------------------------------------
;'' This program shows how to use hardware serialto receive and set the port
;''
;''
;''@author  Evan Venn
;''@licence GPL
;''@version 1.0
;''@date    03/07/2020
;''********************************************************************************
;Start of board specific configuration
;Adjust Oscillator frequency to ensure operation of Serial, if required
;OSCCAL = OSCCAL - 5
	in	SysTemp1,OSCCAL
	ldi	SysTemp2,5
	sub	SysTemp1,SysTemp2
	out	OSCCAL,SysTemp1
;#Define SWITCH  portb.1
;#Define LED     porta.5
;Set Internal Pullup for SWITCH port
;PUEB.PORTB1 = 1
	sbi	PUEB,PORTB1
;Set direction of Switch
;Dir SWITCH in
	cbi	DDRB,1
;Use Volatile to ensure the compiler does not try to optimize the code
;Set direction of LED
;Dir LED out
	sbi	DDRA,5
;LED = 0
	cbi	PORTA,5
;USART settings for USART1
;#define USART_BAUD_RATE 9600
;#define USART_TX_BLOCKING
;End of board specific configuration
;----- Variables
;See inline
;----- Main body of program commences here.
;Configure the Data Direction Register for Port A
;Dir PortA OUT
	ldi	SysValueCopy,255
	out	DDRA,SysValueCopy
;Now that data direction is established, enable the pins.
;Turn off all pins in PORTA by default.
;NOTE: On Xplained Nano board, the built-in LED on PA5 follows
;reverse logic: setting the bit to 0 turns ON the LED and setting
;it to 1 turns OFF the LED. I have no earthly idea why. So, the
;built-in LED on the Xplained Nano board will be lit by default
;after all pins in the port are set to "off" (0000 0000, a.k.a. 0x00).
;PORTA = 0xff
	ldi	SysValueCopy,255
	out	PORTA,SysValueCopy
;USART Receive Completed interrupt call
;On Interrupt UsartRX1Ready call ISR
	in	SysValueCopy,UCSRB
	sbr	SysValueCopy,1<<RXCIE
	out	UCSRB,SysValueCopy
;Loop forever, do nothing. Interrupts handle everything now.
;See the ISR() interrupt handler below for the actions taken when
;the interrupt is triggered.
;USART Receive Complete interrupt stuff
;Do
SysDoLoop_S1:
;Loop
	rjmp	SysDoLoop_S1
SysDoLoop_E1:
;Handler for the USART Receive Complete interrupt.
BASPROGRAMEND:
	sleep
	rjmp	BASPROGRAMEND

;********************************************************************************

;Source: usart.h (1492)
HSERSENDRC:
;AVR USART1 Send
;Wait While UDRE = Off
SysWaitLoop1:
	sbis	UCSRA,UDRE
	rjmp	SysWaitLoop1
;UDR = SerData
	lds	SysValueCopy,SERDATA
	out	UDR,SysValueCopy
	ret

;********************************************************************************

;Source: system.h (109)
INITSYS:
;Set the AVR frequency for chipfamily 121 - assumes internal OSC
;Only sets internal therfore is 12mhz, the default setting is selected, NO OSC will be set.
;Unlock the  frequency register where 0xD8 is the correct signature for the AVRrc chips
;CCP = 0xD8            'signature to CCP
	ldi	SysValueCopy,216
	out	CCP,SysValueCopy
;CLKMSR = 0            'use clock 00: Calibrated Internal 8 MHzOscillator
	ldi	SysValueCopy,0
	out	CLKMSR,SysValueCopy
;CCP = 0xD8            'signature to CCP
	ldi	SysValueCopy,216
	out	CCP,SysValueCopy
;CLKPSR = 0            '8mhz
	ldi	SysValueCopy,0
	out	CLKPSR,SysValueCopy
;Turn off all ports
;PORTA = 0
	ldi	SysValueCopy,0
	out	PORTA,SysValueCopy
;PORTB = 0
	ldi	SysValueCopy,0
	out	PORTB,SysValueCopy
	ret

;********************************************************************************

;Source: usart.h (482)
INITUSART:
;Set baud rate
;U2X = U2X0_TEMP       'Set/Clear bit to double USART transmission speed
	in	SysValueCopy,UCSRA
	sbr	SysValueCopy,1<<U2X
	out	UCSRA,SysValueCopy
;UBRRL = UBRRL_TEMP
	ldi	SysValueCopy,103
	out	UBRRL,SysValueCopy
;UBRRH = UBRRH_TEMP
	ldi	SysValueCopy,0
	out	UBRRH,SysValueCopy
;Enable TX and RX
;RXEN = On
	in	SysValueCopy,UCSRB
	sbr	SysValueCopy,1<<RXEN
	out	UCSRB,SysValueCopy
;TXEN = On
	in	SysValueCopy,UCSRB
	sbr	SysValueCopy,1<<TXEN
	out	UCSRB,SysValueCopy
	ret

;********************************************************************************

;Source: HardwareSerialInterrupt.gcb (70)
ISR:
;Dim Serdata
;Read input from USART, and
;Turn components on/off based on bits in the received byte.
;Whatever we get from the user, push that into PORTA. The 8 bits
;in the byte map perfectly with the 8 bits in PORTA. Components
;connected with the PORTA pins (if any) should turn on/off based on
;how the bits in the cmd byte were set.
;Get and return received data from buffer using a sub to reduce code size. Using the variable Serdat aalso reduces the RAM used.
;SerData = UDR
	in	SysValueCopy,UDR
	sts	SERDATA,SysValueCopy
;Invert the bits so, bit 4 = d32 to set the LED.
;PORTA = !Serdata
	lds	SysTemp1,SERDATA
	com	SysTemp1
	out	PORTA,SysTemp1
;Optionally, return the value back to the terminal
;HSerSend Serdata
	rjmp	HSERSENDRC

;********************************************************************************

IntUSART_RXC:
	rcall	SysIntContextSave
	rcall	ISR
	in	SysValueCopy,UCSRA
	cbr	SysValueCopy,1<<RXC
	out	UCSRA,SysValueCopy
	rjmp	SysIntContextRestore

;********************************************************************************

SysIntContextRestore:
;Restore registers
	lds	SysTemp1,SaveSysTemp1
;Restore SREG
	lds	SysValueCopy,SaveSREG
	out	SREG,SysValueCopy
;Restore SysValueCopy
	lds	SysValueCopy,SaveSysValueCopy
	reti

;********************************************************************************

SysIntContextSave:
;Store SysValueCopy
	sts	SaveSysValueCopy,SysValueCopy
;Store SREG
	in	SysValueCopy,SREG
	sts	SaveSREG,SysValueCopy
;Store registers
	sts	SaveSysTemp1,SysTemp1
	ret

;********************************************************************************


