;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
              INCLUDE     "globals.i"
              
    SECTION CODE

tilemap     include "assets/gfx/rtype_tilemap.i"

;---------- Subroutines -------

levelhandlerstart:
    rts

; Draw a column of 12 tiles.
; @params: d0.w - map column
; @params: d2.w - x position (multiple of 16)
draw_tile_column: 
    movem.l    d0-a6,-(sp)
        
; calculates the tilemap address from which to read the tile index
    lea        tilemap,a0
    lsl.w      #1,d0                                                    ; offset_x = map_column * 2
    ext.l      d0
    add.l      d0,a0
    
    moveq      #12-1,d7
    move.w     #0,d3                                                    ; y position
.loop:
    move.w     (a0),d0                                                  ; tile index
    bsr        draw_tile
         
    add.w      #TILE_HEIGHT,d3                                          ; increment y position
    add.l      #TILEMAP_ROW_SIZE,a0                                     ; move to the next row of the tilemap
    dbra       d7,.loop

    movem.l    (sp)+,d0-a6
    rts

; Initialises the background, copying the initial part of the level map
; @params: d0.w - map column from which to start drawing tiles
init_background:
    movem.l    d0-a6,-(sp)

; initializes the part that will be visible in the display window
    lea        bgnd_surface,a1
    moveq      #20-1,d7
    move.w     #16,d2                                                   ; position x
.loop         
    bsr        draw_tile_column
    add.w      #1,d0                                                    ; increment map column
    add.w      #1,map_ptr
    add.w      #16,d2                                                   ; increase position x
    dbra       d7,.loop

; draws the column to the left of the display window
    add.w      #1,d0                                                    ; map column
    add.w      #1,map_ptr
    move.w     #0,d2                                                    ; x position
    lea        bgnd_surface,a1
    bsr        draw_tile_column

; draws the column to the right of the display window
    move.w     #DISPLAY_WIDTH+16,d2                                     ; x position
    lea        bgnd_surface,a1
    bsr        draw_tile_column

    movem.l    (sp)+,d0-a6
    rts    

; fills the screen with tiles
; @params: d0.w - map column from which to start drawing tiles
; @params: a1 - address of draw surface
fill_screen_with_tiles:
    movem.l    d0-a6,-(sp)

    moveq      #20-1,d7
    move.w     #0,d2                                                    ; position x
.loop         bsr        draw_tile_column
    add.w      #1,d0                                                    ; increment map column
    add.w      #16,d2                                                   ; increase position x
    dbra       d7,.loop

    movem.l    (sp)+,d0-a6
    rts