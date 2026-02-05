;---------- Includes ----------
              INCDIR        "include"
              INCLUDE       "hw.i"

    SECTION CODE

main:
    bsr         init
    
    move.w      camera_x,d0
    lsr.w       #4,d0
    move.w      d0,map_ptr
    bsr         init_background
    move.w      #16,bgnd_x

    ; play the test sound to make sure these functions are working
    lea         TESTSAMPLE,a6
    move.w      #TESTSAMPLE_LEN/2,d0
    move.w      0,d1
    bsr         PlaySampleOnChannel
    bsr         EnemyManagerStart
    bsr         ProjectileManagerStart

    ; DEBUG: hard set all enemies to be active
    lea         enemy_array,a6
    move.w      #ACTOR_STATE_ACTIVE,actor.state(a6)
    move.w      #254,actor.x(a6)
    move.w      #1,actor.anim_timer(a6)
    adda        #actor.length,a6
    move.w      #ACTOR_STATE_ACTIVE,actor.state(a6)
    move.w      #144,actor.x(a6)
    move.w      #3,actor.anim_timer(a6)
    adda        #actor.length,a6
    move.w      #ACTOR_STATE_ACTIVE,actor.state(a6)
    move.w      #220,actor.x(a6)
    move.w      #6,actor.anim_timer(a6)
    adda        #actor.length,a6
    move.w      #ACTOR_STATE_ACTIVE,actor.state(a6)
    move.w      #166,actor.x(a6)
    move.w      #9,actor.anim_timer(a6)
    adda        #actor.length,a6
    move.w      #ACTOR_STATE_ACTIVE,actor.state(a6)

mainloop:
    bsr         wait_vblank
    bsr         swap_buffers
    bsr         update_background

    ; updated controllers
    bsr         joystick_update

    ; run major updates
    bsr         UpdateProjectileManager
    bsr         update_players
    bsr         UpdateEnemies

;    bsr         isConfirmPressed        ; is confirm pressed?
    lea         joystick1_instance,a6
    move.w      joystick.button1(a6),d0
    btst        #0,d0

;    bsr         StopAllSounds
    beq         mainloop
    bsr         mainloop                ; DEBUG, don't quit the game when debugging

    bsr         shutdown
    rts

init:
    bsr         take_system
    bsr         load_palette
    bsr         init_bplpointers
    rts
    
shutdown:
    bsr         release_system
    rts

    INCLUDE         "controllerroutines.s"
    INCLUDE         "drawingroutines.s"
    INCLUDE         "systemroutines.s"
    INCLUDE         "levelhandler.s"
    INCLUDE         "playercontroller.s"
    INCLUDE         "projectilemanager.s"
    INCLUDE         "enemymanager.s"
    INCLUDE         "soundmanager.s"
