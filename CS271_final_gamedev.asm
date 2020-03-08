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
consoleSize     SMALL_RECT <0, 0, 40, 20>
consoleCursor   CONSOLE_CURSOR_INFO <100, 0>          ; Set second Argument to 1 if want to see visible cursor

fileBuffer  BYTE BUFFER_SIZE DUP (?)
fileX       DWORD 20
fileY       DWORD 10
fileName    BYTE "map1.txt", 0
fileHandle  HANDLE ?

charX       BYTE    10                                 ; Size of DL: 1 byte - starting xpos
charY       BYTE    6                                  ; Size of DH: 1 byte - starting ypos
char        BYTE    "@", 0                             ; Character
sharp       BYTE    "#", 0                             ; Sharp
inventory   BYTE    10 DUP(?)                          ; Inventory; arr of chars

consoleHandle   HANDLE 0
bytesWritten    DWORD ?

.code

main    PROC
Setup:
    INVOKE  SetConsoleTitle, ADDR gameTitle
    INVOKE  GetStdHandle, STD_OUTPUT_HANDLE
    mov     consoleHandle, EAX

    INVOKE  SetConsoleWindowInfo, 
        consoleHandle,
        TRUE,
        ADDR consoleSize

    INVOKE  SetConsoleCursorInfo,
        consoleHandle,
        ADDR consoleCursor

    FileIO:
        mov     EDX, OFFSET fileName
        call    OpenInputFile
        mov     fileHandle, EAX

        cmp     EAX, INVALID_HANDLE_VALUE
        jne     fileOpened
        mWrite  <"Cannot Open File", 0dh, 0ah>
        jmp     GameExit

    fileOpened:
        mov     EDX, OFFSET fileBuffer
        mov     ECX, BUFFER_SIZE
        call    ReadFromFile
        jnc     checkBufferSize
        mWrite  <"Error reading File. ", 0dh, 0ah>
        jmp     fileClose

    checkBufferSize:
        cmp     EAX, BUFFER_SIZE
        jb      bufferSizeOK
        mWrite  <"ERROR: buffer too small for the file", 0dh, 0ah>
        jmp     GameExit

    bufferSizeOK:
        mov     fileBuffer[EAX], 0
        mWrite  "File size: "
        call    WriteDec
        call    Crlf

    fileClose:
        mov     EAX, fileHandle
        call    CloseFile
    

GameLoop:

DrawBackground:
    ; Don't call Clrscr, as it is slow
    mov     DL, 0
    mov     DH, 0
    call    Gotoxy

    mov     EDX, OFFSET fileBuffer
    call    WriteString    

DrawCharacter:
    mov     DL, charX           ; X-Coordinate
    mov     DH, charY           ; Y-Coordinate
    call    Gotoxy              ; locate Cursor
    
    INVOKE WriteConsole,        ; Write character '@'
        consoleHandle,
        ADDR char,
        1,
        ADDR bytesWritten,
        0

    call    KeyInput            ; Read key and change coordinate
                                ; Return 0 in EAX if Exiting, 1 in EAX if Continuing
    cmp     EAX, 0
    je      GameExit            ; Jump to GameExit if EAX = 0
    jmp     GameLoop            ; Jump to GameLoop if EAX = 1

GameExit:
    exit	                      ; exit to operating system

main    ENDP

;-------------------------------------------------------------------------------------
KeyInput    PROC
;
;   Read Key Input and move character's coordination.
;       Return 1 to EAX if continuing, 0 if Exiting Game
;   Receive:    None
;   Return:     EAX
;-------------------------------------------------------------------------------------
    KeyInputLoop:
        mov     EAX, 10         ; Delay time
        call    Delay           ; Delay
        call    ReadKey         ; Read Key input
        jz      KeyInputLoop    ; Jump back to KeyInputLoop if there is no key input

    LeftKeyCheck:           
        cmp     dx, VK_LEFT     ; Check if Left Arrow key is pressed
        jne     UpKeyCheck
        sub     charX, 1        ; Move character one space to the left

        ;push OFFSET fileBuffer
        ;call checkWall

        jmp     KeyInputEnd

    UpKeyCheck:
        cmp     dx, VK_UP       ; Check if Up Arrow key is pressed
        jne     RightKeyCheck
        sub     charY, 1        ; Move character one space up
        jmp     KeyInputEnd

    RightKeyCheck:
        cmp     dx, VK_RIGHT    ; Check if Right Arrow key is pressed
        jne     DownKeyCheck
        add     charX, 1        ; Move character one space to the right
        jmp     KeyInputEnd

    DownKeyCheck:
        cmp     dx, VK_DOWN     ; Check if Down Arrow key is pressed
        jne     EscapeKeyCheck
        add     charY, 1        ; Move character one space down
        jmp     KeyInputEnd

    EscapeKeyCheck:
        cmp     dx, VK_ESCAPE
        jne     OtherKeyPressed
        mov     EAX, 0          ; Set EAX to 0, signifying Exit
                                ; Does not Flush, since the game will Exit
        jmp     EndInput

    OtherKeyPressed: 
        jmp     KeyInputEnd     ; Ignore invalid input

    KeyInputEnd:                ; Move has been made
        INVOKE  ReadKeyFlush    ; Clear the current key
                                ; Set EAX to 1, signifying Continue

    EndInput:
        ret
KeyInput    ENDP
;-------------------------------------------------------------------------------------
    
checkWall PROC      ; WIP
    ;mov EDI, OFFSET sharp
    ;lodsb
    ;scasb

    std
    mov EBP, ESP
    add ESI, [EBP+4]


checkWall ENDP

END main