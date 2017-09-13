bits 16

org 0x8000

jmp Stage2

%include "Include/mem.inc"

;=============================================================================
; LOS Stage Two Bootloader for ISO9660 Filesystem
;
; Memory layout at start of this code
;
;   00000000 - 000003FF        1 024 bytes		Real mode IVT
;   00000400 - 000004FF          256 bytes     	BIOS data area
;   00000500 - 000006FF			 512 bytes	   	Global Variables
;   00000700 - 00007BFF       29 952 bytes     	Free
;   00007C00 - 00007DFF          512 bytes     	First-stage boot loader (MBR)
;   00007E00 - 00007FFF     	 512 bytes     	Free
;	00008000 - 0000FFFF		  32 768 bytes	   	Second-stage boot loader
;	00010000 - 0009FBFF		 588 800 bytes	   	Free
;   0009FC00 - 0009FFFF        1 024 bytes     	Extended BIOS data area (EBDA)
;   000A0000 - 000BFFFF      131 072 bytes     	BIOS video memory
;   000C0000 - 000FFFFF      262 144 bytes    	ROM
;
; Memory regions added/used
;	
;	00000700 - 000007FF			 256 bytes		Video Mode Buffer
;   00000800 - 00000FFF		   2 048 bytes		Cdrom sector read buffer
;	00003000 - 000030FF			 256 bytes		Global Descriptor Table (GDT)
;	00003100 - 000031FF			 256 bytes		Task State Segment (TSS)
;	00003200 - 00003FFF		   3 584 bytes		Global Variables
;	00004000 - 00007BFF		  16 384 bytes		Real Mode Stack
;	00010000 - 00017FFF		  32 768 bytes		Page Tables
;	0006F000 - 0006FFFF		   4 096 bytes		Protected Mode Stack
;	00070000 - 0007FFFF		  65 536 bytes		Kernel Load Buffer
;   00070000 - 00075FFF		  24 576 bytes		Memory Table(from BIOS)
;	0008A000 - 0008FFFF		  24 576 bytes		Kernel Special Interrupt Stacks
;	00100000 - 001FEFFF	   1 044 480 bytes		Kernel Interrupt Stack
;	00200000 - 002FFFFF	   1 048 576 bytes		Kernel Stack
;	00300000 - (krnize)    						Kernel Image
;
;=============================================================================

Console		db	1	;Can be set by the kernel at shutdown. If it is 0 - Then boot into graphics mode, otherwise boot into console mode

