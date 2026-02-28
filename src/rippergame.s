    SECTION CODE,CODE
;    CNOP        0,2                                                     ; align data in a word boundary
main:
    nop
    nop

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
    bsr         DrawHUD

mainloop:
    bsr         WaitVBlank
    IFD         HALFFRAMERATE
    bsr         WaitVBlank
    ENDC
    bsr         SwapBuffers
    ; run drawing updates
    bsr         UpdateBackground
    ; updated controllers
    bsr         JoystickUpdate

    ; run major updates
    bsr         UpdateGameManager
    bsr         UpdateProjectileManager
    bsr         UpdatePlayers
    bsr         UpdateEnemies
    
    bsr         DrawPlayers
    bsr         DrawEnemies
    bsr         DrawProjectiles


    ; quit on Q being pressed
    cmp.b       #$10,current_keyboard_key

;    bsr         StopAllSounds
    bne         mainloop
    ;bsr         mainloop                ; DEBUG, don't quit the game when debugging

    bsr         shutdown
    rts

init:
    bsr         TakeSystem
    bsr         LoadPalette
    bsr         InitBPLPointers
    bsr         InitSpritePointers
    bsr         InitialiseKeyboard
    rts
    
shutdown:
    bsr         ReleaseSystem
    rts
;---------- Includes ----------
            INCDIR          "include"
            INCLUDE         "hw.i"
            INCLUDE         "globals.i"
            INCLUDE         "actorroutines.s"
            INCLUDE         "controllerroutines.s"
            INCLUDE         "drawingroutines.s"
            INCLUDE         "enemymanager.s"
            INCLUDE         "fontmanager.s"
            INCLUDE         "gamemanager.s"
            INCLUDE         "levelhandler.s"
            INCLUDE         "playercontroller.s"
            INCLUDE         "projectilemanager.s"
            INCLUDE         "soundmanager.s"
            INCLUDE         "systemroutines.s"


