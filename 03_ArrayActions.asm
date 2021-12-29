assume CS: code, DS: data

data segment
len dw 10
arr dw 401, 302, 104, 502, 400, 304, 201, 609, 808, 745
res db 100 dup (?) ; > len('65536') * 10 + len(9 spaces) + len('$')
data ends

code segment
start:
    mov ax, data
    mov ds, ax

    mov cx, len
    dec cx
    mov bx, arr ; current max elem
    mov si, 2 ; offset of current elem

    ; task: replace every elem of array by current maximum
    iter:
        mov dx, word ptr arr[si]
        cmp bx, dx
        jge replace ; skip update_max if not required

        update_max:
            mov bx, dx

        replace:
            mov word ptr arr[si], bx

        add si, 2
        loop iter

    mov di, offset res ; offset of result
    mov si, 0 ; offset of current elem
    mov bx, 10 ; divider
    mov cx, len ; number of iterations

    put_result: ; put array elems (separated by space) to data segment
        push cx ; save the current index of iteration

        mov ax, word ptr arr[si] ; current elem of arr
        add si, 2
        xor cx, cx ; number of digits

        split: ; extract digits and push their ASCII code to stack
            xor dx, dx
            div bx
            add dx, '0'
            push dx
            inc cx
            cmp ax, 0
            jnz split

        put_number: ; pop digits from stack and put them to res in data segment
            pop dx
            mov ds:[di], dx
            inc di
            loop put_number

        mov dx, ' '
        mov ds:[di], dx ; add separator between numbers
        inc di

        pop cx ; restore index of iteration

        loop put_result

    mov dx, '$'
    mov ds:[di], dx ; add end-of-string symbol

    ; print array elems with 'int 21h'
    mov ah, 09h
    mov dx, offset res
    int 21h

    mov ax, 4C00h
    int 21h

code ends
end start
