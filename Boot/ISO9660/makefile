#LOS ISO9660 BOOTLOADER MAKEFILE

#Makefile for the ISO9660 bootloader

DIR_ROOT := ../..
include $(DIR_ROOT)/Scripts/config.mk

DIR_TARGET		:= $(DIR_BUILD)
ASFLAGS			:= -f bin

ASM_FILES		:= $(wildcard *.asm)
SYS_FILES		:= $(ASM_FILES:%.asm=$(DIR_BUILD)/%.sys)

TAG				:= $(BLUE)[boot]$(NORMAL)

all: mkdir $(SYS_FILES)
	@echo "$(TAG) $(SUCCESS)"
	
mkdir:
	@mkdir -p $(DIR_TARGET) $(DIR_DEPS)
	
clean:
	@rm -f $(SYS_FILES)
	
$(SYS_FILES): $(DIR_BUILD)/%.sys: %.asm
	@echo "$(TAG) Assembling $< . . ."
	$(AS) $(ASFLAGS) $< -o $@
	
.force: