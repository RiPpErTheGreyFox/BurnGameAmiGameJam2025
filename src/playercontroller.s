;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------
ACTOR_SUBPIXEL_PER_PIXEL        equ 16                      ; how many subpixels are in each pixel

PLAYER_WIDTH                    equ 32                      ; width in pixels
PLAYER_WIDTH_B                  equ (PLAYER_WIDTH/8)        ; width in bytes
PLAYER_HEIGHT                   equ 32                      ; height in pixels
PLAYER_STARTING_POSX            equ 16                      ; starting position
PLAYER_STARTING_POSY            equ 32
PLAYER_MAXVELOCITY_X            equ 32                      ; default max speed in subpixel/frame
PLAYER_MAXVELOCITY_Y            equ 32
PLAYER_ACCELERATION             equ 1                       ; in subpixels per frame
PLAYER_DECELERATION             equ 1
PLAYER_JUMP_VELOCITY_INIT       equ -32                     ; initial velocity to apply to character when jumping
PLAYER_BOUNDARY_MIN_X           equ 16
PLAYER_BOUNDARY_MAX_X           equ (0+DISPLAY_WIDTH-PLAYER_WIDTH)               
PLAYER_BOUNDARY_MIN_Y           equ 0
PLAYER_BOUNDARY_MAX_Y           equ (VIEWPORT_HEIGHT-PLAYER_HEIGHT)
PLAYER_MOVEMENT_STATE_NORMAL    equ 0
PLAYER_MOVEMENT_STATE_AIRBORNE  equ 1
PLAYER_ANIM_IDLE                equ 1
PLAYER_ANIM_WALK                equ 0
PLAYER_ANIM_JUMP                equ 2
PLAYER_ANIM_EXPL                equ 3
PLAYER_MAX_FRAME_COUNT          equ 3                       ; only three frames of animation, static for now
PLAYER_FRAME_SIZE               equ (PLAYER_WIDTH_B*PLAYER_HEIGHT)
PLAYER_MASK_SIZE                equ (PLAYER_WIDTH_B*PLAYER_HEIGHT)
PLAYER_SPRITESHEET_WIDTH        equ 96
PLAYER_SPRITESHEET_HEIGHT       equ 96
PLAYER_STATE_ACTIVE             equ 0
PLAYER_STATE_HIT                equ 1
PLAYER_STATE_INVINCIBLE         equ 2

; player states:
; - active: accepts input, can collide with enemies
; - hit: the player has been hit, collisions are disabled
; - invincible: the player is now invulnerable for a short time

PLAYER_MAX_ANIM_DELAY           equ 10                      ; delay between two animation frames (in frames)
PLAYER_INV_STATE_DURATION       equ (50*5)                  ; duration of the invincible state (in frames)
PLAYER_FLASH_DURATION           equ 3                       ; flashing duration (in frames)

BASE_FIRE_INTERVAL              equ 7                       ; delay between two shots for base bullets
BULLET_TYPE_BASE                equ 0                       ; types of bullets
;-------- Data Structures -----
; generic actor subtype to be used by every object that needs it
                        rsreset
actor.x                 rs.w        1                       ; position
actor.subpixel_x        rs.w        1                       ; subpixel position
actor.y                 rs.w        1
actor.subpixel_y        rs.w        1
actor.velocity_x        rs.w        1                       ; x velocity in subpixels/f
actor.velocity_y        rs.w        1                       ; y velocity in subpixels/f
actor.bobdata           rs.l        1                       ; address of graphics data
actor.mask              rs.l        1                       ; address of graphics mask
actor.current_frame     rs.w        1                       ; current animation frame
actor.current_anim      rs.w        1                       ;
actor.width             rs.w        1                       ; width of the actor object
actor.height            rs.w        1                       ; height of the object
actor.spritesheetwidth  rs.w        1                       ; width of the spritesheet used as the graphic
actor.spritesheetheight rs.w        1
actor.state             rs.w        1                       ; current hard state
actor.movement_state    rs.w        1                       ; current movement state
actor.anim_delay        rs.w        1                       ; delay between two animation frames
actor.anim_timer        rs.w        1                       ; timer for the anim_delay
actor.inv_timer         rs.w        1                       ; timer for invulnerable state
actor.flash_timer       rs.w        1                       ; timer for flashing
actor.visible           rs.w        1                       ; visibility flag: 1 visible, 0 not
actor.fire_timer        rs.w        1                       ; timer to implement a delay between subsequent shots
actor.fire_delay        rs.w        1                       ; delay between two shots (in frames)
actor.fire_type         rs.w        1                       ; type of fire
actor.length            rs.b        0

