uppercodeadr = $c000
dataadr = $e000

zp_lines = $fb

* = $0801

;----------------------------------------------------------------------------
;
; Speedo - Ein Basic Zeilen Analyzer
; Version 1.2
;
; Code by TD1334 (Peter Alexander)
; Lizenz: Keine
;
; Greetings to RAP
;
;----------------------------------------------------------------------------




!basic 1334, start

start:
  lda #<uppercode
  ldx #>uppercode
  sta $fb
  stx $fc
  
  lda #<uppercodeadr
  ldx #>uppercodeadr
  sta $fd
  stx $fe

  ldx #(uppercode_ende - uppercode)/256+1
  ldy #0
-
  inc $d020
  lda ($fb),y
  sta ($fd),y
  iny
  bne -
  inc $fc
  inc $fe
  dex
  bne -

  jmp uppercodeinit


uppercode = *

!pseudopc uppercodeadr

!source "inc.timer32_test.asm"

uppercodeinit:

  jsr print_stack
  !pet $93, "speedo v1.2 - basic speed analyzer",13,13
  !pet "code by td1334",13
  !pet 13,0

  lda $0308
  ldx $0309
  sta jump0308
  stx jump0308+1
  
  lda #<new0308
  ldx #>new0308
  sta $0308
  stx $0309

  lda $0302
  ldx $0303
  sta jump0302
  stx jump0302+1
  
  lda #<new0302
  ldx #>new0302
  sta $0302
  stx $0303
 
  
  ; Basic NEW aufrufen
  jsr $a644
  
  lda $2b
  ldx $2c
  sta $2d
  stx $2e
  
  lda #<.testbasic1
  ldx #>.testbasic1
  sta $31
  stx $32
  
-
  lda $31
  cmp #<.testbasic2
  bne +
  lda $32
  cmp #>.testbasic2
  beq ++
+
  ldy #0
  lda ($31),y
  inc $31
  bne +
  inc $32
+
  sta ($2d),y
  inc $2d
  bne +
  inc $2e
+
  jmp -
++
  lda $2d
  ldx $2e
  sta $2f
  stx $30
  sta $31
  stx $32

  ldx #4
  stx $c6
  dex
-
  lda .txtrun,x
  sta $277,x
  dex
  bpl -

  sec
  lda #0
  ;jsr $a69c   ; Basic LIST
  lda #0
  sta $14
  sta $15
  lda $2b
  ldx $2c
  sta $5f
  stx $60
  jmp $a6bd
  
  ;jsr $a871   ; Basic RUN
  
  ;jmp ($0302)
  ;rts

.txtrun
  !pet "run",$0d

.testbasic1
!binary "speedo3.tbas",,2
.testbasic2


print_stack:
  tsx
  lda $0101,x
  sta $03
  lda $0102,x
  sta $04
  ldy #1
-
  inc $0101,x
  bne +
  inc $0102,x
+
  lda ($03),y
  beq +
  jsr $ffd2
  iny
  bne -
+
  rts
  


jump0302  !word $1334
jump0308  !word $1334
active    !byte $00

lineno    !word $ffff


;
; Abwicklung eines neuen Tokens
; Dabei Prüfung auf neue Zeile; Dabei wird stoptimer/starttimer ausgelöst
;
new0308:
  lda active
  beq +
  jsr new308_checknewline   ; Prüfung ob neue Basic Zeile vorliegt
+
  jsr $0073
  php
  pha
  
  cmp #$8a    ; RUN
  bne .new_308_not_run
  lda #$ff
  sta lineno
  sta lineno+1
  sta active
  
  jsr initdata
  
  jmp .new_308_go

.new_308_not_run:

  cmp #$80    ; END
  bne .new_308_not_end
  lda $d011
  ora #$10
  sta $d011
  lda #0
  sta active
  
  jsr print_ergebnis
  
  jmp .new_308_go
.new_308_not_end:

.new_308_go:

  pla
  plp
  
  jsr $a7ed

 
  lda active
  beq +
  jsr new308_checknewline   ; Prüfung ob neue Basic Zeile vorliegt
+
new0308_end:
  jmp $a7ae
  
; Setzt zp_lines = dataadr ($e000)
init_zp_lines:
  lda #<dataadr
  ldx #>dataadr
  sta zp_lines
  stx zp_lines+1
  rts

; Initialisiert den Datenbereich und kopiert alle Zeilennummern des Basicprogram  in den Datenbereich
initdata:
  lda $2b
  ldx $2c
  sta $03
  stx $04
  
  jsr init_zp_lines
  sta $05
  stx $06
.initdata_loop:
  ldy #1
  lda ($03),y     ; Wenn 0 dann keine
  beq .initdata_ende
  ldy #2
  lda ($03),y     ; Zeilennummer lo
  tax
  iny
  lda ($03),y     ; Zeilennummer hi
  ldy #1
  sta ($05),y
  dey
  txa
  sta ($05),y

  ; Zähler für Zeilennummernabarbeitung (2 Bytes) und 32-bit Wert (4 Bytes) auf 0 setzen
  ldy #2
  lda #$00
-
  sta ($05),y
  iny
  cpy #8
  bcc -
  
  ; Addiere ZP 05/06 um 8 Bytes (Eintrag pro Basic Zeile)
  lda $05
  clc
  adc #$08
  sta $05
  bcc +
  inc $06
