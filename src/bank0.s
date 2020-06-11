;;;
;;; Bank 0 Variables
;;;

; Low-level (BIOS) sector access variables
SDOS_VARIABLES   = $000320
BIOS_STATUS      = $000320      ; 1 byte - Status of any BIOS operation
BIOS_DEV         = $000321      ; 1 byte - Block device number for block operations
BIOS_LBA         = $000322      ; 4 bytes - Address of block to read/write (this is the physical block, w/o reference to partition)
BIOS_BUFF_PTR    = $000326      ; 4 bytes - 24-bit pointer to memory for read/write operations
BIOS_FIFO_COUNT  = $00032A      ; 2 bytes - The number of bytes read on the last block read
BIOS_FLAGS       = $00032C      ; 1 byte - Flags for various BIOSy things:
                                ; $80 = time out flag: if set, a timeout has occurred (see ISETTIMEOUT)
BIOS_TIMER       = $00032D      ; 1 byte - the number of 1/60 ticks for a time out

; FAT (cluster level) access
DOS_STATUS       = $00032E      ; 1 byte - The error code describing any error with file access
DOS_CLUS_ID      = $000330      ; 4 bytes - The cluster desired for a DOS operation
DOS_DIR_PTR      = $000338      ; 4 bytes - Pointer to a directory entry (assumed to be within DOS_SECTOR)
DOS_BUFF_PTR     = $00033C      ; 4 bytes - A pointer for DOS cluster read/write operations
DOS_FD_PTR       = $000340      ; 4 bytes - A pointer to a file descriptor
DOS_FAT_LBA      = $000344      ; 4 bytes - The LBA for a sector of the FAT we need to read/write
DOS_TEMP         = $000348      ; 4 bytes - Temporary storage for DOS operations
DOS_FILE_SIZE    = $00034C      ; 4 bytes - The size of a file
DOS_SRC_PTR      = $000350      ; 4 bytes - Pointer for transferring data
DOS_DST_PTR      = $000354      ; 4 bytes - Pointer for transferring data
DOS_END_PTR      = $000358      ; 4 bytes - Pointer to the last byte to save
DOS_RUN_PTR      = $00035C      ; 4 bytes - Pointer for starting a loaded program
DOS_RUN_PARAM    = $000360      ; 4 bytes - Pointer to the ASCIIZ string for arguments in loading a program
DOS_STR1_PTR     = $000364      ; 4 bytes - pointer to a string
DOS_STR2_PTR     = $000368      ; 4 bytes - pointer to a string
DOS_SCRATCH      = $00036B      ; 4 bytes - general purpose short term storage

DOS_PATH_BUFF    = $000400      ; 256 bytes - A buffer for path names

FDC_PARAMETERS   = $000500      ; 16 bytes - a buffer of parameter data for the FDC
FDC_RESULTS      = $000510      ; 16 bytes - Buffer for results of FDC commands
FDC_PARAM_NUM    = $000530      ; 1 byte - The number of parameters to send to the FDC (including command)
FDC_RESULT_NUM   = $000532      ; 1 byte - The number of results expected
FDC_EXPECT_DAT   = $000533      ; 1 byte - 0 = the command expects no data, otherwise expects data
FDC_CMD_RETRY    = $000534      ; 1 byte - a retry counter for commands
