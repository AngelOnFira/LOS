#---------------------------------------
#MAIN LOS MAKEFILE
#
#Makefile for all kernel and bootloaders
#---------------------------------------

DIR_ROOT := .
include $(DIR_ROOT)/Scripts/config.mk

#BUILD TARGETS

default: iso

bootISO: .force
	@$(MAKE) $(MAKE_FLAGS) --directory=$(DIR_BOOT_ISO)
	
kernel: .force libc
	@$(MAKE) $(MAKE_FLAGS) --directory=$(DIR_KERNEL)

iso: .force bootISO
	@echo "$(BLUE)[iso]$(NORMAL) Making the ISO . . ."
	@$(DIR_SCRIPTS)/mkcdrom.sh 2> /dev/null > /dev/null
	@echo "$(BLUE)[iso] $(SUCCESS)"

clean: .force
	@echo "$(BLUE)[clean]$(NORMAL) Deleteing Generated Files . . ."
	@rm -rf $(DIR_BUILD)
	@echo "$(BLUE)[clean]$(NORMAL) Generated Files Deleted"



.force: