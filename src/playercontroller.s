;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------
PLAYER_WIDTH                    equ 32                      ; width in pixels
PLAYER_WIDTH_B                  equ (PLAYER_WIDTH/8)        ; width in bytes
PLAYER_HEIGHT                   equ 32                      ; height in pixels
PLAYER_STARTING_POSX            equ 16                      ; starting position
PLAYER_STARTING_POSY            equ 96
PLAYER_MAXVELOCITY_X            equ 32*FRAMEMULTIPLIER      ; default max speed in subpixel/frame
PLAYER_MAXVELOCITY_Y            equ 32*FRAMEMULTIPLIER
PLAYER_ACCELERATION             equ 1*FRAMEMULTIPLIER       ; in subpixels per frame
PLAYER_DECELERATION             equ 1*FRAMEMULTIPLIER
PLAYER_JUMP_VELOCITY_INIT       equ -64                     ; initial velocity to apply to character when jumping
PLAYER_JUMP_DECELERATE_TIME     equ 24/FRAMEMULTIPLIER      ; amount of frames that jump button can be held to limit the deceleration
SCREEN_BOUNDARY_MIN_X           equ 1
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
PLAYER_STARTING_HEALTH          equ 100

; player states:
; - active: accepts input, can collide with enemies
; - hit: the player has been hit, collisions are disabled
; - invincible: the player is now invulnerable for a short time

PLAYER_MAX_ANIM_DELAY           equ 10/FRAMEMULTIPLIER      ; delay between two animation frames (in frames)
PLAYER_INV_STATE_DURATION       equ (50*5)/FRAMEMULTIPLIER  ; duration of the invincible state (in frames)
PLAYER_RESPAWN_DURATION         equ (50*5)/FRAMEMULTIPLIER
PLAYER_FLASH_DURATION           equ 3                       ; flashing duration (in frames)

BASE_FIRE_INTERVAL              equ 75/FRAMEMULTIPLIER       ; delay between two shots for base bullets
BULLET_TYPE_BASE                equ 0                       ; types of bullets

;----------- Variables --------
; player instances
pl_instance1            dcb.b   actor.length
pl_instance2            dcb.b   actor.length

;---------- Subroutines -------
    SECTION CODE

PlayerControllerStart:
    lea         pl_instance1,a6
    bsr         InitialisePlayer
    move.l      #joystick1_instance,actor.controller_addr(a6)       ; assign joystick 1 to player 1
    ;bsr         SpawnPlayer                                        ; leave the spawning to when the menu is complete
    lea         pl_instance2,a6
    bsr         InitialisePlayer
    move.l      #joystick2_instance,actor.controller_addr(a6)       ; assign joystick 2 to player 2
    ;bsr         SpawnPlayer
    rts

    ; spawns the players based on the player count set by the menu
SpawnPlayers:
.OnePlayerOnly
    lea         pl_instance2,a6
    bsr         SpawnPlayer
    move.w      #48,actor.x(a6)                                     ; offset it a little
    cmpi        #2,current_player_count
    beq         .BothPlayers
    rts
.BothPlayers
    lea         pl_instance1,a6
    bsr         SpawnPlayer
    ;           set player two graphics here
    move.l      #player2_gfx,actor.bobdata(a6)                      ;actor.bobdata
    move.l      #player2_gfx_flip,actor.bobdata_flip(a6)            ;actor.bobdata_flip         
    move.l      #player2_mask,actor.mask(a6)                        ;actor.mask
    move.l      #player2_mask_flip,actor.mask_flip(a6)              ;actor.mask_flip  
    rts

