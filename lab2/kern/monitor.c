// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/pmap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "time", "Display the programs' running time", mon_time },
	{ "shmap", "Display the physical page mappings and corresponding permission bits", mon_showmapping},
	{ "chmap", "Change the permissions of any mapping in current address space ", mon_changemapping},
	{ "memdump", "Dump the contents of a range of memory given either a va or pa ", mon_memdump}
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
	return 0;
}

static inline void rdtsc(unsigned long long *dest){
	__asm__ volatile (".byte 0x0f, 0x31" : "=A"(*dest));
	//return dest;
}

int
mon_time(int argc, char **argv, struct Trapframe *tf){
	unsigned long long startT=0, endT=0;
	int ret_value = -1;
	rdtsc(&startT);
	//no func to be timed
	if(argc == 0) return -1;
	for (int i = 0; i < NCOMMANDS; i++) {
		//invoke the func to be timed
		if (strcmp(argv[1], commands[i].name) == 0)
			ret_value = commands[i].func(argc - 1, argv + 1, tf);
	}
	rdtsc(&endT);
	if(ret_value == -1)
		cprintf("Unknown command '%s'\n", argv[0]);
	cprintf("%s cycles: %d\n", argv[1], endT - startT);
	return ret_value;
}

// Lab1 only
// read the pointer to the retaddr on the stack
static uint32_t
read_pretaddr() {
    uint32_t pretaddr;
    __asm __volatile("leal 4(%%ebp), %0" : "=r" (pretaddr));
    return pretaddr;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	uint32_t* ebp = (uint32_t*)read_ebp();
	uint32_t eip = *(uint32_t*)(ebp + 1);
	uint32_t arg1 = *(uint32_t*)(ebp + 2);
	uint32_t arg2 = *(uint32_t*)(ebp + 3);
	uint32_t arg3 = *(uint32_t*)(ebp + 4);
	uint32_t arg4 = *(uint32_t*)(ebp + 5);
	uint32_t arg5 = *(uint32_t*)(ebp + 6);
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
		cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n",eip, ebp, arg1, arg2, arg3, arg4, arg5);
		//the code below is wrong?
		//struct Eipdebuginfo* info = (struct Eipdebuginfo*)malloc(sizeof(struct Eipdebuginfo));
		struct Eipdebuginfo info;
		debuginfo_eip((uintptr_t)eip, &info);
		cprintf("	 %s:%d: %.*s+%d\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);

		ebp = (uint32_t*)*ebp;
		eip = *(uint32_t*)(ebp + 1);
		arg1 = *(uint32_t*)(ebp + 2);
		arg2 = *(uint32_t*)(ebp + 3);
		arg3 = *(uint32_t*)(ebp + 4);
		arg4 = *(uint32_t*)(ebp + 5);
		arg5 = *(uint32_t*)(ebp + 6);
	}

    //cprintf("Backtrace success\n");
	return 0;
}

int hex2int(char* s){
	int res = 0;
	if(s[0] != '0' || s[1] != 'x') return 0;
	int i = 2;
	while(s[i] != '\0'){
		res *= 16;
		if(s[i] >= '0' && s[i] <= '9') res += s[i] - '0';
		else if(s[i] >= 'a' && s[i] <= 'f') res += s[i] - 'a' + 10;
		else if(s[i] >= 'A' && s[i] <= 'F') res += s[i] - 'A' + 10;
		else return 0;
		i++;
	}
	return res;
}

