	DSK DROPBLOCK

**************************************************
* single-player mode - add 1 or 2 switch?
**************************************************
* Variables
**************************************************

ROW				EQU		$FA			; row/col in text screen
COLUMN			EQU		$FB
CHAR			EQU		$FC			; char/pixel to plot
PLOTROW			EQU		$FE			; row/col in text page
PLOTCOLUMN		EQU		$FF
RNDSEED			EQU		$EA			; +eb +ec
BLOCKCHAR		EQU		$CE			; color of current dropping block
NEXTBLOCK		EQU		$CD			; color of next block to drop
BLOCKROW		EQU		$1D			; dropping block row
BLOCKCOLUMN		EQU		$1E			; dropping block column
PLAYERS			EQU		$40			; in attract mode? 0, 1 or 2 players
PROCESSING		EQU		$41			; do we need to loop again?

BORDERCOLOR		EQU		$09			; border color changes to indicate level up
SWITCHSIDE		EQU		$0A	
PROGRESS 		EQU		$FD			; cleared blocks

PROGRESSBARL	EQU		$1F			; length of the progress bar

BUMPFLAG		EQU		$1C			; whether to bump up opponent's pixels

FIELDLEFT		EQU		$ED	
FIELDRIGHT		EQU		$EF	
LOSEFLAG		EQU		$CC			; lose the game


