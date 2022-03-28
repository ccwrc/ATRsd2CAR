;-----------------------------------------------------------------------		
;
; ATRsd2CAR starter for SWITCHABLE XEGS CARTRIDGE
; (c) 2022 GienekP
;
;-----------------------------------------------------------------------

TMP     = $A0

;-----------------------------------------------------------------------

BUFADR  = $15
RAMTOP  = $6A

DSKTIM  = $0246
DMACTLS = $022F
DSCTLN  = $02D5
MEMTOP  = $02E5
DVSTAT  = $02EA

DDEVIC  = $0300
DCMND   = $0302
DSTATS  = $0303
DBUFA   = $0304
DTIMLO  = $0306
DBYT    = $0308
DAUX1	= $030A
DAUX2	= $030B
BASICF  = $03F8
GINTLK  = $03FA

TRIG3   = $D013
IRQEN   = $D20E
IRQST   = $D20E
PORTB   = $D301
DMACTL  = $D400
VCOUNT  = $D40B
NMIEN   = $D40E

WAIT	= $C0DF
RESETWM = $C290
BOOT    = $C58B
DSKINT  = $C6B3
PUTADR  = $C73A	
JDSKINT = $E453
JSIOINT = $E459

;-----------------------------------------------------------------------		
; SWITCHABLE XEGS CARTRIDGE

		OPT h-f+
		
		ORG $A000

;-----------------------------------------------------------------------		
; INITCART ROUTINE

INIT		rts
	
;-----------------------------------------------------------------------		
; CARTRUN ROUTINE
	
BEGIN		jsr IRQDIS
		jsr ROM2RAM
		jsr SETRAM
		jsr OVRDINT
		jsr IRQENB
		jsr RESERVE
		jmp BYEBYE
	
;-----------------------------------------------------------------------		
; IRQ ENABLE

IRQENB		lda #$40
		sta NMIEN
		lda #$F7
		sta IRQST
		lda DMACTLS
		sta DMACTL
		cli
		rts

;-----------------------------------------------------------------------		
; IRQ DISABLE

IRQDIS		sei	
		lda #$00
		sta DMACTL
		sta NMIEN
		sta IRQEN
		sta IRQST
		rts
		
;-----------------------------------------------------------------------		
; COPY ROM TO RAM
	
ROM2RAM		lda #$C0
		sta TMP+1
		ldy #$00
		sty TMP
L3		lda (TMP),Y
		tax 
		lda #$FE
		and PORTB
		sta PORTB
		txa 
		sta (TMP),Y
		lda #$01
		ora PORTB
		sta PORTB
		iny
		cpy #0
		bne L3
NOK		inc TMP+1
		clc
		lda TMP+1
		cmp #$D0
		bcc T1
		cmp #$D8
		bcc NOK
T1		cmp #$00
		bne L3
		clc 
		rts
;-----------------------------------------------------------------------		
; SET RAM & DISABLE BASIC

SETRAM		lda PORTB
		and #$FE
		ora #$02
		sta PORTB
		lda #$01
		sta BASICF
		rts
;-----------------------------------------------------------------------		
; COPY NEW DSKINT PROCEDURE

OVRDINT		lda #<SRTCPY
		sta TMP
		lda #>SRTCPY
		sta TMP+1
		lda JDSKINT+1
		sta TMP+2
		lda JDSKINT+2
		sta TMP+3
			
		ldy #ENDCPY-SRTCPY-1
LPCPY		lda (TMP),Y
		sta (TMP+2),Y
		dey
		bne LPCPY
		lda (TMP),Y
		sta (TMP+2),Y
		
		;lda #$00
		;sta JDSKINT+1
		;lda #$01
		;sta JDSKINT+2
		
		lda RESETWM+2		; don't test cart exchange RESET
		sta RESETWM+5
		lda RESETWM+3
		sta RESETWM+6
		
		lda WAIT+69		; don't test cart exchange SYSVBL
		sta WAIT+72
		lda WAIT+70
		sta WAIT+73	
		
		rts
;-----------------------------------------------------------------------		
; COPY TO ZEROPAGE FOR "KILLERS" PORTB

RESERVE		lda #<ZEROCP
		sta TMP
		lda #>ZEROCP
		sta TMP+1
		lda #$00
		sta TMP+2
		lda #$01
		sta TMP+3
			
		ldy #ZEROEND-ZEROCP-1
RESCPY		lda (TMP),Y
		sta (TMP+2),Y
		dey
		bne RESCPY
		lda (TMP),Y
		sta (TMP+2),Y
		
		rts
;-----------------------------------------------------------------------		
; LEAVE CART SPACE
		
BYEBYE		lda #$1F
		sta MEMTOP
		lda #$BC
		sta MEMTOP+1
		lda #$C0
		sta RAMTOP

		jmp $0100+GOBOOT-ZEROCP

;-----------------------------------------------------------------------		
; OLD DiSK INTerface

DSKINTO		lda #$31
		sta DDEVIC
		lda DSKTIM
		ldx DCMND
		cpx #$21
		beq STM
		lda #$07
STM 		sta DTIMLO
		ldx #$40
		lda DCMND
		cmp #$50
		beq WRT
		cmp #$57
		bne READ
