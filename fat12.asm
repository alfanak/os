bytes_per_sector		dw 512
sectors_per_cluster		db 1
reserved_sectors		dw 1
number_of_FATs			db 2
root_entries			dw 224
sectors_per_FAT			dw 9
sectors_per_track		dw 18
heads_per_cylinder		dw 2

file_name 				times 11 db 0
file_load_segment 		dw 0

file_cluster			dw 0
FAT_size 				db 0
data_sector 			dw 0

read_sectors			db 1
read_sector				db 0
read_cylinder			db 0
read_head				db 0
read_drive				db 0

root_offset dw 0x0200

;###########################################################

; «·„ ÿ·»« : si = «·«”„ «·ÃœÌœ

set_file_name:
	
	mov di, file_name
	
	mov cx, 11
	
	.loop:
	
		mov al, byte[si]
		mov byte [di], al
		inc si
		inc di
		loop .loop
		
	.return:
	
		ret

;###########################################################

; «·„ ÿ·»« : ax = «·⁄‰Ê«‰ «· ”·”·Ì ··Õ“„… (LBA)

load_sectors:
	
	lba_chs:
		
		xor 	dx, dx
		div		word [sectors_per_track]
		add		dl, 1
		
		mov		byte [read_sector], dl
		
		xor 	dx, dx
		div		word [heads_per_cylinder]
		mov		byte [read_head], dl
		mov		byte [read_cylinder], al
		
	mov 	ah, 2
	mov		al, [read_sectors]
	mov		ch, [read_cylinder]
	mov		cl, [read_sector]
	mov		dh, [read_head]
	mov		dl, [read_drive]
	int		0x13
	
	ret

;###########################################################

load_root_dir:
	
	mov 	ax, 0x0050
	mov 	es, ax
	
	xor 	cx, cx
	xor 	dx, dx
	mov 	ax, 32
	mul		word [root_entries]
	div 	word [bytes_per_sector]
	mov		byte [read_sectors], al
	xchg	ax, cx
	
	mov 	al, byte [number_of_FATs]
	mul		word [sectors_per_FAT]
	add		ax, word [reserved_sectors]
	mov		byte [FAT_size], al
	
	mov 	word [data_sector], ax
	add		word [data_sector], cx
	
	
	
	mov 	bx, 0x1000
	call 	load_sectors
	
	ret

;###########################################################

load_FAT:
	
	mov 	ax, 0x0050
	mov 	es, ax
	
	mov 	al, byte [FAT_size]
	mov		byte [read_sectors], al
	
	mov 	ax, word [reserved_sectors]	;................... „Êﬁ⁄ ÃœÊ· „Ê«ﬁ⁄  Œ“Ì‰ «·„·›«  Ì√ Ì „»«‘—… »⁄œ «·„ﬁ«ÿ⁄ «·„ÕÃÊ“… (⁄·Ï «·ﬁ—’)
	
	mov 	bx, 0x3800
	call 	load_sectors
	
	ret

;###########################################################

load_file:
	
	mov 	ax, 0x0050
	mov 	es, ax
	
	.search_file:
		
		mov 	cx, [root_entries]
		mov		di, 0x1000
		
		.loop:
			push 	cx
			push	di
			mov		cx, 11
			
			mov 	si, file_name
			rep		cmpsb
			pop		di
			je		.load
			add		di, 32
			pop		cx
			loop	.loop
			jmp		.file_not_found

	
	.load:
		
		mov 	ax, word[file_load_segment]
		mov 	es, ax
		mov		bx, 0x0000
		push 	bx
		
		xor 	dx, dx
		add		dx, word [di + 26]
		mov		word [file_cluster], dx
	
		mov 	ax, word [file_cluster]
		
	.load_clusters:
		
		mov 	ax, word [file_cluster]
		
		.cluster_lba:
			
			sub 	ax, 2
			;mul		word [sectors_per_cluster]
			add		ax, [data_sector]
		
		mov		cx, word [sectors_per_cluster]
		mov		byte [read_sectors], cl
		
		call load_sectors ;.................................  Õ„Ì· Õ“„… Ê«Õœ… (›Ì Õ«· ‰« Õ“„… Ê«Õœ… = ﬁÿ«⁄ Ê«Õœ)
		
		.cluster_FAT_offset:
		
			mov 	ax, word [file_cluster]
			mov		dx, ax
			mov		cx, ax
			shr		dx, 0x0001				;...............  «·≈“«Õ… ≈·Ï «·Ì„Ì‰ »ŒÿÊ… Ê«Õœ…  ﬂ«›∆ ﬁ”„… «·—ﬁ„ «·„“«Õ ⁄·Ï «·—ﬁ„ 2
			add		cx, dx					;...............  cx = —ﬁ„ «·Õ“„… ◊ 3/2
			mov 	bx, 0x3800
			add		bx, cx					;...............  —ﬁ„ «·Õ“„… ›Ì ÃœÊ·  ⁄ÌÌ‰ „Ê«ﬁ⁄  Œ“Ì‰ «·„·›«  (⁄·Ï «·–«ﬂ—…)

			; ‰ﬁÊ„ »«· ﬁ«ÿ À„«‰ÌÌ‰ Ì„À·«‰ „⁄« „Êﬁ⁄ √Ê· Õ“„…(ÊÂÌ ›Ì ‰›” «·Êﬁ  —ﬁ„ «·ÊÕœ… ›Ì ÃœÊ·  ⁄ÌÌ‰ „Ê«ﬁ⁄  Œ“Ì‰ «·„·›« )
			mov		dx, word [bx]
			test	ax, 0x0001
			jnz		.odd_cluster
			
			.even_cluster:
				
				and 	dx, 0000111111111111b
				jmp 	.done
				
			.odd_cluster:
		
				shr 	dx, 0x0004
				
			.done:
			
				pop bx
				add bx, 512
				push bx
				
				mov		word [file_cluster], dx
				
				cmp		dx, 0x0FF0
				
				
				jb		.load_clusters
				
				; ”Õ» «·»Ì«‰«  „‰ «·ÿ«»Ê— Õ Ï ‰⁄Êœ ≈·Ï «·„ﬂ«‰ «·’ÕÌÕ
				pop cx
				pop bx
				
				jmp .return
				
	.file_not_found:	
	.return:
		
		ret
