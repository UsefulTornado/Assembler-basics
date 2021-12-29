assume cs: code, ds: data

data segment

dummy db 0Ah, '$'
IRP var, <number1, number2, tmp, res>
    var db 100, 110 dup ('$')
endm
op db 2, 5 dup('$')
big_number db 0, 105, 1, 104 dup (0), '$'
digit_tmp db 0
grade_tmp db 0
sign db ''

data ends

code segment

start:
    mov ax, data
	mov ds, ax

    ; read input strings in appropriate order
    IRP var, <number1, op, number2>
        ; scan an input string
    	mov dx, offset var
    	mov ax, 0
    	mov ah, 0Ah
    	int 21h

        ; make a carriage return
        mov dx, offset dummy
    	mov ah, 09h
    	int 21h
    endm

    ; check if these strings are really numbers
    IRP var, <number1, number2>
        local check_symbol, return, pass

        mov si, 1
        mov cl, byte ptr var[si] ; we have string length in var[1]

        inc si
        mov dl, byte ptr var[si] ; put next symbol in dl

        ; check if first symbol is '-'
        mov ax, '-'
        cmp dx, ax
        jne check_symbol
        inc si
        dec cl

        ; check if every symbol of the string is digit while cl > 0
        check_symbol:
            mov dl, byte ptr var[si] ; put next symbol in dl

            ; if ASCII code of symbol isn't equal to digits code,
            ; we will stop the program. Otherwise, we will save
            ; the sheer number instead of its ASCII code
            mov ax, '0'
            cmp dx, ax
            jl return

            mov ax, '9'
            cmp dx, ax
            jg return

            sub byte ptr var[si], '0' ; now there is sheer number in var[si]

            inc si
            loop check_symbol

        jmp pass ; skip return if we successfully end iterations

        return:
            mov ah, 4ch
        	int 21h

        pass:
    endm

    ; this MACRO put in res sum of x and y
    ; it requires digits number of x >= digits number of y
    sum MACRO x, y, res
        local column_addition, iter, put_len, put_number, done
        push di ; save di cause we use it's value in multiply MACRO

        xor dx, dx

        ; set di and si to the end of each number
        mov di, 1
        mov dl, byte ptr x[di]
        add di, dx

        mov si, 1
        mov dl, byte ptr y[si]
        add si, dx

        ; we will iterate by digits of y to perform pencil-and-paper addition
        mov cl, dl

        xor ax, ax
        mov bl, 10 ; divider

        column_addition:
            ; before each iteration we have overflow value in al
            add al, byte ptr x[di]
            add al, byte ptr y[si]

            div bl ; now we have overflow value in al and needed digit in ah

            mov dl, ah
            push dx ; assemble sum value on stack sequentially
            xor ah, ah

            dec di
            dec si

            loop column_addition

        ; collect residual digits from x (with overflow if required)
        iter:
            cmp di, 1
            jle done ; run out of x digits

            add al, byte ptr x[di]

            div bl

            mov dl, ah
            push dx
            xor ah, ah

            dec di

            jmp iter

        done:
            mov di, 1
            mov cl, byte ptr x[di]

            mov di, offset res
            inc di

            ; if overflow value isn't equal to 0,
            ; we will push it to stack (it'll be the first digit of result)
            ; and increase len of result
            cmp al, 0
            je put_len

            mov dl, al
            push dx
            inc cl

        put_len:
            mov ds:[di], cl
            inc di

        put_number:
            ; pop digits from stack and put them to res in data segment
            pop dx
            mov ds:[di], dx
            inc di

            loop put_number

        pop di ; restore di
    endm

    ; this MACRO put in res the result of subtraction x - y
    ; it requires x >= y
    subtract MACRO x, y, res
        local column_subtraction, iter, put_len, put_number, done

        xor dx, dx

        ; set di and si at the end of each number
        mov di, 1
        mov dl, byte ptr x[di]
        add di, dx

        mov si, 1
        mov dl, byte ptr y[si]
        add si, dx

        ; we will iterate by digits of y to perform pencil-and-paper addition
        mov cl, dl

        xor ax, ax
        mov bl, 10 ; divider

        column_subtraction:
            ; before each iteration we have borrowed value in al
            add al, byte ptr x[di]
            sub al, byte ptr y[si]

            add al, 10
            div bl
            dec al ; now we have borrowed value in al and needed digit in ah

            mov dl, ah
            push dx ; assemble subtraction result on stack sequentially
            xor ah, ah

            dec di
            dec si

            loop column_subtraction

        ; collect residual digits from x (with borrowed values if required)
        iter:
            cmp di, 1
            jle done ; run out of x digits

            add al, byte ptr x[di]

            add al, 10
            div bl
            dec al

            mov dl, ah
            push dx
            xor ah, ah

            dec di

            jmp iter

        done:
            mov di, 1
            mov cl, byte ptr x[di]

            mov di, offset res
            inc di

        put_len:
            mov ds:[di], cl
            inc di

        put_number:
            ; pop digits from stack and put them to res in data segment
            pop dx
            mov ds:[di], dx
            inc di

            loop put_number
    endm

    ; this MACRO perform multiplication of number by (digit * 10 ^ grade)
    ; and put result to res
    multiply_by_digit MACRO x, digit, grade, res
        local fill_zeros, next, column_multiplication, done, put_len, put_number

        push di ; save di cause we use it's value in multiply MACRO
        xor cx, cx
        xor dx, dx

        mov cl, grade
        cmp cl, 0
        je next

        ; set zeros at the end of result by number of grade
        fill_zeros:
            push dx
            loop fill_zeros

        next:
            ; set di to the end of x
            mov di, 1
            mov cl, byte ptr x[di]
            add di, cx

            xor ax, ax
            mov bh, 0
            mov bl, 10 ; divider

        column_multiplication:
            ; before each iteration we have overflow value in bh
            mov al, byte ptr x[di]
            mul digit

            div bl

            mov dl, ah
            add dl, bh ; now we have needed digit in dl
            push dx ; assemble multiplication result on stack sequentially
            xor ah, ah

            mov bh, al ; now we have overflow value in bh

            dec di

            loop column_multiplication

        done:
            mov di, 1
            mov cl, byte ptr x[di]
            add cl, grade

            mov di, offset res
            inc di

            ; if overflow value isn't equal to 0,
            ; we will push it to stack (it'll be the first digit of result)
            ; and increase len of result
            cmp bh, 0
            je put_len

            mov dl, bh
            push dx
            inc cl

        put_len:
            mov ds:[di], cl
            inc di

        put_number:
            ; pop digits from stack and put them to res in data segment
            pop dx
            mov ds:[di], dx
            inc di

            loop put_number

        pop di ; restore di
    endm

    ; this MACRO put in res product of x and y
    multiply MACRO x, y, res
        local iter, done

        push dx ; save dx
        xor dx, dx

        mov di, 1
        mov bl, byte ptr y[di]
        dec bl
        mov grade_tmp, bl ; grade of y first digit

        inc di
        mov bl, byte ptr y[di]
        mov digit_tmp, bl ; first digit of y

        ; initialize res
        multiply_by_digit x, digit_tmp, grade_tmp, res

        cmp grade_tmp, 0
        jne iter
        jmp done

        ; perform column multiplication
        iter:
            dec grade_tmp
            inc di

            mov bl, byte ptr y[di]
            mov digit_tmp, bl

            multiply_by_digit x, digit_tmp, grade_tmp, tmp

            sum res, tmp, res

            cmp grade_tmp, 0
            je done

            jmp iter

        done:
            pop dx
    endm

    ; this MACRO converts numbers to something similar to two's complement code,
    ; but in decimal notation.
    to_tens_complement MACRO x
        local exit

        ; we'll put in x[0] a sign: 0 is equal to '+', 1 is equal to '-'
        xor di, di
        mov x[di], 0

        ; if string's first symbol is '-', we have to convert it to
        ; "ten's complement code" by subtraction from a big number
        mov di, 2
        cmp x[di], '-'
        jne exit

        mov x[di], 0 ; replace '-' by 0

        subtract big_number, x, x

        xor di, di
        inc x[di] ; put 1 to x[0] that means it's negative

        exit:
    endm

    ; choose input operation and run needed MACRO
    mov di, 2
    mov dl, op[di]

    cmp dl, '-'
    je perform_sub

    cmp dl, '+'
    je perform_sum

    jmp check ; to avoid 'relative jump out of range' error

    perform_sub:
        subtract number1, number2, res
        jmp result

    perform_sum:
        to_tens_complement number1
        to_tens_complement number2

        mov di, 1
        mov dl, number1[di]

        cmp dl, number2[di]
        jge greater
        jmp less

        greater:
            sum number1, number2, res
            jmp set_sign

        less:
            sum number2, number1, res
            jmp set_sign

        set_sign:
            xor di, di
            mov al, number1[di]
            add al, number2[di]

            ; if both numbers have sign '+', our result is positive
            cmp al, 0
            je positive

            ; if (first digit of result (it can only be 0 or 1)) +
            ;   + number1 sign (eq to 1 if '-' and 0 if '+') +
            ;   + number2 sign (eq to 1 if '-' and 0 if '+') === 1 (mod 2),
            ; our result is negative. Otherwise, it's positive.
            mov di, 2
            add al, res[di]

            mov bl, 2
            div bl ; now we have remainder by mod 2 in ah

            cmp ah, 0
            je positive

            negative:
                ; convert number to standard notation
                subtract big_number, res, res
                mov di, 2
                mov res[di], 0
                mov sign, '-' ; var 'sign' contains information about res sign
                jmp result

            positive:
                mov res[di], 0
                jmp result

    check:
        cmp dl, '*'
        je perform_mul
        jmp result

    perform_mul:
        xor dl, dl
        mov di, 2

        ; if we multiply numbers with the same signs, the result is positive.
        ; Otherwise, it's negative
        first:
            cmp number1[di], '-'
            jne second

            mov number1[di], 0 ; replace '-' with 0
            inc dl

        second:
            cmp number2[di], '-'
            jne perform

            mov number2[di], 0 ; replace '-' with 0
            inc dl

        perform:
            multiply number1, number2, res

            ; dl is equal to 1 if result is negative and .. to 0 if positive
            cmp dl, 1
            jne result

            mov sign, '-'

    result:
        mov si, 1
        mov di, 1
        mov cl, byte ptr res[si] ; we have string length in var[1]

        ; skip zeros at the beginning of the result so as not to print them
        skip_zeros:
            inc si
            cmp res[si], 0
            jne catch_zero ; end skipping if we met non-zero digit

            inc di
            loop skip_zeros

        ; if every digit is 0, we have 0 as a result
        catch_zero:
            cmp cl, 0
            jne put_sign
            inc cl
            jmp iter

        ; put '-' at the beginning of the result if needed else skip it
        put_sign:
            inc di
            mov dl, sign
            cmp dl, '-'
            jne iter

            dec di
            mov res[di], dl

        ; transform result to ASCII code
        iter:
            add byte ptr res[si], '0'

            inc si
            loop iter

        ; print result
        mov dx, offset dummy
        mov ah, 09h
        int 21h

        mov dx, offset res
        add dx, di
        mov ah, 09h
        int 21h

	mov ah, 4ch
	int 21h

code ends
end start
