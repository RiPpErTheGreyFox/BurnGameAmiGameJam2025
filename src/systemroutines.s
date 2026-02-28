;---------- Includes ----------
            INCDIR          "include"
            INCLUDE         "hw.i"

    SECTION CODE

; takes full control of the system, saving it's state to be restored on program exit

TakeSystem:
    move.l      $4,a6
    jsr         Forbid(a6)
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
    bsr         WaitVBlank                                         ; wait for a vblank

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

ReleaseSystem:

    lea         CUSTOM,a5
    move.l      old_cop,COP1LC(a5)                                  ; set the system copperlist
    move.w      d0,COPJMP1(a5)                                      ; start the system copperlist

    move.w      #$7fff,INTENA(a5)                                   ; disable interrupts
    bsr         WaitVBlank                                         ; wait a frame

    move.l      old_interrupt_ptr,$70.w                             ; restore original interrupt pointer
    move.w      #$7fff,INTREQ(a5)                                   ; clear requests

    move.w      old_intena,d0
    or.w        #$c000,d0                                           ; set bits of INTENA state
    move.w      d0,INTENA(a5)                                       ; restore original intena

    move.l      gfx_base,a6
    jsr         DisOwnBlitter(a6)                                   ; release Blitter ownership
    move.l      $4,a6
    jsr         Enable(a6)                                          ; enable multitasking
    jsr         Permit(a6)
    move.l      gfx_base,a1                                               
    jsr         CloseLibrary(a6)                                    ; close graphics.library
    rts

; waits 3 scanlines to allow for DMA to start when needed
; wait CIA B Timer A
WaitCIABTA:
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

;---------- Collision Functions ----------

; TODO: anything calling this should be using the middle of their entity point and not the top left corner
; TODO: update this to take from a collision box and not just the sprite
; iterates through every live entity and determines if a collision has taken place
; @params: a6 - the source entity
; @params: d0 - actor.type we're intending to collide with
; @returns: a4 - first entity found that's been collided with, zero if no collisions
; @returns: d6 - 1 if collision found, 0 if no collisions
FindEntityCollidedWith:
    ; jump to the loop we're intending to interact which
    ; check's the actor type we're looking for
    cmp         #ACTOR_TYPE_ENEMY,d0
    beq         .LoadEnemySearch
    cmp         #ACTOR_TYPE_PLAYER,d0
    beq         .LoadPlayerSearch
    cmp         #ACTOR_TYPE_PROJECTILE,d0
    beq         .LoadProjectileSearch
    ; load the temp registers with the intended data, then jump the the routine
.LoadEnemySearch:
    lea         enemy_array,a4
    move.w      #ENEMY_MAX_COUNT-1,d6
    bra         .StartEntitySearch
.LoadPlayerSearch:
    ; TODO: we don't have a real player array yet
    lea         pl_instance1,a4
    move.w      #1,d6
    bra         .StartEntitySearch
.LoadProjectileSearch:
    lea         projectile_array,a4
    move.w      #PROJECTILE_MAX_COUNT-1,d6
    bra         .StartEntitySearch

    ; iterate through every entity of the intended type, checking size bounds 
    ; semi-universal routine, use d6 as a loop counter, and a4 as the address
.StartEntitySearch:
    move.w      actor.x_middle(a6),d0
    move.w      actor.y_middle(a6),d1
.loopStart:
    cmp         #ACTOR_STATE_INACTIVE,actor.state(a4)
    beq         .loopEnd
    cmp         #ACTOR_STATE_DEAD,actor.state(a4)
    beq         .loopEnd
    bsr         IsPointWithinEntity
    cmp         #1,d2
    beq         .EntityFound
.loopEnd:
    adda        #actor.length,a4
    dbra        d6,.loopStart
.EntityNotFound:
    move.l      #0,d6
    move.l      #0,a4
    rts
.EntityFound:
    move.l      #1,d6
    rts

; takes an X/Y and determines if that's "within" the size of a provided entity
; doesn't do any active entity checking, it's just a simple "is within" or not
; active entity and eligibility has to be checked by the calling function
; @params: a4 - entity to be checked
; @params: d0.w - x position of the point to check
; @params: d1.w - y position of the point to check
; @clobbers: d2,d3
; @returns: d2 - 1 if true, 0 if false
IsPointWithinEntity:
    ; set the flag
    ; grab, store and add size to the entities position to create "the box"
    move.w      actor.x(a4),d2
    move.w      actor.y(a4),d3
    add         actor.width(a4),d2
    add         actor.height(a4),d3

    ; first check if x is above minimum, and below maximum
    cmp         actor.x(a4),d0
    blt         .checkFailed
        cmp         d2,d0
        bgt         .checkFailed
            ; if so, then check if y is above minimum and below maximum
            cmp         actor.y(a4),d1
            blt         .checkFailed
                cmp         d3,d1
                bgt         .checkFailed
                    move.w      #1,d2
                    rts
    

.checkFailed
    move.w      #0,d2
    rts

;---------- Interrupt Functions ----------

; initialises the keyboard input and installs the interrupt routines
InitialiseKeyboard:

    lea         CIAA,a0

    ; disable all CIAA IRQs
    move.b      #%01111111,CIAICR(a0)

    ; renable only keyboard IRQ
    ;             76543210
    move.b      #%10001000,CIAICR(a0)

    ; install the levl 2 keyboard interrupt routine
    move.l      #KeyboardInterrupt,$68

    ; enable keyboard interrupts (bit 3)
    ;           ; 5432109876543210
    move.w      #%1100000000001000,INTENA(a5)

    rts

; Keyboard interrupt routine
KeyboardInterrupt:
    movem.l     d0-a6,-(sp)
    lea         CIAA,a0
    ; reading the icr we all cause its reset, so the int is cancelled as in intreq
    move.b      CIAICR(a0),d0
    ; if bit IR = 0, returns
    btst.l      #7,d0
    beq         .return
    ; if bit SP = 0, returns
    btst.l      #3,d0
    beq         .return
    ; reads the INTENAR register
    move.w      INTENAR(a5),d0
    ; if bit MASTER = 0, returns
    btst.l      #14,d0
    beq         .return
    ; if bit 3 (SP) = 0, returns
    and.w       INTREQR(a5),d0
    btst.l      #3,d0
    beq         .return
    ; reads the key pressed on the keyboard from CIAA serial register
    moveq       #0,d0
    move.b      CIASDR(a0),d0
    ; inverts all the bits
    not.b       d0
    ; rotates right
    ror.b       #1,d0
    ; save into the variable
    move.b      d0,current_keyboard_key
    ; set the KDAT line to confirm that we have received the character
    bset.b      #6,CIACRA(a0)
    move.b      #$ff,CIASDR(a0)
    ; wait 90 microseconds (4 lines)
    moveq       #4-1,d0
    .waitlines:
    ; reads the actual raster line
    move.b      VHPOSR(a5),d1
    .stepline:
    ; waits a line
    cmp.b       VHPOSR(a5),d1
    beq         .stepline
    ; waits other lines
    dbra        d0,.waitlines
    ; clears KDAT line to enable input mode
    bclr.b      #6,CIACRA(a0)

.return:
    ; clears interrupt request
    move.w      #%1000,INTREQ(a5)
    movem.l     (sp)+,d0-a6
    rte

; TODO: expand this to allow any channel interrupt to be enabled
EnableAudioChannel0Interrupt:
    bsr         WaitCIABTA
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