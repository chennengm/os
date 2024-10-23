# 操作系统实验报告

# Lab2 物理内存和页表

---

安怡然 2213393  翟乐炜2213469 郭笑语 2211392  

# 1. 实验目的

- 理解页表的建立和使用方法
- 理解物理内存的管理方法
- 理解页面分配算法

# 2. 实验内容

**2.1 练习 1：理解 first-fit 连续物理内存分配算法（思考题）**

> first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请
大家仔细阅读实验手册的教程并结合 kern/mm/default_pmm.c 中的相关代码，认真分析 default_init，default_init_memmap，default_alloc_pages，default_free_pages 等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。请在实验报告中简要说明你的设计实现过程。请回答如下问题：
• 你的 first fit 算法是否有进一步的改进空间？
> 

在首次适配算法中，内存分配器维护一个空闲块的列表（称为空闲列表），当收到内存请求时，会扫描列表以找到第一个足够大的块来满足请求。如果选中的块远大于请求的大小，通常会将其拆分，剩余部分作为另一个空闲块加入列表。

1. default_init()用于初始化内存管理结构体
    
    调用 list_init(&free_list) 初始化空闲列表。
    并设置 nr_free = 0，表示开始时没有空闲页块。
    
    - 这个函数在系统启动时调用，一次性初始化物理内存管理器。
2. default_init_memmap用于初始化一段物理内存块，添加到空闲链表中。
    
    循环遍历从 base 开始的 n 个页块，设置页块的 flags 和 property=0，并设置引用计数 ref 为 0
    
    标记第一页块属性，将 base->property 设置为 n，表示这段内存包含 n 个页，并将首块base的 PG_property 设置为有效。将当前free页面+n更新。
    
    将初始化的内存块添加到空闲链表中，如果空闲列表为空，直接插入到 free_list 中。如果不为空，则遍历链表找到合适的位置（找到base 的物理地址<page 的物理地址，然后base前插，保证地址由低到高）。
    
    - 在系统启动时，内核需要知道哪些物理页面是可用的，default_init_memmap函数被用于初始化这些可用页面，并将其添加到空闲链表 free_list 中
3. default_alloc_pages是内存分配函数，使用 First-Fit 策略在空闲列表中查找一个足够大的块。
    - 当收到内存请求时，会遍历空闲列表以找到第一个足够大的块（页数大于等于 n）来满足请求，如果找到就将其指针存储到page中。然后将page从空闲列表中删除，如果page的大小大于请求n的大小，将剩余的部分作为另一个空闲块加入空闲列表。
4. default_free_pages是内存释放函数，用于释放占用的页块，并将其加入到空闲列表中，同时合并相邻的空闲块。
    
    遍历释放的页块，清除其 flags 和引用计数，并设置页的 property=0。
    
    按地址顺序将新的页块插入空闲列表，以保持链表的有序性。
    
    在插入后，检查 base 的前一个和后一个页块，如果它们也是空闲的，将其与 base 合并，并更新合并后的页块属性。
    
- 缺点
    
    每次进行内存分配时，都需要从空闲链表中查找第一个满足大小要求的块。这种线性查找的时间复杂度为 O(n)，其中 n 是链表中空闲块的数量。
    随着系统运行时间的增长，空闲块的数量会不断增多，导致每次分配内存的速度变得越来越慢。这种线性查找在内存负载较重的情况下可能会成为性能瓶颈。
    
    - 改进方法
        
        考虑使用最小堆来存储空闲块，按照内存块大小进行排序。每次请求内存时，从堆顶元素向下依次比较，这样就能在对数的复杂度下快速找到最合适的内存块。
        

**2.2 练习 2：实现 Best-Fit 连续物理内存分配算法（需要编程）**

> 在完成练习一后，参考 kern/mm/default_pmm.c 对 First Fit 算法的实现，编程实现 Best Fit 页面分配算法，算
法的时空复杂度不做要求，能通过测试即可。请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
• 你的 Best-Fit 算法是否有进一步的改进空间？
> 

**Best-Fit 算法相比于 first-fit最大的不同就是， first-fit算法需要找出第一个足够大小的块，而best-fit算法要在空闲链表中做一个遍历，找到与所需大小最接近的空闲堆块进行使用。**

执行内存分配的函数是与firstfit最大的不同，原来只需要遍历到第一个比n大的块即可，现在引入**min_size这一变量，**将其初始为当前空闲的块+1，不止需要比n大，还需要比minsize小，然后将minsize赋值为当前块的小值，同时将当前的小块给page。

```jsx
static struct Page *
best_fit_alloc_pages(size_t n) {
assert(n > 0);
if (n > nr_free) {
return NULL;
}
struct Page *page = NULL;
list_entry_t *le = &free_list;
**size_t min_size = nr_free + 1;**
/*LAB2 EXERCISE 2: YOUR CODE 2211392郭笑语*/
// 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
// 遍历空闲链表，查找满足需求的空闲页框
// 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
while ((le = list_next(le)) != &free_list) {
struct Page *p = le2page(le, page_link);
if (p->property >= n&&p->property<min_size) {
min_size=p->property;
page= p;
}
}
//遍历完空链表，page 指向最佳匹配，如果没有找到匹配，page仍为NULL
if (page != NULL) {
list_entry_t* prev = list_prev(&(page->page_link));
list_del(&(page->page_link));
if (page->property > n) {
struct Page *p = page + n;
p->property = page->property - n;
SetPageProperty(p);
list_add(prev, &(p->page_link));
}
nr_free -= n;
ClearPageProperty(page);}
return page;}
```

