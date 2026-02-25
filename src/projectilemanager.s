;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

PROJECTILE_WIDTH                EQU 16
PROJECTILE_HEIGHT               EQU 16
PROJECTILE_SPRITESHEET_W        EQU 16
PROJECTILE_SPRITESHEET_H        EQU 16

PROJECTILE_STARTING_DAMAGE      EQU 5
PROJECTILE_MAX_COUNT            EQU 8

;----------- Variables --------
projectile_array        dcb.b actor.length
                        dcb.b actor.length
                        dcb.b actor.length
                        dcb.b actor.length
                        dcb.b actor.length
                        dcb.b actor.length
                        dcb.b actor.length
                        dcb.b actor.length

;---------- Subroutines -------
    SECTION CODE

ProjectileManagerStart:
    ; declare and initialise the full projectile pool
    bsr         InitialiseProjectilePool
    rts

UpdateProjectileManager:
    movem.l     d0-a6,-(sp)
    ; iterate through every projectile being managed
    ; update any that require it
    lea         projectile_array,a6
    move.w      #PROJECTILE_MAX_COUNT-1,d7
.loopStart:
    cmp         #ACTOR_STATE_INACTIVE,actor.state(a6)
    beq         .loopEnd
    bsr         UpdateProjectile
.loopEnd:
    adda        #actor.length,a6
    dbra        d7,.loopStart

    movem.l     (sp)+,d0-a6
    rts

; runs all logic for the projectile actors
; @params: a6 - address of the projectile to be updated
UpdateProjectile:
    bsr         ProcessActorMovement
    ; TODO: testing hitting enemies
    move.w      #ACTOR_TYPE_ENEMY,d0
    bsr         FindEntityCollidedWith
    cmpi        #1,d6
    beq         .EnemyHit
    bra         .DespawnCheck
.EnemyHit:
    move.w      actor.health(a6),d0                                 ; place the "health" (damage) of the projectile into d0
    ; save reference to a6 to call despawn
    move.l      a6,a0
    move.l      a4,a6
    ; actually apply damage to the other entity
    bsr         HitActor
    move.l      a0,a6
    bsr         DespawnActor
.DespawnCheck:
    ; TODO: remove this and make projectiles detect properly
    cmpi        #300,actor.x(a6)
    bge         DespawnActor
    cmpi        #0,actor.x(a6)
    blt         DespawnActor
    ; doesn't push return address to the stack, so anything here is ignored for now
    rts

DrawProjectiles:
    movem.l     d0-a6,-(sp)
    ; iterate through the array and draw them all
    lea         projectile_array,a6
    move.w      #PROJECTILE_MAX_COUNT-1,d7                               ; off by one
.loopStart:
    cmpi        #0,actor.visible(a6)
    beq         .hideProjectile
    move.l      actor.sprite_addr(a6),a1
    move.w      actor.y(a6),d0
    move.w      actor.x(a6),d1
    move.w      #PROJECTILE_HEIGHT,d2
    bsr         SetSpritePosition
    bra         .loopEnd
.hideProjectile
    move.l      actor.sprite_addr(a6),a1
    bsr         HideSprite
.loopEnd:
    adda        #actor.length,a6
    dbra        d7,.loopStart                                       ; repeat number of times for every projectile

    movem.l     (sp)+,d0-a6
    rts

CollisionProjectileCheck:
    rts

InitialiseProjectilePool:
    ; iterate through the array and set everything up
    lea         projectile_array,a6
    lea         projectile1_spr,a1
    move.w      #PROJECTILE_MAX_COUNT-1,d0                          ; off by one
.loop:
    bsr         InitialiseProjectile
    move.l      a1,actor.sprite_addr(a6)
    adda        #actor.length,a6
    adda        #$48,a1                                             ; next sprite pointer
    dbra        d0,.loop                                            ; repeat number of times for every projectile

    rts

