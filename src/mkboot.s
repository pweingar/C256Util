;;;
;;; Command to make a disk bootable
;;;
;;; Usage: BRUN "MKBOOT.PGX <boot path>"
;;; where: <boot path> is the path to the executable on the media to boot (which may include parameters)
;;;
;;; NOTE: when making a floppy bootable, the floppy's VBR is replaced with a bootable VBR. When making
;;; an SD card or the hard drive, the MBR is updated with bootable code.
;;;
;;; Example:
;;;     BRUN "MKBOOT.PGX @F:STARTUP.PGX ABC 123" -- Sets the floppy disk to boot STARTUP.PGX, passing the parameters
;;;         "ABC 123" to the PGX file.
;;;

.include "bank0.s"
.include "macros.s"
.include "kernel.s"

;
; Constants
;

BIOS_DEV_FDC = 0            ; Floppy 0
BIOS_DEV_FD1 = 1            ; Future support: Floppy 1 (not likely to be attached)
BIOS_DEV_SD = 2             ; SD card, partition 0
BIOS_DEV_SD1 = 3            ; Future support: SD card, partition 1
BIOS_DEV_SD2 = 4            ; Future support: SD card, partition 2
BIOS_DEV_SD3 = 5            ; Future support: SD card, partition 3
BIOS_DEV_HD0 = 6            ; Future support: IDE Drive 0, partition 0
BIOS_DEV_HD1 = 7            ; Future support: IDE Drive 0, partition 1
BIOS_DEV_HD2 = 8            ; Future support: IDE Drive 0, partition 2
BIOS_DEV_HD3 = 9            ; Future support: IDE Drive 0, partition 3

DOS_SECTOR = $020000
BPB_SIGNATURE = 510         ; Position of the signature bytes in the boot sector
CMD_MOTOR_ON = 1            ; Command code to turn on the spindle motor
CMD_MOTOR_OFF = 2           ; Command code to turn off the spindle motor

FDC_VBR_PATH = 64           ; Offset to the path in the VBR (floppy drive)
MBR_PATH = 11               ; Offset to the path in the MBR (SD and IDE)

BASIC = $3A0000

;
; PGX Header
;

* = START - 8
PGXHEADER           .text "PGX"
                    .byte $01
                    .dword START

;
; Executable code
;

