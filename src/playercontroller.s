;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------
PLAYER_WIDTH                    equ 32                      ; width in pixels
PLAYER_WIDTH_B                  equ (PLAYER_WIDTH/8)        ; width in bytes
PLAYER_HEIGHT                   equ 32                      ; height in pixels
PLAYER_STARTING_POSX            equ 16                      ; starting position
PLAYER_STARTING_POSY            equ 81
PLAYER_MAXVELOCITY_X            equ 48                      ; default max speed in subpixel/frame
PLAYER_MAXVELOCITY_Y            equ 48
PLAYER_SUBPIXEL_PER_PIXEL       equ 16                      ; how many subpixels are in each pixel
PLAYER_ACCELERATION             equ 1                       ; in subpixels per frame
PLAYER_DECELERATION             equ 1
PLAYER_BOUNDARY_MIN_X           equ 16
PLAYER_BOUNDARY_MAX_X           equ (0+DISPLAY_WIDTH-PLAYER_WIDTH)               
PLAYER_BOUNDARY_MIN_Y           equ 0
PLAYER_BOUNDARY_MAX_Y           equ (VIEWPORT_HEIGHT-PLAYER_HEIGHT)
PLAYER_ANIM_IDLE                equ 1
PLAYER_ANIM_UP                  equ 0
PLAYER_ANIM_DOWN                equ 2
PLAYER_ANIM_EXPL                equ 3
PLAYER_FRAME_SIZE               equ (PLAYER_WIDTH_B*PLAYER_HEIGHT)
PLAYER_MASK_SIZE                equ (PLAYER_WIDTH_B*PLAYER_HEIGHT)
PLAYER_SPRITESHEET_WIDTH        equ 96
PLAYER_SPRITESHEET_HEIGHT       equ 32
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
player.subpixel_x       rs.w        1                       ; subpixel position
player.y                rs.w        1
player.subpixel_y       rs.w        1
player.velocity_x       rs.w        1                       ; x velocity in subpixels/f
player.velocity_y       rs.w        1                       ; y velocity in subpixels/f
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
pl_instance1            dc.w    PLAYER_STARTING_POSX,0,PLAYER_STARTING_POSY,0;
                        dc.w    0,0                                         ;
                        dc.l    player_gfx                                  ;
                        dc.l    player_mask                                 ;
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
pl_instance2            dc.w    64,0,PLAYER_STARTING_POSY,0   ;
                        dc.w    0,0         ;
                        dc.l    player_gfx                                  ;
                        dc.l    player_mask                                 ;
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
    bsr         process_player_movement
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

; hard sets the player position, resetting the subpixel count in the process
; @params: d0 - new x position of player
; @params: d1 - new y position of player
; @params: a6 - address of the player instance to update
set_player_position:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    move.w      d0,player.x(a6)
    move.w      d1,player.y(a6)
    move.w      #0,player.subpixel_x(a6)
    move.w      #0,player.subpixel_y(a6)
    
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; applies the current velocities to the player position
; @params: a6 - address of the player instance to update
process_player_movement:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    move.w      player.x(a6),d0                                     ; d0 = x
    move.w      player.y(a6),d1                                     ; d1 = y
    move.w      player.subpixel_x(a6),d2                            ; d2 = subpixel_x
    move.w      player.subpixel_y(a6),d3                            ; d3 = subpixel_y
    move.w      player.velocity_x(a6),d4                            ; d4 = velocity_x
    move.w      player.velocity_y(a6),d5                            ; d5 = velocity_y

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
    ; if subpixel > PLAYER_SUBPIXEL_PER_PIXEL then adjust the full count 
    cmpi.w      #PLAYER_SUBPIXEL_PER_PIXEL,d2
    bge         .spilloverXHigh
    bra         .checkYVelocity                                     ; otherwise we're done
.XNegative
    add.w       d4,d2
    cmpi.w      #0,d2
    blt         .spilloverXLow
    bra         .checkYVelocity
.spilloverXHigh:
    ; run the loop to add pixels until subpixel's back below threshold
    addq        #1,d0                                               ; increment full pixel count
    subi        #PLAYER_SUBPIXEL_PER_PIXEL,d2                                              ; reduce subpixel count by a full pixel
    cmpi.w      #PLAYER_SUBPIXEL_PER_PIXEL,d2                       ; check if there's more pixels to process
    bge         .spilloverXHigh                                     ; loop
    bra         .checkYVelocity                                     ; otherwise we're done
.spilloverXLow:
    ; run the loop to remove pixels until subpixel's back below threshold
    subq        #1,d0
    addi        #PLAYER_SUBPIXEL_PER_PIXEL,d2
    cmpi.w      #0,d2
    blt         .spilloverXLow
    bra         .checkYVelocity

.checkYVelocity:
    tst         d5
    bne         .applyYVelocity
    bra         .boundsCheck
.applyYVelocity:
    ; YVelocity is a TODO:

.boundsCheck:
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
    move.w      #PLAYER_BOUNDARY_MAX_Y,d0
    move.w      #0,d3
    move.w      #0,d5
    bra         .boundsCheckOver
.boundsLowY
    move.w      #PLAYER_BOUNDARY_MIN_Y,d0
    move.w      #0,d3
    move.w      #0,d5
.boundsCheckOver

.EndOfFunc:
    ; apply all the updates
    move.w      d0,player.x(a6)                                     ; move the final stats back into memory
    move.w      d1,player.y(a6)
    move.w      d2,player.subpixel_x(a6)
    move.w      d3,player.subpixel_y(a6)
    move.w      d4,player.velocity_x(a6)
    move.w      d5,player.velocity_y(a6)
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; moves the player according to the directions of the joystick
; @params: a4 - address of the joystick instance to update
; @params: a6 - address of the player instance to update
move_player_with_joystick:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
                                                                    ; move player stats into data registers
    move.w      player.x(a6),d0                                     ; d0 = x
    move.w      player.y(a6),d1                                     ; d1 = y
    move.w      player.subpixel_x(a6),d2                            ; d2 = subpixel_x
    move.w      player.subpixel_y(a6),d3                            ; d3 = subpixel_y
    move.w      player.velocity_x(a6),d4                            ; d4 = velocity_x
    move.w      player.velocity_y(a6),d5                            ; d5 = velocity_y

    move.w      joystick.up(a4),d6
    btst        #0,d6
    beq         .no_up
    sub.w       #1,d1
.no_up:
    move.w      joystick.down(a4),d6
    btst        #0,d6
    beq         .no_down
    add.w       #1,d1
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
    move.w      d4,player.velocity_x(a6)
    move.w      d5,player.velocity_y(a6)

    ;bsr         set_player_position
    
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; ONLY TO BE CALLED FROM move_player_with_joystick
adjustXVelocity:
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

    rts