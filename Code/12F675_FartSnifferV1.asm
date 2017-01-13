;********************************************************************************
; DOES IT WORK?		NO
; FILENAME:			FART SNIFFER
; VERSION:			1
; DATE:				04DEC2016	
; FILE SAVED AS:	12F675_FartSnifferV1.asm
; MICROCONTROLLER:	PIC12F675
; CLOCK FREQUENCY:	32.768kHz using an off-chip oscillator for low power use. 
;********************************************************************************
; FILES REQUIRED:  	p12f675.inc
;********************************************************************************
; PROGRAM FUNCTION:
;	It's a minimalist fart sniffer.  Use MQ-x series of gas sensor
;********************************************************************************
; NOTES:	
;	GROUND				PIN8	VSS
;	LED OUTPUT			PIN7	GP0
;	RF SIGNAL OUTPUT	PIN6	GP1	
;	GAS SENSOR INPUT	PIN5	GP2
;	MCLR RESET INPUT	PIN4	GP3
;	XTAL INPUT			PIN3	GP4
;	XTAL INPUT			PIN2	GP5
;	5 VOLTS DC			PIN1	VDD
;
;		GAS SENSOR:	is normally high 4.7vdc
;					in natural gas goes low 0.16vdc
;					generally clears in about 5sec when using a bic lighter
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
    __CONFIG   _CP_OFF & _CPD_OFF & _BOREN_OFF & _MCLRE_ON & _PWRTE_OFF & _WDT_OFF & _LP_OSC       ; PAGE 58  The Power-up Timer should always be enabled when Brown-out Detect is enabled.
;================================================================================
; DECLARATIONS bit equates
num0	EQU	0x30	; "num0" is a pointer to register 32
num1	EQU	0x31	; "num1" is a pointer to register 33
num2	EQU	0x32	; "num2" is a pointer to register 34
work	EQU	0x33	; interrupt service temporarilly stores working register here
stat	EQU	0x34	; interrupt service temporarilly stores status register here
d1		equ	0x36	; determines time spent in the delay loop
txstate	equ	0x37	; use to change between transmit or not
;================================================================================
; PROGRAM STARTS BELOW
    ORG		0x000
    GOTO	start	; go to the start 
    ORG		0x004	; interrupt service vector at memory location 0x004 it goes here automatically when intcon bit-1 is set
    GOTO	intserv	; go to the interrupt service function
start
    CALL initializer	; CALL the function "initializer"
    GOTO main
	;
	;
main
	BTFSC	txstate,    1
	GOTO	radiotx
	GOTO	standby
standby
    CALL	rfquiet
	GOTO	main
