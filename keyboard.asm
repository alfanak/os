; المتطلبات: si = رقم الحرف في قائمة الحروف العربية
command_print_char:
	
	push 	si ;............................................ حفظ رقم الحرف
	
	call 	get_char_offset ;............................... si = موقع الحرف على الذاكرة
	
	xor 	ax, ax
	mov 	al, byte[fs:si] ;............................... al = خصائص الحرف
	
	and 	al, 00010000b ;................................. هل هذا الحرف قابل للربط من اليمين؟
	jnz 	.previous_char_left_connectable_test ;.......... نعم؟ ننتقل لفحص الحرف السابق إذا ما كان قابلا للربط من اليسار أم لا
	jmp 	.draw_char ;.................................... لا؟ ننتقل مباشرة إلى رسم الحرف التالي
	
	.previous_char_left_connectable_test:
		
		xor 	ax, ax
		mov 	si, command_buffer ;........................ si = موقع سلسلة الحروف المكونة لاسم الأمر
		mov 	al, byte [buffer_index] ;................... al = مؤشر موقعنا الحالي في سلسلة الحروف المكونة لاسم الأمر
		cmp 	al, 0 ;..................................... نحن في بداية السلسلة؟
		jle 	.draw_char ;................................ نعم؟ انتقل مباشرة لرسم الحرف
		dec 	al ;........................................ لا؟ اختيار مؤشر الحرف السابق
		add 	si, ax ;.................................... si = موقع الحرف السابق من سلسلة الحروف المكونة لاسم الأمر في الذاكرة
		
		mov 	si, [si] ;.................................. si = رقم الحرف
		push 	si
		
		call 	get_char_offset ;........................... موقع بيانات الحرف في الذاكرة (الخط)
		
		
		xor 	ax, ax
		mov 	al, byte[fs:si] ;........................... الثماني الأول من بيانات الحرف يحتوي على خصائص الحرف
		mov 	cx, ax
		
		pop 	si ;........................................ نعود إلى الحرف الأول (الحرف الذي نريد كتابته في الأصل)
		
		
		test 	al, 00100000b ;............................. هل الحرف السابق قابل للاتصال من اليسار؟
		jz 		.draw_char ;................................ لا؟ انتقل إلى رسم الحرف الأصلى مباشرة بدون محاولة وصله بالحرف السابق
		test 	al, 10000000b ;............................. هل الحرف السابق متصل من اليسار؟ (طبعا هذه الحالة مستبعدة ولكن ليست مستحيلة)
		jnz 	.get_right_connected_instance ;............. نعم؟ إذن لا نحاول استبدال الحرف السابق بل ننتقل مباشرة إلى رسم الحرف الذي نريد كتابته (بعد الحصول على النسخة المتصلة من اليمين طبعا)
		
	.replace_previous_char:
	
		push 	si ;........................................ رقم الحرف الأصلى
		push 	cx ;........................................ خصائص الحرف السابق
		
		call 	command_erase_char ;........................ مسح الحرف السابق
		
		pop 	cx
		pop 	si
		
		add 	si, 2 ;..................................... النسخة المتصلة من اليسار لأي حرف توجد قبله بخطوتين(انظر إلى جدول الحروف والرموز الخاصة بالخط)
		
		xor 	ax, ax
		mov 	di, command_buffer ;........................ موقع سلسلة حروف اسم الأمر على الذاكرة
		mov 	al, byte [buffer_index]
		add 	di, ax ;.................................... di = موقع الحرف السابق من سلسلة حروف اسم الأمر
		mov 	[di], si ;.................................. نستبدل الحرف السابق (أو بالأحرى رقم الحرف السابق) في سلسلة حروف اسم الأمر برقم نسخة الحرف المتصلة من اليسار
		
		
		call 	draw_char ;................................. رسم الحرف السابق
		
		xor 	ax, ax
		mov 	al, byte[LAST_CHAR_WIDTH] ;................. هذا الرقم يتم حفظه عند رسم كل حرف (انظر دالة رسم الحرف)
		add 	word [CHAR_X], ax ;......................... الموقع الأفقي لرسم الحرف يأتي تماما بعد الحرف السابق(النسخة المتصلة من الحرف طبعا)
		
		
		inc 	byte [buffer_index] ;....................... تصحيح موضع مؤشر الموقع على سلسلة الحروف الخاصة باسم الأمر
		
	.get_right_connected_instance:
		
		pop 	si ;........................................ رقم الحرف الأول (الحرف الذي نريد كتابته في الأصل)
		
		cmp 	si, 137 	  ;............................. هل هذا الحرف عبارة عن تمديد؟
		je 		.skip_research ;............................ نعم؟ إذن لا تحاول استبدال الحرف (التمديد ليس لديه أي نسخ، فقط حرف واحد)
		inc 	si ;........................................ لا؟ إذن نبحث عن النسخة المتصلة من اليمين لهذا الحرف(النسخة المتصلة من اليمين لأي حرف توجد بعده بخطوة واحدة)
		push 	si ;........................................ رقم الحرف (النسخة المتصلة من اليمين)
		jmp 	.draw_char
		
		.skip_research:
		
			push 	si
	
	.draw_char:
	
		pop 	si ;........................................ رقم الحرف الذي نريد رسمه (الحرف الأصلي أو النسخة المتصلة من الحرف)
		push 	si
		call 	draw_char
		
		xor 	ax, ax
		mov 	al, byte[LAST_CHAR_WIDTH]
		add 	word [CHAR_X], ax ;......................... الموقع الأفقي الجديد للرسم يأتي بعد الحرف الذي رسمناه الآن
		
	
	xor 	ax, ax 
	mov 	di, command_buffer ;............................ موقع سلسلة حروف اسم الأمر على الذاكرة
	mov 	al, byte [buffer_index]
	add 	di, ax ;........................................ di = موقع الحرف في سلسلة حروف اسم الأمر
	
	pop 	si ;............................................ رقم الحرف الذي رسمناه (الحرف الأصلي أو النسخة المتصلة)
	mov 	[di], si ;...................................... إضفة رقم الحرف / النسخة المتصلة إلى سلسلة الحروف الخاصة باسم الأمر
	
	inc 	byte [buffer_index]
	
	ret	
	
