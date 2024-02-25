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

btn_fsm:	sbrc	r16,BTN_STATE_WAIT_STABLE_PRESS_BIT
		rjmp	btn_stable_press
		rjmp	btn_stable_release

btn_stable_press:
		lds	r17,db_cnt
		sbis	PINB,0
		inc	r17
		sts	db_cnt,r17

		sbrs	r17,5	; count to 16 = 2^5
		ret

		; BTN0 has been denounced

		; send USART message
		ldi	ZL,LOW(2*btn_db_msg)
		ldi	ZH,HIGH(2*btn_db_msg)
		rcall	USART_tx_str

		; reset debounce counter
		clr	r17
		sts	db_cnt,r17

		; unset the pressed button0 flag
		ldi	r17,(1 << BTN_STATE_WAIT_STABLE_RELEASE_BIT)
		sts	btn_fsm_state,r17

		ret

btn_stable_release:
		lds	r17,db_cnt
		sbic	PINB,0
		inc	r17
		sts	db_cnt,r17

		sbrs	r17,5	; count to 16 = 2^5
		ret

		; BTN0 has released

		; send USART message
		ldi	ZL,LOW(2*btn_rel_msg)
		ldi	ZH,HIGH(2*btn_rel_msg)
		rcall	USART_tx_str

		ldi	r16,NEW_LINE
		rcall	USART_tx_byte

		; reset debounce counter
		clr	r17
		sts	db_cnt,r17

		; unset the pressed button0 flag
		ldi	r17,(1 << BTN_STATE_RELEASED_BIT )
		sts	btn_fsm_state,r17

		ret

ISR_PCINT0:	push	r17		
		push	r16

		; save the status of the PORTB
		in	r16,PINB	

		; check if a button has been already pressed
		lds	r17,btn_fsm_state	
		sbrc	r17,BTN_STATE_RELEASED_BIT	
		breq	update_btn_state

		; no button has been pressed, maybe here for BTN release or debounce, just exit
		rjmp	int_exit	

update_btn_state:
		ldi	r17,(1<<BTN_STATE_WAIT_STABLE_PRESS_BIT)
		sts	btn_fsm_state,r17

		; send USART message
		ldi	ZL,LOW(2*btn_isr_msg)
		ldi	ZH,HIGH(2*btn_isr_msg)
		rcall	USART_tx_str

int_exit:	pop	r16
		pop	r17
		reti

btn_isr_msg:	.db	"B0: RL 2 WP", NEW_LINE, CR, NULL
btn_db_msg:	.db	"B0: WP 2 WR", NEW_LINE, CR, NULL
btn_rel_msg:	.db	"B0: WR 2 RL", NEW_LINE, CR, NULL

		.include "buttons.s"
		.include "uart.s"
