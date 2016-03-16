CHAR_X dw 0 ;............................................... ������ ������ ������ ����� (�� ������ ��� ������)
CHAR_Y dw 0	;............................................... ������ ������� ������ ����� (�� ������ ��� ������)

CHAR_LEFT_LIMIT dw 0
CHAR_BOTTOM_LIMIT dw 0

LAST_CHAR_WIDTH 	db 0
FONT_SIZE 			db 9
LINE_SPACING 		db 3
LINE_HEIGHT 		db 11 ;................................. ������ ����� = ��� ���� + ������ ��� ������
FOREGROUND_COLOR 	db 7 ;.................................. ����
BACKGROUND_COLOR 	db 0 ;.................................. ����
CHAR_PIXELS_PATTERN	dw 1
CURRENT_LINE 		db 0

;###########################################################

select_char:
get_char_offset: ; ����

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
	mov 	es, ax 	   ;.................................... ����� ������� ������� ������
	
	mov 	bx, 319
	sub 	bx, word [CHAR_X] ;............................. ������ ������ ����� = ��� ������ - ������ ������ ����� (�� ������ ��� ������)
	
	mov 	cx, word [CHAR_Y]
	
	xor 	dx, dx
	mov 	dl, byte [fs:si]
	and 	dl, 0x0F 		 ;.............................. DL = ��� �����
	mov 	byte[LAST_CHAR_WIDTH], dl ;..................... ��� ��� �����
	
	mov 	word [CHAR_LEFT_LIMIT], bx
	sub 	word [CHAR_LEFT_LIMIT], dx
	
	mov 	word [CHAR_BOTTOM_LIMIT], cx
	add 	word [CHAR_BOTTOM_LIMIT], 9	;................... ��� ���� / ������ �����
	
	mov 	ax, 320
	mul 	cx		;....................................... ��� ������ (��� ������� ������� ������) = ��� ������ � ������ ������� ����� + ������ ������ �����
	
	inc 	si ;............................................ ������� ����� �� ������ ����� ����� ��� ����� ����ݡ ���� ����� ������ ��� ������� ���� ����
	push 	si ;............................................ ��� ������ ������ �� ������ �����
	mov 	si, word [fs:si] ;.............................. si = ��� ����� �� ������ ��������� ������� �����
	
	mov word [CHAR_PIXELS_PATTERN], 0x0001 ;................ ��� ����� ���� ���� ������ ���� ���� ����� (���� ���� ������ ���� �� ������ ������� ���� �����) �� �� ����� �� �����
	
	mov dl, byte [FOREGROUND_COLOR]
	mov dh, byte [BACKGROUND_COLOR]
	
	.draw_pixels_loop:
	
		mov 	di, ax
		add 	di, bx
		
		test 	si, word [CHAR_PIXELS_PATTERN] ;............ �� ��� ������ = 1� (������ �������� = 1 ���� �� ������ ������� ������ ����� ����� �����)
		jz 		.draw_bg_color ;............................ �ǿ ��� ���� ���� ��� ������� (�� �� ��� ���� ������ �����ǡ ��� ������)
		
		mov 	byte [es:di], dl ;.......................... ��� ��� ��� ������ ���� �� ���� ������� [0xA000:DI]
		
		jmp 	.skip ;..................................... ����� ��� ������� (�� ��� ����� ����� ����� �����)
		
		.draw_bg_color:
		
			mov 	byte [es:di], dh ;...................... �� ��� ������ ��� ����� ����ݡ ��� ��� ������� �� ���� ������� [0xA000:DI]
		
		.skip:
		
		shl 	word [CHAR_PIXELS_PATTERN], 1 ;............. ����� ����� ��� ������ ����� ����ɡ ��� �� ������� ��� ��� ������ ������� �� ����� ������ ������ ������� ����� ��� ���� ����� �� �����
		dec 	bx	  ;..................................... ������ ������� �� ������� ������ ���� ������ / ������ ������� �� ��� ������
		cmp 	bx, word [CHAR_LEFT_LIMIT] ;................ �� ����� ��� ����� ����ѿ
		je 		.next_row ;................................. ��� ����� ��� ����� ������ �� ������ ������� �����
		jmp 	.draw_pixels_loop ;......................... �ǿ ���� ��� ������ �������� �� ����� ������
		
	.next_row:
		
		pop 	si
		inc 	si ;........................................ ���� ������� ������ �� ������ �����
		push 	si ;........................................ ��� ������ ������ �� ������ �����
		mov 	si, [fs:si] ;............................... si = ������� ������ �� ������ ��������� ������� ������� ����� / ����� ������ �� ������ ������� ���� �����
		
		mov 	bx, 319
		sub 	bx, word [CHAR_X] ;......................... ������ ������ ����� (���� ����� ������)
		
		inc 	cx    ;..................................... ����� ������
		cmp 	cx, word [CHAR_BOTTOM_LIMIT] ;.............. ����� ����� ��� ��� ��� ��� ��� �� ������ ������� �����
		je 		.ret
		
		push 	dx ;........................................ ��� ������� (���� ������� ��������)
		
		mov 	ax, 320 ;................................... ���� ����� ������
		mul 	cx
		
		pop 	dx ;........................................ ������� �������
		
		mov 	word [CHAR_PIXELS_PATTERN], 0x0001 ;........ ����� ����� ������� ��� ��� ������ �� ������ ������ ��� ����
		
		jmp 	.draw_pixels_loop
		
	.ret:
	
		pop 	si ;........................................ ��� �������� �� ������� ��� ���� ��� ������ ������
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
	
		push 	si ;........................................ ��� ���� ����





	

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
0