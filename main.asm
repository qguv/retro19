; HIRAM locations
PU1_CH1_DIV_LO      equ $80
PU1_CH1_DIV_HI      equ $81
PU1_CH1_STATE_LO    equ $82
PU1_CH1_STATE_HI    equ $83
PU1_CH2_DIV_LO      equ $84
PU1_CH2_DIV_HI      equ $85
PU1_CH2_STATE_LO    equ $86
PU1_CH2_STATE_HI    equ $87

    section "vblank_intvec",ROM0[$0040]

    reti


    section "timer_intvec",ROM0[$0050]
    
    jp update_sound


    section "entry_point",ROM0[$0100]
    
    nop
    jp start


    section "main",ROM0[$0150]

start
    di

init_sound
    xor a
    ldh [$10],a                     ; PU1 SWEEP off
    ldh [$12],a                     ; PU1 VOLUME 0
    ldh [$13],a                     ; PU1 FREQ LO 0
    ldh [$14],a                     ; PU1 FREQ HI/INIT 0
    dec a
    ldh [$c0],a                     ; PU1 DUTY 75%
    ld a,$77
    ldh [$24],a                     ; L/R master volume = max
    ld a,$11
    ldh [$25],a                     ; PU1 L/R on

reset_row_data
    xor a
    ldh [PU1_CH1_STATE_LO],a
    ldh [PU1_CH1_STATE_HI],a
    ldh [PU1_CH2_STATE_LO],a
    ldh [PU1_CH2_STATE_HI],a

    ldh [PU1_CH1_DIV_LO],a          ; some random frequency will do for now
    ldh [PU1_CH2_DIV_LO],a
    ld a,$18
    ldh [PU1_CH1_DIV_HI],a
    ld a,$10
    ldh [PU1_CH2_DIV_HI],a

init_interrupts
    xor a                           ; clear Intflags
    ldh [$0f],a
    dec a
    ldh [$05],a                     ; set timer modulo
    ldh [$06],a

    ld a,5                          ; VBLANK + TIMER
    ldh [$ff],a                     ; set Interrupt Enable

    dec a
    ldh [$07],a                     ; input clock = 4096 Hz, start timer
    ei
    nop                             ; should not halt immediately after ei?
                                    ; also clearing intflags here would be
                                    ; safer

wait_loop                           ; idle loop waiting for next int
    halt
    nop
    jr wait_loop

update_sound                        ; calculate next sound frame
    push hl
    push de
    push bc
    push af

    ld hl,PU1_CH1_DIV_LO + $ff00
    ld e,[hl]
    inc l
    ld d,[hl]
    inc l
    ld a,[hl+]
    ld h,[hl]
    ld l,a
;    ldh a,[PU1_CH1_STATE_LO]        ; PU1_CH1_STATE += PU1_CH1_DIV
;    ld l,a
;    ldh a,[PU1_CH1_STATE_HI]
;    ld h,a
;    ldh a,[PU1_CH1_DIV_LO]
;    ld e,a
;    ldh a,[PU1_CH1_DIV_HI]
;    ld d,a
    add hl,de
    ld c,h                          ; C = PU1_CH1_STATE_hi
    ld a,h
    ldh [PU1_CH1_STATE_HI],a
    ld a,l
    ldh [PU1_CH1_STATE_LO],a

    ld hl,PU1_CH2_DIV_LO + $ff00
    ld e,[hl]
    inc l
    ld d,[hl]
    inc l
    ld a,[hl+]
    ld h,[hl]
    ld l,a
;    ldh a,[PU1_CH2_STATE_LO]        ; PU1_CH2_STATE += PU1_CH2_DIV
;    ld l,a
;    ldh a,[PU1_CH2_STATE_HI]
;    ld h,a
;    ldh a,[PU1_CH2_DIV_LO]
;    ld e,a
;    ldh a,[PU1_CH2_DIV_HI]
;    ld d,a
    add hl,de
    ld a,l
    ldh [PU1_CH2_STATE_LO],a
    ld a,h
    ldh [PU1_CH2_STATE_HI],a
    add c                           ; volume = (CH1_STATE + CH2_STATE) / 2
    rra
    and $f0
    ldh [$12],a                     ; set volume reg (NR12)
    ld a,$80
    ldh [$14],a                     ; restart sound

    pop af
    pop bc
    pop de
    pop hl
    reti
