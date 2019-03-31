player_target_org   equ $c000
PU1_CH1_DIV_LO      equs "player_target_org + (_pu1_ch1_div - update_sound) + 1"
PU1_CH1_DIV_HI      equs "player_target_org + (_pu1_ch1_div - update_sound) + 2"
PU1_CH1_STATE_LO    equs "player_target_org + (_pu1_ch1_state - update_sound) + 1"
PU1_CH1_STATE_HI    equs "player_target_org + (_pu1_ch1_state - update_sound) + 2"
PU1_CH2_DIV_LO      equs "player_target_org + (_pu1_ch2_div - update_sound) + 1"
PU1_CH2_DIV_HI      equs "player_target_org + (_pu1_ch2_div - update_sound) + 2"
PU1_CH2_STATE_LO    equs "player_target_org + (_pu1_ch2_state - update_sound) + 1"
PU1_CH2_STATE_HI    equs "player_target_org + (_pu1_ch2_state - update_sound) + 2"
PU2_CH1_DIV_LO      equs "player_target_org + (_pu2_ch1_div - update_sound) + 1"
PU2_CH1_DIV_HI      equs "player_target_org + (_pu2_ch1_div - update_sound) + 2"
PU2_CH1_STATE_LO    equs "player_target_org + (_pu2_ch1_state - update_sound) + 1"
PU2_CH1_STATE_HI    equs "player_target_org + (_pu2_ch1_state - update_sound) + 2"
PU2_CH2_DIV_LO      equs "player_target_org + (_pu2_ch2_div - update_sound) + 1"
PU2_CH2_DIV_HI      equs "player_target_org + (_pu2_ch2_div - update_sound) + 2"
PU2_CH2_STATE_LO    equs "player_target_org + (_pu2_ch2_state - update_sound) + 1"
PU2_CH2_STATE_HI    equs "player_target_org + (_pu2_ch2_state - update_sound) + 2"
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
    ld a,%10111101
    ldh [$25],a                     ; PU1 and NOI on both, PU2 on left, WAV on right
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

_pu1_ch1_div
    ld de,0                         ; location of imm value 0 in code is rewritten every frame
_pu1_ch1_state
    ld hl,0                         ; location of imm value 0 in code is rewritten every frame
    add hl,de                       ; PU1_CH1_STATE += PU1_CH1_DIV
    ld a,l
    ld [PU1_CH1_STATE_LO],a
    ld a,h
    ld [PU1_CH1_STATE_HI],a

; like above, but for the second software channel on PU1
_pu1_ch2_div
    ld de,0                         ; location of imm value 0 in code is rewritten every frame
_pu1_ch2_state
    ld hl,0                         ; location of imm value 0 in code is rewritten every frame
    add hl,de                       ; PU1_CH2_STATE += PU1_CH1_DIV
    ld a,l
    ld [PU1_CH2_STATE_LO],a
    ld a,h
    ld [PU1_CH2_STATE_HI],a

; index each software channel in wavetable, then combine the two channels into PU1
    ld hl,puvol_sin                 ; calculate wavetable address
    add a,l                         ; add HL and the ch2 level
    ld l,a
    adc a,h
    sub l
    ld h,a
    ld b,[hl]                       ; and get the new level from the table
    ld hl,puvol_sin                 ; calculate wavetable address
    ld a,[PU1_CH1_STATE_HI]         ; fetch the current ch1 level
    add a,l                         ; add HL and the ch1 level
    ld l,a
    adc a,h
    sub l
    ld h,a
    ld a,[hl]                       ; and get the new level from the table
    add b                           ; combine the two channels
    ldh [$12],a                     ; set volume reg
    ld a,$87
    ldh [$14],a                     ; restart sound


_pu2_ch1_div
    ld de,0                         ; location of imm value 0 in code is rewritten every frame
_pu2_ch1_state
    ld hl,0                         ; location of imm value 0 in code is rewritten every frame
    add hl,de                       ; PU2_CH1_STATE += PU2_CH1_DIV
    ld a,l
    ld [PU2_CH1_STATE_LO],a
    ld a,h
    ld [PU2_CH1_STATE_HI],a

_pu2_ch2_div
    ld de,0                         ; location of imm value 0 in code is rewritten every frame
_pu2_ch2_state
    ld hl,0                         ; location of imm value 0 in code is rewritten every frame
    add hl,de                       ; PU2_CH2_STATE += PU2_CH1_DIV
    ld a,l
    ld [PU2_CH2_STATE_LO],a
    ld a,h
    ld [PU2_CH2_STATE_HI],a

; index each software channel in wavetable, then combine the two channels into PU1
    ld hl,puvol_sin                 ; calculate wavetable address
    add a,l                         ; add HL and the ch2 level
    ld l,a
    adc a,h
    sub l
    ld h,a
    ld b,[hl]                       ; and get the new level from the table
    ld hl,puvol_sin                 ; calculate wavetable address
    ld a,[PU2_CH1_STATE_HI]         ; fetch the current ch1 level
    add a,l                         ; add HL and the ch1 level
    ld l,a
    adc a,h
    sub l
    ld h,a
    ld a,[hl]                       ; and get the new level from the table
    add b                           ; combine the two channels
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

; creates a 256-byte balanced sine table for PU* volume/envelope values, from $10 t/m $70 in increments of $10
puvol_sin
angle   set   0.0
        rept  256
        ; adding 3.0 to get from [-3, 3] to [0, 6]
        ; adding 1.0 to get from [0, 6] to [1, 7]
        ; adding 0.5 to get from [1, 7] to [1.5, 7.5] because ints are floored
        ; this provides a sufficiently balanced sin with a nice linger at 1 and 7
        ; we're right shifting 16 (yes) times to deal with fixed point decimal numbers
        ; we're then leftshifting 4 times to put the low nybble high
        ; (these last two steps implemented as (>>12 & $f0) for compile efficiency)
        db    (mul(3.0, sin(angle)) + 3.0 + 1.0 + 0.5)>>12 & $f0
angle   set angle+256.0
        endr

;         |min              |med              |max
; 0___| 1_L_| 2___| 3___| 4_L_| 5___| 6___| 7_L_|
;                           |
;                        |
;                     |
;                  |
;               |
;             |
;           |
;          |
; 0___| 1___| 2___| 3___| 4___| 5___| 6___| 7___|
;          |
;           |
;             |
;               |
;                  |
;                     |
;                        |
;                           |
; 0___| 1___| 2___| 3___| 4___| 5___| 6___| 7___|
;                              |
;                                 |
;                                    |
;                                       |
;                                         |
;                                           |
;                                            |
;                                             |
; 0___| 1___| 2___| 3___| 4___| 5___| 6___| 7___|
;                                             |
;                                            |
;                                           |
;                                         |
;                                       |
;                                    |
;                                 |
;                              |
;                           |
; 0___| 1___| 2___| 3___| 4___| 5___| 6___| 7___|
