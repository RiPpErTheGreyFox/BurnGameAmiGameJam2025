;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
              INCLUDE     "globals.i"

    SECTION CODE
;---------- Subroutines -------

; load palette into the copperlist
; @params: none
; @clobbers: a0, a1, d7

LoadPalette:
    movem.l     d0-a6,-(sp)                 ; copy registers onto the stack
    lea         palette,a0              ; pointer to palette data in memory
    lea         cop_palette+2,a1        ; pointer to palette data in copperlist
    moveq       #NUM_COLORS-1,d7        ; number of loop iterations
.loop: 
    move.w      (a0)+,(a1)                 ; copy colour value from memory to copperlist
    add.w       #4,a1                   ; point to the next value in the copperlist
    dbra        d7,.loop                ; repeats the loop (NUM_COLOURS-1) times

    movem.l     (sp)+,d0-a6                ; restore registers values from the stack
    rts

; initalises bitplane pointers
; @clobbers: a1, d0, d1

InitBPLPointers:
    movem.l    d0-a6,-(sp)                                              ; copy registers into the stack

    move.l     #dbuffer1,d0                                             ; address of image in d0
    lea        bplpointers,a1                                           ; bitplane pointers in a1
    move.l     #(N_PLANES-1),d1                                         ; number of loop iterations in d1
.loop:
    move.w     d0,6(a1)                                                 ; copy low word of image address into BPLxPTL (low word of BPLxPT)
    swap       d0                                                       ; swap high and low word of image address
    move.w     d0,2(a1)                                                 ; copy high word of image address into BPLxPTH (high word of BPLxPT)
    swap       d0                                                       ; resets d0 to the initial condition
    add.l      #DISPLAY_PLANE_SIZE,d0                                   ; point to the next bitplane
    add.l      #8,a1                                                    ; point to next bplpointer
    dbra       d1,.loop                                                 ; repeats the loop for all planes

    movem.l    (sp)+,d0-a6                                              ; restore registers values from the stack
    rts 

; initialises the sprite pointers with the projectile sprites
; @clobbers: a1, d0
InitSpritePointers:
    movem.l    d0-a6,-(sp)                                          ; copy registers into the stack

    lea         sprite_ptrs,a1
    move.l      #projectile1_spr,d0
    move.w      d0,6(a1)                                            ; low word
    swap d0
    move.w      d0,2(a1)                                            ; high word

    add.l       #8,a1                                               ; next sprite pointer
    move.l      #projectile2_spr,d0                              ; next sprite
    move.w      d0,6(a1)                                            ; low word
    swap d0
    move.w      d0,2(a1)                                            ; high word

    add.l       #8,a1                                               ; next sprite pointer
    move.l      #projectile3_spr,d0                              ; next sprite
    move.w      d0,6(a1)                                            ; low word
    swap d0
    move.w      d0,2(a1)                                            ; high word

    add.l       #8,a1                                               ; next sprite pointer
    move.l      #projectile4_spr,d0                              ; next sprite
    move.w      d0,6(a1)                                            ; low word
    swap d0
    move.w      d0,2(a1)                                            ; high word

    add.l       #8,a1                                               ; next sprite pointer
    move.l      #projectile5_spr,d0                              ; next sprite
    move.w      d0,6(a1)                                            ; low word
    swap d0
    move.w      d0,2(a1)                                            ; high word

    add.l       #8,a1                                               ; next sprite pointer
    move.l      #projectile6_spr,d0                              ; next sprite
    move.w      d0,6(a1)                                            ; low word
    swap d0
    move.w      d0,2(a1)                                            ; high word

    add.l       #8,a1                                               ; next sprite pointer
    move.l      #projectile7_spr,d0                              ; next sprite
    move.w      d0,6(a1)                                            ; low word
    swap d0
    move.w      d0,2(a1)                                            ; high word

    add.l       #8,a1                                               ; next sprite pointer
    move.l      #projectile8_spr,d0                              ; next sprite
    move.w      d0,6(a1)                                            ; low word
    swap d0
    move.w      d0,2(a1)                                            ; high word

    ;bset        #7,projectile_spr+76+3                              ; sets sprite 1 attached bit

    movem.l    (sp)+,d0-a6                                          ; restore registers values from the stack
    rts 

