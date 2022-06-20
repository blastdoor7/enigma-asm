;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MIT License
; 
; Copyright (c) 2022 blastdoor7   51786421+blastdoor7@users.noreply.github.com
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


BITS 32

		org	0x08048000


		db	0x7F, 'ELF'
		db	1			; ELFCLASS32
		db	1			; ELFDATA2LSB
		db	1			; EV_CURRENT
		db	0			; ELFOSABI_NONE
		dd	0
		dd	0
		dw	2			; ET_EXEC
		dw	3			; EM_386
		dd	1			; EV_CURRENT
		dd	_start
		dd	phdrs - $$
		dd	0
		dd	0
		dw	0x34			; sizeof(Elf32_Ehdr)
		dw	0x20			; sizeof(Elf32_Phdr)
		dw	3
		dw	0
		dw	0
		dw	0

phdrs:
		dd	1			; PT_LOAD
		dd	0
		dd	$$
		dd	$$
		dd	file_size
		dd	mem_size
		dd	7			; PF_R | PF_W | PF_X
		dd	0x1000
section .text

_start:
  push ebp
  mov ebp,esp
  mov eax,[esp+4]
  cmp eax,7
  jne exit

  sub esp,24
  mov ecx,[ebp+32]
  mov dword [ebp-4],ecx

  mov ecx,[ebp+28]
  mov dword [ebp-8],ecx

  mov ecx,[ebp+24]
  mov dword [ebp-12],ecx

  mov ecx,[ebp+20]
  mov dword [ebp-16],ecx

  mov ecx,[ebp+16]
  mov dword [ebp-20],ecx

  mov ecx,[ebp+12]
  mov dword [ebp-24],ecx

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Configure plug board 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  mov ecx,dword [ebp-16]
  xor edx,edx
  configure_plug_board_loop:
    mov al,byte [ecx+edx]
    cmp al,0x0
    je configure_plug_board_loop_break

    cmp al,32
    je configure_plug_board_loop_cont
    sub al,65
    inc edx
    mov bl,byte [ecx+edx]
    sub bl,65
    mov byte PLUGBOARD[eax],bl
    mov byte PLUGBOARD[ebx],al

    configure_plug_board_loop_cont:
    inc edx
    jmp configure_plug_board_loop
  configure_plug_board_loop_break:

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Configure the rotors from the command line args
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  pusha
  mov ecx,dword [ebp-24]
  mov dl,48
  mov bl,ROTOR_SEL_IDX
  call configure_rotors
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  mov ecx,dword [ebp-12]
  mov dl,65
  mov bl,ROTOR_RS_IDX
  call configure_rotors
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  mov ecx,dword [ebp-8]
  mov dl,65
  mov bl,ROTOR_WP_IDX
  call configure_rotors
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  popa

  mov ecx,dword [ebp-20]
  mov al,ecx[0]
  pusha
  xor edx,edx
  config_reflector_loop:
    mov ecx,REFLECTOR_NAMES[edx]
    cmp al,cl
    je set_reflector
    add edx,1
    jmp config_reflector_loop

  set_reflector:
    mov eax,28
    mul edx
    mov REFLECTOR[0],eax
   
  config_reflector_loop_break:
  popa

  mov al,byte ROTOR_RIGHT[ROTOR_SEL_IDX]
  rol al,1 
  inc al
  mov dl,byte STEPS_ARRAY[eax]
  mov byte ROTOR_RIGHT[ROTOR_STEP1_IDX],dl

  mov al,byte ROTOR_MIDDLE[ROTOR_SEL_IDX]
  rol al,1 
  inc al
  mov dl,byte STEPS_ARRAY[eax]
  mov byte ROTOR_MIDDLE[ROTOR_STEP1_IDX],dl

  mov al,byte ROTOR_LEFT[ROTOR_SEL_IDX]
  rol al,1 
  inc al
  mov dl,byte STEPS_ARRAY[eax]
  mov byte ROTOR_LEFT[ROTOR_STEP1_IDX],dl

  mov dword ROTOR_RIGHT[ROTOR_STEP2_IDX],-1
  mov dword ROTOR_MIDDLE[ROTOR_STEP2_IDX],-1
  mov dword ROTOR_LEFT[ROTOR_STEP2_IDX],-1
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  mov ecx,[ebp-4]
  call process_input
  jmp exit

  process_input:
    xor edx,edx
    process_char_loop:
      mov al,byte ecx[edx]
      cmp al,0
      je process_input_ret
      pusha
      call step_rotors
      sub al,65
      call process_char
      add al,65
      call printchar
      popa 
      inc edx
      jmp process_char_loop
    process_input_ret:
    ret

  delta_mod_26:
    cmp al,dl
    jl delta_mod_26_swap
    jmp delta_mod_26_subtract
    delta_mod_26_swap:
      xchg al,dl
      sub al,dl
      mov dl,26
      sub dl,al
      mov al,dl
      jmp delta_mod_26_ret
    delta_mod_26_subtract:
      sub al,dl
    delta_mod_26_ret:
    ret 

  process_char:
    mov bl,byte PLUGBOARD[eax]
    mov al,bl
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; right rotor
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,0
    mov edx,8
    call rotor_permute
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; middle rotor
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,0
    mov edx,4
    call rotor_permute
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; left rotor
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,0
    mov edx,0
    call rotor_permute
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; reflector
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bl, byte REFLECTOR[0]
    add bl,al
    mov dl,byte REFLECTOR_PERMS[eax] 
    mov al,dl      
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; feed index back through rotors
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; left rotor - reverse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,208
    mov edx,0
    call rotor_permute
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; middle rotor - reverse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,208
    mov edx,4
    call rotor_permute
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; right rotor - reverse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx,208
    mov edx,8
    call rotor_permute
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bl,byte PLUGBOARD[eax]
    mov al,bl

    process_char_ret:
    ret

  ; input A -> Y -> rotor 3 index 25 -> 14 -> 14-1 -> 13-1 -> rotor 4 index 12
  ;              -> 17 -> 17+1 -> 18-2 -> rotor 5 index 16 -> 0 -> 0+2 
  ;              -> reflector index 2 -> 20 -> 20-2 -> rotor 5 rev index 18 -> 10
  ;              -> 10+2-1 -> rotor 4 rev index 11 -> 15 -> 15+1+1 -> rotor 3 rev index 17
  ;              -> 8 -> 8-1 -> plugboard index 7 -> P
  ; for single array
  ; rotor 3 index 25 -> 2*26 + 25 ->  77
  ;       4       12 -> 3*26 + 12 ->  90
  ;       5       16 -> 4*26 + 16 -> 120
  ; rev
  ;       5       18 -> 8*26 + 4*26 + 18 -> 122 + 208 -> 330
  ;       4       11 -> 8*26 + 3*26 + 11 ->  89 + 208 -> 297
  ;       3       17 -> 8*26 + 2*26 + 17 ->  69 + 208 -> 277
  rotor_permute:
    push ebp
    mov ebp,esp
    sub esp,4
    push eax
    mov ebx,dword ROTORS[edx]  ; select the rotor state
    mov al,byte ebx[ROTOR_SEL_IDX]
    pusha
    mov bl,26
    mul bl   
    mov [ebp-4],eax ; 26 * rotor index
    mov eax,[ebp-4]
    add eax,ecx
    mov [ebp-4],eax   ; eax <- (0 or 1)*8*26 + 26 * rotor index
    popa
    mov al,byte ebx[ROTOR_WP_IDX]
    mov dl,byte ebx[ROTOR_RS_IDX]
    call delta_mod_26
    mov dl,al
    pop eax
    add eax,edx
    call modulo_26 
    push edx       
    add eax,[ebp-4]
    mov dl,byte ROTOR_PERMS[eax]  
    mov eax,edx
    pop edx       
    call delta_mod_26

    mov esp,ebp
    pop ebp
  ret

  step_rotors:
    push eax
    mov al,byte ROTOR_RIGHT[ROTOR_WP_IDX] 
    cmp al,byte ROTOR_RIGHT[ROTOR_STEP1_IDX]
    je step_rotors_middle
    step_rotors_right:
    inc eax
    call modulo_26
    mov byte ROTOR_RIGHT[ROTOR_WP_IDX],al 
    pop eax
    jmp step_rotors_ret
    step_rotors_middle:
    push eax
    mov al,byte ROTOR_MIDDLE[ROTOR_WP_IDX] 
    cmp al,byte ROTOR_MIDDLE[ROTOR_STEP1_IDX]
    je step_rotors_left
    step_middle_ret:
    inc eax
    call modulo_26
    mov byte ROTOR_MIDDLE[ROTOR_WP_IDX],al 
    pop eax
    jmp step_rotors_right
    step_rotors_left:
    push eax
    mov al,byte ROTOR_LEFT[ROTOR_WP_IDX] 
    inc eax
    call modulo_26
    mov byte ROTOR_LEFT[ROTOR_WP_IDX],al 
    pop eax
    jmp step_middle_ret
    step_rotors_ret:
    ret

  modulo_26:
    push edx
    xor edx,edx
    mov ebx,26
    div ebx
    mov eax,edx
    pop edx
    ret

  printchar:
    push eax
    mov ecx,esp 
    pop eax
    mov ebx,1
    mov edx,1
    mov eax,4
    int 0x80
    ret

  configure_rotors:
    mov al,ecx[2]
    sub al,dl
    mov byte ROTOR_RIGHT[ebx],al 
    mov al,ecx[1]
    sub al,dl
    mov byte ROTOR_MIDDLE[ebx],al
    mov al,ecx[0]
    sub al,dl
    mov byte ROTOR_LEFT[ebx],al
    ret

  exit:
    mov esp,ebp
    pop ebp
    mov ebx,0
    mov eax,1
    int 0x80
 
  ; test value 432 B "AY BX DE FG QZ HP MW RS JV UT" CBA AAA ABCDEFGHIJKLMNOPQRSTUVWXYZ
  ; expected output :  PNORAUPMEWYUIFEZNEHEZWEUBU

  ; default - identity, gets configured with supplied plug board
  PLUGBOARD:        db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25

  ; single array for reflector perms
  ; B, C, B_thin, C_thin
  REFLECTOR_PERMS:  db 24,17,20,7,16,18,11,3,15,23,13,6,14,10,12,8,4,1,5,25,2,22,21,9,0,19,0,0 \
                       5,21,15,9,8,0,14,24,4,3,17,25,23,22,6,2,19,10,20,16,18,1,13,12,7,11,0,0 \
                       4,13,10,16,0,20,24,22,9,8,2,14,15,1,11,12,3,23,25,21,5,19,7,17,6,18,0,0 \
                       17,3,14,1,9,13,19,10,21,4,7,12,11,5,2,22,25,0,23,6,24,8,15,18,20,16,0,0

  ; the rotor perms   I - VIII and I - VIII reverse perms - all perms to single array
  ROTOR_PERMS:      db 4,10,12,5,11,6,3,16,21,25,13,19,14,22,24,7,23,20,18,15,0,8,1,17,2,9, \
                       0,9,3,10,18,8,17,20,23,1,11,7,22,19,12,2,16,6,25,13,15,24,5,21,14,4, \
                       1,3,5,7,9,11,2,15,17,19,23,21,25,13,24,4,8,22,6,0,10,12,20,18,16,14, \
                       4,18,14,21,15,25,9,0,24,16,20,8,17,7,23,11,13,5,19,6,10,3,2,12,22,1, \
                       21,25,1,17,6,8,19,24,20,15,18,3,13,7,11,23,0,22,12,9,16,14,5,4,2,10, \
                       9,15,6,21,14,20,12,5,24,16,1,4,13,7,25,17,3,10,0,18,23,11,8,2,19,22, \
                       13,25,9,7,6,17,2,23,12,24,18,22,1,14,20,5,0,8,21,11,15,5,10,16,3,19, \
                       5,10,16,7,19,11,23,14,2,1,9,18,15,3,25,17,0,12,4,22,13,8,20,24,6,21, \
                       20,22,24,6,0,3,5,15,21,25,1,4,2,10,12,19,7,23,18,11,17,8,13,16,14,9, \
                       0,9,15,2,25,22,17,11,5,1,3,10,14,19,24,20,16,6,4,13,7,23,12,8,21,18, \
                       19,0,6,1,15,2,18,3,16,4,20,5,21,13,25,7,24,8,23,9,22,11,17,10,16,12, \
                       7,25,22,21,0,17,19,13,11,6,20,15,23,16,2,4,9,12,1,18,10,3,24,16,8,5, \
                       16,2,24,11,23,22,4,13,5,19,25,16,18,12,21,9,20,3,10,6,8,0,17,15,7,1, \
                       18,10,23,16,11,7,2,13,22,0,17,21,6,12,4,1,9,15,19,24,5,3,25,20,8,14, \
                       16,12,6,24,21,15,4,3,17,2,22,19,8,0,13,20,23,5,10,25,14,18,11,7,9,1, \
                       16,9,8,13,18,0,24,3,21,10,1,5,17,20,7,12,2,15,11,4,22,25,19,6,23,14

  REFLECTOR_NAMES: db 'B','C',0
  ;R,	I
  ;F,	II
  ;W,	III  i.e. 'W'   'V' -> 'W' step with change to 'W'
  ;K,	IV
  ;A,	V
  ;AN,	VI
  ;AN,	VII
  ;AN	VIII
  STEPS_ARRAY: db  0,16,0,4,0,21,0,9,0,25,25,12,25,12,25,12

  ROTOR_RIGHT:  dd 0,0,0,0,0
  ROTOR_MIDDLE: dd 0,0,0,0,0
  ROTOR_LEFT:   dd 0,0,0,0,0  
  REFLECTOR:    dd 0
  ROTORS:       dd ROTOR_LEFT,ROTOR_MIDDLE,ROTOR_RIGHT

  ROTOR_SEL_IDX                   equ   0
  ROTOR_RS_IDX                    equ   1
  ROTOR_WP_IDX                    equ   2
  ROTOR_STEP1_IDX                 equ   3
  ROTOR_STEP2_IDX                 equ   4

file_size equ $ - $$
mem_size equ $ - $$
