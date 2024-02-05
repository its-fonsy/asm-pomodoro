		.include "m328pdef.inc"

		.dseg
		.org	SRAM_START
cnt:		.byte	1
tim2_ow_cnt:	.byte	1

		.cseg
		.org	0x00
		jmp RESET	; Reset Handler
		jmp EXT_INT0	; IRQ0 Handler
		jmp EXT_INT1	; IRQ1 Handler
		jmp _PCINT0	; PCINT0 Handler
		jmp _PCINT1	; PCINT1 Handler
		jmp _PCINT2	; PCINT2 Handler
		jmp WDT		; Watchdog Timer Handler
		jmp TIM2_COMPA	; Timer2 Compare A Handler
		jmp TIM2_COMPB	; Timer2 Compare B Handler
		jmp TIM2_OVF	; Timer2 Overflow Handler
		jmp TIM1_CAPT	; Timer1 Capture Handler
		jmp TIM1_COMPA	; Timer1 Compare A Handler
		jmp TIM1_COMPB	; Timer1 Compare B Handler
		jmp TIM1_OVF	; Timer1 Overflow Handler
		jmp TIM0_COMPA	; Timer0 Compare A Handler
		jmp TIM0_COMPB	; Timer0 Compare B Handler
		jmp TIM0_OVF	; Timer0 Overflow Handler
		jmp SPI_STC	; SPI Transfer Complete Handler
		jmp USART_RXC	; USART, RX Complete Handler
		jmp USART_UDRE	; USART, UDR Empty Handler
		jmp USART_TXC	; USART, TX Complete Handler
		jmp ADC		; ADC Conversion Complete Handler
		jmp EE_RDY	; EEPROM Ready Handler
		jmp ANA_COMP	; Analog Comparator Handler
		jmp TWI		; 2-wire Serial Interface Handler
		jmp SPM_RDY	; Store Program Memory Ready Handler

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

EXT_INT0:	reti
EXT_INT1:	reti
_PCINT0:	reti
_PCINT1:	reti
_PCINT2:	reti
WDT:		reti
TIM2_COMPA:	reti
TIM2_COMPB:	reti
;TIM2_OVF:  	reti
TIM1_CAPT: 	reti
;TIM1_COMPA:	reti
TIM1_COMPB:	reti
TIM1_OVF:  	reti
TIM0_COMPA:	reti
TIM0_COMPB:	reti
TIM0_OVF:  	reti
SPI_STC:   	reti
USART_RXC: 	reti
USART_UDRE:	reti
USART_TXC: 	reti
ADC:		reti
EE_RDY:		reti
ANA_COMP:	reti
TWI:		reti
SPM_RDY:	reti

		.include "lcd.s"
