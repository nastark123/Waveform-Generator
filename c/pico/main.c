#include <stdio.h>
#include "pico/stdlib.h"
#include "pico/binary_info.h"
#include "hardware/spi.h"
#include "hardware/gpio.h"

uint32_t increment = 1;

void callback(uint gpio, uint32_t events) {
    if(gpio == 2) {
        increment++;
    } else if(gpio == 3 && increment > 1) {
        increment--;
    }
}

int main(void) {

    stdio_init_all();

    // Initialize SPI and its associated pins
    spi_init(spi_default, 1000000);
    spi_set_format(spi_default, 16, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);
    gpio_set_function(PICO_DEFAULT_SPI_RX_PIN, GPIO_FUNC_SPI);
    gpio_set_function(PICO_DEFAULT_SPI_SCK_PIN, GPIO_FUNC_SPI);
    gpio_set_function(PICO_DEFAULT_SPI_TX_PIN, GPIO_FUNC_SPI);
    gpio_set_function(PICO_DEFAULT_SPI_CSN_PIN, GPIO_FUNC_SPI);
    // Make the SPI pins available to picotool
    bi_decl(bi_4pins_with_func(PICO_DEFAULT_SPI_RX_PIN, PICO_DEFAULT_SPI_TX_PIN, PICO_DEFAULT_SPI_SCK_PIN, PICO_DEFAULT_SPI_CSN_PIN, GPIO_FUNC_SPI));

    // Initialize the button interrupts to change the increment value
    gpio_set_irq_enabled_with_callback(2, GPIO_IRQ_EDGE_RISE, true, &callback);
    gpio_set_irq_enabled_with_callback(3, GPIO_IRQ_EDGE_RISE, true, &callback);

    uint16_t sine_buf[] = {2047, 2147, 2247, 2347,
                           2446, 2544, 2641, 2736,
                           2830, 2922, 3011, 3099,
                           3184, 3266, 3345, 3421,
                           3494, 3563, 3629, 3691,
                           3749, 3802, 3852, 3897,
                           3938, 3974, 4005, 4032,
                           4054, 4071, 4084, 4091,
                           4094, 4091, 4084, 4071,
                           4054, 4032, 4005, 3974,
                           3938, 3897, 3852, 3802,
                           3749, 3691, 3629, 3563,
                           3494, 3421, 3345, 3266,
                           3184, 3099, 3011, 2922,
                           2830, 2736, 2641, 2544,
                           2446, 2347, 2247, 2147,
                           2047, 1946, 1846, 1746,
                           1647, 1549, 1452, 1357,
                           1263, 1171, 1082,  994,
                           909,   827,  748,  672,
                           599,   530,  464,  402,
                           344,   291,  241,  196,
                           155,   119,   88,   61,
                           39,     22,    9,    2,
                           0,       2,    9,   22,
                           39,     61,   88,  119,
                           155,   196,  241,  291,
                           344,   402,  464,  530,
                           599,   672,  748,  827,
                           909,   994, 1082, 1171,
                           1263, 1357, 1452, 1549,
                           1647, 1746, 1846, 1946};

    uint32_t index = 0;
    for(;;) {
        // Gain of 1, don't disable channel, write channel A
        uint16_t data_word = sine_buf[(index >> 8)] | 0x3000;

        index += increment;

        if((index >> 8) >= 128) index = 0;

        // Transfer data to DAC
        spi_write16_blocking(spi0, &data_word, 1);

        printf("%d\n", increment);
    }

    return 0;
}