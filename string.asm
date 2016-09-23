CHAR_X dw 0 ;............................................... الموقع الأفقي لكتابة الحرف (من اليمين إلى اليسار)
CHAR_Y dw 0	;............................................... الموقع العمودي لكتابة الحرف (من الأعلى إلى الأسفل)

CHAR_LEFT_LIMIT dw 0
CHAR_BOTTOM_LIMIT dw 0

LAST_CHAR_WIDTH 	db 0
FONT_SIZE 			db 9
LINE_SPACING 		db 3
LINE_HEIGHT 		db 11 ;................................. ارتفاع السطر = حجم الخط + الفراغ بين الأسطر
FOREGROUND_COLOR 	db 7 ;.................................. أبيض
BACKGROUND_COLOR 	db 0 ;.................................. أسود
CHAR_PIXELS_PATTERN	dw 1
CURRENT_LINE 		db 0

;###########################################################

select_char:
get_char_offset: ; نسخة

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
	mov 	es, ax 	   ;.................................... عنوان الذاكرة المخصصة للشاشة
	
	mov 	bx, 319
	sub 	bx, word [CHAR_X] ;............................. الموقع الأفقي للرسم = عرض الشاشة - الموقع الأفقي للحرف (من اليمين إلى اليسار)
	
	mov 	cx, word [CHAR_Y]
	
	xor 	dx, dx
	mov 	dl, byte [fs:si]
	and 	dl, 0x0F 		 ;.............................. DL = عرض الحرف
	mov 	byte[LAST_CHAR_WIDTH], dl ;..................... حفظ عرض الحرف
	
	mov 	word [CHAR_LEFT_LIMIT], bx
	sub 	word [CHAR_LEFT_LIMIT], dx
	
	mov 	word [CHAR_BOTTOM_LIMIT], cx
	add 	word [CHAR_BOTTOM_LIMIT], 9	;................... حجم الخط / ارتفاع الحرف
	
	mov 	ax, 320
	mul 	cx		;....................................... رقم النقطة (على الذاكرة المخصصة للشاشة) = عرض الشاشة × الموقع العمودي للحرف + الموقع الأفقي للحرف
	
	inc 	si ;............................................ الثماني الأول من بيانات الحرف يحتوي على خصائص الحرف، لذلك ننتقل مباشرة إلى الثماني الذي بعده
	push 	si ;............................................ حفظ موقعنا الحالي من بيانات الحرف
	mov 	si, word [fs:si] ;.............................. si = أول ثماني من مجموعة الثمانيات المكونة للحرف
	
	mov word [CHAR_PIXELS_PATTERN], 0x0001 ;................ هذا الرقم يمثل أداة مساعدة لفحص شحنة محددة (التي تمثل بدورها نقطة من النقاط المكونة لجسم الحرف) هل هي شفافة أم مرئية
	
	mov dl, byte [FOREGROUND_COLOR]
	mov dh, byte [BACKGROUND_COLOR]
	
	.draw_pixels_loop:
	
		mov 	di, ax
		add 	di, bx
		
		test 	si, word [CHAR_PIXELS_PATTERN] ;............ هل هذه الشحنة = 1؟ (الشحنة المقصودة = 1 يعني أن النقطة المعنية بالرسم مرئية وليست شفافة)
		jz 		.draw_bg_color ;............................ لا؟ إذن اذهب لرسم لون الخلفية (أو لا تقم برسم النقطة نهائيا، حسب الخيار)
		
		mov 	byte [es:di], dl ;.......................... نعم؟ إذن لون النقطة يوضع في موقع الذاكرة [0xA000:DI]
		
		jmp 	.skip ;..................................... تجاوز رسم الخلفية (في حال أردنا خلفية شفافة للحرف)
		
		.draw_bg_color:
		
			mov 	byte [es:di], dh ;...................... في حال اخترنا رسم خلفية الحرف، نضع لون الخلفية في موقع الذاكرة [0xA000:DI]
		
		.skip:
		
		shl 	word [CHAR_PIXELS_PATTERN], 1 ;............. إزاحة الرقم إلى اليسار بخطوة واحدة، هذا ما يساعدنا على فحص النقطة التالية من السطر الحالي للنقاط المكونة للحرف إذا كانت شفافة أم مرئية
		dec 	bx	  ;..................................... الشحنة التالية من الثماني المكون لسطر النقاط / النقطة التالية من سطر النقاط
		cmp 	bx, word [CHAR_LEFT_LIMIT] ;................ هل وصلنا إلى نهاية السطر؟
		je 		.next_row ;................................. نعم؟ ننتقل إلى السطر التالي من النقاط المكونة للحرف
		jmp 	.draw_pixels_loop ;......................... لا؟ نكمل رسم النقاط الموجودة في السطر الحالي
		
	.next_row:
		
		pop 	si
		inc 	si ;........................................ موقع الثماني التالي من بيانات الحرف
		push 	si ;........................................ حفظ موقعنا الجديد من بيانات الحرف
		mov 	si, [fs:si] ;............................... si = الثماني التالي من مجموعة الثمانيات المكونة لبيانات الحرف / السطر التالي من النقاط المكونة لجسم الحرف
		
		mov 	bx, 319
		sub 	bx, word [CHAR_X] ;......................... الموقع الأفقي للرسم (انظر بداية الدالة)
		
		inc 	cx    ;..................................... السطر التالي
		cmp 	cx, word [CHAR_BOTTOM_LIMIT] ;.............. إنهاء الرسم إذا كان هذا آخر سطر من النقاط المكونة للحرف
		je 		.ret
		
		push 	dx ;........................................ حفظ الألوان (لونا الكتابة والخلفية)
		
		mov 	ax, 320 ;................................... انظر بداية الدالة
		mul 	cx
		
		pop 	dx ;........................................ استعادة الألوان
		
		mov 	word [CHAR_PIXELS_PATTERN], 0x0001 ;........ إعادة الرقم المساعد على فحص الشحنة أو شفافية النقطة إلى أصله
		
		jmp 	.draw_pixels_loop
		
	.ret:
	
		pop 	si ;........................................ سحب البيانات من الطابور حتى نعود إلى المكان الصحيح
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
	
		push 	si ;........................................ حفظ مكان النص





	

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