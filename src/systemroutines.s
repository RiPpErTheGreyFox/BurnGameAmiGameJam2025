;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"

    SECTION CODE

; takes full control of the system, saving it's state to be restored on program exit

take_system:
    move.l     $4,a6
    jsr        Disable(a6)                                          ; stop multitasking
    lea        gfx_name,a1                                               
    jsr        OpenLibrary(a6)                                   ; open graphics.library
    move.l     d0,gfx_base                                              ; save base address of graphics.library
    move.l     d0,a6
    move.l     $26(a6),old_cop                                      ; save system copperlist address
    jsr        OwnBlitter(a6)                                       ; takes the Blitter exclusive
    lea        CUSTOM,a5
    
    move.w     #DMASET,DMACON(a5)                                       ; set dma channels

    move.l     #copperlist,COP1LC(a5)                                   ; set our copperlist address into Copper
    move.w     d0,COPJMP1(a5)                                           ; reset Copper PC to the beginning of our copperlist
    move.w     #0,$dff1fc                                               ; disable AGA
    move.w     #$c00,$dff106                                             
    move.w     #$11,$10c(a5)

    rts

; releases full control of the system, restarting EXEC after resetting the state

release_system:

    lea        CUSTOM,a5
    move.l     old_cop,COP1LC(a5)                                   ; set the system copperlist
    move.w     d0,COPJMP1(a5)                                           ; start the system copperlist
    
    move.l     gfx_base,a6
    jsr        DisOwnBlitter(a6)                                    ; release Blitter ownership
    move.l     $4,a6
    jsr        Enable(a6)                                           ; enable multitasking
    move.l     gfx_base,a1                                               
    jsr        CloseLibrary(a6)                                     ; close graphics.library
    rts

;***************************************************************************
; VARIABLES
;***************************************************************************
gfx_name        dc.b    "graphics.library",0    ; name of graphics.library of Amiga O.S.
                even
gfx_base        dc.l    0                       ; base address of graphics.library
old_dma         dc.w    0                       ; saved state of DMACON
old_intena      dc.w    0                       ; saved value of INTENA
old_intreq      dc.w    0                       ; saved value of INTREQ
old_adkcon      dc.w    0                       ; saved value of ADKCON
return_msg      dc.l    0
wb_view         dc.l    0
old_cop         dc.l    0