;----------- Variables --------
; player instance
pl_instance1            dc.w    PLAYER_STARTING_POSX,0,PLAYER_STARTING_POSY,0;
                        dc.w    0,0                                         ;
                        dc.l    player_gfx                                  ;
                        dc.l    player_mask                                 ;
                        dc.w    0                                           ;
                        dc.w    PLAYER_ANIM_IDLE                            ;
                        dc.w    PLAYER_WIDTH,PLAYER_HEIGHT                  ;
                        dc.w    PLAYER_SPRITESHEET_WIDTH,PLAYER_SPRITESHEET_HEIGHT                                 ;
                        dc.w    PLAYER_STATE_ACTIVE                         ;
                        dc.w    PLAYER_MOVEMENT_STATE_NORMAL                ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_INV_STATE_DURATION                   ;
                        dc.w    PLAYER_FLASH_DURATION                       ;
                        dc.w    1                                           ;
                        dc.w    0                                           ;
                        dc.w    BASE_FIRE_INTERVAL                          ;
                        dc.w    BULLET_TYPE_BASE                            ;

                        ; player instance
pl_instance2            dc.w    64,0,PLAYER_STARTING_POSY,0                 ;
                        dc.w    0,0                                         ;
                        dc.l    player_gfx                                  ;
                        dc.l    player_mask                                 ;
                        dc.w    0                                           ;
                        dc.w    PLAYER_ANIM_WALK                            ;
                        dc.w    PLAYER_WIDTH,PLAYER_HEIGHT                  ;
                        dc.w    PLAYER_SPRITESHEET_WIDTH,PLAYER_SPRITESHEET_HEIGHT 
                        dc.w    PLAYER_STATE_ACTIVE                         ;
                        dc.w    PLAYER_MOVEMENT_STATE_NORMAL                ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_INV_STATE_DURATION                   ;
                        dc.w    PLAYER_FLASH_DURATION                       ;
                        dc.w    1                                           ;
                        dc.w    0                                           ;
                        dc.w    BASE_FIRE_INTERVAL                          ;
                        dc.w    BULLET_TYPE_BASE                            ;

;---------- Subroutines -------
    SECTION CODE

playercontrollerstart:
    rts

update_players:
    ; update and draw player 1
    lea         joystick1_instance,a4
    lea         pl_instance1,a6
    ;bsr         move_player_with_joystick
    bsr         process_actor_movement
    bsr         updateAnimation
    bsr         draw_actor
    ; update and draw player 2
    lea         joystick2_instance,a4
    lea         pl_instance2,a6
    bsr         move_player_with_joystick
    bsr         process_actor_movement
    bsr         updateAnimation
    bsr         draw_actor

    rts

; draws the actor using their current data
; @params: a6 - address of the player instance to draw
draw_actor:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    tst.w       actor.visible(a6)                                  ; player is visible?
    beq         .return                                             ; 
    move.l      actor.bobdata(a6),a0                               ; player's image address
    move.l      actor.mask(a6),a1                                  ; player's mask address
    move.l      draw_buffer,a2                                      ; destination video buffer address
    move.w      actor.x(a6),d0                                     ; x position of the player in pixels
    move.w      actor.y(a6),d1                                     ; y position of the player in pixels
    move.w      actor.width(a6),d2                                    ; player width in pixels
    move.w      actor.height(a6),d3                                   ; player height in pixels
    move.w      actor.current_anim(a6),d4                          ; spritesheet column of player
    move.w      actor.current_frame(a6),d5                         ; spritesheet row of player
    move.w      actor.spritesheetwidth(a6),a3                        ; spritesheet width
    move.w      actor.spritesheetheight(a6),a4                       ; spritesheet height

    bsr         draw_bob