;###########################################################

; إعادة رسم الحرف الأخير بعد مسح حرف واحد
command_update_last_char:
	
	xor 	ax, ax
	mov 	si, command_buffer ;............................ موقع سلسلة حروف اسم الأمر على الذاكرة
	mov 	al, byte [buffer_index] ;....................... al = مؤشر موقعنا الحالي في سلسلة الحروف المكونة لاسم الأمر
	cmp 	al, 0 ;......................................... نحن في بداية السلسلة؟
	jle 	.return ;....................................... نعم؟ إذن نذهب مباشرة إلى نهاية الدالة (لا نقوم بأي عمل)
	dec 	al ;............................................ نرجع قيمة مؤشر الموقع على سلسلة حروف اسم الأمر بدرجة واحدة (نحن نريد إعادة رسم الحرف الأخير )
	add 	si, ax
	
	mov 	si, [si] ;...................................... si = رقم الحرف الأخير في سلسلة حروف اسم الأمر
	push 	si 
	
	call 	get_char_offset ;............................... si = موقع بيانات الحرف على الذاكرة (ضمن بيانات الخط المحملة على الذاكرة)
	
	xor 	ax, ax
	mov 	al, byte[fs:si] ;............................... al = خصائص الحرف
	mov 	cx, ax ;........................................ cx = خصائص الحرف
	
	pop 	si ;............................................ si = رقم الحرف
	
	test 	al, 10000000b ;................................. هل هذا الحرف متصل من اليسار؟
	jz		.return ;....................................... لا؟ إذن نذهب إلى نهاية الدالة (لأننا لا نحتاج لاستبدال حرف غير متصل أصلا)
	
	.replace_previous_char:
	
		push 	si
		push 	cx
		
		call 	command_erase_char
		
		pop 	cx
		pop 	si
		
		cmp 	si, 137 ;................................... هل هذا الحرف عبارة عن تمديد؟
		je 		.skip 	;................................... نعم؟ لا تحاول استبدال الحرف(التمديد لديه شكل واحد فقط)
		sub 	si, 2 ;..................................... لا؟ الحرف البديل هو الحرف ما قبل السابق للحرف المعني بالاستبدال
		
		.skip:
		
		push 	si ;........................................ حفظ رقم الحرف البديل
		
		call 	draw_char
		
		xor 	ax, ax
		mov 	al, byte[LAST_CHAR_WIDTH]
		add 	word [CHAR_X], ax
		
		pop 	si ;........................................ رقم الحرف البديل
		
		xor 	ax, ax
		mov 	di, command_buffer
		mov 	al, byte [buffer_index]
		add 	di, ax
		
		mov 	[di], si ;.................................. استبدال رقم الحرف في سلسلة الحروف الخاصة باسم الأمر
		
		inc 	byte [buffer_index] ;....................... تصحيح موضع مؤشر الموقع على سلسلة الحروف الخاصة باسم الأمر
		
	.return:
		
		ret