+

  ; PTR auf nächste Basiczeile setzen
  ldy #1
  lda ($03),y
  tax
  dey
  lda ($03),y
  sta $03
  stx $04
  jmp .initdata_loop

.initdata_ende:
  ; Letzte Zeile wird im Datenbereich mit $ffff markiert
  ldy #$7
  lda #$ff
-
  sta ($05),y
  dey
  bpl -
  rts
  
  
  
; Prüft ob neue Basiczeile vorliegt und löst stoptimer/starttimer aus
new308_checknewline:
  lda $3a     ; Hi Byte Zeile
  cmp #$ff    ; Wenn $ff dann direktmodus
  bne +
-
  rts
+
  cmp lineno+1
  bne new0308_newline
  lda $39     ; Lo Byte Zeile
  cmp lineno
  beq -

new0308_newline:
  lda lineno+1
  cmp #$ff
  beq +
  jsr new_stoptimer     ; Wenn letzte Zeile nicht $ff dann wurde eine Basiczeile abgearbeiet und der Timer muss gestoppt werden
+
  jsr starttimer        ; Timer starten für die neue Zeile

  lda $39
  ldx $3a
  sta lineno
  stx lineno+1
  rts

; Timer stoppen, Counter für Zeile erhöhen und Taktzyklen addieren
new_stoptimer:
  jsr stoptimer
  
  ; Suche Zeile im Datenbereich
  jsr getLinePuffer
  bcs ++

  jsr rom_off
  
  ldx #2
  ldy #2
  sec
-
  lda (zp_lines),y    ; Count wie oft eine Zeile abgearbeitet wurde um 1 erhöhen
  adc #0
  sta (zp_lines),y
  iny
  dex
  bne -
  bcc +
  ; Falls $10000 Durchläufe erreicht dann $ffff setzen
  dey
  lda #$ff
  sta (zp_lines),y
  dey
  sta (zp_lines),y
+
  ldx #4
  ldy #4
  clc
-
  ; Addiere Taktzyklen
  lda tb1-4,y
  adc (zp_lines),y
  sta (zp_lines),y
  iny
  dex
  bne -
++
  jmp rom_on


; ROMs ausschalten
rom_off:
  sei
  lda #$35
  sta $01
  rts

; ROMs einschalten
rom_on:
  lda #$37
  sta $01
  cli
  rts

getLinePuffer:
  jsr rom_off
  ldy #0
  
  lda lineno
  sec
  sbc (zp_lines),y
  iny
  lda lineno+1
  sbc (zp_lines),y
  bcs .getLinePuffer_loop

  jsr init_zp_lines

.getLinePuffer_loop:
  ldy #1
  lda (zp_lines),y
  cmp #$ff
  beq .getLinePuffer_end
  
  cmp lineno+1
  bne .getLinePuffer_next
  dey
  lda (zp_lines),y
  cmp lineno
  bne .getLinePuffer_next
  clc

getLinePuffer_rts:
  jsr rom_on
  rts

.getLinePuffer_end
  jsr init_zp_lines
  sec
  bcs getLinePuffer_rts

.getLinePuffer_next:
  lda #8
  clc
  adc zp_lines
  sta zp_lines
  bcc .getLinePuffer_loop
  inc zp_lines+1
  bne .getLinePuffer_loop



new0302:
  lda $d011
  ora #$10
  sta $d011
  lda active
  beq +
  jsr new_stoptimer
  lda #0
  sta active
  inc $d020
  jsr print_ergebnis
+
  jmp (jump0302)



print_ergebnis:
  ;lda #$0d
  ;jsr $ffd2
  ;jsr $ffd2

  jsr print_stack
  !pet $0d, $0d, "speedo - basic speed analyzer",$0d,$0d
  !pet "line  + count +   cycles",13
  !pet "--------------------------",13
  !pet 13,0
  
  jsr init_zp_lines

.print_ergebnis_loop:
  jsr rom_off

  ldy #0
  lda (zp_lines),y
  tax
  iny
  lda (zp_lines),y
  cmp #$ff
  beq ++++


  pha
  jsr rom_on
  pla
  
  jsr $bdcd

  lda #6
  sta $d3
  
  ;lda #" "
  ;jsr $ffd2
  lda #"-"
  jsr $ffd2
  lda #" "
  jsr $ffd2

  jsr rom_off
  
  ldy #2
  lda (zp_lines),y
  sta tb1
  iny
  lda (zp_lines),y
  sta tb2

  lda #0
  sta tb3
  sta tb4
  

  jsr rom_on
  
  ldy #16
  jsr PrDec32New_entry_y
  
  lda #" "
  jsr $ffd2
  lda #"-"
  jsr $ffd2
  lda #" "
  jsr $ffd2

  jsr rom_off
  
  ldy #4
-
  lda (zp_lines),y
  sta tb1-4,y
  iny
  cpy #8
  bcc -
  
  jsr rom_on
  
  jsr PrDec32New

  lda #$0d
  jsr $ffd2
  
  lda zp_lines
  clc
  adc #8
  sta zp_lines
  bcc +
  inc zp_lines+1
+
  jmp .print_ergebnis_loop
  
  
++++
  jmp rom_on
  

!realpc
uppercode_ende:
  
