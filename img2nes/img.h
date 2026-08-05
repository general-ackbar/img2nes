#define asm @"   \n\
  .inesprg 1   ; 1x 16KB PRG code   \n\
  .ineschr 1   ; 1x  8KB CHR data   \n\
  .inesmap 0   ; mapper 0 = NROM, no bank swapping   \n\
  .inesmir 1   ; background mirroring   \n\
   \n\
   \n\
  .rsset $0000      \n\
ptr .rs 2   \n\
r0 .rs 1          \n\
   \n\
PPU_CTRL  =      $2000   \n\
PPU_MASK  =      $2001   \n\
PPU_STATUS  =    $2002   \n\
OAM_ADDR  =      $2003   \n\
OAM_DATA  =      $2004   \n\
PPU_SCROLL  =    $2005   \n\
PPU_ADDR  =      $2006   \n\
PPU_DATA  =      $2007   \n\
   \n\
PPU_OAM_DMA =    $4014   \n\
DMC_FREQ  =      $4010   \n\
APU_STATUS  =    $4015   \n\
APU_NOISE_VOL  = $400C   \n\
APU_NOISE_FREQ = $400E   \n\
APU_NOISE_TIMER= $400F   \n\
APU_DMC_CTRL   = $4010   \n\
APU_CHAN_CTRL  = $4015   \n\
APU_FRAME      = $4017   \n\
   \n\
   \n\
  .bank 0   \n\
  .org $D000   \n\
   \n\
vblankwait:   \n\
  bit PPU_STATUS   \n\
  bpl vblankwait   \n\
  rts   \n\
   \n\
Reset:   \n\
   \n\
  sei     \n\
  cld     \n\
  ldx #$40   \n\
  stx APU_FRAME    \n\
  ldx #$FF   \n\
  txs     \n\
  inx    \n\
  stx PPU_CTRL    \n\
  stx PPU_MASK     \n\
  stx DMC_FREQ    \n\
  stx APU_STATUS   \n\
  jsr vblankwait   \n\
   \n\
clrmem:   \n\
  lda #$00   \n\
  sta <$0000, x   \n\
  sta $0100, x   \n\
  sta $0300, x   \n\
  sta $0400, x   \n\
  sta $0500, x   \n\
  sta $0600, x   \n\
  sta $0700, x   \n\
  lda #$FE   \n\
  sta $0200, x    \n\
  inx   \n\
  bne clrmem   \n\
  jsr vblankwait   \n\
  jmp start   \n\
   \n\
start:   \n\
  jsr LoadPalettes   \n\
  jsr LoadBackground   \n\
   \n\
  lda #%10010000   \n\
  sta PPU_CTRL   \n\
  jmp GameEngine   \n\
   \n\
   \n\
;; ########## Init subroutines ############   \n\
   \n\
LoadBackground:   \n\
  lda PPU_STATUS     \n\
  lda #$20   \n\
  sta PPU_ADDR       \n\
  lda #$00   \n\
  sta PPU_ADDR     \n\
   \n\
   \n\
  lda #LOW(background)   \n\
  sta <ptr   \n\
  lda #HIGH(background)   \n\
  sta <ptr+1   \n\
     \n\
     \n\
  ldx #$00    \n\
  ldy #$00     \n\
  .outer_loop:   \n\
    .inner_loop:   \n\
      lda [ptr], y       \n\
      sta PPU_DATA             \n\
      iny                      \n\
      cpy #$00                 \n\
      bne  .inner_loop   \n\
   \n\
      inc <ptr+1            \n\
      inx                      \n\
      cpx #$04                 \n\
      bne .outer_loop   \n\
  .load_done:   \n\
    rts   \n\
   \n\
   \n\
LoadPalettes:   \n\
  lda PPU_STATUS    \n\
  lda #$3F   \n\
  sta PPU_ADDR    \n\
  lda #$00   \n\
  sta PPU_ADDR     \n\
  ldx #$00   \n\
  .loop:   \n\
    lda palette, x   \n\
    sta PPU_DATA   \n\
    inx   \n\
    cpx #$20   \n\
    bne .loop   \n\
  rts   \n\
   \n\
   \n\
   \n\
NMI:   \n\
  ; save registers   \n\
  pha   \n\
  txa   \n\
  pha   \n\
  tya   \n\
  pha   \n\
   \n\
    .ppu_cleanup:   \n\
      lda #%10010000   \n\
      sta PPU_CTRL   \n\
      lda #%00011110   \n\
      sta PPU_MASK   \n\
      lda #$00      \n\
      sta PPU_SCROLL   \n\
      sta PPU_SCROLL   \n\
   \n\
    .nmi_end:   \n\
      ; restore registers and return   \n\
      pla   \n\
      tay   \n\
      pla   \n\
      tax   \n\
      pla   \n\
      rti   \n\
   \n\
irq:   \n\
  rti   \n\
   \n\
   \n\
     \n\
GameEngine:   \n\
  jmp GameEngine   \n\
   \n\
   \n\
     \n\
   \n\
   \n\
  .bank 1   \n\
  .org $A000   \n\
   \n\
   \n\
background:   \n\
  .incbin \"[$name].nmt\"   \n\
  ;;[@]   \n\
   \n\
   \n\
   \n\
   \n\
   \n\
; First bytes of first sprite palette defines the background color   \n\
palette:   \n\
  .incbin \"[$name].pal\"   \n\
   \n\
   \n\
  .org $FFFA    \n\
  .dw NMI            \n\
  .dw Reset          \n\
  .dw irq            \n\
   \n\
   \n\
   \n\
  .bank 2   \n\
  .org $0000   \n\
  .incbin \"[$name].chr\"    \n\
     \n\
  ";
