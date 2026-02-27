; program: toggles LED every 1 second
; input: none
; output: port B pin 1

.include "attiny45.asm"
.org 0
.section .text
start:
    ; setup stack
    LDI R16, hi8(RAMEND)
    OUT SPH, R16
    LDI R16, lo8(RAMEND)
    OUT SPL, R16

    SBI DDRB, DDB1 ; output=pin1

toggle:
    SBI PORTB, PB1 ; set LED
    RCALL delay_1s ; delay 1 seconds
    CBI PORTB, PB1 ; clear LED
    RCALL delay_1s ; delay 1 seconds
    RJMP toggle

end:
    RJMP end ; the great wall of mcu

; busy wait timer0 delay
; delay = 1 second
; internal oscillator frequency = 8Mhz, default prescaler = 8
; working frequency = 1Mhz
; timer0 frequency = working frequency / timer prescaler
; cycles required to pass 1 second = timer0 frequency * time = (1Mhz / 1024) * 1 = 976.5625
; using large prescaler introduces some error in delay

; cycle error = [timer0 count before overflow]*[overflow required] - required cycle

; cycle error = 256*4 - 976 = 48 (only multiple of 256 counts) = 256 (no idea)
; actual delay = should be about 1 sec
delay_1s:
    LDI R16, 4 ; timer counter overflow count before return
    LDI R17, 1 << TOV0

    LDI R18, 0x0
    OUT TCNT0, R18 ; timer counter start = 0
    OUT TCCR0A, R18 ; not used
    LDI R18, 0b101
    OUT TCCR0B, R18 ; start timer, normal mode, prescaler = 1024

1:  IN R18, TIFR
    SBRS R18, TOV0 ; skip if overflow
    RJMP 1b

    OUT TIFR, R17 ; clear overflow bit
    DEC R16
    BRNE 1b

    LDI R18, 0x0
    OUT TCCR0B, R18 ; stop timer
    OUT TCCR0A, R18
    RET
