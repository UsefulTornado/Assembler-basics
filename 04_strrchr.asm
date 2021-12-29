; Task:
; strrchr – finds the last occurrence of a character

; char *strrchr (const char *str, int ch)

; Parameters
; str	-	pointer to the null-terminated byte string to be analyzed
; ch	-	character to search for

; Return value
; Pointer to the found character in str, or null pointer if no such character is found.

assume cs: code, ds: data

data segment
dummy db 0Ah, '$'
string db 100, 103 dup ('$')
char db 2, 5 dup('$')
data ends

code segment

strrchar proc
	push bp ; push bp to save its value
	mov bp, sp

    mov bx, [bp+4]
    add bx, 2
    mov al, [bx] ; char

    mov bx, [bp+6]
    add bx, 102 ; the end of string

    pop bp ; restore bp value
    pop dx ; save the return of proc address

    mov cx, 100 ; max length of string

    iter:
        cmp al, [bx] ; compare current symbol of string with our char
        je exit ; if equal we found needed last occurrence so we can return

        dec bx ; keep moving from the end of the string
        loop iter

    add bx, 104 ; return the end of the string if we didn't find the char

    exit:
        push bx ; push return value to stack
        push dx ; push the return of proc address back

	ret
strrchar endp

start:
    mov ax, data
	mov ds, ax

    ; scan an input string
	mov dx, offset string
	mov ax, 0
	mov ah, 0Ah
	int 21h

    push dx ; push the string to stack

    ; make a carriage return
    mov dx, offset dummy
	mov ah, 09h
	int 21h

    ; scan an input char
    mov dx, offset char
	mov ax, 0
	mov ah, 0Ah
	int 21h

    push dx ; push the char to stack

    ; make a carriage return
	mov dx, offset dummy
	mov ah, 09h
	int 21h

    ; now we have our string and char on the stack so let's call strrchar proc
    call strrchar

    ; strrchar worked so we have the result on the stack - let's pop it
    pop dx

    ; we have last occurrence of a character offset in dx so
    ; we can print the string from this char till the end
	mov ah, 09h
	int 21h

	mov ah, 4ch
	int 21h

code ends
end start
