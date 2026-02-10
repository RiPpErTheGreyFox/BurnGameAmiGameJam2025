;---------- Includes ----------
            INCDIR      "include"
            INCLUDE     "hw.i"
;---------- Constants ---------
ENEMY_MAX_COUNT                 equ 5                       ; size of the pool of enemies

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
ENEMY_MAX_ANIM_DELAY            equ 10                      ; delay between two animation frames (in frames)
ENEMY_INV_STATE_DURATION        equ (50*5)                  ; duration of the invincible state (in frames)
ENEMY_FLASH_DURATION            equ 3                       ; flashing duration (in frames)
;-------- Data Structures -----

;----------- Variables --------
; enemy instances
enemy_array             dcb.b   actor.length
                        dcb.b   actor.length
                        dcb.b   actor.length
                        dcb.b   actor.length
                        dcb.b   actor.length

;---------- Subroutines -------
    SECTION CODE

EnemyManagerStart:
    ; declare and initialise the full enemy pool
    bsr         InitialiseEnemyPool
    ; setup the spawning rules based on the level
    rts

UpdateEnemies:
    movem.l     d0-a6,-(sp)
    ; iterate through the array and run the updates of them all
    lea         enemy_array,a6
    move.w      #ENEMY_MAX_COUNT-1,d0                               ; off by one
.loopStart:
    cmpi        #ACTOR_STATE_INACTIVE,actor.state(a6)
    beq         .loopEnd
    bsr         ProcessEnemyAI
    bsr         CheckEnemyPlayerCollision
    bsr         process_actor_movement
    bsr         updateAnimation
.loopEnd:
    adda        #actor.length,a6
    dbra        d0,.loopStart                                       ; repeat number of times for every projectile

    movem.l     (sp)+,d0-a6
    rts

DrawEnemies:
    movem.l     d0-a6,-(sp)
    ; iterate through the array and draw them all
    lea         enemy_array,a6
    move.w      #ENEMY_MAX_COUNT-1,d0                               ; off by one
.loopStart:
    cmpi        #0,actor.visible(a6)
    beq         .loopEnd
    bsr         draw_actor
.loopEnd:
    adda        #actor.length,a6
    dbra        d0,.loopStart                                       ; repeat number of times for every projectile

    movem.l     (sp)+,d0-a6
    rts

; function which contains the enemies decision making
; very simple for, now, walk left and respawn when hitting wall
; @params: a6 - address of the actor instance to update
ProcessEnemyAI:
    movem.l     d0-a6,-(sp)
    ; check if we've hit the left wall
    cmpi        #16,actor.x(a6)
    ble         .respawnEnemy
    bra         .keepgoingleft
.respawnEnemy
    move.w      #SCREEN_BOUNDARY_MAX_X-ENEMY_WIDTH,d0
    move.w      #ENEMY_STARTING_POSY,d1
    bsr         set_actor_position

.keepgoingleft:
    ; if so, respawn, otherwise keep going left
    ; using a variant of adjustXVelocity
    move.w      #-1,d0
    bsr         AdjustXVelocityEnemy

    movem.l     (sp)+,d0-a6 
    rts

; function which checks to see if enemies have run into players or not
; @params: a6 - current enemy doing the checks
CheckEnemyPlayerCollision:
    movem.l     d0-a6,-(sp)
    move.w      #ACTOR_TYPE_PLAYER,d0
    bsr         FindEntityCollidedWith
    cmpi        #1,d6
    beq         .PlayerHit
    movem.l     (sp)+,d0-a6 
    rts
.PlayerHit
    ; call the players "is hit" function
    bsr         PlayerHit
    movem.l     (sp)+,d0-a6 
    rts

; should be called by enemy_ai_process
; @params: d0 - -1 = moving left, 0 = no input, 1 = moving right
; @params: a6 - address of the actor instance to update
AdjustXVelocityEnemy:
    move.w      actor.velocity_x(a6),d4                             ; d4 = velocity_x
    cmpi        #ACTOR_STATE_ACTIVE,actor.state(a6)
    bne         .DecayXVel

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
EnemyScreenScrolled:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    neg         d0                                                  ; make the actor movement opposite of camera movement
    neg         d1
    move.w      #ENEMY_MAX_COUNT-1,d3
    lea         enemy_array,a6
.loopStart:
    cmpi        #ACTOR_STATE_INACTIVE,actor.state(a6)
    beq         .loopEnd
    add.w       d0,actor.x(a6)
    add.w       d1,actor.y(a6)
.loopEnd:
    adda        #actor.length,a6
    dbra        d3,.loopStart
    movem.l     (sp)+,d0-a6                                         ; restore registers onto the stack
    rts


InitialiseEnemyPool:
    ; iterate through the array and set everything up
    lea         enemy_array,a6
    move.w      #ENEMY_MAX_COUNT-1,d0                          ; off by one
.loop:
    bsr         InitialiseEnemy
    adda        #actor.length,a6
    dbra        d0,.loop
    rts

