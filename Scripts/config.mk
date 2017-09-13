#-----------------------------------------------------
#
#The following must be set before including this file
#
#	DIR_ROOT	The Root Directory of the Project
#
#-----------------------------------------------------

#DIRECTORIES
DIR_BOOT		:= $(DIR_ROOT)/Boot
DIR_BOOT_ISO 	:= $(DIR_BOOT)/ISO9660
DIR_BUILD		:= $(DIR_ROOT)/Build
DIR_INCLUDE		:= $(DIR_ROOT)/Include
DIR_SCRIPTS		:= $(DIR_ROOT)/Scripts

#TOOL CONFIG
TARGET			:= x86_64-elf

CC				:= $(TARGET)-gcc

CPP				:= $(TARGET)-g++

CCFLAGS			:= -std=gnu111 -I$(DIR_INCLUDE) -Qn -g -m64 -mno-red-zone -mno-mmx -mfpmath=sse -masm=intel -ffreestanding -fno-asynchronous-unwind-tables -Wall -Wextra -Wpedantic

AS				:= nasm

ASFLAGS			:= -f elf64

LDFLAGS			:= -g -nostdlib -m64 -mno-red-zone -ffreestanding -lgcc -z max-page-size=0x1000

MAKE_FLAGS		:= --quiet --no-print-directory

QEMU			:= qemu-system-x86_64-elf

#COLOR MACROS
BLUE		:= \033[1;34m
YELLOW		:= \033[1;33m
NORMAL		:= \033[0m

SUCCESS		:= $(YELLOW)SUCCESS$(NORMAL)