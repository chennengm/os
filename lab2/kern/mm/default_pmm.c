#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
//该结构体用于管理空闲内存块。
extern free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void
default_init_memmap(struct Page *base, size_t n) {
    //初始化一段物理内存块，添加到空闲链表中。
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n; //该物理块包含 n 个连续的空闲页面
    SetPageProperty(base);
    nr_free += n; //更新全局的空闲页面数量计数器
    if (list_empty(&free_list)) { //free_list空，直接加
        list_add(&free_list, &(base->page_link));
    } else { //根据物理地址从小到大排序

        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *
default_alloc_pages(size_t n) {
    //内存分配函数，First-Fit 策略在空闲列表中查找一个足够大的块
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    //遍历空闲列表从空闲列表中查找第一个满足（页数大于等于 n）
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;//如果找到合适指针存储到 page 中
            break;
        }
    }
    if (page != NULL) {
        //如果找到合适的块，将 page 从空闲列表中删除。
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            //拆分
            struct Page *p = page + n;//剩余部分起始地址
            p->property = page->property - n;
            SetPageProperty(p);//标记为一个空闲块头，可供分配。
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page); //使用ClearPageProperty(page)清除page的property标志表明它已被分配
    }
    return page; //返回分配的page指针
}

static void
default_free_pages(struct Page *base, size_t n) {
    //释放占用的页块，并将其加入到空闲列表中，同时尝试合并相邻的空闲块
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base); //标记为空闲块
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
//合并前面的空闲页块：
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            //p 的结束地址刚好是 base 的起始地址
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
//合并后面的空闲页块
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            //如果 base 的结束地址刚好是 p 的起始地址
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t//返回可用内存页的数量
default_nr_free_pages(void) {
    return nr_free;
}
//检查物理内存管理器的基本功能：分配和释放页面，检查分配、释放以及列表状态是否符合预期
static void
basic_check(void) {
    struct Page *p0, *p1, *p2;// 分配三个物理页面， p0, p1, p2。
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
    // 确保三个页面互不相同
    assert(p0 != p1 && p0 != p2 && p1 != p2);
     // 确保引用计数为 0，表示这些页面刚分配出来，还没有被使用
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    // 验证页面物理地址在有效范围内
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);
    // 存储当前的 free_list ，然后初始化一个新的空的 free_list 列表
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));// 确保 free_list 为空

    unsigned int nr_free_store = nr_free;// 存储当前可用页面数量
    nr_free = 0;
   // 因为空闲列表已被清空nrfree=0，分配页面应该失败
    assert(alloc_page() == NULL);
    // 释放 p0, p1, 和 p2，然后检查 nr_free 是否为3。
    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);
    // 再次分配三个页面，确保它们都不为空
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);
     // 再次尝试分配页面，但此时应该返回NULL，因为没有足够的可用页面
    assert(alloc_page() == NULL);
    // 释放 p0，确保 free_list 列表不为空
    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);// 尝试分配一个页面，应该返回 p0。
    assert(alloc_page() == NULL);//尝试分配页面，返回NULl没有足够的可用页面

    assert(nr_free == 0);// 确保 nr_free 现在为0，因为之前已经分配了所有的可用页面
    free_list = free_list_store;// 恢复原始的 free_list 
    nr_free = nr_free_store;// 恢复原始的 nr_free 
     // 释放 p0, p1, 和 p2
    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {//用于对 First-Fit 内存分配策略检查
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    //// 遍历空闲列表，统计页块数和总空闲页数
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    // 确保 total（总空闲页面数量）等于 nr_free_pages()
    assert(total == nr_free_pages());

    basic_check();// 调用 basic_check 函数，检查
    // 分配一个包含5个页面的连续内存块
    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);//确保返回的指针不为NULL
    assert(!PageProperty(p0));//返回的页面没有 PageProperty 标志,不是空闲态

    //存储当前的 free_list 列表，然后初始化一个新的空 free_list 列表。
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));// 确保新 free_list 为空
    assert(alloc_page() == NULL);// 确保无法分配页面，因为 nr_free 为0
    
    //存储当前可用页面数量
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);// 释放 p0 中的第3、4、5个页面
    assert(alloc_pages(4) == NULL);// 确保无法分配包含4个页面的连续内存块
    assert(PageProperty(p0 + 2) && p0[2].property == 3);// 确保 p0 中的第3个页面有 PageProperty 标志，且 property 值为3
    assert((p1 = alloc_pages(3)) != NULL);//从空闲链表中分配一个包含3个页面的连续内存块给p1
    assert(p0 + 2 == p1);// 确保 p1 是 p0 中的第3个页面

    p2 = p0 + 1;//p2 指针指向 p0中的第 2 个页面
    free_page(p0);//将 p0的第一个页面释放
    free_pages(p1, 3);//释放 p1（包含 3 个页面）
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);
//确认p0新分配的页面是否是p2-1=p0
    assert((p0 = alloc_page()) == p2 - 1);
//释放p0
    free_page(p0);
    //分配 2 个页面并确保它们是 p2 + 1=p0第三个
    assert((p0 = alloc_pages(2)) == p2 + 1);
//释放 p0 指向的 2 个页面
    free_pages(p0, 2);
    //释放 p2 指向的单个页面。
    free_page(p2);
//分配 5 个页面，确保分配成功.
    assert((p0 = alloc_pages(5)) != NULL);
    //分配单个页面，确保分配失败。
    assert(alloc_page() == NULL);
//检查当前空闲页数是否为 0
    assert(nr_free == 0);
    //恢复原始空闲页数
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
//这个结构体在
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};

