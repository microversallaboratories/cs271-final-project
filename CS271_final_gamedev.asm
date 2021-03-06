TITLE gamedev     (CS271_final_gamedev.asm)

; Author: Hojun Shin, Jacob North
; Course / Project ID:  CS271

INCLUDE Irvine32.inc
INCLUDE Macros.inc

BUFFER_SIZE EQU <512>
MAP_QTY     EQU <5>

.data
endl        EQU <0dh, 0ah>                          ; End of Line Sequence
gameTitle   BYTE "@'s Adventure", 0
consoleSize     SMALL_RECT <0, 0, 40, 20>
consoleCursor   CONSOLE_CURSOR_INFO <100, 0>        ; Set second Argument to 1 if want to see visible cursor

fileBuffer  BYTE MAP_QTY DUP(BUFFER_SIZE DUP (?))   ; Where the arrays of map file is stored
curMap      BYTE BUFFER_SIZE DUP (?)                ; Current Map array is stored
curMapNum   DWORD 0                                 ; Current Map #
fileName    DWORD "A", 0                            ; File names, start from A~....Z
fileHandle  HANDLE ?

charX       BYTE    1                               ; Size of DL: 1 byte - starting xpos
charY       BYTE    1                               ; Size of DH: 1 byte - starting ypos
char        BYTE    "@", 0                          ; Character
keyX        BYTE    2                               ; Starting key xposition
keyY        BYTE    6                               ; Starting key yposition
keysymbol   BYTE    "k", 0                          ; Key
stairX      BYTE    15                              ; Starting stair xposition
stairY      BYTE    2                               ; Starting stair yposition
stair       BYTE    "S", 0                          ; Stair
endla       BYTE    10                              ; endline character 0a
endld       BYTE    13                              ; endline character 0d
sharp       BYTE    "#"                             ; sharp character
inventory   BYTE    10 DUP(?)                       ; Inventory; arr of chars
spaces      DWORD   ' ',0                           ; double space for inventory formatting
hline 	      BYTE    "----------------", 0	  ; Line to separate inventory
inventtitle     BYTE    "INVENTORY", 0			  ; Inventory title

consoleHandle HANDLE 0
bytesWritten DWORD ?

.code

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
    mov     DL, 0
    mov     DH, 0
    call    Gotoxy

    push    OFFSET fileBuffer       ; Put @fileBuffer to stack as reference 
    push    OFFSET curMap           ; Put @curMap to stack as reference
    push    BUFFER_SIZE             ; Put BUFFER_SIZE to stack as value 
    push    curMapNum               ; Put curMapNum to stack as value
    call    drawMap                 ; Draw Map from array

pushad
push    OFFSET inventory
call    PickUpItem          ; Pick up the key if the user walks over it
popad

pushad
push    OFFSET  inventory
call    UnlockDoor          ; Unlock the door if user has a key in their inventory
popad

;-------------------------------------------------------------------------------------
DrawKey:
;
;   Draw the key on the map
;   Receive:    keyX, keyY
;   Return:     printed key
;------------------------------------------------------------------------------------- 
    mov DL, keyX                ; X-coordinate
    mov DH, keyY                ; Y-coordinate
    call    Gotoxy              ; locate cursor

    INVOKE  WriteConsole,       ; Write character 'k'
        consoleHandle,
        ADDR    keysymbol,
        1,
        ADDR    bytesWritten, 
        0
;------------------------------------------------------------------------------------- 

;-------------------------------------------------------------------------------------
DrawStair:
;
;   Draw the staircase on the map
;   Receive:    stairX, stairY
;   Return:     printed staircase
;------------------------------------------------------------------------------------- 
    mov DL, stairX              ; X-coordinate
    mov DH, stairY              ; Y-coordinate
    call    Gotoxy              ; locate cursor

    INVOKE  WriteConsole,       ; Write character 'S'
        consoleHandle,
        ADDR    stair,
        1,
        ADDR    bytesWritten, 
        0
