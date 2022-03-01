.include "8515def.inc"


.def Temp = R16
.def control = r17 ; Control register
.def timL = r18; Loops the timer has to do 
.def button_pressed = r19;
.def car_pressed = r20;

.equ Yellow = 2
.equ Green = 1
.equ Red = 4
.equ Walk =8

.equ G_loops = 3;
.equ R_loops = 3;
.equ Y_loops = 1;
.equ W_loops = 1;

.equ Rtim0 = 55981; 
.equ Gtim0 = 36452
.equ Ytim0 = 53817
.equ Wtim0 = 26474

.org 0x0000
rjmp RESET
.org 0x0010
rjmp timer1
reti

RESET : 
	
	ldi temp,HIGH(RAMEND);init stack pointer
	out sph,temp
	ldi temp, LOW(RAMEND)
	out spl,temp

	;Set PORTB pins 0-6 as INPUTS

	ldi temp, 0b11000000
	out DDRB , temp
	com temp
	out PORTB , temp ; Set pull ups 

	
	;Ser potrd as output
	ldi temp,0xFF
	out DDRD,temp
	out PORTD,temp

	;Set PORTA pins 0-3 as INPUTS and 4 - 7 as OUTPUTS

	ldi temp, 0b11110000
	out DDRA , temp
	ldi temp, 0xFF
	out PORTA , temp ; Set pull ups and close leds

	;Set PORTC as  OUTPUT

	out DDRC,temp
	out PORTC,temp

	;Set Timer1 Interupt
	

	ldi temp , 0b00000100 ; Activate overfow interupt
	out TIMSK,temp

	ldi temp,0x00

	out TCNT1H,temp ; Set starting value

	ldi temp,0x00
	out TCNT1L,temp

	ldi temp,0b00000101 ; Prescaller at 1024 
	
	out TCCR1B,temp ; Set prescaler 

	ldi button_pressed,0x00;Control variables
	ldi car_pressed,0x00
	sei;Enable interrupts

Loop:
	rcall walk1
	rcall ph1
	rcall ph2
	rcall ph3
	rcall walk2
	rcall ph4
	rcall ph5
	rcall ph6
rjmp Loop

timer1 :
		sbrc control,0
		rjmp G_int
		sbrc control,1
		rjmp Y_int
		sbrc control,2
		rjmp R_int
		sbrc control,3
		rjmp W_int

		G_int:
			clz
			cpi timL,1
			breq lastG
			
			ldi temp,0x00

			out TCNT1H,temp ; Set starting value

			ldi temp,0x00
			out TCNT1L,temp
			dec timL
		reti
		R_int : 
			clz
			cpi timL,1
			breq lastR
			
			ldi temp,0x00

			out TCNT1H,temp ; Set starting value

			ldi temp,0x00
			out TCNT1L,temp
			dec timL
		reti
		Y_int :
			clz
			cpi timL,1
			breq lastY
			
			ldi temp,0x00

			out TCNT1H,temp ; Set starting value

			ldi temp,0x00
			out TCNT1L,temp
			dec timL
		reti
		W_int:
			clz
			cpi timL,1
			breq lastW
			
			ldi temp,0x00

			out TCNT1H,temp ; Set starting value

			ldi temp,0x00
			out TCNT1L,temp
			dec timL
		reti




		lastG	:
		
			ldi temp,high(Gtim0)

			out TCNT1H,temp ; Set starting value

			ldi temp,low(Gtim0)
			
			out TCNT1L,temp

			dec timL
		reti


		lastR	:
		
			ldi temp,high(Rtim0)

			out TCNT1H,temp ; Set starting value

			ldi temp,low(Rtim0)
			
			out TCNT1L,temp

			dec timL
		reti
		lastY	:
		
			ldi temp,high(Ytim0)

			out TCNT1H,temp ; Set starting value

			ldi temp,low(Ytim0)
			
			out TCNT1L,temp

			dec timL
		reti
		lastW :
			ldi temp,high(Wtim0)

			out TCNT1H,temp ; Set starting value

			ldi temp,low(Wtim0)
			
			out TCNT1L,temp

			dec timL
		reti
reti


;Phase routins
walk1:

	ldi control,Walk ; Let the timer now that we are counting time for the Walk phase
	ldi timL,W_loops; Load in the counter number of interrupts needed (1 in this case)
	
	;Routines for the lights
	rcall light_E_G
	rcall light_B_G
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_R
	rcall led0_on
	
	lw1:
		;If B is pressed button_pressed = 1 else continue 
		sbis PINA,1;If bit PINA(1) =1 then skip next command
		ldi button_pressed,0x01
		;Check if C1/F1 is pressed 
		;If they are pressed the routines for these phase will execute inside checkC1 or checkF1 and 
		;When they execute they will make car_pressed = 1 
		;Then return
		rcall checkF1
		rcall checkC1
		clz;clear zero flag
		;If C1/F1 was pressed return immidietly
		cpi car_pressed,1
		breq retw1
		clz
		;If B was pressed  return immidietly
		cpi button_pressed,1
		breq retw1
		clz ; clear zero flag
		cpi timL,0
		breq retw1 ;Check If i did all the timer loops for green time  if i did then return else jumo ti lw1 
		rjmp lw1
