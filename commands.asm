
cmd_help:
	
	call	go_next_line
	
	mov 	byte[FOREGROUND_COLOR], 2
	
	mov 	si, str_help_message
	call 	print_string
	
	mov 	si, str_alfanak_os
	call 	print_string
	
	mov 	al, byte[DEFAULT_FOREGROUND_COLOR]
	mov 	byte[FOREGROUND_COLOR], al
	
	call 	command_exit
	
	ret

;###########################################################

cmd_version:
	
	call	go_next_line
	
	mov 	byte[FOREGROUND_COLOR], 2
	
	mov 	si, str_alfanak_os
	call 	print_string
	add 	word [CHAR_X], 5 ; ›—«€
	mov 	si, str_version_number
	call 	print_string
	
	mov 	al, byte[DEFAULT_FOREGROUND_COLOR]
	mov 	byte[FOREGROUND_COLOR], al
	
	call 	command_exit
	
	ret

;###########################################################

cmd_time:
	
	ret

;###########################################################

cmd_reboot:
	
	ret

;###########################################################

cmd_poweroff:
	
	; check for APM installation
	mov 	ah, 0x53
	mov 	al, 0x00
	xor 	bx, bx
	int 	0x15
	jc 	.APM_error
	
	; connect to APM interface
	mov 	ah, 0x53
	mov 	al, 0x01
	xor 	bx, bx
	int 	0x15
	jc 		.APM_error
	
	; power off
	mov 	ah, 0x53
	mov 	al, 0x07
	mov 	bx, 0x0001
	mov 	cx, 0x0003
	int 	0x15
	jc 		.APM_error
	
	jmp 	.return
	
	.APM_error:
		; show error message
		
	.return:
	
		call 	command_exit
		ret

;###########################################################

cmd_clean_screen:

	mov 	ax, 0xA000
	mov 	es, ax
	
	mov 	bx, 319
	
	
	xor 	ax, ax
	xor 	dx, dx
	mov 	dl, byte[LINE_HEIGHT]
	mov 	al, byte[CURRENT_LINE]
	inc 	al ; ≈÷«›… «·”ÿ— «·Õ«·Ì
	mul 	dl
	xor 	dx, dx
	mov 	dl, byte [TOP_PANEL_HEIGHT]
	add 	ax, dx
	
	mov 	cx, ax
	
	mov 	ax, 320
	mul 	cx
	
	mov 	dl, byte[DEFAULT_BACKGROUND_COLOR]
	
	.set_pixels_loop:
		
		mov 	di, ax
		add 	di, bx
		
		mov 	byte [es:di], dl
		
		dec 	bx
		jz 		.previous_pixels_row
		
		jmp 	.set_pixels_loop
		
	.previous_pixels_row:
		
		mov 	bx, 319
		dec 	cx
		cmp 	cl, byte[TOP_PANEL_HEIGHT]
		je 		.ret
		
		mov 	ax, 320
		mul 	cx
		
		jmp 	.set_pixels_loop
		
	.ret:
	
		call 	reset_cursor
		call 	command_buffer_reset
		jmp 	read_keyboard
	
		ret
		
;###########################################################

show_error_message:
	
	call	go_next_line
	
	mov 	byte[FOREGROUND_COLOR], 4
	
	mov 	si, str_command_unknown
	call 	print_string
	
	mov 	al, byte[DEFAULT_FOREGROUND_COLOR]
	mov 	byte[FOREGROUND_COLOR], al
	
	call 	command_exit
	
	ret

;###########################################################

command_name_help 			db 111, 64, 21, 87, 54, 121, 0 ; „”«⁄œ…
command_name_help_2 		db 139, 0 ; ⁄·«„… «” ›Â«„
command_name_version 		db 24, 71, 54, 20, 57, 0 ; ≈’œ«—
command_name_version_2 		db 20, 71, 54, 20, 57, 0 ; «’œ«—
command_name_reboot 		db 24, 87, 21, 53, 121, 138, 20, 107, 36, 68, 92, 130, 106, 0 ; ≈⁄«œ… «· ‘€Ì·
command_name_poweroff 		db 22, 79, 96, 134, 0 ; √ÿ›∆
command_name_poweroff_2		db 20, 79, 96, 134, 0 ; «ÿ›∆
command_name_clean			db 111, 64, 46, 0 ; „”Õ
command_name_cleanscreen	db 111, 64, 46, 138, 20, 107, 68, 21, 67, 122,0 ; „”Õ «·‘«‘…
command_name_cleanscreen_2	db 111, 64, 46, 138, 20, 107, 68, 21, 67, 118,0 ; „”Õ «·‘«‘Â

str_alfanak_os 				db 115, 84, 21, 109, 138, 35, 68, 92, 130, 106, 138, 20, 107, 92, 116, 102, 0 ; ‰Ÿ«„  ‘€Ì· «·›‰ﬂ
str_version_number 			db 11, 10, 10, 152, 10, 0 ; —ﬁ„ «·≈’œ«— („ﬂ Ê» „‰ «·Ì„Ì‰ ≈·Ï «·Ì”«—)
str_help_message 			db 22, 119, 108, 21, 138, 123, 63, 120, 108, 21, 138, 31, 102, 138, 95, 128, 138, 0 ; √Â·« Ê”Â·« »ﬂ„ ›Ì
str_command_unknown 		db 79, 108, 30, 138, 91, 130, 58, 138, 111, 88, 58, 123, 93, 0 ; ÿ·» €Ì— „⁄—Ê›