;------------------------------------------------------------------------------------- 

;-------------------------------------------------------------------------------------
DrawCharacter:
;
;   Draw the character on the map
;   Receive:    charX, charY
;   Return:     printed character
;------------------------------------------------------------------------------------- 
    mov     DL, charX           ; X-Coordinate
    mov     DH, charY           ; Y-Coordinate
    call    Gotoxy              ; locate Cursor
    
    INVOKE WriteConsole,        ; Write character '@'
        consoleHandle,
        ADDR char,
        1,
        ADDR bytesWritten,
        0
;------------------------------------------------------------------------------------- 

;-------------------------------------------------------------------------------------
DrawInv:
;
;   Draw the inventory below the map
;   Receive:    inventory, lengthof inventory
;   Return:     printed inventory
;------------------------------------------------------------------------------------- 
    push    OFFSET inventory    ; push inventory offset into stack
    push    LENGTHOF inventory  ; push count into stack
    call    DrawInventory       ; Draw the inventory
;------------------------------------------------------------------------------------- 

Key:
    push    OFFSET curMap       ; Put @curMap to stack as reference
    push    BUFFER_SIZE         ; Put BUFFER_SIZE to stack as value
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
DrawInventory   PROC
;
;   Draw the user inventory as a horizontal array 
;   Receive:    OFFSET list, LENGTHOF list
;   Return:     none
;------------------------------------------------------------------------------------- 
    pushad
    mov     DL, 0
    mov     DH, 10
    call    Gotoxy
    call    Crlf	
    mov     EDX,    OFFSET  inventtitle 		
    call    WriteString     ; draw inventory title
    call    Crlf
    call 	  Crlf
    popad

    push    ebp
    mov     ebp,    esp         ; preserve ebp
    mov     esi,    [ebp+12]    ; address of inventory in esi; size of each element in the inventory * 3
    mov     ecx,    [ebp+8]     ; count in ecx
    mov     EDX, ESI
    call    WriteString
    pop     ebp
    ret     8
DrawInventory   ENDP
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

        call    checkWall
        cmp     EAX, 1
        jne     KeyInputEnd
        add     charX, 1
        jmp     KeyInputEnd

    UpKeyCheck:
        cmp     dx, VK_UP       ; Check if Up Arrow key is pressed
        jne     RightKeyCheck
        sub     charY, 1        ; Move character one space up

        call    checkWall
        cmp     EAX, 1
        jne     KeyInputEnd
        add     charY, 1
        jmp     KeyInputEnd

    RightKeyCheck:
        cmp     dx, VK_RIGHT    ; Check if Right Arrow key is pressed
        jne     DownKeyCheck
        add     charX, 1        ; Move character one space to the right

        call    checkWall
        cmp     EAX, 1
        jne     KeyInputEnd
        sub     charX, 1
        jmp     KeyInputEnd

    DownKeyCheck:
        cmp     dx, VK_DOWN     ; Check if Down Arrow key is pressed
        jne     EscapeKeyCheck
        add     charY, 1        ; Move character one space down

        call    checkWall
        cmp     EAX, 1
        jne     KeyInputEnd
        sub     charY, 1
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
        ret     8
KeyInput    ENDP
;-------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------
checkWall PROC      
;
;   Check if there is wall at the player's coordinate
;       Return 0 to EAX if there is no wall, 1 if exist
;   Receive:    curMap, BUFFER_SIZE, charX, charY
;   Return:     EAX
;-------------------------------------------------------------------------------------
    push    EBP
    mov     EBP, ESP
    pushad
    mov     EDI, [EBP+16]       ; @curMap


    mov     EAX, 0              ; Reset EAX to 0
    mov     AL, charY           ; Move charY to AL
    mov     ECX, EAX            ; Move EAX to ECX : charY -> ECX
    cmp     ECX, 0              ; If ECX == 0, skips whole part
    je      L15
    mov     AL, 10              ; ASCII code for end of line 0a

