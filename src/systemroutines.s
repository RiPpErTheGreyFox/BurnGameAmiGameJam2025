;---------- Includes ----------
            INCDIR          "include"
            INCLUDE         "hw.i"

    SECTION CODE

; takes full control of the system, saving it's state to be restored on program exit

take_system:
    move.l      $4,a6
    jsr         Disable(a6)                                         ; stop multitasking
    lea         gfx_name,a1                                               
    jsr         OpenLibrary(a6)                                     ; open graphics.library
    move.l      d0,gfx_base                                         ; save base address of graphics.library
    move.l      d0,a6
    move.l      $26(a6),old_cop                                     ; save system copperlist address
    jsr         OwnBlitter(a6)                                      ; takes the Blitter exclusive
    lea         CUSTOM,a5
    
    move.w      INTENAR(a5),old_intena                              ; store the old interrupt enable

    move.l      #$7FFF7FFF,INTENA(a5)                               ; disable system interrupts
    bsr         wait_vblank                                         ; wait for a vblank

    ; program the interrupt vectors

    move.l      $70.w,old_interrupt_ptr                             ; store old INTER PTR

    move.l      #InterruptHandlerFunction,$70.w                     ; set the pointer to which function the level 4 interrupt needs
    move.w      #INTENABLEMASK,INTENA(a5)                           ; set the INTENA bits

    move.w      #DMASET,DMACON(a5)                                  ; set dma channels

    move.l      #copperlist,COP1LC(a5)                              ; set our copperlist address into Copper
    move.w      d0,COPJMP1(a5)                                      ; reset Copper PC to the beginning of our copperlist
    move.w      #0,$dff1fc                                          ; disable AGA
    move.w      #$c00,$dff106                                             
    move.w      #$11,$10c(a5)

    rts

; releases full control of the system, restarting EXEC after resetting the state

release_system:

    lea         CUSTOM,a5
    move.l      old_cop,COP1LC(a5)                                  ; set the system copperlist
    move.w      d0,COPJMP1(a5)                                      ; start the system copperlist

    move.w      #$7fff,INTENA(a5)                                   ; disable interrupts
    bsr         wait_vblank                                         ; wait a frame

    move.l      old_interrupt_ptr,$70.w                             ; restore original interrupt pointer
    move.w      #$7fff,INTREQ(a5)                                   ; clear requests

    move.w      old_intena,d0
    or.w        #$c000,d0                                           ; set bits of INTENA state
    move.w      d0,INTENA(a5)                                       ; restore original intena

    move.l      gfx_base,a6
    jsr         DisOwnBlitter(a6)                                   ; release Blitter ownership
    move.l      $4,a6
    jsr         Enable(a6)                                          ; enable multitasking
    move.l      gfx_base,a1                                               
    jsr         CloseLibrary(a6)                                    ; close graphics.library
    rts

;   waits 3 scanlines to allow for DMA to start when needed
wait_ciab_ta:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    lea         $BFD000,a4
    move.b      $e00(a4),d0
    move.b      #%0001000,$e00(a4)                                  ; cra - one-shot mode
    move.b      #%0111111,$d00                                      ; icr - disable all
    move.b      45,$400(a4)                                         ; talo - timer low (about 3 scanlines)
    move.b      #0,$500(a4)                                         ; tahi - start counting
.wait
    btst.b      #0,$d00(a4)                                         ; check timer a finish
    beq.b       .wait
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

;-------- Random Number Functions --------

; regenerates the prng long word filled with a random number
GetRandomNumber:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    moveq       #4,d2
    move.l      prng_number,d0
Ninc0:
    moveq       #0,d1
    ror.l       #2,d0
    bcc         Ninc1

    addq.b      #1,d1
Ninc1:
    ror.l       #3,d0
    bcc         Ninc2

    addq.b      #1,d1
Ninc2:
    rol.l       #5,d0
    roxr.b      #1,d1
    roxr.l      #1,d0
    dbra        d2,Ninc0

    move.l      d0,prng_number

    movem.l     (sp)+,d0-a6                                         ; restore registers onto the stack
    rts

;---------- Interrupt Functions ----------

; TODO: expand this to allow any channel interrupt to be enabled
EnableAudioChannel0Interrupt:
    bsr         wait_ciab_ta
    move.l      #InterruptHandlerFunction,$70.w                     ; set the pointer to which function the level 4 interrupt needs

    move.w      #INTENABLEMASK,INTENA(a5)                           ; set the INTENA bits
    rts

; handles the level 4 interrupts regarding audio, upgrade this to allow more audio channels later
InterruptHandlerFunction:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    lea         CUSTOM,a5

    btst.b      #7,$1F(a5)                                          ; check if is level 4 interrupt
    beq.w       .exit_interrupt

    not.b       Audio
    bne.b       .cancel_interrupt

    move.w      #$0003,DMACON(a5)                                   ; disable audio 0+1 dma
    move.w      #$0080,INTENA(a5)                                   ; disable interrupt
.cancel_interrupt
    move.w      #$0080,INTREQ(a5)                                   ; clear interrupt request

.exit_interrupt
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rte

;***************************************************************************
; VARIABLES
;***************************************************************************
gfx_name        dc.b    "graphics.library",0                        ; name of graphics.library of Amiga O.S.
Audio           dc.b    0
                even
gfx_base        dc.l    0                                           ; base address of graphics.library
old_dma         dc.w    0                                           ; saved state of DMACON
old_intena      dc.w    0                                           ; saved value of INTENA
old_intreq      dc.w    0                                           ; saved value of INTREQ
old_interrupt_ptr dc.w  0                                           ; saved Interrupt pointer
old_adkcon      dc.w    0                                           ; saved value of ADKCON
return_msg      dc.l    0                   
wb_view         dc.l    0
old_cop         dc.l    0
prng_number     dc.l    $DEADBEEF