;###########################################################

command_erase_char:
	
	cmp		byte [buffer_index], 0
	je		.ret
	
	call 	wipe_char
	
	sub 	byte [buffer_index], 2
	
	xor 	ax, ax
	mov 	si, command_buffer
	mov 	al, byte [buffer_index]
	add 	si, ax
	
	xor 	ax, ax
	mov 	al, byte [si]
	
	mov 	si, ax
	call 	get_previous_char_width
	
	inc 	byte [buffer_index]
	
	xor 	ax, ax
	mov 	di, command_buffer
	mov 	al, byte [buffer_index]
	add 	di, ax
	
	mov 	byte [di], 0
	
	.ret:
	
		ret

;###############################################################################

get_previous_char_width:
	
	mov 	ax, word [FONT_SEGMENT]
	mov 	fs, ax
	
	mov 	ax, si
	mov 	bx, 10
	mul 	bl
	
	mov 	si, ax
	xor 	ax, ax
	mov 	al, byte [fs:si]
	and 	al, 0x0F
	
	mov 	byte [LAST_CHAR_WIDTH], al
	
	ret

;###############################################################################

command_buffer_reset:
	
	mov 	di, command_buffer
	xor 	cx, cx
	mov 	cl, byte [buffer_index]
	add 	cx, di
	
	.loop:
		
		mov 	byte [di], 0
		cmp 	di, cx
		je 		.return
		
		inc 	di
		jmp 	.loop
		
	.return:
		
		mov 	byte [buffer_index], 0
		ret

;###############################################################################

