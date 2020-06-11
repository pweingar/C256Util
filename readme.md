# C256Util: Potentially Useful Executable Files for the C256

This project is a collection of some potentially useful "commands" for the C256 Foenix. These will be things a user will need to do, but which won't need to be done often enough to justify having them in the kernel or BASIC.

## Utilities

* [MKBOOT](docs/mkboot.md): Make a disk bootable

## Building

Just as an experiment, I have set this project up to be buildable using a Makefile. I'm using the version of make in the Windows Services for Linux
package under Windows 10, but other versions should work too.

    make all

to build all of the utilities. The associated `PGX` and `LST` files will appear in the build directory.

    make clean

to remove all build targets.
