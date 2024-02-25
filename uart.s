		.equ	F_CPU = 16000000
		.equ	BAUD  = 9600
		.equ	BRC   = ( (F_CPU / 16 / BAUD) - 1 )


; Example of usage
;	; transmit 'Hello'
;	ldi	ZL,LOW(2*str)
;	ldi	ZH,HIGH(2*str)
;	rcall	USART_tx_str
;
;str:	.db	"Hello", 0x0A, 0x0D, 0x00	

		rjmp	main

USART_tx_str:	lpm	r16,Z+
		cpi	r16,0x00
		breq	USART_ret
		rcall	USART_tx_byte
		rjmp	USART_tx_str
USART_ret:	ret

USART_init:	; init the USART
		ldi	r16,LOW(BRC)
		ldi	r17,HIGH(BRC)
		; Set baud rate
		sts	UBRR0H,r17
		sts	UBRR0L,r16
		; Enable receiver and transmitter
		ldi	r16,(1<<TXEN0)
		sts	UCSR0B,r16
		; Set frame format: 8data, 1-bit stop
		ldi	r16, (3<<UCSZ00)
		sts	UCSR0C,r16
		ret

; transmit the byte in r16
USART_tx_byte:	; Wait for empty transmit buffer
		lds	r17,UCSR0A
		sbrs	r17,UDRE0
		rjmp	USART_tx_byte
		; Put data (r16) into buffer, sends the data
		sts	UDR0,r16
		ret
