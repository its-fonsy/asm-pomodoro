		.include "m328pdef.inc"
		.macro	UNUSED_INT
		reti
		nop
		.endmacro

		.equ	DISPLAY_FLAG = 0
		.equ	BTN0_PRESSED_FLAG = 1
		.equ	BTN1_PRESSED_FLAG = 2

		; Button FSM states
		.equ	BTN_STATE_RELEASED_BIT = 0
		.equ	BTN_STATE_WAIT_STABLE_PRESS_BIT = 1
		.equ	BTN_STATE_WAIT_STABLE_RELEASE_BIT = 2
		.equ	BTN_FSM_BIT = 3

		; ASCII char
		.equ NULL		= 0x00
		.equ NEW_LINE		= 0x0A
		.equ CR			= 0x0D

		.dseg
		.org	SRAM_START
btn_fsm_state:	.byte	1
db_cnt:		.byte	1
cnt:		.byte	1

		.cseg
		.org	0x00
		jmp	RESET		; Reset Handler
		UNUSED_INT		; IRQ0 Handler
		UNUSED_INT		; IRQ1 Handler
		jmp	ISR_PCINT0	; PCINT0 Handler
		UNUSED_INT		; PCINT1 Handler
		UNUSED_INT		; PCINT2 Handler
		UNUSED_INT		; Watchdog Timer Handler
		UNUSED_INT		; Timer2 Compare A Handler
		UNUSED_INT		; Timer2 Compare B Handler
		UNUSED_INT		; Timer2 Overflow Handler
		UNUSED_INT		; Timer1 Capture Handler
		UNUSED_INT		; Timer1 Compare A Handler
		UNUSED_INT		; Timer1 Compare B Handler
		UNUSED_INT		; Timer1 Overflow Handler
		UNUSED_INT		; Timer0 Compare A Handler
		UNUSED_INT		; Timer0 Compare B Handler
		UNUSED_INT		; Timer0 Overflow Handler
		UNUSED_INT		; SPI Transfer Complete Handler
		UNUSED_INT		; USART, RX Complete Handler
		UNUSED_INT		; USART, UDR Empty Handler
		UNUSED_INT		; USART, TX Complete Handler
		UNUSED_INT		; ADC Conversion Complete Handler
		UNUSED_INT		; EEPROM Ready Handler
		UNUSED_INT		; Analog Comparator Handler
		UNUSED_INT		; 2-wire Serial Interface Handler
		UNUSED_INT		; Store Program Memory Ready Handler

		; initialize the stack
RESET:		ldi	r16,LOW(RAMEND)
		out	SPL,r16
		ldi	r16,HIGH(RAMEND)
		out	SPH,r16

		; reset variables
		ldi	r16,0
		sts	cnt,r16
		sts	btn_fsm_state,r16

		rcall	BTNS_init
		rcall	USART_init
		sei


main_loop:	lds	r16,btn_fsm_state

		sbrs	r16,BTN_STATE_RELEASED_BIT
		rcall	btn_fsm

		rjmp	main_loop

		.include "buttons.s"
		.include "uart.s"
