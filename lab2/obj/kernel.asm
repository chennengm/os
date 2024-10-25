
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
#ax权限标志。a：这个段在运行时需要被加载到内存中，x：表示这个段是可执行的，
    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址，bpt定义在汇编代码中的预设的三级页表
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    #xffffffffc0000000：这是内核的虚拟地址基地址
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12位变为三级页表的物理页号,去掉12位的页内偏移
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc
    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB（存储最近使用的虚拟地址到物理地址映射的缓存
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！，高20位
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fde50513          	addi	a0,a0,-34 # ffffffffc0206010 <buddy_struct>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	53660613          	addi	a2,a2,1334 # ffffffffc0206570 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	5d0010ef          	jal	ra,ffffffffc020161a <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00001517          	auipc	a0,0x1
ffffffffc0200056:	5de50513          	addi	a0,a0,1502 # ffffffffc0201630 <etext+0x4>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // 初始化中断描述符表
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	6a3000ef          	jal	ra,ffffffffc0200f08 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3fa000ef          	jal	ra,ffffffffc0200464 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>

    intr_enable();  // enable irq interrupt超级用户中断使能位
ffffffffc0200072:	3e6000ef          	jal	ra,ffffffffc0200458 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3cc000ef          	jal	ra,ffffffffc020044c <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	09e010ef          	jal	ra,ffffffffc0201144 <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	8e2a                	mv	t3,a0
ffffffffc02000ba:	f42e                	sd	a1,40(sp)
ffffffffc02000bc:	f832                	sd	a2,48(sp)
ffffffffc02000be:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	00000517          	auipc	a0,0x0
ffffffffc02000c4:	fb850513          	addi	a0,a0,-72 # ffffffffc0200078 <cputch>
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
ffffffffc02000d0:	e0ba                	sd	a4,64(sp)
ffffffffc02000d2:	e4be                	sd	a5,72(sp)
ffffffffc02000d4:	e8c2                	sd	a6,80(sp)
ffffffffc02000d6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000da:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	068010ef          	jal	ra,ffffffffc0201144 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4512                	lw	a0,4(sp)
ffffffffc02000e4:	6125                	addi	sp,sp,96
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e8:	a695                	j	ffffffffc020044c <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34c000ef          	jal	ra,ffffffffc020044c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200104:	00044503          	lbu	a0,0(s0)
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	336000ef          	jal	ra,ffffffffc020044c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	326000ef          	jal	ra,ffffffffc0200454 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020013c:	00001517          	auipc	a0,0x1
ffffffffc0200140:	51450513          	addi	a0,a0,1300 # ffffffffc0201650 <etext+0x24>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00001517          	auipc	a0,0x1
ffffffffc0200156:	51e50513          	addi	a0,a0,1310 # ffffffffc0201670 <etext+0x44>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00001597          	auipc	a1,0x1
ffffffffc0200162:	4ce58593          	addi	a1,a1,1230 # ffffffffc020162c <etext>
ffffffffc0200166:	00001517          	auipc	a0,0x1
ffffffffc020016a:	52a50513          	addi	a0,a0,1322 # ffffffffc0201690 <etext+0x64>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	e9e58593          	addi	a1,a1,-354 # ffffffffc0206010 <buddy_struct>
ffffffffc020017a:	00001517          	auipc	a0,0x1
ffffffffc020017e:	53650513          	addi	a0,a0,1334 # ffffffffc02016b0 <etext+0x84>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	3ea58593          	addi	a1,a1,1002 # ffffffffc0206570 <end>
ffffffffc020018e:	00001517          	auipc	a0,0x1
ffffffffc0200192:	54250513          	addi	a0,a0,1346 # ffffffffc02016d0 <etext+0xa4>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	7d558593          	addi	a1,a1,2005 # ffffffffc020696f <end+0x3ff>
ffffffffc02001a2:	00000797          	auipc	a5,0x0
ffffffffc02001a6:	e9078793          	addi	a5,a5,-368 # ffffffffc0200032 <kern_init>
ffffffffc02001aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b8:	95be                	add	a1,a1,a5
ffffffffc02001ba:	85a9                	srai	a1,a1,0xa
ffffffffc02001bc:	00001517          	auipc	a0,0x1
ffffffffc02001c0:	53450513          	addi	a0,a0,1332 # ffffffffc02016f0 <etext+0xc4>
}
ffffffffc02001c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001c6:	b5f5                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001c8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001c8:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ca:	00001617          	auipc	a2,0x1
ffffffffc02001ce:	55660613          	addi	a2,a2,1366 # ffffffffc0201720 <etext+0xf4>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00001517          	auipc	a0,0x1
ffffffffc02001da:	56250513          	addi	a0,a0,1378 # ffffffffc0201738 <etext+0x10c>
void print_stackframe(void) {
ffffffffc02001de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e0:	1cc000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001e6:	00001617          	auipc	a2,0x1
ffffffffc02001ea:	56a60613          	addi	a2,a2,1386 # ffffffffc0201750 <etext+0x124>
ffffffffc02001ee:	00001597          	auipc	a1,0x1
ffffffffc02001f2:	58258593          	addi	a1,a1,1410 # ffffffffc0201770 <etext+0x144>
ffffffffc02001f6:	00001517          	auipc	a0,0x1
ffffffffc02001fa:	58250513          	addi	a0,a0,1410 # ffffffffc0201778 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00001617          	auipc	a2,0x1
ffffffffc0200208:	58460613          	addi	a2,a2,1412 # ffffffffc0201788 <etext+0x15c>
ffffffffc020020c:	00001597          	auipc	a1,0x1
ffffffffc0200210:	5a458593          	addi	a1,a1,1444 # ffffffffc02017b0 <etext+0x184>
ffffffffc0200214:	00001517          	auipc	a0,0x1
ffffffffc0200218:	56450513          	addi	a0,a0,1380 # ffffffffc0201778 <etext+0x14c>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00001617          	auipc	a2,0x1
ffffffffc0200224:	5a060613          	addi	a2,a2,1440 # ffffffffc02017c0 <etext+0x194>
ffffffffc0200228:	00001597          	auipc	a1,0x1
ffffffffc020022c:	5b858593          	addi	a1,a1,1464 # ffffffffc02017e0 <etext+0x1b4>
ffffffffc0200230:	00001517          	auipc	a0,0x1
ffffffffc0200234:	54850513          	addi	a0,a0,1352 # ffffffffc0201778 <etext+0x14c>
ffffffffc0200238:	e7bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc020023c:	60a2                	ld	ra,8(sp)
ffffffffc020023e:	4501                	li	a0,0
ffffffffc0200240:	0141                	addi	sp,sp,16
ffffffffc0200242:	8082                	ret

ffffffffc0200244 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
ffffffffc0200246:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200248:	ef3ff0ef          	jal	ra,ffffffffc020013a <print_kerninfo>
    return 0;
}
ffffffffc020024c:	60a2                	ld	ra,8(sp)
ffffffffc020024e:	4501                	li	a0,0
ffffffffc0200250:	0141                	addi	sp,sp,16
ffffffffc0200252:	8082                	ret

ffffffffc0200254 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200254:	1141                	addi	sp,sp,-16
ffffffffc0200256:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200258:	f71ff0ef          	jal	ra,ffffffffc02001c8 <print_stackframe>
    return 0;
}
ffffffffc020025c:	60a2                	ld	ra,8(sp)
ffffffffc020025e:	4501                	li	a0,0
ffffffffc0200260:	0141                	addi	sp,sp,16
ffffffffc0200262:	8082                	ret

ffffffffc0200264 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200264:	7115                	addi	sp,sp,-224
ffffffffc0200266:	ed5e                	sd	s7,152(sp)
ffffffffc0200268:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020026a:	00001517          	auipc	a0,0x1
ffffffffc020026e:	58650513          	addi	a0,a0,1414 # ffffffffc02017f0 <etext+0x1c4>
kmonitor(struct trapframe *tf) {
ffffffffc0200272:	ed86                	sd	ra,216(sp)
ffffffffc0200274:	e9a2                	sd	s0,208(sp)
ffffffffc0200276:	e5a6                	sd	s1,200(sp)
ffffffffc0200278:	e1ca                	sd	s2,192(sp)
ffffffffc020027a:	fd4e                	sd	s3,184(sp)
ffffffffc020027c:	f952                	sd	s4,176(sp)
ffffffffc020027e:	f556                	sd	s5,168(sp)
ffffffffc0200280:	f15a                	sd	s6,160(sp)
ffffffffc0200282:	e962                	sd	s8,144(sp)
ffffffffc0200284:	e566                	sd	s9,136(sp)
ffffffffc0200286:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200288:	e2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020028c:	00001517          	auipc	a0,0x1
ffffffffc0200290:	58c50513          	addi	a0,a0,1420 # ffffffffc0201818 <etext+0x1ec>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00001c17          	auipc	s8,0x1
ffffffffc02002a6:	5e6c0c13          	addi	s8,s8,1510 # ffffffffc0201888 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00001917          	auipc	s2,0x1
ffffffffc02002ae:	59690913          	addi	s2,s2,1430 # ffffffffc0201840 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00001497          	auipc	s1,0x1
ffffffffc02002b6:	59648493          	addi	s1,s1,1430 # ffffffffc0201848 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00001b17          	auipc	s6,0x1
ffffffffc02002c0:	594b0b13          	addi	s6,s6,1428 # ffffffffc0201850 <etext+0x224>
        argv[argc ++] = buf;
ffffffffc02002c4:	00001a17          	auipc	s4,0x1
ffffffffc02002c8:	4aca0a13          	addi	s4,s4,1196 # ffffffffc0201770 <etext+0x144>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	1f6010ef          	jal	ra,ffffffffc02014c6 <readline>
ffffffffc02002d4:	842a                	mv	s0,a0
ffffffffc02002d6:	dd65                	beqz	a0,ffffffffc02002ce <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002dc:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	e1bd                	bnez	a1,ffffffffc0200344 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e0:	fe0c87e3          	beqz	s9,ffffffffc02002ce <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00001d17          	auipc	s10,0x1
ffffffffc02002ea:	5a2d0d13          	addi	s10,s10,1442 # ffffffffc0201888 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	2f2010ef          	jal	ra,ffffffffc02015e6 <strcmp>
ffffffffc02002f8:	c919                	beqz	a0,ffffffffc020030e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	2405                	addiw	s0,s0,1
ffffffffc02002fc:	0b540063          	beq	s0,s5,ffffffffc020039c <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200300:	000d3503          	ld	a0,0(s10)
ffffffffc0200304:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200306:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	2de010ef          	jal	ra,ffffffffc02015e6 <strcmp>
ffffffffc020030c:	f57d                	bnez	a0,ffffffffc02002fa <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020030e:	00141793          	slli	a5,s0,0x1
ffffffffc0200312:	97a2                	add	a5,a5,s0
ffffffffc0200314:	078e                	slli	a5,a5,0x3
ffffffffc0200316:	97e2                	add	a5,a5,s8
ffffffffc0200318:	6b9c                	ld	a5,16(a5)
ffffffffc020031a:	865e                	mv	a2,s7
ffffffffc020031c:	002c                	addi	a1,sp,8
ffffffffc020031e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200322:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200324:	fa0555e3          	bgez	a0,ffffffffc02002ce <kmonitor+0x6a>
}
ffffffffc0200328:	60ee                	ld	ra,216(sp)
ffffffffc020032a:	644e                	ld	s0,208(sp)
ffffffffc020032c:	64ae                	ld	s1,200(sp)
ffffffffc020032e:	690e                	ld	s2,192(sp)
ffffffffc0200330:	79ea                	ld	s3,184(sp)
ffffffffc0200332:	7a4a                	ld	s4,176(sp)
ffffffffc0200334:	7aaa                	ld	s5,168(sp)
ffffffffc0200336:	7b0a                	ld	s6,160(sp)
ffffffffc0200338:	6bea                	ld	s7,152(sp)
ffffffffc020033a:	6c4a                	ld	s8,144(sp)
ffffffffc020033c:	6caa                	ld	s9,136(sp)
ffffffffc020033e:	6d0a                	ld	s10,128(sp)
ffffffffc0200340:	612d                	addi	sp,sp,224
ffffffffc0200342:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	8526                	mv	a0,s1
ffffffffc0200346:	2be010ef          	jal	ra,ffffffffc0201604 <strchr>
ffffffffc020034a:	c901                	beqz	a0,ffffffffc020035a <kmonitor+0xf6>
ffffffffc020034c:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200350:	00040023          	sb	zero,0(s0)
ffffffffc0200354:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200356:	d5c9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200358:	b7f5                	j	ffffffffc0200344 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020035a:	00044783          	lbu	a5,0(s0)
ffffffffc020035e:	d3c9                	beqz	a5,ffffffffc02002e0 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200360:	033c8963          	beq	s9,s3,ffffffffc0200392 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200364:	003c9793          	slli	a5,s9,0x3
ffffffffc0200368:	0118                	addi	a4,sp,128
ffffffffc020036a:	97ba                	add	a5,a5,a4
ffffffffc020036c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200374:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200376:	e591                	bnez	a1,ffffffffc0200382 <kmonitor+0x11e>
ffffffffc0200378:	b7b5                	j	ffffffffc02002e4 <kmonitor+0x80>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020037e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200380:	d1a5                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200382:	8526                	mv	a0,s1
ffffffffc0200384:	280010ef          	jal	ra,ffffffffc0201604 <strchr>
ffffffffc0200388:	d96d                	beqz	a0,ffffffffc020037a <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00044583          	lbu	a1,0(s0)
ffffffffc020038e:	d9a9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200390:	bf55                	j	ffffffffc0200344 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020039a:	b7e9                	j	ffffffffc0200364 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	4d250513          	addi	a0,a0,1234 # ffffffffc0201870 <etext+0x244>
ffffffffc02003a6:	d0dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc02003aa:	b715                	j	ffffffffc02002ce <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	17430313          	addi	t1,t1,372 # ffffffffc0206520 <is_panic>
ffffffffc02003b4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	020e1a63          	bnez	t3,ffffffffc02003fc <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003d2:	8432                	mv	s0,a2
ffffffffc02003d4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d6:	862e                	mv	a2,a1
ffffffffc02003d8:	85aa                	mv	a1,a0
ffffffffc02003da:	00001517          	auipc	a0,0x1
ffffffffc02003de:	4f650513          	addi	a0,a0,1270 # ffffffffc02018d0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003e2:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e4:	ccfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e8:	65a2                	ld	a1,8(sp)
ffffffffc02003ea:	8522                	mv	a0,s0
ffffffffc02003ec:	ca7ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003f0:	00001517          	auipc	a0,0x1
ffffffffc02003f4:	32850513          	addi	a0,a0,808 # ffffffffc0201718 <etext+0xec>
ffffffffc02003f8:	cbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003fc:	062000ef          	jal	ra,ffffffffc020045e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	e63ff0ef          	jal	ra,ffffffffc0200264 <kmonitor>
    while (1) {
ffffffffc0200406:	bfed                	j	ffffffffc0200400 <__panic+0x54>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	174010ef          	jal	ra,ffffffffc0201594 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	1007b123          	sd	zero,258(a5) # ffffffffc0206528 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00001517          	auipc	a0,0x1
ffffffffc0200432:	4c250513          	addi	a0,a0,1218 # ffffffffc02018f0 <commands+0x68>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	b9ad                	j	ffffffffc02000b2 <cprintf>

ffffffffc020043a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	14e0106f          	j	ffffffffc0201594 <sbi_set_timer>

ffffffffc020044a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044a:	8082                	ret

ffffffffc020044c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044c:	0ff57513          	andi	a0,a0,255
ffffffffc0200450:	12a0106f          	j	ffffffffc020157a <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	15a0106f          	j	ffffffffc02015ae <sbi_console_getchar>

ffffffffc0200458 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200458:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045c:	8082                	ret

ffffffffc020045e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200464:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200468:	00000797          	auipc	a5,0x0
ffffffffc020046c:	36478793          	addi	a5,a5,868 # ffffffffc02007cc <__alltraps>
ffffffffc0200470:	10579073          	csrw	stvec,a5
}
ffffffffc0200474:	8082                	ret

