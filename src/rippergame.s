    SECTION CODE,CODE
;    CNOP        0,2                                                     ; align data in a word boundary
main:
    nop
    nop

    bsr         init

RestartGame:
    move.w      camera_x,d0
    lsr.w       #4,d0
    move.w      d0,map_ptr
    bsr         InitBackground
    move.w      #16,bgnd_x
    move.w      #0,current_player_count

    bsr         PlayerControllerStart
    bsr         EnemyManagerStart
    bsr         ProjectileManagerStart
    bsr         GameManagerStart
    bsr         DrawHUD

    bsr         PlayerSelectionMenu

mainloop:
    bsr         ReadKeyboard
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

    ; are we in game over?
    cmpi        #1,current_game_is_over
    beq         .GameOver

    ; quit on Q being pressed
    cmp.b       #$10,current_keyboard_key

;    bsr         StopAllSounds
    bne         mainloop
    ;bsr         mainloop                ; DEBUG, don't quit the game when debugging

.GameOver
    bsr         GameOverState
    bsr         shutdown
    rts

init:
    bsr         TakeSystem
    bsr         LoadPalette
    bsr         InitBPLPointers
    bsr         InitSpritePointers
    ;bsr         InitialiseKeyboard
    rts
    
shutdown:
    bsr         ReleaseSystem
    rts

GameOverState:
    lea         game_over_string,a2
    move.w      #16,d3
    move.w      #192+9,d4
    bsr         DrawString

    move.w      #254,d7
.GameOverLoop
    bsr         WaitVBlank
    dbra        d7,.GameOverLoop

    rts

PlayerSelectionMenu:
    ; debug test
    ;bra         .OnePlayer
    ; draw onto the screen the text for player selection
    ; Press 1 for one player mode (joystick in port 2)
    ; Press 2 for two player mode (joysticks in ports 1 and 2)
    lea         player_select_1_str,a2
    move.w      #16,d3
    move.w      #64,d4
    bsr         DrawString

    lea         player_select_1_str2,a2
    move.w      #16,d3
    move.w      #80,d4
    bsr         DrawString

    lea         player_select_2_str,a2
    move.w      #16,d3
    move.w      #112,d4
    bsr         DrawString

    lea         player_select_2_str2,a2
    move.w      #16,d3
    move.w      #128,d4
    bsr         DrawString

.loop
    bsr         ReadKeyboard
    ; draw the screen to keep everything alive
    bsr         WaitVBlank
    ; wait for pressing of 1 or 2
    cmp.b       #$01,current_keyboard_key
    beq         .OnePlayer
    cmp.b       #$1D,current_keyboard_key
    beq         .OnePlayer
    cmp.b       #$02,current_keyboard_key
    beq         .TwoPlayer
    cmp.b       #$1E,current_keyboard_key
    beq         .TwoPlayer
    bra         .loop
.OnePlayer
    ; set variables so spawn players can work appropriately
    move.w      #1,current_player_count
    bra         .SpawnPlayers
.TwoPlayer
    ; set variables so spawn players will now spawn both players
    move.w      #2,current_player_count
.SpawnPlayers
    bsr         ResetLives
    bsr         SpawnPlayers
.return
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


