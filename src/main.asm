
player_target_org   equ $c000
PU1_CH1_DIV_LO      equ (player_target_org + 4)
PU1_CH1_DIV_HI      equ (player_target_org + 5)
PU1_CH1_STATE_LO    equ (player_target_org + 7)
PU1_CH1_STATE_HI    equ (player_target_org + 8)
PU1_CH2_DIV_LO      equ (player_target_org + 19)
PU1_CH2_DIV_HI      equ (player_target_org + 20)
PU1_CH2_STATE_LO    equ (player_target_org + 22)
PU1_CH2_STATE_HI    equ (player_target_org + 23)
PU2_CH1_DIV_LO      equ (player_target_org + 47)
PU2_CH1_DIV_HI      equ (player_target_org + 48)
PU2_CH1_STATE_LO    equ (player_target_org + 50)
PU2_CH1_STATE_HI    equ (player_target_org + 51)
PU2_CH2_DIV_LO      equ (player_target_org + 62)
PU2_CH2_DIV_HI      equ (player_target_org + 63)
PU2_CH2_STATE_LO    equ (player_target_org + 65)
PU2_CH2_STATE_HI    equ (player_target_org + 66)
ROW_LENGTH_COUNTER  equ $80
SEQ_PTR_LO          equ $81
SEQ_PTR_HI          equ $82
PTN_PTR_LO          equ $83
PTN_PTR_HI          equ $84


    section "vblank_intvec",ROM0[$0040]

    ldh a,[ROW_LENGTH_COUNTER]
    dec a
    ldh [ROW_LENGTH_COUNTER],a
    jp z,read_ptn
    reti


    section "timer_intvec",ROM0[$0050]

    jp player_target_org


    section "entry_point",ROM0[$0100]

    nop
    jp start


    section "main",ROM0[$0150]

start
    di

copy_player                         ; copy to RAM
    ld bc,(end_update_sound - update_sound)
    ld hl,player_target_org
    ld de,update_sound
.lp
    ld a,[de]
    ld [hl+],a
    inc de
    dec bc
    ld a,b
    or c
    jr nz,.lp

copy_wave
    xor a
    ldh [$1a],a                     ; disable wave
    ld hl,$ff30
    ld de,tri_wave
.lp
    ld a,[de]
    ld [hl+],a
    inc de
    ld a,l
    xor $40
    jr nz,.lp

init_sound
    ld a,$77
    ldh [$24],a                     ; L/R master volume = max
    ld a,%11111111
    ldh [$25],a                     ; all channels L/R on
    xor a
    ldh [$12],a                     ; PU1/2 Volume 0
    ldh [$17],a
    dec a
    ldh [$13],a                     ; PU1/2 FREQ LO max
    ldh [$18],a
    ldh [$10],a                     ; PU1 SWEEP enable (will not work without)
    ld a,$c0
    ldh [$11],a                     ; PU1/2 DUTY 75%
    ldh [$16],a
    ld a,$87
    ldh [$14],a                     ; restart PU1/2, FREQ-HI max
    ldh [$19],a

reset_row_data
    xor a
    ld [PU1_CH1_STATE_LO],a
    ld [PU1_CH1_STATE_HI],a
    ld [PU1_CH2_STATE_LO],a
    ld [PU1_CH2_STATE_HI],a
    ld [PU2_CH1_STATE_LO],a
    ld [PU2_CH1_STATE_HI],a
    ld [PU2_CH2_STATE_LO],a
    ld [PU2_CH2_STATE_HI],a

init_interrupts
    xor a                           ; clear Intflags
    ldh [$0f],a
    dec a
    ldh [$05],a                     ; set timer modulo
    ldh [$06],a

    ld a,5                          ; TIMER INT ENABLE
    ldh [$ff],a                     ; set Interrupt Enable

    dec a
    ldh [$07],a                     ; input clock = 4096 Hz, start timer

    call init_ptrs

wait_loop                           ; idle loop waiting for next int
    halt
    nop
    jr wait_loop