ffffffffc0200476 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200476:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200478:	1141                	addi	sp,sp,-16
ffffffffc020047a:	e022                	sd	s0,0(sp)
ffffffffc020047c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	00001517          	auipc	a0,0x1
ffffffffc0200482:	49250513          	addi	a0,a0,1170 # ffffffffc0201910 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00001517          	auipc	a0,0x1
ffffffffc0200492:	49a50513          	addi	a0,a0,1178 # ffffffffc0201928 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00001517          	auipc	a0,0x1
ffffffffc02004a0:	4a450513          	addi	a0,a0,1188 # ffffffffc0201940 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00001517          	auipc	a0,0x1
ffffffffc02004ae:	4ae50513          	addi	a0,a0,1198 # ffffffffc0201958 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00001517          	auipc	a0,0x1
ffffffffc02004bc:	4b850513          	addi	a0,a0,1208 # ffffffffc0201970 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00001517          	auipc	a0,0x1
ffffffffc02004ca:	4c250513          	addi	a0,a0,1218 # ffffffffc0201988 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00001517          	auipc	a0,0x1
ffffffffc02004d8:	4cc50513          	addi	a0,a0,1228 # ffffffffc02019a0 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00001517          	auipc	a0,0x1
ffffffffc02004e6:	4d650513          	addi	a0,a0,1238 # ffffffffc02019b8 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00001517          	auipc	a0,0x1
ffffffffc02004f4:	4e050513          	addi	a0,a0,1248 # ffffffffc02019d0 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00001517          	auipc	a0,0x1
ffffffffc0200502:	4ea50513          	addi	a0,a0,1258 # ffffffffc02019e8 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00001517          	auipc	a0,0x1
ffffffffc0200510:	4f450513          	addi	a0,a0,1268 # ffffffffc0201a00 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00001517          	auipc	a0,0x1
ffffffffc020051e:	4fe50513          	addi	a0,a0,1278 # ffffffffc0201a18 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00001517          	auipc	a0,0x1
ffffffffc020052c:	50850513          	addi	a0,a0,1288 # ffffffffc0201a30 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00001517          	auipc	a0,0x1
ffffffffc020053a:	51250513          	addi	a0,a0,1298 # ffffffffc0201a48 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00001517          	auipc	a0,0x1
ffffffffc0200548:	51c50513          	addi	a0,a0,1308 # ffffffffc0201a60 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00001517          	auipc	a0,0x1
ffffffffc0200556:	52650513          	addi	a0,a0,1318 # ffffffffc0201a78 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00001517          	auipc	a0,0x1
ffffffffc0200564:	53050513          	addi	a0,a0,1328 # ffffffffc0201a90 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00001517          	auipc	a0,0x1
ffffffffc0200572:	53a50513          	addi	a0,a0,1338 # ffffffffc0201aa8 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00001517          	auipc	a0,0x1
ffffffffc0200580:	54450513          	addi	a0,a0,1348 # ffffffffc0201ac0 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00001517          	auipc	a0,0x1
ffffffffc020058e:	54e50513          	addi	a0,a0,1358 # ffffffffc0201ad8 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00001517          	auipc	a0,0x1
ffffffffc020059c:	55850513          	addi	a0,a0,1368 # ffffffffc0201af0 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00001517          	auipc	a0,0x1
ffffffffc02005aa:	56250513          	addi	a0,a0,1378 # ffffffffc0201b08 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00001517          	auipc	a0,0x1
ffffffffc02005b8:	56c50513          	addi	a0,a0,1388 # ffffffffc0201b20 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00001517          	auipc	a0,0x1
ffffffffc02005c6:	57650513          	addi	a0,a0,1398 # ffffffffc0201b38 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00001517          	auipc	a0,0x1
ffffffffc02005d4:	58050513          	addi	a0,a0,1408 # ffffffffc0201b50 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00001517          	auipc	a0,0x1
ffffffffc02005e2:	58a50513          	addi	a0,a0,1418 # ffffffffc0201b68 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00001517          	auipc	a0,0x1
ffffffffc02005f0:	59450513          	addi	a0,a0,1428 # ffffffffc0201b80 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00001517          	auipc	a0,0x1
ffffffffc02005fe:	59e50513          	addi	a0,a0,1438 # ffffffffc0201b98 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00001517          	auipc	a0,0x1
ffffffffc020060c:	5a850513          	addi	a0,a0,1448 # ffffffffc0201bb0 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00001517          	auipc	a0,0x1
ffffffffc020061a:	5b250513          	addi	a0,a0,1458 # ffffffffc0201bc8 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00001517          	auipc	a0,0x1
ffffffffc0200628:	5bc50513          	addi	a0,a0,1468 # ffffffffc0201be0 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00001517          	auipc	a0,0x1
ffffffffc020063a:	5c250513          	addi	a0,a0,1474 # ffffffffc0201bf8 <commands+0x370>
}
ffffffffc020063e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200640:	bc8d                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200642 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	00001517          	auipc	a0,0x1
ffffffffc020064e:	5c650513          	addi	a0,a0,1478 # ffffffffc0201c10 <commands+0x388>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200654:	a5fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200658:	8522                	mv	a0,s0
ffffffffc020065a:	e1dff0ef          	jal	ra,ffffffffc0200476 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065e:	10043583          	ld	a1,256(s0)
ffffffffc0200662:	00001517          	auipc	a0,0x1
ffffffffc0200666:	5c650513          	addi	a0,a0,1478 # ffffffffc0201c28 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00001517          	auipc	a0,0x1
ffffffffc0200676:	5ce50513          	addi	a0,a0,1486 # ffffffffc0201c40 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00001517          	auipc	a0,0x1
ffffffffc0200686:	5d650513          	addi	a0,a0,1494 # ffffffffc0201c58 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00001517          	auipc	a0,0x1
ffffffffc020069a:	5da50513          	addi	a0,a0,1498 # ffffffffc0201c70 <commands+0x3e8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a0:	bc09                	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a2:	11853783          	ld	a5,280(a0)
ffffffffc02006a6:	472d                	li	a4,11
ffffffffc02006a8:	0786                	slli	a5,a5,0x1
ffffffffc02006aa:	8385                	srli	a5,a5,0x1
ffffffffc02006ac:	06f76c63          	bltu	a4,a5,ffffffffc0200724 <interrupt_handler+0x82>
ffffffffc02006b0:	00001717          	auipc	a4,0x1
ffffffffc02006b4:	6a070713          	addi	a4,a4,1696 # ffffffffc0201d50 <commands+0x4c8>
ffffffffc02006b8:	078a                	slli	a5,a5,0x2
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	439c                	lw	a5,0(a5)
ffffffffc02006be:	97ba                	add	a5,a5,a4
ffffffffc02006c0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006c2:	00001517          	auipc	a0,0x1
ffffffffc02006c6:	62650513          	addi	a0,a0,1574 # ffffffffc0201ce8 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00001517          	auipc	a0,0x1
ffffffffc02006d0:	5fc50513          	addi	a0,a0,1532 # ffffffffc0201cc8 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00001517          	auipc	a0,0x1
ffffffffc02006da:	5b250513          	addi	a0,a0,1458 # ffffffffc0201c88 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00001517          	auipc	a0,0x1
ffffffffc02006e4:	62850513          	addi	a0,a0,1576 # ffffffffc0201d08 <commands+0x480>
ffffffffc02006e8:	b2e9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006ea:	1141                	addi	sp,sp,-16
ffffffffc02006ec:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006ee:	d4dff0ef          	jal	ra,ffffffffc020043a <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006f2:	00006697          	auipc	a3,0x6
ffffffffc02006f6:	e3668693          	addi	a3,a3,-458 # ffffffffc0206528 <ticks>
ffffffffc02006fa:	629c                	ld	a5,0(a3)
ffffffffc02006fc:	06400713          	li	a4,100
ffffffffc0200700:	0785                	addi	a5,a5,1
ffffffffc0200702:	02e7f733          	remu	a4,a5,a4
ffffffffc0200706:	e29c                	sd	a5,0(a3)
ffffffffc0200708:	cf19                	beqz	a4,ffffffffc0200726 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020070a:	60a2                	ld	ra,8(sp)
ffffffffc020070c:	0141                	addi	sp,sp,16
ffffffffc020070e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200710:	00001517          	auipc	a0,0x1
ffffffffc0200714:	62050513          	addi	a0,a0,1568 # ffffffffc0201d30 <commands+0x4a8>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	58e50513          	addi	a0,a0,1422 # ffffffffc0201ca8 <commands+0x420>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00001517          	auipc	a0,0x1
ffffffffc0200730:	5f450513          	addi	a0,a0,1524 # ffffffffc0201d20 <commands+0x498>
}
ffffffffc0200734:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200736:	bab5                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200738 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200738:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc020073c:	1141                	addi	sp,sp,-16
ffffffffc020073e:	e022                	sd	s0,0(sp)
ffffffffc0200740:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200742:	470d                	li	a4,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200744:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200746:	04e78663          	beq	a5,a4,ffffffffc0200792 <exception_handler+0x5a>
ffffffffc020074a:	02f76c63          	bltu	a4,a5,ffffffffc0200782 <exception_handler+0x4a>
ffffffffc020074e:	4709                	li	a4,2
ffffffffc0200750:	02e79563          	bne	a5,a4,ffffffffc020077a <exception_handler+0x42>
             /* LAB1 CHALLENGE3   YOUR CODE : 2213393 */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:Illegal instruction\n");
ffffffffc0200754:	00001517          	auipc	a0,0x1
ffffffffc0200758:	62c50513          	addi	a0,a0,1580 # ffffffffc0201d80 <commands+0x4f8>
ffffffffc020075c:	957ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            cprintf("Illegal instruction caught at 0x%p\n",tf->epc);
ffffffffc0200760:	10843583          	ld	a1,264(s0)
ffffffffc0200764:	00001517          	auipc	a0,0x1
ffffffffc0200768:	64450513          	addi	a0,a0,1604 # ffffffffc0201da8 <commands+0x520>
ffffffffc020076c:	947ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            tf->epc+=4;
ffffffffc0200770:	10843783          	ld	a5,264(s0)
ffffffffc0200774:	0791                	addi	a5,a5,4
ffffffffc0200776:	10f43423          	sd	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020077a:	60a2                	ld	ra,8(sp)
ffffffffc020077c:	6402                	ld	s0,0(sp)
ffffffffc020077e:	0141                	addi	sp,sp,16
ffffffffc0200780:	8082                	ret
    switch (tf->cause) {
ffffffffc0200782:	17f1                	addi	a5,a5,-4
ffffffffc0200784:	471d                	li	a4,7
ffffffffc0200786:	fef77ae3          	bgeu	a4,a5,ffffffffc020077a <exception_handler+0x42>
}
ffffffffc020078a:	6402                	ld	s0,0(sp)
ffffffffc020078c:	60a2                	ld	ra,8(sp)
ffffffffc020078e:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200790:	bd4d                	j	ffffffffc0200642 <print_trapframe>
            cprintf("Exception type:breakpoint\n");
ffffffffc0200792:	00001517          	auipc	a0,0x1
ffffffffc0200796:	63e50513          	addi	a0,a0,1598 # ffffffffc0201dd0 <commands+0x548>
ffffffffc020079a:	919ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            cprintf("breakpoint caught at 0x%p\n",tf->epc);
ffffffffc020079e:	10843583          	ld	a1,264(s0)
ffffffffc02007a2:	00001517          	auipc	a0,0x1
ffffffffc02007a6:	64e50513          	addi	a0,a0,1614 # ffffffffc0201df0 <commands+0x568>
ffffffffc02007aa:	909ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            tf->epc+=2;
ffffffffc02007ae:	10843783          	ld	a5,264(s0)
}
ffffffffc02007b2:	60a2                	ld	ra,8(sp)
            tf->epc+=2;
ffffffffc02007b4:	0789                	addi	a5,a5,2
ffffffffc02007b6:	10f43423          	sd	a5,264(s0)
}
ffffffffc02007ba:	6402                	ld	s0,0(sp)
ffffffffc02007bc:	0141                	addi	sp,sp,16
ffffffffc02007be:	8082                	ret

ffffffffc02007c0 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc02007c0:	11853783          	ld	a5,280(a0)
ffffffffc02007c4:	0007c363          	bltz	a5,ffffffffc02007ca <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02007c8:	bf85                	j	ffffffffc0200738 <exception_handler>
        interrupt_handler(tf);
ffffffffc02007ca:	bde1                	j	ffffffffc02006a2 <interrupt_handler>