; hides the passed in sprite by moving it off screen
; @params: a1 - sprite address
HideSprite:
    movem.l     d0-a6,-(sp)                                         ; copy registers into the stack

    move.w      #0,d0
    move.w      #0,d1
    move.w      #0,d2
    bsr         SetSpritePosition

    movem.l     (sp)+,d0-a6                                         ; restore registers values from the stack
    rts

; sets position of a sprite
; @params: a1 - sprite address
; @params: d0.w - y position (0-255)
; @params: d1.w - x position (0-319)
; @params: d2.w - sprite height
SetSpritePosition:
    movem.l     d0-a6,-(sp)                                         ; copy registers into the stack

    add.w       #$2c,d0                                             ; adds offset of screen beginning
    move.b      d0,(a1)                                             ; copies y value into sprite VSTART byte
    btst.l      #8,d0                                               ; bit 8 of y position is set?
    beq         .DontSetBit8 
    bset.b      #2,3(a1)                                            ; sets bit 8 of VSTART
    bra         .VSTOP
.DontSetBit8:
    bclr.b      #2,3(a1)                                            ; clears bit 8 of VSTART
.VSTOP:
    add.w       d2,d0                                               ; adds height to y position to get VSTOP
    move.b      d0,2(a1)                                            ; copies the value into sprite VSTOP byte
    btst.l      #8,d0                                               ; bit 8 of VSTOP is set?
    beq         .DontSetVSTOPBit8
    bset.b      #1,3(a1)                                            ; sets bit 8 of VSTOP
    bra         .SetHPos
.DontSetVSTOPBit8:
    bclr.b      #1,3(a1)                                            ; clears bit 8 of VSTOP
.SetHPos:
    add.w       #128,d1                                             ; adds horizontal offset to x
    btst.l      #0,d1
    beq         .HSTARTLSBZero
    bset.b      #0,3(a1)                                            ; sets bit 0 of HSTART
    bra         .SetHSTART
.HSTARTLSBZero:
    bclr.b      #0,3(a1)                                            ; clears bit 0 of HSTART
.SetHSTART:
    lsr.w       #1,d1                                               ; shifts 1 position to right to get the 8
                                                                    ; most significant bits of x position
    move.b      d1,1(a1)                                            ; sets HSTART value

    movem.l     (sp)+,d0-a6                                         ; restore registers values from the stack
    rts

; waits for the blitter to finish
; @clobbers a5
WaitBlitter:
.loop:
    btst.b      #6,DMACONR(a5)          ; if bit 6 is 1, the blitter is busy
    bne         .loop                   ; and then wait until it's zero
    rts