read_keyboard:
	
	.scan_keyboard_key:
	
		xor 	ax, ax
		int 	0x16
		
		mov 	bx, ax
	
	cmp bh, 1			; زر الهروب
	je 	.scan_keyboard_key
	
	cmp bh, 2
	je .write_1
	
	cmp bh, 3
	je .write_2
	
	cmp bh, 4
	je .write_3
	
	cmp bh, 5
	je .write_4
	
	cmp bh, 6
	je .write_5
	
	cmp bh, 7
	je .write_6
	
	cmp bh, 8
	je .write_7
	
	cmp bh, 9
	je .write_8
	
	cmp bh, 10
	je .write_9
	
	cmp bh, 11
	je .write_0
	
	cmp bh, 12
	je .scan_keyboard_key
	
	cmp bh, 13
	je .check_shift_key
		
	cmp bh, 14	; زر مسح حرف
	je .erase_char
	
	cmp bh, 15
	je .scan_keyboard_key
	
	cmp bh, 16
	je .write_dhad
	
	cmp bh, 17
	je .write_sad
	
	cmp bh, 18
	je .write_thaa
	
	cmp bh, 19
	je .write_kaf
	
	cmp bh, 20
	je .write_faa
	
	cmp bh, 21
	je .check_shift_key
	
	cmp bh, 22
	je .write_ain
	
	cmp bh, 23
	je .check_shift_key
		
	cmp bh, 24
	je .check_shift_key
	
	cmp bh, 25
	je .write_haa
	
	cmp bh, 26
	je .write_jim
	
	cmp bh, 27
	je .write_del
	
	cmp bh, 28 ; زر الإدخال
	je .execute_command
	
	cmp bh, 29
	je .scan_keyboard_key
	
	cmp bh, 30
	je .write_sheen
	
	cmp bh, 31
	je .write_seen
	
	cmp bh, 32
	je .write_yaa
	
	cmp bh, 33
	je .write_baa
	
	cmp bh, 34
	je .write_lem
	
	cmp bh, 35
	je .check_shift_key
	
	cmp bh, 36
	je .check_shift_key
		
	cmp bh, 37
	je .check_shift_key
		
	cmp bh, 38
	je .write_mim
	
	cmp bh, 39
	je .check_shift_key
		
	cmp bh, 40
	je .write_dtaa
	
	cmp bh, 41
	je .write_thel
	
	cmp bh, 42
	je .scan_keyboard_key
	
	cmp bh, 43
	je .scan_keyboard_key
	
	cmp bh, 44
	je .write_yaa_hamza_above
	
	cmp bh, 45
	je .write_hamza
	
	cmp bh, 46
	je .write_waw_hamza_above
	
	cmp bh, 47
	je .write_raa
	
	cmp bh, 48
	je .scan_keyboard_key
	
	cmp bh, 49
	je .check_shift_key
		
	cmp bh, 50
	je .write_taa_marbota
	
	cmp bh, 51
	je .write_waw
	
	cmp bh, 52
	je .check_shift_key
		
	cmp bh, 53
	je .check_shift_key
	
	cmp bh, 54
	je .scan_keyboard_key
	
	cmp bh, 55
	je .write_sign_multiply
	
	cmp bh, 56
	je .scan_keyboard_key
	
	cmp bh, 57
	je .write_space
	
	cmp bh, 58
	je .scan_keyboard_key
	
	cmp bh, 59
	je .scan_keyboard_key
	
	cmp bh, 60
	je .scan_keyboard_key
	
	cmp bh, 61
	je .scan_keyboard_key
	
	cmp bh, 62
	je .scan_keyboard_key
	
	cmp bh, 63
	je .scan_keyboard_key
	
	cmp bh, 64
	je .scan_keyboard_key
	
	cmp bh, 65
	je .scan_keyboard_key
	
	cmp bh, 66
	je .scan_keyboard_key
	
	cmp bh, 67
	je .scan_keyboard_key
	
	cmp bh, 68
	je .scan_keyboard_key
	
	cmp bh, 69
	je .scan_keyboard_key
	
	cmp bh, 70
	je .scan_keyboard_key
	
	cmp bh, 71
	je .write_7
	
	cmp bh, 72
	je .write_8
	
	cmp bh, 73
	je .write_9
	
	cmp bh, 74
	je .write_sign_minus
	
	cmp bh, 75
	je .write_4
	
	cmp bh, 76
	je .write_5
	
	cmp bh, 77
	je .write_6
	
	cmp bh, 78
	je .write_sign_plus
	
	cmp bh, 79
	je .write_1
	
	cmp bh, 80
	je .write_2
	
	cmp bh, 81
	je .write_3
	
	cmp bh, 82
	je .write_0
	
	cmp bh, 83
	je .scan_keyboard_key
	
	cmp bh, 84
	je .scan_keyboard_key
	
	cmp bh, 85
	je .scan_keyboard_key
	
	cmp bh, 86
	je .scan_keyboard_key
	
	cmp bh, 87
	je .scan_keyboard_key
	
	cmp bh, 88
	je .scan_keyboard_key
	
	cmp bh, 89
	je .scan_keyboard_key
	
	cmp bh, 90
	je .scan_keyboard_key
	
	cmp bh, 91
	je .scan_keyboard_key
	
	cmp bh, 92
	je .scan_keyboard_key
	
	cmp bh, 93
	je .scan_keyboard_key
	
	cmp bh, 94
	je .scan_keyboard_key
	
	cmp bh, 95
	je .scan_keyboard_key
	
	cmp bh, 96
	je .scan_keyboard_key
	
	cmp bh, 97
	je .scan_keyboard_key
	
	cmp bh, 98
	je .scan_keyboard_key
	
	cmp bh, 99
	je .scan_keyboard_key
	
	cmp bh, 100
	je .scan_keyboard_key
	
	cmp bh, 101
	je .scan_keyboard_key
	
	
	jmp .scan_keyboard_key
	
	
	
	.check_shift_key:
		
		mov ah, 0x02
		int 0x16
		
		test al, 00000011b
		jz .shift_key_off
		
		.shift_key_on:
			
			cmp bh, 13
			je .write_sign_plus
			
			cmp bh, 21
			je .write_alef_hamza_below
			
			cmp bh, 23
			je .write_sign_divide
			
			cmp bh, 24
			je .write_sign_multiply
			
			cmp bh, 35
			je .write_alef_hamza_above
		
			cmp bh, 36
			je .write_tamdeed
			
			cmp bh, 37
			je .write_comma
			
			cmp bh, 39
			je .write_colon
		
			cmp bh, 49
			je .write_alef_mad
			
			cmp bh, 52
			je .write_period
			
			cmp bh, 53
			je .write_question_mark
		
		.shift_key_off:
		
			cmp bh, 13
			je .write_sign_equal
			
			cmp bh, 21
			je .write_ghain
			
			cmp bh, 23
			je .write_hee
			
			cmp bh, 24
			je .write_khaa
			
			cmp bh, 35
			je .write_alef
			
			cmp bh, 36
			je .write_taa
			
			cmp bh, 37
			je .write_noon
			
			cmp bh, 39
			je .write_kef
			
			cmp bh, 49
			je .write_alef_maksura
				
			cmp bh, 52
			je .write_zeen
			
			cmp bh, 53
			je .write_dhaa
				
			
			
	.write_0:
	
		mov 	si, 10
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_1:
	
		mov 	si, 11
		call 	command_print_char
		call 	.scan_keyboard_key
		
	.write_2:
	
		mov 	si, 12
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_3:
	
		mov 	si, 13
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_4:
	
		mov 	si, 14
		call 	command_print_char
		call 	.scan_keyboard_key
		
	.write_5:
	
		mov 	si, 15
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_6:
	
		mov 	si, 16
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_7:
	
		mov 	si, 17
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_8:
	
		mov 	si, 18
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_9:
	
		mov 	si, 19
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_alef:
		
		mov 	si, 20
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_alef_hamza_above:
	
		mov 	si, 22
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_alef_hamza_below:
	
		mov 	si, 24
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_alef_mad:
	
		mov 	si, 26
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_hamza:
	
		mov 	si, 28
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_baa:
	
		mov 	si, 29
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_taa:
		
		mov 	si, 33
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_thaa:
	
		mov 	si, 37
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_jim:
	
		mov 	si, 41
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_haa:
	
		mov 	si, 45
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_khaa:
		
		mov 	si, 49
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_del:
	
		mov 	si, 53
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_thel:
	
		mov 	si, 55
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_raa:
	
		mov 	si, 57
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_zeen:
		
		mov 	si, 59
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_seen:
	
		mov 	si, 61
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_sheen:
	
		mov 	si, 65
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_sad:
	
		mov 	si, 69
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_dhad:
		
		mov 	si, 73
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_dtaa:
	
		mov 	si, 77
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_dhaa:
		
		mov 	si, 81
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_ain:
	
		mov 	si, 85
		call 	command_print_char
		call 	.scan_keyboard_key
	
	.write_ghain:
		
		mov 	si, 89
		call 	command_print_char
		call 	.scan_keyboard_key
	
	
	.write_faa:
	
		mov 	si, 93
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_kaf:
	
		mov 	si, 97
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_kef:
		
		mov 	si, 101
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_lem:
	
		mov 	si, 105
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_mim:
	
		mov 	si, 109
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_noon:
		
		mov 	si, 113
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_hee:
		
		mov 	si, 117
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_taa_marbota:
	
		mov 	si, 121
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_waw:
	
		mov 	si, 123
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_waw_hamza_above:
	
		mov 	si, 125
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_yaa:
	
		mov 	si, 127
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_alef_maksura:
		
		mov 	si, 131
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_yaa_hamza_above:
	
		mov 	si, 133
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_tamdeed:
	
		mov 	si, 137
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_space:
	
		mov 	si, 138
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_question_mark:
	
		mov 	si, 139
		call 	command_print_char
		jmp 	.scan_keyboard_key
		
	.write_exclamtion_mark:
	
		mov 	si, 140
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_sign_plus:
	
		mov 	si, 141
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_sign_minus:
	
		mov 	si, 142
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_sign_multiply:
	
		mov 	si, 143
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_sign_divide:
	
		mov 	si, 144
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_sign_equal:
		
		mov 	si, 145
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_sign_greater_than:
	
		mov 	si, 146
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_sign_less_than:
	
		mov 	si, 147
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_sign_percent:
	
		mov 	si, 148
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_slash_1:
	
		mov 	si, 149
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_slash_2:
	
		mov 	si, 150
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_vertical_line:
	
		mov 	si, 151
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_period:
	
		mov 	si, 152
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_comma:
	
		mov 	si, 153
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_semicolon:
	
		mov 	si, 154
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_colon:
	
		mov 	si, 155
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_double_quotation_mark:
	
		mov 	si, 156
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_single_quotation_mark:
	
		mov 	si, 157
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_parenthese_open:
	
		mov 	si, 158
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_parenthese_close:
	
		mov 	si, 159
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_bracket_open:
	
		mov 	si, 160
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_bracket_close:
	
		mov 	si, 161
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_brace_open:
	
		mov 	si, 162
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	.write_brace_close:
	
		mov 	si, 163
		call 	command_print_char
		jmp 	.scan_keyboard_key
	
	
	.erase_char:
	
		call 	command_erase_char
		call 	command_update_last_char
		jmp 	.scan_keyboard_key
	
	
	.execute_command:
		
		cmp 	byte[buffer_index], 0 	;................... المستخدم لم يقم بإدخال أي طلب (لم يكتب أي شيء)
		je 		.no_command				;................... تجاوز فحص الأوامر
	
		
		;************************************** الأمر: مساعدة
		mov 	si, command_name_help
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_0
		
		call 	cmd_help
		
		.go_next_command_0:
		
		;*********************** الأمر: ؟ (بديل للأمر: مساعدة)
		mov 	si, command_name_help_2
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_00
		
		call 	cmd_help
		
		.go_next_command_00:
		
		;*************************************** الأمر: إصدار
		mov 	si, command_name_version
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_1
		
		call 	cmd_version
		
		.go_next_command_1:
		
		;*************************** الأمر: اصدار (بدون همزة)
		mov 	si, command_name_version_2
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_11
		
		call 	cmd_version
		
		.go_next_command_11:
		
		;**************************************** الأمر: أطفئ
		mov 	si, command_name_poweroff
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_2
		
		call 	cmd_poweroff
		
		.go_next_command_2:
		
		;***************************** الأمر اطفئ (بدون همزة)
		mov 	si, command_name_poweroff_2
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_22
		
		call 	cmd_poweroff
		
		.go_next_command_22:
		
		;***************************************** الأمر: مسح
		mov 	si, command_name_clean
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_3
		
		call 	cmd_clean_screen
		
		.go_next_command_3:
		
		;***************** (بديل: للأمر مسح) الأمر: مسح الشاشة
		mov 	si, command_name_cleanscreen
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_33
		
		call 	cmd_clean_screen
		
		.go_next_command_33:
		
		;* الأمر: مسح الشاشة (باستعمال الحرف: ه بدل الحرف: ة)
		mov 	si, command_name_cleanscreen_2
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_333
		
		call 	cmd_clean_screen
		
		.go_next_command_333:
		
		
		;***************** تم إدخال أمر خاطئ من قبل المستخدم
		.wrong_command:
		
			call 	show_error_message
		
		.no_command:
			
			call 	command_exit
	
	.end:
	
		ret

;###########################################################

command_exit:
	
	call 	go_next_line
	call 	draw_starting_mark
	call 	command_buffer_reset
	jmp 	read_keyboard
	ret

;###########################################################

check_command:
	
	mov di, command_buffer
	mov cl, 0
	
	.cmp_chars_loop:
		
		mov bl, byte [si]
		mov al, byte [di]
		
		cmp al, bl
		jne .command_not_match
		
		cmp byte[buffer_index], cl
		je .success
		
		inc si
		inc di
		inc cl
		jmp .cmp_chars_loop
	
	.command_not_match:
		
		mov ax, 0
		ret
	
	.success:
		
		mov ax, 1
	
	.ret:
		ret
	
	
	
	

