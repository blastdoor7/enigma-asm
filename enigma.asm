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

  ; =================================
  ; validate the rotor selection list
  ; =================================
  mov ecx,dword [ebp-24]
  call validate_triad
  cmp eax,0
  jne error

  call allunique
  cmp eax,0
  jne error

  call validate_rotors
  cmp eax,0
  jne error

  ; =================================
  ; validate the reflector argument 
  ; =================================
  mov ecx,dword [ebp-20]
  call validate_reflector
  cmp eax,0
  jne error

  ; =================================
  ; validate the plug board argument 
  ; =================================
  mov ecx,dword [ebp-16]
  call validate_uppercase
  cmp eax,0
  jne error
  call allunique
  cmp eax,0
  jne error
  call validate_plugboard
  cmp eax,0
  jne error

  ; =================================
  ; validate the ring setting 
  ; =================================
  mov ecx,dword [ebp-12]
  call validate_uppercase
  cmp eax,0
  jne error

  call validate_triad
  cmp eax,0
  jne error

  ; =================================
  ; validate the message setting 
  ; =================================
  mov ecx,dword [ebp-8]
  call validate_uppercase
  cmp eax,0
  jne error

  call validate_triad
  cmp eax,0
  jne error

  ;=================================
  ;validate the message - uppercase
  ;=================================
  mov ecx,dword [ebp-4]
  call validate_uppercase
  cmp eax,0
  jne error

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
  mov al,byte ecx[2]
  sub al,0x30
  mov byte ROTOR_RIGHT[ROTOR_SEL_IDX],al 
    
  mov al,ecx[1]
  sub al,0x30
  mov byte ROTOR_MIDDLE[ROTOR_SEL_IDX],al

  mov al,ecx[0]
  sub al,0x30
  mov byte ROTOR_LEFT[ROTOR_SEL_IDX],al

  mov ecx,dword [ebp-20]
  mov al,ecx[0]
  pusha
  xor edx,edx
  config_reflector_loop:
    mov ecx,REFLECTOR_NAMES[edx]
    cmp al,byte ecx[0] 
    je set_reflector
    add edx,4
    jmp config_reflector_loop

  set_reflector:
    mov REFLECTOR[0],edx
   
  config_reflector_loop_break:
  popa

  mov ecx,dword [ebp-12]
  mov al,ecx[2]
  sub al,0x41
  mov byte ROTOR_RIGHT[ROTOR_RS_IDX],al  

  mov al,ecx[1]
  sub al,0x41  
  mov byte ROTOR_MIDDLE[ROTOR_RS_IDX],al

  mov al,ecx[0]
  sub al,0x41   
  mov byte ROTOR_LEFT[ROTOR_RS_IDX],al

  mov ecx,dword [ebp-8]
  mov al,ecx[2]
  sub al,0x41  
  mov byte ROTOR_RIGHT[ROTOR_WP_IDX],al     
  mov al,ecx[1]
  sub al,0x41   
  mov byte ROTOR_MIDDLE[ROTOR_WP_IDX],al
  mov al,ecx[0]
  sub al,0x41   
  mov byte ROTOR_LEFT[ROTOR_WP_IDX],al
  popa

  mov dl,byte ROTOR_III_STEPS[0]
  mov byte ROTOR_RIGHT[ROTOR_STEP1_IDX],dl

  mov dl,byte ROTOR_IV_STEPS[0]
  mov byte ROTOR_MIDDLE[ROTOR_STEP1_IDX],dl

  mov dl,byte ROTOR_V_STEPS[0]
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
    mov bl, byte ROTOR_RIGHT[ROTOR_SEL_IDX]
    mov ecx,rotor_array[4*ebx]

    push eax
    mov al,byte ROTOR_RIGHT[ROTOR_WP_IDX]
    mov dl,byte ROTOR_RIGHT[ROTOR_RS_IDX]
    call delta_mod_26
    mov dl,al
    pop eax
    
    add eax,edx 
    call modulo_26 
    push edx       
    mov dl,byte ecx[eax] 
    mov al,dl
    pop edx       

    call delta_mod_26

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; middle rotor
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push eax
    xor eax,eax
    mov al, byte ROTOR_MIDDLE[ROTOR_SEL_IDX]
    mov ecx,rotor_array[4*eax]
    pop eax

    push eax
    mov al,byte ROTOR_MIDDLE[ROTOR_WP_IDX]
    mov dl,byte ROTOR_MIDDLE[ROTOR_RS_IDX]     
    call delta_mod_26 

    mov dl,al 
    pop eax
    add eax,edx
    call modulo_26
    push edx
    mov edx,ecx[eax] 
    mov al,dl
    pop edx

    call delta_mod_26

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; left rotor
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push eax
    xor eax,eax
    mov al, byte ROTOR_LEFT[ROTOR_SEL_IDX]
    mov ecx,rotor_array[4*eax]
    pop eax

    push eax
    mov al,byte ROTOR_LEFT[ROTOR_WP_IDX]
    mov dl,byte ROTOR_LEFT[ROTOR_RS_IDX]      
    call delta_mod_26 
    mov dl,al
    pop eax

    add eax,edx
    call modulo_26
    push edx
    mov edx,ecx[eax] 
    mov al,dl
    pop edx

    call delta_mod_26 

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; reflector
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push eax
    xor eax,eax
    mov al, byte REFLECTOR[0]
    mov ecx,reflector_array[eax]
    pop eax

    mov dl,byte ecx[eax] 
    mov al,dl      
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; feed index back through rotors
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; left rotor - reverse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push eax
    xor eax,eax
    mov al, byte ROTOR_LEFT[ROTOR_SEL_IDX]
    mov ecx,rotor_rev_array[4*eax]
    pop eax

    push eax
    mov al,byte ROTOR_LEFT[ROTOR_WP_IDX]  
    mov dl,byte ROTOR_LEFT[ROTOR_RS_IDX]
    call delta_mod_26
    mov dl,al 
    pop eax
    
    add eax,edx 
    call modulo_26 
    push edx       
    mov dl,byte ecx[eax] 
    mov al,dl
    pop edx       
    call delta_mod_26  

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; middle rotor - reverse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push eax
    xor eax,eax
    mov al, byte ROTOR_MIDDLE[ROTOR_SEL_IDX]
    mov ecx,rotor_rev_array[4*eax]
    pop eax

    push eax
    mov al,byte ROTOR_MIDDLE[ROTOR_WP_IDX]
    mov dl,byte ROTOR_MIDDLE[ROTOR_RS_IDX]       
    call delta_mod_26  

    mov dl,al 
    pop eax
    add eax,edx
    call modulo_26
    push edx
    mov edx,ecx[eax] 
    mov al,dl
    pop edx
    call delta_mod_26  
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; right rotor - reverse
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push eax
    xor eax,eax
    mov al, byte ROTOR_RIGHT[ROTOR_SEL_IDX]
    mov ecx,rotor_rev_array[4*eax]
    pop eax

    push eax
    mov al,byte ROTOR_RIGHT[ROTOR_WP_IDX]   
    mov dl,byte ROTOR_RIGHT[ROTOR_RS_IDX]
    call delta_mod_26
    mov dl,al 
    pop eax
    
    add eax,edx  
    call modulo_26 
    push edx       
    mov dl,byte ecx[eax]  
    mov al,dl
    pop edx       
    call delta_mod_26

    mov bl,byte PLUGBOARD[eax]
    mov al,bl

    process_char_ret:
    ret

  step_rotors:
    push eax
    mov al,byte ROTOR_RIGHT[ROTOR_WP_IDX] 

      push eax
      cmp al,byte ROTOR_RIGHT[ROTOR_STEP1_IDX]
      je step_rotors_middle
      step_right_ret:
      pop eax
   
    inc eax
    call modulo_26
    mov byte ROTOR_RIGHT[ROTOR_WP_IDX],al 
    pop eax
    jmp step_rotors_ret
    
    step_rotors_middle:
    push eax
    mov al,byte ROTOR_MIDDLE[ROTOR_WP_IDX] 

      push eax
      cmp al,byte ROTOR_MIDDLE[ROTOR_STEP1_IDX]
      je step_rotors_left
      step_middle_ret:
      pop eax
   
    inc eax
    call modulo_26
    mov byte ROTOR_MIDDLE[ROTOR_WP_IDX],al 
    pop eax
    jmp step_right_ret

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

  validate_plugboard: ; maximum of ten pairs, all uppercase
    push ebx

    xor ebx,ebx
    xor edx,edx
    validate_plugboard_loop:
      mov al,byte [ecx+edx]
      cmp al,0x0
      je validate_plugboard_check_pairs
     
      cmp al,32
      je validate_plugboard_continue
 
      cmp al,65
      jl validate_plugboard_error
      cmp al,90
      jg validate_plugboard_error
      inc ebx
      cmp ebx,20
      jg validate_plugboard_error

      validate_plugboard_continue:
      inc edx
      jmp validate_plugboard_loop

    validate_plugboard_check_pairs:
    xor edx,edx
    xor eax,eax
    mov eax,ebx
    mov ebx,2
    div ebx
    cmp dl,0
    jne validate_plugboard_error
    xor eax,eax
    jmp validate_plugboard_ret
    
    validate_plugboard_error:
      mov eax,ERROR_USAGE
   
    validate_plugboard_ret:
    pop ebx
    ret

  validate_triad:
    xor edx,edx
    xor eax,eax
    validate_triad_loop:
      mov al,byte [ecx+edx]
      cmp al,0x0
      je validate_triad_break
      inc edx
      jmp validate_triad_loop

    validate_triad_break:
      cmp edx,3
      jl validate_triad_error
      cmp edx,3
      jg validate_triad_error
      jmp validate_triad_ret

    validate_triad_error:
      mov eax,ERROR_USAGE

    validate_triad_ret:
    ret

  validate_rotors:
    xor edx,edx
    validate_rotors_loop:
      mov al,byte [ecx+edx]
      cmp al,0x0 
      je validate_rotors_ret

      cmp al,48
      jl validate_rotors_error
      cmp al,55
      jg validate_rotors_error

      inc edx
      jmp validate_rotors_loop
    validate_rotors_error:
      mov eax,ERROR_USAGE
    validate_rotors_ret: 
    ret

  validate_reflector:
    xor edx,edx
    validate_reflector_loop:
      mov al,byte [ecx+edx]
      cmp al,0x0
      je validate_reflector_ret

      cmp al,66
      jl validate_reflector_error
      cmp al,67
      jg validate_reflector_error

      validate_reflector_loop_next:
      inc edx
      cmp edx,1
      jg validate_reflector_error

      jmp validate_reflector_loop
    validate_reflector_error:
      mov eax,ERROR_USAGE
    validate_reflector_ret: 
    ret

  validate_uppercase:
    xor edx,edx
    validate_uppercase_loop:
      mov al,byte [ecx+edx]
      cmp al,0x0
      je validate_uppercase_ret

      cmp al,32
      je validate_uppercase_loop_next

      cmp al,65
      jl validate_uppercase_error
      cmp al,90
      jg validate_uppercase_error

      validate_uppercase_loop_next:
      inc edx
      jmp validate_uppercase_loop
    validate_uppercase_error:
      mov eax,ERROR_USAGE
    validate_uppercase_ret: 
    ret

  allunique:
    mov al,byte [ecx] 
    cmp al,0
    je allunique_ret
    
    xor edx,edx
    allunique_zero_array:
      mov byte UNIQUENESS_ARRAY[edx],0
      cmp edx,90
      je allunique_zero_array_break
      inc edx
      jmp allunique_zero_array

    allunique_zero_array_break:
      xor edx,edx
    allunique_scan:
      mov al,byte [ecx+edx] 
      cmp al,0
      je allunique_ret
      cmp al,32
      je allunique_scan_continue
      
      cmp byte UNIQUENESS_ARRAY[eax],0
      jne allunique_error
      mov byte UNIQUENESS_ARRAY[eax],al
      
      allunique_scan_continue:
        inc edx
        jmp allunique_scan

    allunique_error:
      mov eax,ERROR_USAGE

    allunique_ret:
      ret

  error:
    call errormessage
    jmp exit

  errormessage:
    mov ecx,[errmsg_array+eax]
    xor edx,edx
    loop2:
      mov al,byte [ecx+edx]
      cmp al,0x0
      je errormessage_break
      call printchar
      inc edx
      jmp loop2
    errormessage_break:
    ret

  printchar:
    pusha
    mov ebp,esp
    sub esp,4
    mov byte [ebp-4],al
    lea edx,[ebp-4]
    mov ecx,edx 
    mov ebx,1
    mov edx,1
    mov eax,4
    int 0x80
    mov esp,ebp
    popa
    ret

  exit:
    mov esp,ebp
    pop ebp
    mov ebx,0
    mov eax,1
    int 0x80

  ; test value 432 B "AY BX DE FG QZ HP MW RS JV UT" CBA AAA ABCDEFGHIJKLMNOPQRSTUVWXYZ
  ; expected output :  PNORAUPMEWYUIFEZNEHEZWEUBU

  PLUGBOARD: db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25

  REFLECTOR_B:      db  24,17,20,7,16,18,11,3,15,23,13,6,14,10,12,8,4,1,5,25,2,22,21,9,0,19

  REFLECTOR_C:      db 'FVPJIAOYEDRZXWGCTKUQSBNMHL'
  REFLECTOR_B_thin: db 'AE BN CK DQ FU GY HW IJ LO MP RX SZ TV'
  REFLECTOR_C_thin: db 'AR BD CO EJ FN GT HK IV LM PW QZ SX UY'

  ; forward rotor perms
  ROTOR_I:        db  4,10,12,5,11,6,3,16,21,25,13,19,14,22,24,7,23,20,18,15,0,8,1,17,2,9
  ROTOR_II:       db  0,9,3,10,18,8,17,20,23,1,11,7,22,19,12,2,16,6,25,13,15,24,5,21,14,4
  ROTOR_III:      db  1,3,5,7,9,11,2,15,17,19,23,21,25,13,24,4,8,22,6,0,10,12,20,18,16,14
  ROTOR_IV:       db  4,18,14,21,15,25,9,0,24,16,20,8,17,7,23,11,13,5,19,6,10,3,2,12,22,1
  ROTOR_V:        db  21,25,1,17,6,8,19,24,20,15,18,3,13,7,11,23,0,22,12,9,16,14,5,4,2,10
  ROTOR_VI:       db  9,15,6,21,14,20,12,5,24,16,1,4,13,7,25,17,3,10,0,18,23,11,8,2,19,22
  ROTOR_VII:      db  13,25,9,7,6,17,2,23,12,24,18,22,1,14,20,5,0,8,21,11,15,5,10,16,3,19
  ROTOR_VIII:     db  5,10,16,7,19,11,23,14,2,1,9,18,15,3,25,17,0,12,4,22,13,8,20,24,6,21

  ; reverse rotor perms
  ROTOR_I_REV:    db 20,22,24,6,0,3,5,15,21,25,1,4,2,10,12,19,7,23,18,11,17,8,13,16,14,9
  ROTOR_II_REV:   db 0,9,15,2,25,22,17,11,5,1,3,10,14,19,24,20,16,6,4,13,7,23,12,8,21,18
  ROTOR_III_REV:  db 19,0,6,1,15,2,18,3,16,4,20,5,21,13,25,7,24,8,23,9,22,11,17,10,16,12
  ROTOR_IV_REV:   db 7,25,22,21,0,17,19,13,11,6,20,15,23,16,2,4,9,12,1,18,10,3,24,16,8,5
  ROTOR_V_REV:    db 16,2,24,11,23,22,4,13,5,19,25,16,18,12,21,9,20,3,10,6,8,0,17,15,7,1 
  ROTOR_VI_REV:   db 18,10,23,16,11,7,2,13,22,0,17,21,6,12,4,1,9,15,19,24,5,3,25,20,8,14
  ROTOR_VII_REV:  db 16,12,6,24,21,15,4,3,17,2,22,19,8,0,13,20,23,5,10,25,14,18,11,7,9,1
  ROTOR_VIII_REV: db 16,9,8,13,18,0,24,3,21,10,1,5,17,20,7,12,2,15,11,4,22,25,19,6,23,14

  ROTOR_I_STEPS:    db     16 
  ROTOR_II_STEPS:   db      4   ; 'F'
  ROTOR_III_STEPS:  db     21   ; 'W'     'V' -> 'W' step with change to 'W'
  ROTOR_IV_STEPS:   db      9   ; 'K'
  ROTOR_V_STEPS:    db     25   ; 'A'
  ROTOR_VI_STEPS:   db  25,12   ; 'AN'
  ROTOR_VII_STEPS:  db  25,12   ; 'AN'
  ROTOR_VIII_STEPS: db  25,12   ; 'AN'
  
  reflector_array: dd REFLECTOR_B, REFLECTOR_C, REFLECTOR_B_thin, REFLECTOR_C_thin
  REFLECTOR_NAME_B:    db 'B'
  REFLECTOR_NAME_C:    db 'C'
  REFLECTOR_NAMES_END: db  0 
  REFLECTOR_NAMES: dd REFLECTOR_NAME_B,REFLECTOR_NAME_C,REFLECTOR_NAMES_END

  rotor_array: dd ROTOR_I,ROTOR_II,ROTOR_III,ROTOR_IV,ROTOR_V,ROTOR_VI,ROTOR_VII,ROTOR_VIII
  steps_array: dd ROTOR_I_STEPS,ROTOR_II_STEPS,ROTOR_III_STEPS,ROTOR_IV_STEPS,ROTOR_V_STEPS,ROTOR_VI_STEPS,ROTOR_VII_STEPS,ROTOR_VIII_STEPS
  rotor_rev_array: dd ROTOR_I_REV,ROTOR_II_REV,ROTOR_III_REV,ROTOR_IV_REV,ROTOR_V_REV,ROTOR_VI_REV,ROTOR_VII_REV,ROTOR_VIII_REV

  errmsg0: db 'ERROR : ',10,0
  errmsg1: db 'Usage : e.g. 012 B "AX BY" DCB AAA INPUTTEXT',10,0
  errmsg_array: dd errmsg0,errmsg1
  
  ROTOR_RIGHT:  dd 0,0,0,0,0
  ROTOR_MIDDLE: dd 0,0,0,0,0
  ROTOR_LEFT:   dd 0,0,0,0,0  
  REFLECTOR:    dd 0


file_size equ $ - $$

ABSOLUTE $

UNIQUENESS_ARRAY: resb 90  

ROTOR_SEL_IDX                   equ   0
ROTOR_RS_IDX                    equ   1
ROTOR_WP_IDX                    equ   2
ROTOR_STEP1_IDX                 equ   3
ROTOR_STEP2_IDX                 equ   4

ERROR_USAGE                     equ   4

mem_size equ $ - $$