.return:
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; hard sets the player position, resetting the subpixel count in the process
; @params: d0 - new x position of player
; @params: d1 - new y position of player
; @params: a6 - address of the player instance to update
set_player_position:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    move.w      d0,actor.x(a6)
    move.w      d1,actor.y(a6)
    move.w      #0,actor.subpixel_x(a6)
    move.w      #0,actor.subpixel_y(a6)
    
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; applies the current velocities to the actor position
; @params: a6 - address of the actor instance to update
process_actor_movement:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    move.w      actor.x(a6),d0                                     ; d0 = x
    move.w      actor.y(a6),d1                                     ; d1 = y
    move.w      actor.subpixel_x(a6),d2                            ; d2 = subpixel_x
    move.w      actor.subpixel_y(a6),d3                            ; d3 = subpixel_y
    move.w      actor.velocity_x(a6),d4                            ; d4 = velocity_x
    move.w      actor.velocity_y(a6),d5                            ; d5 = velocity_y

    jsr         update_jump_velocity
    jsr         apply_velocities
    jsr         bounds_check
    
.EndOfFunc:
    ; apply all the updates
    move.w      d0,actor.x(a6)                                     ; move the final stats back into memory
    move.w      d1,actor.y(a6)
    move.w      d2,actor.subpixel_x(a6)
    move.w      d3,actor.subpixel_y(a6)
    move.w      d4,actor.velocity_x(a6)
    move.w      d5,actor.velocity_y(a6)
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

update_jump_velocity:
    ; TODO: make it so that holding down the button reduces falling speed
    ; decelerate down to the maximum negative speed
    addi        #1,d5
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
    jsr         collision_check_at_point                            ; call the function
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
    rts

; to be called only from the process movement function
apply_velocities:
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
    subi        #ACTOR_SUBPIXEL_PER_PIXEL,d2                       ; reduce subpixel count by a full pixel
    cmpi.w      #ACTOR_SUBPIXEL_PER_PIXEL,d2                       ; check if there's more pixels to process
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
    bra         .endOfFunc                                        ; just skip as there's no velocity to apply
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
    bra         .endOfFunc                                        ; otherwise we're done
.YNegative: 
    add.w       d5,d3
    cmpi.w      #0,d3
    blt         .spilloverYLow
    bra         .endOfFunc
.spilloverYHigh:
    ; run the loop to add pixels until subpixel's back below threshold
    addq        #1,d1                                               ; increment full pixel count
    subi        #ACTOR_SUBPIXEL_PER_PIXEL,d3                       ; reduce subpixel count by a full pixel
    cmpi.w      #ACTOR_SUBPIXEL_PER_PIXEL,d3                       ; check if there's more pixels to process
    bge         .spilloverYHigh                                     ; loop
    bra         .endOfFunc                                        ; otherwise we're done
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
bounds_check:
    cmpi        #PLAYER_BOUNDARY_MAX_X,d0
    bge         .boundsHighX
    cmpi        #PLAYER_BOUNDARY_MIN_X,d0
    blt         .boundsLowX
    bra         .boundsCheckY
.boundsHighX
    move.w      #PLAYER_BOUNDARY_MAX_X,d0
    move.w      #0,d2
    move.w      #0,d4
    bra         .boundsCheckY
.boundsLowX
    move.w      #PLAYER_BOUNDARY_MIN_X,d0
    move.w      #0,d2
    move.w      #0,d4
.boundsCheckY
    cmpi        #PLAYER_BOUNDARY_MAX_Y,d1
    bge         .boundsHighY
    cmpi        #PLAYER_BOUNDARY_MIN_Y,d1
    ble         .boundsLowY
    bra         .boundsCheckOver
.boundsHighY
    move.w      #PLAYER_BOUNDARY_MAX_Y,d1
    move.w      #0,d3
    move.w      #0,d5
    bra         .boundsCheckOver
.boundsLowY
    move.w      #PLAYER_BOUNDARY_MIN_Y,d1
    move.w      #0,d3
    move.w      #0,d5
.boundsCheckOver
    rts

; moves the player according to the directions of the joystick
; @params: a4 - address of the joystick instance to update
; @params: a6 - address of the player instance to update
move_player_with_joystick:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
                                                                    ; move player stats into data registers
    move.w      actor.x(a6),d0                                     ; d0 = x
    move.w      actor.y(a6),d1                                     ; d1 = y
    move.w      actor.subpixel_x(a6),d2                            ; d2 = subpixel_x
    move.w      actor.subpixel_y(a6),d3                            ; d3 = subpixel_y
    move.w      actor.velocity_x(a6),d4                            ; d4 = velocity_x
    move.w      actor.velocity_y(a6),d5                            ; d5 = velocity_y

    move.w      joystick.up(a4),d6
    btst        #0,d6
    beq         .no_up
    bsr         player_jump
