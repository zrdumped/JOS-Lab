#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#define TX_NUM 64
#define RX_NUM 128
#define TX_PACKET_BUFFER_SIZE 1518
#define RX_PACKET_BUFFER_SIZE 2048

#define VENDOR_ID_82540EM_A 0x8086
#define DEVICE_ID_82540EM_A 0x100E


#include <inc/string.h>
#include <inc/error.h>
#include <kern/pci.h>
#include <kern/pmap.h>

uint32_t * volatile e1000_map_reg;
//registers
#define E1000_STATUS   0x00008  /* Device Status - RO */
#define E1000_EERD     0x00014  /* EEPROM Read - RW */
#define E1000_RCTL     0x00100  /* RX Control - RW */
#define E1000_TCTL     0x00400  /* TX Control - RW */
#define E1000_TIPG     0x00410  /* TX Inter-packet gap -RW */
#define E1000_RDBAL    0x02800  /* RX Descriptor Base Address Low - RW */
#define E1000_RDBAH    0x02804  /* RX Descriptor Base Address High - RW */
#define E1000_RDLEN    0x02808  /* RX Descriptor Length - RW */
#define E1000_RDH      0x02810  /* RX Descriptor Head - RW */
#define E1000_RDT      0x02818  /* RX Descriptor Tail - RW */
#define E1000_TDBAL    0x03800  /* TX Descriptor Base Address Low - RW */
#define E1000_TDBAH    0x03804  /* TX Descriptor Base Address High - RW */
#define E1000_TDLEN    0x03808  /* TX Descriptor Length - RW */
#define E1000_TDH      0x03810  /* TX Descriptor Head - RW */
#define E1000_TDT      0x03818  /* TX Descripotr Tail - RW */
#define E1000_MTA      0x05200  /* Multicast Table Array - RW Array */
#define E1000_RA       0x05400  /* Receive Address - RW Array */

//transmit
/* Transmit Descriptor bit definitions */
#define E1000_TXD_CMD_RS     0x08000000 /* Report Status */
#define E1000_TXD_CMD_EOP    0x01000000 /* End of Packet */
#define E1000_TXD_STAT_DD    0x00000001 /* Descriptor Done */

/* Transmit Control */
#define E1000_TCTL_EN     0x00000002    /* enable tx */
#define E1000_TCTL_PSP    0x00000008    /* pad short packets */
#define E1000_TCTL_CT     0x00000ff0    /* collision threshold */
#define E1000_TCTL_COLD   0x003ff000    /* collision distance */

/* Transmit Descriptor */
struct e1000_tx_desc {
    uint64_t buffer_addr;       /* Address of the descriptor's data buffer */
    union {
        uint32_t data;
        struct {
            uint16_t length;    /* Data buffer length */
            uint8_t cso;        /* Checksum offset */
            uint8_t cmd;        /* Descriptor control */
        } flags;
    } lower;
    union {
        uint32_t data;
        struct {
            uint8_t status;     /* Descriptor status */
            uint8_t css;        /* Checksum start */
            uint16_t special;
        } fields;
    } upper;
};


//receive
/* Receive Address */
#define E1000_RAH_AV  0x80000000        /* Receive descriptor valid */

/* Receive Descriptor bit definitions */
#define E1000_RXD_STAT_DD       0x01    /* Descriptor Done */
#define E1000_RXD_STAT_EOP      0x02    /* End of Packet */

/* Receive Control */
#define E1000_RCTL_EN             0x00000002    /* enable */
#define E1000_RCTL_BAM            0x00008000    /* broadcast enable */
#define E1000_RCTL_LBM_TCVR       0x000000C0    /* tcvr loopback mode */
/* these buffer sizes are valid if E1000_RCTL_BSEX is 0 */
#define E1000_RCTL_SZ_2048        0x00000000    /* rx buffer size 2048 */
/* these buffer sizes are valid if E1000_RCTL_BSEX is 1 */
#define E1000_RCTL_SECRC          0x04000000    /* Strip Ethernet CRC */


/* Receive Descriptor */
struct e1000_rx_desc {
    uint64_t buffer_addr; /* Address of the descriptor's data buffer */
    uint16_t length;     /* Length of data DMAed into data buffer */
    uint16_t csum;       /* Packet checksum */
    uint8_t status;      /* Descriptor status */
    uint8_t errors;      /* Descriptor Errors */
    uint16_t special;
};


#define E1000_EEPROM_RW_REG_DATA   16   /* Offset to data in EEPROM read/write registers */
#define E1000_EEPROM_RW_REG_DONE   0x10 /* Offset to READ/WRITE done bit */
#define E1000_EEPROM_RW_REG_START  1    /* First bit for telling part to start operation */
#define E1000_EEPROM_RW_ADDR_SHIFT 8    /* Shift to the address bits */



struct e1000_tx_desc tx_queue[TX_NUM] __attribute__((aligned(16)));
char tx_pocket_buffer[TX_NUM][TX_PACKET_BUFFER_SIZE];
struct e1000_rx_desc rx_queue[RX_NUM] __attribute__((aligned(16)));
char rx_pocket_buffer[RX_NUM][RX_PACKET_BUFFER_SIZE];
uint8_t e1000_mac[6];

//functions
int e1000_attach(struct pci_func* f);
int e1000_transmit(char* data, int length);
int e1000_receive(char* data);


#endif	// JOS_KERN_E1000_H
