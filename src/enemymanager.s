;---------- Includes ----------
            INCDIR      "include"
            INCLUDE     "hw.i"
;---------- Constants ---------
ENEMY_WIDTH                     equ 32                       ; width in pixels
ENEMY_WIDTH_B                   equ (ENEMY_WIDTH/8)          ; width in bytes
ENEMY_HEIGHT                    equ 32                       ; height in pixels
ENEMY_STARTING_POSX             equ 320-ENEMY_WIDTH          ; starting position
ENEMY_STARTING_POSY             equ 141
ENEMY_MAXVELOCITY_X             equ 12                       ; default max speed in subpixel/frame
ENEMY_MAXVELOCITY_Y             equ 48
ENEMY_SUBPIXEL_PER_PIXEL        equ 16                       ; how many subpixels are in each pixel
ENEMY_ACCELERATION              equ 1                        ; in subpixels per frame
ENEMY_DECELERATION              equ 1
ENEMY_JUMP_VELOCITY_INIT        equ -30                      ; initial velocity to apply to character when jumping
ENEMY_MOVEMENT_STATE_NORMAL     equ 0
ENEMY_MOVEMENT_STATE_AIRBORNE   equ 1
ENEMY_ANIM_IDLE                 equ 1
ENEMY_ANIM_WALK                 equ 0
ENEMY_ANIM_JUMP                 equ 2
ENEMY_ANIM_EXPL                 equ 3
ENEMY_MAX_FRAME_COUNT           equ 3                        ; only three frames of animation, static for now
ENEMY_FRAME_SIZE                equ (ENEMY_WIDTH_B*ENEMY_HEIGHT)
ENEMY_MASK_SIZE                 equ (ENEMY_WIDTH_B*ENEMY_HEIGHT)
ENEMY_SPRITESHEET_WIDTH         equ 96
ENEMY_SPRITESHEET_HEIGHT        equ 96
ENEMY_STATE_ACTIVE              equ 0
ENEMY_STATE_HIT                 equ 1
ENEMY_STATE_INVINCIBLE          equ 2
ENEMY_MAX_ANIM_DELAY            equ 10                      ; delay between two animation frames (in frames)
ENEMY_INV_STATE_DURATION       equ (50*5)                  ; duration of the invincible state (in frames)
ENEMY_FLASH_DURATION           equ 3                       ; flashing duration (in frames)
;-------- Data Structures -----

;----------- Variables --------
; enemy instances
enemy_instance1         dc.w    ENEMY_STARTING_POSX,0,ENEMY_STARTING_POSY,0 ;
                        dc.w    0,5                                         ;
                        dc.l    enemy_gfx                                   ;
                        dc.l    enemy_mask                                  ;
                        dc.w    0                                           ;
                        dc.w    ENEMY_ANIM_IDLE                             ;
                        dc.w    0                                           ;
                        dc.w    32,32                                       ;
                        dc.w    96,96                                       ;
                        dc.w    ENEMY_STATE_ACTIVE                          ;
                        dc.w    ENEMY_MOVEMENT_STATE_NORMAL                 ;
                        dc.w    ENEMY_MAX_ANIM_DELAY                        ;
                        dc.w    ENEMY_MAX_ANIM_DELAY                        ;
                        dc.w    ENEMY_INV_STATE_DURATION                    ;
                        dc.w    ENEMY_FLASH_DURATION                        ;
                        dc.w    1                                           ;
                        dc.w    0,0                                         ;
                        dc.w    BASE_FIRE_INTERVAL                          ;
                        dc.w    BULLET_TYPE_BASE                            ;
                        dc.l    0                                           ;

;---------- Subroutines -------
    SECTION CODE

enemymanagerstart:
    ; declare and initialise the full enemy pool
    ; setup the spawning rules based on the level
    rts

initialise_enemy_pool:
    ; iterate through the array and set everything up
    rts

update_enemies:
    movem.l     d0-a6,-(sp)

    ; iterate through the array and run the updates of them all
    lea         enemy_instance1,a6
    bsr         enemy_ai_process
    bsr         process_actor_movement
    bsr         updateAnimation
    bsr         draw_actor

    movem.l     (sp)+,d0-a6 
    rts

; function which contains the enemies decision making
; very simple for, now, walk left and respawn when hitting wall
enemy_ai_process:
    movem.l     d0-a6,-(sp)
    ; check if we've hit the left wall
    cmpi        #16,actor.x(a6)
    ble         .respawnEnemy
    bra         .keepgoingleft
.respawnEnemy
    move.w      #ENEMY_STARTING_POSX,d0
    move.w      #ENEMY_STARTING_POSY,d1
    bsr         set_actor_position

.keepgoingleft:
    ; if so, respawn, otherwise keep going left
    ; using a variant of adjustXVelocity
    move.w      #-1,d0
    bsr         adjustXVelocityEnemy

    movem.l     (sp)+,d0-a6 
    rts

; should be called by enemy_ai_process
; @params: d0 - -1 = moving left, 0 = no input, 1 = moving right
; @params: a6 - address of the player instance to update
adjustXVelocityEnemy:
    move.w      actor.velocity_x(a6),d4                             ; d4 = velocity_x

    ; if increasing, then increase velocity, otherwise decay it
    cmpi.w      #1,d0                                               ; test if AI is going to right
    beq         .SlideUpXVel                                        ; slide up XVel
    cmpi.w      #-1,d0
    beq         .SlideDownXVel                                      ; slide down it
    bra         .DecayXVel                                          ; if not, decay the X Velocity
.SlideUpXVel
    cmpi        #ENEMY_MAXVELOCITY_X,d4                             ; check if x velocity is >= max
    bge         .XVelPosCheckDone                                   ; skip if it is
    addq        #ENEMY_ACCELERATION,d4                              ; otherwise increase by acceleration
    bra         .XVelPosCheckDone
.SlideDownXVel
    cmpi        #-ENEMY_MAXVELOCITY_X,d4
    ble         .XVelPosCheckDone
    subq        #ENEMY_ACCELERATION,d4
    bra         .XVelPosCheckDone
.DecayXVel
    tst         d4                                                  ; if XVel is 0 nothing more to do
    beq         .XVelPosCheckDone
    blt         .DecayUp                                            ; if < 0 then decay speed up
    bgt         .DecayDown                                          ; if > 0 then decay speed down
    ; check if current velocity is negative
.DecayUp
    addq        #ENEMY_ACCELERATION,d4
    bra         .XVelPosCheckDone
.DecayDown
    subq        #ENEMY_DECELERATION,d4                             ; reduce by deceleration
.XVelPosCheckDone

    ; save the velocities
    move.w      d4,actor.velocity_x(a6)
    rts

; function called whenever the worldspace screen is scrolled, used to anchor actors in the same plane
; @params: d0.w - X amount of screen scrolled, before negation
; @params: d1.w - Y amount of screen scrolled, before negation
enemy_screen_scrolled:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    neg         d0                                                  ; make the actor movement opposite of camera movement
    neg         d1
    ; TODO: make this work on the entire enemy array
    lea         enemy_instance1,a6
    add.w       d0,actor.x(a6)
    add.w       d1,actor.y(a6)
    movem.l     (sp)+,d0-a6                                         ; restore registers onto the stack
    rts