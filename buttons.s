		; set PINB0 and PINB1 as input with pull-up resistors
init_int:	clr	r16
		ldi	r17,(1<<PINB0)|(1<<PINB1)
		out	DDRB,r16
		out	PORTB,r17
		nop

		; set PINB0 and PINB1 to trigger the interrupt
		ldi	r16,(1<<PCIE0)
		ldi	r17,(1<<PCINT0)|(1<<PCINT1)
		sts	PCMSK0,r17
		sts	PCICR,r16

		ret
