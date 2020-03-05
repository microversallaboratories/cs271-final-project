TITLE gamedev     (CS271_final_gamedev.asm)

; Author:
; Course / Project ID                 Date:
; Description:

INCLUDE Irvine32.inc
INCLUDE Macros.inc

BUFFER_SIZE = 5000
; MIN_X EQU 0                                       ; WIP
; MAX_X EQU 32                                      ; WIP

.data
endl        EQU <0dh, 0ah>                          ; End of Line Sequence
gameTitle   BYTE "@'s Adventure", 0
consoleSize SMALL_RECT <0, 0, 40, 20>
consoleCursor CONSOLE_CURSOR_INFO <100, 0>          ; Set second Argument to 1 if want to see visible cursor

fileBuffer  BYTE BUFFER_SIZE DUP (?)
fileX       DWORD 20
fileY       DWORD 10
fileName    BYTE "map1.txt", 0
fileHandle  HANDLE ?

charX       BYTE 10                                 ; Size of DL: 1 byte
charY       BYTE 6                                  ; Size of DH: 1 byte
char        BYTE "@", 0                             ; Character
sharp       BYTE "#", 0                             ; Sharp

consoleHandle HANDLE 0
bytesWritten DWORD ?

.code
main PROC
Setup:
    INVOKE SetConsoleTitle, ADDR gameTitle
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov consoleHandle, EAX

    INVOKE SetConsoleWindowInfo, 
        consoleHandle,
        TRUE,
        ADDR consoleSize

    INVOKE SetConsoleCursorInfo,
        consoleHandle,
        ADDR consoleCursor

    FileIO:
        mov EDX, OFFSET fileName
        call OpenInputFile
        mov fileHandle, EAX

        cmp EAX, INVALID_HANDLE_VALUE
        jne fileOpened
        mWrite <"Cannot Open File", 0dh, 0ah>
        jmp TempExit

    fileOpened:
        mov EDX, OFFSET fileBuffer
        mov ECX, BUFFER_SIZE
        call ReadFromFile
        jnc checkBufferSize
        mWrite <"Error reading File. ", 0dh, 0ah>
        jmp fileClose

    checkBufferSize:
        cmp EAX, BUFFER_SIZE
        jb bufferSizeOK
        mWrite <"ERROR: buffer too small for the file", 0dh, 0ah>
        jmp TempExit

    bufferSizeOK:
        mov fileBuffer[EAX], 0
        mWrite "File size: "
        call WriteDec
        call Crlf

    fileClose:
        mov EAX, fileHandle
        call CloseFile
    

GameLoop:

DrawBackground:
    ; Don't call Clrscr, as it is slow
    mov DL, 0
    mov DH, 0
    call Gotoxy

    mov EDX, OFFSET fileBuffer
    call WriteString    

DrawCharacter:
    mov DL, charX           ; X-Coordinate
    mov DH, charY           ; Y-Coordinate
    call Gotoxy             ; locate Cursor
    
    INVOKE WriteConsole,    ; Write character '@'
        consoleHandle,
        ADDR char,
        1,
        ADDR bytesWritten,
        0

KeyInput:
    KeyInputLoop:
        mov EAX, 10         ; Delay time
        call Delay          ; Delay
        call ReadKey        ; Read Key input
        jz KeyInputLoop     ; Jump back to KeyInputLoop if there is no key input
    LeftKeyCheck:
        cmp dx, VK_LEFT
        jne UpKeyCheck
        ; mWrite <"Left key is pressed", endl>
        sub charX, 1

        ;push OFFSET fileBuffer
        ;call checkWall

        jmp KeyInputEnd
    UpKeyCheck:
        cmp dx, VK_UP
        jne RightKeyCheck
        ; mWrite <"Up key is pressed", endl>
        sub charY, 1
        jmp KeyInputEnd
    RightKeyCheck:
        cmp dx, VK_Right
        jne DownKeyCheck
        ; mWrite <"Right key is pressed", endl>
        add charX, 1
        jmp KeyInputEnd
    DownKeyCheck:
        cmp dx, VK_DOWN
        jne EscapeKeyCheck
        ; mWrite <"Down key is pressed", endl>
        add charY, 1
        jmp KeyInputEnd
    EscapeKeyCheck:
        cmp dx, VK_ESCAPE
        jne OtherKeyPressed
        ; mWrite <"ESCAPE key is pressed", endl>
        jmp TempExit
    OtherKeyPressed: 
        ; mWrite <"Other key is pressed", endl>
        jmp KeyInputEnd

KeyInputEnd:
    INVOKE ReadKeyFlush
    jmp GameLoop

TempExit:
    exit	; exit to operating system

main ENDP
    
checkWall PROC      ; WIP
    ;mov EDI, OFFSET sharp
    ;lodsb
    ;scasb

    std
    mov EBP, ESP
    add ESI, [EBP+4]


checkWall ENDP

END main