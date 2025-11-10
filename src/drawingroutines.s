;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

                    ;5432109876543210
DMASET              EQU %1000001111000000     ; enable only copper, bitplane and blitter DMA
NUM_COLORS          EQU 16
N_PLANES            EQU 4
DISPLAY_WIDTH       EQU 320
DISPLAY_HEIGHT      EQU 256
DISPLAY_PLANE_SIZE  EQU DISPLAY_HEIGHT*(DISPLAY_WIDTH/8)
DISPLAY_ROW_SIZE    EQU (DISPLAY_WIDTH/8)
IMAGE_WIDTH         EQU 32
IMAGE_HEIGHT        EQU 32
IMAGE_PLANE_SIZE    EQU IMAGE_HEIGHT*(IMAGE_WIDTH/8)
TILESET_WIDTH       EQU 320
TILESET_HEIGHT      EQU 304
TILESET_ROW_SIZE    EQU (TILESET_WIDTH/8)
TILESET_PLANE_SIZE  EQU (TILESET_HEIGHT*TILESET_ROW_SIZE)
TILESET_COLS        EQU 20
TILEMAP_ROW_SIZE    EQU 268*2
TILE_WIDTH          EQU 16
TILE_HEIGHT         EQU 16

    SECTION CODE
; save the copperlist from the system to a variable to be restored later
savecopperlist:
    move.l      gfx_base,a6
    move.l      $26(a6),old_cop
    jsr         wait_blitter
    jsr         OwnBlitter(a6)          ; takes the blitter exclusive
    rts
        
; set a default copperlist as defined by our game
setdefaultcopperlist:
    lea         CUSTOM,a5
    move.w      #DMASET,DMACON(a5)
    move.l      #copperlist,$dff080     ; insert the address of our copperlist in COP1LC
    move.w      d0,$dff088              ; write any value (the content of d0 in this case) in COP1JMP to place the copper PC at the beginning of our copperlist
    move.w      #0,$dff1fc              ; disable AGA
    move.w      #$c00,$dff106
    move.w      #$11,$10c(a5)
    rts

; restore the original copperlist that was saved from the system
restorecopperlist:
    lea         $dff000,a5
    move.l      old_cop,COP1LC(a5)
    move.w      #0,COPJMP1(a5)
    rts

; load palette into the copperlist
; @params: none
; @clobbers: a0, a1, d7

load_palette:
    lea         palette,a0              ; pointer to palette data in memory
    lea         cop_palette+2,a1        ; pointer to palette data in copperlist
    moveq       #NUM_COLORS-1,d7        ; number of loop iterations
.loop: 
    move.w      (a0)+,(a1)                 ; copy colour value from memory to copperlist
    add.w       #4,a1                   ; point to the next value in the copperlist
    dbra        d7,.loop                ; repeats the loop (NUM_COLOURS-1) times

    rts

; initalises bitplane pointers
; @clobbers: a1, d0, d1

init_bplpointers:
    move.l      #screen,d0               ; address of image in d0
    lea         bplpointers,a1          ; bitplane pointers in a1
    move.l      #(N_PLANES-1),d1        ; number of loop iterations in d1
.loop:
    move.w      d0,6(a1)                ; copy low word of image address into BPLxPTL (low word of BPLxPT)
    swap        d0                      ; swap high and low word of image address
    move.w      d0,2(a1)                ; copy high word of the image addres into BPLxPTH (high word of BPLxPT)
    swap        d0                      ; resets d0 to the initial condition
    add.l       #DISPLAY_PLANE_SIZE,d0      ; point to the next bitplane
    add.l       #8,a1                   ; point to next bplpointer
    dbra        d1,.loop                ; repeats the loop for all planes
    rts 

; waits for the blitter to finish
; @clobbers a5
wait_blitter:
    lea         CUSTOM,a5
.loop:
    btst.b      #6,DMACONR(a5)          ; if bit 6 is 1, the blitter is busy
    bne         .loop                   ; and then wait until it's zero
    rts

