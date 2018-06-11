// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>
extern void _pgfault_upcall(void);
// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at vpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if(!((err & FEC_WR) && (vpd[PDX(addr)] & PTE_P) && (vpt[PGNUM(addr)] & PTE_P ) && ( vpt[PGNUM(addr)] & PTE_COW)))
		panic("invalid page");
	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr, PGSIZE);
	if(sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W) < 0)
		panic("sys_page_alloc wrong");
	memmove(PFTEMP, addr, PGSIZE);
	if(sys_page_map(0, PFTEMP, 0, addr, PTE_P | PTE_U | PTE_W) < 0)
		panic("sys_page_map wrong");
	if(sys_page_unmap(0, PFTEMP)< 0)
		panic("sys_page_unmap wrong");
	return ;
	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	void* addr = (void*)(pn * PGSIZE);
	if(vpt[pn] & PTE_W || vpt[pn] & PTE_COW){
		if(sys_page_map(0, addr, envid, addr, PTE_U | PTE_P | PTE_COW) < 0)
			panic("sys_page_map wrong");
		if(sys_page_map(0, addr, 0, addr, PTE_U | PTE_P | PTE_COW) < 0)
			panic("sys_page_map wrong");
	}
	else{
		if(sys_page_map(0, addr, envid, addr, PTE_U | PTE_P ) < 0)
			panic("sys_page_map wrong");
	}
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use vpd, vpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	//1
	set_pgfault_handler(pgfault);
	//2
	envid_t eid = sys_exofork();
	if(eid < 0)
		panic("fork wrong");
	else if(eid == 0){
		//child
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	//3
	for(uintptr_t i = UTEXT; i < USTACKTOP; i += PGSIZE){
		if((vpd[PDX(i)] & PTE_P) && (vpt[PGNUM(i)] & PTE_P) &&  (vpt[PGNUM(i)] & PTE_U))
			duppage(eid, PGNUM(i));
	}
	//set exception stack seperately
	if(sys_page_alloc(eid, (void*)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P) < 0)
		panic("sys_page_alloc wrong");
	//4
	if(sys_env_set_pgfault_upcall(eid, _pgfault_upcall) < 0)
		panic("sys_env_set_pgfault_upcall wrong");
	//5
	if(sys_env_set_status(eid, ENV_RUNNABLE) < 0)
		panic("sys_env_set_status wrong");
	return eid;
	panic("fork not implemented");
}

// Challenge!
int
sfork(void)
{

	#ifdef SFORK_CHALLENGE
	int r;

	set_pgfault_handler(pgfault);

	thisenv = NULL;
	envid_t eid = sys_exofork();
	if(eid < 0)
		panic("fork wrong");
	else if(eid == 0){
		//child
		return 0;
	}

	for(uintptr_t i = 0; i < UTOP; i += PGSIZE){
		if(i != UXSTACKTOP - PGSIZE && i != USTACKTOP - PGSIZE){
			if((vpd[PDX(i)] & PTE_P) && (vpt[PGNUM(i)] & PTE_P) )
				if(sys_page_map(0, (void*)i, eid, (void*)i, vpt[PGNUM(i)] & PTE_SYSCALL) < 0)
					panic("sys_page_map wrong");
		}else if(i == USTACKTOP - PGSIZE)
			duppage(eid, PGNUM(i));
	}

	if(sys_page_alloc(eid, (void*)(UXSTACKTOP - PGSIZE), PTE_U | PTE_W | PTE_P) < 0)
		panic("sys_page_alloc wrong");

	if(sys_env_set_pgfault_upcall(eid, _pgfault_upcall) < 0)
		panic("sys_env_set_pgfault_upcall wrong");

	if(sys_env_set_status(eid, ENV_RUNNABLE) < 0)
		panic("sys_env_set_status wrong");
	return eid;
	#else
	panic("sfork not implemented");
	#endif
}
