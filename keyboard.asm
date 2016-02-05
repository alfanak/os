
command_print_char: ;....................................... PARAMETERS: si = char number
	
	push 	si ;............................................ save char number
	
	call 	get_char_offset ;............................... get char offset in font segment
	
	xor 	ax, ax
	mov 	al, byte[fs:si] ;............................... al = char attributes
	
	and 	al, 00010000b ;................................. is char right connectable?
	jnz 	.previous_char_left_connectable_test ;.......... YES? go to check if previous char is left connectable or not
	jmp 	.draw_char ;.................................... else draw char end finish
	
	.previous_char_left_connectable_test:
		
		xor 	ax, ax
		mov 	si, command_buffer ;........................ si = command buffer location
		mov 	al, byte [buffer_index] ;................... al = buffer index
		cmp 	al, 0 ;..................................... buffer index = 0?
		jle 	.draw_char ;................................ YES? just draw current char
				;........................................... else
		dec 	al ;........................................ get the previous char index
		add 	si, ax ;.................................... si = previous command buffer char offset
		
		mov 	si, [si] ;.................................. si = previous command buffer char number
		push 	si ;........................................ save previous command buffer char number
		
		call 	get_char_offset ;........................... get previous command buffer char offset (in font segment)
		
		
		xor 	ax, ax
		mov 	al, byte[fs:si] ;........................... al = first byte of the font's char data => al = char attributes
		mov 	cx, ax ;.................................... cx = previous command char attributes
		
		pop 	si ;........................................ si = our main char (the char we are trying to write)
		
		
		test 	al, 00100000b ;............................. is previous command char left connectable?
		jz 		.draw_char ;................................ NO? draw main char without connections
				;........................................... else
		test 	al, 10000000b ;............................. is previous command char already right connected?
		jnz 	.get_right_connected_instance ;............. YES? skip previous command char replacement, and go get the right connected instance of our main char
		
	.replace_previous_char:
	
		push 	si ;........................................ save our main char number
		push 	cx ;........................................ save previous command char attributes
		
		call 	command_erase_char ;........................ erase previous command char
		
		pop 	cx ;........................................ get our main char number
		pop 	si ;........................................ get previous command char attributes
		
		add 	si, 2 ;..................................... the left connected instance of the char is two steps after current char (either it is an isolated char or a right connected one, please look at font chars map)
		
		xor 	ax, ax
		mov 	di, command_buffer ;........................ di = command buffer location
		mov 	al, byte [buffer_index]
		add 	di, ax ;.................................... di = di + buffer index
		mov 	[di], si ;.................................. replace previous commmand buffer char number by the connected char number
		
		
		call 	draw_char ;................................. draw the command buffer left connected char
		
		xor 	ax, ax
		mov 	al, byte[LAST_CHAR_WIDTH] ;................. draw char function saves this variable (please look at draw_char (file: string.asm))
		add 	word [CHAR_X], ax ;......................... set current horizontal writing position just after the new command buffer left connected char (the replacement char)
		
		
		inc 	byte [buffer_index] ;....................... reset the buffer index
		
	.get_right_connected_instance:
		
		pop 	si ;........................................ get our main char number
		
		cmp 	si, 137 	  ;............................. is tamdeed?
		je 		.skip_research ;............................ YES? don't look for char replacement
				;........................................... else
		inc 	si ;........................................ get the right connected instance, the right connected instance is one step after current char (either its an isolated char or a left connected one, please look at font chars map)
		push 	si ;........................................ save the right connected instance char number
		jmp 	.draw_char ;................................ go to draw the right connected instance
		
		.skip_research:
		
		push 	si ;........................................ save the right connected instance char number
	
	.draw_char:
	
		pop 	si ;........................................ get our main char number or the right connected instance number (depends on where we came from)
		push 	si ;........................................ save main char / right connected instance number
		call 	draw_char
		
		xor 	ax, ax
		mov 	al, byte[LAST_CHAR_WIDTH]
		add 	word [CHAR_X], ax ;......................... set current horizontal writing position just after our main char / right conneced instance
		
	
	xor 	ax, ax 
	mov 	di, command_buffer ;............................ di = command buffer location
	mov 	al, byte [buffer_index]
	add 	di, ax ;........................................ di = di + buffer index
	
	pop 	si ;............................................ get our main char number or the right connected instance number
	mov 	[di], si ;...................................... add main char / right connected instance to command buffer
	
	inc 	byte [buffer_index]
	
	ret	
	
