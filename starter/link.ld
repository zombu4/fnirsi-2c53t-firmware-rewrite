/* link.ld - the starter: page 0 of the flash, 0x08000000..0x080007FF (2 KB, one erase page).
 * The vector table is at 0x08000000 (the address the core reads at reset), the code follows. */
MEMORY
{
  PAGE0 (rx) : ORIGIN = 0x08000000, LENGTH = 0x800
}
ENTRY(starter_reset)
SECTIONS
{
  .vectors 0x08000000 : { KEEP(*(.vectors)) } > PAGE0
  .text : { *(.text.starter) *(.text*) } > PAGE0
  ASSERT(SIZEOF(.vectors) == 0x184, "vector table must have 97 words")
  /DISCARD/ : { *(.ARM.attributes) *(.comment) *(.ARM.exidx*) *(.data) *(.bss) }
}
