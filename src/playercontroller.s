;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------
PLAYER_WIDTH                    equ 32                      ; width in pixels
PLAYER_WIDTH_B                  equ (PLAYER_WIDTH/8)        ; width in bytes
PLAYER_HEIGHT                   equ 32                      ; height in pixels
PLAYER_STARTING_POSX            equ 16                      ; starting position
PLAYER_STARTING_POSY            equ 32
PLAYER_MAXVELOCITY_X            equ 32                      ; default max speed in subpixel/frame
PLAYER_MAXVELOCITY_Y            equ 32
PLAYER_ACCELERATION             equ 1                       ; in subpixels per frame
PLAYER_DECELERATION             equ 1
PLAYER_JUMP_VELOCITY_INIT       equ -64                     ; initial velocity to apply to character when jumping
PLAYER_JUMP_DECELERATE_TIME     equ 24                      ; amount of frames that jump button can be held to limit the deceleration
SCREEN_BOUNDARY_MIN_X           equ 0
SCREEN_BOUNDARY_MAX_X           equ (0+DISPLAY_WIDTH)               
SCREEN_BOUNDARY_MIN_Y           equ 0
SCREEN_BOUNDARY_MAX_Y           equ (VIEWPORT_HEIGHT)
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

; player states:
; - active: accepts input, can collide with enemies
; - hit: the player has been hit, collisions are disabled
; - invincible: the player is now invulnerable for a short time

PLAYER_MAX_ANIM_DELAY           equ 10                      ; delay between two animation frames (in frames)
PLAYER_INV_STATE_DURATION       equ (50*5)                  ; duration of the invincible state (in frames)
PLAYER_FLASH_DURATION           equ 3                       ; flashing duration (in frames)

BASE_FIRE_INTERVAL              equ 7                       ; delay between two shots for base bullets
BULLET_TYPE_BASE                equ 0                       ; types of bullets

;----------- Variables --------
; player instance
pl_instance1            dc.w    PLAYER_STARTING_POSX,0,PLAYER_STARTING_POSY,0;
                        dc.w    0,0                                         ;
                        dc.l    player_gfx                                  ;
                        dc.l    player_mask                                 ;
                        dc.w    0                                           ;
                        dc.w    PLAYER_ANIM_IDLE                            ;
                        dc.w    1                                           ;
                        dc.w    PLAYER_WIDTH,PLAYER_HEIGHT                  ;
                        dc.w    PLAYER_SPRITESHEET_WIDTH,PLAYER_SPRITESHEET_HEIGHT                                 ;
                        dc.w    ACTOR_STATE_INACTIVE                         ;
                        dc.w    PLAYER_MOVEMENT_STATE_NORMAL                ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_INV_STATE_DURATION                   ;
                        dc.w    PLAYER_FLASH_DURATION                       ;
                        dc.w    1,1                                         ;
                        dc.w    ACTOR_TYPE_PLAYER                           ;
                        dc.w    0,0                                         ;
                        dc.w    BASE_FIRE_INTERVAL                          ;
                        dc.w    BULLET_TYPE_BASE                            ;
                        dc.l    joystick1_instance                          ;

                        ; player instance
pl_instance2            dc.w    64,0,PLAYER_STARTING_POSY,0                 ;
                        dc.w    0,0                                         ;
                        dc.l    player_gfx                                  ;
                        dc.l    player_mask                                 ;
                        dc.w    0                                           ;
                        dc.w    PLAYER_ANIM_WALK                            ;
                        dc.w    1                                           ;
                        dc.w    PLAYER_WIDTH,PLAYER_HEIGHT                  ;
                        dc.w    PLAYER_SPRITESHEET_WIDTH,PLAYER_SPRITESHEET_HEIGHT 
                        dc.w    ACTOR_STATE_INACTIVE                         ;
                        dc.w    PLAYER_MOVEMENT_STATE_NORMAL                ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_INV_STATE_DURATION                   ;
                        dc.w    PLAYER_FLASH_DURATION                       ;
                        dc.w    1,1                                         ;
                        dc.w    ACTOR_TYPE_PLAYER                           ;
                        dc.w    0,0                                         ;
                        dc.w    BASE_FIRE_INTERVAL                          ;
                        dc.w    BULLET_TYPE_BASE                            ;
                        dc.l    joystick2_instance                          ;

;---------- Subroutines -------
    SECTION CODE

playercontrollerstart:
    rts

UpdatedPlayers:
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
    bsr         UpdateFireTimer
    bsr         draw_actor

    rts

DrawPlayers:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
.DrawPlayer1:
    lea         pl_instance1,a6
    cmpi        #1,actor.visible(a6)
    bne         .DrawPlayer2
    bsr         draw_actor
.DrawPlayer2:
    lea         pl_instance2,a6
    cmpi        #1,actor.visible(a6)
    bne         .EndOffunc
    bsr         draw_actor
.EndOffunc
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; if there's anything left int he fire_timer, tick it down
; @params: a6 - address of the player instance being updated
UpdateFireTimer:
    cmpi        #0,actor.fire_timer(a6)
    beq         .nothingToDo
    subi        #1,actor.fire_timer(a6)
.nothingToDo:
    rts

; checks all the timers and conditons needed to fire a projectile
; @params: a6 - address of the player instance firing a projectile
FireProjectile:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    cmpi        #0,actor.fire_timer(a6)
    bne         .cantFire                                           ; if anything left in the fire timer, we can't shoot yet

    move.w      actor.x(a6),d0
    addi.w      #16,d0
    move.w      actor.y(a6),d1
    addi.w      #16,d1
    move.w      #48,d2
    move.w      #0,d3
    move.w      #0,d4
    move.l      a6,a0                                               ; save actor reference
    bsr         SpawnProjectile
    move.l      a0,a6                                               ; restore actor reference
    move.w      actor.fire_delay(a6),actor.fire_timer(a6)           ; set the fire cooldown timer
    ; play a fire sound
    lea         TRIANGLE,a6
    move.w      #TRIANGLE_LEN/2,d0
    move.w      0,d1
    bsr         PlaySampleOnChannel
.cantFire
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
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
    bsr         adjustXVelocityPlayer
.no_right:

.button_check:
    move.w      joystick.button1(a4),d6
    btst        #0,d6
    beq         .no_button
    bsr         FireProjectile
.no_button:

.end_joystick_check:
    ; save the velocities
    move.w      d4,actor.velocity_x(a6)
    move.w      d5,actor.velocity_y(a6)
    
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
    ; set the jump decel timer
    move.w      #PLAYER_JUMP_DECELERATE_TIME,actor.jump_decel_timer(a6)
    ; play the jump sound
    movem.l     d0-a6,-(sp)
    lea         JUMPSOUND,a6
    move.w      #JUMPSOUND_LEN/2,d0
    move.w      0,d1
    bsr         PlaySampleOnChannel
    movem.l     (sp)+,d0-a6
.SkipJump:
    rts

; should be called by move_player_with_joystick
; @params: a4 - address of the joystick instance to update
; @params: a6 - address of the player instance to update
adjustXVelocityPlayer:
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