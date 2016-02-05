jmp os_main

%include "src/string.asm"
%include "src/image.asm"
%include "src/commands.asm"
%include "src/keyboard.asm"

VIDEO_SEGMENT 				dw 0xA000
SCREEN_WIDTH 				dw 320
SCREEN_HEIGHT 				dw 200

FONT_SEGMENT 				dw 0x07E0
DEFAULT_FOREGROUND_COLOR 	db 7 ;.......................... white
DEFAULT_BACKGROUND_COLOR 	db 0 ;.......................... black

TOP_MARGIN 					db 3
RIGHT_MARGIN 				db 1
TOP_PANEL_HEIGHT 			db 14

command_buffer 				times 100 db 0
buffer_index 				db 0


;###########################################################

switch_mode_13h:
	
	mov 	ah, 0x00
	mov 	al, 0x13
	int 	0x10
	ret

;###########################################################
	
reset_cursor:
	
	mov 	byte [CURRENT_LINE], 0
	
	; X
	xor 	ax, ax
	mov 	al, byte [RIGHT_MARGIN]
	mov 	word [CHAR_X], ax
	
	; Y
	xor 	bx, bx
	mov 	bl, byte [TOP_MARGIN]
	add 	bl, byte [TOP_PANEL_HEIGHT]
	mov 	word [CHAR_Y], bx
	
	call 	draw_starting_mark
	
	ret

;###########################################################

go_next_line:
	
	inc 	byte [CURRENT_LINE]
	
	; X
	xor 	ax, ax
	mov 	al, byte [RIGHT_MARGIN]
	mov 	word [CHAR_X], ax
	
	; Y
	xor 	ax, ax
	mov 	al, byte [CURRENT_LINE]
	mul 	byte [LINE_HEIGHT]
	
	xor 	bx, bx
	mov 	bl, byte [TOP_MARGIN]
	add 	bl, byte [TOP_PANEL_HEIGHT]
	
	add 	ax, bx
	mov 	word [CHAR_Y], ax
	
	ret

;###########################################################

draw_starting_mark:
	
	mov 	si, 146
	call 	draw_char
	
	xor 	ax, ax
	mov 	al, byte [RIGHT_MARGIN]
	add 	al, byte[LAST_CHAR_WIDTH]
	add 	al, 2;.......................................... space between starting mark (gt sign) and user input command
	mov 	word [CHAR_X], ax
	
	ret
	
;###########################################################

draw_top_panel:
	
	mov 	ax, 0x0860 ;.................................... logo is loded at 0x07C0:0x0A00 ie 0x8600
	mov 	gs, ax
	xor 	si, si
	
	xor 	ax, ax
	mov 	al, byte[RIGHT_MARGIN]
	mov 	cx, 319
	sub 	cx, ax
	
	mov 	word[IMAGE_X], cx
	
	xor 	dx, dx
	mov 	dl, byte [TOP_MARGIN]
	
	mov 	word [IMAGE_Y], dx
	
	call 	draw_image
	
	;draw bottom line
	mov 	bx, 319
	xor 	cx, cx
	mov 	cl, byte[TOP_PANEL_HEIGHT] ;........................................ y
	
	mov 	ax, 320
	mul 	cx
	
	mov 	dl, byte [FOREGROUND_COLOR]
	
	.draw_pixel_loop:
		
		mov 	di, ax
		add 	di, bx
		
		mov 	byte [es:di], dl
		dec 	bx
		jz 		.draw_end
		jmp 	.draw_pixel_loop
		
	.draw_end:
		
	;write logo
	mov 	word [CHAR_X], 20 ;............................. right margin + image width + space (2px)= 20
	xor 	ax, ax
	mov 	al, byte [TOP_MARGIN]
	mov 	word [CHAR_Y], ax
	
	mov 	si, str_alfanak
	call 	print_string
	
	ret

;###########################################################
		
os_main:
	
	mov 	ax, 0x0880 ;.................................... os is loded at 0x07C00:0x0C00 ie 0x8800
	mov 	ds, ax
	mov 	es, ax
	
	xor 	ax, ax
	
	call 	switch_mode_13h
	call 	draw_top_panel
	call 	reset_cursor
	
	call 	read_keyboard
	
	mov 	si, 29
	call 	draw_char
	
	cli
	hlt

;###########################################################
	
str_alfanak db 20, 107, 92, 116, 102, 0
