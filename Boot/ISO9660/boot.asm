bits 16

org 0

%include "Include/mem.inc"

;=============================================================================
; LOS Stage One Bootloader for ISO9660 Filesystem
;
; Input registers:
;
;   AX      Boot signature (should be 0xaa55)
;   DL      Boot drive number
;
; Memory layout at boot
;
;   00000000 - 000003FF        1 024 bytes     	Real mode IVT
;   00000400 - 000004FF          256 bytes     	BIOS data area
;   00000500 - 00007BFF       30 464 bytes     	Free
;   00007C00 - 00007DFF          512 bytes    	First-stage boot loader (MBR)
;   00007E00 - 0009FBFF      622 080 bytes     	Free
;   0009FC00 - 0009FFFF        1 024 bytes     	Extended BIOS data area (EBDA)
;   000A0000 - 000BFFFF      131 072 bytes     	BIOS video memory
;   000C0000 - 000FFFFF      262 144 bytes     	ROM
;
; Memory regions added
;
;   00000800 - 00000FFF        2 048 bytes     	Cdrom sector read buffer
;   00003200 - 00003FFF        3 584 bytes     	Global variables
;   00004000 - 00007BFF       27 648 bytes     	Stack
;   00008000 - 0000FFFF       32 768 bytes     	Second-stage boot loader
;
;=============================================================================

boot:

	jmp Memory.Loader1.Segment : .init

	;-----------------------------------------------------------------
	;Initialize Registers
	;-----------------------------------------------------------------
	
	.init:
		;Step 1. Clear Interupts
		cli
		
		;Step 2. Setup the Segment Registers
		mov ax, cs
		mov ds, ax
		mov fs, ax
		mov gs, ax
		
		;Step 3. Setup the temporary(16-bit) stack
		xor ax, ax
		mov ss, ax
		mov sp, Memory.Stack.Top
		
		;Step 4. Set ES segment to 0
		mov es, ax
		
		;Step 5. Reenable Interrupts
		sti
		
		;Step 6. Store the Drive Number
		mov byte[es : Globals.DriveNumber], dl
		
		mov si, String.Boot
		call DisplayString
		
	;-----------------------------------------------------------------
	;Locate the Root Directory
	;-----------------------------------------------------------------
	.findRootDirectory:
		;Step 1. Setup Registers
		mov bx, 0x10
		mov cx, 1
		mov di, Memory.Sector.Buffer
		
		.readVolume:
			;Step 2. Call Read Sectors
			call ReadSectors
			jc .error
			
			;Step 3. Check to see if it is the primary volume descriptor
			mov al, byte [es : Memory.Sector.Buffer]
			cmp al, 0x01
			je .found
			
			;Step 4. Check to see if it is the terminator descriptor
			cmp al, 0xFF
			je .error
			
			;Step 5. Move onto the next sector
			inc bx
			jmp .readVolume
			
		.found:
			;Save the root directory sector for later
			mov bx, [es : Memory.Sector.Buffer + ISO.PVD.RootDirEntry + ISO.DIR.LocationLBA]
			mov word [SectorStore], bx
			
	;-----------------------------------------------------------------
	;Load the Root Directory
	;-----------------------------------------------------------------
	.loadRootDirectory:
		mov cx, 1
		mov di, Memory.Sector.Buffer
		
		call ReadSectors
		jc .error
		
	;-----------------------------------------------------------------
	;Locate the Boot Directory
	;-----------------------------------------------------------------
	.locateBootDirectory:
		.processDirEntryBoot:
			xor ax, ax
			mov al, [es:di + ISO.DIR.Length]
			cmp al, 0
			je .error
			
			cmp byte[es:di + ISO.DIR.LengthOfFileIdentifier], String.BootDir.Length
			jne .nextDirEntryBoot
			
			push di
			mov cx, String.BootDir.Length
			mov si, String.BootDir
			add di, ISO.DIR.FileIdentifier
			cld
			rep cmpsb
			pop di
			je .bootFound
		
		.nextDirEntryBoot:
			add di, ax
			cmp di, Memory.Sector.Buffer + Memory.Sector.Buffer.Size
			jb .processDirEntryBoot
			
		.nextSectorBoot:
			inc bx
			jmp .loadRootDirectory
			
		.bootFound:
			mov bx, [es : di + ISO.DIR.LocationLBA]
			mov word [SectorStore], bx
			
	;-----------------------------------------------------------------
	;Load the Boot Directory
	;-----------------------------------------------------------------
	.loadBootDirectory:
		mov cx, 1
		mov di, Memory.Sector.Buffer
		
		call ReadSectors
		jc .error
	
	;-----------------------------------------------------------------
	;Locate loader.sys
	;-----------------------------------------------------------------
	.locateLoaderSys:
		.processDirEntryLoader:
			xor ax, ax
			mov al, [es:di + ISO.DIR.Length]
			cmp al, 0
			je .error
			
			cmp byte[es:di + ISO.DIR.LengthOfFileIdentifier], String.LoaderSys.Length
			jne .nextDirEntryLoader
			
			push di
			mov cx, String.LoaderSys.Length
			mov si, String.LoaderSys
			add di, ISO.DIR.FileIdentifier
			cld
			rep cmpsb
			pop di
			je .loaderFound
		
		.nextDirEntryLoader:
			add di, ax
			cmp di, Memory.Sector.Buffer + Memory.Sector.Buffer.Size
			jb .processDirEntryLoader
			
		.nextSectorLoader:
			inc bx
			jmp .loadBootDirectory
			
		.loaderFound:
			mov bx, [es : di + ISO.DIR.LocationLBA]
			
	;-----------------------------------------------------------------
	;Load and Jump to loader.sys
	;-----------------------------------------------------------------
	.readLoader:
		.calcSize:
			mov cx, [es:di + ISO.DIR.DataLength + 2]
			cmp cx, 0
			jne .error
			
			mov cx, [es:di + ISO.DIR.DataLength]
			
			cmp cx, 0x8000
			ja .error
			
			add cx, Memory.Sector.Buffer.Size - 1
			shr cx, 11
			
		.load:
			mov ax, Memory.Loader2.Segment
			mov es, ax
			xor di, di
			
			call ReadSectors
			jc .error
			
	.launchLoader:
		mov si, String.EnteringS2
		call DisplayString
	
		jmp  0x0000 : Memory.Loader2
	
	;Error Handling
	.error:
		mov si, String.Fail
		call DisplayString
		
		.hang:
			cli
			hlt
			jmp .hang
		
