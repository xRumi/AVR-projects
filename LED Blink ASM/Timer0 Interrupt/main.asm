; program : toggles LED every 1 second
; input   : none
; output  : port B pin 1

.include "attiny45.asm"

.org 0x00               ; interrupt vectors
    RJMP RESET
.org 0x14
    RJMP TIMER0_COMPA
.org 0x20               ; normal code
RESET:
    ; set up stack
    LDI R16, hi8(RAMEND)
    LDI R17, lo8(RAMEND)
    OUT SPH, R16
    OUT SPL, R17

    SBI DDRB, PB1           ; output = port B pin 1
    LDI R16, 1 << PB1
    MOV R0, R16
    MOV R1, R16
    OUT PORTB, R0           ; set port B pin 1
    
    LDI R16, 1 << OCIE0A
    OUT TIMSK, R16          ; enable output comapare A on timer0 interrupt
    SEI                     ; enable global interrupt

    ; target delay = 1 sec
    ; clk = 1Mhz (default fuse)
    ; timer0 prescaller = 1024
    ; timer0 clk = clk / timer0 prescaller = 1*1e6 / 1024 = 976.5625 Hz
    ; total timer0 counts needed = timer0 clk * target delay = 976.5625
    ; interrupt counts needed = timer0 count / (OCR0A + 1) = 976.5625 / 8 = 122.0703
    ; change "timer0 prescaller" & "OCR0A" to acquire nice and whole number
    
    ; set up timer0
    LDI R16, 0
    OUT TCNT0, R16          ; start from 0
    LDI R16, 7
    OUT OCR0A, R16          ; count to 7 + 1 then trigger interrupt
    LDI R16, 122
    MOV R10, R16
    MOV R2, R10             ; required interrupt for delay

    LDI R16, 0b10
    OUT TCCR0A, R16         ; CTC mode - clear timer on compare match
    LDI R16, 0b101
    OUT TCCR0B, R16         ; clock select = clk/1024; start timer0

end: RJMP end               ; idle loop

TIMER0_COMPA:
    DEC R2
    BREQ 1f                 ; if not zero, exit ISR
    RETI
1:  EOR R0, R1
    OUT PORTB, R0           ; toggle port B pin 1
    MOV R2, R10             ; reset interrupt counter
    RETI
    