ffffffffc02007cc <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc02007cc:	14011073          	csrw	sscratch,sp
ffffffffc02007d0:	712d                	addi	sp,sp,-288
ffffffffc02007d2:	e002                	sd	zero,0(sp)
ffffffffc02007d4:	e406                	sd	ra,8(sp)
ffffffffc02007d6:	ec0e                	sd	gp,24(sp)
ffffffffc02007d8:	f012                	sd	tp,32(sp)
ffffffffc02007da:	f416                	sd	t0,40(sp)
ffffffffc02007dc:	f81a                	sd	t1,48(sp)
ffffffffc02007de:	fc1e                	sd	t2,56(sp)
ffffffffc02007e0:	e0a2                	sd	s0,64(sp)
ffffffffc02007e2:	e4a6                	sd	s1,72(sp)
ffffffffc02007e4:	e8aa                	sd	a0,80(sp)
ffffffffc02007e6:	ecae                	sd	a1,88(sp)
ffffffffc02007e8:	f0b2                	sd	a2,96(sp)
ffffffffc02007ea:	f4b6                	sd	a3,104(sp)
ffffffffc02007ec:	f8ba                	sd	a4,112(sp)
ffffffffc02007ee:	fcbe                	sd	a5,120(sp)
ffffffffc02007f0:	e142                	sd	a6,128(sp)
ffffffffc02007f2:	e546                	sd	a7,136(sp)
ffffffffc02007f4:	e94a                	sd	s2,144(sp)
ffffffffc02007f6:	ed4e                	sd	s3,152(sp)
ffffffffc02007f8:	f152                	sd	s4,160(sp)
ffffffffc02007fa:	f556                	sd	s5,168(sp)
ffffffffc02007fc:	f95a                	sd	s6,176(sp)
ffffffffc02007fe:	fd5e                	sd	s7,184(sp)
ffffffffc0200800:	e1e2                	sd	s8,192(sp)
ffffffffc0200802:	e5e6                	sd	s9,200(sp)
ffffffffc0200804:	e9ea                	sd	s10,208(sp)
ffffffffc0200806:	edee                	sd	s11,216(sp)
ffffffffc0200808:	f1f2                	sd	t3,224(sp)
ffffffffc020080a:	f5f6                	sd	t4,232(sp)
ffffffffc020080c:	f9fa                	sd	t5,240(sp)
ffffffffc020080e:	fdfe                	sd	t6,248(sp)
ffffffffc0200810:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200814:	100024f3          	csrr	s1,sstatus
ffffffffc0200818:	14102973          	csrr	s2,sepc
ffffffffc020081c:	143029f3          	csrr	s3,stval
ffffffffc0200820:	14202a73          	csrr	s4,scause
ffffffffc0200824:	e822                	sd	s0,16(sp)
ffffffffc0200826:	e226                	sd	s1,256(sp)
ffffffffc0200828:	e64a                	sd	s2,264(sp)
ffffffffc020082a:	ea4e                	sd	s3,272(sp)
ffffffffc020082c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc020082e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200830:	f91ff0ef          	jal	ra,ffffffffc02007c0 <trap>

ffffffffc0200834 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200834:	6492                	ld	s1,256(sp)
ffffffffc0200836:	6932                	ld	s2,264(sp)
ffffffffc0200838:	10049073          	csrw	sstatus,s1
ffffffffc020083c:	14191073          	csrw	sepc,s2
ffffffffc0200840:	60a2                	ld	ra,8(sp)
ffffffffc0200842:	61e2                	ld	gp,24(sp)
ffffffffc0200844:	7202                	ld	tp,32(sp)
ffffffffc0200846:	72a2                	ld	t0,40(sp)
ffffffffc0200848:	7342                	ld	t1,48(sp)
ffffffffc020084a:	73e2                	ld	t2,56(sp)
ffffffffc020084c:	6406                	ld	s0,64(sp)
ffffffffc020084e:	64a6                	ld	s1,72(sp)
ffffffffc0200850:	6546                	ld	a0,80(sp)
ffffffffc0200852:	65e6                	ld	a1,88(sp)
ffffffffc0200854:	7606                	ld	a2,96(sp)
ffffffffc0200856:	76a6                	ld	a3,104(sp)
ffffffffc0200858:	7746                	ld	a4,112(sp)
ffffffffc020085a:	77e6                	ld	a5,120(sp)
ffffffffc020085c:	680a                	ld	a6,128(sp)
ffffffffc020085e:	68aa                	ld	a7,136(sp)
ffffffffc0200860:	694a                	ld	s2,144(sp)
ffffffffc0200862:	69ea                	ld	s3,152(sp)
ffffffffc0200864:	7a0a                	ld	s4,160(sp)
ffffffffc0200866:	7aaa                	ld	s5,168(sp)
ffffffffc0200868:	7b4a                	ld	s6,176(sp)
ffffffffc020086a:	7bea                	ld	s7,184(sp)
ffffffffc020086c:	6c0e                	ld	s8,192(sp)
ffffffffc020086e:	6cae                	ld	s9,200(sp)
ffffffffc0200870:	6d4e                	ld	s10,208(sp)
ffffffffc0200872:	6dee                	ld	s11,216(sp)
ffffffffc0200874:	7e0e                	ld	t3,224(sp)
ffffffffc0200876:	7eae                	ld	t4,232(sp)
ffffffffc0200878:	7f4e                	ld	t5,240(sp)
ffffffffc020087a:	7fee                	ld	t6,248(sp)
ffffffffc020087c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc020087e:	10200073          	sret

ffffffffc0200882 <buddy_init>:
    return power;
}

static void buddy_init(void)
{
    for(int a=0;a<MAX_LIST;a++)
ffffffffc0200882:	00005797          	auipc	a5,0x5
ffffffffc0200886:	79678793          	addi	a5,a5,1942 # ffffffffc0206018 <buddy_struct+0x8>
ffffffffc020088a:	00006717          	auipc	a4,0x6
ffffffffc020088e:	88e70713          	addi	a4,a4,-1906 # ffffffffc0206118 <buddy_struct+0x108>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200892:	e79c                	sd	a5,8(a5)
ffffffffc0200894:	e39c                	sd	a5,0(a5)
ffffffffc0200896:	07c1                	addi	a5,a5,16
ffffffffc0200898:	fee79de3          	bne	a5,a4,ffffffffc0200892 <buddy_init+0x10>
    {
        list_init(free_array+a);
    }
    level=0;
ffffffffc020089c:	00005797          	auipc	a5,0x5
ffffffffc02008a0:	7607aa23          	sw	zero,1908(a5) # ffffffffc0206010 <buddy_struct>
    nr_free=0;
ffffffffc02008a4:	00006797          	auipc	a5,0x6
ffffffffc02008a8:	8607aa23          	sw	zero,-1932(a5) # ffffffffc0206118 <buddy_struct+0x108>
    return;
}
ffffffffc02008ac:	8082                	ret

ffffffffc02008ae <buddy_nr_free_pages>:
    return;
}
static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02008ae:	00006517          	auipc	a0,0x6
ffffffffc02008b2:	86a56503          	lwu	a0,-1942(a0) # ffffffffc0206118 <buddy_struct+0x108>
ffffffffc02008b6:	8082                	ret

ffffffffc02008b8 <buddy_check>:
    free_pages(p2, 5);
    assert(nr_free==24);

}   

