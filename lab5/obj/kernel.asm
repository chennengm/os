
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	000a1517          	auipc	a0,0xa1
ffffffffc020003a:	f7a50513          	addi	a0,a0,-134 # ffffffffc02a0fb0 <edata>
ffffffffc020003e:	000ac617          	auipc	a2,0xac
ffffffffc0200042:	50260613          	addi	a2,a2,1282 # ffffffffc02ac540 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	36e060ef          	jal	ra,ffffffffc02063bc <memset>
    cons_init();                // init the console
ffffffffc0200052:	58e000ef          	jal	ra,ffffffffc02005e0 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00006597          	auipc	a1,0x6
ffffffffc020005a:	7a258593          	addi	a1,a1,1954 # ffffffffc02067f8 <etext+0x2>
ffffffffc020005e:	00006517          	auipc	a0,0x6
ffffffffc0200062:	7ba50513          	addi	a0,a0,1978 # ffffffffc0206818 <etext+0x22>
ffffffffc0200066:	06a000ef          	jal	ra,ffffffffc02000d0 <cprintf>

    print_kerninfo();
ffffffffc020006a:	25a000ef          	jal	ra,ffffffffc02002c4 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006e:	61e010ef          	jal	ra,ffffffffc020168c <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc0200072:	5e2000ef          	jal	ra,ffffffffc0200654 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200076:	5ec000ef          	jal	ra,ffffffffc0200662 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020007a:	39d020ef          	jal	ra,ffffffffc0202c16 <vmm_init>
    proc_init();                // init process table
ffffffffc020007e:	749050ef          	jal	ra,ffffffffc0205fc6 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc0200082:	4b0000ef          	jal	ra,ffffffffc0200532 <ide_init>
    swap_init();                // init swap
ffffffffc0200086:	007030ef          	jal	ra,ffffffffc020388c <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020008a:	500000ef          	jal	ra,ffffffffc020058a <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008e:	5c8000ef          	jal	ra,ffffffffc0200656 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc0200092:	080060ef          	jal	ra,ffffffffc0206112 <cpu_idle>

ffffffffc0200096 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200096:	1141                	addi	sp,sp,-16
ffffffffc0200098:	e022                	sd	s0,0(sp)
ffffffffc020009a:	e406                	sd	ra,8(sp)
ffffffffc020009c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020009e:	544000ef          	jal	ra,ffffffffc02005e2 <cons_putc>
    (*cnt) ++;
ffffffffc02000a2:	401c                	lw	a5,0(s0)
}
ffffffffc02000a4:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000a6:	2785                	addiw	a5,a5,1
ffffffffc02000a8:	c01c                	sw	a5,0(s0)
}
ffffffffc02000aa:	6402                	ld	s0,0(sp)
ffffffffc02000ac:	0141                	addi	sp,sp,16
ffffffffc02000ae:	8082                	ret

ffffffffc02000b0 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b0:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	86ae                	mv	a3,a1
ffffffffc02000b4:	862a                	mv	a2,a0
ffffffffc02000b6:	006c                	addi	a1,sp,12
ffffffffc02000b8:	00000517          	auipc	a0,0x0
ffffffffc02000bc:	fde50513          	addi	a0,a0,-34 # ffffffffc0200096 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c0:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000c2:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c4:	38e060ef          	jal	ra,ffffffffc0206452 <vprintfmt>
    return cnt;
}
ffffffffc02000c8:	60e2                	ld	ra,24(sp)
ffffffffc02000ca:	4532                	lw	a0,12(sp)
ffffffffc02000cc:	6105                	addi	sp,sp,32
ffffffffc02000ce:	8082                	ret

ffffffffc02000d0 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000d2:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	f42e                	sd	a1,40(sp)
ffffffffc02000d8:	f832                	sd	a2,48(sp)
ffffffffc02000da:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	862a                	mv	a2,a0
ffffffffc02000de:	004c                	addi	a1,sp,4
ffffffffc02000e0:	00000517          	auipc	a0,0x0
ffffffffc02000e4:	fb650513          	addi	a0,a0,-74 # ffffffffc0200096 <cputch>
ffffffffc02000e8:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000ea:	ec06                	sd	ra,24(sp)
ffffffffc02000ec:	e0ba                	sd	a4,64(sp)
ffffffffc02000ee:	e4be                	sd	a5,72(sp)
ffffffffc02000f0:	e8c2                	sd	a6,80(sp)
ffffffffc02000f2:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000f4:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000f6:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f8:	35a060ef          	jal	ra,ffffffffc0206452 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000fc:	60e2                	ld	ra,24(sp)
ffffffffc02000fe:	4512                	lw	a0,4(sp)
ffffffffc0200100:	6125                	addi	sp,sp,96
ffffffffc0200102:	8082                	ret

ffffffffc0200104 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200104:	4de0006f          	j	ffffffffc02005e2 <cons_putc>

ffffffffc0200108 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200108:	1101                	addi	sp,sp,-32
ffffffffc020010a:	e822                	sd	s0,16(sp)
ffffffffc020010c:	ec06                	sd	ra,24(sp)
ffffffffc020010e:	e426                	sd	s1,8(sp)
ffffffffc0200110:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200112:	00054503          	lbu	a0,0(a0)
ffffffffc0200116:	c51d                	beqz	a0,ffffffffc0200144 <cputs+0x3c>
ffffffffc0200118:	0405                	addi	s0,s0,1
ffffffffc020011a:	4485                	li	s1,1
ffffffffc020011c:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020011e:	4c4000ef          	jal	ra,ffffffffc02005e2 <cons_putc>
    (*cnt) ++;
ffffffffc0200122:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	0405                	addi	s0,s0,1
ffffffffc0200128:	fff44503          	lbu	a0,-1(s0)
ffffffffc020012c:	f96d                	bnez	a0,ffffffffc020011e <cputs+0x16>
ffffffffc020012e:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200132:	4529                	li	a0,10
ffffffffc0200134:	4ae000ef          	jal	ra,ffffffffc02005e2 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200138:	8522                	mv	a0,s0
ffffffffc020013a:	60e2                	ld	ra,24(sp)
ffffffffc020013c:	6442                	ld	s0,16(sp)
ffffffffc020013e:	64a2                	ld	s1,8(sp)
ffffffffc0200140:	6105                	addi	sp,sp,32
ffffffffc0200142:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200144:	4405                	li	s0,1
ffffffffc0200146:	b7f5                	j	ffffffffc0200132 <cputs+0x2a>

ffffffffc0200148 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200148:	1141                	addi	sp,sp,-16
ffffffffc020014a:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020014c:	4cc000ef          	jal	ra,ffffffffc0200618 <cons_getc>
ffffffffc0200150:	dd75                	beqz	a0,ffffffffc020014c <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200152:	60a2                	ld	ra,8(sp)
ffffffffc0200154:	0141                	addi	sp,sp,16
ffffffffc0200156:	8082                	ret

ffffffffc0200158 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200158:	715d                	addi	sp,sp,-80
ffffffffc020015a:	e486                	sd	ra,72(sp)
ffffffffc020015c:	e0a2                	sd	s0,64(sp)
ffffffffc020015e:	fc26                	sd	s1,56(sp)
ffffffffc0200160:	f84a                	sd	s2,48(sp)
ffffffffc0200162:	f44e                	sd	s3,40(sp)
ffffffffc0200164:	f052                	sd	s4,32(sp)
ffffffffc0200166:	ec56                	sd	s5,24(sp)
ffffffffc0200168:	e85a                	sd	s6,16(sp)
ffffffffc020016a:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc020016c:	c901                	beqz	a0,ffffffffc020017c <readline+0x24>
        cprintf("%s", prompt);
ffffffffc020016e:	85aa                	mv	a1,a0
ffffffffc0200170:	00006517          	auipc	a0,0x6
ffffffffc0200174:	6b050513          	addi	a0,a0,1712 # ffffffffc0206820 <etext+0x2a>
ffffffffc0200178:	f59ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
readline(const char *prompt) {
ffffffffc020017c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020017e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0200180:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200182:	4aa9                	li	s5,10
ffffffffc0200184:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200186:	000a1b97          	auipc	s7,0xa1
ffffffffc020018a:	e2ab8b93          	addi	s7,s7,-470 # ffffffffc02a0fb0 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020018e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0200192:	fb7ff0ef          	jal	ra,ffffffffc0200148 <getchar>
ffffffffc0200196:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0200198:	00054b63          	bltz	a0,ffffffffc02001ae <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020019c:	00a95b63          	ble	a0,s2,ffffffffc02001b2 <readline+0x5a>
ffffffffc02001a0:	029a5463          	ble	s1,s4,ffffffffc02001c8 <readline+0x70>
        c = getchar();
ffffffffc02001a4:	fa5ff0ef          	jal	ra,ffffffffc0200148 <getchar>
ffffffffc02001a8:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02001aa:	fe0559e3          	bgez	a0,ffffffffc020019c <readline+0x44>
            return NULL;
ffffffffc02001ae:	4501                	li	a0,0
ffffffffc02001b0:	a099                	j	ffffffffc02001f6 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02001b2:	03341463          	bne	s0,s3,ffffffffc02001da <readline+0x82>
ffffffffc02001b6:	e8b9                	bnez	s1,ffffffffc020020c <readline+0xb4>
        c = getchar();
ffffffffc02001b8:	f91ff0ef          	jal	ra,ffffffffc0200148 <getchar>
ffffffffc02001bc:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02001be:	fe0548e3          	bltz	a0,ffffffffc02001ae <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001c2:	fea958e3          	ble	a0,s2,ffffffffc02001b2 <readline+0x5a>
ffffffffc02001c6:	4481                	li	s1,0
            cputchar(c);
ffffffffc02001c8:	8522                	mv	a0,s0
ffffffffc02001ca:	f3bff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            buf[i ++] = c;
ffffffffc02001ce:	009b87b3          	add	a5,s7,s1
ffffffffc02001d2:	00878023          	sb	s0,0(a5)
ffffffffc02001d6:	2485                	addiw	s1,s1,1
ffffffffc02001d8:	bf6d                	j	ffffffffc0200192 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc02001da:	01540463          	beq	s0,s5,ffffffffc02001e2 <readline+0x8a>
ffffffffc02001de:	fb641ae3          	bne	s0,s6,ffffffffc0200192 <readline+0x3a>
            cputchar(c);
ffffffffc02001e2:	8522                	mv	a0,s0
ffffffffc02001e4:	f21ff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            buf[i] = '\0';
ffffffffc02001e8:	000a1517          	auipc	a0,0xa1
ffffffffc02001ec:	dc850513          	addi	a0,a0,-568 # ffffffffc02a0fb0 <edata>
ffffffffc02001f0:	94aa                	add	s1,s1,a0
ffffffffc02001f2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001f6:	60a6                	ld	ra,72(sp)
ffffffffc02001f8:	6406                	ld	s0,64(sp)
ffffffffc02001fa:	74e2                	ld	s1,56(sp)
ffffffffc02001fc:	7942                	ld	s2,48(sp)
ffffffffc02001fe:	79a2                	ld	s3,40(sp)
ffffffffc0200200:	7a02                	ld	s4,32(sp)
ffffffffc0200202:	6ae2                	ld	s5,24(sp)
ffffffffc0200204:	6b42                	ld	s6,16(sp)
ffffffffc0200206:	6ba2                	ld	s7,8(sp)
ffffffffc0200208:	6161                	addi	sp,sp,80
ffffffffc020020a:	8082                	ret
            cputchar(c);
ffffffffc020020c:	4521                	li	a0,8
ffffffffc020020e:	ef7ff0ef          	jal	ra,ffffffffc0200104 <cputchar>
            i --;
ffffffffc0200212:	34fd                	addiw	s1,s1,-1
ffffffffc0200214:	bfbd                	j	ffffffffc0200192 <readline+0x3a>

ffffffffc0200216 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200216:	000ac317          	auipc	t1,0xac
ffffffffc020021a:	19a30313          	addi	t1,t1,410 # ffffffffc02ac3b0 <is_panic>
ffffffffc020021e:	00033303          	ld	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200222:	715d                	addi	sp,sp,-80
ffffffffc0200224:	ec06                	sd	ra,24(sp)
ffffffffc0200226:	e822                	sd	s0,16(sp)
ffffffffc0200228:	f436                	sd	a3,40(sp)
ffffffffc020022a:	f83a                	sd	a4,48(sp)
ffffffffc020022c:	fc3e                	sd	a5,56(sp)
ffffffffc020022e:	e0c2                	sd	a6,64(sp)
ffffffffc0200230:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200232:	02031c63          	bnez	t1,ffffffffc020026a <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200236:	4785                	li	a5,1
ffffffffc0200238:	8432                	mv	s0,a2
ffffffffc020023a:	000ac717          	auipc	a4,0xac
ffffffffc020023e:	16f73b23          	sd	a5,374(a4) # ffffffffc02ac3b0 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200242:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc0200244:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200246:	85aa                	mv	a1,a0
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	5e050513          	addi	a0,a0,1504 # ffffffffc0206828 <etext+0x32>
    va_start(ap, fmt);
ffffffffc0200250:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200252:	e7fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200256:	65a2                	ld	a1,8(sp)
ffffffffc0200258:	8522                	mv	a0,s0
ffffffffc020025a:	e57ff0ef          	jal	ra,ffffffffc02000b0 <vcprintf>
    cprintf("\n");
ffffffffc020025e:	00007517          	auipc	a0,0x7
ffffffffc0200262:	41a50513          	addi	a0,a0,1050 # ffffffffc0207678 <commands+0xd10>
ffffffffc0200266:	e6bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020026a:	4501                	li	a0,0
ffffffffc020026c:	4581                	li	a1,0
ffffffffc020026e:	4601                	li	a2,0
ffffffffc0200270:	48a1                	li	a7,8
ffffffffc0200272:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc0200276:	3e6000ef          	jal	ra,ffffffffc020065c <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020027a:	4501                	li	a0,0
ffffffffc020027c:	174000ef          	jal	ra,ffffffffc02003f0 <kmonitor>
ffffffffc0200280:	bfed                	j	ffffffffc020027a <__panic+0x64>

ffffffffc0200282 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200282:	715d                	addi	sp,sp,-80
ffffffffc0200284:	e822                	sd	s0,16(sp)
ffffffffc0200286:	fc3e                	sd	a5,56(sp)
ffffffffc0200288:	8432                	mv	s0,a2
    va_list ap;
    va_start(ap, fmt);
ffffffffc020028a:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020028c:	862e                	mv	a2,a1
ffffffffc020028e:	85aa                	mv	a1,a0
ffffffffc0200290:	00006517          	auipc	a0,0x6
ffffffffc0200294:	5b850513          	addi	a0,a0,1464 # ffffffffc0206848 <etext+0x52>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200298:	ec06                	sd	ra,24(sp)
ffffffffc020029a:	f436                	sd	a3,40(sp)
ffffffffc020029c:	f83a                	sd	a4,48(sp)
ffffffffc020029e:	e0c2                	sd	a6,64(sp)
ffffffffc02002a0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02002a2:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02002a4:	e2dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02002a8:	65a2                	ld	a1,8(sp)
ffffffffc02002aa:	8522                	mv	a0,s0
ffffffffc02002ac:	e05ff0ef          	jal	ra,ffffffffc02000b0 <vcprintf>
    cprintf("\n");
ffffffffc02002b0:	00007517          	auipc	a0,0x7
ffffffffc02002b4:	3c850513          	addi	a0,a0,968 # ffffffffc0207678 <commands+0xd10>
ffffffffc02002b8:	e19ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    va_end(ap);
}
ffffffffc02002bc:	60e2                	ld	ra,24(sp)
ffffffffc02002be:	6442                	ld	s0,16(sp)
ffffffffc02002c0:	6161                	addi	sp,sp,80
ffffffffc02002c2:	8082                	ret

ffffffffc02002c4 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02002c4:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02002c6:	00006517          	auipc	a0,0x6
ffffffffc02002ca:	5d250513          	addi	a0,a0,1490 # ffffffffc0206898 <etext+0xa2>
void print_kerninfo(void) {
ffffffffc02002ce:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02002d0:	e01ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02002d4:	00000597          	auipc	a1,0x0
ffffffffc02002d8:	d6258593          	addi	a1,a1,-670 # ffffffffc0200036 <kern_init>
ffffffffc02002dc:	00006517          	auipc	a0,0x6
ffffffffc02002e0:	5dc50513          	addi	a0,a0,1500 # ffffffffc02068b8 <etext+0xc2>
ffffffffc02002e4:	dedff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02002e8:	00006597          	auipc	a1,0x6
ffffffffc02002ec:	50e58593          	addi	a1,a1,1294 # ffffffffc02067f6 <etext>
ffffffffc02002f0:	00006517          	auipc	a0,0x6
ffffffffc02002f4:	5e850513          	addi	a0,a0,1512 # ffffffffc02068d8 <etext+0xe2>
ffffffffc02002f8:	dd9ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc02002fc:	000a1597          	auipc	a1,0xa1
ffffffffc0200300:	cb458593          	addi	a1,a1,-844 # ffffffffc02a0fb0 <edata>
ffffffffc0200304:	00006517          	auipc	a0,0x6
ffffffffc0200308:	5f450513          	addi	a0,a0,1524 # ffffffffc02068f8 <etext+0x102>
ffffffffc020030c:	dc5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200310:	000ac597          	auipc	a1,0xac
ffffffffc0200314:	23058593          	addi	a1,a1,560 # ffffffffc02ac540 <end>
ffffffffc0200318:	00006517          	auipc	a0,0x6
ffffffffc020031c:	60050513          	addi	a0,a0,1536 # ffffffffc0206918 <etext+0x122>
ffffffffc0200320:	db1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200324:	000ac597          	auipc	a1,0xac
ffffffffc0200328:	61b58593          	addi	a1,a1,1563 # ffffffffc02ac93f <end+0x3ff>
ffffffffc020032c:	00000797          	auipc	a5,0x0
ffffffffc0200330:	d0a78793          	addi	a5,a5,-758 # ffffffffc0200036 <kern_init>
ffffffffc0200334:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200338:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020033c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020033e:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200342:	95be                	add	a1,a1,a5
ffffffffc0200344:	85a9                	srai	a1,a1,0xa
ffffffffc0200346:	00006517          	auipc	a0,0x6
ffffffffc020034a:	5f250513          	addi	a0,a0,1522 # ffffffffc0206938 <etext+0x142>
}
ffffffffc020034e:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200350:	d81ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc0200354 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200354:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200356:	00006617          	auipc	a2,0x6
ffffffffc020035a:	51260613          	addi	a2,a2,1298 # ffffffffc0206868 <etext+0x72>
ffffffffc020035e:	04d00593          	li	a1,77
ffffffffc0200362:	00006517          	auipc	a0,0x6
ffffffffc0200366:	51e50513          	addi	a0,a0,1310 # ffffffffc0206880 <etext+0x8a>
void print_stackframe(void) {
ffffffffc020036a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020036c:	eabff0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0200370 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200370:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200372:	00006617          	auipc	a2,0x6
ffffffffc0200376:	6d660613          	addi	a2,a2,1750 # ffffffffc0206a48 <commands+0xe0>
ffffffffc020037a:	00006597          	auipc	a1,0x6
ffffffffc020037e:	6ee58593          	addi	a1,a1,1774 # ffffffffc0206a68 <commands+0x100>
ffffffffc0200382:	00006517          	auipc	a0,0x6
ffffffffc0200386:	6ee50513          	addi	a0,a0,1774 # ffffffffc0206a70 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020038a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020038c:	d45ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0200390:	00006617          	auipc	a2,0x6
ffffffffc0200394:	6f060613          	addi	a2,a2,1776 # ffffffffc0206a80 <commands+0x118>
ffffffffc0200398:	00006597          	auipc	a1,0x6
ffffffffc020039c:	71058593          	addi	a1,a1,1808 # ffffffffc0206aa8 <commands+0x140>
ffffffffc02003a0:	00006517          	auipc	a0,0x6
ffffffffc02003a4:	6d050513          	addi	a0,a0,1744 # ffffffffc0206a70 <commands+0x108>
ffffffffc02003a8:	d29ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc02003ac:	00006617          	auipc	a2,0x6
ffffffffc02003b0:	70c60613          	addi	a2,a2,1804 # ffffffffc0206ab8 <commands+0x150>
ffffffffc02003b4:	00006597          	auipc	a1,0x6
ffffffffc02003b8:	72458593          	addi	a1,a1,1828 # ffffffffc0206ad8 <commands+0x170>
ffffffffc02003bc:	00006517          	auipc	a0,0x6
ffffffffc02003c0:	6b450513          	addi	a0,a0,1716 # ffffffffc0206a70 <commands+0x108>
ffffffffc02003c4:	d0dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    }
    return 0;
}
ffffffffc02003c8:	60a2                	ld	ra,8(sp)
ffffffffc02003ca:	4501                	li	a0,0
ffffffffc02003cc:	0141                	addi	sp,sp,16
ffffffffc02003ce:	8082                	ret

ffffffffc02003d0 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003d0:	1141                	addi	sp,sp,-16
ffffffffc02003d2:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02003d4:	ef1ff0ef          	jal	ra,ffffffffc02002c4 <print_kerninfo>
    return 0;
}
ffffffffc02003d8:	60a2                	ld	ra,8(sp)
ffffffffc02003da:	4501                	li	a0,0
ffffffffc02003dc:	0141                	addi	sp,sp,16
ffffffffc02003de:	8082                	ret

ffffffffc02003e0 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003e0:	1141                	addi	sp,sp,-16
ffffffffc02003e2:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02003e4:	f71ff0ef          	jal	ra,ffffffffc0200354 <print_stackframe>
    return 0;
}
ffffffffc02003e8:	60a2                	ld	ra,8(sp)
ffffffffc02003ea:	4501                	li	a0,0
ffffffffc02003ec:	0141                	addi	sp,sp,16
ffffffffc02003ee:	8082                	ret

ffffffffc02003f0 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02003f0:	7115                	addi	sp,sp,-224
ffffffffc02003f2:	e962                	sd	s8,144(sp)
ffffffffc02003f4:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02003f6:	00006517          	auipc	a0,0x6
ffffffffc02003fa:	5ba50513          	addi	a0,a0,1466 # ffffffffc02069b0 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc02003fe:	ed86                	sd	ra,216(sp)
ffffffffc0200400:	e9a2                	sd	s0,208(sp)
ffffffffc0200402:	e5a6                	sd	s1,200(sp)
ffffffffc0200404:	e1ca                	sd	s2,192(sp)
ffffffffc0200406:	fd4e                	sd	s3,184(sp)
ffffffffc0200408:	f952                	sd	s4,176(sp)
ffffffffc020040a:	f556                	sd	s5,168(sp)
ffffffffc020040c:	f15a                	sd	s6,160(sp)
ffffffffc020040e:	ed5e                	sd	s7,152(sp)
ffffffffc0200410:	e566                	sd	s9,136(sp)
ffffffffc0200412:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200414:	cbdff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200418:	00006517          	auipc	a0,0x6
ffffffffc020041c:	5c050513          	addi	a0,a0,1472 # ffffffffc02069d8 <commands+0x70>
ffffffffc0200420:	cb1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    if (tf != NULL) {
ffffffffc0200424:	000c0563          	beqz	s8,ffffffffc020042e <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200428:	8562                	mv	a0,s8
ffffffffc020042a:	420000ef          	jal	ra,ffffffffc020084a <print_trapframe>
ffffffffc020042e:	00006c97          	auipc	s9,0x6
ffffffffc0200432:	53ac8c93          	addi	s9,s9,1338 # ffffffffc0206968 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200436:	00006997          	auipc	s3,0x6
ffffffffc020043a:	5ca98993          	addi	s3,s3,1482 # ffffffffc0206a00 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043e:	00006917          	auipc	s2,0x6
ffffffffc0200442:	5ca90913          	addi	s2,s2,1482 # ffffffffc0206a08 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200446:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200448:	00006b17          	auipc	s6,0x6
ffffffffc020044c:	5c8b0b13          	addi	s6,s6,1480 # ffffffffc0206a10 <commands+0xa8>
    if (argc == 0) {
ffffffffc0200450:	00006a97          	auipc	s5,0x6
ffffffffc0200454:	618a8a93          	addi	s5,s5,1560 # ffffffffc0206a68 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200458:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020045a:	854e                	mv	a0,s3
ffffffffc020045c:	cfdff0ef          	jal	ra,ffffffffc0200158 <readline>
ffffffffc0200460:	842a                	mv	s0,a0
ffffffffc0200462:	dd65                	beqz	a0,ffffffffc020045a <kmonitor+0x6a>
ffffffffc0200464:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200468:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020046a:	c999                	beqz	a1,ffffffffc0200480 <kmonitor+0x90>
ffffffffc020046c:	854a                	mv	a0,s2
ffffffffc020046e:	731050ef          	jal	ra,ffffffffc020639e <strchr>
ffffffffc0200472:	c925                	beqz	a0,ffffffffc02004e2 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc0200474:	00144583          	lbu	a1,1(s0)
ffffffffc0200478:	00040023          	sb	zero,0(s0)
ffffffffc020047c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020047e:	f5fd                	bnez	a1,ffffffffc020046c <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc0200480:	dce9                	beqz	s1,ffffffffc020045a <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200482:	6582                	ld	a1,0(sp)
ffffffffc0200484:	00006d17          	auipc	s10,0x6
ffffffffc0200488:	4e4d0d13          	addi	s10,s10,1252 # ffffffffc0206968 <commands>
    if (argc == 0) {
ffffffffc020048c:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020048e:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200490:	0d61                	addi	s10,s10,24
ffffffffc0200492:	6e3050ef          	jal	ra,ffffffffc0206374 <strcmp>
ffffffffc0200496:	c919                	beqz	a0,ffffffffc02004ac <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200498:	2405                	addiw	s0,s0,1
ffffffffc020049a:	09740463          	beq	s0,s7,ffffffffc0200522 <kmonitor+0x132>
ffffffffc020049e:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02004a2:	6582                	ld	a1,0(sp)
ffffffffc02004a4:	0d61                	addi	s10,s10,24
ffffffffc02004a6:	6cf050ef          	jal	ra,ffffffffc0206374 <strcmp>
ffffffffc02004aa:	f57d                	bnez	a0,ffffffffc0200498 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02004ac:	00141793          	slli	a5,s0,0x1
ffffffffc02004b0:	97a2                	add	a5,a5,s0
ffffffffc02004b2:	078e                	slli	a5,a5,0x3
ffffffffc02004b4:	97e6                	add	a5,a5,s9
ffffffffc02004b6:	6b9c                	ld	a5,16(a5)
ffffffffc02004b8:	8662                	mv	a2,s8
ffffffffc02004ba:	002c                	addi	a1,sp,8
ffffffffc02004bc:	fff4851b          	addiw	a0,s1,-1
ffffffffc02004c0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02004c2:	f8055ce3          	bgez	a0,ffffffffc020045a <kmonitor+0x6a>
}
ffffffffc02004c6:	60ee                	ld	ra,216(sp)
ffffffffc02004c8:	644e                	ld	s0,208(sp)
ffffffffc02004ca:	64ae                	ld	s1,200(sp)
ffffffffc02004cc:	690e                	ld	s2,192(sp)
ffffffffc02004ce:	79ea                	ld	s3,184(sp)
ffffffffc02004d0:	7a4a                	ld	s4,176(sp)
ffffffffc02004d2:	7aaa                	ld	s5,168(sp)
ffffffffc02004d4:	7b0a                	ld	s6,160(sp)
ffffffffc02004d6:	6bea                	ld	s7,152(sp)
ffffffffc02004d8:	6c4a                	ld	s8,144(sp)
ffffffffc02004da:	6caa                	ld	s9,136(sp)
ffffffffc02004dc:	6d0a                	ld	s10,128(sp)
ffffffffc02004de:	612d                	addi	sp,sp,224
ffffffffc02004e0:	8082                	ret
        if (*buf == '\0') {
ffffffffc02004e2:	00044783          	lbu	a5,0(s0)
ffffffffc02004e6:	dfc9                	beqz	a5,ffffffffc0200480 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc02004e8:	03448863          	beq	s1,s4,ffffffffc0200518 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc02004ec:	00349793          	slli	a5,s1,0x3
ffffffffc02004f0:	0118                	addi	a4,sp,128
ffffffffc02004f2:	97ba                	add	a5,a5,a4
ffffffffc02004f4:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004f8:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02004fc:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004fe:	e591                	bnez	a1,ffffffffc020050a <kmonitor+0x11a>
ffffffffc0200500:	b749                	j	ffffffffc0200482 <kmonitor+0x92>
            buf ++;
ffffffffc0200502:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200504:	00044583          	lbu	a1,0(s0)
ffffffffc0200508:	ddad                	beqz	a1,ffffffffc0200482 <kmonitor+0x92>
ffffffffc020050a:	854a                	mv	a0,s2
ffffffffc020050c:	693050ef          	jal	ra,ffffffffc020639e <strchr>
ffffffffc0200510:	d96d                	beqz	a0,ffffffffc0200502 <kmonitor+0x112>
ffffffffc0200512:	00044583          	lbu	a1,0(s0)
ffffffffc0200516:	bf91                	j	ffffffffc020046a <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200518:	45c1                	li	a1,16
ffffffffc020051a:	855a                	mv	a0,s6
ffffffffc020051c:	bb5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0200520:	b7f1                	j	ffffffffc02004ec <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200522:	6582                	ld	a1,0(sp)
ffffffffc0200524:	00006517          	auipc	a0,0x6
ffffffffc0200528:	50c50513          	addi	a0,a0,1292 # ffffffffc0206a30 <commands+0xc8>
ffffffffc020052c:	ba5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    return 0;
ffffffffc0200530:	b72d                	j	ffffffffc020045a <kmonitor+0x6a>

ffffffffc0200532 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200532:	8082                	ret

ffffffffc0200534 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200534:	00253513          	sltiu	a0,a0,2
ffffffffc0200538:	8082                	ret

ffffffffc020053a <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc020053a:	03800513          	li	a0,56
ffffffffc020053e:	8082                	ret

ffffffffc0200540 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200540:	000a1797          	auipc	a5,0xa1
ffffffffc0200544:	e7078793          	addi	a5,a5,-400 # ffffffffc02a13b0 <ide>
ffffffffc0200548:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc020054c:	1141                	addi	sp,sp,-16
ffffffffc020054e:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200550:	95be                	add	a1,a1,a5
ffffffffc0200552:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc0200556:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200558:	677050ef          	jal	ra,ffffffffc02063ce <memcpy>
    return 0;
}
ffffffffc020055c:	60a2                	ld	ra,8(sp)
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	0141                	addi	sp,sp,16
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc0200564:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200566:	0095979b          	slliw	a5,a1,0x9
ffffffffc020056a:	000a1517          	auipc	a0,0xa1
ffffffffc020056e:	e4650513          	addi	a0,a0,-442 # ffffffffc02a13b0 <ide>
                   size_t nsecs) {
ffffffffc0200572:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200574:	00969613          	slli	a2,a3,0x9
ffffffffc0200578:	85ba                	mv	a1,a4
ffffffffc020057a:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc020057c:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020057e:	651050ef          	jal	ra,ffffffffc02063ce <memcpy>
    return 0;
}
ffffffffc0200582:	60a2                	ld	ra,8(sp)
ffffffffc0200584:	4501                	li	a0,0
ffffffffc0200586:	0141                	addi	sp,sp,16
ffffffffc0200588:	8082                	ret

ffffffffc020058a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020058a:	67e1                	lui	a5,0x18
ffffffffc020058c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xdc30>
ffffffffc0200590:	000ac717          	auipc	a4,0xac
ffffffffc0200594:	e2f73423          	sd	a5,-472(a4) # ffffffffc02ac3b8 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200598:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020059c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020059e:	953e                	add	a0,a0,a5
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4881                	li	a7,0
ffffffffc02005a4:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02005a8:	02000793          	li	a5,32
ffffffffc02005ac:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02005b0:	00006517          	auipc	a0,0x6
ffffffffc02005b4:	53850513          	addi	a0,a0,1336 # ffffffffc0206ae8 <commands+0x180>
    ticks = 0;
ffffffffc02005b8:	000ac797          	auipc	a5,0xac
ffffffffc02005bc:	e407bc23          	sd	zero,-424(a5) # ffffffffc02ac410 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02005c0:	b11ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc02005c4 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02005c4:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02005c8:	000ac797          	auipc	a5,0xac
ffffffffc02005cc:	df078793          	addi	a5,a5,-528 # ffffffffc02ac3b8 <timebase>
ffffffffc02005d0:	639c                	ld	a5,0(a5)
ffffffffc02005d2:	4581                	li	a1,0
ffffffffc02005d4:	4601                	li	a2,0
ffffffffc02005d6:	953e                	add	a0,a0,a5
ffffffffc02005d8:	4881                	li	a7,0
ffffffffc02005da:	00000073          	ecall
ffffffffc02005de:	8082                	ret

ffffffffc02005e0 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005e2:	100027f3          	csrr	a5,sstatus
ffffffffc02005e6:	8b89                	andi	a5,a5,2
ffffffffc02005e8:	0ff57513          	andi	a0,a0,255
ffffffffc02005ec:	e799                	bnez	a5,ffffffffc02005fa <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02005ee:	4581                	li	a1,0
ffffffffc02005f0:	4601                	li	a2,0
ffffffffc02005f2:	4885                	li	a7,1
ffffffffc02005f4:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005f8:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005fa:	1101                	addi	sp,sp,-32
ffffffffc02005fc:	ec06                	sd	ra,24(sp)
ffffffffc02005fe:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200600:	05c000ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc0200604:	6522                	ld	a0,8(sp)
ffffffffc0200606:	4581                	li	a1,0
ffffffffc0200608:	4601                	li	a2,0
ffffffffc020060a:	4885                	li	a7,1
ffffffffc020060c:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200610:	60e2                	ld	ra,24(sp)
ffffffffc0200612:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200614:	0420006f          	j	ffffffffc0200656 <intr_enable>

ffffffffc0200618 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200618:	100027f3          	csrr	a5,sstatus
ffffffffc020061c:	8b89                	andi	a5,a5,2
ffffffffc020061e:	eb89                	bnez	a5,ffffffffc0200630 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200620:	4501                	li	a0,0
ffffffffc0200622:	4581                	li	a1,0
ffffffffc0200624:	4601                	li	a2,0
ffffffffc0200626:	4889                	li	a7,2
ffffffffc0200628:	00000073          	ecall
ffffffffc020062c:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020062e:	8082                	ret
int cons_getc(void) {
ffffffffc0200630:	1101                	addi	sp,sp,-32
ffffffffc0200632:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200634:	028000ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc0200638:	4501                	li	a0,0
ffffffffc020063a:	4581                	li	a1,0
ffffffffc020063c:	4601                	li	a2,0
ffffffffc020063e:	4889                	li	a7,2
ffffffffc0200640:	00000073          	ecall
ffffffffc0200644:	2501                	sext.w	a0,a0
ffffffffc0200646:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200648:	00e000ef          	jal	ra,ffffffffc0200656 <intr_enable>
}
ffffffffc020064c:	60e2                	ld	ra,24(sp)
ffffffffc020064e:	6522                	ld	a0,8(sp)
ffffffffc0200650:	6105                	addi	sp,sp,32
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200654:	8082                	ret

ffffffffc0200656 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200656:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020065a:	8082                	ret

ffffffffc020065c <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020065c:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200660:	8082                	ret

ffffffffc0200662 <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200662:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200666:	00000797          	auipc	a5,0x0
ffffffffc020066a:	6b278793          	addi	a5,a5,1714 # ffffffffc0200d18 <__alltraps>
ffffffffc020066e:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200672:	000407b7          	lui	a5,0x40
ffffffffc0200676:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020067a:	8082                	ret

ffffffffc020067c <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020067e:	1141                	addi	sp,sp,-16
ffffffffc0200680:	e022                	sd	s0,0(sp)
ffffffffc0200682:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200684:	00006517          	auipc	a0,0x6
ffffffffc0200688:	7c450513          	addi	a0,a0,1988 # ffffffffc0206e48 <commands+0x4e0>
void print_regs(struct pushregs* gpr) {
ffffffffc020068c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020068e:	a43ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200692:	640c                	ld	a1,8(s0)
ffffffffc0200694:	00006517          	auipc	a0,0x6
ffffffffc0200698:	7cc50513          	addi	a0,a0,1996 # ffffffffc0206e60 <commands+0x4f8>
ffffffffc020069c:	a35ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02006a0:	680c                	ld	a1,16(s0)
ffffffffc02006a2:	00006517          	auipc	a0,0x6
ffffffffc02006a6:	7d650513          	addi	a0,a0,2006 # ffffffffc0206e78 <commands+0x510>
ffffffffc02006aa:	a27ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02006ae:	6c0c                	ld	a1,24(s0)
ffffffffc02006b0:	00006517          	auipc	a0,0x6
ffffffffc02006b4:	7e050513          	addi	a0,a0,2016 # ffffffffc0206e90 <commands+0x528>
ffffffffc02006b8:	a19ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006bc:	700c                	ld	a1,32(s0)
ffffffffc02006be:	00006517          	auipc	a0,0x6
ffffffffc02006c2:	7ea50513          	addi	a0,a0,2026 # ffffffffc0206ea8 <commands+0x540>
ffffffffc02006c6:	a0bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006ca:	740c                	ld	a1,40(s0)
ffffffffc02006cc:	00006517          	auipc	a0,0x6
ffffffffc02006d0:	7f450513          	addi	a0,a0,2036 # ffffffffc0206ec0 <commands+0x558>
ffffffffc02006d4:	9fdff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006d8:	780c                	ld	a1,48(s0)
ffffffffc02006da:	00006517          	auipc	a0,0x6
ffffffffc02006de:	7fe50513          	addi	a0,a0,2046 # ffffffffc0206ed8 <commands+0x570>
ffffffffc02006e2:	9efff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006e6:	7c0c                	ld	a1,56(s0)
ffffffffc02006e8:	00007517          	auipc	a0,0x7
ffffffffc02006ec:	80850513          	addi	a0,a0,-2040 # ffffffffc0206ef0 <commands+0x588>
ffffffffc02006f0:	9e1ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006f4:	602c                	ld	a1,64(s0)
ffffffffc02006f6:	00007517          	auipc	a0,0x7
ffffffffc02006fa:	81250513          	addi	a0,a0,-2030 # ffffffffc0206f08 <commands+0x5a0>
ffffffffc02006fe:	9d3ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200702:	642c                	ld	a1,72(s0)
ffffffffc0200704:	00007517          	auipc	a0,0x7
ffffffffc0200708:	81c50513          	addi	a0,a0,-2020 # ffffffffc0206f20 <commands+0x5b8>
ffffffffc020070c:	9c5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200710:	682c                	ld	a1,80(s0)
ffffffffc0200712:	00007517          	auipc	a0,0x7
ffffffffc0200716:	82650513          	addi	a0,a0,-2010 # ffffffffc0206f38 <commands+0x5d0>
ffffffffc020071a:	9b7ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020071e:	6c2c                	ld	a1,88(s0)
ffffffffc0200720:	00007517          	auipc	a0,0x7
ffffffffc0200724:	83050513          	addi	a0,a0,-2000 # ffffffffc0206f50 <commands+0x5e8>
ffffffffc0200728:	9a9ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020072c:	702c                	ld	a1,96(s0)
ffffffffc020072e:	00007517          	auipc	a0,0x7
ffffffffc0200732:	83a50513          	addi	a0,a0,-1990 # ffffffffc0206f68 <commands+0x600>
ffffffffc0200736:	99bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020073a:	742c                	ld	a1,104(s0)
ffffffffc020073c:	00007517          	auipc	a0,0x7
ffffffffc0200740:	84450513          	addi	a0,a0,-1980 # ffffffffc0206f80 <commands+0x618>
ffffffffc0200744:	98dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200748:	782c                	ld	a1,112(s0)
ffffffffc020074a:	00007517          	auipc	a0,0x7
ffffffffc020074e:	84e50513          	addi	a0,a0,-1970 # ffffffffc0206f98 <commands+0x630>
ffffffffc0200752:	97fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200756:	7c2c                	ld	a1,120(s0)
ffffffffc0200758:	00007517          	auipc	a0,0x7
ffffffffc020075c:	85850513          	addi	a0,a0,-1960 # ffffffffc0206fb0 <commands+0x648>
ffffffffc0200760:	971ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200764:	604c                	ld	a1,128(s0)
ffffffffc0200766:	00007517          	auipc	a0,0x7
ffffffffc020076a:	86250513          	addi	a0,a0,-1950 # ffffffffc0206fc8 <commands+0x660>
ffffffffc020076e:	963ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200772:	644c                	ld	a1,136(s0)
ffffffffc0200774:	00007517          	auipc	a0,0x7
ffffffffc0200778:	86c50513          	addi	a0,a0,-1940 # ffffffffc0206fe0 <commands+0x678>
ffffffffc020077c:	955ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200780:	684c                	ld	a1,144(s0)
ffffffffc0200782:	00007517          	auipc	a0,0x7
ffffffffc0200786:	87650513          	addi	a0,a0,-1930 # ffffffffc0206ff8 <commands+0x690>
ffffffffc020078a:	947ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020078e:	6c4c                	ld	a1,152(s0)
ffffffffc0200790:	00007517          	auipc	a0,0x7
ffffffffc0200794:	88050513          	addi	a0,a0,-1920 # ffffffffc0207010 <commands+0x6a8>
ffffffffc0200798:	939ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020079c:	704c                	ld	a1,160(s0)
ffffffffc020079e:	00007517          	auipc	a0,0x7
ffffffffc02007a2:	88a50513          	addi	a0,a0,-1910 # ffffffffc0207028 <commands+0x6c0>
ffffffffc02007a6:	92bff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02007aa:	744c                	ld	a1,168(s0)
ffffffffc02007ac:	00007517          	auipc	a0,0x7
ffffffffc02007b0:	89450513          	addi	a0,a0,-1900 # ffffffffc0207040 <commands+0x6d8>
ffffffffc02007b4:	91dff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007b8:	784c                	ld	a1,176(s0)
ffffffffc02007ba:	00007517          	auipc	a0,0x7
ffffffffc02007be:	89e50513          	addi	a0,a0,-1890 # ffffffffc0207058 <commands+0x6f0>
ffffffffc02007c2:	90fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007c6:	7c4c                	ld	a1,184(s0)
ffffffffc02007c8:	00007517          	auipc	a0,0x7
ffffffffc02007cc:	8a850513          	addi	a0,a0,-1880 # ffffffffc0207070 <commands+0x708>
ffffffffc02007d0:	901ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007d4:	606c                	ld	a1,192(s0)
ffffffffc02007d6:	00007517          	auipc	a0,0x7
ffffffffc02007da:	8b250513          	addi	a0,a0,-1870 # ffffffffc0207088 <commands+0x720>
ffffffffc02007de:	8f3ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007e2:	646c                	ld	a1,200(s0)
ffffffffc02007e4:	00007517          	auipc	a0,0x7
ffffffffc02007e8:	8bc50513          	addi	a0,a0,-1860 # ffffffffc02070a0 <commands+0x738>
ffffffffc02007ec:	8e5ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007f0:	686c                	ld	a1,208(s0)
ffffffffc02007f2:	00007517          	auipc	a0,0x7
ffffffffc02007f6:	8c650513          	addi	a0,a0,-1850 # ffffffffc02070b8 <commands+0x750>
ffffffffc02007fa:	8d7ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200800:	00007517          	auipc	a0,0x7
ffffffffc0200804:	8d050513          	addi	a0,a0,-1840 # ffffffffc02070d0 <commands+0x768>
ffffffffc0200808:	8c9ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020080c:	706c                	ld	a1,224(s0)
ffffffffc020080e:	00007517          	auipc	a0,0x7
ffffffffc0200812:	8da50513          	addi	a0,a0,-1830 # ffffffffc02070e8 <commands+0x780>
ffffffffc0200816:	8bbff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020081a:	746c                	ld	a1,232(s0)
ffffffffc020081c:	00007517          	auipc	a0,0x7
ffffffffc0200820:	8e450513          	addi	a0,a0,-1820 # ffffffffc0207100 <commands+0x798>
ffffffffc0200824:	8adff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200828:	786c                	ld	a1,240(s0)
ffffffffc020082a:	00007517          	auipc	a0,0x7
ffffffffc020082e:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0207118 <commands+0x7b0>
ffffffffc0200832:	89fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200836:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200838:	6402                	ld	s0,0(sp)
ffffffffc020083a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020083c:	00007517          	auipc	a0,0x7
ffffffffc0200840:	8f450513          	addi	a0,a0,-1804 # ffffffffc0207130 <commands+0x7c8>
}
ffffffffc0200844:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200846:	88bff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc020084a <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc020084a:	1141                	addi	sp,sp,-16
ffffffffc020084c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020084e:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc0200850:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200852:	00007517          	auipc	a0,0x7
ffffffffc0200856:	8f650513          	addi	a0,a0,-1802 # ffffffffc0207148 <commands+0x7e0>
print_trapframe(struct trapframe *tf) {
ffffffffc020085a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020085c:	875ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200860:	8522                	mv	a0,s0
ffffffffc0200862:	e1bff0ef          	jal	ra,ffffffffc020067c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200866:	10043583          	ld	a1,256(s0)
ffffffffc020086a:	00007517          	auipc	a0,0x7
ffffffffc020086e:	8f650513          	addi	a0,a0,-1802 # ffffffffc0207160 <commands+0x7f8>
ffffffffc0200872:	85fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200876:	10843583          	ld	a1,264(s0)
ffffffffc020087a:	00007517          	auipc	a0,0x7
ffffffffc020087e:	8fe50513          	addi	a0,a0,-1794 # ffffffffc0207178 <commands+0x810>
ffffffffc0200882:	84fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200886:	11043583          	ld	a1,272(s0)
ffffffffc020088a:	00007517          	auipc	a0,0x7
ffffffffc020088e:	90650513          	addi	a0,a0,-1786 # ffffffffc0207190 <commands+0x828>
ffffffffc0200892:	83fff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200896:	11843583          	ld	a1,280(s0)
}
ffffffffc020089a:	6402                	ld	s0,0(sp)
ffffffffc020089c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020089e:	00007517          	auipc	a0,0x7
ffffffffc02008a2:	90250513          	addi	a0,a0,-1790 # ffffffffc02071a0 <commands+0x838>
}
ffffffffc02008a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02008a8:	829ff06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc02008ac <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ac:	1101                	addi	sp,sp,-32
ffffffffc02008ae:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008b0:	000ac497          	auipc	s1,0xac
ffffffffc02008b4:	b9848493          	addi	s1,s1,-1128 # ffffffffc02ac448 <check_mm_struct>
ffffffffc02008b8:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ba:	e822                	sd	s0,16(sp)
ffffffffc02008bc:	ec06                	sd	ra,24(sp)
ffffffffc02008be:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008c0:	cbbd                	beqz	a5,ffffffffc0200936 <pgfault_handler+0x8a>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008c2:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008c6:	11053583          	ld	a1,272(a0)
ffffffffc02008ca:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ce:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008d2:	cba1                	beqz	a5,ffffffffc0200922 <pgfault_handler+0x76>
ffffffffc02008d4:	11843703          	ld	a4,280(s0)
ffffffffc02008d8:	47bd                	li	a5,15
ffffffffc02008da:	05700693          	li	a3,87
ffffffffc02008de:	00f70463          	beq	a4,a5,ffffffffc02008e6 <pgfault_handler+0x3a>
ffffffffc02008e2:	05200693          	li	a3,82
ffffffffc02008e6:	00006517          	auipc	a0,0x6
ffffffffc02008ea:	4e250513          	addi	a0,a0,1250 # ffffffffc0206dc8 <commands+0x460>
ffffffffc02008ee:	fe2ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008f2:	6088                	ld	a0,0(s1)
ffffffffc02008f4:	c129                	beqz	a0,ffffffffc0200936 <pgfault_handler+0x8a>
        assert(current == idleproc);
ffffffffc02008f6:	000ac797          	auipc	a5,0xac
ffffffffc02008fa:	afa78793          	addi	a5,a5,-1286 # ffffffffc02ac3f0 <current>
ffffffffc02008fe:	6398                	ld	a4,0(a5)
ffffffffc0200900:	000ac797          	auipc	a5,0xac
ffffffffc0200904:	af878793          	addi	a5,a5,-1288 # ffffffffc02ac3f8 <idleproc>
ffffffffc0200908:	639c                	ld	a5,0(a5)
ffffffffc020090a:	04f71763          	bne	a4,a5,ffffffffc0200958 <pgfault_handler+0xac>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020090e:	11043603          	ld	a2,272(s0)
ffffffffc0200912:	11843583          	ld	a1,280(s0)
}
ffffffffc0200916:	6442                	ld	s0,16(sp)
ffffffffc0200918:	60e2                	ld	ra,24(sp)
ffffffffc020091a:	64a2                	ld	s1,8(sp)
ffffffffc020091c:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020091e:	03f0206f          	j	ffffffffc020315c <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200922:	11843703          	ld	a4,280(s0)
ffffffffc0200926:	47bd                	li	a5,15
ffffffffc0200928:	05500613          	li	a2,85
ffffffffc020092c:	05700693          	li	a3,87
ffffffffc0200930:	faf719e3          	bne	a4,a5,ffffffffc02008e2 <pgfault_handler+0x36>
ffffffffc0200934:	bf4d                	j	ffffffffc02008e6 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc0200936:	000ac797          	auipc	a5,0xac
ffffffffc020093a:	aba78793          	addi	a5,a5,-1350 # ffffffffc02ac3f0 <current>
ffffffffc020093e:	639c                	ld	a5,0(a5)
ffffffffc0200940:	cf85                	beqz	a5,ffffffffc0200978 <pgfault_handler+0xcc>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200942:	11043603          	ld	a2,272(s0)
ffffffffc0200946:	11843583          	ld	a1,280(s0)
}
ffffffffc020094a:	6442                	ld	s0,16(sp)
ffffffffc020094c:	60e2                	ld	ra,24(sp)
ffffffffc020094e:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200950:	7788                	ld	a0,40(a5)
}
ffffffffc0200952:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200954:	0090206f          	j	ffffffffc020315c <do_pgfault>
        assert(current == idleproc);
ffffffffc0200958:	00006697          	auipc	a3,0x6
ffffffffc020095c:	49068693          	addi	a3,a3,1168 # ffffffffc0206de8 <commands+0x480>
ffffffffc0200960:	00006617          	auipc	a2,0x6
ffffffffc0200964:	4a060613          	addi	a2,a2,1184 # ffffffffc0206e00 <commands+0x498>
ffffffffc0200968:	06b00593          	li	a1,107
ffffffffc020096c:	00006517          	auipc	a0,0x6
ffffffffc0200970:	4ac50513          	addi	a0,a0,1196 # ffffffffc0206e18 <commands+0x4b0>
ffffffffc0200974:	8a3ff0ef          	jal	ra,ffffffffc0200216 <__panic>
            print_trapframe(tf);
ffffffffc0200978:	8522                	mv	a0,s0
ffffffffc020097a:	ed1ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020097e:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200982:	11043583          	ld	a1,272(s0)
ffffffffc0200986:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020098a:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020098e:	e399                	bnez	a5,ffffffffc0200994 <pgfault_handler+0xe8>
ffffffffc0200990:	05500613          	li	a2,85
ffffffffc0200994:	11843703          	ld	a4,280(s0)
ffffffffc0200998:	47bd                	li	a5,15
ffffffffc020099a:	02f70663          	beq	a4,a5,ffffffffc02009c6 <pgfault_handler+0x11a>
ffffffffc020099e:	05200693          	li	a3,82
ffffffffc02009a2:	00006517          	auipc	a0,0x6
ffffffffc02009a6:	42650513          	addi	a0,a0,1062 # ffffffffc0206dc8 <commands+0x460>
ffffffffc02009aa:	f26ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            panic("unhandled page fault.\n");
ffffffffc02009ae:	00006617          	auipc	a2,0x6
ffffffffc02009b2:	48260613          	addi	a2,a2,1154 # ffffffffc0206e30 <commands+0x4c8>
ffffffffc02009b6:	07200593          	li	a1,114
ffffffffc02009ba:	00006517          	auipc	a0,0x6
ffffffffc02009be:	45e50513          	addi	a0,a0,1118 # ffffffffc0206e18 <commands+0x4b0>
ffffffffc02009c2:	855ff0ef          	jal	ra,ffffffffc0200216 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009c6:	05700693          	li	a3,87
ffffffffc02009ca:	bfe1                	j	ffffffffc02009a2 <pgfault_handler+0xf6>

ffffffffc02009cc <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009cc:	11853783          	ld	a5,280(a0)
ffffffffc02009d0:	577d                	li	a4,-1
ffffffffc02009d2:	8305                	srli	a4,a4,0x1
ffffffffc02009d4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02009d6:	472d                	li	a4,11
ffffffffc02009d8:	08f76763          	bltu	a4,a5,ffffffffc0200a66 <interrupt_handler+0x9a>
ffffffffc02009dc:	00006717          	auipc	a4,0x6
ffffffffc02009e0:	12870713          	addi	a4,a4,296 # ffffffffc0206b04 <commands+0x19c>
ffffffffc02009e4:	078a                	slli	a5,a5,0x2
ffffffffc02009e6:	97ba                	add	a5,a5,a4
ffffffffc02009e8:	439c                	lw	a5,0(a5)
ffffffffc02009ea:	97ba                	add	a5,a5,a4
ffffffffc02009ec:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009ee:	00006517          	auipc	a0,0x6
ffffffffc02009f2:	39a50513          	addi	a0,a0,922 # ffffffffc0206d88 <commands+0x420>
ffffffffc02009f6:	edaff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009fa:	00006517          	auipc	a0,0x6
ffffffffc02009fe:	36e50513          	addi	a0,a0,878 # ffffffffc0206d68 <commands+0x400>
ffffffffc0200a02:	eceff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a06:	00006517          	auipc	a0,0x6
ffffffffc0200a0a:	32250513          	addi	a0,a0,802 # ffffffffc0206d28 <commands+0x3c0>
ffffffffc0200a0e:	ec2ff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	33650513          	addi	a0,a0,822 # ffffffffc0206d48 <commands+0x3e0>
ffffffffc0200a1a:	eb6ff06f          	j	ffffffffc02000d0 <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a1e:	00006517          	auipc	a0,0x6
ffffffffc0200a22:	38a50513          	addi	a0,a0,906 # ffffffffc0206da8 <commands+0x440>
ffffffffc0200a26:	eaaff06f          	j	ffffffffc02000d0 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a2a:	1141                	addi	sp,sp,-16
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200a2e:	b97ff0ef          	jal	ra,ffffffffc02005c4 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a32:	000ac797          	auipc	a5,0xac
ffffffffc0200a36:	9de78793          	addi	a5,a5,-1570 # ffffffffc02ac410 <ticks>
ffffffffc0200a3a:	639c                	ld	a5,0(a5)
ffffffffc0200a3c:	06400713          	li	a4,100
ffffffffc0200a40:	0785                	addi	a5,a5,1
ffffffffc0200a42:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a46:	000ac697          	auipc	a3,0xac
ffffffffc0200a4a:	9cf6b523          	sd	a5,-1590(a3) # ffffffffc02ac410 <ticks>
ffffffffc0200a4e:	eb09                	bnez	a4,ffffffffc0200a60 <interrupt_handler+0x94>
ffffffffc0200a50:	000ac797          	auipc	a5,0xac
ffffffffc0200a54:	9a078793          	addi	a5,a5,-1632 # ffffffffc02ac3f0 <current>
ffffffffc0200a58:	639c                	ld	a5,0(a5)
ffffffffc0200a5a:	c399                	beqz	a5,ffffffffc0200a60 <interrupt_handler+0x94>
                current->need_resched = 1;
ffffffffc0200a5c:	4705                	li	a4,1
ffffffffc0200a5e:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a60:	60a2                	ld	ra,8(sp)
ffffffffc0200a62:	0141                	addi	sp,sp,16
ffffffffc0200a64:	8082                	ret
            print_trapframe(tf);
ffffffffc0200a66:	de5ff06f          	j	ffffffffc020084a <print_trapframe>

ffffffffc0200a6a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a6a:	11853783          	ld	a5,280(a0)
ffffffffc0200a6e:	473d                	li	a4,15
ffffffffc0200a70:	1ef76b63          	bltu	a4,a5,ffffffffc0200c66 <exception_handler+0x1fc>
ffffffffc0200a74:	00006717          	auipc	a4,0x6
ffffffffc0200a78:	0c070713          	addi	a4,a4,192 # ffffffffc0206b34 <commands+0x1cc>
ffffffffc0200a7c:	078a                	slli	a5,a5,0x2
ffffffffc0200a7e:	97ba                	add	a5,a5,a4
ffffffffc0200a80:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a82:	1101                	addi	sp,sp,-32
ffffffffc0200a84:	e822                	sd	s0,16(sp)
ffffffffc0200a86:	ec06                	sd	ra,24(sp)
ffffffffc0200a88:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200a8a:	97ba                	add	a5,a5,a4
ffffffffc0200a8c:	842a                	mv	s0,a0
ffffffffc0200a8e:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	1f050513          	addi	a0,a0,496 # ffffffffc0206c80 <commands+0x318>
ffffffffc0200a98:	e38ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            tf->epc += 4;
ffffffffc0200a9c:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200aa0:	60e2                	ld	ra,24(sp)
ffffffffc0200aa2:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200aa4:	0791                	addi	a5,a5,4
ffffffffc0200aa6:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200aaa:	6442                	ld	s0,16(sp)
ffffffffc0200aac:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200aae:	7f00506f          	j	ffffffffc020629e <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	1ee50513          	addi	a0,a0,494 # ffffffffc0206ca0 <commands+0x338>
}
ffffffffc0200aba:	6442                	ld	s0,16(sp)
ffffffffc0200abc:	60e2                	ld	ra,24(sp)
ffffffffc0200abe:	64a2                	ld	s1,8(sp)
ffffffffc0200ac0:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200ac2:	e0eff06f          	j	ffffffffc02000d0 <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200ac6:	00006517          	auipc	a0,0x6
ffffffffc0200aca:	1fa50513          	addi	a0,a0,506 # ffffffffc0206cc0 <commands+0x358>
ffffffffc0200ace:	b7f5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200ad0:	00006517          	auipc	a0,0x6
ffffffffc0200ad4:	21050513          	addi	a0,a0,528 # ffffffffc0206ce0 <commands+0x378>
ffffffffc0200ad8:	df8ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200adc:	8522                	mv	a0,s0
ffffffffc0200ade:	dcfff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200ae2:	84aa                	mv	s1,a0
ffffffffc0200ae4:	18051363          	bnez	a0,ffffffffc0200c6a <exception_handler+0x200>
}
ffffffffc0200ae8:	60e2                	ld	ra,24(sp)
ffffffffc0200aea:	6442                	ld	s0,16(sp)
ffffffffc0200aec:	64a2                	ld	s1,8(sp)
ffffffffc0200aee:	6105                	addi	sp,sp,32
ffffffffc0200af0:	8082                	ret
            cprintf("Load page fault\n");
ffffffffc0200af2:	00006517          	auipc	a0,0x6
ffffffffc0200af6:	20650513          	addi	a0,a0,518 # ffffffffc0206cf8 <commands+0x390>
ffffffffc0200afa:	dd6ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200afe:	8522                	mv	a0,s0
ffffffffc0200b00:	dadff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200b04:	84aa                	mv	s1,a0
ffffffffc0200b06:	d16d                	beqz	a0,ffffffffc0200ae8 <exception_handler+0x7e>
                print_trapframe(tf);
ffffffffc0200b08:	8522                	mv	a0,s0
ffffffffc0200b0a:	d41ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b0e:	86a6                	mv	a3,s1
ffffffffc0200b10:	00006617          	auipc	a2,0x6
ffffffffc0200b14:	12060613          	addi	a2,a2,288 # ffffffffc0206c30 <commands+0x2c8>
ffffffffc0200b18:	0f600593          	li	a1,246
ffffffffc0200b1c:	00006517          	auipc	a0,0x6
ffffffffc0200b20:	2fc50513          	addi	a0,a0,764 # ffffffffc0206e18 <commands+0x4b0>
ffffffffc0200b24:	ef2ff0ef          	jal	ra,ffffffffc0200216 <__panic>
            cprintf("Store/AMO page fault\n");
ffffffffc0200b28:	00006517          	auipc	a0,0x6
ffffffffc0200b2c:	1e850513          	addi	a0,a0,488 # ffffffffc0206d10 <commands+0x3a8>
ffffffffc0200b30:	da0ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b34:	8522                	mv	a0,s0
ffffffffc0200b36:	d77ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200b3a:	84aa                	mv	s1,a0
ffffffffc0200b3c:	d555                	beqz	a0,ffffffffc0200ae8 <exception_handler+0x7e>
                print_trapframe(tf);
ffffffffc0200b3e:	8522                	mv	a0,s0
ffffffffc0200b40:	d0bff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b44:	86a6                	mv	a3,s1
ffffffffc0200b46:	00006617          	auipc	a2,0x6
ffffffffc0200b4a:	0ea60613          	addi	a2,a2,234 # ffffffffc0206c30 <commands+0x2c8>
ffffffffc0200b4e:	0fd00593          	li	a1,253
ffffffffc0200b52:	00006517          	auipc	a0,0x6
ffffffffc0200b56:	2c650513          	addi	a0,a0,710 # ffffffffc0206e18 <commands+0x4b0>
ffffffffc0200b5a:	ebcff0ef          	jal	ra,ffffffffc0200216 <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b5e:	00006517          	auipc	a0,0x6
ffffffffc0200b62:	01a50513          	addi	a0,a0,26 # ffffffffc0206b78 <commands+0x210>
ffffffffc0200b66:	bf91                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b68:	00006517          	auipc	a0,0x6
ffffffffc0200b6c:	03050513          	addi	a0,a0,48 # ffffffffc0206b98 <commands+0x230>
ffffffffc0200b70:	b7a9                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200b72:	00006517          	auipc	a0,0x6
ffffffffc0200b76:	04650513          	addi	a0,a0,70 # ffffffffc0206bb8 <commands+0x250>
ffffffffc0200b7a:	b781                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b7c:	00006517          	auipc	a0,0x6
ffffffffc0200b80:	05450513          	addi	a0,a0,84 # ffffffffc0206bd0 <commands+0x268>
ffffffffc0200b84:	d4cff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b88:	6458                	ld	a4,136(s0)
ffffffffc0200b8a:	47a9                	li	a5,10
ffffffffc0200b8c:	f4f71ee3          	bne	a4,a5,ffffffffc0200ae8 <exception_handler+0x7e>
                tf->epc += 4;
ffffffffc0200b90:	10843783          	ld	a5,264(s0)
                cprintf("activate syscall\n");
ffffffffc0200b94:	00006517          	auipc	a0,0x6
ffffffffc0200b98:	04c50513          	addi	a0,a0,76 # ffffffffc0206be0 <commands+0x278>
                tf->epc += 4;
ffffffffc0200b9c:	0791                	addi	a5,a5,4
ffffffffc0200b9e:	10f43423          	sd	a5,264(s0)
                cprintf("activate syscall\n");
ffffffffc0200ba2:	d2eff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                syscall();
ffffffffc0200ba6:	6f8050ef          	jal	ra,ffffffffc020629e <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200baa:	000ac797          	auipc	a5,0xac
ffffffffc0200bae:	84678793          	addi	a5,a5,-1978 # ffffffffc02ac3f0 <current>
ffffffffc0200bb2:	639c                	ld	a5,0(a5)
ffffffffc0200bb4:	8522                	mv	a0,s0
}
ffffffffc0200bb6:	6442                	ld	s0,16(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200bb8:	6b9c                	ld	a5,16(a5)
}
ffffffffc0200bba:	60e2                	ld	ra,24(sp)
ffffffffc0200bbc:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200bbe:	6589                	lui	a1,0x2
ffffffffc0200bc0:	95be                	add	a1,a1,a5
}
ffffffffc0200bc2:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200bc4:	2220006f          	j	ffffffffc0200de6 <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200bc8:	00006517          	auipc	a0,0x6
ffffffffc0200bcc:	03050513          	addi	a0,a0,48 # ffffffffc0206bf8 <commands+0x290>
ffffffffc0200bd0:	b5ed                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200bd2:	00006517          	auipc	a0,0x6
ffffffffc0200bd6:	04650513          	addi	a0,a0,70 # ffffffffc0206c18 <commands+0x2b0>
ffffffffc0200bda:	cf6ff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bde:	8522                	mv	a0,s0
ffffffffc0200be0:	ccdff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200be4:	84aa                	mv	s1,a0
ffffffffc0200be6:	f00501e3          	beqz	a0,ffffffffc0200ae8 <exception_handler+0x7e>
                print_trapframe(tf);
ffffffffc0200bea:	8522                	mv	a0,s0
ffffffffc0200bec:	c5fff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bf0:	86a6                	mv	a3,s1
ffffffffc0200bf2:	00006617          	auipc	a2,0x6
ffffffffc0200bf6:	03e60613          	addi	a2,a2,62 # ffffffffc0206c30 <commands+0x2c8>
ffffffffc0200bfa:	0ce00593          	li	a1,206
ffffffffc0200bfe:	00006517          	auipc	a0,0x6
ffffffffc0200c02:	21a50513          	addi	a0,a0,538 # ffffffffc0206e18 <commands+0x4b0>
ffffffffc0200c06:	e10ff0ef          	jal	ra,ffffffffc0200216 <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200c0a:	00006517          	auipc	a0,0x6
ffffffffc0200c0e:	05e50513          	addi	a0,a0,94 # ffffffffc0206c68 <commands+0x300>
ffffffffc0200c12:	cbeff0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200c16:	8522                	mv	a0,s0
ffffffffc0200c18:	c95ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200c1c:	84aa                	mv	s1,a0
ffffffffc0200c1e:	ec0505e3          	beqz	a0,ffffffffc0200ae8 <exception_handler+0x7e>
                print_trapframe(tf);
ffffffffc0200c22:	8522                	mv	a0,s0
ffffffffc0200c24:	c27ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c28:	86a6                	mv	a3,s1
ffffffffc0200c2a:	00006617          	auipc	a2,0x6
ffffffffc0200c2e:	00660613          	addi	a2,a2,6 # ffffffffc0206c30 <commands+0x2c8>
ffffffffc0200c32:	0d800593          	li	a1,216
ffffffffc0200c36:	00006517          	auipc	a0,0x6
ffffffffc0200c3a:	1e250513          	addi	a0,a0,482 # ffffffffc0206e18 <commands+0x4b0>
ffffffffc0200c3e:	dd8ff0ef          	jal	ra,ffffffffc0200216 <__panic>
}
ffffffffc0200c42:	6442                	ld	s0,16(sp)
ffffffffc0200c44:	60e2                	ld	ra,24(sp)
ffffffffc0200c46:	64a2                	ld	s1,8(sp)
ffffffffc0200c48:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200c4a:	c01ff06f          	j	ffffffffc020084a <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200c4e:	00006617          	auipc	a2,0x6
ffffffffc0200c52:	00260613          	addi	a2,a2,2 # ffffffffc0206c50 <commands+0x2e8>
ffffffffc0200c56:	0d200593          	li	a1,210
ffffffffc0200c5a:	00006517          	auipc	a0,0x6
ffffffffc0200c5e:	1be50513          	addi	a0,a0,446 # ffffffffc0206e18 <commands+0x4b0>
ffffffffc0200c62:	db4ff0ef          	jal	ra,ffffffffc0200216 <__panic>
            print_trapframe(tf);
ffffffffc0200c66:	be5ff06f          	j	ffffffffc020084a <print_trapframe>
                print_trapframe(tf);
ffffffffc0200c6a:	8522                	mv	a0,s0
ffffffffc0200c6c:	bdfff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c70:	86a6                	mv	a3,s1
ffffffffc0200c72:	00006617          	auipc	a2,0x6
ffffffffc0200c76:	fbe60613          	addi	a2,a2,-66 # ffffffffc0206c30 <commands+0x2c8>
ffffffffc0200c7a:	0ef00593          	li	a1,239
ffffffffc0200c7e:	00006517          	auipc	a0,0x6
ffffffffc0200c82:	19a50513          	addi	a0,a0,410 # ffffffffc0206e18 <commands+0x4b0>
ffffffffc0200c86:	d90ff0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0200c8a <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c8a:	1101                	addi	sp,sp,-32
ffffffffc0200c8c:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c8e:	000ab417          	auipc	s0,0xab
ffffffffc0200c92:	76240413          	addi	s0,s0,1890 # ffffffffc02ac3f0 <current>
ffffffffc0200c96:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c98:	ec06                	sd	ra,24(sp)
ffffffffc0200c9a:	e426                	sd	s1,8(sp)
ffffffffc0200c9c:	e04a                	sd	s2,0(sp)
ffffffffc0200c9e:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200ca2:	cf1d                	beqz	a4,ffffffffc0200ce0 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200ca4:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200ca8:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200cac:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200cae:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200cb2:	0206c463          	bltz	a3,ffffffffc0200cda <trap+0x50>
        exception_handler(tf);
ffffffffc0200cb6:	db5ff0ef          	jal	ra,ffffffffc0200a6a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200cba:	601c                	ld	a5,0(s0)
ffffffffc0200cbc:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200cc0:	e499                	bnez	s1,ffffffffc0200cce <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200cc2:	0b07a703          	lw	a4,176(a5)
ffffffffc0200cc6:	8b05                	andi	a4,a4,1
ffffffffc0200cc8:	e339                	bnez	a4,ffffffffc0200d0e <trap+0x84>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200cca:	6f9c                	ld	a5,24(a5)
ffffffffc0200ccc:	eb95                	bnez	a5,ffffffffc0200d00 <trap+0x76>
                schedule();
            }
        }
    }
}
ffffffffc0200cce:	60e2                	ld	ra,24(sp)
ffffffffc0200cd0:	6442                	ld	s0,16(sp)
ffffffffc0200cd2:	64a2                	ld	s1,8(sp)
ffffffffc0200cd4:	6902                	ld	s2,0(sp)
ffffffffc0200cd6:	6105                	addi	sp,sp,32
ffffffffc0200cd8:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200cda:	cf3ff0ef          	jal	ra,ffffffffc02009cc <interrupt_handler>
ffffffffc0200cde:	bff1                	j	ffffffffc0200cba <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ce0:	0006c963          	bltz	a3,ffffffffc0200cf2 <trap+0x68>
}
ffffffffc0200ce4:	6442                	ld	s0,16(sp)
ffffffffc0200ce6:	60e2                	ld	ra,24(sp)
ffffffffc0200ce8:	64a2                	ld	s1,8(sp)
ffffffffc0200cea:	6902                	ld	s2,0(sp)
ffffffffc0200cec:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200cee:	d7dff06f          	j	ffffffffc0200a6a <exception_handler>
}
ffffffffc0200cf2:	6442                	ld	s0,16(sp)
ffffffffc0200cf4:	60e2                	ld	ra,24(sp)
ffffffffc0200cf6:	64a2                	ld	s1,8(sp)
ffffffffc0200cf8:	6902                	ld	s2,0(sp)
ffffffffc0200cfa:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200cfc:	cd1ff06f          	j	ffffffffc02009cc <interrupt_handler>
}
ffffffffc0200d00:	6442                	ld	s0,16(sp)
ffffffffc0200d02:	60e2                	ld	ra,24(sp)
ffffffffc0200d04:	64a2                	ld	s1,8(sp)
ffffffffc0200d06:	6902                	ld	s2,0(sp)
ffffffffc0200d08:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200d0a:	49e0506f          	j	ffffffffc02061a8 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200d0e:	555d                	li	a0,-9
ffffffffc0200d10:	101040ef          	jal	ra,ffffffffc0205610 <do_exit>
ffffffffc0200d14:	601c                	ld	a5,0(s0)
ffffffffc0200d16:	bf55                	j	ffffffffc0200cca <trap+0x40>

ffffffffc0200d18 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d18:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200d1c:	00011463          	bnez	sp,ffffffffc0200d24 <__alltraps+0xc>
ffffffffc0200d20:	14002173          	csrr	sp,sscratch
ffffffffc0200d24:	712d                	addi	sp,sp,-288
ffffffffc0200d26:	e002                	sd	zero,0(sp)
ffffffffc0200d28:	e406                	sd	ra,8(sp)
ffffffffc0200d2a:	ec0e                	sd	gp,24(sp)
ffffffffc0200d2c:	f012                	sd	tp,32(sp)
ffffffffc0200d2e:	f416                	sd	t0,40(sp)
ffffffffc0200d30:	f81a                	sd	t1,48(sp)
ffffffffc0200d32:	fc1e                	sd	t2,56(sp)
ffffffffc0200d34:	e0a2                	sd	s0,64(sp)
ffffffffc0200d36:	e4a6                	sd	s1,72(sp)
ffffffffc0200d38:	e8aa                	sd	a0,80(sp)
ffffffffc0200d3a:	ecae                	sd	a1,88(sp)
ffffffffc0200d3c:	f0b2                	sd	a2,96(sp)
ffffffffc0200d3e:	f4b6                	sd	a3,104(sp)
ffffffffc0200d40:	f8ba                	sd	a4,112(sp)
ffffffffc0200d42:	fcbe                	sd	a5,120(sp)
ffffffffc0200d44:	e142                	sd	a6,128(sp)
ffffffffc0200d46:	e546                	sd	a7,136(sp)
ffffffffc0200d48:	e94a                	sd	s2,144(sp)
ffffffffc0200d4a:	ed4e                	sd	s3,152(sp)
ffffffffc0200d4c:	f152                	sd	s4,160(sp)
ffffffffc0200d4e:	f556                	sd	s5,168(sp)
ffffffffc0200d50:	f95a                	sd	s6,176(sp)
ffffffffc0200d52:	fd5e                	sd	s7,184(sp)
ffffffffc0200d54:	e1e2                	sd	s8,192(sp)
ffffffffc0200d56:	e5e6                	sd	s9,200(sp)
ffffffffc0200d58:	e9ea                	sd	s10,208(sp)
ffffffffc0200d5a:	edee                	sd	s11,216(sp)
ffffffffc0200d5c:	f1f2                	sd	t3,224(sp)
ffffffffc0200d5e:	f5f6                	sd	t4,232(sp)
ffffffffc0200d60:	f9fa                	sd	t5,240(sp)
ffffffffc0200d62:	fdfe                	sd	t6,248(sp)
ffffffffc0200d64:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200d68:	100024f3          	csrr	s1,sstatus
ffffffffc0200d6c:	14102973          	csrr	s2,sepc
ffffffffc0200d70:	143029f3          	csrr	s3,stval
ffffffffc0200d74:	14202a73          	csrr	s4,scause
ffffffffc0200d78:	e822                	sd	s0,16(sp)
ffffffffc0200d7a:	e226                	sd	s1,256(sp)
ffffffffc0200d7c:	e64a                	sd	s2,264(sp)
ffffffffc0200d7e:	ea4e                	sd	s3,272(sp)
ffffffffc0200d80:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d82:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d84:	f07ff0ef          	jal	ra,ffffffffc0200c8a <trap>

ffffffffc0200d88 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d88:	6492                	ld	s1,256(sp)
ffffffffc0200d8a:	6932                	ld	s2,264(sp)
ffffffffc0200d8c:	1004f413          	andi	s0,s1,256
ffffffffc0200d90:	e401                	bnez	s0,ffffffffc0200d98 <__trapret+0x10>
ffffffffc0200d92:	1200                	addi	s0,sp,288
ffffffffc0200d94:	14041073          	csrw	sscratch,s0
ffffffffc0200d98:	10049073          	csrw	sstatus,s1
ffffffffc0200d9c:	14191073          	csrw	sepc,s2
ffffffffc0200da0:	60a2                	ld	ra,8(sp)
ffffffffc0200da2:	61e2                	ld	gp,24(sp)
ffffffffc0200da4:	7202                	ld	tp,32(sp)
ffffffffc0200da6:	72a2                	ld	t0,40(sp)
ffffffffc0200da8:	7342                	ld	t1,48(sp)
ffffffffc0200daa:	73e2                	ld	t2,56(sp)
ffffffffc0200dac:	6406                	ld	s0,64(sp)
ffffffffc0200dae:	64a6                	ld	s1,72(sp)
ffffffffc0200db0:	6546                	ld	a0,80(sp)
ffffffffc0200db2:	65e6                	ld	a1,88(sp)
ffffffffc0200db4:	7606                	ld	a2,96(sp)
ffffffffc0200db6:	76a6                	ld	a3,104(sp)
ffffffffc0200db8:	7746                	ld	a4,112(sp)
ffffffffc0200dba:	77e6                	ld	a5,120(sp)
ffffffffc0200dbc:	680a                	ld	a6,128(sp)
ffffffffc0200dbe:	68aa                	ld	a7,136(sp)
ffffffffc0200dc0:	694a                	ld	s2,144(sp)
ffffffffc0200dc2:	69ea                	ld	s3,152(sp)
ffffffffc0200dc4:	7a0a                	ld	s4,160(sp)
ffffffffc0200dc6:	7aaa                	ld	s5,168(sp)
ffffffffc0200dc8:	7b4a                	ld	s6,176(sp)
ffffffffc0200dca:	7bea                	ld	s7,184(sp)
ffffffffc0200dcc:	6c0e                	ld	s8,192(sp)
ffffffffc0200dce:	6cae                	ld	s9,200(sp)
ffffffffc0200dd0:	6d4e                	ld	s10,208(sp)
ffffffffc0200dd2:	6dee                	ld	s11,216(sp)
ffffffffc0200dd4:	7e0e                	ld	t3,224(sp)
ffffffffc0200dd6:	7eae                	ld	t4,232(sp)
ffffffffc0200dd8:	7f4e                	ld	t5,240(sp)
ffffffffc0200dda:	7fee                	ld	t6,248(sp)
ffffffffc0200ddc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200dde:	10200073          	sret

ffffffffc0200de2 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200de2:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200de4:	b755                	j	ffffffffc0200d88 <__trapret>

ffffffffc0200de6 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200de6:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7690>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200dea:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200dee:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200df2:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200df6:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200dfa:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200dfe:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200e02:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200e06:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200e0a:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200e0c:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200e0e:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200e10:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200e12:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200e14:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200e16:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200e18:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200e1a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200e1c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200e1e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200e20:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200e22:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200e24:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200e26:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200e28:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200e2a:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200e2c:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200e2e:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200e30:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200e32:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200e34:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200e36:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200e38:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200e3a:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200e3c:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200e3e:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200e40:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200e42:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200e44:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200e46:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200e48:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200e4a:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200e4c:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200e4e:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200e50:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200e52:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200e54:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200e56:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200e58:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200e5a:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200e5c:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200e5e:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200e60:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200e62:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200e64:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200e66:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200e68:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200e6a:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e6c:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e6e:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e70:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e72:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e74:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e76:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e78:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e7a:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e7c:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e7e:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e80:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e82:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e84:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e86:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e88:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e8a:	812e                	mv	sp,a1
ffffffffc0200e8c:	bdf5                	j	ffffffffc0200d88 <__trapret>

ffffffffc0200e8e <pa2page.part.4>:
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}

static inline struct Page *
pa2page(uintptr_t pa) {
ffffffffc0200e8e:	1141                	addi	sp,sp,-16
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
ffffffffc0200e90:	00006617          	auipc	a2,0x6
ffffffffc0200e94:	3e060613          	addi	a2,a2,992 # ffffffffc0207270 <commands+0x908>
ffffffffc0200e98:	06200593          	li	a1,98
ffffffffc0200e9c:	00006517          	auipc	a0,0x6
ffffffffc0200ea0:	3f450513          	addi	a0,a0,1012 # ffffffffc0207290 <commands+0x928>
pa2page(uintptr_t pa) {
ffffffffc0200ea4:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0200ea6:	b70ff0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0200eaa <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0200eaa:	715d                	addi	sp,sp,-80
ffffffffc0200eac:	e0a2                	sd	s0,64(sp)
ffffffffc0200eae:	fc26                	sd	s1,56(sp)
ffffffffc0200eb0:	f84a                	sd	s2,48(sp)
ffffffffc0200eb2:	f44e                	sd	s3,40(sp)
ffffffffc0200eb4:	f052                	sd	s4,32(sp)
ffffffffc0200eb6:	ec56                	sd	s5,24(sp)
ffffffffc0200eb8:	e486                	sd	ra,72(sp)
ffffffffc0200eba:	842a                	mv	s0,a0
ffffffffc0200ebc:	000ab497          	auipc	s1,0xab
ffffffffc0200ec0:	55c48493          	addi	s1,s1,1372 # ffffffffc02ac418 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200ec4:	4985                	li	s3,1
ffffffffc0200ec6:	000aba17          	auipc	s4,0xab
ffffffffc0200eca:	522a0a13          	addi	s4,s4,1314 # ffffffffc02ac3e8 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0200ece:	0005091b          	sext.w	s2,a0
ffffffffc0200ed2:	000aba97          	auipc	s5,0xab
ffffffffc0200ed6:	576a8a93          	addi	s5,s5,1398 # ffffffffc02ac448 <check_mm_struct>
ffffffffc0200eda:	a00d                	j	ffffffffc0200efc <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0200edc:	609c                	ld	a5,0(s1)
ffffffffc0200ede:	6f9c                	ld	a5,24(a5)
ffffffffc0200ee0:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0200ee2:	4601                	li	a2,0
ffffffffc0200ee4:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200ee6:	ed0d                	bnez	a0,ffffffffc0200f20 <alloc_pages+0x76>
ffffffffc0200ee8:	0289ec63          	bltu	s3,s0,ffffffffc0200f20 <alloc_pages+0x76>
ffffffffc0200eec:	000a2783          	lw	a5,0(s4)
ffffffffc0200ef0:	2781                	sext.w	a5,a5
ffffffffc0200ef2:	c79d                	beqz	a5,ffffffffc0200f20 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0200ef4:	000ab503          	ld	a0,0(s5)
ffffffffc0200ef8:	134030ef          	jal	ra,ffffffffc020402c <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200efc:	100027f3          	csrr	a5,sstatus
ffffffffc0200f00:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0200f02:	8522                	mv	a0,s0
ffffffffc0200f04:	dfe1                	beqz	a5,ffffffffc0200edc <alloc_pages+0x32>
        intr_disable();
ffffffffc0200f06:	f56ff0ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc0200f0a:	609c                	ld	a5,0(s1)
ffffffffc0200f0c:	8522                	mv	a0,s0
ffffffffc0200f0e:	6f9c                	ld	a5,24(a5)
ffffffffc0200f10:	9782                	jalr	a5
ffffffffc0200f12:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200f14:	f42ff0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc0200f18:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0200f1a:	4601                	li	a2,0
ffffffffc0200f1c:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0200f1e:	d569                	beqz	a0,ffffffffc0200ee8 <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0200f20:	60a6                	ld	ra,72(sp)
ffffffffc0200f22:	6406                	ld	s0,64(sp)
ffffffffc0200f24:	74e2                	ld	s1,56(sp)
ffffffffc0200f26:	7942                	ld	s2,48(sp)
ffffffffc0200f28:	79a2                	ld	s3,40(sp)
ffffffffc0200f2a:	7a02                	ld	s4,32(sp)
ffffffffc0200f2c:	6ae2                	ld	s5,24(sp)
ffffffffc0200f2e:	6161                	addi	sp,sp,80
ffffffffc0200f30:	8082                	ret

ffffffffc0200f32 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f32:	100027f3          	csrr	a5,sstatus
ffffffffc0200f36:	8b89                	andi	a5,a5,2
ffffffffc0200f38:	eb89                	bnez	a5,ffffffffc0200f4a <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200f3a:	000ab797          	auipc	a5,0xab
ffffffffc0200f3e:	4de78793          	addi	a5,a5,1246 # ffffffffc02ac418 <pmm_manager>
ffffffffc0200f42:	639c                	ld	a5,0(a5)
ffffffffc0200f44:	0207b303          	ld	t1,32(a5)
ffffffffc0200f48:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0200f4a:	1101                	addi	sp,sp,-32
ffffffffc0200f4c:	ec06                	sd	ra,24(sp)
ffffffffc0200f4e:	e822                	sd	s0,16(sp)
ffffffffc0200f50:	e426                	sd	s1,8(sp)
ffffffffc0200f52:	842a                	mv	s0,a0
ffffffffc0200f54:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200f56:	f06ff0ef          	jal	ra,ffffffffc020065c <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200f5a:	000ab797          	auipc	a5,0xab
ffffffffc0200f5e:	4be78793          	addi	a5,a5,1214 # ffffffffc02ac418 <pmm_manager>
ffffffffc0200f62:	639c                	ld	a5,0(a5)
ffffffffc0200f64:	85a6                	mv	a1,s1
ffffffffc0200f66:	8522                	mv	a0,s0
ffffffffc0200f68:	739c                	ld	a5,32(a5)
ffffffffc0200f6a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200f6c:	6442                	ld	s0,16(sp)
ffffffffc0200f6e:	60e2                	ld	ra,24(sp)
ffffffffc0200f70:	64a2                	ld	s1,8(sp)
ffffffffc0200f72:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200f74:	ee2ff06f          	j	ffffffffc0200656 <intr_enable>

ffffffffc0200f78 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f78:	100027f3          	csrr	a5,sstatus
ffffffffc0200f7c:	8b89                	andi	a5,a5,2
ffffffffc0200f7e:	eb89                	bnez	a5,ffffffffc0200f90 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200f80:	000ab797          	auipc	a5,0xab
ffffffffc0200f84:	49878793          	addi	a5,a5,1176 # ffffffffc02ac418 <pmm_manager>
ffffffffc0200f88:	639c                	ld	a5,0(a5)
ffffffffc0200f8a:	0287b303          	ld	t1,40(a5)
ffffffffc0200f8e:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0200f90:	1141                	addi	sp,sp,-16
ffffffffc0200f92:	e406                	sd	ra,8(sp)
ffffffffc0200f94:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200f96:	ec6ff0ef          	jal	ra,ffffffffc020065c <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200f9a:	000ab797          	auipc	a5,0xab
ffffffffc0200f9e:	47e78793          	addi	a5,a5,1150 # ffffffffc02ac418 <pmm_manager>
ffffffffc0200fa2:	639c                	ld	a5,0(a5)
ffffffffc0200fa4:	779c                	ld	a5,40(a5)
ffffffffc0200fa6:	9782                	jalr	a5
ffffffffc0200fa8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200faa:	eacff0ef          	jal	ra,ffffffffc0200656 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200fae:	8522                	mv	a0,s0
ffffffffc0200fb0:	60a2                	ld	ra,8(sp)
ffffffffc0200fb2:	6402                	ld	s0,0(sp)
ffffffffc0200fb4:	0141                	addi	sp,sp,16
ffffffffc0200fb6:	8082                	ret

ffffffffc0200fb8 <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200fb8:	7139                	addi	sp,sp,-64
ffffffffc0200fba:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0200fbc:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0200fc0:	1ff4f493          	andi	s1,s1,511
ffffffffc0200fc4:	048e                	slli	s1,s1,0x3
ffffffffc0200fc6:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200fc8:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200fca:	f04a                	sd	s2,32(sp)
ffffffffc0200fcc:	ec4e                	sd	s3,24(sp)
ffffffffc0200fce:	e852                	sd	s4,16(sp)
ffffffffc0200fd0:	fc06                	sd	ra,56(sp)
ffffffffc0200fd2:	f822                	sd	s0,48(sp)
ffffffffc0200fd4:	e456                	sd	s5,8(sp)
ffffffffc0200fd6:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200fd8:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0200fdc:	892e                	mv	s2,a1
ffffffffc0200fde:	8a32                	mv	s4,a2
ffffffffc0200fe0:	000ab997          	auipc	s3,0xab
ffffffffc0200fe4:	3e898993          	addi	s3,s3,1000 # ffffffffc02ac3c8 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0200fe8:	e7bd                	bnez	a5,ffffffffc0201056 <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0200fea:	12060c63          	beqz	a2,ffffffffc0201122 <get_pte+0x16a>
ffffffffc0200fee:	4505                	li	a0,1
ffffffffc0200ff0:	ebbff0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0200ff4:	842a                	mv	s0,a0
ffffffffc0200ff6:	12050663          	beqz	a0,ffffffffc0201122 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0200ffa:	000abb17          	auipc	s6,0xab
ffffffffc0200ffe:	436b0b13          	addi	s6,s6,1078 # ffffffffc02ac430 <pages>
ffffffffc0201002:	000b3503          	ld	a0,0(s6)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201006:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201008:	000ab997          	auipc	s3,0xab
ffffffffc020100c:	3c098993          	addi	s3,s3,960 # ffffffffc02ac3c8 <npage>
    return page - pages + nbase;
ffffffffc0201010:	40a40533          	sub	a0,s0,a0
ffffffffc0201014:	00080ab7          	lui	s5,0x80
ffffffffc0201018:	8519                	srai	a0,a0,0x6
ffffffffc020101a:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc020101e:	c01c                	sw	a5,0(s0)
ffffffffc0201020:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0201022:	9556                	add	a0,a0,s5
ffffffffc0201024:	83b1                	srli	a5,a5,0xc
ffffffffc0201026:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201028:	0532                	slli	a0,a0,0xc
ffffffffc020102a:	14e7f363          	bleu	a4,a5,ffffffffc0201170 <get_pte+0x1b8>
ffffffffc020102e:	000ab797          	auipc	a5,0xab
ffffffffc0201032:	3f278793          	addi	a5,a5,1010 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0201036:	639c                	ld	a5,0(a5)
ffffffffc0201038:	6605                	lui	a2,0x1
ffffffffc020103a:	4581                	li	a1,0
ffffffffc020103c:	953e                	add	a0,a0,a5
ffffffffc020103e:	37e050ef          	jal	ra,ffffffffc02063bc <memset>
    return page - pages + nbase;
ffffffffc0201042:	000b3683          	ld	a3,0(s6)
ffffffffc0201046:	40d406b3          	sub	a3,s0,a3
ffffffffc020104a:	8699                	srai	a3,a3,0x6
ffffffffc020104c:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020104e:	06aa                	slli	a3,a3,0xa
ffffffffc0201050:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201054:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201056:	77fd                	lui	a5,0xfffff
ffffffffc0201058:	068a                	slli	a3,a3,0x2
ffffffffc020105a:	0009b703          	ld	a4,0(s3)
ffffffffc020105e:	8efd                	and	a3,a3,a5
ffffffffc0201060:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201064:	0ce7f163          	bleu	a4,a5,ffffffffc0201126 <get_pte+0x16e>
ffffffffc0201068:	000aba97          	auipc	s5,0xab
ffffffffc020106c:	3b8a8a93          	addi	s5,s5,952 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0201070:	000ab403          	ld	s0,0(s5)
ffffffffc0201074:	01595793          	srli	a5,s2,0x15
ffffffffc0201078:	1ff7f793          	andi	a5,a5,511
ffffffffc020107c:	96a2                	add	a3,a3,s0
ffffffffc020107e:	00379413          	slli	s0,a5,0x3
ffffffffc0201082:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201084:	6014                	ld	a3,0(s0)
ffffffffc0201086:	0016f793          	andi	a5,a3,1
ffffffffc020108a:	e3ad                	bnez	a5,ffffffffc02010ec <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc020108c:	080a0b63          	beqz	s4,ffffffffc0201122 <get_pte+0x16a>
ffffffffc0201090:	4505                	li	a0,1
ffffffffc0201092:	e19ff0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0201096:	84aa                	mv	s1,a0
ffffffffc0201098:	c549                	beqz	a0,ffffffffc0201122 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc020109a:	000abb17          	auipc	s6,0xab
ffffffffc020109e:	396b0b13          	addi	s6,s6,918 # ffffffffc02ac430 <pages>
ffffffffc02010a2:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc02010a6:	4785                	li	a5,1
    return page - pages + nbase;
ffffffffc02010a8:	00080a37          	lui	s4,0x80
ffffffffc02010ac:	40a48533          	sub	a0,s1,a0
ffffffffc02010b0:	8519                	srai	a0,a0,0x6
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02010b2:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc02010b6:	c09c                	sw	a5,0(s1)
ffffffffc02010b8:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc02010ba:	9552                	add	a0,a0,s4
ffffffffc02010bc:	83b1                	srli	a5,a5,0xc
ffffffffc02010be:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02010c0:	0532                	slli	a0,a0,0xc
ffffffffc02010c2:	08e7fa63          	bleu	a4,a5,ffffffffc0201156 <get_pte+0x19e>
ffffffffc02010c6:	000ab783          	ld	a5,0(s5)
ffffffffc02010ca:	6605                	lui	a2,0x1
ffffffffc02010cc:	4581                	li	a1,0
ffffffffc02010ce:	953e                	add	a0,a0,a5
ffffffffc02010d0:	2ec050ef          	jal	ra,ffffffffc02063bc <memset>
    return page - pages + nbase;
ffffffffc02010d4:	000b3683          	ld	a3,0(s6)
ffffffffc02010d8:	40d486b3          	sub	a3,s1,a3
ffffffffc02010dc:	8699                	srai	a3,a3,0x6
ffffffffc02010de:	96d2                	add	a3,a3,s4
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02010e0:	06aa                	slli	a3,a3,0xa
ffffffffc02010e2:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02010e6:	e014                	sd	a3,0(s0)
ffffffffc02010e8:	0009b703          	ld	a4,0(s3)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02010ec:	068a                	slli	a3,a3,0x2
ffffffffc02010ee:	757d                	lui	a0,0xfffff
ffffffffc02010f0:	8ee9                	and	a3,a3,a0
ffffffffc02010f2:	00c6d793          	srli	a5,a3,0xc
ffffffffc02010f6:	04e7f463          	bleu	a4,a5,ffffffffc020113e <get_pte+0x186>
ffffffffc02010fa:	000ab503          	ld	a0,0(s5)
ffffffffc02010fe:	00c95793          	srli	a5,s2,0xc
ffffffffc0201102:	1ff7f793          	andi	a5,a5,511
ffffffffc0201106:	96aa                	add	a3,a3,a0
ffffffffc0201108:	00379513          	slli	a0,a5,0x3
ffffffffc020110c:	9536                	add	a0,a0,a3
}
ffffffffc020110e:	70e2                	ld	ra,56(sp)
ffffffffc0201110:	7442                	ld	s0,48(sp)
ffffffffc0201112:	74a2                	ld	s1,40(sp)
ffffffffc0201114:	7902                	ld	s2,32(sp)
ffffffffc0201116:	69e2                	ld	s3,24(sp)
ffffffffc0201118:	6a42                	ld	s4,16(sp)
ffffffffc020111a:	6aa2                	ld	s5,8(sp)
ffffffffc020111c:	6b02                	ld	s6,0(sp)
ffffffffc020111e:	6121                	addi	sp,sp,64
ffffffffc0201120:	8082                	ret
            return NULL;
ffffffffc0201122:	4501                	li	a0,0
ffffffffc0201124:	b7ed                	j	ffffffffc020110e <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201126:	00006617          	auipc	a2,0x6
ffffffffc020112a:	11260613          	addi	a2,a2,274 # ffffffffc0207238 <commands+0x8d0>
ffffffffc020112e:	0e300593          	li	a1,227
ffffffffc0201132:	00006517          	auipc	a0,0x6
ffffffffc0201136:	12e50513          	addi	a0,a0,302 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020113a:	8dcff0ef          	jal	ra,ffffffffc0200216 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020113e:	00006617          	auipc	a2,0x6
ffffffffc0201142:	0fa60613          	addi	a2,a2,250 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0201146:	0ee00593          	li	a1,238
ffffffffc020114a:	00006517          	auipc	a0,0x6
ffffffffc020114e:	11650513          	addi	a0,a0,278 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201152:	8c4ff0ef          	jal	ra,ffffffffc0200216 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201156:	86aa                	mv	a3,a0
ffffffffc0201158:	00006617          	auipc	a2,0x6
ffffffffc020115c:	0e060613          	addi	a2,a2,224 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0201160:	0eb00593          	li	a1,235
ffffffffc0201164:	00006517          	auipc	a0,0x6
ffffffffc0201168:	0fc50513          	addi	a0,a0,252 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020116c:	8aaff0ef          	jal	ra,ffffffffc0200216 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201170:	86aa                	mv	a3,a0
ffffffffc0201172:	00006617          	auipc	a2,0x6
ffffffffc0201176:	0c660613          	addi	a2,a2,198 # ffffffffc0207238 <commands+0x8d0>
ffffffffc020117a:	0df00593          	li	a1,223
ffffffffc020117e:	00006517          	auipc	a0,0x6
ffffffffc0201182:	0e250513          	addi	a0,a0,226 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201186:	890ff0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020118a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020118a:	1141                	addi	sp,sp,-16
ffffffffc020118c:	e022                	sd	s0,0(sp)
ffffffffc020118e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201190:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201192:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201194:	e25ff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201198:	c011                	beqz	s0,ffffffffc020119c <get_page+0x12>
        *ptep_store = ptep;
ffffffffc020119a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020119c:	c129                	beqz	a0,ffffffffc02011de <get_page+0x54>
ffffffffc020119e:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02011a0:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc02011a2:	0017f713          	andi	a4,a5,1
ffffffffc02011a6:	e709                	bnez	a4,ffffffffc02011b0 <get_page+0x26>
}
ffffffffc02011a8:	60a2                	ld	ra,8(sp)
ffffffffc02011aa:	6402                	ld	s0,0(sp)
ffffffffc02011ac:	0141                	addi	sp,sp,16
ffffffffc02011ae:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc02011b0:	000ab717          	auipc	a4,0xab
ffffffffc02011b4:	21870713          	addi	a4,a4,536 # ffffffffc02ac3c8 <npage>
ffffffffc02011b8:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc02011ba:	078a                	slli	a5,a5,0x2
ffffffffc02011bc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02011be:	02e7f563          	bleu	a4,a5,ffffffffc02011e8 <get_page+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc02011c2:	000ab717          	auipc	a4,0xab
ffffffffc02011c6:	26e70713          	addi	a4,a4,622 # ffffffffc02ac430 <pages>
ffffffffc02011ca:	6308                	ld	a0,0(a4)
ffffffffc02011cc:	60a2                	ld	ra,8(sp)
ffffffffc02011ce:	6402                	ld	s0,0(sp)
ffffffffc02011d0:	fff80737          	lui	a4,0xfff80
ffffffffc02011d4:	97ba                	add	a5,a5,a4
ffffffffc02011d6:	079a                	slli	a5,a5,0x6
ffffffffc02011d8:	953e                	add	a0,a0,a5
ffffffffc02011da:	0141                	addi	sp,sp,16
ffffffffc02011dc:	8082                	ret
ffffffffc02011de:	60a2                	ld	ra,8(sp)
ffffffffc02011e0:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc02011e2:	4501                	li	a0,0
}
ffffffffc02011e4:	0141                	addi	sp,sp,16
ffffffffc02011e6:	8082                	ret
ffffffffc02011e8:	ca7ff0ef          	jal	ra,ffffffffc0200e8e <pa2page.part.4>

ffffffffc02011ec <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02011ec:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02011ee:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02011f2:	ec86                	sd	ra,88(sp)
ffffffffc02011f4:	e8a2                	sd	s0,80(sp)
ffffffffc02011f6:	e4a6                	sd	s1,72(sp)
ffffffffc02011f8:	e0ca                	sd	s2,64(sp)
ffffffffc02011fa:	fc4e                	sd	s3,56(sp)
ffffffffc02011fc:	f852                	sd	s4,48(sp)
ffffffffc02011fe:	f456                	sd	s5,40(sp)
ffffffffc0201200:	f05a                	sd	s6,32(sp)
ffffffffc0201202:	ec5e                	sd	s7,24(sp)
ffffffffc0201204:	e862                	sd	s8,16(sp)
ffffffffc0201206:	e466                	sd	s9,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201208:	03479713          	slli	a4,a5,0x34
ffffffffc020120c:	eb71                	bnez	a4,ffffffffc02012e0 <unmap_range+0xf4>
    assert(USER_ACCESS(start, end));
ffffffffc020120e:	002007b7          	lui	a5,0x200
ffffffffc0201212:	842e                	mv	s0,a1
ffffffffc0201214:	0af5e663          	bltu	a1,a5,ffffffffc02012c0 <unmap_range+0xd4>
ffffffffc0201218:	8932                	mv	s2,a2
ffffffffc020121a:	0ac5f363          	bleu	a2,a1,ffffffffc02012c0 <unmap_range+0xd4>
ffffffffc020121e:	4785                	li	a5,1
ffffffffc0201220:	07fe                	slli	a5,a5,0x1f
ffffffffc0201222:	08c7ef63          	bltu	a5,a2,ffffffffc02012c0 <unmap_range+0xd4>
ffffffffc0201226:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc0201228:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc020122a:	000abc97          	auipc	s9,0xab
ffffffffc020122e:	19ec8c93          	addi	s9,s9,414 # ffffffffc02ac3c8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0201232:	000abc17          	auipc	s8,0xab
ffffffffc0201236:	1fec0c13          	addi	s8,s8,510 # ffffffffc02ac430 <pages>
ffffffffc020123a:	fff80bb7          	lui	s7,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020123e:	00200b37          	lui	s6,0x200
ffffffffc0201242:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0201246:	4601                	li	a2,0
ffffffffc0201248:	85a2                	mv	a1,s0
ffffffffc020124a:	854e                	mv	a0,s3
ffffffffc020124c:	d6dff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc0201250:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc0201252:	cd21                	beqz	a0,ffffffffc02012aa <unmap_range+0xbe>
        if (*ptep != 0) {
ffffffffc0201254:	611c                	ld	a5,0(a0)
ffffffffc0201256:	e38d                	bnez	a5,ffffffffc0201278 <unmap_range+0x8c>
        start += PGSIZE;
ffffffffc0201258:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020125a:	ff2466e3          	bltu	s0,s2,ffffffffc0201246 <unmap_range+0x5a>
}
ffffffffc020125e:	60e6                	ld	ra,88(sp)
ffffffffc0201260:	6446                	ld	s0,80(sp)
ffffffffc0201262:	64a6                	ld	s1,72(sp)
ffffffffc0201264:	6906                	ld	s2,64(sp)
ffffffffc0201266:	79e2                	ld	s3,56(sp)
ffffffffc0201268:	7a42                	ld	s4,48(sp)
ffffffffc020126a:	7aa2                	ld	s5,40(sp)
ffffffffc020126c:	7b02                	ld	s6,32(sp)
ffffffffc020126e:	6be2                	ld	s7,24(sp)
ffffffffc0201270:	6c42                	ld	s8,16(sp)
ffffffffc0201272:	6ca2                	ld	s9,8(sp)
ffffffffc0201274:	6125                	addi	sp,sp,96
ffffffffc0201276:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201278:	0017f713          	andi	a4,a5,1
ffffffffc020127c:	df71                	beqz	a4,ffffffffc0201258 <unmap_range+0x6c>
    if (PPN(pa) >= npage) {
ffffffffc020127e:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201282:	078a                	slli	a5,a5,0x2
ffffffffc0201284:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201286:	06e7fd63          	bleu	a4,a5,ffffffffc0201300 <unmap_range+0x114>
    return &pages[PPN(pa) - nbase];
ffffffffc020128a:	000c3503          	ld	a0,0(s8)
ffffffffc020128e:	97de                	add	a5,a5,s7
ffffffffc0201290:	079a                	slli	a5,a5,0x6
ffffffffc0201292:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201294:	411c                	lw	a5,0(a0)
ffffffffc0201296:	fff7871b          	addiw	a4,a5,-1
ffffffffc020129a:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020129c:	cf11                	beqz	a4,ffffffffc02012b8 <unmap_range+0xcc>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc020129e:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02012a2:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02012a6:	9452                	add	s0,s0,s4
ffffffffc02012a8:	bf4d                	j	ffffffffc020125a <unmap_range+0x6e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02012aa:	945a                	add	s0,s0,s6
ffffffffc02012ac:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02012b0:	d45d                	beqz	s0,ffffffffc020125e <unmap_range+0x72>
ffffffffc02012b2:	f9246ae3          	bltu	s0,s2,ffffffffc0201246 <unmap_range+0x5a>
ffffffffc02012b6:	b765                	j	ffffffffc020125e <unmap_range+0x72>
            free_page(page);
ffffffffc02012b8:	4585                	li	a1,1
ffffffffc02012ba:	c79ff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
ffffffffc02012be:	b7c5                	j	ffffffffc020129e <unmap_range+0xb2>
    assert(USER_ACCESS(start, end));
ffffffffc02012c0:	00006697          	auipc	a3,0x6
ffffffffc02012c4:	5a068693          	addi	a3,a3,1440 # ffffffffc0207860 <commands+0xef8>
ffffffffc02012c8:	00006617          	auipc	a2,0x6
ffffffffc02012cc:	b3860613          	addi	a2,a2,-1224 # ffffffffc0206e00 <commands+0x498>
ffffffffc02012d0:	11000593          	li	a1,272
ffffffffc02012d4:	00006517          	auipc	a0,0x6
ffffffffc02012d8:	f8c50513          	addi	a0,a0,-116 # ffffffffc0207260 <commands+0x8f8>
ffffffffc02012dc:	f3bfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02012e0:	00006697          	auipc	a3,0x6
ffffffffc02012e4:	55068693          	addi	a3,a3,1360 # ffffffffc0207830 <commands+0xec8>
ffffffffc02012e8:	00006617          	auipc	a2,0x6
ffffffffc02012ec:	b1860613          	addi	a2,a2,-1256 # ffffffffc0206e00 <commands+0x498>
ffffffffc02012f0:	10f00593          	li	a1,271
ffffffffc02012f4:	00006517          	auipc	a0,0x6
ffffffffc02012f8:	f6c50513          	addi	a0,a0,-148 # ffffffffc0207260 <commands+0x8f8>
ffffffffc02012fc:	f1bfe0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0201300:	b8fff0ef          	jal	ra,ffffffffc0200e8e <pa2page.part.4>

ffffffffc0201304 <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0201304:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201306:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020130a:	fc86                	sd	ra,120(sp)
ffffffffc020130c:	f8a2                	sd	s0,112(sp)
ffffffffc020130e:	f4a6                	sd	s1,104(sp)
ffffffffc0201310:	f0ca                	sd	s2,96(sp)
ffffffffc0201312:	ecce                	sd	s3,88(sp)
ffffffffc0201314:	e8d2                	sd	s4,80(sp)
ffffffffc0201316:	e4d6                	sd	s5,72(sp)
ffffffffc0201318:	e0da                	sd	s6,64(sp)
ffffffffc020131a:	fc5e                	sd	s7,56(sp)
ffffffffc020131c:	f862                	sd	s8,48(sp)
ffffffffc020131e:	f466                	sd	s9,40(sp)
ffffffffc0201320:	f06a                	sd	s10,32(sp)
ffffffffc0201322:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0201324:	03479713          	slli	a4,a5,0x34
ffffffffc0201328:	1c071163          	bnez	a4,ffffffffc02014ea <exit_range+0x1e6>
    assert(USER_ACCESS(start, end));
ffffffffc020132c:	002007b7          	lui	a5,0x200
ffffffffc0201330:	20f5e563          	bltu	a1,a5,ffffffffc020153a <exit_range+0x236>
ffffffffc0201334:	8b32                	mv	s6,a2
ffffffffc0201336:	20c5f263          	bleu	a2,a1,ffffffffc020153a <exit_range+0x236>
ffffffffc020133a:	4785                	li	a5,1
ffffffffc020133c:	07fe                	slli	a5,a5,0x1f
ffffffffc020133e:	1ec7ee63          	bltu	a5,a2,ffffffffc020153a <exit_range+0x236>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0201342:	c00009b7          	lui	s3,0xc0000
ffffffffc0201346:	400007b7          	lui	a5,0x40000
ffffffffc020134a:	0135f9b3          	and	s3,a1,s3
ffffffffc020134e:	99be                	add	s3,s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0201350:	c0000337          	lui	t1,0xc0000
ffffffffc0201354:	00698933          	add	s2,s3,t1
ffffffffc0201358:	01e95913          	srli	s2,s2,0x1e
ffffffffc020135c:	1ff97913          	andi	s2,s2,511
ffffffffc0201360:	8e2a                	mv	t3,a0
ffffffffc0201362:	090e                	slli	s2,s2,0x3
ffffffffc0201364:	9972                	add	s2,s2,t3
ffffffffc0201366:	00093b83          	ld	s7,0(s2)
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020136a:	ffe004b7          	lui	s1,0xffe00
    return KADDR(page2pa(page));
ffffffffc020136e:	5dfd                	li	s11,-1
        if (pde1&PTE_V){
ffffffffc0201370:	001bf793          	andi	a5,s7,1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0201374:	8ced                	and	s1,s1,a1
    if (PPN(pa) >= npage) {
ffffffffc0201376:	000abd17          	auipc	s10,0xab
ffffffffc020137a:	052d0d13          	addi	s10,s10,82 # ffffffffc02ac3c8 <npage>
    return KADDR(page2pa(page));
ffffffffc020137e:	00cddd93          	srli	s11,s11,0xc
ffffffffc0201382:	000ab717          	auipc	a4,0xab
ffffffffc0201386:	09e70713          	addi	a4,a4,158 # ffffffffc02ac420 <va_pa_offset>
    return &pages[PPN(pa) - nbase];
ffffffffc020138a:	000abe97          	auipc	t4,0xab
ffffffffc020138e:	0a6e8e93          	addi	t4,t4,166 # ffffffffc02ac430 <pages>
        if (pde1&PTE_V){
ffffffffc0201392:	e79d                	bnez	a5,ffffffffc02013c0 <exit_range+0xbc>
    } while (d1start != 0 && d1start < end);
ffffffffc0201394:	12098963          	beqz	s3,ffffffffc02014c6 <exit_range+0x1c2>
ffffffffc0201398:	400007b7          	lui	a5,0x40000
ffffffffc020139c:	84ce                	mv	s1,s3
ffffffffc020139e:	97ce                	add	a5,a5,s3
ffffffffc02013a0:	1369f363          	bleu	s6,s3,ffffffffc02014c6 <exit_range+0x1c2>
ffffffffc02013a4:	89be                	mv	s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02013a6:	00698933          	add	s2,s3,t1
ffffffffc02013aa:	01e95913          	srli	s2,s2,0x1e
ffffffffc02013ae:	1ff97913          	andi	s2,s2,511
ffffffffc02013b2:	090e                	slli	s2,s2,0x3
ffffffffc02013b4:	9972                	add	s2,s2,t3
ffffffffc02013b6:	00093b83          	ld	s7,0(s2)
        if (pde1&PTE_V){
ffffffffc02013ba:	001bf793          	andi	a5,s7,1
ffffffffc02013be:	dbf9                	beqz	a5,ffffffffc0201394 <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc02013c0:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02013c4:	0b8a                	slli	s7,s7,0x2
ffffffffc02013c6:	00cbdb93          	srli	s7,s7,0xc
    if (PPN(pa) >= npage) {
ffffffffc02013ca:	14fbfc63          	bleu	a5,s7,ffffffffc0201522 <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc02013ce:	fff80ab7          	lui	s5,0xfff80
ffffffffc02013d2:	9ade                	add	s5,s5,s7
    return page - pages + nbase;
ffffffffc02013d4:	000806b7          	lui	a3,0x80
ffffffffc02013d8:	96d6                	add	a3,a3,s5
ffffffffc02013da:	006a9593          	slli	a1,s5,0x6
    return KADDR(page2pa(page));
ffffffffc02013de:	01b6f633          	and	a2,a3,s11
    return page - pages + nbase;
ffffffffc02013e2:	e42e                	sd	a1,8(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc02013e4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02013e6:	12f67263          	bleu	a5,a2,ffffffffc020150a <exit_range+0x206>
ffffffffc02013ea:	00073a03          	ld	s4,0(a4)
            free_pd0 = 1;
ffffffffc02013ee:	4c85                	li	s9,1
    return &pages[PPN(pa) - nbase];
ffffffffc02013f0:	fff808b7          	lui	a7,0xfff80
    return KADDR(page2pa(page));
ffffffffc02013f4:	9a36                	add	s4,s4,a3
    return page - pages + nbase;
ffffffffc02013f6:	00080837          	lui	a6,0x80
ffffffffc02013fa:	6a85                	lui	s5,0x1
                d0start += PTSIZE;
ffffffffc02013fc:	00200c37          	lui	s8,0x200
ffffffffc0201400:	a801                	j	ffffffffc0201410 <exit_range+0x10c>
                    free_pd0 = 0;
ffffffffc0201402:	4c81                	li	s9,0
                d0start += PTSIZE;
ffffffffc0201404:	94e2                	add	s1,s1,s8
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0201406:	c0d9                	beqz	s1,ffffffffc020148c <exit_range+0x188>
ffffffffc0201408:	0934f263          	bleu	s3,s1,ffffffffc020148c <exit_range+0x188>
ffffffffc020140c:	0d64fc63          	bleu	s6,s1,ffffffffc02014e4 <exit_range+0x1e0>
                pde0 = pd0[PDX0(d0start)];
ffffffffc0201410:	0154d413          	srli	s0,s1,0x15
ffffffffc0201414:	1ff47413          	andi	s0,s0,511
ffffffffc0201418:	040e                	slli	s0,s0,0x3
ffffffffc020141a:	9452                	add	s0,s0,s4
ffffffffc020141c:	601c                	ld	a5,0(s0)
                if (pde0&PTE_V) {
ffffffffc020141e:	0017f693          	andi	a3,a5,1
ffffffffc0201422:	d2e5                	beqz	a3,ffffffffc0201402 <exit_range+0xfe>
    if (PPN(pa) >= npage) {
ffffffffc0201424:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201428:	00279513          	slli	a0,a5,0x2
ffffffffc020142c:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc020142e:	0eb57a63          	bleu	a1,a0,ffffffffc0201522 <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201432:	9546                	add	a0,a0,a7
    return page - pages + nbase;
ffffffffc0201434:	010506b3          	add	a3,a0,a6
    return KADDR(page2pa(page));
ffffffffc0201438:	01b6f7b3          	and	a5,a3,s11
    return page - pages + nbase;
ffffffffc020143c:	051a                	slli	a0,a0,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020143e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201440:	0cb7f563          	bleu	a1,a5,ffffffffc020150a <exit_range+0x206>
ffffffffc0201444:	631c                	ld	a5,0(a4)
ffffffffc0201446:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc0201448:	015685b3          	add	a1,a3,s5
                        if (pt[i]&PTE_V){
ffffffffc020144c:	629c                	ld	a5,0(a3)
ffffffffc020144e:	8b85                	andi	a5,a5,1
ffffffffc0201450:	fbd5                	bnez	a5,ffffffffc0201404 <exit_range+0x100>
ffffffffc0201452:	06a1                	addi	a3,a3,8
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc0201454:	fed59ce3          	bne	a1,a3,ffffffffc020144c <exit_range+0x148>
    return &pages[PPN(pa) - nbase];
ffffffffc0201458:	000eb783          	ld	a5,0(t4)
                        free_page(pde2page(pde0));
ffffffffc020145c:	4585                	li	a1,1
ffffffffc020145e:	e072                	sd	t3,0(sp)
ffffffffc0201460:	953e                	add	a0,a0,a5
ffffffffc0201462:	ad1ff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
                d0start += PTSIZE;
ffffffffc0201466:	94e2                	add	s1,s1,s8
                        pd0[PDX0(d0start)] = 0;
ffffffffc0201468:	00043023          	sd	zero,0(s0)
ffffffffc020146c:	000abe97          	auipc	t4,0xab
ffffffffc0201470:	fc4e8e93          	addi	t4,t4,-60 # ffffffffc02ac430 <pages>
ffffffffc0201474:	6e02                	ld	t3,0(sp)
ffffffffc0201476:	c0000337          	lui	t1,0xc0000
ffffffffc020147a:	fff808b7          	lui	a7,0xfff80
ffffffffc020147e:	00080837          	lui	a6,0x80
ffffffffc0201482:	000ab717          	auipc	a4,0xab
ffffffffc0201486:	f9e70713          	addi	a4,a4,-98 # ffffffffc02ac420 <va_pa_offset>
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc020148a:	fcbd                	bnez	s1,ffffffffc0201408 <exit_range+0x104>
            if (free_pd0) {
ffffffffc020148c:	f00c84e3          	beqz	s9,ffffffffc0201394 <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0201490:	000d3783          	ld	a5,0(s10)
ffffffffc0201494:	e072                	sd	t3,0(sp)
ffffffffc0201496:	08fbf663          	bleu	a5,s7,ffffffffc0201522 <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc020149a:	000eb503          	ld	a0,0(t4)
                free_page(pde2page(pde1));
ffffffffc020149e:	67a2                	ld	a5,8(sp)
ffffffffc02014a0:	4585                	li	a1,1
ffffffffc02014a2:	953e                	add	a0,a0,a5
ffffffffc02014a4:	a8fff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02014a8:	00093023          	sd	zero,0(s2)
ffffffffc02014ac:	000ab717          	auipc	a4,0xab
ffffffffc02014b0:	f7470713          	addi	a4,a4,-140 # ffffffffc02ac420 <va_pa_offset>
ffffffffc02014b4:	c0000337          	lui	t1,0xc0000
ffffffffc02014b8:	6e02                	ld	t3,0(sp)
ffffffffc02014ba:	000abe97          	auipc	t4,0xab
ffffffffc02014be:	f76e8e93          	addi	t4,t4,-138 # ffffffffc02ac430 <pages>
    } while (d1start != 0 && d1start < end);
ffffffffc02014c2:	ec099be3          	bnez	s3,ffffffffc0201398 <exit_range+0x94>
}
ffffffffc02014c6:	70e6                	ld	ra,120(sp)
ffffffffc02014c8:	7446                	ld	s0,112(sp)
ffffffffc02014ca:	74a6                	ld	s1,104(sp)
ffffffffc02014cc:	7906                	ld	s2,96(sp)
ffffffffc02014ce:	69e6                	ld	s3,88(sp)
ffffffffc02014d0:	6a46                	ld	s4,80(sp)
ffffffffc02014d2:	6aa6                	ld	s5,72(sp)
ffffffffc02014d4:	6b06                	ld	s6,64(sp)
ffffffffc02014d6:	7be2                	ld	s7,56(sp)
ffffffffc02014d8:	7c42                	ld	s8,48(sp)
ffffffffc02014da:	7ca2                	ld	s9,40(sp)
ffffffffc02014dc:	7d02                	ld	s10,32(sp)
ffffffffc02014de:	6de2                	ld	s11,24(sp)
ffffffffc02014e0:	6109                	addi	sp,sp,128
ffffffffc02014e2:	8082                	ret
            if (free_pd0) {
ffffffffc02014e4:	ea0c8ae3          	beqz	s9,ffffffffc0201398 <exit_range+0x94>
ffffffffc02014e8:	b765                	j	ffffffffc0201490 <exit_range+0x18c>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02014ea:	00006697          	auipc	a3,0x6
ffffffffc02014ee:	34668693          	addi	a3,a3,838 # ffffffffc0207830 <commands+0xec8>
ffffffffc02014f2:	00006617          	auipc	a2,0x6
ffffffffc02014f6:	90e60613          	addi	a2,a2,-1778 # ffffffffc0206e00 <commands+0x498>
ffffffffc02014fa:	12000593          	li	a1,288
ffffffffc02014fe:	00006517          	auipc	a0,0x6
ffffffffc0201502:	d6250513          	addi	a0,a0,-670 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201506:	d11fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    return KADDR(page2pa(page));
ffffffffc020150a:	00006617          	auipc	a2,0x6
ffffffffc020150e:	d2e60613          	addi	a2,a2,-722 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0201512:	06900593          	li	a1,105
ffffffffc0201516:	00006517          	auipc	a0,0x6
ffffffffc020151a:	d7a50513          	addi	a0,a0,-646 # ffffffffc0207290 <commands+0x928>
ffffffffc020151e:	cf9fe0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201522:	00006617          	auipc	a2,0x6
ffffffffc0201526:	d4e60613          	addi	a2,a2,-690 # ffffffffc0207270 <commands+0x908>
ffffffffc020152a:	06200593          	li	a1,98
ffffffffc020152e:	00006517          	auipc	a0,0x6
ffffffffc0201532:	d6250513          	addi	a0,a0,-670 # ffffffffc0207290 <commands+0x928>
ffffffffc0201536:	ce1fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020153a:	00006697          	auipc	a3,0x6
ffffffffc020153e:	32668693          	addi	a3,a3,806 # ffffffffc0207860 <commands+0xef8>
ffffffffc0201542:	00006617          	auipc	a2,0x6
ffffffffc0201546:	8be60613          	addi	a2,a2,-1858 # ffffffffc0206e00 <commands+0x498>
ffffffffc020154a:	12100593          	li	a1,289
ffffffffc020154e:	00006517          	auipc	a0,0x6
ffffffffc0201552:	d1250513          	addi	a0,a0,-750 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201556:	cc1fe0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020155a <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc020155a:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020155c:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc020155e:	e426                	sd	s1,8(sp)
ffffffffc0201560:	ec06                	sd	ra,24(sp)
ffffffffc0201562:	e822                	sd	s0,16(sp)
ffffffffc0201564:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201566:	a53ff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
    if (ptep != NULL) {
ffffffffc020156a:	c511                	beqz	a0,ffffffffc0201576 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc020156c:	611c                	ld	a5,0(a0)
ffffffffc020156e:	842a                	mv	s0,a0
ffffffffc0201570:	0017f713          	andi	a4,a5,1
ffffffffc0201574:	e711                	bnez	a4,ffffffffc0201580 <page_remove+0x26>
}
ffffffffc0201576:	60e2                	ld	ra,24(sp)
ffffffffc0201578:	6442                	ld	s0,16(sp)
ffffffffc020157a:	64a2                	ld	s1,8(sp)
ffffffffc020157c:	6105                	addi	sp,sp,32
ffffffffc020157e:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201580:	000ab717          	auipc	a4,0xab
ffffffffc0201584:	e4870713          	addi	a4,a4,-440 # ffffffffc02ac3c8 <npage>
ffffffffc0201588:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc020158a:	078a                	slli	a5,a5,0x2
ffffffffc020158c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020158e:	02e7fe63          	bleu	a4,a5,ffffffffc02015ca <page_remove+0x70>
    return &pages[PPN(pa) - nbase];
ffffffffc0201592:	000ab717          	auipc	a4,0xab
ffffffffc0201596:	e9e70713          	addi	a4,a4,-354 # ffffffffc02ac430 <pages>
ffffffffc020159a:	6308                	ld	a0,0(a4)
ffffffffc020159c:	fff80737          	lui	a4,0xfff80
ffffffffc02015a0:	97ba                	add	a5,a5,a4
ffffffffc02015a2:	079a                	slli	a5,a5,0x6
ffffffffc02015a4:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02015a6:	411c                	lw	a5,0(a0)
ffffffffc02015a8:	fff7871b          	addiw	a4,a5,-1
ffffffffc02015ac:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02015ae:	cb11                	beqz	a4,ffffffffc02015c2 <page_remove+0x68>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc02015b0:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02015b4:	12048073          	sfence.vma	s1
}
ffffffffc02015b8:	60e2                	ld	ra,24(sp)
ffffffffc02015ba:	6442                	ld	s0,16(sp)
ffffffffc02015bc:	64a2                	ld	s1,8(sp)
ffffffffc02015be:	6105                	addi	sp,sp,32
ffffffffc02015c0:	8082                	ret
            free_page(page);
ffffffffc02015c2:	4585                	li	a1,1
ffffffffc02015c4:	96fff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
ffffffffc02015c8:	b7e5                	j	ffffffffc02015b0 <page_remove+0x56>
ffffffffc02015ca:	8c5ff0ef          	jal	ra,ffffffffc0200e8e <pa2page.part.4>

ffffffffc02015ce <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02015ce:	7179                	addi	sp,sp,-48
ffffffffc02015d0:	e44e                	sd	s3,8(sp)
ffffffffc02015d2:	89b2                	mv	s3,a2
ffffffffc02015d4:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02015d6:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02015d8:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02015da:	85ce                	mv	a1,s3
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02015dc:	ec26                	sd	s1,24(sp)
ffffffffc02015de:	f406                	sd	ra,40(sp)
ffffffffc02015e0:	e84a                	sd	s2,16(sp)
ffffffffc02015e2:	e052                	sd	s4,0(sp)
ffffffffc02015e4:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02015e6:	9d3ff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
    if (ptep == NULL) {
ffffffffc02015ea:	cd49                	beqz	a0,ffffffffc0201684 <page_insert+0xb6>
    page->ref += 1;
ffffffffc02015ec:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc02015ee:	611c                	ld	a5,0(a0)
ffffffffc02015f0:	892a                	mv	s2,a0
ffffffffc02015f2:	0016871b          	addiw	a4,a3,1
ffffffffc02015f6:	c018                	sw	a4,0(s0)
ffffffffc02015f8:	0017f713          	andi	a4,a5,1
ffffffffc02015fc:	ef05                	bnez	a4,ffffffffc0201634 <page_insert+0x66>
ffffffffc02015fe:	000ab797          	auipc	a5,0xab
ffffffffc0201602:	e3278793          	addi	a5,a5,-462 # ffffffffc02ac430 <pages>
ffffffffc0201606:	6398                	ld	a4,0(a5)
    return page - pages + nbase;
ffffffffc0201608:	8c19                	sub	s0,s0,a4
ffffffffc020160a:	000806b7          	lui	a3,0x80
ffffffffc020160e:	8419                	srai	s0,s0,0x6
ffffffffc0201610:	9436                	add	s0,s0,a3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201612:	042a                	slli	s0,s0,0xa
ffffffffc0201614:	8c45                	or	s0,s0,s1
ffffffffc0201616:	00146413          	ori	s0,s0,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020161a:	00893023          	sd	s0,0(s2)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020161e:	12098073          	sfence.vma	s3
    return 0;
ffffffffc0201622:	4501                	li	a0,0
}
ffffffffc0201624:	70a2                	ld	ra,40(sp)
ffffffffc0201626:	7402                	ld	s0,32(sp)
ffffffffc0201628:	64e2                	ld	s1,24(sp)
ffffffffc020162a:	6942                	ld	s2,16(sp)
ffffffffc020162c:	69a2                	ld	s3,8(sp)
ffffffffc020162e:	6a02                	ld	s4,0(sp)
ffffffffc0201630:	6145                	addi	sp,sp,48
ffffffffc0201632:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201634:	000ab717          	auipc	a4,0xab
ffffffffc0201638:	d9470713          	addi	a4,a4,-620 # ffffffffc02ac3c8 <npage>
ffffffffc020163c:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc020163e:	078a                	slli	a5,a5,0x2
ffffffffc0201640:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201642:	04e7f363          	bleu	a4,a5,ffffffffc0201688 <page_insert+0xba>
    return &pages[PPN(pa) - nbase];
ffffffffc0201646:	000aba17          	auipc	s4,0xab
ffffffffc020164a:	deaa0a13          	addi	s4,s4,-534 # ffffffffc02ac430 <pages>
ffffffffc020164e:	000a3703          	ld	a4,0(s4)
ffffffffc0201652:	fff80537          	lui	a0,0xfff80
ffffffffc0201656:	953e                	add	a0,a0,a5
ffffffffc0201658:	051a                	slli	a0,a0,0x6
ffffffffc020165a:	953a                	add	a0,a0,a4
        if (p == page) {
ffffffffc020165c:	00a40a63          	beq	s0,a0,ffffffffc0201670 <page_insert+0xa2>
    page->ref -= 1;
ffffffffc0201660:	411c                	lw	a5,0(a0)
ffffffffc0201662:	fff7869b          	addiw	a3,a5,-1
ffffffffc0201666:	c114                	sw	a3,0(a0)
        if (page_ref(page) ==
ffffffffc0201668:	c691                	beqz	a3,ffffffffc0201674 <page_insert+0xa6>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020166a:	12098073          	sfence.vma	s3
ffffffffc020166e:	bf69                	j	ffffffffc0201608 <page_insert+0x3a>
ffffffffc0201670:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201672:	bf59                	j	ffffffffc0201608 <page_insert+0x3a>
            free_page(page);
ffffffffc0201674:	4585                	li	a1,1
ffffffffc0201676:	8bdff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
ffffffffc020167a:	000a3703          	ld	a4,0(s4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020167e:	12098073          	sfence.vma	s3
ffffffffc0201682:	b759                	j	ffffffffc0201608 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0201684:	5571                	li	a0,-4
ffffffffc0201686:	bf79                	j	ffffffffc0201624 <page_insert+0x56>
ffffffffc0201688:	807ff0ef          	jal	ra,ffffffffc0200e8e <pa2page.part.4>

ffffffffc020168c <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020168c:	00007797          	auipc	a5,0x7
ffffffffc0201690:	f2478793          	addi	a5,a5,-220 # ffffffffc02085b0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201694:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201696:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201698:	00006517          	auipc	a0,0x6
ffffffffc020169c:	c2050513          	addi	a0,a0,-992 # ffffffffc02072b8 <commands+0x950>
void pmm_init(void) {
ffffffffc02016a0:	e486                	sd	ra,72(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02016a2:	000ab717          	auipc	a4,0xab
ffffffffc02016a6:	d6f73b23          	sd	a5,-650(a4) # ffffffffc02ac418 <pmm_manager>
void pmm_init(void) {
ffffffffc02016aa:	e0a2                	sd	s0,64(sp)
ffffffffc02016ac:	fc26                	sd	s1,56(sp)
ffffffffc02016ae:	f84a                	sd	s2,48(sp)
ffffffffc02016b0:	f44e                	sd	s3,40(sp)
ffffffffc02016b2:	f052                	sd	s4,32(sp)
ffffffffc02016b4:	ec56                	sd	s5,24(sp)
ffffffffc02016b6:	e85a                	sd	s6,16(sp)
ffffffffc02016b8:	e45e                	sd	s7,8(sp)
ffffffffc02016ba:	e062                	sd	s8,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02016bc:	000ab417          	auipc	s0,0xab
ffffffffc02016c0:	d5c40413          	addi	s0,s0,-676 # ffffffffc02ac418 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02016c4:	a0dfe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    pmm_manager->init();
ffffffffc02016c8:	601c                	ld	a5,0(s0)
ffffffffc02016ca:	000ab497          	auipc	s1,0xab
ffffffffc02016ce:	cfe48493          	addi	s1,s1,-770 # ffffffffc02ac3c8 <npage>
ffffffffc02016d2:	000ab917          	auipc	s2,0xab
ffffffffc02016d6:	d5e90913          	addi	s2,s2,-674 # ffffffffc02ac430 <pages>
ffffffffc02016da:	679c                	ld	a5,8(a5)
ffffffffc02016dc:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02016de:	57f5                	li	a5,-3
ffffffffc02016e0:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02016e2:	00006517          	auipc	a0,0x6
ffffffffc02016e6:	bee50513          	addi	a0,a0,-1042 # ffffffffc02072d0 <commands+0x968>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02016ea:	000ab717          	auipc	a4,0xab
ffffffffc02016ee:	d2f73b23          	sd	a5,-714(a4) # ffffffffc02ac420 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc02016f2:	9dffe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02016f6:	46c5                	li	a3,17
ffffffffc02016f8:	06ee                	slli	a3,a3,0x1b
ffffffffc02016fa:	40100613          	li	a2,1025
ffffffffc02016fe:	16fd                	addi	a3,a3,-1
ffffffffc0201700:	0656                	slli	a2,a2,0x15
ffffffffc0201702:	07e005b7          	lui	a1,0x7e00
ffffffffc0201706:	00006517          	auipc	a0,0x6
ffffffffc020170a:	be250513          	addi	a0,a0,-1054 # ffffffffc02072e8 <commands+0x980>
ffffffffc020170e:	9c3fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201712:	777d                	lui	a4,0xfffff
ffffffffc0201714:	000ac797          	auipc	a5,0xac
ffffffffc0201718:	e2b78793          	addi	a5,a5,-469 # ffffffffc02ad53f <end+0xfff>
ffffffffc020171c:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020171e:	00088737          	lui	a4,0x88
ffffffffc0201722:	000ab697          	auipc	a3,0xab
ffffffffc0201726:	cae6b323          	sd	a4,-858(a3) # ffffffffc02ac3c8 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020172a:	000ab717          	auipc	a4,0xab
ffffffffc020172e:	d0f73323          	sd	a5,-762(a4) # ffffffffc02ac430 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201732:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201734:	4685                	li	a3,1
ffffffffc0201736:	fff80837          	lui	a6,0xfff80
ffffffffc020173a:	a019                	j	ffffffffc0201740 <pmm_init+0xb4>
ffffffffc020173c:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc0201740:	00671613          	slli	a2,a4,0x6
ffffffffc0201744:	97b2                	add	a5,a5,a2
ffffffffc0201746:	07a1                	addi	a5,a5,8
ffffffffc0201748:	40d7b02f          	amoor.d	zero,a3,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020174c:	6090                	ld	a2,0(s1)
ffffffffc020174e:	0705                	addi	a4,a4,1
ffffffffc0201750:	010607b3          	add	a5,a2,a6
ffffffffc0201754:	fef764e3          	bltu	a4,a5,ffffffffc020173c <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201758:	00093503          	ld	a0,0(s2)
ffffffffc020175c:	fe0007b7          	lui	a5,0xfe000
ffffffffc0201760:	00661693          	slli	a3,a2,0x6
ffffffffc0201764:	97aa                	add	a5,a5,a0
ffffffffc0201766:	96be                	add	a3,a3,a5
ffffffffc0201768:	c02007b7          	lui	a5,0xc0200
ffffffffc020176c:	7af6ed63          	bltu	a3,a5,ffffffffc0201f26 <pmm_init+0x89a>
ffffffffc0201770:	000ab997          	auipc	s3,0xab
ffffffffc0201774:	cb098993          	addi	s3,s3,-848 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0201778:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc020177c:	47c5                	li	a5,17
ffffffffc020177e:	07ee                	slli	a5,a5,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201780:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc0201782:	02f6f763          	bleu	a5,a3,ffffffffc02017b0 <pmm_init+0x124>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201786:	6585                	lui	a1,0x1
ffffffffc0201788:	15fd                	addi	a1,a1,-1
ffffffffc020178a:	96ae                	add	a3,a3,a1
    if (PPN(pa) >= npage) {
ffffffffc020178c:	00c6d713          	srli	a4,a3,0xc
ffffffffc0201790:	48c77a63          	bleu	a2,a4,ffffffffc0201c24 <pmm_init+0x598>
    pmm_manager->init_memmap(base, n);
ffffffffc0201794:	6010                	ld	a2,0(s0)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201796:	75fd                	lui	a1,0xfffff
ffffffffc0201798:	8eed                	and	a3,a3,a1
    return &pages[PPN(pa) - nbase];
ffffffffc020179a:	9742                	add	a4,a4,a6
    pmm_manager->init_memmap(base, n);
ffffffffc020179c:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020179e:	40d786b3          	sub	a3,a5,a3
ffffffffc02017a2:	071a                	slli	a4,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc02017a4:	00c6d593          	srli	a1,a3,0xc
ffffffffc02017a8:	953a                	add	a0,a0,a4
ffffffffc02017aa:	9602                	jalr	a2
ffffffffc02017ac:	0009b583          	ld	a1,0(s3)
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc02017b0:	00006517          	auipc	a0,0x6
ffffffffc02017b4:	b8850513          	addi	a0,a0,-1144 # ffffffffc0207338 <commands+0x9d0>
ffffffffc02017b8:	919fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02017bc:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02017be:	000ab417          	auipc	s0,0xab
ffffffffc02017c2:	c0240413          	addi	s0,s0,-1022 # ffffffffc02ac3c0 <boot_pgdir>
    pmm_manager->check();
ffffffffc02017c6:	7b9c                	ld	a5,48(a5)
ffffffffc02017c8:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02017ca:	00006517          	auipc	a0,0x6
ffffffffc02017ce:	b8650513          	addi	a0,a0,-1146 # ffffffffc0207350 <commands+0x9e8>
ffffffffc02017d2:	8fffe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02017d6:	0000a697          	auipc	a3,0xa
ffffffffc02017da:	82a68693          	addi	a3,a3,-2006 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc02017de:	000ab797          	auipc	a5,0xab
ffffffffc02017e2:	bed7b123          	sd	a3,-1054(a5) # ffffffffc02ac3c0 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02017e6:	c02007b7          	lui	a5,0xc0200
ffffffffc02017ea:	10f6eae3          	bltu	a3,a5,ffffffffc02020fe <pmm_init+0xa72>
ffffffffc02017ee:	0009b783          	ld	a5,0(s3)
ffffffffc02017f2:	8e9d                	sub	a3,a3,a5
ffffffffc02017f4:	000ab797          	auipc	a5,0xab
ffffffffc02017f8:	c2d7ba23          	sd	a3,-972(a5) # ffffffffc02ac428 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc02017fc:	f7cff0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201800:	6098                	ld	a4,0(s1)
ffffffffc0201802:	c80007b7          	lui	a5,0xc8000
ffffffffc0201806:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc0201808:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020180a:	0ce7eae3          	bltu	a5,a4,ffffffffc02020de <pmm_init+0xa52>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc020180e:	6008                	ld	a0,0(s0)
ffffffffc0201810:	44050463          	beqz	a0,ffffffffc0201c58 <pmm_init+0x5cc>
ffffffffc0201814:	6785                	lui	a5,0x1
ffffffffc0201816:	17fd                	addi	a5,a5,-1
ffffffffc0201818:	8fe9                	and	a5,a5,a0
ffffffffc020181a:	2781                	sext.w	a5,a5
ffffffffc020181c:	42079e63          	bnez	a5,ffffffffc0201c58 <pmm_init+0x5cc>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201820:	4601                	li	a2,0
ffffffffc0201822:	4581                	li	a1,0
ffffffffc0201824:	967ff0ef          	jal	ra,ffffffffc020118a <get_page>
ffffffffc0201828:	78051b63          	bnez	a0,ffffffffc0201fbe <pmm_init+0x932>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc020182c:	4505                	li	a0,1
ffffffffc020182e:	e7cff0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0201832:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201834:	6008                	ld	a0,0(s0)
ffffffffc0201836:	4681                	li	a3,0
ffffffffc0201838:	4601                	li	a2,0
ffffffffc020183a:	85d6                	mv	a1,s5
ffffffffc020183c:	d93ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
ffffffffc0201840:	7a051f63          	bnez	a0,ffffffffc0201ffe <pmm_init+0x972>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201844:	6008                	ld	a0,0(s0)
ffffffffc0201846:	4601                	li	a2,0
ffffffffc0201848:	4581                	li	a1,0
ffffffffc020184a:	f6eff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc020184e:	78050863          	beqz	a0,ffffffffc0201fde <pmm_init+0x952>
    assert(pte2page(*ptep) == p1);
ffffffffc0201852:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201854:	0017f713          	andi	a4,a5,1
ffffffffc0201858:	3e070463          	beqz	a4,ffffffffc0201c40 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc020185c:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020185e:	078a                	slli	a5,a5,0x2
ffffffffc0201860:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201862:	3ce7f163          	bleu	a4,a5,ffffffffc0201c24 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0201866:	00093683          	ld	a3,0(s2)
ffffffffc020186a:	fff80637          	lui	a2,0xfff80
ffffffffc020186e:	97b2                	add	a5,a5,a2
ffffffffc0201870:	079a                	slli	a5,a5,0x6
ffffffffc0201872:	97b6                	add	a5,a5,a3
ffffffffc0201874:	72fa9563          	bne	s5,a5,ffffffffc0201f9e <pmm_init+0x912>
    assert(page_ref(p1) == 1);
ffffffffc0201878:	000aab83          	lw	s7,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc020187c:	4785                	li	a5,1
ffffffffc020187e:	70fb9063          	bne	s7,a5,ffffffffc0201f7e <pmm_init+0x8f2>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201882:	6008                	ld	a0,0(s0)
ffffffffc0201884:	76fd                	lui	a3,0xfffff
ffffffffc0201886:	611c                	ld	a5,0(a0)
ffffffffc0201888:	078a                	slli	a5,a5,0x2
ffffffffc020188a:	8ff5                	and	a5,a5,a3
ffffffffc020188c:	00c7d613          	srli	a2,a5,0xc
ffffffffc0201890:	66e67e63          	bleu	a4,a2,ffffffffc0201f0c <pmm_init+0x880>
ffffffffc0201894:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201898:	97e2                	add	a5,a5,s8
ffffffffc020189a:	0007bb03          	ld	s6,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc020189e:	0b0a                	slli	s6,s6,0x2
ffffffffc02018a0:	00db7b33          	and	s6,s6,a3
ffffffffc02018a4:	00cb5793          	srli	a5,s6,0xc
ffffffffc02018a8:	56e7f863          	bleu	a4,a5,ffffffffc0201e18 <pmm_init+0x78c>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02018ac:	4601                	li	a2,0
ffffffffc02018ae:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02018b0:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02018b2:	f06ff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02018b6:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02018b8:	55651063          	bne	a0,s6,ffffffffc0201df8 <pmm_init+0x76c>

    p2 = alloc_page();
ffffffffc02018bc:	4505                	li	a0,1
ffffffffc02018be:	decff0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc02018c2:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02018c4:	6008                	ld	a0,0(s0)
ffffffffc02018c6:	46d1                	li	a3,20
ffffffffc02018c8:	6605                	lui	a2,0x1
ffffffffc02018ca:	85da                	mv	a1,s6
ffffffffc02018cc:	d03ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
ffffffffc02018d0:	50051463          	bnez	a0,ffffffffc0201dd8 <pmm_init+0x74c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02018d4:	6008                	ld	a0,0(s0)
ffffffffc02018d6:	4601                	li	a2,0
ffffffffc02018d8:	6585                	lui	a1,0x1
ffffffffc02018da:	edeff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc02018de:	4c050d63          	beqz	a0,ffffffffc0201db8 <pmm_init+0x72c>
    assert(*ptep & PTE_U);
ffffffffc02018e2:	611c                	ld	a5,0(a0)
ffffffffc02018e4:	0107f713          	andi	a4,a5,16
ffffffffc02018e8:	4a070863          	beqz	a4,ffffffffc0201d98 <pmm_init+0x70c>
    assert(*ptep & PTE_W);
ffffffffc02018ec:	8b91                	andi	a5,a5,4
ffffffffc02018ee:	48078563          	beqz	a5,ffffffffc0201d78 <pmm_init+0x6ec>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02018f2:	6008                	ld	a0,0(s0)
ffffffffc02018f4:	611c                	ld	a5,0(a0)
ffffffffc02018f6:	8bc1                	andi	a5,a5,16
ffffffffc02018f8:	46078063          	beqz	a5,ffffffffc0201d58 <pmm_init+0x6cc>
    assert(page_ref(p2) == 1);
ffffffffc02018fc:	000b2783          	lw	a5,0(s6) # 200000 <_binary_obj___user_exit_out_size+0x1f5590>
ffffffffc0201900:	43779c63          	bne	a5,s7,ffffffffc0201d38 <pmm_init+0x6ac>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201904:	4681                	li	a3,0
ffffffffc0201906:	6605                	lui	a2,0x1
ffffffffc0201908:	85d6                	mv	a1,s5
ffffffffc020190a:	cc5ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
ffffffffc020190e:	40051563          	bnez	a0,ffffffffc0201d18 <pmm_init+0x68c>
    assert(page_ref(p1) == 2);
ffffffffc0201912:	000aa703          	lw	a4,0(s5)
ffffffffc0201916:	4789                	li	a5,2
ffffffffc0201918:	3ef71063          	bne	a4,a5,ffffffffc0201cf8 <pmm_init+0x66c>
    assert(page_ref(p2) == 0);
ffffffffc020191c:	000b2783          	lw	a5,0(s6)
ffffffffc0201920:	3a079c63          	bnez	a5,ffffffffc0201cd8 <pmm_init+0x64c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201924:	6008                	ld	a0,0(s0)
ffffffffc0201926:	4601                	li	a2,0
ffffffffc0201928:	6585                	lui	a1,0x1
ffffffffc020192a:	e8eff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc020192e:	38050563          	beqz	a0,ffffffffc0201cb8 <pmm_init+0x62c>
    assert(pte2page(*ptep) == p1);
ffffffffc0201932:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201934:	00177793          	andi	a5,a4,1
ffffffffc0201938:	30078463          	beqz	a5,ffffffffc0201c40 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc020193c:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020193e:	00271793          	slli	a5,a4,0x2
ffffffffc0201942:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201944:	2ed7f063          	bleu	a3,a5,ffffffffc0201c24 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0201948:	00093683          	ld	a3,0(s2)
ffffffffc020194c:	fff80637          	lui	a2,0xfff80
ffffffffc0201950:	97b2                	add	a5,a5,a2
ffffffffc0201952:	079a                	slli	a5,a5,0x6
ffffffffc0201954:	97b6                	add	a5,a5,a3
ffffffffc0201956:	32fa9163          	bne	s5,a5,ffffffffc0201c78 <pmm_init+0x5ec>
    assert((*ptep & PTE_U) == 0);
ffffffffc020195a:	8b41                	andi	a4,a4,16
ffffffffc020195c:	70071163          	bnez	a4,ffffffffc020205e <pmm_init+0x9d2>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201960:	6008                	ld	a0,0(s0)
ffffffffc0201962:	4581                	li	a1,0
ffffffffc0201964:	bf7ff0ef          	jal	ra,ffffffffc020155a <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201968:	000aa703          	lw	a4,0(s5)
ffffffffc020196c:	4785                	li	a5,1
ffffffffc020196e:	6cf71863          	bne	a4,a5,ffffffffc020203e <pmm_init+0x9b2>
    assert(page_ref(p2) == 0);
ffffffffc0201972:	000b2783          	lw	a5,0(s6)
ffffffffc0201976:	6a079463          	bnez	a5,ffffffffc020201e <pmm_init+0x992>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc020197a:	6008                	ld	a0,0(s0)
ffffffffc020197c:	6585                	lui	a1,0x1
ffffffffc020197e:	bddff0ef          	jal	ra,ffffffffc020155a <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201982:	000aa783          	lw	a5,0(s5)
ffffffffc0201986:	50079363          	bnez	a5,ffffffffc0201e8c <pmm_init+0x800>
    assert(page_ref(p2) == 0);
ffffffffc020198a:	000b2783          	lw	a5,0(s6)
ffffffffc020198e:	4c079f63          	bnez	a5,ffffffffc0201e6c <pmm_init+0x7e0>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201992:	00043a83          	ld	s5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201996:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201998:	000ab783          	ld	a5,0(s5)
ffffffffc020199c:	078a                	slli	a5,a5,0x2
ffffffffc020199e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02019a0:	28c7f263          	bleu	a2,a5,ffffffffc0201c24 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02019a4:	fff80737          	lui	a4,0xfff80
ffffffffc02019a8:	00093503          	ld	a0,0(s2)
ffffffffc02019ac:	97ba                	add	a5,a5,a4
ffffffffc02019ae:	079a                	slli	a5,a5,0x6
ffffffffc02019b0:	00f50733          	add	a4,a0,a5
ffffffffc02019b4:	4314                	lw	a3,0(a4)
ffffffffc02019b6:	4705                	li	a4,1
ffffffffc02019b8:	48e69a63          	bne	a3,a4,ffffffffc0201e4c <pmm_init+0x7c0>
    return page - pages + nbase;
ffffffffc02019bc:	8799                	srai	a5,a5,0x6
ffffffffc02019be:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc02019c2:	577d                	li	a4,-1
    return page - pages + nbase;
ffffffffc02019c4:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc02019c6:	8331                	srli	a4,a4,0xc
ffffffffc02019c8:	8f7d                	and	a4,a4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02019ca:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02019cc:	46c77363          	bleu	a2,a4,ffffffffc0201e32 <pmm_init+0x7a6>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02019d0:	0009b683          	ld	a3,0(s3)
ffffffffc02019d4:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc02019d6:	639c                	ld	a5,0(a5)
ffffffffc02019d8:	078a                	slli	a5,a5,0x2
ffffffffc02019da:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02019dc:	24c7f463          	bleu	a2,a5,ffffffffc0201c24 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02019e0:	416787b3          	sub	a5,a5,s6
ffffffffc02019e4:	079a                	slli	a5,a5,0x6
ffffffffc02019e6:	953e                	add	a0,a0,a5
ffffffffc02019e8:	4585                	li	a1,1
ffffffffc02019ea:	d48ff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02019ee:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc02019f2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02019f4:	078a                	slli	a5,a5,0x2
ffffffffc02019f6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02019f8:	22e7f663          	bleu	a4,a5,ffffffffc0201c24 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02019fc:	00093503          	ld	a0,0(s2)
ffffffffc0201a00:	416787b3          	sub	a5,a5,s6
ffffffffc0201a04:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0201a06:	953e                	add	a0,a0,a5
ffffffffc0201a08:	4585                	li	a1,1
ffffffffc0201a0a:	d28ff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0201a0e:	601c                	ld	a5,0(s0)
ffffffffc0201a10:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0201a14:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0201a18:	d60ff0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>
ffffffffc0201a1c:	68aa1163          	bne	s4,a0,ffffffffc020209e <pmm_init+0xa12>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201a20:	00006517          	auipc	a0,0x6
ffffffffc0201a24:	c4050513          	addi	a0,a0,-960 # ffffffffc0207660 <commands+0xcf8>
ffffffffc0201a28:	ea8fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc0201a2c:	d4cff0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201a30:	6098                	ld	a4,0(s1)
ffffffffc0201a32:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc0201a36:	8a2a                	mv	s4,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201a38:	00c71693          	slli	a3,a4,0xc
ffffffffc0201a3c:	18d7f563          	bleu	a3,a5,ffffffffc0201bc6 <pmm_init+0x53a>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201a40:	83b1                	srli	a5,a5,0xc
ffffffffc0201a42:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201a44:	c0200ab7          	lui	s5,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201a48:	1ae7f163          	bleu	a4,a5,ffffffffc0201bea <pmm_init+0x55e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201a4c:	7bfd                	lui	s7,0xfffff
ffffffffc0201a4e:	6b05                	lui	s6,0x1
ffffffffc0201a50:	a029                	j	ffffffffc0201a5a <pmm_init+0x3ce>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201a52:	00cad713          	srli	a4,s5,0xc
ffffffffc0201a56:	18f77a63          	bleu	a5,a4,ffffffffc0201bea <pmm_init+0x55e>
ffffffffc0201a5a:	0009b583          	ld	a1,0(s3)
ffffffffc0201a5e:	4601                	li	a2,0
ffffffffc0201a60:	95d6                	add	a1,a1,s5
ffffffffc0201a62:	d56ff0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc0201a66:	16050263          	beqz	a0,ffffffffc0201bca <pmm_init+0x53e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201a6a:	611c                	ld	a5,0(a0)
ffffffffc0201a6c:	078a                	slli	a5,a5,0x2
ffffffffc0201a6e:	0177f7b3          	and	a5,a5,s7
ffffffffc0201a72:	19579963          	bne	a5,s5,ffffffffc0201c04 <pmm_init+0x578>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201a76:	609c                	ld	a5,0(s1)
ffffffffc0201a78:	9ada                	add	s5,s5,s6
ffffffffc0201a7a:	6008                	ld	a0,0(s0)
ffffffffc0201a7c:	00c79713          	slli	a4,a5,0xc
ffffffffc0201a80:	fceae9e3          	bltu	s5,a4,ffffffffc0201a52 <pmm_init+0x3c6>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0201a84:	611c                	ld	a5,0(a0)
ffffffffc0201a86:	62079c63          	bnez	a5,ffffffffc02020be <pmm_init+0xa32>

    struct Page *p;
    p = alloc_page();
ffffffffc0201a8a:	4505                	li	a0,1
ffffffffc0201a8c:	c1eff0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0201a90:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201a92:	6008                	ld	a0,0(s0)
ffffffffc0201a94:	4699                	li	a3,6
ffffffffc0201a96:	10000613          	li	a2,256
ffffffffc0201a9a:	85d6                	mv	a1,s5
ffffffffc0201a9c:	b33ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
ffffffffc0201aa0:	1e051c63          	bnez	a0,ffffffffc0201c98 <pmm_init+0x60c>
    assert(page_ref(p) == 1);
ffffffffc0201aa4:	000aa703          	lw	a4,0(s5) # ffffffffc0200000 <kern_entry>
ffffffffc0201aa8:	4785                	li	a5,1
ffffffffc0201aaa:	44f71163          	bne	a4,a5,ffffffffc0201eec <pmm_init+0x860>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201aae:	6008                	ld	a0,0(s0)
ffffffffc0201ab0:	6b05                	lui	s6,0x1
ffffffffc0201ab2:	4699                	li	a3,6
ffffffffc0201ab4:	100b0613          	addi	a2,s6,256 # 1100 <_binary_obj___user_faultread_out_size-0x8470>
ffffffffc0201ab8:	85d6                	mv	a1,s5
ffffffffc0201aba:	b15ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
ffffffffc0201abe:	40051763          	bnez	a0,ffffffffc0201ecc <pmm_init+0x840>
    assert(page_ref(p) == 2);
ffffffffc0201ac2:	000aa703          	lw	a4,0(s5)
ffffffffc0201ac6:	4789                	li	a5,2
ffffffffc0201ac8:	3ef71263          	bne	a4,a5,ffffffffc0201eac <pmm_init+0x820>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201acc:	00006597          	auipc	a1,0x6
ffffffffc0201ad0:	ccc58593          	addi	a1,a1,-820 # ffffffffc0207798 <commands+0xe30>
ffffffffc0201ad4:	10000513          	li	a0,256
ffffffffc0201ad8:	08b040ef          	jal	ra,ffffffffc0206362 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201adc:	100b0593          	addi	a1,s6,256
ffffffffc0201ae0:	10000513          	li	a0,256
ffffffffc0201ae4:	091040ef          	jal	ra,ffffffffc0206374 <strcmp>
ffffffffc0201ae8:	44051b63          	bnez	a0,ffffffffc0201f3e <pmm_init+0x8b2>
    return page - pages + nbase;
ffffffffc0201aec:	00093683          	ld	a3,0(s2)
ffffffffc0201af0:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0201af4:	5b7d                	li	s6,-1
    return page - pages + nbase;
ffffffffc0201af6:	40da86b3          	sub	a3,s5,a3
ffffffffc0201afa:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201afc:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0201afe:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0201b00:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0201b04:	0166f733          	and	a4,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b08:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201b0a:	10f77f63          	bleu	a5,a4,ffffffffc0201c28 <pmm_init+0x59c>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201b0e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201b12:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201b16:	96be                	add	a3,a3,a5
ffffffffc0201b18:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fd52bc0>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201b1c:	003040ef          	jal	ra,ffffffffc020631e <strlen>
ffffffffc0201b20:	54051f63          	bnez	a0,ffffffffc020207e <pmm_init+0x9f2>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201b24:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201b28:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b2a:	000bb683          	ld	a3,0(s7) # fffffffffffff000 <end+0x3fd52ac0>
ffffffffc0201b2e:	068a                	slli	a3,a3,0x2
ffffffffc0201b30:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201b32:	0ef6f963          	bleu	a5,a3,ffffffffc0201c24 <pmm_init+0x598>
    return KADDR(page2pa(page));
ffffffffc0201b36:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b3a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201b3c:	0efb7663          	bleu	a5,s6,ffffffffc0201c28 <pmm_init+0x59c>
ffffffffc0201b40:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0201b44:	4585                	li	a1,1
ffffffffc0201b46:	8556                	mv	a0,s5
ffffffffc0201b48:	99b6                	add	s3,s3,a3
ffffffffc0201b4a:	be8ff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b4e:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0201b52:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b54:	078a                	slli	a5,a5,0x2
ffffffffc0201b56:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201b58:	0ce7f663          	bleu	a4,a5,ffffffffc0201c24 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b5c:	00093503          	ld	a0,0(s2)
ffffffffc0201b60:	fff809b7          	lui	s3,0xfff80
ffffffffc0201b64:	97ce                	add	a5,a5,s3
ffffffffc0201b66:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0201b68:	953e                	add	a0,a0,a5
ffffffffc0201b6a:	4585                	li	a1,1
ffffffffc0201b6c:	bc6ff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b70:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc0201b74:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201b76:	078a                	slli	a5,a5,0x2
ffffffffc0201b78:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201b7a:	0ae7f563          	bleu	a4,a5,ffffffffc0201c24 <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b7e:	00093503          	ld	a0,0(s2)
ffffffffc0201b82:	97ce                	add	a5,a5,s3
ffffffffc0201b84:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0201b86:	953e                	add	a0,a0,a5
ffffffffc0201b88:	4585                	li	a1,1
ffffffffc0201b8a:	ba8ff0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0201b8e:	601c                	ld	a5,0(s0)
ffffffffc0201b90:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>
  asm volatile("sfence.vma");
ffffffffc0201b94:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0201b98:	be0ff0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>
ffffffffc0201b9c:	3caa1163          	bne	s4,a0,ffffffffc0201f5e <pmm_init+0x8d2>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0201ba0:	00006517          	auipc	a0,0x6
ffffffffc0201ba4:	c7050513          	addi	a0,a0,-912 # ffffffffc0207810 <commands+0xea8>
ffffffffc0201ba8:	d28fe0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc0201bac:	6406                	ld	s0,64(sp)
ffffffffc0201bae:	60a6                	ld	ra,72(sp)
ffffffffc0201bb0:	74e2                	ld	s1,56(sp)
ffffffffc0201bb2:	7942                	ld	s2,48(sp)
ffffffffc0201bb4:	79a2                	ld	s3,40(sp)
ffffffffc0201bb6:	7a02                	ld	s4,32(sp)
ffffffffc0201bb8:	6ae2                	ld	s5,24(sp)
ffffffffc0201bba:	6b42                	ld	s6,16(sp)
ffffffffc0201bbc:	6ba2                	ld	s7,8(sp)
ffffffffc0201bbe:	6c02                	ld	s8,0(sp)
ffffffffc0201bc0:	6161                	addi	sp,sp,80
    kmalloc_init();
ffffffffc0201bc2:	2c70106f          	j	ffffffffc0203688 <kmalloc_init>
ffffffffc0201bc6:	6008                	ld	a0,0(s0)
ffffffffc0201bc8:	bd75                	j	ffffffffc0201a84 <pmm_init+0x3f8>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201bca:	00006697          	auipc	a3,0x6
ffffffffc0201bce:	ab668693          	addi	a3,a3,-1354 # ffffffffc0207680 <commands+0xd18>
ffffffffc0201bd2:	00005617          	auipc	a2,0x5
ffffffffc0201bd6:	22e60613          	addi	a2,a2,558 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201bda:	25800593          	li	a1,600
ffffffffc0201bde:	00005517          	auipc	a0,0x5
ffffffffc0201be2:	68250513          	addi	a0,a0,1666 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201be6:	e30fe0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0201bea:	86d6                	mv	a3,s5
ffffffffc0201bec:	00005617          	auipc	a2,0x5
ffffffffc0201bf0:	64c60613          	addi	a2,a2,1612 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0201bf4:	25800593          	li	a1,600
ffffffffc0201bf8:	00005517          	auipc	a0,0x5
ffffffffc0201bfc:	66850513          	addi	a0,a0,1640 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201c00:	e16fe0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201c04:	00006697          	auipc	a3,0x6
ffffffffc0201c08:	abc68693          	addi	a3,a3,-1348 # ffffffffc02076c0 <commands+0xd58>
ffffffffc0201c0c:	00005617          	auipc	a2,0x5
ffffffffc0201c10:	1f460613          	addi	a2,a2,500 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201c14:	25900593          	li	a1,601
ffffffffc0201c18:	00005517          	auipc	a0,0x5
ffffffffc0201c1c:	64850513          	addi	a0,a0,1608 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201c20:	df6fe0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0201c24:	a6aff0ef          	jal	ra,ffffffffc0200e8e <pa2page.part.4>
    return KADDR(page2pa(page));
ffffffffc0201c28:	00005617          	auipc	a2,0x5
ffffffffc0201c2c:	61060613          	addi	a2,a2,1552 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0201c30:	06900593          	li	a1,105
ffffffffc0201c34:	00005517          	auipc	a0,0x5
ffffffffc0201c38:	65c50513          	addi	a0,a0,1628 # ffffffffc0207290 <commands+0x928>
ffffffffc0201c3c:	ddafe0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0201c40:	00006617          	auipc	a2,0x6
ffffffffc0201c44:	81060613          	addi	a2,a2,-2032 # ffffffffc0207450 <commands+0xae8>
ffffffffc0201c48:	07400593          	li	a1,116
ffffffffc0201c4c:	00005517          	auipc	a0,0x5
ffffffffc0201c50:	64450513          	addi	a0,a0,1604 # ffffffffc0207290 <commands+0x928>
ffffffffc0201c54:	dc2fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201c58:	00005697          	auipc	a3,0x5
ffffffffc0201c5c:	73868693          	addi	a3,a3,1848 # ffffffffc0207390 <commands+0xa28>
ffffffffc0201c60:	00005617          	auipc	a2,0x5
ffffffffc0201c64:	1a060613          	addi	a2,a2,416 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201c68:	21c00593          	li	a1,540
ffffffffc0201c6c:	00005517          	auipc	a0,0x5
ffffffffc0201c70:	5f450513          	addi	a0,a0,1524 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201c74:	da2fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201c78:	00006697          	auipc	a3,0x6
ffffffffc0201c7c:	80068693          	addi	a3,a3,-2048 # ffffffffc0207478 <commands+0xb10>
ffffffffc0201c80:	00005617          	auipc	a2,0x5
ffffffffc0201c84:	18060613          	addi	a2,a2,384 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201c88:	23800593          	li	a1,568
ffffffffc0201c8c:	00005517          	auipc	a0,0x5
ffffffffc0201c90:	5d450513          	addi	a0,a0,1492 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201c94:	d82fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201c98:	00006697          	auipc	a3,0x6
ffffffffc0201c9c:	a5868693          	addi	a3,a3,-1448 # ffffffffc02076f0 <commands+0xd88>
ffffffffc0201ca0:	00005617          	auipc	a2,0x5
ffffffffc0201ca4:	16060613          	addi	a2,a2,352 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201ca8:	26100593          	li	a1,609
ffffffffc0201cac:	00005517          	auipc	a0,0x5
ffffffffc0201cb0:	5b450513          	addi	a0,a0,1460 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201cb4:	d62fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201cb8:	00006697          	auipc	a3,0x6
ffffffffc0201cbc:	85068693          	addi	a3,a3,-1968 # ffffffffc0207508 <commands+0xba0>
ffffffffc0201cc0:	00005617          	auipc	a2,0x5
ffffffffc0201cc4:	14060613          	addi	a2,a2,320 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201cc8:	23700593          	li	a1,567
ffffffffc0201ccc:	00005517          	auipc	a0,0x5
ffffffffc0201cd0:	59450513          	addi	a0,a0,1428 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201cd4:	d42fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201cd8:	00006697          	auipc	a3,0x6
ffffffffc0201cdc:	8f868693          	addi	a3,a3,-1800 # ffffffffc02075d0 <commands+0xc68>
ffffffffc0201ce0:	00005617          	auipc	a2,0x5
ffffffffc0201ce4:	12060613          	addi	a2,a2,288 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201ce8:	23600593          	li	a1,566
ffffffffc0201cec:	00005517          	auipc	a0,0x5
ffffffffc0201cf0:	57450513          	addi	a0,a0,1396 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201cf4:	d22fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0201cf8:	00006697          	auipc	a3,0x6
ffffffffc0201cfc:	8c068693          	addi	a3,a3,-1856 # ffffffffc02075b8 <commands+0xc50>
ffffffffc0201d00:	00005617          	auipc	a2,0x5
ffffffffc0201d04:	10060613          	addi	a2,a2,256 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201d08:	23500593          	li	a1,565
ffffffffc0201d0c:	00005517          	auipc	a0,0x5
ffffffffc0201d10:	55450513          	addi	a0,a0,1364 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201d14:	d02fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201d18:	00006697          	auipc	a3,0x6
ffffffffc0201d1c:	87068693          	addi	a3,a3,-1936 # ffffffffc0207588 <commands+0xc20>
ffffffffc0201d20:	00005617          	auipc	a2,0x5
ffffffffc0201d24:	0e060613          	addi	a2,a2,224 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201d28:	23400593          	li	a1,564
ffffffffc0201d2c:	00005517          	auipc	a0,0x5
ffffffffc0201d30:	53450513          	addi	a0,a0,1332 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201d34:	ce2fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0201d38:	00006697          	auipc	a3,0x6
ffffffffc0201d3c:	83868693          	addi	a3,a3,-1992 # ffffffffc0207570 <commands+0xc08>
ffffffffc0201d40:	00005617          	auipc	a2,0x5
ffffffffc0201d44:	0c060613          	addi	a2,a2,192 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201d48:	23200593          	li	a1,562
ffffffffc0201d4c:	00005517          	auipc	a0,0x5
ffffffffc0201d50:	51450513          	addi	a0,a0,1300 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201d54:	cc2fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201d58:	00006697          	auipc	a3,0x6
ffffffffc0201d5c:	80068693          	addi	a3,a3,-2048 # ffffffffc0207558 <commands+0xbf0>
ffffffffc0201d60:	00005617          	auipc	a2,0x5
ffffffffc0201d64:	0a060613          	addi	a2,a2,160 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201d68:	23100593          	li	a1,561
ffffffffc0201d6c:	00005517          	auipc	a0,0x5
ffffffffc0201d70:	4f450513          	addi	a0,a0,1268 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201d74:	ca2fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0201d78:	00005697          	auipc	a3,0x5
ffffffffc0201d7c:	7d068693          	addi	a3,a3,2000 # ffffffffc0207548 <commands+0xbe0>
ffffffffc0201d80:	00005617          	auipc	a2,0x5
ffffffffc0201d84:	08060613          	addi	a2,a2,128 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201d88:	23000593          	li	a1,560
ffffffffc0201d8c:	00005517          	auipc	a0,0x5
ffffffffc0201d90:	4d450513          	addi	a0,a0,1236 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201d94:	c82fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0201d98:	00005697          	auipc	a3,0x5
ffffffffc0201d9c:	7a068693          	addi	a3,a3,1952 # ffffffffc0207538 <commands+0xbd0>
ffffffffc0201da0:	00005617          	auipc	a2,0x5
ffffffffc0201da4:	06060613          	addi	a2,a2,96 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201da8:	22f00593          	li	a1,559
ffffffffc0201dac:	00005517          	auipc	a0,0x5
ffffffffc0201db0:	4b450513          	addi	a0,a0,1204 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201db4:	c62fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201db8:	00005697          	auipc	a3,0x5
ffffffffc0201dbc:	75068693          	addi	a3,a3,1872 # ffffffffc0207508 <commands+0xba0>
ffffffffc0201dc0:	00005617          	auipc	a2,0x5
ffffffffc0201dc4:	04060613          	addi	a2,a2,64 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201dc8:	22e00593          	li	a1,558
ffffffffc0201dcc:	00005517          	auipc	a0,0x5
ffffffffc0201dd0:	49450513          	addi	a0,a0,1172 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201dd4:	c42fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201dd8:	00005697          	auipc	a3,0x5
ffffffffc0201ddc:	6f868693          	addi	a3,a3,1784 # ffffffffc02074d0 <commands+0xb68>
ffffffffc0201de0:	00005617          	auipc	a2,0x5
ffffffffc0201de4:	02060613          	addi	a2,a2,32 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201de8:	22d00593          	li	a1,557
ffffffffc0201dec:	00005517          	auipc	a0,0x5
ffffffffc0201df0:	47450513          	addi	a0,a0,1140 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201df4:	c22fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201df8:	00005697          	auipc	a3,0x5
ffffffffc0201dfc:	6b068693          	addi	a3,a3,1712 # ffffffffc02074a8 <commands+0xb40>
ffffffffc0201e00:	00005617          	auipc	a2,0x5
ffffffffc0201e04:	00060613          	mv	a2,a2
ffffffffc0201e08:	22a00593          	li	a1,554
ffffffffc0201e0c:	00005517          	auipc	a0,0x5
ffffffffc0201e10:	45450513          	addi	a0,a0,1108 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201e14:	c02fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201e18:	86da                	mv	a3,s6
ffffffffc0201e1a:	00005617          	auipc	a2,0x5
ffffffffc0201e1e:	41e60613          	addi	a2,a2,1054 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0201e22:	22900593          	li	a1,553
ffffffffc0201e26:	00005517          	auipc	a0,0x5
ffffffffc0201e2a:	43a50513          	addi	a0,a0,1082 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201e2e:	be8fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    return KADDR(page2pa(page));
ffffffffc0201e32:	86be                	mv	a3,a5
ffffffffc0201e34:	00005617          	auipc	a2,0x5
ffffffffc0201e38:	40460613          	addi	a2,a2,1028 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0201e3c:	06900593          	li	a1,105
ffffffffc0201e40:	00005517          	auipc	a0,0x5
ffffffffc0201e44:	45050513          	addi	a0,a0,1104 # ffffffffc0207290 <commands+0x928>
ffffffffc0201e48:	bcefe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201e4c:	00005697          	auipc	a3,0x5
ffffffffc0201e50:	7cc68693          	addi	a3,a3,1996 # ffffffffc0207618 <commands+0xcb0>
ffffffffc0201e54:	00005617          	auipc	a2,0x5
ffffffffc0201e58:	fac60613          	addi	a2,a2,-84 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201e5c:	24300593          	li	a1,579
ffffffffc0201e60:	00005517          	auipc	a0,0x5
ffffffffc0201e64:	40050513          	addi	a0,a0,1024 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201e68:	baefe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0201e6c:	00005697          	auipc	a3,0x5
ffffffffc0201e70:	76468693          	addi	a3,a3,1892 # ffffffffc02075d0 <commands+0xc68>
ffffffffc0201e74:	00005617          	auipc	a2,0x5
ffffffffc0201e78:	f8c60613          	addi	a2,a2,-116 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201e7c:	24100593          	li	a1,577
ffffffffc0201e80:	00005517          	auipc	a0,0x5
ffffffffc0201e84:	3e050513          	addi	a0,a0,992 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201e88:	b8efe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0201e8c:	00005697          	auipc	a3,0x5
ffffffffc0201e90:	77468693          	addi	a3,a3,1908 # ffffffffc0207600 <commands+0xc98>
ffffffffc0201e94:	00005617          	auipc	a2,0x5
ffffffffc0201e98:	f6c60613          	addi	a2,a2,-148 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201e9c:	24000593          	li	a1,576
ffffffffc0201ea0:	00005517          	auipc	a0,0x5
ffffffffc0201ea4:	3c050513          	addi	a0,a0,960 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201ea8:	b6efe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0201eac:	00006697          	auipc	a3,0x6
ffffffffc0201eb0:	8d468693          	addi	a3,a3,-1836 # ffffffffc0207780 <commands+0xe18>
ffffffffc0201eb4:	00005617          	auipc	a2,0x5
ffffffffc0201eb8:	f4c60613          	addi	a2,a2,-180 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201ebc:	26400593          	li	a1,612
ffffffffc0201ec0:	00005517          	auipc	a0,0x5
ffffffffc0201ec4:	3a050513          	addi	a0,a0,928 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201ec8:	b4efe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201ecc:	00006697          	auipc	a3,0x6
ffffffffc0201ed0:	87468693          	addi	a3,a3,-1932 # ffffffffc0207740 <commands+0xdd8>
ffffffffc0201ed4:	00005617          	auipc	a2,0x5
ffffffffc0201ed8:	f2c60613          	addi	a2,a2,-212 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201edc:	26300593          	li	a1,611
ffffffffc0201ee0:	00005517          	auipc	a0,0x5
ffffffffc0201ee4:	38050513          	addi	a0,a0,896 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201ee8:	b2efe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0201eec:	00006697          	auipc	a3,0x6
ffffffffc0201ef0:	83c68693          	addi	a3,a3,-1988 # ffffffffc0207728 <commands+0xdc0>
ffffffffc0201ef4:	00005617          	auipc	a2,0x5
ffffffffc0201ef8:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201efc:	26200593          	li	a1,610
ffffffffc0201f00:	00005517          	auipc	a0,0x5
ffffffffc0201f04:	36050513          	addi	a0,a0,864 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201f08:	b0efe0ef          	jal	ra,ffffffffc0200216 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201f0c:	86be                	mv	a3,a5
ffffffffc0201f0e:	00005617          	auipc	a2,0x5
ffffffffc0201f12:	32a60613          	addi	a2,a2,810 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0201f16:	22800593          	li	a1,552
ffffffffc0201f1a:	00005517          	auipc	a0,0x5
ffffffffc0201f1e:	34650513          	addi	a0,a0,838 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201f22:	af4fe0ef          	jal	ra,ffffffffc0200216 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201f26:	00005617          	auipc	a2,0x5
ffffffffc0201f2a:	3ea60613          	addi	a2,a2,1002 # ffffffffc0207310 <commands+0x9a8>
ffffffffc0201f2e:	07f00593          	li	a1,127
ffffffffc0201f32:	00005517          	auipc	a0,0x5
ffffffffc0201f36:	32e50513          	addi	a0,a0,814 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201f3a:	adcfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201f3e:	00006697          	auipc	a3,0x6
ffffffffc0201f42:	87268693          	addi	a3,a3,-1934 # ffffffffc02077b0 <commands+0xe48>
ffffffffc0201f46:	00005617          	auipc	a2,0x5
ffffffffc0201f4a:	eba60613          	addi	a2,a2,-326 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201f4e:	26800593          	li	a1,616
ffffffffc0201f52:	00005517          	auipc	a0,0x5
ffffffffc0201f56:	30e50513          	addi	a0,a0,782 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201f5a:	abcfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0201f5e:	00005697          	auipc	a3,0x5
ffffffffc0201f62:	6e268693          	addi	a3,a3,1762 # ffffffffc0207640 <commands+0xcd8>
ffffffffc0201f66:	00005617          	auipc	a2,0x5
ffffffffc0201f6a:	e9a60613          	addi	a2,a2,-358 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201f6e:	27400593          	li	a1,628
ffffffffc0201f72:	00005517          	auipc	a0,0x5
ffffffffc0201f76:	2ee50513          	addi	a0,a0,750 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201f7a:	a9cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0201f7e:	00005697          	auipc	a3,0x5
ffffffffc0201f82:	51268693          	addi	a3,a3,1298 # ffffffffc0207490 <commands+0xb28>
ffffffffc0201f86:	00005617          	auipc	a2,0x5
ffffffffc0201f8a:	e7a60613          	addi	a2,a2,-390 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201f8e:	22600593          	li	a1,550
ffffffffc0201f92:	00005517          	auipc	a0,0x5
ffffffffc0201f96:	2ce50513          	addi	a0,a0,718 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201f9a:	a7cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0201f9e:	00005697          	auipc	a3,0x5
ffffffffc0201fa2:	4da68693          	addi	a3,a3,1242 # ffffffffc0207478 <commands+0xb10>
ffffffffc0201fa6:	00005617          	auipc	a2,0x5
ffffffffc0201faa:	e5a60613          	addi	a2,a2,-422 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201fae:	22500593          	li	a1,549
ffffffffc0201fb2:	00005517          	auipc	a0,0x5
ffffffffc0201fb6:	2ae50513          	addi	a0,a0,686 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201fba:	a5cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201fbe:	00005697          	auipc	a3,0x5
ffffffffc0201fc2:	40a68693          	addi	a3,a3,1034 # ffffffffc02073c8 <commands+0xa60>
ffffffffc0201fc6:	00005617          	auipc	a2,0x5
ffffffffc0201fca:	e3a60613          	addi	a2,a2,-454 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201fce:	21d00593          	li	a1,541
ffffffffc0201fd2:	00005517          	auipc	a0,0x5
ffffffffc0201fd6:	28e50513          	addi	a0,a0,654 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201fda:	a3cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201fde:	00005697          	auipc	a3,0x5
ffffffffc0201fe2:	44268693          	addi	a3,a3,1090 # ffffffffc0207420 <commands+0xab8>
ffffffffc0201fe6:	00005617          	auipc	a2,0x5
ffffffffc0201fea:	e1a60613          	addi	a2,a2,-486 # ffffffffc0206e00 <commands+0x498>
ffffffffc0201fee:	22400593          	li	a1,548
ffffffffc0201ff2:	00005517          	auipc	a0,0x5
ffffffffc0201ff6:	26e50513          	addi	a0,a0,622 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0201ffa:	a1cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201ffe:	00005697          	auipc	a3,0x5
ffffffffc0202002:	3f268693          	addi	a3,a3,1010 # ffffffffc02073f0 <commands+0xa88>
ffffffffc0202006:	00005617          	auipc	a2,0x5
ffffffffc020200a:	dfa60613          	addi	a2,a2,-518 # ffffffffc0206e00 <commands+0x498>
ffffffffc020200e:	22100593          	li	a1,545
ffffffffc0202012:	00005517          	auipc	a0,0x5
ffffffffc0202016:	24e50513          	addi	a0,a0,590 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020201a:	9fcfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020201e:	00005697          	auipc	a3,0x5
ffffffffc0202022:	5b268693          	addi	a3,a3,1458 # ffffffffc02075d0 <commands+0xc68>
ffffffffc0202026:	00005617          	auipc	a2,0x5
ffffffffc020202a:	dda60613          	addi	a2,a2,-550 # ffffffffc0206e00 <commands+0x498>
ffffffffc020202e:	23d00593          	li	a1,573
ffffffffc0202032:	00005517          	auipc	a0,0x5
ffffffffc0202036:	22e50513          	addi	a0,a0,558 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020203a:	9dcfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020203e:	00005697          	auipc	a3,0x5
ffffffffc0202042:	45268693          	addi	a3,a3,1106 # ffffffffc0207490 <commands+0xb28>
ffffffffc0202046:	00005617          	auipc	a2,0x5
ffffffffc020204a:	dba60613          	addi	a2,a2,-582 # ffffffffc0206e00 <commands+0x498>
ffffffffc020204e:	23c00593          	li	a1,572
ffffffffc0202052:	00005517          	auipc	a0,0x5
ffffffffc0202056:	20e50513          	addi	a0,a0,526 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020205a:	9bcfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020205e:	00005697          	auipc	a3,0x5
ffffffffc0202062:	58a68693          	addi	a3,a3,1418 # ffffffffc02075e8 <commands+0xc80>
ffffffffc0202066:	00005617          	auipc	a2,0x5
ffffffffc020206a:	d9a60613          	addi	a2,a2,-614 # ffffffffc0206e00 <commands+0x498>
ffffffffc020206e:	23900593          	li	a1,569
ffffffffc0202072:	00005517          	auipc	a0,0x5
ffffffffc0202076:	1ee50513          	addi	a0,a0,494 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020207a:	99cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020207e:	00005697          	auipc	a3,0x5
ffffffffc0202082:	76a68693          	addi	a3,a3,1898 # ffffffffc02077e8 <commands+0xe80>
ffffffffc0202086:	00005617          	auipc	a2,0x5
ffffffffc020208a:	d7a60613          	addi	a2,a2,-646 # ffffffffc0206e00 <commands+0x498>
ffffffffc020208e:	26b00593          	li	a1,619
ffffffffc0202092:	00005517          	auipc	a0,0x5
ffffffffc0202096:	1ce50513          	addi	a0,a0,462 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020209a:	97cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020209e:	00005697          	auipc	a3,0x5
ffffffffc02020a2:	5a268693          	addi	a3,a3,1442 # ffffffffc0207640 <commands+0xcd8>
ffffffffc02020a6:	00005617          	auipc	a2,0x5
ffffffffc02020aa:	d5a60613          	addi	a2,a2,-678 # ffffffffc0206e00 <commands+0x498>
ffffffffc02020ae:	24b00593          	li	a1,587
ffffffffc02020b2:	00005517          	auipc	a0,0x5
ffffffffc02020b6:	1ae50513          	addi	a0,a0,430 # ffffffffc0207260 <commands+0x8f8>
ffffffffc02020ba:	95cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc02020be:	00005697          	auipc	a3,0x5
ffffffffc02020c2:	61a68693          	addi	a3,a3,1562 # ffffffffc02076d8 <commands+0xd70>
ffffffffc02020c6:	00005617          	auipc	a2,0x5
ffffffffc02020ca:	d3a60613          	addi	a2,a2,-710 # ffffffffc0206e00 <commands+0x498>
ffffffffc02020ce:	25d00593          	li	a1,605
ffffffffc02020d2:	00005517          	auipc	a0,0x5
ffffffffc02020d6:	18e50513          	addi	a0,a0,398 # ffffffffc0207260 <commands+0x8f8>
ffffffffc02020da:	93cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02020de:	00005697          	auipc	a3,0x5
ffffffffc02020e2:	29268693          	addi	a3,a3,658 # ffffffffc0207370 <commands+0xa08>
ffffffffc02020e6:	00005617          	auipc	a2,0x5
ffffffffc02020ea:	d1a60613          	addi	a2,a2,-742 # ffffffffc0206e00 <commands+0x498>
ffffffffc02020ee:	21b00593          	li	a1,539
ffffffffc02020f2:	00005517          	auipc	a0,0x5
ffffffffc02020f6:	16e50513          	addi	a0,a0,366 # ffffffffc0207260 <commands+0x8f8>
ffffffffc02020fa:	91cfe0ef          	jal	ra,ffffffffc0200216 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02020fe:	00005617          	auipc	a2,0x5
ffffffffc0202102:	21260613          	addi	a2,a2,530 # ffffffffc0207310 <commands+0x9a8>
ffffffffc0202106:	0c100593          	li	a1,193
ffffffffc020210a:	00005517          	auipc	a0,0x5
ffffffffc020210e:	15650513          	addi	a0,a0,342 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0202112:	904fe0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202116 <copy_range>:
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share) {
ffffffffc0202116:	7119                	addi	sp,sp,-128
ffffffffc0202118:	e0da                	sd	s6,64(sp)
ffffffffc020211a:	8b2a                	mv	s6,a0
    cprintf("\ncopy on write activated\n");
ffffffffc020211c:	00005517          	auipc	a0,0x5
ffffffffc0202120:	09c50513          	addi	a0,a0,156 # ffffffffc02071b8 <commands+0x850>
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share) {
ffffffffc0202124:	f4a6                	sd	s1,104(sp)
ffffffffc0202126:	f0ca                	sd	s2,96(sp)
ffffffffc0202128:	ec6e                	sd	s11,24(sp)
ffffffffc020212a:	8936                	mv	s2,a3
ffffffffc020212c:	8db2                	mv	s11,a2
ffffffffc020212e:	e03a                	sd	a4,0(sp)
ffffffffc0202130:	fc86                	sd	ra,120(sp)
ffffffffc0202132:	f8a2                	sd	s0,112(sp)
ffffffffc0202134:	ecce                	sd	s3,88(sp)
ffffffffc0202136:	e8d2                	sd	s4,80(sp)
ffffffffc0202138:	e4d6                	sd	s5,72(sp)
ffffffffc020213a:	fc5e                	sd	s7,56(sp)
ffffffffc020213c:	f862                	sd	s8,48(sp)
ffffffffc020213e:	f466                	sd	s9,40(sp)
ffffffffc0202140:	f06a                	sd	s10,32(sp)
ffffffffc0202142:	84ae                	mv	s1,a1
    cprintf("\ncopy on write activated\n");
ffffffffc0202144:	f8dfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202148:	012de733          	or	a4,s11,s2
ffffffffc020214c:	03471793          	slli	a5,a4,0x34
ffffffffc0202150:	26079263          	bnez	a5,ffffffffc02023b4 <copy_range+0x29e>
    assert(USER_ACCESS(start, end));
ffffffffc0202154:	00200737          	lui	a4,0x200
ffffffffc0202158:	22ede263          	bltu	s11,a4,ffffffffc020237c <copy_range+0x266>
ffffffffc020215c:	232df063          	bleu	s2,s11,ffffffffc020237c <copy_range+0x266>
ffffffffc0202160:	4705                	li	a4,1
ffffffffc0202162:	077e                	slli	a4,a4,0x1f
ffffffffc0202164:	21276c63          	bltu	a4,s2,ffffffffc020237c <copy_range+0x266>
ffffffffc0202168:	5afd                	li	s5,-1
        start += PGSIZE;
ffffffffc020216a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc020216c:	000aac97          	auipc	s9,0xaa
ffffffffc0202170:	25cc8c93          	addi	s9,s9,604 # ffffffffc02ac3c8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202174:	000aac17          	auipc	s8,0xaa
ffffffffc0202178:	2bcc0c13          	addi	s8,s8,700 # ffffffffc02ac430 <pages>
    return page - pages + nbase;
ffffffffc020217c:	00080bb7          	lui	s7,0x80
    return KADDR(page2pa(page));
ffffffffc0202180:	00cada93          	srli	s5,s5,0xc
ffffffffc0202184:	000aad17          	auipc	s10,0xaa
ffffffffc0202188:	29cd0d13          	addi	s10,s10,668 # ffffffffc02ac420 <va_pa_offset>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020218c:	4601                	li	a2,0
ffffffffc020218e:	85ee                	mv	a1,s11
ffffffffc0202190:	8526                	mv	a0,s1
ffffffffc0202192:	e27fe0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc0202196:	842a                	mv	s0,a0
        if (ptep == NULL) {
ffffffffc0202198:	c179                	beqz	a0,ffffffffc020225e <copy_range+0x148>
        if (*ptep & PTE_V) {
ffffffffc020219a:	6118                	ld	a4,0(a0)
ffffffffc020219c:	8b05                	andi	a4,a4,1
ffffffffc020219e:	e705                	bnez	a4,ffffffffc02021c6 <copy_range+0xb0>
        start += PGSIZE;
ffffffffc02021a0:	9dd2                	add	s11,s11,s4
    } while (start != 0 && start < end);
ffffffffc02021a2:	ff2de5e3          	bltu	s11,s2,ffffffffc020218c <copy_range+0x76>
    return 0;
ffffffffc02021a6:	4501                	li	a0,0
}
ffffffffc02021a8:	70e6                	ld	ra,120(sp)
ffffffffc02021aa:	7446                	ld	s0,112(sp)
ffffffffc02021ac:	74a6                	ld	s1,104(sp)
ffffffffc02021ae:	7906                	ld	s2,96(sp)
ffffffffc02021b0:	69e6                	ld	s3,88(sp)
ffffffffc02021b2:	6a46                	ld	s4,80(sp)
ffffffffc02021b4:	6aa6                	ld	s5,72(sp)
ffffffffc02021b6:	6b06                	ld	s6,64(sp)
ffffffffc02021b8:	7be2                	ld	s7,56(sp)
ffffffffc02021ba:	7c42                	ld	s8,48(sp)
ffffffffc02021bc:	7ca2                	ld	s9,40(sp)
ffffffffc02021be:	7d02                	ld	s10,32(sp)
ffffffffc02021c0:	6de2                	ld	s11,24(sp)
ffffffffc02021c2:	6109                	addi	sp,sp,128
ffffffffc02021c4:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) return -E_NO_MEM;
ffffffffc02021c6:	4605                	li	a2,1
ffffffffc02021c8:	85ee                	mv	a1,s11
ffffffffc02021ca:	855a                	mv	a0,s6
ffffffffc02021cc:	dedfe0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc02021d0:	12050b63          	beqz	a0,ffffffffc0202306 <copy_range+0x1f0>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02021d4:	6018                	ld	a4,0(s0)
    if (!(pte & PTE_V)) {
ffffffffc02021d6:	00177693          	andi	a3,a4,1
ffffffffc02021da:	0007099b          	sext.w	s3,a4
ffffffffc02021de:	16068363          	beqz	a3,ffffffffc0202344 <copy_range+0x22e>
    if (PPN(pa) >= npage) {
ffffffffc02021e2:	000cb683          	ld	a3,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02021e6:	070a                	slli	a4,a4,0x2
ffffffffc02021e8:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage) {
ffffffffc02021ea:	1ad77963          	bleu	a3,a4,ffffffffc020239c <copy_range+0x286>
    return &pages[PPN(pa) - nbase];
ffffffffc02021ee:	fff807b7          	lui	a5,0xfff80
ffffffffc02021f2:	973e                	add	a4,a4,a5
ffffffffc02021f4:	000c3403          	ld	s0,0(s8)
            if(share)
ffffffffc02021f8:	6782                	ld	a5,0(sp)
ffffffffc02021fa:	071a                	slli	a4,a4,0x6
ffffffffc02021fc:	943a                	add	s0,s0,a4
ffffffffc02021fe:	cfad                	beqz	a5,ffffffffc0202278 <copy_range+0x162>
    return page - pages + nbase;
ffffffffc0202200:	8719                	srai	a4,a4,0x6
ffffffffc0202202:	975e                	add	a4,a4,s7
    return KADDR(page2pa(page));
ffffffffc0202204:	01577633          	and	a2,a4,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0202208:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc020220a:	10d67063          	bleu	a3,a2,ffffffffc020230a <copy_range+0x1f4>
ffffffffc020220e:	000d3583          	ld	a1,0(s10)
                cprintf("Sharing the page 0x%x\n", page2kva(page));
ffffffffc0202212:	00005517          	auipc	a0,0x5
ffffffffc0202216:	fc650513          	addi	a0,a0,-58 # ffffffffc02071d8 <commands+0x870>
                page_insert(from, page, start, perm & ~PTE_W);
ffffffffc020221a:	01b9f993          	andi	s3,s3,27
                cprintf("Sharing the page 0x%x\n", page2kva(page));
ffffffffc020221e:	95ba                	add	a1,a1,a4
ffffffffc0202220:	eb1fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                page_insert(from, page, start, perm & ~PTE_W);
ffffffffc0202224:	86ce                	mv	a3,s3
ffffffffc0202226:	866e                	mv	a2,s11
ffffffffc0202228:	85a2                	mv	a1,s0
ffffffffc020222a:	8526                	mv	a0,s1
ffffffffc020222c:	ba2ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
                ret = page_insert(to, page, start, perm & ~PTE_W);
ffffffffc0202230:	86ce                	mv	a3,s3
ffffffffc0202232:	866e                	mv	a2,s11
ffffffffc0202234:	85a2                	mv	a1,s0
ffffffffc0202236:	855a                	mv	a0,s6
ffffffffc0202238:	b96ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
            assert(ret == 0);
ffffffffc020223c:	d135                	beqz	a0,ffffffffc02021a0 <copy_range+0x8a>
ffffffffc020223e:	00005697          	auipc	a3,0x5
ffffffffc0202242:	fea68693          	addi	a3,a3,-22 # ffffffffc0207228 <commands+0x8c0>
ffffffffc0202246:	00005617          	auipc	a2,0x5
ffffffffc020224a:	bba60613          	addi	a2,a2,-1094 # ffffffffc0206e00 <commands+0x498>
ffffffffc020224e:	1bc00593          	li	a1,444
ffffffffc0202252:	00005517          	auipc	a0,0x5
ffffffffc0202256:	00e50513          	addi	a0,a0,14 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020225a:	fbdfd0ef          	jal	ra,ffffffffc0200216 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020225e:	00200737          	lui	a4,0x200
ffffffffc0202262:	00ed87b3          	add	a5,s11,a4
ffffffffc0202266:	ffe00737          	lui	a4,0xffe00
ffffffffc020226a:	00e7fdb3          	and	s11,a5,a4
    } while (start != 0 && start < end);
ffffffffc020226e:	f20d8ce3          	beqz	s11,ffffffffc02021a6 <copy_range+0x90>
ffffffffc0202272:	f12dede3          	bltu	s11,s2,ffffffffc020218c <copy_range+0x76>
ffffffffc0202276:	bf05                	j	ffffffffc02021a6 <copy_range+0x90>
                struct Page *npage = alloc_page();
ffffffffc0202278:	4505                	li	a0,1
ffffffffc020227a:	c31fe0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
                assert(page!=NULL);
ffffffffc020227e:	c05d                	beqz	s0,ffffffffc0202324 <copy_range+0x20e>
                assert(npage!=NULL);
ffffffffc0202280:	cd71                	beqz	a0,ffffffffc020235c <copy_range+0x246>
    return page - pages + nbase;
ffffffffc0202282:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0202286:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc020228a:	40d506b3          	sub	a3,a0,a3
ffffffffc020228e:	8699                	srai	a3,a3,0x6
ffffffffc0202290:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0202292:	0156f633          	and	a2,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0202296:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202298:	06e67a63          	bleu	a4,a2,ffffffffc020230c <copy_range+0x1f6>
ffffffffc020229c:	000d3583          	ld	a1,0(s10)
ffffffffc02022a0:	e42a                	sd	a0,8(sp)
                cprintf("alloc a new page 0x%x\n", page2kva(npage));
ffffffffc02022a2:	00005517          	auipc	a0,0x5
ffffffffc02022a6:	f6e50513          	addi	a0,a0,-146 # ffffffffc0207210 <commands+0x8a8>
ffffffffc02022aa:	95b6                	add	a1,a1,a3
ffffffffc02022ac:	e25fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    return page - pages + nbase;
ffffffffc02022b0:	000c3703          	ld	a4,0(s8)
    return KADDR(page2pa(page));
ffffffffc02022b4:	000cb603          	ld	a2,0(s9)
ffffffffc02022b8:	6822                	ld	a6,8(sp)
    return page - pages + nbase;
ffffffffc02022ba:	40e406b3          	sub	a3,s0,a4
ffffffffc02022be:	8699                	srai	a3,a3,0x6
ffffffffc02022c0:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02022c2:	0156f5b3          	and	a1,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc02022c6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02022c8:	04c5f263          	bleu	a2,a1,ffffffffc020230c <copy_range+0x1f6>
    return page - pages + nbase;
ffffffffc02022cc:	40e80733          	sub	a4,a6,a4
    return KADDR(page2pa(page));
ffffffffc02022d0:	000d3503          	ld	a0,0(s10)
    return page - pages + nbase;
ffffffffc02022d4:	8719                	srai	a4,a4,0x6
ffffffffc02022d6:	975e                	add	a4,a4,s7
    return KADDR(page2pa(page));
ffffffffc02022d8:	015778b3          	and	a7,a4,s5
ffffffffc02022dc:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02022e0:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc02022e2:	02c8f463          	bleu	a2,a7,ffffffffc020230a <copy_range+0x1f4>
                memcpy(kva_dst, kva_src, PGSIZE);
ffffffffc02022e6:	6605                	lui	a2,0x1
ffffffffc02022e8:	953a                	add	a0,a0,a4
ffffffffc02022ea:	e442                	sd	a6,8(sp)
ffffffffc02022ec:	0e2040ef          	jal	ra,ffffffffc02063ce <memcpy>
                ret = page_insert(to, npage, start, perm);
ffffffffc02022f0:	6822                	ld	a6,8(sp)
ffffffffc02022f2:	01f9f693          	andi	a3,s3,31
ffffffffc02022f6:	866e                	mv	a2,s11
ffffffffc02022f8:	85c2                	mv	a1,a6
ffffffffc02022fa:	855a                	mv	a0,s6
ffffffffc02022fc:	ad2ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
            assert(ret == 0);
ffffffffc0202300:	ea0500e3          	beqz	a0,ffffffffc02021a0 <copy_range+0x8a>
ffffffffc0202304:	bf2d                	j	ffffffffc020223e <copy_range+0x128>
            if ((nptep = get_pte(to, start, 1)) == NULL) return -E_NO_MEM;
ffffffffc0202306:	5571                	li	a0,-4
ffffffffc0202308:	b545                	j	ffffffffc02021a8 <copy_range+0x92>
ffffffffc020230a:	86ba                	mv	a3,a4
ffffffffc020230c:	00005617          	auipc	a2,0x5
ffffffffc0202310:	f2c60613          	addi	a2,a2,-212 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0202314:	06900593          	li	a1,105
ffffffffc0202318:	00005517          	auipc	a0,0x5
ffffffffc020231c:	f7850513          	addi	a0,a0,-136 # ffffffffc0207290 <commands+0x928>
ffffffffc0202320:	ef7fd0ef          	jal	ra,ffffffffc0200216 <__panic>
                assert(page!=NULL);
ffffffffc0202324:	00005697          	auipc	a3,0x5
ffffffffc0202328:	ecc68693          	addi	a3,a3,-308 # ffffffffc02071f0 <commands+0x888>
ffffffffc020232c:	00005617          	auipc	a2,0x5
ffffffffc0202330:	ad460613          	addi	a2,a2,-1324 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202334:	1b300593          	li	a1,435
ffffffffc0202338:	00005517          	auipc	a0,0x5
ffffffffc020233c:	f2850513          	addi	a0,a0,-216 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0202340:	ed7fd0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202344:	00005617          	auipc	a2,0x5
ffffffffc0202348:	10c60613          	addi	a2,a2,268 # ffffffffc0207450 <commands+0xae8>
ffffffffc020234c:	07400593          	li	a1,116
ffffffffc0202350:	00005517          	auipc	a0,0x5
ffffffffc0202354:	f4050513          	addi	a0,a0,-192 # ffffffffc0207290 <commands+0x928>
ffffffffc0202358:	ebffd0ef          	jal	ra,ffffffffc0200216 <__panic>
                assert(npage!=NULL);
ffffffffc020235c:	00005697          	auipc	a3,0x5
ffffffffc0202360:	ea468693          	addi	a3,a3,-348 # ffffffffc0207200 <commands+0x898>
ffffffffc0202364:	00005617          	auipc	a2,0x5
ffffffffc0202368:	a9c60613          	addi	a2,a2,-1380 # ffffffffc0206e00 <commands+0x498>
ffffffffc020236c:	1b400593          	li	a1,436
ffffffffc0202370:	00005517          	auipc	a0,0x5
ffffffffc0202374:	ef050513          	addi	a0,a0,-272 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0202378:	e9ffd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020237c:	00005697          	auipc	a3,0x5
ffffffffc0202380:	4e468693          	addi	a3,a3,1252 # ffffffffc0207860 <commands+0xef8>
ffffffffc0202384:	00005617          	auipc	a2,0x5
ffffffffc0202388:	a7c60613          	addi	a2,a2,-1412 # ffffffffc0206e00 <commands+0x498>
ffffffffc020238c:	19500593          	li	a1,405
ffffffffc0202390:	00005517          	auipc	a0,0x5
ffffffffc0202394:	ed050513          	addi	a0,a0,-304 # ffffffffc0207260 <commands+0x8f8>
ffffffffc0202398:	e7ffd0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020239c:	00005617          	auipc	a2,0x5
ffffffffc02023a0:	ed460613          	addi	a2,a2,-300 # ffffffffc0207270 <commands+0x908>
ffffffffc02023a4:	06200593          	li	a1,98
ffffffffc02023a8:	00005517          	auipc	a0,0x5
ffffffffc02023ac:	ee850513          	addi	a0,a0,-280 # ffffffffc0207290 <commands+0x928>
ffffffffc02023b0:	e67fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023b4:	00005697          	auipc	a3,0x5
ffffffffc02023b8:	47c68693          	addi	a3,a3,1148 # ffffffffc0207830 <commands+0xec8>
ffffffffc02023bc:	00005617          	auipc	a2,0x5
ffffffffc02023c0:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206e00 <commands+0x498>
ffffffffc02023c4:	19400593          	li	a1,404
ffffffffc02023c8:	00005517          	auipc	a0,0x5
ffffffffc02023cc:	e9850513          	addi	a0,a0,-360 # ffffffffc0207260 <commands+0x8f8>
ffffffffc02023d0:	e47fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02023d4 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02023d4:	12058073          	sfence.vma	a1
}
ffffffffc02023d8:	8082                	ret

ffffffffc02023da <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02023da:	7179                	addi	sp,sp,-48
ffffffffc02023dc:	e84a                	sd	s2,16(sp)
ffffffffc02023de:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc02023e0:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02023e2:	f022                	sd	s0,32(sp)
ffffffffc02023e4:	ec26                	sd	s1,24(sp)
ffffffffc02023e6:	e44e                	sd	s3,8(sp)
ffffffffc02023e8:	f406                	sd	ra,40(sp)
ffffffffc02023ea:	84ae                	mv	s1,a1
ffffffffc02023ec:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc02023ee:	abdfe0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc02023f2:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc02023f4:	cd1d                	beqz	a0,ffffffffc0202432 <pgdir_alloc_page+0x58>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc02023f6:	85aa                	mv	a1,a0
ffffffffc02023f8:	86ce                	mv	a3,s3
ffffffffc02023fa:	8626                	mv	a2,s1
ffffffffc02023fc:	854a                	mv	a0,s2
ffffffffc02023fe:	9d0ff0ef          	jal	ra,ffffffffc02015ce <page_insert>
ffffffffc0202402:	e121                	bnez	a0,ffffffffc0202442 <pgdir_alloc_page+0x68>
        if (swap_init_ok) {
ffffffffc0202404:	000aa797          	auipc	a5,0xaa
ffffffffc0202408:	fe478793          	addi	a5,a5,-28 # ffffffffc02ac3e8 <swap_init_ok>
ffffffffc020240c:	439c                	lw	a5,0(a5)
ffffffffc020240e:	2781                	sext.w	a5,a5
ffffffffc0202410:	c38d                	beqz	a5,ffffffffc0202432 <pgdir_alloc_page+0x58>
            if (check_mm_struct != NULL) {
ffffffffc0202412:	000aa797          	auipc	a5,0xaa
ffffffffc0202416:	03678793          	addi	a5,a5,54 # ffffffffc02ac448 <check_mm_struct>
ffffffffc020241a:	6388                	ld	a0,0(a5)
ffffffffc020241c:	c919                	beqz	a0,ffffffffc0202432 <pgdir_alloc_page+0x58>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc020241e:	4681                	li	a3,0
ffffffffc0202420:	8622                	mv	a2,s0
ffffffffc0202422:	85a6                	mv	a1,s1
ffffffffc0202424:	3f9010ef          	jal	ra,ffffffffc020401c <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc0202428:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc020242a:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc020242c:	4785                	li	a5,1
ffffffffc020242e:	02f71063          	bne	a4,a5,ffffffffc020244e <pgdir_alloc_page+0x74>
}
ffffffffc0202432:	8522                	mv	a0,s0
ffffffffc0202434:	70a2                	ld	ra,40(sp)
ffffffffc0202436:	7402                	ld	s0,32(sp)
ffffffffc0202438:	64e2                	ld	s1,24(sp)
ffffffffc020243a:	6942                	ld	s2,16(sp)
ffffffffc020243c:	69a2                	ld	s3,8(sp)
ffffffffc020243e:	6145                	addi	sp,sp,48
ffffffffc0202440:	8082                	ret
            free_page(page);
ffffffffc0202442:	8522                	mv	a0,s0
ffffffffc0202444:	4585                	li	a1,1
ffffffffc0202446:	aedfe0ef          	jal	ra,ffffffffc0200f32 <free_pages>
            return NULL;
ffffffffc020244a:	4401                	li	s0,0
ffffffffc020244c:	b7dd                	j	ffffffffc0202432 <pgdir_alloc_page+0x58>
                assert(page_ref(page) == 1);
ffffffffc020244e:	00005697          	auipc	a3,0x5
ffffffffc0202452:	e5268693          	addi	a3,a3,-430 # ffffffffc02072a0 <commands+0x938>
ffffffffc0202456:	00005617          	auipc	a2,0x5
ffffffffc020245a:	9aa60613          	addi	a2,a2,-1622 # ffffffffc0206e00 <commands+0x498>
ffffffffc020245e:	1fc00593          	li	a1,508
ffffffffc0202462:	00005517          	auipc	a0,0x5
ffffffffc0202466:	dfe50513          	addi	a0,a0,-514 # ffffffffc0207260 <commands+0x8f8>
ffffffffc020246a:	dadfd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020246e <_fifo_init_mm>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020246e:	000aa797          	auipc	a5,0xaa
ffffffffc0202472:	fca78793          	addi	a5,a5,-54 # ffffffffc02ac438 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0202476:	f51c                	sd	a5,40(a0)
ffffffffc0202478:	e79c                	sd	a5,8(a5)
ffffffffc020247a:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc020247c:	4501                	li	a0,0
ffffffffc020247e:	8082                	ret

ffffffffc0202480 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0202480:	4501                	li	a0,0
ffffffffc0202482:	8082                	ret

ffffffffc0202484 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0202484:	4501                	li	a0,0
ffffffffc0202486:	8082                	ret

ffffffffc0202488 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0202488:	4501                	li	a0,0
ffffffffc020248a:	8082                	ret

ffffffffc020248c <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc020248c:	711d                	addi	sp,sp,-96
ffffffffc020248e:	fc4e                	sd	s3,56(sp)
ffffffffc0202490:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0202492:	00005517          	auipc	a0,0x5
ffffffffc0202496:	3e650513          	addi	a0,a0,998 # ffffffffc0207878 <commands+0xf10>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020249a:	698d                	lui	s3,0x3
ffffffffc020249c:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc020249e:	e8a2                	sd	s0,80(sp)
ffffffffc02024a0:	e4a6                	sd	s1,72(sp)
ffffffffc02024a2:	ec86                	sd	ra,88(sp)
ffffffffc02024a4:	e0ca                	sd	s2,64(sp)
ffffffffc02024a6:	f456                	sd	s5,40(sp)
ffffffffc02024a8:	f05a                	sd	s6,32(sp)
ffffffffc02024aa:	ec5e                	sd	s7,24(sp)
ffffffffc02024ac:	e862                	sd	s8,16(sp)
ffffffffc02024ae:	e466                	sd	s9,8(sp)
    assert(pgfault_num==4);
ffffffffc02024b0:	000aa417          	auipc	s0,0xaa
ffffffffc02024b4:	f2040413          	addi	s0,s0,-224 # ffffffffc02ac3d0 <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc02024b8:	c19fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02024bc:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6570>
    assert(pgfault_num==4);
ffffffffc02024c0:	4004                	lw	s1,0(s0)
ffffffffc02024c2:	4791                	li	a5,4
ffffffffc02024c4:	2481                	sext.w	s1,s1
ffffffffc02024c6:	14f49963          	bne	s1,a5,ffffffffc0202618 <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02024ca:	00005517          	auipc	a0,0x5
ffffffffc02024ce:	3fe50513          	addi	a0,a0,1022 # ffffffffc02078c8 <commands+0xf60>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02024d2:	6a85                	lui	s5,0x1
ffffffffc02024d4:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02024d6:	bfbfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02024da:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
    assert(pgfault_num==4);
ffffffffc02024de:	00042903          	lw	s2,0(s0)
ffffffffc02024e2:	2901                	sext.w	s2,s2
ffffffffc02024e4:	2a991a63          	bne	s2,s1,ffffffffc0202798 <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02024e8:	00005517          	auipc	a0,0x5
ffffffffc02024ec:	40850513          	addi	a0,a0,1032 # ffffffffc02078f0 <commands+0xf88>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02024f0:	6b91                	lui	s7,0x4
ffffffffc02024f2:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02024f4:	bddfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02024f8:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5570>
    assert(pgfault_num==4);
ffffffffc02024fc:	4004                	lw	s1,0(s0)
ffffffffc02024fe:	2481                	sext.w	s1,s1
ffffffffc0202500:	27249c63          	bne	s1,s2,ffffffffc0202778 <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0202504:	00005517          	auipc	a0,0x5
ffffffffc0202508:	41450513          	addi	a0,a0,1044 # ffffffffc0207918 <commands+0xfb0>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020250c:	6909                	lui	s2,0x2
ffffffffc020250e:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0202510:	bc1fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202514:	01990023          	sb	s9,0(s2) # 2000 <_binary_obj___user_faultread_out_size-0x7570>
    assert(pgfault_num==4);
ffffffffc0202518:	401c                	lw	a5,0(s0)
ffffffffc020251a:	2781                	sext.w	a5,a5
ffffffffc020251c:	22979e63          	bne	a5,s1,ffffffffc0202758 <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0202520:	00005517          	auipc	a0,0x5
ffffffffc0202524:	42050513          	addi	a0,a0,1056 # ffffffffc0207940 <commands+0xfd8>
ffffffffc0202528:	ba9fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020252c:	6795                	lui	a5,0x5
ffffffffc020252e:	4739                	li	a4,14
ffffffffc0202530:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4570>
    assert(pgfault_num==5);
ffffffffc0202534:	4004                	lw	s1,0(s0)
ffffffffc0202536:	4795                	li	a5,5
ffffffffc0202538:	2481                	sext.w	s1,s1
ffffffffc020253a:	1ef49f63          	bne	s1,a5,ffffffffc0202738 <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020253e:	00005517          	auipc	a0,0x5
ffffffffc0202542:	3da50513          	addi	a0,a0,986 # ffffffffc0207918 <commands+0xfb0>
ffffffffc0202546:	b8bfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020254a:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==5);
ffffffffc020254e:	401c                	lw	a5,0(s0)
ffffffffc0202550:	2781                	sext.w	a5,a5
ffffffffc0202552:	1c979363          	bne	a5,s1,ffffffffc0202718 <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0202556:	00005517          	auipc	a0,0x5
ffffffffc020255a:	37250513          	addi	a0,a0,882 # ffffffffc02078c8 <commands+0xf60>
ffffffffc020255e:	b73fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202562:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0202566:	401c                	lw	a5,0(s0)
ffffffffc0202568:	4719                	li	a4,6
ffffffffc020256a:	2781                	sext.w	a5,a5
ffffffffc020256c:	18e79663          	bne	a5,a4,ffffffffc02026f8 <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0202570:	00005517          	auipc	a0,0x5
ffffffffc0202574:	3a850513          	addi	a0,a0,936 # ffffffffc0207918 <commands+0xfb0>
ffffffffc0202578:	b59fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020257c:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==7);
ffffffffc0202580:	401c                	lw	a5,0(s0)
ffffffffc0202582:	471d                	li	a4,7
ffffffffc0202584:	2781                	sext.w	a5,a5
ffffffffc0202586:	14e79963          	bne	a5,a4,ffffffffc02026d8 <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc020258a:	00005517          	auipc	a0,0x5
ffffffffc020258e:	2ee50513          	addi	a0,a0,750 # ffffffffc0207878 <commands+0xf10>
ffffffffc0202592:	b3ffd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202596:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc020259a:	401c                	lw	a5,0(s0)
ffffffffc020259c:	4721                	li	a4,8
ffffffffc020259e:	2781                	sext.w	a5,a5
ffffffffc02025a0:	10e79c63          	bne	a5,a4,ffffffffc02026b8 <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02025a4:	00005517          	auipc	a0,0x5
ffffffffc02025a8:	34c50513          	addi	a0,a0,844 # ffffffffc02078f0 <commands+0xf88>
ffffffffc02025ac:	b25fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02025b0:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc02025b4:	401c                	lw	a5,0(s0)
ffffffffc02025b6:	4725                	li	a4,9
ffffffffc02025b8:	2781                	sext.w	a5,a5
ffffffffc02025ba:	0ce79f63          	bne	a5,a4,ffffffffc0202698 <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02025be:	00005517          	auipc	a0,0x5
ffffffffc02025c2:	38250513          	addi	a0,a0,898 # ffffffffc0207940 <commands+0xfd8>
ffffffffc02025c6:	b0bfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02025ca:	6795                	lui	a5,0x5
ffffffffc02025cc:	4739                	li	a4,14
ffffffffc02025ce:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4570>
    assert(pgfault_num==10);
ffffffffc02025d2:	4004                	lw	s1,0(s0)
ffffffffc02025d4:	47a9                	li	a5,10
ffffffffc02025d6:	2481                	sext.w	s1,s1
ffffffffc02025d8:	0af49063          	bne	s1,a5,ffffffffc0202678 <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02025dc:	00005517          	auipc	a0,0x5
ffffffffc02025e0:	2ec50513          	addi	a0,a0,748 # ffffffffc02078c8 <commands+0xf60>
ffffffffc02025e4:	aedfd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02025e8:	6785                	lui	a5,0x1
ffffffffc02025ea:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
ffffffffc02025ee:	06979563          	bne	a5,s1,ffffffffc0202658 <_fifo_check_swap+0x1cc>
    assert(pgfault_num==11);
ffffffffc02025f2:	401c                	lw	a5,0(s0)
ffffffffc02025f4:	472d                	li	a4,11
ffffffffc02025f6:	2781                	sext.w	a5,a5
ffffffffc02025f8:	04e79063          	bne	a5,a4,ffffffffc0202638 <_fifo_check_swap+0x1ac>
}
ffffffffc02025fc:	60e6                	ld	ra,88(sp)
ffffffffc02025fe:	6446                	ld	s0,80(sp)
ffffffffc0202600:	64a6                	ld	s1,72(sp)
ffffffffc0202602:	6906                	ld	s2,64(sp)
ffffffffc0202604:	79e2                	ld	s3,56(sp)
ffffffffc0202606:	7a42                	ld	s4,48(sp)
ffffffffc0202608:	7aa2                	ld	s5,40(sp)
ffffffffc020260a:	7b02                	ld	s6,32(sp)
ffffffffc020260c:	6be2                	ld	s7,24(sp)
ffffffffc020260e:	6c42                	ld	s8,16(sp)
ffffffffc0202610:	6ca2                	ld	s9,8(sp)
ffffffffc0202612:	4501                	li	a0,0
ffffffffc0202614:	6125                	addi	sp,sp,96
ffffffffc0202616:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0202618:	00005697          	auipc	a3,0x5
ffffffffc020261c:	28868693          	addi	a3,a3,648 # ffffffffc02078a0 <commands+0xf38>
ffffffffc0202620:	00004617          	auipc	a2,0x4
ffffffffc0202624:	7e060613          	addi	a2,a2,2016 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202628:	05100593          	li	a1,81
ffffffffc020262c:	00005517          	auipc	a0,0x5
ffffffffc0202630:	28450513          	addi	a0,a0,644 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202634:	be3fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==11);
ffffffffc0202638:	00005697          	auipc	a3,0x5
ffffffffc020263c:	3b868693          	addi	a3,a3,952 # ffffffffc02079f0 <commands+0x1088>
ffffffffc0202640:	00004617          	auipc	a2,0x4
ffffffffc0202644:	7c060613          	addi	a2,a2,1984 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202648:	07300593          	li	a1,115
ffffffffc020264c:	00005517          	auipc	a0,0x5
ffffffffc0202650:	26450513          	addi	a0,a0,612 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202654:	bc3fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0202658:	00005697          	auipc	a3,0x5
ffffffffc020265c:	37068693          	addi	a3,a3,880 # ffffffffc02079c8 <commands+0x1060>
ffffffffc0202660:	00004617          	auipc	a2,0x4
ffffffffc0202664:	7a060613          	addi	a2,a2,1952 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202668:	07100593          	li	a1,113
ffffffffc020266c:	00005517          	auipc	a0,0x5
ffffffffc0202670:	24450513          	addi	a0,a0,580 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202674:	ba3fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==10);
ffffffffc0202678:	00005697          	auipc	a3,0x5
ffffffffc020267c:	34068693          	addi	a3,a3,832 # ffffffffc02079b8 <commands+0x1050>
ffffffffc0202680:	00004617          	auipc	a2,0x4
ffffffffc0202684:	78060613          	addi	a2,a2,1920 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202688:	06f00593          	li	a1,111
ffffffffc020268c:	00005517          	auipc	a0,0x5
ffffffffc0202690:	22450513          	addi	a0,a0,548 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202694:	b83fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==9);
ffffffffc0202698:	00005697          	auipc	a3,0x5
ffffffffc020269c:	31068693          	addi	a3,a3,784 # ffffffffc02079a8 <commands+0x1040>
ffffffffc02026a0:	00004617          	auipc	a2,0x4
ffffffffc02026a4:	76060613          	addi	a2,a2,1888 # ffffffffc0206e00 <commands+0x498>
ffffffffc02026a8:	06c00593          	li	a1,108
ffffffffc02026ac:	00005517          	auipc	a0,0x5
ffffffffc02026b0:	20450513          	addi	a0,a0,516 # ffffffffc02078b0 <commands+0xf48>
ffffffffc02026b4:	b63fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==8);
ffffffffc02026b8:	00005697          	auipc	a3,0x5
ffffffffc02026bc:	2e068693          	addi	a3,a3,736 # ffffffffc0207998 <commands+0x1030>
ffffffffc02026c0:	00004617          	auipc	a2,0x4
ffffffffc02026c4:	74060613          	addi	a2,a2,1856 # ffffffffc0206e00 <commands+0x498>
ffffffffc02026c8:	06900593          	li	a1,105
ffffffffc02026cc:	00005517          	auipc	a0,0x5
ffffffffc02026d0:	1e450513          	addi	a0,a0,484 # ffffffffc02078b0 <commands+0xf48>
ffffffffc02026d4:	b43fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==7);
ffffffffc02026d8:	00005697          	auipc	a3,0x5
ffffffffc02026dc:	2b068693          	addi	a3,a3,688 # ffffffffc0207988 <commands+0x1020>
ffffffffc02026e0:	00004617          	auipc	a2,0x4
ffffffffc02026e4:	72060613          	addi	a2,a2,1824 # ffffffffc0206e00 <commands+0x498>
ffffffffc02026e8:	06600593          	li	a1,102
ffffffffc02026ec:	00005517          	auipc	a0,0x5
ffffffffc02026f0:	1c450513          	addi	a0,a0,452 # ffffffffc02078b0 <commands+0xf48>
ffffffffc02026f4:	b23fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==6);
ffffffffc02026f8:	00005697          	auipc	a3,0x5
ffffffffc02026fc:	28068693          	addi	a3,a3,640 # ffffffffc0207978 <commands+0x1010>
ffffffffc0202700:	00004617          	auipc	a2,0x4
ffffffffc0202704:	70060613          	addi	a2,a2,1792 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202708:	06300593          	li	a1,99
ffffffffc020270c:	00005517          	auipc	a0,0x5
ffffffffc0202710:	1a450513          	addi	a0,a0,420 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202714:	b03fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==5);
ffffffffc0202718:	00005697          	auipc	a3,0x5
ffffffffc020271c:	25068693          	addi	a3,a3,592 # ffffffffc0207968 <commands+0x1000>
ffffffffc0202720:	00004617          	auipc	a2,0x4
ffffffffc0202724:	6e060613          	addi	a2,a2,1760 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202728:	06000593          	li	a1,96
ffffffffc020272c:	00005517          	auipc	a0,0x5
ffffffffc0202730:	18450513          	addi	a0,a0,388 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202734:	ae3fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==5);
ffffffffc0202738:	00005697          	auipc	a3,0x5
ffffffffc020273c:	23068693          	addi	a3,a3,560 # ffffffffc0207968 <commands+0x1000>
ffffffffc0202740:	00004617          	auipc	a2,0x4
ffffffffc0202744:	6c060613          	addi	a2,a2,1728 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202748:	05d00593          	li	a1,93
ffffffffc020274c:	00005517          	auipc	a0,0x5
ffffffffc0202750:	16450513          	addi	a0,a0,356 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202754:	ac3fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==4);
ffffffffc0202758:	00005697          	auipc	a3,0x5
ffffffffc020275c:	14868693          	addi	a3,a3,328 # ffffffffc02078a0 <commands+0xf38>
ffffffffc0202760:	00004617          	auipc	a2,0x4
ffffffffc0202764:	6a060613          	addi	a2,a2,1696 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202768:	05a00593          	li	a1,90
ffffffffc020276c:	00005517          	auipc	a0,0x5
ffffffffc0202770:	14450513          	addi	a0,a0,324 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202774:	aa3fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==4);
ffffffffc0202778:	00005697          	auipc	a3,0x5
ffffffffc020277c:	12868693          	addi	a3,a3,296 # ffffffffc02078a0 <commands+0xf38>
ffffffffc0202780:	00004617          	auipc	a2,0x4
ffffffffc0202784:	68060613          	addi	a2,a2,1664 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202788:	05700593          	li	a1,87
ffffffffc020278c:	00005517          	auipc	a0,0x5
ffffffffc0202790:	12450513          	addi	a0,a0,292 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202794:	a83fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgfault_num==4);
ffffffffc0202798:	00005697          	auipc	a3,0x5
ffffffffc020279c:	10868693          	addi	a3,a3,264 # ffffffffc02078a0 <commands+0xf38>
ffffffffc02027a0:	00004617          	auipc	a2,0x4
ffffffffc02027a4:	66060613          	addi	a2,a2,1632 # ffffffffc0206e00 <commands+0x498>
ffffffffc02027a8:	05400593          	li	a1,84
ffffffffc02027ac:	00005517          	auipc	a0,0x5
ffffffffc02027b0:	10450513          	addi	a0,a0,260 # ffffffffc02078b0 <commands+0xf48>
ffffffffc02027b4:	a63fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02027b8 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02027b8:	751c                	ld	a5,40(a0)
{
ffffffffc02027ba:	1141                	addi	sp,sp,-16
ffffffffc02027bc:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc02027be:	cf91                	beqz	a5,ffffffffc02027da <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc02027c0:	ee0d                	bnez	a2,ffffffffc02027fa <_fifo_swap_out_victim+0x42>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02027c2:	679c                	ld	a5,8(a5)
}
ffffffffc02027c4:	60a2                	ld	ra,8(sp)
ffffffffc02027c6:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc02027c8:	6394                	ld	a3,0(a5)
ffffffffc02027ca:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc02027cc:	fd878793          	addi	a5,a5,-40
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02027d0:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02027d2:	e314                	sd	a3,0(a4)
ffffffffc02027d4:	e19c                	sd	a5,0(a1)
}
ffffffffc02027d6:	0141                	addi	sp,sp,16
ffffffffc02027d8:	8082                	ret
         assert(head != NULL);
ffffffffc02027da:	00005697          	auipc	a3,0x5
ffffffffc02027de:	24668693          	addi	a3,a3,582 # ffffffffc0207a20 <commands+0x10b8>
ffffffffc02027e2:	00004617          	auipc	a2,0x4
ffffffffc02027e6:	61e60613          	addi	a2,a2,1566 # ffffffffc0206e00 <commands+0x498>
ffffffffc02027ea:	04100593          	li	a1,65
ffffffffc02027ee:	00005517          	auipc	a0,0x5
ffffffffc02027f2:	0c250513          	addi	a0,a0,194 # ffffffffc02078b0 <commands+0xf48>
ffffffffc02027f6:	a21fd0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(in_tick==0);
ffffffffc02027fa:	00005697          	auipc	a3,0x5
ffffffffc02027fe:	23668693          	addi	a3,a3,566 # ffffffffc0207a30 <commands+0x10c8>
ffffffffc0202802:	00004617          	auipc	a2,0x4
ffffffffc0202806:	5fe60613          	addi	a2,a2,1534 # ffffffffc0206e00 <commands+0x498>
ffffffffc020280a:	04200593          	li	a1,66
ffffffffc020280e:	00005517          	auipc	a0,0x5
ffffffffc0202812:	0a250513          	addi	a0,a0,162 # ffffffffc02078b0 <commands+0xf48>
ffffffffc0202816:	a01fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020281a <_fifo_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc020281a:	02860713          	addi	a4,a2,40
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020281e:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc0202820:	cb09                	beqz	a4,ffffffffc0202832 <_fifo_map_swappable+0x18>
ffffffffc0202822:	cb81                	beqz	a5,ffffffffc0202832 <_fifo_map_swappable+0x18>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202824:	6394                	ld	a3,0(a5)
    prev->next = next->prev = elm;
ffffffffc0202826:	e398                	sd	a4,0(a5)
}
ffffffffc0202828:	4501                	li	a0,0
ffffffffc020282a:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc020282c:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc020282e:	f614                	sd	a3,40(a2)
ffffffffc0202830:	8082                	ret
{
ffffffffc0202832:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0202834:	00005697          	auipc	a3,0x5
ffffffffc0202838:	1cc68693          	addi	a3,a3,460 # ffffffffc0207a00 <commands+0x1098>
ffffffffc020283c:	00004617          	auipc	a2,0x4
ffffffffc0202840:	5c460613          	addi	a2,a2,1476 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202844:	03200593          	li	a1,50
ffffffffc0202848:	00005517          	auipc	a0,0x5
ffffffffc020284c:	06850513          	addi	a0,a0,104 # ffffffffc02078b0 <commands+0xf48>
{
ffffffffc0202850:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0202852:	9c5fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202856 <check_vma_overlap.isra.1.part.2>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0202856:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202858:	00005697          	auipc	a3,0x5
ffffffffc020285c:	20068693          	addi	a3,a3,512 # ffffffffc0207a58 <commands+0x10f0>
ffffffffc0202860:	00004617          	auipc	a2,0x4
ffffffffc0202864:	5a060613          	addi	a2,a2,1440 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202868:	06d00593          	li	a1,109
ffffffffc020286c:	00005517          	auipc	a0,0x5
ffffffffc0202870:	20c50513          	addi	a0,a0,524 # ffffffffc0207a78 <commands+0x1110>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0202874:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202876:	9a1fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020287a <mm_create>:
mm_create(void) {
ffffffffc020287a:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020287c:	04000513          	li	a0,64
mm_create(void) {
ffffffffc0202880:	e022                	sd	s0,0(sp)
ffffffffc0202882:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202884:	629000ef          	jal	ra,ffffffffc02036ac <kmalloc>
ffffffffc0202888:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc020288a:	c515                	beqz	a0,ffffffffc02028b6 <mm_create+0x3c>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc020288c:	000aa797          	auipc	a5,0xaa
ffffffffc0202890:	b5c78793          	addi	a5,a5,-1188 # ffffffffc02ac3e8 <swap_init_ok>
ffffffffc0202894:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0202896:	e408                	sd	a0,8(s0)
ffffffffc0202898:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc020289a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020289e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02028a2:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02028a6:	2781                	sext.w	a5,a5
ffffffffc02028a8:	ef81                	bnez	a5,ffffffffc02028c0 <mm_create+0x46>
        else mm->sm_priv = NULL;
ffffffffc02028aa:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc02028ae:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc02028b2:	02043c23          	sd	zero,56(s0)
}
ffffffffc02028b6:	8522                	mv	a0,s0
ffffffffc02028b8:	60a2                	ld	ra,8(sp)
ffffffffc02028ba:	6402                	ld	s0,0(sp)
ffffffffc02028bc:	0141                	addi	sp,sp,16
ffffffffc02028be:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02028c0:	74c010ef          	jal	ra,ffffffffc020400c <swap_init_mm>
ffffffffc02028c4:	b7ed                	j	ffffffffc02028ae <mm_create+0x34>

ffffffffc02028c6 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc02028c6:	1101                	addi	sp,sp,-32
ffffffffc02028c8:	e04a                	sd	s2,0(sp)
ffffffffc02028ca:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02028cc:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc02028d0:	e822                	sd	s0,16(sp)
ffffffffc02028d2:	e426                	sd	s1,8(sp)
ffffffffc02028d4:	ec06                	sd	ra,24(sp)
ffffffffc02028d6:	84ae                	mv	s1,a1
ffffffffc02028d8:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02028da:	5d3000ef          	jal	ra,ffffffffc02036ac <kmalloc>
    if (vma != NULL) {
ffffffffc02028de:	c509                	beqz	a0,ffffffffc02028e8 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02028e0:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02028e4:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02028e6:	cd00                	sw	s0,24(a0)
}
ffffffffc02028e8:	60e2                	ld	ra,24(sp)
ffffffffc02028ea:	6442                	ld	s0,16(sp)
ffffffffc02028ec:	64a2                	ld	s1,8(sp)
ffffffffc02028ee:	6902                	ld	s2,0(sp)
ffffffffc02028f0:	6105                	addi	sp,sp,32
ffffffffc02028f2:	8082                	ret

ffffffffc02028f4 <find_vma>:
    if (mm != NULL) {
ffffffffc02028f4:	c51d                	beqz	a0,ffffffffc0202922 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc02028f6:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02028f8:	c781                	beqz	a5,ffffffffc0202900 <find_vma+0xc>
ffffffffc02028fa:	6798                	ld	a4,8(a5)
ffffffffc02028fc:	02e5f663          	bleu	a4,a1,ffffffffc0202928 <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc0202900:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc0202902:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0202904:	00f50f63          	beq	a0,a5,ffffffffc0202922 <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0202908:	fe87b703          	ld	a4,-24(a5)
ffffffffc020290c:	fee5ebe3          	bltu	a1,a4,ffffffffc0202902 <find_vma+0xe>
ffffffffc0202910:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202914:	fee5f7e3          	bleu	a4,a1,ffffffffc0202902 <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc0202918:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc020291a:	c781                	beqz	a5,ffffffffc0202922 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc020291c:	e91c                	sd	a5,16(a0)
}
ffffffffc020291e:	853e                	mv	a0,a5
ffffffffc0202920:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0202922:	4781                	li	a5,0
}
ffffffffc0202924:	853e                	mv	a0,a5
ffffffffc0202926:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0202928:	6b98                	ld	a4,16(a5)
ffffffffc020292a:	fce5fbe3          	bleu	a4,a1,ffffffffc0202900 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020292e:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc0202930:	b7fd                	j	ffffffffc020291e <find_vma+0x2a>

ffffffffc0202932 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202932:	6590                	ld	a2,8(a1)
ffffffffc0202934:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0202938:	1141                	addi	sp,sp,-16
ffffffffc020293a:	e406                	sd	ra,8(sp)
ffffffffc020293c:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020293e:	01066863          	bltu	a2,a6,ffffffffc020294e <insert_vma_struct+0x1c>
ffffffffc0202942:	a8b9                	j	ffffffffc02029a0 <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0202944:	fe87b683          	ld	a3,-24(a5)
ffffffffc0202948:	04d66763          	bltu	a2,a3,ffffffffc0202996 <insert_vma_struct+0x64>
ffffffffc020294c:	873e                	mv	a4,a5
ffffffffc020294e:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc0202950:	fef51ae3          	bne	a0,a5,ffffffffc0202944 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0202954:	02a70463          	beq	a4,a0,ffffffffc020297c <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202958:	ff073683          	ld	a3,-16(a4) # ffffffffffdffff0 <end+0x3fb53ab0>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020295c:	fe873883          	ld	a7,-24(a4)
ffffffffc0202960:	08d8f063          	bleu	a3,a7,ffffffffc02029e0 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202964:	04d66e63          	bltu	a2,a3,ffffffffc02029c0 <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc0202968:	00f50a63          	beq	a0,a5,ffffffffc020297c <insert_vma_struct+0x4a>
ffffffffc020296c:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202970:	0506e863          	bltu	a3,a6,ffffffffc02029c0 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0202974:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202978:	02c6f263          	bleu	a2,a3,ffffffffc020299c <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc020297c:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc020297e:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202980:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202984:	e390                	sd	a2,0(a5)
ffffffffc0202986:	e710                	sd	a2,8(a4)
}
ffffffffc0202988:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020298a:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020298c:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc020298e:	2685                	addiw	a3,a3,1
ffffffffc0202990:	d114                	sw	a3,32(a0)
}
ffffffffc0202992:	0141                	addi	sp,sp,16
ffffffffc0202994:	8082                	ret
    if (le_prev != list) {
ffffffffc0202996:	fca711e3          	bne	a4,a0,ffffffffc0202958 <insert_vma_struct+0x26>
ffffffffc020299a:	bfd9                	j	ffffffffc0202970 <insert_vma_struct+0x3e>
ffffffffc020299c:	ebbff0ef          	jal	ra,ffffffffc0202856 <check_vma_overlap.isra.1.part.2>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02029a0:	00005697          	auipc	a3,0x5
ffffffffc02029a4:	20868693          	addi	a3,a3,520 # ffffffffc0207ba8 <commands+0x1240>
ffffffffc02029a8:	00004617          	auipc	a2,0x4
ffffffffc02029ac:	45860613          	addi	a2,a2,1112 # ffffffffc0206e00 <commands+0x498>
ffffffffc02029b0:	07400593          	li	a1,116
ffffffffc02029b4:	00005517          	auipc	a0,0x5
ffffffffc02029b8:	0c450513          	addi	a0,a0,196 # ffffffffc0207a78 <commands+0x1110>
ffffffffc02029bc:	85bfd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02029c0:	00005697          	auipc	a3,0x5
ffffffffc02029c4:	22868693          	addi	a3,a3,552 # ffffffffc0207be8 <commands+0x1280>
ffffffffc02029c8:	00004617          	auipc	a2,0x4
ffffffffc02029cc:	43860613          	addi	a2,a2,1080 # ffffffffc0206e00 <commands+0x498>
ffffffffc02029d0:	06c00593          	li	a1,108
ffffffffc02029d4:	00005517          	auipc	a0,0x5
ffffffffc02029d8:	0a450513          	addi	a0,a0,164 # ffffffffc0207a78 <commands+0x1110>
ffffffffc02029dc:	83bfd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02029e0:	00005697          	auipc	a3,0x5
ffffffffc02029e4:	1e868693          	addi	a3,a3,488 # ffffffffc0207bc8 <commands+0x1260>
ffffffffc02029e8:	00004617          	auipc	a2,0x4
ffffffffc02029ec:	41860613          	addi	a2,a2,1048 # ffffffffc0206e00 <commands+0x498>
ffffffffc02029f0:	06b00593          	li	a1,107
ffffffffc02029f4:	00005517          	auipc	a0,0x5
ffffffffc02029f8:	08450513          	addi	a0,a0,132 # ffffffffc0207a78 <commands+0x1110>
ffffffffc02029fc:	81bfd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202a00 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc0202a00:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc0202a02:	1141                	addi	sp,sp,-16
ffffffffc0202a04:	e406                	sd	ra,8(sp)
ffffffffc0202a06:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0202a08:	e78d                	bnez	a5,ffffffffc0202a32 <mm_destroy+0x32>
ffffffffc0202a0a:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0202a0c:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0202a0e:	00a40c63          	beq	s0,a0,ffffffffc0202a26 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202a12:	6118                	ld	a4,0(a0)
ffffffffc0202a14:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0202a16:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0202a18:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202a1a:	e398                	sd	a4,0(a5)
ffffffffc0202a1c:	54d000ef          	jal	ra,ffffffffc0203768 <kfree>
    return listelm->next;
ffffffffc0202a20:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0202a22:	fea418e3          	bne	s0,a0,ffffffffc0202a12 <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc0202a26:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0202a28:	6402                	ld	s0,0(sp)
ffffffffc0202a2a:	60a2                	ld	ra,8(sp)
ffffffffc0202a2c:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc0202a2e:	53b0006f          	j	ffffffffc0203768 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0202a32:	00005697          	auipc	a3,0x5
ffffffffc0202a36:	1d668693          	addi	a3,a3,470 # ffffffffc0207c08 <commands+0x12a0>
ffffffffc0202a3a:	00004617          	auipc	a2,0x4
ffffffffc0202a3e:	3c660613          	addi	a2,a2,966 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202a42:	09400593          	li	a1,148
ffffffffc0202a46:	00005517          	auipc	a0,0x5
ffffffffc0202a4a:	03250513          	addi	a0,a0,50 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202a4e:	fc8fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202a52 <mm_map>:

int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202a52:	6785                	lui	a5,0x1
       struct vma_struct **vma_store) {
ffffffffc0202a54:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202a56:	17fd                	addi	a5,a5,-1
ffffffffc0202a58:	787d                	lui	a6,0xfffff
       struct vma_struct **vma_store) {
ffffffffc0202a5a:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202a5c:	00f60433          	add	s0,a2,a5
       struct vma_struct **vma_store) {
ffffffffc0202a60:	f426                	sd	s1,40(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202a62:	942e                	add	s0,s0,a1
       struct vma_struct **vma_store) {
ffffffffc0202a64:	fc06                	sd	ra,56(sp)
ffffffffc0202a66:	f04a                	sd	s2,32(sp)
ffffffffc0202a68:	ec4e                	sd	s3,24(sp)
ffffffffc0202a6a:	e852                	sd	s4,16(sp)
ffffffffc0202a6c:	e456                	sd	s5,8(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0202a6e:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end)) {
ffffffffc0202a72:	002007b7          	lui	a5,0x200
ffffffffc0202a76:	01047433          	and	s0,s0,a6
ffffffffc0202a7a:	06f4e363          	bltu	s1,a5,ffffffffc0202ae0 <mm_map+0x8e>
ffffffffc0202a7e:	0684f163          	bleu	s0,s1,ffffffffc0202ae0 <mm_map+0x8e>
ffffffffc0202a82:	4785                	li	a5,1
ffffffffc0202a84:	07fe                	slli	a5,a5,0x1f
ffffffffc0202a86:	0487ed63          	bltu	a5,s0,ffffffffc0202ae0 <mm_map+0x8e>
ffffffffc0202a8a:	89aa                	mv	s3,a0
ffffffffc0202a8c:	8a3a                	mv	s4,a4
ffffffffc0202a8e:	8ab6                	mv	s5,a3
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0202a90:	c931                	beqz	a0,ffffffffc0202ae4 <mm_map+0x92>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0202a92:	85a6                	mv	a1,s1
ffffffffc0202a94:	e61ff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
ffffffffc0202a98:	c501                	beqz	a0,ffffffffc0202aa0 <mm_map+0x4e>
ffffffffc0202a9a:	651c                	ld	a5,8(a0)
ffffffffc0202a9c:	0487e263          	bltu	a5,s0,ffffffffc0202ae0 <mm_map+0x8e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202aa0:	03000513          	li	a0,48
ffffffffc0202aa4:	409000ef          	jal	ra,ffffffffc02036ac <kmalloc>
ffffffffc0202aa8:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0202aaa:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc0202aac:	02090163          	beqz	s2,ffffffffc0202ace <mm_map+0x7c>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0202ab0:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0202ab2:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0202ab6:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0202aba:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0202abe:	85ca                	mv	a1,s2
ffffffffc0202ac0:	e73ff0ef          	jal	ra,ffffffffc0202932 <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0202ac4:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc0202ac6:	000a0463          	beqz	s4,ffffffffc0202ace <mm_map+0x7c>
        *vma_store = vma;
ffffffffc0202aca:	012a3023          	sd	s2,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8570>

out:
    return ret;
}
ffffffffc0202ace:	70e2                	ld	ra,56(sp)
ffffffffc0202ad0:	7442                	ld	s0,48(sp)
ffffffffc0202ad2:	74a2                	ld	s1,40(sp)
ffffffffc0202ad4:	7902                	ld	s2,32(sp)
ffffffffc0202ad6:	69e2                	ld	s3,24(sp)
ffffffffc0202ad8:	6a42                	ld	s4,16(sp)
ffffffffc0202ada:	6aa2                	ld	s5,8(sp)
ffffffffc0202adc:	6121                	addi	sp,sp,64
ffffffffc0202ade:	8082                	ret
        return -E_INVAL;
ffffffffc0202ae0:	5575                	li	a0,-3
ffffffffc0202ae2:	b7f5                	j	ffffffffc0202ace <mm_map+0x7c>
    assert(mm != NULL);
ffffffffc0202ae4:	00005697          	auipc	a3,0x5
ffffffffc0202ae8:	13c68693          	addi	a3,a3,316 # ffffffffc0207c20 <commands+0x12b8>
ffffffffc0202aec:	00004617          	auipc	a2,0x4
ffffffffc0202af0:	31460613          	addi	a2,a2,788 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202af4:	0a700593          	li	a1,167
ffffffffc0202af8:	00005517          	auipc	a0,0x5
ffffffffc0202afc:	f8050513          	addi	a0,a0,-128 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202b00:	f16fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202b04 <dup_mmap>:

int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc0202b04:	7139                	addi	sp,sp,-64
ffffffffc0202b06:	fc06                	sd	ra,56(sp)
ffffffffc0202b08:	f822                	sd	s0,48(sp)
ffffffffc0202b0a:	f426                	sd	s1,40(sp)
ffffffffc0202b0c:	f04a                	sd	s2,32(sp)
ffffffffc0202b0e:	ec4e                	sd	s3,24(sp)
ffffffffc0202b10:	e852                	sd	s4,16(sp)
ffffffffc0202b12:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0202b14:	c535                	beqz	a0,ffffffffc0202b80 <dup_mmap+0x7c>
ffffffffc0202b16:	892a                	mv	s2,a0
ffffffffc0202b18:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0202b1a:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0202b1c:	e59d                	bnez	a1,ffffffffc0202b4a <dup_mmap+0x46>
ffffffffc0202b1e:	a08d                	j	ffffffffc0202b80 <dup_mmap+0x7c>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0202b20:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0202b22:	0157b423          	sd	s5,8(a5) # 200008 <_binary_obj___user_exit_out_size+0x1f5598>
        insert_vma_struct(to, nvma);
ffffffffc0202b26:	854a                	mv	a0,s2
        vma->vm_end = vm_end;
ffffffffc0202b28:	0147b823          	sd	s4,16(a5)
        vma->vm_flags = vm_flags;
ffffffffc0202b2c:	0137ac23          	sw	s3,24(a5)
        insert_vma_struct(to, nvma);
ffffffffc0202b30:	e03ff0ef          	jal	ra,ffffffffc0202932 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc0202b34:	ff043683          	ld	a3,-16(s0)
ffffffffc0202b38:	fe843603          	ld	a2,-24(s0)
ffffffffc0202b3c:	6c8c                	ld	a1,24(s1)
ffffffffc0202b3e:	01893503          	ld	a0,24(s2)
ffffffffc0202b42:	4701                	li	a4,0
ffffffffc0202b44:	dd2ff0ef          	jal	ra,ffffffffc0202116 <copy_range>
ffffffffc0202b48:	e105                	bnez	a0,ffffffffc0202b68 <dup_mmap+0x64>
    return listelm->prev;
ffffffffc0202b4a:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc0202b4c:	02848863          	beq	s1,s0,ffffffffc0202b7c <dup_mmap+0x78>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202b50:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0202b54:	fe843a83          	ld	s5,-24(s0)
ffffffffc0202b58:	ff043a03          	ld	s4,-16(s0)
ffffffffc0202b5c:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202b60:	34d000ef          	jal	ra,ffffffffc02036ac <kmalloc>
ffffffffc0202b64:	87aa                	mv	a5,a0
    if (vma != NULL) {
ffffffffc0202b66:	fd4d                	bnez	a0,ffffffffc0202b20 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0202b68:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0202b6a:	70e2                	ld	ra,56(sp)
ffffffffc0202b6c:	7442                	ld	s0,48(sp)
ffffffffc0202b6e:	74a2                	ld	s1,40(sp)
ffffffffc0202b70:	7902                	ld	s2,32(sp)
ffffffffc0202b72:	69e2                	ld	s3,24(sp)
ffffffffc0202b74:	6a42                	ld	s4,16(sp)
ffffffffc0202b76:	6aa2                	ld	s5,8(sp)
ffffffffc0202b78:	6121                	addi	sp,sp,64
ffffffffc0202b7a:	8082                	ret
    return 0;
ffffffffc0202b7c:	4501                	li	a0,0
ffffffffc0202b7e:	b7f5                	j	ffffffffc0202b6a <dup_mmap+0x66>
    assert(to != NULL && from != NULL);
ffffffffc0202b80:	00005697          	auipc	a3,0x5
ffffffffc0202b84:	fe868693          	addi	a3,a3,-24 # ffffffffc0207b68 <commands+0x1200>
ffffffffc0202b88:	00004617          	auipc	a2,0x4
ffffffffc0202b8c:	27860613          	addi	a2,a2,632 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202b90:	0c000593          	li	a1,192
ffffffffc0202b94:	00005517          	auipc	a0,0x5
ffffffffc0202b98:	ee450513          	addi	a0,a0,-284 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202b9c:	e7afd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202ba0 <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc0202ba0:	1101                	addi	sp,sp,-32
ffffffffc0202ba2:	ec06                	sd	ra,24(sp)
ffffffffc0202ba4:	e822                	sd	s0,16(sp)
ffffffffc0202ba6:	e426                	sd	s1,8(sp)
ffffffffc0202ba8:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0202baa:	c531                	beqz	a0,ffffffffc0202bf6 <exit_mmap+0x56>
ffffffffc0202bac:	591c                	lw	a5,48(a0)
ffffffffc0202bae:	84aa                	mv	s1,a0
ffffffffc0202bb0:	e3b9                	bnez	a5,ffffffffc0202bf6 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0202bb2:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0202bb4:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc0202bb8:	02850663          	beq	a0,s0,ffffffffc0202be4 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0202bbc:	ff043603          	ld	a2,-16(s0)
ffffffffc0202bc0:	fe843583          	ld	a1,-24(s0)
ffffffffc0202bc4:	854a                	mv	a0,s2
ffffffffc0202bc6:	e26fe0ef          	jal	ra,ffffffffc02011ec <unmap_range>
ffffffffc0202bca:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0202bcc:	fe8498e3          	bne	s1,s0,ffffffffc0202bbc <exit_mmap+0x1c>
ffffffffc0202bd0:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc0202bd2:	00848c63          	beq	s1,s0,ffffffffc0202bea <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0202bd6:	ff043603          	ld	a2,-16(s0)
ffffffffc0202bda:	fe843583          	ld	a1,-24(s0)
ffffffffc0202bde:	854a                	mv	a0,s2
ffffffffc0202be0:	f24fe0ef          	jal	ra,ffffffffc0201304 <exit_range>
ffffffffc0202be4:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0202be6:	fe8498e3          	bne	s1,s0,ffffffffc0202bd6 <exit_mmap+0x36>
    }
}
ffffffffc0202bea:	60e2                	ld	ra,24(sp)
ffffffffc0202bec:	6442                	ld	s0,16(sp)
ffffffffc0202bee:	64a2                	ld	s1,8(sp)
ffffffffc0202bf0:	6902                	ld	s2,0(sp)
ffffffffc0202bf2:	6105                	addi	sp,sp,32
ffffffffc0202bf4:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0202bf6:	00005697          	auipc	a3,0x5
ffffffffc0202bfa:	f9268693          	addi	a3,a3,-110 # ffffffffc0207b88 <commands+0x1220>
ffffffffc0202bfe:	00004617          	auipc	a2,0x4
ffffffffc0202c02:	20260613          	addi	a2,a2,514 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202c06:	0d600593          	li	a1,214
ffffffffc0202c0a:	00005517          	auipc	a0,0x5
ffffffffc0202c0e:	e6e50513          	addi	a0,a0,-402 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202c12:	e04fd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0202c16 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0202c16:	7139                	addi	sp,sp,-64
ffffffffc0202c18:	f822                	sd	s0,48(sp)
ffffffffc0202c1a:	f426                	sd	s1,40(sp)
ffffffffc0202c1c:	fc06                	sd	ra,56(sp)
ffffffffc0202c1e:	f04a                	sd	s2,32(sp)
ffffffffc0202c20:	ec4e                	sd	s3,24(sp)
ffffffffc0202c22:	e852                	sd	s4,16(sp)
ffffffffc0202c24:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc0202c26:	c55ff0ef          	jal	ra,ffffffffc020287a <mm_create>
    assert(mm != NULL);
ffffffffc0202c2a:	842a                	mv	s0,a0
ffffffffc0202c2c:	03200493          	li	s1,50
ffffffffc0202c30:	e919                	bnez	a0,ffffffffc0202c46 <vmm_init+0x30>
ffffffffc0202c32:	a989                	j	ffffffffc0203084 <vmm_init+0x46e>
        vma->vm_start = vm_start;
ffffffffc0202c34:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202c36:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202c38:	00052c23          	sw	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202c3c:	14ed                	addi	s1,s1,-5
ffffffffc0202c3e:	8522                	mv	a0,s0
ffffffffc0202c40:	cf3ff0ef          	jal	ra,ffffffffc0202932 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0202c44:	c88d                	beqz	s1,ffffffffc0202c76 <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202c46:	03000513          	li	a0,48
ffffffffc0202c4a:	263000ef          	jal	ra,ffffffffc02036ac <kmalloc>
ffffffffc0202c4e:	85aa                	mv	a1,a0
ffffffffc0202c50:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0202c54:	f165                	bnez	a0,ffffffffc0202c34 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc0202c56:	00005697          	auipc	a3,0x5
ffffffffc0202c5a:	1f268693          	addi	a3,a3,498 # ffffffffc0207e48 <commands+0x14e0>
ffffffffc0202c5e:	00004617          	auipc	a2,0x4
ffffffffc0202c62:	1a260613          	addi	a2,a2,418 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202c66:	11300593          	li	a1,275
ffffffffc0202c6a:	00005517          	auipc	a0,0x5
ffffffffc0202c6e:	e0e50513          	addi	a0,a0,-498 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202c72:	da4fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc0202c76:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202c7a:	1f900913          	li	s2,505
ffffffffc0202c7e:	a819                	j	ffffffffc0202c94 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0202c80:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202c82:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202c84:	00052c23          	sw	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202c88:	0495                	addi	s1,s1,5
ffffffffc0202c8a:	8522                	mv	a0,s0
ffffffffc0202c8c:	ca7ff0ef          	jal	ra,ffffffffc0202932 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0202c90:	03248a63          	beq	s1,s2,ffffffffc0202cc4 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202c94:	03000513          	li	a0,48
ffffffffc0202c98:	215000ef          	jal	ra,ffffffffc02036ac <kmalloc>
ffffffffc0202c9c:	85aa                	mv	a1,a0
ffffffffc0202c9e:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0202ca2:	fd79                	bnez	a0,ffffffffc0202c80 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc0202ca4:	00005697          	auipc	a3,0x5
ffffffffc0202ca8:	1a468693          	addi	a3,a3,420 # ffffffffc0207e48 <commands+0x14e0>
ffffffffc0202cac:	00004617          	auipc	a2,0x4
ffffffffc0202cb0:	15460613          	addi	a2,a2,340 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202cb4:	11900593          	li	a1,281
ffffffffc0202cb8:	00005517          	auipc	a0,0x5
ffffffffc0202cbc:	dc050513          	addi	a0,a0,-576 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202cc0:	d56fd0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0202cc4:	6418                	ld	a4,8(s0)
ffffffffc0202cc6:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0202cc8:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0202ccc:	2ee40063          	beq	s0,a4,ffffffffc0202fac <vmm_init+0x396>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202cd0:	fe873603          	ld	a2,-24(a4)
ffffffffc0202cd4:	ffe78693          	addi	a3,a5,-2
ffffffffc0202cd8:	24d61a63          	bne	a2,a3,ffffffffc0202f2c <vmm_init+0x316>
ffffffffc0202cdc:	ff073683          	ld	a3,-16(a4)
ffffffffc0202ce0:	24f69663          	bne	a3,a5,ffffffffc0202f2c <vmm_init+0x316>
ffffffffc0202ce4:	0795                	addi	a5,a5,5
ffffffffc0202ce6:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0202ce8:	feb792e3          	bne	a5,a1,ffffffffc0202ccc <vmm_init+0xb6>
ffffffffc0202cec:	491d                	li	s2,7
ffffffffc0202cee:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202cf0:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202cf4:	85a6                	mv	a1,s1
ffffffffc0202cf6:	8522                	mv	a0,s0
ffffffffc0202cf8:	bfdff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
ffffffffc0202cfc:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0202cfe:	30050763          	beqz	a0,ffffffffc020300c <vmm_init+0x3f6>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0202d02:	00148593          	addi	a1,s1,1
ffffffffc0202d06:	8522                	mv	a0,s0
ffffffffc0202d08:	bedff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
ffffffffc0202d0c:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202d0e:	2c050f63          	beqz	a0,ffffffffc0202fec <vmm_init+0x3d6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0202d12:	85ca                	mv	a1,s2
ffffffffc0202d14:	8522                	mv	a0,s0
ffffffffc0202d16:	bdfff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202d1a:	2a051963          	bnez	a0,ffffffffc0202fcc <vmm_init+0x3b6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0202d1e:	00348593          	addi	a1,s1,3
ffffffffc0202d22:	8522                	mv	a0,s0
ffffffffc0202d24:	bd1ff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202d28:	32051263          	bnez	a0,ffffffffc020304c <vmm_init+0x436>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0202d2c:	00448593          	addi	a1,s1,4
ffffffffc0202d30:	8522                	mv	a0,s0
ffffffffc0202d32:	bc3ff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202d36:	2e051b63          	bnez	a0,ffffffffc020302c <vmm_init+0x416>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0202d3a:	008a3783          	ld	a5,8(s4)
ffffffffc0202d3e:	20979763          	bne	a5,s1,ffffffffc0202f4c <vmm_init+0x336>
ffffffffc0202d42:	010a3783          	ld	a5,16(s4)
ffffffffc0202d46:	21279363          	bne	a5,s2,ffffffffc0202f4c <vmm_init+0x336>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0202d4a:	0089b783          	ld	a5,8(s3)
ffffffffc0202d4e:	20979f63          	bne	a5,s1,ffffffffc0202f6c <vmm_init+0x356>
ffffffffc0202d52:	0109b783          	ld	a5,16(s3)
ffffffffc0202d56:	21279b63          	bne	a5,s2,ffffffffc0202f6c <vmm_init+0x356>
ffffffffc0202d5a:	0495                	addi	s1,s1,5
ffffffffc0202d5c:	0915                	addi	s2,s2,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0202d5e:	f9549be3          	bne	s1,s5,ffffffffc0202cf4 <vmm_init+0xde>
ffffffffc0202d62:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0202d64:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0202d66:	85a6                	mv	a1,s1
ffffffffc0202d68:	8522                	mv	a0,s0
ffffffffc0202d6a:	b8bff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
ffffffffc0202d6e:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc0202d72:	c90d                	beqz	a0,ffffffffc0202da4 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0202d74:	6914                	ld	a3,16(a0)
ffffffffc0202d76:	6510                	ld	a2,8(a0)
ffffffffc0202d78:	00005517          	auipc	a0,0x5
ffffffffc0202d7c:	fb850513          	addi	a0,a0,-72 # ffffffffc0207d30 <commands+0x13c8>
ffffffffc0202d80:	b50fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0202d84:	00005697          	auipc	a3,0x5
ffffffffc0202d88:	fd468693          	addi	a3,a3,-44 # ffffffffc0207d58 <commands+0x13f0>
ffffffffc0202d8c:	00004617          	auipc	a2,0x4
ffffffffc0202d90:	07460613          	addi	a2,a2,116 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202d94:	13b00593          	li	a1,315
ffffffffc0202d98:	00005517          	auipc	a0,0x5
ffffffffc0202d9c:	ce050513          	addi	a0,a0,-800 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202da0:	c76fd0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0202da4:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc0202da6:	fd2490e3          	bne	s1,s2,ffffffffc0202d66 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc0202daa:	8522                	mv	a0,s0
ffffffffc0202dac:	c55ff0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202db0:	00005517          	auipc	a0,0x5
ffffffffc0202db4:	fc050513          	addi	a0,a0,-64 # ffffffffc0207d70 <commands+0x1408>
ffffffffc0202db8:	b18fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0202dbc:	9bcfe0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>
ffffffffc0202dc0:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0202dc2:	ab9ff0ef          	jal	ra,ffffffffc020287a <mm_create>
ffffffffc0202dc6:	000a9797          	auipc	a5,0xa9
ffffffffc0202dca:	68a7b123          	sd	a0,1666(a5) # ffffffffc02ac448 <check_mm_struct>
ffffffffc0202dce:	84aa                	mv	s1,a0
    assert(check_mm_struct != NULL);
ffffffffc0202dd0:	36050663          	beqz	a0,ffffffffc020313c <vmm_init+0x526>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202dd4:	000a9797          	auipc	a5,0xa9
ffffffffc0202dd8:	5ec78793          	addi	a5,a5,1516 # ffffffffc02ac3c0 <boot_pgdir>
ffffffffc0202ddc:	0007b903          	ld	s2,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0202de0:	00093783          	ld	a5,0(s2)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202de4:	01253c23          	sd	s2,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0202de8:	2c079e63          	bnez	a5,ffffffffc02030c4 <vmm_init+0x4ae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202dec:	03000513          	li	a0,48
ffffffffc0202df0:	0bd000ef          	jal	ra,ffffffffc02036ac <kmalloc>
ffffffffc0202df4:	842a                	mv	s0,a0
    if (vma != NULL) {
ffffffffc0202df6:	18050b63          	beqz	a0,ffffffffc0202f8c <vmm_init+0x376>
        vma->vm_end = vm_end;
ffffffffc0202dfa:	002007b7          	lui	a5,0x200
ffffffffc0202dfe:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc0202e00:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0202e02:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0202e04:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc0202e06:	8526                	mv	a0,s1
        vma->vm_start = vm_start;
ffffffffc0202e08:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc0202e0c:	b27ff0ef          	jal	ra,ffffffffc0202932 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0202e10:	10000593          	li	a1,256
ffffffffc0202e14:	8526                	mv	a0,s1
ffffffffc0202e16:	adfff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
ffffffffc0202e1a:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc0202e1e:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0202e22:	2ca41163          	bne	s0,a0,ffffffffc02030e4 <vmm_init+0x4ce>
        *(char *)(addr + i) = i;
ffffffffc0202e26:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f5590>
        sum += i;
ffffffffc0202e2a:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc0202e2c:	fee79de3          	bne	a5,a4,ffffffffc0202e26 <vmm_init+0x210>
        sum += i;
ffffffffc0202e30:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc0202e32:	10000793          	li	a5,256
        sum += i;
ffffffffc0202e36:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x821a>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0202e3a:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0202e3e:	0007c683          	lbu	a3,0(a5)
ffffffffc0202e42:	0785                	addi	a5,a5,1
ffffffffc0202e44:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0202e46:	fec79ce3          	bne	a5,a2,ffffffffc0202e3e <vmm_init+0x228>
    }

    assert(sum == 0);
ffffffffc0202e4a:	2c071963          	bnez	a4,ffffffffc020311c <vmm_init+0x506>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e4e:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202e52:	000a9a97          	auipc	s5,0xa9
ffffffffc0202e56:	576a8a93          	addi	s5,s5,1398 # ffffffffc02ac3c8 <npage>
ffffffffc0202e5a:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e5e:	078a                	slli	a5,a5,0x2
ffffffffc0202e60:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e62:	20e7f563          	bleu	a4,a5,ffffffffc020306c <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e66:	00006697          	auipc	a3,0x6
ffffffffc0202e6a:	11268693          	addi	a3,a3,274 # ffffffffc0208f78 <nbase>
ffffffffc0202e6e:	0006ba03          	ld	s4,0(a3)
ffffffffc0202e72:	414786b3          	sub	a3,a5,s4
ffffffffc0202e76:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0202e78:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202e7a:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0202e7c:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0202e7e:	83b1                	srli	a5,a5,0xc
ffffffffc0202e80:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e82:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e84:	28e7f063          	bleu	a4,a5,ffffffffc0203104 <vmm_init+0x4ee>
ffffffffc0202e88:	000a9797          	auipc	a5,0xa9
ffffffffc0202e8c:	59878793          	addi	a5,a5,1432 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0202e90:	6380                	ld	s0,0(a5)

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0202e92:	4581                	li	a1,0
ffffffffc0202e94:	854a                	mv	a0,s2
ffffffffc0202e96:	9436                	add	s0,s0,a3
ffffffffc0202e98:	ec2fe0ef          	jal	ra,ffffffffc020155a <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e9c:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202e9e:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ea2:	078a                	slli	a5,a5,0x2
ffffffffc0202ea4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ea6:	1ce7f363          	bleu	a4,a5,ffffffffc020306c <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0202eaa:	000a9417          	auipc	s0,0xa9
ffffffffc0202eae:	58640413          	addi	s0,s0,1414 # ffffffffc02ac430 <pages>
ffffffffc0202eb2:	6008                	ld	a0,0(s0)
ffffffffc0202eb4:	414787b3          	sub	a5,a5,s4
ffffffffc0202eb8:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0202eba:	953e                	add	a0,a0,a5
ffffffffc0202ebc:	4585                	li	a1,1
ffffffffc0202ebe:	874fe0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ec2:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202ec6:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202eca:	078a                	slli	a5,a5,0x2
ffffffffc0202ecc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ece:	18e7ff63          	bleu	a4,a5,ffffffffc020306c <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ed2:	6008                	ld	a0,0(s0)
ffffffffc0202ed4:	414787b3          	sub	a5,a5,s4
ffffffffc0202ed8:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0202eda:	4585                	li	a1,1
ffffffffc0202edc:	953e                	add	a0,a0,a5
ffffffffc0202ede:	854fe0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    pgdir[0] = 0;
ffffffffc0202ee2:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc0202ee6:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc0202eea:	0004bc23          	sd	zero,24(s1)
    mm_destroy(mm);
ffffffffc0202eee:	8526                	mv	a0,s1
ffffffffc0202ef0:	b11ff0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0202ef4:	000a9797          	auipc	a5,0xa9
ffffffffc0202ef8:	5407ba23          	sd	zero,1364(a5) # ffffffffc02ac448 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0202efc:	87cfe0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>
ffffffffc0202f00:	1aa99263          	bne	s3,a0,ffffffffc02030a4 <vmm_init+0x48e>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0202f04:	00005517          	auipc	a0,0x5
ffffffffc0202f08:	f0c50513          	addi	a0,a0,-244 # ffffffffc0207e10 <commands+0x14a8>
ffffffffc0202f0c:	9c4fd0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc0202f10:	7442                	ld	s0,48(sp)
ffffffffc0202f12:	70e2                	ld	ra,56(sp)
ffffffffc0202f14:	74a2                	ld	s1,40(sp)
ffffffffc0202f16:	7902                	ld	s2,32(sp)
ffffffffc0202f18:	69e2                	ld	s3,24(sp)
ffffffffc0202f1a:	6a42                	ld	s4,16(sp)
ffffffffc0202f1c:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202f1e:	00005517          	auipc	a0,0x5
ffffffffc0202f22:	f1250513          	addi	a0,a0,-238 # ffffffffc0207e30 <commands+0x14c8>
}
ffffffffc0202f26:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202f28:	9a8fd06f          	j	ffffffffc02000d0 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f2c:	00005697          	auipc	a3,0x5
ffffffffc0202f30:	d1c68693          	addi	a3,a3,-740 # ffffffffc0207c48 <commands+0x12e0>
ffffffffc0202f34:	00004617          	auipc	a2,0x4
ffffffffc0202f38:	ecc60613          	addi	a2,a2,-308 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202f3c:	12200593          	li	a1,290
ffffffffc0202f40:	00005517          	auipc	a0,0x5
ffffffffc0202f44:	b3850513          	addi	a0,a0,-1224 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202f48:	acefd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0202f4c:	00005697          	auipc	a3,0x5
ffffffffc0202f50:	d8468693          	addi	a3,a3,-636 # ffffffffc0207cd0 <commands+0x1368>
ffffffffc0202f54:	00004617          	auipc	a2,0x4
ffffffffc0202f58:	eac60613          	addi	a2,a2,-340 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202f5c:	13200593          	li	a1,306
ffffffffc0202f60:	00005517          	auipc	a0,0x5
ffffffffc0202f64:	b1850513          	addi	a0,a0,-1256 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202f68:	aaefd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0202f6c:	00005697          	auipc	a3,0x5
ffffffffc0202f70:	d9468693          	addi	a3,a3,-620 # ffffffffc0207d00 <commands+0x1398>
ffffffffc0202f74:	00004617          	auipc	a2,0x4
ffffffffc0202f78:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202f7c:	13300593          	li	a1,307
ffffffffc0202f80:	00005517          	auipc	a0,0x5
ffffffffc0202f84:	af850513          	addi	a0,a0,-1288 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202f88:	a8efd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(vma != NULL);
ffffffffc0202f8c:	00005697          	auipc	a3,0x5
ffffffffc0202f90:	ebc68693          	addi	a3,a3,-324 # ffffffffc0207e48 <commands+0x14e0>
ffffffffc0202f94:	00004617          	auipc	a2,0x4
ffffffffc0202f98:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202f9c:	15200593          	li	a1,338
ffffffffc0202fa0:	00005517          	auipc	a0,0x5
ffffffffc0202fa4:	ad850513          	addi	a0,a0,-1320 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202fa8:	a6efd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0202fac:	00005697          	auipc	a3,0x5
ffffffffc0202fb0:	c8468693          	addi	a3,a3,-892 # ffffffffc0207c30 <commands+0x12c8>
ffffffffc0202fb4:	00004617          	auipc	a2,0x4
ffffffffc0202fb8:	e4c60613          	addi	a2,a2,-436 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202fbc:	12000593          	li	a1,288
ffffffffc0202fc0:	00005517          	auipc	a0,0x5
ffffffffc0202fc4:	ab850513          	addi	a0,a0,-1352 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202fc8:	a4efd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma3 == NULL);
ffffffffc0202fcc:	00005697          	auipc	a3,0x5
ffffffffc0202fd0:	cd468693          	addi	a3,a3,-812 # ffffffffc0207ca0 <commands+0x1338>
ffffffffc0202fd4:	00004617          	auipc	a2,0x4
ffffffffc0202fd8:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202fdc:	12c00593          	li	a1,300
ffffffffc0202fe0:	00005517          	auipc	a0,0x5
ffffffffc0202fe4:	a9850513          	addi	a0,a0,-1384 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0202fe8:	a2efd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma2 != NULL);
ffffffffc0202fec:	00005697          	auipc	a3,0x5
ffffffffc0202ff0:	ca468693          	addi	a3,a3,-860 # ffffffffc0207c90 <commands+0x1328>
ffffffffc0202ff4:	00004617          	auipc	a2,0x4
ffffffffc0202ff8:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206e00 <commands+0x498>
ffffffffc0202ffc:	12a00593          	li	a1,298
ffffffffc0203000:	00005517          	auipc	a0,0x5
ffffffffc0203004:	a7850513          	addi	a0,a0,-1416 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0203008:	a0efd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma1 != NULL);
ffffffffc020300c:	00005697          	auipc	a3,0x5
ffffffffc0203010:	c7468693          	addi	a3,a3,-908 # ffffffffc0207c80 <commands+0x1318>
ffffffffc0203014:	00004617          	auipc	a2,0x4
ffffffffc0203018:	dec60613          	addi	a2,a2,-532 # ffffffffc0206e00 <commands+0x498>
ffffffffc020301c:	12800593          	li	a1,296
ffffffffc0203020:	00005517          	auipc	a0,0x5
ffffffffc0203024:	a5850513          	addi	a0,a0,-1448 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0203028:	9eefd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma5 == NULL);
ffffffffc020302c:	00005697          	auipc	a3,0x5
ffffffffc0203030:	c9468693          	addi	a3,a3,-876 # ffffffffc0207cc0 <commands+0x1358>
ffffffffc0203034:	00004617          	auipc	a2,0x4
ffffffffc0203038:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206e00 <commands+0x498>
ffffffffc020303c:	13000593          	li	a1,304
ffffffffc0203040:	00005517          	auipc	a0,0x5
ffffffffc0203044:	a3850513          	addi	a0,a0,-1480 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0203048:	9cefd0ef          	jal	ra,ffffffffc0200216 <__panic>
        assert(vma4 == NULL);
ffffffffc020304c:	00005697          	auipc	a3,0x5
ffffffffc0203050:	c6468693          	addi	a3,a3,-924 # ffffffffc0207cb0 <commands+0x1348>
ffffffffc0203054:	00004617          	auipc	a2,0x4
ffffffffc0203058:	dac60613          	addi	a2,a2,-596 # ffffffffc0206e00 <commands+0x498>
ffffffffc020305c:	12e00593          	li	a1,302
ffffffffc0203060:	00005517          	auipc	a0,0x5
ffffffffc0203064:	a1850513          	addi	a0,a0,-1512 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0203068:	9aefd0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020306c:	00004617          	auipc	a2,0x4
ffffffffc0203070:	20460613          	addi	a2,a2,516 # ffffffffc0207270 <commands+0x908>
ffffffffc0203074:	06200593          	li	a1,98
ffffffffc0203078:	00004517          	auipc	a0,0x4
ffffffffc020307c:	21850513          	addi	a0,a0,536 # ffffffffc0207290 <commands+0x928>
ffffffffc0203080:	996fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(mm != NULL);
ffffffffc0203084:	00005697          	auipc	a3,0x5
ffffffffc0203088:	b9c68693          	addi	a3,a3,-1124 # ffffffffc0207c20 <commands+0x12b8>
ffffffffc020308c:	00004617          	auipc	a2,0x4
ffffffffc0203090:	d7460613          	addi	a2,a2,-652 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203094:	10c00593          	li	a1,268
ffffffffc0203098:	00005517          	auipc	a0,0x5
ffffffffc020309c:	9e050513          	addi	a0,a0,-1568 # ffffffffc0207a78 <commands+0x1110>
ffffffffc02030a0:	976fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02030a4:	00005697          	auipc	a3,0x5
ffffffffc02030a8:	d4468693          	addi	a3,a3,-700 # ffffffffc0207de8 <commands+0x1480>
ffffffffc02030ac:	00004617          	auipc	a2,0x4
ffffffffc02030b0:	d5460613          	addi	a2,a2,-684 # ffffffffc0206e00 <commands+0x498>
ffffffffc02030b4:	17000593          	li	a1,368
ffffffffc02030b8:	00005517          	auipc	a0,0x5
ffffffffc02030bc:	9c050513          	addi	a0,a0,-1600 # ffffffffc0207a78 <commands+0x1110>
ffffffffc02030c0:	956fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir[0] == 0);
ffffffffc02030c4:	00005697          	auipc	a3,0x5
ffffffffc02030c8:	ce468693          	addi	a3,a3,-796 # ffffffffc0207da8 <commands+0x1440>
ffffffffc02030cc:	00004617          	auipc	a2,0x4
ffffffffc02030d0:	d3460613          	addi	a2,a2,-716 # ffffffffc0206e00 <commands+0x498>
ffffffffc02030d4:	14f00593          	li	a1,335
ffffffffc02030d8:	00005517          	auipc	a0,0x5
ffffffffc02030dc:	9a050513          	addi	a0,a0,-1632 # ffffffffc0207a78 <commands+0x1110>
ffffffffc02030e0:	936fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc02030e4:	00005697          	auipc	a3,0x5
ffffffffc02030e8:	cd468693          	addi	a3,a3,-812 # ffffffffc0207db8 <commands+0x1450>
ffffffffc02030ec:	00004617          	auipc	a2,0x4
ffffffffc02030f0:	d1460613          	addi	a2,a2,-748 # ffffffffc0206e00 <commands+0x498>
ffffffffc02030f4:	15700593          	li	a1,343
ffffffffc02030f8:	00005517          	auipc	a0,0x5
ffffffffc02030fc:	98050513          	addi	a0,a0,-1664 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0203100:	916fd0ef          	jal	ra,ffffffffc0200216 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203104:	00004617          	auipc	a2,0x4
ffffffffc0203108:	13460613          	addi	a2,a2,308 # ffffffffc0207238 <commands+0x8d0>
ffffffffc020310c:	06900593          	li	a1,105
ffffffffc0203110:	00004517          	auipc	a0,0x4
ffffffffc0203114:	18050513          	addi	a0,a0,384 # ffffffffc0207290 <commands+0x928>
ffffffffc0203118:	8fefd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(sum == 0);
ffffffffc020311c:	00005697          	auipc	a3,0x5
ffffffffc0203120:	cbc68693          	addi	a3,a3,-836 # ffffffffc0207dd8 <commands+0x1470>
ffffffffc0203124:	00004617          	auipc	a2,0x4
ffffffffc0203128:	cdc60613          	addi	a2,a2,-804 # ffffffffc0206e00 <commands+0x498>
ffffffffc020312c:	16300593          	li	a1,355
ffffffffc0203130:	00005517          	auipc	a0,0x5
ffffffffc0203134:	94850513          	addi	a0,a0,-1720 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0203138:	8defd0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc020313c:	00005697          	auipc	a3,0x5
ffffffffc0203140:	c5468693          	addi	a3,a3,-940 # ffffffffc0207d90 <commands+0x1428>
ffffffffc0203144:	00004617          	auipc	a2,0x4
ffffffffc0203148:	cbc60613          	addi	a2,a2,-836 # ffffffffc0206e00 <commands+0x498>
ffffffffc020314c:	14b00593          	li	a1,331
ffffffffc0203150:	00005517          	auipc	a0,0x5
ffffffffc0203154:	92850513          	addi	a0,a0,-1752 # ffffffffc0207a78 <commands+0x1110>
ffffffffc0203158:	8befd0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020315c <do_pgfault>:
//    }
//    ret = 0;
// failed:
//     return ret;
// }
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020315c:	715d                	addi	sp,sp,-80
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020315e:	85b2                	mv	a1,a2
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0203160:	e0a2                	sd	s0,64(sp)
ffffffffc0203162:	fc26                	sd	s1,56(sp)
ffffffffc0203164:	e486                	sd	ra,72(sp)
ffffffffc0203166:	f84a                	sd	s2,48(sp)
ffffffffc0203168:	f44e                	sd	s3,40(sp)
ffffffffc020316a:	f052                	sd	s4,32(sp)
ffffffffc020316c:	ec56                	sd	s5,24(sp)
ffffffffc020316e:	8432                	mv	s0,a2
ffffffffc0203170:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203172:	f82ff0ef          	jal	ra,ffffffffc02028f4 <find_vma>

    pgfault_num++;
ffffffffc0203176:	000a9797          	auipc	a5,0xa9
ffffffffc020317a:	25a78793          	addi	a5,a5,602 # ffffffffc02ac3d0 <pgfault_num>
ffffffffc020317e:	439c                	lw	a5,0(a5)
ffffffffc0203180:	2785                	addiw	a5,a5,1
ffffffffc0203182:	000a9717          	auipc	a4,0xa9
ffffffffc0203186:	24f72723          	sw	a5,590(a4) # ffffffffc02ac3d0 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc020318a:	16050863          	beqz	a0,ffffffffc02032fa <do_pgfault+0x19e>
ffffffffc020318e:	651c                	ld	a5,8(a0)
ffffffffc0203190:	16f46563          	bltu	s0,a5,ffffffffc02032fa <do_pgfault+0x19e>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203194:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0203196:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203198:	8b89                	andi	a5,a5,2
ffffffffc020319a:	ebbd                	bnez	a5,ffffffffc0203210 <do_pgfault+0xb4>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020319c:	767d                	lui	a2,0xfffff

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;
    // 查找当前虚拟地址所对应的页表项
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc020319e:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02031a0:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02031a2:	85a2                	mv	a1,s0
ffffffffc02031a4:	4605                	li	a2,1
ffffffffc02031a6:	e13fd0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc02031aa:	892a                	mv	s2,a0
ffffffffc02031ac:	16050063          	beqz	a0,ffffffffc020330c <do_pgfault+0x1b0>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    // 如果这个页表项所对应的物理页不存在，则
    if (*ptep == 0) {
ffffffffc02031b0:	6110                	ld	a2,0(a0)
ffffffffc02031b2:	10060563          	beqz	a2,ffffffffc02032bc <do_pgfault+0x160>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    }
    else {
        struct Page *page=NULL;
ffffffffc02031b6:	e402                	sd	zero,8(sp)
        // 如果当前页错误的原因是写入了只读页面
        if (*ptep & PTE_V) {
ffffffffc02031b8:	00167793          	andi	a5,a2,1
ffffffffc02031bc:	efa1                	bnez	a5,ffffffffc0203214 <do_pgfault+0xb8>
                page_insert(mm->pgdir, page, addr, perm);
        }
        else
        {
            // 如果swap已经初始化完成
            if(swap_init_ok) {
ffffffffc02031be:	000a9797          	auipc	a5,0xa9
ffffffffc02031c2:	22a78793          	addi	a5,a5,554 # ffffffffc02ac3e8 <swap_init_ok>
ffffffffc02031c6:	439c                	lw	a5,0(a5)
ffffffffc02031c8:	2781                	sext.w	a5,a5
ffffffffc02031ca:	10078f63          	beqz	a5,ffffffffc02032e8 <do_pgfault+0x18c>
                // 将目标数据加载到某块新的物理页中。
                // 该物理页可能是尚未分配的物理页，也可能是从别的已分配物理页中取的
                if ((ret = swap_in(mm, addr, &page)) != 0) {
ffffffffc02031ce:	0030                	addi	a2,sp,8
ffffffffc02031d0:	85a2                	mv	a1,s0
ffffffffc02031d2:	8526                	mv	a0,s1
ffffffffc02031d4:	76d000ef          	jal	ra,ffffffffc0204140 <swap_in>
ffffffffc02031d8:	892a                	mv	s2,a0
ffffffffc02031da:	10051063          	bnez	a0,ffffffffc02032da <do_pgfault+0x17e>
                    cprintf("swap_in in do_pgfault failed\n");
                    goto failed;
                }
                // 将该物理页与对应的虚拟地址关联，同时设置页表。
                page_insert(mm->pgdir, page, addr, perm);
ffffffffc02031de:	65a2                	ld	a1,8(sp)
ffffffffc02031e0:	6c88                	ld	a0,24(s1)
ffffffffc02031e2:	86ce                	mv	a3,s3
ffffffffc02031e4:	8622                	mv	a2,s0
ffffffffc02031e6:	be8fe0ef          	jal	ra,ffffffffc02015ce <page_insert>
                cprintf("no swap_init_ok but ptep is %x, failed\n",*ptep);
                goto failed;
            }
        }
        // 当前缺失的页已经加载回内存中，所以设置当前页为可swap。
        swap_map_swappable(mm, addr, page, 1);
ffffffffc02031ea:	6622                	ld	a2,8(sp)
ffffffffc02031ec:	4685                	li	a3,1
ffffffffc02031ee:	85a2                	mv	a1,s0
ffffffffc02031f0:	8526                	mv	a0,s1
ffffffffc02031f2:	62b000ef          	jal	ra,ffffffffc020401c <swap_map_swappable>
        page->pra_vaddr = addr;
ffffffffc02031f6:	67a2                	ld	a5,8(sp)
   }
   ret = 0;
ffffffffc02031f8:	4901                	li	s2,0
        page->pra_vaddr = addr;
ffffffffc02031fa:	ff80                	sd	s0,56(a5)
failed:
    return ret;
}
ffffffffc02031fc:	60a6                	ld	ra,72(sp)
ffffffffc02031fe:	6406                	ld	s0,64(sp)
ffffffffc0203200:	854a                	mv	a0,s2
ffffffffc0203202:	74e2                	ld	s1,56(sp)
ffffffffc0203204:	7942                	ld	s2,48(sp)
ffffffffc0203206:	79a2                	ld	s3,40(sp)
ffffffffc0203208:	7a02                	ld	s4,32(sp)
ffffffffc020320a:	6ae2                	ld	s5,24(sp)
ffffffffc020320c:	6161                	addi	sp,sp,80
ffffffffc020320e:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0203210:	49dd                	li	s3,23
ffffffffc0203212:	b769                	j	ffffffffc020319c <do_pgfault+0x40>
            cprintf("\n\nCOW: ptep 0x%x, pte 0x%x\n",ptep, *ptep);
ffffffffc0203214:	85aa                	mv	a1,a0
ffffffffc0203216:	00005517          	auipc	a0,0x5
ffffffffc020321a:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0207b00 <commands+0x1198>
ffffffffc020321e:	eb3fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
            page = pte2page(*ptep);
ffffffffc0203222:	00093783          	ld	a5,0(s2)
    if (!(pte & PTE_V)) {
ffffffffc0203226:	0017f713          	andi	a4,a5,1
ffffffffc020322a:	10070663          	beqz	a4,ffffffffc0203336 <do_pgfault+0x1da>
    if (PPN(pa) >= npage) {
ffffffffc020322e:	000a9a17          	auipc	s4,0xa9
ffffffffc0203232:	19aa0a13          	addi	s4,s4,410 # ffffffffc02ac3c8 <npage>
ffffffffc0203236:	000a3703          	ld	a4,0(s4)
    return pa2page(PTE_ADDR(pte));
ffffffffc020323a:	078a                	slli	a5,a5,0x2
ffffffffc020323c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020323e:	10e7f863          	bleu	a4,a5,ffffffffc020334e <do_pgfault+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc0203242:	00006717          	auipc	a4,0x6
ffffffffc0203246:	d3670713          	addi	a4,a4,-714 # ffffffffc0208f78 <nbase>
ffffffffc020324a:	00073903          	ld	s2,0(a4)
ffffffffc020324e:	000a9a97          	auipc	s5,0xa9
ffffffffc0203252:	1e2a8a93          	addi	s5,s5,482 # ffffffffc02ac430 <pages>
ffffffffc0203256:	000ab583          	ld	a1,0(s5)
ffffffffc020325a:	412787b3          	sub	a5,a5,s2
ffffffffc020325e:	079a                	slli	a5,a5,0x6
ffffffffc0203260:	95be                	add	a1,a1,a5
            if(page_ref(page) > 1)
ffffffffc0203262:	4198                	lw	a4,0(a1)
ffffffffc0203264:	4785                	li	a5,1
            page = pte2page(*ptep);
ffffffffc0203266:	e42e                	sd	a1,8(sp)
    return page->ref;
ffffffffc0203268:	6c88                	ld	a0,24(s1)
            if(page_ref(page) > 1)
ffffffffc020326a:	f6e7dce3          	ble	a4,a5,ffffffffc02031e2 <do_pgfault+0x86>
                struct Page* newPage = pgdir_alloc_page(mm->pgdir, addr, perm);
ffffffffc020326e:	864e                	mv	a2,s3
ffffffffc0203270:	85a2                	mv	a1,s0
ffffffffc0203272:	968ff0ef          	jal	ra,ffffffffc02023da <pgdir_alloc_page>
    return page - pages + nbase;
ffffffffc0203276:	000ab783          	ld	a5,0(s5)
ffffffffc020327a:	66a2                	ld	a3,8(sp)
    return KADDR(page2pa(page));
ffffffffc020327c:	577d                	li	a4,-1
ffffffffc020327e:	000a3603          	ld	a2,0(s4)
    return page - pages + nbase;
ffffffffc0203282:	8e9d                	sub	a3,a3,a5
ffffffffc0203284:	8699                	srai	a3,a3,0x6
ffffffffc0203286:	96ca                	add	a3,a3,s2
    return KADDR(page2pa(page));
ffffffffc0203288:	8331                	srli	a4,a4,0xc
ffffffffc020328a:	00e6f5b3          	and	a1,a3,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc020328e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203290:	08c5f763          	bleu	a2,a1,ffffffffc020331e <do_pgfault+0x1c2>
    return page - pages + nbase;
ffffffffc0203294:	40f507b3          	sub	a5,a0,a5
    return KADDR(page2pa(page));
ffffffffc0203298:	000a9597          	auipc	a1,0xa9
ffffffffc020329c:	18858593          	addi	a1,a1,392 # ffffffffc02ac420 <va_pa_offset>
ffffffffc02032a0:	6188                	ld	a0,0(a1)
    return page - pages + nbase;
ffffffffc02032a2:	8799                	srai	a5,a5,0x6
ffffffffc02032a4:	97ca                	add	a5,a5,s2
    return KADDR(page2pa(page));
ffffffffc02032a6:	8f7d                	and	a4,a4,a5
ffffffffc02032a8:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02032ac:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02032ae:	06c77763          	bleu	a2,a4,ffffffffc020331c <do_pgfault+0x1c0>
                memcpy(kva_dst, kva_src, PGSIZE);
ffffffffc02032b2:	6605                	lui	a2,0x1
ffffffffc02032b4:	953e                	add	a0,a0,a5
ffffffffc02032b6:	118030ef          	jal	ra,ffffffffc02063ce <memcpy>
ffffffffc02032ba:	bf05                	j	ffffffffc02031ea <do_pgfault+0x8e>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02032bc:	6c88                	ld	a0,24(s1)
ffffffffc02032be:	864e                	mv	a2,s3
ffffffffc02032c0:	85a2                	mv	a1,s0
ffffffffc02032c2:	918ff0ef          	jal	ra,ffffffffc02023da <pgdir_alloc_page>
   ret = 0;
ffffffffc02032c6:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02032c8:	f915                	bnez	a0,ffffffffc02031fc <do_pgfault+0xa0>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc02032ca:	00005517          	auipc	a0,0x5
ffffffffc02032ce:	80e50513          	addi	a0,a0,-2034 # ffffffffc0207ad8 <commands+0x1170>
ffffffffc02032d2:	dfffc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02032d6:	5971                	li	s2,-4
            goto failed;
ffffffffc02032d8:	b715                	j	ffffffffc02031fc <do_pgfault+0xa0>
                    cprintf("swap_in in do_pgfault failed\n");
ffffffffc02032da:	00005517          	auipc	a0,0x5
ffffffffc02032de:	84650513          	addi	a0,a0,-1978 # ffffffffc0207b20 <commands+0x11b8>
ffffffffc02032e2:	deffc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                    goto failed;
ffffffffc02032e6:	bf19                	j	ffffffffc02031fc <do_pgfault+0xa0>
                cprintf("no swap_init_ok but ptep is %x, failed\n",*ptep);
ffffffffc02032e8:	85b2                	mv	a1,a2
ffffffffc02032ea:	00005517          	auipc	a0,0x5
ffffffffc02032ee:	85650513          	addi	a0,a0,-1962 # ffffffffc0207b40 <commands+0x11d8>
ffffffffc02032f2:	ddffc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02032f6:	5971                	li	s2,-4
                goto failed;
ffffffffc02032f8:	b711                	j	ffffffffc02031fc <do_pgfault+0xa0>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02032fa:	85a2                	mv	a1,s0
ffffffffc02032fc:	00004517          	auipc	a0,0x4
ffffffffc0203300:	78c50513          	addi	a0,a0,1932 # ffffffffc0207a88 <commands+0x1120>
ffffffffc0203304:	dcdfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    int ret = -E_INVAL;
ffffffffc0203308:	5975                	li	s2,-3
        goto failed;
ffffffffc020330a:	bdcd                	j	ffffffffc02031fc <do_pgfault+0xa0>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc020330c:	00004517          	auipc	a0,0x4
ffffffffc0203310:	7ac50513          	addi	a0,a0,1964 # ffffffffc0207ab8 <commands+0x1150>
ffffffffc0203314:	dbdfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0203318:	5971                	li	s2,-4
        goto failed;
ffffffffc020331a:	b5cd                	j	ffffffffc02031fc <do_pgfault+0xa0>
ffffffffc020331c:	86be                	mv	a3,a5
ffffffffc020331e:	00004617          	auipc	a2,0x4
ffffffffc0203322:	f1a60613          	addi	a2,a2,-230 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0203326:	06900593          	li	a1,105
ffffffffc020332a:	00004517          	auipc	a0,0x4
ffffffffc020332e:	f6650513          	addi	a0,a0,-154 # ffffffffc0207290 <commands+0x928>
ffffffffc0203332:	ee5fc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203336:	00004617          	auipc	a2,0x4
ffffffffc020333a:	11a60613          	addi	a2,a2,282 # ffffffffc0207450 <commands+0xae8>
ffffffffc020333e:	07400593          	li	a1,116
ffffffffc0203342:	00004517          	auipc	a0,0x4
ffffffffc0203346:	f4e50513          	addi	a0,a0,-178 # ffffffffc0207290 <commands+0x928>
ffffffffc020334a:	ecdfc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020334e:	00004617          	auipc	a2,0x4
ffffffffc0203352:	f2260613          	addi	a2,a2,-222 # ffffffffc0207270 <commands+0x908>
ffffffffc0203356:	06200593          	li	a1,98
ffffffffc020335a:	00004517          	auipc	a0,0x4
ffffffffc020335e:	f3650513          	addi	a0,a0,-202 # ffffffffc0207290 <commands+0x928>
ffffffffc0203362:	eb5fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0203366 <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0203366:	7179                	addi	sp,sp,-48
ffffffffc0203368:	f022                	sd	s0,32(sp)
ffffffffc020336a:	f406                	sd	ra,40(sp)
ffffffffc020336c:	ec26                	sd	s1,24(sp)
ffffffffc020336e:	e84a                	sd	s2,16(sp)
ffffffffc0203370:	e44e                	sd	s3,8(sp)
ffffffffc0203372:	e052                	sd	s4,0(sp)
ffffffffc0203374:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc0203376:	c135                	beqz	a0,ffffffffc02033da <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0203378:	002007b7          	lui	a5,0x200
ffffffffc020337c:	04f5e663          	bltu	a1,a5,ffffffffc02033c8 <user_mem_check+0x62>
ffffffffc0203380:	00c584b3          	add	s1,a1,a2
ffffffffc0203384:	0495f263          	bleu	s1,a1,ffffffffc02033c8 <user_mem_check+0x62>
ffffffffc0203388:	4785                	li	a5,1
ffffffffc020338a:	07fe                	slli	a5,a5,0x1f
ffffffffc020338c:	0297ee63          	bltu	a5,s1,ffffffffc02033c8 <user_mem_check+0x62>
ffffffffc0203390:	892a                	mv	s2,a0
ffffffffc0203392:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0203394:	6a05                	lui	s4,0x1
ffffffffc0203396:	a821                	j	ffffffffc02033ae <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0203398:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc020339c:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc020339e:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc02033a0:	c685                	beqz	a3,ffffffffc02033c8 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc02033a2:	c399                	beqz	a5,ffffffffc02033a8 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc02033a4:	02e46263          	bltu	s0,a4,ffffffffc02033c8 <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc02033a8:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc02033aa:	04947663          	bleu	s1,s0,ffffffffc02033f6 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc02033ae:	85a2                	mv	a1,s0
ffffffffc02033b0:	854a                	mv	a0,s2
ffffffffc02033b2:	d42ff0ef          	jal	ra,ffffffffc02028f4 <find_vma>
ffffffffc02033b6:	c909                	beqz	a0,ffffffffc02033c8 <user_mem_check+0x62>
ffffffffc02033b8:	6518                	ld	a4,8(a0)
ffffffffc02033ba:	00e46763          	bltu	s0,a4,ffffffffc02033c8 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc02033be:	4d1c                	lw	a5,24(a0)
ffffffffc02033c0:	fc099ce3          	bnez	s3,ffffffffc0203398 <user_mem_check+0x32>
ffffffffc02033c4:	8b85                	andi	a5,a5,1
ffffffffc02033c6:	f3ed                	bnez	a5,ffffffffc02033a8 <user_mem_check+0x42>
            return 0;
ffffffffc02033c8:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc02033ca:	70a2                	ld	ra,40(sp)
ffffffffc02033cc:	7402                	ld	s0,32(sp)
ffffffffc02033ce:	64e2                	ld	s1,24(sp)
ffffffffc02033d0:	6942                	ld	s2,16(sp)
ffffffffc02033d2:	69a2                	ld	s3,8(sp)
ffffffffc02033d4:	6a02                	ld	s4,0(sp)
ffffffffc02033d6:	6145                	addi	sp,sp,48
ffffffffc02033d8:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc02033da:	c02007b7          	lui	a5,0xc0200
ffffffffc02033de:	4501                	li	a0,0
ffffffffc02033e0:	fef5e5e3          	bltu	a1,a5,ffffffffc02033ca <user_mem_check+0x64>
ffffffffc02033e4:	962e                	add	a2,a2,a1
ffffffffc02033e6:	fec5f2e3          	bleu	a2,a1,ffffffffc02033ca <user_mem_check+0x64>
ffffffffc02033ea:	c8000537          	lui	a0,0xc8000
ffffffffc02033ee:	0505                	addi	a0,a0,1
ffffffffc02033f0:	00a63533          	sltu	a0,a2,a0
ffffffffc02033f4:	bfd9                	j	ffffffffc02033ca <user_mem_check+0x64>
        return 1;
ffffffffc02033f6:	4505                	li	a0,1
ffffffffc02033f8:	bfc9                	j	ffffffffc02033ca <user_mem_check+0x64>

ffffffffc02033fa <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02033fa:	c125                	beqz	a0,ffffffffc020345a <slob_free+0x60>
		return;

	if (size)
ffffffffc02033fc:	e1a5                	bnez	a1,ffffffffc020345c <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02033fe:	100027f3          	csrr	a5,sstatus
ffffffffc0203402:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203404:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203406:	e3bd                	bnez	a5,ffffffffc020346c <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203408:	0009e797          	auipc	a5,0x9e
ffffffffc020340c:	b9878793          	addi	a5,a5,-1128 # ffffffffc02a0fa0 <slobfree>
ffffffffc0203410:	639c                	ld	a5,0(a5)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203412:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203414:	00a7fa63          	bleu	a0,a5,ffffffffc0203428 <slob_free+0x2e>
ffffffffc0203418:	00e56c63          	bltu	a0,a4,ffffffffc0203430 <slob_free+0x36>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020341c:	00e7fa63          	bleu	a4,a5,ffffffffc0203430 <slob_free+0x36>
    return 0;
ffffffffc0203420:	87ba                	mv	a5,a4
ffffffffc0203422:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203424:	fea7eae3          	bltu	a5,a0,ffffffffc0203418 <slob_free+0x1e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203428:	fee7ece3          	bltu	a5,a4,ffffffffc0203420 <slob_free+0x26>
ffffffffc020342c:	fee57ae3          	bleu	a4,a0,ffffffffc0203420 <slob_free+0x26>
			break;

	if (b + b->units == cur->next) {
ffffffffc0203430:	4110                	lw	a2,0(a0)
ffffffffc0203432:	00461693          	slli	a3,a2,0x4
ffffffffc0203436:	96aa                	add	a3,a3,a0
ffffffffc0203438:	08d70b63          	beq	a4,a3,ffffffffc02034ce <slob_free+0xd4>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc020343c:	4394                	lw	a3,0(a5)
		b->next = cur->next;
ffffffffc020343e:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0203440:	00469713          	slli	a4,a3,0x4
ffffffffc0203444:	973e                	add	a4,a4,a5
ffffffffc0203446:	08e50f63          	beq	a0,a4,ffffffffc02034e4 <slob_free+0xea>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc020344a:	e788                	sd	a0,8(a5)

	slobfree = cur;
ffffffffc020344c:	0009e717          	auipc	a4,0x9e
ffffffffc0203450:	b4f73a23          	sd	a5,-1196(a4) # ffffffffc02a0fa0 <slobfree>
    if (flag) {
ffffffffc0203454:	c199                	beqz	a1,ffffffffc020345a <slob_free+0x60>
        intr_enable();
ffffffffc0203456:	a00fd06f          	j	ffffffffc0200656 <intr_enable>
ffffffffc020345a:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc020345c:	05bd                	addi	a1,a1,15
ffffffffc020345e:	8191                	srli	a1,a1,0x4
ffffffffc0203460:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203462:	100027f3          	csrr	a5,sstatus
ffffffffc0203466:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203468:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020346a:	dfd9                	beqz	a5,ffffffffc0203408 <slob_free+0xe>
{
ffffffffc020346c:	1101                	addi	sp,sp,-32
ffffffffc020346e:	e42a                	sd	a0,8(sp)
ffffffffc0203470:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0203472:	9eafd0ef          	jal	ra,ffffffffc020065c <intr_disable>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203476:	0009e797          	auipc	a5,0x9e
ffffffffc020347a:	b2a78793          	addi	a5,a5,-1238 # ffffffffc02a0fa0 <slobfree>
ffffffffc020347e:	639c                	ld	a5,0(a5)
        return 1;
ffffffffc0203480:	6522                	ld	a0,8(sp)
ffffffffc0203482:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0203484:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203486:	00a7fa63          	bleu	a0,a5,ffffffffc020349a <slob_free+0xa0>
ffffffffc020348a:	00e56c63          	bltu	a0,a4,ffffffffc02034a2 <slob_free+0xa8>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020348e:	00e7fa63          	bleu	a4,a5,ffffffffc02034a2 <slob_free+0xa8>
    return 0;
ffffffffc0203492:	87ba                	mv	a5,a4
ffffffffc0203494:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0203496:	fea7eae3          	bltu	a5,a0,ffffffffc020348a <slob_free+0x90>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020349a:	fee7ece3          	bltu	a5,a4,ffffffffc0203492 <slob_free+0x98>
ffffffffc020349e:	fee57ae3          	bleu	a4,a0,ffffffffc0203492 <slob_free+0x98>
	if (b + b->units == cur->next) {
ffffffffc02034a2:	4110                	lw	a2,0(a0)
ffffffffc02034a4:	00461693          	slli	a3,a2,0x4
ffffffffc02034a8:	96aa                	add	a3,a3,a0
ffffffffc02034aa:	04d70763          	beq	a4,a3,ffffffffc02034f8 <slob_free+0xfe>
		b->next = cur->next;
ffffffffc02034ae:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02034b0:	4394                	lw	a3,0(a5)
ffffffffc02034b2:	00469713          	slli	a4,a3,0x4
ffffffffc02034b6:	973e                	add	a4,a4,a5
ffffffffc02034b8:	04e50663          	beq	a0,a4,ffffffffc0203504 <slob_free+0x10a>
		cur->next = b;
ffffffffc02034bc:	e788                	sd	a0,8(a5)
	slobfree = cur;
ffffffffc02034be:	0009e717          	auipc	a4,0x9e
ffffffffc02034c2:	aef73123          	sd	a5,-1310(a4) # ffffffffc02a0fa0 <slobfree>
    if (flag) {
ffffffffc02034c6:	e58d                	bnez	a1,ffffffffc02034f0 <slob_free+0xf6>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02034c8:	60e2                	ld	ra,24(sp)
ffffffffc02034ca:	6105                	addi	sp,sp,32
ffffffffc02034cc:	8082                	ret
		b->units += cur->next->units;
ffffffffc02034ce:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02034d0:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc02034d2:	9e35                	addw	a2,a2,a3
ffffffffc02034d4:	c110                	sw	a2,0(a0)
	if (cur + cur->units == b) {
ffffffffc02034d6:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02034d8:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02034da:	00469713          	slli	a4,a3,0x4
ffffffffc02034de:	973e                	add	a4,a4,a5
ffffffffc02034e0:	f6e515e3          	bne	a0,a4,ffffffffc020344a <slob_free+0x50>
		cur->units += b->units;
ffffffffc02034e4:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc02034e6:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc02034e8:	9eb9                	addw	a3,a3,a4
ffffffffc02034ea:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc02034ec:	e790                	sd	a2,8(a5)
ffffffffc02034ee:	bfb9                	j	ffffffffc020344c <slob_free+0x52>
}
ffffffffc02034f0:	60e2                	ld	ra,24(sp)
ffffffffc02034f2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02034f4:	962fd06f          	j	ffffffffc0200656 <intr_enable>
		b->units += cur->next->units;
ffffffffc02034f8:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02034fa:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc02034fc:	9e35                	addw	a2,a2,a3
ffffffffc02034fe:	c110                	sw	a2,0(a0)
		b->next = cur->next->next;
ffffffffc0203500:	e518                	sd	a4,8(a0)
ffffffffc0203502:	b77d                	j	ffffffffc02034b0 <slob_free+0xb6>
		cur->units += b->units;
ffffffffc0203504:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0203506:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0203508:	9eb9                	addw	a3,a3,a4
ffffffffc020350a:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc020350c:	e790                	sd	a2,8(a5)
ffffffffc020350e:	bf45                	j	ffffffffc02034be <slob_free+0xc4>

ffffffffc0203510 <__slob_get_free_pages.isra.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0203510:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0203512:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0203514:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0203518:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc020351a:	991fd0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
  if(!page)
ffffffffc020351e:	c139                	beqz	a0,ffffffffc0203564 <__slob_get_free_pages.isra.0+0x54>
    return page - pages + nbase;
ffffffffc0203520:	000a9797          	auipc	a5,0xa9
ffffffffc0203524:	f1078793          	addi	a5,a5,-240 # ffffffffc02ac430 <pages>
ffffffffc0203528:	6394                	ld	a3,0(a5)
ffffffffc020352a:	00006797          	auipc	a5,0x6
ffffffffc020352e:	a4e78793          	addi	a5,a5,-1458 # ffffffffc0208f78 <nbase>
    return KADDR(page2pa(page));
ffffffffc0203532:	000a9717          	auipc	a4,0xa9
ffffffffc0203536:	e9670713          	addi	a4,a4,-362 # ffffffffc02ac3c8 <npage>
    return page - pages + nbase;
ffffffffc020353a:	40d506b3          	sub	a3,a0,a3
ffffffffc020353e:	6388                	ld	a0,0(a5)
ffffffffc0203540:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203542:	57fd                	li	a5,-1
ffffffffc0203544:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0203546:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0203548:	83b1                	srli	a5,a5,0xc
ffffffffc020354a:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020354c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020354e:	00e7ff63          	bleu	a4,a5,ffffffffc020356c <__slob_get_free_pages.isra.0+0x5c>
ffffffffc0203552:	000a9797          	auipc	a5,0xa9
ffffffffc0203556:	ece78793          	addi	a5,a5,-306 # ffffffffc02ac420 <va_pa_offset>
ffffffffc020355a:	6388                	ld	a0,0(a5)
}
ffffffffc020355c:	60a2                	ld	ra,8(sp)
ffffffffc020355e:	9536                	add	a0,a0,a3
ffffffffc0203560:	0141                	addi	sp,sp,16
ffffffffc0203562:	8082                	ret
ffffffffc0203564:	60a2                	ld	ra,8(sp)
    return NULL;
ffffffffc0203566:	4501                	li	a0,0
}
ffffffffc0203568:	0141                	addi	sp,sp,16
ffffffffc020356a:	8082                	ret
ffffffffc020356c:	00004617          	auipc	a2,0x4
ffffffffc0203570:	ccc60613          	addi	a2,a2,-820 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0203574:	06900593          	li	a1,105
ffffffffc0203578:	00004517          	auipc	a0,0x4
ffffffffc020357c:	d1850513          	addi	a0,a0,-744 # ffffffffc0207290 <commands+0x928>
ffffffffc0203580:	c97fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0203584 <slob_alloc.isra.1.constprop.3>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0203584:	7179                	addi	sp,sp,-48
ffffffffc0203586:	f406                	sd	ra,40(sp)
ffffffffc0203588:	f022                	sd	s0,32(sp)
ffffffffc020358a:	ec26                	sd	s1,24(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc020358c:	01050713          	addi	a4,a0,16
ffffffffc0203590:	6785                	lui	a5,0x1
ffffffffc0203592:	0cf77b63          	bleu	a5,a4,ffffffffc0203668 <slob_alloc.isra.1.constprop.3+0xe4>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0203596:	00f50413          	addi	s0,a0,15
ffffffffc020359a:	8011                	srli	s0,s0,0x4
ffffffffc020359c:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020359e:	10002673          	csrr	a2,sstatus
ffffffffc02035a2:	8a09                	andi	a2,a2,2
ffffffffc02035a4:	ea5d                	bnez	a2,ffffffffc020365a <slob_alloc.isra.1.constprop.3+0xd6>
	prev = slobfree;
ffffffffc02035a6:	0009e497          	auipc	s1,0x9e
ffffffffc02035aa:	9fa48493          	addi	s1,s1,-1542 # ffffffffc02a0fa0 <slobfree>
ffffffffc02035ae:	6094                	ld	a3,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02035b0:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02035b2:	4398                	lw	a4,0(a5)
ffffffffc02035b4:	0a875763          	ble	s0,a4,ffffffffc0203662 <slob_alloc.isra.1.constprop.3+0xde>
		if (cur == slobfree) {
ffffffffc02035b8:	00f68a63          	beq	a3,a5,ffffffffc02035cc <slob_alloc.isra.1.constprop.3+0x48>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02035bc:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02035be:	4118                	lw	a4,0(a0)
ffffffffc02035c0:	02875763          	ble	s0,a4,ffffffffc02035ee <slob_alloc.isra.1.constprop.3+0x6a>
ffffffffc02035c4:	6094                	ld	a3,0(s1)
ffffffffc02035c6:	87aa                	mv	a5,a0
		if (cur == slobfree) {
ffffffffc02035c8:	fef69ae3          	bne	a3,a5,ffffffffc02035bc <slob_alloc.isra.1.constprop.3+0x38>
    if (flag) {
ffffffffc02035cc:	ea39                	bnez	a2,ffffffffc0203622 <slob_alloc.isra.1.constprop.3+0x9e>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02035ce:	4501                	li	a0,0
ffffffffc02035d0:	f41ff0ef          	jal	ra,ffffffffc0203510 <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc02035d4:	cd29                	beqz	a0,ffffffffc020362e <slob_alloc.isra.1.constprop.3+0xaa>
			slob_free(cur, PAGE_SIZE);
ffffffffc02035d6:	6585                	lui	a1,0x1
ffffffffc02035d8:	e23ff0ef          	jal	ra,ffffffffc02033fa <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02035dc:	10002673          	csrr	a2,sstatus
ffffffffc02035e0:	8a09                	andi	a2,a2,2
ffffffffc02035e2:	ea1d                	bnez	a2,ffffffffc0203618 <slob_alloc.isra.1.constprop.3+0x94>
			cur = slobfree;
ffffffffc02035e4:	609c                	ld	a5,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02035e6:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02035e8:	4118                	lw	a4,0(a0)
ffffffffc02035ea:	fc874de3          	blt	a4,s0,ffffffffc02035c4 <slob_alloc.isra.1.constprop.3+0x40>
			if (cur->units == units) /* exact fit? */
ffffffffc02035ee:	04e40663          	beq	s0,a4,ffffffffc020363a <slob_alloc.isra.1.constprop.3+0xb6>
				prev->next = cur + units;
ffffffffc02035f2:	00441693          	slli	a3,s0,0x4
ffffffffc02035f6:	96aa                	add	a3,a3,a0
ffffffffc02035f8:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02035fa:	650c                	ld	a1,8(a0)
				prev->next->units = cur->units - units;
ffffffffc02035fc:	9f01                	subw	a4,a4,s0
ffffffffc02035fe:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0203600:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0203602:	c100                	sw	s0,0(a0)
			slobfree = prev;
ffffffffc0203604:	0009e717          	auipc	a4,0x9e
ffffffffc0203608:	98f73e23          	sd	a5,-1636(a4) # ffffffffc02a0fa0 <slobfree>
    if (flag) {
ffffffffc020360c:	ee15                	bnez	a2,ffffffffc0203648 <slob_alloc.isra.1.constprop.3+0xc4>
}
ffffffffc020360e:	70a2                	ld	ra,40(sp)
ffffffffc0203610:	7402                	ld	s0,32(sp)
ffffffffc0203612:	64e2                	ld	s1,24(sp)
ffffffffc0203614:	6145                	addi	sp,sp,48
ffffffffc0203616:	8082                	ret
        intr_disable();
ffffffffc0203618:	844fd0ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc020361c:	4605                	li	a2,1
			cur = slobfree;
ffffffffc020361e:	609c                	ld	a5,0(s1)
ffffffffc0203620:	b7d9                	j	ffffffffc02035e6 <slob_alloc.isra.1.constprop.3+0x62>
        intr_enable();
ffffffffc0203622:	834fd0ef          	jal	ra,ffffffffc0200656 <intr_enable>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0203626:	4501                	li	a0,0
ffffffffc0203628:	ee9ff0ef          	jal	ra,ffffffffc0203510 <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc020362c:	f54d                	bnez	a0,ffffffffc02035d6 <slob_alloc.isra.1.constprop.3+0x52>
}
ffffffffc020362e:	70a2                	ld	ra,40(sp)
ffffffffc0203630:	7402                	ld	s0,32(sp)
ffffffffc0203632:	64e2                	ld	s1,24(sp)
				return 0;
ffffffffc0203634:	4501                	li	a0,0
}
ffffffffc0203636:	6145                	addi	sp,sp,48
ffffffffc0203638:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc020363a:	6518                	ld	a4,8(a0)
ffffffffc020363c:	e798                	sd	a4,8(a5)
			slobfree = prev;
ffffffffc020363e:	0009e717          	auipc	a4,0x9e
ffffffffc0203642:	96f73123          	sd	a5,-1694(a4) # ffffffffc02a0fa0 <slobfree>
    if (flag) {
ffffffffc0203646:	d661                	beqz	a2,ffffffffc020360e <slob_alloc.isra.1.constprop.3+0x8a>
ffffffffc0203648:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020364a:	80cfd0ef          	jal	ra,ffffffffc0200656 <intr_enable>
}
ffffffffc020364e:	70a2                	ld	ra,40(sp)
ffffffffc0203650:	7402                	ld	s0,32(sp)
ffffffffc0203652:	6522                	ld	a0,8(sp)
ffffffffc0203654:	64e2                	ld	s1,24(sp)
ffffffffc0203656:	6145                	addi	sp,sp,48
ffffffffc0203658:	8082                	ret
        intr_disable();
ffffffffc020365a:	802fd0ef          	jal	ra,ffffffffc020065c <intr_disable>
ffffffffc020365e:	4605                	li	a2,1
ffffffffc0203660:	b799                	j	ffffffffc02035a6 <slob_alloc.isra.1.constprop.3+0x22>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0203662:	853e                	mv	a0,a5
ffffffffc0203664:	87b6                	mv	a5,a3
ffffffffc0203666:	b761                	j	ffffffffc02035ee <slob_alloc.isra.1.constprop.3+0x6a>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0203668:	00005697          	auipc	a3,0x5
ffffffffc020366c:	81068693          	addi	a3,a3,-2032 # ffffffffc0207e78 <commands+0x1510>
ffffffffc0203670:	00003617          	auipc	a2,0x3
ffffffffc0203674:	79060613          	addi	a2,a2,1936 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203678:	06400593          	li	a1,100
ffffffffc020367c:	00005517          	auipc	a0,0x5
ffffffffc0203680:	81c50513          	addi	a0,a0,-2020 # ffffffffc0207e98 <commands+0x1530>
ffffffffc0203684:	b93fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0203688 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0203688:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc020368a:	00005517          	auipc	a0,0x5
ffffffffc020368e:	82650513          	addi	a0,a0,-2010 # ffffffffc0207eb0 <commands+0x1548>
kmalloc_init(void) {
ffffffffc0203692:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0203694:	a3dfc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0203698:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc020369a:	00004517          	auipc	a0,0x4
ffffffffc020369e:	7be50513          	addi	a0,a0,1982 # ffffffffc0207e58 <commands+0x14f0>
}
ffffffffc02036a2:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc02036a4:	a2dfc06f          	j	ffffffffc02000d0 <cprintf>

ffffffffc02036a8 <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc02036a8:	4501                	li	a0,0
ffffffffc02036aa:	8082                	ret

ffffffffc02036ac <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc02036ac:	1101                	addi	sp,sp,-32
ffffffffc02036ae:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02036b0:	6905                	lui	s2,0x1
{
ffffffffc02036b2:	e822                	sd	s0,16(sp)
ffffffffc02036b4:	ec06                	sd	ra,24(sp)
ffffffffc02036b6:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02036b8:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8581>
{
ffffffffc02036bc:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc02036be:	04a7fc63          	bleu	a0,a5,ffffffffc0203716 <kmalloc+0x6a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc02036c2:	4561                	li	a0,24
ffffffffc02036c4:	ec1ff0ef          	jal	ra,ffffffffc0203584 <slob_alloc.isra.1.constprop.3>
ffffffffc02036c8:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc02036ca:	cd21                	beqz	a0,ffffffffc0203722 <kmalloc+0x76>
	bb->order = find_order(size);
ffffffffc02036cc:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc02036d0:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc02036d2:	00f95763          	ble	a5,s2,ffffffffc02036e0 <kmalloc+0x34>
ffffffffc02036d6:	6705                	lui	a4,0x1
ffffffffc02036d8:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc02036da:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc02036dc:	fef74ee3          	blt	a4,a5,ffffffffc02036d8 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc02036e0:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc02036e2:	e2fff0ef          	jal	ra,ffffffffc0203510 <__slob_get_free_pages.isra.0>
ffffffffc02036e6:	e488                	sd	a0,8(s1)
ffffffffc02036e8:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc02036ea:	c935                	beqz	a0,ffffffffc020375e <kmalloc+0xb2>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02036ec:	100027f3          	csrr	a5,sstatus
ffffffffc02036f0:	8b89                	andi	a5,a5,2
ffffffffc02036f2:	e3a1                	bnez	a5,ffffffffc0203732 <kmalloc+0x86>
		bb->next = bigblocks;
ffffffffc02036f4:	000a9797          	auipc	a5,0xa9
ffffffffc02036f8:	ce478793          	addi	a5,a5,-796 # ffffffffc02ac3d8 <bigblocks>
ffffffffc02036fc:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc02036fe:	000a9717          	auipc	a4,0xa9
ffffffffc0203702:	cc973d23          	sd	s1,-806(a4) # ffffffffc02ac3d8 <bigblocks>
		bb->next = bigblocks;
ffffffffc0203706:	e89c                	sd	a5,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0203708:	8522                	mv	a0,s0
ffffffffc020370a:	60e2                	ld	ra,24(sp)
ffffffffc020370c:	6442                	ld	s0,16(sp)
ffffffffc020370e:	64a2                	ld	s1,8(sp)
ffffffffc0203710:	6902                	ld	s2,0(sp)
ffffffffc0203712:	6105                	addi	sp,sp,32
ffffffffc0203714:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0203716:	0541                	addi	a0,a0,16
ffffffffc0203718:	e6dff0ef          	jal	ra,ffffffffc0203584 <slob_alloc.isra.1.constprop.3>
		return m ? (void *)(m + 1) : 0;
ffffffffc020371c:	01050413          	addi	s0,a0,16
ffffffffc0203720:	f565                	bnez	a0,ffffffffc0203708 <kmalloc+0x5c>
ffffffffc0203722:	4401                	li	s0,0
}
ffffffffc0203724:	8522                	mv	a0,s0
ffffffffc0203726:	60e2                	ld	ra,24(sp)
ffffffffc0203728:	6442                	ld	s0,16(sp)
ffffffffc020372a:	64a2                	ld	s1,8(sp)
ffffffffc020372c:	6902                	ld	s2,0(sp)
ffffffffc020372e:	6105                	addi	sp,sp,32
ffffffffc0203730:	8082                	ret
        intr_disable();
ffffffffc0203732:	f2bfc0ef          	jal	ra,ffffffffc020065c <intr_disable>
		bb->next = bigblocks;
ffffffffc0203736:	000a9797          	auipc	a5,0xa9
ffffffffc020373a:	ca278793          	addi	a5,a5,-862 # ffffffffc02ac3d8 <bigblocks>
ffffffffc020373e:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0203740:	000a9717          	auipc	a4,0xa9
ffffffffc0203744:	c8973c23          	sd	s1,-872(a4) # ffffffffc02ac3d8 <bigblocks>
		bb->next = bigblocks;
ffffffffc0203748:	e89c                	sd	a5,16(s1)
        intr_enable();
ffffffffc020374a:	f0dfc0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc020374e:	6480                	ld	s0,8(s1)
}
ffffffffc0203750:	60e2                	ld	ra,24(sp)
ffffffffc0203752:	64a2                	ld	s1,8(sp)
ffffffffc0203754:	8522                	mv	a0,s0
ffffffffc0203756:	6442                	ld	s0,16(sp)
ffffffffc0203758:	6902                	ld	s2,0(sp)
ffffffffc020375a:	6105                	addi	sp,sp,32
ffffffffc020375c:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc020375e:	45e1                	li	a1,24
ffffffffc0203760:	8526                	mv	a0,s1
ffffffffc0203762:	c99ff0ef          	jal	ra,ffffffffc02033fa <slob_free>
  return __kmalloc(size, 0);
ffffffffc0203766:	b74d                	j	ffffffffc0203708 <kmalloc+0x5c>

ffffffffc0203768 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0203768:	c175                	beqz	a0,ffffffffc020384c <kfree+0xe4>
{
ffffffffc020376a:	1101                	addi	sp,sp,-32
ffffffffc020376c:	e426                	sd	s1,8(sp)
ffffffffc020376e:	ec06                	sd	ra,24(sp)
ffffffffc0203770:	e822                	sd	s0,16(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0203772:	03451793          	slli	a5,a0,0x34
ffffffffc0203776:	84aa                	mv	s1,a0
ffffffffc0203778:	eb8d                	bnez	a5,ffffffffc02037aa <kfree+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020377a:	100027f3          	csrr	a5,sstatus
ffffffffc020377e:	8b89                	andi	a5,a5,2
ffffffffc0203780:	efc9                	bnez	a5,ffffffffc020381a <kfree+0xb2>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0203782:	000a9797          	auipc	a5,0xa9
ffffffffc0203786:	c5678793          	addi	a5,a5,-938 # ffffffffc02ac3d8 <bigblocks>
ffffffffc020378a:	6394                	ld	a3,0(a5)
ffffffffc020378c:	ce99                	beqz	a3,ffffffffc02037aa <kfree+0x42>
			if (bb->pages == block) {
ffffffffc020378e:	669c                	ld	a5,8(a3)
ffffffffc0203790:	6a80                	ld	s0,16(a3)
ffffffffc0203792:	0af50e63          	beq	a0,a5,ffffffffc020384e <kfree+0xe6>
    return 0;
ffffffffc0203796:	4601                	li	a2,0
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0203798:	c801                	beqz	s0,ffffffffc02037a8 <kfree+0x40>
			if (bb->pages == block) {
ffffffffc020379a:	6418                	ld	a4,8(s0)
ffffffffc020379c:	681c                	ld	a5,16(s0)
ffffffffc020379e:	00970f63          	beq	a4,s1,ffffffffc02037bc <kfree+0x54>
ffffffffc02037a2:	86a2                	mv	a3,s0
ffffffffc02037a4:	843e                	mv	s0,a5
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc02037a6:	f875                	bnez	s0,ffffffffc020379a <kfree+0x32>
    if (flag) {
ffffffffc02037a8:	e659                	bnez	a2,ffffffffc0203836 <kfree+0xce>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc02037aa:	6442                	ld	s0,16(sp)
ffffffffc02037ac:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc02037ae:	ff048513          	addi	a0,s1,-16
}
ffffffffc02037b2:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc02037b4:	4581                	li	a1,0
}
ffffffffc02037b6:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc02037b8:	c43ff06f          	j	ffffffffc02033fa <slob_free>
				*last = bb->next;
ffffffffc02037bc:	ea9c                	sd	a5,16(a3)
ffffffffc02037be:	e641                	bnez	a2,ffffffffc0203846 <kfree+0xde>
    return pa2page(PADDR(kva));
ffffffffc02037c0:	c02007b7          	lui	a5,0xc0200
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc02037c4:	4018                	lw	a4,0(s0)
ffffffffc02037c6:	08f4ea63          	bltu	s1,a5,ffffffffc020385a <kfree+0xf2>
ffffffffc02037ca:	000a9797          	auipc	a5,0xa9
ffffffffc02037ce:	c5678793          	addi	a5,a5,-938 # ffffffffc02ac420 <va_pa_offset>
ffffffffc02037d2:	6394                	ld	a3,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02037d4:	000a9797          	auipc	a5,0xa9
ffffffffc02037d8:	bf478793          	addi	a5,a5,-1036 # ffffffffc02ac3c8 <npage>
ffffffffc02037dc:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc02037de:	8c95                	sub	s1,s1,a3
    if (PPN(pa) >= npage) {
ffffffffc02037e0:	80b1                	srli	s1,s1,0xc
ffffffffc02037e2:	08f4f963          	bleu	a5,s1,ffffffffc0203874 <kfree+0x10c>
    return &pages[PPN(pa) - nbase];
ffffffffc02037e6:	00005797          	auipc	a5,0x5
ffffffffc02037ea:	79278793          	addi	a5,a5,1938 # ffffffffc0208f78 <nbase>
ffffffffc02037ee:	639c                	ld	a5,0(a5)
ffffffffc02037f0:	000a9697          	auipc	a3,0xa9
ffffffffc02037f4:	c4068693          	addi	a3,a3,-960 # ffffffffc02ac430 <pages>
ffffffffc02037f8:	6288                	ld	a0,0(a3)
ffffffffc02037fa:	8c9d                	sub	s1,s1,a5
ffffffffc02037fc:	049a                	slli	s1,s1,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc02037fe:	4585                	li	a1,1
ffffffffc0203800:	9526                	add	a0,a0,s1
ffffffffc0203802:	00e595bb          	sllw	a1,a1,a4
ffffffffc0203806:	f2cfd0ef          	jal	ra,ffffffffc0200f32 <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc020380a:	8522                	mv	a0,s0
}
ffffffffc020380c:	6442                	ld	s0,16(sp)
ffffffffc020380e:	60e2                	ld	ra,24(sp)
ffffffffc0203810:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0203812:	45e1                	li	a1,24
}
ffffffffc0203814:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0203816:	be5ff06f          	j	ffffffffc02033fa <slob_free>
        intr_disable();
ffffffffc020381a:	e43fc0ef          	jal	ra,ffffffffc020065c <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc020381e:	000a9797          	auipc	a5,0xa9
ffffffffc0203822:	bba78793          	addi	a5,a5,-1094 # ffffffffc02ac3d8 <bigblocks>
ffffffffc0203826:	6394                	ld	a3,0(a5)
ffffffffc0203828:	c699                	beqz	a3,ffffffffc0203836 <kfree+0xce>
			if (bb->pages == block) {
ffffffffc020382a:	669c                	ld	a5,8(a3)
ffffffffc020382c:	6a80                	ld	s0,16(a3)
ffffffffc020382e:	00f48763          	beq	s1,a5,ffffffffc020383c <kfree+0xd4>
        return 1;
ffffffffc0203832:	4605                	li	a2,1
ffffffffc0203834:	b795                	j	ffffffffc0203798 <kfree+0x30>
        intr_enable();
ffffffffc0203836:	e21fc0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc020383a:	bf85                	j	ffffffffc02037aa <kfree+0x42>
				*last = bb->next;
ffffffffc020383c:	000a9797          	auipc	a5,0xa9
ffffffffc0203840:	b887be23          	sd	s0,-1124(a5) # ffffffffc02ac3d8 <bigblocks>
ffffffffc0203844:	8436                	mv	s0,a3
ffffffffc0203846:	e11fc0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc020384a:	bf9d                	j	ffffffffc02037c0 <kfree+0x58>
ffffffffc020384c:	8082                	ret
ffffffffc020384e:	000a9797          	auipc	a5,0xa9
ffffffffc0203852:	b887b523          	sd	s0,-1142(a5) # ffffffffc02ac3d8 <bigblocks>
ffffffffc0203856:	8436                	mv	s0,a3
ffffffffc0203858:	b7a5                	j	ffffffffc02037c0 <kfree+0x58>
    return pa2page(PADDR(kva));
ffffffffc020385a:	86a6                	mv	a3,s1
ffffffffc020385c:	00004617          	auipc	a2,0x4
ffffffffc0203860:	ab460613          	addi	a2,a2,-1356 # ffffffffc0207310 <commands+0x9a8>
ffffffffc0203864:	06e00593          	li	a1,110
ffffffffc0203868:	00004517          	auipc	a0,0x4
ffffffffc020386c:	a2850513          	addi	a0,a0,-1496 # ffffffffc0207290 <commands+0x928>
ffffffffc0203870:	9a7fc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203874:	00004617          	auipc	a2,0x4
ffffffffc0203878:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0207270 <commands+0x908>
ffffffffc020387c:	06200593          	li	a1,98
ffffffffc0203880:	00004517          	auipc	a0,0x4
ffffffffc0203884:	a1050513          	addi	a0,a0,-1520 # ffffffffc0207290 <commands+0x928>
ffffffffc0203888:	98ffc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020388c <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc020388c:	7135                	addi	sp,sp,-160
ffffffffc020388e:	ed06                	sd	ra,152(sp)
ffffffffc0203890:	e922                	sd	s0,144(sp)
ffffffffc0203892:	e526                	sd	s1,136(sp)
ffffffffc0203894:	e14a                	sd	s2,128(sp)
ffffffffc0203896:	fcce                	sd	s3,120(sp)
ffffffffc0203898:	f8d2                	sd	s4,112(sp)
ffffffffc020389a:	f4d6                	sd	s5,104(sp)
ffffffffc020389c:	f0da                	sd	s6,96(sp)
ffffffffc020389e:	ecde                	sd	s7,88(sp)
ffffffffc02038a0:	e8e2                	sd	s8,80(sp)
ffffffffc02038a2:	e4e6                	sd	s9,72(sp)
ffffffffc02038a4:	e0ea                	sd	s10,64(sp)
ffffffffc02038a6:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc02038a8:	460010ef          	jal	ra,ffffffffc0204d08 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02038ac:	000a9797          	auipc	a5,0xa9
ffffffffc02038b0:	c2c78793          	addi	a5,a5,-980 # ffffffffc02ac4d8 <max_swap_offset>
ffffffffc02038b4:	6394                	ld	a3,0(a5)
ffffffffc02038b6:	010007b7          	lui	a5,0x1000
ffffffffc02038ba:	17e1                	addi	a5,a5,-8
ffffffffc02038bc:	ff968713          	addi	a4,a3,-7
ffffffffc02038c0:	4ae7ee63          	bltu	a5,a4,ffffffffc0203d7c <swap_init+0x4f0>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc02038c4:	0009d797          	auipc	a5,0x9d
ffffffffc02038c8:	68c78793          	addi	a5,a5,1676 # ffffffffc02a0f50 <swap_manager_fifo>
     int r = sm->init();
ffffffffc02038cc:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc02038ce:	000a9697          	auipc	a3,0xa9
ffffffffc02038d2:	b0f6b923          	sd	a5,-1262(a3) # ffffffffc02ac3e0 <sm>
     int r = sm->init();
ffffffffc02038d6:	9702                	jalr	a4
ffffffffc02038d8:	8aaa                	mv	s5,a0
     
     if (r == 0)
ffffffffc02038da:	c10d                	beqz	a0,ffffffffc02038fc <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02038dc:	60ea                	ld	ra,152(sp)
ffffffffc02038de:	644a                	ld	s0,144(sp)
ffffffffc02038e0:	8556                	mv	a0,s5
ffffffffc02038e2:	64aa                	ld	s1,136(sp)
ffffffffc02038e4:	690a                	ld	s2,128(sp)
ffffffffc02038e6:	79e6                	ld	s3,120(sp)
ffffffffc02038e8:	7a46                	ld	s4,112(sp)
ffffffffc02038ea:	7aa6                	ld	s5,104(sp)
ffffffffc02038ec:	7b06                	ld	s6,96(sp)
ffffffffc02038ee:	6be6                	ld	s7,88(sp)
ffffffffc02038f0:	6c46                	ld	s8,80(sp)
ffffffffc02038f2:	6ca6                	ld	s9,72(sp)
ffffffffc02038f4:	6d06                	ld	s10,64(sp)
ffffffffc02038f6:	7de2                	ld	s11,56(sp)
ffffffffc02038f8:	610d                	addi	sp,sp,160
ffffffffc02038fa:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02038fc:	000a9797          	auipc	a5,0xa9
ffffffffc0203900:	ae478793          	addi	a5,a5,-1308 # ffffffffc02ac3e0 <sm>
ffffffffc0203904:	639c                	ld	a5,0(a5)
ffffffffc0203906:	00004517          	auipc	a0,0x4
ffffffffc020390a:	64250513          	addi	a0,a0,1602 # ffffffffc0207f48 <commands+0x15e0>
ffffffffc020390e:	000a9417          	auipc	s0,0xa9
ffffffffc0203912:	c0a40413          	addi	s0,s0,-1014 # ffffffffc02ac518 <free_area>
ffffffffc0203916:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0203918:	4785                	li	a5,1
ffffffffc020391a:	000a9717          	auipc	a4,0xa9
ffffffffc020391e:	acf72723          	sw	a5,-1330(a4) # ffffffffc02ac3e8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203922:	faefc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0203926:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203928:	36878e63          	beq	a5,s0,ffffffffc0203ca4 <swap_init+0x418>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020392c:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203930:	8305                	srli	a4,a4,0x1
ffffffffc0203932:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203934:	36070c63          	beqz	a4,ffffffffc0203cac <swap_init+0x420>
     int ret, count = 0, total = 0, i;
ffffffffc0203938:	4481                	li	s1,0
ffffffffc020393a:	4901                	li	s2,0
ffffffffc020393c:	a031                	j	ffffffffc0203948 <swap_init+0xbc>
ffffffffc020393e:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0203942:	8b09                	andi	a4,a4,2
ffffffffc0203944:	36070463          	beqz	a4,ffffffffc0203cac <swap_init+0x420>
        count ++, total += p->property;
ffffffffc0203948:	ff87a703          	lw	a4,-8(a5)
ffffffffc020394c:	679c                	ld	a5,8(a5)
ffffffffc020394e:	2905                	addiw	s2,s2,1
ffffffffc0203950:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203952:	fe8796e3          	bne	a5,s0,ffffffffc020393e <swap_init+0xb2>
ffffffffc0203956:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0203958:	e20fd0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>
ffffffffc020395c:	69351863          	bne	a0,s3,ffffffffc0203fec <swap_init+0x760>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0203960:	8626                	mv	a2,s1
ffffffffc0203962:	85ca                	mv	a1,s2
ffffffffc0203964:	00004517          	auipc	a0,0x4
ffffffffc0203968:	62c50513          	addi	a0,a0,1580 # ffffffffc0207f90 <commands+0x1628>
ffffffffc020396c:	f64fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0203970:	f0bfe0ef          	jal	ra,ffffffffc020287a <mm_create>
ffffffffc0203974:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0203976:	60050b63          	beqz	a0,ffffffffc0203f8c <swap_init+0x700>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020397a:	000a9797          	auipc	a5,0xa9
ffffffffc020397e:	ace78793          	addi	a5,a5,-1330 # ffffffffc02ac448 <check_mm_struct>
ffffffffc0203982:	639c                	ld	a5,0(a5)
ffffffffc0203984:	62079463          	bnez	a5,ffffffffc0203fac <swap_init+0x720>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203988:	000a9797          	auipc	a5,0xa9
ffffffffc020398c:	a3878793          	addi	a5,a5,-1480 # ffffffffc02ac3c0 <boot_pgdir>
ffffffffc0203990:	0007bb03          	ld	s6,0(a5)
     check_mm_struct = mm;
ffffffffc0203994:	000a9797          	auipc	a5,0xa9
ffffffffc0203998:	aaa7ba23          	sd	a0,-1356(a5) # ffffffffc02ac448 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc020399c:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02039a0:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc02039a4:	4e079863          	bnez	a5,ffffffffc0203e94 <swap_init+0x608>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc02039a8:	6599                	lui	a1,0x6
ffffffffc02039aa:	460d                	li	a2,3
ffffffffc02039ac:	6505                	lui	a0,0x1
ffffffffc02039ae:	f19fe0ef          	jal	ra,ffffffffc02028c6 <vma_create>
ffffffffc02039b2:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02039b4:	50050063          	beqz	a0,ffffffffc0203eb4 <swap_init+0x628>

     insert_vma_struct(mm, vma);
ffffffffc02039b8:	855e                	mv	a0,s7
ffffffffc02039ba:	f79fe0ef          	jal	ra,ffffffffc0202932 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02039be:	00004517          	auipc	a0,0x4
ffffffffc02039c2:	61250513          	addi	a0,a0,1554 # ffffffffc0207fd0 <commands+0x1668>
ffffffffc02039c6:	f0afc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02039ca:	018bb503          	ld	a0,24(s7)
ffffffffc02039ce:	4605                	li	a2,1
ffffffffc02039d0:	6585                	lui	a1,0x1
ffffffffc02039d2:	de6fd0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02039d6:	4e050f63          	beqz	a0,ffffffffc0203ed4 <swap_init+0x648>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02039da:	00004517          	auipc	a0,0x4
ffffffffc02039de:	64650513          	addi	a0,a0,1606 # ffffffffc0208020 <commands+0x16b8>
ffffffffc02039e2:	000a9997          	auipc	s3,0xa9
ffffffffc02039e6:	a6e98993          	addi	s3,s3,-1426 # ffffffffc02ac450 <check_rp>
ffffffffc02039ea:	ee6fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02039ee:	000a9a17          	auipc	s4,0xa9
ffffffffc02039f2:	a82a0a13          	addi	s4,s4,-1406 # ffffffffc02ac470 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02039f6:	8c4e                	mv	s8,s3
          check_rp[i] = alloc_page();
ffffffffc02039f8:	4505                	li	a0,1
ffffffffc02039fa:	cb0fd0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc02039fe:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc0203a02:	32050d63          	beqz	a0,ffffffffc0203d3c <swap_init+0x4b0>
ffffffffc0203a06:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203a08:	8b89                	andi	a5,a5,2
ffffffffc0203a0a:	30079963          	bnez	a5,ffffffffc0203d1c <swap_init+0x490>
ffffffffc0203a0e:	0c21                	addi	s8,s8,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203a10:	ff4c14e3          	bne	s8,s4,ffffffffc02039f8 <swap_init+0x16c>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0203a14:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0203a16:	000a9c17          	auipc	s8,0xa9
ffffffffc0203a1a:	a3ac0c13          	addi	s8,s8,-1478 # ffffffffc02ac450 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0203a1e:	ec3e                	sd	a5,24(sp)
ffffffffc0203a20:	641c                	ld	a5,8(s0)
ffffffffc0203a22:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0203a24:	481c                	lw	a5,16(s0)
ffffffffc0203a26:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0203a28:	000a9797          	auipc	a5,0xa9
ffffffffc0203a2c:	ae87bc23          	sd	s0,-1288(a5) # ffffffffc02ac520 <free_area+0x8>
ffffffffc0203a30:	000a9797          	auipc	a5,0xa9
ffffffffc0203a34:	ae87b423          	sd	s0,-1304(a5) # ffffffffc02ac518 <free_area>
     nr_free = 0;
ffffffffc0203a38:	000a9797          	auipc	a5,0xa9
ffffffffc0203a3c:	ae07a823          	sw	zero,-1296(a5) # ffffffffc02ac528 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0203a40:	000c3503          	ld	a0,0(s8)
ffffffffc0203a44:	4585                	li	a1,1
ffffffffc0203a46:	0c21                	addi	s8,s8,8
ffffffffc0203a48:	ceafd0ef          	jal	ra,ffffffffc0200f32 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203a4c:	ff4c1ae3          	bne	s8,s4,ffffffffc0203a40 <swap_init+0x1b4>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203a50:	01042c03          	lw	s8,16(s0)
ffffffffc0203a54:	4791                	li	a5,4
ffffffffc0203a56:	50fc1b63          	bne	s8,a5,ffffffffc0203f6c <swap_init+0x6e0>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0203a5a:	00004517          	auipc	a0,0x4
ffffffffc0203a5e:	64e50513          	addi	a0,a0,1614 # ffffffffc02080a8 <commands+0x1740>
ffffffffc0203a62:	e6efc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203a66:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0203a68:	000a9797          	auipc	a5,0xa9
ffffffffc0203a6c:	9607a423          	sw	zero,-1688(a5) # ffffffffc02ac3d0 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203a70:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc0203a72:	000a9797          	auipc	a5,0xa9
ffffffffc0203a76:	95e78793          	addi	a5,a5,-1698 # ffffffffc02ac3d0 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203a7a:	00c68023          	sb	a2,0(a3) # 1000 <_binary_obj___user_faultread_out_size-0x8570>
     assert(pgfault_num==1);
ffffffffc0203a7e:	4398                	lw	a4,0(a5)
ffffffffc0203a80:	4585                	li	a1,1
ffffffffc0203a82:	2701                	sext.w	a4,a4
ffffffffc0203a84:	38b71863          	bne	a4,a1,ffffffffc0203e14 <swap_init+0x588>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0203a88:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc0203a8c:	4394                	lw	a3,0(a5)
ffffffffc0203a8e:	2681                	sext.w	a3,a3
ffffffffc0203a90:	3ae69263          	bne	a3,a4,ffffffffc0203e34 <swap_init+0x5a8>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203a94:	6689                	lui	a3,0x2
ffffffffc0203a96:	462d                	li	a2,11
ffffffffc0203a98:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7570>
     assert(pgfault_num==2);
ffffffffc0203a9c:	4398                	lw	a4,0(a5)
ffffffffc0203a9e:	4589                	li	a1,2
ffffffffc0203aa0:	2701                	sext.w	a4,a4
ffffffffc0203aa2:	2eb71963          	bne	a4,a1,ffffffffc0203d94 <swap_init+0x508>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0203aa6:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0203aaa:	4394                	lw	a3,0(a5)
ffffffffc0203aac:	2681                	sext.w	a3,a3
ffffffffc0203aae:	30e69363          	bne	a3,a4,ffffffffc0203db4 <swap_init+0x528>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203ab2:	668d                	lui	a3,0x3
ffffffffc0203ab4:	4631                	li	a2,12
ffffffffc0203ab6:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6570>
     assert(pgfault_num==3);
ffffffffc0203aba:	4398                	lw	a4,0(a5)
ffffffffc0203abc:	458d                	li	a1,3
ffffffffc0203abe:	2701                	sext.w	a4,a4
ffffffffc0203ac0:	30b71a63          	bne	a4,a1,ffffffffc0203dd4 <swap_init+0x548>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0203ac4:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc0203ac8:	4394                	lw	a3,0(a5)
ffffffffc0203aca:	2681                	sext.w	a3,a3
ffffffffc0203acc:	32e69463          	bne	a3,a4,ffffffffc0203df4 <swap_init+0x568>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203ad0:	6691                	lui	a3,0x4
ffffffffc0203ad2:	4635                	li	a2,13
ffffffffc0203ad4:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5570>
     assert(pgfault_num==4);
ffffffffc0203ad8:	4398                	lw	a4,0(a5)
ffffffffc0203ada:	2701                	sext.w	a4,a4
ffffffffc0203adc:	37871c63          	bne	a4,s8,ffffffffc0203e54 <swap_init+0x5c8>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0203ae0:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0203ae4:	439c                	lw	a5,0(a5)
ffffffffc0203ae6:	2781                	sext.w	a5,a5
ffffffffc0203ae8:	38e79663          	bne	a5,a4,ffffffffc0203e74 <swap_init+0x5e8>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203aec:	481c                	lw	a5,16(s0)
ffffffffc0203aee:	40079363          	bnez	a5,ffffffffc0203ef4 <swap_init+0x668>
ffffffffc0203af2:	000a9797          	auipc	a5,0xa9
ffffffffc0203af6:	97e78793          	addi	a5,a5,-1666 # ffffffffc02ac470 <swap_in_seq_no>
ffffffffc0203afa:	000a9717          	auipc	a4,0xa9
ffffffffc0203afe:	99e70713          	addi	a4,a4,-1634 # ffffffffc02ac498 <swap_out_seq_no>
ffffffffc0203b02:	000a9617          	auipc	a2,0xa9
ffffffffc0203b06:	99660613          	addi	a2,a2,-1642 # ffffffffc02ac498 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0203b0a:	56fd                	li	a3,-1
ffffffffc0203b0c:	c394                	sw	a3,0(a5)
ffffffffc0203b0e:	c314                	sw	a3,0(a4)
ffffffffc0203b10:	0791                	addi	a5,a5,4
ffffffffc0203b12:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203b14:	fef61ce3          	bne	a2,a5,ffffffffc0203b0c <swap_init+0x280>
ffffffffc0203b18:	000a9697          	auipc	a3,0xa9
ffffffffc0203b1c:	9e068693          	addi	a3,a3,-1568 # ffffffffc02ac4f8 <check_ptep>
ffffffffc0203b20:	000a9817          	auipc	a6,0xa9
ffffffffc0203b24:	93080813          	addi	a6,a6,-1744 # ffffffffc02ac450 <check_rp>
ffffffffc0203b28:	6d05                	lui	s10,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203b2a:	000a9c97          	auipc	s9,0xa9
ffffffffc0203b2e:	89ec8c93          	addi	s9,s9,-1890 # ffffffffc02ac3c8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203b32:	00005d97          	auipc	s11,0x5
ffffffffc0203b36:	446d8d93          	addi	s11,s11,1094 # ffffffffc0208f78 <nbase>
ffffffffc0203b3a:	000a9c17          	auipc	s8,0xa9
ffffffffc0203b3e:	8f6c0c13          	addi	s8,s8,-1802 # ffffffffc02ac430 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0203b42:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203b46:	4601                	li	a2,0
ffffffffc0203b48:	85ea                	mv	a1,s10
ffffffffc0203b4a:	855a                	mv	a0,s6
ffffffffc0203b4c:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc0203b4e:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203b50:	c68fd0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc0203b54:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0203b56:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203b58:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc0203b5a:	20050163          	beqz	a0,ffffffffc0203d5c <swap_init+0x4d0>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203b5e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203b60:	0017f613          	andi	a2,a5,1
ffffffffc0203b64:	1a060063          	beqz	a2,ffffffffc0203d04 <swap_init+0x478>
    if (PPN(pa) >= npage) {
ffffffffc0203b68:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203b6c:	078a                	slli	a5,a5,0x2
ffffffffc0203b6e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203b70:	14c7fe63          	bleu	a2,a5,ffffffffc0203ccc <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203b74:	000db703          	ld	a4,0(s11)
ffffffffc0203b78:	000c3603          	ld	a2,0(s8)
ffffffffc0203b7c:	00083583          	ld	a1,0(a6)
ffffffffc0203b80:	8f99                	sub	a5,a5,a4
ffffffffc0203b82:	079a                	slli	a5,a5,0x6
ffffffffc0203b84:	e43a                	sd	a4,8(sp)
ffffffffc0203b86:	97b2                	add	a5,a5,a2
ffffffffc0203b88:	14f59e63          	bne	a1,a5,ffffffffc0203ce4 <swap_init+0x458>
ffffffffc0203b8c:	6785                	lui	a5,0x1
ffffffffc0203b8e:	9d3e                	add	s10,s10,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203b90:	6795                	lui	a5,0x5
ffffffffc0203b92:	06a1                	addi	a3,a3,8
ffffffffc0203b94:	0821                	addi	a6,a6,8
ffffffffc0203b96:	fafd16e3          	bne	s10,a5,ffffffffc0203b42 <swap_init+0x2b6>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0203b9a:	00004517          	auipc	a0,0x4
ffffffffc0203b9e:	5b650513          	addi	a0,a0,1462 # ffffffffc0208150 <commands+0x17e8>
ffffffffc0203ba2:	d2efc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    int ret = sm->check_swap();
ffffffffc0203ba6:	000a9797          	auipc	a5,0xa9
ffffffffc0203baa:	83a78793          	addi	a5,a5,-1990 # ffffffffc02ac3e0 <sm>
ffffffffc0203bae:	639c                	ld	a5,0(a5)
ffffffffc0203bb0:	7f9c                	ld	a5,56(a5)
ffffffffc0203bb2:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0203bb4:	40051c63          	bnez	a0,ffffffffc0203fcc <swap_init+0x740>

     nr_free = nr_free_store;
ffffffffc0203bb8:	77a2                	ld	a5,40(sp)
ffffffffc0203bba:	000a9717          	auipc	a4,0xa9
ffffffffc0203bbe:	96f72723          	sw	a5,-1682(a4) # ffffffffc02ac528 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0203bc2:	67e2                	ld	a5,24(sp)
ffffffffc0203bc4:	000a9717          	auipc	a4,0xa9
ffffffffc0203bc8:	94f73a23          	sd	a5,-1708(a4) # ffffffffc02ac518 <free_area>
ffffffffc0203bcc:	7782                	ld	a5,32(sp)
ffffffffc0203bce:	000a9717          	auipc	a4,0xa9
ffffffffc0203bd2:	94f73923          	sd	a5,-1710(a4) # ffffffffc02ac520 <free_area+0x8>

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0203bd6:	0009b503          	ld	a0,0(s3)
ffffffffc0203bda:	4585                	li	a1,1
ffffffffc0203bdc:	09a1                	addi	s3,s3,8
ffffffffc0203bde:	b54fd0ef          	jal	ra,ffffffffc0200f32 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203be2:	ff499ae3          	bne	s3,s4,ffffffffc0203bd6 <swap_init+0x34a>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc0203be6:	000bbc23          	sd	zero,24(s7)
     mm_destroy(mm);
ffffffffc0203bea:	855e                	mv	a0,s7
ffffffffc0203bec:	e15fe0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0203bf0:	000a8797          	auipc	a5,0xa8
ffffffffc0203bf4:	7d078793          	addi	a5,a5,2000 # ffffffffc02ac3c0 <boot_pgdir>
ffffffffc0203bf8:	639c                	ld	a5,0(a5)
     check_mm_struct = NULL;
ffffffffc0203bfa:	000a9697          	auipc	a3,0xa9
ffffffffc0203bfe:	8406b723          	sd	zero,-1970(a3) # ffffffffc02ac448 <check_mm_struct>
    if (PPN(pa) >= npage) {
ffffffffc0203c02:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c06:	6394                	ld	a3,0(a5)
ffffffffc0203c08:	068a                	slli	a3,a3,0x2
ffffffffc0203c0a:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203c0c:	0ce6f063          	bleu	a4,a3,ffffffffc0203ccc <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203c10:	67a2                	ld	a5,8(sp)
ffffffffc0203c12:	000c3503          	ld	a0,0(s8)
ffffffffc0203c16:	8e9d                	sub	a3,a3,a5
ffffffffc0203c18:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0203c1a:	8699                	srai	a3,a3,0x6
ffffffffc0203c1c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203c1e:	57fd                	li	a5,-1
ffffffffc0203c20:	83b1                	srli	a5,a5,0xc
ffffffffc0203c22:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203c24:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203c26:	2ee7f763          	bleu	a4,a5,ffffffffc0203f14 <swap_init+0x688>
     free_page(pde2page(pd0[0]));
ffffffffc0203c2a:	000a8797          	auipc	a5,0xa8
ffffffffc0203c2e:	7f678793          	addi	a5,a5,2038 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0203c32:	639c                	ld	a5,0(a5)
ffffffffc0203c34:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c36:	629c                	ld	a5,0(a3)
ffffffffc0203c38:	078a                	slli	a5,a5,0x2
ffffffffc0203c3a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203c3c:	08e7f863          	bleu	a4,a5,ffffffffc0203ccc <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203c40:	69a2                	ld	s3,8(sp)
ffffffffc0203c42:	4585                	li	a1,1
ffffffffc0203c44:	413787b3          	sub	a5,a5,s3
ffffffffc0203c48:	079a                	slli	a5,a5,0x6
ffffffffc0203c4a:	953e                	add	a0,a0,a5
ffffffffc0203c4c:	ae6fd0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c50:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0203c54:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c58:	078a                	slli	a5,a5,0x2
ffffffffc0203c5a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203c5c:	06e7f863          	bleu	a4,a5,ffffffffc0203ccc <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203c60:	000c3503          	ld	a0,0(s8)
ffffffffc0203c64:	413787b3          	sub	a5,a5,s3
ffffffffc0203c68:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0203c6a:	4585                	li	a1,1
ffffffffc0203c6c:	953e                	add	a0,a0,a5
ffffffffc0203c6e:	ac4fd0ef          	jal	ra,ffffffffc0200f32 <free_pages>
     pgdir[0] = 0;
ffffffffc0203c72:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0203c76:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203c7a:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203c7c:	00878963          	beq	a5,s0,ffffffffc0203c8e <swap_init+0x402>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203c80:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203c84:	679c                	ld	a5,8(a5)
ffffffffc0203c86:	397d                	addiw	s2,s2,-1
ffffffffc0203c88:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203c8a:	fe879be3          	bne	a5,s0,ffffffffc0203c80 <swap_init+0x3f4>
     }
     assert(count==0);
ffffffffc0203c8e:	28091f63          	bnez	s2,ffffffffc0203f2c <swap_init+0x6a0>
     assert(total==0);
ffffffffc0203c92:	2a049d63          	bnez	s1,ffffffffc0203f4c <swap_init+0x6c0>

     cprintf("check_swap() succeeded!\n");
ffffffffc0203c96:	00004517          	auipc	a0,0x4
ffffffffc0203c9a:	50a50513          	addi	a0,a0,1290 # ffffffffc02081a0 <commands+0x1838>
ffffffffc0203c9e:	c32fc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0203ca2:	b92d                	j	ffffffffc02038dc <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0203ca4:	4481                	li	s1,0
ffffffffc0203ca6:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203ca8:	4981                	li	s3,0
ffffffffc0203caa:	b17d                	j	ffffffffc0203958 <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc0203cac:	00004697          	auipc	a3,0x4
ffffffffc0203cb0:	2b468693          	addi	a3,a3,692 # ffffffffc0207f60 <commands+0x15f8>
ffffffffc0203cb4:	00003617          	auipc	a2,0x3
ffffffffc0203cb8:	14c60613          	addi	a2,a2,332 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203cbc:	0bc00593          	li	a1,188
ffffffffc0203cc0:	00004517          	auipc	a0,0x4
ffffffffc0203cc4:	27850513          	addi	a0,a0,632 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203cc8:	d4efc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203ccc:	00003617          	auipc	a2,0x3
ffffffffc0203cd0:	5a460613          	addi	a2,a2,1444 # ffffffffc0207270 <commands+0x908>
ffffffffc0203cd4:	06200593          	li	a1,98
ffffffffc0203cd8:	00003517          	auipc	a0,0x3
ffffffffc0203cdc:	5b850513          	addi	a0,a0,1464 # ffffffffc0207290 <commands+0x928>
ffffffffc0203ce0:	d36fc0ef          	jal	ra,ffffffffc0200216 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203ce4:	00004697          	auipc	a3,0x4
ffffffffc0203ce8:	44468693          	addi	a3,a3,1092 # ffffffffc0208128 <commands+0x17c0>
ffffffffc0203cec:	00003617          	auipc	a2,0x3
ffffffffc0203cf0:	11460613          	addi	a2,a2,276 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203cf4:	0fc00593          	li	a1,252
ffffffffc0203cf8:	00004517          	auipc	a0,0x4
ffffffffc0203cfc:	24050513          	addi	a0,a0,576 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203d00:	d16fc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203d04:	00003617          	auipc	a2,0x3
ffffffffc0203d08:	74c60613          	addi	a2,a2,1868 # ffffffffc0207450 <commands+0xae8>
ffffffffc0203d0c:	07400593          	li	a1,116
ffffffffc0203d10:	00003517          	auipc	a0,0x3
ffffffffc0203d14:	58050513          	addi	a0,a0,1408 # ffffffffc0207290 <commands+0x928>
ffffffffc0203d18:	cfefc0ef          	jal	ra,ffffffffc0200216 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0203d1c:	00004697          	auipc	a3,0x4
ffffffffc0203d20:	34468693          	addi	a3,a3,836 # ffffffffc0208060 <commands+0x16f8>
ffffffffc0203d24:	00003617          	auipc	a2,0x3
ffffffffc0203d28:	0dc60613          	addi	a2,a2,220 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203d2c:	0dd00593          	li	a1,221
ffffffffc0203d30:	00004517          	auipc	a0,0x4
ffffffffc0203d34:	20850513          	addi	a0,a0,520 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203d38:	cdefc0ef          	jal	ra,ffffffffc0200216 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0203d3c:	00004697          	auipc	a3,0x4
ffffffffc0203d40:	30c68693          	addi	a3,a3,780 # ffffffffc0208048 <commands+0x16e0>
ffffffffc0203d44:	00003617          	auipc	a2,0x3
ffffffffc0203d48:	0bc60613          	addi	a2,a2,188 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203d4c:	0dc00593          	li	a1,220
ffffffffc0203d50:	00004517          	auipc	a0,0x4
ffffffffc0203d54:	1e850513          	addi	a0,a0,488 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203d58:	cbefc0ef          	jal	ra,ffffffffc0200216 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0203d5c:	00004697          	auipc	a3,0x4
ffffffffc0203d60:	3b468693          	addi	a3,a3,948 # ffffffffc0208110 <commands+0x17a8>
ffffffffc0203d64:	00003617          	auipc	a2,0x3
ffffffffc0203d68:	09c60613          	addi	a2,a2,156 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203d6c:	0fb00593          	li	a1,251
ffffffffc0203d70:	00004517          	auipc	a0,0x4
ffffffffc0203d74:	1c850513          	addi	a0,a0,456 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203d78:	c9efc0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0203d7c:	00004617          	auipc	a2,0x4
ffffffffc0203d80:	19c60613          	addi	a2,a2,412 # ffffffffc0207f18 <commands+0x15b0>
ffffffffc0203d84:	02800593          	li	a1,40
ffffffffc0203d88:	00004517          	auipc	a0,0x4
ffffffffc0203d8c:	1b050513          	addi	a0,a0,432 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203d90:	c86fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==2);
ffffffffc0203d94:	00004697          	auipc	a3,0x4
ffffffffc0203d98:	34c68693          	addi	a3,a3,844 # ffffffffc02080e0 <commands+0x1778>
ffffffffc0203d9c:	00003617          	auipc	a2,0x3
ffffffffc0203da0:	06460613          	addi	a2,a2,100 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203da4:	09700593          	li	a1,151
ffffffffc0203da8:	00004517          	auipc	a0,0x4
ffffffffc0203dac:	19050513          	addi	a0,a0,400 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203db0:	c66fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==2);
ffffffffc0203db4:	00004697          	auipc	a3,0x4
ffffffffc0203db8:	32c68693          	addi	a3,a3,812 # ffffffffc02080e0 <commands+0x1778>
ffffffffc0203dbc:	00003617          	auipc	a2,0x3
ffffffffc0203dc0:	04460613          	addi	a2,a2,68 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203dc4:	09900593          	li	a1,153
ffffffffc0203dc8:	00004517          	auipc	a0,0x4
ffffffffc0203dcc:	17050513          	addi	a0,a0,368 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203dd0:	c46fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==3);
ffffffffc0203dd4:	00004697          	auipc	a3,0x4
ffffffffc0203dd8:	31c68693          	addi	a3,a3,796 # ffffffffc02080f0 <commands+0x1788>
ffffffffc0203ddc:	00003617          	auipc	a2,0x3
ffffffffc0203de0:	02460613          	addi	a2,a2,36 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203de4:	09b00593          	li	a1,155
ffffffffc0203de8:	00004517          	auipc	a0,0x4
ffffffffc0203dec:	15050513          	addi	a0,a0,336 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203df0:	c26fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==3);
ffffffffc0203df4:	00004697          	auipc	a3,0x4
ffffffffc0203df8:	2fc68693          	addi	a3,a3,764 # ffffffffc02080f0 <commands+0x1788>
ffffffffc0203dfc:	00003617          	auipc	a2,0x3
ffffffffc0203e00:	00460613          	addi	a2,a2,4 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203e04:	09d00593          	li	a1,157
ffffffffc0203e08:	00004517          	auipc	a0,0x4
ffffffffc0203e0c:	13050513          	addi	a0,a0,304 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203e10:	c06fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==1);
ffffffffc0203e14:	00004697          	auipc	a3,0x4
ffffffffc0203e18:	2bc68693          	addi	a3,a3,700 # ffffffffc02080d0 <commands+0x1768>
ffffffffc0203e1c:	00003617          	auipc	a2,0x3
ffffffffc0203e20:	fe460613          	addi	a2,a2,-28 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203e24:	09300593          	li	a1,147
ffffffffc0203e28:	00004517          	auipc	a0,0x4
ffffffffc0203e2c:	11050513          	addi	a0,a0,272 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203e30:	be6fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==1);
ffffffffc0203e34:	00004697          	auipc	a3,0x4
ffffffffc0203e38:	29c68693          	addi	a3,a3,668 # ffffffffc02080d0 <commands+0x1768>
ffffffffc0203e3c:	00003617          	auipc	a2,0x3
ffffffffc0203e40:	fc460613          	addi	a2,a2,-60 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203e44:	09500593          	li	a1,149
ffffffffc0203e48:	00004517          	auipc	a0,0x4
ffffffffc0203e4c:	0f050513          	addi	a0,a0,240 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203e50:	bc6fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==4);
ffffffffc0203e54:	00004697          	auipc	a3,0x4
ffffffffc0203e58:	a4c68693          	addi	a3,a3,-1460 # ffffffffc02078a0 <commands+0xf38>
ffffffffc0203e5c:	00003617          	auipc	a2,0x3
ffffffffc0203e60:	fa460613          	addi	a2,a2,-92 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203e64:	09f00593          	li	a1,159
ffffffffc0203e68:	00004517          	auipc	a0,0x4
ffffffffc0203e6c:	0d050513          	addi	a0,a0,208 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203e70:	ba6fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgfault_num==4);
ffffffffc0203e74:	00004697          	auipc	a3,0x4
ffffffffc0203e78:	a2c68693          	addi	a3,a3,-1492 # ffffffffc02078a0 <commands+0xf38>
ffffffffc0203e7c:	00003617          	auipc	a2,0x3
ffffffffc0203e80:	f8460613          	addi	a2,a2,-124 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203e84:	0a100593          	li	a1,161
ffffffffc0203e88:	00004517          	auipc	a0,0x4
ffffffffc0203e8c:	0b050513          	addi	a0,a0,176 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203e90:	b86fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203e94:	00004697          	auipc	a3,0x4
ffffffffc0203e98:	f1468693          	addi	a3,a3,-236 # ffffffffc0207da8 <commands+0x1440>
ffffffffc0203e9c:	00003617          	auipc	a2,0x3
ffffffffc0203ea0:	f6460613          	addi	a2,a2,-156 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203ea4:	0cc00593          	li	a1,204
ffffffffc0203ea8:	00004517          	auipc	a0,0x4
ffffffffc0203eac:	09050513          	addi	a0,a0,144 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203eb0:	b66fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(vma != NULL);
ffffffffc0203eb4:	00004697          	auipc	a3,0x4
ffffffffc0203eb8:	f9468693          	addi	a3,a3,-108 # ffffffffc0207e48 <commands+0x14e0>
ffffffffc0203ebc:	00003617          	auipc	a2,0x3
ffffffffc0203ec0:	f4460613          	addi	a2,a2,-188 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203ec4:	0cf00593          	li	a1,207
ffffffffc0203ec8:	00004517          	auipc	a0,0x4
ffffffffc0203ecc:	07050513          	addi	a0,a0,112 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203ed0:	b46fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203ed4:	00004697          	auipc	a3,0x4
ffffffffc0203ed8:	13468693          	addi	a3,a3,308 # ffffffffc0208008 <commands+0x16a0>
ffffffffc0203edc:	00003617          	auipc	a2,0x3
ffffffffc0203ee0:	f2460613          	addi	a2,a2,-220 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203ee4:	0d700593          	li	a1,215
ffffffffc0203ee8:	00004517          	auipc	a0,0x4
ffffffffc0203eec:	05050513          	addi	a0,a0,80 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203ef0:	b26fc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert( nr_free == 0);         
ffffffffc0203ef4:	00004697          	auipc	a3,0x4
ffffffffc0203ef8:	20c68693          	addi	a3,a3,524 # ffffffffc0208100 <commands+0x1798>
ffffffffc0203efc:	00003617          	auipc	a2,0x3
ffffffffc0203f00:	f0460613          	addi	a2,a2,-252 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203f04:	0f300593          	li	a1,243
ffffffffc0203f08:	00004517          	auipc	a0,0x4
ffffffffc0203f0c:	03050513          	addi	a0,a0,48 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203f10:	b06fc0ef          	jal	ra,ffffffffc0200216 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203f14:	00003617          	auipc	a2,0x3
ffffffffc0203f18:	32460613          	addi	a2,a2,804 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0203f1c:	06900593          	li	a1,105
ffffffffc0203f20:	00003517          	auipc	a0,0x3
ffffffffc0203f24:	37050513          	addi	a0,a0,880 # ffffffffc0207290 <commands+0x928>
ffffffffc0203f28:	aeefc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(count==0);
ffffffffc0203f2c:	00004697          	auipc	a3,0x4
ffffffffc0203f30:	25468693          	addi	a3,a3,596 # ffffffffc0208180 <commands+0x1818>
ffffffffc0203f34:	00003617          	auipc	a2,0x3
ffffffffc0203f38:	ecc60613          	addi	a2,a2,-308 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203f3c:	11d00593          	li	a1,285
ffffffffc0203f40:	00004517          	auipc	a0,0x4
ffffffffc0203f44:	ff850513          	addi	a0,a0,-8 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203f48:	acefc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(total==0);
ffffffffc0203f4c:	00004697          	auipc	a3,0x4
ffffffffc0203f50:	24468693          	addi	a3,a3,580 # ffffffffc0208190 <commands+0x1828>
ffffffffc0203f54:	00003617          	auipc	a2,0x3
ffffffffc0203f58:	eac60613          	addi	a2,a2,-340 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203f5c:	11e00593          	li	a1,286
ffffffffc0203f60:	00004517          	auipc	a0,0x4
ffffffffc0203f64:	fd850513          	addi	a0,a0,-40 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203f68:	aaefc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203f6c:	00004697          	auipc	a3,0x4
ffffffffc0203f70:	11468693          	addi	a3,a3,276 # ffffffffc0208080 <commands+0x1718>
ffffffffc0203f74:	00003617          	auipc	a2,0x3
ffffffffc0203f78:	e8c60613          	addi	a2,a2,-372 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203f7c:	0ea00593          	li	a1,234
ffffffffc0203f80:	00004517          	auipc	a0,0x4
ffffffffc0203f84:	fb850513          	addi	a0,a0,-72 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203f88:	a8efc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(mm != NULL);
ffffffffc0203f8c:	00004697          	auipc	a3,0x4
ffffffffc0203f90:	c9468693          	addi	a3,a3,-876 # ffffffffc0207c20 <commands+0x12b8>
ffffffffc0203f94:	00003617          	auipc	a2,0x3
ffffffffc0203f98:	e6c60613          	addi	a2,a2,-404 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203f9c:	0c400593          	li	a1,196
ffffffffc0203fa0:	00004517          	auipc	a0,0x4
ffffffffc0203fa4:	f9850513          	addi	a0,a0,-104 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203fa8:	a6efc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203fac:	00004697          	auipc	a3,0x4
ffffffffc0203fb0:	00c68693          	addi	a3,a3,12 # ffffffffc0207fb8 <commands+0x1650>
ffffffffc0203fb4:	00003617          	auipc	a2,0x3
ffffffffc0203fb8:	e4c60613          	addi	a2,a2,-436 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203fbc:	0c700593          	li	a1,199
ffffffffc0203fc0:	00004517          	auipc	a0,0x4
ffffffffc0203fc4:	f7850513          	addi	a0,a0,-136 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203fc8:	a4efc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(ret==0);
ffffffffc0203fcc:	00004697          	auipc	a3,0x4
ffffffffc0203fd0:	1ac68693          	addi	a3,a3,428 # ffffffffc0208178 <commands+0x1810>
ffffffffc0203fd4:	00003617          	auipc	a2,0x3
ffffffffc0203fd8:	e2c60613          	addi	a2,a2,-468 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203fdc:	10200593          	li	a1,258
ffffffffc0203fe0:	00004517          	auipc	a0,0x4
ffffffffc0203fe4:	f5850513          	addi	a0,a0,-168 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0203fe8:	a2efc0ef          	jal	ra,ffffffffc0200216 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203fec:	00004697          	auipc	a3,0x4
ffffffffc0203ff0:	f8468693          	addi	a3,a3,-124 # ffffffffc0207f70 <commands+0x1608>
ffffffffc0203ff4:	00003617          	auipc	a2,0x3
ffffffffc0203ff8:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206e00 <commands+0x498>
ffffffffc0203ffc:	0bf00593          	li	a1,191
ffffffffc0204000:	00004517          	auipc	a0,0x4
ffffffffc0204004:	f3850513          	addi	a0,a0,-200 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc0204008:	a0efc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020400c <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc020400c:	000a8797          	auipc	a5,0xa8
ffffffffc0204010:	3d478793          	addi	a5,a5,980 # ffffffffc02ac3e0 <sm>
ffffffffc0204014:	639c                	ld	a5,0(a5)
ffffffffc0204016:	0107b303          	ld	t1,16(a5)
ffffffffc020401a:	8302                	jr	t1

ffffffffc020401c <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc020401c:	000a8797          	auipc	a5,0xa8
ffffffffc0204020:	3c478793          	addi	a5,a5,964 # ffffffffc02ac3e0 <sm>
ffffffffc0204024:	639c                	ld	a5,0(a5)
ffffffffc0204026:	0207b303          	ld	t1,32(a5)
ffffffffc020402a:	8302                	jr	t1

ffffffffc020402c <swap_out>:
{
ffffffffc020402c:	711d                	addi	sp,sp,-96
ffffffffc020402e:	ec86                	sd	ra,88(sp)
ffffffffc0204030:	e8a2                	sd	s0,80(sp)
ffffffffc0204032:	e4a6                	sd	s1,72(sp)
ffffffffc0204034:	e0ca                	sd	s2,64(sp)
ffffffffc0204036:	fc4e                	sd	s3,56(sp)
ffffffffc0204038:	f852                	sd	s4,48(sp)
ffffffffc020403a:	f456                	sd	s5,40(sp)
ffffffffc020403c:	f05a                	sd	s6,32(sp)
ffffffffc020403e:	ec5e                	sd	s7,24(sp)
ffffffffc0204040:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0204042:	cde9                	beqz	a1,ffffffffc020411c <swap_out+0xf0>
ffffffffc0204044:	8ab2                	mv	s5,a2
ffffffffc0204046:	892a                	mv	s2,a0
ffffffffc0204048:	8a2e                	mv	s4,a1
ffffffffc020404a:	4401                	li	s0,0
ffffffffc020404c:	000a8997          	auipc	s3,0xa8
ffffffffc0204050:	39498993          	addi	s3,s3,916 # ffffffffc02ac3e0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0204054:	00004b17          	auipc	s6,0x4
ffffffffc0204058:	1ccb0b13          	addi	s6,s6,460 # ffffffffc0208220 <commands+0x18b8>
                    cprintf("SWAP: failed to save\n");
ffffffffc020405c:	00004b97          	auipc	s7,0x4
ffffffffc0204060:	1acb8b93          	addi	s7,s7,428 # ffffffffc0208208 <commands+0x18a0>
ffffffffc0204064:	a825                	j	ffffffffc020409c <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0204066:	67a2                	ld	a5,8(sp)
ffffffffc0204068:	8626                	mv	a2,s1
ffffffffc020406a:	85a2                	mv	a1,s0
ffffffffc020406c:	7f94                	ld	a3,56(a5)
ffffffffc020406e:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0204070:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0204072:	82b1                	srli	a3,a3,0xc
ffffffffc0204074:	0685                	addi	a3,a3,1
ffffffffc0204076:	85afc0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020407a:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc020407c:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020407e:	7d1c                	ld	a5,56(a0)
ffffffffc0204080:	83b1                	srli	a5,a5,0xc
ffffffffc0204082:	0785                	addi	a5,a5,1
ffffffffc0204084:	07a2                	slli	a5,a5,0x8
ffffffffc0204086:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc020408a:	ea9fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc020408e:	01893503          	ld	a0,24(s2)
ffffffffc0204092:	85a6                	mv	a1,s1
ffffffffc0204094:	b40fe0ef          	jal	ra,ffffffffc02023d4 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0204098:	048a0d63          	beq	s4,s0,ffffffffc02040f2 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc020409c:	0009b783          	ld	a5,0(s3)
ffffffffc02040a0:	8656                	mv	a2,s5
ffffffffc02040a2:	002c                	addi	a1,sp,8
ffffffffc02040a4:	7b9c                	ld	a5,48(a5)
ffffffffc02040a6:	854a                	mv	a0,s2
ffffffffc02040a8:	9782                	jalr	a5
          if (r != 0) {
ffffffffc02040aa:	e12d                	bnez	a0,ffffffffc020410c <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc02040ac:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02040ae:	01893503          	ld	a0,24(s2)
ffffffffc02040b2:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc02040b4:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02040b6:	85a6                	mv	a1,s1
ffffffffc02040b8:	f01fc0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc02040bc:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02040be:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc02040c0:	8b85                	andi	a5,a5,1
ffffffffc02040c2:	cfb9                	beqz	a5,ffffffffc0204120 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc02040c4:	65a2                	ld	a1,8(sp)
ffffffffc02040c6:	7d9c                	ld	a5,56(a1)
ffffffffc02040c8:	83b1                	srli	a5,a5,0xc
ffffffffc02040ca:	00178513          	addi	a0,a5,1
ffffffffc02040ce:	0522                	slli	a0,a0,0x8
ffffffffc02040d0:	509000ef          	jal	ra,ffffffffc0204dd8 <swapfs_write>
ffffffffc02040d4:	d949                	beqz	a0,ffffffffc0204066 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc02040d6:	855e                	mv	a0,s7
ffffffffc02040d8:	ff9fb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02040dc:	0009b783          	ld	a5,0(s3)
ffffffffc02040e0:	6622                	ld	a2,8(sp)
ffffffffc02040e2:	4681                	li	a3,0
ffffffffc02040e4:	739c                	ld	a5,32(a5)
ffffffffc02040e6:	85a6                	mv	a1,s1
ffffffffc02040e8:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc02040ea:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02040ec:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc02040ee:	fa8a17e3          	bne	s4,s0,ffffffffc020409c <swap_out+0x70>
}
ffffffffc02040f2:	8522                	mv	a0,s0
ffffffffc02040f4:	60e6                	ld	ra,88(sp)
ffffffffc02040f6:	6446                	ld	s0,80(sp)
ffffffffc02040f8:	64a6                	ld	s1,72(sp)
ffffffffc02040fa:	6906                	ld	s2,64(sp)
ffffffffc02040fc:	79e2                	ld	s3,56(sp)
ffffffffc02040fe:	7a42                	ld	s4,48(sp)
ffffffffc0204100:	7aa2                	ld	s5,40(sp)
ffffffffc0204102:	7b02                	ld	s6,32(sp)
ffffffffc0204104:	6be2                	ld	s7,24(sp)
ffffffffc0204106:	6c42                	ld	s8,16(sp)
ffffffffc0204108:	6125                	addi	sp,sp,96
ffffffffc020410a:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc020410c:	85a2                	mv	a1,s0
ffffffffc020410e:	00004517          	auipc	a0,0x4
ffffffffc0204112:	0b250513          	addi	a0,a0,178 # ffffffffc02081c0 <commands+0x1858>
ffffffffc0204116:	fbbfb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
                  break;
ffffffffc020411a:	bfe1                	j	ffffffffc02040f2 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc020411c:	4401                	li	s0,0
ffffffffc020411e:	bfd1                	j	ffffffffc02040f2 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0204120:	00004697          	auipc	a3,0x4
ffffffffc0204124:	0d068693          	addi	a3,a3,208 # ffffffffc02081f0 <commands+0x1888>
ffffffffc0204128:	00003617          	auipc	a2,0x3
ffffffffc020412c:	cd860613          	addi	a2,a2,-808 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204130:	06800593          	li	a1,104
ffffffffc0204134:	00004517          	auipc	a0,0x4
ffffffffc0204138:	e0450513          	addi	a0,a0,-508 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc020413c:	8dafc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204140 <swap_in>:
{
ffffffffc0204140:	7179                	addi	sp,sp,-48
ffffffffc0204142:	e84a                	sd	s2,16(sp)
ffffffffc0204144:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0204146:	4505                	li	a0,1
{
ffffffffc0204148:	ec26                	sd	s1,24(sp)
ffffffffc020414a:	e44e                	sd	s3,8(sp)
ffffffffc020414c:	f406                	sd	ra,40(sp)
ffffffffc020414e:	f022                	sd	s0,32(sp)
ffffffffc0204150:	84ae                	mv	s1,a1
ffffffffc0204152:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0204154:	d57fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
     assert(result!=NULL);
ffffffffc0204158:	c129                	beqz	a0,ffffffffc020419a <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc020415a:	842a                	mv	s0,a0
ffffffffc020415c:	01893503          	ld	a0,24(s2)
ffffffffc0204160:	4601                	li	a2,0
ffffffffc0204162:	85a6                	mv	a1,s1
ffffffffc0204164:	e55fc0ef          	jal	ra,ffffffffc0200fb8 <get_pte>
ffffffffc0204168:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc020416a:	6108                	ld	a0,0(a0)
ffffffffc020416c:	85a2                	mv	a1,s0
ffffffffc020416e:	3d3000ef          	jal	ra,ffffffffc0204d40 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0204172:	00093583          	ld	a1,0(s2)
ffffffffc0204176:	8626                	mv	a2,s1
ffffffffc0204178:	00004517          	auipc	a0,0x4
ffffffffc020417c:	d6050513          	addi	a0,a0,-672 # ffffffffc0207ed8 <commands+0x1570>
ffffffffc0204180:	81a1                	srli	a1,a1,0x8
ffffffffc0204182:	f4ffb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
}
ffffffffc0204186:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0204188:	0089b023          	sd	s0,0(s3)
}
ffffffffc020418c:	7402                	ld	s0,32(sp)
ffffffffc020418e:	64e2                	ld	s1,24(sp)
ffffffffc0204190:	6942                	ld	s2,16(sp)
ffffffffc0204192:	69a2                	ld	s3,8(sp)
ffffffffc0204194:	4501                	li	a0,0
ffffffffc0204196:	6145                	addi	sp,sp,48
ffffffffc0204198:	8082                	ret
     assert(result!=NULL);
ffffffffc020419a:	00004697          	auipc	a3,0x4
ffffffffc020419e:	d2e68693          	addi	a3,a3,-722 # ffffffffc0207ec8 <commands+0x1560>
ffffffffc02041a2:	00003617          	auipc	a2,0x3
ffffffffc02041a6:	c5e60613          	addi	a2,a2,-930 # ffffffffc0206e00 <commands+0x498>
ffffffffc02041aa:	07e00593          	li	a1,126
ffffffffc02041ae:	00004517          	auipc	a0,0x4
ffffffffc02041b2:	d8a50513          	addi	a0,a0,-630 # ffffffffc0207f38 <commands+0x15d0>
ffffffffc02041b6:	860fc0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02041ba <default_init>:
    elm->prev = elm->next = elm;
ffffffffc02041ba:	000a8797          	auipc	a5,0xa8
ffffffffc02041be:	35e78793          	addi	a5,a5,862 # ffffffffc02ac518 <free_area>
ffffffffc02041c2:	e79c                	sd	a5,8(a5)
ffffffffc02041c4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02041c6:	0007a823          	sw	zero,16(a5)
}
ffffffffc02041ca:	8082                	ret

ffffffffc02041cc <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02041cc:	000a8517          	auipc	a0,0xa8
ffffffffc02041d0:	35c56503          	lwu	a0,860(a0) # ffffffffc02ac528 <free_area+0x10>
ffffffffc02041d4:	8082                	ret

ffffffffc02041d6 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc02041d6:	715d                	addi	sp,sp,-80
ffffffffc02041d8:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc02041da:	000a8917          	auipc	s2,0xa8
ffffffffc02041de:	33e90913          	addi	s2,s2,830 # ffffffffc02ac518 <free_area>
ffffffffc02041e2:	00893783          	ld	a5,8(s2)
ffffffffc02041e6:	e486                	sd	ra,72(sp)
ffffffffc02041e8:	e0a2                	sd	s0,64(sp)
ffffffffc02041ea:	fc26                	sd	s1,56(sp)
ffffffffc02041ec:	f44e                	sd	s3,40(sp)
ffffffffc02041ee:	f052                	sd	s4,32(sp)
ffffffffc02041f0:	ec56                	sd	s5,24(sp)
ffffffffc02041f2:	e85a                	sd	s6,16(sp)
ffffffffc02041f4:	e45e                	sd	s7,8(sp)
ffffffffc02041f6:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02041f8:	31278463          	beq	a5,s2,ffffffffc0204500 <default_check+0x32a>
ffffffffc02041fc:	ff07b703          	ld	a4,-16(a5)
ffffffffc0204200:	8305                	srli	a4,a4,0x1
ffffffffc0204202:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0204204:	30070263          	beqz	a4,ffffffffc0204508 <default_check+0x332>
    int count = 0, total = 0;
ffffffffc0204208:	4401                	li	s0,0
ffffffffc020420a:	4481                	li	s1,0
ffffffffc020420c:	a031                	j	ffffffffc0204218 <default_check+0x42>
ffffffffc020420e:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0204212:	8b09                	andi	a4,a4,2
ffffffffc0204214:	2e070a63          	beqz	a4,ffffffffc0204508 <default_check+0x332>
        count ++, total += p->property;
ffffffffc0204218:	ff87a703          	lw	a4,-8(a5)
ffffffffc020421c:	679c                	ld	a5,8(a5)
ffffffffc020421e:	2485                	addiw	s1,s1,1
ffffffffc0204220:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0204222:	ff2796e3          	bne	a5,s2,ffffffffc020420e <default_check+0x38>
ffffffffc0204226:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0204228:	d51fc0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>
ffffffffc020422c:	73351e63          	bne	a0,s3,ffffffffc0204968 <default_check+0x792>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0204230:	4505                	li	a0,1
ffffffffc0204232:	c79fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0204236:	8a2a                	mv	s4,a0
ffffffffc0204238:	46050863          	beqz	a0,ffffffffc02046a8 <default_check+0x4d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020423c:	4505                	li	a0,1
ffffffffc020423e:	c6dfc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0204242:	89aa                	mv	s3,a0
ffffffffc0204244:	74050263          	beqz	a0,ffffffffc0204988 <default_check+0x7b2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204248:	4505                	li	a0,1
ffffffffc020424a:	c61fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc020424e:	8aaa                	mv	s5,a0
ffffffffc0204250:	4c050c63          	beqz	a0,ffffffffc0204728 <default_check+0x552>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0204254:	2d3a0a63          	beq	s4,s3,ffffffffc0204528 <default_check+0x352>
ffffffffc0204258:	2caa0863          	beq	s4,a0,ffffffffc0204528 <default_check+0x352>
ffffffffc020425c:	2ca98663          	beq	s3,a0,ffffffffc0204528 <default_check+0x352>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0204260:	000a2783          	lw	a5,0(s4)
ffffffffc0204264:	2e079263          	bnez	a5,ffffffffc0204548 <default_check+0x372>
ffffffffc0204268:	0009a783          	lw	a5,0(s3)
ffffffffc020426c:	2c079e63          	bnez	a5,ffffffffc0204548 <default_check+0x372>
ffffffffc0204270:	411c                	lw	a5,0(a0)
ffffffffc0204272:	2c079b63          	bnez	a5,ffffffffc0204548 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0204276:	000a8797          	auipc	a5,0xa8
ffffffffc020427a:	1ba78793          	addi	a5,a5,442 # ffffffffc02ac430 <pages>
ffffffffc020427e:	639c                	ld	a5,0(a5)
ffffffffc0204280:	00005717          	auipc	a4,0x5
ffffffffc0204284:	cf870713          	addi	a4,a4,-776 # ffffffffc0208f78 <nbase>
ffffffffc0204288:	6310                	ld	a2,0(a4)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020428a:	000a8717          	auipc	a4,0xa8
ffffffffc020428e:	13e70713          	addi	a4,a4,318 # ffffffffc02ac3c8 <npage>
ffffffffc0204292:	6314                	ld	a3,0(a4)
ffffffffc0204294:	40fa0733          	sub	a4,s4,a5
ffffffffc0204298:	8719                	srai	a4,a4,0x6
ffffffffc020429a:	9732                	add	a4,a4,a2
ffffffffc020429c:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020429e:	0732                	slli	a4,a4,0xc
ffffffffc02042a0:	2cd77463          	bleu	a3,a4,ffffffffc0204568 <default_check+0x392>
    return page - pages + nbase;
ffffffffc02042a4:	40f98733          	sub	a4,s3,a5
ffffffffc02042a8:	8719                	srai	a4,a4,0x6
ffffffffc02042aa:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02042ac:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02042ae:	4ed77d63          	bleu	a3,a4,ffffffffc02047a8 <default_check+0x5d2>
    return page - pages + nbase;
ffffffffc02042b2:	40f507b3          	sub	a5,a0,a5
ffffffffc02042b6:	8799                	srai	a5,a5,0x6
ffffffffc02042b8:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02042ba:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02042bc:	34d7f663          	bleu	a3,a5,ffffffffc0204608 <default_check+0x432>
    assert(alloc_page() == NULL);
ffffffffc02042c0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02042c2:	00093c03          	ld	s8,0(s2)
ffffffffc02042c6:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02042ca:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc02042ce:	000a8797          	auipc	a5,0xa8
ffffffffc02042d2:	2527b923          	sd	s2,594(a5) # ffffffffc02ac520 <free_area+0x8>
ffffffffc02042d6:	000a8797          	auipc	a5,0xa8
ffffffffc02042da:	2527b123          	sd	s2,578(a5) # ffffffffc02ac518 <free_area>
    nr_free = 0;
ffffffffc02042de:	000a8797          	auipc	a5,0xa8
ffffffffc02042e2:	2407a523          	sw	zero,586(a5) # ffffffffc02ac528 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02042e6:	bc5fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc02042ea:	2e051f63          	bnez	a0,ffffffffc02045e8 <default_check+0x412>
    free_page(p0);
ffffffffc02042ee:	4585                	li	a1,1
ffffffffc02042f0:	8552                	mv	a0,s4
ffffffffc02042f2:	c41fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    free_page(p1);
ffffffffc02042f6:	4585                	li	a1,1
ffffffffc02042f8:	854e                	mv	a0,s3
ffffffffc02042fa:	c39fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    free_page(p2);
ffffffffc02042fe:	4585                	li	a1,1
ffffffffc0204300:	8556                	mv	a0,s5
ffffffffc0204302:	c31fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    assert(nr_free == 3);
ffffffffc0204306:	01092703          	lw	a4,16(s2)
ffffffffc020430a:	478d                	li	a5,3
ffffffffc020430c:	2af71e63          	bne	a4,a5,ffffffffc02045c8 <default_check+0x3f2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0204310:	4505                	li	a0,1
ffffffffc0204312:	b99fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0204316:	89aa                	mv	s3,a0
ffffffffc0204318:	28050863          	beqz	a0,ffffffffc02045a8 <default_check+0x3d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020431c:	4505                	li	a0,1
ffffffffc020431e:	b8dfc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0204322:	8aaa                	mv	s5,a0
ffffffffc0204324:	3e050263          	beqz	a0,ffffffffc0204708 <default_check+0x532>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204328:	4505                	li	a0,1
ffffffffc020432a:	b81fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc020432e:	8a2a                	mv	s4,a0
ffffffffc0204330:	3a050c63          	beqz	a0,ffffffffc02046e8 <default_check+0x512>
    assert(alloc_page() == NULL);
ffffffffc0204334:	4505                	li	a0,1
ffffffffc0204336:	b75fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc020433a:	38051763          	bnez	a0,ffffffffc02046c8 <default_check+0x4f2>
    free_page(p0);
ffffffffc020433e:	4585                	li	a1,1
ffffffffc0204340:	854e                	mv	a0,s3
ffffffffc0204342:	bf1fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0204346:	00893783          	ld	a5,8(s2)
ffffffffc020434a:	23278f63          	beq	a5,s2,ffffffffc0204588 <default_check+0x3b2>
    assert((p = alloc_page()) == p0);
ffffffffc020434e:	4505                	li	a0,1
ffffffffc0204350:	b5bfc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0204354:	32a99a63          	bne	s3,a0,ffffffffc0204688 <default_check+0x4b2>
    assert(alloc_page() == NULL);
ffffffffc0204358:	4505                	li	a0,1
ffffffffc020435a:	b51fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc020435e:	30051563          	bnez	a0,ffffffffc0204668 <default_check+0x492>
    assert(nr_free == 0);
ffffffffc0204362:	01092783          	lw	a5,16(s2)
ffffffffc0204366:	2e079163          	bnez	a5,ffffffffc0204648 <default_check+0x472>
    free_page(p);
ffffffffc020436a:	854e                	mv	a0,s3
ffffffffc020436c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020436e:	000a8797          	auipc	a5,0xa8
ffffffffc0204372:	1b87b523          	sd	s8,426(a5) # ffffffffc02ac518 <free_area>
ffffffffc0204376:	000a8797          	auipc	a5,0xa8
ffffffffc020437a:	1b77b523          	sd	s7,426(a5) # ffffffffc02ac520 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc020437e:	000a8797          	auipc	a5,0xa8
ffffffffc0204382:	1b67a523          	sw	s6,426(a5) # ffffffffc02ac528 <free_area+0x10>
    free_page(p);
ffffffffc0204386:	badfc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    free_page(p1);
ffffffffc020438a:	4585                	li	a1,1
ffffffffc020438c:	8556                	mv	a0,s5
ffffffffc020438e:	ba5fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    free_page(p2);
ffffffffc0204392:	4585                	li	a1,1
ffffffffc0204394:	8552                	mv	a0,s4
ffffffffc0204396:	b9dfc0ef          	jal	ra,ffffffffc0200f32 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020439a:	4515                	li	a0,5
ffffffffc020439c:	b0ffc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc02043a0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02043a2:	28050363          	beqz	a0,ffffffffc0204628 <default_check+0x452>
ffffffffc02043a6:	651c                	ld	a5,8(a0)
ffffffffc02043a8:	8385                	srli	a5,a5,0x1
ffffffffc02043aa:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02043ac:	54079e63          	bnez	a5,ffffffffc0204908 <default_check+0x732>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02043b0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02043b2:	00093b03          	ld	s6,0(s2)
ffffffffc02043b6:	00893a83          	ld	s5,8(s2)
ffffffffc02043ba:	000a8797          	auipc	a5,0xa8
ffffffffc02043be:	1527bf23          	sd	s2,350(a5) # ffffffffc02ac518 <free_area>
ffffffffc02043c2:	000a8797          	auipc	a5,0xa8
ffffffffc02043c6:	1527bf23          	sd	s2,350(a5) # ffffffffc02ac520 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc02043ca:	ae1fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc02043ce:	50051d63          	bnez	a0,ffffffffc02048e8 <default_check+0x712>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02043d2:	08098a13          	addi	s4,s3,128
ffffffffc02043d6:	8552                	mv	a0,s4
ffffffffc02043d8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02043da:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc02043de:	000a8797          	auipc	a5,0xa8
ffffffffc02043e2:	1407a523          	sw	zero,330(a5) # ffffffffc02ac528 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02043e6:	b4dfc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02043ea:	4511                	li	a0,4
ffffffffc02043ec:	abffc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc02043f0:	4c051c63          	bnez	a0,ffffffffc02048c8 <default_check+0x6f2>
ffffffffc02043f4:	0889b783          	ld	a5,136(s3)
ffffffffc02043f8:	8385                	srli	a5,a5,0x1
ffffffffc02043fa:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02043fc:	4a078663          	beqz	a5,ffffffffc02048a8 <default_check+0x6d2>
ffffffffc0204400:	0909a703          	lw	a4,144(s3)
ffffffffc0204404:	478d                	li	a5,3
ffffffffc0204406:	4af71163          	bne	a4,a5,ffffffffc02048a8 <default_check+0x6d2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020440a:	450d                	li	a0,3
ffffffffc020440c:	a9ffc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0204410:	8c2a                	mv	s8,a0
ffffffffc0204412:	46050b63          	beqz	a0,ffffffffc0204888 <default_check+0x6b2>
    assert(alloc_page() == NULL);
ffffffffc0204416:	4505                	li	a0,1
ffffffffc0204418:	a93fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc020441c:	44051663          	bnez	a0,ffffffffc0204868 <default_check+0x692>
    assert(p0 + 2 == p1);
ffffffffc0204420:	438a1463          	bne	s4,s8,ffffffffc0204848 <default_check+0x672>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0204424:	4585                	li	a1,1
ffffffffc0204426:	854e                	mv	a0,s3
ffffffffc0204428:	b0bfc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    free_pages(p1, 3);
ffffffffc020442c:	458d                	li	a1,3
ffffffffc020442e:	8552                	mv	a0,s4
ffffffffc0204430:	b03fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
ffffffffc0204434:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0204438:	04098c13          	addi	s8,s3,64
ffffffffc020443c:	8385                	srli	a5,a5,0x1
ffffffffc020443e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0204440:	3e078463          	beqz	a5,ffffffffc0204828 <default_check+0x652>
ffffffffc0204444:	0109a703          	lw	a4,16(s3)
ffffffffc0204448:	4785                	li	a5,1
ffffffffc020444a:	3cf71f63          	bne	a4,a5,ffffffffc0204828 <default_check+0x652>
ffffffffc020444e:	008a3783          	ld	a5,8(s4)
ffffffffc0204452:	8385                	srli	a5,a5,0x1
ffffffffc0204454:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0204456:	3a078963          	beqz	a5,ffffffffc0204808 <default_check+0x632>
ffffffffc020445a:	010a2703          	lw	a4,16(s4)
ffffffffc020445e:	478d                	li	a5,3
ffffffffc0204460:	3af71463          	bne	a4,a5,ffffffffc0204808 <default_check+0x632>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0204464:	4505                	li	a0,1
ffffffffc0204466:	a45fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc020446a:	36a99f63          	bne	s3,a0,ffffffffc02047e8 <default_check+0x612>
    free_page(p0);
ffffffffc020446e:	4585                	li	a1,1
ffffffffc0204470:	ac3fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0204474:	4509                	li	a0,2
ffffffffc0204476:	a35fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc020447a:	34aa1763          	bne	s4,a0,ffffffffc02047c8 <default_check+0x5f2>

    free_pages(p0, 2);
ffffffffc020447e:	4589                	li	a1,2
ffffffffc0204480:	ab3fc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    free_page(p2);
ffffffffc0204484:	4585                	li	a1,1
ffffffffc0204486:	8562                	mv	a0,s8
ffffffffc0204488:	aabfc0ef          	jal	ra,ffffffffc0200f32 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020448c:	4515                	li	a0,5
ffffffffc020448e:	a1dfc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0204492:	89aa                	mv	s3,a0
ffffffffc0204494:	48050a63          	beqz	a0,ffffffffc0204928 <default_check+0x752>
    assert(alloc_page() == NULL);
ffffffffc0204498:	4505                	li	a0,1
ffffffffc020449a:	a11fc0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc020449e:	2e051563          	bnez	a0,ffffffffc0204788 <default_check+0x5b2>

    assert(nr_free == 0);
ffffffffc02044a2:	01092783          	lw	a5,16(s2)
ffffffffc02044a6:	2c079163          	bnez	a5,ffffffffc0204768 <default_check+0x592>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02044aa:	4595                	li	a1,5
ffffffffc02044ac:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02044ae:	000a8797          	auipc	a5,0xa8
ffffffffc02044b2:	0777ad23          	sw	s7,122(a5) # ffffffffc02ac528 <free_area+0x10>
    free_list = free_list_store;
ffffffffc02044b6:	000a8797          	auipc	a5,0xa8
ffffffffc02044ba:	0767b123          	sd	s6,98(a5) # ffffffffc02ac518 <free_area>
ffffffffc02044be:	000a8797          	auipc	a5,0xa8
ffffffffc02044c2:	0757b123          	sd	s5,98(a5) # ffffffffc02ac520 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc02044c6:	a6dfc0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    return listelm->next;
ffffffffc02044ca:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02044ce:	01278963          	beq	a5,s2,ffffffffc02044e0 <default_check+0x30a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02044d2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02044d6:	679c                	ld	a5,8(a5)
ffffffffc02044d8:	34fd                	addiw	s1,s1,-1
ffffffffc02044da:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02044dc:	ff279be3          	bne	a5,s2,ffffffffc02044d2 <default_check+0x2fc>
    }
    assert(count == 0);
ffffffffc02044e0:	26049463          	bnez	s1,ffffffffc0204748 <default_check+0x572>
    assert(total == 0);
ffffffffc02044e4:	46041263          	bnez	s0,ffffffffc0204948 <default_check+0x772>
}
ffffffffc02044e8:	60a6                	ld	ra,72(sp)
ffffffffc02044ea:	6406                	ld	s0,64(sp)
ffffffffc02044ec:	74e2                	ld	s1,56(sp)
ffffffffc02044ee:	7942                	ld	s2,48(sp)
ffffffffc02044f0:	79a2                	ld	s3,40(sp)
ffffffffc02044f2:	7a02                	ld	s4,32(sp)
ffffffffc02044f4:	6ae2                	ld	s5,24(sp)
ffffffffc02044f6:	6b42                	ld	s6,16(sp)
ffffffffc02044f8:	6ba2                	ld	s7,8(sp)
ffffffffc02044fa:	6c02                	ld	s8,0(sp)
ffffffffc02044fc:	6161                	addi	sp,sp,80
ffffffffc02044fe:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0204500:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0204502:	4401                	li	s0,0
ffffffffc0204504:	4481                	li	s1,0
ffffffffc0204506:	b30d                	j	ffffffffc0204228 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0204508:	00004697          	auipc	a3,0x4
ffffffffc020450c:	a5868693          	addi	a3,a3,-1448 # ffffffffc0207f60 <commands+0x15f8>
ffffffffc0204510:	00003617          	auipc	a2,0x3
ffffffffc0204514:	8f060613          	addi	a2,a2,-1808 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204518:	0f000593          	li	a1,240
ffffffffc020451c:	00004517          	auipc	a0,0x4
ffffffffc0204520:	d4450513          	addi	a0,a0,-700 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204524:	cf3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0204528:	00004697          	auipc	a3,0x4
ffffffffc020452c:	db068693          	addi	a3,a3,-592 # ffffffffc02082d8 <commands+0x1970>
ffffffffc0204530:	00003617          	auipc	a2,0x3
ffffffffc0204534:	8d060613          	addi	a2,a2,-1840 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204538:	0bd00593          	li	a1,189
ffffffffc020453c:	00004517          	auipc	a0,0x4
ffffffffc0204540:	d2450513          	addi	a0,a0,-732 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204544:	cd3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0204548:	00004697          	auipc	a3,0x4
ffffffffc020454c:	db868693          	addi	a3,a3,-584 # ffffffffc0208300 <commands+0x1998>
ffffffffc0204550:	00003617          	auipc	a2,0x3
ffffffffc0204554:	8b060613          	addi	a2,a2,-1872 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204558:	0be00593          	li	a1,190
ffffffffc020455c:	00004517          	auipc	a0,0x4
ffffffffc0204560:	d0450513          	addi	a0,a0,-764 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204564:	cb3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0204568:	00004697          	auipc	a3,0x4
ffffffffc020456c:	dd868693          	addi	a3,a3,-552 # ffffffffc0208340 <commands+0x19d8>
ffffffffc0204570:	00003617          	auipc	a2,0x3
ffffffffc0204574:	89060613          	addi	a2,a2,-1904 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204578:	0c000593          	li	a1,192
ffffffffc020457c:	00004517          	auipc	a0,0x4
ffffffffc0204580:	ce450513          	addi	a0,a0,-796 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204584:	c93fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0204588:	00004697          	auipc	a3,0x4
ffffffffc020458c:	e4068693          	addi	a3,a3,-448 # ffffffffc02083c8 <commands+0x1a60>
ffffffffc0204590:	00003617          	auipc	a2,0x3
ffffffffc0204594:	87060613          	addi	a2,a2,-1936 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204598:	0d900593          	li	a1,217
ffffffffc020459c:	00004517          	auipc	a0,0x4
ffffffffc02045a0:	cc450513          	addi	a0,a0,-828 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02045a4:	c73fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02045a8:	00004697          	auipc	a3,0x4
ffffffffc02045ac:	cd068693          	addi	a3,a3,-816 # ffffffffc0208278 <commands+0x1910>
ffffffffc02045b0:	00003617          	auipc	a2,0x3
ffffffffc02045b4:	85060613          	addi	a2,a2,-1968 # ffffffffc0206e00 <commands+0x498>
ffffffffc02045b8:	0d200593          	li	a1,210
ffffffffc02045bc:	00004517          	auipc	a0,0x4
ffffffffc02045c0:	ca450513          	addi	a0,a0,-860 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02045c4:	c53fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free == 3);
ffffffffc02045c8:	00004697          	auipc	a3,0x4
ffffffffc02045cc:	df068693          	addi	a3,a3,-528 # ffffffffc02083b8 <commands+0x1a50>
ffffffffc02045d0:	00003617          	auipc	a2,0x3
ffffffffc02045d4:	83060613          	addi	a2,a2,-2000 # ffffffffc0206e00 <commands+0x498>
ffffffffc02045d8:	0d000593          	li	a1,208
ffffffffc02045dc:	00004517          	auipc	a0,0x4
ffffffffc02045e0:	c8450513          	addi	a0,a0,-892 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02045e4:	c33fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02045e8:	00004697          	auipc	a3,0x4
ffffffffc02045ec:	db868693          	addi	a3,a3,-584 # ffffffffc02083a0 <commands+0x1a38>
ffffffffc02045f0:	00003617          	auipc	a2,0x3
ffffffffc02045f4:	81060613          	addi	a2,a2,-2032 # ffffffffc0206e00 <commands+0x498>
ffffffffc02045f8:	0cb00593          	li	a1,203
ffffffffc02045fc:	00004517          	auipc	a0,0x4
ffffffffc0204600:	c6450513          	addi	a0,a0,-924 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204604:	c13fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0204608:	00004697          	auipc	a3,0x4
ffffffffc020460c:	d7868693          	addi	a3,a3,-648 # ffffffffc0208380 <commands+0x1a18>
ffffffffc0204610:	00002617          	auipc	a2,0x2
ffffffffc0204614:	7f060613          	addi	a2,a2,2032 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204618:	0c200593          	li	a1,194
ffffffffc020461c:	00004517          	auipc	a0,0x4
ffffffffc0204620:	c4450513          	addi	a0,a0,-956 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204624:	bf3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(p0 != NULL);
ffffffffc0204628:	00004697          	auipc	a3,0x4
ffffffffc020462c:	dd868693          	addi	a3,a3,-552 # ffffffffc0208400 <commands+0x1a98>
ffffffffc0204630:	00002617          	auipc	a2,0x2
ffffffffc0204634:	7d060613          	addi	a2,a2,2000 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204638:	0f800593          	li	a1,248
ffffffffc020463c:	00004517          	auipc	a0,0x4
ffffffffc0204640:	c2450513          	addi	a0,a0,-988 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204644:	bd3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free == 0);
ffffffffc0204648:	00004697          	auipc	a3,0x4
ffffffffc020464c:	ab868693          	addi	a3,a3,-1352 # ffffffffc0208100 <commands+0x1798>
ffffffffc0204650:	00002617          	auipc	a2,0x2
ffffffffc0204654:	7b060613          	addi	a2,a2,1968 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204658:	0df00593          	li	a1,223
ffffffffc020465c:	00004517          	auipc	a0,0x4
ffffffffc0204660:	c0450513          	addi	a0,a0,-1020 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204664:	bb3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204668:	00004697          	auipc	a3,0x4
ffffffffc020466c:	d3868693          	addi	a3,a3,-712 # ffffffffc02083a0 <commands+0x1a38>
ffffffffc0204670:	00002617          	auipc	a2,0x2
ffffffffc0204674:	79060613          	addi	a2,a2,1936 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204678:	0dd00593          	li	a1,221
ffffffffc020467c:	00004517          	auipc	a0,0x4
ffffffffc0204680:	be450513          	addi	a0,a0,-1052 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204684:	b93fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0204688:	00004697          	auipc	a3,0x4
ffffffffc020468c:	d5868693          	addi	a3,a3,-680 # ffffffffc02083e0 <commands+0x1a78>
ffffffffc0204690:	00002617          	auipc	a2,0x2
ffffffffc0204694:	77060613          	addi	a2,a2,1904 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204698:	0dc00593          	li	a1,220
ffffffffc020469c:	00004517          	auipc	a0,0x4
ffffffffc02046a0:	bc450513          	addi	a0,a0,-1084 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02046a4:	b73fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02046a8:	00004697          	auipc	a3,0x4
ffffffffc02046ac:	bd068693          	addi	a3,a3,-1072 # ffffffffc0208278 <commands+0x1910>
ffffffffc02046b0:	00002617          	auipc	a2,0x2
ffffffffc02046b4:	75060613          	addi	a2,a2,1872 # ffffffffc0206e00 <commands+0x498>
ffffffffc02046b8:	0b900593          	li	a1,185
ffffffffc02046bc:	00004517          	auipc	a0,0x4
ffffffffc02046c0:	ba450513          	addi	a0,a0,-1116 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02046c4:	b53fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02046c8:	00004697          	auipc	a3,0x4
ffffffffc02046cc:	cd868693          	addi	a3,a3,-808 # ffffffffc02083a0 <commands+0x1a38>
ffffffffc02046d0:	00002617          	auipc	a2,0x2
ffffffffc02046d4:	73060613          	addi	a2,a2,1840 # ffffffffc0206e00 <commands+0x498>
ffffffffc02046d8:	0d600593          	li	a1,214
ffffffffc02046dc:	00004517          	auipc	a0,0x4
ffffffffc02046e0:	b8450513          	addi	a0,a0,-1148 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02046e4:	b33fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02046e8:	00004697          	auipc	a3,0x4
ffffffffc02046ec:	bd068693          	addi	a3,a3,-1072 # ffffffffc02082b8 <commands+0x1950>
ffffffffc02046f0:	00002617          	auipc	a2,0x2
ffffffffc02046f4:	71060613          	addi	a2,a2,1808 # ffffffffc0206e00 <commands+0x498>
ffffffffc02046f8:	0d400593          	li	a1,212
ffffffffc02046fc:	00004517          	auipc	a0,0x4
ffffffffc0204700:	b6450513          	addi	a0,a0,-1180 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204704:	b13fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0204708:	00004697          	auipc	a3,0x4
ffffffffc020470c:	b9068693          	addi	a3,a3,-1136 # ffffffffc0208298 <commands+0x1930>
ffffffffc0204710:	00002617          	auipc	a2,0x2
ffffffffc0204714:	6f060613          	addi	a2,a2,1776 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204718:	0d300593          	li	a1,211
ffffffffc020471c:	00004517          	auipc	a0,0x4
ffffffffc0204720:	b4450513          	addi	a0,a0,-1212 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204724:	af3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0204728:	00004697          	auipc	a3,0x4
ffffffffc020472c:	b9068693          	addi	a3,a3,-1136 # ffffffffc02082b8 <commands+0x1950>
ffffffffc0204730:	00002617          	auipc	a2,0x2
ffffffffc0204734:	6d060613          	addi	a2,a2,1744 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204738:	0bb00593          	li	a1,187
ffffffffc020473c:	00004517          	auipc	a0,0x4
ffffffffc0204740:	b2450513          	addi	a0,a0,-1244 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204744:	ad3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(count == 0);
ffffffffc0204748:	00004697          	auipc	a3,0x4
ffffffffc020474c:	e0868693          	addi	a3,a3,-504 # ffffffffc0208550 <commands+0x1be8>
ffffffffc0204750:	00002617          	auipc	a2,0x2
ffffffffc0204754:	6b060613          	addi	a2,a2,1712 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204758:	12500593          	li	a1,293
ffffffffc020475c:	00004517          	auipc	a0,0x4
ffffffffc0204760:	b0450513          	addi	a0,a0,-1276 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204764:	ab3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_free == 0);
ffffffffc0204768:	00004697          	auipc	a3,0x4
ffffffffc020476c:	99868693          	addi	a3,a3,-1640 # ffffffffc0208100 <commands+0x1798>
ffffffffc0204770:	00002617          	auipc	a2,0x2
ffffffffc0204774:	69060613          	addi	a2,a2,1680 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204778:	11a00593          	li	a1,282
ffffffffc020477c:	00004517          	auipc	a0,0x4
ffffffffc0204780:	ae450513          	addi	a0,a0,-1308 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204784:	a93fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204788:	00004697          	auipc	a3,0x4
ffffffffc020478c:	c1868693          	addi	a3,a3,-1000 # ffffffffc02083a0 <commands+0x1a38>
ffffffffc0204790:	00002617          	auipc	a2,0x2
ffffffffc0204794:	67060613          	addi	a2,a2,1648 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204798:	11800593          	li	a1,280
ffffffffc020479c:	00004517          	auipc	a0,0x4
ffffffffc02047a0:	ac450513          	addi	a0,a0,-1340 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02047a4:	a73fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02047a8:	00004697          	auipc	a3,0x4
ffffffffc02047ac:	bb868693          	addi	a3,a3,-1096 # ffffffffc0208360 <commands+0x19f8>
ffffffffc02047b0:	00002617          	auipc	a2,0x2
ffffffffc02047b4:	65060613          	addi	a2,a2,1616 # ffffffffc0206e00 <commands+0x498>
ffffffffc02047b8:	0c100593          	li	a1,193
ffffffffc02047bc:	00004517          	auipc	a0,0x4
ffffffffc02047c0:	aa450513          	addi	a0,a0,-1372 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02047c4:	a53fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02047c8:	00004697          	auipc	a3,0x4
ffffffffc02047cc:	d4868693          	addi	a3,a3,-696 # ffffffffc0208510 <commands+0x1ba8>
ffffffffc02047d0:	00002617          	auipc	a2,0x2
ffffffffc02047d4:	63060613          	addi	a2,a2,1584 # ffffffffc0206e00 <commands+0x498>
ffffffffc02047d8:	11200593          	li	a1,274
ffffffffc02047dc:	00004517          	auipc	a0,0x4
ffffffffc02047e0:	a8450513          	addi	a0,a0,-1404 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02047e4:	a33fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02047e8:	00004697          	auipc	a3,0x4
ffffffffc02047ec:	d0868693          	addi	a3,a3,-760 # ffffffffc02084f0 <commands+0x1b88>
ffffffffc02047f0:	00002617          	auipc	a2,0x2
ffffffffc02047f4:	61060613          	addi	a2,a2,1552 # ffffffffc0206e00 <commands+0x498>
ffffffffc02047f8:	11000593          	li	a1,272
ffffffffc02047fc:	00004517          	auipc	a0,0x4
ffffffffc0204800:	a6450513          	addi	a0,a0,-1436 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204804:	a13fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0204808:	00004697          	auipc	a3,0x4
ffffffffc020480c:	cc068693          	addi	a3,a3,-832 # ffffffffc02084c8 <commands+0x1b60>
ffffffffc0204810:	00002617          	auipc	a2,0x2
ffffffffc0204814:	5f060613          	addi	a2,a2,1520 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204818:	10e00593          	li	a1,270
ffffffffc020481c:	00004517          	auipc	a0,0x4
ffffffffc0204820:	a4450513          	addi	a0,a0,-1468 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204824:	9f3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0204828:	00004697          	auipc	a3,0x4
ffffffffc020482c:	c7868693          	addi	a3,a3,-904 # ffffffffc02084a0 <commands+0x1b38>
ffffffffc0204830:	00002617          	auipc	a2,0x2
ffffffffc0204834:	5d060613          	addi	a2,a2,1488 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204838:	10d00593          	li	a1,269
ffffffffc020483c:	00004517          	auipc	a0,0x4
ffffffffc0204840:	a2450513          	addi	a0,a0,-1500 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204844:	9d3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0204848:	00004697          	auipc	a3,0x4
ffffffffc020484c:	c4868693          	addi	a3,a3,-952 # ffffffffc0208490 <commands+0x1b28>
ffffffffc0204850:	00002617          	auipc	a2,0x2
ffffffffc0204854:	5b060613          	addi	a2,a2,1456 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204858:	10800593          	li	a1,264
ffffffffc020485c:	00004517          	auipc	a0,0x4
ffffffffc0204860:	a0450513          	addi	a0,a0,-1532 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204864:	9b3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0204868:	00004697          	auipc	a3,0x4
ffffffffc020486c:	b3868693          	addi	a3,a3,-1224 # ffffffffc02083a0 <commands+0x1a38>
ffffffffc0204870:	00002617          	auipc	a2,0x2
ffffffffc0204874:	59060613          	addi	a2,a2,1424 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204878:	10700593          	li	a1,263
ffffffffc020487c:	00004517          	auipc	a0,0x4
ffffffffc0204880:	9e450513          	addi	a0,a0,-1564 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204884:	993fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0204888:	00004697          	auipc	a3,0x4
ffffffffc020488c:	be868693          	addi	a3,a3,-1048 # ffffffffc0208470 <commands+0x1b08>
ffffffffc0204890:	00002617          	auipc	a2,0x2
ffffffffc0204894:	57060613          	addi	a2,a2,1392 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204898:	10600593          	li	a1,262
ffffffffc020489c:	00004517          	auipc	a0,0x4
ffffffffc02048a0:	9c450513          	addi	a0,a0,-1596 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02048a4:	973fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02048a8:	00004697          	auipc	a3,0x4
ffffffffc02048ac:	b9868693          	addi	a3,a3,-1128 # ffffffffc0208440 <commands+0x1ad8>
ffffffffc02048b0:	00002617          	auipc	a2,0x2
ffffffffc02048b4:	55060613          	addi	a2,a2,1360 # ffffffffc0206e00 <commands+0x498>
ffffffffc02048b8:	10500593          	li	a1,261
ffffffffc02048bc:	00004517          	auipc	a0,0x4
ffffffffc02048c0:	9a450513          	addi	a0,a0,-1628 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02048c4:	953fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02048c8:	00004697          	auipc	a3,0x4
ffffffffc02048cc:	b6068693          	addi	a3,a3,-1184 # ffffffffc0208428 <commands+0x1ac0>
ffffffffc02048d0:	00002617          	auipc	a2,0x2
ffffffffc02048d4:	53060613          	addi	a2,a2,1328 # ffffffffc0206e00 <commands+0x498>
ffffffffc02048d8:	10400593          	li	a1,260
ffffffffc02048dc:	00004517          	auipc	a0,0x4
ffffffffc02048e0:	98450513          	addi	a0,a0,-1660 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02048e4:	933fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02048e8:	00004697          	auipc	a3,0x4
ffffffffc02048ec:	ab868693          	addi	a3,a3,-1352 # ffffffffc02083a0 <commands+0x1a38>
ffffffffc02048f0:	00002617          	auipc	a2,0x2
ffffffffc02048f4:	51060613          	addi	a2,a2,1296 # ffffffffc0206e00 <commands+0x498>
ffffffffc02048f8:	0fe00593          	li	a1,254
ffffffffc02048fc:	00004517          	auipc	a0,0x4
ffffffffc0204900:	96450513          	addi	a0,a0,-1692 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204904:	913fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(!PageProperty(p0));
ffffffffc0204908:	00004697          	auipc	a3,0x4
ffffffffc020490c:	b0868693          	addi	a3,a3,-1272 # ffffffffc0208410 <commands+0x1aa8>
ffffffffc0204910:	00002617          	auipc	a2,0x2
ffffffffc0204914:	4f060613          	addi	a2,a2,1264 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204918:	0f900593          	li	a1,249
ffffffffc020491c:	00004517          	auipc	a0,0x4
ffffffffc0204920:	94450513          	addi	a0,a0,-1724 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204924:	8f3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0204928:	00004697          	auipc	a3,0x4
ffffffffc020492c:	c0868693          	addi	a3,a3,-1016 # ffffffffc0208530 <commands+0x1bc8>
ffffffffc0204930:	00002617          	auipc	a2,0x2
ffffffffc0204934:	4d060613          	addi	a2,a2,1232 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204938:	11700593          	li	a1,279
ffffffffc020493c:	00004517          	auipc	a0,0x4
ffffffffc0204940:	92450513          	addi	a0,a0,-1756 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204944:	8d3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(total == 0);
ffffffffc0204948:	00004697          	auipc	a3,0x4
ffffffffc020494c:	c1868693          	addi	a3,a3,-1000 # ffffffffc0208560 <commands+0x1bf8>
ffffffffc0204950:	00002617          	auipc	a2,0x2
ffffffffc0204954:	4b060613          	addi	a2,a2,1200 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204958:	12600593          	li	a1,294
ffffffffc020495c:	00004517          	auipc	a0,0x4
ffffffffc0204960:	90450513          	addi	a0,a0,-1788 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204964:	8b3fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(total == nr_free_pages());
ffffffffc0204968:	00003697          	auipc	a3,0x3
ffffffffc020496c:	60868693          	addi	a3,a3,1544 # ffffffffc0207f70 <commands+0x1608>
ffffffffc0204970:	00002617          	auipc	a2,0x2
ffffffffc0204974:	49060613          	addi	a2,a2,1168 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204978:	0f300593          	li	a1,243
ffffffffc020497c:	00004517          	auipc	a0,0x4
ffffffffc0204980:	8e450513          	addi	a0,a0,-1820 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204984:	893fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0204988:	00004697          	auipc	a3,0x4
ffffffffc020498c:	91068693          	addi	a3,a3,-1776 # ffffffffc0208298 <commands+0x1930>
ffffffffc0204990:	00002617          	auipc	a2,0x2
ffffffffc0204994:	47060613          	addi	a2,a2,1136 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204998:	0ba00593          	li	a1,186
ffffffffc020499c:	00004517          	auipc	a0,0x4
ffffffffc02049a0:	8c450513          	addi	a0,a0,-1852 # ffffffffc0208260 <commands+0x18f8>
ffffffffc02049a4:	873fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02049a8 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02049a8:	1141                	addi	sp,sp,-16
ffffffffc02049aa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02049ac:	16058e63          	beqz	a1,ffffffffc0204b28 <default_free_pages+0x180>
    for (; p != base + n; p ++) {
ffffffffc02049b0:	00659693          	slli	a3,a1,0x6
ffffffffc02049b4:	96aa                	add	a3,a3,a0
ffffffffc02049b6:	02d50d63          	beq	a0,a3,ffffffffc02049f0 <default_free_pages+0x48>
ffffffffc02049ba:	651c                	ld	a5,8(a0)
ffffffffc02049bc:	8b85                	andi	a5,a5,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02049be:	14079563          	bnez	a5,ffffffffc0204b08 <default_free_pages+0x160>
ffffffffc02049c2:	651c                	ld	a5,8(a0)
ffffffffc02049c4:	8385                	srli	a5,a5,0x1
ffffffffc02049c6:	8b85                	andi	a5,a5,1
ffffffffc02049c8:	14079063          	bnez	a5,ffffffffc0204b08 <default_free_pages+0x160>
ffffffffc02049cc:	87aa                	mv	a5,a0
ffffffffc02049ce:	a809                	j	ffffffffc02049e0 <default_free_pages+0x38>
ffffffffc02049d0:	6798                	ld	a4,8(a5)
ffffffffc02049d2:	8b05                	andi	a4,a4,1
ffffffffc02049d4:	12071a63          	bnez	a4,ffffffffc0204b08 <default_free_pages+0x160>
ffffffffc02049d8:	6798                	ld	a4,8(a5)
ffffffffc02049da:	8b09                	andi	a4,a4,2
ffffffffc02049dc:	12071663          	bnez	a4,ffffffffc0204b08 <default_free_pages+0x160>
        p->flags = 0;
ffffffffc02049e0:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc02049e4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02049e8:	04078793          	addi	a5,a5,64
ffffffffc02049ec:	fed792e3          	bne	a5,a3,ffffffffc02049d0 <default_free_pages+0x28>
    base->property = n;
ffffffffc02049f0:	2581                	sext.w	a1,a1
ffffffffc02049f2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02049f4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02049f8:	4789                	li	a5,2
ffffffffc02049fa:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02049fe:	000a8697          	auipc	a3,0xa8
ffffffffc0204a02:	b1a68693          	addi	a3,a3,-1254 # ffffffffc02ac518 <free_area>
ffffffffc0204a06:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0204a08:	669c                	ld	a5,8(a3)
ffffffffc0204a0a:	9db9                	addw	a1,a1,a4
ffffffffc0204a0c:	000a8717          	auipc	a4,0xa8
ffffffffc0204a10:	b0b72e23          	sw	a1,-1252(a4) # ffffffffc02ac528 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0204a14:	0cd78163          	beq	a5,a3,ffffffffc0204ad6 <default_free_pages+0x12e>
            struct Page* page = le2page(le, page_link);
ffffffffc0204a18:	fe878713          	addi	a4,a5,-24
ffffffffc0204a1c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0204a1e:	4801                	li	a6,0
ffffffffc0204a20:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0204a24:	00e56a63          	bltu	a0,a4,ffffffffc0204a38 <default_free_pages+0x90>
    return listelm->next;
ffffffffc0204a28:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0204a2a:	04d70f63          	beq	a4,a3,ffffffffc0204a88 <default_free_pages+0xe0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204a2e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0204a30:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0204a34:	fee57ae3          	bleu	a4,a0,ffffffffc0204a28 <default_free_pages+0x80>
ffffffffc0204a38:	00080663          	beqz	a6,ffffffffc0204a44 <default_free_pages+0x9c>
ffffffffc0204a3c:	000a8817          	auipc	a6,0xa8
ffffffffc0204a40:	acb83e23          	sd	a1,-1316(a6) # ffffffffc02ac518 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204a44:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc0204a46:	e390                	sd	a2,0(a5)
ffffffffc0204a48:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc0204a4a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204a4c:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc0204a4e:	06d58a63          	beq	a1,a3,ffffffffc0204ac2 <default_free_pages+0x11a>
        if (p + p->property == base) {
ffffffffc0204a52:	ff85a603          	lw	a2,-8(a1) # ff8 <_binary_obj___user_faultread_out_size-0x8578>
        p = le2page(le, page_link);
ffffffffc0204a56:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc0204a5a:	02061793          	slli	a5,a2,0x20
ffffffffc0204a5e:	83e9                	srli	a5,a5,0x1a
ffffffffc0204a60:	97ba                	add	a5,a5,a4
ffffffffc0204a62:	04f51b63          	bne	a0,a5,ffffffffc0204ab8 <default_free_pages+0x110>
            p->property += base->property;
ffffffffc0204a66:	491c                	lw	a5,16(a0)
ffffffffc0204a68:	9e3d                	addw	a2,a2,a5
ffffffffc0204a6a:	fec5ac23          	sw	a2,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204a6e:	57f5                	li	a5,-3
ffffffffc0204a70:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204a74:	01853803          	ld	a6,24(a0)
ffffffffc0204a78:	7110                	ld	a2,32(a0)
            base = p;
ffffffffc0204a7a:	853a                	mv	a0,a4
    prev->next = next;
ffffffffc0204a7c:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0204a80:	659c                	ld	a5,8(a1)
ffffffffc0204a82:	01063023          	sd	a6,0(a2)
ffffffffc0204a86:	a815                	j	ffffffffc0204aba <default_free_pages+0x112>
    prev->next = next->prev = elm;
ffffffffc0204a88:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204a8a:	f114                	sd	a3,32(a0)
ffffffffc0204a8c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0204a8e:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0204a90:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204a92:	00d70563          	beq	a4,a3,ffffffffc0204a9c <default_free_pages+0xf4>
ffffffffc0204a96:	4805                	li	a6,1
ffffffffc0204a98:	87ba                	mv	a5,a4
ffffffffc0204a9a:	bf59                	j	ffffffffc0204a30 <default_free_pages+0x88>
ffffffffc0204a9c:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0204a9e:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc0204aa0:	00d78d63          	beq	a5,a3,ffffffffc0204aba <default_free_pages+0x112>
        if (p + p->property == base) {
ffffffffc0204aa4:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc0204aa8:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc0204aac:	02061793          	slli	a5,a2,0x20
ffffffffc0204ab0:	83e9                	srli	a5,a5,0x1a
ffffffffc0204ab2:	97ba                	add	a5,a5,a4
ffffffffc0204ab4:	faf509e3          	beq	a0,a5,ffffffffc0204a66 <default_free_pages+0xbe>
ffffffffc0204ab8:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0204aba:	fe878713          	addi	a4,a5,-24
ffffffffc0204abe:	00d78963          	beq	a5,a3,ffffffffc0204ad0 <default_free_pages+0x128>
        if (base + base->property == p) {
ffffffffc0204ac2:	4910                	lw	a2,16(a0)
ffffffffc0204ac4:	02061693          	slli	a3,a2,0x20
ffffffffc0204ac8:	82e9                	srli	a3,a3,0x1a
ffffffffc0204aca:	96aa                	add	a3,a3,a0
ffffffffc0204acc:	00d70e63          	beq	a4,a3,ffffffffc0204ae8 <default_free_pages+0x140>
}
ffffffffc0204ad0:	60a2                	ld	ra,8(sp)
ffffffffc0204ad2:	0141                	addi	sp,sp,16
ffffffffc0204ad4:	8082                	ret
ffffffffc0204ad6:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0204ad8:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0204adc:	e398                	sd	a4,0(a5)
ffffffffc0204ade:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0204ae0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204ae2:	ed1c                	sd	a5,24(a0)
}
ffffffffc0204ae4:	0141                	addi	sp,sp,16
ffffffffc0204ae6:	8082                	ret
            base->property += p->property;
ffffffffc0204ae8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204aec:	ff078693          	addi	a3,a5,-16
ffffffffc0204af0:	9e39                	addw	a2,a2,a4
ffffffffc0204af2:	c910                	sw	a2,16(a0)
ffffffffc0204af4:	5775                	li	a4,-3
ffffffffc0204af6:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204afa:	6398                	ld	a4,0(a5)
ffffffffc0204afc:	679c                	ld	a5,8(a5)
}
ffffffffc0204afe:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0204b00:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0204b02:	e398                	sd	a4,0(a5)
ffffffffc0204b04:	0141                	addi	sp,sp,16
ffffffffc0204b06:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0204b08:	00004697          	auipc	a3,0x4
ffffffffc0204b0c:	a6868693          	addi	a3,a3,-1432 # ffffffffc0208570 <commands+0x1c08>
ffffffffc0204b10:	00002617          	auipc	a2,0x2
ffffffffc0204b14:	2f060613          	addi	a2,a2,752 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204b18:	08300593          	li	a1,131
ffffffffc0204b1c:	00003517          	auipc	a0,0x3
ffffffffc0204b20:	74450513          	addi	a0,a0,1860 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204b24:	ef2fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(n > 0);
ffffffffc0204b28:	00004697          	auipc	a3,0x4
ffffffffc0204b2c:	a7068693          	addi	a3,a3,-1424 # ffffffffc0208598 <commands+0x1c30>
ffffffffc0204b30:	00002617          	auipc	a2,0x2
ffffffffc0204b34:	2d060613          	addi	a2,a2,720 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204b38:	08000593          	li	a1,128
ffffffffc0204b3c:	00003517          	auipc	a0,0x3
ffffffffc0204b40:	72450513          	addi	a0,a0,1828 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204b44:	ed2fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204b48 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0204b48:	c959                	beqz	a0,ffffffffc0204bde <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0204b4a:	000a8597          	auipc	a1,0xa8
ffffffffc0204b4e:	9ce58593          	addi	a1,a1,-1586 # ffffffffc02ac518 <free_area>
ffffffffc0204b52:	0105a803          	lw	a6,16(a1)
ffffffffc0204b56:	862a                	mv	a2,a0
ffffffffc0204b58:	02081793          	slli	a5,a6,0x20
ffffffffc0204b5c:	9381                	srli	a5,a5,0x20
ffffffffc0204b5e:	00a7ee63          	bltu	a5,a0,ffffffffc0204b7a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0204b62:	87ae                	mv	a5,a1
ffffffffc0204b64:	a801                	j	ffffffffc0204b74 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0204b66:	ff87a703          	lw	a4,-8(a5)
ffffffffc0204b6a:	02071693          	slli	a3,a4,0x20
ffffffffc0204b6e:	9281                	srli	a3,a3,0x20
ffffffffc0204b70:	00c6f763          	bleu	a2,a3,ffffffffc0204b7e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0204b74:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0204b76:	feb798e3          	bne	a5,a1,ffffffffc0204b66 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0204b7a:	4501                	li	a0,0
}
ffffffffc0204b7c:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0204b7e:	fe878513          	addi	a0,a5,-24
    if (page != NULL) {
ffffffffc0204b82:	dd6d                	beqz	a0,ffffffffc0204b7c <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0204b84:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204b88:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0204b8c:	00060e1b          	sext.w	t3,a2
ffffffffc0204b90:	0068b423          	sd	t1,8(a7) # fffffffffff80008 <end+0x3fcd3ac8>
    next->prev = prev;
ffffffffc0204b94:	01133023          	sd	a7,0(t1) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff5590>
        if (page->property > n) {
ffffffffc0204b98:	02d67863          	bleu	a3,a2,ffffffffc0204bc8 <default_alloc_pages+0x80>
            struct Page *p = page + n;
ffffffffc0204b9c:	061a                	slli	a2,a2,0x6
ffffffffc0204b9e:	962a                	add	a2,a2,a0
            p->property = page->property - n;
ffffffffc0204ba0:	41c7073b          	subw	a4,a4,t3
ffffffffc0204ba4:	ca18                	sw	a4,16(a2)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204ba6:	00860693          	addi	a3,a2,8
ffffffffc0204baa:	4709                	li	a4,2
ffffffffc0204bac:	40e6b02f          	amoor.d	zero,a4,(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204bb0:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0204bb4:	01860693          	addi	a3,a2,24
    prev->next = next->prev = elm;
ffffffffc0204bb8:	0105a803          	lw	a6,16(a1)
ffffffffc0204bbc:	e314                	sd	a3,0(a4)
ffffffffc0204bbe:	00d8b423          	sd	a3,8(a7)
    elm->next = next;
ffffffffc0204bc2:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc0204bc4:	01163c23          	sd	a7,24(a2)
        nr_free -= n;
ffffffffc0204bc8:	41c8083b          	subw	a6,a6,t3
ffffffffc0204bcc:	000a8717          	auipc	a4,0xa8
ffffffffc0204bd0:	95072e23          	sw	a6,-1700(a4) # ffffffffc02ac528 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204bd4:	5775                	li	a4,-3
ffffffffc0204bd6:	17c1                	addi	a5,a5,-16
ffffffffc0204bd8:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0204bdc:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0204bde:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0204be0:	00004697          	auipc	a3,0x4
ffffffffc0204be4:	9b868693          	addi	a3,a3,-1608 # ffffffffc0208598 <commands+0x1c30>
ffffffffc0204be8:	00002617          	auipc	a2,0x2
ffffffffc0204bec:	21860613          	addi	a2,a2,536 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204bf0:	06200593          	li	a1,98
ffffffffc0204bf4:	00003517          	auipc	a0,0x3
ffffffffc0204bf8:	66c50513          	addi	a0,a0,1644 # ffffffffc0208260 <commands+0x18f8>
default_alloc_pages(size_t n) {
ffffffffc0204bfc:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0204bfe:	e18fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204c02 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0204c02:	1141                	addi	sp,sp,-16
ffffffffc0204c04:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0204c06:	c1ed                	beqz	a1,ffffffffc0204ce8 <default_init_memmap+0xe6>
    for (; p != base + n; p ++) {
ffffffffc0204c08:	00659693          	slli	a3,a1,0x6
ffffffffc0204c0c:	96aa                	add	a3,a3,a0
ffffffffc0204c0e:	02d50463          	beq	a0,a3,ffffffffc0204c36 <default_init_memmap+0x34>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0204c12:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc0204c14:	87aa                	mv	a5,a0
ffffffffc0204c16:	8b05                	andi	a4,a4,1
ffffffffc0204c18:	e709                	bnez	a4,ffffffffc0204c22 <default_init_memmap+0x20>
ffffffffc0204c1a:	a07d                	j	ffffffffc0204cc8 <default_init_memmap+0xc6>
ffffffffc0204c1c:	6798                	ld	a4,8(a5)
ffffffffc0204c1e:	8b05                	andi	a4,a4,1
ffffffffc0204c20:	c745                	beqz	a4,ffffffffc0204cc8 <default_init_memmap+0xc6>
        p->flags = p->property = 0;
ffffffffc0204c22:	0007a823          	sw	zero,16(a5)
ffffffffc0204c26:	0007b423          	sd	zero,8(a5)
ffffffffc0204c2a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0204c2e:	04078793          	addi	a5,a5,64
ffffffffc0204c32:	fed795e3          	bne	a5,a3,ffffffffc0204c1c <default_init_memmap+0x1a>
    base->property = n;
ffffffffc0204c36:	2581                	sext.w	a1,a1
ffffffffc0204c38:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204c3a:	4789                	li	a5,2
ffffffffc0204c3c:	00850713          	addi	a4,a0,8
ffffffffc0204c40:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0204c44:	000a8697          	auipc	a3,0xa8
ffffffffc0204c48:	8d468693          	addi	a3,a3,-1836 # ffffffffc02ac518 <free_area>
ffffffffc0204c4c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0204c4e:	669c                	ld	a5,8(a3)
ffffffffc0204c50:	9db9                	addw	a1,a1,a4
ffffffffc0204c52:	000a8717          	auipc	a4,0xa8
ffffffffc0204c56:	8cb72b23          	sw	a1,-1834(a4) # ffffffffc02ac528 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0204c5a:	04d78a63          	beq	a5,a3,ffffffffc0204cae <default_init_memmap+0xac>
            struct Page* page = le2page(le, page_link);
ffffffffc0204c5e:	fe878713          	addi	a4,a5,-24
ffffffffc0204c62:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0204c64:	4801                	li	a6,0
ffffffffc0204c66:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0204c6a:	00e56a63          	bltu	a0,a4,ffffffffc0204c7e <default_init_memmap+0x7c>
    return listelm->next;
ffffffffc0204c6e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0204c70:	02d70563          	beq	a4,a3,ffffffffc0204c9a <default_init_memmap+0x98>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204c74:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0204c76:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0204c7a:	fee57ae3          	bleu	a4,a0,ffffffffc0204c6e <default_init_memmap+0x6c>
ffffffffc0204c7e:	00080663          	beqz	a6,ffffffffc0204c8a <default_init_memmap+0x88>
ffffffffc0204c82:	000a8717          	auipc	a4,0xa8
ffffffffc0204c86:	88b73b23          	sd	a1,-1898(a4) # ffffffffc02ac518 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204c8a:	6398                	ld	a4,0(a5)
}
ffffffffc0204c8c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0204c8e:	e390                	sd	a2,0(a5)
ffffffffc0204c90:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0204c92:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204c94:	ed18                	sd	a4,24(a0)
ffffffffc0204c96:	0141                	addi	sp,sp,16
ffffffffc0204c98:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0204c9a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0204c9c:	f114                	sd	a3,32(a0)
ffffffffc0204c9e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0204ca0:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0204ca2:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0204ca4:	00d70e63          	beq	a4,a3,ffffffffc0204cc0 <default_init_memmap+0xbe>
ffffffffc0204ca8:	4805                	li	a6,1
ffffffffc0204caa:	87ba                	mv	a5,a4
ffffffffc0204cac:	b7e9                	j	ffffffffc0204c76 <default_init_memmap+0x74>
}
ffffffffc0204cae:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0204cb0:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0204cb4:	e398                	sd	a4,0(a5)
ffffffffc0204cb6:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0204cb8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0204cba:	ed1c                	sd	a5,24(a0)
}
ffffffffc0204cbc:	0141                	addi	sp,sp,16
ffffffffc0204cbe:	8082                	ret
ffffffffc0204cc0:	60a2                	ld	ra,8(sp)
ffffffffc0204cc2:	e290                	sd	a2,0(a3)
ffffffffc0204cc4:	0141                	addi	sp,sp,16
ffffffffc0204cc6:	8082                	ret
        assert(PageReserved(p));
ffffffffc0204cc8:	00004697          	auipc	a3,0x4
ffffffffc0204ccc:	8d868693          	addi	a3,a3,-1832 # ffffffffc02085a0 <commands+0x1c38>
ffffffffc0204cd0:	00002617          	auipc	a2,0x2
ffffffffc0204cd4:	13060613          	addi	a2,a2,304 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204cd8:	04900593          	li	a1,73
ffffffffc0204cdc:	00003517          	auipc	a0,0x3
ffffffffc0204ce0:	58450513          	addi	a0,a0,1412 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204ce4:	d32fb0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(n > 0);
ffffffffc0204ce8:	00004697          	auipc	a3,0x4
ffffffffc0204cec:	8b068693          	addi	a3,a3,-1872 # ffffffffc0208598 <commands+0x1c30>
ffffffffc0204cf0:	00002617          	auipc	a2,0x2
ffffffffc0204cf4:	11060613          	addi	a2,a2,272 # ffffffffc0206e00 <commands+0x498>
ffffffffc0204cf8:	04600593          	li	a1,70
ffffffffc0204cfc:	00003517          	auipc	a0,0x3
ffffffffc0204d00:	56450513          	addi	a0,a0,1380 # ffffffffc0208260 <commands+0x18f8>
ffffffffc0204d04:	d12fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204d08 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204d08:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204d0a:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204d0c:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204d0e:	827fb0ef          	jal	ra,ffffffffc0200534 <ide_device_valid>
ffffffffc0204d12:	cd01                	beqz	a0,ffffffffc0204d2a <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204d14:	4505                	li	a0,1
ffffffffc0204d16:	825fb0ef          	jal	ra,ffffffffc020053a <ide_device_size>
}
ffffffffc0204d1a:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204d1c:	810d                	srli	a0,a0,0x3
ffffffffc0204d1e:	000a7797          	auipc	a5,0xa7
ffffffffc0204d22:	7aa7bd23          	sd	a0,1978(a5) # ffffffffc02ac4d8 <max_swap_offset>
}
ffffffffc0204d26:	0141                	addi	sp,sp,16
ffffffffc0204d28:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204d2a:	00004617          	auipc	a2,0x4
ffffffffc0204d2e:	8d660613          	addi	a2,a2,-1834 # ffffffffc0208600 <default_pmm_manager+0x50>
ffffffffc0204d32:	45b5                	li	a1,13
ffffffffc0204d34:	00004517          	auipc	a0,0x4
ffffffffc0204d38:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0208620 <default_pmm_manager+0x70>
ffffffffc0204d3c:	cdafb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204d40 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204d40:	1141                	addi	sp,sp,-16
ffffffffc0204d42:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204d44:	00855793          	srli	a5,a0,0x8
ffffffffc0204d48:	cfb9                	beqz	a5,ffffffffc0204da6 <swapfs_read+0x66>
ffffffffc0204d4a:	000a7717          	auipc	a4,0xa7
ffffffffc0204d4e:	78e70713          	addi	a4,a4,1934 # ffffffffc02ac4d8 <max_swap_offset>
ffffffffc0204d52:	6318                	ld	a4,0(a4)
ffffffffc0204d54:	04e7f963          	bleu	a4,a5,ffffffffc0204da6 <swapfs_read+0x66>
    return page - pages + nbase;
ffffffffc0204d58:	000a7717          	auipc	a4,0xa7
ffffffffc0204d5c:	6d870713          	addi	a4,a4,1752 # ffffffffc02ac430 <pages>
ffffffffc0204d60:	6310                	ld	a2,0(a4)
ffffffffc0204d62:	00004717          	auipc	a4,0x4
ffffffffc0204d66:	21670713          	addi	a4,a4,534 # ffffffffc0208f78 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204d6a:	000a7697          	auipc	a3,0xa7
ffffffffc0204d6e:	65e68693          	addi	a3,a3,1630 # ffffffffc02ac3c8 <npage>
    return page - pages + nbase;
ffffffffc0204d72:	40c58633          	sub	a2,a1,a2
ffffffffc0204d76:	630c                	ld	a1,0(a4)
ffffffffc0204d78:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204d7a:	577d                	li	a4,-1
ffffffffc0204d7c:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204d7e:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204d80:	8331                	srli	a4,a4,0xc
ffffffffc0204d82:	8f71                	and	a4,a4,a2
ffffffffc0204d84:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d88:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204d8a:	02d77a63          	bleu	a3,a4,ffffffffc0204dbe <swapfs_read+0x7e>
ffffffffc0204d8e:	000a7797          	auipc	a5,0xa7
ffffffffc0204d92:	69278793          	addi	a5,a5,1682 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0204d96:	639c                	ld	a5,0(a5)
}
ffffffffc0204d98:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204d9a:	46a1                	li	a3,8
ffffffffc0204d9c:	963e                	add	a2,a2,a5
ffffffffc0204d9e:	4505                	li	a0,1
}
ffffffffc0204da0:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204da2:	f9efb06f          	j	ffffffffc0200540 <ide_read_secs>
ffffffffc0204da6:	86aa                	mv	a3,a0
ffffffffc0204da8:	00004617          	auipc	a2,0x4
ffffffffc0204dac:	89060613          	addi	a2,a2,-1904 # ffffffffc0208638 <default_pmm_manager+0x88>
ffffffffc0204db0:	45d1                	li	a1,20
ffffffffc0204db2:	00004517          	auipc	a0,0x4
ffffffffc0204db6:	86e50513          	addi	a0,a0,-1938 # ffffffffc0208620 <default_pmm_manager+0x70>
ffffffffc0204dba:	c5cfb0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0204dbe:	86b2                	mv	a3,a2
ffffffffc0204dc0:	06900593          	li	a1,105
ffffffffc0204dc4:	00002617          	auipc	a2,0x2
ffffffffc0204dc8:	47460613          	addi	a2,a2,1140 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0204dcc:	00002517          	auipc	a0,0x2
ffffffffc0204dd0:	4c450513          	addi	a0,a0,1220 # ffffffffc0207290 <commands+0x928>
ffffffffc0204dd4:	c42fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204dd8 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204dd8:	1141                	addi	sp,sp,-16
ffffffffc0204dda:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204ddc:	00855793          	srli	a5,a0,0x8
ffffffffc0204de0:	cfb9                	beqz	a5,ffffffffc0204e3e <swapfs_write+0x66>
ffffffffc0204de2:	000a7717          	auipc	a4,0xa7
ffffffffc0204de6:	6f670713          	addi	a4,a4,1782 # ffffffffc02ac4d8 <max_swap_offset>
ffffffffc0204dea:	6318                	ld	a4,0(a4)
ffffffffc0204dec:	04e7f963          	bleu	a4,a5,ffffffffc0204e3e <swapfs_write+0x66>
    return page - pages + nbase;
ffffffffc0204df0:	000a7717          	auipc	a4,0xa7
ffffffffc0204df4:	64070713          	addi	a4,a4,1600 # ffffffffc02ac430 <pages>
ffffffffc0204df8:	6310                	ld	a2,0(a4)
ffffffffc0204dfa:	00004717          	auipc	a4,0x4
ffffffffc0204dfe:	17e70713          	addi	a4,a4,382 # ffffffffc0208f78 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204e02:	000a7697          	auipc	a3,0xa7
ffffffffc0204e06:	5c668693          	addi	a3,a3,1478 # ffffffffc02ac3c8 <npage>
    return page - pages + nbase;
ffffffffc0204e0a:	40c58633          	sub	a2,a1,a2
ffffffffc0204e0e:	630c                	ld	a1,0(a4)
ffffffffc0204e10:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204e12:	577d                	li	a4,-1
ffffffffc0204e14:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204e16:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204e18:	8331                	srli	a4,a4,0xc
ffffffffc0204e1a:	8f71                	and	a4,a4,a2
ffffffffc0204e1c:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e20:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204e22:	02d77a63          	bleu	a3,a4,ffffffffc0204e56 <swapfs_write+0x7e>
ffffffffc0204e26:	000a7797          	auipc	a5,0xa7
ffffffffc0204e2a:	5fa78793          	addi	a5,a5,1530 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0204e2e:	639c                	ld	a5,0(a5)
}
ffffffffc0204e30:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204e32:	46a1                	li	a3,8
ffffffffc0204e34:	963e                	add	a2,a2,a5
ffffffffc0204e36:	4505                	li	a0,1
}
ffffffffc0204e38:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204e3a:	f2afb06f          	j	ffffffffc0200564 <ide_write_secs>
ffffffffc0204e3e:	86aa                	mv	a3,a0
ffffffffc0204e40:	00003617          	auipc	a2,0x3
ffffffffc0204e44:	7f860613          	addi	a2,a2,2040 # ffffffffc0208638 <default_pmm_manager+0x88>
ffffffffc0204e48:	45e5                	li	a1,25
ffffffffc0204e4a:	00003517          	auipc	a0,0x3
ffffffffc0204e4e:	7d650513          	addi	a0,a0,2006 # ffffffffc0208620 <default_pmm_manager+0x70>
ffffffffc0204e52:	bc4fb0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0204e56:	86b2                	mv	a3,a2
ffffffffc0204e58:	06900593          	li	a1,105
ffffffffc0204e5c:	00002617          	auipc	a2,0x2
ffffffffc0204e60:	3dc60613          	addi	a2,a2,988 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0204e64:	00002517          	auipc	a0,0x2
ffffffffc0204e68:	42c50513          	addi	a0,a0,1068 # ffffffffc0207290 <commands+0x928>
ffffffffc0204e6c:	baafb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204e70 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204e70:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204e72:	9402                	jalr	s0

	jal do_exit
ffffffffc0204e74:	79c000ef          	jal	ra,ffffffffc0205610 <do_exit>

ffffffffc0204e78 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204e78:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204e7c:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204e80:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204e82:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204e84:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204e88:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204e8c:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204e90:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204e94:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204e98:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204e9c:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204ea0:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204ea4:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204ea8:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204eac:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204eb0:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204eb4:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204eb6:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204eb8:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204ebc:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204ec0:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204ec4:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204ec8:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204ecc:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204ed0:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204ed4:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204ed8:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204edc:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204ee0:	8082                	ret

ffffffffc0204ee2 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204ee2:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204ee4:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204ee8:	e022                	sd	s0,0(sp)
ffffffffc0204eea:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204eec:	fc0fe0ef          	jal	ra,ffffffffc02036ac <kmalloc>
ffffffffc0204ef0:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204ef2:	cd29                	beqz	a0,ffffffffc0204f4c <alloc_proc+0x6a>
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
    
        proc->state = PROC_UNINIT;
ffffffffc0204ef4:	57fd                	li	a5,-1
ffffffffc0204ef6:	1782                	slli	a5,a5,0x20
ffffffffc0204ef8:	e11c                	sd	a5,0(a0)
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        proc->mm = NULL; // 进程所用的虚拟内存
        memset(&(proc->context), 0, sizeof(struct context)); // 进程的上下文
ffffffffc0204efa:	07000613          	li	a2,112
ffffffffc0204efe:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0204f00:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0204f04:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0204f08:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0204f0c:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0204f10:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 进程的上下文
ffffffffc0204f14:	03050513          	addi	a0,a0,48
ffffffffc0204f18:	4a4010ef          	jal	ra,ffffffffc02063bc <memset>
        proc->tf = NULL; // 中断帧指针
        proc->cr3 = boot_cr3; // 页目录表地址 设为 内核页目录表基址
ffffffffc0204f1c:	000a7797          	auipc	a5,0xa7
ffffffffc0204f20:	50c78793          	addi	a5,a5,1292 # ffffffffc02ac428 <boot_cr3>
ffffffffc0204f24:	639c                	ld	a5,0(a5)
        proc->tf = NULL; // 中断帧指针
ffffffffc0204f26:	0a043023          	sd	zero,160(s0)
        proc->flags = 0; // 标志位
ffffffffc0204f2a:	0a042823          	sw	zero,176(s0)
        proc->cr3 = boot_cr3; // 页目录表地址 设为 内核页目录表基址
ffffffffc0204f2e:	f45c                	sd	a5,168(s0)
        memset(&(proc->name), 0, PROC_NAME_LEN); // 进程名
ffffffffc0204f30:	463d                	li	a2,15
ffffffffc0204f32:	4581                	li	a1,0
ffffffffc0204f34:	0b440513          	addi	a0,s0,180
ffffffffc0204f38:	484010ef          	jal	ra,ffffffffc02063bc <memset>
        proc->wait_state = 0;  
ffffffffc0204f3c:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->optr = proc->yptr = NULL;
ffffffffc0204f40:	0e043c23          	sd	zero,248(s0)
ffffffffc0204f44:	10043023          	sd	zero,256(s0)
ffffffffc0204f48:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0204f4c:	8522                	mv	a0,s0
ffffffffc0204f4e:	60a2                	ld	ra,8(sp)
ffffffffc0204f50:	6402                	ld	s0,0(sp)
ffffffffc0204f52:	0141                	addi	sp,sp,16
ffffffffc0204f54:	8082                	ret

ffffffffc0204f56 <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204f56:	000a7797          	auipc	a5,0xa7
ffffffffc0204f5a:	49a78793          	addi	a5,a5,1178 # ffffffffc02ac3f0 <current>
ffffffffc0204f5e:	639c                	ld	a5,0(a5)
ffffffffc0204f60:	73c8                	ld	a0,160(a5)
ffffffffc0204f62:	e81fb06f          	j	ffffffffc0200de2 <forkrets>

ffffffffc0204f66 <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204f66:	000a7797          	auipc	a5,0xa7
ffffffffc0204f6a:	48a78793          	addi	a5,a5,1162 # ffffffffc02ac3f0 <current>
ffffffffc0204f6e:	639c                	ld	a5,0(a5)
user_main(void *arg) {
ffffffffc0204f70:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204f72:	00004617          	auipc	a2,0x4
ffffffffc0204f76:	ad660613          	addi	a2,a2,-1322 # ffffffffc0208a48 <default_pmm_manager+0x498>
ffffffffc0204f7a:	43cc                	lw	a1,4(a5)
ffffffffc0204f7c:	00004517          	auipc	a0,0x4
ffffffffc0204f80:	adc50513          	addi	a0,a0,-1316 # ffffffffc0208a58 <default_pmm_manager+0x4a8>
user_main(void *arg) {
ffffffffc0204f84:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204f86:	94afb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
ffffffffc0204f8a:	00004797          	auipc	a5,0x4
ffffffffc0204f8e:	abe78793          	addi	a5,a5,-1346 # ffffffffc0208a48 <default_pmm_manager+0x498>
ffffffffc0204f92:	3fe05717          	auipc	a4,0x3fe05
ffffffffc0204f96:	33e70713          	addi	a4,a4,830 # a2d0 <_binary_obj___user_forktest_out_size>
ffffffffc0204f9a:	e43a                	sd	a4,8(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204f9c:	853e                	mv	a0,a5
ffffffffc0204f9e:	00088717          	auipc	a4,0x88
ffffffffc0204fa2:	57a70713          	addi	a4,a4,1402 # ffffffffc028d518 <_binary_obj___user_forktest_out_start>
ffffffffc0204fa6:	f03a                	sd	a4,32(sp)
ffffffffc0204fa8:	f43e                	sd	a5,40(sp)
ffffffffc0204faa:	e802                	sd	zero,16(sp)
ffffffffc0204fac:	372010ef          	jal	ra,ffffffffc020631e <strlen>
ffffffffc0204fb0:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204fb2:	4511                	li	a0,4
ffffffffc0204fb4:	55a2                	lw	a1,40(sp)
ffffffffc0204fb6:	4662                	lw	a2,24(sp)
ffffffffc0204fb8:	5682                	lw	a3,32(sp)
ffffffffc0204fba:	4722                	lw	a4,8(sp)
ffffffffc0204fbc:	48a9                	li	a7,10
ffffffffc0204fbe:	9002                	ebreak
ffffffffc0204fc0:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204fc2:	65c2                	ld	a1,16(sp)
ffffffffc0204fc4:	00004517          	auipc	a0,0x4
ffffffffc0204fc8:	abc50513          	addi	a0,a0,-1348 # ffffffffc0208a80 <default_pmm_manager+0x4d0>
ffffffffc0204fcc:	904fb0ef          	jal	ra,ffffffffc02000d0 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204fd0:	00004617          	auipc	a2,0x4
ffffffffc0204fd4:	ac060613          	addi	a2,a2,-1344 # ffffffffc0208a90 <default_pmm_manager+0x4e0>
ffffffffc0204fd8:	35900593          	li	a1,857
ffffffffc0204fdc:	00004517          	auipc	a0,0x4
ffffffffc0204fe0:	ad450513          	addi	a0,a0,-1324 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0204fe4:	a32fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0204fe8 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204fe8:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204fea:	1141                	addi	sp,sp,-16
ffffffffc0204fec:	e406                	sd	ra,8(sp)
ffffffffc0204fee:	c02007b7          	lui	a5,0xc0200
ffffffffc0204ff2:	04f6e263          	bltu	a3,a5,ffffffffc0205036 <put_pgdir+0x4e>
ffffffffc0204ff6:	000a7797          	auipc	a5,0xa7
ffffffffc0204ffa:	42a78793          	addi	a5,a5,1066 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0204ffe:	6388                	ld	a0,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0205000:	000a7797          	auipc	a5,0xa7
ffffffffc0205004:	3c878793          	addi	a5,a5,968 # ffffffffc02ac3c8 <npage>
ffffffffc0205008:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc020500a:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc020500c:	82b1                	srli	a3,a3,0xc
ffffffffc020500e:	04f6f063          	bleu	a5,a3,ffffffffc020504e <put_pgdir+0x66>
    return &pages[PPN(pa) - nbase];
ffffffffc0205012:	00004797          	auipc	a5,0x4
ffffffffc0205016:	f6678793          	addi	a5,a5,-154 # ffffffffc0208f78 <nbase>
ffffffffc020501a:	639c                	ld	a5,0(a5)
ffffffffc020501c:	000a7717          	auipc	a4,0xa7
ffffffffc0205020:	41470713          	addi	a4,a4,1044 # ffffffffc02ac430 <pages>
ffffffffc0205024:	6308                	ld	a0,0(a4)
}
ffffffffc0205026:	60a2                	ld	ra,8(sp)
ffffffffc0205028:	8e9d                	sub	a3,a3,a5
ffffffffc020502a:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc020502c:	4585                	li	a1,1
ffffffffc020502e:	9536                	add	a0,a0,a3
}
ffffffffc0205030:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0205032:	f01fb06f          	j	ffffffffc0200f32 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0205036:	00002617          	auipc	a2,0x2
ffffffffc020503a:	2da60613          	addi	a2,a2,730 # ffffffffc0207310 <commands+0x9a8>
ffffffffc020503e:	06e00593          	li	a1,110
ffffffffc0205042:	00002517          	auipc	a0,0x2
ffffffffc0205046:	24e50513          	addi	a0,a0,590 # ffffffffc0207290 <commands+0x928>
ffffffffc020504a:	9ccfb0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020504e:	00002617          	auipc	a2,0x2
ffffffffc0205052:	22260613          	addi	a2,a2,546 # ffffffffc0207270 <commands+0x908>
ffffffffc0205056:	06200593          	li	a1,98
ffffffffc020505a:	00002517          	auipc	a0,0x2
ffffffffc020505e:	23650513          	addi	a0,a0,566 # ffffffffc0207290 <commands+0x928>
ffffffffc0205062:	9b4fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205066 <setup_pgdir>:
setup_pgdir(struct mm_struct *mm) {
ffffffffc0205066:	1101                	addi	sp,sp,-32
ffffffffc0205068:	e426                	sd	s1,8(sp)
ffffffffc020506a:	84aa                	mv	s1,a0
    if ((page = alloc_page()) == NULL) {
ffffffffc020506c:	4505                	li	a0,1
setup_pgdir(struct mm_struct *mm) {
ffffffffc020506e:	ec06                	sd	ra,24(sp)
ffffffffc0205070:	e822                	sd	s0,16(sp)
    if ((page = alloc_page()) == NULL) {
ffffffffc0205072:	e39fb0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
ffffffffc0205076:	c125                	beqz	a0,ffffffffc02050d6 <setup_pgdir+0x70>
    return page - pages + nbase;
ffffffffc0205078:	000a7797          	auipc	a5,0xa7
ffffffffc020507c:	3b878793          	addi	a5,a5,952 # ffffffffc02ac430 <pages>
ffffffffc0205080:	6394                	ld	a3,0(a5)
ffffffffc0205082:	00004797          	auipc	a5,0x4
ffffffffc0205086:	ef678793          	addi	a5,a5,-266 # ffffffffc0208f78 <nbase>
ffffffffc020508a:	6380                	ld	s0,0(a5)
ffffffffc020508c:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0205090:	000a7717          	auipc	a4,0xa7
ffffffffc0205094:	33870713          	addi	a4,a4,824 # ffffffffc02ac3c8 <npage>
    return page - pages + nbase;
ffffffffc0205098:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020509a:	57fd                	li	a5,-1
ffffffffc020509c:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc020509e:	96a2                	add	a3,a3,s0
    return KADDR(page2pa(page));
ffffffffc02050a0:	83b1                	srli	a5,a5,0xc
ffffffffc02050a2:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02050a4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02050a6:	02e7fa63          	bleu	a4,a5,ffffffffc02050da <setup_pgdir+0x74>
ffffffffc02050aa:	000a7797          	auipc	a5,0xa7
ffffffffc02050ae:	37678793          	addi	a5,a5,886 # ffffffffc02ac420 <va_pa_offset>
ffffffffc02050b2:	6380                	ld	s0,0(a5)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc02050b4:	000a7797          	auipc	a5,0xa7
ffffffffc02050b8:	30c78793          	addi	a5,a5,780 # ffffffffc02ac3c0 <boot_pgdir>
ffffffffc02050bc:	638c                	ld	a1,0(a5)
ffffffffc02050be:	9436                	add	s0,s0,a3
ffffffffc02050c0:	6605                	lui	a2,0x1
ffffffffc02050c2:	8522                	mv	a0,s0
ffffffffc02050c4:	30a010ef          	jal	ra,ffffffffc02063ce <memcpy>
    return 0;
ffffffffc02050c8:	4501                	li	a0,0
    mm->pgdir = pgdir;
ffffffffc02050ca:	ec80                	sd	s0,24(s1)
}
ffffffffc02050cc:	60e2                	ld	ra,24(sp)
ffffffffc02050ce:	6442                	ld	s0,16(sp)
ffffffffc02050d0:	64a2                	ld	s1,8(sp)
ffffffffc02050d2:	6105                	addi	sp,sp,32
ffffffffc02050d4:	8082                	ret
        return -E_NO_MEM;
ffffffffc02050d6:	5571                	li	a0,-4
ffffffffc02050d8:	bfd5                	j	ffffffffc02050cc <setup_pgdir+0x66>
ffffffffc02050da:	00002617          	auipc	a2,0x2
ffffffffc02050de:	15e60613          	addi	a2,a2,350 # ffffffffc0207238 <commands+0x8d0>
ffffffffc02050e2:	06900593          	li	a1,105
ffffffffc02050e6:	00002517          	auipc	a0,0x2
ffffffffc02050ea:	1aa50513          	addi	a0,a0,426 # ffffffffc0207290 <commands+0x928>
ffffffffc02050ee:	928fb0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02050f2 <set_proc_name>:
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc02050f2:	1101                	addi	sp,sp,-32
ffffffffc02050f4:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050f6:	0b450413          	addi	s0,a0,180
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc02050fa:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050fc:	4641                	li	a2,16
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc02050fe:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205100:	8522                	mv	a0,s0
ffffffffc0205102:	4581                	li	a1,0
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0205104:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205106:	2b6010ef          	jal	ra,ffffffffc02063bc <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020510a:	8522                	mv	a0,s0
}
ffffffffc020510c:	6442                	ld	s0,16(sp)
ffffffffc020510e:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205110:	85a6                	mv	a1,s1
}
ffffffffc0205112:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205114:	463d                	li	a2,15
}
ffffffffc0205116:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205118:	2b60106f          	j	ffffffffc02063ce <memcpy>

ffffffffc020511c <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc020511c:	1101                	addi	sp,sp,-32
    if (proc != current) {
ffffffffc020511e:	000a7797          	auipc	a5,0xa7
ffffffffc0205122:	2d278793          	addi	a5,a5,722 # ffffffffc02ac3f0 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0205126:	e426                	sd	s1,8(sp)
    if (proc != current) {
ffffffffc0205128:	6384                	ld	s1,0(a5)
proc_run(struct proc_struct *proc) {
ffffffffc020512a:	ec06                	sd	ra,24(sp)
ffffffffc020512c:	e822                	sd	s0,16(sp)
ffffffffc020512e:	e04a                	sd	s2,0(sp)
    if (proc != current) {
ffffffffc0205130:	02a48b63          	beq	s1,a0,ffffffffc0205166 <proc_run+0x4a>
ffffffffc0205134:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205136:	100027f3          	csrr	a5,sstatus
ffffffffc020513a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020513c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020513e:	e3a9                	bnez	a5,ffffffffc0205180 <proc_run+0x64>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0205140:	745c                	ld	a5,168(s0)
            current = proc; // 将当前进程换为 要切换到的进程
ffffffffc0205142:	000a7717          	auipc	a4,0xa7
ffffffffc0205146:	2a873723          	sd	s0,686(a4) # ffffffffc02ac3f0 <current>
ffffffffc020514a:	577d                	li	a4,-1
ffffffffc020514c:	177e                	slli	a4,a4,0x3f
ffffffffc020514e:	83b1                	srli	a5,a5,0xc
ffffffffc0205150:	8fd9                	or	a5,a5,a4
ffffffffc0205152:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context)); // 调用 switch_to 进行上下文的保存与切换
ffffffffc0205156:	03040593          	addi	a1,s0,48
ffffffffc020515a:	03048513          	addi	a0,s1,48
ffffffffc020515e:	d1bff0ef          	jal	ra,ffffffffc0204e78 <switch_to>
    if (flag) {
ffffffffc0205162:	00091863          	bnez	s2,ffffffffc0205172 <proc_run+0x56>
}
ffffffffc0205166:	60e2                	ld	ra,24(sp)
ffffffffc0205168:	6442                	ld	s0,16(sp)
ffffffffc020516a:	64a2                	ld	s1,8(sp)
ffffffffc020516c:	6902                	ld	s2,0(sp)
ffffffffc020516e:	6105                	addi	sp,sp,32
ffffffffc0205170:	8082                	ret
ffffffffc0205172:	6442                	ld	s0,16(sp)
ffffffffc0205174:	60e2                	ld	ra,24(sp)
ffffffffc0205176:	64a2                	ld	s1,8(sp)
ffffffffc0205178:	6902                	ld	s2,0(sp)
ffffffffc020517a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020517c:	cdafb06f          	j	ffffffffc0200656 <intr_enable>
        intr_disable();
ffffffffc0205180:	cdcfb0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc0205184:	4905                	li	s2,1
ffffffffc0205186:	bf6d                	j	ffffffffc0205140 <proc_run+0x24>

ffffffffc0205188 <find_proc>:
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205188:	0005071b          	sext.w	a4,a0
ffffffffc020518c:	6789                	lui	a5,0x2
ffffffffc020518e:	fff7069b          	addiw	a3,a4,-1
ffffffffc0205192:	17f9                	addi	a5,a5,-2
ffffffffc0205194:	04d7e063          	bltu	a5,a3,ffffffffc02051d4 <find_proc+0x4c>
find_proc(int pid) {
ffffffffc0205198:	1141                	addi	sp,sp,-16
ffffffffc020519a:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020519c:	45a9                	li	a1,10
ffffffffc020519e:	842a                	mv	s0,a0
ffffffffc02051a0:	853a                	mv	a0,a4
find_proc(int pid) {
ffffffffc02051a2:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02051a4:	63a010ef          	jal	ra,ffffffffc02067de <hash32>
ffffffffc02051a8:	02051693          	slli	a3,a0,0x20
ffffffffc02051ac:	82f1                	srli	a3,a3,0x1c
ffffffffc02051ae:	000a3517          	auipc	a0,0xa3
ffffffffc02051b2:	20250513          	addi	a0,a0,514 # ffffffffc02a83b0 <hash_list>
ffffffffc02051b6:	96aa                	add	a3,a3,a0
ffffffffc02051b8:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc02051ba:	a029                	j	ffffffffc02051c4 <find_proc+0x3c>
            if (proc->pid == pid) {
ffffffffc02051bc:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7644>
ffffffffc02051c0:	00870c63          	beq	a4,s0,ffffffffc02051d8 <find_proc+0x50>
    return listelm->next;
ffffffffc02051c4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc02051c6:	fef69be3          	bne	a3,a5,ffffffffc02051bc <find_proc+0x34>
}
ffffffffc02051ca:	60a2                	ld	ra,8(sp)
ffffffffc02051cc:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc02051ce:	4501                	li	a0,0
}
ffffffffc02051d0:	0141                	addi	sp,sp,16
ffffffffc02051d2:	8082                	ret
    return NULL;
ffffffffc02051d4:	4501                	li	a0,0
}
ffffffffc02051d6:	8082                	ret
ffffffffc02051d8:	60a2                	ld	ra,8(sp)
ffffffffc02051da:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02051dc:	f2878513          	addi	a0,a5,-216
}
ffffffffc02051e0:	0141                	addi	sp,sp,16
ffffffffc02051e2:	8082                	ret

ffffffffc02051e4 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc02051e4:	7159                	addi	sp,sp,-112
ffffffffc02051e6:	e0d2                	sd	s4,64(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc02051e8:	000a7a17          	auipc	s4,0xa7
ffffffffc02051ec:	220a0a13          	addi	s4,s4,544 # ffffffffc02ac408 <nr_process>
ffffffffc02051f0:	000a2703          	lw	a4,0(s4)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc02051f4:	f486                	sd	ra,104(sp)
ffffffffc02051f6:	f0a2                	sd	s0,96(sp)
ffffffffc02051f8:	eca6                	sd	s1,88(sp)
ffffffffc02051fa:	e8ca                	sd	s2,80(sp)
ffffffffc02051fc:	e4ce                	sd	s3,72(sp)
ffffffffc02051fe:	fc56                	sd	s5,56(sp)
ffffffffc0205200:	f85a                	sd	s6,48(sp)
ffffffffc0205202:	f45e                	sd	s7,40(sp)
ffffffffc0205204:	f062                	sd	s8,32(sp)
ffffffffc0205206:	ec66                	sd	s9,24(sp)
ffffffffc0205208:	e86a                	sd	s10,16(sp)
ffffffffc020520a:	e46e                	sd	s11,8(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc020520c:	6785                	lui	a5,0x1
ffffffffc020520e:	30f75a63          	ble	a5,a4,ffffffffc0205522 <do_fork+0x33e>
ffffffffc0205212:	89aa                	mv	s3,a0
ffffffffc0205214:	892e                	mv	s2,a1
ffffffffc0205216:	84b2                	mv	s1,a2
    if ((proc = alloc_proc()) == NULL)
ffffffffc0205218:	ccbff0ef          	jal	ra,ffffffffc0204ee2 <alloc_proc>
ffffffffc020521c:	842a                	mv	s0,a0
ffffffffc020521e:	2e050463          	beqz	a0,ffffffffc0205506 <do_fork+0x322>
    proc->parent = current; // 设置父进程
ffffffffc0205222:	000a7c17          	auipc	s8,0xa7
ffffffffc0205226:	1cec0c13          	addi	s8,s8,462 # ffffffffc02ac3f0 <current>
ffffffffc020522a:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);  
ffffffffc020522e:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8484>
    proc->parent = current; // 设置父进程
ffffffffc0205232:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);  
ffffffffc0205234:	30071563          	bnez	a4,ffffffffc020553e <do_fork+0x35a>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0205238:	4509                	li	a0,2
ffffffffc020523a:	c71fb0ef          	jal	ra,ffffffffc0200eaa <alloc_pages>
    if (page != NULL) {
ffffffffc020523e:	2c050163          	beqz	a0,ffffffffc0205500 <do_fork+0x31c>
    return page - pages + nbase;
ffffffffc0205242:	000a7a97          	auipc	s5,0xa7
ffffffffc0205246:	1eea8a93          	addi	s5,s5,494 # ffffffffc02ac430 <pages>
ffffffffc020524a:	000ab683          	ld	a3,0(s5)
ffffffffc020524e:	00004b17          	auipc	s6,0x4
ffffffffc0205252:	d2ab0b13          	addi	s6,s6,-726 # ffffffffc0208f78 <nbase>
ffffffffc0205256:	000b3783          	ld	a5,0(s6)
ffffffffc020525a:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc020525e:	000a7b97          	auipc	s7,0xa7
ffffffffc0205262:	16ab8b93          	addi	s7,s7,362 # ffffffffc02ac3c8 <npage>
    return page - pages + nbase;
ffffffffc0205266:	8699                	srai	a3,a3,0x6
ffffffffc0205268:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020526a:	000bb703          	ld	a4,0(s7)
ffffffffc020526e:	57fd                	li	a5,-1
ffffffffc0205270:	83b1                	srli	a5,a5,0xc
ffffffffc0205272:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0205274:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205276:	2ae7f863          	bleu	a4,a5,ffffffffc0205526 <do_fork+0x342>
ffffffffc020527a:	000a7c97          	auipc	s9,0xa7
ffffffffc020527e:	1a6c8c93          	addi	s9,s9,422 # ffffffffc02ac420 <va_pa_offset>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0205282:	000c3703          	ld	a4,0(s8)
ffffffffc0205286:	000cb783          	ld	a5,0(s9)
ffffffffc020528a:	02873c03          	ld	s8,40(a4)
ffffffffc020528e:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0205290:	e814                	sd	a3,16(s0)
    if (oldmm == NULL) {
ffffffffc0205292:	020c0863          	beqz	s8,ffffffffc02052c2 <do_fork+0xde>
    if (clone_flags & CLONE_VM) {
ffffffffc0205296:	1009f993          	andi	s3,s3,256
ffffffffc020529a:	1e098163          	beqz	s3,ffffffffc020547c <do_fork+0x298>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc020529e:	030c2703          	lw	a4,48(s8)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02052a2:	018c3783          	ld	a5,24(s8)
ffffffffc02052a6:	c02006b7          	lui	a3,0xc0200
ffffffffc02052aa:	2705                	addiw	a4,a4,1
ffffffffc02052ac:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc02052b0:	03843423          	sd	s8,40(s0)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc02052b4:	2ad7e563          	bltu	a5,a3,ffffffffc020555e <do_fork+0x37a>
ffffffffc02052b8:	000cb703          	ld	a4,0(s9)
ffffffffc02052bc:	6814                	ld	a3,16(s0)
ffffffffc02052be:	8f99                	sub	a5,a5,a4
ffffffffc02052c0:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02052c2:	6789                	lui	a5,0x2
ffffffffc02052c4:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7690>
ffffffffc02052c8:	96be                	add	a3,a3,a5
ffffffffc02052ca:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc02052cc:	87b6                	mv	a5,a3
ffffffffc02052ce:	12048813          	addi	a6,s1,288
ffffffffc02052d2:	6088                	ld	a0,0(s1)
ffffffffc02052d4:	648c                	ld	a1,8(s1)
ffffffffc02052d6:	6890                	ld	a2,16(s1)
ffffffffc02052d8:	6c98                	ld	a4,24(s1)
ffffffffc02052da:	e388                	sd	a0,0(a5)
ffffffffc02052dc:	e78c                	sd	a1,8(a5)
ffffffffc02052de:	eb90                	sd	a2,16(a5)
ffffffffc02052e0:	ef98                	sd	a4,24(a5)
ffffffffc02052e2:	02048493          	addi	s1,s1,32
ffffffffc02052e6:	02078793          	addi	a5,a5,32
ffffffffc02052ea:	ff0494e3          	bne	s1,a6,ffffffffc02052d2 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc02052ee:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x1a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02052f2:	12090e63          	beqz	s2,ffffffffc020542e <do_fork+0x24a>
ffffffffc02052f6:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02052fa:	00000797          	auipc	a5,0x0
ffffffffc02052fe:	c5c78793          	addi	a5,a5,-932 # ffffffffc0204f56 <forkret>
ffffffffc0205302:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205304:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205306:	100027f3          	csrr	a5,sstatus
ffffffffc020530a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020530c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020530e:	12079f63          	bnez	a5,ffffffffc020544c <do_fork+0x268>
    if (++ last_pid >= MAX_PID) {
ffffffffc0205312:	0009c797          	auipc	a5,0x9c
ffffffffc0205316:	c9678793          	addi	a5,a5,-874 # ffffffffc02a0fa8 <last_pid.1691>
ffffffffc020531a:	439c                	lw	a5,0(a5)
ffffffffc020531c:	6709                	lui	a4,0x2
ffffffffc020531e:	0017851b          	addiw	a0,a5,1
ffffffffc0205322:	0009c697          	auipc	a3,0x9c
ffffffffc0205326:	c8a6a323          	sw	a0,-890(a3) # ffffffffc02a0fa8 <last_pid.1691>
ffffffffc020532a:	14e55263          	ble	a4,a0,ffffffffc020546e <do_fork+0x28a>
    if (last_pid >= next_safe) {
ffffffffc020532e:	0009c797          	auipc	a5,0x9c
ffffffffc0205332:	c7e78793          	addi	a5,a5,-898 # ffffffffc02a0fac <next_safe.1690>
ffffffffc0205336:	439c                	lw	a5,0(a5)
ffffffffc0205338:	000a7497          	auipc	s1,0xa7
ffffffffc020533c:	1f848493          	addi	s1,s1,504 # ffffffffc02ac530 <proc_list>
ffffffffc0205340:	06f54063          	blt	a0,a5,ffffffffc02053a0 <do_fork+0x1bc>
        next_safe = MAX_PID;
ffffffffc0205344:	6789                	lui	a5,0x2
ffffffffc0205346:	0009c717          	auipc	a4,0x9c
ffffffffc020534a:	c6f72323          	sw	a5,-922(a4) # ffffffffc02a0fac <next_safe.1690>
ffffffffc020534e:	4581                	li	a1,0
ffffffffc0205350:	87aa                	mv	a5,a0
ffffffffc0205352:	000a7497          	auipc	s1,0xa7
ffffffffc0205356:	1de48493          	addi	s1,s1,478 # ffffffffc02ac530 <proc_list>
    repeat:
ffffffffc020535a:	6889                	lui	a7,0x2
ffffffffc020535c:	882e                	mv	a6,a1
ffffffffc020535e:	6609                	lui	a2,0x2
        le = list;
ffffffffc0205360:	000a7697          	auipc	a3,0xa7
ffffffffc0205364:	1d068693          	addi	a3,a3,464 # ffffffffc02ac530 <proc_list>
ffffffffc0205368:	6694                	ld	a3,8(a3)
        while ((le = list_next(le)) != list) {
ffffffffc020536a:	00968f63          	beq	a3,s1,ffffffffc0205388 <do_fork+0x1a4>
            if (proc->pid == last_pid) {
ffffffffc020536e:	f3c6a703          	lw	a4,-196(a3)
ffffffffc0205372:	0ae78963          	beq	a5,a4,ffffffffc0205424 <do_fork+0x240>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc0205376:	fee7d9e3          	ble	a4,a5,ffffffffc0205368 <do_fork+0x184>
ffffffffc020537a:	fec757e3          	ble	a2,a4,ffffffffc0205368 <do_fork+0x184>
ffffffffc020537e:	6694                	ld	a3,8(a3)
ffffffffc0205380:	863a                	mv	a2,a4
ffffffffc0205382:	4805                	li	a6,1
        while ((le = list_next(le)) != list) {
ffffffffc0205384:	fe9695e3          	bne	a3,s1,ffffffffc020536e <do_fork+0x18a>
ffffffffc0205388:	c591                	beqz	a1,ffffffffc0205394 <do_fork+0x1b0>
ffffffffc020538a:	0009c717          	auipc	a4,0x9c
ffffffffc020538e:	c0f72f23          	sw	a5,-994(a4) # ffffffffc02a0fa8 <last_pid.1691>
ffffffffc0205392:	853e                	mv	a0,a5
ffffffffc0205394:	00080663          	beqz	a6,ffffffffc02053a0 <do_fork+0x1bc>
ffffffffc0205398:	0009c797          	auipc	a5,0x9c
ffffffffc020539c:	c0c7aa23          	sw	a2,-1004(a5) # ffffffffc02a0fac <next_safe.1690>
        proc->pid = get_pid(); // 这一句话要在前面！！！ 
ffffffffc02053a0:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02053a2:	45a9                	li	a1,10
ffffffffc02053a4:	2501                	sext.w	a0,a0
ffffffffc02053a6:	438010ef          	jal	ra,ffffffffc02067de <hash32>
ffffffffc02053aa:	1502                	slli	a0,a0,0x20
ffffffffc02053ac:	000a3797          	auipc	a5,0xa3
ffffffffc02053b0:	00478793          	addi	a5,a5,4 # ffffffffc02a83b0 <hash_list>
ffffffffc02053b4:	8171                	srli	a0,a0,0x1c
ffffffffc02053b6:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02053b8:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02053ba:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02053bc:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc02053c0:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02053c2:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc02053c4:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02053c6:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02053c8:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc02053cc:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc02053ce:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02053d0:	e21c                	sd	a5,0(a2)
ffffffffc02053d2:	000a7597          	auipc	a1,0xa7
ffffffffc02053d6:	16f5b323          	sd	a5,358(a1) # ffffffffc02ac538 <proc_list+0x8>
    elm->next = next;
ffffffffc02053da:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02053dc:	e464                	sd	s1,200(s0)
    proc->yptr = NULL;
ffffffffc02053de:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02053e2:	10e43023          	sd	a4,256(s0)
ffffffffc02053e6:	c311                	beqz	a4,ffffffffc02053ea <do_fork+0x206>
        proc->optr->yptr = proc;
ffffffffc02053e8:	ff60                	sd	s0,248(a4)
    nr_process ++;
ffffffffc02053ea:	000a2783          	lw	a5,0(s4)
    proc->parent->cptr = proc;
ffffffffc02053ee:	fae0                	sd	s0,240(a3)
    nr_process ++;
ffffffffc02053f0:	2785                	addiw	a5,a5,1
ffffffffc02053f2:	000a7717          	auipc	a4,0xa7
ffffffffc02053f6:	00f72b23          	sw	a5,22(a4) # ffffffffc02ac408 <nr_process>
    if (flag) {
ffffffffc02053fa:	10091863          	bnez	s2,ffffffffc020550a <do_fork+0x326>
    wakeup_proc(proc);
ffffffffc02053fe:	8522                	mv	a0,s0
ffffffffc0205400:	52d000ef          	jal	ra,ffffffffc020612c <wakeup_proc>
    ret = proc->pid;
ffffffffc0205404:	4048                	lw	a0,4(s0)
}
ffffffffc0205406:	70a6                	ld	ra,104(sp)
ffffffffc0205408:	7406                	ld	s0,96(sp)
ffffffffc020540a:	64e6                	ld	s1,88(sp)
ffffffffc020540c:	6946                	ld	s2,80(sp)
ffffffffc020540e:	69a6                	ld	s3,72(sp)
ffffffffc0205410:	6a06                	ld	s4,64(sp)
ffffffffc0205412:	7ae2                	ld	s5,56(sp)
ffffffffc0205414:	7b42                	ld	s6,48(sp)
ffffffffc0205416:	7ba2                	ld	s7,40(sp)
ffffffffc0205418:	7c02                	ld	s8,32(sp)
ffffffffc020541a:	6ce2                	ld	s9,24(sp)
ffffffffc020541c:	6d42                	ld	s10,16(sp)
ffffffffc020541e:	6da2                	ld	s11,8(sp)
ffffffffc0205420:	6165                	addi	sp,sp,112
ffffffffc0205422:	8082                	ret
                if (++ last_pid >= next_safe) {
ffffffffc0205424:	2785                	addiw	a5,a5,1
ffffffffc0205426:	0ec7d563          	ble	a2,a5,ffffffffc0205510 <do_fork+0x32c>
ffffffffc020542a:	4585                	li	a1,1
ffffffffc020542c:	bf35                	j	ffffffffc0205368 <do_fork+0x184>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020542e:	8936                	mv	s2,a3
ffffffffc0205430:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0205434:	00000797          	auipc	a5,0x0
ffffffffc0205438:	b2278793          	addi	a5,a5,-1246 # ffffffffc0204f56 <forkret>
ffffffffc020543c:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020543e:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205440:	100027f3          	csrr	a5,sstatus
ffffffffc0205444:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205446:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205448:	ec0785e3          	beqz	a5,ffffffffc0205312 <do_fork+0x12e>
        intr_disable();
ffffffffc020544c:	a10fb0ef          	jal	ra,ffffffffc020065c <intr_disable>
    if (++ last_pid >= MAX_PID) {
ffffffffc0205450:	0009c797          	auipc	a5,0x9c
ffffffffc0205454:	b5878793          	addi	a5,a5,-1192 # ffffffffc02a0fa8 <last_pid.1691>
ffffffffc0205458:	439c                	lw	a5,0(a5)
ffffffffc020545a:	6709                	lui	a4,0x2
        return 1;
ffffffffc020545c:	4905                	li	s2,1
ffffffffc020545e:	0017851b          	addiw	a0,a5,1
ffffffffc0205462:	0009c697          	auipc	a3,0x9c
ffffffffc0205466:	b4a6a323          	sw	a0,-1210(a3) # ffffffffc02a0fa8 <last_pid.1691>
ffffffffc020546a:	ece542e3          	blt	a0,a4,ffffffffc020532e <do_fork+0x14a>
        last_pid = 1;
ffffffffc020546e:	4785                	li	a5,1
ffffffffc0205470:	0009c717          	auipc	a4,0x9c
ffffffffc0205474:	b2f72c23          	sw	a5,-1224(a4) # ffffffffc02a0fa8 <last_pid.1691>
ffffffffc0205478:	4505                	li	a0,1
ffffffffc020547a:	b5e9                	j	ffffffffc0205344 <do_fork+0x160>
    if ((mm = mm_create()) == NULL) {
ffffffffc020547c:	bfefd0ef          	jal	ra,ffffffffc020287a <mm_create>
ffffffffc0205480:	8d2a                	mv	s10,a0
ffffffffc0205482:	c539                	beqz	a0,ffffffffc02054d0 <do_fork+0x2ec>
    if (setup_pgdir(mm) != 0) {
ffffffffc0205484:	be3ff0ef          	jal	ra,ffffffffc0205066 <setup_pgdir>
ffffffffc0205488:	e949                	bnez	a0,ffffffffc020551a <do_fork+0x336>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc020548a:	038c0d93          	addi	s11,s8,56
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020548e:	4785                	li	a5,1
ffffffffc0205490:	40fdb7af          	amoor.d	a5,a5,(s11)
ffffffffc0205494:	8b85                	andi	a5,a5,1
ffffffffc0205496:	4985                	li	s3,1
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc0205498:	c799                	beqz	a5,ffffffffc02054a6 <do_fork+0x2c2>
        schedule();
ffffffffc020549a:	50f000ef          	jal	ra,ffffffffc02061a8 <schedule>
ffffffffc020549e:	413db7af          	amoor.d	a5,s3,(s11)
ffffffffc02054a2:	8b85                	andi	a5,a5,1
    while (!try_lock(lock)) {
ffffffffc02054a4:	fbfd                	bnez	a5,ffffffffc020549a <do_fork+0x2b6>
        ret = dup_mmap(mm, oldmm);
ffffffffc02054a6:	85e2                	mv	a1,s8
ffffffffc02054a8:	856a                	mv	a0,s10
ffffffffc02054aa:	e5afd0ef          	jal	ra,ffffffffc0202b04 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02054ae:	57f9                	li	a5,-2
ffffffffc02054b0:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc02054b4:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc02054b6:	c3e9                	beqz	a5,ffffffffc0205578 <do_fork+0x394>
    if (ret != 0) {
ffffffffc02054b8:	8c6a                	mv	s8,s10
ffffffffc02054ba:	de0502e3          	beqz	a0,ffffffffc020529e <do_fork+0xba>
    exit_mmap(mm);
ffffffffc02054be:	856a                	mv	a0,s10
ffffffffc02054c0:	ee0fd0ef          	jal	ra,ffffffffc0202ba0 <exit_mmap>
    put_pgdir(mm);
ffffffffc02054c4:	856a                	mv	a0,s10
ffffffffc02054c6:	b23ff0ef          	jal	ra,ffffffffc0204fe8 <put_pgdir>
    mm_destroy(mm);
ffffffffc02054ca:	856a                	mv	a0,s10
ffffffffc02054cc:	d34fd0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02054d0:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02054d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02054d6:	0cf6e963          	bltu	a3,a5,ffffffffc02055a8 <do_fork+0x3c4>
ffffffffc02054da:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage) {
ffffffffc02054de:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02054e2:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02054e6:	83b1                	srli	a5,a5,0xc
ffffffffc02054e8:	0ae7f463          	bleu	a4,a5,ffffffffc0205590 <do_fork+0x3ac>
    return &pages[PPN(pa) - nbase];
ffffffffc02054ec:	000b3703          	ld	a4,0(s6)
ffffffffc02054f0:	000ab503          	ld	a0,0(s5)
ffffffffc02054f4:	4589                	li	a1,2
ffffffffc02054f6:	8f99                	sub	a5,a5,a4
ffffffffc02054f8:	079a                	slli	a5,a5,0x6
ffffffffc02054fa:	953e                	add	a0,a0,a5
ffffffffc02054fc:	a37fb0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    kfree(proc);
ffffffffc0205500:	8522                	mv	a0,s0
ffffffffc0205502:	a66fe0ef          	jal	ra,ffffffffc0203768 <kfree>
    ret = -E_NO_MEM;
ffffffffc0205506:	5571                	li	a0,-4
    return ret;
ffffffffc0205508:	bdfd                	j	ffffffffc0205406 <do_fork+0x222>
        intr_enable();
ffffffffc020550a:	94cfb0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc020550e:	bdc5                	j	ffffffffc02053fe <do_fork+0x21a>
                    if (last_pid >= MAX_PID) {
ffffffffc0205510:	0117c363          	blt	a5,a7,ffffffffc0205516 <do_fork+0x332>
                        last_pid = 1;
ffffffffc0205514:	4785                	li	a5,1
                    goto repeat;
ffffffffc0205516:	4585                	li	a1,1
ffffffffc0205518:	b591                	j	ffffffffc020535c <do_fork+0x178>
    mm_destroy(mm);
ffffffffc020551a:	856a                	mv	a0,s10
ffffffffc020551c:	ce4fd0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
ffffffffc0205520:	bf45                	j	ffffffffc02054d0 <do_fork+0x2ec>
    int ret = -E_NO_FREE_PROC;
ffffffffc0205522:	556d                	li	a0,-5
ffffffffc0205524:	b5cd                	j	ffffffffc0205406 <do_fork+0x222>
    return KADDR(page2pa(page));
ffffffffc0205526:	00002617          	auipc	a2,0x2
ffffffffc020552a:	d1260613          	addi	a2,a2,-750 # ffffffffc0207238 <commands+0x8d0>
ffffffffc020552e:	06900593          	li	a1,105
ffffffffc0205532:	00002517          	auipc	a0,0x2
ffffffffc0205536:	d5e50513          	addi	a0,a0,-674 # ffffffffc0207290 <commands+0x928>
ffffffffc020553a:	cddfa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(current->wait_state == 0);  
ffffffffc020553e:	00003697          	auipc	a3,0x3
ffffffffc0205542:	2e268693          	addi	a3,a3,738 # ffffffffc0208820 <default_pmm_manager+0x270>
ffffffffc0205546:	00002617          	auipc	a2,0x2
ffffffffc020554a:	8ba60613          	addi	a2,a2,-1862 # ffffffffc0206e00 <commands+0x498>
ffffffffc020554e:	1b500593          	li	a1,437
ffffffffc0205552:	00003517          	auipc	a0,0x3
ffffffffc0205556:	55e50513          	addi	a0,a0,1374 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc020555a:	cbdfa0ef          	jal	ra,ffffffffc0200216 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020555e:	86be                	mv	a3,a5
ffffffffc0205560:	00002617          	auipc	a2,0x2
ffffffffc0205564:	db060613          	addi	a2,a2,-592 # ffffffffc0207310 <commands+0x9a8>
ffffffffc0205568:	16700593          	li	a1,359
ffffffffc020556c:	00003517          	auipc	a0,0x3
ffffffffc0205570:	54450513          	addi	a0,a0,1348 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205574:	ca3fa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("Unlock failed.\n");
ffffffffc0205578:	00003617          	auipc	a2,0x3
ffffffffc020557c:	2c860613          	addi	a2,a2,712 # ffffffffc0208840 <default_pmm_manager+0x290>
ffffffffc0205580:	03100593          	li	a1,49
ffffffffc0205584:	00003517          	auipc	a0,0x3
ffffffffc0205588:	2cc50513          	addi	a0,a0,716 # ffffffffc0208850 <default_pmm_manager+0x2a0>
ffffffffc020558c:	c8bfa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0205590:	00002617          	auipc	a2,0x2
ffffffffc0205594:	ce060613          	addi	a2,a2,-800 # ffffffffc0207270 <commands+0x908>
ffffffffc0205598:	06200593          	li	a1,98
ffffffffc020559c:	00002517          	auipc	a0,0x2
ffffffffc02055a0:	cf450513          	addi	a0,a0,-780 # ffffffffc0207290 <commands+0x928>
ffffffffc02055a4:	c73fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02055a8:	00002617          	auipc	a2,0x2
ffffffffc02055ac:	d6860613          	addi	a2,a2,-664 # ffffffffc0207310 <commands+0x9a8>
ffffffffc02055b0:	06e00593          	li	a1,110
ffffffffc02055b4:	00002517          	auipc	a0,0x2
ffffffffc02055b8:	cdc50513          	addi	a0,a0,-804 # ffffffffc0207290 <commands+0x928>
ffffffffc02055bc:	c5bfa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02055c0 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02055c0:	7129                	addi	sp,sp,-320
ffffffffc02055c2:	fa22                	sd	s0,304(sp)
ffffffffc02055c4:	f626                	sd	s1,296(sp)
ffffffffc02055c6:	f24a                	sd	s2,288(sp)
ffffffffc02055c8:	84ae                	mv	s1,a1
ffffffffc02055ca:	892a                	mv	s2,a0
ffffffffc02055cc:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02055ce:	4581                	li	a1,0
ffffffffc02055d0:	12000613          	li	a2,288
ffffffffc02055d4:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02055d6:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02055d8:	5e5000ef          	jal	ra,ffffffffc02063bc <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02055dc:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02055de:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02055e0:	100027f3          	csrr	a5,sstatus
ffffffffc02055e4:	edd7f793          	andi	a5,a5,-291
ffffffffc02055e8:	1207e793          	ori	a5,a5,288
ffffffffc02055ec:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02055ee:	860a                	mv	a2,sp
ffffffffc02055f0:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02055f4:	00000797          	auipc	a5,0x0
ffffffffc02055f8:	87c78793          	addi	a5,a5,-1924 # ffffffffc0204e70 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02055fc:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02055fe:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205600:	be5ff0ef          	jal	ra,ffffffffc02051e4 <do_fork>
}
ffffffffc0205604:	70f2                	ld	ra,312(sp)
ffffffffc0205606:	7452                	ld	s0,304(sp)
ffffffffc0205608:	74b2                	ld	s1,296(sp)
ffffffffc020560a:	7912                	ld	s2,288(sp)
ffffffffc020560c:	6131                	addi	sp,sp,320
ffffffffc020560e:	8082                	ret

ffffffffc0205610 <do_exit>:
do_exit(int error_code) {
ffffffffc0205610:	7179                	addi	sp,sp,-48
ffffffffc0205612:	e84a                	sd	s2,16(sp)
    if (current == idleproc) {
ffffffffc0205614:	000a7717          	auipc	a4,0xa7
ffffffffc0205618:	de470713          	addi	a4,a4,-540 # ffffffffc02ac3f8 <idleproc>
ffffffffc020561c:	000a7917          	auipc	s2,0xa7
ffffffffc0205620:	dd490913          	addi	s2,s2,-556 # ffffffffc02ac3f0 <current>
ffffffffc0205624:	00093783          	ld	a5,0(s2)
ffffffffc0205628:	6318                	ld	a4,0(a4)
do_exit(int error_code) {
ffffffffc020562a:	f406                	sd	ra,40(sp)
ffffffffc020562c:	f022                	sd	s0,32(sp)
ffffffffc020562e:	ec26                	sd	s1,24(sp)
ffffffffc0205630:	e44e                	sd	s3,8(sp)
ffffffffc0205632:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc0205634:	0ce78c63          	beq	a5,a4,ffffffffc020570c <do_exit+0xfc>
    if (current == initproc) {
ffffffffc0205638:	000a7417          	auipc	s0,0xa7
ffffffffc020563c:	dc840413          	addi	s0,s0,-568 # ffffffffc02ac400 <initproc>
ffffffffc0205640:	6018                	ld	a4,0(s0)
ffffffffc0205642:	0ee78b63          	beq	a5,a4,ffffffffc0205738 <do_exit+0x128>
    struct mm_struct *mm = current->mm;
ffffffffc0205646:	7784                	ld	s1,40(a5)
ffffffffc0205648:	89aa                	mv	s3,a0
    if (mm != NULL) {
ffffffffc020564a:	c48d                	beqz	s1,ffffffffc0205674 <do_exit+0x64>
        lcr3(boot_cr3);
ffffffffc020564c:	000a7797          	auipc	a5,0xa7
ffffffffc0205650:	ddc78793          	addi	a5,a5,-548 # ffffffffc02ac428 <boot_cr3>
ffffffffc0205654:	639c                	ld	a5,0(a5)
ffffffffc0205656:	577d                	li	a4,-1
ffffffffc0205658:	177e                	slli	a4,a4,0x3f
ffffffffc020565a:	83b1                	srli	a5,a5,0xc
ffffffffc020565c:	8fd9                	or	a5,a5,a4
ffffffffc020565e:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0205662:	589c                	lw	a5,48(s1)
ffffffffc0205664:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205668:	d898                	sw	a4,48(s1)
        if (mm_count_dec(mm) == 0) {
ffffffffc020566a:	cf4d                	beqz	a4,ffffffffc0205724 <do_exit+0x114>
        current->mm = NULL;
ffffffffc020566c:	00093783          	ld	a5,0(s2)
ffffffffc0205670:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0205674:	00093783          	ld	a5,0(s2)
ffffffffc0205678:	470d                	li	a4,3
ffffffffc020567a:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc020567c:	0f37a423          	sw	s3,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205680:	100027f3          	csrr	a5,sstatus
ffffffffc0205684:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205686:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205688:	e7e1                	bnez	a5,ffffffffc0205750 <do_exit+0x140>
        proc = current->parent;
ffffffffc020568a:	00093703          	ld	a4,0(s2)
        if (proc->wait_state == WT_CHILD) {
ffffffffc020568e:	800007b7          	lui	a5,0x80000
ffffffffc0205692:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0205694:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205696:	0ec52703          	lw	a4,236(a0)
ffffffffc020569a:	0af70f63          	beq	a4,a5,ffffffffc0205758 <do_exit+0x148>
ffffffffc020569e:	00093683          	ld	a3,0(s2)
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02056a2:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02056a6:	448d                	li	s1,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02056a8:	0985                	addi	s3,s3,1
        while (current->cptr != NULL) {
ffffffffc02056aa:	7afc                	ld	a5,240(a3)
ffffffffc02056ac:	cb95                	beqz	a5,ffffffffc02056e0 <do_exit+0xd0>
            current->cptr = proc->optr;
ffffffffc02056ae:	1007b703          	ld	a4,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff5690>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02056b2:	6008                	ld	a0,0(s0)
            current->cptr = proc->optr;
ffffffffc02056b4:	faf8                	sd	a4,240(a3)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02056b6:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02056b8:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02056bc:	10e7b023          	sd	a4,256(a5)
ffffffffc02056c0:	c311                	beqz	a4,ffffffffc02056c4 <do_exit+0xb4>
                initproc->cptr->yptr = proc;
ffffffffc02056c2:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02056c4:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02056c6:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02056c8:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02056ca:	fe9710e3          	bne	a4,s1,ffffffffc02056aa <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02056ce:	0ec52783          	lw	a5,236(a0)
ffffffffc02056d2:	fd379ce3          	bne	a5,s3,ffffffffc02056aa <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02056d6:	257000ef          	jal	ra,ffffffffc020612c <wakeup_proc>
ffffffffc02056da:	00093683          	ld	a3,0(s2)
ffffffffc02056de:	b7f1                	j	ffffffffc02056aa <do_exit+0x9a>
    if (flag) {
ffffffffc02056e0:	020a1363          	bnez	s4,ffffffffc0205706 <do_exit+0xf6>
    schedule();
ffffffffc02056e4:	2c5000ef          	jal	ra,ffffffffc02061a8 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02056e8:	00093783          	ld	a5,0(s2)
ffffffffc02056ec:	00003617          	auipc	a2,0x3
ffffffffc02056f0:	11460613          	addi	a2,a2,276 # ffffffffc0208800 <default_pmm_manager+0x250>
ffffffffc02056f4:	21000593          	li	a1,528
ffffffffc02056f8:	43d4                	lw	a3,4(a5)
ffffffffc02056fa:	00003517          	auipc	a0,0x3
ffffffffc02056fe:	3b650513          	addi	a0,a0,950 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205702:	b15fa0ef          	jal	ra,ffffffffc0200216 <__panic>
        intr_enable();
ffffffffc0205706:	f51fa0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc020570a:	bfe9                	j	ffffffffc02056e4 <do_exit+0xd4>
        panic("idleproc exit.\n");
ffffffffc020570c:	00003617          	auipc	a2,0x3
ffffffffc0205710:	0d460613          	addi	a2,a2,212 # ffffffffc02087e0 <default_pmm_manager+0x230>
ffffffffc0205714:	1e400593          	li	a1,484
ffffffffc0205718:	00003517          	auipc	a0,0x3
ffffffffc020571c:	39850513          	addi	a0,a0,920 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205720:	af7fa0ef          	jal	ra,ffffffffc0200216 <__panic>
            exit_mmap(mm);
ffffffffc0205724:	8526                	mv	a0,s1
ffffffffc0205726:	c7afd0ef          	jal	ra,ffffffffc0202ba0 <exit_mmap>
            put_pgdir(mm);
ffffffffc020572a:	8526                	mv	a0,s1
ffffffffc020572c:	8bdff0ef          	jal	ra,ffffffffc0204fe8 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205730:	8526                	mv	a0,s1
ffffffffc0205732:	acefd0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
ffffffffc0205736:	bf1d                	j	ffffffffc020566c <do_exit+0x5c>
        panic("initproc exit.\n");
ffffffffc0205738:	00003617          	auipc	a2,0x3
ffffffffc020573c:	0b860613          	addi	a2,a2,184 # ffffffffc02087f0 <default_pmm_manager+0x240>
ffffffffc0205740:	1e700593          	li	a1,487
ffffffffc0205744:	00003517          	auipc	a0,0x3
ffffffffc0205748:	36c50513          	addi	a0,a0,876 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc020574c:	acbfa0ef          	jal	ra,ffffffffc0200216 <__panic>
        intr_disable();
ffffffffc0205750:	f0dfa0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc0205754:	4a05                	li	s4,1
ffffffffc0205756:	bf15                	j	ffffffffc020568a <do_exit+0x7a>
            wakeup_proc(proc);
ffffffffc0205758:	1d5000ef          	jal	ra,ffffffffc020612c <wakeup_proc>
ffffffffc020575c:	b789                	j	ffffffffc020569e <do_exit+0x8e>

ffffffffc020575e <do_wait.part.1>:
do_wait(int pid, int *code_store) {
ffffffffc020575e:	7139                	addi	sp,sp,-64
ffffffffc0205760:	e852                	sd	s4,16(sp)
        current->wait_state = WT_CHILD;
ffffffffc0205762:	80000a37          	lui	s4,0x80000
do_wait(int pid, int *code_store) {
ffffffffc0205766:	f426                	sd	s1,40(sp)
ffffffffc0205768:	f04a                	sd	s2,32(sp)
ffffffffc020576a:	ec4e                	sd	s3,24(sp)
ffffffffc020576c:	e456                	sd	s5,8(sp)
ffffffffc020576e:	e05a                	sd	s6,0(sp)
ffffffffc0205770:	fc06                	sd	ra,56(sp)
ffffffffc0205772:	f822                	sd	s0,48(sp)
ffffffffc0205774:	89aa                	mv	s3,a0
ffffffffc0205776:	8b2e                	mv	s6,a1
        proc = current->cptr;
ffffffffc0205778:	000a7917          	auipc	s2,0xa7
ffffffffc020577c:	c7890913          	addi	s2,s2,-904 # ffffffffc02ac3f0 <current>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205780:	448d                	li	s1,3
        current->state = PROC_SLEEPING;
ffffffffc0205782:	4a85                	li	s5,1
        current->wait_state = WT_CHILD;
ffffffffc0205784:	2a05                	addiw	s4,s4,1
    if (pid != 0) {
ffffffffc0205786:	02098f63          	beqz	s3,ffffffffc02057c4 <do_wait.part.1+0x66>
        proc = find_proc(pid);
ffffffffc020578a:	854e                	mv	a0,s3
ffffffffc020578c:	9fdff0ef          	jal	ra,ffffffffc0205188 <find_proc>
ffffffffc0205790:	842a                	mv	s0,a0
        if (proc != NULL && proc->parent == current) {
ffffffffc0205792:	12050063          	beqz	a0,ffffffffc02058b2 <do_wait.part.1+0x154>
ffffffffc0205796:	00093703          	ld	a4,0(s2)
ffffffffc020579a:	711c                	ld	a5,32(a0)
ffffffffc020579c:	10e79b63          	bne	a5,a4,ffffffffc02058b2 <do_wait.part.1+0x154>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02057a0:	411c                	lw	a5,0(a0)
ffffffffc02057a2:	02978c63          	beq	a5,s1,ffffffffc02057da <do_wait.part.1+0x7c>
        current->state = PROC_SLEEPING;
ffffffffc02057a6:	01572023          	sw	s5,0(a4)
        current->wait_state = WT_CHILD;
ffffffffc02057aa:	0f472623          	sw	s4,236(a4)
        schedule();
ffffffffc02057ae:	1fb000ef          	jal	ra,ffffffffc02061a8 <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc02057b2:	00093783          	ld	a5,0(s2)
ffffffffc02057b6:	0b07a783          	lw	a5,176(a5)
ffffffffc02057ba:	8b85                	andi	a5,a5,1
ffffffffc02057bc:	d7e9                	beqz	a5,ffffffffc0205786 <do_wait.part.1+0x28>
            do_exit(-E_KILLED);
ffffffffc02057be:	555d                	li	a0,-9
ffffffffc02057c0:	e51ff0ef          	jal	ra,ffffffffc0205610 <do_exit>
        proc = current->cptr;
ffffffffc02057c4:	00093703          	ld	a4,0(s2)
ffffffffc02057c8:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc02057ca:	e409                	bnez	s0,ffffffffc02057d4 <do_wait.part.1+0x76>
ffffffffc02057cc:	a0dd                	j	ffffffffc02058b2 <do_wait.part.1+0x154>
ffffffffc02057ce:	10043403          	ld	s0,256(s0)
ffffffffc02057d2:	d871                	beqz	s0,ffffffffc02057a6 <do_wait.part.1+0x48>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02057d4:	401c                	lw	a5,0(s0)
ffffffffc02057d6:	fe979ce3          	bne	a5,s1,ffffffffc02057ce <do_wait.part.1+0x70>
    if (proc == idleproc || proc == initproc) {
ffffffffc02057da:	000a7797          	auipc	a5,0xa7
ffffffffc02057de:	c1e78793          	addi	a5,a5,-994 # ffffffffc02ac3f8 <idleproc>
ffffffffc02057e2:	639c                	ld	a5,0(a5)
ffffffffc02057e4:	0c878d63          	beq	a5,s0,ffffffffc02058be <do_wait.part.1+0x160>
ffffffffc02057e8:	000a7797          	auipc	a5,0xa7
ffffffffc02057ec:	c1878793          	addi	a5,a5,-1000 # ffffffffc02ac400 <initproc>
ffffffffc02057f0:	639c                	ld	a5,0(a5)
ffffffffc02057f2:	0cf40663          	beq	s0,a5,ffffffffc02058be <do_wait.part.1+0x160>
    if (code_store != NULL) {
ffffffffc02057f6:	000b0663          	beqz	s6,ffffffffc0205802 <do_wait.part.1+0xa4>
        *code_store = proc->exit_code;
ffffffffc02057fa:	0e842783          	lw	a5,232(s0)
ffffffffc02057fe:	00fb2023          	sw	a5,0(s6)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205802:	100027f3          	csrr	a5,sstatus
ffffffffc0205806:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205808:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020580a:	e7d5                	bnez	a5,ffffffffc02058b6 <do_wait.part.1+0x158>
    __list_del(listelm->prev, listelm->next);
ffffffffc020580c:	6c70                	ld	a2,216(s0)
ffffffffc020580e:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc0205810:	10043703          	ld	a4,256(s0)
ffffffffc0205814:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0205816:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205818:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020581a:	6470                	ld	a2,200(s0)
ffffffffc020581c:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020581e:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205820:	e290                	sd	a2,0(a3)
ffffffffc0205822:	c319                	beqz	a4,ffffffffc0205828 <do_wait.part.1+0xca>
        proc->optr->yptr = proc->yptr;
ffffffffc0205824:	ff7c                	sd	a5,248(a4)
ffffffffc0205826:	7c7c                	ld	a5,248(s0)
    if (proc->yptr != NULL) {
ffffffffc0205828:	c3d1                	beqz	a5,ffffffffc02058ac <do_wait.part.1+0x14e>
        proc->yptr->optr = proc->optr;
ffffffffc020582a:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc020582e:	000a7797          	auipc	a5,0xa7
ffffffffc0205832:	bda78793          	addi	a5,a5,-1062 # ffffffffc02ac408 <nr_process>
ffffffffc0205836:	439c                	lw	a5,0(a5)
ffffffffc0205838:	37fd                	addiw	a5,a5,-1
ffffffffc020583a:	000a7717          	auipc	a4,0xa7
ffffffffc020583e:	bcf72723          	sw	a5,-1074(a4) # ffffffffc02ac408 <nr_process>
    if (flag) {
ffffffffc0205842:	e1b5                	bnez	a1,ffffffffc02058a6 <do_wait.part.1+0x148>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0205844:	6814                	ld	a3,16(s0)
ffffffffc0205846:	c02007b7          	lui	a5,0xc0200
ffffffffc020584a:	0af6e263          	bltu	a3,a5,ffffffffc02058ee <do_wait.part.1+0x190>
ffffffffc020584e:	000a7797          	auipc	a5,0xa7
ffffffffc0205852:	bd278793          	addi	a5,a5,-1070 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0205856:	6398                	ld	a4,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0205858:	000a7797          	auipc	a5,0xa7
ffffffffc020585c:	b7078793          	addi	a5,a5,-1168 # ffffffffc02ac3c8 <npage>
ffffffffc0205860:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0205862:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc0205864:	82b1                	srli	a3,a3,0xc
ffffffffc0205866:	06f6f863          	bleu	a5,a3,ffffffffc02058d6 <do_wait.part.1+0x178>
    return &pages[PPN(pa) - nbase];
ffffffffc020586a:	00003797          	auipc	a5,0x3
ffffffffc020586e:	70e78793          	addi	a5,a5,1806 # ffffffffc0208f78 <nbase>
ffffffffc0205872:	639c                	ld	a5,0(a5)
ffffffffc0205874:	000a7717          	auipc	a4,0xa7
ffffffffc0205878:	bbc70713          	addi	a4,a4,-1092 # ffffffffc02ac430 <pages>
ffffffffc020587c:	6308                	ld	a0,0(a4)
ffffffffc020587e:	8e9d                	sub	a3,a3,a5
ffffffffc0205880:	069a                	slli	a3,a3,0x6
ffffffffc0205882:	9536                	add	a0,a0,a3
ffffffffc0205884:	4589                	li	a1,2
ffffffffc0205886:	eacfb0ef          	jal	ra,ffffffffc0200f32 <free_pages>
    kfree(proc);
ffffffffc020588a:	8522                	mv	a0,s0
ffffffffc020588c:	eddfd0ef          	jal	ra,ffffffffc0203768 <kfree>
    return 0;
ffffffffc0205890:	4501                	li	a0,0
}
ffffffffc0205892:	70e2                	ld	ra,56(sp)
ffffffffc0205894:	7442                	ld	s0,48(sp)
ffffffffc0205896:	74a2                	ld	s1,40(sp)
ffffffffc0205898:	7902                	ld	s2,32(sp)
ffffffffc020589a:	69e2                	ld	s3,24(sp)
ffffffffc020589c:	6a42                	ld	s4,16(sp)
ffffffffc020589e:	6aa2                	ld	s5,8(sp)
ffffffffc02058a0:	6b02                	ld	s6,0(sp)
ffffffffc02058a2:	6121                	addi	sp,sp,64
ffffffffc02058a4:	8082                	ret
        intr_enable();
ffffffffc02058a6:	db1fa0ef          	jal	ra,ffffffffc0200656 <intr_enable>
ffffffffc02058aa:	bf69                	j	ffffffffc0205844 <do_wait.part.1+0xe6>
       proc->parent->cptr = proc->optr;
ffffffffc02058ac:	701c                	ld	a5,32(s0)
ffffffffc02058ae:	fbf8                	sd	a4,240(a5)
ffffffffc02058b0:	bfbd                	j	ffffffffc020582e <do_wait.part.1+0xd0>
    return -E_BAD_PROC;
ffffffffc02058b2:	5579                	li	a0,-2
ffffffffc02058b4:	bff9                	j	ffffffffc0205892 <do_wait.part.1+0x134>
        intr_disable();
ffffffffc02058b6:	da7fa0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc02058ba:	4585                	li	a1,1
ffffffffc02058bc:	bf81                	j	ffffffffc020580c <do_wait.part.1+0xae>
        panic("wait idleproc or initproc.\n");
ffffffffc02058be:	00003617          	auipc	a2,0x3
ffffffffc02058c2:	faa60613          	addi	a2,a2,-86 # ffffffffc0208868 <default_pmm_manager+0x2b8>
ffffffffc02058c6:	30700593          	li	a1,775
ffffffffc02058ca:	00003517          	auipc	a0,0x3
ffffffffc02058ce:	1e650513          	addi	a0,a0,486 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc02058d2:	945fa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02058d6:	00002617          	auipc	a2,0x2
ffffffffc02058da:	99a60613          	addi	a2,a2,-1638 # ffffffffc0207270 <commands+0x908>
ffffffffc02058de:	06200593          	li	a1,98
ffffffffc02058e2:	00002517          	auipc	a0,0x2
ffffffffc02058e6:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0207290 <commands+0x928>
ffffffffc02058ea:	92dfa0ef          	jal	ra,ffffffffc0200216 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02058ee:	00002617          	auipc	a2,0x2
ffffffffc02058f2:	a2260613          	addi	a2,a2,-1502 # ffffffffc0207310 <commands+0x9a8>
ffffffffc02058f6:	06e00593          	li	a1,110
ffffffffc02058fa:	00002517          	auipc	a0,0x2
ffffffffc02058fe:	99650513          	addi	a0,a0,-1642 # ffffffffc0207290 <commands+0x928>
ffffffffc0205902:	915fa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205906 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc0205906:	1141                	addi	sp,sp,-16
ffffffffc0205908:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020590a:	e6efb0ef          	jal	ra,ffffffffc0200f78 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020590e:	d9bfd0ef          	jal	ra,ffffffffc02036a8 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0205912:	4601                	li	a2,0
ffffffffc0205914:	4581                	li	a1,0
ffffffffc0205916:	fffff517          	auipc	a0,0xfffff
ffffffffc020591a:	65050513          	addi	a0,a0,1616 # ffffffffc0204f66 <user_main>
ffffffffc020591e:	ca3ff0ef          	jal	ra,ffffffffc02055c0 <kernel_thread>
    if (pid <= 0) {
ffffffffc0205922:	00a04563          	bgtz	a0,ffffffffc020592c <init_main+0x26>
ffffffffc0205926:	a841                	j	ffffffffc02059b6 <init_main+0xb0>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc0205928:	081000ef          	jal	ra,ffffffffc02061a8 <schedule>
    if (code_store != NULL) {
ffffffffc020592c:	4581                	li	a1,0
ffffffffc020592e:	4501                	li	a0,0
ffffffffc0205930:	e2fff0ef          	jal	ra,ffffffffc020575e <do_wait.part.1>
    while (do_wait(0, NULL) == 0) {
ffffffffc0205934:	d975                	beqz	a0,ffffffffc0205928 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0205936:	00003517          	auipc	a0,0x3
ffffffffc020593a:	f7250513          	addi	a0,a0,-142 # ffffffffc02088a8 <default_pmm_manager+0x2f8>
ffffffffc020593e:	f92fa0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205942:	000a7797          	auipc	a5,0xa7
ffffffffc0205946:	abe78793          	addi	a5,a5,-1346 # ffffffffc02ac400 <initproc>
ffffffffc020594a:	639c                	ld	a5,0(a5)
ffffffffc020594c:	7bf8                	ld	a4,240(a5)
ffffffffc020594e:	e721                	bnez	a4,ffffffffc0205996 <init_main+0x90>
ffffffffc0205950:	7ff8                	ld	a4,248(a5)
ffffffffc0205952:	e331                	bnez	a4,ffffffffc0205996 <init_main+0x90>
ffffffffc0205954:	1007b703          	ld	a4,256(a5)
ffffffffc0205958:	ef1d                	bnez	a4,ffffffffc0205996 <init_main+0x90>
    assert(nr_process == 2);
ffffffffc020595a:	000a7717          	auipc	a4,0xa7
ffffffffc020595e:	aae70713          	addi	a4,a4,-1362 # ffffffffc02ac408 <nr_process>
ffffffffc0205962:	4314                	lw	a3,0(a4)
ffffffffc0205964:	4709                	li	a4,2
ffffffffc0205966:	0ae69463          	bne	a3,a4,ffffffffc0205a0e <init_main+0x108>
    return listelm->next;
ffffffffc020596a:	000a7697          	auipc	a3,0xa7
ffffffffc020596e:	bc668693          	addi	a3,a3,-1082 # ffffffffc02ac530 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205972:	6698                	ld	a4,8(a3)
ffffffffc0205974:	0c878793          	addi	a5,a5,200
ffffffffc0205978:	06f71b63          	bne	a4,a5,ffffffffc02059ee <init_main+0xe8>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020597c:	629c                	ld	a5,0(a3)
ffffffffc020597e:	04f71863          	bne	a4,a5,ffffffffc02059ce <init_main+0xc8>

    cprintf("init check memory pass.\n");
ffffffffc0205982:	00003517          	auipc	a0,0x3
ffffffffc0205986:	00e50513          	addi	a0,a0,14 # ffffffffc0208990 <default_pmm_manager+0x3e0>
ffffffffc020598a:	f46fa0ef          	jal	ra,ffffffffc02000d0 <cprintf>
    return 0;
}
ffffffffc020598e:	60a2                	ld	ra,8(sp)
ffffffffc0205990:	4501                	li	a0,0
ffffffffc0205992:	0141                	addi	sp,sp,16
ffffffffc0205994:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205996:	00003697          	auipc	a3,0x3
ffffffffc020599a:	f3a68693          	addi	a3,a3,-198 # ffffffffc02088d0 <default_pmm_manager+0x320>
ffffffffc020599e:	00001617          	auipc	a2,0x1
ffffffffc02059a2:	46260613          	addi	a2,a2,1122 # ffffffffc0206e00 <commands+0x498>
ffffffffc02059a6:	36c00593          	li	a1,876
ffffffffc02059aa:	00003517          	auipc	a0,0x3
ffffffffc02059ae:	10650513          	addi	a0,a0,262 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc02059b2:	865fa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("create user_main failed.\n");
ffffffffc02059b6:	00003617          	auipc	a2,0x3
ffffffffc02059ba:	ed260613          	addi	a2,a2,-302 # ffffffffc0208888 <default_pmm_manager+0x2d8>
ffffffffc02059be:	36400593          	li	a1,868
ffffffffc02059c2:	00003517          	auipc	a0,0x3
ffffffffc02059c6:	0ee50513          	addi	a0,a0,238 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc02059ca:	84dfa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02059ce:	00003697          	auipc	a3,0x3
ffffffffc02059d2:	f9268693          	addi	a3,a3,-110 # ffffffffc0208960 <default_pmm_manager+0x3b0>
ffffffffc02059d6:	00001617          	auipc	a2,0x1
ffffffffc02059da:	42a60613          	addi	a2,a2,1066 # ffffffffc0206e00 <commands+0x498>
ffffffffc02059de:	36f00593          	li	a1,879
ffffffffc02059e2:	00003517          	auipc	a0,0x3
ffffffffc02059e6:	0ce50513          	addi	a0,a0,206 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc02059ea:	82dfa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02059ee:	00003697          	auipc	a3,0x3
ffffffffc02059f2:	f4268693          	addi	a3,a3,-190 # ffffffffc0208930 <default_pmm_manager+0x380>
ffffffffc02059f6:	00001617          	auipc	a2,0x1
ffffffffc02059fa:	40a60613          	addi	a2,a2,1034 # ffffffffc0206e00 <commands+0x498>
ffffffffc02059fe:	36e00593          	li	a1,878
ffffffffc0205a02:	00003517          	auipc	a0,0x3
ffffffffc0205a06:	0ae50513          	addi	a0,a0,174 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205a0a:	80dfa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(nr_process == 2);
ffffffffc0205a0e:	00003697          	auipc	a3,0x3
ffffffffc0205a12:	f1268693          	addi	a3,a3,-238 # ffffffffc0208920 <default_pmm_manager+0x370>
ffffffffc0205a16:	00001617          	auipc	a2,0x1
ffffffffc0205a1a:	3ea60613          	addi	a2,a2,1002 # ffffffffc0206e00 <commands+0x498>
ffffffffc0205a1e:	36d00593          	li	a1,877
ffffffffc0205a22:	00003517          	auipc	a0,0x3
ffffffffc0205a26:	08e50513          	addi	a0,a0,142 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205a2a:	fecfa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205a2e <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205a2e:	7135                	addi	sp,sp,-160
ffffffffc0205a30:	f8d2                	sd	s4,112(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0205a32:	000a7a17          	auipc	s4,0xa7
ffffffffc0205a36:	9bea0a13          	addi	s4,s4,-1602 # ffffffffc02ac3f0 <current>
ffffffffc0205a3a:	000a3783          	ld	a5,0(s4)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205a3e:	e14a                	sd	s2,128(sp)
ffffffffc0205a40:	e922                	sd	s0,144(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0205a42:	0287b903          	ld	s2,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205a46:	fcce                	sd	s3,120(sp)
ffffffffc0205a48:	f0da                	sd	s6,96(sp)
ffffffffc0205a4a:	89aa                	mv	s3,a0
ffffffffc0205a4c:	842e                	mv	s0,a1
ffffffffc0205a4e:	8b32                	mv	s6,a2
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205a50:	4681                	li	a3,0
ffffffffc0205a52:	862e                	mv	a2,a1
ffffffffc0205a54:	85aa                	mv	a1,a0
ffffffffc0205a56:	854a                	mv	a0,s2
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205a58:	ed06                	sd	ra,152(sp)
ffffffffc0205a5a:	e526                	sd	s1,136(sp)
ffffffffc0205a5c:	f4d6                	sd	s5,104(sp)
ffffffffc0205a5e:	ecde                	sd	s7,88(sp)
ffffffffc0205a60:	e8e2                	sd	s8,80(sp)
ffffffffc0205a62:	e4e6                	sd	s9,72(sp)
ffffffffc0205a64:	e0ea                	sd	s10,64(sp)
ffffffffc0205a66:	fc6e                	sd	s11,56(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205a68:	8fffd0ef          	jal	ra,ffffffffc0203366 <user_mem_check>
ffffffffc0205a6c:	40050463          	beqz	a0,ffffffffc0205e74 <do_execve+0x446>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0205a70:	4641                	li	a2,16
ffffffffc0205a72:	4581                	li	a1,0
ffffffffc0205a74:	1008                	addi	a0,sp,32
ffffffffc0205a76:	147000ef          	jal	ra,ffffffffc02063bc <memset>
    memcpy(local_name, name, len);
ffffffffc0205a7a:	47bd                	li	a5,15
ffffffffc0205a7c:	8622                	mv	a2,s0
ffffffffc0205a7e:	0687ee63          	bltu	a5,s0,ffffffffc0205afa <do_execve+0xcc>
ffffffffc0205a82:	85ce                	mv	a1,s3
ffffffffc0205a84:	1008                	addi	a0,sp,32
ffffffffc0205a86:	149000ef          	jal	ra,ffffffffc02063ce <memcpy>
    if (mm != NULL) {
ffffffffc0205a8a:	06090f63          	beqz	s2,ffffffffc0205b08 <do_execve+0xda>
        cputs("mm != NULL");
ffffffffc0205a8e:	00002517          	auipc	a0,0x2
ffffffffc0205a92:	19250513          	addi	a0,a0,402 # ffffffffc0207c20 <commands+0x12b8>
ffffffffc0205a96:	e72fa0ef          	jal	ra,ffffffffc0200108 <cputs>
        lcr3(boot_cr3);
ffffffffc0205a9a:	000a7797          	auipc	a5,0xa7
ffffffffc0205a9e:	98e78793          	addi	a5,a5,-1650 # ffffffffc02ac428 <boot_cr3>
ffffffffc0205aa2:	639c                	ld	a5,0(a5)
ffffffffc0205aa4:	577d                	li	a4,-1
ffffffffc0205aa6:	177e                	slli	a4,a4,0x3f
ffffffffc0205aa8:	83b1                	srli	a5,a5,0xc
ffffffffc0205aaa:	8fd9                	or	a5,a5,a4
ffffffffc0205aac:	18079073          	csrw	satp,a5
ffffffffc0205ab0:	03092783          	lw	a5,48(s2)
ffffffffc0205ab4:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205ab8:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205abc:	28070b63          	beqz	a4,ffffffffc0205d52 <do_execve+0x324>
        current->mm = NULL;
ffffffffc0205ac0:	000a3783          	ld	a5,0(s4)
ffffffffc0205ac4:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc0205ac8:	db3fc0ef          	jal	ra,ffffffffc020287a <mm_create>
ffffffffc0205acc:	892a                	mv	s2,a0
ffffffffc0205ace:	c135                	beqz	a0,ffffffffc0205b32 <do_execve+0x104>
    if (setup_pgdir(mm) != 0) {
ffffffffc0205ad0:	d96ff0ef          	jal	ra,ffffffffc0205066 <setup_pgdir>
ffffffffc0205ad4:	e931                	bnez	a0,ffffffffc0205b28 <do_execve+0xfa>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc0205ad6:	000b2703          	lw	a4,0(s6)
ffffffffc0205ada:	464c47b7          	lui	a5,0x464c4
ffffffffc0205ade:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9b0f>
ffffffffc0205ae2:	04f70a63          	beq	a4,a5,ffffffffc0205b36 <do_execve+0x108>
    put_pgdir(mm);
ffffffffc0205ae6:	854a                	mv	a0,s2
ffffffffc0205ae8:	d00ff0ef          	jal	ra,ffffffffc0204fe8 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205aec:	854a                	mv	a0,s2
ffffffffc0205aee:	f13fc0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0205af2:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc0205af4:	854e                	mv	a0,s3
ffffffffc0205af6:	b1bff0ef          	jal	ra,ffffffffc0205610 <do_exit>
    memcpy(local_name, name, len);
ffffffffc0205afa:	463d                	li	a2,15
ffffffffc0205afc:	85ce                	mv	a1,s3
ffffffffc0205afe:	1008                	addi	a0,sp,32
ffffffffc0205b00:	0cf000ef          	jal	ra,ffffffffc02063ce <memcpy>
    if (mm != NULL) {
ffffffffc0205b04:	f80915e3          	bnez	s2,ffffffffc0205a8e <do_execve+0x60>
    if (current->mm != NULL) {
ffffffffc0205b08:	000a3783          	ld	a5,0(s4)
ffffffffc0205b0c:	779c                	ld	a5,40(a5)
ffffffffc0205b0e:	dfcd                	beqz	a5,ffffffffc0205ac8 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0205b10:	00003617          	auipc	a2,0x3
ffffffffc0205b14:	b4860613          	addi	a2,a2,-1208 # ffffffffc0208658 <default_pmm_manager+0xa8>
ffffffffc0205b18:	21a00593          	li	a1,538
ffffffffc0205b1c:	00003517          	auipc	a0,0x3
ffffffffc0205b20:	f9450513          	addi	a0,a0,-108 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205b24:	ef2fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    mm_destroy(mm);
ffffffffc0205b28:	854a                	mv	a0,s2
ffffffffc0205b2a:	ed7fc0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc0205b2e:	59f1                	li	s3,-4
ffffffffc0205b30:	b7d1                	j	ffffffffc0205af4 <do_execve+0xc6>
ffffffffc0205b32:	59f1                	li	s3,-4
ffffffffc0205b34:	b7c1                	j	ffffffffc0205af4 <do_execve+0xc6>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205b36:	038b5703          	lhu	a4,56(s6)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205b3a:	020b3403          	ld	s0,32(s6)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205b3e:	00371793          	slli	a5,a4,0x3
ffffffffc0205b42:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205b44:	945a                	add	s0,s0,s6
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205b46:	078e                	slli	a5,a5,0x3
ffffffffc0205b48:	97a2                	add	a5,a5,s0
ffffffffc0205b4a:	ec3e                	sd	a5,24(sp)
    for (; ph < ph_end; ph ++) {
ffffffffc0205b4c:	02f47b63          	bleu	a5,s0,ffffffffc0205b82 <do_execve+0x154>
    return KADDR(page2pa(page));
ffffffffc0205b50:	5bfd                	li	s7,-1
ffffffffc0205b52:	00cbd793          	srli	a5,s7,0xc
    return page - pages + nbase;
ffffffffc0205b56:	000a7d97          	auipc	s11,0xa7
ffffffffc0205b5a:	8dad8d93          	addi	s11,s11,-1830 # ffffffffc02ac430 <pages>
ffffffffc0205b5e:	00003d17          	auipc	s10,0x3
ffffffffc0205b62:	41ad0d13          	addi	s10,s10,1050 # ffffffffc0208f78 <nbase>
    return KADDR(page2pa(page));
ffffffffc0205b66:	e43e                	sd	a5,8(sp)
ffffffffc0205b68:	000a7c97          	auipc	s9,0xa7
ffffffffc0205b6c:	860c8c93          	addi	s9,s9,-1952 # ffffffffc02ac3c8 <npage>
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc0205b70:	4018                	lw	a4,0(s0)
ffffffffc0205b72:	4785                	li	a5,1
ffffffffc0205b74:	0ef70d63          	beq	a4,a5,ffffffffc0205c6e <do_execve+0x240>
    for (; ph < ph_end; ph ++) {
ffffffffc0205b78:	67e2                	ld	a5,24(sp)
ffffffffc0205b7a:	03840413          	addi	s0,s0,56
ffffffffc0205b7e:	fef469e3          	bltu	s0,a5,ffffffffc0205b70 <do_execve+0x142>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc0205b82:	4701                	li	a4,0
ffffffffc0205b84:	46ad                	li	a3,11
ffffffffc0205b86:	00100637          	lui	a2,0x100
ffffffffc0205b8a:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0205b8e:	854a                	mv	a0,s2
ffffffffc0205b90:	ec3fc0ef          	jal	ra,ffffffffc0202a52 <mm_map>
ffffffffc0205b94:	89aa                	mv	s3,a0
ffffffffc0205b96:	1a051463          	bnez	a0,ffffffffc0205d3e <do_execve+0x310>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205b9a:	01893503          	ld	a0,24(s2)
ffffffffc0205b9e:	467d                	li	a2,31
ffffffffc0205ba0:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0205ba4:	837fc0ef          	jal	ra,ffffffffc02023da <pgdir_alloc_page>
ffffffffc0205ba8:	36050263          	beqz	a0,ffffffffc0205f0c <do_execve+0x4de>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205bac:	01893503          	ld	a0,24(s2)
ffffffffc0205bb0:	467d                	li	a2,31
ffffffffc0205bb2:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0205bb6:	825fc0ef          	jal	ra,ffffffffc02023da <pgdir_alloc_page>
ffffffffc0205bba:	32050963          	beqz	a0,ffffffffc0205eec <do_execve+0x4be>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205bbe:	01893503          	ld	a0,24(s2)
ffffffffc0205bc2:	467d                	li	a2,31
ffffffffc0205bc4:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205bc8:	813fc0ef          	jal	ra,ffffffffc02023da <pgdir_alloc_page>
ffffffffc0205bcc:	30050063          	beqz	a0,ffffffffc0205ecc <do_execve+0x49e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205bd0:	01893503          	ld	a0,24(s2)
ffffffffc0205bd4:	467d                	li	a2,31
ffffffffc0205bd6:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205bda:	801fc0ef          	jal	ra,ffffffffc02023da <pgdir_alloc_page>
ffffffffc0205bde:	2c050763          	beqz	a0,ffffffffc0205eac <do_execve+0x47e>
    mm->mm_count += 1;
ffffffffc0205be2:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0205be6:	000a3603          	ld	a2,0(s4)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205bea:	01893683          	ld	a3,24(s2)
ffffffffc0205bee:	2785                	addiw	a5,a5,1
ffffffffc0205bf0:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0205bf4:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf55b8>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205bf8:	c02007b7          	lui	a5,0xc0200
ffffffffc0205bfc:	28f6ec63          	bltu	a3,a5,ffffffffc0205e94 <do_execve+0x466>
ffffffffc0205c00:	000a7797          	auipc	a5,0xa7
ffffffffc0205c04:	82078793          	addi	a5,a5,-2016 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0205c08:	639c                	ld	a5,0(a5)
ffffffffc0205c0a:	577d                	li	a4,-1
ffffffffc0205c0c:	177e                	slli	a4,a4,0x3f
ffffffffc0205c0e:	8e9d                	sub	a3,a3,a5
ffffffffc0205c10:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205c14:	f654                	sd	a3,168(a2)
ffffffffc0205c16:	8fd9                	or	a5,a5,a4
ffffffffc0205c18:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205c1c:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205c1e:	4581                	li	a1,0
ffffffffc0205c20:	12000613          	li	a2,288
ffffffffc0205c24:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0205c26:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205c2a:	792000ef          	jal	ra,ffffffffc02063bc <memset>
    tf->epc = elf->e_entry;
ffffffffc0205c2e:	018b3703          	ld	a4,24(s6)
    tf->gpr.sp = USTACKTOP;
ffffffffc0205c32:	4785                	li	a5,1
    set_proc_name(current, local_name);
ffffffffc0205c34:	000a3503          	ld	a0,0(s4)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205c38:	edf4f493          	andi	s1,s1,-289
    tf->gpr.sp = USTACKTOP;
ffffffffc0205c3c:	07fe                	slli	a5,a5,0x1f
ffffffffc0205c3e:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0205c40:	10e43423          	sd	a4,264(s0)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205c44:	10943023          	sd	s1,256(s0)
    set_proc_name(current, local_name);
ffffffffc0205c48:	100c                	addi	a1,sp,32
ffffffffc0205c4a:	ca8ff0ef          	jal	ra,ffffffffc02050f2 <set_proc_name>
}
ffffffffc0205c4e:	60ea                	ld	ra,152(sp)
ffffffffc0205c50:	644a                	ld	s0,144(sp)
ffffffffc0205c52:	854e                	mv	a0,s3
ffffffffc0205c54:	64aa                	ld	s1,136(sp)
ffffffffc0205c56:	690a                	ld	s2,128(sp)
ffffffffc0205c58:	79e6                	ld	s3,120(sp)
ffffffffc0205c5a:	7a46                	ld	s4,112(sp)
ffffffffc0205c5c:	7aa6                	ld	s5,104(sp)
ffffffffc0205c5e:	7b06                	ld	s6,96(sp)
ffffffffc0205c60:	6be6                	ld	s7,88(sp)
ffffffffc0205c62:	6c46                	ld	s8,80(sp)
ffffffffc0205c64:	6ca6                	ld	s9,72(sp)
ffffffffc0205c66:	6d06                	ld	s10,64(sp)
ffffffffc0205c68:	7de2                	ld	s11,56(sp)
ffffffffc0205c6a:	610d                	addi	sp,sp,160
ffffffffc0205c6c:	8082                	ret
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc0205c6e:	7410                	ld	a2,40(s0)
ffffffffc0205c70:	701c                	ld	a5,32(s0)
ffffffffc0205c72:	20f66363          	bltu	a2,a5,ffffffffc0205e78 <do_execve+0x44a>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205c76:	405c                	lw	a5,4(s0)
ffffffffc0205c78:	0017f693          	andi	a3,a5,1
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205c7c:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205c80:	068a                	slli	a3,a3,0x2
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205c82:	0e071263          	bnez	a4,ffffffffc0205d66 <do_execve+0x338>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205c86:	4745                	li	a4,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205c88:	8b91                	andi	a5,a5,4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205c8a:	e03a                	sd	a4,0(sp)
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205c8c:	c789                	beqz	a5,ffffffffc0205c96 <do_execve+0x268>
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205c8e:	47cd                	li	a5,19
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205c90:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205c94:	e03e                	sd	a5,0(sp)
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205c96:	0026f793          	andi	a5,a3,2
ffffffffc0205c9a:	efe1                	bnez	a5,ffffffffc0205d72 <do_execve+0x344>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0205c9c:	0046f793          	andi	a5,a3,4
ffffffffc0205ca0:	c789                	beqz	a5,ffffffffc0205caa <do_execve+0x27c>
ffffffffc0205ca2:	6782                	ld	a5,0(sp)
ffffffffc0205ca4:	0087e793          	ori	a5,a5,8
ffffffffc0205ca8:	e03e                	sd	a5,0(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc0205caa:	680c                	ld	a1,16(s0)
ffffffffc0205cac:	4701                	li	a4,0
ffffffffc0205cae:	854a                	mv	a0,s2
ffffffffc0205cb0:	da3fc0ef          	jal	ra,ffffffffc0202a52 <mm_map>
ffffffffc0205cb4:	89aa                	mv	s3,a0
ffffffffc0205cb6:	e541                	bnez	a0,ffffffffc0205d3e <do_execve+0x310>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205cb8:	01043b83          	ld	s7,16(s0)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205cbc:	02043983          	ld	s3,32(s0)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205cc0:	00843a83          	ld	s5,8(s0)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205cc4:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205cc6:	99de                	add	s3,s3,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205cc8:	9ada                	add	s5,s5,s6
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205cca:	00fbfc33          	and	s8,s7,a5
        while (start < end) {
ffffffffc0205cce:	053bef63          	bltu	s7,s3,ffffffffc0205d2c <do_execve+0x2fe>
ffffffffc0205cd2:	aa79                	j	ffffffffc0205e70 <do_execve+0x442>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205cd4:	6785                	lui	a5,0x1
ffffffffc0205cd6:	418b8533          	sub	a0,s7,s8
ffffffffc0205cda:	9c3e                	add	s8,s8,a5
ffffffffc0205cdc:	417c0833          	sub	a6,s8,s7
            if (end < la) {
ffffffffc0205ce0:	0189f463          	bleu	s8,s3,ffffffffc0205ce8 <do_execve+0x2ba>
                size -= la - end;
ffffffffc0205ce4:	41798833          	sub	a6,s3,s7
    return page - pages + nbase;
ffffffffc0205ce8:	000db683          	ld	a3,0(s11)
ffffffffc0205cec:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205cf0:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205cf2:	40d486b3          	sub	a3,s1,a3
ffffffffc0205cf6:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205cf8:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205cfc:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205cfe:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205d02:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205d04:	16c5fc63          	bleu	a2,a1,ffffffffc0205e7c <do_execve+0x44e>
ffffffffc0205d08:	000a6797          	auipc	a5,0xa6
ffffffffc0205d0c:	71878793          	addi	a5,a5,1816 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0205d10:	0007b883          	ld	a7,0(a5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205d14:	85d6                	mv	a1,s5
ffffffffc0205d16:	8642                	mv	a2,a6
ffffffffc0205d18:	96c6                	add	a3,a3,a7
ffffffffc0205d1a:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205d1c:	9bc2                	add	s7,s7,a6
ffffffffc0205d1e:	e842                	sd	a6,16(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205d20:	6ae000ef          	jal	ra,ffffffffc02063ce <memcpy>
            start += size, from += size;
ffffffffc0205d24:	6842                	ld	a6,16(sp)
ffffffffc0205d26:	9ac2                	add	s5,s5,a6
        while (start < end) {
ffffffffc0205d28:	053bf863          	bleu	s3,s7,ffffffffc0205d78 <do_execve+0x34a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205d2c:	01893503          	ld	a0,24(s2)
ffffffffc0205d30:	6602                	ld	a2,0(sp)
ffffffffc0205d32:	85e2                	mv	a1,s8
ffffffffc0205d34:	ea6fc0ef          	jal	ra,ffffffffc02023da <pgdir_alloc_page>
ffffffffc0205d38:	84aa                	mv	s1,a0
ffffffffc0205d3a:	fd49                	bnez	a0,ffffffffc0205cd4 <do_execve+0x2a6>
        ret = -E_NO_MEM;
ffffffffc0205d3c:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0205d3e:	854a                	mv	a0,s2
ffffffffc0205d40:	e61fc0ef          	jal	ra,ffffffffc0202ba0 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205d44:	854a                	mv	a0,s2
ffffffffc0205d46:	aa2ff0ef          	jal	ra,ffffffffc0204fe8 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205d4a:	854a                	mv	a0,s2
ffffffffc0205d4c:	cb5fc0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
    return ret;
ffffffffc0205d50:	b355                	j	ffffffffc0205af4 <do_execve+0xc6>
            exit_mmap(mm);
ffffffffc0205d52:	854a                	mv	a0,s2
ffffffffc0205d54:	e4dfc0ef          	jal	ra,ffffffffc0202ba0 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205d58:	854a                	mv	a0,s2
ffffffffc0205d5a:	a8eff0ef          	jal	ra,ffffffffc0204fe8 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205d5e:	854a                	mv	a0,s2
ffffffffc0205d60:	ca1fc0ef          	jal	ra,ffffffffc0202a00 <mm_destroy>
ffffffffc0205d64:	bbb1                	j	ffffffffc0205ac0 <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205d66:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205d6a:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205d6c:	2681                	sext.w	a3,a3
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205d6e:	f20790e3          	bnez	a5,ffffffffc0205c8e <do_execve+0x260>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205d72:	47dd                	li	a5,23
ffffffffc0205d74:	e03e                	sd	a5,0(sp)
ffffffffc0205d76:	b71d                	j	ffffffffc0205c9c <do_execve+0x26e>
ffffffffc0205d78:	01043983          	ld	s3,16(s0)
        end = ph->p_va + ph->p_memsz;
ffffffffc0205d7c:	7414                	ld	a3,40(s0)
ffffffffc0205d7e:	99b6                	add	s3,s3,a3
        if (start < la) {
ffffffffc0205d80:	098bf163          	bleu	s8,s7,ffffffffc0205e02 <do_execve+0x3d4>
            if (start == end) {
ffffffffc0205d84:	df798ae3          	beq	s3,s7,ffffffffc0205b78 <do_execve+0x14a>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205d88:	6505                	lui	a0,0x1
ffffffffc0205d8a:	955e                	add	a0,a0,s7
ffffffffc0205d8c:	41850533          	sub	a0,a0,s8
                size -= la - end;
ffffffffc0205d90:	41798ab3          	sub	s5,s3,s7
            if (end < la) {
ffffffffc0205d94:	0d89fb63          	bleu	s8,s3,ffffffffc0205e6a <do_execve+0x43c>
    return page - pages + nbase;
ffffffffc0205d98:	000db683          	ld	a3,0(s11)
ffffffffc0205d9c:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205da0:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205da2:	40d486b3          	sub	a3,s1,a3
ffffffffc0205da6:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205da8:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205dac:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205dae:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205db2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205db4:	0cc5f463          	bleu	a2,a1,ffffffffc0205e7c <do_execve+0x44e>
ffffffffc0205db8:	000a6617          	auipc	a2,0xa6
ffffffffc0205dbc:	66860613          	addi	a2,a2,1640 # ffffffffc02ac420 <va_pa_offset>
ffffffffc0205dc0:	00063803          	ld	a6,0(a2)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205dc4:	4581                	li	a1,0
ffffffffc0205dc6:	8656                	mv	a2,s5
ffffffffc0205dc8:	96c2                	add	a3,a3,a6
ffffffffc0205dca:	9536                	add	a0,a0,a3
ffffffffc0205dcc:	5f0000ef          	jal	ra,ffffffffc02063bc <memset>
            start += size;
ffffffffc0205dd0:	017a8733          	add	a4,s5,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205dd4:	0389f463          	bleu	s8,s3,ffffffffc0205dfc <do_execve+0x3ce>
ffffffffc0205dd8:	dae980e3          	beq	s3,a4,ffffffffc0205b78 <do_execve+0x14a>
ffffffffc0205ddc:	00003697          	auipc	a3,0x3
ffffffffc0205de0:	8a468693          	addi	a3,a3,-1884 # ffffffffc0208680 <default_pmm_manager+0xd0>
ffffffffc0205de4:	00001617          	auipc	a2,0x1
ffffffffc0205de8:	01c60613          	addi	a2,a2,28 # ffffffffc0206e00 <commands+0x498>
ffffffffc0205dec:	26f00593          	li	a1,623
ffffffffc0205df0:	00003517          	auipc	a0,0x3
ffffffffc0205df4:	cc050513          	addi	a0,a0,-832 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205df8:	c1efa0ef          	jal	ra,ffffffffc0200216 <__panic>
ffffffffc0205dfc:	ff8710e3          	bne	a4,s8,ffffffffc0205ddc <do_execve+0x3ae>
ffffffffc0205e00:	8be2                	mv	s7,s8
ffffffffc0205e02:	000a6a97          	auipc	s5,0xa6
ffffffffc0205e06:	61ea8a93          	addi	s5,s5,1566 # ffffffffc02ac420 <va_pa_offset>
        while (start < end) {
ffffffffc0205e0a:	053be763          	bltu	s7,s3,ffffffffc0205e58 <do_execve+0x42a>
ffffffffc0205e0e:	b3ad                	j	ffffffffc0205b78 <do_execve+0x14a>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205e10:	6785                	lui	a5,0x1
ffffffffc0205e12:	418b8533          	sub	a0,s7,s8
ffffffffc0205e16:	9c3e                	add	s8,s8,a5
ffffffffc0205e18:	417c0633          	sub	a2,s8,s7
            if (end < la) {
ffffffffc0205e1c:	0189f463          	bleu	s8,s3,ffffffffc0205e24 <do_execve+0x3f6>
                size -= la - end;
ffffffffc0205e20:	41798633          	sub	a2,s3,s7
    return page - pages + nbase;
ffffffffc0205e24:	000db683          	ld	a3,0(s11)
ffffffffc0205e28:	000d3803          	ld	a6,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205e2c:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205e2e:	40d486b3          	sub	a3,s1,a3
ffffffffc0205e32:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205e34:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0205e38:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc0205e3a:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205e3e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205e40:	02b87e63          	bleu	a1,a6,ffffffffc0205e7c <do_execve+0x44e>
ffffffffc0205e44:	000ab803          	ld	a6,0(s5)
            start += size;
ffffffffc0205e48:	9bb2                	add	s7,s7,a2
            memset(page2kva(page) + off, 0, size);
ffffffffc0205e4a:	4581                	li	a1,0
ffffffffc0205e4c:	96c2                	add	a3,a3,a6
ffffffffc0205e4e:	9536                	add	a0,a0,a3
ffffffffc0205e50:	56c000ef          	jal	ra,ffffffffc02063bc <memset>
        while (start < end) {
ffffffffc0205e54:	d33bf2e3          	bleu	s3,s7,ffffffffc0205b78 <do_execve+0x14a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205e58:	01893503          	ld	a0,24(s2)
ffffffffc0205e5c:	6602                	ld	a2,0(sp)
ffffffffc0205e5e:	85e2                	mv	a1,s8
ffffffffc0205e60:	d7afc0ef          	jal	ra,ffffffffc02023da <pgdir_alloc_page>
ffffffffc0205e64:	84aa                	mv	s1,a0
ffffffffc0205e66:	f54d                	bnez	a0,ffffffffc0205e10 <do_execve+0x3e2>
ffffffffc0205e68:	bdd1                	j	ffffffffc0205d3c <do_execve+0x30e>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205e6a:	417c0ab3          	sub	s5,s8,s7
ffffffffc0205e6e:	b72d                	j	ffffffffc0205d98 <do_execve+0x36a>
        while (start < end) {
ffffffffc0205e70:	89de                	mv	s3,s7
ffffffffc0205e72:	b729                	j	ffffffffc0205d7c <do_execve+0x34e>
        return -E_INVAL;
ffffffffc0205e74:	59f5                	li	s3,-3
ffffffffc0205e76:	bbe1                	j	ffffffffc0205c4e <do_execve+0x220>
            ret = -E_INVAL_ELF;
ffffffffc0205e78:	59e1                	li	s3,-8
ffffffffc0205e7a:	b5d1                	j	ffffffffc0205d3e <do_execve+0x310>
ffffffffc0205e7c:	00001617          	auipc	a2,0x1
ffffffffc0205e80:	3bc60613          	addi	a2,a2,956 # ffffffffc0207238 <commands+0x8d0>
ffffffffc0205e84:	06900593          	li	a1,105
ffffffffc0205e88:	00001517          	auipc	a0,0x1
ffffffffc0205e8c:	40850513          	addi	a0,a0,1032 # ffffffffc0207290 <commands+0x928>
ffffffffc0205e90:	b86fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205e94:	00001617          	auipc	a2,0x1
ffffffffc0205e98:	47c60613          	addi	a2,a2,1148 # ffffffffc0207310 <commands+0x9a8>
ffffffffc0205e9c:	28a00593          	li	a1,650
ffffffffc0205ea0:	00003517          	auipc	a0,0x3
ffffffffc0205ea4:	c1050513          	addi	a0,a0,-1008 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205ea8:	b6efa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205eac:	00003697          	auipc	a3,0x3
ffffffffc0205eb0:	8ec68693          	addi	a3,a3,-1812 # ffffffffc0208798 <default_pmm_manager+0x1e8>
ffffffffc0205eb4:	00001617          	auipc	a2,0x1
ffffffffc0205eb8:	f4c60613          	addi	a2,a2,-180 # ffffffffc0206e00 <commands+0x498>
ffffffffc0205ebc:	28500593          	li	a1,645
ffffffffc0205ec0:	00003517          	auipc	a0,0x3
ffffffffc0205ec4:	bf050513          	addi	a0,a0,-1040 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205ec8:	b4efa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205ecc:	00003697          	auipc	a3,0x3
ffffffffc0205ed0:	88468693          	addi	a3,a3,-1916 # ffffffffc0208750 <default_pmm_manager+0x1a0>
ffffffffc0205ed4:	00001617          	auipc	a2,0x1
ffffffffc0205ed8:	f2c60613          	addi	a2,a2,-212 # ffffffffc0206e00 <commands+0x498>
ffffffffc0205edc:	28400593          	li	a1,644
ffffffffc0205ee0:	00003517          	auipc	a0,0x3
ffffffffc0205ee4:	bd050513          	addi	a0,a0,-1072 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205ee8:	b2efa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205eec:	00003697          	auipc	a3,0x3
ffffffffc0205ef0:	81c68693          	addi	a3,a3,-2020 # ffffffffc0208708 <default_pmm_manager+0x158>
ffffffffc0205ef4:	00001617          	auipc	a2,0x1
ffffffffc0205ef8:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206e00 <commands+0x498>
ffffffffc0205efc:	28300593          	li	a1,643
ffffffffc0205f00:	00003517          	auipc	a0,0x3
ffffffffc0205f04:	bb050513          	addi	a0,a0,-1104 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205f08:	b0efa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205f0c:	00002697          	auipc	a3,0x2
ffffffffc0205f10:	7b468693          	addi	a3,a3,1972 # ffffffffc02086c0 <default_pmm_manager+0x110>
ffffffffc0205f14:	00001617          	auipc	a2,0x1
ffffffffc0205f18:	eec60613          	addi	a2,a2,-276 # ffffffffc0206e00 <commands+0x498>
ffffffffc0205f1c:	28200593          	li	a1,642
ffffffffc0205f20:	00003517          	auipc	a0,0x3
ffffffffc0205f24:	b9050513          	addi	a0,a0,-1136 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc0205f28:	aeefa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0205f2c <do_yield>:
    current->need_resched = 1;
ffffffffc0205f2c:	000a6797          	auipc	a5,0xa6
ffffffffc0205f30:	4c478793          	addi	a5,a5,1220 # ffffffffc02ac3f0 <current>
ffffffffc0205f34:	639c                	ld	a5,0(a5)
ffffffffc0205f36:	4705                	li	a4,1
}
ffffffffc0205f38:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0205f3a:	ef98                	sd	a4,24(a5)
}
ffffffffc0205f3c:	8082                	ret

ffffffffc0205f3e <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205f3e:	1101                	addi	sp,sp,-32
ffffffffc0205f40:	e822                	sd	s0,16(sp)
ffffffffc0205f42:	e426                	sd	s1,8(sp)
ffffffffc0205f44:	ec06                	sd	ra,24(sp)
ffffffffc0205f46:	842e                	mv	s0,a1
ffffffffc0205f48:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205f4a:	cd81                	beqz	a1,ffffffffc0205f62 <do_wait+0x24>
    struct mm_struct *mm = current->mm;
ffffffffc0205f4c:	000a6797          	auipc	a5,0xa6
ffffffffc0205f50:	4a478793          	addi	a5,a5,1188 # ffffffffc02ac3f0 <current>
ffffffffc0205f54:	639c                	ld	a5,0(a5)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205f56:	4685                	li	a3,1
ffffffffc0205f58:	4611                	li	a2,4
ffffffffc0205f5a:	7788                	ld	a0,40(a5)
ffffffffc0205f5c:	c0afd0ef          	jal	ra,ffffffffc0203366 <user_mem_check>
ffffffffc0205f60:	c909                	beqz	a0,ffffffffc0205f72 <do_wait+0x34>
ffffffffc0205f62:	85a2                	mv	a1,s0
}
ffffffffc0205f64:	6442                	ld	s0,16(sp)
ffffffffc0205f66:	60e2                	ld	ra,24(sp)
ffffffffc0205f68:	8526                	mv	a0,s1
ffffffffc0205f6a:	64a2                	ld	s1,8(sp)
ffffffffc0205f6c:	6105                	addi	sp,sp,32
ffffffffc0205f6e:	ff0ff06f          	j	ffffffffc020575e <do_wait.part.1>
ffffffffc0205f72:	60e2                	ld	ra,24(sp)
ffffffffc0205f74:	6442                	ld	s0,16(sp)
ffffffffc0205f76:	64a2                	ld	s1,8(sp)
ffffffffc0205f78:	5575                	li	a0,-3
ffffffffc0205f7a:	6105                	addi	sp,sp,32
ffffffffc0205f7c:	8082                	ret

ffffffffc0205f7e <do_kill>:
do_kill(int pid) {
ffffffffc0205f7e:	1141                	addi	sp,sp,-16
ffffffffc0205f80:	e406                	sd	ra,8(sp)
ffffffffc0205f82:	e022                	sd	s0,0(sp)
    if ((proc = find_proc(pid)) != NULL) {
ffffffffc0205f84:	a04ff0ef          	jal	ra,ffffffffc0205188 <find_proc>
ffffffffc0205f88:	cd0d                	beqz	a0,ffffffffc0205fc2 <do_kill+0x44>
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205f8a:	0b052703          	lw	a4,176(a0)
ffffffffc0205f8e:	00177693          	andi	a3,a4,1
ffffffffc0205f92:	e695                	bnez	a3,ffffffffc0205fbe <do_kill+0x40>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205f94:	0ec52683          	lw	a3,236(a0)
            proc->flags |= PF_EXITING;
ffffffffc0205f98:	00176713          	ori	a4,a4,1
ffffffffc0205f9c:	0ae52823          	sw	a4,176(a0)
            return 0;
ffffffffc0205fa0:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205fa2:	0006c763          	bltz	a3,ffffffffc0205fb0 <do_kill+0x32>
}
ffffffffc0205fa6:	8522                	mv	a0,s0
ffffffffc0205fa8:	60a2                	ld	ra,8(sp)
ffffffffc0205faa:	6402                	ld	s0,0(sp)
ffffffffc0205fac:	0141                	addi	sp,sp,16
ffffffffc0205fae:	8082                	ret
                wakeup_proc(proc);
ffffffffc0205fb0:	17c000ef          	jal	ra,ffffffffc020612c <wakeup_proc>
}
ffffffffc0205fb4:	8522                	mv	a0,s0
ffffffffc0205fb6:	60a2                	ld	ra,8(sp)
ffffffffc0205fb8:	6402                	ld	s0,0(sp)
ffffffffc0205fba:	0141                	addi	sp,sp,16
ffffffffc0205fbc:	8082                	ret
        return -E_KILLED;
ffffffffc0205fbe:	545d                	li	s0,-9
ffffffffc0205fc0:	b7dd                	j	ffffffffc0205fa6 <do_kill+0x28>
    return -E_INVAL;
ffffffffc0205fc2:	5475                	li	s0,-3
ffffffffc0205fc4:	b7cd                	j	ffffffffc0205fa6 <do_kill+0x28>

ffffffffc0205fc6 <proc_init>:
    elm->prev = elm->next = elm;
ffffffffc0205fc6:	000a6797          	auipc	a5,0xa6
ffffffffc0205fca:	56a78793          	addi	a5,a5,1386 # ffffffffc02ac530 <proc_list>

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205fce:	1101                	addi	sp,sp,-32
ffffffffc0205fd0:	000a6717          	auipc	a4,0xa6
ffffffffc0205fd4:	56f73423          	sd	a5,1384(a4) # ffffffffc02ac538 <proc_list+0x8>
ffffffffc0205fd8:	000a6717          	auipc	a4,0xa6
ffffffffc0205fdc:	54f73c23          	sd	a5,1368(a4) # ffffffffc02ac530 <proc_list>
ffffffffc0205fe0:	ec06                	sd	ra,24(sp)
ffffffffc0205fe2:	e822                	sd	s0,16(sp)
ffffffffc0205fe4:	e426                	sd	s1,8(sp)
ffffffffc0205fe6:	000a2797          	auipc	a5,0xa2
ffffffffc0205fea:	3ca78793          	addi	a5,a5,970 # ffffffffc02a83b0 <hash_list>
ffffffffc0205fee:	000a6717          	auipc	a4,0xa6
ffffffffc0205ff2:	3c270713          	addi	a4,a4,962 # ffffffffc02ac3b0 <is_panic>
ffffffffc0205ff6:	e79c                	sd	a5,8(a5)
ffffffffc0205ff8:	e39c                	sd	a5,0(a5)
ffffffffc0205ffa:	07c1                	addi	a5,a5,16
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205ffc:	fee79de3          	bne	a5,a4,ffffffffc0205ff6 <proc_init+0x30>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0206000:	ee3fe0ef          	jal	ra,ffffffffc0204ee2 <alloc_proc>
ffffffffc0206004:	000a6717          	auipc	a4,0xa6
ffffffffc0206008:	3ea73a23          	sd	a0,1012(a4) # ffffffffc02ac3f8 <idleproc>
ffffffffc020600c:	000a6497          	auipc	s1,0xa6
ffffffffc0206010:	3ec48493          	addi	s1,s1,1004 # ffffffffc02ac3f8 <idleproc>
ffffffffc0206014:	c559                	beqz	a0,ffffffffc02060a2 <proc_init+0xdc>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0206016:	4709                	li	a4,2
ffffffffc0206018:	e118                	sd	a4,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
ffffffffc020601a:	4405                	li	s0,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020601c:	00003717          	auipc	a4,0x3
ffffffffc0206020:	fe470713          	addi	a4,a4,-28 # ffffffffc0209000 <bootstack>
    set_proc_name(idleproc, "idle");
ffffffffc0206024:	00003597          	auipc	a1,0x3
ffffffffc0206028:	9a458593          	addi	a1,a1,-1628 # ffffffffc02089c8 <default_pmm_manager+0x418>
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020602c:	e918                	sd	a4,16(a0)
    idleproc->need_resched = 1;
ffffffffc020602e:	ed00                	sd	s0,24(a0)
    set_proc_name(idleproc, "idle");
ffffffffc0206030:	8c2ff0ef          	jal	ra,ffffffffc02050f2 <set_proc_name>
    nr_process ++;
ffffffffc0206034:	000a6797          	auipc	a5,0xa6
ffffffffc0206038:	3d478793          	addi	a5,a5,980 # ffffffffc02ac408 <nr_process>
ffffffffc020603c:	439c                	lw	a5,0(a5)

    current = idleproc;
ffffffffc020603e:	6098                	ld	a4,0(s1)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0206040:	4601                	li	a2,0
    nr_process ++;
ffffffffc0206042:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0206044:	4581                	li	a1,0
ffffffffc0206046:	00000517          	auipc	a0,0x0
ffffffffc020604a:	8c050513          	addi	a0,a0,-1856 # ffffffffc0205906 <init_main>
    nr_process ++;
ffffffffc020604e:	000a6697          	auipc	a3,0xa6
ffffffffc0206052:	3af6ad23          	sw	a5,954(a3) # ffffffffc02ac408 <nr_process>
    current = idleproc;
ffffffffc0206056:	000a6797          	auipc	a5,0xa6
ffffffffc020605a:	38e7bd23          	sd	a4,922(a5) # ffffffffc02ac3f0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020605e:	d62ff0ef          	jal	ra,ffffffffc02055c0 <kernel_thread>
    if (pid <= 0) {
ffffffffc0206062:	08a05c63          	blez	a0,ffffffffc02060fa <proc_init+0x134>
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0206066:	922ff0ef          	jal	ra,ffffffffc0205188 <find_proc>
    set_proc_name(initproc, "init");
ffffffffc020606a:	00003597          	auipc	a1,0x3
ffffffffc020606e:	98658593          	addi	a1,a1,-1658 # ffffffffc02089f0 <default_pmm_manager+0x440>
    initproc = find_proc(pid);
ffffffffc0206072:	000a6797          	auipc	a5,0xa6
ffffffffc0206076:	38a7b723          	sd	a0,910(a5) # ffffffffc02ac400 <initproc>
    set_proc_name(initproc, "init");
ffffffffc020607a:	878ff0ef          	jal	ra,ffffffffc02050f2 <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020607e:	609c                	ld	a5,0(s1)
ffffffffc0206080:	cfa9                	beqz	a5,ffffffffc02060da <proc_init+0x114>
ffffffffc0206082:	43dc                	lw	a5,4(a5)
ffffffffc0206084:	ebb9                	bnez	a5,ffffffffc02060da <proc_init+0x114>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0206086:	000a6797          	auipc	a5,0xa6
ffffffffc020608a:	37a78793          	addi	a5,a5,890 # ffffffffc02ac400 <initproc>
ffffffffc020608e:	639c                	ld	a5,0(a5)
ffffffffc0206090:	c78d                	beqz	a5,ffffffffc02060ba <proc_init+0xf4>
ffffffffc0206092:	43dc                	lw	a5,4(a5)
ffffffffc0206094:	02879363          	bne	a5,s0,ffffffffc02060ba <proc_init+0xf4>
}
ffffffffc0206098:	60e2                	ld	ra,24(sp)
ffffffffc020609a:	6442                	ld	s0,16(sp)
ffffffffc020609c:	64a2                	ld	s1,8(sp)
ffffffffc020609e:	6105                	addi	sp,sp,32
ffffffffc02060a0:	8082                	ret
        panic("cannot alloc idleproc.\n");
ffffffffc02060a2:	00003617          	auipc	a2,0x3
ffffffffc02060a6:	90e60613          	addi	a2,a2,-1778 # ffffffffc02089b0 <default_pmm_manager+0x400>
ffffffffc02060aa:	38100593          	li	a1,897
ffffffffc02060ae:	00003517          	auipc	a0,0x3
ffffffffc02060b2:	a0250513          	addi	a0,a0,-1534 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc02060b6:	960fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02060ba:	00003697          	auipc	a3,0x3
ffffffffc02060be:	96668693          	addi	a3,a3,-1690 # ffffffffc0208a20 <default_pmm_manager+0x470>
ffffffffc02060c2:	00001617          	auipc	a2,0x1
ffffffffc02060c6:	d3e60613          	addi	a2,a2,-706 # ffffffffc0206e00 <commands+0x498>
ffffffffc02060ca:	39600593          	li	a1,918
ffffffffc02060ce:	00003517          	auipc	a0,0x3
ffffffffc02060d2:	9e250513          	addi	a0,a0,-1566 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc02060d6:	940fa0ef          	jal	ra,ffffffffc0200216 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02060da:	00003697          	auipc	a3,0x3
ffffffffc02060de:	91e68693          	addi	a3,a3,-1762 # ffffffffc02089f8 <default_pmm_manager+0x448>
ffffffffc02060e2:	00001617          	auipc	a2,0x1
ffffffffc02060e6:	d1e60613          	addi	a2,a2,-738 # ffffffffc0206e00 <commands+0x498>
ffffffffc02060ea:	39500593          	li	a1,917
ffffffffc02060ee:	00003517          	auipc	a0,0x3
ffffffffc02060f2:	9c250513          	addi	a0,a0,-1598 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc02060f6:	920fa0ef          	jal	ra,ffffffffc0200216 <__panic>
        panic("create init_main failed.\n");
ffffffffc02060fa:	00003617          	auipc	a2,0x3
ffffffffc02060fe:	8d660613          	addi	a2,a2,-1834 # ffffffffc02089d0 <default_pmm_manager+0x420>
ffffffffc0206102:	38f00593          	li	a1,911
ffffffffc0206106:	00003517          	auipc	a0,0x3
ffffffffc020610a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0208ab0 <default_pmm_manager+0x500>
ffffffffc020610e:	908fa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc0206112 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0206112:	1141                	addi	sp,sp,-16
ffffffffc0206114:	e022                	sd	s0,0(sp)
ffffffffc0206116:	e406                	sd	ra,8(sp)
ffffffffc0206118:	000a6417          	auipc	s0,0xa6
ffffffffc020611c:	2d840413          	addi	s0,s0,728 # ffffffffc02ac3f0 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0206120:	6018                	ld	a4,0(s0)
ffffffffc0206122:	6f1c                	ld	a5,24(a4)
ffffffffc0206124:	dffd                	beqz	a5,ffffffffc0206122 <cpu_idle+0x10>
            schedule();
ffffffffc0206126:	082000ef          	jal	ra,ffffffffc02061a8 <schedule>
ffffffffc020612a:	bfdd                	j	ffffffffc0206120 <cpu_idle+0xe>

ffffffffc020612c <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020612c:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc020612e:	1101                	addi	sp,sp,-32
ffffffffc0206130:	ec06                	sd	ra,24(sp)
ffffffffc0206132:	e822                	sd	s0,16(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0206134:	478d                	li	a5,3
ffffffffc0206136:	04f70a63          	beq	a4,a5,ffffffffc020618a <wakeup_proc+0x5e>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020613a:	100027f3          	csrr	a5,sstatus
ffffffffc020613e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0206140:	4401                	li	s0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0206142:	ef8d                	bnez	a5,ffffffffc020617c <wakeup_proc+0x50>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0206144:	4789                	li	a5,2
ffffffffc0206146:	00f70f63          	beq	a4,a5,ffffffffc0206164 <wakeup_proc+0x38>
            proc->state = PROC_RUNNABLE;
ffffffffc020614a:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc020614c:	0e052623          	sw	zero,236(a0)
    if (flag) {
ffffffffc0206150:	e409                	bnez	s0,ffffffffc020615a <wakeup_proc+0x2e>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206152:	60e2                	ld	ra,24(sp)
ffffffffc0206154:	6442                	ld	s0,16(sp)
ffffffffc0206156:	6105                	addi	sp,sp,32
ffffffffc0206158:	8082                	ret
ffffffffc020615a:	6442                	ld	s0,16(sp)
ffffffffc020615c:	60e2                	ld	ra,24(sp)
ffffffffc020615e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0206160:	cf6fa06f          	j	ffffffffc0200656 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0206164:	00003617          	auipc	a2,0x3
ffffffffc0206168:	99c60613          	addi	a2,a2,-1636 # ffffffffc0208b00 <default_pmm_manager+0x550>
ffffffffc020616c:	45c9                	li	a1,18
ffffffffc020616e:	00003517          	auipc	a0,0x3
ffffffffc0206172:	97a50513          	addi	a0,a0,-1670 # ffffffffc0208ae8 <default_pmm_manager+0x538>
ffffffffc0206176:	90cfa0ef          	jal	ra,ffffffffc0200282 <__warn>
ffffffffc020617a:	bfd9                	j	ffffffffc0206150 <wakeup_proc+0x24>
ffffffffc020617c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020617e:	cdefa0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc0206182:	6522                	ld	a0,8(sp)
ffffffffc0206184:	4405                	li	s0,1
ffffffffc0206186:	4118                	lw	a4,0(a0)
ffffffffc0206188:	bf75                	j	ffffffffc0206144 <wakeup_proc+0x18>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020618a:	00003697          	auipc	a3,0x3
ffffffffc020618e:	93e68693          	addi	a3,a3,-1730 # ffffffffc0208ac8 <default_pmm_manager+0x518>
ffffffffc0206192:	00001617          	auipc	a2,0x1
ffffffffc0206196:	c6e60613          	addi	a2,a2,-914 # ffffffffc0206e00 <commands+0x498>
ffffffffc020619a:	45a5                	li	a1,9
ffffffffc020619c:	00003517          	auipc	a0,0x3
ffffffffc02061a0:	94c50513          	addi	a0,a0,-1716 # ffffffffc0208ae8 <default_pmm_manager+0x538>
ffffffffc02061a4:	872fa0ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc02061a8 <schedule>:

void
schedule(void) {
ffffffffc02061a8:	1141                	addi	sp,sp,-16
ffffffffc02061aa:	e406                	sd	ra,8(sp)
ffffffffc02061ac:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02061ae:	100027f3          	csrr	a5,sstatus
ffffffffc02061b2:	8b89                	andi	a5,a5,2
ffffffffc02061b4:	4401                	li	s0,0
ffffffffc02061b6:	e3d1                	bnez	a5,ffffffffc020623a <schedule+0x92>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02061b8:	000a6797          	auipc	a5,0xa6
ffffffffc02061bc:	23878793          	addi	a5,a5,568 # ffffffffc02ac3f0 <current>
ffffffffc02061c0:	0007b883          	ld	a7,0(a5)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02061c4:	000a6797          	auipc	a5,0xa6
ffffffffc02061c8:	23478793          	addi	a5,a5,564 # ffffffffc02ac3f8 <idleproc>
ffffffffc02061cc:	6388                	ld	a0,0(a5)
        current->need_resched = 0;
ffffffffc02061ce:	0008bc23          	sd	zero,24(a7) # 2018 <_binary_obj___user_faultread_out_size-0x7558>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02061d2:	04a88e63          	beq	a7,a0,ffffffffc020622e <schedule+0x86>
ffffffffc02061d6:	0c888693          	addi	a3,a7,200
ffffffffc02061da:	000a6617          	auipc	a2,0xa6
ffffffffc02061de:	35660613          	addi	a2,a2,854 # ffffffffc02ac530 <proc_list>
        le = last;
ffffffffc02061e2:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02061e4:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02061e6:	4809                	li	a6,2
    return listelm->next;
ffffffffc02061e8:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02061ea:	00c78863          	beq	a5,a2,ffffffffc02061fa <schedule+0x52>
                if (next->state == PROC_RUNNABLE) {
ffffffffc02061ee:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02061f2:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc02061f6:	01070463          	beq	a4,a6,ffffffffc02061fe <schedule+0x56>
                    break;
                }
            }
        } while (le != last);
ffffffffc02061fa:	fef697e3          	bne	a3,a5,ffffffffc02061e8 <schedule+0x40>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02061fe:	c589                	beqz	a1,ffffffffc0206208 <schedule+0x60>
ffffffffc0206200:	4198                	lw	a4,0(a1)
ffffffffc0206202:	4789                	li	a5,2
ffffffffc0206204:	00f70e63          	beq	a4,a5,ffffffffc0206220 <schedule+0x78>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0206208:	451c                	lw	a5,8(a0)
ffffffffc020620a:	2785                	addiw	a5,a5,1
ffffffffc020620c:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc020620e:	00a88463          	beq	a7,a0,ffffffffc0206216 <schedule+0x6e>
            proc_run(next);
ffffffffc0206212:	f0bfe0ef          	jal	ra,ffffffffc020511c <proc_run>
    if (flag) {
ffffffffc0206216:	e419                	bnez	s0,ffffffffc0206224 <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206218:	60a2                	ld	ra,8(sp)
ffffffffc020621a:	6402                	ld	s0,0(sp)
ffffffffc020621c:	0141                	addi	sp,sp,16
ffffffffc020621e:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206220:	852e                	mv	a0,a1
ffffffffc0206222:	b7dd                	j	ffffffffc0206208 <schedule+0x60>
}
ffffffffc0206224:	6402                	ld	s0,0(sp)
ffffffffc0206226:	60a2                	ld	ra,8(sp)
ffffffffc0206228:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020622a:	c2cfa06f          	j	ffffffffc0200656 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020622e:	000a6617          	auipc	a2,0xa6
ffffffffc0206232:	30260613          	addi	a2,a2,770 # ffffffffc02ac530 <proc_list>
ffffffffc0206236:	86b2                	mv	a3,a2
ffffffffc0206238:	b76d                	j	ffffffffc02061e2 <schedule+0x3a>
        intr_disable();
ffffffffc020623a:	c22fa0ef          	jal	ra,ffffffffc020065c <intr_disable>
        return 1;
ffffffffc020623e:	4405                	li	s0,1
ffffffffc0206240:	bfa5                	j	ffffffffc02061b8 <schedule+0x10>

ffffffffc0206242 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0206242:	000a6797          	auipc	a5,0xa6
ffffffffc0206246:	1ae78793          	addi	a5,a5,430 # ffffffffc02ac3f0 <current>
ffffffffc020624a:	639c                	ld	a5,0(a5)
}
ffffffffc020624c:	43c8                	lw	a0,4(a5)
ffffffffc020624e:	8082                	ret

ffffffffc0206250 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0206250:	4501                	li	a0,0
ffffffffc0206252:	8082                	ret

ffffffffc0206254 <sys_putc>:
    cputchar(c);
ffffffffc0206254:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0206256:	1141                	addi	sp,sp,-16
ffffffffc0206258:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020625a:	eabf90ef          	jal	ra,ffffffffc0200104 <cputchar>
}
ffffffffc020625e:	60a2                	ld	ra,8(sp)
ffffffffc0206260:	4501                	li	a0,0
ffffffffc0206262:	0141                	addi	sp,sp,16
ffffffffc0206264:	8082                	ret

ffffffffc0206266 <sys_kill>:
    return do_kill(pid);
ffffffffc0206266:	4108                	lw	a0,0(a0)
ffffffffc0206268:	d17ff06f          	j	ffffffffc0205f7e <do_kill>

ffffffffc020626c <sys_yield>:
    return do_yield();
ffffffffc020626c:	cc1ff06f          	j	ffffffffc0205f2c <do_yield>

ffffffffc0206270 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0206270:	6d14                	ld	a3,24(a0)
ffffffffc0206272:	6910                	ld	a2,16(a0)
ffffffffc0206274:	650c                	ld	a1,8(a0)
ffffffffc0206276:	6108                	ld	a0,0(a0)
ffffffffc0206278:	fb6ff06f          	j	ffffffffc0205a2e <do_execve>

ffffffffc020627c <sys_wait>:
    return do_wait(pid, store);
ffffffffc020627c:	650c                	ld	a1,8(a0)
ffffffffc020627e:	4108                	lw	a0,0(a0)
ffffffffc0206280:	cbfff06f          	j	ffffffffc0205f3e <do_wait>

ffffffffc0206284 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0206284:	000a6797          	auipc	a5,0xa6
ffffffffc0206288:	16c78793          	addi	a5,a5,364 # ffffffffc02ac3f0 <current>
ffffffffc020628c:	639c                	ld	a5,0(a5)
    return do_fork(0, stack, tf);
ffffffffc020628e:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc0206290:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0206292:	6a0c                	ld	a1,16(a2)
ffffffffc0206294:	f51fe06f          	j	ffffffffc02051e4 <do_fork>

ffffffffc0206298 <sys_exit>:
    return do_exit(error_code);
ffffffffc0206298:	4108                	lw	a0,0(a0)
ffffffffc020629a:	b76ff06f          	j	ffffffffc0205610 <do_exit>

ffffffffc020629e <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020629e:	715d                	addi	sp,sp,-80
ffffffffc02062a0:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02062a2:	000a6497          	auipc	s1,0xa6
ffffffffc02062a6:	14e48493          	addi	s1,s1,334 # ffffffffc02ac3f0 <current>
ffffffffc02062aa:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02062ac:	e0a2                	sd	s0,64(sp)
ffffffffc02062ae:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02062b0:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02062b2:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02062b4:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02062b6:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02062ba:	0327ee63          	bltu	a5,s2,ffffffffc02062f6 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02062be:	00391713          	slli	a4,s2,0x3
ffffffffc02062c2:	00003797          	auipc	a5,0x3
ffffffffc02062c6:	8a678793          	addi	a5,a5,-1882 # ffffffffc0208b68 <syscalls>
ffffffffc02062ca:	97ba                	add	a5,a5,a4
ffffffffc02062cc:	639c                	ld	a5,0(a5)
ffffffffc02062ce:	c785                	beqz	a5,ffffffffc02062f6 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02062d0:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02062d2:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02062d4:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02062d6:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02062d8:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02062da:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02062dc:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02062de:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02062e0:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02062e2:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02062e4:	0028                	addi	a0,sp,8
ffffffffc02062e6:	9782                	jalr	a5
ffffffffc02062e8:	e828                	sd	a0,80(s0)
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02062ea:	60a6                	ld	ra,72(sp)
ffffffffc02062ec:	6406                	ld	s0,64(sp)
ffffffffc02062ee:	74e2                	ld	s1,56(sp)
ffffffffc02062f0:	7942                	ld	s2,48(sp)
ffffffffc02062f2:	6161                	addi	sp,sp,80
ffffffffc02062f4:	8082                	ret
    print_trapframe(tf);
ffffffffc02062f6:	8522                	mv	a0,s0
ffffffffc02062f8:	d52fa0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02062fc:	609c                	ld	a5,0(s1)
ffffffffc02062fe:	86ca                	mv	a3,s2
ffffffffc0206300:	00003617          	auipc	a2,0x3
ffffffffc0206304:	82060613          	addi	a2,a2,-2016 # ffffffffc0208b20 <default_pmm_manager+0x570>
ffffffffc0206308:	43d8                	lw	a4,4(a5)
ffffffffc020630a:	06300593          	li	a1,99
ffffffffc020630e:	0b478793          	addi	a5,a5,180
ffffffffc0206312:	00003517          	auipc	a0,0x3
ffffffffc0206316:	83e50513          	addi	a0,a0,-1986 # ffffffffc0208b50 <default_pmm_manager+0x5a0>
ffffffffc020631a:	efdf90ef          	jal	ra,ffffffffc0200216 <__panic>

ffffffffc020631e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020631e:	00054783          	lbu	a5,0(a0)
ffffffffc0206322:	cb91                	beqz	a5,ffffffffc0206336 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0206324:	4781                	li	a5,0
        cnt ++;
ffffffffc0206326:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0206328:	00f50733          	add	a4,a0,a5
ffffffffc020632c:	00074703          	lbu	a4,0(a4)
ffffffffc0206330:	fb7d                	bnez	a4,ffffffffc0206326 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0206332:	853e                	mv	a0,a5
ffffffffc0206334:	8082                	ret
    size_t cnt = 0;
ffffffffc0206336:	4781                	li	a5,0
}
ffffffffc0206338:	853e                	mv	a0,a5
ffffffffc020633a:	8082                	ret

ffffffffc020633c <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc020633c:	c185                	beqz	a1,ffffffffc020635c <strnlen+0x20>
ffffffffc020633e:	00054783          	lbu	a5,0(a0)
ffffffffc0206342:	cf89                	beqz	a5,ffffffffc020635c <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0206344:	4781                	li	a5,0
ffffffffc0206346:	a021                	j	ffffffffc020634e <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206348:	00074703          	lbu	a4,0(a4)
ffffffffc020634c:	c711                	beqz	a4,ffffffffc0206358 <strnlen+0x1c>
        cnt ++;
ffffffffc020634e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206350:	00f50733          	add	a4,a0,a5
ffffffffc0206354:	fef59ae3          	bne	a1,a5,ffffffffc0206348 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0206358:	853e                	mv	a0,a5
ffffffffc020635a:	8082                	ret
    size_t cnt = 0;
ffffffffc020635c:	4781                	li	a5,0
}
ffffffffc020635e:	853e                	mv	a0,a5
ffffffffc0206360:	8082                	ret

ffffffffc0206362 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0206362:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0206364:	0585                	addi	a1,a1,1
ffffffffc0206366:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020636a:	0785                	addi	a5,a5,1
ffffffffc020636c:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0206370:	fb75                	bnez	a4,ffffffffc0206364 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0206372:	8082                	ret

ffffffffc0206374 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206374:	00054783          	lbu	a5,0(a0)
ffffffffc0206378:	0005c703          	lbu	a4,0(a1)
ffffffffc020637c:	cb91                	beqz	a5,ffffffffc0206390 <strcmp+0x1c>
ffffffffc020637e:	00e79c63          	bne	a5,a4,ffffffffc0206396 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0206382:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206384:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0206388:	0585                	addi	a1,a1,1
ffffffffc020638a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020638e:	fbe5                	bnez	a5,ffffffffc020637e <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206390:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0206392:	9d19                	subw	a0,a0,a4
ffffffffc0206394:	8082                	ret
ffffffffc0206396:	0007851b          	sext.w	a0,a5
ffffffffc020639a:	9d19                	subw	a0,a0,a4
ffffffffc020639c:	8082                	ret

ffffffffc020639e <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020639e:	00054783          	lbu	a5,0(a0)
ffffffffc02063a2:	cb91                	beqz	a5,ffffffffc02063b6 <strchr+0x18>
        if (*s == c) {
ffffffffc02063a4:	00b79563          	bne	a5,a1,ffffffffc02063ae <strchr+0x10>
ffffffffc02063a8:	a809                	j	ffffffffc02063ba <strchr+0x1c>
ffffffffc02063aa:	00b78763          	beq	a5,a1,ffffffffc02063b8 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc02063ae:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02063b0:	00054783          	lbu	a5,0(a0)
ffffffffc02063b4:	fbfd                	bnez	a5,ffffffffc02063aa <strchr+0xc>
    }
    return NULL;
ffffffffc02063b6:	4501                	li	a0,0
}
ffffffffc02063b8:	8082                	ret
ffffffffc02063ba:	8082                	ret

ffffffffc02063bc <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02063bc:	ca01                	beqz	a2,ffffffffc02063cc <memset+0x10>
ffffffffc02063be:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02063c0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02063c2:	0785                	addi	a5,a5,1
ffffffffc02063c4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02063c8:	fec79de3          	bne	a5,a2,ffffffffc02063c2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02063cc:	8082                	ret

ffffffffc02063ce <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02063ce:	ca19                	beqz	a2,ffffffffc02063e4 <memcpy+0x16>
ffffffffc02063d0:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02063d2:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02063d4:	0585                	addi	a1,a1,1
ffffffffc02063d6:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02063da:	0785                	addi	a5,a5,1
ffffffffc02063dc:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02063e0:	fec59ae3          	bne	a1,a2,ffffffffc02063d4 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02063e4:	8082                	ret

ffffffffc02063e6 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02063e6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02063ea:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02063ec:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02063f0:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02063f2:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02063f6:	f022                	sd	s0,32(sp)
ffffffffc02063f8:	ec26                	sd	s1,24(sp)
ffffffffc02063fa:	e84a                	sd	s2,16(sp)
ffffffffc02063fc:	f406                	sd	ra,40(sp)
ffffffffc02063fe:	e44e                	sd	s3,8(sp)
ffffffffc0206400:	84aa                	mv	s1,a0
ffffffffc0206402:	892e                	mv	s2,a1
ffffffffc0206404:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206408:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc020640a:	03067e63          	bleu	a6,a2,ffffffffc0206446 <printnum+0x60>
ffffffffc020640e:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206410:	00805763          	blez	s0,ffffffffc020641e <printnum+0x38>
ffffffffc0206414:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206416:	85ca                	mv	a1,s2
ffffffffc0206418:	854e                	mv	a0,s3
ffffffffc020641a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020641c:	fc65                	bnez	s0,ffffffffc0206414 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020641e:	1a02                	slli	s4,s4,0x20
ffffffffc0206420:	020a5a13          	srli	s4,s4,0x20
ffffffffc0206424:	00003797          	auipc	a5,0x3
ffffffffc0206428:	a6478793          	addi	a5,a5,-1436 # ffffffffc0208e88 <error_string+0xc8>
ffffffffc020642c:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020642e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206430:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0206434:	70a2                	ld	ra,40(sp)
ffffffffc0206436:	69a2                	ld	s3,8(sp)
ffffffffc0206438:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020643a:	85ca                	mv	a1,s2
ffffffffc020643c:	8326                	mv	t1,s1
}
ffffffffc020643e:	6942                	ld	s2,16(sp)
ffffffffc0206440:	64e2                	ld	s1,24(sp)
ffffffffc0206442:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206444:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0206446:	03065633          	divu	a2,a2,a6
ffffffffc020644a:	8722                	mv	a4,s0
ffffffffc020644c:	f9bff0ef          	jal	ra,ffffffffc02063e6 <printnum>
ffffffffc0206450:	b7f9                	j	ffffffffc020641e <printnum+0x38>

ffffffffc0206452 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0206452:	7119                	addi	sp,sp,-128
ffffffffc0206454:	f4a6                	sd	s1,104(sp)
ffffffffc0206456:	f0ca                	sd	s2,96(sp)
ffffffffc0206458:	e8d2                	sd	s4,80(sp)
ffffffffc020645a:	e4d6                	sd	s5,72(sp)
ffffffffc020645c:	e0da                	sd	s6,64(sp)
ffffffffc020645e:	fc5e                	sd	s7,56(sp)
ffffffffc0206460:	f862                	sd	s8,48(sp)
ffffffffc0206462:	f06a                	sd	s10,32(sp)
ffffffffc0206464:	fc86                	sd	ra,120(sp)
ffffffffc0206466:	f8a2                	sd	s0,112(sp)
ffffffffc0206468:	ecce                	sd	s3,88(sp)
ffffffffc020646a:	f466                	sd	s9,40(sp)
ffffffffc020646c:	ec6e                	sd	s11,24(sp)
ffffffffc020646e:	892a                	mv	s2,a0
ffffffffc0206470:	84ae                	mv	s1,a1
ffffffffc0206472:	8d32                	mv	s10,a2
ffffffffc0206474:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0206476:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206478:	00002a17          	auipc	s4,0x2
ffffffffc020647c:	7f0a0a13          	addi	s4,s4,2032 # ffffffffc0208c68 <syscalls+0x100>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206480:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206484:	00003c17          	auipc	s8,0x3
ffffffffc0206488:	93cc0c13          	addi	s8,s8,-1732 # ffffffffc0208dc0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020648c:	000d4503          	lbu	a0,0(s10)
ffffffffc0206490:	02500793          	li	a5,37
ffffffffc0206494:	001d0413          	addi	s0,s10,1
ffffffffc0206498:	00f50e63          	beq	a0,a5,ffffffffc02064b4 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc020649c:	c521                	beqz	a0,ffffffffc02064e4 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020649e:	02500993          	li	s3,37
ffffffffc02064a2:	a011                	j	ffffffffc02064a6 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02064a4:	c121                	beqz	a0,ffffffffc02064e4 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02064a6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02064a8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02064aa:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02064ac:	fff44503          	lbu	a0,-1(s0)
ffffffffc02064b0:	ff351ae3          	bne	a0,s3,ffffffffc02064a4 <vprintfmt+0x52>
ffffffffc02064b4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02064b8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02064bc:	4981                	li	s3,0
ffffffffc02064be:	4801                	li	a6,0
        width = precision = -1;
ffffffffc02064c0:	5cfd                	li	s9,-1
ffffffffc02064c2:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02064c4:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc02064c8:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02064ca:	fdd6069b          	addiw	a3,a2,-35
ffffffffc02064ce:	0ff6f693          	andi	a3,a3,255
ffffffffc02064d2:	00140d13          	addi	s10,s0,1
ffffffffc02064d6:	20d5e563          	bltu	a1,a3,ffffffffc02066e0 <vprintfmt+0x28e>
ffffffffc02064da:	068a                	slli	a3,a3,0x2
ffffffffc02064dc:	96d2                	add	a3,a3,s4
ffffffffc02064de:	4294                	lw	a3,0(a3)
ffffffffc02064e0:	96d2                	add	a3,a3,s4
ffffffffc02064e2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02064e4:	70e6                	ld	ra,120(sp)
ffffffffc02064e6:	7446                	ld	s0,112(sp)
ffffffffc02064e8:	74a6                	ld	s1,104(sp)
ffffffffc02064ea:	7906                	ld	s2,96(sp)
ffffffffc02064ec:	69e6                	ld	s3,88(sp)
ffffffffc02064ee:	6a46                	ld	s4,80(sp)
ffffffffc02064f0:	6aa6                	ld	s5,72(sp)
ffffffffc02064f2:	6b06                	ld	s6,64(sp)
ffffffffc02064f4:	7be2                	ld	s7,56(sp)
ffffffffc02064f6:	7c42                	ld	s8,48(sp)
ffffffffc02064f8:	7ca2                	ld	s9,40(sp)
ffffffffc02064fa:	7d02                	ld	s10,32(sp)
ffffffffc02064fc:	6de2                	ld	s11,24(sp)
ffffffffc02064fe:	6109                	addi	sp,sp,128
ffffffffc0206500:	8082                	ret
    if (lflag >= 2) {
ffffffffc0206502:	4705                	li	a4,1
ffffffffc0206504:	008a8593          	addi	a1,s5,8
ffffffffc0206508:	01074463          	blt	a4,a6,ffffffffc0206510 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc020650c:	26080363          	beqz	a6,ffffffffc0206772 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0206510:	000ab603          	ld	a2,0(s5)
ffffffffc0206514:	46c1                	li	a3,16
ffffffffc0206516:	8aae                	mv	s5,a1
ffffffffc0206518:	a06d                	j	ffffffffc02065c2 <vprintfmt+0x170>
            goto reswitch;
ffffffffc020651a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020651e:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206520:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206522:	b765                	j	ffffffffc02064ca <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0206524:	000aa503          	lw	a0,0(s5)
ffffffffc0206528:	85a6                	mv	a1,s1
ffffffffc020652a:	0aa1                	addi	s5,s5,8
ffffffffc020652c:	9902                	jalr	s2
            break;
ffffffffc020652e:	bfb9                	j	ffffffffc020648c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0206530:	4705                	li	a4,1
ffffffffc0206532:	008a8993          	addi	s3,s5,8
ffffffffc0206536:	01074463          	blt	a4,a6,ffffffffc020653e <vprintfmt+0xec>
    else if (lflag) {
ffffffffc020653a:	22080463          	beqz	a6,ffffffffc0206762 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020653e:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0206542:	24044463          	bltz	s0,ffffffffc020678a <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0206546:	8622                	mv	a2,s0
ffffffffc0206548:	8ace                	mv	s5,s3
ffffffffc020654a:	46a9                	li	a3,10
ffffffffc020654c:	a89d                	j	ffffffffc02065c2 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc020654e:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206552:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0206554:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0206556:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020655a:	8fb5                	xor	a5,a5,a3
ffffffffc020655c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206560:	1ad74363          	blt	a4,a3,ffffffffc0206706 <vprintfmt+0x2b4>
ffffffffc0206564:	00369793          	slli	a5,a3,0x3
ffffffffc0206568:	97e2                	add	a5,a5,s8
ffffffffc020656a:	639c                	ld	a5,0(a5)
ffffffffc020656c:	18078d63          	beqz	a5,ffffffffc0206706 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0206570:	86be                	mv	a3,a5
ffffffffc0206572:	00000617          	auipc	a2,0x0
ffffffffc0206576:	2ae60613          	addi	a2,a2,686 # ffffffffc0206820 <etext+0x2a>
ffffffffc020657a:	85a6                	mv	a1,s1
ffffffffc020657c:	854a                	mv	a0,s2
ffffffffc020657e:	240000ef          	jal	ra,ffffffffc02067be <printfmt>
ffffffffc0206582:	b729                	j	ffffffffc020648c <vprintfmt+0x3a>
            lflag ++;
ffffffffc0206584:	00144603          	lbu	a2,1(s0)
ffffffffc0206588:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020658a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020658c:	bf3d                	j	ffffffffc02064ca <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc020658e:	4705                	li	a4,1
ffffffffc0206590:	008a8593          	addi	a1,s5,8
ffffffffc0206594:	01074463          	blt	a4,a6,ffffffffc020659c <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0206598:	1e080263          	beqz	a6,ffffffffc020677c <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc020659c:	000ab603          	ld	a2,0(s5)
ffffffffc02065a0:	46a1                	li	a3,8
ffffffffc02065a2:	8aae                	mv	s5,a1
ffffffffc02065a4:	a839                	j	ffffffffc02065c2 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc02065a6:	03000513          	li	a0,48
ffffffffc02065aa:	85a6                	mv	a1,s1
ffffffffc02065ac:	e03e                	sd	a5,0(sp)
ffffffffc02065ae:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02065b0:	85a6                	mv	a1,s1
ffffffffc02065b2:	07800513          	li	a0,120
ffffffffc02065b6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02065b8:	0aa1                	addi	s5,s5,8
ffffffffc02065ba:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc02065be:	6782                	ld	a5,0(sp)
ffffffffc02065c0:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02065c2:	876e                	mv	a4,s11
ffffffffc02065c4:	85a6                	mv	a1,s1
ffffffffc02065c6:	854a                	mv	a0,s2
ffffffffc02065c8:	e1fff0ef          	jal	ra,ffffffffc02063e6 <printnum>
            break;
ffffffffc02065cc:	b5c1                	j	ffffffffc020648c <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02065ce:	000ab603          	ld	a2,0(s5)
ffffffffc02065d2:	0aa1                	addi	s5,s5,8
ffffffffc02065d4:	1c060663          	beqz	a2,ffffffffc02067a0 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc02065d8:	00160413          	addi	s0,a2,1
ffffffffc02065dc:	17b05c63          	blez	s11,ffffffffc0206754 <vprintfmt+0x302>
ffffffffc02065e0:	02d00593          	li	a1,45
ffffffffc02065e4:	14b79263          	bne	a5,a1,ffffffffc0206728 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02065e8:	00064783          	lbu	a5,0(a2)
ffffffffc02065ec:	0007851b          	sext.w	a0,a5
ffffffffc02065f0:	c905                	beqz	a0,ffffffffc0206620 <vprintfmt+0x1ce>
ffffffffc02065f2:	000cc563          	bltz	s9,ffffffffc02065fc <vprintfmt+0x1aa>
ffffffffc02065f6:	3cfd                	addiw	s9,s9,-1
ffffffffc02065f8:	036c8263          	beq	s9,s6,ffffffffc020661c <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc02065fc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02065fe:	18098463          	beqz	s3,ffffffffc0206786 <vprintfmt+0x334>
ffffffffc0206602:	3781                	addiw	a5,a5,-32
ffffffffc0206604:	18fbf163          	bleu	a5,s7,ffffffffc0206786 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc0206608:	03f00513          	li	a0,63
ffffffffc020660c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020660e:	0405                	addi	s0,s0,1
ffffffffc0206610:	fff44783          	lbu	a5,-1(s0)
ffffffffc0206614:	3dfd                	addiw	s11,s11,-1
ffffffffc0206616:	0007851b          	sext.w	a0,a5
ffffffffc020661a:	fd61                	bnez	a0,ffffffffc02065f2 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc020661c:	e7b058e3          	blez	s11,ffffffffc020648c <vprintfmt+0x3a>
ffffffffc0206620:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0206622:	85a6                	mv	a1,s1
ffffffffc0206624:	02000513          	li	a0,32
ffffffffc0206628:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020662a:	e60d81e3          	beqz	s11,ffffffffc020648c <vprintfmt+0x3a>
ffffffffc020662e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0206630:	85a6                	mv	a1,s1
ffffffffc0206632:	02000513          	li	a0,32
ffffffffc0206636:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206638:	fe0d94e3          	bnez	s11,ffffffffc0206620 <vprintfmt+0x1ce>
ffffffffc020663c:	bd81                	j	ffffffffc020648c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020663e:	4705                	li	a4,1
ffffffffc0206640:	008a8593          	addi	a1,s5,8
ffffffffc0206644:	01074463          	blt	a4,a6,ffffffffc020664c <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0206648:	12080063          	beqz	a6,ffffffffc0206768 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc020664c:	000ab603          	ld	a2,0(s5)
ffffffffc0206650:	46a9                	li	a3,10
ffffffffc0206652:	8aae                	mv	s5,a1
ffffffffc0206654:	b7bd                	j	ffffffffc02065c2 <vprintfmt+0x170>
ffffffffc0206656:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc020665a:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020665e:	846a                	mv	s0,s10
ffffffffc0206660:	b5ad                	j	ffffffffc02064ca <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0206662:	85a6                	mv	a1,s1
ffffffffc0206664:	02500513          	li	a0,37
ffffffffc0206668:	9902                	jalr	s2
            break;
ffffffffc020666a:	b50d                	j	ffffffffc020648c <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc020666c:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0206670:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0206674:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206676:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0206678:	e40dd9e3          	bgez	s11,ffffffffc02064ca <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc020667c:	8de6                	mv	s11,s9
ffffffffc020667e:	5cfd                	li	s9,-1
ffffffffc0206680:	b5a9                	j	ffffffffc02064ca <vprintfmt+0x78>
            goto reswitch;
ffffffffc0206682:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0206686:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020668a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020668c:	bd3d                	j	ffffffffc02064ca <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc020668e:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0206692:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206696:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0206698:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020669c:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02066a0:	fcd56ce3          	bltu	a0,a3,ffffffffc0206678 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc02066a4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02066a6:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02066aa:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02066ae:	0196873b          	addw	a4,a3,s9
ffffffffc02066b2:	0017171b          	slliw	a4,a4,0x1
ffffffffc02066b6:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02066ba:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02066be:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02066c2:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02066c6:	fcd57fe3          	bleu	a3,a0,ffffffffc02066a4 <vprintfmt+0x252>
ffffffffc02066ca:	b77d                	j	ffffffffc0206678 <vprintfmt+0x226>
            if (width < 0)
ffffffffc02066cc:	fffdc693          	not	a3,s11
ffffffffc02066d0:	96fd                	srai	a3,a3,0x3f
ffffffffc02066d2:	00ddfdb3          	and	s11,s11,a3
ffffffffc02066d6:	00144603          	lbu	a2,1(s0)
ffffffffc02066da:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02066dc:	846a                	mv	s0,s10
ffffffffc02066de:	b3f5                	j	ffffffffc02064ca <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc02066e0:	85a6                	mv	a1,s1
ffffffffc02066e2:	02500513          	li	a0,37
ffffffffc02066e6:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02066e8:	fff44703          	lbu	a4,-1(s0)
ffffffffc02066ec:	02500793          	li	a5,37
ffffffffc02066f0:	8d22                	mv	s10,s0
ffffffffc02066f2:	d8f70de3          	beq	a4,a5,ffffffffc020648c <vprintfmt+0x3a>
ffffffffc02066f6:	02500713          	li	a4,37
ffffffffc02066fa:	1d7d                	addi	s10,s10,-1
ffffffffc02066fc:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0206700:	fee79de3          	bne	a5,a4,ffffffffc02066fa <vprintfmt+0x2a8>
ffffffffc0206704:	b361                	j	ffffffffc020648c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0206706:	00003617          	auipc	a2,0x3
ffffffffc020670a:	86260613          	addi	a2,a2,-1950 # ffffffffc0208f68 <error_string+0x1a8>
ffffffffc020670e:	85a6                	mv	a1,s1
ffffffffc0206710:	854a                	mv	a0,s2
ffffffffc0206712:	0ac000ef          	jal	ra,ffffffffc02067be <printfmt>
ffffffffc0206716:	bb9d                	j	ffffffffc020648c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0206718:	00003617          	auipc	a2,0x3
ffffffffc020671c:	84860613          	addi	a2,a2,-1976 # ffffffffc0208f60 <error_string+0x1a0>
            if (width > 0 && padc != '-') {
ffffffffc0206720:	00003417          	auipc	s0,0x3
ffffffffc0206724:	84140413          	addi	s0,s0,-1983 # ffffffffc0208f61 <error_string+0x1a1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206728:	8532                	mv	a0,a2
ffffffffc020672a:	85e6                	mv	a1,s9
ffffffffc020672c:	e032                	sd	a2,0(sp)
ffffffffc020672e:	e43e                	sd	a5,8(sp)
ffffffffc0206730:	c0dff0ef          	jal	ra,ffffffffc020633c <strnlen>
ffffffffc0206734:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0206738:	6602                	ld	a2,0(sp)
ffffffffc020673a:	01b05d63          	blez	s11,ffffffffc0206754 <vprintfmt+0x302>
ffffffffc020673e:	67a2                	ld	a5,8(sp)
ffffffffc0206740:	2781                	sext.w	a5,a5
ffffffffc0206742:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0206744:	6522                	ld	a0,8(sp)
ffffffffc0206746:	85a6                	mv	a1,s1
ffffffffc0206748:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020674a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020674c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020674e:	6602                	ld	a2,0(sp)
ffffffffc0206750:	fe0d9ae3          	bnez	s11,ffffffffc0206744 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206754:	00064783          	lbu	a5,0(a2)
ffffffffc0206758:	0007851b          	sext.w	a0,a5
ffffffffc020675c:	e8051be3          	bnez	a0,ffffffffc02065f2 <vprintfmt+0x1a0>
ffffffffc0206760:	b335                	j	ffffffffc020648c <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0206762:	000aa403          	lw	s0,0(s5)
ffffffffc0206766:	bbf1                	j	ffffffffc0206542 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0206768:	000ae603          	lwu	a2,0(s5)
ffffffffc020676c:	46a9                	li	a3,10
ffffffffc020676e:	8aae                	mv	s5,a1
ffffffffc0206770:	bd89                	j	ffffffffc02065c2 <vprintfmt+0x170>
ffffffffc0206772:	000ae603          	lwu	a2,0(s5)
ffffffffc0206776:	46c1                	li	a3,16
ffffffffc0206778:	8aae                	mv	s5,a1
ffffffffc020677a:	b5a1                	j	ffffffffc02065c2 <vprintfmt+0x170>
ffffffffc020677c:	000ae603          	lwu	a2,0(s5)
ffffffffc0206780:	46a1                	li	a3,8
ffffffffc0206782:	8aae                	mv	s5,a1
ffffffffc0206784:	bd3d                	j	ffffffffc02065c2 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0206786:	9902                	jalr	s2
ffffffffc0206788:	b559                	j	ffffffffc020660e <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc020678a:	85a6                	mv	a1,s1
ffffffffc020678c:	02d00513          	li	a0,45
ffffffffc0206790:	e03e                	sd	a5,0(sp)
ffffffffc0206792:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0206794:	8ace                	mv	s5,s3
ffffffffc0206796:	40800633          	neg	a2,s0
ffffffffc020679a:	46a9                	li	a3,10
ffffffffc020679c:	6782                	ld	a5,0(sp)
ffffffffc020679e:	b515                	j	ffffffffc02065c2 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc02067a0:	01b05663          	blez	s11,ffffffffc02067ac <vprintfmt+0x35a>
ffffffffc02067a4:	02d00693          	li	a3,45
ffffffffc02067a8:	f6d798e3          	bne	a5,a3,ffffffffc0206718 <vprintfmt+0x2c6>
ffffffffc02067ac:	00002417          	auipc	s0,0x2
ffffffffc02067b0:	7b540413          	addi	s0,s0,1973 # ffffffffc0208f61 <error_string+0x1a1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02067b4:	02800513          	li	a0,40
ffffffffc02067b8:	02800793          	li	a5,40
ffffffffc02067bc:	bd1d                	j	ffffffffc02065f2 <vprintfmt+0x1a0>

ffffffffc02067be <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02067be:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02067c0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02067c4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02067c6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02067c8:	ec06                	sd	ra,24(sp)
ffffffffc02067ca:	f83a                	sd	a4,48(sp)
ffffffffc02067cc:	fc3e                	sd	a5,56(sp)
ffffffffc02067ce:	e0c2                	sd	a6,64(sp)
ffffffffc02067d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02067d2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02067d4:	c7fff0ef          	jal	ra,ffffffffc0206452 <vprintfmt>
}
ffffffffc02067d8:	60e2                	ld	ra,24(sp)
ffffffffc02067da:	6161                	addi	sp,sp,80
ffffffffc02067dc:	8082                	ret

ffffffffc02067de <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02067de:	9e3707b7          	lui	a5,0x9e370
ffffffffc02067e2:	2785                	addiw	a5,a5,1
ffffffffc02067e4:	02f5053b          	mulw	a0,a0,a5
    return (hash >> (32 - bits));
ffffffffc02067e8:	02000793          	li	a5,32
ffffffffc02067ec:	40b785bb          	subw	a1,a5,a1
}
ffffffffc02067f0:	00b5553b          	srlw	a0,a0,a1
ffffffffc02067f4:	8082                	ret
