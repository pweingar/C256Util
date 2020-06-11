# MKBOOT: Make a Disk Bootable

MKBOOT will update the boot record of a disk to make it a bootable device on the C256. This utility requires an executable file to be on the disk in question. The user provides the path to that executable, and MKBOOT will configure the disk to run that exectuable at boot time.

Other boot loaders can be implemented for the C256, and in time, MKBOOT may support other ways of booting a disk.

NOTE: Currently, only the floppy disk is supported by MKBOOT. It is my intention to update MKBOOT in the future to support writing to the IDE drive and SDC master boot records.

# Usage

MKBOOT can be run using the BASIC BRUN command. It takes the path to the desired executable as its only argument:

    BRUN "MKBOOT.PGX @F:STARTUP.PGX"

Makes the floppy disk bootable, setting it to execute STARTUP.PGX on boot.

    BRUN "MKBOOT.PGX @F:SYSTEM.PGX 800x600"

Makes the floppy disk bootable, setting it to execute SYSTEM.PGX on boot, passing it the argument string "@F:SYSTEM.PGX 800x600" at runtime.

