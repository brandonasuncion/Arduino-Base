MCU             = atmega328p
BOARD           = standard

BUILD_DIR       = .build
CORE_BUILD_DIR  = $(BUILD_DIR)/core
CORE_LIB        = $(CORE_BUILD_DIR)/core.a

ARDUINO_DIR     = /Applications/Arduino.app/

# includes
CORE_DIR        = $(ARDUINO_DIR)/Contents/Java/hardware/arduino/avr/cores/arduino
BOARD_DIR       = $(ARDUINO_DIR)/Contents/Java/hardware/arduino/avr/variants/$(BOARD)

CORE_MAIN       = $(CORE_DIR)/main.cpp

# bin
BIN_DIR         = $(ARDUINO_DIR)/Contents/Java/hardware/tools/avr/bin
GPP             = $(BIN_DIR)/avr-g++
GCC             = $(BIN_DIR)/avr-gcc
AR              = $(BIN_DIR)/avr-gcc-ar
OBJCOPY         = $(BIN_DIR)/avr-objcopy
AVRSIZE         = $(BIN_DIR)/avr-size


CXX_DEFINES = -DF_CPU=16000000L -DARDUINO=10816 -DARDUINO_AVR_UNO -DARDUINO_ARCH_AVR

# C args
GCC_ARGS = -g -Os -Wall -Wextra -std=gnu11 -ffunction-sections -fdata-sections -MMD -flto -fno-fat-lto-objects \
	-mmcu=$(MCU) $(CXX_DEFINES) \
	-I$(CORE_DIR) -I$(BOARD_DIR)

# C++ args
GPP_ARGS = -g -Os -w -std=gnu++11 -fpermissive -fno-exceptions -ffunction-sections -fdata-sections \
	-fno-threadsafe-statics -Wno-error=narrowing -flto \
	-w -x c++ -E -CC -mmcu=$(MCU) $(CXX_DEFINES) \
	-I$(CORE_DIR) -I$(BOARD_DIR)


CORE_C_SOURCES = $(wildcard $(CORE_DIR)/*.c)
CORE_C_OBJECTS = $(CORE_C_SOURCES:$(CORE_DIR)/%.c=$(CORE_BUILD_DIR)/%.c.o)

CORE_CPP_SOURCES = $(wildcard $(CORE_DIR)/*.cpp)
CORE_CPP_OBJECTS = $(CORE_CPP_SOURCES:$(CORE_DIR)/%.cpp=$(CORE_BUILD_DIR)/%.cpp.o)

CORE_OBJECTS = $(CORE_C_OBJECTS) $(CORE_CPP_OBJECTS)

.PHONY: all
all: clean $(CORE_LIB) $(BUILD_DIR)/main.hex

.PHONY: clean
clean:
	rm -f $(BUILD_DIR)/*.*
	mkdir -p $(BUILD_DIR)
	mkdir -p $(CORE_BUILD_DIR)


$(BUILD_DIR)/main.cpp : sketch.ino
	echo '#include "Arduino.h"' > $@
	cat $^ >> $@
	cat $(CORE_DIR)/main.cpp >> $@

$(BUILD_DIR)/main.o : $(BUILD_DIR)/main.cpp
	$(GCC) -c $(GCC_ARGS) $^ -o $@

$(CORE_BUILD_DIR)/%.c.o : $(CORE_DIR)/%.c
	$(GCC) -c $(GCC_ARGS) $^ -o $@

$(CORE_BUILD_DIR)/%.cpp.o : $(CORE_DIR)/%.cpp
	$(GPP) -c $(GPP_ARGS) $^ -o $@

$(CORE_LIB) : $(CORE_C_OBJECTS) $(CORE_CPP_OBJECTS)
	$(AR) rcs $@ $^

$(BUILD_DIR)/main.elf: $(BUILD_DIR)/main.o $(CORE_LIB)
	$(GCC) -Wall -Wextra -Os -g -flto -fuse-linker-plugin -Wl,--gc-sections \
		-mmcu=$(MCU) -o $@ $^ \
		-L$(BUILD_DIR) -lm

$(BUILD_DIR)/main.hex : $(BUILD_DIR)/main.elf
	$(OBJCOPY) -O ihex -R .eeprom $^ $@
