

NMIMENU__HANDLEKEY:
	LD	HL, NMI_MENU	
        CP	$26 	; A key
        JR	NZ, _n1
        JP	MENU__CHOOSENEXT
_n1:
        CP	$25     ; Q key
        JR	NZ, _n2
        JP	MENU__CHOOSEPREV
_n2:
        CP	$21     ; ENTER key
        JR	NZ, _n3
        JP	MENU__ACTIVATE
_n3:
	RET
        

NMIENTRY3HANDLER:

NMIENTRY4HANDLER:

NMIENTRY5HANDLER:
        RET
        
NMIENTRY6HANDLER:
        ; Request RESET from FPGA
        DI
        LD   	A, CMD_RESET
        CALL 	WRITECMDFIFO
	ENDLESS

NMIMENU__SETUP:
       	LD	IX, NMI_MENU
        LD	(IX + FRAME_OFF_WIDTH), 28 ; Menu width 24
        LD	(IX + FRAME_OFF_NUMBER_OF_LINES), 7 ; Menu visible entries
        LD	(IX + MENU_OFF_DATA_ENTRIES), 7 ; Menu actual entries 
        LD 	(IX + MENU_OFF_SELECTED_ENTRY), 0 ; Selected entry
        LD	(IX+FRAME_OFF_TITLEPTR), LOW(NMIMENUTITLE)
        LD	(IX+FRAME_OFF_TITLEPTR+1), HIGH(NMIMENUTITLE)
        ; Entry 1
        LD	(IX+MENU_OFF_FIRST_ENTRY), 0 ; Flags
        LD	(IX+MENU_OFF_FIRST_ENTRY+1), LOW(NMIENTRY1)
        LD	(IX+MENU_OFF_FIRST_ENTRY+2), HIGH(NMIENTRY1);

        LD	(IX+MENU_OFF_FIRST_ENTRY+3), 0 ; Flags
        LD	(IX+MENU_OFF_FIRST_ENTRY+4), LOW(NMIENTRY2)
        LD	(IX+MENU_OFF_FIRST_ENTRY+5), HIGH(NMIENTRY2);
        
        LD	(IX+MENU_OFF_FIRST_ENTRY+6), 0 ; Flags
        LD	(IX+MENU_OFF_FIRST_ENTRY+7), LOW(NMIENTRY3)
        LD	(IX+MENU_OFF_FIRST_ENTRY+8), HIGH(NMIENTRY3)
        
        LD	(IX+MENU_OFF_FIRST_ENTRY+9), 0 ; Flags
        LD	(IX+MENU_OFF_FIRST_ENTRY+10), LOW(NMIENTRY4)
        LD	(IX+MENU_OFF_FIRST_ENTRY+11), HIGH(NMIENTRY4)

        LD	(IX+MENU_OFF_FIRST_ENTRY+12), 0 ; Flags
        LD	(IX+MENU_OFF_FIRST_ENTRY+13), LOW(NMIENTRY5)
        LD	(IX+MENU_OFF_FIRST_ENTRY+14), HIGH(NMIENTRY5)

        LD	(IX+MENU_OFF_FIRST_ENTRY+15), 0 ; Flags
        LD	(IX+MENU_OFF_FIRST_ENTRY+16), LOW(NMIENTRY6)
        LD	(IX+MENU_OFF_FIRST_ENTRY+17), HIGH(NMIENTRY6)

        LD	(IX+MENU_OFF_FIRST_ENTRY+18), 0 ; Flags
        LD	(IX+MENU_OFF_FIRST_ENTRY+19), LOW(NMIENTRY7)
        LD	(IX+MENU_OFF_FIRST_ENTRY+20), HIGH(NMIENTRY7)

	LD	(IX+MENU_OFF_CALLBACKPTR), LOW(NMIMENUCALLBACKTABLE)
        LD	(IX+MENU_OFF_CALLBACKPTR+1), HIGH(NMIMENUCALLBACKTABLE)

        LD 	(IX+MENU_OFF_DISPLAY_OFFSET), 0
        LD 	(IX+MENU_OFF_SELECTED_ENTRY), 0
        RET


LOADSNAPSHOT:
        LD	A, FILE_FILTER_SNAPSHOTS
        CALL	FILECHOOSER__SETFILTER
        
	LD	HL, FILECHOOSER__CLASSDEF
        CALL	WIDGET__DISPLAY	

	CALL 	WIDGET__GETCURRENTINSTANCE
        
        LD	DE, REQUEST_SNAPSHOT
        JP	FILECHOOSER__SETSELECTCALLBACK 	; TAILCALL

LOADTAPE:
        LD	A, FILE_FILTER_TAPES
        CALL	FILECHOOSER__SETFILTER

	LD	HL, FILECHOOSER__CLASSDEF
        CALL	WIDGET__DISPLAY	

	CALL 	WIDGET__GETCURRENTINSTANCE

        LD	DE, REQUEST_TAPE
        JP	FILECHOOSER__SETSELECTCALLBACK	; TAILCALL

REQUEST_SNAPSHOT:
	; Request load snapshot
        LD 	A, CMD_LOAD_SNA
        CALL	WRITECMDFIFO
        ; String still in HL
        CALL	WRITECMDSTRING
        ;
        ; Wait for completion
_wait:
        LD	HL, NMICMD_RESPONSE
	LD	A, RESOURCE_ID_OPERATION_STATUS
        CALL	LOADRESOURCE
        JR	Z, _error1
        ; Get operation status
        LD	A, (NMICMD_RESPONSE)
        CP      STATUS_INPROGRESS
        JR	Z, _wait
        CP	STATUS_OK
        JP	Z, SNARAM
        
        LD	HL, NMICMD_RESPONSE
        INC	HL	
        JP	SHOWOPERRORMSG

_error1:
	JP	INTERNALERROR
	ENDLESS


REQUEST_TAPE:
        LD 	A, CMD_PLAY_TAPE
        CALL	WRITECMDFIFO
        ; String still in HL
        CALL	WRITECMDSTRING
        JP	WIDGET__CLOSEALL ; TAILCALL

NMIMENUCALLBACKTABLE:
	DEFW LOADSNAPSHOT       ; Load snapshot
        DEFW ASKFILENAME        ; Save snapshot
        DEFW LOADTAPE           ; Play tape
        DEFW NMIENTRY4HANDLER	; Poke
        DEFW SETTINGS__SHOW	; Settings
        DEFW NMIENTRY6HANDLER	; Reset
        DEFW WIDGET__CLOSE 	; Exit

NMIMENU__INIT:
	CALL	NMIMENU__SETUP
        LD	HL, NMI_MENU
        LD	D, 6 		; line to display menu at.
        JP	MENU__INIT 	; TAILCALL

NMIMENU__CLASSDEF:
	DEFW	NMIMENU__INIT	; Init
        DEFW	WIDGET__IDLE	; Idle
        DEFW	NMIMENU__HANDLEKEY    ; Keyboard handler
        DEFW	MENU__DRAW	; Draw
        DEFW	MENU__GETBOUNDS	; Get rect 

NMIMENUTITLE:
	DB 	"ZX Interface Z", 0
NMIENTRY1: DB	"Load snapshot..", 0
NMIENTRY2: DB	"Save snapshot..", 0
NMIENTRY3: DB	"Play tape...", 0
NMIENTRY4: DB	"Poke...",0
NMIENTRY5: DB	"Settings...", 0
NMIENTRY6: DB	"Reset", 0
NMIENTRY7: DB	"Exit", 0

