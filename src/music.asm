
    include "src/note_names.asm"

; Format Specification

; Sequence - list of 16-bit pattern pointers, terminated with dw 0, followed
; by loop point address

    dw ptn0
    dw ptn1
    dw ptn2
    dw ptn3
    dw ptn1
loop_point
    dw ptn1a
    dw ptn2a
    dw ptn3a
    dw ptn1a
    dw ptn1a
    dw ptn2a
    dw ptn3b
    dw ptn1b
    dw ptn10a
    dw ptn20a
    dw ptn30a
    dw ptn10c
    dw ptn10a
    dw ptn20a
    dw ptn30b
    dw ptn10b
    dw 0
    dw loop_point

; Patterns
; byte  bit     function
; 0             row length in ticks (# of VBLANKS)
;               row length = 0 marks end of pattern
; 1             control byte
;       0       PU1_CH1 data follows
;       1       PU1_CH2 data follows
;       2       PU2_CH1 data follows
;       3       PU2_CH2 data follows
;       4       WAV data follows
;       5       NOI data follows
;       7       player core swap (not implemented)
; [div_pu1_ch1, div_pu1_ch2, div_pu2_ch1, div_pu2_ch2]


ptn0
    dw ((%00001111 << 8) | $20),c3,rest,rest,rest
    dw ((%00000001 << 8) | $20),ds3
    dw ((%00000001 << 8) | $20),g3
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn1
    dw ((%00000011 << 8) | $20),c3,c2
    dw ((%00000001 << 8) | $20),ds3
    dw ((%00000011 << 8) | $20),g3,g1
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn2
    dw ((%00000011 << 8) | $20),c3,gs1
    dw ((%00000001 << 8) | $20),ds3
    dw ((%00000001 << 8) | $20),g3
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn3
    dw ((%00000011 << 8) | $20),c3,gs1
    dw ((%00000001 << 8) | $20),ds3
    dw ((%00000011 << 8) | $20),g3,g1
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn1a
    dw ((%00111111 << 8) | $20),c3,c2,c1,g3,0,0,$7700,$8037
    dw ((%00000001 << 8) | $20),ds3
    dw ((%00001111 << 8) | $20),g3,g1,g0,g3
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn1b
    dw ((%00101111 << 8) | $20),c3,c2,c1,c3,$7700,$8037
    dw ((%00000001 << 8) | $20),ds3
    dw ((%00001111 << 8) | $20),g3,g1,g0,c3
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn2a
    dw ((%00001111 << 8) | $20),c3,gs1,gs0,f3
    dw ((%00001001 << 8) | $20),ds3,ds3
    dw ((%00000001 << 8) | $20),g3
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn3a
    dw ((%00101111 << 8) | $20),c3,gs1,gs0,g3,$7700,$8017
    dw ((%00001001 << 8) | $20),ds3,f3
    dw ((%00101111 << 8) | $20),g3,g1,g0,ds3,$7700,$8027
    dw ((%00001001 << 8) | $20),b3,f3
    db 0

ptn3b
    dw ((%00101111 << 8) | $20),c3,gs1,gs0,c3,$7700,$8017
    dw ((%00001001 << 8) | $20),ds3,as2
    dw ((%00101111 << 8) | $20),g3,g1,g0,c3,$7700,$8027
    dw ((%00001001 << 8) | $20),b3,d3
    db 0

ptn10a
    dw ((%00111111 << 8) | $20),c3,c2,c1,g3,$00a0,(gbds3 + $8000),$7700,$8037
    dw ((%00010001 << 8) | $20),ds3,$00a0,(gbg3 + $8000)
    dw ((%00011111 << 8) | $20),g3,g1,g0,g3,$00a0,(gbb3 + $8000)
    dw ((%00010001 << 8) | $20),b3,$00a0,(gbc3 + $8000)
    db 0

ptn10c
    dw ((%00111111 << 8) | $20),c3,c2,c1,g3,$00a0,(gbg3 + $8000),$7700,$8037
    dw ((%00000001 << 8) | $10),ds3
    dw ((%00010000 << 8) | $08),$00a0,(gbgs3 + $8000)
    dw ((%00010000 << 8) | $08),$00a0,(gbg3 + $8000)
    dw ((%00011111 << 8) | $20),g3,g1,g0,g3,$00a0,(gbf3 + $8000)
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn10b
    dw ((%00111111 << 8) | $20),c3,c2,c1,c3,$00a0,(gbc3 + $8000),$7700,$8037
    dw ((%00000001 << 8) | $20),ds3
    dw ((%00001111 << 8) | $20),g3,g1,g0,c3
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn20a
    dw ((%00001111 << 8) | $20),c3,gs1,gs0,f3
    dw ((%00001001 << 8) | $20),ds3,ds3
    dw ((%00000001 << 8) | $20),g3
    dw ((%00000001 << 8) | $20),b3
    db 0

ptn30a
    dw ((%00111111 << 8) | $20),c3,gs1,gs0,g3,$00a0,(gbds3 + $8000),$7700,$8017
    dw ((%00011001 << 8) | $20),ds3,f3,$00a0,(gbd3 + $8000)
    dw ((%00111111 << 8) | $20),g3,g1,g0,ds3,$00a0,(gbds3 + $8000),$7700,$8027
    dw ((%00011001 << 8) | $20),b3,f3,$00a0,(gbf3 + $8000)
    db 0

ptn30b
    dw ((%00111111 << 8) | $20),c3,gs1,gs0,c3,$00a0,(gbc3 + $8000),$7700,$8017
    dw ((%00011001 << 8) | $20),ds3,as2,$00a0,(gbas2 + $8000)
    dw ((%00111111 << 8) | $20),g3,g1,g0,c3,$00a0,(gbc3 + $8000),$7700,$8027
    dw ((%00011001 << 8) | $20),b3,d3,$00a0,(gbd3 + $8000)
    db 0
