;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

;---------- Subroutines -------
    SECTION CODE

controllerroutinesstart:
; Checks if left mouse button, joystick button or keyboard enter is pressed
; @clobbers a0, a1, d1
; @returns d0: 1 if any confirm buttons are pressed
isConfirmPressed:
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

; Checks if right mouse button/joystick button 2 is pressed
; @clobbers a0, a1, d1
; @returns d0: 1 if any right mouse button is pressed
checkRightMouseButton:
    ; TODO: this needs to be made more robust
    move.w      #0,d0                   ; clear the return register
    btst        #10,$dff016             ; check port 1 mouse button, remember that POTGOR is 1 = no input
    bne.s       .endFunc                ; if not, skip to port 2 mouse button

    move.w      #1,d0                   ; otherwise, set return and rts
.endFunc
    rts