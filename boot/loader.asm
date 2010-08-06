org 10000h
format binary
use16
 
jmp main
 
; in
; si - asciiz string 
 
print:
		lodsb	
		test al, al
		jz print_done
		mov	ah,	0eh	; print character from al
		int	10h
		jmp	print
	print_done:
		ret
 
; stage 2 loader
 
main:
		cli
		push cs
		pop	ds
 

		cli
		hlt
 
 