radiotx
    CALL	transmit
	CALL	rfquiet
	GOTO	main
	;
	NOP
	GOTO	main	; loops back to main (it's a catcher)
;================================================================================
; SUBROUTINES AND FUNCTIONS
initializer					; first set numbers into the equate register declarations
    MOVLW	0xA
    MOVWF	d1
	;
    MOVLW	0x00
    MOVWF	work
    MOVWF	stat
	;
; COMPARATOR REGISTER	must be set up to use these pins as gpio
	BCF		CMCON,	6
	BCF		CMCON,	4
	BCF		CMCON,	3
	BSF		CMCON,	2
	BSF		CMCON,	1
	BSF		CMCON,	0
; ANALOG SELECT REGISTER	must be set up to use these pins as gpio
	BSF		STATUS,	5		;Bank 1
	BCF		ANSEL,	3
	BCF		ANSEL,	2
	BCF		ANSEL,	1
	BCF		ANSEL,	0
	BCF		STATUS,	5		; bank zero
; TRIS INPUT OUTPUT REGISTER
	BSF		STATUS,	5		;Bank 1
	BSF		TRISIO,	5		; xtal
	BSF		TRISIO,	4		; xtal
	BSF		TRISIO,	3		; mclr reset button
	BSF		TRISIO,	2		; input interrupt from gas sensor
	BCF		TRISIO,	1		; output two state led indicator
	BCF		TRISIO,	0		; output rf module signal to relay
	BCF		STATUS,	5		; bank zero
; OPTION REGISTER
	BSF		STATUS,	5		;Bank 1
	BSF		OPTION_REG,	7
	BCF		OPTION_REG,	6	; clear for interrupt on falling edge
	BCF		OPTION_REG,	5
	BCF		OPTION_REG,	4
	BCF		OPTION_REG,	3
	BCF		OPTION_REG,	2
	BCF		OPTION_REG,	1
	BCF		OPTION_REG,	0
	BCF		STATUS,	5		; bank zero
; INTERRUPT ON CHANGE REGISTER
	BSF		STATUS,	5		;Bank 1
	BCF		IOC,	5
	BCF		IOC,	4
	BCF		IOC,	3
	BSF		IOC,	2		; set for int on change on pin5
	BCF		IOC,	1
	BCF		IOC,	0
	BCF		STATUS,	5		; bank zero
; GENERAL PIN INPUT OUTPUT REGISTER
	BSF		GPIO,	5
	BSF		GPIO,	4
	BSF		GPIO,	3
	BSF		GPIO,	2
	BCF		GPIO,	1
	BCF		GPIO,	0
; INTERRUPT CONTROL REGISTER
	BSF		INTCON,	7		; ENABLE GLOBAL INTERRUPTS
	BCF		INTCON,	6		; Peripheral Interrupt Enable bit
	BCF		INTCON,	5		; TMR0 Overflow Interrupt Enable bit
	BCF		INTCON,	4		; enable GP2/INT
	BSF		INTCON,	3		; enable interrupt on change
	BCF		INTCON,	2		; TMR0 Overflow Interrupt Flag bit
	BCF		INTCON,	1		; interrupt GP2/INT FLAG
	BCF		INTCON,	0		; interrupt on change flag
	;
	;
	RETURN
	;
	;
rfquiet
	BCF		GPIO,	0
	BCF		GPIO,	1
	RETURN
transmit
	BSF		GPIO,	0
	BSF		GPIO,	1
	RETURN
	;
	;
delay				; 8-bit system so... setting counters to zero gives 256 bits/decrements
					; uses literal number in working register to determine how many passes through the d_loop
    MOVWF	num2	; pass value from working register into delay counter at R34
    MOVWF	num1	; pass value from working register into delay counter at R33
	MOVWF	num0	; pass value from working register into delay counter at R32
d_loop
    DECFSZ	num2, F	; decrements delay counter by one then skips next step if count1_register-nine ontains zero
    GOTO	d_loop	; returns to d_loop if R9 contains any ones
    MOVWF	num2	; prepares for next use by setting R9 back to zero
	;
    DECFSZ	num1, F	; decrements delay counter by one then skips next step if count2_register-eight contains a zero
    GOTO	d_loop	; returns to d_loop if R8 contains any ones
	MOVWF	num1	; prepares for next use by setting R8 back to zero
	;
	DECFSZ	num0, f	; decrements delay counter by one then skips next step if count0_register-seven contains a zero
	GOTO	d_loop	; returns to d_loop if R7 contains any ones
    RETURN		; the larger command set on midline chips supports the "return" command. It is more appropriate here
;
;
intserv	; hey service this interrupt.  save those registers, do stuff, bring those registers back.  YAY!!!
    MOVWF	work		; save current working register in memory
    SWAPF	STATUS, 0	; d=destination working register.  get current status without changing flags
    MOVWF	stat		; store current status register in memory
	;
    BTFSC	INTCON,	0	; TEST TO SEE IF INTERRUPT CAME FROM THE BUTTON AT RB0/INT int-on-change
    GOTO 	ismellgas
	GOTO	intexit
	;
	BTFSC	INTCON,	1	; TEST TO SEE IF INTERRUPT CAME FROM THE BUTTON AT RB0/INT interrupt
	GOTO 	ismellgas
	GOTO	intexit
	;
	;
ismellgas
	BTFSC	GPIO,	2
	GOTO	gasoff
gason
	MOVLW	0xFF
	MOVWF	txstate
	BCF		INTCON,	0	; interrupt on change flag
	BCF		INTCON,	1	; interrupt GP2/INT FLAG
	GOTO	intexit
gasoff	
	MOVLW	0x00
	MOVWF	txstate
	BCF		INTCON,	0	; interrupt on change flag
	BCF		INTCON,	1	; interrupt GP2/INT FLAG
	GOTO	intexit
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


