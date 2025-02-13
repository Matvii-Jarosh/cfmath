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
rpncal:
	push ebx
	mov ebx, esp
	add ebx, 4

	;; init var

	mov eax, [ebx+8]
	mov [rpn_x], eax

	mov eax, [ebx+4]
	push eax
	call [strlen]
	mov [rpn_input_len], al

	mov esi, rpn_stack
	dec esi
	mov ecx, 0
	.init_stack:
	inc esi
	mov byte [esi], 0
	inc ecx
	cmp ecx, 52
	jne .init_stack

	mov esi, rpn_token
	dec esi
	mov ecx, 0
	.init_text:
	inc esi
	mov byte [esi], 0
	inc ecx
	cmp ecx, 20
	jne .init_text

	mov ecx, 0
	mov esi, [ebx+4]
	.main_loop:
	finit
	;; ini token
	lodsb
	cmp al, 0
	;je .main_loop_end
	je .store_token

	cmp al, ' '
	je .store_token

	mov edx, rpn_token
	add edx, ecx
	mov [edx], al
	inc ecx
	mov [rpn_token_len], cl 
	cmp ecx, 19
	jl .main_loop

	.store_token:
	;push rpn_token
	;push rpn_deb
	;call [printf]
	;add esp, 8
	
	;; main code

	;; if (!isNaN(Number(token)))
	.if_num:
		mov edx, rpn_token
		mov ecx, 0

		mov al, [edx]
		cmp al, '-'
		jne .if_num_loop 

		cmp byte [rpn_token_len], 1
		je .if_x 

		inc edx
		inc ecx

	.if_num_loop:
		mov al, [edx]
		call rpn_is_number
		cmp eax, 0
		je .if_x
		inc ecx
		inc edx
		cmp cl, [rpn_token_len]
		jl .if_num_loop

	.yes_num:
		;; stack.push(Number(token));
		;; str2float
		.num_str2float:
			mov edx, rpn_token 
			fldz
			mov ecx, 0          
			mov [rpn_flp], 0
			mov [rpn_minp], 1

			.num_str2float_loop:
				mov al, [edx]       
				cmp al, 0
				je .num_str2float_loop_end
				cmp al, '.'         
				je .decimal_part_start
				cmp al, '-'         
				je .min_part_start

				sub al, '0'         
				mov dword [rpn_tmp], eax
				fimul dword [rpn_ten] ;; st(0) *= 10
				fiadd dword [rpn_tmp] ;; st(0) += num

				inc edx

				cmp ecx, 1
				jne .num_str2float_loop
				inc [rpn_flp]
				jmp .num_str2float_loop

				.decimal_part_start:
				inc edx
				mov ecx, 1
				jmp .num_str2float_loop

				.min_part_start:
				inc edx
				mov [rpn_minp], -1
				jmp .num_str2float_loop

			.num_str2float_loop_end:
			fimul [rpn_minp]
			cmp [rpn_flp], 0
			je .num_str2float_end

			@@: ;; floating point
			fidiv [rpn_ten]
			dec [rpn_flp]
			cmp [rpn_flp], 0
			jne @b

		.num_str2float_end:
		;; push to stack
		mov eax, rpn_stack
		mov cl, [rpn_sp]
		movsx ecx, cl
		imul ecx, 4 ;; 4 byte
		add eax, ecx
		fstp dword [eax]
		inc [rpn_sp]

		jmp .main_loop_cont

	;; token is just x
	.if_x:
		cmp [rpn_token_len], 1
		jne .main_loop_error3

		mov al, [rpn_token]
		cmp al, 'x'
		jne .if_p
	.yes_x:
		;; stack.push(x)
		mov edx, rpn_stack
		mov cl, [rpn_sp]
		movsx ecx, cl
		imul ecx, 4 ;; 4 byte
		add edx, ecx
		mov eax, [rpn_x]
		mov [edx], eax 	
		inc [rpn_sp]

		jmp .main_loop_cont

	;; token is just pi
	.if_p:
		mov al, [rpn_token]
		cmp al, 'p'
		jne .if_op
	.yes_p:
		;; stack.push(x)
		mov edx, rpn_stack
		mov cl, [rpn_sp]
		movsx ecx, cl
		imul ecx, 4 ;; 4 byte
		add edx, ecx
		mov eax, 3.14159265359
		mov [edx], eax 	
		inc [rpn_sp]

		jmp .main_loop_cont
		
	.if_op:
		mov al, [rpn_token] 
		call is_operator
		cmp eax, 1
		jne .if_fn
	.yes_op:
		mov al, [rpn_token] 
    .if_op_pl:
			cmp al, '+'
			jne .if_op_mn

			;; stack.push(stack.pop() + stack.pop())
			mov edx, rpn_stack
			dec [rpn_sp]
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			dec [rpn_sp]
			sub edx, 4
			mov eax, [edx]
			mov [rpn_tmp], eax
			fadd [rpn_tmp]

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

		.if_op_mn:
			cmp al, '-'
			jne .if_op_ml

			;; stack.push(stack.pop() - stack.pop())
			mov edx, rpn_stack
			dec [rpn_sp]
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 ;; 4 byte
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			dec [rpn_sp]
			sub edx, 4
			mov eax, [edx]
			mov [rpn_tmp], eax
			fsubr [rpn_tmp] 

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 ;; 4 byte
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]
			jmp .main_loop_cont

		.if_op_ml:
			cmp al, '*'
			jne .if_op_dv

			;; stack.push(stack.pop() * stack.pop())
			mov edx, rpn_stack
			dec [rpn_sp]  
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4   
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			dec [rpn_sp] 
			sub edx, 4
			mov eax, [edx]
			mov [rpn_tmp], eax
			fmul [rpn_tmp]

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

		.if_op_dv:
			cmp al, '/'
			jne .if_op_st

			;; stack.push(stack.pop() / stack.pop())
			mov edx, rpn_stack
			dec [rpn_sp]  
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4   
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			dec [rpn_sp] 
			sub edx, 4
			mov eax, [edx]
			mov [rpn_tmp], eax
			fdivr [rpn_tmp]

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

		.if_op_st:
			cmp al, '^'
			jne .if_op_mn

			;; stack.push(stack.pop() ^ stack.pop())
			mov edx, rpn_stack
			dec [rpn_sp]  
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4   
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			dec [rpn_sp] 
			sub edx, 4
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]
			fxch
			fistp [rpn_tmp]
			mov ecx, [rpn_tmp]
			fst [rpn_tmp]

			;; if y == 1
			cmp ecx, 1
			je .if_op_st_1 
			;; if y == 0
			cmp ecx, 0
			je .if_op_st_0 

			dec ecx
			@@:
				dec ecx
				fmul [rpn_tmp]
				cmp ecx, 0
				jne @b
			
			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]
			jmp .main_loop_cont

			.if_op_st_1:
			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			mov eax, [rpn_tmp]
			mov edx, eax
			inc [rpn_sp]
			jmp .main_loop_cont

			.if_op_st_0:
			fld1
			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]
			jmp .main_loop_cont

	.if_fn:
		mov al, [rpn_token] 
    .if_fn_sin:
			cmp al, 'S'
			jne .if_fn_cos

			mov edx, rpn_stack
			dec [rpn_sp]
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			fsin

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

		.if_fn_cos:
			cmp al, 'C'
			jne .if_fn_tg

			mov edx, rpn_stack
			dec [rpn_sp]
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			fcos

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

		.if_fn_tg:
			cmp al, 'T'
			jne .if_fn_ctg

			mov edx, rpn_stack
			dec [rpn_sp]
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax

			fld dword [rpn_tmp]
			fld st0 

			fcos
			fstp dword [rpn_tmp]
			fsin         
			fdiv dword [rpn_tmp]

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

		.if_fn_ctg:
			cmp al, 'G'
			jne .if_fn_sqrt

			mov edx, rpn_stack
			dec [rpn_sp]
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax

			fld dword [rpn_tmp]
			fld st0 

			fsin
			fstp dword [rpn_tmp] 
			fcos
			fdiv dword [rpn_tmp]

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

		.if_fn_sqrt:
			cmp al, 'Q'
			jne .if_fn_abs

			mov edx, rpn_stack
			dec [rpn_sp]
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			fsqrt

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

		.if_fn_abs:
			cmp al, 'A'
			jne .if_fn_abs

			mov edx, rpn_stack
			dec [rpn_sp]
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4 
			add edx, ecx
			mov eax, [edx]
			mov [rpn_tmp], eax
			fld [rpn_tmp]

			fabs

			mov edx, rpn_stack
			mov cl, [rpn_sp]
			movsx ecx, cl
			imul ecx, 4
			add edx, ecx
			fstp dword [edx]
			inc [rpn_sp]

			jmp .main_loop_cont

	.main_loop_error3:
	push rpn_error3
	call [printf]
	jmp exit

	.main_loop_cont:
	;; clear token
	mov edx, rpn_token
	dec edx
	mov ecx, 0
	.clear_text:
	inc edx
	mov al, [edx]
	cmp al, 0
	je @f
	mov byte [edx], 0
	inc ecx
	cmp ecx, 20
	jne .clear_text

	@@:
	xor ecx, ecx

	inc byte [rpn_i]

	cmp byte [esi], 0
	je .main_loop_end
	jmp .main_loop

	.main_loop_end:
	mov edx, rpn_stack
	dec [rpn_sp]
	mov cl, [rpn_sp]
	movsx ecx, cl
	imul ecx, 4 ;; 4 byte 
	add edx, ecx
	mov eax, [edx]
	add esp, 4
	pop ebx
	ret

rpn_is_number:
	cmp al, '.'
	je yes
	cmp al, '-'
	je yes

	sub al, 30h

	cmp al, 9
	ja no

	jmp yes