**************************************************
* Apple Standard Memory Locations
**************************************************
CLRLORES  	EQU	$F832
LORES     	EQU	$C050
TXTSET    	EQU	$C051
MIXCLR    	EQU	$C052
MIXSET    	EQU	$C053
TXTPAGE1  	EQU	$C054
TXTPAGE2  	EQU	$C055
KEY       	EQU	$C000
C80STOREOF	EQU	$C000
C80STOREON	EQU	$C001
STROBE    	EQU	$C010
SPEAKER   	EQU	$C030
VBL       	EQU	$C02E
RDVBLBAR  	EQU	$C019       ;not VBL (VBL signal low
WAIT		EQU	$FCA8 
RAMWRTAUX 	EQU	$C005
RAMWRTMAIN	EQU	$C004
SETAN3    	EQU	$C05E       ;Set annunciator-3 output to 0
SET80VID  	EQU	$C00D       ;enable 80-column display mode (WR-only)
CLR80VID	EQU	$C00C
HOME 		EQU	$FC58			; clear the text screen
CH        	EQU	$24			; cursor Horiz
CV        	EQU	$25			; cursor Vert
VTAB      	EQU	$FC22       ; Sets the cursor vertical position (from CV)
COUT      	EQU	$FDED       ; Calls the output routine whose address is stored in CSW,
          	   	            ;  normally COUTI
STROUT		EQU	$DB3A 		;Y=String ptr high, A=String ptr low
		
ALTTEXT		EQU	$C055
ALTTEXTOFF	EQU	$C054
	
ROMINIT   	EQU    $FB2F
ROMSETKBD 	EQU    $FE89
ROMSETVID 	EQU    $FE93
	
ALTCHAR		EQU		$C00F		; enables alternative character set - mousetext
	
BLINK		EQU		$F3
SPEED		EQU		$F1


**************************************************
* START - sets up various fiddly zero page bits
**************************************************

				ORG $2000						; PROGRAM DATA STARTS AT $2000

				JSR   SPLASHSCREEN				; Interrupt Game right at the start


				JSR ROMSETVID           	 	; Init char output hook at $36/$37
				JSR ROMSETKBD           	 	; Init key input hook at $38/$39
				JSR ROMINIT               	 	; GR/HGR off, Text page 1
				
				LDA #$00
				STA BLINK						; blinking text? no thanks.
				STA LORES						; low res graphics mode
				STA MIXCLR						; For IIGS
				STA PLAYERSCORE
				STA PLAYERSCORE+1
				STA BORDERCOLOR					; border starts pink (BB) from BORDERCOLORS LUT
				STA SWITCHSIDE
				STA BUMPFLAG					
				STA LOSEFLAG

				lda #$01
				sta $c029
				lda SETAN3
				sta CLR80VID 					; turn 80 column off

				LDA #$00						; all the way to the left side
				STA FIELDLEFT
				CLC
				ADC #$14						; 20 columns wide to start
				STA FIELDRIGHT				

				JSR CLRLORES					; clear screen		

				JSR DRAWBOARD
;				LDA #$00
;				STA PLAYERS						; start in ATTRACT mode, 0 players
				
				JSR RANDOMBLOCK					; get a block color
				STA NEXTBLOCK					; get initial block color
				
**************************************************
*	ATTRACT LOOP
*	waits for keyboard input, plays at random
**************************************************

;ATTRACT		
;
;* attract loop animation? instructions?
;				JSR NEXTSCREEN
;
;				LDA LOSEFLAG			; did the game end?
;				BNE LOSEGAME
;
;				LDA KEY					; check for keydown
;				CMP #$B2				; 2 for 2 player
;				BEQ STARTGAME2			; 
;
;				CMP #$B1				; 1 for 1 player
;				BEQ STARTGAME1			; 
;
;				CMP #$9B				; ESC
;				BEQ END					; exit on ESC?
;
;				LDA SPEED				; let's do an interframe delay
;				JSR WAIT
;
;				JMP ATTRACT
;				
;STARTGAME1		STA STROBE
;				LDA #$01
;				STA PLAYERS				; start in 1 player mode (for now)
;				JMP PLAYBALL			
;
;STARTGAME2		STA STROBE
;				LDA #$02
;				STA PLAYERS				; start in 2 player mode (for now)
;				JMP PLAYBALL			
;



PLAYBALL		;LDA #$01
				;STA PLAYERS				; leave ATTRACT mode
				JSR RESTART
				JMP MAINLOOP

END				STA STROBE
				STA ALTTEXTOFF
				STA TXTSET
				JSR HOME
				RTS						; END	



**************************************************
*	MAIN LOOP
*	waits for keyboard input
**************************************************

MAIN		
MAINLOOP		

				LDA KEY					; check for keydown

				CMP #$D2				; R to reset
				BEQ PLAYBALL

				CMP #$9B				; ESC
				BEQ END					; exit on ESC?

				LDA FIELDLEFT
				BEQ LEFTSIDE

				LDA KEY					; check for keydown

RIGHTSIDE		CMP #$CA				; J
				BEQ GOTLEFT
				CMP #$EA				; J
				BEQ GOTLEFT

				CMP #$CC				; L
				BEQ GOTRIGHT
				CMP #$EC				; L
				BEQ GOTRIGHT

				CMP #$CB				; K
				BEQ NODELAY
				CMP #$EB				; K
				BEQ NODELAY

				JMP LOADDELAY

				

LEFTSIDE
				LDA KEY					; check for keydown
				CMP #$C1				; A
				BEQ GOTLEFT
				CMP #$E1				; A
				BEQ GOTLEFT

				CMP #$C4				; D
				BEQ GOTRIGHT
				CMP #$E4				; D
				BEQ GOTRIGHT

				CMP #$F3				; S
				BEQ NODELAY
				CMP #$D3				; S
				BEQ NODELAY


LOADDELAY		LDA SPEED				; let's do an interframe delay
				CMP #$40
				BCC GOFAST				; #$40 is plenty fast
				JSR WAIT
				JMP NODELAY

GOFAST			LDA #$40				; if it's gone below #$40, then reset to 40 (#01 is no delay)
				STA SPEED
				JSR WAIT

NODELAY			
				JSR NEXTSCREEN			; animate one frame per loop

				LDA LOSEFLAG			; did the game end?
				BNE LOSEGAME

GOLOOP			JMP MAINLOOP			; loop until a key
								

**************************************************
*	keyboard input handling
**************************************************
				
GOTLEFT			STA STROBE
				JSR MOVEBLOCKLEFT
				JMP MAINLOOP

GOTRIGHT		STA STROBE
				JSR MOVEBLOCKRIGHT
				JMP MAINLOOP

GOTRESET		;LDA #$00
				;STA PLAYERS				; ATTRACT mode
				JSR RESTART
				JMP PLAYBALL				; otherwise, attract loop.


RESTART			LDA #$00
				STA STROBE
				STA BORDERCOLOR
				STA LOSEFLAG
				STA FIELDLEFT
				CLC
				ADC #$14				; 20 columns to start
				STA FIELDRIGHT

				JSR DRAWBOARD
				JSR RESETSCORE

				LDA #$01				
				STA PLOTROW				; stop the current block from polluting the new game
				STA BLOCKROW
				STA SWITCHSIDE			; reset for next turn
				JSR SWITCHSIDES

				JSR RANDOMBLOCK			; get a new block color to start off with.
				STA BLOCKCHAR
				STA NEXTBLOCK
	
				RTS

*** LOSE FLAG

LOSEGAME		JSR BONK
				LDA #$17
				STA BLOCKROW

LOSELOOP		LDA #$1
				STA BUMPFLAG			; just do this once (for now)
				JSR BUMPPIXELS
				JSR CLICK				; bump playfield up and CLICK?

				DEC BLOCKROW
				BNE LOSELOOP			

				LDA PLAYERS			; in attract mode or not?
				BNE STARTOVER			; start at level 1
				JMP GOTRESET			; reset in attract mode
				
STARTOVER		JMP PLAYBALL			; 

*** LOSE GAME
				

					

**************************************************
*	subroutines
**************************************************

**************************************************
*	move the falling block left/right on keystroke
**************************************************

MOVEBLOCKLEFT							; got left
				LDA FIELDLEFT
				CLC
				ADC #$02				; if BLOCKCOLUMN = #02, can't move left					
				CMP BLOCKCOLUMN
				BEQ DONEMOVING
				
				JSR GETBLOCKPOS			; if pixel-2 color != black, can't move left.
				DEC PLOTCOLUMN
				DEC PLOTCOLUMN
				JSR GETCHAR		
				BNE DONEMOVING
				
				JSR GETBLOCKCOLOR		; get the current block's color
				
				JSR CLEARBLOCKL			; set current block to black
				
				DEC PLOTCOLUMN			; move left 2 px
				DEC PLOTCOLUMN
				DEC BLOCKCOLUMN
				DEC BLOCKCOLUMN
				LDA BLOCKCHAR
				STA CHAR				; set pixel color
				JSR PLOTQUICK			; color new pixel position
				DEC PLOTCOLUMN
				JSR PLOTQUICK				
				JMP DONEMOVING

MOVEBLOCKRIGHT							; got left
				LDA FIELDRIGHT
				SEC
				SBC #$04				; if BLOCKCOLUMN = #12, can't move right						
				CMP BLOCKCOLUMN
				BEQ DONEMOVING

				JSR GETBLOCKPOS			; if pixel+2 color != black, can't move left.
				INC PLOTCOLUMN
				INC PLOTCOLUMN
				JSR GETCHAR		
				BNE DONEMOVING
				
				JSR GETBLOCKCOLOR		; get the current block's color
				
				JSR CLEARBLOCKL			; set current block to black
				
				;INC PLOTCOLUMN			; move right 2 px (1 done in clearblock)
				INC PLOTCOLUMN
				INC BLOCKCOLUMN
				INC BLOCKCOLUMN
				LDA BLOCKCHAR
				STA CHAR				; set pixel color
				JSR PLOTQUICK			; color new pixel position
				INC PLOTCOLUMN
				JSR PLOTQUICK				

DONEMOVING		RTS

**************************************************
*	where is the dropping block now, what color is it?
**************************************************
GETBLOCKPOS		LDX BLOCKCOLUMN			; get current block position
				STX PLOTCOLUMN
				LDX BLOCKROW
				STX PLOTROW
				RTS
;/GETBLOCKPOS
GETBLOCKCOLOR	JSR GETBLOCKPOS			; get current block color
				JSR GETCHAR		
				STA BLOCKCHAR			; store it in BLOCKCHAR
				RTS
;/GETBLOCKCOLOR

**************************************************
*	main animation loop
*	
*	if not processing/compacting,
* 	drops the active block 
*	otherwise, processes the existing
*	blocks to compact them
*	then adds new active block
**************************************************

NEXTSCREEN

*	MAIN LOOP

RESETPROCESSING	LDA #$00				; PROCESSING = 0
				STA PROCESSING
DROPBLOCK		
* shortcut to drop just the next block, instead of having to search each pixel
				JSR GETBLOCKPOS
				INC PLOTROW				
				JSR GETCHAR				; pixel below value to A
				BNE PROCESSPIXELS		; not black, done dropping the block. go on to check for others to drop

FALLBLOCK		LDA BLOCKCHAR			; store block color to CHAR
				STA CHAR
				JSR PLOTQUICK
				INC PLOTCOLUMN
				JSR PLOTQUICK
				DEC PLOTCOLUMN
				DEC PLOTROW
				JSR CLEARBLOCKL
				INC BLOCKROW			; drop down to do it again
				RTS						; shortcut.

PROCESSPIXELS								
				JSR COMBINEPIXELS		; combines neighbors
				JSR COLLAPSE			; drops into blank spaces
				
				LDA PROCESSING			; PROCESSING updated with each combine action
				BNE PROCESSPIXELS		; keep combining until done.

				LDA PLAYERS				; how many players?
				CMP #$01
				BEQ DRAWNEXTBLOCK		; 1 player - skip the switchside

TOURNAMENTMODE							;0/2 PLAYER MODE							
				LDA SWITCHSIDE			
				BEQ DRAWNEXTBLOCK		; with each new point, switch sides

				LDA #$0
				STA SWITCHSIDE			; reset for next turn

				JSR SWITCHSIDES
							
DRAWNEXTBLOCK							; all done PROCESSING/combining, add new block at top of screen
										; draw upcoming block at 0, move previous upcoming down to 1
				STA STROBE				; clear out the keyboard buffer from fast drop
				LDA #$0				
				STA PLOTROW
				STA BLOCKROW
	
				LDA PLAYERS				; if PLAYERS=0, do random column. 
				BNE MIDDLETOP			; 1 or 2 =done attracting, now playing with block in middle
				JSR RANDOMCOLUMN		; gets random column from 2-18 for attract mode
				JMP RANDOMTOP
				
MIDDLETOP		JSR CENTERCOLUMN	

RANDOMTOP		STA PLOTCOLUMN			
				STA BLOCKCOLUMN										
				
				LDA NEXTBLOCK
				STA BLOCKCHAR			; transfer upcoming block to current

				JSR RANDOMBLOCK			; get a block color
				STA CHAR
				STA NEXTBLOCK			; color of upcoming block
				JSR PLOTQUICK
				INC PLOTCOLUMN
				JSR PLOTQUICK
				
				INC PLOTROW				; down to row 1
				INC BLOCKROW			; set falling block position
				DEC PLOTCOLUMN			

GETNEXTBLOCK	LDA BLOCKCHAR			; take current block color and draw the dropping block	
				STA CHAR
				JSR PLOTQUICK
				INC PLOTCOLUMN
				JSR PLOTQUICK
				

NEXTSCREENDONE	RTS

;/NEXTSCREEN		




**************************************************
* TOURNAMENT / 2 PLAYER MODE
**************************************************

SWITCHSIDES

										; clear the upcoming block from current side
				JSR CENTERCOLUMN		; get center COLUMN
				STA PLOTCOLUMN
				LDA #$0
				STA PLOTROW
				STA CHAR
				JSR PLOTQUICK
				INC PLOTCOLUMN
				JSR PLOTQUICK			; clear upcoming block

				LDA FIELDLEFT			
				BNE NEXTSIDE			; if FIELDORIGIN is 0, set it to 20
				LDA #$14				; else set to 0
				JMP NEXTSIDE2
NEXTSIDE		LDA #$00
NEXTSIDE2		STA FIELDLEFT

				CLC
				ADC #$14				; move right border as well
				STA FIELDRIGHT

				LDA BUMPFLAG			; flagged to bump up?
				BEQ NEXTSIDE3			; 0 skip
				JSR BUMPPIXELS			; bump pixels up if flagged

NEXTSIDE3		RTS
;/SWITCHSIDES



**************************************************
* returns with "middle" column in accumulator
**************************************************

CENTERCOLUMN	LDA FIELDRIGHT			; move drop location to between left/right borders
				SEC
				SBC FIELDLEFT			; get width as right-LEFT
				CLC
				LSR						; divide by 2
				AND #$FE				; divisible by 2
				CLC
				ADC FIELDLEFT			; add left offset.
				RTS	
;/CENTERCOLUMN



**************************************************
*	Draw the playfield(s)
**************************************************


DRAWBOARD		JSR HOME							

				LDA #$A0
				STA SPEED						; re-using the applesoft variable. fun.


				STA ALTTEXTOFF					; display main text page
				JSR RNDINIT						; *should* cycle the random seed.
				LDA #$00

				STA PROCESSING

; FOR EACH ROW/COLUMN

				LDA #$18				; 
				STA PLOTROW
ROWLOOP2 								; (ROW 40 to 0)
				DEC PLOTROW				;	start columnloop (COLUMN 0 to 40)
				LDA #$28
				STA PLOTCOLUMN
COLUMNLOOP2		DEC PLOTCOLUMN	

				LDA PLOTROW				
PLOTZERO		LDA #$00				; set all pixels to 00
PLOTLINE		STA CHAR
				JSR PLOTQUICK			; plot 00

				LDA PLOTCOLUMN			; last COLUMN?
				BNE COLUMNLOOP2			; loop

;	/columnloop2
			
				LDA PLOTROW				; last ROW?
				BNE ROWLOOP2			; loop 
	
; 	/rowloop2		

				JSR DRAWBORDER
				LDA #$14				
				STA FIELDLEFT
				CLC
				ADC #$14				; move right border as well
				STA FIELDRIGHT			

				JSR DRAWBORDER
				
				RTS

**************************************************
*	Draws the pink border
**************************************************

DRAWBORDER								; draws the pink border line
				
LEFTLINE		LDA FIELDLEFT					; column 0
				STA PLOTCOLUMN
				LDX BORDERCOLOR			; which color to use 
				LDA BORDERCOLORS,X		; lookup table of colors
				STA CHAR
				LDA #$18				; row 23 to 0				
				STA PLOTROW
LEFTLINELOOP	DEC PLOTROW
				JSR PLOTQUICK			; plot CHAR
				
				INC PLOTCOLUMN			; black sub-border
				LDA #$0
				STA CHAR
				JSR PLOTQUICK			; plot CHAR
				DEC PLOTCOLUMN
				LDX BORDERCOLOR			; which color to use 
				LDA BORDERCOLORS,X		; lookup table of colors
				STA CHAR
				
				LDA PLOTROW				; last ROW?
				BNE LEFTLINELOOP		; draw next row of line
										
RIGHTLINE		LDX FIELDRIGHT
				DEX						; column 20 to 0
				STX PLOTCOLUMN
				LDX BORDERCOLOR			; which color to use 
				LDA BORDERCOLORS,X		; lookup table of colors
				STA CHAR
				LDA #$18				; row 23 to 0				
				STA PLOTROW
RIGHTLINELOOP	DEC PLOTROW
				JSR PLOTQUICK			; plot CHAR
				
				DEC PLOTCOLUMN			; black sub-border
				LDA #$0
				STA CHAR
				JSR PLOTQUICK			; plot CHAR
				INC PLOTCOLUMN
				
				LDX BORDERCOLOR			; which color to use 
				LDA BORDERCOLORS,X		; lookup table of colors
				STA CHAR
							
				LDA PLOTROW				; last ROW?
				BNE RIGHTLINELOOP		; draw next row of line

TOPLINE			LDA #$0					; row 0
				STA PLOTROW
				
				LDX BORDERCOLOR			; which color to use 
				LDA BORDERCOLORS,X		; lookup table of colors
				AND #$0F				; clear top nibble
				STA CHAR

				LDX FIELDRIGHT
				DEX						; column 20 to 0
				STX PLOTCOLUMN			
TOPLINELOOP		DEC PLOTCOLUMN
				JSR PLOTQUICK			; PLOT CHAR
				LDA PLOTCOLUMN			; last COLUMN?
				SEC
				SBC #$01
				CMP FIELDLEFT
				BNE TOPLINELOOP			; draw next column of line
				
BASELINE		LDA #$17				; row 24
				STA PLOTROW
				LDX BORDERCOLOR			; which color to use 
				LDA BORDERCOLORS,X		; lookup table of colors
				AND #$0F				; clear bottom nibble
				ORA #$50				; adds dark grey to bottom
				STA CHAR

				LDA FIELDLEFT
				CLC
				ADC #$14				; baseline is 20px wide
				
				STA PLOTCOLUMN			
BASELINELOOP	DEC PLOTCOLUMN
				JSR PLOTQUICK			; PLOT CHAR
				LDA PLOTCOLUMN			; last COLUMN?
				CMP FIELDLEFT
				BNE BASELINELOOP		; draw next column of line

				RTS
;/DRAWBORDER				


**************************************************
* clears score
**************************************************


RESETSCORE	
				LDA #$00
				STA PLAYERSCORE
				STA PLAYERSCORE+1
				RTS
;/RESETSCORE				


**************************************************
*	creates a progress indicator at the bottom of the screen
**************************************************

PROGRESSBAR	
				LDA PLAYERSCORE+1		; score+1 = 0 to #99, divide by 4 to get 1-#26
				CLC							
				ROR						; divide by 2
				CLC	
				ROR						; 4
				STA PROGRESSBARL		; new length for progress bar
				
										; draw baseline from border with *color*
										; instead of grey from column 0 to score/8	
DRAWBAR			LDA #$17				; row 24
				STA PLOTROW
				LDX BORDERCOLOR			; which color to use 
				LDA BORDERCOLORS,X		; lookup table of colors
				AND #$0F				; clear bottom nibble
				ORA #$F0				; adds white to bottom
				STA CHAR
				LDA PROGRESSBARL
				BEQ NOBAR
				CLC
				STA PLOTCOLUMN			
DRAWBARLOOP		
				JSR PLOTQUICK			; PLOT CHAR
				;LDA PLOTCOLUMN			; last COLUMN?
				DEC PLOTCOLUMN
				BNE DRAWBARLOOP			; draw next column of line
				
NOBAR				RTS
;/PROGRESSBAR

**************************************************
*	blanks a 2px block - LEFT TO RIGHT
**************************************************
CLEARBLOCKL
				LDA #$00				; set block to black
				STA CHAR
				JSR PLOTQUICK
				INC PLOTCOLUMN
				JSR PLOTQUICK
				RTS
;CLEARBLOCKL


**************************************************
*	blanks a 2px block - RIGHT TO LEFT
**************************************************
CLEARBLOCKR
				LDA #$00				; set block to black
				STA CHAR
				JSR PLOTQUICK
				DEC PLOTCOLUMN
				JSR PLOTQUICK
				RTS
;CLEARBLOCKR

**************************************************
*	matches plot position to pixel getting processed 
**************************************************

RESETPIXEL		LDX COLUMN				; transfer checkpixel to plotpixel
				STX PLOTCOLUMN
				LDX ROW
				STX PLOTROW
				RTS
;/RESETPIXEL


**************************************************
*	loops through columns/rows to find neighboring
*	pixels that match. Shortcut stops processing
*	column when reaching a blank space 
**************************************************

COMBINEPIXELS
				LDA #$0					; reset PROCESSING
				STA PROCESSING

CHECKCOLUMN		LDX FIELDRIGHT
				DEX						; column 20 to 0
				DEX
				STX COLUMN
CHECKCOLUMNLOOP	DEC COLUMN

CHECKROW		LDA #$17				; start at row 23
				STA ROW
CHECKROWLOOP	DEC ROW				



RESETPROGRESS	LDA #$00				; reset progress
				STA PROGRESS			; how many blocks to delete?				
				JSR CHECKPIXEL			; check neighboring pixels to combine

				LDA BLOCKCHAR			; if the pixel checked was blank, 
				BEQ COLUMNSHORT			; done with the column
				
				

DONECHECKING

				LDA #$01				; at row 1?
				CMP ROW
				BNE CHECKROWLOOP		; loopty rows
				
				STA LOSEFLAG			; made it to ROW 1 - LOSE GAME
;/CHECKROWLOOP

COLUMNSHORT		LDA FIELDLEFT 
				CLC
				ADC #$02				; at COLUMN 2?
				CMP COLUMN
				BNE CHECKCOLUMNLOOP		; loopty columns
;/CHECKCOLUMNLOOP				
				

				RTS
;/COMBINEPIXELS



**************************************************
*	loops through columns/rows 
*	bumps each pixel up by one
**************************************************

BUMPPIXELS
				LDA #$0
				STA BUMPFLAG			; just do this once (for now)

BUMPCOLUMN		LDX FIELDRIGHT
				DEX
				DEX						; column 20 to 0
				STX COLUMN
BUMPCOLUMNLOOP	DEC COLUMN

BUMPROW			LDA #$0					; start at row 0
				STA ROW
BUMPROWLOOP		INC ROW				

				JSR BUMPPIXEL			; move pixels up by one

DONEBUMPING

				LDA #$16				; at row 22?
				CMP ROW
				BNE BUMPROWLOOP			; loopty rows
;/BUMPROWLOOP

BUMPSHORT		DEC COLUMN				; every other column
				LDA FIELDLEFT 
				CLC
				ADC #$02				; at COLUMN 2?
				CMP COLUMN
				BNE BUMPCOLUMNLOOP		; loopty columns
;/BUMPCOLUMNLOOP				
				

				LDA #$16				; row 23 needs random blocks
				STA ROW
RANDCOLUMN		LDX FIELDRIGHT
				DEX
				DEX						; column 20 to 0
				STX COLUMN
RANDCOLUMNLOOP	DEC COLUMN
				JSR RESETPIXEL
				LDA #$55				; shorten the playfield
				STA CHAR				; store px color
				JSR PLOTQUICK			; plot over pixel.
				DEC PLOTCOLUMN
				JSR PLOTQUICK			; plot over pixel.
				DEC COLUMN
				
				LDA COLUMN
				SEC
				SBC #$02
				CMP FIELDLEFT
				BNE RANDCOLUMNLOOP
				
				RTS
;/BUMPPIXELS



**************************************************
*	bumps each pixel up by one
**************************************************

BUMPPIXEL		JSR RESETPIXEL						
					
				JSR GETCHAR				; current pixel value to A
				STA BLOCKCHAR			; store current color
				BNE BUMPINGPX			; not blank, check on.
				RTS						; ==0, DONE CHECKING

BUMPINGPX		DEC PLOTROW				; go up 1 ROW	
				LDA BLOCKCHAR			; get pixel color
				STA CHAR				; store px color
				JSR PLOTQUICK			; plot over pixel above.
				DEC PLOTCOLUMN
				JSR PLOTQUICK			; plot over pixel-1 above.
				
				RTS



**************************************************
*	for each pixel position, checks neighbors for matches.
**************************************************
CHECKPIXEL								; get pixel color
				JSR RESETPIXEL						
					
				JSR GETCHAR				; current pixel value to A
				STA BLOCKCHAR			; store current color
				CMP #$55
				BEQ CHECKSHORT			; skip grey pixels.
				LDA BLOCKCHAR
				BNE CHECKINGPX			; not blank, check on.
CHECKSHORT		RTS						; ==0, DONE CHECKING
					
CHECKINGPX				
CHECKABOVE		DEC PLOTROW				; check above	
				JSR GETCHAR	
				CMP BLOCKCHAR
				BNE CHECKLEFT			; not equal, move on to check left side
CLEARABOVE		JSR CLEARBLOCKR
				INC PROGRESS

CHECKUPLEFT		JSR RESETPIXEL			; if the above pixel is a match, check diagonal			
				DEC PLOTCOLUMN
				DEC PLOTCOLUMN	
				DEC PLOTROW		
				JSR GETCHAR	
				CMP BLOCKCHAR
				BNE CHECKLEFT
CLEARUPLEFT		JSR CLEARBLOCKR							
				INC PROGRESS


CHECKLEFT		JSR RESETPIXEL						
				DEC PLOTCOLUMN
				DEC PLOTCOLUMN			
				JSR GETCHAR	
				CMP BLOCKCHAR
				BNE CHECKPROGRESS		; not equal, skip checking left+1
CLEARLEFT		JSR CLEARBLOCKR							
				INC PROGRESS

CHECKLEFT2		JSR RESETPIXEL						
				DEC PLOTCOLUMN
				DEC PLOTCOLUMN
				DEC PLOTCOLUMN
				DEC PLOTCOLUMN
				JSR GETCHAR	
				CMP BLOCKCHAR
				BNE CHECKLEFTDOWN		; not equal, check diagonal
CLEARLEFT2		JSR CLEARBLOCKR							
				INC PROGRESS

CHECKLEFTDOWN	JSR RESETPIXEL						
				DEC PLOTCOLUMN
				DEC PLOTCOLUMN	
				INC PLOTROW		
				JSR GETCHAR	
				CMP BLOCKCHAR
				BNE CHECKPROGRESS
CLEARLEFTDOWN	JSR CLEARBLOCKR							
				INC PROGRESS

CHECKPROGRESS	LDA PROGRESS				; if PROGRESS then clear the check block, too
				BEQ DONECHECKINGPX

				CMP #$02					; if progress == 2, then drop a grey block on opponent
				BNE COMBINE4
				LDX #$55
				STX NEXTBLOCK
				
COMBINE4		CMP #$03					; if progress == 3, then clear both lines?
				BNE CLEARBLOCK

				JSR CLEAR2LINES
				INC BUMPFLAG				; move everything up 1 line on next go-around
											; this prevents confusion with which columns are
											; bumping/clearing

				JSR INCSCORE10				; bump up score by 10
				JSR PROGRESSBAR
				JSR BONK

CLEARBLOCK		JSR RESETPIXEL
				JSR CLEARBLOCKR
				INC PROCESSING				; set the PROCESSING so we loop again
				JSR CLICK
				JSR INCSCORE
				JSR PROGRESSBAR	

				INC SWITCHSIDE


				
DONECHECKINGPX	RTS


**************************************************
*	for each column, clear the pixels in 2 rows.
*	reward for clearing 4 blocks at once
**************************************************


CLEAR2LINES		JSR RESETPIXEL			; go to row/column to clear						

				LDX FIELDRIGHT				; column 19 - 3
				DEX
				DEX
				STX PLOTCOLUMN
CLEARCOLUMN1	DEC PLOTCOLUMN

				JSR CLEARBLOCKR			; clear the block

				LDA FIELDLEFT
				CLC
				ADC #$02				; at COLUMN 2?
				CMP PLOTCOLUMN
				BNE CLEARCOLUMN1		; loopty columns
;/CLEARCOLUMN1				

				JSR RESETPIXEL			; second line...
				INC PLOTROW
				
				LDX FIELDRIGHT				; column 19 - 3
				DEX
				DEX
				STX PLOTCOLUMN
CLEARCOLUMN2	DEC PLOTCOLUMN

				JSR CLEARBLOCKR			; clear the block

				LDA FIELDLEFT
				CLC
				ADC #$02				; at COLUMN 2?
				CMP PLOTCOLUMN
				BNE CLEARCOLUMN2		; loopty columns
;/CLEARCOLUMN2				

				RTS
												
;/CLEAR2LINES






**************************************************
* Traverse each column up from the bottom, 
* removing blanks between colors.
*
* Shortcut to column complete when two blanks in a row.
**************************************************

COLLAPSE

EACHCOLUMN		LDX FIELDRIGHT				; column 19 - 3
				DEX
				DEX
				STX COLUMN
EACHCOLUMNLOOP	DEC COLUMN

EACHROW			LDA #$17				; start at row 23
				STA ROW
EACHROWLOOP		DEC ROW				



* check pixel *above* to see if it's black. 

EACHPIXEL		JSR RESETPIXEL			; transfer checkpixel to plotpixel
				
				JSR GETCHAR				; current pixel value to A
				BNE DONEDROPPING		; NONZERO=DONE CHECKING
										; BLANK. check if pixel above is NONZERO
				DEC PLOTROW
				JSR GETCHAR				;  (pixel above) value to A
				BEQ DONEDROPPING		;  ZERO, DONE CHECKING
				
				STA BLOCKCHAR			; store pixel above color 


DROPPIXEL								; COLOR ABOVE BLANK, drop pixel down
				INC PROCESSING			; PROCESSING++

				;LDA BLOCKCHAR			; block char in A
				STA CHAR				; store block color to CHAR
				INC PLOTROW				; back down to blank space
				JSR PLOTQUICK			; draw new block 1 row down

				LDA #$00				; set color to black
				STA CHAR
				DEC PLOTROW				; erase block
				JSR PLOTQUICK
;				JSR CLICK

DONEDROPPING
				
				LDA #$02				; at row 2?
				CMP ROW
				BNE EACHROWLOOP			; loopty rows
;/EACHROWLOOP

COLLAPSESHORT	
				LDA FIELDLEFT
				CLC
				ADC #$02				; at COLUMN 2?
				CMP COLUMN
				BNE EACHCOLUMNLOOP		; loopty columns
;/EACHCOLUMNLOOP				

COLLAPSEDONE	RTS
;/COLLAPSE

**************************************************
*	prints one CHAR at PLOTROW,PLOTCOLUMN - clobbers A,Y
*	used for plotting background elements that don't need collision detection
**************************************************
PLOTQUICK
				LDY PLOTROW
				TYA
				CMP #$18
				BCS OUTOFBOUNDS2			; stop plotting if dimensions are outside screen
				
				LDA LoLineTableL,Y
				STA $0
				LDA LoLineTableH,Y
				STA $1       		  		; now word/pointer at $0+$1 points to line 

LOADQUICK		
				LDY PLOTCOLUMN
				TYA
				CMP #$28
				BCS OUTOFBOUNDS2			; stop plotting if dimensions are outside screen

				STY $06						; hang onto Y for a sec...

				LDA CHAR
				LDY $06
				STA ($0),Y  

OUTOFBOUNDS2	RTS
;/PLOTQUICK			   
			   

**************************************************
*	GETS one CHAR at PLOTROW,PLOTCOLUMN - value returns in Accumulator - clobbers Y
**************************************************
GETCHAR
				LDY PLOTROW
				CLC

				LDA LoLineTableL,Y
				STA $0
				LDA LoLineTableH,Y

STORECHAR		STA $1       		  	; now word/pointer at $0+$1 points to line 
				LDY PLOTCOLUMN
				LDA ($0),Y  			; byte at row,col is now in accumulator
				RTS
;/GETCHAR					   

**************************************************
*	Increase player score by 1
**************************************************
INCSCORE		SED						; set decimal mode
				CLC
				LDA PLAYERSCORE+1				
				ADC #$01
				STA PLAYERSCORE+1
				
				
				BNE SCOREDONE			; if not rolled over, skip
				CLC						
				LDA PLAYERSCORE			; if rolled over to zero, add one to 100s byte
				ADC #$01
				STA PLAYERSCORE
				CLD

LEVELUP			INC BORDERCOLOR			; change border to indicate level up

										; make play field shorter, narrower with each levelup?
										; add to difficulty?


				LDA SPEED				; Increase speed?
				SEC
				SBC #$10				
				STA SPEED

				INC BUMPFLAG			; next frame, bump up the base. (oontz oontz)
				JSR BUMPPIXELS			; bump pixels up if flagged

SCOREDONE		CLD						; clear decimal mode

				RTS

**************************************************
*	Increase player score by 10
**************************************************				
INCSCORE10		LDX #$0A
LOOP10			JSR INCSCORE
				DEX		
				BNE LOOP10
				RTS				
;/INCSCORE10	
		
**************************************************
*	Gets a random color byte from BLOCKCOLORS
**************************************************

RANDOMBLOCK		JSR RND16		; gets 0-F
				TAX				; puts to X
				LDA BLOCKCOLORS,X	; gets byte from table
				RTS
;/RANDOMBLOCK

**************************************************
*	Gets a random BLOCK POSITION for attract mode
**************************************************

RANDOMCOLUMN	JSR RND16		; gets 0-F into accumulator
				CLC
				ADC FIELDLEFT	; adjust for left side of play field (0)
				
				ADC #$02		; column 2-18
				
				LDX FIELDRIGHT	; decrement right border for black space
				DEX
				DEX
				STX $06			; store this temporarily
				
				CMP $06			; compare to right border 
				BCS	RANDOMCOLUMN	; if too high, run again
				
				LSR				; divide by 2, remainder in Carry
				CLC				; clear remainder
				ROL				; multiply by 2, should result in an even number 2-18
				
				
				
				
				
				RTS
;/RANDOMCOLUMN


**************************************************
*	CLICKS and BEEPS - clobbers X,Y,A
**************************************************
CLICK			LDX #$06
CLICKLOOP		LDA #$10				; SLIGHT DELAY
				JSR WAIT
				LDA SPEAKER				
				DEX
				BNE CLICKLOOP
				RTS
;/CLICK

BEEP			LDX #$30
BEEPLOOP		LDA #$08				; short DELAY
				JSR WAIT
				LDA SPEAKER				
				DEX
				BNE BEEPLOOP
				RTS
;/BEEP


BONK			LDX #$50
BONKLOOP		LDA #$20				; longer DELAY
				JSR WAIT
				LDA SPEAKER				
				DEX
				BNE BONKLOOP
				RTS
;/BONK



**************************************************
* DATASOFT RND 6502
* BY JAMES GARON
* 10/02/86
* Thanks to John Brooks for this. I modified it slightly.
*
* returns a randomish number in Accumulator.
**************************************************
RNDINIT
				LDA	$C030			; #$AB
				STA	RNDSEED
				LDA	$4E				; #$55
				STA	RNDSEED+1
				LDA	PROCESSING		; #$7E
				STA	RNDSEED+2
				RTS	

* RESULT IN ACC
RND  			LDA	RNDSEED
     			ROL	RNDSEED
     			EOR	RNDSEED
     			ROR	RNDSEED
     			INC	RNDSEED+1
     			BNE	RND10
     			LDA	RNDSEED+2
     			INC	RNDSEED+2
RND10			ADC	RNDSEED+1
     			BVC	RND20
     			INC	RNDSEED+1
     			BNE	RND20
     			LDA	RNDSEED+2
     			INC	RNDSEED+2
RND20			STA	RNDSEED
     			RTS	

RND16			JSR RND			; limits RND output to 0-F
				AND #$0F		; strips high nibble
				RTS


**************************************************
* Thanks to Craig Bower for the splash screen 
*	and this code (I modified it slightly)
**************************************************

SPLASHSCREEN
										; move graphic data to $3000

					LDA   SPLASHLO		; Setup pointers to move memory
					STA   $3C			; $3C and $3D for source start
					LDA   SPLASHHI
					STA   $3D

					LDA   SPLASHLO
					STA   $3E			; $3E and $3F for source end
					LDA   SPLASHHI
					CLC
					ADC	#$04			; add $400 to start == end of graphic
					STA   $3F			; 

					LDA   #$00
					STA   $42			; $42 and $43 for destination
					LDA   #$30
					STA   $43
					LDA   #$00			; Clear ACC, X,Y for smooth operation
					TAX
					TAY
					JSR   $FE2C    		; F8ROM:MOVE	; Do the memory move



					LDA   #$15			; Kill 80-Column mode whether active or not
					JSR   $FDED    		; F8ROM:COUT
					
					STA   $C050   		; rw:TXTCLR	; Set Lo-res page 1, mixed graphics + text
					STA   $C053   		; rw:MIXSET
					STA   $C054   		; rw:TXTPAGE1
					STA   $C056   		; rw:LORES

										; display the data from $3000 at $400					
RESETVPTR			LDA   #$00			; Move titlepage from $3000 to $400 (screen)
					STA   $FE			; pointer for where we are at vertically on screen
					TAY					; Y-Reg used for indexing across (horiz) screen
VERTICALPTR			LDA   $FE			; pointer for where we are at vertically on screen
					JSR   $F847    		; F8ROM:GBASCALC

					LDA   $26
					STA   $FA			; $FA is our offset GBASL Byte (Source data titlepage)

					LDA   $27			; Add 04 w/ Carry to get to $3000 where graphic data is
					ADC	#$2C
					STA   $FB			; $FB is our offset GBASH Byte (Source data titlepage)
					
GRABSTORAGE			LDA   ($FA),Y		; Grab from storage
					STA   ($26),Y		; Put to screen
					INY
					CPY   #$28			; #$28 past the width of screen?
					BNE   GRABSTORAGE	; No?  Back for another round
					LDA   #$00
					TAX
					TAY

					
					INC   $FE			; Next line down vertically
					LDA   #$00
					TAX
					TAY
					LDA   $FE
					CMP   #$18			; #$18 bottom of screen?
					BNE   VERTICALPTR	; No? Go back and do next line down
					
					
					LDA   #$00
					STA   $C010    		; r:KBDSTRB 	; Clear keyboard strobe
					
										; LOOP HERE TO WAIT FOR KEYPRESS
SPLASHLOOP			LDA KEY				; check for keydown

					CMP #$B2				; 2 for 2 player
					BEQ STARTGAME2			; 
		
					CMP #$B1				; 1 for 1 player
					BEQ STARTGAME1			; 

					CMP #$B0				; 1 for 1 player
					BEQ STARTGAME0			; 

					JMP SPLASHLOOP		; got a key?
					
;/SPLASHSCREEN


STARTGAME0			STA STROBE
					LDA #$00
					STA PLAYERS				; start in 1 player mode (for now)
					RTS					; We now return you to your regular programming

STARTGAME1			STA STROBE
					LDA #$01
					STA PLAYERS				; start in 1 player mode (for now)
					RTS					; We now return you to your regular programming

STARTGAME2			STA STROBE
					LDA #$02
					STA PLAYERS				; start in 2 player mode (for now)
					RTS					; We now return you to your regular programming





**************************************************
* Data Tables
*
**************************************************
; Apple logo colors :)
BLOCKCOLORS		HEX	11,99,DD,CC,66,33,11,99,DD,CC,66,11,33,99,DD,CC
				HEX	11,99,DD,CC,66,33,11,99,DD,CC,66,11,33,99,DD,CC
				
