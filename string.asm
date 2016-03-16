CHAR_X dw 0 ;............................................... «·„Êﬁ⁄ «·√›ﬁÌ ·ﬂ «»… «·Õ—› („‰ «·Ì„Ì‰ ≈·Ï «·Ì”«—)
CHAR_Y dw 0	;............................................... «·„Êﬁ⁄ «·⁄„ÊœÌ ·ﬂ «»… «·Õ—› („‰ «·√⁄·Ï ≈·Ï «·√”›·)

CHAR_LEFT_LIMIT dw 0
CHAR_BOTTOM_LIMIT dw 0

LAST_CHAR_WIDTH 	db 0
FONT_SIZE 			db 9
LINE_SPACING 		db 3
LINE_HEIGHT 		db 11 ;................................. «— ›«⁄ «·”ÿ— = ÕÃ„ «·Œÿ + «·›—«€ »Ì‰ «·√”ÿ—
FOREGROUND_COLOR 	db 7 ;.................................. √»Ì÷
BACKGROUND_COLOR 	db 0 ;.................................. √”Êœ
CHAR_PIXELS_PATTERN	dw 1
CURRENT_LINE 		db 0

;###########################################################

select_char:
get_char_offset: ; ‰”Œ…

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
	mov 	es, ax 	   ;.................................... ⁄‰Ê«‰ «·–«ﬂ—… «·„Œ’’… ··‘«‘…
	
	mov 	bx, 319
	sub 	bx, word [CHAR_X] ;............................. «·„Êﬁ⁄ «·√›ﬁÌ ··—”„ = ⁄—÷ «·‘«‘… - «·„Êﬁ⁄ «·√›ﬁÌ ··Õ—› („‰ «·Ì„Ì‰ ≈·Ï «·Ì”«—)
	
	mov 	cx, word [CHAR_Y]
	
	xor 	dx, dx
	mov 	dl, byte [fs:si]
	and 	dl, 0x0F 		 ;.............................. DL = ⁄—÷ «·Õ—›
	mov 	byte[LAST_CHAR_WIDTH], dl ;..................... Õ›Ÿ ⁄—÷ «·Õ—›
	
	mov 	word [CHAR_LEFT_LIMIT], bx
	sub 	word [CHAR_LEFT_LIMIT], dx
	
	mov 	word [CHAR_BOTTOM_LIMIT], cx
	add 	word [CHAR_BOTTOM_LIMIT], 9	;................... ÕÃ„ «·Œÿ / «— ›«⁄ «·Õ—›
	
	mov 	ax, 320
	mul 	cx		;....................................... —ﬁ„ «·‰ﬁÿ… (⁄·Ï «·–«ﬂ—… «·„Œ’’… ··‘«‘…) = ⁄—÷ «·‘«‘… ◊ «·„Êﬁ⁄ «·⁄„ÊœÌ ··Õ—› + «·„Êﬁ⁄ «·√›ﬁÌ ··Õ—›
	
	inc 	si ;............................................ «·À„«‰Ì «·√Ê· „‰ »Ì«‰«  «·Õ—› ÌÕ ÊÌ ⁄·Ï Œ’«∆’ «·Õ—›° ·–·ﬂ ‰‰ ﬁ· „»«‘—… ≈·Ï «·À„«‰Ì «·–Ì »⁄œÂ
	push 	si ;............................................ Õ›Ÿ „Êﬁ⁄‰« «·Õ«·Ì „‰ »Ì«‰«  «·Õ—›
	mov 	si, word [fs:si] ;.............................. si = √Ê· À„«‰Ì „‰ „Ã„Ê⁄… «·À„«‰Ì«  «·„ﬂÊ‰… ··Õ—›
	
	mov word [CHAR_PIXELS_PATTERN], 0x0001 ;................ Â–« «·—ﬁ„ Ì„À· √œ«… „”«⁄œ… ·›Õ’ ‘Õ‰… „Õœœ… («· Ì  „À· »œÊ—Â« ‰ﬁÿ… „‰ «·‰ﬁ«ÿ «·„ﬂÊ‰… ·Ã”„ «·Õ—›) Â· ÂÌ ‘›«›… √„ „—∆Ì…
	
	mov dl, byte [FOREGROUND_COLOR]
	mov dh, byte [BACKGROUND_COLOR]
	
	.draw_pixels_loop:
	
		mov 	di, ax
		add 	di, bx
		
		test 	si, word [CHAR_PIXELS_PATTERN] ;............ Â· Â–Â «·‘Õ‰… = 1ø («·‘Õ‰… «·„ﬁ’Êœ… = 1 Ì⁄‰Ì √‰ «·‰ﬁÿ… «·„⁄‰Ì… »«·—”„ „—∆Ì… Ê·Ì”  ‘›«›…)
		jz 		.draw_bg_color ;............................ ·«ø ≈–‰ «–Â» ·—”„ ·Ê‰ «·Œ·›Ì… (√Ê ·«  ﬁ„ »—”„ «·‰ﬁÿ… ‰Â«∆Ì«° Õ”» «·ŒÌ«—)
		
		mov 	byte [es:di], dl ;.......................... ‰⁄„ø ≈–‰ ·Ê‰ «·‰ﬁÿ… ÌÊ÷⁄ ›Ì „Êﬁ⁄ «·–«ﬂ—… [0xA000:DI]
		
		jmp 	.skip ;.....................................  Ã«Ê“ —”„ «·Œ·›Ì… (›Ì Õ«· √—œ‰« Œ·›Ì… ‘›«›… ··Õ—›)
		
		.draw_bg_color:
		
			mov 	byte [es:di], dh ;...................... ›Ì Õ«· «Œ —‰« —”„ Œ·›Ì… «·Õ—›° ‰÷⁄ ·Ê‰ «·Œ·›Ì… ›Ì „Êﬁ⁄ «·–«ﬂ—… [0xA000:DI]
		
		.skip:
		
		shl 	word [CHAR_PIXELS_PATTERN], 1 ;............. ≈“«Õ… «·—ﬁ„ ≈·Ï «·Ì”«— »ŒÿÊ… Ê«Õœ…° Â–« „« Ì”«⁄œ‰« ⁄·Ï ›Õ’ «·‰ﬁÿ… «· «·Ì… „‰ «·”ÿ— «·Õ«·Ì ··‰ﬁ«ÿ «·„ﬂÊ‰… ··Õ—› ≈–« ﬂ«‰  ‘›«›… √„ „—∆Ì…
		dec 	bx	  ;..................................... «·‘Õ‰… «· «·Ì… „‰ «·À„«‰Ì «·„ﬂÊ‰ ·”ÿ— «·‰ﬁ«ÿ / «·‰ﬁÿ… «· «·Ì… „‰ ”ÿ— «·‰ﬁ«ÿ
		cmp 	bx, word [CHAR_LEFT_LIMIT] ;................ Â· Ê’·‰« ≈·Ï ‰Â«Ì… «·”ÿ—ø
		je 		.next_row ;................................. ‰⁄„ø ‰‰ ﬁ· ≈·Ï «·”ÿ— «· «·Ì „‰ «·‰ﬁ«ÿ «·„ﬂÊ‰… ··Õ—›
		jmp 	.draw_pixels_loop ;......................... ·«ø ‰ﬂ„· —”„ «·‰ﬁ«ÿ «·„ÊÃÊœ… ›Ì «·”ÿ— «·Õ«·Ì
		
	.next_row:
		
		pop 	si
		inc 	si ;........................................ „Êﬁ⁄ «·À„«‰Ì «· «·Ì „‰ »Ì«‰«  «·Õ—›
		push 	si ;........................................ Õ›Ÿ „Êﬁ⁄‰« «·ÃœÌœ „‰ »Ì«‰«  «·Õ—›
		mov 	si, [fs:si] ;............................... si = «·À„«‰Ì «· «·Ì „‰ „Ã„Ê⁄… «·À„«‰Ì«  «·„ﬂÊ‰… ·»Ì«‰«  «·Õ—› / «·”ÿ— «· «·Ì „‰ «·‰ﬁ«ÿ «·„ﬂÊ‰… ·Ã”„ «·Õ—›
		
		mov 	bx, 319
		sub 	bx, word [CHAR_X] ;......................... «·„Êﬁ⁄ «·√›ﬁÌ ··—”„ («‰Ÿ— »œ«Ì… «·œ«·…)
		
		inc 	cx    ;..................................... «·”ÿ— «· «·Ì
		cmp 	cx, word [CHAR_BOTTOM_LIMIT] ;.............. ≈‰Â«¡ «·—”„ ≈–« ﬂ«‰ Â–« ¬Œ— ”ÿ— „‰ «·‰ﬁ«ÿ «·„ﬂÊ‰… ··Õ—›
		je 		.ret
		
		push 	dx ;........................................ Õ›Ÿ «·√·Ê«‰ (·Ê‰« «·ﬂ «»… Ê«·Œ·›Ì…)
		
		mov 	ax, 320 ;................................... «‰Ÿ— »œ«Ì… «·œ«·…
		mul 	cx
		
		pop 	dx ;........................................ «” ⁄«œ… «·√·Ê«‰
		
		mov 	word [CHAR_PIXELS_PATTERN], 0x0001 ;........ ≈⁄«œ… «·—ﬁ„ «·„”«⁄œ ⁄·Ï ›Õ’ «·‘Õ‰… √Ê ‘›«›Ì… «·‰ﬁÿ… ≈·Ï √’·Â
		
		jmp 	.draw_pixels_loop
		
	.ret:
	
		pop 	si ;........................................ ”Õ» «·»Ì«‰«  „‰ «·ÿ«»Ê— Õ Ï ‰⁄Êœ ≈·Ï «·„ﬂ«‰ «·’ÕÌÕ
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
	
		push 	si ;........................................ Õ›Ÿ „ﬂ«‰ «·‰’





	

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