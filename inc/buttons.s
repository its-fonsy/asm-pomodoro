		; set PINB0 and PINB1 as input with pull-up resistors
BTNS_init:	clr	r16
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
		lds	r17,db_cnt
		sbrs	r16,BTN_FSM_BIT
		rjmp	wait_for_btn0_stable_press

		; wait for stable press of  BTN1
		sbis	PINB,1	
		inc	r17
		sts	db_cnt,r17
		sbrs	r17,5
		ret
		rjmp	btn1_pressed

wait_for_btn0_stable_press:
		sbis	PINB,0
		inc	r17
		sts	db_cnt,r17
		sbrs	r17,5
		ret
		rjmp	btn0_pressed

btn0_pressed:	ldi	ZL,LOW(2*btn0_db_msg)
		ldi	ZH,HIGH(2*btn0_db_msg)
		rcall	USART_tx_str
		rjmp	btn_pres_exit

btn1_pressed:	ldi	ZL,LOW(2*btn1_db_msg)
		ldi	ZH,HIGH(2*btn1_db_msg)
		rcall	USART_tx_str
		rjmp	btn_pres_exit

		; reset debounce counter
btn_pres_exit:	clr	r17
		sts	db_cnt,r17

		; unset the pressed button0 flag
		ldi	r17,(1 << BTN_STATE_WAIT_STABLE_RELEASE_BIT)
		sbrc	r16,BTN_FSM_BIT
		ldi	r17,(1 << BTN_STATE_WAIT_STABLE_RELEASE_BIT) | (1 << BTN_FSM_BIT)
		sts	btn_fsm_state,r17

		ret

btn_stable_release:
		lds	r17,db_cnt
		sbrs	r16,BTN_FSM_BIT
		rjmp	wait_for_btn0_stable_release

		; wait for stable press of  BTN1
		sbic	PINB,1	
		inc	r17
		sts	db_cnt,r17
		sbrs	r17,4
		ret
		rjmp	btn1_released

wait_for_btn0_stable_release:
		sbic	PINB,0
		inc	r17
		sts	db_cnt,r17
		sbrs	r17,4
		ret
		rjmp	btn0_released

btn0_released:	ldi	ZL,LOW(2*btn0_rel_msg)
		ldi	ZH,HIGH(2*btn0_rel_msg)
		rcall	USART_tx_str
		rjmp	btn_released

btn1_released:	ldi	ZL,LOW(2*btn1_rel_msg)
		ldi	ZH,HIGH(2*btn1_rel_msg)
		rcall	USART_tx_str
		rjmp	btn_released

btn_released:	ldi	r16,NEW_LINE
		rcall	USART_tx_byte

		; reset debounce counter
		clr	r17
		sts	db_cnt,r17

		; unset the pressed button flag
		ldi	r17,(1 << BTN_STATE_RELEASED_BIT )
		sts	btn_fsm_state,r17

		ret

ISR_PCINT0:	push	r17		
		push	r16

		; check if a button has been already pressed
		lds	r17,btn_fsm_state	
		sbrc	r17,BTN_STATE_RELEASED_BIT	
		breq	update_btn_state

		; no button has been pressed, maybe here for BTN release or debounce, just exit
		rjmp	int_exit	

update_btn_state:
		ldi	r17,(1<<BTN_STATE_WAIT_STABLE_PRESS_BIT)
		sbic	PINB,0
		ori	r17,(1<<BTN_FSM_BIT)
		sts	btn_fsm_state,r17

		sbic	PINB,0
		rjmp	int_b1_uart
		rjmp	int_b0_uart

		; send USART message
int_b0_uart:	ldi	ZL,LOW(2*btn0_isr_msg)
		ldi	ZH,HIGH(2*btn0_isr_msg)
		rcall	USART_tx_str
		rjmp	int_exit

int_b1_uart:	ldi	ZL,LOW(2*btn1_isr_msg)
		ldi	ZH,HIGH(2*btn1_isr_msg)
		rcall	USART_tx_str

int_exit:	pop	r16
		pop	r17
		reti

btn0_isr_msg:	.db	"B0: RL 2 WP", NEW_LINE, CR, NULL
btn0_db_msg:	.db	"B0: WP 2 WR", NEW_LINE, CR, NULL
btn0_rel_msg:	.db	"B0: WR 2 RL", NEW_LINE, CR, NULL

btn1_isr_msg:	.db	"B1: RL 2 WP", NEW_LINE, CR, NULL
btn1_db_msg:	.db	"B1: WP 2 WR", NEW_LINE, CR, NULL
btn1_rel_msg:	.db	"B1: WR 2 RL", NEW_LINE, CR, NULL