;Goes up to 16 - hard mode?
;BLOCKCOLORS	HEX	11,22,33,44,55,66,77,88,99,AA,BB,CC,DD,EE,FF,11

; Player score, two bytes to go up to 9999
PLAYERSCORE		HEX 00,00


BORDERCOLORS	HEX BB,77,EE,AA,FF,44,22,33


**************************************************
* Lores/Text lines
* Thanks to Dagen Brock for this.
**************************************************
Lo01                 equ   $400
Lo02                 equ   $480
Lo03                 equ   $500
Lo04                 equ   $580
Lo05                 equ   $600
Lo06                 equ   $680
Lo07                 equ   $700
Lo08                 equ   $780
Lo09                 equ   $428
Lo10                 equ   $4a8
Lo11                 equ   $528
Lo12                 equ   $5a8
Lo13                 equ   $628
Lo14                 equ   $6a8
Lo15                 equ   $728
Lo16                 equ   $7a8
Lo17                 equ   $450
Lo18                 equ   $4d0
Lo19                 equ   $550
Lo20                 equ   $5d0
* the "plus four" lines
Lo21                 equ   $650
Lo22                 equ   $6d0
Lo23                 equ   $750
Lo24                 equ   $7d0

; alt text page lines
Alt01                 equ   $800
Alt02                 equ   $880
Alt03                 equ   $900
Alt04                 equ   $980
Alt05                 equ   $A00
Alt06                 equ   $A80
Alt07                 equ   $B00
Alt08                 equ   $B80
Alt09                 equ   $828
Alt10                 equ   $8a8
Alt11                 equ   $928
Alt12                 equ   $9a8
Alt13                 equ   $A28
Alt14                 equ   $Aa8
Alt15                 equ   $B28
Alt16                 equ   $Ba8
Alt17                 equ   $850
Alt18                 equ   $8d0
Alt19                 equ   $950
Alt20                 equ   $9d0
* the "plus four" lines
Alt21                 equ   $A50
Alt22                 equ   $Ad0
Alt23                 equ   $B50
Alt24                 equ   $Bd0




