;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------
ACTOR_SUBPIXEL_PER_PIXEL        equ 16                      ; how many subpixels are in each pixel
ACTOR_GRAVITY_NORMAL            equ 5                       ; in sp/f
ACTOR_GRAVITY_SLOW              equ 1                       ; in sp/f

ACTOR_STATE_ACTIVE              equ 0
ACTOR_STATE_HIT                 equ 1
ACTOR_STATE_INVINCIBLE          equ 2
ACTOR_STATE_DEAD                equ 3
ACTOR_STATE_INACTIVE            equ 4

ACTOR_TYPE_PLAYER               equ 0
ACTOR_TYPE_ENEMY                equ 1
ACTOR_TYPE_PROJECTILE           equ 2

;-------- Data Structures -----
; generic actor subtype to be used by every object that needs it
                        rsreset
actor.x                 rs.w        1                       ; position (top left of actor)
actor.subpixel_x        rs.w        1                       ; subpixel position
actor.y                 rs.w        1
actor.subpixel_y        rs.w        1
actor.velocity_x        rs.w        1                       ; x velocity in subpixels/f
actor.velocity_y        rs.w        1                       ; y velocity in subpixels/f
actor.bobdata           rs.l        1                       ; address of graphics data
actor.mask              rs.l        1                       ; address of graphics mask
actor.current_frame     rs.w        1                       ; current animation frame
actor.current_anim      rs.w        1                       ;
actor.respectsBounds    rs.w        1                       ; a flag that determines if the current actor respects screen boundaries
actor.width             rs.w        1                       ; width of the actor object
actor.height            rs.w        1                       ; height of the object
actor.x_middle          rs.w        1                       ; holds the calculated middle position of the actor
actor.y_middle          rs.w        1                       ; holds the y component
actor.spritesheetwidth  rs.w        1                       ; width of the spritesheet used as the graphic
actor.spritesheetheight rs.w        1
actor.state             rs.w        1                       ; current hard state
actor.movement_state    rs.w        1                       ; current movement state
actor.anim_delay        rs.w        1                       ; delay between two animation frames
actor.anim_timer        rs.w        1                       ; timer for the anim_delay
actor.inv_timer         rs.w        1                       ; timer for invulnerable state
actor.flash_timer       rs.w        1                       ; timer for flashing
actor.visible           rs.w        1                       ; visibility flag: 1 visible, 0 not
actor.gravity           rs.w        1                       ; gravity flag: 1 is affected by gravity, 0 is not
actor.type              rs.w        1                       ; used for checking actor types in universal functions
actor.jump_decel_timer  rs.w        1                       ; timer variable to track jump deceleration
actor.fire_timer        rs.w        1                       ; timer to implement a delay between subsequent shots
actor.fire_delay        rs.w        1                       ; delay between two shots (in frames)
actor.fire_type         rs.w        1                       ; type of fire
actor.controller_addr   rs.l        1                       ; point of the attached controller for this actor, if one exists
actor.sprite_addr       rs.l        1                       ; store the sprite address of the actor if it's a sprite user (projectiles only)
actor.length            rs.b        0

;----------- Variables --------

;---------- Subroutines -------
    SECTION CODE

; draws the actor using their current data
; @params: a6 - address of the player instance to draw
DrawActor:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    tst.w       actor.visible(a6)                                   ; actor is visible?
    beq         .return                                             ; if not, stop
    move.l      actor.bobdata(a6),a0                                ; actor's image address
    move.l      actor.mask(a6),a1                                   ; actor's mask address
    move.l      draw_buffer,a2                                      ; destination video buffer address
    move.w      actor.x(a6),d0                                      ; x position of the actor in pixels
    move.w      actor.y(a6),d1                                      ; y position of the actor in pixels
    move.w      actor.width(a6),d2                                  ; actor width in pixels
    move.w      actor.height(a6),d3                                 ; actor height in pixels
    move.w      actor.current_anim(a6),d4                           ; spritesheet column of actor
    move.w      actor.current_frame(a6),d5                          ; spritesheet row of actor
    move.w      actor.spritesheetwidth(a6),a3                       ; spritesheet width
    move.w      actor.spritesheetheight(a6),a4                      ; spritesheet height

    bsr         DrawBOb
