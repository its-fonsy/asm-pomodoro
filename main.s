		.include "m328pdef.inc"
		.macro	UNUSED_INT
		reti
		nop
		.endmacro

		.dseg
		.org	SRAM_START
cnt:		.byte	1
tim2_ow_cnt:	.byte	1

		.cseg
		.org	0x00
		jmp	RESET		; Reset Handler
		UNUSED_INT		; IRQ0 Handler
		UNUSED_INT		; IRQ1 Handler
		UNUSED_INT		; PCINT0 Handler
		UNUSED_INT		; PCINT1 Handler
		UNUSED_INT		; PCINT2 Handler
		UNUSED_INT		; Watchdog Timer Handler
		UNUSED_INT		; Timer2 Compare A Handler
		UNUSED_INT		; Timer2 Compare B Handler
		jmp 	TIM2_OVF	; Timer2 Overflow Handler
		UNUSED_INT		; Timer1 Capture Handler
		jmp 	TIM1_COMPA	; Timer1 Compare A Handler
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

RESET:		ldi	r16,'0'
		sts	cnt,r16

		ldi	r16,0
		sts	tim2_ow_cnt,r16

		out	DDRB,r21
		out	PORTB,r16
		nop

		rcall	lcd_init
		rcall	init_timers
		sei

		ldi	ZL,LOW(2*line_one)
		ldi	ZH,HIGH(2*line_one)
		rcall	lcd_print_string

		ldi	r16,40 + (1<<7)
		rcall	lcd_inst

		ldi	ZL,LOW(2*line_two)
		ldi	ZH,HIGH(2*line_two)
		rcall	lcd_print_string

main_loop:	lds	r16,tim2_ow_cnt
		cpi	r16,7
		brsh	print_num

		rjmp	main_loop

init_timers:
		; Configure Timer1
		ldi	r16,HIGH(15625)
		sts	OCR1AH,r16
		ldi	r16,LOW(15625)
		sts	OCR1AL,r16

		ldi	r16,(1<<OCIE1A)				; Enable compare match interrupt
		sts	TIMSK1,r16
		ldi	r16,(1<<WGM12)|(1<<CS12)|(1<<CS10)	; Configure Timer1 prescaler to 1024 and CTC mode
		sts	TCCR1B, r16

		; Configure Timer2
		ldi	r16,(1<<TOIE2)
		sts	TIMSK2,r16				; Enable interrupt on overflow
		ldi	r16,(1<<CS22)|(1<<CS21)|(1<<CS20)
		sts	TCCR2B,r16				; Set prescaler 1024

		ret

print_num:	ldi	r16,(1<<7)
		rcall	lcd_inst
		lds	r16,cnt
		rcall	lcd_print_char
		clr	r16
		sts	tim2_ow_cnt,r16
		rjmp	main_loop
		
; count 15 overflows, correspond to 245.76ms
TIM2_OVF:	push	r16
		lds	r16,tim2_ow_cnt
		inc	r16
		sts	tim2_ow_cnt,r16
		pop	r16
		reti

TIM1_COMPA:	push	r16
		lds	r16,cnt
		cpi	r16,'9'
		breq	reset_cnt
		inc	r16
		rjmp	timer_end
reset_cnt:	ldi	r16,'0'
timer_end:	sts	cnt,r16
		pop	r16
		reti

line_one:	.db	"                ",NULL,NULL
line_two:	.db	"Pefforza        ",NULL,NULL

		.include "lcd.s"
