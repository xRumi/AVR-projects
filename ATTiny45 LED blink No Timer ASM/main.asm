; program: toggles LED every 1 second
; input: none
; output: port B pin 1

.include "attiny45.asm"
.org 0
.section .text
start:
    ; setup stack
    LDI R16, hi8(SRAM_END_ADDR)
    OUT SPH, R16
    LDI R16, lo8(SRAM_END_ADDR)
    OUT SPL, R16

    SBI DDRB, DDB1 ; output=pin1
    NOP ; synchronize delay for DDRB to take effect (not needed)
    LDI R16, 1 << PINB1
    MOV R0, R16 ; load r0 with r16
    EOR R1, R1 ; or use CLR R1
toggle:
    EOR R1, R0 ; toggle pin1
    OUT PORTB, R1 ; send to port B
    RCALL delay_1s ; delay 1 seconds
    RJMP toggle

end:
    RJMP end ; the great wall of mcu

; busy wait delay
; delay = 1 second
; internal oscillator frequency = 8Mhz, default prescaler = 8
; working frequency = 1Mhz
; cycles required to pass 1 second = cycle frequency * time = 1Mhz * 1sec = 1,000,000

; cycle error = [L3 cycle]*[L3 executed] + [L2 cycle excluding L3]*[L2 executed] + [L1 cycle excluding L2 & L3]*[L2 executed]
;     - [brance not taken = 1]*[L2 executed]*[L1 executed] - [brance not taken = 1]*[L1 executed] ;; not sure about this one & not very impactful either
;     - required cycle
; we need to minimize cycle error by trial and error. change only 3 variables (R16, R17, r18)

; cycle error = 5*255*196*4 + 4*196*4 + 4*4 - 1*196*4 - 1*4 - 1,000,000 = 1964 (wasting more cycles than required)
; actual delay = 1 sec + 1964 * (1 / 10^6) = 1.001964 sec
delay_1s:
    LDI R16, 4
L1:
    LDI R17, 196
L2:
    LDI R18, 0xFF; takes 1 cycle
L3:
    NOP ; takes 1 cycle
    NOP
    DEC R18 ; takes 1 cycle
    BRNE L3 ; takes 2 cycle if branch otherwise 1 cycle
    ; L3 cycle = 1 + 1 + 1 + 2 = 5
    
    DEC R17
    BRNE L2
    ; L2 cycle excluding L3 = 1 + 1 + 2 = 4
    
    DEC R16
    BRNE L1
    ; L1 cycle excluding L2 & L3 = 1 + 1 + 2 = 4
    RET ; takes 4 cycle (ignored)

; as loading r16 with 4 gives us 1 sec delay then, delay(t) = 4 * t