.return:
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; hard sets the actor position, resetting the subpixel count in the process
; @params: d0 - new x position of actor
; @params: d1 - new y position of actor
; @params: a6 - address of the actor instance to update
SetActorPosition:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    move.w      d0,actor.x(a6)
    move.w      d1,actor.y(a6)
    move.w      #0,actor.subpixel_x(a6)
    move.w      #0,actor.subpixel_y(a6)
    
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; applies the current velocities to the actor position
; @params: a6 - address of the actor instance to update
ProcessActorMovement:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    move.w      actor.x(a6),d0                                      ; d0 = x
    move.w      actor.y(a6),d1                                      ; d1 = y
    move.w      actor.subpixel_x(a6),d2                             ; d2 = subpixel_x
    move.w      actor.subpixel_y(a6),d3                             ; d3 = subpixel_y
    move.w      actor.velocity_x(a6),d4                             ; d4 = velocity_x
    move.w      actor.velocity_y(a6),d5                             ; d5 = velocity_y

    bsr         UpdateJumpVelocity
    bsr         ApplyVelocities
    cmpi        #1,actor.respectsBounds(a6)
    bne         .EndOfFunc
    bsr         BoundsCheck
    
.EndOfFunc:
    ; apply all the updates
    move.w      d0,actor.x(a6)                                      ; move the final stats back into memory
    move.w      d1,actor.y(a6)
    move.w      d2,actor.subpixel_x(a6)
    move.w      d3,actor.subpixel_y(a6)
    move.w      d4,actor.velocity_x(a6)
    move.w      d5,actor.velocity_y(a6)
    ; calculate the middle position of the actor
    move.w      actor.width(a6),d2
    move.w      actor.height(a6),d3
    lsr.w       d2                                                  ; divide width and height by 2
    lsr.w       d3
    add.w       d2,d0
    add.w       d3,d1
    move.w      d0,actor.x_middle(a6)
    move.w      d1,actor.y_middle(a6)
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; @params: a6 - address of the current actor instance to update
UpdateJumpVelocity:
    ; first see if actor even respects gravity, if not, then just skip the function
    cmpi        #1,actor.gravity(a6)
    bne         .endFunc
    ; first to see if the timer is set, if the timer isn't set, then we haven't jumped
    cmpi        #0,actor.jump_decel_timer(a6)
    ble         .applyNormalGravity                                 ; skip if there's no slow timer left
    ; there's a timer set, so decrement it
    subi        #1,actor.jump_decel_timer(a6)
    ; check if we have a controller attached
    cmpi        #0,actor.controller_addr(a6)
    beq         .applyNormalGravity                                 ; skip if we can't find a controller
    ; otherwise grab it from the actor
    move.l      actor.controller_addr(a6),a4
    move.w      joystick.up(a4),d6
    btst        #0,d6
    bne         .applySlowGravity
    bra         .applyNormalGravity
    ; TODO: make it so that holding down the button reduces falling speed
.applySlowGravity:
    addi        #ACTOR_GRAVITY_SLOW,d5
    bra         .endGravity
.applyNormalGravity:
    ; decelerate down to the maximum negative speed
    addi        #ACTOR_GRAVITY_NORMAL,d5
.endGravity: 
    ; do a max velocity test
    cmp         #PLAYER_MAXVELOCITY_Y,d5
    bgt         .clampYVelocity
    bra         .endVelocityClamp
.clampYVelocity:
    move        #PLAYER_MAXVELOCITY_Y,d5
    ; clamp max velocity
