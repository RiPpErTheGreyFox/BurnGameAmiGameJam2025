;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------
PLAYER_WIDTH                    equ 32                      ; width in pixels
PLAYER_WIDTH_B                  equ (PLAYER_WIDTH/8)        ; width in bytes
PLAYER_HEIGHT                   equ 30                      ; height in pixels
PLAYER_STARTING_POSX            equ 16                      ; starting position
PLAYER_STARTING_POSY            equ 81
PLAYER_VELOCITY_X               equ 2                       ; default speed in pixel/frame
PLAYER_VELOCITY_Y               equ 2
PLAYER_BOUNDARY_MIN_X           equ 32
PLAYER_BOUNDARY_MAX_X           equ (16+DISPLAY_WIDTH-PLAYER_WIDTH)               
PLAYER_BOUNDARY_MIN_Y           equ 0
PLAYER_BOUNDARY_MAX_Y           equ (VIEWPORT_HEIGHT-PLAYER_HEIGHT)
PLAYER_ANIM_IDLE                equ 1
PLAYER_ANIM_UP                  equ 0
PLAYER_ANIM_DOWN                equ 2
PLAYER_ANIM_EXPL                equ 3
PLAYER_FRAME_SIZE               equ (PLAYER_WIDTH_B*PLAYER_HEIGHT)
PLAYER_MASK_SIZE                equ (PLAYER_WIDTH_B*PLAYER_HEIGHT)
PLAYER_SPRITESHEET_WIDTH        equ 96
PLAYER_SPRITESHEET_HEIGHT       equ 30
PLAYER_STATE_ACTIVE             equ 0
PLAYER_STATE_HIT                equ 1
PLAYER_STATE_INVINCIBLE         equ 2
; player states:
; - active: accepts input, can collide with enemies
; - hit: the player has been hit, collisions are disabled
; - invincible: the player is now invulnerable for a short time

PLAYER_MAX_ANIM_DELAY           equ 4                       ; delay between two animation frames (in frames)
PLAYER_INV_STATE_DURATION       equ (50*5)                  ; duration of the invincible state (in frames)
PLAYER_FLASH_DURATION           equ 3                       ; flashing duration (in frames)

BASE_FIRE_INTERVAL              equ 7                       ; delay between two shots for base bullets
BULLET_TYPE_BASE                equ 0                       ; types of bullets

;-------- Data Structures -----
                        rsreset
player.x                rs.w        1                       ; position
player.y                rs.w        1
player.velx             rs.w        1                       ; x velocity
player.vely             rs.w        1                       ; y velocity
player.bobdata          rs.l        1                       ; address of graphics data
player.mask             rs.l        1                       ; address of graphics mask
player.current_frame    rs.w        1                       ; current animation frame
player.state            rs.w        1                       ; current state
player.anim_delay       rs.w        1                       ; delay between two animation frames
player.inv_timer        rs.w        1                       ; timer for invulnerable state
player.flash_timer      rs.w        1                       ; timer for flashing
player.visible          rs.w        1                       ; visibility flag: 1 visible, 0 not
player.fire_timer       rs.w        1                       ; timer to implement a delay between subsequent shots
player.fire_delay       rs.w        1                       ; delay between two shots (in frames)
player.fire_type        rs.w        1                       ; type of fire
player.length           rs.b        0


;----------- Variables --------
; player instance
pl_instance1            dc.w    PLAYER_STARTING_POSX,PLAYER_STARTING_POSY   ;
                        dc.w    PLAYER_VELOCITY_X,PLAYER_VELOCITY_Y         ;
                        dc.l    ship_gfx                                    ;
                        dc.l    ship_mask                                   ;
                        dc.w    PLAYER_ANIM_IDLE                            ;
                        dc.w    PLAYER_STATE_ACTIVE                         ;
                        dc.w    PLAYER_MAX_ANIM_DELAY                       ;
                        dc.w    PLAYER_INV_STATE_DURATION                   ;
                        dc.w    PLAYER_FLASH_DURATION                       ;
                        dc.w    1                                           ;
                        dc.w    0                                           ;
                        dc.w    BASE_FIRE_INTERVAL                          ;
                        dc.w    BULLET_TYPE_BASE                            ;

                        ; player instance
pl_instance2            dc.w    64,PLAYER_STARTING_POSY   ;
                        dc.w    PLAYER_VELOCITY_X,PLAYER_VELOCITY_Y         ;
                        dc.l    ship_gfx                                    ;
                        dc.l    ship_mask                                   ;
                        dc.w    PLAYER_ANIM_UP                              ;
                        dc.w    PLAYER_STATE_ACTIVE                         ;
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
    bsr         draw_player
    ; update and draw player 2
    lea         joystick2_instance,a4
    lea         pl_instance2,a6
    bsr         move_player_with_joystick
    bsr         draw_player

    rts

; draws the player using their current data
; @params: a6 - address of the player instance to draw
draw_player:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    tst.w       player.visible(a6)                                  ; player is visible?
    beq         .return                                             ; 
    move.l      player.bobdata(a6),a0                               ; player's image address
    move.l      player.mask(a6),a1                                  ; player's mask address
    move.l      draw_buffer,a2                                      ; destination video buffer address
    move.w      player.x(a6),d0                                     ; x position of the player in pixels
    move.w      player.y(a6),d1                                     ; y position of the player in pixels
    move.w      #PLAYER_WIDTH,d2                                    ; player width in pixels
    move.w      #PLAYER_HEIGHT,d3                                   ; player height in pixels
    move.w      player.current_frame(a6),d4                         ; spritesheet column of player
    move.w      #0,d5                                               ; spritesheet row of player
    move.w      #PLAYER_SPRITESHEET_WIDTH,a3                        ; spritesheet width
    move.w      #PLAYER_SPRITESHEET_HEIGHT,a4                       ; spritesheet height

    bsr draw_bob
.return:
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; @params: d0 - new x position of player
; @params: d1 - new y position of player
; @params: a6 - address of the player instance to update
set_player_position:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    move.w      d0,player.x(a6)
    move.w      d1,player.y(a6)
    
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; moves the player according to the directions of the joystick
; @params: a4 - address of the joystick instance to update
; @params: a6 - address of the player instance to update
move_player_with_joystick:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    move.w      player.x(a6),d0
    move.w      player.y(a6),d1

    move.w      joystick.up(a4),d2
    btst        #0,d2
    beq         .no_up
    sub.w       #1,d1
.no_up:
    move.w      joystick.down(a4),d2
    btst        #0,d2
    beq         .no_down
    add.w       #1,d1
.no_down:
    move.w      joystick.left(a4),d2
    btst        #0,d2
    beq         .no_left
    sub.w       #1,d0
.no_left:
    move.w      joystick.right(a4),d2
    btst        #0,d2
    beq         .no_right
    add.w       #1,d0
.no_right:

    bsr         set_player_position
    
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts