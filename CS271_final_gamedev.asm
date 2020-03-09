TITLE gamedev     (CS271_final_gamedev.asm)

; Author: 
; Course / Project ID                 Date:
; Description:

INCLUDE Irvine32.inc
INCLUDE Macros.inc

BUFFER_SIZE EQU <512>
MAP_QTY     EQU <5>

.data
endl        EQU <0dh, 0ah>                          ; End of Line Sequence
gameTitle   BYTE "@'s Adventure", 0
consoleSize     SMALL_RECT <0, 0, 40, 20>
consoleCursor   CONSOLE_CURSOR_INFO <100, 0>        ; Set second Argument to 1 if want to see visible cursor

fileBuffer  BYTE MAP_QTY DUP(BUFFER_SIZE DUP (?))
fileX       DWORD 20
fileY       DWORD 10
curMap      BYTE BUFFER_SIZE DUP (?)
curMapNum   DWORD 0
fileName    DWORD "A", 0
fileHandle  HANDLE ?

charX       BYTE    10                              ; Size of DL: 1 byte - starting xpos
charY       BYTE    6                               ; Size of DH: 1 byte - starting ypos
char        BYTE    "@", 0                          ; Character
sharp       BYTE    "#", 0                          ; Sharp
inventory   BYTE    10 DUP(?)                       ; Inventory; arr of chars

consoleHandle HANDLE 0
bytesWritten DWORD ?

.code

DrawInventory   PROC
    ; implement for-loop to loop through inventory items and print each one
    push    ebp
    mov ebp,    esp         ; preserve ebp
    mov esi,    [ebp+6]     ; address of inventory in esi; size of each element in the inventory * 3
    mov ecx,    [ebp+4]     ; count in ecx
    
    forloop:
        mov eax,    esi     ; move the current element into the eax register
        call    WriteDec    ; write it out to the terminal
        call    Crlf        ; newline
        add     esi,    2   ; increment the instruction pointer
        loop    forloop     ; loop
    pop ebp
    ret 4
DrawInventory   ENDP

main PROC

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

    push    OFFSET fileBuffer       ; Put @fileBuffer to stack as reference 
    push    MAP_QTY                 ; Put MAP_QTY to stack as value
    push    BUFFER_SIZE             ; Put BUFFER_SIZE to stack as value
    push    OFFSET fileName         ; Put fileName to stack as reference
    call    readMap                 ; Read Map files and store them in array

    cmp     EAX, 0
    je      GameExit                ; Jump to GameExit if EAX = 0
    

GameLoop:

DrawBackground:
    ; Don't call Clrscr, as it is slow
    mov     DL, 0
    mov     DH, 0
    call    Gotoxy

    push    OFFSET fileBuffer       ; Put @fileBuffer to stack as reference 
    push    OFFSET curMap           ; Put @curMap to stack as reference
    push    BUFFER_SIZE             ; Put BUFFER_SIZE to stack as value 
    push    curMapNum               ; Put curMapNum to stack as value
    call    drawMap                 ; Draw Map from array

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
readMap     PROC
;
;   Read Map from text file and store them in array
;       Uses Register Indirect Mode 
;   Receive:    fileBuffer, MAP_QTY, BUFFER_SIZE, filename
;   Return:     EAX
;------------------------------------------------------------------------------------- 
    push    EBP
    mov     EBP, ESP
    pushad
    mov     EDI, [EBP+20]       ; @Array
    mov     ECX, [EBP+16]       ; Map Quantity
    mov     EBX, [EBP+8]        ; fileName
    mov     ESI, 1              ; Used to increment FileName