.no_up:
    move.w      joystick.down(a4),d6
    btst        #0,d6
    beq         .no_down
    ;add.w       #1,d1
.no_down:
    ;move.w      joystick.left(a4),d6
    ;btst        #0,d6
    ;beq         .no_left
    ;sub.w       #1,d0
.no_left:
    ; left and right handled by adjust X Velocity function
    bsr         adjustXVelocity
.no_right:

.end_joystick_check:
    ; save the velocities
    move.w      d4,actor.velocity_x(a6)
    move.w      d5,actor.velocity_y(a6)

    ;bsr         set_player_position
    
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; should be called by move_player_with_joystick
; makes the player jump when the button is pressed
; checks for valid states before doing so
; @params: a4 - address of the joystick instance to check
; @params: a6 - address of the player instance to update
player_jump:
    ; check if player is airborne
    cmp         #PLAYER_MOVEMENT_STATE_AIRBORNE,actor.movement_state(a6)
    beq         .SkipJump
    ; if not, add a large negative velocity
    move.w      #PLAYER_JUMP_VELOCITY_INIT,d5
    ; and set state to airborne
    move.w      #PLAYER_MOVEMENT_STATE_AIRBORNE,actor.movement_state(a6)
.SkipJump:
    rts

; should be called by move_player_with_joystick
; @params: a4 - address of the joystick instance to update
; @params: a6 - address of the player instance to update
adjustXVelocity:
    move.w      actor.velocity_x(a6),d4                            ; d4 = velocity_x

    ; if increasing, then increase velocity, otherwise decay it
    move.w      joystick.right(a4),d6
    cmpi.w      #1,d6                                               ; test if joystick is held to right
    beq         .SlideUpXVel                                        ; slide up XVel
    move.w      joystick.left(a4),d6                                ; otherwise if held to the left
    cmpi.w      #1,d6
    beq         .SlideDownXVel                                      ; slide down it
    bra         .DecayXVel                                          ; if not, decay the X Velocity
.SlideUpXVel
    cmpi        #PLAYER_MAXVELOCITY_X,d4                            ; check if x velocity is >= max
    bge         .XVelPosCheckDone                                   ; skip if it is
    addq        #PLAYER_ACCELERATION,d4                             ; otherwise increase by acceleration
    bra         .XVelPosCheckDone
.SlideDownXVel
    cmpi        #-PLAYER_MAXVELOCITY_X,d4
    ble         .XVelPosCheckDone
    subq        #PLAYER_ACCELERATION,d4
    bra         .XVelPosCheckDone
.DecayXVel
    tst         d4                                                  ; if XVel is 0 nothing more to do
    beq         .XVelPosCheckDone
    blt         .DecayUp                                            ; if < 0 then decay speed up
    bgt         .DecayDown                                          ; if > 0 then decay speed down
    ; check if current velocity is negative
.DecayUp
    addq        #PLAYER_ACCELERATION,d4
    bra         .XVelPosCheckDone
.DecayDown
    subq        #PLAYER_DECELERATION,d4                             ; reduce by deceleration
.XVelPosCheckDone

    ; save the velocities
    move.w      d4,actor.velocity_x(a6)
    rts


; does all the animation updating for a player
; TODO: Do frame swapping with lookup tables and the like
; @params: a6 - address of the player instance to update
updateAnimation:
; check for animation swap
    move.w      actor.velocity_x(a6),d4                            ; d4 = velocity_x
    move.w      actor.current_frame(a6),d6                         ; d6 = current anim frame
    move.w      actor.anim_timer(a6),d7                            ; d7 = current frame timer

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
    move.w      actor.anim_delay(a6),d7                            ; reset the timer
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

; function called whenever the worldspace screen is scrolled, used to anchor actors in the same plane
; @params: d0.w - X amount of screen scrolled, before negation
; @params: d1.w - Y amount of screen scrolled, before negation
player_screen_scrolled:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    
    neg         d0                                                  ; make the actor movement opposite of camera movement
    neg         d1

    lea         pl_instance1,a6
    add.w       d0,actor.x(a6)
    add.w       d1,actor.y(a6)

    lea         pl_instance2,a6
    add.w       d0,actor.x(a6)
    add.w       d1,actor.y(a6)
    movem.l     (sp)+,d0-a6                                         ; restore registers onto the stack
    rts