;THINGS TO DO
;1. Setup various registers
;2. Switch Graphics Mode unless [Console] is set
;3. Enable the A20 Line
;4. Detect if it is a 64-Bit CPU
;5. Enable SSE
;6. Load the Kernel into Memory
;7. Load the ISO9660 Filesystem Driver into Memory
;8. Get the Memory Layout from the BIOS
;9. Wipe Loader Memory
;10. Setup (Don't Install) 64-Bit GDT
;11. Setup (Don't Install) 64-Bit TSS
;12. Setup Page Tables and Enable PAE Paging
;13. Enable 64-Bit Protected Mode and Paging
;14. Launch the Kernel

Stage2:
	;STEP 1. Setup Various Registers
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	
	mov sp, Memory.Stack.Top
	
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor si, si
	xor di, di
	xor bp, bp
	
	mov si, Strings.WelcomeToStage2
	call DisplayString
	
	;STEP 2. Switch Graphics Mode unless [Console] is set
	
	mov di, Memory.Sector.Buffer
	mov ax, 0x4F00
	int 0x10
	
	cmp ax, 0x004F
	jne Errors.VBEError
	
	;Check Console
	mov bl, [Console]
	test bl, 1
	jnz .SetConsoleMode
	
	.SetGraphicsMode:
		mov si, Strings.SettingGraphicsMode
		call DisplayString
		
		call SetGraphicsMode
		
		jmp .EnableA20
	
	.SetConsoleMode:
		mov si, Strings.SettingConsoleMode
		call DisplayString
		
		call SetConsoleMode
		
	;STEP 3. Enable the A20 Line
	.EnableA20:
		mov si, Strings.EnablingA20
		call DisplayString
	
		call EnableA20
		jnc Errors.A20
	
	;STEP 4. Detect if it is a 64-Bit CPU
	.Detect64Bit:
		mov si, Strings.Detecting64Bit
		call DisplayString

		call HasCPUID
		cmp eax, 0
		je Errors.64Bit
		
		mov eax, 0x80000000
		cpuid
		cmp eax, 0x80000001
		jb Errors.64Bit
		
		mov eax, 0x80000001
		cpuid
		test edx, (1 << 29)
		jz Errors.64Bit
		
	;STEP 5. Enable SSE
	.EnableSSE:
		mov si, Strings.EnablingSSE
		call DisplayString
		
		;Steps:
		;1. Load CPU Features into ecx and edx
		mov eax, 1
		cpuid
		
		;2. Check for FXSAVE/FXSTOR supported
		test edx, (1 << 24)
		jz Errors.SSE
		
		;3. Check for SSE1 Support
		test edx, (1 << 25)
		jz Errors.SSE
		
		;4. Check for SSE2 Support
		test edx, (1 << 26)
		jz Errors.SSE
		
		;5. Enable hardware FPU with monitoring
		mov eax, cr0
		and eax, ~(1 << 2)
		or eax, (1 << 2)
		mov cr0, eax
		
		mov eax, cr4
		or eax, (1 << 9) | (1 << 10)
		mov cr4, eax
		
	;STEP 6. Load the Kernel
	.LoadKernel:
		mov si, Strings.LoadingKernel
		call DisplayString
	
		jmp Errors.hang
	
;=============================================================================
; ERROR HANDLING
;=============================================================================
Errors:
	.VBEError:
		mov si, Strings.VBEError
		call DisplayString
		
		jmp .hang
		
	.A20:
		mov si, Strings.A20Error
		call DisplayString
		
		jmp .hang
		
	.64Bit:
		mov si, Strings.64BitError
		call DisplayString
		
		jmp .hang
		
	.SSE:
		mov si, Strings.SSEError
		call DisplayString
		
		jmp .hang
		
	.hang:
		cli
		hlt
		jmp .hang
		
;=============================================================================
; FUNCTIONS
;=============================================================================

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

	mov al, byte [Console]
	test al, 2
	jnz .done
	
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

;=============================================================================
; SetGraphicsMode
;
; Sets the video mode to an appropriate graphics mode
;
; Killed registers:
;   None
;=============================================================================
SetGraphicsMode:
	pusha
	
	mov si, word [Memory.Sector.Buffer + Video.VGAInfo.VideoModePtr]
	mov di, Memory.Video.ModeBuffer
	
	.loop:
		lodsw
		
		cmp ax, 0xFFFF
		je .loopDone
		
		mov cx, ax
		mov ax, 0x4F01
		int 0x10
		
		cmp ax, 0x004F
		jne Errors.VBEError
		
		mov ax, word [Memory.Video.ModeBuffer]
		
		test ax, 0x0010
		jz .loop
		
		mov al, byte [Memory.Video.ModeBuffer + Video.Mode.BPP]
		mov ah, byte [BestBpp]
		cmp ah, al
		
		js .newBest
		jz .equal
		
		jmp .loop
		
	.equal:
		mov ax, word [Memory.Video.ModeBuffer + Video.Mode.Width]
		mov bx, word [Memory.Video.ModeBuffer + Video.Mode.Height]
		
		add ax, bx
		
		mov bx, word [BestRes]
		
		cmp bx, ax
		jns .loop
		
	.newBest:
		mov ax, word [Memory.Video.ModeBuffer + Video.Mode.Width]
		mov bx, word [Memory.Video.ModeBuffer + Video.Mode.Height]
		
		add ax, bx
		
		mov word [BestRes], ax
		mov word [BestMode], cx
		mov al, byte [Memory.Video.ModeBuffer + Video.Mode.BPP]
		mov byte [BestBpp], al
		
		jmp .loop
		
	.loopDone:
		mov ax, 0x4F02
		mov bx, word [BestMode]
		mov di, Memory.Sector.Buffer
		int 0x10
	
		mov ax, 0x4F01
		mov cx, word [BestMode]
		mov di, Memory.Video.ModeBuffer
		int 0x10
	
		mov al, byte [Console]
		or al, 0x2
		mov byte [Console], al
	
		popa
		ret
		
;=============================================================================
; SetConsoleMode
;
; Sets the video mode to an appropriate graphics mode
;
; Killed registers:
;   None
;=============================================================================
SetConsoleMode:
	pusha
	
	mov si, word [Memory.Sector.Buffer + Video.VGAInfo.VideoModePtr]
	mov di, Memory.Video.ModeBuffer
	
	.loop:
		lodsw
		
		cmp ax, 0xFFFF
		je .loopDone
		
		mov cx, ax
		mov ax, 0x4F01
		int 0x10
		
		cmp ax, 0x004F
		jne Errors.VBEError
		
		mov ax, word [Memory.Video.ModeBuffer]
		
		test ax, 0x0010
		jnz .loop
		
		mov ax, word [Memory.Video.ModeBuffer + Video.Mode.Width]
		mov bx, word [Memory.Video.ModeBuffer + Video.Mode.Height]
		
		add ax, bx
		
		mov bx, word [BestRes]
		
		cmp bx, ax
		jns .loop
		
	.newBest:
		mov ax, word [Memory.Video.ModeBuffer + Video.Mode.Width]
		mov bx, word [Memory.Video.ModeBuffer + Video.Mode.Height]
		
		add ax, bx
		
		mov word [BestRes], ax
		mov word [BestMode], cx
		
		jmp .loop
		
	.loopDone:
		mov ax, 0x4F02
		mov bx, word [BestMode]
		mov di, Memory.Sector.Buffer
		int 0x10
	
		mov ax, 0x4F01
		mov cx, word [BestMode]
		mov di, Memory.Video.ModeBuffer
		int 0x10
	
		mov al, byte [Console]
		and al, 0x1
		mov byte [Console], al
	
		popa
		ret
		
;=============================================================================
; EnableA20
;
; Enables the A20 Line
;
; Killed registers:
;   None
;=============================================================================
EnableA20:
	push ax
	
	call TestA20
	jc .done
	
	.attempt1:
		mov ax, 0x2401
		int 0x15
		
		call TestA20
		jc .done
		
	.attempt2:
		call .attempt2.wait1
		
		mov al, 0xAD
		out 0x64, al
		call .attempt2.wait1
		
		mov al, 0xD0
		out 0x64, al
		call .attempt2.wait2
		
		in al, 0x60
		push eax
		call .attempt2.wait1
		
		mov al, 0xD1
		out 0x64, al
		call .attempt2.wait1
		
		pop eax
		or al, 2
		out 0x60, al
		call .attempt2.wait1
		
		mov al, 0xAE
		out 0x64, al
		call .attempt2.wait1
		
		call TestA20
		jc .done
		
		jmp .attempt3
		
		.attempt2.wait1:
			in al, 0x64
			test al, 2
			jnz .attempt2.wait1
			ret
			
		.attempt2.wait2:
			in al, 0x64
			test al, 1
			jz .attempt2.wait2
			ret
			
	.attempt3:
		in al, 0x92
		or al, 2
		out 0x92, al
		xor ax, ax
		
		call TestA20
		
	.done:
		pop ax
		
		ret
	
;=============================================================================
; TestA20
;
; Check to see if the A20 address line is enabled.
;
; Return flags:
;   CF      Set if enabled
;
; Killed registers:
;   None
;=============================================================================
TestA20:
	push ds
	push es
	pusha
	
	clc
	
	xor ax, ax
	mov es, ax
	
	not ax
	mov ds, ax
	
	mov di, 0x0500
	mov si, 0x0510
	
	mov ax, [es:di]
	push ax
	mov ax, [ds:si]
	push ax
	
	mov byte [es:di], 0x00
	mov byte [ds:si], 0xFF
	
	cmp byte [es:di], 0xFF
	
	pop ax
	mov [ds:si], ax
	pop ax
	mov [es:di], ax
	
	je .done
	
	.enabled:
		stc
		
	.done:
		popa
		pop es
		pop ds
		
		ret
		
;=============================================================================
; HasCPUID
;
; Detects whether the CPU supports the CPUID command
;
; Return flags:
;   eax      zero if not available
;
; Killed registers:
;   None
;=============================================================================
HasCPUID:
	pushfd
	pushfd
	xor dword [esp], 0x00200000
	popfd
	pushfd
	pop eax
	xor eax, [esp]
	popfd
	and eax, 0x00200000
	ret
	
;=============================================================================
; VARIABLES
;=============================================================================
BestRes		dw 0
BestMode	dw 0
BestBpp		db 0

;=============================================================================
; STRINGS
;=============================================================================
Strings:
	.WelcomeToStage2		db "[LOS] Entered Stage 2!", 0x0D, 0x0A, 0
	.VBEError				db "[LOS] An Error has occured with VBE!", 0x0D, 0x0A, 0
	.A20Error				db "[LOS] There has been an error while enabling the A20 Line!", 0x0D, 0x0A, 0
	.64BitError				db "[LOS] 64-Bit mode is not supported on this CPU!", 0x0D, 0x0A, 0
	.SSEError				db "[LOS] SSE is not supported on this CPU!", 0x0D, 0x0A, 0
	.SettingGraphicsMode	db "[LOS] Setting Graphics Mode . . .", 0x0D, 0x0A, 0
	.SettingConsoleMode		db "[LOS] Setting Console Mode . . .", 0x0D, 0x0A, 0
	.EnablingA20			db "[LOS] Enabling A20 . . .", 0x0D, 0x0A, 0
	.Detecting64Bit			db "[LOS] Dectecting if the system is 64-bit . . .", 0x0D, 0x0A, 0
	.EnablingSSE			db "[LOS] Enabling SSE . . .", 0x0D, 0x0A, 0
	.LoadingKernel			db "[LOS] Loading the kernel . . .", 0x0D, 0x0A, 0