;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

                 ;5432109876543210
DMASET       EQU %1000001010000000     ; enable only copper DMA

    SECTION CODE
savecopperlist:
    move.l      gfx_base,a6
    move.l      $26(a6),old_cop
    rts    
setdefaultcopperlist:
    lea         CUSTOM,a5
    move.w      #DMASET,DMACON(a5)
    move.l      #copperlist,$dff080     ; insert the address of our copperlist in COP1LC
    move.w      d0,$dff088              ; write any value (the content of d0 in this case) in COP1JMP to place the copper PC at the beginning of our copperlist
    move.w      #0,$dff1fc              ; disable AGA
    move.w      #$c00,$dff106
    move.w      #$11,$10c(a5)
    rts
restorecopperlist:
    lea         $dff000,a5
    move.l      old_cop,COP1LC(a5)
    move.w      #0,COPJMP1(a5)
    rts

    SECTION copper_segment,DATA_C
copperlist:
    dc.w        $0100,$0200             ; set the lowres video mode using BPLCON0 register ($dff100)
    dc.w        $0180,$000f             ; puts blue value into COLOR0 register
    dc.w        $9601,$fffe             ; WAIT line 150 ($96)
    dc.w        $0180,$0000             ; puts black vlaue into COLOR0 register
    dc.w        $ffff,$fffe             ; END of copperlist