		.include "m328pdef.inc"
		.macro	UNUSED_INT
		reti
		nop
		.endmacro

		.equ	DISPLAY_FLAG = 0
		.equ	BTN0_PRESSED_FLAG = 1
		.equ	BTN1_PRESSED_FLAG = 2

		.dseg
		.org	SRAM_START
btn0_db_cnt:	.byte	1
btn1_db_cnt:	.byte	1
cnt:		.byte	1
tim2_ow_cnt:	.byte	1
flags:		.byte	1

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
		jmp 	TIM2_OVF	; Timer2 Overflow Handler
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
		sts	tim2_ow_cnt,r16
		sts	btn0_db_cnt,r16
		sts	btn1_db_cnt,r16
		sts	flags,r16

		rcall	lcd_init
		rcall	init_timers
		rcall	init_int
		rcall	UART_init
		sei


main_loop:	lds	r16,flags

		sbrc	r16,DISPLAY_FLAG
		rcall	print_num

		sbrc	r16,BTN0_PRESSED_FLAG
		rcall	btn0_pressed

		sbrc	r16,BTN1_PRESSED_FLAG
		rcall	btn1_pressed

		rjmp	main_loop

; Configure Timer2 to refresh the display
init_timers:	ldi	r16,(1<<TOIE2)
		sts	TIMSK2,r16				; Enable interrupt on overflow
		ldi	r16,(1<<CS22)|(1<<CS21)|(1<<CS20)
		sts	TCCR2B,r16				; Set prescaler 1024
		ret

print_num:	ldi	r16,(1<<7)
		rcall	lcd_inst
		lds	r16,cnt
		ori	r16,0x30	; convert number to ASCII digit
		rcall	lcd_print_char
		clr	r16
		sts	tim2_ow_cnt,r16
		ret
		
; count 15 overflows, correspond to 245.76ms
TIM2_OVF:	push	r16
		lds	r16,tim2_ow_cnt
		cpi	r16,7
		brsh	set_disp_flag
		inc	r16
		sts	tim2_ow_cnt,r16
		pop	r16
		reti

set_disp_flag:	lds	r16,flags
		ori	r16,(1<<DISPLAY_FLAG)
		sts	flags,r16
		clr	r16
		sts	tim2_ow_cnt,r16
		pop	r16
		reti

btn0_pressed:	lds	r17,btn0_db_cnt
		sbis	PINB,0
		inc	r17
		sts	btn0_db_cnt,r17

		cpi	r17,8
		brlo	btn0_ret

		; BTN0 has been denounced
		; increment the counter
		lds	r17,cnt
		inc	r17
		sts	cnt,r17

		; reset debounce counter
		clr	r17
		sts	btn0_db_cnt,r17

		; unset the pressed button0 flag
		lds	r17,flags
		andi	r17,~(1<<BTN0_PRESSED_FLAG)
		sts	flags,r17

btn0_ret:	ret

btn1_pressed:	lds	r17,btn1_db_cnt
		sbis	PINB,1
		inc	r17
		sts	btn1_db_cnt,r17

		cpi	r17,8
		brlo	btn1_ret

		; BTN1 has been denounced
		; decrement the counter
		lds	r17,cnt
		dec	r17
		sts	cnt,r17

		; reset debounce counter
		clr	r17
		sts	btn1_db_cnt,r17

		; unset the pressed button flag
		lds	r17,flags
		andi	r17,~(1<<BTN1_PRESSED_FLAG)
		sts	flags,r17

btn1_ret:	ret
		
	
; For the flags a 0 means the button is released, a 1 means it's pressed
;      BTN0 and BTN1 released: 0b0000000X
; BTN0 pressed, BTN1 released: 0b0000001X
; BTN0 released, BTN1 pressed: 0b0000010X

; The interrupt is triggered every rising or falling edge
; The flag are set on the rising edge
ISR_PCINT0:	push	r17		
		push	r16

		in	r16,PINB	; save the status of the PORTB

		; check if a button has been already pressed
		lds	r17,flags	
		lsr	r17
		breq	set_btn_flag	; flags set to zero means no button has been pressed

		; no button has been pressed, maybe here for BTN release or debounce, just exit
		rjmp	int_exit	

; since buttons have pull-up resistors reading 1 means they are released,
; otherwise a 0 means they arepressed. The flag variable works opposite way
; so we need to deal with that
set_btn_flag:	lsl	r17		; restore the DISPLAY_FLAG
		com	r16		; negate the PORTB status
		andi	r16,0x03	; mask the button bits
		lsl	r16		; left shift to align on the right bit position
		or	r16,r17		; update the flags variable
		sts	flags,r16

int_exit:	pop	r16
		pop	r17
		reti

line_one:	.db	"                ",NULL,NULL
line_two:	.db	"Pefforza        ",NULL,NULL

		.include "lcd.s"
		.include "buttons.s"
		.include "uart.s"
