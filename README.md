# AVR-projects
A collection of standalone AVR projects written for ATtiny45 in Assembly and C. Each project is self-contained with its own Makefile.

# Projects
| Project | Description | I/O |
|---------|:-----------:|-----|
| [LED Blink ASM](<LED Blink ASM>) | Contains 3 sub-projects that toggles an LED every second in 3 different ways | `PB1`(LED) |
| [Hello World Bit Bang ASM](<Hello World Bit Bang ASM>) | As ATtiny45 does not have UART hardward, `Hello world!` is bit-banged through Tx | `PB1`(Tx) |
| [Echo Bit Bang ASM](<Echo Bit Bang ASM>) | Bit-banged UART. Echos back every bytes. | `PB1`(Tx), `PB4`(Rx) |
| [DHT11 Sensor C](<DHT11 Sensor C>) | Reads DHT11 sensor and streams raw data bytes over bit-banged UART Tx line. Toggles LED on valid checksum. | `PB0`(Tx), `PB1`(LED), `PB4`(DHT11 data) |

# Requirements
## Hardware
1. ATtiny45
2. USBasp ISP programmer
3. LEDs, Resistors
4. USB-to-Serial (TTL) for UART to Computer
5. DHT11 sensor

## Toolchain
1. **avr-gcc**, **avr-binutils**, **avr-libc** (Compiler & Library)
2. **avrdude** (Flashing)
3. **make** (Build System)

### Arch Linux
```bash
sudo pacman -S avr-gcc avr-libc avrdude make
```

# Building & Flashing
```
cd project_name
make
make upload
make clean
```
|<img src="./LED Blink ASM/circuit_label.jpg" height="256">|<img src="./Hello World Bit Bang ASM/pictures/circuit_label.jpg" height="256">|
|:-:|:-:|
|<img src="./DHT11 Sensor C/pictures/circuit_label.jpg" height="256">|<img src="./Echo Bit Bang ASM/pictures/circuit_label.jpg" height="256">|
|<img src="./DHT11 Sensor C/pictures/cutecom.png" width="256">|<img src="./Echo Bit Bang ASM/pictures/cutecom.png" width="300">|