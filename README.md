# Fairy Lights for PIC microcontroller unit (MCU)

## Description

The project is a spin-off from [Arduino-based device](https://github.com/ValV/getting-started-arduino) that is more focused on hardware implementation, thus the main algorithm is derived from that work.

Main goal is to develop and implement PIC-based microcontroller board that is able to drive fairy lights like Arduino:

![Arduino-driven board](https://github.com/ValV/getting-started-arduino/raw/master/schematics.jpg)

## Principles

### Pulse Width Modulation

The four independent PWM modules onboard are used to generate a signal with variable duty cycle, i.e. four independent variable power sources.

Changing duty cycle of a signal, one can change power level that is driven to the consumer. In this case the consumer is a group of LEDs (LED, to keep it simple, let it be one led per a group). So with duty cycle changing, LED's brightness changes (trivial thing).

### Mode switching and sequences

The PWM data control registers are being set periodically (on timer) by special routine according to the wrap-around variable. Variable *SQ* indicates a state in a sequence (sequence of states), it increments 8 times and resets to inital value. So every mode has a sequence of 8 states (4 values for each LED in a state).

There are 4 modes in the algorithm. Variable *MD* is responsible for cycling through the modes. Modes are switched by IOC (Interrupt On Change) signal from one of the pins.

### Interrupts

Incrementing of variables *SQ* and *MD* is done on interrupt events. Interrupt events (interrupts) are being handled after *ISR* (Interrupt Service Routine) label.

### Device configuration

Upon reset an MCU device goes into its initial state, so before using it one needs to configure MCU properly. Configuration is done in a special routine after *SETUP* label.

### Main routine

Main program after *START* label allocates a marix of modes, calls *SETUP* routine, initializes *SQ* and *MD* variables, loops in a cycle... And nothing more.

## Target Device

### Selecting MCU

According to [MAPS](https://www.microchip.com/maps/Microcontroller.aspx) *PIC16F1503* is the cheapest and the simplest device of all the diversity of Microchip's production with 4 PWM onboard at the moment.

Program code for *PIC16F1503* unit is located in [PIC16F1503.asm](https://github.com/ValV/getting-started-pic-mcu/blob/master/src/PIC16F1503.asm) file. Unit-specific information is given next.

### Capabilities

*PIC16F1503* has 8-bit core, 15-bit program counter (PC), 16-level deep hardware stack, and peripherials:

* analog to digital converter (ADC);
* complementary wave generator (CWG);
* digital to analog converter (DAC);
* fixed voltage reference (FVR);
* numerically controlled oscillator (NCO);
* temperature indicator;
* 2 comparators (*C1*, *C2*);
* 2 configurable logic blocks (*CLC1*, *CLC2*);
* master SSP (for SPI and SSI interfaces);
* 4 independent PWM modules (*PWM1*, *PWM2*, *PWM3*, *PWM4*);
* 3 timers (*Timer0*, *Timer1*, *Timer2*).

Most of the peripherials are not used. Focusing on *PWMx* modules, *Timer1*, and *Timer2*.

### PWM registers

*PIC16F1503* has 10-bit PWM registers, so every PWM module can generate an impulse as small as 1/1024 of a period.

As far as microcontroller's core is 8-bit, 10-bit PWM registers are composed of two 8-bit registers. It is a 16-bit paired register, but only two most significant bits of the second register are used.

In the Arduino's variant of **fairy-lights** PWM registers were 8-bit large, thus PWM duty cycles values are 8-bit values. In this project the first 8-bit data control register *PWMxDCH* is used, while register *PWMxDCL* remains clear. PWM duty cycle value increments with step equal to 4.

### Timers

Enchanced 16-bit *Timer1* is used for cycling modes and states. *Timer2* is configured for PWM.

### Interrupt on change

For IOC functionality *RA4* pin has been selected. *RA4* is configured to trigger interrupts as well as *Timer1*.

## Development Tools

### MPLAB X IDE

This is the default choice for developing Microchip's devices (PIC, AVR, etc). Since it's open source, it's not a problem to install it in *Archlinux*.

### MPASM

This is the second default choice. MPASM, Microchip's Assembler, is shipped with MPLAB X IDE.

## Debugging and simulation

While the program is not loaded into the device, simulation is the only way to check up correctness of the program.

### Breakpoints

Breakpoint is set on the line with *GOTO START* this must be address *0000h*. After that debugger is launched in *MPLAB X IDE* with *Debug -> Debug Project (fairy-lights)*.

After debugger is launched and stopped at address *0000h*, step-by-step tracing is possible via *F8* key. Thus checking instruction sequence.

### Program memory

Program memory should be explored to reveal how PWM data table is allocated in program memory. This is done via *Window -> Target Memory Views -> Program Memory*, then a new window will be opened with opcodes and disassembly at address *0000h* (Figure 1).

![Figure 1](img/progmem-start.png)
> Figure 1. Program memory at address 0000h

Column *Label* indicates a label of the instruction, so it's easy to find the beginning of the table using it (Figure 2).

![Figure 2](img/progmem-matrix-begin.png)
> Figure 2. Beginning of the MX table

As show on the figure, all PWM duty cycle values are preceeded by *MOVLW* instructions, as *DTM* directive specifies. This is correct until the end of the table (Figure 3).

![Figure 3](img/progmem-matrix-end.png)
> Figure 3. End of the MX table

Difference between the beginning and the end of the table gives exactly 128, which is the number of values for all the modes (4x8x4).

### Special Function Registers

SFRs are another important things to check. There are two ways to do it.

The fist one is via *Window -> Debugging -> IO View*. This will open a new window with SFRs grouped by a perpherial (Figure 4).

![Figure 4](img/ioview-oscillator.png)
> Figure 4. Oscillator SFRs

Oscillator SFRs are the first to be examined due to waiting loop in the program code. The program will wait until oscillator is stable, reading *HFIOFS* bit in *OSCSTAT* register - it should be set manually since simulator has different oscillaton logic.

This can be done also via *Window -> Target Memory Views -> SFRs* (Figure 5).

![Figure 5](img/sfrmem-oscstat.png)
> Figure 5. Oscillator SFRs in Target Memory Views

### Variables

Variables *MD* and *SQ* are stored in data memory (the Harvard architecture, ok). They are initially empty, thus it's important to check how the program changes their values.

Variables are traced via *Window -> Debugging -> Watches* (Figure 6).

![Figure 6](img/watches-x.png)
> Figure 6. Watches window with variables

It's also convenient to watch PWM data registers as well to be sure their values are set up correctly according to the mode *MD* and the state *SQ* in a sequence.

### Logic Analyzer

*MPLAB X IDE* also allows to check output for some period of time via *Window -> Simulator -> Logic Analyzer* (Figure 7).

![Figure 7](img/logic-analyzer-pwm.png)
> Figure 7. PWM output in Logic Analyzer

The figure shows how duty cycle changes according to the values in PWM data registers, which is quite fair.


## Electronic scematics

*TODO*
