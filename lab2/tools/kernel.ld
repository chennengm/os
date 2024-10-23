/* Simple linker script for the ucore kernel.
   See the GNU ld 'info' manual ("info ld") to learn the syntax. */

OUTPUT_ARCH(riscv)
ENTRY(kern_entry)
/*内核虚拟地址的基地址*/
BASE_ADDRESS = 0xFFFFFFFFC0200000;
/*定义链接段*/
SECTIONS
{
    /* Load the kernel at this address: "." means the current address */
    . = BASE_ADDRESS;

    .text : {
        *(.text.kern_entry)
        *(.text .stub .text.* .gnu.linkonce.t.*)
    }

    PROVIDE(etext = .); /* 定义一个符号 etext，指向 .text 段的结束地址Define the 'etext' symbol to this value */

    .rodata : {
        *(.rodata .rodata.* .gnu.linkonce.r.*)
    }/*定义一个名为 .rodata 的只读数据段*/

    /* 将当前地址对齐到0x1000Adjust the address for the data segment to the next page */
    . = ALIGN(0x1000);

    /* The data segment */
    /*包含所有已经初始化的全局变量和静态变量*/
    .data : {
        *(.data)
        *(.data.*)
    }
/*存储小数据段*/
    .sdata : {
        *(.sdata)
        *(.sdata.*)
    }
/*用来为特定符号定义一个地址，*/
    PROVIDE(edata = .);
/*用于存储未初始化的全局变量和静态变量，在程序启动时会被清零*/
    .bss : {
        *(.bss)
        *(.bss.*)
        *(.sbss*)
    }

    PROVIDE(end = .);
/*表示将其中的内容丢弃，不包含在最终的输出文件中*/
    /DISCARD/ : {
        *(.eh_frame .note.GNU-stack)
    }
}