- 代码是如何对物理内存进行分配和释放的？

代码通过一系列函数来完成物理内存的分配和释放，主要包括 best_fit_init()、best_fit_init_memmap()、best_fit_alloc_pages() 和 best_fit_free_pages() 等函数。这些函数相互配合，共同实现了内存页的管理。

在系统启动时，首先调用 best_fit_init() 初始化空闲页块链表 free_list，并将空闲页数量 nr_free 设置为 0，确保内存管理器处于初始状态。之后，通过 best_fit_init_memmap() 函数初始化具体的内存区域，将传入的物理页范围标记为空闲，并按地址顺序插入到 free_list 链表中，形成一个按地址升序排列的空闲内存页块列表。对于每个页块，函数会将其 property 设置为块的大小，标记该页为可用状态，并将这些空闲页链接到链表中。这一步是为了确保内存管理器具有对物理内存的初始描述，以便后续进行分配和释放操作。

当需要分配内存时，best_fit_alloc_pages() 会被调用。它通过遍历 free_list 链表，查找能够满足请求的最小空闲块，以尽可能减少内存碎片。这种最佳匹配策略有助于找到最适合当前请求的块，并保留较大的空闲块以供将来使用。在找到合适的空闲块后，函数会将其从空闲链表中删除，并根据请求的大小进行分割。如果剩余部分的大小大于 0，则将剩余部分重新插入到空闲链表中，并更新其 property 值。最后，函数返回分配的页块地址，并更新全局的空闲页数量 nr_free。

在内存释放时，调用 best_fit_free_pages() 函数。该函数接受一个页块及其大小作为参数，将其插入到空闲链表中，同时尝试与相邻的空闲块合并，以减少内存碎片。在插入链表时，best_fit_free_pages() 会按照地址顺序将新释放的块插入到合适的位置，以保持链表的有序性。之后，函数会检查新插入的块是否与前后相邻的块可以合并，如果可以合并，则更新相邻块的 property 属性，并从链表中删除被合并的块。这种合并操作有助于减小内存碎片的数量，提高内存分配的效率。

通过这种方式，best_fit_alloc_pages() 和 best_fit_free_pages() 实现了对物理内存的动态分配与释放。

- 缺点
    
    每次进行内存分配时，都需要遍历完空闲链表中的所有块。这种线性查找的时间复杂度为 O(n)，其中 n 是链表中空闲块的数量。
    而且，bestfit算法还容易产生大量不能再利用的内存碎片。
    
    - 改进方法
        
        考虑使用最小堆来存储空闲块，按照内存块大小进行排序。每次请求内存时，从堆顶元素向下依次比较，这样第一个找到的块就是最佳匹配的块。
        

**2.3 扩展练习 Challenge：buddy system（伙伴系统）分配算法（需要编程）**

> Buddy System 算法把系统中的可用存储空间划分为存储块 (Block) 来进行管理, 每个存储块的大小必须是 2 的
n 次幂 (Pow(2, n)), 即 1, 2, 4, 8, 16, 32, 64, 128…
• 参考伙伴分配器的一个极简实现，在 ucore 中实现 buddy system 分配算法，要求有比较充分的测试用例
说明实现的正确性，需要有设计文档。
> 

**2.4 扩展练习 Challenge：任意大小的内存单元 slub 分配算法（需要编程）**

> slub 算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上
实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。
• 参考linux 的 slub 分配算法/，在 ucore 中实现 slub 分配算法。要求有比较充分的测试用例说明实现的正
确性，需要有设计文档。
> 

**2.5 扩展练习 Challenge：硬件的可用物理内存范围的获取方法（思考题）**

> 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？
Challenges 是选做，完成 Challenge 的同学可单独提交 Challenge。完成得好的同学可获得最终考试成绩的加分。
> 

在基于OpenSBI固件的操作系统中sbi_domain_memregion_count 和 sbi_domain_memregion_get 可以用于获取当前硬件的可用物理内存范围。这两个函数通过 SBI（Supervisor Binary Interface） 与底层固件（例如 OpenSBI）交互，以获取物理内存的相关信息。它们可以提供当前系统硬件中不同物理内存区域的数量和详细信息。

1.sbi_domain_memregion_count 获取内存区域数量

sbi_domain_memregion_count(unsigned long domain_id) 函数可以返回指定域（domain）的内存区域数量。

2.sbi_domain_memregion_get 获取内存区域详细信息

sbi_domain_memregion_get(unsigned long domain_id, unsigned long index, struct sbi_domain_memregion *mem_region) 函数可以用于获取特定内存区域的详细信息，包括基地址、大小以及标志。
当我们知道有多少个内存区域之后，接下来可以遍历这些区域，通过 sbi_domain_memregion_get() 来获取每一个内存区域的具体信息。