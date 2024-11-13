#include <defs.h>     
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_LRU.h>
#include <list.h>

extern list_entry_t pra_list_head;  //管理所有页面

static int
_lru_init_mm(struct mm_struct* mm)
{
    list_init(&pra_list_head);  // 初始化pra_list_head为空链表
    mm->sm_priv = &pra_list_head;  // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
    return 0;
}

static int
_lru_map_swappable(struct mm_struct* mm, uintptr_t addr, struct Page* page, int swap_in)
//将新映射的页面插入到页面置换算法的管理结构中
{
    list_entry_t* head = (list_entry_t*)mm->sm_priv;
    list_entry_t* entry = &(page->pra_page_link);  //获取页面的链表节点
    assert(entry != NULL && head != NULL);  //断言该节点不为空

    // 将页面page插入到页面链表pra_list_head的尾部！表明它是最近被访问的
    list_add_after(head, entry);  

    return 0;
}

static int
_lru_swap_out_victim(struct mm_struct* mm, struct Page** ptr_page, int in_tick)
//选择要换出的页面
{
    list_entry_t* head = (list_entry_t*)mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);

    // 获取链表尾部的页面
    list_entry_t* tail_entry = list_prev(head);   

    // 如果链表为空，返回NULL
    if (tail_entry == head) {
        *ptr_page = NULL;
        return 0;
    }

    // 获取链表尾部的页面对应的Page结构指针
    struct Page* page = le2page(tail_entry, pra_page_link);

    // 将该页面从链表中删除
    list_del(tail_entry);

    // 将该页面指针赋值给ptr_page作为换出页面
    *ptr_page = page;

    return 0;
}

static void
_lru_update_page(struct Page* page)     //写入一个新页面

{
    list_entry_t* entry = &(page->pra_page_link);
    assert(entry != NULL);

    // 如果页面已经在链表头部，无需移动
    if (list_next(entry) == &pra_list_head) {
        return;
    }

    // 将页面从当前位置删除
    list_del(entry);

    // 将页面插入到链表尾部     
    list_add_before(&pra_list_head, entry);
}

void _lru_mem(int addr, int value)
{
    *(unsigned char*)addr = value;
    struct Page* page = get_page(check_mm_struct->pgdir, addr, NULL);
    if (page != NULL)
    {
        _lru_update_page(page);
    }
}

static int
_lru_check_swap(void) {
    cprintf("write Virt Page c in lru_check_swap\n");
    _lru_mem(0x3000, 0x0c);     //写入虚拟页c（0x3000）
    assert(pgfault_num == 4);  //缺页异常的次数

    cprintf("write Virt Page a in lru_check_swap\n");
    _lru_mem(0x1000, 0x0a);
    assert(pgfault_num == 4);

    cprintf("write Virt Page d in lru_check_swap\n");
    _lru_mem(0x4000, 0x0d);
    assert(pgfault_num == 4);

    cprintf("write Virt Page b in lru_check_swap\n");
    _lru_mem(0x2000, 0x0b);
    assert(pgfault_num == 4);   

    cprintf("write Virt Page e in lru_check_swap\n");
    _lru_mem(0x5000, 0x0e);
    assert(pgfault_num == 5);  //增加，说明此次发生page fault

    cprintf("write Virt Page b in lru_check_swap\n");  
    _lru_mem(0x2000, 0x0b);
    assert(pgfault_num == 5);

    cprintf("write Virt Page a in lru_check_swap\n");
    _lru_mem(0x1000, 0x0a);
    assert(pgfault_num == 5);

    cprintf("write Virt Page b in lru_check_swap\n");
    _lru_mem(0x2000, 0x0b);
    assert(pgfault_num == 5);

    cprintf("write Virt Page c in lru_check_swap\n");  
    _lru_mem(0x3000, 0x0c);
    assert(pgfault_num == 6);

    cprintf("write Virt Page d in lru_check_swap\n");
    _lru_mem(0x4000, 0x0d);
    assert(pgfault_num == 7);

    cprintf("write Virt Page e in lru_check_swap\n");
    _lru_mem(0x5000, 0x0e);
    assert(pgfault_num == 8);

    cprintf("write Virt Page a in lru_check_swap\n");
    _lru_mem(0x1000, 0x0a);
    assert(pgfault_num == 9);

    return 0;
}

static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct* mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct* mm)
{
    return 0;
}

struct swap_manager swap_manager_lru =
{
     .name = "lru swap manager",
     .init = &_lru_init,   //do nothing
     .init_mm = &_lru_init_mm,
     .tick_event = &_lru_tick_event, //nothing
     .map_swappable = &_lru_map_swappable,
     .set_unswappable = &_lru_set_unswappable, //nothing
     .swap_out_victim = &_lru_swap_out_victim,
     .check_swap = &_lru_check_swap,
};