;###########################################################

command_update_last_char: ;update last char after erase command
	
	xor 	ax, ax
	mov 	si, command_buffer ;............................ si = command_buffer
	mov 	al, byte [buffer_index] ;....................... al = buffer index
	cmp 	al, 0 ;......................................... is buffer index = 0? (buffer index = 0 => we have no chars in command input)
	jle 	.return ;....................................... YES? return
			;............................................... else
	dec 	al ;............................................ decrease buffer index (we are trying to redraw last char in command buffer)
	add 	si, ax
	
	mov 	si, [si] ;...................................... si = char number
	push 	si 
	
	call 	get_char_offset ;............................... si = char offset in font segment
	
	xor 	ax, ax
	mov 	al, byte[fs:si] ;............................... al = char attributes
	mov 	cx, ax ;........................................ cx = char attributes
	
	pop 	si ;............................................ si = char number
	
	test 	al, 10000000b ;................................. is char left connected?
	jz		.return ;....................................... NO? return
	
	.replace_previous_char:
	
		push 	si
		push 	cx
		
		call 	command_erase_char
		
		pop 	cx
		pop 	si
		
		cmp 	si, 137 ;................................... is tamdeed?
		je 		.skip 	;................................... YES? don't look for char replacement
				;........................................... else
		sub 	si, 2 ;..................................... replacement is two steps before
		
		.skip:
		
		push 	si ;........................................ save replacement char number
		
		call 	draw_char
		
		xor 	ax, ax
		mov 	al, byte[LAST_CHAR_WIDTH]
		add 	word [CHAR_X], ax
		
		pop 	si ;........................................ si = replacement char number
		
		xor 	ax, ax
		mov 	di, command_buffer
		mov 	al, byte [buffer_index]
		add 	di, ax
		
		mov 	[di], si ;.................................. replace char number in command buffer
		
		inc 	byte [buffer_index] ;....................... reset buffer index
		
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
	
	cmp bh, 1			; escape
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
		
	cmp bh, 14	; backspace
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
	
	cmp bh, 28
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
		
		cmp 	byte[buffer_index], 0 	; no command?
		je 		.no_command				; skip all commands
	
		
		;************************************** command help
		mov 	si, command_name_help
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_0
		
		call 	cmd_help
		
		.go_next_command_0:
		
		;******************** command help 2 (question mark)
		mov 	si, command_name_help_2
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_00
		
		call 	cmd_help
		
		.go_next_command_00:
		
		;*********************************** command version
		mov 	si, command_name_version
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_1
		
		call 	cmd_version
		
		.go_next_command_1:
		
		;****** command version 2 (using alef without hamza)
		mov 	si, command_name_version_2
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_11
		
		call 	cmd_version
		
		.go_next_command_11:
		
		;********************************** command poweroff
		mov 	si, command_name_poweroff
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_2
		
		call 	cmd_poweroff
		
		.go_next_command_2:
		
		;***** command poweroff 2 (using alef without hamza)
		mov 	si, command_name_poweroff_2
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_22
		
		call 	cmd_poweroff
		
		.go_next_command_22:
		
		;****************************** command clean screen
		mov 	si, command_name_clean
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_3
		
		call 	cmd_clean_screen
		
		.go_next_command_3:
		
		;******** command clean screen 2 (using cleanscreen)
		mov 	si, command_name_cleanscreen
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_33
		
		call 	cmd_clean_screen
		
		.go_next_command_33:
		
		;command clean screen 2 (using cleanscreen with hee)
		mov 	si, command_name_cleanscreen_2
		call 	check_command
		
		cmp 	ax, 1
		jne 	.go_next_command_333
		
		call 	cmd_clean_screen
		
		.go_next_command_333:
		
		
		;************************************* wrong command
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
	
	
	
	
