;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

;---------- Subroutines -------

;----------- Variables --------

    SECTION CODE

; channel 0 & 3 left side
; channel 1 & 2 right side
; volume is between 1-64
; minimum period is 123 - PAL, 124 - NTSC
soundmanagerstart:
    rts

enableallchannels:
    move.w      #$8001,DMACON           ; enable channel 0
    move.w      #$8008,DMACON           ; enable channel 3
    move.w      #$8003,DMACON           ; enable channel 0 and 1
    ; DMA play sample data in an infinite loop until the channel is disable from DMACON
    move.w      #$01,DMACON             ; disable channel 0
    rts


; starts the DMA for playing data at the address specified
; @param: a6 - address of the sample to be played
; @param: d0 - length of the sample to be played
; @param: d1 - bitmask of channels to play the sound on
PlaySampleOnChannel:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    ;TODO: Finish this
    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

PlayTestSound:
    movem.l     d0-a6,-(sp)                                         ; copy registers onto the stack
    lea         CUSTOM,a5
    move.l      #SINE,AUD0LC(a5)
    move.w      #(SINE_END-SINE)/2,AUD0LEN(a5)
    move.w      #339,AUD0PER(a5)
    move.w      #32,AUD0VOL(a5)
                 ;fedcba9876543210
    move.w      #%1000001000000001,DMACON(a5)

.empty_sample:
    move.l      #EMPTY_SAMPLE,AUD0LC(a5)
    move.l      #(EMPTY_SAMPLE_LENGTH-EMPTY_SAMPLE)/2,AUD0LEN

    movem.l     (sp)+,d0-a6                                         ; restore the registers off of the stack
    rts

StopAllSounds:
    lea         CUSTOM,a5
    move.w      #$0007,DMACON(a5)              ; turn off all channels
    rts

    SECTION AUDIO, DATA_C

    CNOP        0,2                     ; align data in a word boundary

TRIANGLE:
    DC.B        0, 20, 40, 60, 80, 100, 80, 60, 40, 20
    DC.B        0,-20,-40,-60,-80,-100,-80,-60,-40,-20
TRIANGLE_END

SINE:
    DC.B        0, 39, 75, 103, 121, 127, 121, 103, 75, 39
    DC.B        0,-39,-75,-103,-121,-127,-121,-103,-75,-39
SINE_END

SQUARE:
    DC.B        100, 100, 100, 100, 100, 100, 100, 100, 100
    DC.B        -100,-100,-100,-100,-100,-100,-100,-100,-100
SQUARE_END

EMPTY_SAMPLE:
    dcb.w       1
EMPTY_SAMPLE_LENGTH

RAZORMIND:
    ;DC.B        
RAZORMIND_END: