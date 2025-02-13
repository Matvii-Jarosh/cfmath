;; Copyright (C) 2025 Matvii Jarosh
;; 
;; This file is part of cfmath.
;; cfmath is free software: you can redistribute it and/or modify it under the terms of the GNU General
;; Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; cfmath is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
;; the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along with cfmath. If not, see
;; <https://www.gnu.org/licenses/>.
shunting_yard:
	;; var init
	push sy_input_text
	call [strlen]
	mov [sy_input_len], al
	
	mov esi, sy_stack
	dec esi
	mov ecx, 0
	.init_stack:
	inc esi
	mov byte [esi], 0
	inc ecx
	cmp ecx, 12
	jne .init_stack

	mov esi, sy_text
	dec esi
	mov ecx, 0
	.init_text:
	inc esi
	mov byte [esi], 0
	inc ecx
	cmp ecx, 40
	jne .init_text

	mov [sy_sp], 0
	mov [sy_text_len], 0

	;; while i < sy_input_len
	.main_loop:
		mov al, [sy_input_len]
		mov [sy_input_len], al
		mov bl, [sy_i] 
		cmp bl, al
		jge .main_loop_end

		;; init cur_char
		mov al, [sy_i]
		movsx eax, al
		mov esi, sy_input_text
		add esi, eax
		mov al, [esi]
		mov [sy_cur_char], al

		
		.if_is_number:
			;; if (isNumber(currentChar) || (currentChar == '-' && (i == 0 || sy_input.charAt(i - 1) == '(')))
			;; Проверяем, является ли текущий символ числом
			call is_number
			cmp eax, 1
			je .yes_is_number  ; Если число, сразу идём в обработку чисел

			;; Проверяем, является ли символ '-'
			mov al, [sy_cur_char]
			cmp al, '-'
			jne .if_x  ; Если это не '-', пропускаем проверку унарного минуса

			;; Проверяем, является ли это унарным минусом (i == 0 || sy_input[i - 1] == '(')
			movzx ebx, byte [sy_i]  ; Загружаем i в EBX
			cmp ebx, 0
			je .yes_is_number  ; Если i == 0, значит это унарный минус

			;; Проверяем, является ли предыдущий символ '('
			dec ebx                  ; i - 1
			mov al, [sy_input_text + ebx]    ; sy_input[i - 1]
			cmp al, '('
			je .yes_is_number  ; Если sy_input[i-1] == '(', значит это унарный минус)
			jmp .if_x
		.yes_is_number:
			;; sy_text += cur_char
			mov eax, sy_text
			mov bl, [sy_text_len]
			mov dl, [sy_cur_char]
			mov esi, sy_text
			movsx ebx, bl
			add esi, ebx     
			mov [esi], dl  
			inc bl
			mov [sy_text_len], bl

		
			;; if (i + 1 == length || isOperator(sy_input.charAt(i + 1)) || sy_input.charAt(i + 1) == '(' || sy_input.charAt(i + 1) == ')')
			;; if (i + 1 == sy_input_len)
			mov al, [sy_i]
			inc al
			mov bl, [sy_input_len]
			cmp al, bl
			je @f

			;; if foward char is operator
			movsx eax, al
			mov esi, sy_input_text
			add esi, eax
			mov al, [esi]
			mov dl, al
			call is_operator
			cmp eax, 1
			je @f

			;; if foward char is "("
			cmp dl, '('
			je @f

			;; if foward char is ")"
			cmp dl, ')'
			je @f

			jmp .main_loop_cont
			@@:
				;; sy_text += ' ';
				mov esi, sy_text
				mov bl, [sy_text_len]
				movsx ebx, bl
				add esi, ebx
				mov byte [esi], ' '
				inc bl
				mov [sy_text_len], bl

			jmp .main_loop_cont

		;; if cur_char is "x"
		.if_x:
			mov al, [sy_cur_char]
			cmp al, 'x'
			jne .if_p
		.yes_x:
			;; sy_text += "x "
			mov esi, sy_text
			mov bl, [sy_text_len]
			movsx ebx, bl
			add esi, ebx
			inc bl
			mov byte [esi], 'x'
			inc esi
			mov byte [esi], ' '
			inc bl
			mov [sy_text_len], bl
			jmp .main_loop_cont
		
		;; if cur_char is "x"
		.if_p:
			mov al, [sy_cur_char]
			cmp al, 'p'
			jne .if_bo
		.yes_p:
			;; sy_text += "x "
			mov esi, sy_text
			mov bl, [sy_text_len]
			movsx ebx, bl
			add esi, ebx
			inc bl
			mov byte [esi], 'p'
			inc esi
			mov byte [esi], ' '
			inc bl
			mov [sy_text_len], bl
			jmp .main_loop_cont

		;; if cur char is "("
		.if_bo:
			mov al, [sy_cur_char]
			cmp al, '('
			jne .if_bc
		.yes_bo:
			;;stack.push("(")
			mov bl, [sy_sp]
			inc bl
			mov [sy_sp], bl
			movsx ebx, bl
			mov esi, sy_stack
			add esi, ebx
			mov byte [esi], '('
			
			jmp .main_loop_cont

		;; if cur char is ")"
		.if_bc:
			mov al, [sy_cur_char]
			cmp al, ')'
			jne .if_op
		.yes_bc:
			.bc_loop:
				;; (stack.length > 0 && stack[stack.length - 1] != '(')
				mov al, [sy_sp]
				cmp al, 0
				jle .bc_loop_end
				mov esi, sy_stack
				movsx eax, al
				add esi, eax
				mov bl, [esi]
				cmp bl, '('
				je .bc_loop_end

				;; sy_text += stack.pop() + ' ';
				mov al, [sy_sp]
				mov bl, [esi]
				mov esi, sy_text
				mov al, [sy_text_len]
				movsx eax, al
				add esi, eax 
				inc al
				mov [sy_text_len], al
				mov [esi], bl
				inc esi
				mov byte [esi], ' '
				mov al, [sy_text_len]
				inc al
				mov [sy_text_len], al

				dec byte [sy_sp]

				jmp .bc_loop
			.bc_loop_end:

			;; stack.pop()
			mov al, [sy_sp]
			dec al
			mov [sy_sp], al

			;; if (stack.length > 0 && isFunction(stack[stack.length - 1]))
			cmp al, 0
			jle .main_loop_cont
			
			mov al, [sy_sp]
			mov esi, sy_stack
			movsx eax, al
			add esi, eax
			mov al, [esi]
			call is_function
			cmp eax, 0
			je .main_loop_cont

			;; sy_text += stack.pop() + ' ';
			mov al, [sy_sp]
			mov esi, sy_stack
			movsx eax, al
			add esi, eax
			mov bl, [esi]
			mov esi, sy_text
			mov al, [sy_text_len]
			movsx eax, al
			add esi, eax 
			inc al
			mov [sy_text_len], al
			mov [esi], bl
			inc esi
			mov byte [esi], ' '
		
			mov al, [sy_text_len]
			inc al
			mov [sy_text_len], al
			dec byte [sy_sp]
			jmp .main_loop_cont

		;; if cur char is operator
		.if_op:
			mov al, [sy_cur_char]
			call is_operator
			jne .if_fn
		.yes_op:
			.op_loop:
				;; (stack.length > 0 && opPreced(stack[stack.length - 1]) >= opPreced(currentChar))
				mov al, [sy_sp]
				cmp al, 0
				je .op_loop_end

				mov esi, sy_stack 
				movsx eax, al
				add esi, eax
				mov al, [esi]
				call on_preced
				mov edx, eax ;opPreced(stack[stack.length - 1]) 

				mov al, [sy_cur_char]
				call on_preced
				cmp edx, eax
				jl .op_loop_end

				;; sy_text += stack.pop() + ' ';
				;; mov [sy_sp], al
				;; stack pop
				mov bl, [esi]
				mov esi, sy_text
				mov al, [sy_text_len]
				movsx eax, al
				add esi, eax 
				add [sy_text_len], 2
				dec [sy_sp]
				mov [esi], bl
				inc esi
				mov byte [esi], ' '
				
				jmp .op_loop
			.op_loop_end:
			;; stack.push(cur_char)
			mov al, [sy_cur_char]
			mov bl, [sy_sp]
			inc bl
			mov [sy_sp], bl
			movsx ebx, bl
			mov esi, sy_stack
			add esi, ebx
			mov [esi], al

			jmp .main_loop_cont

		;; if char is fun
		.if_fn:
			mov al, [sy_cur_char]
			call is_function
			cmp eax, 0
			je .main_loop_cont
		.yes_fn:
			;; stack.push(currentChar)
			mov al, [sy_cur_char]
			mov bl, [sy_sp]
			inc bl
			mov [sy_sp], bl
			movsx ebx, bl
			mov esi, sy_stack
			add esi, ebx
			mov [esi], al

			jmp .main_loop_cont

		;; error
		.main_loop_error:
			push sy_error1
			call printf
			call exit

		.main_loop_cont:
		;; i++
		mov al, [sy_i]
		inc al
		mov [sy_i], al
		jmp .main_loop

	.main_loop_end:

	.sy_sec_loop:
		;; (stack.length > 0)
		mov al, [sy_sp]
		cmp al, 0
		jle .sy_sec_loop_end

		;; output += stack.pop() + ' ';
		movsx eax, al
		mov esi, sy_stack
		add esi, eax
		dec al
		mov [sy_sp], al
		mov bl, [esi]
		mov esi, sy_text
		mov al, [sy_text_len]
		movsx eax, al
		add esi, eax 
		inc al
		mov [sy_text_len], al
		mov [esi], bl
		inc esi
		mov byte [esi], ' '

		mov al, [sy_text_len]
		inc al
		mov [sy_text_len], al

		jmp .sy_sec_loop
	.sy_sec_loop_end:
	
	mov esi, sy_text       ; Указатель на строку
  movzx ecx, byte [sy_text_len]  ; Загружаем длину строки в ECX

	lea edi, [esi + ecx - 1] ; Указатель на последний символ

	.trim_loop:
	cmp edi, esi            ; Проверяем, не вышли ли за начало строки
	jl .trim_done                 ; Если да, выходим
	mov al, [edi]           ; Загружаем текущий символ
	cmp al, ' '             ; Проверяем, является ли пробелом
	jg .trim_done                 ; Если не пробел, то выходим
	mov byte [edi], 0       ; Убираем пробел, заменяя на 0
	dec edi                 ; Двигаемся влево
	jmp .trim_loop           ; Повторяем цикл

	.trim_done:

	;; return to main func
	add esp, 4
	ret


	; yes is opertator
