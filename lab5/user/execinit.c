#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	int r;
	cprintf("i am parent environment %08x\n", thisenv->env_id);
	if ((r = execl("init", "init", "one", "two", 0)) < 0)
		panic("execl(init) failed: %e", r);
}
