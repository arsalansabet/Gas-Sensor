;********************************************************************************
; DOES IT WORK?		NO
; FILENAME:			FART SNIFFER
; VERSION:			1
; DATE:				04DEC2016	
; FILE SAVED AS:	12F675_FartSnifferV1.asm
; MICROCONTROLLER:	PIC12F675
; CLOCK FREQUENCY:	32.768kHz using an off-board oscillator for low power use. 
;********************************************************************************
; FILES REQUIRED:  	p12f675.inc
;********************************************************************************
; PROGRAM FUNCTION:
;	It's a minimalist fart sniffer.  Use MQ-x series of gas sensor
;********************************************************************************
; NOTES:	
;
;********************************************************************************
; AUTHOR:			KAM ROBERTSON
; COMPANY:			ACORN ENERGY LLC
;********************************************************************************
;********************************************************************************
;********************************************************************************
; HOUSEKEEPING
    list P=PIC12F675		; list directive to define processor
    include C:\Program Files (x86)\Microchip\MPASM Suite\p12f675.inc	
    __CONFIG   _CP_OFF & _CPD_OFF & _BOREN_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _LP_OSC           
	; '__CONFIG' directive is used to embed configuration word within .asm file
;================================================================================
; DECLARATIONS cpu equates (memory map)
porta	EQU	0x05	; assigns the memory location of register PORTA to porta for use in code 
					; literals assigned with EQU cannot be changed elswhere in code
					; creates an un-changable pointer and allows use of lower case porta
portb	EQU	0x06	; allows use of lower case PORTB
;
; DECLARATIONS bit equates
num0	EQU	0x20	; "num0" is a pointer to register 32
num1	EQU	0x21	; "num1" is a pointer to register 33
num2	EQU	0x22	; "num2" is a pointer to register 34
work	EQU	0x23	; interrupt service temporarilly stores working register here
stat	EQU	0x24	; interrupt service temporarilly stores status register here
speed	EQU	0x25	; use for timer inc/dec that is used to run the led's and piezo buzzer
d1		equ	0x26	; determines time spent in the delay loop
duty1	equ	0x27	; used for pwm prescaler
duty2	equ	0x28	; used for pwm prescaler
ledstate	equ	0x29	; led ledstate green-set or red-clear
mute	equ	0x2A	; allows sound to be muted or not every other on/off cycle
roten	equ	0x2B	; quadrature
tone1	equ	0x2C	; quadrature
past	equ	0x2D	; quadrature
present	equ	0x2E	; quadrature
time	equ	0x2F	; used to set the beat tone sent to the piezo.  increments every light cycle
beatstate	equ	0x30	; use logic shift and bit test to set the beat time beatstate: mute, 4/4, 2/4, 2/3, 3/4. 6/4 
d2		equ	0x31	; determine time spent in the delay loop
;================================================================================
; PROGRAM STARTS BELOW
    ORG		0x000
    GOTO	start	; go to the start 
    ORG		0x004	; interrupt service vector at memory location 0x004 it goes here automatically when intcon bit-1 is set
    GOTO	intserv	; go to the interrupt service function
start
    CALL initializer	; CALL the function "initializer"
    goto main
	;
	;
main
	;
	;
	GOTO	main	; loops back to main (it's a catcher)
	;
	;
;================================================================================
; SUBROUTINES AND FUNCTIONS
initializer					; first set numbers into the equate register declarations
    MOVLW	0x05
    MOVWF	d1
	;
    MOVLW	0x07
    MOVWF	d2
	;
    MOVLW	0x02
    MOVWF	duty1
	;
    MOVLW	0x02
    MOVWF	duty2
	;
;    MOVLW	0x20	    ; does not appear to work on PR2 in  bank1
;    MOVWF	tone1	    ; does not appear to work on PR2 in  bank1
	;
    MOVLW	0xC0
    MOVWF	speed
	;
    MOVLW	0x00
    MOVWF	ledstate
    MOVWF	work
    MOVWF	stat
    MOVWF	roten
    MOVWF	mute
    MOVWF	past
    MOVWF	present	
	;
;
;
delay				; 8-bit system so... setting counters to zero gives 256 bits/decrements
					; uses literal number in working register to determine how many passes through the d_loop
    MOVWF	num2	; pass value from working register into delay counter at R34
    MOVWF	num1	; pass value from working register into delay counter at R33
;	MOVWF	num0	; pass value from working register into delay counter at R32
d_loop
    DECFSZ	num2, f	; decrements delay counter by one then skips next step if count1_register-nine ontains zero
    GOTO	d_loop	; returns to d_loop if R9 contains any ones
    MOVWF	num2	; prepares for next use by setting R9 back to zero
	;
    DECFSZ	num1, f	; decrements delay counter by one then skips next step if count2_register-eight contains a zero
    GOTO	d_loop	; returns to d_loop if R8 contains any ones
    MOVWF	num1	; prepares for next use by setting R8 back to zero
	;
;	DECFSZ	num0, f	; decrements delay counter by one then skips next step if count0_register-seven contains a zero
;	GOTO	d_loop	; returns to d_loop if R7 contains any ones
    RETURN		; the larger command set on midline chips supports the "return" command. It is more appropriate here
;
;
intserv	; hey service this interrupt.  save those registers, do stuff, bring those registers back.  YAY!!!
    MOVWF	work		; save current working register in memory
    SWAPF	STATUS, 0	; d=destination working register.  get current status without changing flags
    MOVWF	stat		; store current status register in memory
	;
    BTFSC	INTCON,	0	; TEST TO SEE IF INTERRUPT CAME FROM THE BUTTON AT RB0/INT
;    goto 	rotencoder
	;
    BTFSC	INTCON,	1	; TEST TO SEE IF INTERRUPT CAME FROM THE BUTTON AT RB0/INT
;    goto	button
	;
    BTFSC	INTCON,	2	; CHECK THE TIMER ZERO FLAG
;    GOTO	led
	;
;    GOTO	intexit		; who knows where the interrupt came from.  let's get outa dodge.
	;
	;
intexit
    SWAPF	stat,	0	; d=destination working register
    MOVWF	STATUS		; puts working register into status register... back to what it was
    SWAPF	work,	1	; d=destination file register... twist, no holder change.
    SWAPF	work,	0	; d=destination working register... untwist and back to what it was.  no holder change
    RETFIE				; back from whence you came and as you were.
	;
	;
;================================================================================
    END
;================================================================================


