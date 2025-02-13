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
section '.idata' import data readable
	library kernel, 'kernel32.dll',\
     	msvcrt, 'msvcrt.dll'
          
	import kernel, ExitProcess, 'ExitProcess',\
	GetStdHandle, 'GetStdHandle'
	
	import msvcrt, printf, 'printf',\
	scanf, 'scanf',\
        getch, '_getch',\
				strlen, 'strlen',\
				atof, 'atof'

section '.data' data readable writeable
	NULL = 0

	;; get x	
	x_val dd 0.0
	x_input_format db "%19s",0
	x_input_text db 20 dup(0)
	x_input_len db 0
	x_flp db 0
	x_tmp dd 0.0
	x_minp dd 1
	x_ten dd 10

	;; sy
	sy_input_format db "%19s",0
	sy_input_text db 100 dup(0)
	sy_stack db 52 dup(0)
	sy_sp db 0
	sy_text db 200 dup(0)
	sy_text_len db 0
	sy_input_len db ?
	sy_i db ?
	sy_cur_char db ?
	sy_error1 db "Ошибка в выражении!",0

	;; rpnc
	rpn_input_text db 200 dup(0)
	rpn_input_len db 0
	rpn_sp db 0
	rpn_stack dd 100 dup(0)
	rpn_cur_char db 0
	rpn_x dd 0
	rpn_token db 20 dup(0)
	rpn_token_len db 0
	rpn_i db 0
	rpn_error1 db "Ошибка в функции! FN",0
	rpn_error2 db "Ошибка в оператора! OP",0
	rpn_error3 db "Ошибка в токене! TK",0
	rpn_deb db "%s",0dh,0ah,0
	rpn_debi db "%f",0dh,0ah,0
	rpn_ten dd 10
	rpn_tmp dd 0.0
	rpn_minp dd 1
	rpn_flp db 0