static void buddy_check(void) {
ffffffffc02008b8:	7179                	addi	sp,sp,-48
ffffffffc02008ba:	ec26                	sd	s1,24(sp)
    cprintf("空闲块数为：%d\n", nr_free);
ffffffffc02008bc:	00005497          	auipc	s1,0x5
ffffffffc02008c0:	75448493          	addi	s1,s1,1876 # ffffffffc0206010 <buddy_struct>
ffffffffc02008c4:	1084a583          	lw	a1,264(s1)
ffffffffc02008c8:	00001517          	auipc	a0,0x1
ffffffffc02008cc:	54850513          	addi	a0,a0,1352 # ffffffffc0201e10 <commands+0x588>
static void buddy_check(void) {
ffffffffc02008d0:	f406                	sd	ra,40(sp)
ffffffffc02008d2:	f022                	sd	s0,32(sp)
ffffffffc02008d4:	e84a                	sd	s2,16(sp)
ffffffffc02008d6:	e44e                	sd	s3,8(sp)
    cprintf("空闲块数为：%d\n", nr_free);
ffffffffc02008d8:	fdaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    p0 = alloc_pages(5);
ffffffffc02008dc:	4515                	li	a0,5
ffffffffc02008de:	5ac000ef          	jal	ra,ffffffffc0200e8a <alloc_pages>
ffffffffc02008e2:	892a                	mv	s2,a0
    p1 = alloc_pages(5);
ffffffffc02008e4:	4515                	li	a0,5
ffffffffc02008e6:	5a4000ef          	jal	ra,ffffffffc0200e8a <alloc_pages>
ffffffffc02008ea:	89aa                	mv	s3,a0
    p2 = alloc_pages(5);
ffffffffc02008ec:	4515                	li	a0,5
ffffffffc02008ee:	59c000ef          	jal	ra,ffffffffc0200e8a <alloc_pages>
ffffffffc02008f2:	842a                	mv	s0,a0
    cprintf("p0的虚拟地址0x%016lx.\n", p0);
ffffffffc02008f4:	85ca                	mv	a1,s2
ffffffffc02008f6:	00001517          	auipc	a0,0x1
ffffffffc02008fa:	53250513          	addi	a0,a0,1330 # ffffffffc0201e28 <commands+0x5a0>
ffffffffc02008fe:	fb4ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p1的虚拟地址0x%016lx.\n", p1);
ffffffffc0200902:	85ce                	mv	a1,s3
ffffffffc0200904:	00001517          	auipc	a0,0x1
ffffffffc0200908:	54450513          	addi	a0,a0,1348 # ffffffffc0201e48 <commands+0x5c0>
ffffffffc020090c:	fa6ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("p2的虚拟地址0x%016lx.\n", p2);
ffffffffc0200910:	85a2                	mv	a1,s0
ffffffffc0200912:	00001517          	auipc	a0,0x1
ffffffffc0200916:	55650513          	addi	a0,a0,1366 # ffffffffc0201e68 <commands+0x5e0>
ffffffffc020091a:	f98ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020091e:	0d390563          	beq	s2,s3,ffffffffc02009e8 <buddy_check+0x130>
ffffffffc0200922:	0c890363          	beq	s2,s0,ffffffffc02009e8 <buddy_check+0x130>
ffffffffc0200926:	0c898163          	beq	s3,s0,ffffffffc02009e8 <buddy_check+0x130>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020092a:	00092783          	lw	a5,0(s2)
ffffffffc020092e:	efe9                	bnez	a5,ffffffffc0200a08 <buddy_check+0x150>
ffffffffc0200930:	0009a783          	lw	a5,0(s3)
ffffffffc0200934:	ebf1                	bnez	a5,ffffffffc0200a08 <buddy_check+0x150>
ffffffffc0200936:	401c                	lw	a5,0(s0)
ffffffffc0200938:	ebe1                	bnez	a5,ffffffffc0200a08 <buddy_check+0x150>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020093a:	00006797          	auipc	a5,0x6
ffffffffc020093e:	c067b783          	ld	a5,-1018(a5) # ffffffffc0206540 <pages>
ffffffffc0200942:	40f90733          	sub	a4,s2,a5
ffffffffc0200946:	870d                	srai	a4,a4,0x3
ffffffffc0200948:	00002597          	auipc	a1,0x2
ffffffffc020094c:	a605b583          	ld	a1,-1440(a1) # ffffffffc02023a8 <error_string+0x38>
ffffffffc0200950:	02b70733          	mul	a4,a4,a1
ffffffffc0200954:	00002617          	auipc	a2,0x2
ffffffffc0200958:	a5c63603          	ld	a2,-1444(a2) # ffffffffc02023b0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020095c:	00006697          	auipc	a3,0x6
ffffffffc0200960:	bdc6b683          	ld	a3,-1060(a3) # ffffffffc0206538 <npage>
ffffffffc0200964:	06b2                	slli	a3,a3,0xc
ffffffffc0200966:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200968:	0732                	slli	a4,a4,0xc
ffffffffc020096a:	0ad77f63          	bgeu	a4,a3,ffffffffc0200a28 <buddy_check+0x170>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020096e:	40f98733          	sub	a4,s3,a5
ffffffffc0200972:	870d                	srai	a4,a4,0x3
ffffffffc0200974:	02b70733          	mul	a4,a4,a1
ffffffffc0200978:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020097a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020097c:	0ed77663          	bgeu	a4,a3,ffffffffc0200a68 <buddy_check+0x1b0>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200980:	40f407b3          	sub	a5,s0,a5
ffffffffc0200984:	878d                	srai	a5,a5,0x3
ffffffffc0200986:	02b787b3          	mul	a5,a5,a1
ffffffffc020098a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020098c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020098e:	0ad7fd63          	bgeu	a5,a3,ffffffffc0200a48 <buddy_check+0x190>
    assert(alloc_page() == NULL);
ffffffffc0200992:	4505                	li	a0,1
    nr_free = 0;
ffffffffc0200994:	00005797          	auipc	a5,0x5
ffffffffc0200998:	7807a223          	sw	zero,1924(a5) # ffffffffc0206118 <buddy_struct+0x108>
    assert(alloc_page() == NULL);
ffffffffc020099c:	4ee000ef          	jal	ra,ffffffffc0200e8a <alloc_pages>
ffffffffc02009a0:	14051463          	bnez	a0,ffffffffc0200ae8 <buddy_check+0x230>
    free_pages(p0, 5);
ffffffffc02009a4:	4595                	li	a1,5
ffffffffc02009a6:	854a                	mv	a0,s2
ffffffffc02009a8:	520000ef          	jal	ra,ffffffffc0200ec8 <free_pages>
    assert(nr_free==8);
ffffffffc02009ac:	1084a703          	lw	a4,264(s1)
ffffffffc02009b0:	47a1                	li	a5,8
ffffffffc02009b2:	10f71b63          	bne	a4,a5,ffffffffc0200ac8 <buddy_check+0x210>
    free_pages(p1, 5);
ffffffffc02009b6:	4595                	li	a1,5
ffffffffc02009b8:	854e                	mv	a0,s3
ffffffffc02009ba:	50e000ef          	jal	ra,ffffffffc0200ec8 <free_pages>
    assert(nr_free==16);
ffffffffc02009be:	1084a703          	lw	a4,264(s1)
ffffffffc02009c2:	47c1                	li	a5,16
ffffffffc02009c4:	0ef71263          	bne	a4,a5,ffffffffc0200aa8 <buddy_check+0x1f0>
    free_pages(p2, 5);
ffffffffc02009c8:	4595                	li	a1,5
ffffffffc02009ca:	8522                	mv	a0,s0
ffffffffc02009cc:	4fc000ef          	jal	ra,ffffffffc0200ec8 <free_pages>
    assert(nr_free==24);
ffffffffc02009d0:	1084a703          	lw	a4,264(s1)
ffffffffc02009d4:	47e1                	li	a5,24
ffffffffc02009d6:	0af71963          	bne	a4,a5,ffffffffc0200a88 <buddy_check+0x1d0>
    basic_check();
}
ffffffffc02009da:	70a2                	ld	ra,40(sp)
ffffffffc02009dc:	7402                	ld	s0,32(sp)
ffffffffc02009de:	64e2                	ld	s1,24(sp)
ffffffffc02009e0:	6942                	ld	s2,16(sp)
ffffffffc02009e2:	69a2                	ld	s3,8(sp)
ffffffffc02009e4:	6145                	addi	sp,sp,48
ffffffffc02009e6:	8082                	ret
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02009e8:	00001697          	auipc	a3,0x1
ffffffffc02009ec:	4a068693          	addi	a3,a3,1184 # ffffffffc0201e88 <commands+0x600>
ffffffffc02009f0:	00001617          	auipc	a2,0x1
ffffffffc02009f4:	4c060613          	addi	a2,a2,1216 # ffffffffc0201eb0 <commands+0x628>
ffffffffc02009f8:	0b400593          	li	a1,180
ffffffffc02009fc:	00001517          	auipc	a0,0x1
ffffffffc0200a00:	4cc50513          	addi	a0,a0,1228 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200a04:	9a9ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200a08:	00001697          	auipc	a3,0x1
ffffffffc0200a0c:	4d868693          	addi	a3,a3,1240 # ffffffffc0201ee0 <commands+0x658>
ffffffffc0200a10:	00001617          	auipc	a2,0x1
ffffffffc0200a14:	4a060613          	addi	a2,a2,1184 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200a18:	0b500593          	li	a1,181
ffffffffc0200a1c:	00001517          	auipc	a0,0x1
ffffffffc0200a20:	4ac50513          	addi	a0,a0,1196 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200a24:	989ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200a28:	00001697          	auipc	a3,0x1
ffffffffc0200a2c:	4f868693          	addi	a3,a3,1272 # ffffffffc0201f20 <commands+0x698>
ffffffffc0200a30:	00001617          	auipc	a2,0x1
ffffffffc0200a34:	48060613          	addi	a2,a2,1152 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200a38:	0b700593          	li	a1,183
ffffffffc0200a3c:	00001517          	auipc	a0,0x1
ffffffffc0200a40:	48c50513          	addi	a0,a0,1164 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200a44:	969ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a48:	00001697          	auipc	a3,0x1
ffffffffc0200a4c:	51868693          	addi	a3,a3,1304 # ffffffffc0201f60 <commands+0x6d8>
ffffffffc0200a50:	00001617          	auipc	a2,0x1
ffffffffc0200a54:	46060613          	addi	a2,a2,1120 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200a58:	0b900593          	li	a1,185
ffffffffc0200a5c:	00001517          	auipc	a0,0x1
ffffffffc0200a60:	46c50513          	addi	a0,a0,1132 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200a64:	949ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200a68:	00001697          	auipc	a3,0x1
ffffffffc0200a6c:	4d868693          	addi	a3,a3,1240 # ffffffffc0201f40 <commands+0x6b8>
ffffffffc0200a70:	00001617          	auipc	a2,0x1
ffffffffc0200a74:	44060613          	addi	a2,a2,1088 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200a78:	0b800593          	li	a1,184
ffffffffc0200a7c:	00001517          	auipc	a0,0x1
ffffffffc0200a80:	44c50513          	addi	a0,a0,1100 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200a84:	929ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free==24);
ffffffffc0200a88:	00001697          	auipc	a3,0x1
ffffffffc0200a8c:	53068693          	addi	a3,a3,1328 # ffffffffc0201fb8 <commands+0x730>
ffffffffc0200a90:	00001617          	auipc	a2,0x1
ffffffffc0200a94:	42060613          	addi	a2,a2,1056 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200a98:	0c700593          	li	a1,199
ffffffffc0200a9c:	00001517          	auipc	a0,0x1
ffffffffc0200aa0:	42c50513          	addi	a0,a0,1068 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200aa4:	909ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free==16);
ffffffffc0200aa8:	00001697          	auipc	a3,0x1
ffffffffc0200aac:	50068693          	addi	a3,a3,1280 # ffffffffc0201fa8 <commands+0x720>
ffffffffc0200ab0:	00001617          	auipc	a2,0x1
ffffffffc0200ab4:	40060613          	addi	a2,a2,1024 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200ab8:	0c500593          	li	a1,197
ffffffffc0200abc:	00001517          	auipc	a0,0x1
ffffffffc0200ac0:	40c50513          	addi	a0,a0,1036 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200ac4:	8e9ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free==8);
ffffffffc0200ac8:	00001697          	auipc	a3,0x1
ffffffffc0200acc:	4d068693          	addi	a3,a3,1232 # ffffffffc0201f98 <commands+0x710>
ffffffffc0200ad0:	00001617          	auipc	a2,0x1
ffffffffc0200ad4:	3e060613          	addi	a2,a2,992 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200ad8:	0c300593          	li	a1,195
ffffffffc0200adc:	00001517          	auipc	a0,0x1
ffffffffc0200ae0:	3ec50513          	addi	a0,a0,1004 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200ae4:	8c9ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ae8:	00001697          	auipc	a3,0x1
ffffffffc0200aec:	49868693          	addi	a3,a3,1176 # ffffffffc0201f80 <commands+0x6f8>
ffffffffc0200af0:	00001617          	auipc	a2,0x1
ffffffffc0200af4:	3c060613          	addi	a2,a2,960 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200af8:	0bf00593          	li	a1,191
ffffffffc0200afc:	00001517          	auipc	a0,0x1
ffffffffc0200b00:	3cc50513          	addi	a0,a0,972 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200b04:	8a9ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200b08 <buddy_alloc_pages>:
{
ffffffffc0200b08:	1101                	addi	sp,sp,-32
ffffffffc0200b0a:	ec06                	sd	ra,24(sp)
ffffffffc0200b0c:	e822                	sd	s0,16(sp)
ffffffffc0200b0e:	e426                	sd	s1,8(sp)
    assert(n > 0);
ffffffffc0200b10:	10050763          	beqz	a0,ffffffffc0200c1e <buddy_alloc_pages+0x116>
    if (n > nr_free) {
ffffffffc0200b14:	00005297          	auipc	t0,0x5
ffffffffc0200b18:	4fc28293          	addi	t0,t0,1276 # ffffffffc0206010 <buddy_struct>
ffffffffc0200b1c:	1082e783          	lwu	a5,264(t0)
ffffffffc0200b20:	0aa7ed63          	bltu	a5,a0,ffffffffc0200bda <buddy_alloc_pages+0xd2>
    while(n>>=1)
ffffffffc0200b24:	00155793          	srli	a5,a0,0x1
    uint32_t power = 0;
ffffffffc0200b28:	4881                	li	a7,0
    while(n>>=1)
ffffffffc0200b2a:	c781                	beqz	a5,ffffffffc0200b32 <buddy_alloc_pages+0x2a>
ffffffffc0200b2c:	8385                	srli	a5,a5,0x1
        power++;
ffffffffc0200b2e:	2885                	addiw	a7,a7,1
    while(n>>=1)
ffffffffc0200b30:	fff5                	bnez	a5,ffffffffc0200b2c <buddy_alloc_pages+0x24>
    if(!(IS_POWER_OF_2(n))) //要用更大的
ffffffffc0200b32:	fff50793          	addi	a5,a0,-1
ffffffffc0200b36:	8d7d                	and	a0,a0,a5
ffffffffc0200b38:	e55d                	bnez	a0,ffffffffc0200be6 <buddy_alloc_pages+0xde>
    level = get_power(n);
ffffffffc0200b3a:	0112a023          	sw	a7,0(t0)
    while(spilttime<MAX_LIST) //尝试分块的次数比层数还大说明找不到合适的块
ffffffffc0200b3e:	00489e93          	slli	t4,a7,0x4
        if(!(list_empty(free_array+level)))
ffffffffc0200b42:	02089793          	slli	a5,a7,0x20
ffffffffc0200b46:	00005397          	auipc	t2,0x5
ffffffffc0200b4a:	4d238393          	addi	t2,t2,1234 # ffffffffc0206018 <buddy_struct+0x8>
ffffffffc0200b4e:	01c7d313          	srli	t1,a5,0x1c
ffffffffc0200b52:	0ea1                	addi	t4,t4,8
ffffffffc0200b54:	55e1                	li	a1,-8
ffffffffc0200b56:	931e                	add	t1,t1,t2
ffffffffc0200b58:	00088e1b          	sext.w	t3,a7
ffffffffc0200b5c:	9e96                	add	t4,t4,t0
ffffffffc0200b5e:	4841                	li	a6,16
            for(int a=level;a<MAX_LIST;a++)
ffffffffc0200b60:	4fbd                	li	t6,15
ffffffffc0200b62:	405585b3          	sub	a1,a1,t0
ffffffffc0200b66:	4541                	li	a0,16
                    struct Page *page2=page1+(1<<(a-1));
ffffffffc0200b68:	4405                	li	s0,1
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
ffffffffc0200b6a:	00833783          	ld	a5,8(t1)
        if(!(list_empty(free_array+level)))
ffffffffc0200b6e:	08f31063          	bne	t1,a5,ffffffffc0200bee <buddy_alloc_pages+0xe6>
            for(int a=level;a<MAX_LIST;a++)
ffffffffc0200b72:	07cfc163          	blt	t6,t3,ffffffffc0200bd4 <buddy_alloc_pages+0xcc>
ffffffffc0200b76:	87f6                	mv	a5,t4
ffffffffc0200b78:	8772                	mv	a4,t3
ffffffffc0200b7a:	a029                	j	ffffffffc0200b84 <buddy_alloc_pages+0x7c>
ffffffffc0200b7c:	2705                	addiw	a4,a4,1
ffffffffc0200b7e:	07c1                	addi	a5,a5,16
ffffffffc0200b80:	04a70a63          	beq	a4,a0,ffffffffc0200bd4 <buddy_alloc_pages+0xcc>
ffffffffc0200b84:	6794                	ld	a3,8(a5)
ffffffffc0200b86:	00f58633          	add	a2,a1,a5
                if(!list_empty(free_array+a)) //分块
ffffffffc0200b8a:	fef689e3          	beq	a3,a5,ffffffffc0200b7c <buddy_alloc_pages+0x74>
                    struct Page *page2=page1+(1<<(a-1));
ffffffffc0200b8e:	377d                	addiw	a4,a4,-1
ffffffffc0200b90:	00e41f3b          	sllw	t5,s0,a4
ffffffffc0200b94:	002f1793          	slli	a5,t5,0x2
ffffffffc0200b98:	97fa                	add	a5,a5,t5
ffffffffc0200b9a:	078e                	slli	a5,a5,0x3
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b9c:	0086bf03          	ld	t5,8(a3)
ffffffffc0200ba0:	6284                	ld	s1,0(a3)
ffffffffc0200ba2:	17a1                	addi	a5,a5,-24
                    page1->property=a-1; //修改幂次
ffffffffc0200ba4:	fee6ac23          	sw	a4,-8(a3)
                    struct Page *page2=page1+(1<<(a-1));
ffffffffc0200ba8:	97b6                	add	a5,a5,a3
                    page2->property=a-1;
ffffffffc0200baa:	cb98                	sw	a4,16(a5)
                    list_add(free_array+a-1,&(page2->page_link));
ffffffffc0200bac:	1641                	addi	a2,a2,-16
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200bae:	01e4b423          	sd	t5,8(s1)
ffffffffc0200bb2:	961e                	add	a2,a2,t2
    __list_add(elm, listelm, listelm->next);
ffffffffc0200bb4:	6618                	ld	a4,8(a2)
    next->prev = prev;
ffffffffc0200bb6:	009f3023          	sd	s1,0(t5)
ffffffffc0200bba:	01878f13          	addi	t5,a5,24
    prev->next = next->prev = elm;
ffffffffc0200bbe:	01e73023          	sd	t5,0(a4)
ffffffffc0200bc2:	01e63423          	sd	t5,8(a2)
    elm->next = next;
ffffffffc0200bc6:	f398                	sd	a4,32(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200bc8:	6618                	ld	a4,8(a2)
    elm->prev = prev;
ffffffffc0200bca:	ef90                	sd	a2,24(a5)
    prev->next = next->prev = elm;
ffffffffc0200bcc:	e314                	sd	a3,0(a4)
ffffffffc0200bce:	e614                	sd	a3,8(a2)
    elm->next = next;
ffffffffc0200bd0:	e698                	sd	a4,8(a3)
    elm->prev = prev;
ffffffffc0200bd2:	e290                	sd	a2,0(a3)
    while(spilttime<MAX_LIST) //尝试分块的次数比层数还大说明找不到合适的块
ffffffffc0200bd4:	387d                	addiw	a6,a6,-1
ffffffffc0200bd6:	f8081ae3          	bnez	a6,ffffffffc0200b6a <buddy_alloc_pages+0x62>
}
ffffffffc0200bda:	60e2                	ld	ra,24(sp)
ffffffffc0200bdc:	6442                	ld	s0,16(sp)
ffffffffc0200bde:	64a2                	ld	s1,8(sp)
        return NULL;
ffffffffc0200be0:	4501                	li	a0,0
}
ffffffffc0200be2:	6105                	addi	sp,sp,32
ffffffffc0200be4:	8082                	ret
        level++;
ffffffffc0200be6:	2885                	addiw	a7,a7,1
ffffffffc0200be8:	0112a023          	sw	a7,0(t0)
ffffffffc0200bec:	bf89                	j	ffffffffc0200b3e <buddy_alloc_pages+0x36>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200bee:	6798                	ld	a4,8(a5)
ffffffffc0200bf0:	6394                	ld	a3,0(a5)
            page=le2page(list_next(free_array+level),page_link); // convert list entry to page
ffffffffc0200bf2:	fe878513          	addi	a0,a5,-24
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200bf6:	17c1                	addi	a5,a5,-16
    prev->next = next;
ffffffffc0200bf8:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200bfa:	e314                	sd	a3,0(a4)
ffffffffc0200bfc:	4709                	li	a4,2
ffffffffc0200bfe:	40e7b02f          	amoor.d	zero,a4,(a5)
            nr_free-=the_n; //减去用掉的页
ffffffffc0200c02:	1082a783          	lw	a5,264(t0)
    size_t the_n=1<<level;
ffffffffc0200c06:	4705                	li	a4,1
}
ffffffffc0200c08:	60e2                	ld	ra,24(sp)
ffffffffc0200c0a:	6442                	ld	s0,16(sp)
    size_t the_n=1<<level;
ffffffffc0200c0c:	011718bb          	sllw	a7,a4,a7
            nr_free-=the_n; //减去用掉的页
ffffffffc0200c10:	411787bb          	subw	a5,a5,a7
ffffffffc0200c14:	10f2a423          	sw	a5,264(t0)
}
ffffffffc0200c18:	64a2                	ld	s1,8(sp)
ffffffffc0200c1a:	6105                	addi	sp,sp,32
ffffffffc0200c1c:	8082                	ret
    assert(n > 0);