retw1:
ret


walk2:
	ldi control,Walk
	ldi timL,W_loops
	rcall light_E_R
	rcall light_B_R
	rcall light_A_G
	rcall light_D_G
	rcall light_F_R
	rcall light_C_R
	rcall led1_on
	lw2:
		;Check if A is pressed
		sbis PINA,0;If bit PINA(0) =1 then skip next command
		ldi button_pressed,0x01
		clz 
		;If pressed return immidietly
		cpi button_pressed,1
		breq retw2
		clz ; clear zero flag
		cpi timL,0
		breq retw2 ; If i did all the timer loops the green time passed and i return 
		rjmp lw2
retw2:
ret


ph1:
	;If B or C1 or F1 was pressed if return immidietly else execute routine normally  
	clz
	cpi car_pressed,1
	breq ret1
	cpi button_pressed,1
	breq ret1
	ldi control,Green ; tell the control register that we wait for the green time to finish
	ldi timL,G_loops ; Initialize loop counter

	rcall light_E_G
	rcall light_B_G
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_R
	
	l1:
		rcall led0_on
		rcall delay;Call to blink the leds
		rcall led0_off
		;Check if B is pressed
		sbis PINA,1;If bit PINA(1) =1 then skip next command
		ldi button_pressed,0x01
		rcall checkF1
		rcall checkC1
		clz
		cpi car_pressed,1
		breq ret1
		clz 
		cpi button_pressed,1
		breq ret1
		rcall delay
		clz ; clear zero flag
		cpi timL,0
		breq ret1 ; If i did all the timer loops the green time passed and i return 
		rjmp l1
ret1:
ret



ph2:
	clz
	cpi car_pressed,1
	breq ret2
			ldi temp,0x00

			out TCNT1H,temp ; Set starting value

			ldi temp,0x00
			out TCNT1L,temp
	ldi button_pressed,0x00
	ldi control,Yellow
	ldi timL,Y_loops

	rcall led0_off
	rcall light_E_Y
	rcall light_B_Y
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_R
	l2:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret2
		rjmp l2
ret2:
ret

ph3:
	
	ldi control,Red
	ldi timL,R_loops


	rcall light_E_R
	rcall light_B_R
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_R
	l3:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret3
		rjmp l3
ret3:
ret


ph4:
	cpi button_pressed,1
	breq ret4
	ldi control,Green
	ldi timL,G_loops

	rcall light_E_R
	rcall light_B_R
	rcall light_A_G
	rcall light_D_G
	rcall light_F_R
	rcall light_C_R
	
	l4:

		rcall led1_on
		rcall delay
		sbis PINA,0;If bit PINA(0) =1 then skip next command
		ldi button_pressed,0x01
		rcall led1_off
		clz 
		cpi button_pressed,1
		breq ret4
		rcall delay
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret4
		rjmp l4
ret4:
ret


ph5:
			ldi temp,0x00

			out TCNT1H,temp ; Set starting value

			ldi temp,0x00
			out TCNT1L,temp
	ldi button_pressed,0x00
	ldi control,Yellow
	ldi timL,Y_loops


	rcall light_E_R
	rcall light_B_R
	rcall light_A_Y
	rcall light_D_Y
	rcall light_F_R
	rcall light_C_R
	rcall led1_off
	l5:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret5
		rjmp l5
ret5:
ret

ph6:
	ldi control,Red
	ldi timL,R_loops


	rcall light_E_R
	rcall light_B_R
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_R
	l6:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret6
		rjmp l6
ret6:	
ret


;Button checkers

checkB:
	sbis PINA,1;If bit PINA(1) =1 then skip next command
	rcall ph2
ret
checkF1:
	sbis PINA,3;If bit PINA(3) =1 then skip next command
	rcall F1
ret
checkC1:
	sbis PINA,2;If bit PINA(2) =1 then skip next command
	rcall C1
ret
F1:
	ldi car_pressed,0x01
	rcall F1Y
	rcall F1G
	rcall FY

ret
C1: 
	ldi car_pressed,0x01
	rcall C1Y
	rcall C1G
	rcall CY

ret
F1Y:
	ldi control,Yellow
	ldi timL,Y_loops

	rcall led0_off
	rcall light_E_G
	rcall light_B_Y
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_R
	l21:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret21
		rjmp l21
ret21:
ret

FY:
	ldi control,Yellow
	ldi timL,Y_loops

	rcall led0_off
	rcall light_E_Y
	rcall light_B_R
	rcall light_A_R
	rcall light_D_R
	rcall light_F_Y
	rcall light_C_R
	l212:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret212
		rjmp l212
