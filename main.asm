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
	format PE Console
	entry start

	include 'win32a.inc'
	include 'data.asm'

	section '.text' code readable executable
	include 'shunting_yard.asm'
	include 'rpncal.asm'

start:

	push x_input_text
	push x_input_format
	call [scanf]
	;; str2float
	.num_str2float:
		mov edx, x_input_text
		fldz
		mov ecx, 0          
		mov [x_flp], 0
		mov [x_minp], 1

		.num_str2float_loop:
			mov al, [edx]       
			cmp al, 0
			je .num_str2float_loop_end
			cmp al, '.'         
			je .decimal_part_start
			cmp al, '-'         
			je .min_part_start

			sub al, '0'         
			mov dword [x_tmp], eax
			fimul dword [x_ten] ;; st(0) *= 10
			fiadd dword [x_tmp] ;; st(0) += num

			inc edx

			cmp ecx, 1
			jne .num_str2float_loop
			inc [x_flp]
			jmp .num_str2float_loop

			.decimal_part_start:
			inc edx
			mov ecx, 1
			jmp .num_str2float_loop

			.min_part_start:
			inc edx
			mov [x_minp], -1
			jmp .num_str2float_loop

		.num_str2float_loop_end:
		fimul [x_minp]
		cmp [x_flp], 0
		je .num_str2float_end

		@@: ;; floating point
		fidiv [x_ten]
		dec [x_flp]
		cmp [x_flp], 0
		jne @b

	.num_str2float_end:
	fstp [x_val]


	
	push sy_input_text
	push sy_input_format
	call [scanf]

	;; call shunting_yard
	call shunting_yard

	;push sy_text
	;call [printf]

	finit
	
	push [x_val]
	push sy_text
	call rpncal

	mov [rpn_tmp], eax      
	fld dword [rpn_tmp]      
	sub esp, 8              
	fstp qword [esp]        
	push rpn_debi           
	call [printf]          
	add esp, 12             

	jmp exit ;; END

exit:
	push 0
	call [ExitProcess]