; creates a sane starting point for the player actor structure
; @params: a6 - the actor object to initialise as a player
InitialisePlayer:
    move.w      #PLAYER_STARTING_POSX,actor.x(a6)                   ;actor.x               
    move.w      #0,actor.subpixel_x(a6)                             ;actor.subpixel_x      
    move.w      #PLAYER_STARTING_POSY,actor.y(a6)                   ;actor.y               
    move.w      #0,actor.subpixel_y(a6)                             ;actor.subpixel_y      
    move.w      #0,actor.velocity_x(a6)                             ;actor.velocity_x      
    move.w      #0,actor.velocity_y(a6)                             ;actor.velocity_y
    move.w      #0,actor.direction(a6)                              ;actor.direction      
    move.l      #player1_gfx,actor.bobdata(a6)                      ;actor.bobdata
    move.l      #player1_gfx_flip,actor.bobdata_flip(a6)            ;actor.bobdata_flip         
    move.l      #player1_mask,actor.mask(a6)                        ;actor.mask
    move.l      #player1_mask_flip,actor.mask_flip(a6)              ;actor.mask_flip            
    move.w      #0,actor.current_frame(a6)                          ;actor.current_frame   
    move.w      #PLAYER_ANIM_IDLE,actor.current_anim(a6)            ;actor.current_anim    
    move.w      #1,actor.respectsBounds(a6)                         ;actor.respectsBounds  
    move.w      #PLAYER_WIDTH,actor.width(a6)                       ;actor.width           
    move.w      #PLAYER_HEIGHT,actor.height(a6)                     ;actor.height
    move.w      #0,actor.x_middle(a6)                               ;actor.x_middle
    move.w      #0,actor.y_middle(a6)                               ;actor.y_middle          
    move.w      #PLAYER_SPRITESHEET_WIDTH,actor.spritesheetwidth(a6);actor.spritesheetwidth
    move.w      #PLAYER_SPRITESHEET_HEIGHT,actor.spritesheetheight(a6);actor.spritesheetheight
    move.w      #ACTOR_STATE_INACTIVE,actor.state(a6)               ;actor.state           
    move.w      #PLAYER_MOVEMENT_STATE_AIRBORNE,actor.movement_state(a6);actor.movement_state  
    move.w      #PLAYER_MAX_ANIM_DELAY,actor.anim_delay(a6)         ;actor.anim_delay      
    move.w      #PLAYER_MAX_ANIM_DELAY,actor.anim_timer(a6)         ;actor.anim_timer      
    move.w      #PLAYER_INV_STATE_DURATION,actor.inv_timer(a6)      ;actor.inv_timer
    move.w      #0,actor.respawn_timer(a6)                          ;actor.respawn_timer       
    move.w      #PLAYER_FLASH_DURATION,actor.flash_timer(a6)        ;actor.flash_timer     
    move.w      #0,actor.visible(a6)                                ;actor.visible
    move.w      #1,actor.gravity(a6)                                ;actor.gravity         
    move.w      #ACTOR_TYPE_PLAYER,actor.type(a6)                   ;actor.type
    move.w      #PLAYER_STARTING_HEALTH,actor.health(a6)            ;actor.health
    move.w      #0,actor.jump_decel_timer(a6)                       ;actor.jump_decel_timer
    move.w      #0,actor.fire_timer(a6)                             ;actor.fire_timer      
    move.w      #BASE_FIRE_INTERVAL,actor.fire_delay(a6)            ;actor.fire_delay      
    move.w      #BULLET_TYPE_BASE,actor.fire_type(a6)               ;actor.fire_type       
    move.l      #0,actor.controller_addr(a6)                        ;actor.controller_addr 
    move.l      #0,actor.sprite_addr(a6)                            ;sprite_addr 
    rts

; actually spawns the dang player
; @params: a6 - player actor to spawn
SpawnPlayer:

    bsr         DecreaseLives
    cmpi        #0,d1                                               ; check the return register
    beq         .Failure
    
