#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- 进程/线程机制的设计与实现 -------------
（一个简化的 Linux 进程/线程机制）
简介:
  ucore 实现了一个简单的进程/线程机制。进程包含独立的内存空间、至少一个用于执行的线程、内核数据（用于管理）、
  处理器状态（用于上下文切换）、文件（实验六中会实现）等。ucore 需要高效地管理这些细节。在 ucore 中，线程
  只是进程的一种特殊形式（共享进程的内存）。
------------------------------
进程状态       :    含义                   -- 原因
    PROC_UNINIT     : 未初始化               -- 在 `alloc_proc` 中分配
    PROC_SLEEPING   : 睡眠状态               -- 在 `try_free_pages可能因为内存不足，进程进入睡眠等待资源。
                                              `, `do_wait`, `do_sleep` 中
    PROC_RUNNABLE   : 可运行（可能正在运行）  -- 在 `proc_init`初始化时将进程设置为可运行, 
                                             `wakeup_proc` 中唤醒某个睡眠中的进程，使其重新进入可运行状态。
    PROC_ZOMBIE     : 接近死亡状态           -- 在 `do_exit` 中

-----------------------------
进程状态的变化:

                                             RUNNING
  alloc_proc                                                
      +                                   +--<----<--+
      +                                   + `proc_run` +
      V                                   +-->---->--+    //如果进程需要等待资源（例如内存不足、I/O 等）
PROC_UNINIT -- `proc_init`/`wakeup_proc` --> PROC_RUNNABLE -- `try_free_pages`/`do_wait`/`do_sleep` --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- `do_exit` --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           ---------------------`wakeup_proc`-----------------------------------

-----------------------------
进程关系:
父进程:           `proc->parent`  （`proc` 是子进程）
子进程:           `proc->cptr`    （`proc` 是父进程）
较老的兄弟进程:    `proc->optr`    （`proc` 是较年轻的兄弟进程）
较年轻的兄弟进程:  `proc->yptr`    （`proc` 是较老的兄弟进程）

-----------------------------
与进程相关的系统调用:
- `SYS_exit`        : 进程退出                           --> 调用 `do_exit`
- `SYS_fork`        : 创建子进程，复制内存管理结构         --> 调用 `do_fork` -> `wakeup_proc`
- `SYS_wait`        : 等待进程                           --> 调用 `do_wait`
- `SYS_exec`        : 在 `fork` 之后，执行程序            --> 加载程序并刷新内存管理结构
- `SYS_clone`       : 创建子线程                         --> 调用 `do_fork` -> `wakeup_proc`
- `SYS_yield`       : 进程标记自身需要重新调度            --> `proc->need_sched=1`, 调度器将重新调度该进程
- `SYS_sleep`       : 进程睡眠                           --> 调用 `do_sleep`
- `SYS_kill`        : 杀死进程                           --> `do_kill` -> `proc->flags |= PF_EXITING`
                                                     --> `wakeup_proc` -> `do_wait` -> `do_exit`
- `SYS_getpid`      : 获取进程的 PID
*/

//所有进程的链表，用于管理进程集合
list_entry_t proc_list;

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// 基于进程 ID 的哈希表，用于快速查找进程
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc,指向空闲进程（idle 进程，当没有其他进程运行时由调度器选中）。
struct proc_struct *idleproc = NULL;
// init proc,指向初始进程（init 进程，是第一个被创建的用户进程）。
struct proc_struct *initproc = NULL;
// current proc,指向当前正在运行的进程。
struct proc_struct *current = NULL;
//当前系统中进程的总数量。
static int nr_process = 0;
//用于线程入口的函数
void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);//系统调用 fork 返回时的处理函数
void switch_to(struct context *from, struct context *to);
//上下文切换函数
// alloc_proc - 用于分配并初始化一个新的 proc_struct（进程结构）
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) { 
    //LAB4:EXERCISE1 YOUR CODE 2211392 郭笑语
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
        proc->state = PROC_UNINIT;//初始状态为未初始化
        proc->pid = -1;//pid为未赋值
        proc->runs = 0;//运行次数初始为 0
        proc->kstack = 0;//除了idleproc其他线程的内核栈都要后续分配
        proc->need_resched =0; // 不需要立即调度切换线程
        proc->parent = NULL;//没有父线程
        proc->mm = NULL;//未分配内存
        memset(&(proc->context), 0, sizeof(struct context));// 清空上下文
        proc->tf = NULL; //中断帧指针未分配
        proc->cr3 = boot_cr3;//内核线程的cr3为boot_cr3，即页目录为内核页目录表
        proc->flags = 0;// 进程标志位初始化为 0
        memset(proc->name, 0, PROC_NAME_LEN+1);// 进程名清空
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
       
    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
}

// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    //对trameframe， 也 就 是 我 们 程 序 的 一 些 上 下 文 进 行 一 些 初 始 化
    struct trapframe tf;//保存线程创建时的初始上下文
    memset(&tf, 0, sizeof(struct trapframe));//所有字段初始化为 0
    // 设 置 内 核 线 程 的 参 数 和 函 数 指 针
    tf.gpr.s0 = (uintptr_t)fn;// s0 寄 存 器 保 存 函 数 指 针
    tf.gpr.s1 = (uintptr_t)arg;// s1 寄 存 器 保 存 函 数 参 数
 // 设置 trapframe 中的 status 寄存器（SSTATUS）
// SSTATUS_SPP：设置为 Supervisor 模式，因为这是一个内核线程）
// SSTATUS_SPIE：（启用中断，保证线程可以处理中断）
// SSTATUS_SIE：（禁用当前线程运行时的中断，避免线程被中断）
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
   // 设置入口点（epc），表示线程启动时的程序计数器
// kernel_thread_entry 是线程的实际入口函数，trapentry.S 会用到这个地址 
    tf.epc = (uintptr_t)kernel_thread_entry;
// 使用 do_fork 创建一个新进程（内核线程）
    // clone_flags | CLONE_VM：允许线程与父进程共享虚拟内存空间
    // 第三个参数 &tf：将初始化好的 trapframe 传递给 do_fork，以设置新进程的上下文
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE);
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page);
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    assert(current->mm == NULL);
    /* do nothing in this project */
    return 0;
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
//用于设置子进程的上下文和陷阱帧（trapframe），确保子进程能够正确从父进程的状态恢复并运行。
//uintptr_t esp栈指针，指定子进程的栈顶地址
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
//设置子进程的 trapframe 地址,KSTACKSIZE：内核栈的大小。子进程放在内核栈顶
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    //复制父进程的 trapframe 到子进程
    *(proc->tf) = *tf;

    // Set a0 to 0 so a child process knows it's just forked
    proc->tf->gpr.a0 = 0;//a0=0说明为子进程
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
//ra设置为forkret的入口
    proc->context.ra = (uintptr_t)forkret;
//设置子进程的栈指针为子进程trapframe 地址
    proc->context.sp = (uintptr_t)(proc->tf);
}

/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;//表示没有可用的进程控制块
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {//检查当前进程数量是否达到上限 MAX_PROCESS
        goto fork_out;
    }
    ret = -E_NO_MEM;//初始化返回值为内存不足错误(内存分配失败)
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