WRT		ldx #$80
READ		cmp #$53
		bne DSL
		lda #<DVSTAT
		sta DBUFA
		lda #>DVSTAT
		sta DBUFA+1
		ldy #$04
		lda #$00
		beq SPM
DSL		ldy DSCTLN
		lda DSCTLN+1
SPM		stx DSTATS
		sty DBYT
		sta DBYT+1
		jsr JSIOINT
		bpl SUC
		rts
SUC		lda DCMND
		cmp #$53
		bne FRMT
		jsr PUTADR
		ldy #$02
		lda (BUFADR),Y
		sta DSKTIM
FRMT		lda DCMND
		CMP #$21
		BNE EXIT
		jsr PUTADR
		ldy #$FE
LOOP1		iny
		iny
LOOP2		lda (BUFADR),Y
		cmp #$FF
		bne LOOP1
		iny
		lda (BUFADR),Y
		iny
		cmp #$FF
		bne LOOP2
		dey
		dey
		sty DBYT
		lda #$00
		sta DBYT+1
EXIT		ldy DSTATS
		rts
		
;-----------------------------------------------------------------------		
; NEW DiSK INTerface

SRTCPY
.local DSKINT_new,$C6B3

		nop
		nop			; ONLY TRIM TO $C739
		nop
		lda DCMND
		cmp #$52
		beq SECREAD
		clc
		bcc STATOK
;.......................................................................		
SECREAD		lda DAUX1
		cmp #$00
		bne NOCORR1
		dec DAUX2
NOCORR1		dec DAUX1
		lda DAUX1
		and #$01
		cmp #$01
		bne NOHALF
		lda #$80
NOHALF		sta TMP
		lda DAUX1
		lsr
		and #$1F
		clc
		adc #$80
		sta TMP+1	
		lda DAUX2
		asl
		asl
		and #$7F
		sta TMP+4
		lda DAUX1
		lsr
		lsr
		lsr
		lsr
		lsr
		lsr
		ora TMP+4
		sta TMP+4		
		lda DAUX1
		cmp #$FF
		bne NOCORR2
		inc DAUX2
NOCORR2 	inc DAUX1				
		lda DBUFA
		sta TMP+2
		lda DBUFA+1
		sta TMP+3
;.......................................................................				
LOOP		lda VCOUNT
		cmp #$82
		bne LOOP		
		ldy #$00
CPYSECT 	ldx TMP+4
		stx $D500
		lda (TMP),Y
		ldx #$FF
		stx $D500
		sta (TMP+2),Y
		iny
		cpy #$80
		bne CPYSECT
STATOK		ldy #$01
		sty DSTATS
		
FINISH		lda TRIG3
		sta GINTLK
		rts

.end
ENDCPY	; --->>> $C739

;-----------------------------------------------------------------------		
; ZEROPAGE DiSK INTerface
; RELOC CODE FOR $0100

ZEROCP		
ZLOOP		lda VCOUNT
		cmp #$82
		bne ZLOOP		
		ldy #$00
		sty $D500
		jmp AROUND
CATCH		ldx TMP+4	; $010F
		stx $D500
		lda (TMP),Y
		ldx #$FF
		stx $D500
		sta (TMP+2),Y
		iny
		cpy #$80
		bne CATCH
		ldy #$01
		sty DSTATS	
				
BACK		lda #$FF	; $0127
		sta $D500
		lda TRIG3
		sta GINTLK
		rts
;		
;	additional trik for future use
;
;		$0133 <- JUMP IF NEED OLD PROCEDURE
;
		lda #$00	; $0133
		sta $D500		
		jsr DSKINTO
		clc
		bne BACK
		
GOBOOT		lda #$FF	; $013E
		sta $D500
		lda TRIG3
		sta GINTLK
		jmp BOOT
		
ZEROEND

;-----------------------------------------------------------------------		
; AROUND DiSK INTerface

AROUND		lda DCMND
		cmp #$52
		beq SECREAD
		jsr DSKINTO
		jmp $0100+BACK-ZEROCP
;.......................................................................		
SECREAD		lda DAUX1
		cmp #$00
		bne NOCORR1
		dec DAUX2
NOCORR1		dec DAUX1
		lda DAUX1
		and #$01
		cmp #$01
		bne NOHALF
		lda #$80
NOHALF		sta TMP
		lda DAUX1
		lsr
		and #$1F
		clc
		adc #$80
		sta TMP+1	
		lda DAUX2
		asl
		asl
		and #$7F
		sta TMP+4
		lda DAUX1
		lsr
		lsr
		lsr
		lsr
		lsr
		lsr
		ora TMP+4
		sta TMP+4		
		lda DAUX1
		cmp #$FF
		bne NOCORR2
		inc DAUX2
NOCORR2 	inc DAUX1				
		lda DBUFA
		sta TMP+2
		lda DBUFA+1
		sta TMP+3
;.......................................................................	
		jmp $0100+CATCH-ZEROCP

;-----------------------------------------------------------------------		

		ORG $BFFA
		dta <BEGIN, >BEGIN, $00, $04, <INIT, >INIT

;-----------------------------------------------------------------------		