; Draws a bob using the blitter
; @params: a0 - image address
; @params: a1 - mask address
; @params: a2 - destination video buffer address
; @params: d0.w - x position of the bob in pixels
; @params: d1.w - y position of the bob in pixels
; @params: d2.w - bob width in pixels
; @params: d3.w - bob height in pixels
; @params: d4.w - spritesheet column of the bob
; @params: d5.w - spritesheet row of the bob
; @params: a3.w - spritesheet width
; @params: a4.w - spritesheet height
DrawBOb:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    ; calculate the destination address (D channel)
    mulu.w      #DISPLAY_ROW_SIZE,d1                                ; offset_y = y * DISPLAY_ROW_SIZE
    add.l       d1,a2                                               ; adds offset_y to destination address
    move.w      d0,d6                                               ; copies x
    lsr.w       #3,d0                                               ; offset_x = x/8
    and.w       #$fffe,d0                                           ; makes offset_x even
    add.w       d0,a2                                               ; adds offset_x to destination address

    ; calculate source address (A and B Channel)
    move.w      d2,d1                                               ; makes a copy of bob width in d1 
    lsr.w       #3,d1                                               ; bob width in bytes (bob_width/8)
    mulu        d1,d4                                               ; offset_x = column * (bob_width/8)
    add.w       d4,a0                                               ; adds offset_x to the base address of the bob's image
    add.w       d4,a1                                               ; and bob's mask
    mulu        d3,d5                                               ; bob_height * row
    move.w      a3,d1                                               ; copies spritesheet width in d1
    asr.w       #3,d1                                               ; spritesheet_row_size = spritesheet_width / 8
    mulu        d1,d5                                               ; offset_y = row * bob_height * spritesheet_row_size
    add.w       d5,a0                                               ; adds offset_y to the base address of bob's image
    add.w       d5,a1                                               ; and bob's mask

    ; get the modulus of channels A and B
    move.w      a3,d1                                               ; copies spritesheet_width in d1
    sub.w       d2,d1                                               ; spritesheet_width - bob_width
    sub.w       #16,d1                                              ; spritesheet_width - bob_width -16
    asr.w       #3,d1                                               ; (spritesheet_width - bob_width -16)/8

    ; now the C and D modulus
    ; CD's modulus
    lsr         #3,d2                                               ; bob_width / 8
    add.w       #2,d2                                               ; adds 2 to the sprite width in bytes, due to the shift
    move.w      #DISPLAY_ROW_SIZE,d4                                ; screen width in bytes
    sub.w       d2,d4                                               ; modulus (d4) = screen_width - bob_width

    ; calculate the shift value for Chan A,B (d6) and value of BLTCON0 (d5)
    and.w       #$000f,d6                                           ; selects the first 4 bits of x
    lsl.w       #8,d6                                               ; moves the shift value to the upper nibble
    lsl.w       #4,d6                                               ; so as to thave the value to insert in BLTCON1
    move.w      d6,d5                                               ; copy to calculate the value to insert in BLTCON0
    or.w        #$0fca,d5                                           ; value to insert in BLTCON0
                                                                    ; logic function LF = $ca

    ; get the blit size (d3)
    lsl.w       #6,d3                                               ; bob_height << 6
    lsr.w       #1,d2                                               ; bob_width/2 (in word)
    or          d2,d3                                               ; combines the dimensions into the value to be inserted into BLTSIZE

    ; calculate the size of the BOB spritesheet bitplane
    move.w      a3,d2                                               ; copies spritesheet_width in d2
    lsr.w       #3,d2                                               ; spritesheet_width/8
    and.w       #$fffe,d2                                           ; makes even
    move.w      a4,d0                                               ; spritesheet_height
    mulu        d0,d2                                               ; multiplies by the height

    ; inits the registers that remain constant
    bsr         WaitBlitter
    move.w      #$ffff,BLTAFWM(a5)                                  ; first word of channel A: no mask
    move.w      #$0000,BLTALWM(a5)                                  ; last word of channel A: reset all bits
    move.w      d6,BLTCON1(a5)                                      ; shift value for channel A
    move.w      d5,BLTCON0(a5)                                      ; activates all 4 channels, logic_function=$CA,shift
    move.w      d1,BLTAMOD(a5)                                      ; modules for channels A,B
    move.w      d1,BLTBMOD(a5)
    move.w      d4,BLTCMOD(a5)                                      ; modules for channels C,D
    move.w      d4,BLTDMOD(a5)
    moveq       #N_PLANES-1,d7                                      ; number of cycle repitions

    ; copy cycle for each bitplane
