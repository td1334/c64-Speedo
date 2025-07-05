
tb1 = $0334
tb2 = $0335
tb3 = $0336
tb4 = $0337

tb1_zp = $69
tb2_zp = $6a
tb3_zp = $6b
tb4_zp = $6c

tbhexstring = tb4+1
tbdecstring = tb4+1+9


;------------------------------------------------------------------------
; Startet einen 32-Bit Timer auf CIA2
;------------------------------------------------------------------------
starttimer:
  sei
-
  lda $d011
  bpl -
  and #%11101111    ; Bildschirm aus
  sta $d011
  
  ;Timer stoppen
  lda #$00
  sta $dd0f
  sta $dd0e

  ;Startzeit einstellen (z.B. 50 Taktzyklen)
  lda #$ff
  sta $dd07
  sta $dd06
  sta $dd04
  sta $dd05

  lda #%01000001
  sta $dd0f
  lda #%00000001
  sta $dd0e
  rts

;------------------------------------------------------------------------
; Stoppt den 32-Bit Time auf CIA2
;------------------------------------------------------------------------
stoptimer:
 ;Timer stoppen
  lda #$00
  sta $dd0e
  sta $dd0f

  lda $dd04
  clc
  adc #18
  eor #$ff
  sta tb1
  lda $dd05
  adc #0
  eor #$ff
  sta tb2
  lda $dd06
  adc #0
  eor #$ff
  sta tb3
  lda $dd07
  adc #0
  eor #$ff
  sta tb4

  lda $d011
  ora #$10
  sta $d011

  cli
  rts


;------------------------------------------------------------------------
; Gebe 32-Bit Zahl als Integer aus inkl. führenden "0"
;------------------------------------------------------------------------
PrDec32New:
  LDY #36                                  ;\ Offset to powers of ten

; Y=(number of digits)*4-4, eg 36 for 10 digits
PrDec32New_entry_y:
  ldx #3
-
  lda tb1,x
  sta tb1_zp,x
  dex
  bpl -

--
  ldx #$2f
  sec
---
  lda tb1_zp
  sbc PrDec32TensNew+0,y
  sta tb1_zp
  lda tb2_zp
  sbc PrDec32TensNew+1,y
  sta tb2_zp
  lda tb3_zp
  sbc PrDec32TensNew+2,y
  sta tb3_zp
  lda tb4_zp
  sbc PrDec32TensNew+3,y
  sta tb4_zp
  inx
  bcs ---

  clc
  lda tb1_zp
  adc PrDec32TensNew+0,y
  sta tb1_zp
  lda tb2_zp
  adc PrDec32TensNew+1,y
  sta tb2_zp
  lda tb3_zp
  adc PrDec32TensNew+2,y
  sta tb3_zp
  lda tb4_zp
  adc PrDec32TensNew+3,y
  sta tb4_zp

  txa
  jsr $ffd2
  dey
  dey
  dey
  dey
  bpl --

  rts



PrDec32TensNew:
   !dword 1
   !dword 10
   !dword 100
   !dword 1000
   !dword 10000
   !dword 100000
   !dword 1000000
   !dword 10000000
   !dword 100000000
   !dword 1000000000  


