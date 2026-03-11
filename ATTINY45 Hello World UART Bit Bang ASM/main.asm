; program : Send "hello world!" using UART Bit banging, hell yeah
; input   : none
; output  : port B pin 1 (as TX)

.include "attiny45.asm"

.section .text
.org 0x00                           ; interrupt vectors (byte addressed)
    RJMP RESET
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

    LDI R16, 1 << OCIE0A
    OUT TIMSK, R16                  ; enable output comapare A interrupt on timer0
    SEI                             ; enable global interrupt

    ; baud rate = 1200
    ; clk = 1Mhz (default fuse)
    ; timer0 prescaller = 8
    ; send 1 bit per OCR0A match
    ; OCR0A = 1/(baud rate) * clk/prescaller = 1/1200 * 1e6/8 = 104.166

    ; set up timer0
    LDI R16, 0
    OUT TCNT0, R16                  ; start count from 0
    LDI R16, 104
    OUT OCR0A, R16                  ; count to 104 then trigger interrupt

    LDI R16, 0b10
    OUT TCCR0A, R16                 ; CTC mode - clear timer on  compare match A
    LDI R16, 0b10
    OUT TCCR0B, R16                 ; clock select = clk / 8; start timer0

    LDI R17, 0                      ; tx bit index: start = 0, idle = 10
    LDI ZH, hi8(hello_world)        ; load flash address to hello world string
    LDI ZL, lo8(hello_world)        ; avr-as is byte addressed, no need for shift or anything
    
    LPM R18, Z+                     ; tx data: load program memory and point Z to next char
    ; from now one, r17 & r18 reserved to TX

end: RJMP end                       ; idle loop. we can also go to sleep here (idle mode)

TIMER0_COMPA:                       ; on TCNT0 == OCR0A
    CPI R17, 0                      ; idle bit = 1, start bit = 0, end bit = 1 (if single end bit, else, 1 1)
    BREQ tx_clear_bit               ; send the start , 0
    CPI R17, 9
    BREQ tx_end_bit                 ; send the end bit, 1
    CPI R17, 10
    BREQ tx_set_idle

    LSR R18                         ; logical shift to right, shifted bit is in the carry
    BRCS tx_set_bit

tx_clear_bit:
    CBI PORTB, PB1                  ; send 0
    INC R17                         
    RETI
tx_end_bit:
    LPM R18, Z+                     ; load char at Z and post increment Z
    CPI R18, 0                      ; if null char
    BREQ tx_set_idle                ; nothing to send
    LDI R17, 0xFF                   ; else more to send and also the end bit, 1
tx_set_bit:
    SBI PORTB, PB1                  ; send 1
    INC R17
    RETI
tx_set_idle:                        ; idle, we can also stop the timer0
    SBI PORTB, PB1                  ; idle bit = 1
    LDI R17, 10
    RETI

hello_world:
    .string "Hello world!\n"