; bring all values back to sane and empty/default values
; @params: a6 - address of the enemy to initialise
InitialiseEnemy:
    move.w      #ENEMY_STARTING_POSX,actor.x(a6)                    ;actor.x               
    move.w      #0,actor.subpixel_x(a6)                             ;actor.subpixel_x      
    move.w      #ENEMY_STARTING_POSY,actor.y(a6)                    ;actor.y               
    move.w      #0,actor.subpixel_y(a6)                             ;actor.subpixel_y      
    move.w      #0,actor.velocity_x(a6)                             ;actor.velocity_x      
    move.w      #0,actor.velocity_y(a6)                             ;actor.velocity_y      
    move.l      #enemy_gfx,actor.bobdata(a6)                        ;actor.bobdata         
    move.l      #enemy_mask,actor.mask(a6)                          ;actor.mask            
    move.w      #0,actor.current_frame(a6)                          ;actor.current_frame   
    move.w      #ENEMY_ANIM_IDLE,actor.current_anim(a6)             ;actor.current_anim    
    move.w      #0,actor.respectsBounds(a6)                         ;actor.respectsBounds  
    move.w      #ENEMY_WIDTH,actor.width(a6)                        ;actor.width           
    move.w      #ENEMY_HEIGHT,actor.height(a6)                      ;actor.height          
    move.w      #ENEMY_SPRITESHEET_WIDTH,actor.spritesheetwidth(a6) ;actor.spritesheetwidth
    move.w      #ENEMY_SPRITESHEET_HEIGHT,actor.spritesheetheight(a6);actor.spritesheetheight
    move.w      #ACTOR_STATE_INACTIVE,actor.state(a6)               ;actor.state           
    move.w      #ENEMY_MOVEMENT_STATE_NORMAL,actor.movement_state(a6);actor.movement_state  
    move.w      #ENEMY_MAX_ANIM_DELAY,actor.anim_delay(a6)          ;actor.anim_delay      
    move.w      #ENEMY_MAX_ANIM_DELAY,actor.anim_timer(a6)          ;actor.anim_timer      
    move.w      #ENEMY_INV_STATE_DURATION,actor.inv_timer(a6)       ;actor.inv_timer       
    move.w      #ENEMY_FLASH_DURATION,actor.flash_timer(a6)         ;actor.flash_timer     
    move.w      #0,actor.visible(a6)                                ;actor.visible
    move.w      #1,actor.gravity(a6)                                ;actor.gravity         
    move.w      #0,actor.jump_decel_timer(a6)                       ;actor.jump_decel_timer
    move.w      #0,actor.fire_timer(a6)                             ;actor.fire_timer      
    move.w      #BASE_FIRE_INTERVAL,actor.fire_delay(a6)            ;actor.fire_delay      
    move.w      #BULLET_TYPE_BASE,actor.fire_type(a6)               ;actor.fire_type       
    move.l      #0,actor.controller_addr(a6)                        ;actor.controller_addr 

    rts

; iterates through the array and returns the first free instance
; very useful for spawning
; @returns: a6 - address of actor that's marked as inactive, returns 0 if none found
; @clobbers: d7
FindNextFreeEnemy:
    lea         enemy_array,a6
    move.w      #ENEMY_MAX_COUNT-1,d7                               ; off by one
.loopStart:
    cmpi        #ACTOR_STATE_INACTIVE,actor.state(a6)
    beq         .actorFound
    adda        #actor.length,a6
    dbra        d7,.loopStart
.actorNotfound:
    move.l      #0,a6
.actorFound:
    rts

; attempts to spawn an enemy with the desired location, will add more stuff later to it, AI needs updating
; @params: d0.w - x position
; @params: d1.w - y position
; @clobbers: d2.l
; @returns: a6 - address of actor spawn, or 0.l if spawn failed
SpawnEnemy:
    bsr         FindNextFreeEnemy
    move.l      a6,d2
    cmpi.l      #0,d2
    beq         .spawnFailed
.spawnSuccess:
    move.w      d0,actor.x(a6)                                          ;actor.x               
    move.w      #0,actor.subpixel_x(a6)                                 ;actor.subpixel_x      
    move.w      d1,actor.y(a6)                                          ;actor.y               
    move.w      #0,actor.subpixel_y(a6)                                 ;actor.subpixel_y      
    move.w      #0,actor.velocity_x(a6)                                 ;actor.velocity_x      
    move.w      #0,actor.velocity_y(a6)                                 ;actor.velocity_y
    bsr         GetRandomNumber
    move.b      prng_number,d2
    andi.w      #%1,d2                                                  ;random number between 0 and 1
    move.w      d2,actor.current_frame(a6)                              ;actor.current_frame   
    move.w      #ENEMY_ANIM_IDLE,actor.current_anim(a6)                 ;actor.current_anim
    move.w      #ACTOR_STATE_ACTIVE,actor.state(a6)                     ;actor.state           
    move.w      #ENEMY_MOVEMENT_STATE_NORMAL,actor.movement_state(a6)   ;actor.movement_state
    ; get a random number for the frame timer
    bsr         GetRandomNumber
    move.b      prng_number,d2
    andi.w      #%111,d2                                                ;random number between 1 and 8
    addq.b      #1,d2  
    move.w      d2,actor.anim_timer(a6)                                 ;actor.anim_timer     
    move.w      #1,actor.visible(a6)                                    ;actor.visible         
    move.w      #0,actor.jump_decel_timer(a6)                           ;actor.jump_decel_timer
    move.w      #0,actor.fire_timer(a6)                                 ;actor.fire_timer      
.spawnFailed:
    rts

; disables the enemy pointed to by the address
; @params: a6 - address of actor to disable
DespawnActor:
    move.w      #ACTOR_STATE_INACTIVE,actor.state(a6)
    move.w      #0,actor.visible(a6)
    rts