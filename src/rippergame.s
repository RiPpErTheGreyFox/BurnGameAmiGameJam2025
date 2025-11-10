;---------- Includes ----------
              INCDIR        "include"
              INCLUDE       "hw.i"

    SECTION CODE

main:
    bsr         init
    
    move.w      #196,d0                 ; map column to drawing from
    bsr         fill_screen_with_tiles

    
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

    INCLUDE         "controllerroutines.s"
    INCLUDE         "drawingroutines.s"
    INCLUDE         "systemroutines.s"
    INCLUDE         "levelhandler.s"