IMAGE_X dw 0 ;.............................................. RightToLeft x
IMAGE_Y dw 0 ;.............................................. TopToBottom y

IMAGE_LEFT_END dw 0
IMAGE_BOTTOM_END dw 0

;###########################################################

draw_image:
	
	mov 	ax, 0xA000
	mov 	es, ax
	
	
	mov 	bx, word [IMAGE_X]
	push 	bx
	
	mov 	ax, word [gs:si] ;.............................. ax = image width
	mov 	word[IMAGE_LEFT_END], bx
	sub 	word[IMAGE_LEFT_END], ax ;...................... image left end = image width + image x
	
	mov 	cx, word [IMAGE_Y]
	
	mov 	ax, word [gs:si + 2] ;.......................... ax = image height
	mov 	word [IMAGE_BOTTOM_END], cx
	add 	word [IMAGE_BOTTOM_END], ax ;................... image bottom end = image height + image y
	
	add 	si, 4 ;......................................... si point to image data (after image width & image height)
	
	mov 	ax, 320
	mul 	cx
	
	xor 	dx, dx
	
	.draw_pixels_loop:
		
		mov 	dl, byte [gs:si] ;.......................... al = next pixel
		cmp 	dl, 0 ;..................................... 0 means transparent pixel (either we dont draw it or we use DEFAULT_BACKGROUND_COLOR for it)
		je 		.ignore ;................................... transparent pixel? dont draw it
		;................................................... else
		dec 	dl ;........................................ color = [al] - 1
		
		mov 	di, ax ;.................................... di = SCREEN_WIDTH (320) x IMAGE_Y
		add 	di, bx ;.................................... di = SCREEN_WIDTH (320) x IMAGE_Y + IMAGE_X
		
		mov 	byte [es:di], dl ;.......................... 0xA000:DI = pixel color
		
		.ignore:
		
		inc 	si ;........................................ select next pixel
		dec 	bx ;........................................
		cmp 	bx, word[IMAGE_LEFT_END] ;.................. we reached the end of pixels line? (image width)
		je 		.next_pixels_row ;.......................... YES? go next pixels line
				;........................................... else
		jmp 	.draw_pixels_loop ;......................... continue drawing pixels 
		
	.next_pixels_row:
		
		pop 	bx ;........................................ bx = image width
		inc 	cx ;........................................ select next pixels line
		cmp 	cx, word[IMAGE_BOTTOM_END] ;................ we reached the last line?
		je 		.return ;................................... YES? stop drawing (return)
				;........................................... else
		push 	bx ;........................................ save image width
		
		mov 	ax, 320
		mul 	cx
		
		jmp 	.draw_pixels_loop ;......................... continue drawing pixels
		
	.return:
	
		ret
