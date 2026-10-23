# Camellia bring-up branch

This branch contains the Redmi Note 10 5G (`camellia`, MT6833) DarwinBoot
bring-up work.

It is not release-ready. The current code has hardware-specific staging and
framebuffer addresses, bring-up drawing, and diagnostic failure loops. These
are used to isolate the XNU handoff on a device whose UEFI memory map does not
provide a usable large allocation.

Hardware status:

| Stage | State |
| --- | --- |
| Loaded kernel from a FAT payload | works |
| Copied the prelinked Mach-O through a fixed staging buffer | works |
| Exited boot services and disabled the MMU | works |
| Entered XNU at `_start_first_cpu` | works |
| XNU bootstrap page tables | in progress |
| XNU MMU and kernel C initialization | not reached |

The diagnostic screen is temporary:

- a full-screen four-color pattern proves that every scatter-page framebuffer
  run can be written;
- visible bands mark cache flush, MMU/TLBI and XNU entry;
- large failure text replaces reliance on a serial console.

Before proposing this code upstream, platform memory ownership must be fixed
and the diagnostic drawing and forced fixed-window fallback must be removed or
put behind a build option.

Build:

```sh
cd /path/to/UniXNU
export WORKSPACE=$PWD
export MUROOT=$PWD/out/feeds/mu_basecore-89034cbb
export PACKAGES_PATH=$PWD/drivers/DarwinBoot:$PWD/package:$MUROOT
export EDK_TOOLS_PATH=$MUROOT/BaseTools
export CONF_PATH=$PWD/out/qemu/tree/build/darwinboot-efi/Conf
export PYTHON_COMMAND=python3
export CLANG_BIN=/usr/bin/
export PATH=$MUROOT/BaseTools/BinWrappers/PosixLike:$EDK_TOOLS_PATH/Source/C/bin:$PATH
build -p DarwinBootPkg/DarwinBoot.dsc -a AARCH64 -b DEBUG -t CLANGPDB -n 4
```
