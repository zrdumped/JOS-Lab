#include <kern/e1000.h>

// LAB 6: Your driver code here

static uint32_t e1000_read_eeprom(uint8_t addr){
	e1000_map_reg[E1000_EERD >> 2] = (addr << E1000_EEPROM_RW_ADDR_SHIFT) + E1000_EEPROM_RW_REG_START;
	while(!(e1000_map_reg[E1000_EERD >> 2] & E1000_EEPROM_RW_REG_DONE));
	uint32_t volatile mac = e1000_map_reg[E1000_EERD >> 2];
	//cprintf("mac:%08x\n", mac);
	return mac >> E1000_EEPROM_RW_REG_DATA;
	//uint32_t volatile  *eerd = (uint32_t*)(e1000_map_reg + E1000_EERD);
	//*eerd = (addr << 8) | E1000_EEPROM_RW_REG_START;
	//while((*eerd & E1000_EEPROM_RW_REG_DONE) == 0);
	//return *eerd  >> 16;
}

int e1000_attach(struct pci_func* f){
	pci_func_enable(f);

	boot_map_region(kern_pgdir, KSTACKTOP, f->reg_size[0], f->reg_base[0], PTE_PCD | PTE_PWT | PTE_W);
	e1000_map_reg = (uint32_t*)KSTACKTOP;
	//cprintf("e1000 status reg: %08x\n", e1000_map_reg[E1000_STATUS >> 2]);
	if(e1000_map_reg[E1000_STATUS >> 2] != 0x80080783)
		panic("wrong status register value of e1000");

	//initiate transmit
	memset(tx_queue, 0, TX_NUM * sizeof(struct e1000_tx_desc));
	memset(tx_pocket_buffer, 0, TX_NUM * TX_PACKET_BUFFER_SIZE);
	for(int i = 0; i < TX_NUM; i++){
		tx_queue[i].buffer_addr = PADDR(tx_pocket_buffer[i]);
		tx_queue[i].upper.data |= E1000_TXD_STAT_DD;
	}

	//initiate transimit descriptor list
	e1000_map_reg[E1000_TDBAL >> 2] = PADDR(tx_queue);
	e1000_map_reg[E1000_TDBAH >> 2] = 0;
	//set the size of descriptor ring(in B)
	e1000_map_reg[E1000_TDLEN >> 2] = TX_NUM * sizeof(struct e1000_tx_desc);
	e1000_map_reg[E1000_TDH >> 2] = 0;
	e1000_map_reg[E1000_TDT >> 2] = 0;

	uint32_t tctl = e1000_map_reg[E1000_TCTL >> 2];
	tctl |= E1000_TCTL_EN + E1000_TCTL_PSP;
	tctl &= ~E1000_TCTL_CT;
	tctl |= 0x100;
	tctl &= ~E1000_TCTL_COLD;
	tctl |= 0x40000;
	e1000_map_reg[E1000_TCTL >> 2] = tctl;

	e1000_map_reg[E1000_TIPG >> 2] = 10 | (4<<10) | (6 << 20);

	//initiate receive
	memset(rx_queue, 0, RX_NUM * sizeof(struct e1000_rx_desc));
	memset(rx_pocket_buffer, 0, RX_NUM * RX_PACKET_BUFFER_SIZE);
	for(int i = 0; i < RX_NUM; i++)
		rx_queue[i].buffer_addr = PADDR(rx_pocket_buffer[i]);
	//MAC addr -> RA, little endian
	//e1000_map_reg[E1000_RA >> 2] = 0x12005452;
	//e1000_map_reg[(E1000_RA >> 2) + 1] = 0x00005634 | E1000_RAH_AV;
	uint32_t mac_l = e1000_read_eeprom(0x0);
	//cprintf("mac:%08x\n", mac_l);
	uint32_t mac_m = e1000_read_eeprom(0x1);
	//cprintf("mac:%08x\n", mac_m);
	uint32_t mac_h = e1000_read_eeprom(0x2);
	//cprintf("mac:%08x\n", mac_h);
	e1000_mac[0] = mac_l & 0xff;
	e1000_mac[1] = (mac_l >> 8) & 0xff;
	e1000_mac[2] = mac_m & 0xff;
	e1000_mac[3] = (mac_m >> 8) & 0xff;
	e1000_mac[4] = mac_h & 0xff;
	e1000_mac[5] = (mac_h >> 8) & 0xff;
	cprintf("MAC: %02x:%02x:%02x:%02x:%02x:%02x\n", 
		e1000_mac[0], e1000_mac[1], e1000_mac[2], e1000_mac[3], e1000_mac[4], e1000_mac[5]);
	e1000_map_reg[E1000_RA >> 2] = (mac_m << 16) + mac_l;
	e1000_map_reg[(E1000_RA >> 2) + 1] = mac_h + E1000_RAH_AV;

	//initiate MTA to 0b
	e1000_map_reg[E1000_MTA >> 2] = 0;

	//program the IMS
	//did not configure the card to use interrupts
	//not initiate RDTR

	//initiate receive descriptor list
	e1000_map_reg[E1000_RDBAL >> 2] = PADDR(rx_queue);
	e1000_map_reg[E1000_RDBAH >> 2] = 0;
	//set the size of descriptor ring(in B)
	e1000_map_reg[E1000_RDLEN >> 2] = RX_NUM * sizeof(struct e1000_rx_desc);
	//set receive descriptor head & tail
	//head should point to the first valid receive dspt in the ring
	e1000_map_reg[E1000_RDH >> 2] = 0;
	//tail point to the one dspt beyond the liast valid dspt
	e1000_map_reg[E1000_RDT >> 2] = RX_NUM - 1;

	//program RCTL
	uint32_t rctl = e1000_map_reg[E1000_RCTL >> 2];
	rctl = E1000_RCTL_EN + E1000_RCTL_BAM + E1000_RCTL_SECRC + E1000_RCTL_SZ_2048 + E1000_RCTL_LBM_TCVR;
	//rctl &= ~E1000_RCTL_LPE;
	e1000_map_reg[E1000_RCTL >> 2] = rctl;

	return 0;
}