update_sound                        ; calculate next sound frame
    push hl
    push de
    push af

    ld de,0                         ; PU1_CH1_DIV equ @ + 1
    ld hl,0                         ; PU1_CH2_STATE equ @ + 1
    add hl,de                       ; PU1_CH2_STATE += PU1_CH1_DIV
    ld a,l
    ld [PU1_CH1_STATE_LO],a
    ld a,h
    ld [PU1_CH1_STATE_HI],a

    ld de,0                         ; PU1_CH2_DIV equ @ + 1
    ld hl,0                         ; PU1_CH2_STATE equ @ + 1
    add hl,de                       ; PU1_CH2_STATE += PU1_CH1_DIV
    ld a,l
    ld [PU1_CH2_STATE_LO],a
    ld a,h
    ld [PU1_CH2_STATE_HI],a

    ld a,[PU1_CH1_STATE_HI]         ; PU1 frame volume = CH1_STATE + CH2_STATE
    add h
    rra                             ; frame volume /= 2
    and $f0
    ldh [$12],a                     ; set volume reg
    ld a,$87
    ldh [$14],a                     ; restart sound


    ld de,0                         ; PU2_CH1_DIV equ @ + 1
    ld hl,0                         ; PU2_CH2_STATE equ @ + 1
    add hl,de                       ; PU2_CH2_STATE += PU2_CH1_DIV
    ld a,l
    ld [PU2_CH1_STATE_LO],a
    ld a,h
    ld [PU2_CH1_STATE_HI],a

    ld de,0                         ; PU2_CH2_DIV equ @ + 1
    ld hl,0                         ; PU2_CH2_STATE equ @ + 1
    add hl,de                       ; PU2_CH2_STATE += PU2_CH1_DIV
    ld a,l
    ld [PU2_CH2_STATE_LO],a
    ld a,h
    ld [PU2_CH2_STATE_HI],a

    ld a,[PU2_CH1_STATE_HI]         ; PU2 frame volume = CH1_STATE + CH2_STATE
    add h
    rra                             ; frame volume /= 2
    and $f0
    ldh [$17],a                     ; set volume reg
    ld a,$87
    ldh [$19],a                     ; restart sound

    pop af
    pop de
    pop hl
    reti
end_update_sound


init_ptrs
    ld a,(music_data & $ff)
    ldh [SEQ_PTR_LO],a
    ld a,(music_data >> 8)
    ldh [SEQ_PTR_HI],a

read_seq                            ; update sequence pointer
    ldh a,[SEQ_PTR_LO]
    ld l,a
    ldh a,[SEQ_PTR_HI]
    ld h,a
from_loop
    ld a,[hl+]
    ldh [PTN_PTR_LO],a
    ld a,[hl+]
    or a
    jr nz,.no_loop                  ; PTR_HI = 0 -> restart from loop point
    ld a,[hl+]
    ld h,[hl]
    ld l,a
    jr from_loop

.no_loop
    ldh [PTN_PTR_HI],a
    ld a,l
    ldh [SEQ_PTR_LO],a
    ld a,h
    ldh [SEQ_PTR_HI],a

read_ptn                            ; update pattern ptr
    ldh a,[PTN_PTR_LO]
    ld l,a
    ldh a,[PTN_PTR_HI]
    ld h,a

    ld a,[hl+]
    or a
    jr z,read_seq

    ldh [ROW_LENGTH_COUNTER],a

    ld a,[hl+]                      ; ctrl byte
    ld e,a

    rr e
    jr nc,.no_reset_pu1_ch1         ; if !c, skip channel update

    ld a,[hl+]
    ld [PU1_CH1_DIV_LO],a
    ld a,[hl+]
    ld [PU1_CH1_DIV_HI],a
    or a
    jr nz,.no_reset_pu1_ch1
    ld [PU1_CH1_STATE_HI],a         ; reset state on rests
.no_reset_pu1_ch1
    rr e
    jr nc,.no_reset_pu1_ch2

    ld a,[hl+]
    ld [PU1_CH2_DIV_LO],a
    ld a,[hl+]
    ld [PU1_CH2_DIV_HI],a
    or a
    jr nz,.no_reset_pu1_ch2
    ld [PU1_CH2_STATE_HI],a
.no_reset_pu1_ch2
    rr e
    jr nc,.no_reset_pu2_ch1

    ld a,[hl+]
    ld [PU2_CH1_DIV_LO],a
    ld a,[hl+]
    ld [PU2_CH1_DIV_HI],a
    or a
    jr nz,.no_reset_pu2_ch1
    ld [PU2_CH1_STATE_HI],a         ; reset state on rests
.no_reset_pu2_ch1
    rr e
    jr nc,.no_reset_pu2_ch2

    ld a,[hl+]
    ld [PU2_CH2_DIV_LO],a
    ld a,[hl+]
    ld [PU2_CH2_DIV_HI],a
    or a
    jr nz,.no_reset_pu2_ch2
    ld [PU2_CH2_STATE_HI],a
.no_reset_pu2_ch2
    rr e
    jr nc,.no_wav_update

    ld a,[hl+]
    ldh [$1c],a
    ldh [$1a],a
    ld a,[hl+]
    ldh [$1b],a
    ld a,[hl+]
    ldh [$1d],a
    ld a,[hl+]
    ldh [$1e],a

.no_wav_update
    rr e
    jr nc,.no_noise_update

    ld a,[hl+]
    ldh [$20],a
    ld a,[hl+]
    ldh [$21],a
    ld a,[hl+]
    ldh [$22],a
    ld a,[hl+]
    ldh [$23],a

.no_noise_update
    ld a,l
    ldh [PTN_PTR_LO],a
    ld a,h
    ldh [PTN_PTR_HI],a

    reti

tri_wave                                        ; well, sort of ;)
    db $00,$12,$34,$55,$68,$89,$ab,$cc
    db $cb,$a9,$88,$76,$54,$33,$21,$10

music_data
    include "src/music.asm"

