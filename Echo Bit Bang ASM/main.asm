; program : Echo UART bit banging, hell yeah
; input   : port B pin 4 (as RX)
; output  : port B pin 1 (as TX)

.include "attiny45.asm"

.section .text
.org 0x00                           ; interrupt vectors
    RJMP RESET
.org 0x4
    RJMP PCINT0_ISR
.org 0x6
    RJMP TIMER1_COMPA
.org 0x14
    RJMP TIMER0_COMPA
.org 0x20                           ; code
RESET:
    ; set up stack
    LDI R16, hi8(RAMEND)
    LDI R17, lo8(RAMEND)
    OUT SPH, R16
    OUT SPL, R17

    SBI DDRB, PB1                   ; output = port B pin 1
    SBI PORTB, PB1                  ; set port B pin 1 (idle bit, 1)
    SBI PORTB, PB4                  ; pull up resistor (idle bit, 1)

    NOP
    NOP

    SBI PCMSK, PCINT4               ; enable interrupt on level change on PB4
    LDI R16, 1 << PCIE
    OUT GIMSK, R16
    
    LDI R16, (1 << OCIE0A) | (1 << OCIE1A)
    OUT TIMSK, R16                  ; enable OCR0A and OCR1A interrupt
    SEI                             ; enable global interrupt

    ; baud rate = 1200
    ; clk = 1Mhz (default fuse)
    ; timer0 prescaller = 8
    ; timer1 prescaller = 8
    ; send 1 bit per OCR0A match and receive 1 bit per OCR1A match
    ; OCR0A = 1/(baud rate) * clk/prescaller = 1/1200 * 1e6/8 = 104.166

    ; set up timer0
    LDI R16, 0
    OUT TCNT0, R16                  ; start from 0
    LDI R16, 104
    OUT OCR0A, R16                  ; count to 104 then trigger interrupt

    LDI R16, 0b10
    OUT TCCR0A, R16                 ; CTC mode - clear timer on compare match A
    LDI R16, 0b10
    OUT TCCR0B, R16                 ; clock select = clk / 8; start timer0

    LDI R17, 0                      ; tx bit index: start = 0, idle = 10
    LDI R18, 'R'                    ; tx data: send 'R' to indicate Ready
    ; from now on, r17 & r18 reserved to TX

    LDI R19, 0                      ; rx bit index
    LDI R20, 0                      ; rx data
    ; from now on, r19 & r20 reserved to RX

end: RJMP end                       ; idle loop. We can also go to sleep here (idle mode)

TIMER0_COMPA:                       ; on TCNT0 == OCR0A
    CPI R17, 0                      ; idle bit = 1, start bit = 0, end bit = 1 (if single end bit, else, 1 1)
    BREQ tx_clear_bit               ; send the start bit, 0
    CPI R17, 9
    BREQ tx_set_bit                 ; send the end bit, 1
    CPI R17, 10
    BREQ tx_end

    LSR R18                         ; logical shift to right, shifted bit is in the carry
    BRCS tx_set_bit

tx_clear_bit:
    CBI PORTB, PB1                  ; send 0
    INC R17
    RETI
tx_set_bit:
    SBI PORTB, PB1                  ; send 1
    INC R17
    RETI
tx_end:
    LDI R17, 0
    OUT TCCR0B, R17                 ; stop timer0
    RETI

PCINT0_ISR:                         ; on level change on PB4, indicating start of RX
    CBI PCMSK, PCINT4               ; wait until receive is done
    LDI R21, 156                    ; 104 + (104 / 2) = 156
    OUT OCR1A, R21                  ; wait for 1.5 bit time(middle of the next bit) after start bit, 0
    OUT OCR1C, R21
    LDI R21, 0b10000100             ; CTC mode - clear timer on compare match C
    OUT TCCR1, R21                  ; clock select = clk / 8; start timer1
    RETI

TIMER1_COMPA:
    CPI R19, 0
    BRNE not_first_bit              ; if first bit
    LDI R21, 104                    ; wait for 1 bit time
    OUT OCR1A, R21
    OUT OCR1C, R21
    LDI R20, 0                      ; reset rx data
not_first_bit:
    INC R19
    CLC
    SBIC PINB, PB4
    SEC
    ROR R20                         ; load data into r20

    CPI R19, 8
    BREQ rx_end
    RETI
rx_end:                             ; byte received, now transmit received byte
    LDI R19, 0

    LDI R21, 0
    OUT TCCR1, R21                  ; stop timer1, stop RX

    LDI R17, 0                      ; tx bit index
    MOV R18, R20                    ; tx data
    LDI R21, 0b10
    OUT TCCR0B, R21                 ; start timer0, start TX

    SBI PCMSK, PCINT4               ; wait for next receive

    RETI

hello_world:
    .string "Hello world!\n"
