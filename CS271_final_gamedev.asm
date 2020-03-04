TITLE gamedev     (CS271_final_gamedev.asm)

; Author:
; Course / Project ID                 Date:
; Description:

INCLUDE Irvine32.inc
INCLUDE Macros.inc


.data

.code
main PROC

L1: mov EAX, 10
    call Delay
    call ReadKey
    jz L1

    cmp dx, VK_RIGHT
    jne L2
    mWrite <"Right key is pressed", 0dh, 0ah>
    jmp L4
L2: 
    cmp dx, VK_LEFT
    jne L3
    mWrite <"Left key is pressed", 0dh, 0ah>
    jmp L4
L3: 
    mWrite <"Arrow key is not pressed", 0dh, 0ah>
L4:
    exit	; exit to operating system
main ENDP


END main