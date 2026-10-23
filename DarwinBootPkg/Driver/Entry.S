// SPDX-License-Identifier: BSD-2-Clause-Patent
#include <AsmMacroLib.h>

ASM_FUNC(DarwinCurrentEl)
  mrs x0, CurrentEL
  ret

// x0=boot_args PA, x1=entry PA, x2=owned PA, x3=owned size, x4=frame buffer
// PA (0 for none), x5=its size in bytes. EL1 only.
ASM_FUNC(DarwinEnter)
  msr daifset, #15
  // The top scanlines are outside the visible panel area. Resolve a marker
  // address one eighth of the way down the frame buffer instead.
  bl DarwinScanoutMarkerAddress
  mov x20, x0
  // Paint the real scanout pages through the handoff map. Four full-screen
  // bands distinguish a working display path from stale firmware pixels.
  stp x0, x1, [sp, #-48]!
  stp x2, x3, [sp, #16]
  stp x4, x5, [sp, #32]
  bl DarwinScanoutColorBands
  ldp x4, x5, [sp, #32]
  ldp x2, x3, [sp, #16]
  ldp x0, x1, [sp], #48
  // Breadcrumb: a green bar (BGRA 0xFF00FF00) over the top 1/16 of the frame
  // buffer shows that this code ran, whatever the kernel does afterwards.
  cbz x4, 9f
  lsr x9, x5, #4
  bic x9, x9, #7
  mov w10, #0xFF00
  movk w10, #0xFF00, lsl #16
  mov x11, x4
3:
  stp w10, w10, [x11], #8
  subs x9, x9, #8
  b.hi 3b
  dsb sy
9:
  dsb sy
  ic iallu
  dsb sy
  isb
  // C flushed the copied window through EFI_CPU_ARCH_PROTOCOL before exiting
  // boot services. White means that completed and I-cache invalidation ran.
  mov x9, x20
  mov x10, #0x20000
  mov w11, #0xFFFF
  movk w11, #0xFFFF, lsl #16
10:
  stp w11, w11, [x9], #8
  subs x10, x10, #8
  b.hi 10b
  dsb sy
  mrs x4, sctlr_el1
  bic x4, x4, #1
  bic x4, x4, #4
  bic x4, x4, #0x1000
  msr sctlr_el1, x4
  isb
  tlbi vmalle1
  dsb sy
  isb
  // Yellow means the MMU is off and TLBI completed. XNU's entry marker
  // repaints the same top band blue if the final branch succeeds.
  mov x9, x20
  mov x10, #0x20000
  mov w11, #0xFF00
  movk w11, #0xFFFF, lsl #16
11:
  stp w11, w11, [x9], #8
  subs x10, x10, #8
  b.hi 11b
  dsb sy
  br x1
