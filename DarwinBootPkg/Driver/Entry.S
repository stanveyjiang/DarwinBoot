// SPDX-License-Identifier: BSD-2-Clause-Patent
#include <AsmMacroLib.h>

ASM_FUNC(DarwinCurrentEl)
  mrs x0, CurrentEL
  ret

// x0=boot_args PA, x1=entry PA, x2=owned PA, x3=owned size, x4=frame buffer
// PA (0 for none), x5=its size in bytes. EL1 only.
ASM_FUNC(DarwinEnter)
  msr daifset, #15
  // Boot args and everything they describe must survive until XNU reads them.
  // Framebuffer diagnostics here can overlap that allocation and overwrite the
  // argument words with pixels. Keep this path free of all framebuffer writes.
  dsb sy
  ic iallu
  dsb sy
  isb
  mrs x4, sctlr_el1
  bic x4, x4, #1
  bic x4, x4, #4
  bic x4, x4, #0x1000
  msr sctlr_el1, x4
  isb
  tlbi vmalle1
  dsb sy
  isb
  br x1