ffffffffc0200c1e:	00001697          	auipc	a3,0x1
ffffffffc0200c22:	3aa68693          	addi	a3,a3,938 # ffffffffc0201fc8 <commands+0x740>
ffffffffc0200c26:	00001617          	auipc	a2,0x1
ffffffffc0200c2a:	28a60613          	addi	a2,a2,650 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200c2e:	04300593          	li	a1,67
ffffffffc0200c32:	00001517          	auipc	a0,0x1
ffffffffc0200c36:	29650513          	addi	a0,a0,662 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200c3a:	f72ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200c3e <buddy_init_memmap>:
{
ffffffffc0200c3e:	1141                	addi	sp,sp,-16
ffffffffc0200c40:	e406                	sd	ra,8(sp)
    assert(n>0);
ffffffffc0200c42:	c1c5                	beqz	a1,ffffffffc0200ce2 <buddy_init_memmap+0xa4>
    while(n>>=1)
ffffffffc0200c44:	0015d793          	srli	a5,a1,0x1
    uint32_t power = 0;
ffffffffc0200c48:	4601                	li	a2,0
    while(n>>=1)
ffffffffc0200c4a:	cba5                	beqz	a5,ffffffffc0200cba <buddy_init_memmap+0x7c>
ffffffffc0200c4c:	8385                	srli	a5,a5,0x1
        power++;
ffffffffc0200c4e:	2605                	addiw	a2,a2,1
    while(n>>=1)
ffffffffc0200c50:	fff5                	bnez	a5,ffffffffc0200c4c <buddy_init_memmap+0xe>
    size_t the_n=1<<level;
ffffffffc0200c52:	4785                	li	a5,1
ffffffffc0200c54:	00c797bb          	sllw	a5,a5,a2
    for (; p != base + the_n; p+=1) 
ffffffffc0200c58:	00279693          	slli	a3,a5,0x2
ffffffffc0200c5c:	96be                	add	a3,a3,a5
ffffffffc0200c5e:	068e                	slli	a3,a3,0x3
    level=get_power(n);
ffffffffc0200c60:	00005597          	auipc	a1,0x5
ffffffffc0200c64:	3b058593          	addi	a1,a1,944 # ffffffffc0206010 <buddy_struct>
    nr_free=the_n; //该块大小
ffffffffc0200c68:	10f5a423          	sw	a5,264(a1)
    level=get_power(n);
ffffffffc0200c6c:	c190                	sw	a2,0(a1)
    for (; p != base + the_n; p+=1) 
ffffffffc0200c6e:	96aa                	add	a3,a3,a0
ffffffffc0200c70:	87aa                	mv	a5,a0
ffffffffc0200c72:	00d50f63          	beq	a0,a3,ffffffffc0200c90 <buddy_init_memmap+0x52>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c76:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0200c78:	8b05                	andi	a4,a4,1
ffffffffc0200c7a:	c721                	beqz	a4,ffffffffc0200cc2 <buddy_init_memmap+0x84>
        p->flags = 0;
ffffffffc0200c7c:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0200c80:	0007a823          	sw	zero,16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200c84:	0007a023          	sw	zero,0(a5)
    for (; p != base + the_n; p+=1) 
ffffffffc0200c88:	02878793          	addi	a5,a5,40
ffffffffc0200c8c:	fed795e3          	bne	a5,a3,ffffffffc0200c76 <buddy_init_memmap+0x38>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c90:	02061713          	slli	a4,a2,0x20
ffffffffc0200c94:	01c75793          	srli	a5,a4,0x1c
ffffffffc0200c98:	00f586b3          	add	a3,a1,a5
ffffffffc0200c9c:	6a98                	ld	a4,16(a3)
    list_add(&(free_array[level]), &(base->page_link));
ffffffffc0200c9e:	01850813          	addi	a6,a0,24
}
ffffffffc0200ca2:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200ca4:	01073023          	sd	a6,0(a4)
    list_add(&(free_array[level]), &(base->page_link));
ffffffffc0200ca8:	07a1                	addi	a5,a5,8
ffffffffc0200caa:	0106b823          	sd	a6,16(a3)
ffffffffc0200cae:	95be                	add	a1,a1,a5
    elm->next = next;
ffffffffc0200cb0:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc0200cb2:	ed0c                	sd	a1,24(a0)
    base->property=level; //不同于前面算法，这里存的是次数
ffffffffc0200cb4:	c910                	sw	a2,16(a0)
}
ffffffffc0200cb6:	0141                	addi	sp,sp,16
ffffffffc0200cb8:	8082                	ret
    while(n>>=1)
ffffffffc0200cba:	02800693          	li	a3,40
ffffffffc0200cbe:	4785                	li	a5,1
ffffffffc0200cc0:	b745                	j	ffffffffc0200c60 <buddy_init_memmap+0x22>
        assert(PageReserved(p));
ffffffffc0200cc2:	00001697          	auipc	a3,0x1
ffffffffc0200cc6:	31668693          	addi	a3,a3,790 # ffffffffc0201fd8 <commands+0x750>
ffffffffc0200cca:	00001617          	auipc	a2,0x1
ffffffffc0200cce:	1e660613          	addi	a2,a2,486 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200cd2:	03700593          	li	a1,55
ffffffffc0200cd6:	00001517          	auipc	a0,0x1
ffffffffc0200cda:	1f250513          	addi	a0,a0,498 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200cde:	eceff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n>0);
ffffffffc0200ce2:	00001697          	auipc	a3,0x1
ffffffffc0200ce6:	2ee68693          	addi	a3,a3,750 # ffffffffc0201fd0 <commands+0x748>
ffffffffc0200cea:	00001617          	auipc	a2,0x1
ffffffffc0200cee:	1c660613          	addi	a2,a2,454 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200cf2:	02f00593          	li	a1,47
ffffffffc0200cf6:	00001517          	auipc	a0,0x1
ffffffffc0200cfa:	1d250513          	addi	a0,a0,466 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200cfe:	eaeff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200d02 <buddy_free_pages>:
{
ffffffffc0200d02:	7179                	addi	sp,sp,-48
ffffffffc0200d04:	f406                	sd	ra,40(sp)
ffffffffc0200d06:	f022                	sd	s0,32(sp)
ffffffffc0200d08:	ec26                	sd	s1,24(sp)
ffffffffc0200d0a:	e84a                	sd	s2,16(sp)
ffffffffc0200d0c:	e44e                	sd	s3,8(sp)
ffffffffc0200d0e:	e052                	sd	s4,0(sp)
    assert(n > 0);
ffffffffc0200d10:	14058d63          	beqz	a1,ffffffffc0200e6a <buddy_free_pages+0x168>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d14:	00006f97          	auipc	t6,0x6
ffffffffc0200d18:	82cf8f93          	addi	t6,t6,-2004 # ffffffffc0206540 <pages>
ffffffffc0200d1c:	000fb783          	ld	a5,0(t6)
ffffffffc0200d20:	00001f17          	auipc	t5,0x1
ffffffffc0200d24:	688f3f03          	ld	t5,1672(t5) # ffffffffc02023a8 <error_string+0x38>
ffffffffc0200d28:	00001e97          	auipc	t4,0x1
ffffffffc0200d2c:	688e8e93          	addi	t4,t4,1672 # ffffffffc02023b0 <nbase>
ffffffffc0200d30:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d34:	878d                	srai	a5,a5,0x3
ffffffffc0200d36:	03e787b3          	mul	a5,a5,t5
ffffffffc0200d3a:	000eb703          	ld	a4,0(t4)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));//伙伴块的物理页号
ffffffffc0200d3e:	00005e17          	auipc	t3,0x5
ffffffffc0200d42:	7f2e0e13          	addi	t3,t3,2034 # ffffffffc0206530 <fppn>
    unsigned int newfree=1<<(base->property);
ffffffffc0200d46:	4910                	lw	a2,16(a0)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));//伙伴块的物理页号
ffffffffc0200d48:	000e3683          	ld	a3,0(t3)
    unsigned int newfree=1<<(base->property);
ffffffffc0200d4c:	4585                	li	a1,1
ffffffffc0200d4e:	00c5933b          	sllw	t1,a1,a2
    nr_free+=newfree;  
ffffffffc0200d52:	00005897          	auipc	a7,0x5
ffffffffc0200d56:	2be88893          	addi	a7,a7,702 # ffffffffc0206010 <buddy_struct>
ffffffffc0200d5a:	1088a803          	lw	a6,264(a7)
    unsigned int newfree=1<<(base->property);
ffffffffc0200d5e:	859a                	mv	a1,t1
ffffffffc0200d60:	97ba                	add	a5,a5,a4
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));//伙伴块的物理页号
ffffffffc0200d62:	40d78733          	sub	a4,a5,a3
ffffffffc0200d66:	00674733          	xor	a4,a4,t1
    return page+(ppn-page2ppn(page));
ffffffffc0200d6a:	40f687b3          	sub	a5,a3,a5
ffffffffc0200d6e:	97ba                	add	a5,a5,a4
ffffffffc0200d70:	00279713          	slli	a4,a5,0x2
    list_add(free_array+(free_page->property),&(free_page->page_link));
ffffffffc0200d74:	02061693          	slli	a3,a2,0x20
ffffffffc0200d78:	01c6d313          	srli	t1,a3,0x1c
    return page+(ppn-page2ppn(page));
ffffffffc0200d7c:	97ba                	add	a5,a5,a4
    list_add(free_array+(free_page->property),&(free_page->page_link));
ffffffffc0200d7e:	00005697          	auipc	a3,0x5
ffffffffc0200d82:	29a68693          	addi	a3,a3,666 # ffffffffc0206018 <buddy_struct+0x8>
ffffffffc0200d86:	969a                	add	a3,a3,t1
    return page+(ppn-page2ppn(page));
ffffffffc0200d88:	078e                	slli	a5,a5,0x3
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d8a:	0086b303          	ld	t1,8(a3)
ffffffffc0200d8e:	97aa                	add	a5,a5,a0
ffffffffc0200d90:	6798                	ld	a4,8(a5)
    nr_free+=newfree;  
ffffffffc0200d92:	00b805bb          	addw	a1,a6,a1
ffffffffc0200d96:	10b8a423          	sw	a1,264(a7)
    list_add(free_array+(free_page->property),&(free_page->page_link));
ffffffffc0200d9a:	01850813          	addi	a6,a0,24
    prev->next = next->prev = elm;
ffffffffc0200d9e:	01033023          	sd	a6,0(t1)
ffffffffc0200da2:	0106b423          	sd	a6,8(a3)
ffffffffc0200da6:	8305                	srli	a4,a4,0x1
    elm->next = next;
ffffffffc0200da8:	02653023          	sd	t1,32(a0)
    elm->prev = prev;
ffffffffc0200dac:	ed14                	sd	a3,24(a0)
    while(!PageProperty(free_page_buddy)&&free_page->property<14)
ffffffffc0200dae:	8b05                	andi	a4,a4,1
            ClearPageProperty(free_page);
ffffffffc0200db0:	00850313          	addi	t1,a0,8
    while(!PageProperty(free_page_buddy)&&free_page->property<14)
ffffffffc0200db4:	42b5                	li	t0,13
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200db6:	5475                	li	s0,-3
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));//伙伴块的物理页号
ffffffffc0200db8:	4385                	li	t2,1
    while(!PageProperty(free_page_buddy)&&free_page->property<14)
ffffffffc0200dba:	ef49                	bnez	a4,ffffffffc0200e54 <buddy_free_pages+0x152>
ffffffffc0200dbc:	08c2ec63          	bltu	t0,a2,ffffffffc0200e54 <buddy_free_pages+0x152>
        if(free_page_buddy<free_page)
ffffffffc0200dc0:	00a7fe63          	bgeu	a5,a0,ffffffffc0200ddc <buddy_free_pages+0xda>
            free_page->property=0;
ffffffffc0200dc4:	00052823          	sw	zero,16(a0)
ffffffffc0200dc8:	6083302f          	amoand.d	zero,s0,(t1)
    ClearPageProperty(free_page);
ffffffffc0200dcc:	872a                	mv	a4,a0
        free_page->property+=1;
ffffffffc0200dce:	4b90                	lw	a2,16(a5)
    ClearPageProperty(free_page);
ffffffffc0200dd0:	853e                	mv	a0,a5
ffffffffc0200dd2:	00878313          	addi	t1,a5,8
ffffffffc0200dd6:	01878813          	addi	a6,a5,24
ffffffffc0200dda:	87ba                	mv	a5,a4
ffffffffc0200ddc:	000fb703          	ld	a4,0(t6)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200de0:	6d04                	ld	s1,24(a0)
ffffffffc0200de2:	710c                	ld	a1,32(a0)
ffffffffc0200de4:	40e50733          	sub	a4,a0,a4
ffffffffc0200de8:	870d                	srai	a4,a4,0x3
ffffffffc0200dea:	03e70733          	mul	a4,a4,t5
ffffffffc0200dee:	000eb983          	ld	s3,0(t4)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));//伙伴块的物理页号
ffffffffc0200df2:	000e3683          	ld	a3,0(t3)
    prev->next = next;
ffffffffc0200df6:	e48c                	sd	a1,8(s1)
    next->prev = prev;
ffffffffc0200df8:	e184                	sd	s1,0(a1)
        free_page->property+=1;
ffffffffc0200dfa:	2605                	addiw	a2,a2,1
    __list_del(listelm->prev, listelm->next);
ffffffffc0200dfc:	0187b903          	ld	s2,24(a5)
ffffffffc0200e00:	7384                	ld	s1,32(a5)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));//伙伴块的物理页号
ffffffffc0200e02:	00c397bb          	sllw	a5,t2,a2
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e06:	02061a13          	slli	s4,a2,0x20
ffffffffc0200e0a:	974e                	add	a4,a4,s3
ffffffffc0200e0c:	40d709b3          	sub	s3,a4,a3
ffffffffc0200e10:	0137c7b3          	xor	a5,a5,s3
    return page+(ppn-page2ppn(page));
ffffffffc0200e14:	40e68733          	sub	a4,a3,a4
ffffffffc0200e18:	97ba                	add	a5,a5,a4
    prev->next = next;
ffffffffc0200e1a:	00993423          	sd	s1,8(s2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e1e:	01ca5593          	srli	a1,s4,0x1c
ffffffffc0200e22:	00279693          	slli	a3,a5,0x2
    next->prev = prev;
ffffffffc0200e26:	0124b023          	sd	s2,0(s1)
ffffffffc0200e2a:	97b6                	add	a5,a5,a3
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e2c:	00b88933          	add	s2,a7,a1
ffffffffc0200e30:	01093483          	ld	s1,16(s2)
ffffffffc0200e34:	078e                	slli	a5,a5,0x3
ffffffffc0200e36:	97aa                	add	a5,a5,a0
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e38:	6794                	ld	a3,8(a5)
        free_page->property+=1;
ffffffffc0200e3a:	c910                	sw	a2,16(a0)
    prev->next = next->prev = elm;
ffffffffc0200e3c:	0104b023          	sd	a6,0(s1)
        list_add(&(free_array[free_page->property]),&(free_page->page_link));
ffffffffc0200e40:	00858713          	addi	a4,a1,8
ffffffffc0200e44:	01093823          	sd	a6,16(s2)
ffffffffc0200e48:	9746                	add	a4,a4,a7
    elm->prev = prev;
ffffffffc0200e4a:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200e4c:	f104                	sd	s1,32(a0)
    while(!PageProperty(free_page_buddy)&&free_page->property<14)
ffffffffc0200e4e:	0026f713          	andi	a4,a3,2
ffffffffc0200e52:	d72d                	beqz	a4,ffffffffc0200dbc <buddy_free_pages+0xba>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200e54:	57f5                	li	a5,-3
ffffffffc0200e56:	60f3302f          	amoand.d	zero,a5,(t1)
}
ffffffffc0200e5a:	70a2                	ld	ra,40(sp)
ffffffffc0200e5c:	7402                	ld	s0,32(sp)
ffffffffc0200e5e:	64e2                	ld	s1,24(sp)
ffffffffc0200e60:	6942                	ld	s2,16(sp)
ffffffffc0200e62:	69a2                	ld	s3,8(sp)
ffffffffc0200e64:	6a02                	ld	s4,0(sp)
ffffffffc0200e66:	6145                	addi	sp,sp,48
ffffffffc0200e68:	8082                	ret
    assert(n > 0);
