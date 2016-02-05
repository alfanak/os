start: jmp main

times 0x0B - $ + start db 0

;######################## BIOS PARAMETER BLOCK #################################

bytes_per_sector:		dw 512
sectors_per_cluster:	db 1
reserved_sectors:		dw 1
number_of_FATs:			db 2
root_entries:			dw 224
total_sectors:			dw 2880
media:					db 0xF0
sectors_per_FAT:		dw 9
sectors_per_track:		dw 18
heads_per_cylinder:		dw 2
hidden_sectors:			dd 0
total_sectors_big:		dd 0

drive_number:			db 0
unused:					db 0
boot_signature:			db 0x29
serial_number:			dd 0xffffffff
volume_label:			db "ALFANAK OS " ;.................. 11 bytes
file_system:			db "FAT12   "	 ;.................. 8 bytes

;###############################################################################		

; NOTE: dl already contains current drive numver (BIOS set this value to execute int 0x19)

load_font:

	mov 	bx, 0x0200 ;.................................... load font to 0x0C70:0x0200 --> just after our bootloader
	mov 	ah, 2
	mov 	al, 4	   ;.................................... font is exactly 4 sectors size (2048 bytes)
	mov 	ch, 0
	mov 	cl, 2
	mov 	dh, 0
	int 	0x13
	ret
		
;###############################################################################

load_logo:
	
	mov 	bx, 0x0A00
	mov 	ah, 2
	mov 	al, 1
	mov 	ch, 0
	mov 	cl, 6
	mov 	dh, 0
	int		0x13
	ret

;###############################################################################

load_os:
	
	mov 	bx, 0x0C00 ;.................................... load OS to 0x07C0:0x0A00
	mov 	ah, 2
	mov 	al, 10     ;.................................... load 10 sectors for os_main
	mov 	ch, 0
	mov 	cl, 7
	mov 	dh, 0
	int 	0x13
	
	jmp 	0x07C0:0x0C00
	;ret

;###############################################################################

main:
	
	mov 	ax, 0x07C0
	mov 	ds, ax
	mov 	es, ax
	
	call 	load_font
	call 	load_logo
	call 	load_os
	
;###############################################################################

times 510 - ($ - $$) db 0
dw 0xAA55

incbin "src/resources/font.bin"
incbin "src/resources/logo.bin"
incbin "os_main.bin"

times (512 * 18 * 80 * 2) - ($ - $$) db 0