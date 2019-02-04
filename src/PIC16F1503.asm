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
#INCLUDE    "modes.asm"
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
        CBLOCK      0x20                ;
                    MD, SQ              ; mode 0x20 and sequence 0x21
                    TEMP                ; temporary variable
        ENDC                            ;

RST:    ORG         0x0000              ; processor reset vector
        PAGESEL     START               ; ensure proper page is selected
        GOTO        START               ; go to beginning of program

; TODO ADD INTERRUPTS HERE IF USED
ISR:    ORG         0x0004              ; interrupt vector address
; Check Timer1 interrupt flag and handle it
        BANKSEL     PIR1                ;
ISRTMR:
        BTFSS       PIR1, TMR1IF        ; check timer's interrupt flag set
        GOTO        ISRIOC              ; goto interrupt-on-change flag
        BCF         PIR1, TMR1IF        ; clear timer's interrupt flag
; Reset Timer1 counter (assume LSB is set at 11th clock, +0xB)
        BANKSEL     TMR1L               ; assume TMR1L, TMR1H together
        MOVLW       0xCB                ; set LSB for counter value 0x63C0
        MOVWF       TMR1L               ; write Timer1 counter LSB
        MOVLW       0x63                ; set MSB for counter value 0x63C0
        MOVWF       TMR1H               ; write Timer1 counter MSB
; Read variables and write to PWM duty cycles
        BANKSEL     MD                  ;
        MOVLW       LOW MX              ; set W as matrix low address
        ADDWF       MD, W               ; add mode offset
        ADDWF       SQ, W               ; add sequence offset
        MOVWF       FSR0L               ; move address with offset to FSR
        MOVLW       HIGH MX             ; set W as matrix high address
        MOVWF       FSR0H               ; move address MSB to FSR
        BANKSEL     PWM1DCH             ; assume PWMxDCx registers together
        MOVIW       0[FSR0]             ; get MX[MD][SQ][0] value
        MOVWF       PWM1DCH             ; set PWM1 duty cycle
        MOVIW       1[FSR0]             ; get MX[MD][SQ][1] value
        MOVWF       PWM2DCH             ; set PWM2 duty cycle
        MOVIW       2[FSR0]             ; get MX[MD][SQ][2] value
        MOVWF       PWM3DCH             ; set PWM3 duty cycle
        MOVIW       3[FSR0]             ; get MX[MD][SQ][3] value
        MOVWF       PWM4DCH             ; set PWM4 duty cycle
; Rotate cycles
        BANKSEL     SQ                  ; rotate variable 0..31 by 4
        MOVLW       0x4                 ; increase by 4 (4 PWMs)
        ADDWF       SQ, W               ; increment cycle and store in W
        ANDLW       0x1F                ; W & 0x1F (rotate 0..31)
        MOVWF       SQ                  ; return W to SQ
; Check interrupt-on-change flag
ISRIOC:
        BANKSEL     IOCAF               ;
        BTFSS       IOCAF, IOCAF4       ; PushButton interrupt vector (high)
        GOTO        ISREND              ; exit ISR
        BCF         IOCAF, IOCAF4       ; clear RA4 IOC interrupt flag
; Rotate modes
        BANKSEL     MD                  ; rotate variable 0..127 by 32
        MOVLW       0x20                ; increase by 32 (8x4 mode matrix)
        ADDWF       MD, W               ; increment mode and store in W
        ANDLW       0x7F                ; W & 0x7F (rotate 0..127)
        MOVWF       MD                  ; return W to MD
        CLRF        SQ                  ; mode switched, reset sequence
; Final check
ISREND:
        BANKSEL     PIR1                ;
        BTFSC       PIR1, TMR1IF        ; check timer's interrupt flag again
        GOTO        ISRTMR              ; interrupt occured in ISR, handle
        RETFIE                          ;

SETUP:
; INTERNAL OSCILLATOR SETUP
        BANKSEL     OSCCON              ;
        MOVLW       B'01110000'         ; '00' SCS -> _FOSC_INTOSC config
        MOVWF       OSCCON              ; '1110' IRCF -> 8 MHz
        BANKSEL     OSCSTAT             ;
OSCRDY: BTFSS       OSCSTAT, HFIOFS     ; check if HF oscillator is stable
        GOTO        OSCRDY              ; HFINTOSC bit is not set -> check
