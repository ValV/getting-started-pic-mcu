        #INCLUDE    <p16f1503.inc>
; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
                                        ; CONFIG1
        __CONFIG    _CONFIG1, 0xFFE4    ; _FOSC_INTOSC & _WDTE_OFF &
                                        ; _PWRTE_OFF & _MCLRE_ON &
                                        ; _CP_OFF & _BOREN_ON &
                                        ; _CLKOUTEN_OFF
                                        ; CONFIG2
        __CONFIG    _CONFIG2, 0xFFFF    ; _WRT_OFF & _STVREN_ON & _BORV_LO &
                                        ; _LPBOR_OFF & _LVP_ON

; VARIABLES BLOCK
        CBLOCK      0x20
        MODE
        ENDC

RESET:  ORG         0x0000              ; processor reset vector
        PAGESEL     START               ; ensure proper page is selected
        GOTO        START               ; go to beginning of program

; TODO ADD INTERRUPTS HERE IF USED
ISR:    ORG         0x0004              ; interrupt vector address
                                        ; cycle timer interrupt vector (low)

                                        ; PushButton interrupt vector (high)
        RETFIE

SETUP:
; PWM configuration
; Step 1. Disable PWMx outputs
        BANKSEL     TRISC
        BSF         TRISC, TRISC5       ; disable PWM1 output driver (RC5)
        BSF         TRISC, TRISC3       ; disable PWM2 output driver (RC3)
        BSF         TRISC, TRISC1       ; disable PWM4 output driver (RC1)
        BANKSEL     TRISA
        BSF         TRISA, TRISA2       ; disable PWM3 output driver (RA1)
; Step 2. Clear PWM configuration
        BANKSEL     PWM1CON
        CLRF        PWM1CON             ; disable PWM1 module, pin, configs
        CLRF        PWM2CON             ; disable PWM2 module, pin, configs
        CLRF        PWM3CON             ; disable PWM3 module, pin, configs
        CLRF        PWM4CON             ; disable PWM4 module, pin, configs
; Step 3. Setting PWM period
        BANKSEL     PR2
        MOVLW       0x65                ; (0x65+1)*4/(8*10^6)*1 = 19607.8 Hz
        MOVWF       PR2                 ; PR2=0x65, Tosc=1/8 MHz, prescale=1
; Step 4. Clear PWM duty cycle
        BANKSEL     PWM1DCH
        CLRF        PWM1DCH             ; clear MSB
        CLRF        PWM1DCL             ; clear LSB
; Step 5. Setup and start Timer2
        BANKSEL     PIR1
                                        ; reset cycle and PWM timers (disable and detach)
                                        ; disable interrupts PWM timer(s)
        BCF         PIR1, TMR2IF        ; reset timer (clear overflow bit)
        BANKSEL     T2CON               ; x1 prescaler for Timer2 = 0x00
        BCF         T2CON, T2CKPS0      ; clear LSB
        BCF         T2CON, T2CKPS1      ; clear MSB
        BSF         T2CON, TMR2ON       ; enable PWM timer(s) (16000000/1/256 = 62500 Hz, (/1) prescaler)
; Step 6. Enable PWM outputs
        NOP                             ; enable PWM (?)
; Step 7. Enable PWMx pin output drivers
        BANKSEL     TRISC
        BCF         TRISC, TRISC5
        BCF         TRISC, TRISC3
        BCF         TRISC, TRISC1
        BANKSEL     TRISA
        BCF         TRISA, TRISA2       ; enable PWM output driver
        BANKSEL     PWM1CON
        BSF         PWM1CON, PWM1OE     ; PWM1 output enable
        BSF         PWM2CON, PWM2OE     ; PWM1 output enable
        BSF         PWM3CON, PWM3OE     ; PWM1 output enable
        BSF         PWM4CON, PWM4OE     ; PWM1 output enable
; Step 8. Enable PWM module
        BANKSEL     PWM1CON
        BSF         PWM1CON, PWM1EN     ; activate PWM1
        BSF         PWM2CON, PWM2EN     ; activate PWM2
        BSF         PWM3CON, PWM3EN     ; activate PWM3
        BSF         PWM4CON, PWM4EN     ; activate PWM4
;       BANKSEL     INTCON              ; TODO
;       BCF         INTCON, GIE         ; turn off global interrupts
                                        ; configure PushButton pin (input)
                                        ; enable cycle timer (16000000/8/256 = 7812.5 Hz, (/8) prescaler)
                                        ; enable interrupts on cycle timer
                                        ; set prescaler for cycle timer
                                        ; set cycle timer frequency (50 Hz)
                                        ; set compare register for cycle timer
                                        ; enable interrupts for PushButton
                                        ; enable global interrupts
        RETURN

START:
        CALL        SETUP               ; setup MCU
        GOTO        $                   ; loop forever
        END