* = $010000
START               PHX
                    PHY
                    PHB
                    PHD
                    PHP

                    setdbr `START
                    setdp SDOS_VARIABLES

                    setxl
scan_for_space      setas
                    LDA [DOS_RUN_PARAM]         ; Get the character from the parameters
                    BEQ PATH_NOT_FOUND          ; If NULL, we don't have the info we need... just quit
                    CMP #' '                    ; If it's a SPACE...
                    BEQ trim_head               ; ... then eat the rest of the spaces

                    setal
                    INC DOS_RUN_PARAM           ; Move to the next character
                    BNE scan_for_space
                    INC DOS_RUN_PARAM+2
                    BRA scan_for_space

trim_head           setal
                    INC DOS_RUN_PARAM           ; Move to the next character
                    BNE eat_space
                    INC DOS_RUN_PARAM+2

eat_space           setas
                    LDA [DOS_RUN_PARAM]         ; Get the character from the parameters
                    BEQ PATH_NOT_FOUND          ; If it's NULL, we didn't get what we need... just quit
                    CMP #' '                    ; If it's a SPACE...
                    BEQ trim_head               ; ... eat it

                    CMP #'@'                    ; Verify that the parameters start with a drive specification
                    BNE DEV_NOT_FOUND           ; If not: print the usage message

                    LDY #1
                    LDA [DOS_RUN_PARAM],Y       ; Check the next character
                    CMP #'f'                    ; If 'f' or 'F'
                    BEQ fdc_case                ; ... make the floppy disk bootable
                    CMP #'F'
                    BEQ fdc_case

                    CMP #'s'                    ; If 's' or 'S'
                    BEQ sdc_case                ; ... make the SD card bootable
                    CMP #'S'
                    BEQ sdc_case

                    CMP #'h'                    ; If 'h' or 'H'
                    BEQ ide_case                ; ... make the hard drive bootable
                    CMP #'H'
                    BEQ ide_case


                    setaxl
                    LDX #<>MSG_BADDEV           ; Return a bad device code error
PRINT_ERROR         JSL PUTS

PRINT_USAGE         setaxl
                    LDX #<>MSG_USAGE            ; Print the usage message
                    JSL PUTS
                    BRA RETURN1

PATH_NOT_FOUND      setaxl
                    LDX #<>MSG_NOPATH           ; Return a path not found error
                    BRA PRINT_ERROR

DEV_NOT_FOUND       setaxl
                    LDX #<>MSG_NODEV            ; Return device not found error
                    BRA PRINT_ERROR

fdc_case            JSR FDC_WRITEVBR            ; Attempt to make the disk bootable
                    BCS RETURN0
                    
                    setaxl
                    LDX #<>MSG_NOFDC            ; Print an error message that we couldn't make the floppy disk bootable      
                    JSL PUTS
                    LDA #2
                    BRA RETURN

sdc_case            setas
                    LDA #BIOS_DEV_SD
                    STA @b BIOS_DEV
                    
                    JSR WRITE_MBR               ; Attempt to make the disk bootable
                    BCS RETURN0
                    
                    setaxl
                    LDX #<>MSG_NOSDC           ; Print an error message that we couldn't make the SD card bootable      
                    JSL PUTS
                    LDA #2
                    BRA RETURN

ide_case            setas
                    LDA #BIOS_DEV_HD0
                    STA @b BIOS_DEV
                    
                    JSR WRITE_MBR               ; Attempt to make the disk bootable
                    BCS RETURN0
                    
                    setaxl
                    LDX #<>MSG_NOIDE           ; Print an error message that we couldn't make the hard drive 
                    JSL PUTS
                    LDA #2
                    BRA RETURN

RETURN1             setaxl                      ; Return error code 1
                    LDA #1
                    BRA RETURN

RETURN0             setaxl                      ; Return 0
                    LDA #0
RETURN              PLP
                    PLD
                    PLB
                    PLY
                    PLX
                    RTL

DEFAULT_PARAMS      .null "@s:mkboot.pgx @f:sample.pgx Hello"
MSG_USAGE           .null "USAGE: MKBOOT.PGX <path>", 13
MSG_NOFDC           .null "Could not make the floppy disk bootable.", 13
MSG_NOPATH          .null "No boot path was found.", 13, 13
MSG_NODEV           .null "No device name found.", 13, 13
MSG_BADDEV          .null "Bad device name.", 13, 13
MSG_NOMOUNT         .null "Could not mount floppy drive.", 13, 13
MSG_NOSDC           .null "Could not make the SD card bootable.", 13
MSG_NOIDE           .null "Could not make the hard drive bootable.", 13

;
; Write a volume block record to the floppy drive
;
; Inputs:
;   DOS_RUN_PARAM = pointer to the path to the binary to execute (0 for non-booting)
;
FDC_WRITEVBR        .proc
                    PHB
                    PHD
                    PHP

                    setdbr `START
                    setdp SDOS_VARIABLES

                    TRACE "FDC_WRITEVBR"

                    setas
                    LDA #BIOS_DEV_FDC
                    STA @b BIOS_DEV

                    JSL F_MOUNT                 ; Attempt to mount the floppy
                    BCS clr_buffer
                    BRL ret_failure

clr_buffer          setaxl
                    LDA #0                      ; Clear the sector buffer
                    LDX #0
clr_loop            STA @l DOS_SECTOR,X
                    INX
                    INX
                    CPX #512
                    BNE clr_loop

                    setas
                    LDX #0                      ; Copy the prototype VBR to the sector buffer