.plane_loop:
    bsr         WaitBlitter
    move.l      a1,BLTAPT(a5)                                       ; Channel A: bob's mask
    move.l      a0,BLTBPT(a5)                                       ; Channel B: bob's image
    move.l      a2,BLTCPT(a5)                                       ; Channel C: draw buffer
    move.l      a2,BLTDPT(a5)                                       ; Channel D: draw buffer
    move.w      d3,BLTSIZE(a5)                                      ; blit size and starts blit

    add.l       d2,a0                                               ; points to the next bitplane
    add.l       #DISPLAY_PLANE_SIZE,a2
    dbra        d7,.plane_loop                                      ; repeats the cycle for each bitplane

    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; Draw a 16x16 pixel tile using blitter
; @params: d0.w - tile index
; @params: d2.w - x position of the screen where the tile will be drawn
; @params: d3.w - y position of the screen where the tile will be drawn
; @params: a1 - address of draw surface
DrawTile:
    movem.l    d0-a6,-(sp)                                              ; copy registers into the stack

; calculates the destination address where to draw the tile
    mulu       #BGND_ROW_SIZE,d3                                        ; y_offset = y * BGND_ROW_SIZE
    lsr.w      #3,d2                                                    ; x_offset = x / 8
    ext.l      d2
    add.l      d3,a1                                                    ; sums offsets to a1
    add.l      d2,a1

; calculates row and column of tile in tileset starting from index
    ext.l      d0                                                       ; extend d0 to a longword because the destination operand if divu must be long
    divu       #TILESET_COLS,d0                              
    swap       d0
    move.w     d0,d1                                                    ; the rest indicates the tile column
    swap       d0                                                       ; the quotient indicates the tile row

; calculates the x,y coordinates of the tile in the tileset
    lsl.w      #4,d0                                                    ; y = row * 16
    lsl.w      #4,d1                                                    ; x = column * 16
         
; calculates the offset to add to a0 to get the address of the source image
    mulu       #TILESET_ROW_SIZE,d0                                     ; offset_y = y * TILESET_ROW_SIZE
    lsr.w      #3,d1                                                    ; offset_x = x / 8
    ext.l      d1

    lea        tileset,a0                                               ; source image address
    add.l      d0,a0                                                    ; add y_offset
    add.l      d1,a0                                                    ; add x_offset

    moveq      #N_PLANES-1,d7
    
    bsr        WaitBlitter
    move.w     #$ffff,BLTAFWM(a5)                                       ; don't use mask
    move.w     #$ffff,BLTALWM(a5)
    move.w     #$09f0,BLTCON0(a5)                                       ; enable channels A,D
                                                                           ; logical function = $f0, D = A
    move.w     #0,BLTCON1(a5)
    move.w     #(TILESET_WIDTH-TILE_WIDTH)/8,BLTAMOD(a5)                ; A channel modulus
    move.w     #(BGND_WIDTH-TILE_WIDTH)/8,BLTDMOD(a5)                   ; D channel modulus
.loop:
    bsr        WaitBlitter
    move.l     a0,BLTAPT(a5)                                            ; source address
    move.l     a1,BLTDPT(a5)                                            ; destination address
    move.w     #64*16+1,BLTSIZE(a5)                                     ; blit size: 16 rows for 1 word
    add.l      #TILESET_PLANE_SIZE,a0                                   ; advances to the next plane
    ;add.l      #DISPLAY_PLANE_SIZE,a1
    add.l      #BGND_PLANE_SIZE,a1
    dbra       d7,.loop
    ;bsr        WaitBlitter

    movem.l    (sp)+,d0-a6                                              ; restore registers values from the stack
    rts

; draw the background, copying it from background_surface via Blitter.
; @params: d0.w - x position of the part of background
; @params: a1 - buffer where to draw
DrawBackground:
    movem.l    d0-a6,-(sp)

    moveq      #N_PLANES-1,d7
    lea        bgnd_surface,a0
    move.w     d0,d2
    asr.w      #3,d0                                                    ; offset_x = x/8
    and.w      #$fffe,d0                                                ; rounds to even addresses
    ext.l      d0
    add.l      d0,a0                                                    ; address of image to copy
    and.w      #$000f,d2                                                ; selects the first 4 bits, which correspond to the shift
    move.w     #$f,d3
    sub.w      d2,d3
    lsl.w      #8,d3                                                    ; moves the 4 shift bits to the position they occupy in BLTCON0
    lsl.w      #4,d3
    or.w       #$09f0,d3                                                ; inserts the 4 bits into the value to be assigned to BLTCON0
