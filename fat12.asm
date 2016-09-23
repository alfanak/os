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

; المتطلبات: si = الاسم الجديد

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

; المتطلبات: ax = العنوان التسلسلي للحزمة (LBA)

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
	
	mov 	ax, word [reserved_sectors]	;................... موقع جدول مواقع تخزين الملفات يأتي مباشرة بعد المقاطع المحجوزة (على القرص)
	
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
		
		call load_sectors ;................................. تحميل حزمة واحدة (في حالتنا حزمة واحدة = قطاع واحد)
		
		.cluster_FAT_offset:
		
			mov 	ax, word [file_cluster]
			mov		dx, ax
			mov		cx, ax
			shr		dx, 0x0001				;...............  الإزاحة إلى اليمين بخطوة واحدة تكافئ قسمة الرقم المزاح على الرقم 2
			add		cx, dx					;...............  cx = رقم الحزمة × 3/2
			mov 	bx, 0x3800
			add		bx, cx					;...............  رقم الحزمة في جدول تعيين مواقع تخزين الملفات (على الذاكرة)

			; نقوم بالتقاط ثمانيين يمثلان معا موقع أول حزمة(وهي في نفس الوقت رقم الوحدة في جدول تعيين مواقع تخزين الملفات)
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
				
				; سحب البيانات من الطابور حتى نعود إلى المكان الصحيح
				pop cx
				pop bx
				
				jmp .return
				
	.file_not_found:	
	.return:
		
		ret

