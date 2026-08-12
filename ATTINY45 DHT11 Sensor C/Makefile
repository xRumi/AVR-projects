main.hex: main.out
	avr-objcopy main.out -O ihex main.hex

main.out: main.o
	avr-gcc -mmcu=attiny45 -mrelax main.o -o main.out

main.o: main.c
	avr-gcc -g -O2 -mmcu=attiny45 -c main.c -o main.o

upload: main.hex
	sudo avrdude -c usbasp -p attiny45 -U flash:w:main.hex:i

clean:
	rm main.out main.hex main.o

.PHONY: clean upload
