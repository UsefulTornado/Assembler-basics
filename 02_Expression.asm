assume CS: code, DS: data

data segment
a dw 1024
b dw 3010
c dw 4087
d dw 4012
res db "             $"
data ends

code segment
start:
    mov ax, data
    mov ds, ax

    ; res = c - (a + b) / 2 + d = (c * 2 - a - b) / 2 + d
    ; ==========
    mov ax, c
    shl ax, 1
    sub ax, a
    sub ax, b
    shr ax, 1
    add ax, d
    ; ==========

    mov bx, 10 ; divider
    xor cx, cx ; number of digits

split: ; extract digits and push their ASCII code to stack
    xor dx, dx
    div bx
    add dx, '0'
    push dx
    inc cx
    cmp ax, 0
    jnz split


    mov di, offset res ; offset of result

put_result: ; pop digits from stack and put them to res in data segment
    pop ax
    mov ds:[di], ax
    inc di
    loop put_result

    mov ax, '$'
    mov ds:[di], ax

    ; now DS contains expression result so we can print it with 'int 21h'
    mov ah, 09h
    mov dx, offset res
    int 21h


    mov ax, 4C00h
    int 21h

code ends
end start
