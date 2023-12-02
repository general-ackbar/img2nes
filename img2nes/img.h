  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring


  .rsset $0000    ; variables starting at $0000
ptr .rs 2
nmt_data .rs 32
nmt_needs_update .rs 1
palette_needs_update .rs 1
r0 .rs 1        ;;general mem

  ;; Various definitions
PPU_CTRL  =      $2000
PPU_MASK  =      $2001
PPU_STATUS  =    $2002
OAM_ADDR  =      $2003
OAM_DATA  =      $2004
PPU_SCROLL  =    $2005
PPU_ADDR  =      $2006
PPU_DATA  =      $2007

PPU_OAM_DMA =    $4014
DMC_FREQ  =      $4010
APU_STATUS  =    $4015
APU_NOISE_VOL  = $400C
APU_NOISE_FREQ = $400E
APU_NOISE_TIMER= $400F
APU_DMC_CTRL   = $4010
APU_CHAN_CTRL  = $4015
APU_FRAME      = $4017


  .bank 0
  .org $D000

vblankwait:       ; First wait for vblank to make sure PPU is ready
  bit PPU_STATUS
  bpl vblankwait
  rts

Reset:

  sei          ; disable IRQs
  cld          ; disable decimal mode
  ldx #$40
  stx APU_FRAME    ; disable APU frame IRQ (4017)
  ldx #$FF
  txs          ; Set up stack
  inx          ; now X = 0
  stx PPU_CTRL    ; disable NMI (2000)
  stx PPU_MASK    ; disable rendering (2001)
  stx DMC_FREQ    ; disable DMC IRQs (4010)
  stx APU_STATUS  ;disable APU sound (4015)
  jsr vblankwait

clrmem:
  lda #$00
  sta <$0000, x
  sta $0100, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  lda #$FE
  sta $0200, x    ;move all sprites off screen
  inx
  bne clrmem
  jsr vblankwait
  jmp start

start:
  jsr LoadPalettes
  jsr LoadBackground

  lda #%10010000
  sta PPU_CTRL
  jmp GameEngine


;; ########## Init subroutines ############

LoadBackground:
  lda PPU_STATUS         ; read PPU status to reset the high/low latch
  lda #$20
  sta PPU_ADDR           ; write the high byte of PPU_CTRL address
  lda #$00
  sta PPU_ADDR           ; write the low byte of PPU_CTRL address


  lda #LOW(background)
  sta <ptr
  lda #HIGH(background)
  sta <ptr+1
  
  
  ldx #$00              ; start out at x=0
  ldy #$00              ; start out at y=0
  .outer_loop:
    .inner_loop:
      lda [ptr], y    
      sta PPU_DATA          
      iny                   
      cpy #$00              
      bne  .inner_loop

      inc <ptr+1         
      inx                   
      cpx #$04              
      bne .outer_loop
  .load_done:
    rts


LoadPalettes:
  lda PPU_STATUS   ;Read state PPU (reset)
  lda #$3F
  sta PPU_ADDR   ;Store High byte of PPU
  lda #$00
  sta PPU_ADDR   ;Store Low byte
  ldx #$00
  .loop:
    lda palette, x
    sta PPU_DATA
    inx
    cpx #$20
    bne .loop
  rts



NMI:
  ; save registers
  pha
  txa
  pha
  tya
  pha

    ;;This is the PPU clean up section, so rendering the next frame starts properly.
    .ppu_cleanup:
      lda #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
      sta PPU_CTRL
      lda #%00011110   ; enable sprites, enable background, no clipping on left side
      sta PPU_MASK
      lda #$00        ;;tell the ppu there is no background scrolling
      sta PPU_SCROLL
      sta PPU_SCROLL

    .nmi_end:
      ; restore registers and return
      pla
      tay
      pla
      tax
      pla
      rti

irq:
  rti


  
GameEngine:
  jmp GameEngine


  


  .bank 1
  .org $A000


background:
  .incbin "[$name].dat"
attributes:
  .incbin "[$name].attr"





; First bytes of first sprite palette defines the background color
palette:
  .incbin "[$name].pal"
  .incbin "[$name].pal"


  .org $FFFA      ;first of the three vectors starts here
  .dw NMI         
  .dw Reset       
  .dw irq         


  ;; #################################### ;;


  .bank 2
  .org $0000
  .incbin "[$name].chr"   ;includes 8KB graphics file