.planeloop:
    bsr        WaitBlitter
    move.l     a0,BLTAPT(a5)                                            ; channel A points to background surface
    move.l     a1,BLTDPT(a5)                                            ; channel D points to draw buffer
    move.w     #$ffff,BLTAFWM(a5)                                       ; no first word mask
    move.w     #$0000,BLTALWM(a5)                                       ; masks last word
    move.w     d3,BLTCON0(a5)                                            
    move.w     #0,BLTCON1(a5)
    move.w     #(BGND_WIDTH-VIEWPORT_WIDTH-16)/8,BLTAMOD(a5) 
    move.w     #(DISPLAY_WIDTH-VIEWPORT_WIDTH-16)/8,BLTDMOD(a5)
    move.w     #VIEWPORT_HEIGHT<<6+(VIEWPORT_WIDTH/16)+1,BLTSIZE(a5)
    move.l     a0,d0
    add.l      #BGND_PLANE_SIZE,d0                                      ; points a0 to the next plane
    move.l     d0,a0
    move.l     a1,d0
    add.l      #DISPLAY_PLANE_SIZE,d0                                   ; points a1 to the next plane
    move.l     d0,a1
    dbra       d7,.planeloop

    movem.l    (sp)+,d0-a6
    rts

; waits for the drawing beam to reach a given line
; @params: d2.l - line
WaitVLine:
    movem.l     d0-a6,-(sp)                 ; copy registers onto the stack

    lsl.l       #8,d2
    move.l      #$1ff00,d1
.wait:
    move.l      VPOSR(a5),d0
    and.l       d1,d0
    cmp.l       d2,d0
    bne.s       .wait

    movem.l     (sp)+,d0-a6                                         ; restore registers onto the stack
    rts

; waits for the vertical blank
WaitVBlank:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    move.l      #304,d2
    bsr         WaitVLine
    movem.l     (sp)+,d0-a6                                         ; restore registers onto the stack
    rts

; draws and scrolls the background to the right if either of the players are past the scroll threshold
UpdateBackground:
    movem.l     d0-a6,-(sp)

    move.w      bgnd_x,d0                                            ; x position of the part of background to draw
    move.l      draw_buffer,a1                                       ; buffer where to draw                                                  
    bsr         DrawBackground
    ; drawing the background before the scroll check makes it a frame behind

.scroll_check:
    ; first check if scrolling allowed flag is set
    cmpi        #1,screen_scroll_allowed
    bne         .return
    ; check if either player is near the edge, if so scroll screen
    lea         pl_instance1,a6                                     ; grab each player instance and store their data
    cmpi.w      #SCROLL_THRESHOLD_X_RIGHT,actor.x(a6)               ; compared them to the screen scroll threshold
    bge         .scroll_screen                                      ; if past the threshold, then branch to scroll
    lea         pl_instance2,a6
    cmpi.w      #SCROLL_THRESHOLD_X_RIGHT,actor.x(a6)
    bge         .scroll_screen
    bra         .return                                ; otherwise skip scrolling
.scroll_screen:
    ; call the screen_scrolled functions on all actors to make sure they shift correctly, just report how the "camera" moved
    move.w      #SCROLL_SPEED,d0
    move.w      0,d1
    bsr         PlayerScreenScrolled
    bsr         EnemyScreenScrolled
.end_of_scroll_check:

    move.w      bgnd_x,d0                                            ; x position of the part of background to draw
    ext.l       d0                                                   ; every 16 pixels draws a new column
    divu        #16,d0
    swap        d0
    tst.w       d0                                                   ; remainder of bgnd_x/16 is zero?
    beq         .draw_new_column
    bra         .check_bgnd_end