.endVelocityClamp:
.collisionCheck:
    ; only check if we're moving down
    tst         d5
    blt         .falseResult                                        ; if velocity is negative, we're on our way up so don't check
    ; if we hit something, stop and reset our state back to normal
    ; collision check with temp register, increase it by 1 to check a pixel below us
    move        d1,d6                                               ; store Y position in a temp register
    addi        #1,d1
    jsr         CollisionCheckAtPoint                               ; call the function
    move        d6,d1                                               ; restore Y position from temp register
    btst        #0,d7
    beq         .falseResult
    ; true
.trueResult:
    move.w      #PLAYER_MOVEMENT_STATE_NORMAL,actor.movement_state(a6) ; reset the movement state
    move.w      #0,d3                                               ; reset subpixels
    move.w      #0,d5                                               ; reset velocity
    ; false
.falseResult:
.endFunc:
    rts

; to be called only from the process movement function
ApplyVelocities:
.checkXVelocity:
    ; check if velocity isn't zero
    tst         d4
    bne         .applyXVelocity                                     ; if the test value came back with Z flag set
    bra         .checkYVelocity                                     ; just skip as there's no velocity to apply
.applyXVelocity:
    ; check the current velocity for positive or negative
    ; send to the correct branch
    tst         d4                                                  ; compare against zero to get the flags
    blt         .XNegative                                          ; if the negative flag is set then jump to neg
.XPositive:
    add         d4,d2                                               ; apply it to the current subpixel count
    ; then add to the full pixel count
    ; if subpixel > ACTOR_SUBPIXEL_PER_PIXEL then adjust the full count 
    cmpi.w      #ACTOR_SUBPIXEL_PER_PIXEL,d2
    bge         .spilloverXHigh
    bra         .checkYVelocity                                     ; otherwise we're done
.XNegative:
    add.w       d4,d2
    cmpi.w      #0,d2
    blt         .spilloverXLow
    bra         .checkYVelocity
.spilloverXHigh:
    ; run the loop to add pixels until subpixel's back below threshold
    addq        #1,d0                                               ; increment full pixel count
    subi        #ACTOR_SUBPIXEL_PER_PIXEL,d2                        ; reduce subpixel count by a full pixel
    cmpi.w      #ACTOR_SUBPIXEL_PER_PIXEL,d2                        ; check if there's more pixels to process
    bge         .spilloverXHigh                                     ; loop
    bra         .checkYVelocity                                     ; otherwise we're done
.spilloverXLow:
    ; run the loop to remove pixels until subpixel's back below threshold
    subq        #1,d0
    addi        #ACTOR_SUBPIXEL_PER_PIXEL,d2
    cmpi.w      #0,d2
    blt         .spilloverXLow
    bra         .checkYVelocity

.checkYVelocity:
    ; check if velocity isn't zero                                  
    tst         d5
    bne         .applyYVelocity                                     ; if the test value came back with Z flag set
    bra         .endOfFunc                                          ; just skip as there's no velocity to apply
.applyYVelocity:
    ; YVelocity is a TODO:
    ; check the current velocity for positive or negative
    ; send to the correct branch
    tst         d5                                                  ; compare against zero to get the flags
    blt         .YNegative                                          ; if the negative flag is set then jump to neg
.YPositive:
    add         d5,d3                                               ; apply it to the current subpixel count
    ; then add to the full pixel count
    ; if subpixel > PLAYER_SUB PIXEL_PER_PIXEL then adjust the full count
    cmpi.w      #ACTOR_SUBPIXEL_PER_PIXEL,d3
    bge         .spilloverYHigh
    bra         .endOfFunc                                          ; otherwise we're done
.YNegative: 
    add.w       d5,d3
    cmpi.w      #0,d3
    blt         .spilloverYLow
    bra         .endOfFunc