//    1. 调用 alloc_proc 函数，为新进程分配一个 proc_struct。
//    2. 调用 setup_kstack 函数，为子进程分配一个内核栈。
//    3. 调用 copy_mm 函数，根据 clone_flag 的值，复制或共享父进程的内存管理结构。
//    4. 调用 copy_thread 函数，设置子进程的 trapframe 和上下文信息（context）。
//    5. 将子进程的 proc_struct 插入到全局的 hash_list 和 proc_list 中。
//    6. 调用 wakeup_proc 函数，将子进程的状态设置为 PROC_RUNNABLE（可运行状态）。
//    7. 使用子进程的 pid 设置返回值 ret。
// 1.调用alloc_proc分配一个proc_struct
    proc = alloc_proc();
    if (proc == NULL)// 如果分配失败
        goto fork_out; // 返回内存不足错误
    proc->parent = current; // 设置子进程的父进程为当前进程
    // 2.调用setup_kstack为子进程分配一个内核栈
    if (setup_kstack(proc) != 0) 
        goto bad_fork_cleanup_proc; // 如果分配失败，清理已分配的 proc_struct

     // 3. 调用 copy_mm 函数，复制或共享父进程的内存管理信息
    if (copy_mm(clone_flags, proc) != 0) 
        goto bad_fork_cleanup_kstack; // 如果失败，清理已分配的内核栈  

    // 4. 调用copy_thread()函数复制父进程的中断帧和上下文信息到子进程
    copy_thread(proc, stack, tf);

    // 5. 将子进程的proc_struct插入hash_list && proc_list
    bool intr_flag;
    local_intr_save(intr_flag); // 关闭中断，保证操作的原子性
    
    proc->pid = get_pid(); // 为子进程分配唯一的 PID
    hash_proc(proc); //将子进程插入全局哈希表建立映射
    list_add(&proc_list, &(proc->list_link));// 将子进程插入全局链表
    nr_process ++; // 增加全局进程计数
    
    local_intr_restore(intr_flag);// 恢复中断

    // 6.调用wakeup_proc使新子进程RUNNABLE
    wakeup_proc(proc);

    // 7.使用子进程pid设置获取值
    ret = proc->pid;
    

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int
do_exit(int error_code) {
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char *)arg);
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
    return 0;
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
    int i;
// 初始化全局进程链表
    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);// 初始化哈希链表，每个桶都是一个链表节点
    }
// 调用 alloc_proc 函数分配第一个内核线程 idleproc
    if ((idleproc = alloc_proc()) == NULL) {
        // 如果分配失败，系统无法正常运行，直接报错并终止
        panic("cannot alloc idleproc.\n");
    }
// 检查 alloc_proc 函数是否正确初始化了 idleproc 的 context
  // 分配一个 context 大小的内存块
    int *context_mem = (int*) kmalloc(sizeof(struct context));
    memset(context_mem, 0, sizeof(struct context)); // 将其清零
    // 比较 context 内容是否一致
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
// 检查 alloc_proc 函数是否正确初始化了 idleproc 的 name
   // 分配一个存储进程名的内存块
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
    //将其清零
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    // 比较 name 内容是否一致
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
    // 检查 idleproc 的所有字段是否按照期望初始化
    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){ // 如果检查全部通过，说明 alloc_proc 实现正确，打印调试信息
        cprintf("alloc_proc() correct!\n");

    }
    // 设置 idleproc 的属性
    idleproc->pid = 0; // 设置进程 ID 为 0
    idleproc->state = PROC_RUNNABLE; // 设置进程状态为可运行
    idleproc->kstack = (uintptr_t)bootstack;// 设置内核栈指针为全局的 bootstack
    idleproc->need_resched = 1;// 标记需要调度
    set_proc_name(idleproc, "idle");// 设置进程名称为 "idle"
    nr_process ++;// 增加全局进程计数

    current = idleproc; // 设置当前进程为 idleproc
 // 创建第二个内核线程 init_main，并传递参数
    int pid = kernel_thread(init_main, "Hello world!!", 0);
    if (pid <= 0) {// 如果创建失败，报错并终止
        panic("create init_main failed.\n");
    }
// 通过返回的 pid 查找并初始化 initproc
    initproc = find_proc(pid); // 根据 pid 查找新创建的 initproc
    set_proc_name(initproc, "init");// 设置进程名称为 "init"
 // 确保 idleproc 和 initproc 正常创建
    // 检查 idleproc 是否正确初始化
    assert(idleproc != NULL && idleproc->pid == 0);
    // 检查 initproc 是否正确初始化
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
//判断是否有其他更高优先级的进程需要运行，如果是，则执行调度。
void
cpu_idle(void) {
    while (1) {//need_resched 为 true 时表示需要进行上下文切换
        if (current->need_resched) {
            //current,全局变量，指向当前正在运行的进程（此处为 idleproc）。
            //调度器
            schedule();
        }
    }
}

