CHAR_X dw 0 ; RightToLeft_X
CHAR_Y dw 0	; TopToBottom_Y

CHAR_LEFT_LIMIT dw 0
CHAR_BOTTOM_LIMIT dw 0

LAST_CHAR_WIDTH 	db 0
FONT_SIZE 			db 9
LINE_SPACING 		db 3
LINE_HEIGHT 		db 11 ;................................. line height = font size(9) + line spacing(3)
FOREGROUND_COLOR 	db 7 ;.................................. white
BACKGROUND_COLOR 	db 0 ;.................................. black
CHAR_PIXELS_PATTERN	dw 1
CURRENT_LINE 		db 0

;###########################################################

select_char:
get_char_offset: ; alias

	mov ax, word [FONT_SEGMENT]
	mov fs, ax
	mov ax, si
	mov bx, 10
	mul bl
	mov si, ax
	
	ret

;###########################################################


draw_char:

	call 	select_char
	
	mov 	ax, 0xA000 
	mov 	es, ax 	   ;.................................... ES points to video segment
	
	mov 	bx, 319			  ;............................. RTL x position = SCREEN_WIDTH (319) - CHAR_X
	sub 	bx, word [CHAR_X]
	
	mov 	cx, word [CHAR_Y]
	
	xor 	dx, dx
	mov 	dl, byte [fs:si]
	and 	dl, 0x0F 		 ;.............................. DL = char width
	mov 	byte[LAST_CHAR_WIDTH], dl ;..................... save char width
	
	
	mov 	word [CHAR_LEFT_LIMIT], bx
	sub 	word [CHAR_LEFT_LIMIT], dx
	
	mov 	word [CHAR_BOTTOM_LIMIT], cx
	add 	word [CHAR_BOTTOM_LIMIT], 9	; 9 is font height/char height
	
	mov 	ax, 320	;....................................... pixel offset (in video memory) = ( SCREEN_WIDTH(320) x CHAR_Y ) + CHAR_X
	mul 	cx
	
	inc 	si ;............................................ first byte in char data contains char attributes, so, we select the second byte
	push 	si ;............................................ save byte number
	mov 	si, word [fs:si] ;.............................. si = char 2nd byte 
	
	mov word [CHAR_PIXELS_PATTERN], 0x0001 ;................ this is the pattern to test if pixel (bit) is set or not
	
	mov dl, byte [FOREGROUND_COLOR]
	mov dh, byte [BACKGROUND_COLOR]
	
	.draw_pixels_loop:
		
		mov 	di, ax ;.................................... ax = 320 * CHAR_Y (look ".next_row" below)
		add 	di, bx ;.................................... DI = (320 x CHAR_Y) + CHAR_X
		
		test 	si, word [CHAR_PIXELS_PATTERN]
		jz 		.draw_bg_color ;............................ NO?, go to ".draw_bg_color"
		
		mov 	byte [es:di], dl ;.......................... 0xA000:DI = foreground color
		
		jmp 	.skip ;..................................... don't draw background color
		
		.draw_bg_color:
		
			mov 	byte [es:di], dh ;...................... 0xA000:DI = bgbackground color // comment this line if you dont want to draw background pixels
		
		.skip:
		
		shl 	word [CHAR_PIXELS_PATTERN], 1 ;............. to test the next bit/pixel
		dec 	bx	  ;..................................... select the next bit/pixelt
		cmp 	bx, word [CHAR_LEFT_LIMIT] ;................ if we reach the left limit (char width)
		je 		.next_row ;................................. we go the next pixels line (next byte in char data)
		jmp 	.draw_pixels_loop ;......................... else, we continue drawing pixels in current line
		
	.next_row:
		
		pop 	si ;........................................ current byte (pixels line) offset 
		inc 	si ;........................................ next byte offset
		push 	si ;........................................ re-save byte offset
		mov 	si, [fs:si] ;............................... si = byte contents
		
		mov 	bx, 319 ;................................... RTL x position = 319 - CHAR_X (same as above)
		sub 	bx, word [CHAR_X]
		
		inc 	cx    ;..................................... set next pixels line
		cmp 	cx, word [CHAR_BOTTOM_LIMIT] ;..................................... stop drawing if we finish drawing the last line
		je 		.ret
		
		push 	dx ;........................................ save colors
		
		mov 	ax, 320 ;................................... pixel offset = 320 x CHAR_Y ) + CHAR_X (same as above)
		mul 	cx
		
		pop 	dx ;........................................ get colors back
		
		mov 	word [CHAR_PIXELS_PATTERN], 0x0001 ;........ reset pattern
		
		jmp 	.draw_pixels_loop
		
	.ret:
	
		pop 	si ;........................................ to make sure we return to the right place
		ret

;###########################################################

wipe_char:
	
	mov 	ax, 0xA000 
	mov 	es, ax
	
	xor 	dx, dx
	mov 	dl, byte[LAST_CHAR_WIDTH]
	
	sub 	word [CHAR_X], dx
	
	mov 	bx, 319
	sub 	bx, word [CHAR_X]
	
	mov 	cx, word [CHAR_Y]
	
	
	mov 	word [CHAR_LEFT_LIMIT], bx
	sub 	word [CHAR_LEFT_LIMIT], dx
	
	mov 	word [CHAR_BOTTOM_LIMIT], cx
	add 	word [CHAR_BOTTOM_LIMIT], 9
	
	mov 	ax, 320
	mul 	cx
	
	.set_pixels_loop:
		
		mov 	di, ax
		add 	di, bx
		
		mov 	byte [es:di], 0
		
		dec 	bx
		cmp 	bx, word [CHAR_LEFT_LIMIT]
		je 		.next_row
		jmp 	.set_pixels_loop
		
	.next_row:
		
		mov 	bx, 319
		sub 	bx, word [CHAR_X]
		inc 	cx
		cmp 	cx, word [CHAR_BOTTOM_LIMIT]
		je 		.ret
		
		mov 	ax, 320
		mul 	cx
		
		jmp 	.set_pixels_loop
		
	.ret:
	
		ret

;###########################################################

print_string:
	
	.print_loop:
	
		push 	si ;........................................ save string location
		
		mov 	si, word[si]
		and 	si, 0x00FF
		cmp 	si, 0
		je 		.print_done
		
		call 	draw_char
		
		xor 	ax, ax
		mov 	al, byte[LAST_CHAR_WIDTH]
		add 	word [CHAR_X], ax
		
		pop 	si
		
		inc 	si
		
		jmp 	.print_loop
	
	.print_done:
	
		pop 	si
		ret
