;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------

                    ;5432109876543210
DMASET          EQU %1000001110000000     ; enable only copper and bitplane DMA
NUM_COLORS      EQU 16
N_PLANES        EQU 4
DISPLAY_WIDTH   EQU 320
DISPLAY_HEIGHT  EQU 256
PLF_PLANE_SIZE  EQU DISPLAY_HEIGHT*(DISPLAY_WIDTH/8)

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

load_palette:
    lea         palette,a0              ; pointer to palette data in memory
    lea         cop_palette+2,a1        ; pointer to palette data in copperlist
    moveq       #NUM_COLORS-1,d7        ; number of loop iterations
.loop:
    move.w      (a0)+,(a1)              ; copy colour value from memory to copperlist
    add.w       #4,a1                   ; point to the next value in the copperlist
    dbra        d7,.loop                ; repeats the loop (NUM_COLORS-1) times

    rts

init_bplpointers:
    move.l      #image,d0               ; address of image in d0
    lea         bplpointers,a1          ; bitplane pointers in a1
    move.l      #(N_PLANES-1),d1        ; number of loop iterations in d1
.loop:
    move.w      d0,6(a1)                ; copy low word of image address into BPLxPTL (low word of BPLxPT)
    swap        d0                      ; swap high and low word of image address
    move.w      d0,2(a1)                ; copy high word of the image addres into BPLxPTH (high word of BPLxPT)
    swap        d0                      ; resets d0 to the initial condition
    add.l       #PLF_PLANE_SIZE,d0      ; point to the next bitplane
    add.l       #8,a1                   ; point to next bplpointer
    dbra        d1,.loop                ; repeats the loop for all planes
    rts 

    SECTION copper_segment,DATA_C
    
image   incbin "assets/image.raw"
palette incbin "assets/image.pal"

copperlist:
    dc.w DIWSTRT,$2c81                  ; display window start at ($81,$2c)
    dc.w DIWSTOP,$2cc1                  ; display window stop at ($1c1,$12c)
    dc.w DDFSTRT,$38                    ; display data fetch start at $38
    dc.w DDFSTOP,$d0                    ; display data fetch stop at $d0
    dc.w BPLCON1,0
    dc.w BPLCON2,0
    dc.w BPL1MOD,0
    dc.w BPL2MOD,0

    dc.w BPLCON0,$4200                  ; 4 bitplane lowres video mode   
cop_palette:
    ; copperlist containing copper move instructions and data to fill the 
    dc.w COLOR00,0,COLOR01,0,COLOR02,0,COLOR03,0
    dc.w COLOR04,0,COLOR05,0,COLOR06,0,COLOR07,0
    dc.w COLOR08,0,COLOR09,0,COLOR10,0,COLOR11,0
    dc.w COLOR12,0,COLOR13,0,COLOR14,0,COLOR15,0

bplpointers:
    dc.w BPL1PTH,$0000,BPL1PTL,$0000
    dc.w BPL2PTH,$0000,BPL2PTL,$0000
    dc.w BPL3PTH,$0000,BPL3PTL,$0000
    dc.w BPL4PTH,$0000,BPL4PTL,$0000

    dc.w $ffff,$fffe                    ; END of copperlist
