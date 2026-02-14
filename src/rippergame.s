;---------- Includes ----------
              INCDIR        "include"
              INCLUDE       "hw.i"

    SECTION CODE

main:
    bsr         init
    
    move.w      camera_x,d0
    lsr.w       #4,d0
    move.w      d0,map_ptr
    bsr         InitBackground
    move.w      #16,bgnd_x

    ; play the test sound to make sure these functions are working
    lea         TESTSAMPLE,a6
    move.w      #TESTSAMPLE_LEN/2,d0
    move.w      0,d1
    bsr         PlaySampleOnChannel
    bsr         PlayerControllerStart
    bsr         EnemyManagerStart
    bsr         ProjectileManagerStart
    bsr         GameManagerStart

mainloop:
    bsr         WaitVBlank
    bsr         SwapBuffers
    ; run drawing updates
    bsr         UpdateBackground

    ; updated controllers
    bsr         JoystickUpdate

    ; run major updates
    bsr         UpdateGameManager
    bsr         UpdateProjectileManager
    bsr         DrawProjectiles
    bsr         UpdatePlayers
    bsr         DrawPlayers
    bsr         UpdateEnemies
    bsr         DrawEnemies

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
    bsr         TakeSystem
    bsr         LoadPalette
    bsr         InitBPLPointers
    rts
    
shutdown:
    bsr         ReleaseSystem
    rts

    INCLUDE         "actorroutines.s"
    INCLUDE         "controllerroutines.s"
    INCLUDE         "drawingroutines.s"
    INCLUDE         "enemymanager.s"
    INCLUDE         "gamemanager.s"
    INCLUDE         "levelhandler.s"
    INCLUDE         "playercontroller.s"
    INCLUDE         "projectilemanager.s"
    INCLUDE         "soundmanager.s"
    INCLUDE         "systemroutines.s"
