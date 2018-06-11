#include "ns.h"

extern union Nsipc nsipcbuf;

void
input(envid_t ns_envid)
{
	binaryname = "ns_input";

	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.
	int ret;
	char data[2048];
	while(1){
		//cprintf("before sys_e1000_receive\n");
		if((ret = sys_e1000_receive(data)) < 0){
			if(ret != -E_RX_EMPTY)
				panic("sys_e1000_receive wrong");
			sys_yield();
			continue;
		}
		while(sys_page_alloc(0, &nsipcbuf, PTE_P|PTE_W|PTE_U) < 0);
			//sys_yield();
		//cprintf("sys_page_alloc\n");
		nsipcbuf.pkt.jp_len = ret;
		memmove(nsipcbuf.pkt.jp_data, data, ret);
		while(sys_ipc_try_send(ns_envid, NSREQ_INPUT, &nsipcbuf, PTE_P|PTE_W|PTE_U) < 0);
			//sys_yield();
		//cprintf("sys_ipc_try_send\n");
	}
}
