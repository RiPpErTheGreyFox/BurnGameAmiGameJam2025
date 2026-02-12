;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
              INCLUDE     "globals.i"
              
    SECTION CODE

tilemap     include "assets/gfx/rtype_tilemap.i"

;---------- Subroutines -------

LevelHandlerStart:
    rts

; Draw a column of 12 tiles.
; @params: d0.w - map column
; @params: d2.w - x position (multiple of 16)
DrawTileColumn: 
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
    bsr        DrawTile
         
    add.w      #TILE_HEIGHT,d3                                          ; increment y position
    add.l      #TILEMAP_ROW_SIZE,a0                                     ; move to the next row of the tilemap
    dbra       d7,.loop

    movem.l    (sp)+,d0-a6
    rts

; Initialises the background, copying the initial part of the level map
; @params: d0.w - map column from which to start drawing tiles
InitBackground:
    movem.l    d0-a6,-(sp)

; initializes the part that will be visible in the display window
    lea        bgnd_surface,a1
    moveq      #20-1,d7
    move.w     #16,d2                                                   ; position x
.loop         
    bsr        DrawTileColumn
    add.w      #1,d0                                                    ; increment map column
    add.w      #1,map_ptr
    add.w      #16,d2                                                   ; increase position x
    dbra       d7,.loop

; draws the column to the left of the display window
    add.w      #1,d0                                                    ; map column
    add.w      #1,map_ptr
    move.w     #0,d2                                                    ; x position
    lea        bgnd_surface,a1
    bsr        DrawTileColumn

; draws the column to the right of the display window
    move.w     #DISPLAY_WIDTH+16,d2                                     ; x position
    lea        bgnd_surface,a1
    bsr        DrawTileColumn

    movem.l    (sp)+,d0-a6
    rts    

; fills the screen with tiles
; @params: d0.w - map column from which to start drawing tiles
; @params: a1 - address of draw surface
FillScreenWithTiles:
    movem.l    d0-a6,-(sp)

    moveq      #20-1,d7
    move.w     #0,d2                                                    ; position x
.loop         
    bsr        DrawTileColumn
    add.w      #1,d0                                                    ; increment map column
    add.w      #16,d2                                                   ; increase position x
    dbra       d7,.loop

    movem.l    (sp)+,d0-a6
    rts

; check for collision at point, basic version just returns a lower plane
; doesn't preserve registers
; @params: d0.w - X Position to check
; @params: d1.w - Y position to check
; @params: d4.w - X Velocity
; @params: d5.w - Y Velocity
; @returns: d7 - 1 if true
CollisionCheckAtPoint:
    ; TODO: use a lookup table for collidable tile types
    ; TODO: handle scrolling of the map
    ; for now just return true if position Y is at a certain point
    ; compare Y position if it's above 300, return true
    cmpi       #142,d1
    bgt        .returntrue

.returnfalse:
    move.w     #0,d7
    rts
.returntrue:
    move.w     #1,d7
    rts