ReadMapFromFile:
    push ECX
    FileIO:
        mov     EDX, EBX        ; Filename (A, B, C, ... , Qty-1)
        call    OpenInputFile   ; Open the file
        mov     fileHandle, EAX ; Check how file went through
        cmp     EAX, INVALID_HANDLE_VALUE
        jne     fileOpened      ; Jump to next stage if opened
        mov     EAX, 0
        jmp     EndReading      ; Exit Procedure with EAX = 0, which Exit program

    fileOpened:
        mov     EDX, EDI            ; Load Address of Array to EDX
        mov     ECX, [EBP+12]       ; Load Buffer Size to ECX
        call    ReadFromFile        ; Read from the file and store it to address of array with buffer size total
        jnc     bufferSizeOK         
        mWrite  <"Error reading File. ", 0dh, 0ah>
        jmp     fileClose

    checkBufferSize:
        cmp     EAX, [EBP+12]       ; Compare Actual Map Size
        jb      bufferSizeOK        ; Jump to Size display if below Buffer size
        mov     EAX, 0
        jmp     EndReading          ; Exit Procedure with EAX = 0, which Exit program

    bufferSizeOK:
        mWrite  "File size: "       ; Debug purpose. Displays the size of map file
        call    WriteDec
        call    Crlf

    fileClose:
        mov     EAX, fileHandle
        call    CloseFile           ; Close opened file

    add     EDI, [EBP+12]           ; Increase current address pointing by Buffer size
    add     [EBX], ESI              ; Increase file name (A -> B, B -> C, .... )
    pop     ECX                     ; Pop ECX to continue counter
    loop    ReadMapFromFile         ; Loop back to reading


    popad
    mov     EAX, 1
EndReading:
                                    ; Immediately end procedure if this Label is called
    pop     EBP
    ret     12
readMap     ENDP
;-------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------
drawMap     PROC
;
;   Read Map from text file and store them in array
;       Uses Register Indirect Mode 
;   Receive:    fileBuffer, curMap, MAP_QTY, BUFFER_SIZE
;   Return:     EAX
;-------------------------------------------------------------------------------------
    push    EBP
    mov     EBP, ESP
    pushad
    mov     EDI, [EBP+20]       ; @fileBuffer
    mov     ESI, [EBP+16]       ; @curMap

    mov     EAX, [EBP+12]       ; BUFFER_SIZE
    mov     EBX, [EBP+8]        ; curMapNum
    mul     EBX                 ; EAX = curMapNum * BUFFER_SIZE

    add     EDI, EAX            ; EDI is moved curMapNum * BUFFER_SIZE

    mov     EAX, [EBP+12]       ; BUFFER_SIZE
    mov     EBX, 4              ; 4 to EBX
    cdq
    div     EBX                 ; BUFFER_SIZE / 4
    mov     ECX, EAX            ; Set loop counter to EAX
    
L1:
    mov     EAX, [EDI]          ; Copy fileBuffer Array[i] to EAX
    mov     [ESI], EAX          ; Copy EAX to curMap Array[i]
    add     EDI, 4              ; Move on to next index
    add     ESI, 4              ; Move on to next index
    loop    L1                  ; Loop to L1. Copies fileBuffer to curMap

    mov     ESI, [EBP+16]       ; @curMap array[0]
    mov     EDX, ESI            ; Move it to display string
    call    WriteString
    
    popad
    pop     EBP
    ret     16
drawMap     ENDP
;-------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------
KeyInput    PROC
;
;   Read Key Input and move character's coordination.
;       Return 1 to EAX if continuing, 0 if Exiting Game
;   Receive:    charX, charY
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

        ;push OFFSET curMap
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


;-------------------------------------------------------------------------------------
checkWall PROC      
;
;   Check if there is wall at the player's coordinate
;       Return 1 to EAX if there is no wall, 0 if exist
;   Receive:    curMap, charX, charY
;   Return:     EAX
;-------------------------------------------------------------------------------------
    ;mov EDI, OFFSET sharp
    ;lodsb
    ;scasb

    std
    mov EBP, ESP
    add ESI, [EBP+4]


checkWall ENDP
;-------------------------------------------------------------------------------------

END main