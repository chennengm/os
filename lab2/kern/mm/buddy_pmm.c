#include <assert.h>
#include <stdio.h>  
#include <string.h>
#include <pmm.h>
#include <list.h>
#include <buddy_pmm.h>

#define MAX_LIST 16

struct buddy
{
    unsigned int level;      // 层数
    list_entry_t free_array[MAX_LIST]; // 伙伴堆数组
    unsigned int nr_free;      // 剩余的空闲块
};

struct buddy buddy_struct;

#define level (buddy_struct.level)
#define free_array (buddy_struct.free_array)
#define nr_free (buddy_struct.nr_free)

#define IS_POWER_OF_2(x) (!((x)&((x)-1)))  //x是否为2的幂 &是按位与！
static uint32_t get_power(size_t n) //n相对于2的幂
{
    uint32_t power = 0;
    while(n>>=1)
    {
        power++;
    }
    return power;
}

static void buddy_init(void)
{
    for(int a=0;a<MAX_LIST;a++)
    {
        list_init(free_array+a);
    }
    level=0;
    nr_free=0;
    return;
}

static void buddy_init_memmap(struct Page *base,size_t n)
{
    assert(n>0);
    struct Page *p=base;
    level=get_power(n);
    size_t the_n=1<<level;
    nr_free=the_n; //该块大小
    //初始化
    for (; p != base + the_n; p+=1) 
    {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);               
    }
    list_add(&(free_array[level]), &(base->page_link));
    base->property=level; //不同于前面算法，这里存的是次数
    return;
}

static struct Page * buddy_alloc_pages(size_t n)
{
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page=NULL;
    level = get_power(n);
    if(!(IS_POWER_OF_2(n))) //要用更大的
    {
        level++;
    }
    size_t the_n=1<<level;
    int spilttime = 0;
    while(spilttime<MAX_LIST) //尝试分块的次数比层数还大说明找不到合适的块
    {
        if(!(list_empty(free_array+level)))
        {
            //将该空闲块断开
            page=le2page(list_next(free_array+level),page_link); // convert list entry to page
            list_del(list_next(free_array+level));
            SetPageProperty(page);//已使用
            nr_free-=the_n; //减去用掉的页
            break;
        }
        else
        {
            spilttime++;
            for(int a=level;a<MAX_LIST;a++)
            {
                if(!list_empty(free_array+a)) //分块
                {   
                    struct Page *page1=le2page(list_next(free_array+a),page_link);
                    struct Page *page2=page1+(1<<(a-1));
                    page1->property=a-1; //修改幂次
                    page2->property=a-1;
                    list_del(list_next(free_array+a));
                    list_add(free_array+a-1,&(page2->page_link));
                    list_add(free_array+a-1,&(page1->page_link));
                    break;
                }
            }
        }
        
    }
    return page;
}

extern ppn_t fppn;

static struct Page* get_buddy(struct Page *page)
{
    uint32_t power=page->property;
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));//伙伴块的物理页号
    return page+(ppn-page2ppn(page));

    // size_t real_block_size = 1 << block_size;                    
    // size_t relative_block_addr = (size_t)block_addr - mem_begin; 
    // size_t sizeOfPage = real_block_size * sizeof(struct Page);                  
    // size_t buddy_relative_addr = (size_t)relative_block_addr ^ sizeOfPage;      
    // struct Page *buddy_page = (struct Page *)(buddy_relative_addr + mem_begin); 
    // return buddy_page;
}


static void buddy_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    unsigned int newfree=1<<(base->property);
    nr_free+=newfree;  
    struct Page *free_page=base;
    list_add(free_array+(free_page->property),&(free_page->page_link));
    //当其伙伴块没有被使用且不大于设定的最大块时
    struct Page *free_page_buddy=get_buddy(free_page);
    while(!PageProperty(free_page_buddy)&&free_page->property<14)
    {
        if(free_page_buddy<free_page)
        {
            struct Page* temp;
            free_page->property=0;
            ClearPageProperty(free_page);
            temp=free_page;
            free_page=free_page_buddy;
            free_page_buddy=temp;
        }
        list_del(&(free_page->page_link));
        list_del(&(free_page_buddy->page_link));
        free_page->property+=1;
        list_add(&(free_array[free_page->property]),&(free_page->page_link));
        free_page_buddy=get_buddy(free_page); //循环到更高一次
    }
    ClearPageProperty(free_page);
    return;
}
static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

 static void basic_check(void) {
    cprintf("空闲块数为：%d\n", nr_free);
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;

    p0 = alloc_pages(5);
    p1 = alloc_pages(5);
    p2 = alloc_pages(5);

    // cprintf("p0的物理地址0x%016lx.\n", PADDR(p0)); // 0x8020f318
    cprintf("p0的虚拟地址0x%016lx.\n", p0);
    // cprintf("p1的物理地址0x%016lx.\n", PADDR(p1)); // 0x8020f458,和p0相差0x140=0x28*5
    cprintf("p1的虚拟地址0x%016lx.\n", p1);
    // cprintf("p2的物理地址0x%016lx.\n", PADDR(p2)); // 0x8020f598,和p1相差0x140=0x28*5
    cprintf("p2的虚拟地址0x%016lx.\n", p2);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    
    unsigned int nr_free_store = nr_free; // 假设空闲块数是0
    nr_free = 0;

    assert(alloc_page() == NULL);


    free_pages(p0, 5);
    assert(nr_free==8);
    free_pages(p1, 5);
    assert(nr_free==16);
    free_pages(p2, 5);
    assert(nr_free==24);

}   

static void buddy_check(void) {
    basic_check();
}

const struct pmm_manager buddy_sys_pmm_manager = {
    .name = "buddy_sys_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};