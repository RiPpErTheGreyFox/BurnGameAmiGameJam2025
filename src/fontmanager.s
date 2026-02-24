;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

;---------- Subroutines -------
    SECTION CODE

; draws a character using a given font
; @params: d1.l - destination bitplane address offset
; @params: d0.b - character ascii code
; the font must be 8x16px, 1 bpp
DrawChar:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    lea         hud_font_gfx,a0                                     ; font address
    lea         dbuffer1,a1
    lea         dbuffer2,a2
    adda.l      d1,a1
    adda.l      d1,a2

    ; since the font starts from '0', subtracts the ascii code of '0'
    ; in order to have an index starting from zero
    sub.b       #48,d0
    ; clears the high byte of d0 as it's unused
    and.w       #$00FF,d0
    ; calculates the address of the character within the font spritesheet
    add.w       d0,a0
    ; copies the character data to the desitnation bitplane
    moveq       #16-1,d2
.loop:
    move.b      (a0),(a1)                                           ; copies a row of 8 px from font to bitplane
    move.b      (a0),(a2)
    ;move.b      #255,(a1)
    add.l       #DISPLAY_ROW_SIZE,a1                                             ; go to the next row of the bitplane
    add.l       #DISPLAY_ROW_SIZE,a2
    add.l       #10,a0                                              ; go to the next row of the font spritesheet
    dbra        d2,.loop

    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; draws a string using a given font
; @params: a2 - address of the string, zero terminated
; @params: d3.w - x coordinates of where to draw the string
; @params: d4.w - y coordinates where to draw the string
DrawString:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    ; calculates the destination address on the bitplane
    move.l      #0,a1                                               ; where to draw
    mulu.w      #DISPLAY_ROW_SIZE,d4                              
    add.l       d4,a1                                               ; adds offset_y to bitplane address
    lsr.w       #3,d3                                               ; offset_x = x/8
    and.l       #$0000FFFF,d3                                       ; clears the high word of d3
    add.l       d3,a1                                               ; adds offset_x to bitplane address
    move.l      a1,d1

    ; for each character of the string
.loop:
    move.b      (a2)+,d0                                            ; current string character
    tst.b       d0                                                  ; if current character is zero
    beq         .return                                             ; returns because the string is finished
    bsr         DrawChar                                            ; else draws the character
    add.l       #1,d1                                               ; moves 8 pixel to the right
    bra         .loop                                               ; repeats the loop

.return:
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; Convert a 16-bit number into a string
; @params: d0.w - 16 bit number
; @params: a0 - address of the output string
NumToString:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    moveq       #4,d2                                               ; number of iterations
    move.l      #10000,d1

.loop:
    and.l       #$0000FFFF,d0                                       ; clears high word of d0 because DIVU destination
                                                                    ; operand is always long
    divu        d1,d0                                               ; d0 = d0 / d1
    add.b       #'0',d0                                             ; the quotient is the digit but must be converted into ascii code
    move.b      d0,(a0)+                                            ; copies the digit to the destination string
    divu        #10,d1                                              ; d1 = d1/10
    swap        d0                                                  ; moves the remainder into the lower word of d0
    dbra        d2,.loop
    move.b      #0,(a0)                                             ; adds a string terminator

    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

    SECTION hud_graphics_data,DATA_C                                ; segment loaded in CHIP RAM
hud_font_gfx:  incbin "assets/gfx/HUDNumberFont.raw"
hud_background_mask: incbin "assets/gfx/HUDNumberFont.mask"