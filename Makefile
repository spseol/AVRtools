# AVR project Makefile
# wykys 2018


######################################
# project variables
######################################
# target name
TARGET = DEMO
# chip
CHIP = atmega328p
# programmer
PROG = -c arduino -P /dev/ttyUSB0
# optimalization
OPT = -Og
# build dir
BUILD_DIR = build
# source dir
SRC = src
# includes
INC = -Iinc


######################################
# source
######################################
# C sources
C_SOURCES = $(wildcard $(SRC)/*.c)
# ASM sources
ASM_SOURCES = $(wildcard $(SRC)/*.S)


#######################################
# toolchain
#######################################
#fixed AVR toolchain bug
FIXED_LC_ALL = export LC_ALL=C
TOOLCHAIN_PATH = /opt/avr8-gnu-toolchain-linux_x86_64
BINPATH = $(TOOLCHAIN_PATH)/bin/
PREFIX = avr-
CC = $(FIXED_LC_ALL) && $(BINPATH)$(PREFIX)gcc -fdiagnostics-color=always
AS = $(FIXED_LC_ALL) && $(BINPATH)$(PREFIX)gcc -fdiagnostics-color=always -x assembler-with-cpp
CP = $(FIXED_LC_ALL) && $(BINPATH)$(PREFIX)objcopy
DP = $(FIXED_LC_ALL) && $(BINPATH)$(PREFIX)objdump
AR = $(FIXED_LC_ALL) && $(BINPATH)$(PREFIX)ar
SZ = $(FIXED_LC_ALL) && $(BINPATH)$(PREFIX)size
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S
RM = rm -rf
# python scripts
SCRIPTS_DIR = .scripts/
WTR = $(SCRIPTS_DIR)$(PREFIX)translate-mcu.py --mcu=$(CHIP)
WSZ = $(SCRIPTS_DIR)$(PREFIX)size.py --mcu=$(CHIP) -c
# avrdude
AVRDUDE = avrdude -p $(shell $(WTR)) $(PROG)


#######################################
# build the application
#######################################
# compile gcc flags
MCU = -mmcu=$(CHIP)
AFLAGS = $(MCU) -Wall $(INC)
CFLAGS = $(MCU) -Wall -std=c99 $(INC) $(OPT)
LDFLAGS = $(MCU)  -Wl,-Map=$(BUILD_DIR)/$(TARGET).map -Wl,--cref

# generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"

# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# add ASM to objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.S=.o)))
vpath %.S $(sort $(dir $(ASM_SOURCES)))

# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/EEPROM.hex $(BUILD_DIR)/$(TARGET).lss size
# create object files from C files
$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	@$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@
# create object files from ASM files
$(BUILD_DIR)/%.o: %.S Makefile | $(BUILD_DIR)
	@$(AS) -c $(AFLAGS) $< -o $@
# create aplication ELF file
$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@
# create aplication FLASH intel HEX file
$(BUILD_DIR)/$(TARGET).hex: $(BUILD_DIR)/$(TARGET).elf
	@$(HEX) -R .eeprom $< $@
# create aplication EEPROM intel HEX file
$(BUILD_DIR)/EEPROM.hex: $(BUILD_DIR)/$(TARGET).elf
	@$(HEX) -j .eeprom --change-section-lma .eeprom=0 $< $@ 2> /dev/null
# disassembly EFL
$(BUILD_DIR)/$(TARGET).lss: $(BUILD_DIR)/$(TARGET).elf
	@$(DP) -h -S $< > $@
# create build directory
$(BUILD_DIR):
	@mkdir $@
# prints memory usage tables
size:
	@$(WSZ) -e $(BUILD_DIR)/$(TARGET).elf
# clean up
clean:
	@$(RM) $(BUILD_DIR)


#######################################
# avrdude
#######################################
terminal:
	@$(AVRDUDE) -t
dump_eeprom:
	@echo "dump eeprom" | $(AVRDUDE) -t
flash:
	@$(AVRDUDE) -U flash:w:$(BUILD_DIR)/$(TARGET).elf:e
flash_all:
	@$(AVRDUDE) -U flash:w:$(BUILD_DIR)/$(TARGET).elf:e -U eeprom:w:$(BUILD_DIR)/$(TARGET).elf:e
chip_test:
	@$(AVRDUDE)
build_and_flash: all flash
