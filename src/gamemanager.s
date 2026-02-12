;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------
INITIAL_WAVE_TIMER      equ         60                      ; time between scrolling stopping and first enemy wave spawning

;-------- Data Structures -----
; gamestate struct which holds most variables related to the gamestate
                        rsreset
gamestate.curr_point    rs.w        1                       ; the index of the current waypoint we're on
gamestate.waypointarray rs.l        1                       ; address of the beginning of the waypoint array
gamestate.size_of_array rs.w        1                       ; how many waypoints there are to load
gamestate.length        rs.b        0

                        rsreset
waypoint.x_pos          rs.w        1                       ; position of the waypoint
waypoint.triggered      rs.w        1                       ; flag to show if the waypoint has already been triggered or not
waypoint.respawn_delay  rs.w        1                       ; gap between enemy spawns (in frames)
waypoint.wave_delay     rs.w        1                       ; gap between enemy waves (in frames)
waypoint.wave_amount    rs.w        1                       ; amount of enemies in a wave
waypoint.num_of_waves   rs.w        1                       ; how many waves we're spawning
waypoint.length         rs.b        0
; spawn points on the map will be tiles in the background, for now just make them camera space 300

;----------- Variables --------
gamestate_array         dc.w        0                       ; gamestate.curr_point
                        dc.l        testwaypoint            ; gamestate.waypointarray
                        dc.w        2                       ; gamestate.size_of_array

testwaypoint            dc.w        30                      ; waypoint.x_pos
                        dc.w        0                       ; waypoint.triggered
                        dc.w        60                      ; waypoint.respawn_delay
                        dc.w        180                     ; waypoint.wave_timer
                        dc.w        1                       ; waypoint.wave_amount
                        dc.w        1                       ; waypoint.num_of_waves

testwaypoint2           dc.w        60                      ; waypoint.x_pos
                        dc.w        0                       ; waypoint.triggered
                        dc.w        60                      ; waypoint.respawn_delay
                        dc.w        180                     ; waypoint.wave_timer
                        dc.w        2                       ; waypoint.wave_amount
                        dc.w        2                       ; waypoint.num_of_waves

screen_scroll_allowed   ds.w        1                       ; bool flag for if the screen scroll is paused or not
current_respawn_timer   ds.w        1                       ; amount of frames left until next respawn
current_respawn_counter ds.w        1                       ; amount of enemies left to spawn in the wave
current_wave_timer      ds.w        1                       ; amount of frames left until next wave
current_wave_number     ds.w        1                       ; number of waves of enemies to spawn
current_waypoint_addr   ds.l        1                       ; pointer to the current waypoint

;---------- Subroutines -------
    SECTION CODE

GameManagerStart:
    ; initialise the game state and set up all the defaults
    lea         gamestate_array,a6
    move.w      #1,screen_scroll_allowed
    move.w      #0,current_respawn_timer
    move.w      #0,current_respawn_counter
    move.w      #0,current_wave_timer
    move.w      #0,current_wave_number
    move.l      gamestate.waypointarray(a6),a4
    move.l      a4,current_waypoint_addr

    rts

UpdateGameManager:
    lea         gamestate_array,a6
    bsr         WaypointCheck
    rts

; function that handles everything related to enemy spawn checkpoints
; @params: a6 - current game state object
; @clobbers: d0,a4
WaypointCheck:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    ; first, check the array to see if we've hit the end
    move.w      gamestate.curr_point(a6),d0
    cmp         gamestate.size_of_array(a6),d0
    beq         .OutOfWaypoints
    ; there's still some array to go
    move.l      (current_waypoint_addr),a4
    ; check to see if we already have a waypoint active
    cmpi        #1,waypoint.triggered(a4)
    beq         .WaypointActive
    ; check the array to figure out when the next waypoint is
    ; check the current screen scroll position to see if we've hit a waypoint
    move.w      map_ptr,d0
    cmp         waypoint.x_pos(a4),d0
    bgt         .WaypointReached
    bra         .SkipFunc
.WaypointReached
    ; when hitting a waypoint, stop the scrolling and set enemy wave timer to a small amount
    move.w      #0,screen_scroll_allowed
    move.w      #1,waypoint.triggered(a4)
    move.w      #INITIAL_WAVE_TIMER,current_wave_timer
    move.w      waypoint.num_of_waves(a4),current_wave_number
.WaypointActive
    ; wait for wave timer to hit zero
    cmpi        #0,current_wave_timer
    beq         .WaveTimerComplete
    subi        #1,current_wave_timer
    bra         .SkipFunc
.WaveTimerComplete
    ; check if the respawn timer is active
    cmpi        #0,current_respawn_timer
    bgt         .RespawnCountdown
    ; when wave timer is zero, start a spawning round
    move.w      waypoint.respawn_delay(a4),current_respawn_timer
    ; set the respawn counter to the amount asked for
    move.w      waypoint.wave_amount(a4),current_respawn_counter

.RespawnCountdown
    cmpi        #1,current_respawn_timer
    beq         .RespawnTimerComplete
    subi        #1,current_respawn_timer
    bra         .SkipFunc
.RespawnTimerComplete
    cmpi        #0,current_respawn_counter
    beq         .RespawnRoundFinished
    ; spawn an enemy, set the respawn timer to the respawn delay amount
    move.w      #300,d0
    move.w      #120,d1
    move.l      a6,a0
    bsr         SpawnEnemy
    move.l      a0,a6
    move.w      waypoint.respawn_delay(a4),current_respawn_timer
    subi        #1,current_respawn_counter
    bra         .SkipFunc
.RespawnRoundFinished
    ; Wait until all enemies are deadge
    bsr         GetNumberOfEnemiesSpawned
    cmpi        #0,d7
    bgt         .SkipFunc
    ; set respawn timer to zero, so the wave timer kicks in again
    move.w      #0,current_respawn_timer
    ; reset the wave timer
    move.w      waypoint.wave_delay(a4),current_wave_timer
    ; continue until wave is at zero, start a new wave with the wave delay timer
    subi        #1,current_wave_number
    bgt         .SkipFunc
    ; if we're out of waves, then we're done, move onto next waypoint
    bsr         IndexWaypointArray
    move.w      #1,screen_scroll_allowed
.SkipFunc
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts
.OutOfWaypoints
    move.w      #1,screen_scroll_allowed
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

; indexes the pointer in the array to the next address
; @clobbers: d0,a6
IndexWaypointArray:
    lea         gamestate_array,a6
    move.l      #waypoint.length,d0
    add.l       d0,current_waypoint_addr
    addi        #1,gamestate.curr_point(a6)
    rts