.draw_new_column:
    add.w       #SCROLL_SPEED*16,camera_x
    add.w       #1,map_ptr
    cmp.w       #268,map_ptr                                         ; end of map?
    bge         .return

    move.w      map_ptr,d0                                           ; map column
    move.w      bgnd_x,d2                                            ; x position = bgnd_x - 16
    sub.w       #16,d2
    lea         bgnd_surface,a1
    bsr         DrawTileColumn                                     ; draws the column to the left of the viewport

    move.w      bgnd_x,d2                                            ; x position = bgnd_x + VIEWPORT_WIDTH
    add.w       #VIEWPORT_WIDTH,d2 
    lea         bgnd_surface,a1
    bsr         DrawTileColumn                                     ; draws the column to the right of the viewport
.check_bgnd_end:
    cmp.w       #16+VIEWPORT_WIDTH,bgnd_x                            ; end of background surface?
    ble         .incr_x
    move.w      #SCROLL_SPEED,bgnd_x                                 ; resets x position of the part of background to draw
    bra         .return
.incr_x         
    add.w       #SCROLL_SPEED,bgnd_x                                 ; increases x position of the part of background to draw

.return 
    movem.l     (sp)+,d0-a6
    rts

; swaps video buffers, causing draw_buffer to be displayed
SwapBuffers:
    movem.l    d0-a6,-(sp)                                              ; copy registers into the stack

    move.l     draw_buffer,d0                                           ; swaps the values ​​of draw_buffer and view_buffer
    move.l     view_buffer,draw_buffer
    move.l     d0,view_buffer
    lea        bplpointers,a1                                           ; sets the bitplane pointers to the view_buffer 
    moveq      #N_PLANES-1,d1                                            
.loop:
    move.w     d0,6(a1)                                                 ; copies low word
    swap       d0                                                       ; swaps low and high word of d0
    move.w     d0,2(a1)                                                 ; copies high word
    swap       d0                                                       ; resets d0 to the initial condition
    add.l      #DISPLAY_PLANE_SIZE,d0                                   ; points to the next bitplane
    add.l      #8,a1                                                    ; points to next bplpointer
    dbra       d1,.loop                                                 ; repeats the loop for all planes

    movem.l    (sp)+,d0-a6                                              ; restore registers values from the stack
    rts

    SECTION bss_data,BSS_C

screen          ds.b (DISPLAY_PLANE_SIZE*N_PLANES)   ; visible screen
dbuffer1        ds.b (DISPLAY_PLANE_SIZE*N_PLANES)                            ; display buffers used for double buffering
dbuffer2        ds.b (DISPLAY_PLANE_SIZE*N_PLANES) 

bgnd_surface  ds.b       (BGND_PLANE_SIZE*N_PLANES)                               ; invisible surface used for scrolling background


    SECTION graphics_data,DATA_C            ; segment loaded in CHIP RAM

tileset         incbin "assets/gfx/DemoLevel1_tileset.raw"
palette         incbin "assets/gfx/testsprite.pal"

PLAYERGFX:
player_gfx      incbin "assets/gfx/testsprite.raw"                      ; ship spritesheet 96x96, 3cols x 3rows, frame size: 32x32
player_mask     incbin "assets/gfx/testsprite.mask"
PLAYERGFX_LEN=*-PLAYERGFX

player_gfx_flip incbin "assets/gfx/testsprite_flipped.raw"
player_mask_flip incbin "assets/gfx/testsprite_flipped.mask"

ENEMYGFX:
enemy_gfx       incbin "assets/gfx/enemytestsprite.raw"
enemy_mask      incbin "assets/gfx/enemytestsprite.mask"
ENEMYGFX_LEN=*-ENEMYGFX