.Success
    movem.l     d0-a6,-(sp)
    lea         PLAYERSPAWNSAMPLE,a6
    move.w      #PLAYERSPAWNSAMPLE_LEN/2,d0
    move.w      0,d1
    bsr         PlaySampleOnChannel
    movem.l     (sp)+,d0-a6

    move.w      #PLAYER_STARTING_POSX,d0
    move.w      #PLAYER_STARTING_POSY,d1
    move.w      #PLAYER_STARTING_POSX,actor.x(a6)                   ;actor.x               
    move.w      #0,actor.subpixel_x(a6)                             ;actor.subpixel_x      
    move.w      #PLAYER_STARTING_POSY,actor.y(a6)                   ;actor.y               
    move.w      #0,actor.subpixel_y(a6)                             ;actor.subpixel_y
    move.w      #1,actor.direction(a6)                              ;actor.direction      
    move.w      #0,actor.velocity_x(a6)                             ;actor.velocity_x      
    move.w      #0,actor.velocity_y(a6)                             ;actor.velocity_          
    move.w      #0,actor.current_frame(a6)                          ;actor.current_frame 
    move.w      actor.width(a6),d2
    move.w      actor.height(a6),d3
    lsr.w       d2                                                  ; divide width and height by 2
    lsr.w       d3
    add.w       d2,d0
    add.w       d3,d1
    move.w      d0,actor.x_middle(a6)                               ;actor.x_middle
    move.w      d1,actor.y_middle(a6)                               ;actor.y_middle  
    move.w      #PLAYER_ANIM_IDLE,actor.current_anim(a6)            ;actor.current_anim
    move.w      #ACTOR_STATE_ACTIVE,actor.state(a6)                 ;actor.state           
    move.w      #PLAYER_MOVEMENT_STATE_AIRBORNE,actor.movement_state(a6);actor.movement_state     
    move.w      #PLAYER_MAX_ANIM_DELAY,actor.anim_timer(a6)         ;actor.anim_timer      
    move.w      #PLAYER_INV_STATE_DURATION,actor.inv_timer(a6)      ;actor.inv_timer
    move.w      #0,actor.respawn_timer(a6)                          ;actor.respawn_timer       
    move.w      #PLAYER_FLASH_DURATION,actor.flash_timer(a6)        ;actor.flash_timer    
    move.w      #1,actor.visible(a6)                                ;actor.visible 
    move.w      #PLAYER_STARTING_HEALTH,actor.health(a6)            ;actor.health
    move.w      #0,actor.jump_decel_timer(a6)                       ;actor.jump_decel_timer
    move.w      #0,actor.fire_timer(a6)                             ;actor.fire_timer

    bsr         DrawHUD

    rts
.Failure
    move.w      #ACTOR_STATE_INACTIVE,actor.state(a6)               ;actor.state    
    move.w      #0,actor.visible(a6)                                ;actor.visible 
    bsr         CheckForGameOver
    rts

UpdatePlayers:
    ; update and draw player 1
.UpdatePlayer1
    lea         joystick1_instance,a4
    lea         pl_instance1,a6
    cmpi        #ACTOR_STATE_INACTIVE,actor.state(a6)
    beq         .UpdatePlayer2
    bsr         MovePlayerWithJoystick
    bsr         ProcessActorMovement
    bsr         UpdateAnimation
    bsr         UpdateFireTimer
    bsr         UpdateInvulnerableTimer
    bsr         UpdateRespawnTimer
    ; update and draw player 2
.UpdatePlayer2
    lea         joystick2_instance,a4
    lea         pl_instance2,a6
    cmpi        #ACTOR_STATE_INACTIVE,actor.state(a6)
    beq         .return
    bsr         MovePlayerWithJoystick
    bsr         ProcessActorMovement
    bsr         UpdateAnimation
    bsr         UpdateFireTimer
    bsr         UpdateInvulnerableTimer
    bsr         UpdateRespawnTimer

.return
    rts

DrawPlayers:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
.DrawPlayer1:
    lea         pl_instance1,a6
    cmpi        #1,actor.visible(a6)
    bne         .DrawPlayer2
    bsr         DrawActor
.DrawPlayer2:
    lea         pl_instance2,a6
    cmpi        #1,actor.visible(a6)
    bne         .EndOffunc
    bsr         DrawActor
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

; check to see if the player is dead, if they are, decrement the timer and respawn the player
UpdateRespawnTimer:
    cmpi        #ACTOR_STATE_DEAD,actor.state(a6)
    bne         .SkipFunction
    subi        #1,actor.respawn_timer(a6)
    cmpi        #0,actor.respawn_timer(a6)
    beq         .RespawnPlayer
    bra         .SkipFunction
.RespawnPlayer
    bsr         SpawnPlayer
.SkipFunction
    rts

; checks all the timers and conditons needed to fire a projectile
; @params: a6 - address of the player instance firing a projectile
FireProjectile:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    cmpi.w      #0,actor.fire_timer(a6)
    bne         .cantFire                                           ; if anything left in the fire timer, we can't shoot yet

    move.w      actor.y(a6),d1
    addi.w      #16,d1
    move.w      actor.x(a6),d0
    cmpi.w      #0,actor.direction(a6)
    bne         .ShootingRight
.ShootingLeft:
    move.w      #-48*FRAMEMULTIPLIER,d2
    bra         .ContinueFiring
.ShootingRight:
    addi.w      #16,d0
    move.w      #48*FRAMEMULTIPLIER,d2
