%define KEY_STOP
%define STOP_BOARD
%define KEY_CNT

CPU 386
org 100h 

section .text 

start:
x_i:    
    mov ax, 013h     ;VGA mode
    int 10h         ;320 x 200 16 colors.
y_i:    
    mov ax,0A000h
    mov es,ax       ;ES points to the video memory.

next_point:
;r(n+1) = r(n) + h*v(n)
;v(n+1) = v(n) - h*((k/(r^3))x + b/x^2 - b/(L_x - x)^2)
    fninit

    fld     dword [d_t]
    fld     dword [x_]  ;1
    fmul    st0 ;dword [x_]  ;2
    fld     dword [y_]  ;3
    fmul    st0 ;dword [y_]  ;4
    fadd    st0, st1    ;5

    fld     st0         ;st(0) = r^2, st(1) = r^2
    fsqrt               ;st(0) = r
    fmul    st0, st1    ;6

    fstp
    fld     dword [ka]  ;7
    fld     dword [ka]
    fdiv    st0, st2    ;8
    fmul    dword [x_]  ;9
    fld     dword [y_]  
    fmul    st0, st2    ;10
    fdiv    st0, st3    ;11
    fld     dword [y_]
    fadd    dword [L_y]
    fmul    st0, st0
    fdivr   dword [kb]  ;12
    faddp               ;13
    fld     dword [L_y]
    fsub    dword [y_]  ;14
    fmul    st0, st0    ;15
    fdivr   dword [kb]  ;16
    fsubp               ;17
    fld     dword [v_y] 
    fmul    st0, st6
    fadd    dword [y_]  
    fst     dword [y_]  ;update y
    fadd    dword [L_y]
    frndint

%ifdef STOP_BOARD
    ftst ;ficom   word [board_zero]
    fnstsw   ax
    mov cx, ax
    ficom   word [board_y_r]
    fnstsw  ax
    or      ax, cx
    and     ax, 4000h
    jnz $
%endif

    fistp   dword [y_i] ;update Y coordinate

    fmul    st0, st5
    fadd    dword [v_y] ;18
%ifdef KEY_CNT
    mov ah, 1  ;ah = 01
    int 16h
    jz return_v_y
    xor ah, ah
    int 16h

    cmp ah, 17  ; 17 - scan code "w"(up) key
    jz up_v_i
    cmp ah, 31  ; 31 - scan code "s"(down) key
    jz down_v_i
return_v_y:
    fstp    dword [v_y] ;update V_y ; 19
%endif

    fld     dword [x_]
    fadd    dword [L_x]
    fmul    st0, st0
    fdivr   dword [kb]  ;20
    fld     dword [L_x]
    fsub    dword [x_]
    fmul    st0, st0    ;21
    fdivr   dword [kb]  ;22
    fsubp
    faddp   ;st0, st1    ;23
    fld     dword [v_x]
    fmul    st0, st5
    fadd    dword [x_]
    fst     dword [x_]  ;update x
    fadd    dword [L_x]
    frndint

%ifdef STOP_BOARD
    mov     bx, ax
    ftst
    fnstsw  ax
    mov     cx, ax

    ficom   word [board_x_r]
    fnstsw  ax
    or      ax, cx
    and     ax, 4000h
    jnz $
    mov     ax, bx
%endif
    fistp   dword [x_i] ;update X coordinate

    fmul    st0, st4
    fadd    dword [v_x] ;24

%ifdef KEY_CNT
    cmp ah, 32  ; 32 - scan code "d"(right) key
    jz right_v_i
    cmp ah, 30  ; 30 - scan code "a"(left) key
    jz left_v_i
    
    jmp end_compute

left_v_i:
    fsub    dword [dv]
    jmp end_compute
right_v_i:
    fadd    dword [dv]
    jmp end_compute
down_v_i:
    fsub    dword [dv]
    jmp return_v_y
up_v_i:
    fadd    dword [dv]
    jmp return_v_y
end_compute:
%endif

    fst     dword [v_x] ;update V_x
    ;input:         (x_i, y_i)
    ;output: di -   (address)
    ;mov di, word [y_i]
    mov ax, 200
    sub ax, word [y_i];di
    mov di, 320 
    mul di
    add ax, word [x_i]
    sub ax, 320
    mov di, ax
    mov byte [es:di], 0fh ;drow point

%ifdef KEY_STOP
    mov ah, 1  ;ah = 01
    int 16h
    jnz read_key
    jmp next_point
read_key:
    xor ah, ah
    int 16h
    cmp ah, 28  ; 28 - scan code Enter
    jz $
%endif
    jmp next_point


section .data
%ifdef KEY_CNT
dv          dd      0.01
%endif
%ifdef STOP_BOARD
board_y_r   dw      200
board_x_r   dw      320
%endif
ka          dd      -0.07
kb          dd      0.1
L_x         dd      160.0
L_y         dd      100.0
d_t         dd      0.005
x_          dd      -50.0
y_          dd      50.0
v_x         dd      0.1
v_y         dd      0.1