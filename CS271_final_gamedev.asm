TITLE gamedev     (CS271_final_gamedev.asm)

; Author:
; Course / Project ID                 Date:
; Description:

INCLUDE Irvine32.inc


.data

    ex BYTE "test 1 2 3.", 0

.code
main PROC
begin:
    call Clrscr
    mov EDX, OFFSET ex
    call WriteString
    call Crlf

	exit	; exit to operating system
main ENDP


END main