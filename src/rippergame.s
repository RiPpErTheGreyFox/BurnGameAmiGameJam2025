;---------- Includes ----------
              INCDIR        "include"
              INCLUDE       "hw.i"

    SECTION CODE

main:
    bsr         init
mainloop:

    btst        #6,CIAAPRA              ; left mouse button pressed?
    bne         mainloop

    bsr         shutdown
    rts

init:
    lea         CUSTOM,a5
    bsr         take_system
    bsr         savecopperlist
    bsr         setdefaultcopperlist
    rts
    
shutdown:
    bsr         restorecopperlist
    bsr         release_system
    rts

    INCLUDE       "drawingroutines.s"
    INCLUDE       "systemroutines.s"