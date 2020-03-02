TITLE gamedev     (CS271_final_gamedev.asm)

; Author:
; Course / Project ID                 Date:
; Description:

INCLUDE Irvine32.inc

; (insert constant definitions here)

.data

; (insert variable definitions here)
    ex BYTE "test 1 2 3.", 0

.code
main PROC

; (insert executable instructions here)
    call Clrscr
    mov EDX, OFFSET ex
    call WriteString
    call Crlf

	exit	; exit to operating system
main ENDP

; (insert additional procedures here)

END main