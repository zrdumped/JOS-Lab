#include "ns.h"

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";

	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
	int ret, length;
	char* data;

	while(1){
		if((ret = sys_ipc_recv(&nsipcbuf)) < 0)
			panic("sys_ipc_recv wrong");
		if((thisenv->env_ipc_from != ns_envid) || (thisenv->env_ipc_value != NSREQ_OUTPUT))
			continue;
		while((ret = sys_e1000_transmit(nsipcbuf.pkt.jp_data, nsipcbuf.pkt.jp_len)) < 0){
			if(ret != -E_TX_FULL)
				panic("sys_e1000_transimit wrong");
			sys_yield();
		}
	}
}