LoLineTable          da    	Lo01,Lo02,Lo03,Lo04
                     da    	Lo05,Lo06,Lo07,Lo08
                     da		Lo09,Lo10,Lo11,Lo12
                     da    	Lo13,Lo14,Lo15,Lo16
                     da		Lo17,Lo18,Lo19,Lo20
                     da		Lo21,Lo22,Lo23,Lo24

; alt text page
AltLineTable         da    	Alt01,Alt02,Alt03,Alt04
                     da    	Alt05,Alt06,Alt07,Alt08
                     da		Alt09,Alt10,Alt11,Alt12
                     da    	Alt13,Alt14,Alt15,Alt16
                     da		Alt17,Alt18,Alt19,Alt20
                     da		Alt21,Alt22,Alt23,Alt24


** Here we split the table for an optimization
** We can directly get our line numbers now
** Without using ASL
LoLineTableH         db    >Lo01,>Lo02,>Lo03
                     db    >Lo04,>Lo05,>Lo06
                     db    >Lo07,>Lo08,>Lo09
                     db    >Lo10,>Lo11,>Lo12
                     db    >Lo13,>Lo14,>Lo15
                     db    >Lo16,>Lo17,>Lo18
                     db    >Lo19,>Lo20,>Lo21
                     db    >Lo22,>Lo23,>Lo24
LoLineTableL         db    <Lo01,<Lo02,<Lo03
                     db    <Lo04,<Lo05,<Lo06
                     db    <Lo07,<Lo08,<Lo09
                     db    <Lo10,<Lo11,<Lo12
                     db    <Lo13,<Lo14,<Lo15
                     db    <Lo16,<Lo17,<Lo18
                     db    <Lo19,<Lo20,<Lo21
                     db    <Lo22,<Lo23,<Lo24

; alt text page
AltLineTableH        db    >Alt01,>Alt02,>Alt03
                     db    >Alt04,>Alt05,>Alt06
                     db    >Alt07,>Alt08,>Alt09
                     db    >Alt10,>Alt11,>Alt12
                     db    >Alt13,>Alt14,>Alt15
                     db    >Alt16,>Alt17,>Alt18
                     db    >Alt19,>Alt20,>Alt21
                     db    >Alt22,>Alt23,>Alt24
AltLineTableL        db    <Alt01,<Alt02,<Alt03
                     db    <Alt04,<Alt05,<Alt06
                     db    <Alt07,<Alt08,<Alt09
                     db    <Alt10,<Alt11,<Alt12
                     db    <Alt13,<Alt14,<Alt15
                     db    <Alt16,<Alt17,<Alt18
                     db    <Alt19,<Alt20,<Alt21
                     db    <Alt22,<Alt23,<Alt24


