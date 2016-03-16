start: jmp main

times 0x0B - $ + start db 0

;###########################################################

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
volume_label:			db "ALFANAK OS "
file_system:			db "FAT12   "

;###########################################################

OS_SEGMENT dw 0x0050

FILE_SEGMENT dw 0;

boot_drive db 0

;FILE_NAME db 20, 107, 112, 58, 103, 60, 0; ÇáãÑßÒ


file_name 		db "OS_MAIN BIN"
file_cluster	dw 0
FAT_size 		db 0
data_sector 	dw 0

read_sectors	db 1
read_sector		db 0
read_cylinder	db 0
read_head		db 0
read_drive		db 0

;###########################################################

load_sectors:
	
	lba_chs:	; ax = ÇáÚäæÇä ÇáÊÓáÓáí ááÍÒãÉ (LBA)
		
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

load_file:
	
	.load_root:
	
		mov		byte [read_sectors], 14 ;................... ÍÌã ÌÏæá ÃÓãÇÁ ÇáãáİÇÊ åæ 14 ŞØÇÚÇ
		
		mov 	ax, 19 ;.................................... ãæŞÚ ÌÏæá ÃÓãÇÁ ÇáãáİÇÊ íÈÏÃ ÚäÏ ÇáŞØÇÚ 19 (ÊÍÏíÏÇ ÈÚÏ ÌÏæáí ÊÚííä ãæÇŞÚ ÊÎÒíä ÇáãáİÇÊ ÅÖÇİÉ Åáì ÇáŞØÇÚÇÊ ÇáãÍÌæÒÉ æÇáí åí ÚÈÇÑÉ Úä ŞØÇÚ æÇÍÏ íÊãËá İí ŞØÇÚ ÇáÅŞáÇÚ)
		
		mov 	bx, 0x0200 ;................................ ÊÍãíá ÌÏæá ÃÓãÇÁ ÇáãáİÇÊ Åáì ãæŞÚ ÇáĞÇßÑÉ [0x07C0:0x0200]
		call 	load_sectors
		
	.search_file:
		
		mov 	cx, [root_entries]
		mov		di, 0x0200 ;................................ ÈÏÇíÉ ÇáÈÍË Úä Çáãáİ ÚäÏ ãæŞÚ ÇáĞÇßÑÉ [0x07C0:0x0200]
		
		.loop:
			push 	cx ;.................................... cx = ÚÏÏ ÇáãáİÇÊ ÇáÊí íãßä ÊÎÒíäåÇ Úáì ÇáŞÑÕ
			push	di ;.................................... di = ãæŞÚ ÌÏæá ÃÓãÇÁ ÇáãáİÇÊ Úáì ÇáĞÇßÑÉ ÇáÍíÉ [0x7C0:0x0200]
			mov		cx, 11 ;................................ ÚÏÏ ÇáÍÑæİ İí ÇÓã Çáãáİ åæ 11 ÍÑİÇ
			
			mov 	si, file_name
			rep		cmpsb
			pop		di
			je		.load_FAT
			
			add		di, 32
			pop		cx
			loop	.loop
			
	
	.load_FAT:
		
		xor 	dx, dx
		add		dx, word [di + 26]
		mov		word [file_cluster], dx
		
		mov		byte [read_sectors], 18
		
		mov 	ax, word [reserved_sectors]
		
		mov 	bx, 0x0200
		call 	load_sectors
		
	mov 	ax, 0x0050
	mov 	es, ax
	mov		bx, 0x0000
	push 	bx
		
	.load:
	
		mov 	ax, word [file_cluster]
		
		.cluster_lba:
			
			sub 	ax, 2
			;mul		word [bpbSectorsPerCluster]
			add		ax, 33 ;................................ ÈíÇäÇÊ ÇáãáİÇÊ ÊÍİÙ ÈÏÇíÉ ãä ÇáŞØÇÚ 33
		
		mov		cx, word [sectors_per_cluster]
		mov		byte [read_sectors], cl
		
		call 	load_sectors ;.............................. ŞÑÇÁÉ ÍÒãÉ ÈíÇäÇÊ æÇÍÏÉ (İí ÍÇáÊäÇ åí ÚÈÇÑÉ Úä ŞØÇÚ æÇÍÏ)
		
		
		.cluster_FAT_offset:
		
			mov 	ax, word [file_cluster]
			mov		dx, ax
			mov		cx, ax
			shr		dx, 0x0001				;............... ÇáÅÒÇÍÉ Åáì Çáíãíä ÈÎØæÉ æÇÍÏÉ ÊßÇİÆ ŞÓãÉ ÇáÑŞã ÇáãÒÇÍ Úáì ÇáÑŞã 2
			add		cx, dx					;............... cx = ÑŞã ÇáÍÒãÉ × 3/2
			
			mov 	bx, 0x0200
			add		bx, cx					;............... bx = ÑŞã ÇáÍÒãÉ İí ÌÏæá ÊÚííä ãæÇŞÚ ÊÎÒíä ÇáãáİÇÊ (Úáì ÇáĞÇßÑÉ)
			
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
				jb		.load
				
			.return:
				
				mov dl, byte [read_drive]
				
				jmp 0x0050:0x0000
				
	ret
	
;###########################################################

main:
	
	mov 	ax, 0x07C0
	mov		ds, ax
	mov 	es, ax
	
	mov		byte [read_drive], dl
	
	call 	load_file
	
	cli
	hlt

times 510 - ($-$$) db 0
dw 0xAA55

; ÅäÔÇÁ ÕæÑÉ ááŞÑÕ ÇáãÑä

times (  512   *   18    *   80   *   2  ) - ($-$$) db 0 ; 1474560 ËãÇäí