copy_loop           LDA @w FDC_VBR_BEGIN,X
                    STA @l DOS_SECTOR,X
                    INX
                    CPX #<>(FDC_VBR_END - FDC_VBR_BEGIN + 1)
                    BNE copy_loop

                    LDY #0                      ; Copy the boot binary path to the VBR
                    LDX #FDC_VBR_PATH
path_copy_loop      LDA [DOS_RUN_PARAM],Y
                    STA @l DOS_SECTOR,X
                    BEQ path_copy_done
                    INX
                    INY
                    CPY #128
                    BNE path_copy_loop

path_copy_done      setal
                    LDA #$AA55                  ; Set the VBR signature bytes at the end
                    STA DOS_SECTOR+BPB_SIGNATURE

                    setal
                    LDA #<>DOS_SECTOR           ; Point to the BIOS buffer
                    STA @b BIOS_BUFF_PTR
                    LDA #`DOS_SECTOR
                    STA @b BIOS_BUFF_PTR+2

                    LDA #0                      ; Set the sector to #0 (boot record)
                    STA @b BIOS_LBA
                    STA @b BIOS_LBA+2

                    setas
                    LDA #BIOS_DEV_FDC
                    STA @b BIOS_DEV

                    JSL PUTBLOCK                ; Attempt to write the boot record
                    BCS ret_success

ret_failure         setas
                    LDA #CMD_MOTOR_OFF          ; Send command to turn off the motor
                    JSL CMDBLOCK

                    PLP
                    PLD
                    PLB
                    CLC
                    RTS

ret_success         setas
                    LDA #CMD_MOTOR_OFF          ; Send command to turn off the motor
                    JSL CMDBLOCK

                    PLP
                    PLD
                    PLB
                    SEC
                    RTS
                    .pend

;
; Make the master boot record of the SDC or IDE HD bootable.
;
; Inputs:
;   BIOS_DEV = the device to write the MBR to (must be the SDC or IDE)
;   DOS_RUN_PARAM = pointer to the path to the binary to execute (0 for non-booting)
;
WRITE_MBR           .proc
                    PHB
                    PHD
                    PHP

                    setdbr `START
                    setdp SDOS_VARIABLES

                    TRACE "WRITE_MBR"

                    setas
                    LDA BIOS_DEV
                    CMP #BIOS_DEV_SD
                    BEQ dev_ok
                    CMP #BIOS_DEV_HD0
                    BEQ dev_ok
                    BRL ret_failure

dev_ok              setal
                    LDA #0                      ; Point to the MBR
                    STA @b BIOS_LBA
                    STA @b BIOS_LBA+2

                    LDA #<>DOS_SECTOR           ; ... and the buffer where we want it
                    STA @b BIOS_BUFF_PTR
                    LDA #`DOS_SECTOR
                    STA @b BIOS_BUFF_PTR+2

                    JSL GETBLOCK                ; Read the current version (we need the partition data)
                    BCS mbr_read
                    BRL ret_failure             ; Return if we couldn't read it.

mbr_read            setas
                    LDX #0                      ; Copy the prototype MBR to the sector buffer
copy_loop           LDA @w MBR_START,X
                    STA @l DOS_SECTOR,X
                    INX
                    CPX #<>(MBR_END -  MBR_START + 1)
                    BNE copy_loop

                    LDY #0                      ; Copy the boot binary path to the VBR
                    LDX #MBR_PATH
path_copy_loop      LDA [DOS_RUN_PARAM],Y
                    STA @l DOS_SECTOR,X
                    BEQ path_copy_done
                    INX
                    INY
                    CPY #128
                    BNE path_copy_loop

