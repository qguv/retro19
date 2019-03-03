include "lib/gbhw.inc"                  ; hardware descriptions
include "src/optim.inc"                 ; optimized instruction aliases

include "src/interrupts.asm"
include "src/music.asm"

section "entry",ROM0[$100]
    nop
    jp start

section "main",ROM0[$0150]


; a = nybble in question
bring_closer_to_eight:
    cp $08
    jr z,.end
    jr c,.raise
.lower
    sub 1
    ret
.raise
    add 1
.end
    ret

decrease_wave_volume:
    push hl                             ; hl = hiram address
    push bc                             ; b = processed low nybble, c = sample value
    ld h,$ff
    ld l,$80
.next_byte
    ld a,[hl]                           ; get a pair of samples
    ld c,a                              ; save it to c and a
    and $0f                             ; work on the lower nybble first
    call bring_closer_to_eight
    ld b,a
    ld a,c                              ; now the upper nybble
    rept 4
    srl a
    endr
    call bring_closer_to_eight
    rept 4
    sla a
    endr
    or b                                ; combine the two nybbles again
    ld [hl+],a                          ; save to hiram
    ld a,l
    cp $90
    jr nz,.next_byte
    pop bc
    pop hl
    ret

start
    ldz                                 ; turn audio off while setting up to save some battery
    ld [rAUDENA],a

    di                                  ; excuse me, I was speaking

; create wavetable in HIRAM
HIRAM_LOC = $80
ANGLE = 0.0
    rept $10
HIGHNIBBLE = (MUL(7.8, SIN(ANGLE)) + 7.8) >> 16
LOWNIBBLE = (MUL(7.8, SIN(ANGLE + 2048.0)) + 7.8) >> 16
    ld a,LOW(LOWNIBBLE | (HIGHNIBBLE << 4))
    ldh [HIRAM_LOC],a
HIRAM_LOC = HIRAM_LOC + 1
ANGLE = ANGLE + 4096.0                  ; circle has 65536.0 degrees, sin range [-1,1]
    endr

; global audio settings
    ld a,$80                            ; turn audio on globally
    ld [rAUDENA],a
    ld a,$44                            ; WAV channel output on
    ld [rAUDTERM],a
    ld a,$77                            ; master volume max
    ld [rAUDVOL],a

    ld l,$40                            ; l is a counter to dec samples
    ld h,a                              ; h is unused here
    push hl

copy_wave
    dec l                               ; ++l, do we need to decrease volume?
    jr nz,begin_wait_loop
    call z,decrease_wave_volume
    ld l,$10

    ldz
    ld [rAUDTERM],a                     ; WAV channel output off
    ld [rAUD3ENA],a                     ; WAV channel off

; copy from wave buffer to wave sample io registers
.do_copy
    push hl
    ld h,$ff                            ; hl = source (hiram wave sample buffer)
    ld l,$80
    ld b,h                              ; bc = destination (wave sample registers)
    ld c,$30
.next
    ld a,[hl+]
    ld [bc],a
    inc c
    ld a,c
    cp $40
    jr nz,.next
    pop hl

    ld a,$80                            ; WAV channel on
    ld [rAUD3ENA],a
    ld a,$44                            ; WAV channel output on
    ld [rAUDTERM],a
    ld a,$20                            ; don't divide waves
    ld [rAUD3LEVEL],a
    ld a,LOW(c4_freq)                   ; play C2 (low byte)
    ld [rAUD3LOW],a
    ld a,(HIGH(c4_freq) & $07) | $80    ; play C2 (high byte) + some flags + trigger
    ld [rAUD3HIGH],a

begin_wait_loop:
    ld b,10                             ; delay timers
    ldz

wait_loop:                               ; busy loop
    inc a
    jr nz,wait_loop
    dec b
    jr nz,wait_loop
    jr copy_wave

; vim: se ft=rgbds et ts=4 sts=4 sw=4:
