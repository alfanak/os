jmp os_main

%include "src/fat12.asm"
%include "src/string.asm"
%include "print.asm"
%include "src/image.asm"
%include "src/commands.asm"
%include "src/keyboard.asm"

VIDEO_SEGMENT 				dw 0xA000
SCREEN_WIDTH 				dw 320
SCREEN_HEIGHT 				dw 200

FONT_SEGMENT 				dw 0x0790 ;..................... 0x0050:0x7400
LOGO_SEGMENT 				dw 0x0810 ;..................... 0x0050:0x7C00
DEFAULT_FOREGROUND_COLOR 	db 7 ;.......................... أبيض
DEFAULT_BACKGROUND_COLOR 	db 0 ;.......................... أسود

TOP_MARGIN 					db 3
RIGHT_MARGIN 				db 1
TOP_PANEL_HEIGHT 			db 14

command_buffer 				times 100 db 0 ;................ سلسلة الحروف الخاصة باسم الأمر (100 حرف كحد أقصى)
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
	add 	al, 2;.......................................... الفراغ بين علامة البداية والنص الذي يكتبه المستخدم
	mov 	word [CHAR_X], ax
	
	ret
	
;###########################################################

draw_top_panel:
	
	mov 	ax, word[LOGO_SEGMENT]
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
	
	;الخط الذي يمثل الحدود السفلية للشريط العلوي
	mov 	bx, 319
	xor 	cx, cx
	mov 	cl, byte[TOP_PANEL_HEIGHT]
	
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
		
	;كتابة الشعار (اسم النظام)
	mov 	word [CHAR_X], 20 ;............................. الهامش الأيمن + عرض الصورة (2 نقطة) = 20 نقطة
	xor 	ax, ax
	mov 	al, byte [TOP_MARGIN]
	mov 	word [CHAR_Y], ax
	
	mov 	si, str_alfanak
	call 	print_string
	
	ret

;###########################################################
		
os_main:
	
	mov 	ax, 0x0050
	mov 	ds, ax
	
	xor 	ax, ax
	
	call 	switch_mode_13h
	
	call load_root_dir
	
	call load_FAT
	
	mov si, font_file_name
	call set_file_name
	
	mov ax, word[FONT_SEGMENT]
	mov word[file_load_segment], ax
	
	call load_file
	
	mov si, logo_file_name
	call set_file_name
	
	mov ax, word[LOGO_SEGMENT]
	mov word[file_load_segment], ax
	
	call load_file
	
	call 	draw_top_panel
	call 	reset_cursor
	
	call 	read_keyboard
	
	mov 	si, 29
	call 	draw_char
	
	cli
	hlt

;###########################################################

logo_file_name db "LOGO    BIN", 0
font_file_name db "FONT    BIN", 0
str_alfanak db 20, 107, 92, 116, 102, 0

