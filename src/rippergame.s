;---------- Includes ----------
              INCDIR        "include"
              INCLUDE       "hw.i"

    SECTION CODE

main:
    bsr         init
    
    move.w      camera_x,d0
    lsr.w       #4,d0
    move.w      d0,map_ptr
    bsr         init_background
    move.w      #16,bgnd_x

    
mainloop:
    bsr         wait_vblank
    bsr         swap_buffers
    bsr         scroll_background
    bsr         isConfirmPressed        ; is confirm pressed?
    btst        #0,d0
    beq         mainloop

    bsr         shutdown
    rts

init:
    bsr         take_system
    bsr         load_palette
    bsr         init_bplpointers
    rts
    
shutdown:
    bsr         release_system
    rts

    INCLUDE         "controllerroutines.s"
    INCLUDE         "drawingroutines.s"
    INCLUDE         "systemroutines.s"
    INCLUDE         "levelhandler.s"