;=============================================================================
; ReadSectors
;
; Read 1 or more 2048-byte sectors from the CDROM using int 13 function 42.
;
; Input registers:
;   BX      Starting sector LBA
;   CX      Number of sectors to read
;   DL      Drive number
;   ES:DI   Target buffer
;
; Return registers:
;   AH      Return code from int 13 (42h) BIOS call
;
; Flags:
;   CF      Set on error
;
; Killed registers:
;   AX, SI
;=============================================================================
ReadSectors:
	;Step 1. Setup the DAP Buffer
	mov word [DAPBuffer.ReadSectors], cx
	mov word [DAPBuffer.TargetBufferOffset], di
	mov word [DAPBuffer.TargetBufferSegment], es
	mov word [DAPBuffer.FirstSector], bx
	
	;Step 2. Load DS:SI with the Buffer's Address
	lea si, [DAPBuffer]
	
	;Step 3. Call INT 0x13 - 0x42
	mov ax, 0x4200
	int 0x13
	ret
	
;=============================================================================
; DisplayString
;
; Display a null-terminated string to the console using the BIOS int 10
; function 0E.
;
; Input registers:
;   SI      String offset
;
; Killed registers:
;   None
;=============================================================================
DisplayString:
    pusha

	;Step 1. Setup Registers
    mov ah, 0x0E
    xor bx, bx

    cld

    .loop:
        ;Step 2. Read next string character into al register.
        lodsb

        ;Step 3. Break when a null terminator is reached.
        cmp al, 0
        je  .done

        ;Step 4. Call INT 0x10 - 0x0E
        int 0x10
        jmp .loop

    .done:
        popa
        ret

;STRINGS
String.Fail					db "[LOS] ERROR: Failed to load", 0x0D, 0x0A, 0
String.Boot					db "[LOS] Booting LOS . . .", 0x0D, 0x0A, 0
String.EnteringS2			db "[LOS] Entering Stage 2 . . .", 0x0D, 0x0A, 0

String.BootDir				db "BOOT"
String.BootDir.Length		equ ($ - String.BootDir)
							db 0
String.LoaderSys			db "LOADER.SYS;1"
String.LoaderSys.Length		equ ($ - String.LoaderSys)
							db 0
	
;OTHER VARIABLES
DAPBuffer:
	.Bytes					db BIOS.DAP.Size
	.Zero					db 0
	.ReadSectors			dw 0
	.TargetBufferOffset 	dw 0
	.TargetBufferSegment	dw 0
	.FirstSector			dq 0
	
SectorStore		dw 0
	
times 0x1FE - ($ - $$) db 0
signature dw 0xAA55