; Draw a 16x16 pixel tile using blitter
; @params: d0.w - tile index
; @params: d2.w - x position of the screen where the tile will be drawn
; @params: d3.w - y position of the screen where the tile will be drawn
draw_tile:
    movem.l     d0-a6,-(sp)                 ; copy registers onto the stack

    ; calculate the screen address where to draw the tile
    mulu        #DISPLAY_ROW_SIZE,d3        ; y_offset = y * DISPLAY_ROW_SIZE
    lsr.w       #3,d2                       ; x_offset = x / 8
    ext.l       d2
    lea         screen,a1
    add.l       d3,a1                       ; sums offsets to a1
    add.l       d2,a1

    ; calculates row and column of tile in tileset starting from index
    ext.l       d0                          ; extend d0 to a longword because the destination operand of divu must be long
    divu        #TILESET_COLS,d0
    swap        d0
    move.w      d0,d1                       ; the remainder indicates the tile column
    swap        d0                          ; the quotient indicates the tile row

    ; calculates the x,y coordinates of the tile in the tileset
    lsl.w       #4,d0                       ; y = row * 16
    lsl.w       #4,d1                       ; x = column * 16

    ; calculate the offset to add to a0 to get the address of the source image
    mulu        #TILESET_ROW_SIZE,d0        ; offset_y = y * TILESET_ROW_SIZE
    lsr.w       #3,d1                       ; offset_x = x / 8
    ext.l       d1

    lea         tileset,a0                  ; source image address
    add.l       d0,a0                       ; add y_offset
    add.l       d1,a0                       ; add x_offset

    moveq       #N_PLANES-1,d7

    bsr         wait_blitter
    move.w      #$ffff,BLTAFWM(a5)          ; don't use mask
    move.w      #$ffff,BLTALWM(a5)
    move.w      #$09f0,BLTCON0(a5)          ; enable channels A,D
                                            ; logical function = $f0, D=A
    move.w      #0,BLTCON1(a5)
    move.w      #(TILESET_WIDTH-TILE_WIDTH)/8,BLTAMOD(a5)   ; A channel modulus
    move.w      #(DISPLAY_WIDTH-TILE_WIDTH)/8,BLTDMOD(a5)  ; D channel modulus
.loop:
    bsr         wait_blitter
    move.l      a0,BLTAPT(a5)               ; source address
    move.l      a1,BLTDPT(a5)               ; destination address
    move.w      #64*16+1,BLTSIZE(a5)        ; blitsize: 16 rows for 1 words
    add.l       #TILESET_PLANE_SIZE,a0      ; advances to the next plane
    add.l       #DISPLAY_PLANE_SIZE,a1
    dbra        d7,.loop
    bsr         wait_blitter

    movem.l     (sp)+,d0-a6                ; restore registers values from the stack
    rts

    SECTION bss_data,BSS_C

screen          ds.b (DISPLAY_PLANE_SIZE*N_PLANES)   ; visible screen

    SECTION graphics_data,DATA_C            ; segment loaded in CHIP RAM

tileset         incbin "assets/gfx/rtype_tileset.raw"
palette         incbin "assets/gfx/rtype.pal"

    SECTION copper_segment,DATA_C

copperlist:
    ; copperlist containing copper move instructions and data to fill it
    dc.w DIWSTRT,$2c81                  ; display window start at ($81,$2c)
    dc.w DIWSTOP,$2cc1                  ; display window stop at ($1c1,$12c)
    dc.w DDFSTRT,$38                    ; display data fetch start at $38
    dc.w DDFSTOP,$d0                    ; display data fetch stop at $d0
    dc.w BPLCON1,0
    dc.w BPLCON2,0
    dc.w BPL1MOD,0
    dc.w BPL2MOD,0

    dc.w BPLCON0,$4200                  ; 4 bitplane lowres video mode   
cop_palette:
    dc.w COLOR00,0,COLOR01,0,COLOR02,0,COLOR03,0
    dc.w COLOR04,0,COLOR05,0,COLOR06,0,COLOR07,0
    dc.w COLOR08,0,COLOR09,0,COLOR10,0,COLOR11,0
    dc.w COLOR12,0,COLOR13,0,COLOR14,0,COLOR15,0

bplpointers:
    dc.w BPL1PTH,$0000,BPL1PTL,$0000
    dc.w BPL2PTH,$0000,BPL2PTL,$0000
    dc.w BPL3PTH,$0000,BPL3PTL,$0000
    dc.w BPL4PTH,$0000,BPL4PTL,$0000

    dc.w $ffff,$fffe                    ; END of copperlist