.ContinueFiring:
    move.w      #0,d3
    move.w      #0,d4
    move.l      a6,a0                                               ; save actor reference
    bsr         SpawnProjectile
    move.l      a6,d6                                               ; store return address for testing if successful
    move.l      a0,a6                                               ; restore actor reference
    move.w      actor.fire_delay(a6),actor.fire_timer(a6)           ; set the fire cooldown timer
    cmpi.l      #0,d6
    beq         .cantFire                                           ; if d6 = $0, then spawn failed
    ; play a fire sound if spawning successful
.PlayFiresound
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
MovePlayerWithJoystick:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    ; move player stats into data registers
    move.w      actor.x(a6),d0                                      ; d0 = x
    move.w      actor.y(a6),d1                                      ; d1 = y
    move.w      actor.subpixel_x(a6),d2                             ; d2 = subpixel_x
    move.w      actor.subpixel_y(a6),d3                             ; d3 = subpixel_y
    move.w      actor.velocity_x(a6),d4                             ; d4 = velocity_x
    move.w      actor.velocity_y(a6),d5                             ; d5 = velocity_y

    move.w      actor.state(a6),d6
    cmpi        #ACTOR_STATE_ACTIVE,actor.state(a6)                 ; only proceed with letting player control if player is active
    bne         .end_joystick_check

    move.w      joystick.up(a4),d6
    btst        #0,d6
    beq         .no_up
    bsr         PlayerJump
.no_up:
    move.w      joystick.down(a4),d6
    btst        #0,d6
    beq         .no_down
.no_down:
.no_left:
.no_right:

.button_check:
    move.w      joystick.button1(a4),d6
    btst        #0,d6
    beq         .no_button
    bsr         FireProjectile
.no_button:

.end_joystick_check:
    ; run the velocity updates
    ; left and right handled by adjust X Velocity function
    bsr         AdjustXVelocityPlayer
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
PlayerJump:
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
    lea         PLAYERJUMPSAMPLE,a6
    move.w      #PLAYERJUMPSAMPLE_LEN/2,d0
    move.w      0,d1
    bsr         PlaySampleOnChannel
    movem.l     (sp)+,d0-a6
.SkipJump:
    rts

; should be called by move_player_with_joystick
; @params: a4 - address of the joystick instance to update
; @params: a6 - address of the player instance to update
; @clobbers: d4,d5,d6
AdjustXVelocityPlayer:
    move.w      actor.velocity_x(a6),d4                            ; d4 = velocity_x
    ; check if the player is allowed to make inputs, otherwise assume no input
    cmpi        #ACTOR_STATE_ACTIVE,actor.state(a6)
    bne         .DecayXVel

.ProcessInput:
    ; if moving, then increase velocity, otherwise decay it
    move.w      joystick.right(a4),d6
    cmpi.w      #1,d6                                               ; test if joystick is held to right
    beq         .SlideUpXVel                                        ; slide up XVel
    move.w      joystick.left(a4),d6
    cmpi.w      #1,d6                                               ; otherwise if held to the left
    beq         .SlideDownXVel                                      ; slide down it
    bra         .DecayXVel                                          ; if not, decay the X Velocity
.SlideUpXVel:
    cmpi        #PLAYER_MAXVELOCITY_X,d4                            ; check if x velocity is >= max
    bge         .XVelPosCheckDone                                   ; skip if it is
    addq        #PLAYER_ACCELERATION,d4                             ; otherwise increase by acceleration
    bra         .XVelPosCheckDone
.SlideDownXVel:
    cmpi        #-PLAYER_MAXVELOCITY_X,d4
    ble         .XVelPosCheckDone
    subq        #PLAYER_ACCELERATION,d4
    bra         .XVelPosCheckDone
.DecayXVel:
    tst         d4                                                  ; if XVel is 0 nothing more to do
    beq         .XVelPosCheckDone
    blt         .DecayUp                                            ; if < 0 then decay speed up
    bgt         .DecayDown                                          ; if > 0 then decay speed down
    ; check if current velocity is negative
.DecayUp:
    addq        #PLAYER_ACCELERATION,d4
    bra         .XVelPosCheckDone
.DecayDown:
    subq        #PLAYER_DECELERATION,d4                             ; reduce by deceleration
.XVelPosCheckDone:

    ; save the velocities
    move.w      d4,actor.velocity_x(a6)
    rts

; function called whenever the worldspace screen is scrolled, used to anchor actors in the same plane
; @params: d0.w - X amount of screen scrolled, before negation
; @params: d1.w - Y amount of screen scrolled, before negation
PlayerScreenScrolled:
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
