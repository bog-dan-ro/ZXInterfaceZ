
SCREEN		equ	$4000
LINE1		equ 	$4020
LINE2		equ 	$4040
LINE3		equ 	$4060
LINE4		equ 	$4080
LINE23		equ 	$50E0
LINE22		equ 	$50C0
LINE21		equ 	$50A0
ATTR		equ	$5800
SCREENSIZE	equ     $1B00

DEFVAR	MACRO	name, SIZE
name	EQU	$
ORG	$ + SIZE
ENDM

ORG		$5C00

DEFVAR	FRAMES1, 1
DEFVAR	P_TEMP, 1


; IY-based variables.
;IYBASE		EQU 	$
;DEFVAR	ERR_NR, 1
DEFVAR	FLAGS, 1
DEFVAR	PREVKEY, 2
DEFVAR	CURKEY, 2
;DEFVAR	CURRSTATUS, 1
;DEFVAR	CURRSTATUSXOR, 1

DEFVAR	WIFIFLAGS, 1
;DEFVAR	SDMENU, 2
DEFVAR	WIFIAPMENU, 2

DEFVAR	STATE, 1
DEFVAR	PREVSTATUS, 2

MENU1		equ	$5C20 ; 4 entries: size: 9+(4*2) = 9+16 = 25
DEFVAR	PASSWDENTRY, 16
TEXTMESSAGEAREA	equ	$5CA0 

; Store SSID here
DEFVAR	SSID, 32	; Max 32 bytes
DEFVAR	WIFIPASSWD, 16      ; Max 16 bytes

DEFVAR	STATUSBUF, 8

; NMI areas.
DEFVAR	NMI_SCRATCH, 2
DEFVAR	NMI_MENU, 32
DEFVAR	SNAFILENAME, 16

DEFVAR	FILENAMEENTRYWIDGET, 16
DEFVAR	NMICMD_RESPONSE,     32

DEFVAR	VIDEOMODE_MENU, 32
DEFVAR	SETTINGS_MENU, 32
DEFVAR	WIFI_MENU, 32
; Widget system
DEFVAR	STACKINDEX, 1
DEFVAR	STACKDATA, (4*8) ; Max 8 stacked widgets

DEFVAR  Screen_INST, 	Screen__SIZE

DEFVAR  MainWindow_INST, Menuwindow__SIZE
DEFVAR  VideomodeWindow_INST, MenuwindowIndexed__SIZE
DEFVAR  SettingsWindow_INST, Menuwindow__SIZE
DEFVAR  FileWindow_INST, FileDialog__SIZE

DEFVAR  ALLOC_ENDPTR, 2


STACKSIZE	EQU 	64
HEAP		EQU 	$2000
HEAPEND		EQU 	$3FFF


ORG		$5FFE
DEFVAR	NMI_SPVAL, 2

; Patched ROM (on-the-fly)  - max 256 bytes

ROM_PATCHED_SNALOAD equ $1F00