enemy_gfx_flip  incbin "assets/gfx/enemytestsprite_flipped.raw"
enemy_mask_flip incbin "assets/gfx/enemytestsprite_flipped.mask"

ENEMY2GFX:
enemy2_gfx       incbin "assets/gfx/enemy2testsprite.raw"
enemy2_mask      incbin "assets/gfx/enemytestsprite.mask"
ENEMY2GFX_LEN=*-ENEMYGFX

enemy2_gfx_flip  incbin "assets/gfx/enemy2testsprite_flipped.raw"
enemy2_mask_flip incbin "assets/gfx/enemytestsprite_flipped.mask"

    SECTION sprite_data,DATA_C              ; segment loaded into CHIP MEM

projectile1_spr incbin "assets/gfx/sprites/projectiletestsprite.raw"
projectile2_spr incbin "assets/gfx/sprites/projectiletestsprite.raw"
projectile3_spr incbin "assets/gfx/sprites/projectiletestsprite.raw"
projectile4_spr incbin "assets/gfx/sprites/projectiletestsprite.raw"
projectile5_spr incbin "assets/gfx/sprites/projectiletestsprite.raw"
projectile6_spr incbin "assets/gfx/sprites/projectiletestsprite.raw"
projectile7_spr incbin "assets/gfx/sprites/projectiletestsprite.raw"
projectile8_spr incbin "assets/gfx/sprites/projectiletestsprite.raw"

    SECTION copper_segment,DATA_C

copperlist:
; Let's start the display window 16 pixels after the default value, to cover the noise caused by shift during scrolling
    dc.w       DIWSTRT,$2c91                                            ; display window start at ($91,$2c)
    dc.w       DIWSTOP,$2cc1                                            ; display window stop at ($1c1,$12c)
    dc.w       DDFSTRT,$38                                              ; display data fetch start at $38
    dc.w       DDFSTOP,$d0                                              ; display data fetch stop at $d0
    dc.w       BPLCON1,0                                          
    dc.w       BPLCON2,%100100                                          ; sets sprites priority over playfield
    dc.w       BPL1MOD,0                                             
    dc.w       BPL2MOD,0                                             

    dc.w       BPLCON0,$4200                                            ; 4 bitplane lowres video mode
 
    ; sprite-bitplane collisions
    ; bit 12: enable sprite 1
    ; bit 6-9: enable bitplanes 1-4
    ; bit 0-5: colour index for collisions with playfield
    ;                  %5432109876543210
    dc.w        CLXCON,%0001001111001000

cop_palette:
    dc.w       COLOR00,0,COLOR01,0,COLOR02,0,COLOR03,0
    dc.w       COLOR04,0,COLOR05,0,COLOR06,0,COLOR07,0
    dc.w       COLOR08,0,COLOR09,0,COLOR10,0,COLOR11,0
    dc.w       COLOR12,0,COLOR13,0,COLOR14,0,COLOR15,0

sprite_palette  incbin "assets/gfx/sprites/projectiletestsprite.pal"
         
bplpointers:
    dc.w       BPL1PTH,$0000,BPL1PTL,$0000
    dc.w       BPL2PTH,$0000,BPL2PTL,$0000
    dc.w       BPL3PTH,$0000,BPL3PTL,$0000
    dc.w       BPL4PTH,$0000,BPL4PTL,$0000

sprite_ptrs:
    dc.w       SPR0PT,0,SPR0PT+2,0
    dc.w       SPR1PT,0,SPR1PT+2,0
    dc.w       SPR2PT,0,SPR2PT+2,0
    dc.w       SPR3PT,0,SPR3PT+2,0
    dc.w       SPR4PT,0,SPR4PT+2,0
    dc.w       SPR5PT,0,SPR5PT+2,0
    dc.w       SPR6PT,0,SPR6PT+2,0
    dc.w       SPR7PT,0,SPR7PT+2,0

    dc.w       $ffff,$fffe                                              ; end of copperlist
