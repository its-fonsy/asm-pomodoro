		; set PINB0 and PINB1 as input with pull-up resistors
BTNS_init:	ldi	r16,(1<<PINB5)
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

btn_fsm:	sbrc	r16,BTN_STATE_WAIT_STABLE_PRESS_BIT
		rjmp	btn_stable_press
		rjmp	btn_stable_release

btn_stable_press:
		lds	r17,btn_db_cnt
		sbrs	r16,BTN_FSM_BIT
		rjmp	wait_for_btn0_stable_press

		; wait for stable press of  BTN1
		sbis	PINB,1	
		inc	r17
		sts	btn_db_cnt,r17
		sbrs	r17,5
		ret
		rjmp	btn1_pressed

wait_for_btn0_stable_press:
		sbis	PINB,0
		inc	r17
		sts	btn_db_cnt,r17
		sbrs	r17,5
		ret

		; button 0 pressed
		lds	r17,cnt
		inc	r17
		rjmp	btn_pres_exit

btn1_pressed:	lds	r17,cnt
		dec	r17

btn_pres_exit:	sts	cnt,r17
		clr	r17		; reset debounce counter
		sts	btn_db_cnt,r17

		lds	r17,dev_state
		andi	r17,~(1 << BTN_STATE_WAIT_STABLE_PRESS_BIT)	; reset the wait for stable press flag
		ori	r17,(1 << BTN_STATE_WAIT_STABLE_RELEASE_BIT)	; set the wait for stable release flag
		sts	dev_state,r17

		ret

btn_stable_release:
		lds	r17,btn_db_cnt
		sbrs	r16,BTN_FSM_BIT
		rjmp	wait_for_btn0_stable_release

		; wait for stable press of  BTN1
		sbic	PINB,1	
		inc	r17
		sts	btn_db_cnt,r17
		sbrs	r17,4
		ret
		rjmp	btn_released

wait_for_btn0_stable_release:
		sbic	PINB,0
		inc	r17
		sts	btn_db_cnt,r17
		sbrs	r17,4
		ret
btn_released:	clr	r17
		sts	btn_db_cnt,r17	; reset debounce counter

		; update the device state variable
		lds	r17,dev_state
		andi	r17,~(1 << BTN_STATE_WAIT_STABLE_RELEASE_BIT)	; reset the wait for stable release flag
		ori	r17,(1 << BTN_STATE_RELEASED_BIT)		; set released flag
		sts	dev_state,r17

		ret

ISR_PCINT0:	push	r17		
		push	r16

		; check if a button has been already pressed
		lds	r17,dev_state	
		sbrc	r17,BTN_STATE_RELEASED_BIT	
		breq	update_btn_state

		; no button has been pressed, maybe here for BTN release or debounce, just exit
		rjmp	int_exit	

update_btn_state:
		; check which button has been pressed and set accordingly the flag
		andi	r17,~(1<<BTN_FSM_BIT)
		sbic	PINB,0
		ori	r17,(1<<BTN_FSM_BIT)

		ori	r17,(1<<BTN_STATE_WAIT_STABLE_PRESS_BIT)	; set the wait for stable release flag
		andi	r17,~(1<<BTN_STATE_RELEASED_BIT)		; reset released flag
		sts	dev_state,r17

int_exit:	pop	r16
		pop	r17
		reti