ffffffffc0200e6a:	00001697          	auipc	a3,0x1
ffffffffc0200e6e:	15e68693          	addi	a3,a3,350 # ffffffffc0201fc8 <commands+0x740>
ffffffffc0200e72:	00001617          	auipc	a2,0x1
ffffffffc0200e76:	03e60613          	addi	a2,a2,62 # ffffffffc0201eb0 <commands+0x628>
ffffffffc0200e7a:	08400593          	li	a1,132
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	04a50513          	addi	a0,a0,74 # ffffffffc0201ec8 <commands+0x640>
ffffffffc0200e86:	d26ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200e8a <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {   //记录当前的中断状态，并在中断开启时将其禁用
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200e8a:	100027f3          	csrr	a5,sstatus
ffffffffc0200e8e:	8b89                	andi	a5,a5,2
ffffffffc0200e90:	e799                	bnez	a5,ffffffffc0200e9e <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200e92:	00005797          	auipc	a5,0x5
ffffffffc0200e96:	6b67b783          	ld	a5,1718(a5) # ffffffffc0206548 <pmm_manager>
ffffffffc0200e9a:	6f9c                	ld	a5,24(a5)
ffffffffc0200e9c:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200e9e:	1141                	addi	sp,sp,-16
ffffffffc0200ea0:	e406                	sd	ra,8(sp)
ffffffffc0200ea2:	e022                	sd	s0,0(sp)
ffffffffc0200ea4:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200ea6:	db8ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200eaa:	00005797          	auipc	a5,0x5
ffffffffc0200eae:	69e7b783          	ld	a5,1694(a5) # ffffffffc0206548 <pmm_manager>
ffffffffc0200eb2:	6f9c                	ld	a5,24(a5)
ffffffffc0200eb4:	8522                	mv	a0,s0
ffffffffc0200eb6:	9782                	jalr	a5
ffffffffc0200eb8:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {  //根据之前保存的状态选择是否恢复中断
    if (flag) {
        intr_enable();
ffffffffc0200eba:	d9eff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200ebe:	60a2                	ld	ra,8(sp)
ffffffffc0200ec0:	8522                	mv	a0,s0
ffffffffc0200ec2:	6402                	ld	s0,0(sp)
ffffffffc0200ec4:	0141                	addi	sp,sp,16
ffffffffc0200ec6:	8082                	ret

ffffffffc0200ec8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200ec8:	100027f3          	csrr	a5,sstatus
ffffffffc0200ecc:	8b89                	andi	a5,a5,2
ffffffffc0200ece:	e799                	bnez	a5,ffffffffc0200edc <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200ed0:	00005797          	auipc	a5,0x5
ffffffffc0200ed4:	6787b783          	ld	a5,1656(a5) # ffffffffc0206548 <pmm_manager>
ffffffffc0200ed8:	739c                	ld	a5,32(a5)
ffffffffc0200eda:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200edc:	1101                	addi	sp,sp,-32
ffffffffc0200ede:	ec06                	sd	ra,24(sp)
ffffffffc0200ee0:	e822                	sd	s0,16(sp)
ffffffffc0200ee2:	e426                	sd	s1,8(sp)
ffffffffc0200ee4:	842a                	mv	s0,a0
ffffffffc0200ee6:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200ee8:	d76ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200eec:	00005797          	auipc	a5,0x5
ffffffffc0200ef0:	65c7b783          	ld	a5,1628(a5) # ffffffffc0206548 <pmm_manager>
ffffffffc0200ef4:	739c                	ld	a5,32(a5)
ffffffffc0200ef6:	85a6                	mv	a1,s1
ffffffffc0200ef8:	8522                	mv	a0,s0
ffffffffc0200efa:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200efc:	6442                	ld	s0,16(sp)
ffffffffc0200efe:	60e2                	ld	ra,24(sp)
ffffffffc0200f00:	64a2                	ld	s1,8(sp)
ffffffffc0200f02:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200f04:	d54ff06f          	j	ffffffffc0200458 <intr_enable>

ffffffffc0200f08 <pmm_init>:
    pmm_manager = &buddy_sys_pmm_manager;
ffffffffc0200f08:	00001797          	auipc	a5,0x1
ffffffffc0200f0c:	0f878793          	addi	a5,a5,248 # ffffffffc0202000 <buddy_sys_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f10:	638c                	ld	a1,0(a5)
        fppn=pa2page(mem_begin)-pages+nbase; //起始的物理页号
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200f12:	7179                	addi	sp,sp,-48
ffffffffc0200f14:	e84a                	sd	s2,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f16:	00001517          	auipc	a0,0x1
ffffffffc0200f1a:	12250513          	addi	a0,a0,290 # ffffffffc0202038 <buddy_sys_pmm_manager+0x38>
    pmm_manager = &buddy_sys_pmm_manager;
ffffffffc0200f1e:	00005917          	auipc	s2,0x5
ffffffffc0200f22:	62a90913          	addi	s2,s2,1578 # ffffffffc0206548 <pmm_manager>
void pmm_init(void) {
ffffffffc0200f26:	f406                	sd	ra,40(sp)
ffffffffc0200f28:	f022                	sd	s0,32(sp)
ffffffffc0200f2a:	ec26                	sd	s1,24(sp)
    pmm_manager = &buddy_sys_pmm_manager;
ffffffffc0200f2c:	00f93023          	sd	a5,0(s2)
void pmm_init(void) {
ffffffffc0200f30:	e44e                	sd	s3,8(sp)
ffffffffc0200f32:	e052                	sd	s4,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f34:	97eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0200f38:	00093783          	ld	a5,0(s2)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f3c:	00005417          	auipc	s0,0x5
ffffffffc0200f40:	62440413          	addi	s0,s0,1572 # ffffffffc0206560 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc0200f44:	00005497          	auipc	s1,0x5
ffffffffc0200f48:	5f448493          	addi	s1,s1,1524 # ffffffffc0206538 <npage>
    pmm_manager->init();
ffffffffc0200f4c:	679c                	ld	a5,8(a5)
ffffffffc0200f4e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f50:	57f5                	li	a5,-3
ffffffffc0200f52:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200f54:	00001517          	auipc	a0,0x1
ffffffffc0200f58:	0fc50513          	addi	a0,a0,252 # ffffffffc0202050 <buddy_sys_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f5c:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0200f5e:	954ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200f62:	46c5                	li	a3,17
ffffffffc0200f64:	06ee                	slli	a3,a3,0x1b
ffffffffc0200f66:	40100613          	li	a2,1025
ffffffffc0200f6a:	16fd                	addi	a3,a3,-1
ffffffffc0200f6c:	07e005b7          	lui	a1,0x7e00
ffffffffc0200f70:	0656                	slli	a2,a2,0x15
ffffffffc0200f72:	00001517          	auipc	a0,0x1
ffffffffc0200f76:	0f650513          	addi	a0,a0,246 # ffffffffc0202068 <buddy_sys_pmm_manager+0x68>
ffffffffc0200f7a:	938ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200f7e:	777d                	lui	a4,0xfffff
ffffffffc0200f80:	00006797          	auipc	a5,0x6
ffffffffc0200f84:	5ef78793          	addi	a5,a5,1519 # ffffffffc020756f <end+0xfff>
ffffffffc0200f88:	8ff9                	and	a5,a5,a4
ffffffffc0200f8a:	00005517          	auipc	a0,0x5
ffffffffc0200f8e:	5b650513          	addi	a0,a0,1462 # ffffffffc0206540 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0200f92:	00088737          	lui	a4,0x88
ffffffffc0200f96:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200f98:	e11c                	sd	a5,0(a0)
ffffffffc0200f9a:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200f9c:	4701                	li	a4,0
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200f9e:	4805                	li	a6,1
ffffffffc0200fa0:	fff805b7          	lui	a1,0xfff80
ffffffffc0200fa4:	a011                	j	ffffffffc0200fa8 <pmm_init+0xa0>
        SetPageReserved(pages + i);
ffffffffc0200fa6:	611c                	ld	a5,0(a0)
ffffffffc0200fa8:	97b6                	add	a5,a5,a3
ffffffffc0200faa:	07a1                	addi	a5,a5,8
ffffffffc0200fac:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200fb0:	609c                	ld	a5,0(s1)
ffffffffc0200fb2:	0705                	addi	a4,a4,1
ffffffffc0200fb4:	02868693          	addi	a3,a3,40
ffffffffc0200fb8:	00b78633          	add	a2,a5,a1
ffffffffc0200fbc:	fec765e3          	bltu	a4,a2,ffffffffc0200fa6 <pmm_init+0x9e>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200fc0:	6108                	ld	a0,0(a0)
ffffffffc0200fc2:	00279693          	slli	a3,a5,0x2
ffffffffc0200fc6:	96be                	add	a3,a3,a5
ffffffffc0200fc8:	fec00737          	lui	a4,0xfec00
ffffffffc0200fcc:	972a                	add	a4,a4,a0
ffffffffc0200fce:	068e                	slli	a3,a3,0x3
ffffffffc0200fd0:	96ba                	add	a3,a3,a4
ffffffffc0200fd2:	c0200737          	lui	a4,0xc0200
ffffffffc0200fd6:	0ce6e863          	bltu	a3,a4,ffffffffc02010a6 <pmm_init+0x19e>
ffffffffc0200fda:	6010                	ld	a2,0(s0)
    if (freemem < mem_end) {
ffffffffc0200fdc:	4745                	li	a4,17
ffffffffc0200fde:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200fe0:	8e91                	sub	a3,a3,a2
    if (freemem < mem_end) {
ffffffffc0200fe2:	04e6ec63          	bltu	a3,a4,ffffffffc020103a <pmm_init+0x132>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200fe6:	00093783          	ld	a5,0(s2)
ffffffffc0200fea:	7b9c                	ld	a5,48(a5)
ffffffffc0200fec:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200fee:	00001517          	auipc	a0,0x1
ffffffffc0200ff2:	11250513          	addi	a0,a0,274 # ffffffffc0202100 <buddy_sys_pmm_manager+0x100>
ffffffffc0200ff6:	8bcff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200ffa:	00004597          	auipc	a1,0x4
ffffffffc0200ffe:	00658593          	addi	a1,a1,6 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201002:	00005797          	auipc	a5,0x5
ffffffffc0201006:	54b7bb23          	sd	a1,1366(a5) # ffffffffc0206558 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020100a:	c02007b7          	lui	a5,0xc0200
ffffffffc020100e:	0af5e863          	bltu	a1,a5,ffffffffc02010be <pmm_init+0x1b6>
ffffffffc0201012:	6010                	ld	a2,0(s0)
}
ffffffffc0201014:	7402                	ld	s0,32(sp)
ffffffffc0201016:	70a2                	ld	ra,40(sp)
ffffffffc0201018:	64e2                	ld	s1,24(sp)
ffffffffc020101a:	6942                	ld	s2,16(sp)
ffffffffc020101c:	69a2                	ld	s3,8(sp)
ffffffffc020101e:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201020:	40c58633          	sub	a2,a1,a2
ffffffffc0201024:	00005797          	auipc	a5,0x5
ffffffffc0201028:	52c7b623          	sd	a2,1324(a5) # ffffffffc0206550 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020102c:	00001517          	auipc	a0,0x1
ffffffffc0201030:	0f450513          	addi	a0,a0,244 # ffffffffc0202120 <buddy_sys_pmm_manager+0x120>
}
ffffffffc0201034:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201036:	87cff06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020103a:	6605                	lui	a2,0x1
ffffffffc020103c:	167d                	addi	a2,a2,-1
ffffffffc020103e:	96b2                	add	a3,a3,a2
ffffffffc0201040:	767d                	lui	a2,0xfffff
ffffffffc0201042:	8ef1                	and	a3,a3,a2
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201044:	00c6da13          	srli	s4,a3,0xc
ffffffffc0201048:	04fa7363          	bgeu	s4,a5,ffffffffc020108e <pmm_init+0x186>
    pmm_manager->init_memmap(base, n);
ffffffffc020104c:	00093783          	ld	a5,0(s2)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201050:	95d2                	add	a1,a1,s4
ffffffffc0201052:	00259993          	slli	s3,a1,0x2
ffffffffc0201056:	6b9c                	ld	a5,16(a5)
ffffffffc0201058:	95ce                	add	a1,a1,s3
ffffffffc020105a:	00359993          	slli	s3,a1,0x3
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020105e:	40d705b3          	sub	a1,a4,a3
    pmm_manager->init_memmap(base, n);
ffffffffc0201062:	81b1                	srli	a1,a1,0xc
ffffffffc0201064:	954e                	add	a0,a0,s3
ffffffffc0201066:	9782                	jalr	a5
    if (PPN(pa) >= npage) {
ffffffffc0201068:	609c                	ld	a5,0(s1)
ffffffffc020106a:	02fa7263          	bgeu	s4,a5,ffffffffc020108e <pmm_init+0x186>
        fppn=pa2page(mem_begin)-pages+nbase; //起始的物理页号
ffffffffc020106e:	4039d793          	srai	a5,s3,0x3
ffffffffc0201072:	00001997          	auipc	s3,0x1
ffffffffc0201076:	3369b983          	ld	s3,822(s3) # ffffffffc02023a8 <error_string+0x38>
ffffffffc020107a:	033787b3          	mul	a5,a5,s3
ffffffffc020107e:	00080737          	lui	a4,0x80
ffffffffc0201082:	97ba                	add	a5,a5,a4
ffffffffc0201084:	00005717          	auipc	a4,0x5
ffffffffc0201088:	4af73623          	sd	a5,1196(a4) # ffffffffc0206530 <fppn>
ffffffffc020108c:	bfa9                	j	ffffffffc0200fe6 <pmm_init+0xde>
        panic("pa2page called with invalid pa");
ffffffffc020108e:	00001617          	auipc	a2,0x1
ffffffffc0201092:	04260613          	addi	a2,a2,66 # ffffffffc02020d0 <buddy_sys_pmm_manager+0xd0>
ffffffffc0201096:	06b00593          	li	a1,107
ffffffffc020109a:	00001517          	auipc	a0,0x1
ffffffffc020109e:	05650513          	addi	a0,a0,86 # ffffffffc02020f0 <buddy_sys_pmm_manager+0xf0>
ffffffffc02010a2:	b0aff0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010a6:	00001617          	auipc	a2,0x1
ffffffffc02010aa:	ff260613          	addi	a2,a2,-14 # ffffffffc0202098 <buddy_sys_pmm_manager+0x98>
ffffffffc02010ae:	07200593          	li	a1,114
ffffffffc02010b2:	00001517          	auipc	a0,0x1
ffffffffc02010b6:	00e50513          	addi	a0,a0,14 # ffffffffc02020c0 <buddy_sys_pmm_manager+0xc0>
ffffffffc02010ba:	af2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010be:	86ae                	mv	a3,a1
ffffffffc02010c0:	00001617          	auipc	a2,0x1
ffffffffc02010c4:	fd860613          	addi	a2,a2,-40 # ffffffffc0202098 <buddy_sys_pmm_manager+0x98>
ffffffffc02010c8:	08e00593          	li	a1,142
ffffffffc02010cc:	00001517          	auipc	a0,0x1
ffffffffc02010d0:	ff450513          	addi	a0,a0,-12 # ffffffffc02020c0 <buddy_sys_pmm_manager+0xc0>
ffffffffc02010d4:	ad8ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02010d8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02010d8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02010dc:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02010de:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02010e2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02010e4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02010e8:	f022                	sd	s0,32(sp)
ffffffffc02010ea:	ec26                	sd	s1,24(sp)
ffffffffc02010ec:	e84a                	sd	s2,16(sp)
ffffffffc02010ee:	f406                	sd	ra,40(sp)
ffffffffc02010f0:	e44e                	sd	s3,8(sp)
ffffffffc02010f2:	84aa                	mv	s1,a0
ffffffffc02010f4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02010f6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02010fa:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02010fc:	03067e63          	bgeu	a2,a6,ffffffffc0201138 <printnum+0x60>
ffffffffc0201100:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201102:	00805763          	blez	s0,ffffffffc0201110 <printnum+0x38>
ffffffffc0201106:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201108:	85ca                	mv	a1,s2
ffffffffc020110a:	854e                	mv	a0,s3
ffffffffc020110c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020110e:	fc65                	bnez	s0,ffffffffc0201106 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201110:	1a02                	slli	s4,s4,0x20
ffffffffc0201112:	00001797          	auipc	a5,0x1
ffffffffc0201116:	04e78793          	addi	a5,a5,78 # ffffffffc0202160 <buddy_sys_pmm_manager+0x160>
ffffffffc020111a:	020a5a13          	srli	s4,s4,0x20
ffffffffc020111e:	9a3e                	add	s4,s4,a5
}
ffffffffc0201120:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201122:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201126:	70a2                	ld	ra,40(sp)
ffffffffc0201128:	69a2                	ld	s3,8(sp)
ffffffffc020112a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020112c:	85ca                	mv	a1,s2
ffffffffc020112e:	87a6                	mv	a5,s1
}
ffffffffc0201130:	6942                	ld	s2,16(sp)
ffffffffc0201132:	64e2                	ld	s1,24(sp)
ffffffffc0201134:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201136:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201138:	03065633          	divu	a2,a2,a6
ffffffffc020113c:	8722                	mv	a4,s0
ffffffffc020113e:	f9bff0ef          	jal	ra,ffffffffc02010d8 <printnum>
ffffffffc0201142:	b7f9                	j	ffffffffc0201110 <printnum+0x38>

ffffffffc0201144 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201144:	7119                	addi	sp,sp,-128
ffffffffc0201146:	f4a6                	sd	s1,104(sp)
ffffffffc0201148:	f0ca                	sd	s2,96(sp)
ffffffffc020114a:	ecce                	sd	s3,88(sp)
ffffffffc020114c:	e8d2                	sd	s4,80(sp)
ffffffffc020114e:	e4d6                	sd	s5,72(sp)
ffffffffc0201150:	e0da                	sd	s6,64(sp)
ffffffffc0201152:	fc5e                	sd	s7,56(sp)
ffffffffc0201154:	f06a                	sd	s10,32(sp)
ffffffffc0201156:	fc86                	sd	ra,120(sp)
ffffffffc0201158:	f8a2                	sd	s0,112(sp)
ffffffffc020115a:	f862                	sd	s8,48(sp)
ffffffffc020115c:	f466                	sd	s9,40(sp)
ffffffffc020115e:	ec6e                	sd	s11,24(sp)
ffffffffc0201160:	892a                	mv	s2,a0
ffffffffc0201162:	84ae                	mv	s1,a1
ffffffffc0201164:	8d32                	mv	s10,a2
ffffffffc0201166:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201168:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020116c:	5b7d                	li	s6,-1
ffffffffc020116e:	00001a97          	auipc	s5,0x1
ffffffffc0201172:	026a8a93          	addi	s5,s5,38 # ffffffffc0202194 <buddy_sys_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201176:	00001b97          	auipc	s7,0x1
ffffffffc020117a:	1fab8b93          	addi	s7,s7,506 # ffffffffc0202370 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020117e:	000d4503          	lbu	a0,0(s10)
ffffffffc0201182:	001d0413          	addi	s0,s10,1
ffffffffc0201186:	01350a63          	beq	a0,s3,ffffffffc020119a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020118a:	c121                	beqz	a0,ffffffffc02011ca <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020118c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020118e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201190:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201192:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201196:	ff351ae3          	bne	a0,s3,ffffffffc020118a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020119a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020119e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02011a2:	4c81                	li	s9,0
ffffffffc02011a4:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02011a6:	5c7d                	li	s8,-1
ffffffffc02011a8:	5dfd                	li	s11,-1
ffffffffc02011aa:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02011ae:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011b0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02011b4:	0ff5f593          	andi	a1,a1,255
ffffffffc02011b8:	00140d13          	addi	s10,s0,1
ffffffffc02011bc:	04b56263          	bltu	a0,a1,ffffffffc0201200 <vprintfmt+0xbc>
ffffffffc02011c0:	058a                	slli	a1,a1,0x2
ffffffffc02011c2:	95d6                	add	a1,a1,s5
ffffffffc02011c4:	4194                	lw	a3,0(a1)
ffffffffc02011c6:	96d6                	add	a3,a3,s5
ffffffffc02011c8:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02011ca:	70e6                	ld	ra,120(sp)
ffffffffc02011cc:	7446                	ld	s0,112(sp)
ffffffffc02011ce:	74a6                	ld	s1,104(sp)
ffffffffc02011d0:	7906                	ld	s2,96(sp)
ffffffffc02011d2:	69e6                	ld	s3,88(sp)
ffffffffc02011d4:	6a46                	ld	s4,80(sp)
ffffffffc02011d6:	6aa6                	ld	s5,72(sp)
ffffffffc02011d8:	6b06                	ld	s6,64(sp)
ffffffffc02011da:	7be2                	ld	s7,56(sp)
ffffffffc02011dc:	7c42                	ld	s8,48(sp)
ffffffffc02011de:	7ca2                	ld	s9,40(sp)
ffffffffc02011e0:	7d02                	ld	s10,32(sp)
ffffffffc02011e2:	6de2                	ld	s11,24(sp)
ffffffffc02011e4:	6109                	addi	sp,sp,128
ffffffffc02011e6:	8082                	ret
            padc = '0';
ffffffffc02011e8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02011ea:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011ee:	846a                	mv	s0,s10
ffffffffc02011f0:	00140d13          	addi	s10,s0,1
ffffffffc02011f4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02011f8:	0ff5f593          	andi	a1,a1,255
ffffffffc02011fc:	fcb572e3          	bgeu	a0,a1,ffffffffc02011c0 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201200:	85a6                	mv	a1,s1
ffffffffc0201202:	02500513          	li	a0,37
ffffffffc0201206:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201208:	fff44783          	lbu	a5,-1(s0)
ffffffffc020120c:	8d22                	mv	s10,s0
ffffffffc020120e:	f73788e3          	beq	a5,s3,ffffffffc020117e <vprintfmt+0x3a>
ffffffffc0201212:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201216:	1d7d                	addi	s10,s10,-1
ffffffffc0201218:	ff379de3          	bne	a5,s3,ffffffffc0201212 <vprintfmt+0xce>
ffffffffc020121c:	b78d                	j	ffffffffc020117e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020121e:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201222:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201226:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201228:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020122c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201230:	02d86463          	bltu	a6,a3,ffffffffc0201258 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201234:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201238:	002c169b          	slliw	a3,s8,0x2
ffffffffc020123c:	0186873b          	addw	a4,a3,s8
ffffffffc0201240:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201244:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201246:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020124a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020124c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201250:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201254:	fed870e3          	bgeu	a6,a3,ffffffffc0201234 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201258:	f40ddce3          	bgez	s11,ffffffffc02011b0 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020125c:	8de2                	mv	s11,s8
ffffffffc020125e:	5c7d                	li	s8,-1
ffffffffc0201260:	bf81                	j	ffffffffc02011b0 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201262:	fffdc693          	not	a3,s11
ffffffffc0201266:	96fd                	srai	a3,a3,0x3f
ffffffffc0201268:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020126c:	00144603          	lbu	a2,1(s0)
ffffffffc0201270:	2d81                	sext.w	s11,s11
ffffffffc0201272:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201274:	bf35                	j	ffffffffc02011b0 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201276:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020127a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020127e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201280:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201282:	bfd9                	j	ffffffffc0201258 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201284:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201286:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020128a:	01174463          	blt	a4,a7,ffffffffc0201292 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020128e:	1a088e63          	beqz	a7,ffffffffc020144a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201292:	000a3603          	ld	a2,0(s4)
ffffffffc0201296:	46c1                	li	a3,16
ffffffffc0201298:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020129a:	2781                	sext.w	a5,a5
ffffffffc020129c:	876e                	mv	a4,s11
ffffffffc020129e:	85a6                	mv	a1,s1
ffffffffc02012a0:	854a                	mv	a0,s2
ffffffffc02012a2:	e37ff0ef          	jal	ra,ffffffffc02010d8 <printnum>
            break;
ffffffffc02012a6:	bde1                	j	ffffffffc020117e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02012a8:	000a2503          	lw	a0,0(s4)
ffffffffc02012ac:	85a6                	mv	a1,s1
ffffffffc02012ae:	0a21                	addi	s4,s4,8
ffffffffc02012b0:	9902                	jalr	s2
            break;
ffffffffc02012b2:	b5f1                	j	ffffffffc020117e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02012b4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02012b6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02012ba:	01174463          	blt	a4,a7,ffffffffc02012c2 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02012be:	18088163          	beqz	a7,ffffffffc0201440 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02012c2:	000a3603          	ld	a2,0(s4)
ffffffffc02012c6:	46a9                	li	a3,10
ffffffffc02012c8:	8a2e                	mv	s4,a1
ffffffffc02012ca:	bfc1                	j	ffffffffc020129a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012cc:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02012d0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012d2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02012d4:	bdf1                	j	ffffffffc02011b0 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02012d6:	85a6                	mv	a1,s1
ffffffffc02012d8:	02500513          	li	a0,37
ffffffffc02012dc:	9902                	jalr	s2
            break;
ffffffffc02012de:	b545                	j	ffffffffc020117e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02012e4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02012e8:	b5e1                	j	ffffffffc02011b0 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02012ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02012ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02012f0:	01174463          	blt	a4,a7,ffffffffc02012f8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02012f4:	14088163          	beqz	a7,ffffffffc0201436 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02012f8:	000a3603          	ld	a2,0(s4)
ffffffffc02012fc:	46a1                	li	a3,8
ffffffffc02012fe:	8a2e                	mv	s4,a1
ffffffffc0201300:	bf69                	j	ffffffffc020129a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201302:	03000513          	li	a0,48
ffffffffc0201306:	85a6                	mv	a1,s1
ffffffffc0201308:	e03e                	sd	a5,0(sp)
ffffffffc020130a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020130c:	85a6                	mv	a1,s1
ffffffffc020130e:	07800513          	li	a0,120
ffffffffc0201312:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201314:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201316:	6782                	ld	a5,0(sp)
ffffffffc0201318:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020131a:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020131e:	bfb5                	j	ffffffffc020129a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201320:	000a3403          	ld	s0,0(s4)
ffffffffc0201324:	008a0713          	addi	a4,s4,8
ffffffffc0201328:	e03a                	sd	a4,0(sp)
ffffffffc020132a:	14040263          	beqz	s0,ffffffffc020146e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020132e:	0fb05763          	blez	s11,ffffffffc020141c <vprintfmt+0x2d8>
ffffffffc0201332:	02d00693          	li	a3,45
ffffffffc0201336:	0cd79163          	bne	a5,a3,ffffffffc02013f8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020133a:	00044783          	lbu	a5,0(s0)
ffffffffc020133e:	0007851b          	sext.w	a0,a5
ffffffffc0201342:	cf85                	beqz	a5,ffffffffc020137a <vprintfmt+0x236>
ffffffffc0201344:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201348:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020134c:	000c4563          	bltz	s8,ffffffffc0201356 <vprintfmt+0x212>
ffffffffc0201350:	3c7d                	addiw	s8,s8,-1
ffffffffc0201352:	036c0263          	beq	s8,s6,ffffffffc0201376 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201356:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201358:	0e0c8e63          	beqz	s9,ffffffffc0201454 <vprintfmt+0x310>
ffffffffc020135c:	3781                	addiw	a5,a5,-32
ffffffffc020135e:	0ef47b63          	bgeu	s0,a5,ffffffffc0201454 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201362:	03f00513          	li	a0,63
ffffffffc0201366:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201368:	000a4783          	lbu	a5,0(s4)
ffffffffc020136c:	3dfd                	addiw	s11,s11,-1
ffffffffc020136e:	0a05                	addi	s4,s4,1
ffffffffc0201370:	0007851b          	sext.w	a0,a5
ffffffffc0201374:	ffe1                	bnez	a5,ffffffffc020134c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201376:	01b05963          	blez	s11,ffffffffc0201388 <vprintfmt+0x244>
ffffffffc020137a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020137c:	85a6                	mv	a1,s1
ffffffffc020137e:	02000513          	li	a0,32
ffffffffc0201382:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201384:	fe0d9be3          	bnez	s11,ffffffffc020137a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201388:	6a02                	ld	s4,0(sp)
ffffffffc020138a:	bbd5                	j	ffffffffc020117e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020138c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020138e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201392:	01174463          	blt	a4,a7,ffffffffc020139a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201396:	08088d63          	beqz	a7,ffffffffc0201430 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020139a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020139e:	0a044d63          	bltz	s0,ffffffffc0201458 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02013a2:	8622                	mv	a2,s0
ffffffffc02013a4:	8a66                	mv	s4,s9
ffffffffc02013a6:	46a9                	li	a3,10
ffffffffc02013a8:	bdcd                	j	ffffffffc020129a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02013aa:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013ae:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02013b0:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02013b2:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02013b6:	8fb5                	xor	a5,a5,a3
ffffffffc02013b8:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013bc:	02d74163          	blt	a4,a3,ffffffffc02013de <vprintfmt+0x29a>
ffffffffc02013c0:	00369793          	slli	a5,a3,0x3
ffffffffc02013c4:	97de                	add	a5,a5,s7
ffffffffc02013c6:	639c                	ld	a5,0(a5)
ffffffffc02013c8:	cb99                	beqz	a5,ffffffffc02013de <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02013ca:	86be                	mv	a3,a5
ffffffffc02013cc:	00001617          	auipc	a2,0x1
ffffffffc02013d0:	dc460613          	addi	a2,a2,-572 # ffffffffc0202190 <buddy_sys_pmm_manager+0x190>
ffffffffc02013d4:	85a6                	mv	a1,s1
ffffffffc02013d6:	854a                	mv	a0,s2
ffffffffc02013d8:	0ce000ef          	jal	ra,ffffffffc02014a6 <printfmt>
ffffffffc02013dc:	b34d                	j	ffffffffc020117e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02013de:	00001617          	auipc	a2,0x1
ffffffffc02013e2:	da260613          	addi	a2,a2,-606 # ffffffffc0202180 <buddy_sys_pmm_manager+0x180>
ffffffffc02013e6:	85a6                	mv	a1,s1
ffffffffc02013e8:	854a                	mv	a0,s2
ffffffffc02013ea:	0bc000ef          	jal	ra,ffffffffc02014a6 <printfmt>
ffffffffc02013ee:	bb41                	j	ffffffffc020117e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02013f0:	00001417          	auipc	s0,0x1
ffffffffc02013f4:	d8840413          	addi	s0,s0,-632 # ffffffffc0202178 <buddy_sys_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02013f8:	85e2                	mv	a1,s8
ffffffffc02013fa:	8522                	mv	a0,s0
ffffffffc02013fc:	e43e                	sd	a5,8(sp)
ffffffffc02013fe:	1cc000ef          	jal	ra,ffffffffc02015ca <strnlen>
ffffffffc0201402:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201406:	01b05b63          	blez	s11,ffffffffc020141c <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020140a:	67a2                	ld	a5,8(sp)
ffffffffc020140c:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201410:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201412:	85a6                	mv	a1,s1
ffffffffc0201414:	8552                	mv	a0,s4
ffffffffc0201416:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201418:	fe0d9ce3          	bnez	s11,ffffffffc0201410 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020141c:	00044783          	lbu	a5,0(s0)
ffffffffc0201420:	00140a13          	addi	s4,s0,1
ffffffffc0201424:	0007851b          	sext.w	a0,a5
ffffffffc0201428:	d3a5                	beqz	a5,ffffffffc0201388 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020142a:	05e00413          	li	s0,94
ffffffffc020142e:	bf39                	j	ffffffffc020134c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201430:	000a2403          	lw	s0,0(s4)
ffffffffc0201434:	b7ad                	j	ffffffffc020139e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201436:	000a6603          	lwu	a2,0(s4)
ffffffffc020143a:	46a1                	li	a3,8
ffffffffc020143c:	8a2e                	mv	s4,a1
ffffffffc020143e:	bdb1                	j	ffffffffc020129a <vprintfmt+0x156>
ffffffffc0201440:	000a6603          	lwu	a2,0(s4)
ffffffffc0201444:	46a9                	li	a3,10
ffffffffc0201446:	8a2e                	mv	s4,a1
ffffffffc0201448:	bd89                	j	ffffffffc020129a <vprintfmt+0x156>
ffffffffc020144a:	000a6603          	lwu	a2,0(s4)
ffffffffc020144e:	46c1                	li	a3,16
ffffffffc0201450:	8a2e                	mv	s4,a1
ffffffffc0201452:	b5a1                	j	ffffffffc020129a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201454:	9902                	jalr	s2
ffffffffc0201456:	bf09                	j	ffffffffc0201368 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201458:	85a6                	mv	a1,s1
ffffffffc020145a:	02d00513          	li	a0,45
ffffffffc020145e:	e03e                	sd	a5,0(sp)
ffffffffc0201460:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201462:	6782                	ld	a5,0(sp)
ffffffffc0201464:	8a66                	mv	s4,s9
ffffffffc0201466:	40800633          	neg	a2,s0
ffffffffc020146a:	46a9                	li	a3,10
ffffffffc020146c:	b53d                	j	ffffffffc020129a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020146e:	03b05163          	blez	s11,ffffffffc0201490 <vprintfmt+0x34c>
ffffffffc0201472:	02d00693          	li	a3,45
ffffffffc0201476:	f6d79de3          	bne	a5,a3,ffffffffc02013f0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020147a:	00001417          	auipc	s0,0x1
ffffffffc020147e:	cfe40413          	addi	s0,s0,-770 # ffffffffc0202178 <buddy_sys_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201482:	02800793          	li	a5,40
ffffffffc0201486:	02800513          	li	a0,40
ffffffffc020148a:	00140a13          	addi	s4,s0,1
ffffffffc020148e:	bd6d                	j	ffffffffc0201348 <vprintfmt+0x204>
ffffffffc0201490:	00001a17          	auipc	s4,0x1
ffffffffc0201494:	ce9a0a13          	addi	s4,s4,-791 # ffffffffc0202179 <buddy_sys_pmm_manager+0x179>
ffffffffc0201498:	02800513          	li	a0,40
ffffffffc020149c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014a0:	05e00413          	li	s0,94
ffffffffc02014a4:	b565                	j	ffffffffc020134c <vprintfmt+0x208>

ffffffffc02014a6 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014a6:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02014a8:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014ac:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02014ae:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014b0:	ec06                	sd	ra,24(sp)
ffffffffc02014b2:	f83a                	sd	a4,48(sp)
ffffffffc02014b4:	fc3e                	sd	a5,56(sp)
ffffffffc02014b6:	e0c2                	sd	a6,64(sp)
ffffffffc02014b8:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02014ba:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02014bc:	c89ff0ef          	jal	ra,ffffffffc0201144 <vprintfmt>
}
ffffffffc02014c0:	60e2                	ld	ra,24(sp)
ffffffffc02014c2:	6161                	addi	sp,sp,80
ffffffffc02014c4:	8082                	ret

ffffffffc02014c6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02014c6:	715d                	addi	sp,sp,-80
ffffffffc02014c8:	e486                	sd	ra,72(sp)
ffffffffc02014ca:	e0a6                	sd	s1,64(sp)
ffffffffc02014cc:	fc4a                	sd	s2,56(sp)
ffffffffc02014ce:	f84e                	sd	s3,48(sp)
ffffffffc02014d0:	f452                	sd	s4,40(sp)
ffffffffc02014d2:	f056                	sd	s5,32(sp)
ffffffffc02014d4:	ec5a                	sd	s6,24(sp)
ffffffffc02014d6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02014d8:	c901                	beqz	a0,ffffffffc02014e8 <readline+0x22>
ffffffffc02014da:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02014dc:	00001517          	auipc	a0,0x1
ffffffffc02014e0:	cb450513          	addi	a0,a0,-844 # ffffffffc0202190 <buddy_sys_pmm_manager+0x190>
ffffffffc02014e4:	bcffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc02014e8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02014ea:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02014ec:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02014ee:	4aa9                	li	s5,10
ffffffffc02014f0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02014f2:	00005b97          	auipc	s7,0x5
ffffffffc02014f6:	c2eb8b93          	addi	s7,s7,-978 # ffffffffc0206120 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02014fa:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02014fe:	c2dfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201502:	00054a63          	bltz	a0,ffffffffc0201516 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201506:	00a95a63          	bge	s2,a0,ffffffffc020151a <readline+0x54>
ffffffffc020150a:	029a5263          	bge	s4,s1,ffffffffc020152e <readline+0x68>
        c = getchar();
ffffffffc020150e:	c1dfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201512:	fe055ae3          	bgez	a0,ffffffffc0201506 <readline+0x40>
            return NULL;
ffffffffc0201516:	4501                	li	a0,0
ffffffffc0201518:	a091                	j	ffffffffc020155c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020151a:	03351463          	bne	a0,s3,ffffffffc0201542 <readline+0x7c>
ffffffffc020151e:	e8a9                	bnez	s1,ffffffffc0201570 <readline+0xaa>
        c = getchar();
ffffffffc0201520:	c0bfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201524:	fe0549e3          	bltz	a0,ffffffffc0201516 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201528:	fea959e3          	bge	s2,a0,ffffffffc020151a <readline+0x54>
ffffffffc020152c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020152e:	e42a                	sd	a0,8(sp)
ffffffffc0201530:	bb9fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc0201534:	6522                	ld	a0,8(sp)
ffffffffc0201536:	009b87b3          	add	a5,s7,s1
ffffffffc020153a:	2485                	addiw	s1,s1,1
ffffffffc020153c:	00a78023          	sb	a0,0(a5)
ffffffffc0201540:	bf7d                	j	ffffffffc02014fe <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201542:	01550463          	beq	a0,s5,ffffffffc020154a <readline+0x84>
ffffffffc0201546:	fb651ce3          	bne	a0,s6,ffffffffc02014fe <readline+0x38>
            cputchar(c);
ffffffffc020154a:	b9ffe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc020154e:	00005517          	auipc	a0,0x5
ffffffffc0201552:	bd250513          	addi	a0,a0,-1070 # ffffffffc0206120 <buf>
ffffffffc0201556:	94aa                	add	s1,s1,a0
ffffffffc0201558:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020155c:	60a6                	ld	ra,72(sp)
ffffffffc020155e:	6486                	ld	s1,64(sp)
ffffffffc0201560:	7962                	ld	s2,56(sp)
ffffffffc0201562:	79c2                	ld	s3,48(sp)
ffffffffc0201564:	7a22                	ld	s4,40(sp)
ffffffffc0201566:	7a82                	ld	s5,32(sp)
ffffffffc0201568:	6b62                	ld	s6,24(sp)
ffffffffc020156a:	6bc2                	ld	s7,16(sp)
ffffffffc020156c:	6161                	addi	sp,sp,80
ffffffffc020156e:	8082                	ret
            cputchar(c);
ffffffffc0201570:	4521                	li	a0,8
ffffffffc0201572:	b77fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc0201576:	34fd                	addiw	s1,s1,-1
ffffffffc0201578:	b759                	j	ffffffffc02014fe <readline+0x38>

ffffffffc020157a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020157a:	4781                	li	a5,0
ffffffffc020157c:	00005717          	auipc	a4,0x5
ffffffffc0201580:	a8c73703          	ld	a4,-1396(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201584:	88ba                	mv	a7,a4
ffffffffc0201586:	852a                	mv	a0,a0
ffffffffc0201588:	85be                	mv	a1,a5
ffffffffc020158a:	863e                	mv	a2,a5
ffffffffc020158c:	00000073          	ecall
ffffffffc0201590:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201592:	8082                	ret

ffffffffc0201594 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201594:	4781                	li	a5,0
ffffffffc0201596:	00005717          	auipc	a4,0x5
ffffffffc020159a:	fd273703          	ld	a4,-46(a4) # ffffffffc0206568 <SBI_SET_TIMER>
ffffffffc020159e:	88ba                	mv	a7,a4
ffffffffc02015a0:	852a                	mv	a0,a0
ffffffffc02015a2:	85be                	mv	a1,a5
ffffffffc02015a4:	863e                	mv	a2,a5
ffffffffc02015a6:	00000073          	ecall
ffffffffc02015aa:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc02015ac:	8082                	ret

ffffffffc02015ae <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc02015ae:	4501                	li	a0,0
ffffffffc02015b0:	00005797          	auipc	a5,0x5
ffffffffc02015b4:	a507b783          	ld	a5,-1456(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc02015b8:	88be                	mv	a7,a5
ffffffffc02015ba:	852a                	mv	a0,a0
ffffffffc02015bc:	85aa                	mv	a1,a0
ffffffffc02015be:	862a                	mv	a2,a0
ffffffffc02015c0:	00000073          	ecall
ffffffffc02015c4:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc02015c6:	2501                	sext.w	a0,a0
ffffffffc02015c8:	8082                	ret

ffffffffc02015ca <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02015ca:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015cc:	e589                	bnez	a1,ffffffffc02015d6 <strnlen+0xc>
ffffffffc02015ce:	a811                	j	ffffffffc02015e2 <strnlen+0x18>
        cnt ++;
ffffffffc02015d0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02015d2:	00f58863          	beq	a1,a5,ffffffffc02015e2 <strnlen+0x18>
ffffffffc02015d6:	00f50733          	add	a4,a0,a5
ffffffffc02015da:	00074703          	lbu	a4,0(a4)
ffffffffc02015de:	fb6d                	bnez	a4,ffffffffc02015d0 <strnlen+0x6>
ffffffffc02015e0:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02015e2:	852e                	mv	a0,a1
ffffffffc02015e4:	8082                	ret

ffffffffc02015e6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015e6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015ea:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015ee:	cb89                	beqz	a5,ffffffffc0201600 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02015f0:	0505                	addi	a0,a0,1
ffffffffc02015f2:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02015f4:	fee789e3          	beq	a5,a4,ffffffffc02015e6 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02015f8:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02015fc:	9d19                	subw	a0,a0,a4
ffffffffc02015fe:	8082                	ret
ffffffffc0201600:	4501                	li	a0,0
ffffffffc0201602:	bfed                	j	ffffffffc02015fc <strcmp+0x16>

ffffffffc0201604 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201604:	00054783          	lbu	a5,0(a0)
ffffffffc0201608:	c799                	beqz	a5,ffffffffc0201616 <strchr+0x12>
        if (*s == c) {
ffffffffc020160a:	00f58763          	beq	a1,a5,ffffffffc0201618 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020160e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201612:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201614:	fbfd                	bnez	a5,ffffffffc020160a <strchr+0x6>
    }
    return NULL;
ffffffffc0201616:	4501                	li	a0,0
}
ffffffffc0201618:	8082                	ret

ffffffffc020161a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020161a:	ca01                	beqz	a2,ffffffffc020162a <memset+0x10>
ffffffffc020161c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020161e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201620:	0785                	addi	a5,a5,1
ffffffffc0201622:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201626:	fec79de3          	bne	a5,a2,ffffffffc0201620 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020162a:	8082                	ret
