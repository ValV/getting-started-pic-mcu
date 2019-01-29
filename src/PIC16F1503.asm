#INCLUDE        <p16f1503.inc>
; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
; CONFIG1
 __CONFIG       _CONFIG1, 0xFFE4        ; _FOSC_INTOSC & _WDTE_OFF &
                                        ; _PWRTE_OFF & _MCLRE_ON &
                                        ; _CP_OFF & _BOREN_ON &
                                        ; _CLKOUTEN_OFF
; CONFIG2
 __CONFIG       _CONFIG2, 0xFFFF        ; _WRT_OFF & _STVREN_ON & _BORV_LO &
                                        ; _LPBOR_OFF & _LVP_ON

RESET:  ORG     0x0000                  ; processor reset vector
;RESET: CODE    0x0000                  ; processor reset vector (rel)
        GOTO    START                   ; go to beginning of program

; TODO ADD INTERRUPTS HERE IF USED
ISR:    ORG     0x0004                  ; ISR base address
;ISR    CODE    0x0004                  ; ISR base address (rel)
; cycle timer interrupt vector (low)

; PushButton interrupt vector (high)
        RETFIE

SETUP:  ORG     0x0080
        ; turn off global interrupts
        ; configure PWM pins (output) (?)
        ; configure PushButton pin (input)
        ; reset cycle and PWM timers (disable and detach)
        ; disable interrupts PWM timer(s)
        ; enable PWM (?)
        ; enable cycle timer (16000000/8/256 = 7812.5 Hz, (/8) prescaler)
        ; enable PWM timer(s) (16000000/1/256 = 62500 Hz, (/1) prescaler)
        ; set compare match (pins) on PWM timer(s) (?)
        ; set compare register for PWM (8 bit precision)
        ; enable interrupts on cycle timer
        ; set PWM mode (phase-correct) (?)
        ; set prescaler for cycle timer
        ; set cycle timer frequency (50 Hz)
        ; set compare register for cycle timer
        ; enable interrupts for PushButton
        ; enable global interrupts
        RETURN

MAIN:   ORG     0x00FF
;   CODE                                ; let linker place main program (rel)

START:
        CALL    SETUP                   ; setup MCU
        GOTO    $                       ; loop forever
        END