path_copy_done      setal
                    LDA #$AA55                  ; Set the VBR signature bytes at the end
                    STA DOS_SECTOR+BPB_SIGNATURE

                    setal
                    LDA #<>DOS_SECTOR           ; Point to the BIOS buffer
                    STA @b BIOS_BUFF_PTR
                    LDA #`DOS_SECTOR
                    STA @b BIOS_BUFF_PTR+2

                    LDA #0                      ; Set the sector to #0 (boot record)
                    STA @b BIOS_LBA
                    STA @b BIOS_LBA+2

                    JSL PUTBLOCK                ; Attempt to write the boot record
                    BCS ret_success

ret_failure         PLP
                    PLD
                    PLB
                    CLC
                    RTS

ret_success         PLP
                    PLD
                    PLB
                    SEC
                    RTS
                    .pend

FDC_VBR_BEGIN       .block
start               .byte $EB, $00, $90     ; Entry point
magic               .text "C256DOS "        ; OEM name / magic text for booting
bytes_per_sec       .word 512               ; How many bytes per sector
sec_per_cluster     .byte 1                 ; How many sectors per cluster
rsrv_sectors        .word 1                 ; Number of reserved sectors
num_fat             .byte 2                 ; Number of FATs
max_dir_entry       .word (32-18)*16        ; Total number of root dir entries
total_sectors       .word 2880              ; Total sectors
media_descriptor    .byte $F0               ; 3.5" 1.44 MB floppy 80 tracks, 18 tracks per sector
sec_per_fat         .word 9                 ; Sectors per FAT
sec_per_track       .word 18                ; Sectors per track
num_head            .word 2                 ; Number of heads
ignore2             .dword 0
fat32_sector        .dword 0                ; # of sectors in FAT32
ignore3             .word 0
boot_signature      .byte $29
volume_id           .dword $12345678        ; Replaced by code
volume_name         .text "UNTITLED   "     ; Replace by code
fs_type             .text "FAT12   "

; Boot code (assumes we are in native mode)
                    
                    BRA vbr_start

file_path           .fill 64                ; Reserve 64 bytes for a path and any options

vbr_start           setdp SDOS_VARIABLES
                    setas
                    STZ @b DOS_RUN_PARAM+3
                    PHK                     ; Get the current bank to set the DOS_RUN_PARAM pointer
                    PLA
                    STA @b DOS_RUN_PARAM+2

                    setaxl
                    PER file_path           ; Get the rest of the path address for the DOS_RUN_PARAM pointer
                    PLA
                    STA @b DOS_RUN_PARAM
                    
                    JSL F_RUN               ; And try to execute the binary file
                    BCS lock                ; If it returned success... lock up... I guess?

error               setas
                    PHK                     ; Otherwise, print an error message
                    PLB
                    PER message
                    PLX
                    JSL PUTS

lock                NOP                     ; And lock up
                    BRA lock

message             .null "Could not find a bootable binary.",13
                    .bend
FDC_VBR_END

; Code for the Master Boot Record to use on the IDE drive and SDCs
MBR_START           .block
                    BRL mbr_start           ; Initial jump
                    .text "C256DOS "        ; Magic code for a C256 bootable drive
file_path           .fill 64                ; Reserve 64 bytes for a path and any options

mbr_start           setdp SDOS_VARIABLES
                    setas
                    STZ @b DOS_RUN_PARAM+3
                    PHK                     ; Get the current bank to set the DOS_RUN_PARAM pointer
                    PLA
                    STA @b DOS_RUN_PARAM+2

                    setaxl
                    PER file_path           ; Get the rest of the path address for the DOS_RUN_PARAM pointer
                    PLA
                    STA @b DOS_RUN_PARAM
                    
                    JSL F_RUN               ; And try to execute the binary file
                    BCS lock                ; If it returned success... lock up... I guess?

error               setas
                    PHK                     ; Otherwise, print an error message
                    PLB
                    PER message
                    PLX
                    JSL PUTS

lock                NOP                     ; And lock up
                    BRA lock

message             .null "Could not find a bootable binary.",13
                    .bend         
MBR_END