; bring all values back to sane and empty/default values
; @params: a6 - address of the projectile to initialise
; @return: a6 - end of the projectile array
InitialiseProjectile:
    move.w      #0,actor.x(a6)                                      ;actor.x               
    move.w      #0,actor.subpixel_x(a6)                             ;actor.subpixel_x      
    move.w      #0,actor.y(a6)                                      ;actor.y               
    move.w      #0,actor.subpixel_y(a6)                             ;actor.subpixel_y
    move.w      #0,actor.direction(a6)                              ;actor.direction         
    move.w      #0,actor.velocity_x(a6)                             ;actor.velocity_x      
    move.w      #0,actor.velocity_y(a6)                             ;actor.velocity_y      
    move.l      #0,actor.bobdata(a6)                                ;actor.bobdata         
    move.l      #0,actor.mask(a6)                                   ;actor.mask            
    move.w      #0,actor.current_frame(a6)                          ;actor.current_frame   
    move.w      #0,actor.current_anim(a6)                           ;actor.current_anim    
    move.w      #0,actor.respectsBounds(a6)                         ;actor.respectsBounds  
    move.w      #PROJECTILE_WIDTH,actor.width(a6)                   ;actor.width           
    move.w      #PROJECTILE_HEIGHT,actor.height(a6)                 ;actor.height         
    move.w      #0,actor.x_middle(a6)                               ;actor.x_middle
    move.w      #0,actor.y_middle(a6)                               ;actor.y_middle
    move.w      #PROJECTILE_SPRITESHEET_W,actor.spritesheetwidth(a6);actor.spritesheetwidth
    move.w      #PROJECTILE_SPRITESHEET_H,actor.spritesheetheight(a6);actor.spritesheetheight
    move.w      #ACTOR_STATE_INACTIVE,actor.state(a6)               ;actor.state           
    move.w      #0,actor.movement_state(a6)                         ;actor.movement_state  
    move.w      #0,actor.anim_delay(a6)                             ;actor.anim_delay      
    move.w      #0,actor.anim_timer(a6)                             ;actor.anim_timer      
    move.w      #0,actor.inv_timer(a6)                              ;actor.inv_timer       
    move.w      #0,actor.flash_timer(a6)                            ;actor.flash_timer     
    move.w      #0,actor.visible(a6)                                ;actor.visible
    move.w      #0,actor.gravity(a6)                                ;actor.gravity         
    move.w      #ACTOR_TYPE_PROJECTILE,actor.type(a6)               ;actor.type 
    move.w      #PROJECTILE_STARTING_DAMAGE,actor.health(a6)        ;actor.health        
    move.w      #0,actor.jump_decel_timer(a6)                       ;actor.jump_decel_timer
    move.w      #0,actor.fire_timer(a6)                             ;actor.fire_timer      
    move.w      #0,actor.fire_delay(a6)                             ;actor.fire_delay      
    move.w      #0,actor.fire_type(a6)                              ;actor.fire_type       
    move.l      #0,actor.controller_addr(a6)                        ;actor.controller_addr 
    move.l      #0,actor.sprite_addr(a6)                            ;sprite_addr 

    rts

; iterates through the array and returns the first free instance
; very useful for spawning
; @returns: a6 - address of actor that's marked as inactive, returns 0 if none found
; @clobbers: d7
FindNextFreeProjectile:
    lea         projectile_array,a6
    move.w      #PROJECTILE_MAX_COUNT-1,d7                               ; off by one
.loopStart:
    cmpi        #ACTOR_STATE_INACTIVE,actor.state(a6)
    beq         .actorFound
    adda        #actor.length,a6
    dbra        d7,.loopStart
.actorNotfound:
    move.l      #0,a6
.actorFound:
    rts

; function for creating a projectile with a set type and initial position/velocity
; @params: d0.w - x position
; @params: d1.w - y position
; @params: d2.w - x velocity
; @params: d3.w - y velocity
; @params: d4.w - projectile type
; @returns: a6 - address of actor spawn, or 0.l if spawn failed
SpawnProjectile:
    bsr         FindNextFreeProjectile
    move.l      a6,d7
    cmpi.l      #0,d7
    beq         .spawnFailed
.spawnSuccess:
    move.w      d0,actor.x(a6)                                          ;actor.x               
    move.w      #0,actor.subpixel_x(a6)                                 ;actor.subpixel_x      
    move.w      d1,actor.y(a6)                                          ;actor.y               
    move.w      #0,actor.subpixel_y(a6)                                 ;actor.subpixel_y      
    move.w      d2,actor.velocity_x(a6)                                 ;actor.velocity_x      
    move.w      d3,actor.velocity_y(a6)                                 ;actor.velocity_y      
    move.w      #0,actor.current_frame(a6)                              ;actor.current_frame   
    move.w      #0,actor.current_anim(a6)                               ;actor.current_anim
    move.w      actor.width(a6),d2
    move.w      actor.height(a6),d3
    lsr.w       d2                                                      ; divide width and height by 2
    lsr.w       d3
    add.w       d2,d0
    add.w       d3,d1
    move.w      d0,actor.x_middle(a6)                                   ;actor.x_middle
    move.w      d1,actor.y_middle(a6)                                   ;actor.y_middle
    move.w      #ACTOR_STATE_ACTIVE,actor.state(a6)                     ;actor.state           
    move.w      #ENEMY_MOVEMENT_STATE_NORMAL,actor.movement_state(a6)   ;actor.movement_state   
    move.w      #ENEMY_MAX_ANIM_DELAY,actor.anim_timer(a6)              ;actor.anim_timer     
    move.w      #1,actor.visible(a6)                                    ;actor.visible         
    move.w      #0,actor.jump_decel_timer(a6)                           ;actor.jump_decel_timer
    move.w      #0,actor.fire_timer(a6)                                 ;actor.fire_timer
    move.w      d4,actor.fire_type(a6)                                  ;actor.fire_type       
.spawnFailed:   
    rts