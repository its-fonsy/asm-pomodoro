		.equ HD44780U_DDR	= DDRD
		.equ HD44780U_PORT	= PORTD
		.equ HD44780U_PIN	= PIND
		.equ HD44780U_RS_PIN	= 0
		.equ HD44780U_RW_PIN	= 1
		.equ HD44780U_EN_PIN	= 2
		.equ HD44780U_DB4_PIN	= 3
		.equ HD44780U_DB5_PIN	= 4
		.equ HD44780U_DB6_PIN	= 5
		.equ HD44780U_DB7_PIN	= 6

		; HD44780U PORT ? DB7 DB6 DB5 DB4 EN RS RW
		;          7  6   5   4   3   2  1  0


HD44780U_clear:	ldi	r16,0b00000001	; clear display
		ldi	r17,0x00
		rcall	HD44780U_inst
		ret

; Write the byte inside r16 to the HD4478U
; reg used: r16, r17, r18
HD4478U_send_byte:
		push	r18

		; copy content of r16
		mov	r18,r16		

		; send the 4 MSB
		swap	r16
		andi	r16,0x0F
		lsl	r16
		lsl	r16
		lsl	r16
		or	r16, r17
		out	HD44780U_PORT,r16
		rcall	HD44780U_toggle_en

		; send the 4 LSB
		andi	r18,0x0F
		lsl	r18
		lsl	r18
		lsl	r18
		or	r18, r17
		out	HD44780U_PORT,r18
		rcall	HD44780U_toggle_en

		pop	r18

		ret

HD44780U_inst:	rcall	HD44780U_wait	; wait busy flag
		clr	r17		; for every inst. RS=RW=E=0
		rcall	HD4478U_send_byte	; send byte to HD44780U
		ret
		

HD44780U_wait:	ldi	r17,0b00000111		; set RW,EN,RS as output, DB as input
		ldi	r18,0b00000010		; set RW pin, clear E and RS
		out	HD44780U_DDR,r17
		out	HD44780U_PORT,r18
		nop
HD44780U_busy:	rcall	HD44780U_toggle_en		; toggle E to read 4 MSB from HD44780U
		in	r17,HD44780U_PIN		; save them into r17
		rcall	HD44780U_toggle_en		; toggle E to load 4 LSB (don't need them)
		andi	r17,(1<<HD44780U_DB7_PIN)	; check busy flag
		brne	HD44780U_busy			; if busy flag is 0 then repeat

		; set back HD44780U DATA pin as output
		ldi	r17,0xFF
		ldi	r18,0x00
		out	HD44780U_DDR,r17
		out	HD44780U_PORT,r18
		nop

		ret

HD44780U_toggle_en:
		sbi	HD44780U_PORT,HD44780U_EN_PIN	; set EN pin high
		push	r16				; waste 2 cycle
		pop	r16				; waste 2 cycle
		cbi	HD44780U_PORT,HD44780U_EN_PIN	; set EN pin low
		ret

HD44780U_init:	ldi	r16,0xFF		; set HD44780U_PORT as output
		ldi	r17,0x00		; clear all pins
		out	HD44780U_DDR,r16
		out	HD44780U_PORT,r16
		nop

		; wait 15ms
		ldi	r16,250
HD44780U_loop1: ldi	r17,239
		nop
HD44780U_loop2: dec	r17
		nop
		brne	HD44780U_loop2
		dec	r16
		brne	HD44780U_loop1
		nop

		; initialize the HD44780U
		ldi	r16,0b00010000
		out	HD44780U_PORT,r16
		rcall	HD44780U_toggle_en

		ldi	r16,0b00101000	; 4-bit on, 2 lines, 8x5 dots
		rcall	HD44780U_inst

		ldi	r16,0b00001100	; display on, curson off, blink off
		rcall	HD44780U_inst

		ldi	r16,0b00000110	; set address increment, and display shift off
		rcall	HD44780U_inst

		rcall	HD44780U_clear

		ret
