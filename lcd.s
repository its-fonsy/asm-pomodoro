	.equ LCD_DDR		= DDRD
	.equ LCD_PORT		= PORTD
	.equ LCD_PIN		= PIND
	.equ LCD_RS_PIN		= 0
	.equ LCD_RW_PIN		= 1
	.equ LCD_EN_PIN		= 2
	.equ LCD_DB4_PIN	= 3
	.equ LCD_DB5_PIN	= 4
	.equ LCD_DB6_PIN	= 5
	.equ LCD_DB7_PIN	= 6
	.equ NULL		= 0x00
	.equ NEW_LINE		= 0x0A
	.equ CR			= 0x0D

	; LCD PORT ? DB7 DB6 DB5 DB4 EN RS RW
	;          7  6   5   4   3   2  1  0

lcd_clear:
	ldi	r16,0b00000001	; clear display
	ldi	r17,0x00
	rcall	lcd_inst
	ret

lcd_print_string:
	lpm	r16,Z+
	cpi	r16,NULL
	breq	string_end
	rcall	lcd_print_char
	rjmp	lcd_print_string
string_end:
	ret
	
; r16 has the instruction, r17 the RS,RW
lcd_send_byte:
	mov	r18,r16		; copy content of r16

	; send the 4 MSB
	swap	r16
	andi	r16,0x0F
	lsl	r16
	lsl	r16
	lsl	r16
	or	r16, r17
	out	LCD_PORT,r16
	rcall	lcd_tog_en

	; send the 4 LSB
	andi	r18,0x0F
	lsl	r18
	lsl	r18
	lsl	r18
	or	r18, r17
	out	LCD_PORT,r18
	rcall	lcd_tog_en

	ret

lcd_inst:
	rcall	lcd_wait	; wait busy flag
	clr	r17		; for every inst. RS=RW=E=0
	rcall	lcd_send_byte	; send byte to LCD
	ret
	
lcd_print_char:
	rcall	lcd_wait		; wait busy flag
	ldi	r17,(1<<LCD_RS_PIN)
	rcall	lcd_send_byte		; send char to LCD
	cbi	LCD_PORT,LCD_RS_PIN	; reset RS
	ret

lcd_wait:
	ldi	r17,0b00000111		; set RW,EN,RS as output, DB as input
	ldi	r18,0b00000010		; set RW pin, clear E and RS
	out	LCD_DDR,r17
	out	LCD_PORT,r18
	nop
lcd_busy:
	rcall	lcd_tog_en		; toggle E to read 4 MSB from LCD
	in	r17,LCD_PIN		; save them to r17
	rcall	lcd_tog_en		; toggle E to load 4 LSB (don't need them)
	andi	r17,(1<<LCD_DB7_PIN)	; check busy flag
	brne	lcd_busy		; if busy flag is 0 then repeat

	; set back LCD DATA pin as output
	ldi	r17,0xFF
	ldi	r18,0x00
	out	LCD_DDR,r17
	out	LCD_PORT,r18
	nop

	ret

lcd_tog_en:
	sbi	LCD_PORT,LCD_EN_PIN
	push	r16	; waste 4 cycle
	pop	r16
	cbi	LCD_PORT,LCD_EN_PIN
	ret

lcd_init:
	; set LCD_PORT as output
	; and clear all pins
	ldi	r16,0xFF
	ldi	r17,0x00
	out	LCD_DDR,r16
	out	LCD_PORT,r16
	nop

	; wait 15ms
	ldi	r16,250
init_del_out_loop:
	ldi	r17,239
	nop
init_del_inn_loop:
	dec	r17
	nop
	brne	init_del_inn_loop
	dec	r16
	brne	init_del_out_loop
	nop

	; initialize the LCD
	ldi	r16,0b00010000
	out	LCD_PORT,r16
	rcall	lcd_tog_en

	ldi	r16,0b00101000	; 4-bit on, 2 lines, 8x5 dots
	rcall	lcd_inst

	ldi	r16,0b00001100	; display on, curson off, blink off
	rcall	lcd_inst

	ldi	r16,0b00000110	; set address increment, and display shift off
	rcall	lcd_inst

	rcall	lcd_clear

	ret
