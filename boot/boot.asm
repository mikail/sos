; first stage bootloader

use16
format binary
org 7c00h

start:	
	jmp	main

; BIOS Parameter Block
	bpbOEM					db "SOS	    "	; must be 8 bytes
	bpbBytesPerSector:		dw 512
	bpbSectorsPerCluster:	db 1
	bpbReservedSectors:		dw 1
	bpbNumberOfFATs:		db 2
	bpbRootEntries:			dw 224
	bpbTotalSectors:		dw 2880
	bpbMedia:				db 0F8h
	bpbSectorsPerFAT:		dw 9
	bpbSectorsPerTrack:		dw 18
	bpbHeadsPerCylinder:	dw 2
	bpbHiddenSectors:		dd 0
	bpbTotalSectorsBig:		dd 0
	bsDriveNumber:			db 0
	bsUnused:				db 0
	bsExtBootSignature:		db 29h
	bsSerialNumber:			dd 0CAFEBABEh
	bsVolumeLabel:			db "SOSBOOTDISC"
	bsFileSystem:			db "FAT12   "


; Reads a series of sectors
; in
; cx - Number of sectors to read
; ax - starting sector
; es:bx - input buffer
ReadSectors:
	rs_main:
		mov	di, 5		; 5 tries when error occurs
	rs_loop:
		push ax
		push bx
		push cx
		call LBACHS
		mov	ah, 2		; BIOS read sector
		mov	al, 1		; read one physical sector
		mov	ch, byte [absoluteTrack]
		mov	cl, byte [absoluteSector]
		mov	dh, byte [absoluteHead]
		mov dl, byte [bsDriveNumber]
		int	13h			; BIOS interrupt
		jnc	rs_success	; test for error
		xor	ax, ax		; BIOS reset disk int
		int	13h
		dec	di
		pop	cx
		pop	bx
		pop	ax
		jnz	rs_loop		; try to read again
		int	18h			; boot failure
	rs_success:
		pop	cx
		pop	bx
		pop	ax
		add	bx, word [bpbBytesPerSector]		; queue next buffer
		inc	ax									; queue next sector
		loop rs_main							; read next sector
			ret


; Convert CHS to LBA
; LBA = (cluster - 2) * sectors per cluster
; in
; ax - cluster number
ClusterLBA:
		sub	ax, 2
		xor	cx, cx
		mov	cl, byte [bpbSectorsPerCluster]
		mul	cx
		add	ax, word [datasector]
		ret

	
; Convert LBA to CHS
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
; in
; ax - LBA address
LBACHS:
		xor	dx, dx
		div	word [bpbSectorsPerTrack]
		inc	dl
		mov	byte [absoluteSector], dl
		xor dx, dx
		div word [bpbHeadsPerCylinder]
		mov byte [absoluteHead], dl
		mov byte [absoluteTrack], al
		ret

; Bootloader Entry Point
main:

		cli				; disable interrupts
		mov ax, 07C0h	; setup registers to point to our segment
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax

	; create stack

		xor	ax, ax
		mov	ss, ax
		mov	sp, 0FFFFh
		sti

	; load root directory table

	LOAD_ROOT:
	
	; cx <- amount of sectors for root directory table
	
		xor cx, cx
		xor dx, dx
		mov ax, 32 	; 32 bytes per one entry
		mul word [bpbRootEntries]
		div word [bpbBytesPerSector]
		xchg ax, cx
		
	; ax <- first sector of root dir
    
		mov al, byte [bpbNumberOfFATs]		; number of FATs
		mul word [bpbSectorsPerFAT]			; sectors used by FATs
		add ax, word [bpbReservedSectors]	; adjust for bootsector
		mov word [datasector], ax			; base of root directory
		add word [datasector], cx

	; read root directory into memory (7C00:0200)

		mov bx, 0200h
		call ReadSectors

	; browse root directory for binary image

		mov cx, word [bpbRootEntries]	; load loop counter
		mov di, 0200h					; locate first root entry
	.loop:
		push cx
		mov cx, 11						; eleven name length
		mov si, ImageName				; image name to find
		push di
		rep  cmpsb						; test for entry match
		pop di
		je LOAD_FAT
		pop cx
		add di, 32						; queue next directory entry
		loop .loop
		jmp FAILURE

	LOAD_FAT:

	; save starting cluster of boot image
	
		mov dx, word [di+26]
		mov word [cluster], dx			; file's first cluster
		
	; compute size of FAT and store in "cx"
	
		xor ax, ax
		mov al, byte [bpbNumberOfFATs]	; number of FATs
		mul word [bpbSectorsPerFAT]		; sectors used by FATs
		mov cx, ax

	; compute location of FAT and store in "ax"

		mov ax, word [bpbReservedSectors]	; adjust for bootsector
		
	; read FAT into memory (7C00:0200)

		mov bx, 0200h						; copy FAT above bootcode
		call ReadSectors

	; read image file into memory (0050:0000)
	
		mov ax, 0050h
		mov es, ax						; destination for image
		xor bx, bx						; destination for image
		push bx

	; load stage 2

	LOAD_IMAGE:	
		mov	ax, word [cluster]				; cluster to read
		pop	bx								; buffer to read into
		call ClusterLBA						; convert cluster to LBA
		xor	cx, cx
		mov	cl, byte [bpbSectorsPerCluster]	; sectors to read
		call ReadSectors
		push bx
		
	; compute next cluster
	
		mov	ax, word [cluster]	; identify current cluster
		mov	cx, ax
		mov	dx, ax
		shr	dx, 1				; divide by two
		add	cx, dx				; sum for (3/2)
		mov	bx, 0200h			; location of FAT in memory
		add	bx, cx				; index into FAT
		mov	dx, word [bx]		; read two bytes from FAT
		test ax, 1
		jnz	.ODD_CLUSTER
	.EVEN_CLUSTER:
		and	dx, 0000111111111111b	; take low twelve bits
	    jmp .DONE
	.ODD_CLUSTER:
		shr	dx, 4					; take high twelve bits
	.DONE:
		mov	word [cluster], dx		; store new cluster
		cmp	dx, 0FF0h				; test for end of file
		jb LOAD_IMAGE
		push word 50h
		push word 0
		retf
		
	FAILURE:
		int	19h
	

	absoluteSector	db 0
	absoluteHead	db 0
	absoluteTrack	db 0
	datasector		dw 0
	cluster			dw 0
	ImageName		db "loader  sos"
	
	rb 510-($-$$)
	dw 0AA55h