L1:
    push    ECX                 ; Save ECX
    mov     ECX, [EBP+12]       ; Buffer Size of ECX
    cld
    repne   scasb               ; Repeat until finding AL
    pop     ECX                 ; Load ECX
    loop    L1

L15:
    mov     EAX, 0              ; Reset EAX
    mov     AL, charX           
    mov     ECX, EAX            ; charX -> ECX
    mov     ESI, EDI            ; @curMap from EDI to ESI
    cmp     ECX, 0              ; If charX == 0, skips whole part
    je      L25
    cmp     ECX, 1              ; If charX == 1, ESI does not decrease
    je      L2
    dec     ESI

L2:
    lodsb                       ; Load BYTE at ESI to EAX, increment ESI by 1.
    loop    L2
    
L25:
    mov     EDI, OFFSET sharp   ; Move @sharp to EDI
    cmpsb                       ; Compare value at ESI and EDI. If ESI has 23
    je      L3
    mov     EDI, OFFSET endla   ; Move @endla to EDI
    cmpsb                       ; Compare value at ESI and EDI. If ESI has 0a
    je      L3
    mov     EDI, OFFSET endld   ; Move @endld to EDI
    cmpsb                       ; Compare value at ESI and EDI. If ESI has 0d
    je      L3

    popad
    mov     EAX, 0              ; The wall or 0a, 0d does not exist at coordinate
    jmp     L4

L3:
    popad
    mov     EAX, 1              ; The wall or 0a, 0d exist at coordinate
L4:
    pop     EBP
    ret     
checkWall ENDP
;-------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------
DrawHorizLine	PROC 
;
;   Print a horizontal line to the terminal
;   Receive:    hline
;   Return:     none
;------------------------------------------------------------------------------------- 
    mov     EDX,    OFFSET  hline 	; load the hline variable
    call    WriteString 		; write the line
    call    Crlf			; write newline
DrawHorizLine 	ENDP
;------------------------------------------------------------------------------------- 


;-------------------------------------------------------------------------------------
PickUpItem  PROC
;
;   Grab an item below the user, and add to the their inventory
;   Receive:    charX, charY, keyX, keyY, inventory
;   Return:     changed keyX, keyY, and inventory
;------------------------------------------------------------------------------------- 
chkX:    
    mov     al, charX
    cmp     al,  keyX               ; if X coordinates match,
    jne     notsame
chkY:
    mov     al, charY
    cmp     al,  keyY               ; and if Y coordinates also match,
    jne     notsame
                                    ; if same x and y coordinates,
    mov     al, keysymbol
    mov     [inventory], al         ; add the key to the player's inventory

notsame:                            ; else do nothing
    ret
PickUpItem  ENDP
;------------------------------------------------------------------------------------- 


;-------------------------------------------------------------------------------------
UnlockDoor  PROC
;
;   Apply a key (if in the inventory) to unlock the door
;   Receive:    charX, charY, stairX, stairY, inventory
;   Return:     changed inventory, changed map
;------------------------------------------------------------------------------------- 
                                        ; if coordinate of the player equals that of the stair,
chkX:    
    mov     al, charX
    cmp     al, stairX                  ; if X-coordinate matches,
    jne     notsame
chkY:
    mov     al, charY
    cmp     al, stairY                  ; and if Y-coordinate matches,
    jne     notsame
                                        ; if same x and y coordinates,
chkKey:                                 ; If the player has the key,
    mov     al, keysymbol
    cmp     al,  [inventory]            ; if the key is in the first inventory position,
    jne     notsame
    ; else, if at correct X and Y, and player has the key,
    mov     [inventory],  "?"           ; remove the key from the player's inventory
    inc     curMapNum                   ; move to the next map

notsame:                                ; else do nothing
    ret

UnlockDoor  ENDP
;-------------------------------------------------------------------------------------

END main