ret212:
ret
	
F1G:
	ldi control,Green ; tell the control register that we wait for the green time to finish
	ldi timL,G_loops ; Initialize loop counter

	rcall light_E_G
	rcall light_B_R
	rcall light_A_R
	rcall light_D_R
	rcall light_F_G
	rcall light_C_R
	l22:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret22
		rjmp l22
ret22:
ret
	
C1Y:
	ldi control,Yellow
	ldi timL,Y_loops

	rcall led0_off
	rcall light_E_Y
	rcall light_B_G
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_R
	l23:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret23
		rjmp l23
ret23:
ret
	
C1G:
	ldi control,Green ; tell the control register that we wait for the green time to finish
	ldi timL,G_loops ; Initialize loop counter

	rcall light_E_R
	rcall light_B_G
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_G
	l24:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret24
		rjmp l24
ret24:
ret
CY:
	ldi control,Yellow
	ldi timL,Y_loops

	rcall led0_off
	rcall light_E_R
	rcall light_B_Y
	rcall light_A_R
	rcall light_D_R
	rcall light_F_R
	rcall light_C_Y
	l234:
		clz ; clear zero flag
		cpi timL,0 ; If i did all the timer loops the green time passed and i return 
		breq ret234
		rjmp l234
ret234:
ret
	
;LED LIGHTING FUNCTIONS

light_F_R:
	in temp,PORTA
	ori temp,0b00110000
	andi temp,0b11001111 ; make temp = xx00xxxx where xi = PORTB(i)
	out PORTA,temp
ret

light_F_G:
	in temp,PORTA
	ori temp,0b00110000
	andi temp,0b11101111 ; make temp = xx10xxxx where xi = PORTB(i)
	out PORTA,temp
ret

light_F_Y:
	in temp,PORTA
	ori temp,0b00110000
	andi temp,0b11011111 ; make temp = xx01xxxx where xi = PORTB(i)
	out PORTA,temp
ret

light_C_R:
	in temp,PORTA
	ori temp,0b11000000
	andi temp,0b00111111
	out PORTA,temp
ret

light_C_G:
	in temp,PORTA
	ori temp,0b11000000
	andi temp,0b10111111
	out PORTA,temp
ret

light_C_Y:
	in temp,PORTA
	ori temp,0b11000000
	andi temp,0b01111111
	out PORTA,temp
ret




light_B_R:
	in temp,PORTC
	ori temp,0b00110000
	andi temp,0b11001111 ; make temp = xx00xxxx where xi = PORTB(i)
	out PORTC,temp
ret

light_B_G:
	in temp,PORTC
	ori temp,0b00110000
	andi temp,0b11101111 ; make temp = xx10xxxx where xi = PORTB(i)
	out PORTC,temp
ret

light_B_Y:
	in temp,PORTC
	ori temp,0b00110000
	andi temp,0b11011111 ; make temp = xx01xxxx where xi = PORTB(i)
	out PORTC,temp
ret

light_E_R:
	in temp,PORTC
	ori temp,0b11000000
	andi temp,0b00111111
	out PORTC,temp
ret

light_E_G:
	in temp,PORTC
	ori temp,0b11000000
	andi temp,0b10111111
	out PORTC,temp
ret

light_E_Y:
	in temp,PORTC
	ori temp,0b11000000
	andi temp,0b01111111
	out PORTC,temp
ret


light_D_R:
	in temp,PORTC
	ori temp,0b00001100
	andi temp,0b11110011
	out PORTC,temp
ret

light_D_G:
	in temp,PORTC
	ori temp,0b00001100
	andi temp,0b11111011
	out PORTC,temp
ret

light_D_Y:
	in temp,PORTC
	ori temp,0b00001100
	andi temp,0b11110111
	out PORTC,temp
ret

light_A_R:
	in temp,PORTC
	ori temp,0b00000011
	andi temp,0b11111100
	out PORTC,temp
ret

light_A_G:
	in temp,PORTC
	ori temp,0b00000011
	andi temp,0b11111110
	out PORTC,temp
ret

light_A_Y:
	in temp,PORTC
	ori temp,0b00000011
	andi temp,0b11111101
	out PORTC,temp
ret

turn_off_A:

	in temp,PORTC
	ori temp,0b00000011
	out PORTC,temp
ret

led0_on:
	ldi temp,0b11111110
	out PORTD,temp
ret
led0_off:
	ldi temp,0b11111111
	out PORTD,temp
ret


led1_on:
	ldi temp,0b11111101
	out PORTD,temp
ret
led1_off:
	ldi temp,0b11111111
	out PORTD,temp
ret

delay:
    ldi  r19, 6
    ldi  r20, 19
    ldi  r21, 174
Ll1: 
	dec  r21
    brne Ll1
    dec  r20
    brne Ll1
    dec  r19
    brne Ll1
    ret
