;---------- Includes ----------
            INCDIR      "include"
            INCLUDE     "hw.i"
;---------- Constants ---------
ENEMY_WIDTH                     equ 32                       ; width in pixels
ENEMY_WIDTH_B                   equ (ENEMY_WIDTH/8)          ; width in bytes
ENEMY_HEIGHT                    equ 32                       ; height in pixels
ENEMY_STARTING_POSX             equ 120                      ; starting position
ENEMY_STARTING_POSY             equ 32
ENEMY_MAXVELOCITY_X             equ 48                       ; default max speed in subpixel/frame
ENEMY_MAXVELOCITY_Y             equ 48
ENEMY_SUBPIXEL_PER_PIXEL        equ 16                       ; how many subpixels are in each pixel
ENEMY_ACCELERATION              equ 1                        ; in subpixels per frame
ENEMY_DECELERATION              equ 1
ENEMY_JUMP_VELOCITY_INIT        equ -30                      ; initial velocity to apply to character when jumping
ENEMY_BOUNDARY_MIN_X            equ 16
ENEMY_BOUNDARY_MAX_X            equ (0+DISPLAY_WIDTH-ENEMY_WIDTH)               
ENEMY_BOUNDARY_MIN_Y            equ 0
ENEMY_BOUNDARY_MAX_Y            equ (VIEWPORT_HEIGHT-ENEMY_HEIGHT)
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
                        dc.w    32,32,96,96                                 ;
                        dc.w    ENEMY_STATE_ACTIVE                          ;
                        dc.w    ENEMY_MOVEMENT_STATE_NORMAL                 ;
                        dc.w    ENEMY_MAX_ANIM_DELAY                        ;
                        dc.w    ENEMY_MAX_ANIM_DELAY                        ;
                        dc.w    ENEMY_INV_STATE_DURATION                    ;
                        dc.w    ENEMY_FLASH_DURATION                        ;
                        dc.w    1                                           ;
                        dc.w    0                                           ;
                        dc.w    BASE_FIRE_INTERVAL                          ;
                        dc.w    BULLET_TYPE_BASE                            ;

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
    bsr         process_actor_movement
    bsr         updateAnimation
    bsr         draw_actor

    movem.l     (sp)+,d0-a6 
    rts