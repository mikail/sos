org	7c00h
format binary 
use16
 
start:
	
	xor	bx, bx		; A faster method of clearing BX to 0
	mov	ah, 0ah
	mov	al, 'A'
	int	10h 
	cli
	hlt
	
rb 510 - ($-$$) 
dw 0AA55h
