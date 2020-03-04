TITLE gamedev     (CS271_final_gamedev.asm)

; Author:
; Course / Project ID                 Date:
; Description:

INCLUDE Irvine32.inc
INCLUDE Macros.inc


.data

.code
main PROC

KeyInput:
    KeyInputLoop:
        mov EAX, 10     ; Delay time
        call Delay      ; Delay
        call ReadKey    ; Read Key input
        jz KeyInputLoop ; Jump back to KeyInputLoop if there is no key input
    LeftKeyCheck:
        cmp dx, VK_LEFT
        jne UpKeyCheck
        mWrite <"Left key is pressed", 0dh, 0ah>
        jmp KeyInputEnd
    UpKeyCheck:
        cmp dx, VK_UP
        jne RightKeyCheck
        mWrite <"Up key is pressed", 0dh, 0ah>
        jmp KeyInputEnd
    RightKeyCheck:
        cmp dx, VK_Right
        jne DownKeyCheck
        mWrite <"Right key is pressed", 0dh, 0ah>
        jmp KeyInputEnd
    DownKeyCheck:
        cmp dx, VK_DOWN
        jne EscapeKeyCheck
        mWrite <"Down key is pressed", 0dh, 0ah>
        jmp KeyInputEnd
    EscapeKeyCheck:
        cmp dx, VK_ESCAPE
        jne OtherKeyPressed
        mWrite <"ESCAPE key is pressed", 0dh, 0ah>
        jmp TempExit
    OtherKeyPressed: 
        mWrite <"Other key is pressed", 0dh, 0ah>
        jmp KeyInputEnd

KeyInputEnd:
    jmp KeyInput

TempExit:
    exit	; exit to operating system

main ENDP


END main