int
mon_showmapping(int argc, char **argv, struct Trapframe *tf){
	int start = hex2int(argv[1]);
	int end = hex2int(argv[2]);
	if(start == 0 || end == 0){
		cprintf("Wrong Input\n");
		 return 0;
	}
	pte_t * target_pte;
	int i = start;
	while(i <= end){
		target_pte = pgdir_walk(kern_pgdir, (void*)i, 0);
		if(target_pte && (*target_pte & PTE_P)){
			if(*target_pte & PTE_PS)
				i = PDX(i) << PDXSHIFT;
			else
				i = PGNUM(i) << PTXSHIFT;
			cprintf("0x%08x -> 0x%08x", i, PGNUM(*target_pte) << PTXSHIFT);
			if(*target_pte & PTE_W) cprintf(" W");
			if(*target_pte & PTE_U) cprintf(" U");
			if(*target_pte & PTE_PWT) cprintf(" PWT");
			if(*target_pte & PTE_PCD) cprintf(" PCD");
			if(*target_pte & PTE_A) cprintf(" A");
			if(*target_pte & PTE_D) cprintf(" D");
			if(*target_pte & PTE_PS) cprintf(" PS");
			if(*target_pte & PTE_G) cprintf(" G");
			cprintf("\n");
			if(*target_pte & PTE_PS)
				i += PTSIZE;
			else
				i += PGSIZE;
		}
		else{
			i = PGNUM(i) << PTXSHIFT;
			cprintf("0x%08x -> NOT EXIST\n", i);
			i += PGSIZE;
		}
	}
	return 0;
}


int mon_changemapping(int argc, char **argv, struct Trapframe *tf){
	int add;
	if(argv[1][0] == '-') add = 0;
	else if(argv[1][0] == '+') add = 1;
	else{
		cprintf("Wrong Input\n");
		 return 0;
	}

	int i = 1, perm = 0;
	while(argv[1][i] != '\0'){
	switch(argv[1][i]){
		case 'W':  perm |= PTE_W; break;
		case 'U':  perm |= PTE_U; break;
		case 'A':  perm |= PTE_A; break;
		case 'D':  perm |= PTE_D; break;
		case 'G':  perm |= PTE_G; break;
		case 'P':
			if(argv[1][i+1] == 'W' && argv[1][i+2] == 'T')
				perm |= PTE_PWT;
			else if(argv[1][i+1] == 'C' && argv[1][i+2] == 'D')
				perm |= PTE_PCD;
			else{
				cprintf("Wrong Input\n");
				return 0;
			}
			i += 2;
			break;
		default:
			cprintf("Wrong Input\n");
		  return 0;
		}
	i ++;
	}
	int addr = hex2int(argv[2]);
	pte_t* target_pte = pgdir_walk(kern_pgdir, (void*)addr, 0);
	if(target_pte){
		if(add) *target_pte |= perm;
		else *target_pte &= ~perm;
	}
	return 0;
}


int mon_memdump(int argc, char **argv, struct Trapframe *tf){
	int pa;
	if(strcmp(argv[1], "-v") == 0) pa = 0;
	else if(strcmp(argv[1], "-p") == 0) pa = 1;
	else{
		cprintf("Wrong Input\n");
		return 0;
	}

	int start = hex2int(argv[2]), end = hex2int(argv[3]);
	if(start == 0 || end == 0){
		cprintf("Wrong Input\n");
		return 0;
	}
	int i = start;
	for(; i < end - end % 8; i+=8){
		cprintf("0x%08x: ", i);
		for(int j = 0; j < 8; j++){
			if(!pa)
				cprintf(" 0x%02x", (unsigned int)*(char*)(i + j) & 0xff);
			else
			  //prgram can only access va ,so convert pa -> va
			  cprintf(" 0x%02x", (unsigned int)*(char*)(i + j + KERNBASE) & 0xff);
		}
		cprintf("\n");
	}
	cprintf("0x%08x: ", i);
	for(;i < end; i++){
			if(!pa)
				cprintf(" 0x%02x", (unsigned int)*(char*)i & 0xff);
			else
				//prgram can only access va ,so convert pa -> va
				cprintf(" 0x%02x", (unsigned int)*(char*)(i + KERNBASE) & 0xff);
	}
	cprintf("\n");
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}

// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
	return callerpc;
}
