#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define F_CPU 8000000UL
#include <util/delay.h>

#define TX _BV(PB0)
#define LED _BV(PB1)
#define DHT11 _BV(PB4)
#define DHT11_INPUT (PINB & DHT11)

volatile uint32_t timer0_ovf_count = 0;
ISR(TIMER0_OVF_vect) {
    timer0_ovf_count++;
}

volatile uint8_t tx;
ISR(TIMER1_COMPA_vect) {
    static uint8_t count = 0;
    if (count == 0) {
        PORTB &= ~TX; // send start bit, 0
    } else if (count == 9) {
        PORTB |= TX; // send stop bit, 1
        count = 0xFF;
        TCCR1 = 0; // stop timer1
    } else {
        uint8_t bit = tx & 1;
        tx >>= 1;
        if (bit) PORTB |= TX;
        else PORTB &= ~TX;
    }
    count++;
}
static inline void print(const char* str) {
    for (uint8_t i = 0; str[i]; i++) {
        while (TCCR1) sleep_mode();
        tx = str[i];
        TCCR1 = 0b10000110;
    }
}

uint32_t micros() {
    uint32_t ovfs;
    uint8_t t;

    cli();
    ovfs = timer0_ovf_count;
    t = TCNT0;
    if (TIFR & _BV(OCF0A)) ovfs++;
    sei();

    return (ovfs << 8) + t;
}

static inline void ioint(void) {
    TIMSK = _BV(TOIE0) | _BV(OCIE1A);

    // timer0
    TCNT0 = 0;
    TCCR0A = 0;
    TCCR0B = 0b10;

    // timer1
    TCNT1 = 0;
    OCR1C = 208;
    OCR1A = 208;

    sei();

    DDRB |= LED | DHT11 | TX; // output
    PORTB |= DHT11 | TX; // pull high, defaults
}

static inline uint8_t dht11_readBit() {
    while (!DHT11_INPUT); // pull high
    uint32_t ticks = micros();
    while (DHT11_INPUT); // finish
    if (micros() - ticks <= 65) return 0;
    return 1;
}

static char* padByteStr(char* str) {
    uint8_t len = strlen(str);
    uint8_t shift = 8 - len;
    for (int8_t i = len - 1; i >= 0; i--) {
        str[i + shift] = str[i];
    }
    for (uint8_t i = 0; i < shift; i++) {
        str[i] = '0';
    }
    str[8] = 0;
    return str;
}

void dht11() {
    DDRB |= DHT11; // output: mcu to sensor
    PORTB &= ~DHT11; // pull down, start signal, pull down for atleast 18ms
    _delay_ms(30);

    PORTB |= DHT11; // pull high
    DDRB &= ~DHT11; // input: sensor to mcu

    while (DHT11_INPUT); // wait for sensor to pull low
    while (!DHT11_INPUT); // wait for sensor to pull high

    uint8_t data[5] = {};

    while (DHT11_INPUT);
    for (int i = 0; i < 40; i++) {
        data[i / 8] <<= 1;
        data[i / 8] |= dht11_readBit();
    }

    DDRB |= DHT11; // mcu to sensor output

    char numberStr[10];
    print(padByteStr(itoa(data[0], numberStr, 2)));
    print(".");
    print(padByteStr(itoa(data[1], numberStr, 2)));
    print("\n");
    print(padByteStr(itoa(data[2], numberStr, 2)));
    print(".");
    print(padByteStr(itoa(data[3], numberStr, 2)));
    print("\n");
    print(padByteStr(itoa(data[4], numberStr, 2)));
    print("\n");

    if ((uint8_t)(data[0] + data[1] + data[2] + data[3]) == data[4] && data[1] == 0 && data[3] == 0) {
        PORTB ^= LED;
        print("Humidity = ");
        print(itoa(data[0], numberStr, 10));
        print("\n");
        print("Temperature = ");
        print(itoa(data[2], numberStr, 10));
    }
    print("\n");
    print("\n");
}

int main() {
    ioint();
    _delay_ms(1000);

    for(;;) {
        dht11();
        _delay_ms(2000);
    }
    return 0;
}