TITLE gamedev     (CS271_final_gamedev.asm)

; Author:
; Course / Project ID                 Date:
; Description:

INCLUDE Irvine32.inc
INCLUDE Macros.inc

; MIN_X EQU 0                                       ; WIP
; MAX_X EQU 32                                      ; WIP

.data
endl        EQU <0dh, 0ah>                          ; End of Line Sequence
gameTitle   BYTE "@'s Adventure", 0
consoleSize SMALL_RECT <0, 0, 40, 20>
consoleCursor CONSOLE_CURSOR_INFO <100, 0>          ; Set second Argument to 1 if want to see visible cursor

charX       BYTE    10                                 ; Size of DL: 1 byte - starting xpos
charY       BYTE    6                                  ; Size of DH: 1 byte - starting ypos
char        BYTE    "@", 0                             ; Character
wall        BYTE    "################", 0              ; Wall, 16 character long
sideWall    BYTE    "#..............#", 0              ; Side Wall
lineNumber  BYTE    1
inventory   BYTE    10 DUP(?)                          ; Inventory; arr of chars

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

GameLoop:

DrawBackground:
    ; Don't call Clrscr, as it is slow
    mov lineNumber, 0               ; reset lineNumber to zero
    mov DL, 0
    mov DH, lineNumber
    call Gotoxy
    
    INVOKE WriteConsole,            ; Write Top wall
        consoleHandle,
        ADDR wall,
        16,
        ADDR bytesWritten,
        0

    mov ECX, 10                     ; # of loops
    inc lineNumber

    SideWallLoop:
        mov DL, 0
        mov DH, lineNumber
        call Gotoxy
        push ECX

        INVOKE WriteConsole,        ; Write side wall
            consoleHandle,
            ADDR sideWall,
            16,
            ADDR bytesWritten,
            0

        pop ECX
        inc lineNumber
        loop SideWallLoop

    mov DL, 0
    mov DH, lineNumber
    call Gotoxy
    
    INVOKE WriteConsole,             ; Write Bottom wall
        consoleHandle,
        ADDR wall,
        16,
        ADDR bytesWritten,
        0

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

DrawInventory:
    ; implement for-loop to loop through inventory items and print each one

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
        sub charX, 1        ; Move character one space to the left
        jmp KeyInputEnd
    UpKeyCheck:
        cmp dx, VK_UP
        jne RightKeyCheck
        ; mWrite <"Up key is pressed", endl>
        sub charY, 1        ; Move character one space up
        jmp KeyInputEnd
    RightKeyCheck:
        cmp dx, VK_Right
        jne DownKeyCheck
        ; mWrite <"Right key is pressed", endl>
        add charX, 1        ; Move character one space to the right
        jmp KeyInputEnd
    DownKeyCheck:
        cmp dx, VK_DOWN
        jne EscapeKeyCheck
        ; mWrite <"Down key is pressed", endl>
        add charY, 1        ; Move character one space down
        jmp KeyInputEnd
    EscapeKeyCheck:
        cmp dx, VK_ESCAPE
        jne OtherKeyPressed
        ; mWrite <"ESCAPE key is pressed", endl>
        jmp TempExit        ; Exit game
    OtherKeyPressed: 
        ; mWrite <"Other key is pressed", endl>
        jmp KeyInputEnd     ; "Ignore" invalid input

KeyInputEnd:                ; Move has been made
    INVOKE ReadKeyFlush     ; Clear the current key
                            ; Check for an object on the ground, add it if there
                            ; IF the key is in the user's inventory, 
                            ; Check if they are next to a door
                            ; If next to a door,
                            ; Unlock the door
                            ; Place the character in the next room
    jmp GameLoop            ; Repeat the game loop

TempExit:
    exit	                ; exit to operating system

main ENDP
    
END main