SPLASHLO			db	<SPLASHSCREENDATA
SPLASHHI			db	>SPLASHSCREENDATA

SPLASHTABLE			da SPLASHLO,SPLASHHI

SPLASHSCREENDATA	HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,66,77,FF,CF,44,44,CF,4C
					HEX	44,44,FF,77,00,00,CC,00,00,00,00,CC,00,00,CC,00
					HEX	00,CC,00,00,CC,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,99,BB,FF,FF,22
					HEX	22,22,22,22,26,FF,BB,00,66,00,00,00,60,60,00,00
					HEX	00,60,60,00,00,66,00,00,FF,FF,FF,FF,FF,FF,FF,FF
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,66,77,FF,44,44,44,44,44
					HEX	F4,FF,FF,77,00,C0,CC,C0,00,00,00,0C,C0,C0,0C,00
					HEX	00,CC,C0,C0,0C,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,99,BB,FF,6F,22
					HEX	22,6F,6F,22,22,FF,BB,00,66,00,00,66,00,00,66,00
					HEX	66,00,00,06,00,66,60,06,FF,FF,FF,FF,FF,FF,FF,FF
					HEX	60,77,F7,F7,F7,F7,F7,F7,F7,F7,F7,77,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,06,77,7F,7F,7F,7F,7F,7F
					HEX	7F,7F,7F,77,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,CC,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,99,BB,FF,22,22
					HEX	22,22,22,22,F2,FF,BB,00,66,00,00,66,00,00,66,00
					HEX	66,00,00,60,00,66,06,60,FF,FF,FF,FF,FF,FF,FF,FF
					HEX	66,77,FF,4C,4C,4C,4C,4C,CF,FF,FF,77,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,B0,B0,B0,B0,B0,B0,B0,B0,B0,B0,B0,00
					HEX	00,CC,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,09,BB,BF,BF,BF
					HEX	BF,BF,BF,BF,BF,BF,BB,00,06,06,00,00,06,06,00,00
					HEX	00,06,06,00,00,06,00,06,FF,FF,FF,FF,FF,FF,FF,FF
					HEX	66,77,FF,F4,44,44,F4,44,44,4C,FF,77,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,99,BB,FF,6F,6F,6F,6F,6F,FF,FF,FF,BB,00
					HEX	00,CC,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,FF,FF,FF,FF,FF,FF,FF,C0
					HEX	66,77,FF,FF,44,44,FF,FF,44,44,FF,77,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,99,BB,FF,22,22,22,22,22,26,6F,FF,BB,00
					HEX	60,00,00,00,00,00,00,00,00,00,00,00,60,60,00,00
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,FF,FF,FF,FF,FF,FF,FF,00
					HEX	66,77,FF,FF,44,44,FF,FF,44,44,FF,77,00,0C,CC,00
					HEX	C0,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,99,BB,FF,FF,22,22,F2,F2,22,22,FF,BB,00
					HEX	66,00,00,00,00,00,00,00,00,00,00,00,00,66,00,00
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0,A0
					HEX	A0,A0,A0,A0,A0,A0,A0,A0,70,FF,FF,FF,FF,FF,FF,00
					HEX	66,77,FF,FF,44,44,FF,FF,44,44,FF,77,00,00,CC,CC
					HEX	0C,CC,00,C0,0C,0C,C0,00,0C,CC,0C,0C,C0,00,00,00
					HEX	00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
					HEX	00,00,00,99,BB,FF,FF,22,22,6F,6F,22,F2,FF,BB,00
					HEX	66,00,00,00,00,00,00,00,00,00,00,00,00,66,00,00
					HEX	A0,A0,D0,D2,C5,D3,D3,A0,B1,A0,CF,D2,A0,B2,A0,C6
					HEX	CF,D2,A0,CF,CE,C5,A0,CF,D2,A0,D4,D7,CF,A0,D0,CC
					HEX	C1,D9,C5,D2,D3,A0,A0,A0,00,FF,FF,FF,FF,FF,FF,FF
	
	
	
	
	
	
	
	