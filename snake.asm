push 0xB800        ; comments sorce chatgpt Push the video memory segment address
pop es             ; Pop the address into ES segment register

start:             ; Start of the program
    mov al, 0x3    ; Set the video mode to text mode 80x25
    int 0x10       ; Call interrupt 0x10 (BIOS video services)

    mov di, 0x7D0  ; Set DI to the starting position of the snake's head
    mov bp, 0x4    ; Set BP to the initial length of the snake
    call print_food ; Call the subroutine to print the food

.input:            ; Main input loop
    in al, 0x60    ; Read the scan code from the keyboard
    mov bx, 0xA0   ; Set BX to a default value for left/right movement
    test al, 0x1   ; Check if the scan code is a key release
    jz .up_down    ; Jump to up/down movement if not a key release
    mov bl, 0x4    ; Set BX to a value for left movement

.up_down:          ; Up/down movement handling
    and al, 0x7F   ; Clear the high bit of the scan code
    cmp al, 0x4D   ; Compare with the right arrow scan code
    jl .minus      ; Jump to minus label if less than right arrow
    neg bx         ; Negate BX to change direction to right

.minus:            ; Minus label for subtracting BX from DI
    sub di, bx     ; Subtract BX from DI to update the snake's position
    cmp di, 0xF9C  ; Compare DI with the screen's bottom right position
    ja start       ; Jump to start label if DI exceeds the screen boundary
    sar bx, 0x1    ; Shift BX right by 1 to divide it by 2
    lea ax, [di+bx+0x2]  ; Calculate the position for comparison
    mov cl, 0xA0   ; Set CL to 0xA0 (160)
    div cl         ; Divide AX by CL to get the row and column
    test ah, ah    ; Test if the remainder (AH) is zero
    jz start       ; Jump to start label if remainder is zero (snake hits itself)

    mov ax, 0x9    ; Set AL to 0x9 (color attribute for snake body)
    scasb          ; Compare the byte at ES:DI with AL (snake body)
    je start       ; Jump to start label if equal (snake hits itself)

    dec di         ; Decrement DI to point to the empty space behind the snake
    cmp BYTE [es:di], 0x7  ; Compare the byte at ES:DI with 0x7 (food)
    sete ah        ; Set AH to 1 if equal (snake eats the food)
    stosb          ; Store AL (snake body) at ES:DI
    dec di         ; Decrement DI to point to the empty space behind the snake

    mov bx, bp     ; Move BP (snake length) to BX for the loop
.next_byte:        ; Loop to move the snake's body
    mov al, [bx]   ; Move the byte at BX to AL (snake body)
    mov [bx+0x2], al  ; Move AL to [BX+0x2] (next body position)
    dec bx         ; Decrement BX for the next iteration
    jns .next_byte ; Jump to next_byte label if not signed (BX >= 0)

    mov [bx+0x1], di  ; Move DI (snake head position) to [BX+0x1] (first body position)
    test ah, ah    ; Test if AH is zero (snake didn't eat the food)
    jnz .food      ; Jump to food label if not zero

    mov si, [bp]   ; Move [BP] (old tail position) to SI
    mov [es:si], BYTE 0x20  ; Move 0x20 (space character) to [ES:SI] (clear the tail position)
    jmp SHORT .input  ; Jump back to the input loop

.food:             ; Food handling
    inc bp         ; Increment BP (snake length) for the new body
    inc bp
    call print_food  ; Call the subroutine to print the new food
    jmp SHORT .input  ; Jump back to the input loop

print_food:        ; Subroutine to print the food
    pusha           ; Push all the registers onto the stack

.rand:             ; Random position generation for the food
    add di, dx      ; Add DX to DI for randomization
    div di          ; Divide DX:AX by DI
    and dx, 0xFFC   ; Mask DX with 0xFFC to limit the position within the screen
    cmp dx, 0xF9C   ; Compare DX with the screen's bottom right position
    jg .rand        ; Jump to rand label if DX exceeds the screen boundary

    mov di, dx      ; Move DX to DI (food position)
    mov al, 0x9     ; Set AL to 0x9 (color attribute for food)
    scasb           ; Compare the byte at ES:DI with AL (food)
    je .rand        ; Jump to rand label if equal (food overlaps with snake body)
    dec di          ; Decrement DI to the correct position
    mov al, 0x7     ; Set AL to 0x7 (color attribute for food)
    stosb           ; Store AL (food) at ES:DI

    popa            ; Pop all the registers from the stack
    ret             ; Return from the subroutine
