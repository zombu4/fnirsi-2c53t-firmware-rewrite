/* link.ld - the starter: page 0 of the flash, 0x08000000..0x080007FF (2 KB, one erase page).
 * The vector table is at 0x08000000 (the address the core reads at reset), the code follows. */
MEMORY
{
  PAGE0 (rx) : ORIGIN = 0x08000000, LENGTH = 0x800
}
ENTRY(starter_reset)
STARTER_SIG_ADDR_LD = 0x08000184;   /* STARTER_SIG_ADDR in common/layout.inc */
SECTIONS
{
  .vectors 0x08000000 : { KEEP(*(.vectors)) } > PAGE0
  .signature 0x08000184 : { KEEP(*(.signature)) } > PAGE0
  .text : { *(.text.starter) *(.text*) } > PAGE0
  ASSERT(SIZEOF(.vectors) == 0x184, "vector table must have 97 words")
  ASSERT(ADDR(.signature) == STARTER_SIG_ADDR_LD, "signature must follow the vector table")
  /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.ARM.exidx*) *(.data) *(.bss) }
}
