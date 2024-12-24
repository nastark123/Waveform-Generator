cmake_minimum_required(VERSION 3.13)

include(pico_sdk_import.cmake)

project(waveform_generator)

pico_sdk_init()

add_executable(waveform_generator)

target_sources(waveform_generator PUBLIC
        ${CMAKE_CURRENT_LIST_DIR}/main.c
        )

# Make sure TinyUSB can find tusb_config.h
target_include_directories(waveform_generator PUBLIC
        ${CMAKE_CURRENT_LIST_DIR})

# enable usb output, disable uart output
pico_enable_stdio_usb(waveform_generator 1)
pico_enable_stdio_uart(waveform_generator 0)

# In addition to pico_stdlib required for common PicoSDK functionality, add dependency on tinyusb_device
# for TinyUSB device support and tinyusb_board for the additional board support library used by the example
target_link_libraries(waveform_generator PUBLIC pico_stdlib hardware_spi)

# Uncomment this line to enable fix for Errata RP2040-E5 (the fix requires use of GPIO 15)
#target_compile_definitions(usb_wheel PUBLIC PICO_RP2040_USB_DEVICE_ENUMERATION_FIX=1)

pico_add_extra_outputs(waveform_generator)
