; this macro receives string as var 'str' and
; put this string without redundant spaces to var 'res'

exclude_redundant_spaces MACRO str, res
    mov ax, '-' ; some kind of flag that represents if the last char was a space
    mov di, offset res ; we will use di as index to put chars in res
    mov si, 1
    mov cl, byte ptr str[si] ; now we have in cl number of string's chars

    iter:
        inc si
        mov dl, byte ptr str[si] ; current char

        cmp dl, ' '
        jne not_space ; we can put char to res if it isn't space

        cmp ax, '-' ; check if last char wasn't space
        mov ax, '+' ; we got here if we met a space so we have to raise the flag
        je put_char ; ; we can put char to res if last char wasn't space

        jmp end_iter ; we don't have to put repeated space to string

        not_space:
            mov ax, '-' ; put down the flag if current char isn't space

        put_char:
            mov ds:[di], dl ; put current char to res at needed address
            inc di

        end_iter:
            loop iter
endm
