# Calc

A calculator application for handheld game consoles made with Love2d that aims to be both powerful and customizable.

## Features and Concepts
This calculator tries to be simple to use, but some explanation is needed to help the user. 

Main Features:

- Infix Notation for a easier use
- Standard Operations(+,-,/, *, ^ and √)
- Basic Scientific operation(sin, cos, tan, exp, log and more), the inverses too
- Floating point controls
- Shortcuts for faster opeation
- Bitwise and logic operations for programmers
- Memory and variables
- Multple number bases(dec, hex, bin and oct)

Some key concepts:
- Numbers are only active if it exists on that base
- On hex base active, variables A to F buttons act as numbers
- Square roots are not implied, to calculate the √4 you must input 2√4.
- Multiplication can be input implicitly
- The calculator limits itself to a PS1 layout to unsere compatiility. But the left analog can be used for navegation as it was a dpad.
- On logical operations 1 and 0 are analogs to True and False
- The buffer preserves previous expressions and results. 
- AC clears the buffer and the register, C clear the register, but if pressed again it acts like AC.

## Controls
| Button | Action |
|--|--|
|D-Pad|Navegate Keys|
|A|Press Key|
|B|Backspace|
|Y|Evaluate Result|
|X|Copy Answear|
|R1/R2|Move Float Point|
|L1/L2|Change Mode|
|Select|Open Credits|
|Start|Change Pallete|