yes:
	mov eax, 1
	ret
	
	;; no is not operator
no:
	mov eax, 0
	ret

is_number:
	;; get number of char
	mov al, [sy_cur_char]

	cmp al, '.'
	je yes

	sub al, 30h

	cmp al, 9
	ja no

	jmp yes

is_operator:
	;; if char is + - * / ^
	cmp al, '+'
	je yes
	cmp al, '-'
	je yes
	cmp al, '*'
	je yes
	cmp al, '/'
	je yes
	cmp al, '^'
	je yes

	jmp no

is_function:
	;; if char is S C T G Q
	cmp al, 'S' ;; sin
	je yes
	cmp al, 'C' ;; cos
	je yes
	cmp al, 'T' ;; tg
	je yes
	cmp al, 'G' ;; ctg
	je yes
	cmp al, 'Q' ;; sqrt
	je yes
	cmp al, 'A'
	je yes

	jmp no

on_preced:
	cmp al, '^'
	jne @f
	mov eax, 4
	ret
	@@:
	cmp al, '*'
	jne @f
	mov eax, 3
	ret
	@@:
	cmp al, '/'
	jne @f
	mov eax, 3
	ret
	@@:
	cmp al, '+'
	jne @f
	mov eax, 2
	ret
	@@:
	cmp al, '-'
	jne @f
	mov eax, 2
	ret
	@@:
	mov eax, 0
	ret
