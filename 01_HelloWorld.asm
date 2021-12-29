assume CS: code, DS: data

data segment
msg db "Hello, world!$"
data ends

code segment
start:
    mov ax, data
    mov ds, ax
    mov ah, 09h
    mov dx, offset msg
    int 21h
    mov ax, 4C00h
    int 21h
code ends

end start
