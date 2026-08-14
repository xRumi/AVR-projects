main.hex: main.elf
	avr-objcopy main.elf -O ihex main.hex

main.elf: main.o
	avr-ld main.o -o main.elf

main.o: main.asm
	avr-as main.asm -o main.o

upload: main.hex
	sudo avrdude -c usbasp -p attiny45 -U flash:w:main.hex:i

clean:
	rm main.elf main.hex main.o

.PHONY: clean upload
