;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

;-------- Data Structures -----
                            rsreset
joystick.up             rs.w 1
joystick.down           rs.w 1
joystick.left           rs.w 1
joystick.right          rs.w 1
joystick.button1        rs.w 1
joystick.button2        rs.w 1
joystick.length         rs.b 0
; add CD32 buttons later?
;----------- Variables --------
joystick1_instance      dc.w 0,0,0,0,0,0
joystick2_instance      dc.w 0,0,0,0,0,0

current_keyboard_key    dc.b 0 ; last key pressed on the keyboard
    even
;---------- Subroutines -------
    SECTION CODE

ControllerManagerStart:
; Checks if left mouse button, joystick button or keyboard enter is pressed
; @clobbers a0, a1, d1
; @returns d0: 1 if any confirm buttons are pressed
IsConfirmPressed:
    move.w      #0,d0                   ; clear the return register
.checkMouseButton:
    btst        #6,CIAAPRA              ; left mouse button pressed?
    bne         .checkJoystickButton    ; if not skip to joystick

    move.w      #1,d0                   ; otherwise, set return and rts
    rts
.checkJoystickButton
    btst        #7,CIAAPRA              ; check if button pressed
    bne         .checkKeyboardEnter     ; if not skip to keyboard
    
    move.w      #1,d0                   ; otherwise, set return and rts
    rts
.checkKeyboardEnter
    ; TODO: need keyboard handling routine
.endFunc:
    rts

; Updates both joysticks and their respective registers
JoystickUpdate:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack

    ; make sure we have the custom chip address in at
    lea         CUSTOM,a5
    bsr         UpdateJoystick1 ;EXPECTING MOUSE TODO: FIX
    bsr         UpdateJoystick2 ;EXPECTING JOYSTICK TODO: FIX

    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

UpdateJoystick1:

    ; grab the address of the first joystick
    lea         joystick1_instance,a6
    ; place the joystick data in d0
    move.w      JOY0DAT(a5),d0
    move.w      d0,d1
    lsr.w       #1,d1
    and.w       #$0101,d1
    eor.w       d1,d0

    ; clear the data from the joystick to make sure we have fresh data
    move.w      #0,joystick.up(a6)
    move.w      #0,joystick.down(a6)
    move.w      #0,joystick.left(a6)
    move.w      #0,joystick.right(a6)
    move.w      #0,joystick.button1(a6)
    move.w      #0,joystick.button2(a6)

    ; check the data vertically
    btst        #0,d0
    beq.s       .no_down
    move.w      #1,joystick.down(a6)
.no_down:
    btst        #8,d0
    beq.s       .no_up
    move.w      #1,joystick.up(a6)
.no_up:

    ; horizontal movement
    btst        #1,d0
    beq.s       .no_right
    move.w      #1,joystick.right(a6)
.no_right:
    btst        #9,d0
    beq.s       .no_left
    move.w      #1,joystick.left(a6)
.no_left:

    ; check fire button
    btst        #6,CIAAPRA
    bne.s       .no_fire
    move.w      #1,joystick.button1(a6)
.no_fire:

    rts

UpdateJoystick2:

    ; grab the address of the first joystick
    lea         joystick2_instance,a6
    ; place the joystick data in d0
    move.w      JOY1DAT(a5),d0
    move.w      d0,d1
    lsr.w       #1,d1
    and.w       #$0101,d1
    eor.w       d1,d0

    ; clear the data from the joystick to make sure we have fresh data
    move.w      #0,joystick.up(a6)
    move.w      #0,joystick.down(a6)
    move.w      #0,joystick.left(a6)
    move.w      #0,joystick.right(a6)
    move.w      #0,joystick.button1(a6)
    move.w      #0,joystick.button2(a6)

    ; check the data vertically
    btst        #0,d0
    beq.s       .no_down
    move.w      #1,joystick.down(a6)
.no_down:
    btst        #8,d0
    beq.s       .no_up
    move.w      #1,joystick.up(a6)
.no_up:

    ; horizontal movement
    btst        #1,d0
    beq.s       .no_right
    move.w      #1,joystick.right(a6)
.no_right:
    btst        #9,d0
    beq.s       .no_left
    move.w      #1,joystick.left(a6)
.no_left:

    ; check fire button
    btst        #7,CIAAPRA
    bne.s       .no_fire
    move.w      #1,joystick.button1(a6)
.no_fire:

    rts

; Checks if right mouse button/joystick button 2 is pressed
; @clobbers a0, a1, d1
; @returns d0: 1 if any right mouse button is pressed
CheckRightMouseButton:
    ; TODO: this needs to be made more robust
    move.w      #0,d0                   ; clear the return register
    ;btst        #10,$dff016             ; check port 1 mouse button, remember that POTGOR is 1 = no input
    bne.s       .endFunc                ; if not, skip to port 2 mouse button

    move.w      #1,d0                   ; otherwise, set return and rts
.endFunc
    rts