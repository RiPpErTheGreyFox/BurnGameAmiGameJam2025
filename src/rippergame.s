;---------- Includes ----------
              INCDIR        "include"
              INCLUDE       "hw.i"

    SECTION CODE

main:
    bsr         init
    move.w      #(320-32)/2,d0          ; x position
    move.w      #(256-32)/2,d1          ; y position
    mulu        #DISPLAY_ROW_SIZE,d1    ; y_offset = y * DISPLAY_ROW_SIZE
    asr.w       #3,d0                   ; x_offset = x/8
    add.w       d1,d0                   ; sum the offsets
    ext.l       d0
    lea         screen,a1
    add.l       d0,a1                   ; sum the offset to a1
    bsr         draw_tile

    
mainloop:
    bsr         isConfirmPressed        ; is confirm pressed?
    btst        #0,d0
    beq         mainloop

    bsr         shutdown
    rts

init:
    lea         CUSTOM,a5
    bsr         take_system
    bsr         savecopperlist
    bsr         setdefaultcopperlist
    bsr         load_palette
    bsr         init_bplpointers
    rts
    
shutdown:
    bsr         restorecopperlist
    bsr         release_system
    rts

    INCLUDE       "controllerroutines.s"
    INCLUDE       "drawingroutines.s"
    INCLUDE       "systemroutines.s"