int e1000_transmit(char* data, int length){
	if(data == NULL || length < 0 || length > TX_PACKET_BUFFER_SIZE)
		return -E_INVAL;
	uint32_t tdt = e1000_map_reg[E1000_TDT >> 2];
	if(!(tx_queue[tdt].upper.data & E1000_TXD_STAT_DD))
		return -E_TX_FULL;

	memset(tx_pocket_buffer[tdt], 0, TX_PACKET_BUFFER_SIZE);
	memmove(tx_pocket_buffer[tdt], data, length);
	tx_queue[tdt].lower.flags.length = length;
	tx_queue[tdt].lower.data |= E1000_TXD_CMD_RS;
	tx_queue[tdt].lower.data |= E1000_TXD_CMD_EOP;
	tx_queue[tdt].upper.data &= ~E1000_TXD_STAT_DD;

	e1000_map_reg[E1000_TDT >> 2] = (tdt + 1) % TX_NUM;

	return 0;
}

int e1000_receive(char* data){
	if(data == NULL)
		return -E_INVAL;
	uint32_t rdt = (e1000_map_reg[E1000_RDT >> 2] + 1) % RX_NUM;
	if(!(rx_queue[rdt].status & E1000_RXD_STAT_DD))
		return -E_RX_EMPTY;
	if(!(rx_queue[rdt].status & E1000_RXD_STAT_EOP))
		return -E_RX_OVER_LONG;
	while(rdt == e1000_map_reg[E1000_RDH >> 2]);
	uint32_t length = rx_queue[rdt].length;
	memmove(data, rx_pocket_buffer[rdt], length);
	rx_queue[rdt].status &= ~E1000_RXD_STAT_DD;
	rx_queue[rdt].status &= ~E1000_RXD_STAT_EOP;

	e1000_map_reg[E1000_RDT >> 2] = rdt;
	return length;
}
