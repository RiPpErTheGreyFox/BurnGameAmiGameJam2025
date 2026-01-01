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

    ; test rendering of bob
    lea         ship_gfx,a0             ; ship's image address
    lea         ship_mask,a1            ; ship's mask address
    move.l      draw_buffer,a2          ; destination video buffer address
    move.w      #16,d0                  ; x position of the ship in pixels
    move.w      #81,d1                  ; y position of the ship in pixels
    move.w      #32,d2                  ; ship width in pixels
    move.w      #30,d3                  ; ship height in pixels
    move.w      #1,d4                   ; spritesheet column of ship
    move.w      #0,d5                   ; spritesheet row of ship
    move.w      #96,a3                  ; spritesheet width
    move.w      #30,a4                  ; spritesheet height
    bsr         draw_bob

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