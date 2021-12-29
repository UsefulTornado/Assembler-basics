include macro.asm

assume cs: code, ds: data

data segment
dummy db 0Ah, '$'
string db 100, 103 dup ('$')
res db 100 dup ('$')
data ends

code segment
start:
    mov ax, data
	mov ds, ax

    ; scan an input string
	mov dx, offset string
	mov ax, 0
	mov ah, 0Ah
	int 21h

    ; use macro from 'macro.asm' file
    exclude_redundant_spaces string, res

    ; make a carriage return
    mov dx, offset dummy
	mov ah, 09h
	int 21h

    ; put result in dx and print it
    mov dx, offset res
	mov ah, 09h
	int 21h

	mov ah, 4ch
	int 21h

code ends
end start
