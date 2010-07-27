org	7c00h
format binary 
use16
 
start:
	
	cli
	hlt
	
rb 510 - ($-$$) 
dw 0AA55h