.spilloverYHigh:
    ; run the loop to add pixels until subpixel's back below threshold
    addq        #1,d1                                               ; increment full pixel count
    subi        #ACTOR_SUBPIXEL_PER_PIXEL,d3                        ; reduce subpixel count by a full pixel
    cmpi.w      #ACTOR_SUBPIXEL_PER_PIXEL,d3                        ; check if there's more pixels to process
    bge         .spilloverYHigh                                     ; loop
    bra         .endOfFunc                                          ; otherwise we're done
.spilloverYLow:
    ; run the loop to remove pixels until subpixel's back below threshold
    subq        #1,d1
    addi        #ACTOR_SUBPIXEL_PER_PIXEL,d3
    cmpi.w      #0,d3
    blt         .spilloverYLow
    bra         .endOfFunc
.endOfFunc
    rts

; to be called only from the process movement function
BoundsCheck:
    move.w      #SCREEN_BOUNDARY_MAX_X,d7
    sub.w       actor.width(a6),d7
    cmp         d7,d0
    bge         .boundsHighX
    cmpi        #SCREEN_BOUNDARY_MIN_X,d0
    blt         .boundsLowX
    bra         .boundsCheckY
.boundsHighX
    move.w      #SCREEN_BOUNDARY_MAX_X,d7
    sub.w       actor.width(a6),d7
    move.w      d7,d0
    move.w      #0,d2
    move.w      #0,d4
    bra         .boundsCheckY
.boundsLowX
    move.w      #SCREEN_BOUNDARY_MIN_X,d0
    move.w      #0,d2
    move.w      #0,d4
.boundsCheckY
    move.w      #SCREEN_BOUNDARY_MAX_Y,d7
    sub.w       actor.height(a6),d7
    cmp         d7,d1
    bge         .boundsHighY
    cmpi        #SCREEN_BOUNDARY_MIN_Y,d1
    ble         .boundsLowY
    bra         .boundsCheckOver
.boundsHighY
    move.w      #SCREEN_BOUNDARY_MAX_Y,d7
    sub.w       actor.height(a6),d7
    move.w      d7,d1
    move.w      #0,d3
    move.w      #0,d5
    bra         .boundsCheckOver
.boundsLowY
    move.w      #SCREEN_BOUNDARY_MIN_Y,d1
    move.w      #0,d3
    move.w      #0,d5
.boundsCheckOver
    rts
; does all the animation updating for a player
; TODO: Do frame swapping with lookup tables and the like
; @params: a6 - address of the player instance to update
UpdateAnimation:
    ; check for animation swap
    move.w      actor.velocity_x(a6),d4                             ; d4 = velocity_x
    move.w      actor.current_frame(a6),d6                          ; d6 = current anim frame
    move.w      actor.anim_timer(a6),d7                             ; d7 = current frame timer

    tst         d4
    beq         .idleAnim
    blt         .leftAnim
    bgt         .rightAnim

.idleAnim
    move.w      #PLAYER_ANIM_IDLE,d1                                ; swap the animation
    bra         .EndAnimSwapCheck
.leftAnim
    move.w      #PLAYER_ANIM_JUMP,d1
    bra         .EndAnimSwapCheck
.rightAnim
    move.w      #PLAYER_ANIM_WALK,d1
    bra         .EndAnimSwapCheck
.EndAnimSwapCheck:

.UpdateCurrentFrame:
    ; decrement the timer
    ; if timer = 0 then swap frame
    subq        #1,d7
    bne         .EndOfFunc
.NextFrame:
    move.w      actor.anim_delay(a6),d7                             ; reset the timer
    addq        #1,d6                                               ; increment the frame counter
    cmpi        #PLAYER_MAX_FRAME_COUNT,d6                          ; check if we've hit the max frame counter
    bne         .EndOfFunc                                          ; if not, jump over the reset
.ResetFrames:
    ; wraps around at the end of frames
    move.w      #0,d6

.EndOfFunc:
    ; save all our changed variables before leaving
    move.w      d1,actor.current_anim(a6)
    move.w      d6,actor.current_frame(a6)
    move.w      d7,actor.anim_timer(a6)
    rts
