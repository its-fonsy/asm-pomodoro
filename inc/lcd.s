
lcd_update:	push	r16

		; set cursor row 0, col 0
		ldi	r16,(1<<7)
		rcall	HD44780U_inst

		; print cnt value
		lds	r16,cnt
		rcall	LCD_print_int

		; reset tim2 overflow counter variable
		clr	r16
		sts	tim2_ow_cnt,r16

		; reset the device flag
		lds	r16,dev_state
		andi	r16,~(1 << LCD_UPDATE_BIT)
		sts	dev_state,r16

		pop r16

		ret

LCD_init:	rcall	TIM2_init
		rcall	HD44780U_init
		ret

; print the string NULL terminated that starts in address ZH,ZL
LCD_print_string:
		push	r16
		lpm	r16,Z+
		cpi	r16,NULL
		breq	string_end
		rcall	LCD_print_char
		rjmp	LCD_print_string
string_end:	pop	r16
		ret

; print the char (in ASCII code) in r16
LCD_print_char: push	r17
		rcall	HD44780U_wait			; wait busy flag
		ldi	r17,(1<<HD44780U_RS_PIN)
		rcall	HD4478U_send_byte		; send char to HD44780U
		cbi	HD44780U_PORT,HD44780U_RS_PIN	; reset RS
		pop	r17
		ret

; print the number inside r16
LCD_print_int:	ori	r16,0x30	; convert number to ASCII digit
		rjmp	LCD_print_char

; Configure Timer2 to refresh the display
TIM2_init:	ldi	r16,(1<<TOIE2)
		sts	TIMSK2,r16				; Enable interrupt on overflow
		ldi	r16,(1<<CS22)|(1<<CS21)|(1<<CS20)
		sts	TCCR2B,r16				; Set prescaler 1024
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

set_disp_flag:	lds	r16,dev_state
		ori	r16,(1<<LCD_UPDATE_BIT)
		sts	dev_state,r16
		clr	r16
		sts	tim2_ow_cnt,r16
		pop	r16
		reti

		.include "hd44780u.s"
