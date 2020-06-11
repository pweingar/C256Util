;;;
;;; Command to make a disk bootable
;;;
;;; Usage: BRUN "MKBOOT.PGX <boot path>"
;;; where: <boot path> is the path to the executable on the media to boot (which may include parameters)
;;;
;;; NOTE: currently, only the floppy drive is supported
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

DOS_SECTOR = $020000

BIOS_DEV_FDC = 0            ; Device ID for the FDC

BPB_SIGNATURE = 510         ; Position of the signature bytes in the boot sector

CMD_MOTOR_ON = 1            ; Command code to turn on the spindle motor
CMD_MOTOR_OFF = 2           ; Command code to turn off the spindle motor

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

                    setxl
                    setas

                    setdbr `START
                    setdp SDOS_VARIABLES

scan_for_space      LDA [DOS_RUN_PTR]           ; Get the character from the parameters
                    BEQ PRINT_USAGE             ; If NULL, we don't have the info we need... just quit
                    CMP #' '                    ; If it's a SPACE...
                    BEQ trim_head               ; ... then eat the rest of the spaces

                    setal
                    INC DOS_RUN_PTR             ; Move to the next character
                    BNE scan_for_space
                    INC DOS_RUN_PTR+2
                    BRA scan_for_space

trim_head           setal
                    INC DOS_RUN_PTR             ; Move to the next character
                    BNE eat_space
                    INC DOS_RUN_PTR+2

eat_space           setas
                    LDA [DOS_RUN_PTR]           ; Get the character from the parameters
                    BEQ PRINT_USAGE             ; If it's NULL, we didn't get what we need... just quit
                    CMP #' '                    ; If it's a SPACE...
                    BEQ trim_head               ; ... eat it

                    CMP #'@'                    ; Verify that the parameters start with a drive specification
                    BNE PRINT_USAGE             ; If not: print the usage message

                    LDY #1
                    LDA [DOS_RUN_PTR],Y         ; Check the next character
                    CMP #'f'                    ; If 'f' or 'F'
                    BEQ fdc_case                ; ... make the floppy disk bootable
                    CMP #'F'
                    BEQ fdc_case

                    ; TODO: support the IDE and SDC

PRINT_USAGE         LDX #<>MSG_USAGE            ; Print a usage message
                    JSL PUTS

                    setaxl
                    LDA #1
                    BRA RETURN

fdc_case            JSR FDC_WRITEVBR            ; Attempt to make the disk bootable
                    BCC FDC_FAILED

; Return to the caller
RETURN0             setaxl
                    LDA #0

RETURN              PLP
                    PLD
                    PLB
                    PLY
                    PLX
                    RTL

FDC_FAILED          LDX #<>MSG_NOFDC            ; Print an error message that we couldn't make the floppy disk bootable
                    JSL PUTS

                    setaxl
                    LDA #2
                    BRA RETURN

;
; Write a volume block record to the floppy drive
;
; Inputs:
;   DOS_RUN_PTR = pointer to the path to the binary to execute (0 for non-booting)
;
FDC_WRITEVBR        .proc
                    PHP
                    TRACE "FDC_WRITEVBR"

                    setas
                    LDA #BIOS_DEV_FDC
                    STA BIOS_DEV

                    LDA #CMD_MOTOR_ON           ; Send command to turn on the motor
                    JSL CMDBLOCK

                    setaxl
                    LDA #0                      ; Clear the sector buffer
                    LDX #0
clr_loop            STA DOS_SECTOR,X
                    INX
                    INX
                    CPX #512
                    BNE clr_loop

                    setas
                    LDX #0                      ; Copy the prototype VBR to the sector buffer
copy_loop           LDA FDC_VBR_BEGIN,X
                    STA DOS_SECTOR,X
                    INX
                    CPX #<>(FDC_VBR_END - FDC_VBR_BEGIN + 1)
                    BNE copy_loop

                    LDY #0                      ; Copy the boot binary path to the VBR
                    LDX #FDC_VBR_PATH
path_copy_loop      LDA [DOS_RUN_PTR],Y
                    STA DOS_SECTOR,X
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
                    STA BIOS_BUFF_PTR
                    LDA #`DOS_SECTOR
                    STA BIOS_BUFF_PTR+2

                    LDA #0                      ; Set the sector to #0 (boot record)
                    STA BIOS_LBA
                    STA BIOS_LBA+2

                    setas
                    LDA #BIOS_DEV_FDC
                    STA BIOS_DEV

                    JSL PUTBLOCK                ; Attempt to write the boot record
                    BCS ret_success

                    setas
                    LDA #CMD_MOTOR_OFF          ; Send command to turn off the motor
                    JSL CMDBLOCK

                    PLP
                    CLC
                    RTS

ret_success         setas
                    LDA #CMD_MOTOR_OFF          ; Send command to turn off the motor
                    JSL CMDBLOCK

                    PLP
                    SEC
                    RTS
                    .pend

FDC_BOOT_START = 62                         ; Entry point to the boot code
FDC_VBR_PATH = 64                           ; Offset to the path in the VBR
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

vbr_start           setal
                    LDA #<>(DOS_SECTOR + (file_path - FDC_VBR_BEGIN))
                    STA @l DOS_RUN_PARAM
                    LDA #`(DOS_SECTOR + (file_path - FDC_VBR_BEGIN))
                    STA @l DOS_RUN_PARAM+2
                    
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

MSG_USAGE           .null "USAGE: MKBOOT.PGX <path>",13
MSG_NOFDC           .null "Could not make the floppy disk bootable.",13
