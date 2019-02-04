# Fairy Lights for PIC microcontroller unit (MCU)

## Description

The project is a spin-off from [Arduino-based device](https://github.com/ValV/getting-started-arduino) that is more focused on hardware implementation, thus the main algorithm is derived from that work.

## Selecting MCU

*PIC16F1503* has been chosen from all the diversity of Microchip's production as the cheapest and the simplest 8-bit device with 4 PWM onboard.

> Perhaps, not the cheapest at all, but at this point of time [MAPS](https://www.microchip.com/maps/Microcontroller.aspx) promotes it as such

Maybe it's not the most optimal choice for such a simple task, but let's stick with this one.

## Principles

The four independent PWM modules onboard are used to generate a signal with variable duty cycle, i.e. four independent variable power sources.

Changing duty cycle of a signal one can change power level that is driven to the consumer. In this case the consumer is a LED. So by changing duty cycle, LED's brightness changes (trivial thing).

*PIC16F1503* has 10-bit PWM registers, that is every PWM module can generate up to 1024 duty cycles per period, but with some certain limitations.

As far as it is 8-bit device, 10-bit PWM registers are composed from two 8-bit registers. This is 16-bit pair register, but only two MSB of the second register are used. This is not quite convenient to use with 8-bit values from the previous project, thus 10-bit precision is left, but only the first register is used. So the two LSB are always zero. This is ok.

The PWM registers are set periodically (on timer) by special routine according to the cyclic variable. This variable ([SQ](https://github.com/ValV/getting-started-pic-mcu/blob/8219d292200d4933213a8735276e1c57c0d83088/src/PIC16F1503.asm#L29)) indicates a sequence, it increments 8 times and resets it value to inital (0). So every mode has 8 sequences.

There are 4 modes in the algorithm. Variable [MD](https://github.com/ValV/getting-started-pic-mcu/blob/8219d292200d4933213a8735276e1c57c0d83088/src/PIC16F1503.asm#L29) is responsible for cycling through the modes. Modes are swithced by IOC (Interrupt On Change) signal from one of the pins (RA4).

Incrementing of variables SQ and MD is done in [ISR](https://github.com/ValV/getting-started-pic-mcu/blob/8219d292200d4933213a8735276e1c57c0d83088/src/PIC16F1503.asm#L38) (Interrupt Service Routine). Thus RA4 is configured to trigger interrupts as well as Timer1. Enchanced 16-bit Timer1 is used for cycling variable and Timer2 is configured for PWM.

Configuration is done in a special routine [SETUP](https://github.com/ValV/getting-started-pic-mcu/blob/8219d292200d4933213a8735276e1c57c0d83088/src/PIC16F1503.asm#L94).

Main program after [START](https://github.com/ValV/getting-started-pic-mcu/blob/8219d292200d4933213a8735276e1c57c0d83088/src/PIC16F1503.asm#L182) allocates a marix of modes, calls SETUP, initializes SQ and MD, loops in a cycle... And nothing more.

## Electronic scematics

*TODO*