; PWM CONFIGURATION
; Step 1. Disable PWMx output drivers
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
        BANKSEL     PIR1                ;
        BCF         PIR1, TMR2IF        ; reset timer (clear overflow bit)
        BANKSEL     T2CON               ;
        BCF         T2CON, T2CKPS0      ; clear LSB (x1 prescaler = 0x00)
        BCF         T2CON, T2CKPS1      ; clear MSB (x1 prescaler = 0x00)
        BSF         T2CON, TMR2ON       ; enable PWM timer
; Step 6. Enable PWM outputs
        NOP                             ; TODO: remove this step
; Step 7. Enable PWMx pin output drivers
        BANKSEL     TRISA               ; assume TRISx registers together
        BCF         TRISC, TRISC5       ; set RC5 to output (PWM1)
        BCF         TRISC, TRISC3       ; set RC3 to output (PWM2)
        BCF         TRISA, TRISA2       ; set RA2 to output (PWM3)
        BCF         TRISC, TRISC1       ; set RC1 to output (PWM4)
        BANKSEL     PWM1CON             ;
        BSF         PWM1CON, PWM1OE     ; PWM1 output enable
        BSF         PWM2CON, PWM2OE     ; PWM2 output enable
        BSF         PWM3CON, PWM3OE     ; PWM3 output enable
        BSF         PWM4CON, PWM4OE     ; PWM4 output enable
; Step 8. Activate PWM module
        BANKSEL     PWM1CON             ;
        BSF         PWM1CON, PWM1EN     ; activate PWM1
        BSF         PWM2CON, PWM2EN     ; activate PWM2
        BSF         PWM3CON, PWM3EN     ; activate PWM3
        BSF         PWM4CON, PWM4EN     ; activate PWM4
; PUSHBUTTON AND CYCLE TIMER CONFIGURATION
; Step 1. Configure push button interrupts
        BCF         INTCON, GIE         ; turn off global interrupts (CFR)
        BSF         INTCON, IOCIE       ; enable interrupt-on-change
        BANKSEL     IOCAP               ; IOCAP sets IOCAF bit on positive edge
        BSF         IOCAP, IOCAP4       ; RA4 pin interrupt on positive detect
        BSF         TRISA, TRISA4       ; configure PushButton pin (input)
; Step 2. Configure cycle timer (Timer1) clock source
        BANKSEL     T1CON               ; assume T1CON, T1GCON together
        BCF         T1CON, TMR1CS0      ; set Timer1 clock source to
        BCF         T1CON, TMR1CS1      ; instruction clock: Fosc/4 = 2 MHz
; Step 3. Enable cycle timer (with 2 MHz counter frequency)
        BSF         T1CON, TMR1ON       ; enable Timer1
        BCF         T1GCON, TMR1GE      ; disable Timer1 gate mode
; Step 4. Setup Timer1 initial counter value (2^16-(8*10^6)/(4*50) = 25536)
        BANKSEL     TMR1L               ; assume TMR1L, TMR1H together
        MOVLW       0xC0                ; set LSB for counter value 0x63C0
        MOVWF       TMR1L               ; write Timer1 counter LSB
        MOVLW       0x63                ; set MSB for counter value 0x63C0
        MOVWF       TMR1H               ; write Timer1 counter MSB
; Step 5. Enable interrupts for Timer1
        BANKSEL     PIE1                ;
        BSF         PIE1, TMR1IE        ; enable interrupts for Timer1
        BSF         INTCON, PEIE        ; enable peripherial interrupts
        BSF         INTCON, GIE         ; enable global interrupts (CFR)
        RETURN                          ;

START:
; Create tables in program memory
MX:     DTM         MODA                ; 1st mode (from modes.asm file)
        DTM         MODB                ; 2nd mode (from modes.asm file)
        DTM         MODC                ; 3rd mode (from modes.asm file)
        DTM         MODD                ; 4th mode (from modes.asm file)
; Call device configuration routine
        CALL        SETUP               ; setup MCU
; Initialize variables
        MOVLW       0x0                 ; variables initial value
        MOVWF       MD                  ; initialize mode variable
        MOVWF       SQ                  ; initialize sequence variable
        GOTO        $                   ; loop forever
        END