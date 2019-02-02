;*******************************************************************************
;                                                                              *
;    Filename:      PIC16F1503.asm                                             *
;    Date:          2019.02.01                                                 *
;    File Version:  1.0                                                        *
;    Author:        ValV                                                       *
;    Company:                                                                  *
;    Description:   Fairy lights PIC MCU project.                              *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;                                                                              *
;*******************************************************************************
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
; INTERNAL OSCILLATOR SETUP
        BANKSEL     OSCCON
        MOVLW       B'01110000'         ; '00' SCS -> _FOSC_INTOSC config
        MOVWF       OSCCON              ; '1110' IRCF -> 8 MHz
        BANKSEL     OSCSTAT
OSCRDY: BTFSS       OSCSTAT, HFIOFS     ; check if HF oscillator is stable
        GOTO        OSCRDY              ; HFINTOSC bit is not set -> check
; PWM CONFIGURATION
; Step 1. Disable PWMx outputs
        BANKSEL     TRISA               ; assume TRISx registers together
        BSF         TRISC, TRISC5       ; set RC5 to input (PWM1)
        BSF         TRISC, TRISC3       ; set RC3 to input (PWM2)
        BSF         TRISA, TRISA2       ; set RA2 to input (PWM3)
        BSF         TRISC, TRISC1       ; set RC1 to input (PWM4)
; Step 2. Clear PWM configuration
        BANKSEL     PWM1CON             ; assume PWMxCON registers together
        CLRF        PWM1CON             ; disable PWM1 module, pin, configs
        CLRF        PWM2CON             ; disable PWM2 module, pin, configs
        CLRF        PWM3CON             ; disable PWM3 module, pin, configs
        CLRF        PWM4CON             ; disable PWM4 module, pin, configs
; Step 3. Setting PWM period
        BANKSEL     PR2                 ; period = (PR2+1)*4*Tosc*prescale
        MOVLW       0xFF                ; (8*10^6)/((0xFF+1)*4*1) = 7812.5 Hz
        MOVWF       PR2                 ; PR2=0xFF, Tosc=1/8 MHz, prescale=1
; Step 4. Clear PWM duty cycle
        BANKSEL     PWM1DCH             ; assume PWMxDCx registers together
        CLRF        PWM1DCH             ; clear MSB (0..1020, w/o LSB)
        CLRF        PWM1DCL             ; clear LSB (will not be used)
        CLRF        PWM2DCH             ; duty cycle ratio (DCR) =
        CLRF        PWM2DCL             ; (PWMxDCH:PWMxDCL<7:6>)/(4(PR2+1))
        CLRF        PWM3DCH             ; PWMxDCH = 0xFF => DCR = 0.996
        CLRF        PWM3DCL             ; PWMxDCH = 0x85 => DCR = 0.332
        CLRF        PWM4DCH             ; where PWMxDCL is always 0x00
        CLRF        PWM4DCL             ; loss of LSB does not affect much
; Step 5. Setup and start Timer2
        BANKSEL     PIR1
        BCF         PIR1, TMR2IF        ; reset timer (clear overflow bit)
        BANKSEL     T2CON
        BCF         T2CON, T2CKPS0      ; clear LSB (x1 prescaler = 0x00)
        BCF         T2CON, T2CKPS1      ; clear MSB (x1 prescaler = 0x00)
        BSF         T2CON, TMR2ON       ; enable PWM timer(s) (16000000/1/256 = 62500 Hz, (/1) prescaler)
; Step 6. Enable PWM outputs
        NOP                             ; TODO: remove this step
; Step 7. Enable PWMx pin output drivers
        BANKSEL     TRISA               ; assume TRISx registers together
        BCF         TRISC, TRISC5       ; set RC5 to output (PWM1)
        BCF         TRISC, TRISC3       ; set RC3 to output (PWM2)
        BCF         TRISA, TRISA2       ; set RA2 to output (PWM3)
        BCF         TRISC, TRISC1       ; set RC1 to output (PWM4)
        BANKSEL     PWM1CON
        BSF         PWM1CON, PWM1OE     ; PWM1 output enable
        BSF         PWM2CON, PWM2OE     ; PWM2 output enable
        BSF         PWM3CON, PWM3OE     ; PWM3 output enable
        BSF         PWM4CON, PWM4OE     ; PWM4 output enable
; Step 8. Activate PWM module
        BANKSEL     PWM1CON
        BSF         PWM1CON, PWM1EN     ; activate PWM1
        BSF         PWM2CON, PWM2EN     ; activate PWM2
        BSF         PWM3CON, PWM3EN     ; activate PWM3
        BSF         PWM4CON, PWM4EN     ; activate PWM4
; PUSHBUTTON AND CYCLE TIMER CONFIGURATION
        BCF         INTCON, GIE         ; turn off global interrupts (CFR)
        BANKSEL     IOCAP               ; IOCAP sets IOCAF bit on positive edge
        BSF         IOCAP, IOCAP4       ; RA4 pin interrupt on positive detect
                                        ; configure PushButton pin (input)
                                        ; enable cycle timer (16000000/8/256 = 7812.5 Hz, (/8) prescaler)
                                        ; enable interrupts on cycle timer
                                        ; set prescaler for cycle timer
                                        ; set cycle timer frequency (50 Hz)
                                        ; set compare register for cycle timer
        BSF         INTCON, GIE         ; enable global interrupts (CFR)
        RETURN

START:
        CALL        SETUP               ; setup MCU
        GOTO        $                   ; loop forever
        END