;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

tilemap     include "assets/gfx/rtype_tilemap.i"

;---------- Subroutines -------
    SECTION CODE

levelhandlerstart:
    rts

; Draw a column of 12 tiles.
; @params: d0.w - map column
; @params: d2.w - x position (multiple of 16)
draw_tile_column:
    movem.l     d0-a6,-(sp)                 ; save registers onto the stack

    ; calculates the tilemap address from which to read the tile index
    lea         tilemap,a0
    lsl.w       #1,d0                       ; offset_x = map_column * 2
    ext.l       d0                          ; extend to a long for adding
    add.l       d0,a0

    moveq       #12-1,d7
    move.w      #0,d3                       ; y position
.loop:
    move.w      (a0),d0                     ; tile index
    bsr         draw_tile
    add.w       #TILE_HEIGHT,d3             ; increment y position
    add.l       #TILEMAP_ROW_SIZE,a0        ; move to the next row of the tilemap
    dbra        d7,.loop

    movem.l     (sp)+,d0-a6                 ; restore registers onto the stack
    rts

; Fills the screen with tiles.
;
; @params: d0.w - map column from which to start drawing tiles
fill_screen_with_tiles:
    movem.l     d0-a6,-(sp)

    moveq       #20-1,d7
    move.w      #0,d2                       ; position x
.loop: 
    bsr draw_tile_column
    add.w       #1,d0                       ; increment map column
    add.w       #16,d2                      ; increase position x
    dbra        d7,.loop

    movem.l     (sp)+,d0-a6
    rts