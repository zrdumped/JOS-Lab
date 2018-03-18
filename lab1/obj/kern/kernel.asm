
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 40 1d 10 f0       	push   $0xf0101d40
f0100050:	e8 35 0a 00 00       	call   f0100a8a <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 d3 07 00 00       	call   f010084e <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 5c 1d 10 f0       	push   $0xf0101d5c
f0100087:	e8 fe 09 00 00       	call   f0100a8a <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	char ntest[256] = {};

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 a7 17 00 00       	call   f0101858 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 c5 04 00 00       	call   f010057b <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 77 1d 10 f0       	push   $0xf0101d77
f01000c3:	e8 c2 09 00 00       	call   f0100a8a <cprintf>
	cprintf("pading space in the right to number 22: %-8d.\n", 22);
f01000c8:	83 c4 08             	add    $0x8,%esp
f01000cb:	6a 16                	push   $0x16
f01000cd:	68 e0 1d 10 f0       	push   $0xf0101de0
f01000d2:	e8 b3 09 00 00       	call   f0100a8a <cprintf>
	cprintf("show me the sign: %+d, %+d\n", 1024, -1024);
f01000d7:	83 c4 0c             	add    $0xc,%esp
f01000da:	68 00 fc ff ff       	push   $0xfffffc00
f01000df:	68 00 04 00 00       	push   $0x400
f01000e4:	68 92 1d 10 f0       	push   $0xf0101d92
f01000e9:	e8 9c 09 00 00       	call   f0100a8a <cprintf>


	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000ee:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000f5:	e8 46 ff ff ff       	call   f0100040 <test_backtrace>
f01000fa:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000fd:	83 ec 0c             	sub    $0xc,%esp
f0100100:	6a 00                	push   $0x0
f0100102:	e8 fd 07 00 00       	call   f0100904 <monitor>
f0100107:	83 c4 10             	add    $0x10,%esp
f010010a:	eb f1                	jmp    f01000fd <i386_init+0x69>

f010010c <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010010c:	55                   	push   %ebp
f010010d:	89 e5                	mov    %esp,%ebp
f010010f:	56                   	push   %esi
f0100110:	53                   	push   %ebx
f0100111:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100114:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010011b:	75 37                	jne    f0100154 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010011d:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100123:	fa                   	cli    
f0100124:	fc                   	cld    

	va_start(ap, fmt);
f0100125:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100128:	83 ec 04             	sub    $0x4,%esp
f010012b:	ff 75 0c             	pushl  0xc(%ebp)
f010012e:	ff 75 08             	pushl  0x8(%ebp)
f0100131:	68 ae 1d 10 f0       	push   $0xf0101dae
f0100136:	e8 4f 09 00 00       	call   f0100a8a <cprintf>
	vcprintf(fmt, ap);
f010013b:	83 c4 08             	add    $0x8,%esp
f010013e:	53                   	push   %ebx
f010013f:	56                   	push   %esi
f0100140:	e8 1f 09 00 00       	call   f0100a64 <vcprintf>
	cprintf("\n");
f0100145:	c7 04 24 19 1e 10 f0 	movl   $0xf0101e19,(%esp)
f010014c:	e8 39 09 00 00       	call   f0100a8a <cprintf>
	va_end(ap);
f0100151:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100154:	83 ec 0c             	sub    $0xc,%esp
f0100157:	6a 00                	push   $0x0
f0100159:	e8 a6 07 00 00       	call   f0100904 <monitor>
f010015e:	83 c4 10             	add    $0x10,%esp
f0100161:	eb f1                	jmp    f0100154 <_panic+0x48>

f0100163 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100163:	55                   	push   %ebp
f0100164:	89 e5                	mov    %esp,%ebp
f0100166:	53                   	push   %ebx
f0100167:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010016a:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010016d:	ff 75 0c             	pushl  0xc(%ebp)
f0100170:	ff 75 08             	pushl  0x8(%ebp)
f0100173:	68 c6 1d 10 f0       	push   $0xf0101dc6
f0100178:	e8 0d 09 00 00       	call   f0100a8a <cprintf>
	vcprintf(fmt, ap);
f010017d:	83 c4 08             	add    $0x8,%esp
f0100180:	53                   	push   %ebx
f0100181:	ff 75 10             	pushl  0x10(%ebp)
f0100184:	e8 db 08 00 00       	call   f0100a64 <vcprintf>
	cprintf("\n");
f0100189:	c7 04 24 19 1e 10 f0 	movl   $0xf0101e19,(%esp)
f0100190:	e8 f5 08 00 00       	call   f0100a8a <cprintf>
	va_end(ap);
}
f0100195:	83 c4 10             	add    $0x10,%esp
f0100198:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010019b:	c9                   	leave  
f010019c:	c3                   	ret    

f010019d <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010019d:	55                   	push   %ebp
f010019e:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a0:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a5:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	74 0b                	je     f01001b5 <serial_proc_data+0x18>
f01001aa:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2b                	jmp    f01001f2 <cons_intr+0x36>
		if (c == 0)
f01001c7:	85 c0                	test   %eax,%eax
f01001c9:	74 27                	je     f01001f2 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	8b 0d 44 25 11 f0    	mov    0xf0112544,%ecx
f01001d1:	8d 51 01             	lea    0x1(%ecx),%edx
f01001d4:	89 15 44 25 11 f0    	mov    %edx,0xf0112544
f01001da:	88 81 40 23 11 f0    	mov    %al,-0xfeedcc0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001e0:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001e6:	75 0a                	jne    f01001f2 <cons_intr+0x36>
			cons.wpos = 0;
f01001e8:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001ef:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f2:	ff d3                	call   *%ebx
f01001f4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f7:	75 ce                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001f9:	83 c4 04             	add    $0x4,%esp
f01001fc:	5b                   	pop    %ebx
f01001fd:	5d                   	pop    %ebp
f01001fe:	c3                   	ret    

f01001ff <kbd_proc_data>:
f01001ff:	ba 64 00 00 00       	mov    $0x64,%edx
f0100204:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100205:	a8 01                	test   $0x1,%al
f0100207:	0f 84 f0 00 00 00    	je     f01002fd <kbd_proc_data+0xfe>
f010020d:	ba 60 00 00 00       	mov    $0x60,%edx
f0100212:	ec                   	in     (%dx),%al
f0100213:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100215:	3c e0                	cmp    $0xe0,%al
f0100217:	75 0d                	jne    f0100226 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100219:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f0100220:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100225:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100226:	55                   	push   %ebp
f0100227:	89 e5                	mov    %esp,%ebp
f0100229:	53                   	push   %ebx
f010022a:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022d:	84 c0                	test   %al,%al
f010022f:	79 36                	jns    f0100267 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100231:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100237:	89 cb                	mov    %ecx,%ebx
f0100239:	83 e3 40             	and    $0x40,%ebx
f010023c:	83 e0 7f             	and    $0x7f,%eax
f010023f:	85 db                	test   %ebx,%ebx
f0100241:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100244:	0f b6 d2             	movzbl %dl,%edx
f0100247:	0f b6 82 60 1f 10 f0 	movzbl -0xfefe0a0(%edx),%eax
f010024e:	83 c8 40             	or     $0x40,%eax
f0100251:	0f b6 c0             	movzbl %al,%eax
f0100254:	f7 d0                	not    %eax
f0100256:	21 c8                	and    %ecx,%eax
f0100258:	a3 20 23 11 f0       	mov    %eax,0xf0112320
		return 0;
f010025d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100262:	e9 9e 00 00 00       	jmp    f0100305 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100267:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f010026d:	f6 c1 40             	test   $0x40,%cl
f0100270:	74 0e                	je     f0100280 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100272:	83 c8 80             	or     $0xffffff80,%eax
f0100275:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100277:	83 e1 bf             	and    $0xffffffbf,%ecx
f010027a:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f0100280:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100283:	0f b6 82 60 1f 10 f0 	movzbl -0xfefe0a0(%edx),%eax
f010028a:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
f0100290:	0f b6 8a 60 1e 10 f0 	movzbl -0xfefe1a0(%edx),%ecx
f0100297:	31 c8                	xor    %ecx,%eax
f0100299:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010029e:	89 c1                	mov    %eax,%ecx
f01002a0:	83 e1 03             	and    $0x3,%ecx
f01002a3:	8b 0c 8d 40 1e 10 f0 	mov    -0xfefe1c0(,%ecx,4),%ecx
f01002aa:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ae:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b1:	a8 08                	test   $0x8,%al
f01002b3:	74 1b                	je     f01002d0 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f01002b5:	89 da                	mov    %ebx,%edx
f01002b7:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002ba:	83 f9 19             	cmp    $0x19,%ecx
f01002bd:	77 05                	ja     f01002c4 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f01002bf:	83 eb 20             	sub    $0x20,%ebx
f01002c2:	eb 0c                	jmp    f01002d0 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f01002c4:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c7:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ca:	83 fa 19             	cmp    $0x19,%edx
f01002cd:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d0:	f7 d0                	not    %eax
f01002d2:	a8 06                	test   $0x6,%al
f01002d4:	75 2d                	jne    f0100303 <kbd_proc_data+0x104>
f01002d6:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002dc:	75 25                	jne    f0100303 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002de:	83 ec 0c             	sub    $0xc,%esp
f01002e1:	68 0f 1e 10 f0       	push   $0xf0101e0f
f01002e6:	e8 9f 07 00 00       	call   f0100a8a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002eb:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f0:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f5:	ee                   	out    %al,(%dx)
f01002f6:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 08                	jmp    f0100305 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100303:	89 d8                	mov    %ebx,%eax
}
f0100305:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100308:	c9                   	leave  
f0100309:	c3                   	ret    

f010030a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010030a:	55                   	push   %ebp
f010030b:	89 e5                	mov    %esp,%ebp
f010030d:	57                   	push   %edi
f010030e:	56                   	push   %esi
f010030f:	53                   	push   %ebx
f0100310:	83 ec 1c             	sub    $0x1c,%esp
f0100313:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100315:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010031a:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;
	
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031b:	a8 20                	test   $0x20,%al
f010031d:	75 27                	jne    f0100346 <cons_putc+0x3c>
f010031f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100324:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100329:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032e:	89 ca                	mov    %ecx,%edx
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	ec                   	in     (%dx),%al
	     i++)
f0100334:	83 c3 01             	add    $0x1,%ebx
f0100337:	89 f2                	mov    %esi,%edx
f0100339:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;
	
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033a:	a8 20                	test   $0x20,%al
f010033c:	75 08                	jne    f0100346 <cons_putc+0x3c>
f010033e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100344:	7e e8                	jle    f010032e <cons_putc+0x24>
f0100346:	89 f8                	mov    %edi,%eax
f0100348:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100350:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100351:	ba 79 03 00 00       	mov    $0x379,%edx
f0100356:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100357:	84 c0                	test   %al,%al
f0100359:	78 27                	js     f0100382 <cons_putc+0x78>
f010035b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100360:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100365:	be 79 03 00 00       	mov    $0x379,%esi
f010036a:	89 ca                	mov    %ecx,%edx
f010036c:	ec                   	in     (%dx),%al
f010036d:	ec                   	in     (%dx),%al
f010036e:	ec                   	in     (%dx),%al
f010036f:	ec                   	in     (%dx),%al
f0100370:	83 c3 01             	add    $0x1,%ebx
f0100373:	89 f2                	mov    %esi,%edx
f0100375:	ec                   	in     (%dx),%al
f0100376:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010037c:	7f 04                	jg     f0100382 <cons_putc+0x78>
f010037e:	84 c0                	test   %al,%al
f0100380:	79 e8                	jns    f010036a <cons_putc+0x60>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100382:	ba 78 03 00 00       	mov    $0x378,%edx
f0100387:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010038b:	ee                   	out    %al,(%dx)
f010038c:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100391:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100396:	ee                   	out    %al,(%dx)
f0100397:	b8 08 00 00 00       	mov    $0x8,%eax
f010039c:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010039d:	89 fa                	mov    %edi,%edx
f010039f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003a5:	89 f8                	mov    %edi,%eax
f01003a7:	80 cc 07             	or     $0x7,%ah
f01003aa:	85 d2                	test   %edx,%edx
f01003ac:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003af:	89 f8                	mov    %edi,%eax
f01003b1:	0f b6 c0             	movzbl %al,%eax
f01003b4:	83 f8 09             	cmp    $0x9,%eax
f01003b7:	74 74                	je     f010042d <cons_putc+0x123>
f01003b9:	83 f8 09             	cmp    $0x9,%eax
f01003bc:	7f 0a                	jg     f01003c8 <cons_putc+0xbe>
f01003be:	83 f8 08             	cmp    $0x8,%eax
f01003c1:	74 14                	je     f01003d7 <cons_putc+0xcd>
f01003c3:	e9 99 00 00 00       	jmp    f0100461 <cons_putc+0x157>
f01003c8:	83 f8 0a             	cmp    $0xa,%eax
f01003cb:	74 3a                	je     f0100407 <cons_putc+0xfd>
f01003cd:	83 f8 0d             	cmp    $0xd,%eax
f01003d0:	74 3d                	je     f010040f <cons_putc+0x105>
f01003d2:	e9 8a 00 00 00       	jmp    f0100461 <cons_putc+0x157>
	case '\b':
		if (crt_pos > 0) {
f01003d7:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003de:	66 85 c0             	test   %ax,%ax
f01003e1:	0f 84 e6 00 00 00    	je     f01004cd <cons_putc+0x1c3>
			crt_pos--;
f01003e7:	83 e8 01             	sub    $0x1,%eax
f01003ea:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003f0:	0f b7 c0             	movzwl %ax,%eax
f01003f3:	66 81 e7 00 ff       	and    $0xff00,%di
f01003f8:	83 cf 20             	or     $0x20,%edi
f01003fb:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100401:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100405:	eb 78                	jmp    f010047f <cons_putc+0x175>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100407:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f010040e:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010040f:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f0100416:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010041c:	c1 e8 16             	shr    $0x16,%eax
f010041f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100422:	c1 e0 04             	shl    $0x4,%eax
f0100425:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f010042b:	eb 52                	jmp    f010047f <cons_putc+0x175>
		break;
	case '\t':
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 d3 fe ff ff       	call   f010030a <cons_putc>
		cons_putc(' ');
f0100437:	b8 20 00 00 00       	mov    $0x20,%eax
f010043c:	e8 c9 fe ff ff       	call   f010030a <cons_putc>
		cons_putc(' ');
f0100441:	b8 20 00 00 00       	mov    $0x20,%eax
f0100446:	e8 bf fe ff ff       	call   f010030a <cons_putc>
		cons_putc(' ');
f010044b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100450:	e8 b5 fe ff ff       	call   f010030a <cons_putc>
		cons_putc(' ');
f0100455:	b8 20 00 00 00       	mov    $0x20,%eax
f010045a:	e8 ab fe ff ff       	call   f010030a <cons_putc>
f010045f:	eb 1e                	jmp    f010047f <cons_putc+0x175>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100461:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f0100468:	8d 50 01             	lea    0x1(%eax),%edx
f010046b:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100472:	0f b7 c0             	movzwl %ax,%eax
f0100475:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f010047b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010047f:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f0100486:	cf 07 
f0100488:	76 43                	jbe    f01004cd <cons_putc+0x1c3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010048a:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f010048f:	83 ec 04             	sub    $0x4,%esp
f0100492:	68 00 0f 00 00       	push   $0xf00
f0100497:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010049d:	52                   	push   %edx
f010049e:	50                   	push   %eax
f010049f:	e8 01 14 00 00       	call   f01018a5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004a4:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01004aa:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004b0:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004b6:	83 c4 10             	add    $0x10,%esp
f01004b9:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004be:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004c1:	39 c2                	cmp    %eax,%edx
f01004c3:	75 f4                	jne    f01004b9 <cons_putc+0x1af>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004c5:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f01004cc:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004cd:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01004d3:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004d8:	89 ca                	mov    %ecx,%edx
f01004da:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004db:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004e2:	8d 71 01             	lea    0x1(%ecx),%esi
f01004e5:	89 d8                	mov    %ebx,%eax
f01004e7:	66 c1 e8 08          	shr    $0x8,%ax
f01004eb:	89 f2                	mov    %esi,%edx
f01004ed:	ee                   	out    %al,(%dx)
f01004ee:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004f3:	89 ca                	mov    %ecx,%edx
f01004f5:	ee                   	out    %al,(%dx)
f01004f6:	89 d8                	mov    %ebx,%eax
f01004f8:	89 f2                	mov    %esi,%edx
f01004fa:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004fe:	5b                   	pop    %ebx
f01004ff:	5e                   	pop    %esi
f0100500:	5f                   	pop    %edi
f0100501:	5d                   	pop    %ebp
f0100502:	c3                   	ret    

f0100503 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100503:	83 3d 54 25 11 f0 00 	cmpl   $0x0,0xf0112554
f010050a:	74 11                	je     f010051d <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010050c:	55                   	push   %ebp
f010050d:	89 e5                	mov    %esp,%ebp
f010050f:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100512:	b8 9d 01 10 f0       	mov    $0xf010019d,%eax
f0100517:	e8 a0 fc ff ff       	call   f01001bc <cons_intr>
}
f010051c:	c9                   	leave  
f010051d:	f3 c3                	repz ret 

f010051f <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010051f:	55                   	push   %ebp
f0100520:	89 e5                	mov    %esp,%ebp
f0100522:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100525:	b8 ff 01 10 f0       	mov    $0xf01001ff,%eax
f010052a:	e8 8d fc ff ff       	call   f01001bc <cons_intr>
}
f010052f:	c9                   	leave  
f0100530:	c3                   	ret    

f0100531 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100531:	55                   	push   %ebp
f0100532:	89 e5                	mov    %esp,%ebp
f0100534:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100537:	e8 c7 ff ff ff       	call   f0100503 <serial_intr>
	kbd_intr();
f010053c:	e8 de ff ff ff       	call   f010051f <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100541:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f0100546:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f010054c:	74 26                	je     f0100574 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010054e:	8d 50 01             	lea    0x1(%eax),%edx
f0100551:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f0100557:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010055e:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100560:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100566:	75 11                	jne    f0100579 <cons_getc+0x48>
			cons.rpos = 0;
f0100568:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f010056f:	00 00 00 
f0100572:	eb 05                	jmp    f0100579 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100574:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100579:	c9                   	leave  
f010057a:	c3                   	ret    

f010057b <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010057b:	55                   	push   %ebp
f010057c:	89 e5                	mov    %esp,%ebp
f010057e:	57                   	push   %edi
f010057f:	56                   	push   %esi
f0100580:	53                   	push   %ebx
f0100581:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100584:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010058b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100592:	5a a5 
	if (*cp != 0xA55A) {
f0100594:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010059b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010059f:	74 11                	je     f01005b2 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01005a1:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f01005a8:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005ab:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01005b0:	eb 16                	jmp    f01005c8 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005b2:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005b9:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f01005c0:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005c3:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005c8:	8b 3d 50 25 11 f0    	mov    0xf0112550,%edi
f01005ce:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005d3:	89 fa                	mov    %edi,%edx
f01005d5:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005d6:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d9:	89 da                	mov    %ebx,%edx
f01005db:	ec                   	in     (%dx),%al
f01005dc:	0f b6 c8             	movzbl %al,%ecx
f01005df:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005e7:	89 fa                	mov    %edi,%edx
f01005e9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ed:	89 35 4c 25 11 f0    	mov    %esi,0xf011254c
	crt_pos = pos;
f01005f3:	0f b6 c0             	movzbl %al,%eax
f01005f6:	09 c8                	or     %ecx,%eax
f01005f8:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005fe:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100603:	b8 00 00 00 00       	mov    $0x0,%eax
f0100608:	89 f2                	mov    %esi,%edx
f010060a:	ee                   	out    %al,(%dx)
f010060b:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100610:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100615:	ee                   	out    %al,(%dx)
f0100616:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010061b:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100620:	89 da                	mov    %ebx,%edx
f0100622:	ee                   	out    %al,(%dx)
f0100623:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100628:	b8 00 00 00 00       	mov    $0x0,%eax
f010062d:	ee                   	out    %al,(%dx)
f010062e:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100633:	b8 03 00 00 00       	mov    $0x3,%eax
f0100638:	ee                   	out    %al,(%dx)
f0100639:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010063e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100643:	ee                   	out    %al,(%dx)
f0100644:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100649:	b8 01 00 00 00       	mov    $0x1,%eax
f010064e:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010064f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100654:	ec                   	in     (%dx),%al
f0100655:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100657:	3c ff                	cmp    $0xff,%al
f0100659:	0f 95 c0             	setne  %al
f010065c:	0f b6 c0             	movzbl %al,%eax
f010065f:	a3 54 25 11 f0       	mov    %eax,0xf0112554
f0100664:	89 f2                	mov    %esi,%edx
f0100666:	ec                   	in     (%dx),%al
f0100667:	89 da                	mov    %ebx,%edx
f0100669:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010066a:	80 f9 ff             	cmp    $0xff,%cl
f010066d:	75 10                	jne    f010067f <cons_init+0x104>
		cprintf("Serial port does not exist!\n");
f010066f:	83 ec 0c             	sub    $0xc,%esp
f0100672:	68 1b 1e 10 f0       	push   $0xf0101e1b
f0100677:	e8 0e 04 00 00       	call   f0100a8a <cprintf>
f010067c:	83 c4 10             	add    $0x10,%esp
}
f010067f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100682:	5b                   	pop    %ebx
f0100683:	5e                   	pop    %esi
f0100684:	5f                   	pop    %edi
f0100685:	5d                   	pop    %ebp
f0100686:	c3                   	ret    

f0100687 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100687:	55                   	push   %ebp
f0100688:	89 e5                	mov    %esp,%ebp
f010068a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010068d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100690:	e8 75 fc ff ff       	call   f010030a <cons_putc>
}
f0100695:	c9                   	leave  
f0100696:	c3                   	ret    

f0100697 <getchar>:

int
getchar(void)
{
f0100697:	55                   	push   %ebp
f0100698:	89 e5                	mov    %esp,%ebp
f010069a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010069d:	e8 8f fe ff ff       	call   f0100531 <cons_getc>
f01006a2:	85 c0                	test   %eax,%eax
f01006a4:	74 f7                	je     f010069d <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006a6:	c9                   	leave  
f01006a7:	c3                   	ret    

f01006a8 <iscons>:

int
iscons(int fdnum)
{
f01006a8:	55                   	push   %ebp
f01006a9:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ab:	b8 01 00 00 00       	mov    $0x1,%eax
f01006b0:	5d                   	pop    %ebp
f01006b1:	c3                   	ret    

f01006b2 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006b2:	55                   	push   %ebp
f01006b3:	89 e5                	mov    %esp,%ebp
f01006b5:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006b8:	68 60 20 10 f0       	push   $0xf0102060
f01006bd:	68 7e 20 10 f0       	push   $0xf010207e
f01006c2:	68 83 20 10 f0       	push   $0xf0102083
f01006c7:	e8 be 03 00 00       	call   f0100a8a <cprintf>
f01006cc:	83 c4 0c             	add    $0xc,%esp
f01006cf:	68 24 21 10 f0       	push   $0xf0102124
f01006d4:	68 8c 20 10 f0       	push   $0xf010208c
f01006d9:	68 83 20 10 f0       	push   $0xf0102083
f01006de:	e8 a7 03 00 00       	call   f0100a8a <cprintf>
f01006e3:	83 c4 0c             	add    $0xc,%esp
f01006e6:	68 4c 21 10 f0       	push   $0xf010214c
f01006eb:	68 95 20 10 f0       	push   $0xf0102095
f01006f0:	68 83 20 10 f0       	push   $0xf0102083
f01006f5:	e8 90 03 00 00       	call   f0100a8a <cprintf>
	return 0;
}
f01006fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ff:	c9                   	leave  
f0100700:	c3                   	ret    

f0100701 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100701:	55                   	push   %ebp
f0100702:	89 e5                	mov    %esp,%ebp
f0100704:	83 ec 14             	sub    $0x14,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100707:	68 9a 20 10 f0       	push   $0xf010209a
f010070c:	e8 79 03 00 00       	call   f0100a8a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100711:	83 c4 0c             	add    $0xc,%esp
f0100714:	68 0c 00 10 00       	push   $0x10000c
f0100719:	68 0c 00 10 f0       	push   $0xf010000c
f010071e:	68 70 21 10 f0       	push   $0xf0102170
f0100723:	e8 62 03 00 00       	call   f0100a8a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100728:	83 c4 0c             	add    $0xc,%esp
f010072b:	68 21 1d 10 00       	push   $0x101d21
f0100730:	68 21 1d 10 f0       	push   $0xf0101d21
f0100735:	68 94 21 10 f0       	push   $0xf0102194
f010073a:	e8 4b 03 00 00       	call   f0100a8a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073f:	83 c4 0c             	add    $0xc,%esp
f0100742:	68 00 23 11 00       	push   $0x112300
f0100747:	68 00 23 11 f0       	push   $0xf0112300
f010074c:	68 b8 21 10 f0       	push   $0xf01021b8
f0100751:	e8 34 03 00 00       	call   f0100a8a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100756:	83 c4 0c             	add    $0xc,%esp
f0100759:	68 60 29 11 00       	push   $0x112960
f010075e:	68 60 29 11 f0       	push   $0xf0112960
f0100763:	68 dc 21 10 f0       	push   $0xf01021dc
f0100768:	e8 1d 03 00 00       	call   f0100a8a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010076d:	83 c4 08             	add    $0x8,%esp
f0100770:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100775:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f010077a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100780:	85 c0                	test   %eax,%eax
f0100782:	0f 48 c2             	cmovs  %edx,%eax
f0100785:	c1 f8 0a             	sar    $0xa,%eax
f0100788:	50                   	push   %eax
f0100789:	68 00 22 10 f0       	push   $0xf0102200
f010078e:	e8 f7 02 00 00       	call   f0100a8a <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f0100793:	b8 00 00 00 00       	mov    $0x0,%eax
f0100798:	c9                   	leave  
f0100799:	c3                   	ret    

f010079a <mon_time>:
	__asm__ volatile (".byte 0x0f, 0x31" : "=A"(*dest));
	//return dest;
}

int
mon_time(int argc, char **argv, struct Trapframe *tf){
f010079a:	55                   	push   %ebp
f010079b:	89 e5                	mov    %esp,%ebp
f010079d:	57                   	push   %edi
f010079e:	56                   	push   %esi
f010079f:	53                   	push   %ebx
f01007a0:	83 ec 2c             	sub    $0x2c,%esp
f01007a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01007a6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
		(end-entry+1023)/1024);
	return 0;
}

static inline void rdtsc(unsigned long long *dest){
	__asm__ volatile (".byte 0x0f, 0x31" : "=A"(*dest));
f01007a9:	0f 31                	rdtsc  
f01007ab:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01007ae:	89 55 dc             	mov    %edx,-0x24(%ebp)
mon_time(int argc, char **argv, struct Trapframe *tf){
	unsigned long long startT=0, endT=0;
	int ret_value = -1;
	rdtsc(&startT);
	//no func to be timed
	if(argc == 0) return -1;
f01007b1:	85 c9                	test   %ecx,%ecx
f01007b3:	0f 84 88 00 00 00    	je     f0100841 <mon_time+0xa7>
f01007b9:	be c0 22 10 f0       	mov    $0xf01022c0,%esi
f01007be:	bf e4 22 10 f0       	mov    $0xf01022e4,%edi
f01007c3:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
	for (int i = 0; i < NCOMMANDS; i++) {
		//invoke the func to be timed
		if (strcmp(argv[1], commands[i].name) == 0)
			ret_value = commands[i].func(argc - 1, argv + 1, tf);
f01007ca:	8d 43 04             	lea    0x4(%ebx),%eax
f01007cd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01007d0:	8d 41 ff             	lea    -0x1(%ecx),%eax
f01007d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	rdtsc(&startT);
	//no func to be timed
	if(argc == 0) return -1;
	for (int i = 0; i < NCOMMANDS; i++) {
		//invoke the func to be timed
		if (strcmp(argv[1], commands[i].name) == 0)
f01007d6:	83 ec 08             	sub    $0x8,%esp
f01007d9:	ff 36                	pushl  (%esi)
f01007db:	ff 73 04             	pushl  0x4(%ebx)
f01007de:	e8 93 0f 00 00       	call   f0101776 <strcmp>
f01007e3:	83 c4 10             	add    $0x10,%esp
f01007e6:	85 c0                	test   %eax,%eax
f01007e8:	75 15                	jne    f01007ff <mon_time+0x65>
			ret_value = commands[i].func(argc - 1, argv + 1, tf);
f01007ea:	83 ec 04             	sub    $0x4,%esp
f01007ed:	ff 75 10             	pushl  0x10(%ebp)
f01007f0:	ff 75 e0             	pushl  -0x20(%ebp)
f01007f3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007f6:	ff 56 08             	call   *0x8(%esi)
f01007f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01007fc:	83 c4 10             	add    $0x10,%esp
f01007ff:	83 c6 0c             	add    $0xc,%esi
	unsigned long long startT=0, endT=0;
	int ret_value = -1;
	rdtsc(&startT);
	//no func to be timed
	if(argc == 0) return -1;
	for (int i = 0; i < NCOMMANDS; i++) {
f0100802:	39 fe                	cmp    %edi,%esi
f0100804:	75 d0                	jne    f01007d6 <mon_time+0x3c>
		(end-entry+1023)/1024);
	return 0;
}

static inline void rdtsc(unsigned long long *dest){
	__asm__ volatile (".byte 0x0f, 0x31" : "=A"(*dest));
f0100806:	0f 31                	rdtsc  
f0100808:	89 c6                	mov    %eax,%esi
f010080a:	89 d7                	mov    %edx,%edi
		//invoke the func to be timed
		if (strcmp(argv[1], commands[i].name) == 0)
			ret_value = commands[i].func(argc - 1, argv + 1, tf);
	}
	rdtsc(&endT);
	if(ret_value == -1)
f010080c:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
f0100810:	75 12                	jne    f0100824 <mon_time+0x8a>
		cprintf("Unknown command '%s'\n", argv[0]);
f0100812:	83 ec 08             	sub    $0x8,%esp
f0100815:	ff 33                	pushl  (%ebx)
f0100817:	68 b3 20 10 f0       	push   $0xf01020b3
f010081c:	e8 69 02 00 00       	call   f0100a8a <cprintf>
f0100821:	83 c4 10             	add    $0x10,%esp
	cprintf("%s cycles: %d\n", argv[1], endT - startT);
f0100824:	2b 75 d8             	sub    -0x28(%ebp),%esi
f0100827:	1b 7d dc             	sbb    -0x24(%ebp),%edi
f010082a:	57                   	push   %edi
f010082b:	56                   	push   %esi
f010082c:	ff 73 04             	pushl  0x4(%ebx)
f010082f:	68 c9 20 10 f0       	push   $0xf01020c9
f0100834:	e8 51 02 00 00       	call   f0100a8a <cprintf>
	return ret_value;
f0100839:	83 c4 10             	add    $0x10,%esp
f010083c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010083f:	eb 05                	jmp    f0100846 <mon_time+0xac>
mon_time(int argc, char **argv, struct Trapframe *tf){
	unsigned long long startT=0, endT=0;
	int ret_value = -1;
	rdtsc(&startT);
	//no func to be timed
	if(argc == 0) return -1;
f0100841:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	rdtsc(&endT);
	if(ret_value == -1)
		cprintf("Unknown command '%s'\n", argv[0]);
	cprintf("%s cycles: %d\n", argv[1], endT - startT);
	return ret_value;
}
f0100846:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100849:	5b                   	pop    %ebx
f010084a:	5e                   	pop    %esi
f010084b:	5f                   	pop    %edi
f010084c:	5d                   	pop    %ebp
f010084d:	c3                   	ret    

f010084e <mon_backtrace>:
    return pretaddr;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010084e:	55                   	push   %ebp
f010084f:	89 e5                	mov    %esp,%ebp
f0100851:	57                   	push   %edi
f0100852:	56                   	push   %esi
f0100853:	53                   	push   %ebx
f0100854:	83 ec 58             	sub    $0x58,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100857:	89 e8                	mov    %ebp,%eax
f0100859:	89 c1                	mov    %eax,%ecx
	// Your code here.
	uint32_t* ebp = (uint32_t*)read_ebp();
f010085b:	89 c3                	mov    %eax,%ebx
	uint32_t eip = *(uint32_t*)(ebp + 1);
f010085d:	8b 70 04             	mov    0x4(%eax),%esi
	uint32_t arg1 = *(uint32_t*)(ebp + 2);
f0100860:	8b 78 08             	mov    0x8(%eax),%edi
	uint32_t arg2 = *(uint32_t*)(ebp + 3);
f0100863:	8b 40 0c             	mov    0xc(%eax),%eax
f0100866:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	uint32_t arg3 = *(uint32_t*)(ebp + 4);
f0100869:	8b 51 10             	mov    0x10(%ecx),%edx
f010086c:	89 55 b8             	mov    %edx,-0x48(%ebp)
	uint32_t arg4 = *(uint32_t*)(ebp + 5);
f010086f:	8b 41 14             	mov    0x14(%ecx),%eax
f0100872:	89 45 b4             	mov    %eax,-0x4c(%ebp)
	uint32_t arg5 = *(uint32_t*)(ebp + 6);
f0100875:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f0100878:	8b 41 18             	mov    0x18(%ecx),%eax
f010087b:	89 45 c0             	mov    %eax,-0x40(%ebp)
	cprintf("Stack backtrace:\n");
f010087e:	68 d8 20 10 f0       	push   $0xf01020d8
f0100883:	e8 02 02 00 00       	call   f0100a8a <cprintf>
	while(ebp != 0){
f0100888:	83 c4 10             	add    $0x10,%esp
f010088b:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
f010088f:	74 66                	je     f01008f7 <mon_backtrace+0xa9>
		cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n",eip, ebp, arg1, arg2, arg3, arg4, arg5);
		//the code below is wrong?
		//struct Eipdebuginfo* info = (struct Eipdebuginfo*)malloc(sizeof(struct Eipdebuginfo));
		struct Eipdebuginfo info;
		debuginfo_eip((uintptr_t)eip, &info);
f0100891:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0100894:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
	uint32_t arg3 = *(uint32_t*)(ebp + 4);
	uint32_t arg4 = *(uint32_t*)(ebp + 5);
	uint32_t arg5 = *(uint32_t*)(ebp + 6);
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
		cprintf("  eip %08x  ebp %08x  args %08x %08x %08x %08x %08x\n",eip, ebp, arg1, arg2, arg3, arg4, arg5);
f0100897:	ff 75 c0             	pushl  -0x40(%ebp)
f010089a:	51                   	push   %ecx
f010089b:	52                   	push   %edx
f010089c:	ff 75 c4             	pushl  -0x3c(%ebp)
f010089f:	57                   	push   %edi
f01008a0:	53                   	push   %ebx
f01008a1:	56                   	push   %esi
f01008a2:	68 2c 22 10 f0       	push   $0xf010222c
f01008a7:	e8 de 01 00 00       	call   f0100a8a <cprintf>
		//the code below is wrong?
		//struct Eipdebuginfo* info = (struct Eipdebuginfo*)malloc(sizeof(struct Eipdebuginfo));
		struct Eipdebuginfo info;
		debuginfo_eip((uintptr_t)eip, &info);
f01008ac:	83 c4 18             	add    $0x18,%esp
f01008af:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008b2:	50                   	push   %eax
f01008b3:	56                   	push   %esi
f01008b4:	e8 11 03 00 00       	call   f0100bca <debuginfo_eip>
		cprintf("	 %s:%d: %.*s+%d\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f01008b9:	83 c4 08             	add    $0x8,%esp
f01008bc:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01008bf:	56                   	push   %esi
f01008c0:	ff 75 d8             	pushl  -0x28(%ebp)
f01008c3:	ff 75 dc             	pushl  -0x24(%ebp)
f01008c6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008c9:	ff 75 d0             	pushl  -0x30(%ebp)
f01008cc:	68 ea 20 10 f0       	push   $0xf01020ea
f01008d1:	e8 b4 01 00 00       	call   f0100a8a <cprintf>

		ebp = (uint32_t*)*ebp;
f01008d6:	8b 1b                	mov    (%ebx),%ebx
		eip = *(uint32_t*)(ebp + 1);
f01008d8:	8b 73 04             	mov    0x4(%ebx),%esi
		arg1 = *(uint32_t*)(ebp + 2);
f01008db:	8b 7b 08             	mov    0x8(%ebx),%edi
		arg2 = *(uint32_t*)(ebp + 3);
f01008de:	8b 43 0c             	mov    0xc(%ebx),%eax
f01008e1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		arg3 = *(uint32_t*)(ebp + 4);
f01008e4:	8b 53 10             	mov    0x10(%ebx),%edx
		arg4 = *(uint32_t*)(ebp + 5);
f01008e7:	8b 4b 14             	mov    0x14(%ebx),%ecx
		arg5 = *(uint32_t*)(ebp + 6);
f01008ea:	8b 43 18             	mov    0x18(%ebx),%eax
f01008ed:	89 45 c0             	mov    %eax,-0x40(%ebp)
	uint32_t arg2 = *(uint32_t*)(ebp + 3);
	uint32_t arg3 = *(uint32_t*)(ebp + 4);
	uint32_t arg4 = *(uint32_t*)(ebp + 5);
	uint32_t arg5 = *(uint32_t*)(ebp + 6);
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f01008f0:	83 c4 20             	add    $0x20,%esp
f01008f3:	85 db                	test   %ebx,%ebx
f01008f5:	75 a0                	jne    f0100897 <mon_backtrace+0x49>
		arg5 = *(uint32_t*)(ebp + 6);
	}

    //cprintf("Backtrace success\n");
	return 0;
}
f01008f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01008fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ff:	5b                   	pop    %ebx
f0100900:	5e                   	pop    %esi
f0100901:	5f                   	pop    %edi
f0100902:	5d                   	pop    %ebp
f0100903:	c3                   	ret    

f0100904 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100904:	55                   	push   %ebp
f0100905:	89 e5                	mov    %esp,%ebp
f0100907:	57                   	push   %edi
f0100908:	56                   	push   %esi
f0100909:	53                   	push   %ebx
f010090a:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010090d:	68 64 22 10 f0       	push   $0xf0102264
f0100912:	e8 73 01 00 00       	call   f0100a8a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100917:	c7 04 24 88 22 10 f0 	movl   $0xf0102288,(%esp)
f010091e:	e8 67 01 00 00       	call   f0100a8a <cprintf>
f0100923:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100926:	83 ec 0c             	sub    $0xc,%esp
f0100929:	68 fc 20 10 f0       	push   $0xf01020fc
f010092e:	e8 71 0c 00 00       	call   f01015a4 <readline>
f0100933:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100935:	83 c4 10             	add    $0x10,%esp
f0100938:	85 c0                	test   %eax,%eax
f010093a:	74 ea                	je     f0100926 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010093c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100943:	be 00 00 00 00       	mov    $0x0,%esi
f0100948:	eb 0a                	jmp    f0100954 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010094a:	c6 03 00             	movb   $0x0,(%ebx)
f010094d:	89 f7                	mov    %esi,%edi
f010094f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100952:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100954:	0f b6 03             	movzbl (%ebx),%eax
f0100957:	84 c0                	test   %al,%al
f0100959:	74 6a                	je     f01009c5 <monitor+0xc1>
f010095b:	83 ec 08             	sub    $0x8,%esp
f010095e:	0f be c0             	movsbl %al,%eax
f0100961:	50                   	push   %eax
f0100962:	68 00 21 10 f0       	push   $0xf0102100
f0100967:	e8 8e 0e 00 00       	call   f01017fa <strchr>
f010096c:	83 c4 10             	add    $0x10,%esp
f010096f:	85 c0                	test   %eax,%eax
f0100971:	75 d7                	jne    f010094a <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100973:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100976:	74 4d                	je     f01009c5 <monitor+0xc1>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100978:	83 fe 0f             	cmp    $0xf,%esi
f010097b:	75 14                	jne    f0100991 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010097d:	83 ec 08             	sub    $0x8,%esp
f0100980:	6a 10                	push   $0x10
f0100982:	68 05 21 10 f0       	push   $0xf0102105
f0100987:	e8 fe 00 00 00       	call   f0100a8a <cprintf>
f010098c:	83 c4 10             	add    $0x10,%esp
f010098f:	eb 95                	jmp    f0100926 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100991:	8d 7e 01             	lea    0x1(%esi),%edi
f0100994:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100998:	0f b6 03             	movzbl (%ebx),%eax
f010099b:	84 c0                	test   %al,%al
f010099d:	75 0c                	jne    f01009ab <monitor+0xa7>
f010099f:	eb b1                	jmp    f0100952 <monitor+0x4e>
			buf++;
f01009a1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009a4:	0f b6 03             	movzbl (%ebx),%eax
f01009a7:	84 c0                	test   %al,%al
f01009a9:	74 a7                	je     f0100952 <monitor+0x4e>
f01009ab:	83 ec 08             	sub    $0x8,%esp
f01009ae:	0f be c0             	movsbl %al,%eax
f01009b1:	50                   	push   %eax
f01009b2:	68 00 21 10 f0       	push   $0xf0102100
f01009b7:	e8 3e 0e 00 00       	call   f01017fa <strchr>
f01009bc:	83 c4 10             	add    $0x10,%esp
f01009bf:	85 c0                	test   %eax,%eax
f01009c1:	74 de                	je     f01009a1 <monitor+0x9d>
f01009c3:	eb 8d                	jmp    f0100952 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01009c5:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009cc:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009cd:	85 f6                	test   %esi,%esi
f01009cf:	0f 84 51 ff ff ff    	je     f0100926 <monitor+0x22>
f01009d5:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009da:	83 ec 08             	sub    $0x8,%esp
f01009dd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009e0:	ff 34 85 c0 22 10 f0 	pushl  -0xfefdd40(,%eax,4)
f01009e7:	ff 75 a8             	pushl  -0x58(%ebp)
f01009ea:	e8 87 0d 00 00       	call   f0101776 <strcmp>
f01009ef:	83 c4 10             	add    $0x10,%esp
f01009f2:	85 c0                	test   %eax,%eax
f01009f4:	75 21                	jne    f0100a17 <monitor+0x113>
			return commands[i].func(argc, argv, tf);
f01009f6:	83 ec 04             	sub    $0x4,%esp
f01009f9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009fc:	ff 75 08             	pushl  0x8(%ebp)
f01009ff:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a02:	52                   	push   %edx
f0100a03:	56                   	push   %esi
f0100a04:	ff 14 85 c8 22 10 f0 	call   *-0xfefdd38(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a0b:	83 c4 10             	add    $0x10,%esp
f0100a0e:	85 c0                	test   %eax,%eax
f0100a10:	78 25                	js     f0100a37 <monitor+0x133>
f0100a12:	e9 0f ff ff ff       	jmp    f0100926 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a17:	83 c3 01             	add    $0x1,%ebx
f0100a1a:	83 fb 03             	cmp    $0x3,%ebx
f0100a1d:	75 bb                	jne    f01009da <monitor+0xd6>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a1f:	83 ec 08             	sub    $0x8,%esp
f0100a22:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a25:	68 b3 20 10 f0       	push   $0xf01020b3
f0100a2a:	e8 5b 00 00 00       	call   f0100a8a <cprintf>
f0100a2f:	83 c4 10             	add    $0x10,%esp
f0100a32:	e9 ef fe ff ff       	jmp    f0100926 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a37:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a3a:	5b                   	pop    %ebx
f0100a3b:	5e                   	pop    %esi
f0100a3c:	5f                   	pop    %edi
f0100a3d:	5d                   	pop    %ebp
f0100a3e:	c3                   	ret    

f0100a3f <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100a3f:	55                   	push   %ebp
f0100a40:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100a42:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100a45:	5d                   	pop    %ebp
f0100a46:	c3                   	ret    

f0100a47 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a47:	55                   	push   %ebp
f0100a48:	89 e5                	mov    %esp,%ebp
f0100a4a:	53                   	push   %ebx
f0100a4b:	83 ec 10             	sub    $0x10,%esp
f0100a4e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	cputchar(ch);
f0100a51:	ff 75 08             	pushl  0x8(%ebp)
f0100a54:	e8 2e fc ff ff       	call   f0100687 <cputchar>
    (*cnt)++;
f0100a59:	83 03 01             	addl   $0x1,(%ebx)
}
f0100a5c:	83 c4 10             	add    $0x10,%esp
f0100a5f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a62:	c9                   	leave  
f0100a63:	c3                   	ret    

f0100a64 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a64:	55                   	push   %ebp
f0100a65:	89 e5                	mov    %esp,%ebp
f0100a67:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100a6a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a71:	ff 75 0c             	pushl  0xc(%ebp)
f0100a74:	ff 75 08             	pushl  0x8(%ebp)
f0100a77:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a7a:	50                   	push   %eax
f0100a7b:	68 47 0a 10 f0       	push   $0xf0100a47
f0100a80:	e8 05 06 00 00       	call   f010108a <vprintfmt>
	return cnt;
}
f0100a85:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a88:	c9                   	leave  
f0100a89:	c3                   	ret    

f0100a8a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a8a:	55                   	push   %ebp
f0100a8b:	89 e5                	mov    %esp,%ebp
f0100a8d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a90:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a93:	50                   	push   %eax
f0100a94:	ff 75 08             	pushl  0x8(%ebp)
f0100a97:	e8 c8 ff ff ff       	call   f0100a64 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a9c:	c9                   	leave  
f0100a9d:	c3                   	ret    

f0100a9e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a9e:	55                   	push   %ebp
f0100a9f:	89 e5                	mov    %esp,%ebp
f0100aa1:	57                   	push   %edi
f0100aa2:	56                   	push   %esi
f0100aa3:	53                   	push   %ebx
f0100aa4:	83 ec 14             	sub    $0x14,%esp
f0100aa7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100aaa:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100aad:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ab0:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100ab3:	8b 1a                	mov    (%edx),%ebx
f0100ab5:	8b 01                	mov    (%ecx),%eax
f0100ab7:	89 45 f0             	mov    %eax,-0x10(%ebp)

	while (l <= r) {
f0100aba:	39 c3                	cmp    %eax,%ebx
f0100abc:	0f 8f 9a 00 00 00    	jg     f0100b5c <stab_binsearch+0xbe>
f0100ac2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f0100ac9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100acc:	01 d8                	add    %ebx,%eax
f0100ace:	89 c6                	mov    %eax,%esi
f0100ad0:	c1 ee 1f             	shr    $0x1f,%esi
f0100ad3:	01 c6                	add    %eax,%esi
f0100ad5:	d1 fe                	sar    %esi

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ad7:	39 de                	cmp    %ebx,%esi
f0100ad9:	0f 8c c4 00 00 00    	jl     f0100ba3 <stab_binsearch+0x105>
f0100adf:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100ae2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ae5:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100ae8:	0f b6 42 04          	movzbl 0x4(%edx),%eax
f0100aec:	39 c7                	cmp    %eax,%edi
f0100aee:	0f 84 b4 00 00 00    	je     f0100ba8 <stab_binsearch+0x10a>
f0100af4:	89 f0                	mov    %esi,%eax
			m--;
f0100af6:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100af9:	39 d8                	cmp    %ebx,%eax
f0100afb:	0f 8c a2 00 00 00    	jl     f0100ba3 <stab_binsearch+0x105>
f0100b01:	0f b6 4a f8          	movzbl -0x8(%edx),%ecx
f0100b05:	83 ea 0c             	sub    $0xc,%edx
f0100b08:	39 f9                	cmp    %edi,%ecx
f0100b0a:	75 ea                	jne    f0100af6 <stab_binsearch+0x58>
f0100b0c:	e9 99 00 00 00       	jmp    f0100baa <stab_binsearch+0x10c>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100b11:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b14:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100b16:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b19:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b20:	eb 2b                	jmp    f0100b4d <stab_binsearch+0xaf>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100b22:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b25:	76 14                	jbe    f0100b3b <stab_binsearch+0x9d>
			*region_right = m - 1;
f0100b27:	83 e8 01             	sub    $0x1,%eax
f0100b2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b2d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100b30:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b32:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b39:	eb 12                	jmp    f0100b4d <stab_binsearch+0xaf>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b3b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b3e:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100b40:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b44:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b46:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b4d:	39 5d f0             	cmp    %ebx,-0x10(%ebp)
f0100b50:	0f 8d 73 ff ff ff    	jge    f0100ac9 <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b56:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b5a:	75 0f                	jne    f0100b6b <stab_binsearch+0xcd>
		*region_right = *region_left - 1;
f0100b5c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b5f:	8b 00                	mov    (%eax),%eax
f0100b61:	83 e8 01             	sub    $0x1,%eax
f0100b64:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b67:	89 07                	mov    %eax,(%edi)
f0100b69:	eb 57                	jmp    f0100bc2 <stab_binsearch+0x124>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b6b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b6e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b70:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b73:	8b 0e                	mov    (%esi),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b75:	39 c8                	cmp    %ecx,%eax
f0100b77:	7e 23                	jle    f0100b9c <stab_binsearch+0xfe>
		     l > *region_left && stabs[l].n_type != type;
f0100b79:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b7c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b7f:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0100b82:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100b86:	39 df                	cmp    %ebx,%edi
f0100b88:	74 12                	je     f0100b9c <stab_binsearch+0xfe>
		     l--)
f0100b8a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b8d:	39 c8                	cmp    %ecx,%eax
f0100b8f:	7e 0b                	jle    f0100b9c <stab_binsearch+0xfe>
		     l > *region_left && stabs[l].n_type != type;
f0100b91:	0f b6 5a f8          	movzbl -0x8(%edx),%ebx
f0100b95:	83 ea 0c             	sub    $0xc,%edx
f0100b98:	39 df                	cmp    %ebx,%edi
f0100b9a:	75 ee                	jne    f0100b8a <stab_binsearch+0xec>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b9c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b9f:	89 07                	mov    %eax,(%edi)
	}
}
f0100ba1:	eb 1f                	jmp    f0100bc2 <stab_binsearch+0x124>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ba3:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100ba6:	eb a5                	jmp    f0100b4d <stab_binsearch+0xaf>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0100ba8:	89 f0                	mov    %esi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100baa:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bad:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100bb0:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100bb4:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bb7:	0f 82 54 ff ff ff    	jb     f0100b11 <stab_binsearch+0x73>
f0100bbd:	e9 60 ff ff ff       	jmp    f0100b22 <stab_binsearch+0x84>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100bc2:	83 c4 14             	add    $0x14,%esp
f0100bc5:	5b                   	pop    %ebx
f0100bc6:	5e                   	pop    %esi
f0100bc7:	5f                   	pop    %edi
f0100bc8:	5d                   	pop    %ebp
f0100bc9:	c3                   	ret    

f0100bca <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100bca:	55                   	push   %ebp
f0100bcb:	89 e5                	mov    %esp,%ebp
f0100bcd:	57                   	push   %edi
f0100bce:	56                   	push   %esi
f0100bcf:	53                   	push   %ebx
f0100bd0:	83 ec 3c             	sub    $0x3c,%esp
f0100bd3:	8b 75 08             	mov    0x8(%ebp),%esi
f0100bd6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100bd9:	c7 03 e4 22 10 f0    	movl   $0xf01022e4,(%ebx)
	info->eip_line = 0;
f0100bdf:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100be6:	c7 43 08 e4 22 10 f0 	movl   $0xf01022e4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100bed:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100bf4:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100bf7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bfe:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100c04:	76 11                	jbe    f0100c17 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c06:	b8 b2 7c 10 f0       	mov    $0xf0107cb2,%eax
f0100c0b:	3d c5 62 10 f0       	cmp    $0xf01062c5,%eax
f0100c10:	77 19                	ja     f0100c2b <debuginfo_eip+0x61>
f0100c12:	e9 d0 01 00 00       	jmp    f0100de7 <debuginfo_eip+0x21d>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100c17:	83 ec 04             	sub    $0x4,%esp
f0100c1a:	68 ee 22 10 f0       	push   $0xf01022ee
f0100c1f:	6a 7f                	push   $0x7f
f0100c21:	68 fb 22 10 f0       	push   $0xf01022fb
f0100c26:	e8 e1 f4 ff ff       	call   f010010c <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c2b:	80 3d b1 7c 10 f0 00 	cmpb   $0x0,0xf0107cb1
f0100c32:	0f 85 b6 01 00 00    	jne    f0100dee <debuginfo_eip+0x224>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c38:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c3f:	b8 c4 62 10 f0       	mov    $0xf01062c4,%eax
f0100c44:	2d 98 25 10 f0       	sub    $0xf0102598,%eax
f0100c49:	c1 f8 02             	sar    $0x2,%eax
f0100c4c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c52:	83 e8 01             	sub    $0x1,%eax
f0100c55:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c58:	83 ec 08             	sub    $0x8,%esp
f0100c5b:	56                   	push   %esi
f0100c5c:	6a 64                	push   $0x64
f0100c5e:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c61:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c64:	b8 98 25 10 f0       	mov    $0xf0102598,%eax
f0100c69:	e8 30 fe ff ff       	call   f0100a9e <stab_binsearch>
	if (lfile == 0)
f0100c6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c71:	83 c4 10             	add    $0x10,%esp
f0100c74:	85 c0                	test   %eax,%eax
f0100c76:	0f 84 79 01 00 00    	je     f0100df5 <debuginfo_eip+0x22b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c7c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c82:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c85:	83 ec 08             	sub    $0x8,%esp
f0100c88:	56                   	push   %esi
f0100c89:	6a 24                	push   $0x24
f0100c8b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c8e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c91:	b8 98 25 10 f0       	mov    $0xf0102598,%eax
f0100c96:	e8 03 fe ff ff       	call   f0100a9e <stab_binsearch>

	if (lfun <= rfun) {
f0100c9b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c9e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ca1:	83 c4 10             	add    $0x10,%esp
f0100ca4:	39 d0                	cmp    %edx,%eax
f0100ca6:	7f 40                	jg     f0100ce8 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ca8:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100cab:	c1 e1 02             	shl    $0x2,%ecx
f0100cae:	8d b9 98 25 10 f0    	lea    -0xfefda68(%ecx),%edi
f0100cb4:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100cb7:	8b b9 98 25 10 f0    	mov    -0xfefda68(%ecx),%edi
f0100cbd:	b9 b2 7c 10 f0       	mov    $0xf0107cb2,%ecx
f0100cc2:	81 e9 c5 62 10 f0    	sub    $0xf01062c5,%ecx
f0100cc8:	39 cf                	cmp    %ecx,%edi
f0100cca:	73 09                	jae    f0100cd5 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ccc:	81 c7 c5 62 10 f0    	add    $0xf01062c5,%edi
f0100cd2:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100cd5:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100cd8:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100cdb:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100cde:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ce0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ce3:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100ce6:	eb 0f                	jmp    f0100cf7 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ce8:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100ceb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100cf1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cf4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100cf7:	83 ec 08             	sub    $0x8,%esp
f0100cfa:	6a 3a                	push   $0x3a
f0100cfc:	ff 73 08             	pushl  0x8(%ebx)
f0100cff:	e8 2c 0b 00 00       	call   f0101830 <strfind>
f0100d04:	2b 43 08             	sub    0x8(%ebx),%eax
f0100d07:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	//use text segment line number
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d0a:	83 c4 08             	add    $0x8,%esp
f0100d0d:	56                   	push   %esi
f0100d0e:	6a 44                	push   $0x44
f0100d10:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d13:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d16:	b8 98 25 10 f0       	mov    $0xf0102598,%eax
f0100d1b:	e8 7e fd ff ff       	call   f0100a9e <stab_binsearch>
	if(lline <= rline)
f0100d20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d23:	83 c4 10             	add    $0x10,%esp
f0100d26:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100d29:	0f 8f cd 00 00 00    	jg     f0100dfc <debuginfo_eip+0x232>
		// description field
		info->eip_line = stabs[lline].n_desc;
f0100d2f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d32:	8d 34 95 98 25 10 f0 	lea    -0xfefda68(,%edx,4),%esi
f0100d39:	0f b7 56 06          	movzwl 0x6(%esi),%edx
f0100d3d:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d40:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d43:	39 f8                	cmp    %edi,%eax
f0100d45:	7c 54                	jl     f0100d9b <debuginfo_eip+0x1d1>
	       && stabs[lline].n_type != N_SOL
f0100d47:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100d4b:	80 fa 84             	cmp    $0x84,%dl
f0100d4e:	74 2b                	je     f0100d7b <debuginfo_eip+0x1b1>
f0100d50:	89 f1                	mov    %esi,%ecx
f0100d52:	83 c6 08             	add    $0x8,%esi
f0100d55:	eb 16                	jmp    f0100d6d <debuginfo_eip+0x1a3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100d57:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d5a:	39 f8                	cmp    %edi,%eax
f0100d5c:	7c 3d                	jl     f0100d9b <debuginfo_eip+0x1d1>
	       && stabs[lline].n_type != N_SOL
f0100d5e:	0f b6 51 f8          	movzbl -0x8(%ecx),%edx
f0100d62:	83 e9 0c             	sub    $0xc,%ecx
f0100d65:	83 ee 0c             	sub    $0xc,%esi
f0100d68:	80 fa 84             	cmp    $0x84,%dl
f0100d6b:	74 0e                	je     f0100d7b <debuginfo_eip+0x1b1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d6d:	80 fa 64             	cmp    $0x64,%dl
f0100d70:	75 e5                	jne    f0100d57 <debuginfo_eip+0x18d>
f0100d72:	83 3e 00             	cmpl   $0x0,(%esi)
f0100d75:	74 e0                	je     f0100d57 <debuginfo_eip+0x18d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d77:	39 c7                	cmp    %eax,%edi
f0100d79:	7f 20                	jg     f0100d9b <debuginfo_eip+0x1d1>
f0100d7b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100d7e:	8b 14 85 98 25 10 f0 	mov    -0xfefda68(,%eax,4),%edx
f0100d85:	b8 b2 7c 10 f0       	mov    $0xf0107cb2,%eax
f0100d8a:	2d c5 62 10 f0       	sub    $0xf01062c5,%eax
f0100d8f:	39 c2                	cmp    %eax,%edx
f0100d91:	73 08                	jae    f0100d9b <debuginfo_eip+0x1d1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d93:	81 c2 c5 62 10 f0    	add    $0xf01062c5,%edx
f0100d99:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d9b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d9e:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100da1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100da6:	39 f1                	cmp    %esi,%ecx
f0100da8:	7d 6c                	jge    f0100e16 <debuginfo_eip+0x24c>
		for (lline = lfun + 1;
f0100daa:	8d 41 01             	lea    0x1(%ecx),%eax
f0100dad:	39 c6                	cmp    %eax,%esi
f0100daf:	7e 52                	jle    f0100e03 <debuginfo_eip+0x239>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100db1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100db4:	c1 e2 02             	shl    $0x2,%edx
f0100db7:	80 ba 9c 25 10 f0 a0 	cmpb   $0xa0,-0xfefda64(%edx)
f0100dbe:	75 4a                	jne    f0100e0a <debuginfo_eip+0x240>
f0100dc0:	8d 41 02             	lea    0x2(%ecx),%eax
f0100dc3:	81 c2 8c 25 10 f0    	add    $0xf010258c,%edx
		     lline++)
			info->eip_fn_narg++;
f0100dc9:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100dcd:	39 c6                	cmp    %eax,%esi
f0100dcf:	74 40                	je     f0100e11 <debuginfo_eip+0x247>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100dd1:	0f b6 4a 1c          	movzbl 0x1c(%edx),%ecx
f0100dd5:	83 c0 01             	add    $0x1,%eax
f0100dd8:	83 c2 0c             	add    $0xc,%edx
f0100ddb:	80 f9 a0             	cmp    $0xa0,%cl
f0100dde:	74 e9                	je     f0100dc9 <debuginfo_eip+0x1ff>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100de0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100de5:	eb 2f                	jmp    f0100e16 <debuginfo_eip+0x24c>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100de7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dec:	eb 28                	jmp    f0100e16 <debuginfo_eip+0x24c>
f0100dee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100df3:	eb 21                	jmp    f0100e16 <debuginfo_eip+0x24c>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100df5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100dfa:	eb 1a                	jmp    f0100e16 <debuginfo_eip+0x24c>
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline)
		// description field
		info->eip_line = stabs[lline].n_desc;
	else
		return -1;
f0100dfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e01:	eb 13                	jmp    f0100e16 <debuginfo_eip+0x24c>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e03:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e08:	eb 0c                	jmp    f0100e16 <debuginfo_eip+0x24c>
f0100e0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e0f:	eb 05                	jmp    f0100e16 <debuginfo_eip+0x24c>
f0100e11:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e16:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e19:	5b                   	pop    %ebx
f0100e1a:	5e                   	pop    %esi
f0100e1b:	5f                   	pop    %edi
f0100e1c:	5d                   	pop    %ebp
f0100e1d:	c3                   	ret    

f0100e1e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e1e:	55                   	push   %ebp
f0100e1f:	89 e5                	mov    %esp,%ebp
f0100e21:	57                   	push   %edi
f0100e22:	56                   	push   %esi
f0100e23:	53                   	push   %ebx
f0100e24:	83 ec 2c             	sub    $0x2c,%esp
f0100e27:	89 c3                	mov    %eax,%ebx
f0100e29:	89 d6                	mov    %edx,%esi
f0100e2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e2e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100e31:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e34:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100e37:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e3a:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100e3d:	8b 7d 18             	mov    0x18(%ebp),%edi
	// space on the right side if neccesary.
	// you can add helper function if needed.
	// your code here:

	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e40:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e43:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e48:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100e4b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100e4e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e51:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e54:	39 4d dc             	cmp    %ecx,-0x24(%ebp)
f0100e57:	72 26                	jb     f0100e7f <printnum+0x61>
f0100e59:	39 55 10             	cmp    %edx,0x10(%ebp)
f0100e5c:	76 21                	jbe    f0100e7f <printnum+0x61>
		else
			printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		// the padc is assigned by the user, can be a number or any other character
		while (padc != '+' && padc != '-' && --width > 0)
f0100e5e:	8d 47 d5             	lea    -0x2b(%edi),%eax
f0100e61:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0100e66:	0f 84 4c 01 00 00    	je     f0100fb8 <printnum+0x19a>
f0100e6c:	83 6d 14 01          	subl   $0x1,0x14(%ebp)
f0100e70:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
f0100e74:	0f 8f 7f 01 00 00    	jg     f0100ff9 <printnum+0x1db>
f0100e7a:	e9 39 01 00 00       	jmp    f0100fb8 <printnum+0x19a>
	// your code here:

	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		//padding to left, '+' means not the first recursion
		if(padc == '-')
f0100e7f:	83 ff 2d             	cmp    $0x2d,%edi
f0100e82:	75 74                	jne    f0100ef8 <printnum+0xda>
			printnum(putch, putdat, num / base, base, width - 1, '+');
f0100e84:	83 ec 0c             	sub    $0xc,%esp
f0100e87:	6a 2b                	push   $0x2b
f0100e89:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e8c:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100e8f:	52                   	push   %edx
f0100e90:	ff 75 10             	pushl  0x10(%ebp)
f0100e93:	83 ec 08             	sub    $0x8,%esp
f0100e96:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e99:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e9c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e9f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ea2:	e8 f9 0b 00 00       	call   f0101aa0 <__udivdi3>
f0100ea7:	83 c4 18             	add    $0x18,%esp
f0100eaa:	52                   	push   %edx
f0100eab:	50                   	push   %eax
f0100eac:	89 f2                	mov    %esi,%edx
f0100eae:	89 d8                	mov    %ebx,%eax
f0100eb0:	e8 69 ff ff ff       	call   f0100e1e <printnum>
		while (padc != '+' && padc != '-' && --width > 0)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100eb5:	83 c4 18             	add    $0x18,%esp
f0100eb8:	56                   	push   %esi
f0100eb9:	83 ec 04             	sub    $0x4,%esp
f0100ebc:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ebf:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ec2:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100ec5:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ec8:	e8 03 0d 00 00       	call   f0101bd0 <__umoddi3>
f0100ecd:	83 c4 14             	add    $0x14,%esp
f0100ed0:	0f be 80 09 23 10 f0 	movsbl -0xfefdcf7(%eax),%eax
f0100ed7:	50                   	push   %eax
f0100ed8:	ff d3                	call   *%ebx
f0100eda:	83 c4 10             	add    $0x10,%esp
f0100edd:	bf 00 00 00 00       	mov    $0x0,%edi
f0100ee2:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0100ee5:	89 fb                	mov    %edi,%ebx
f0100ee7:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0100eea:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100eed:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100ef0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ef3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100ef6:	eb 6e                	jmp    f0100f66 <printnum+0x148>
		if(padc == '-')
			printnum(putch, putdat, num / base, base, width - 1, '+');
		//padding to right
		// the padc is assigned by the user, can be a number or any other character
		else
			printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ef8:	83 ec 0c             	sub    $0xc,%esp
f0100efb:	57                   	push   %edi
f0100efc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eff:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100f02:	52                   	push   %edx
f0100f03:	ff 75 10             	pushl  0x10(%ebp)
f0100f06:	83 ec 08             	sub    $0x8,%esp
f0100f09:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f0c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100f0f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f12:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f15:	e8 86 0b 00 00       	call   f0101aa0 <__udivdi3>
f0100f1a:	83 c4 18             	add    $0x18,%esp
f0100f1d:	52                   	push   %edx
f0100f1e:	50                   	push   %eax
f0100f1f:	89 f2                	mov    %esi,%edx
f0100f21:	89 d8                	mov    %ebx,%eax
f0100f23:	e8 f6 fe ff ff       	call   f0100e1e <printnum>
		while (padc != '+' && padc != '-' && --width > 0)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100f28:	83 c4 18             	add    $0x18,%esp
f0100f2b:	56                   	push   %esi
f0100f2c:	83 ec 04             	sub    $0x4,%esp
f0100f2f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f32:	ff 75 d8             	pushl  -0x28(%ebp)
f0100f35:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f38:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f3b:	e8 90 0c 00 00       	call   f0101bd0 <__umoddi3>
f0100f40:	83 c4 14             	add    $0x14,%esp
f0100f43:	0f be 80 09 23 10 f0 	movsbl -0xfefdcf7(%eax),%eax
f0100f4a:	50                   	push   %eax
f0100f4b:	ff d3                	call   *%ebx
f0100f4d:	83 c4 10             	add    $0x10,%esp
f0100f50:	e9 b9 00 00 00       	jmp    f010100e <printnum+0x1f0>
		else
			printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		// the padc is assigned by the user, can be a number or any other character
		while (padc != '+' && padc != '-' && --width > 0)
f0100f55:	83 eb 01             	sub    $0x1,%ebx
f0100f58:	0f 85 89 00 00 00    	jne    f0100fe7 <printnum+0x1c9>
f0100f5e:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0100f61:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f64:	eb 52                	jmp    f0100fb8 <printnum+0x19a>
	putch("0123456789abcdef"[num % base], putdat);

	if(padc == '-'){
		int num_length = 0;
		while(num >= base){
			num /= base;
f0100f66:	57                   	push   %edi
f0100f67:	56                   	push   %esi
f0100f68:	52                   	push   %edx
f0100f69:	50                   	push   %eax
f0100f6a:	e8 31 0b 00 00       	call   f0101aa0 <__udivdi3>
f0100f6f:	83 c4 10             	add    $0x10,%esp
			num_length ++;
f0100f72:	83 c3 01             	add    $0x1,%ebx
	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);

	if(padc == '-'){
		int num_length = 0;
		while(num >= base){
f0100f75:	39 d7                	cmp    %edx,%edi
f0100f77:	72 ed                	jb     f0100f66 <printnum+0x148>
f0100f79:	77 15                	ja     f0100f90 <printnum+0x172>
f0100f7b:	39 c6                	cmp    %eax,%esi
f0100f7d:	76 e7                	jbe    f0100f66 <printnum+0x148>
f0100f7f:	89 df                	mov    %ebx,%edi
f0100f81:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f84:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0100f87:	eb 0f                	jmp    f0100f98 <printnum+0x17a>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);

	if(padc == '-'){
f0100f89:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f8e:	eb 08                	jmp    f0100f98 <printnum+0x17a>
f0100f90:	89 df                	mov    %ebx,%edi
f0100f92:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f95:	8b 75 cc             	mov    -0x34(%ebp),%esi
		int num_length = 0;
		while(num >= base){
			num /= base;
			num_length ++;
		}
		width -= num_length;
f0100f98:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f9b:	29 f8                	sub    %edi,%eax
f0100f9d:	89 c7                	mov    %eax,%edi
		while(--width > 0)
f0100f9f:	83 ef 01             	sub    $0x1,%edi
f0100fa2:	85 ff                	test   %edi,%edi
f0100fa4:	7e 68                	jle    f010100e <printnum+0x1f0>
			putch(' ', putdat);
f0100fa6:	83 ec 08             	sub    $0x8,%esp
f0100fa9:	56                   	push   %esi
f0100faa:	6a 20                	push   $0x20
f0100fac:	ff d3                	call   *%ebx
		while(num >= base){
			num /= base;
			num_length ++;
		}
		width -= num_length;
		while(--width > 0)
f0100fae:	83 c4 10             	add    $0x10,%esp
f0100fb1:	83 ef 01             	sub    $0x1,%edi
f0100fb4:	75 f0                	jne    f0100fa6 <printnum+0x188>
f0100fb6:	eb 56                	jmp    f010100e <printnum+0x1f0>
		while (padc != '+' && padc != '-' && --width > 0)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100fb8:	83 ec 08             	sub    $0x8,%esp
f0100fbb:	56                   	push   %esi
f0100fbc:	83 ec 04             	sub    $0x4,%esp
f0100fbf:	ff 75 dc             	pushl  -0x24(%ebp)
f0100fc2:	ff 75 d8             	pushl  -0x28(%ebp)
f0100fc5:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100fc8:	ff 75 d0             	pushl  -0x30(%ebp)
f0100fcb:	e8 00 0c 00 00       	call   f0101bd0 <__umoddi3>
f0100fd0:	83 c4 14             	add    $0x14,%esp
f0100fd3:	0f be 80 09 23 10 f0 	movsbl -0xfefdcf7(%eax),%eax
f0100fda:	50                   	push   %eax
f0100fdb:	ff d3                	call   *%ebx

	if(padc == '-'){
f0100fdd:	83 c4 10             	add    $0x10,%esp
f0100fe0:	83 ff 2d             	cmp    $0x2d,%edi
f0100fe3:	75 29                	jne    f010100e <printnum+0x1f0>
f0100fe5:	eb a2                	jmp    f0100f89 <printnum+0x16b>
			printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		// the padc is assigned by the user, can be a number or any other character
		while (padc != '+' && padc != '-' && --width > 0)
			putch(padc, putdat);
f0100fe7:	83 ec 08             	sub    $0x8,%esp
f0100fea:	56                   	push   %esi
f0100feb:	57                   	push   %edi
f0100fec:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fef:	ff d0                	call   *%eax
f0100ff1:	83 c4 10             	add    $0x10,%esp
f0100ff4:	e9 5c ff ff ff       	jmp    f0100f55 <printnum+0x137>
f0100ff9:	83 ec 08             	sub    $0x8,%esp
f0100ffc:	56                   	push   %esi
f0100ffd:	57                   	push   %edi
f0100ffe:	ff d3                	call   *%ebx
f0101000:	83 c4 10             	add    $0x10,%esp
f0101003:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0101006:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101009:	e9 47 ff ff ff       	jmp    f0100f55 <printnum+0x137>
		}
		width -= num_length;
		while(--width > 0)
			putch(' ', putdat);
	}
}
f010100e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101011:	5b                   	pop    %ebx
f0101012:	5e                   	pop    %esi
f0101013:	5f                   	pop    %edi
f0101014:	5d                   	pop    %ebp
f0101015:	c3                   	ret    

f0101016 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101016:	55                   	push   %ebp
f0101017:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101019:	83 fa 01             	cmp    $0x1,%edx
f010101c:	7e 0e                	jle    f010102c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010101e:	8b 10                	mov    (%eax),%edx
f0101020:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101023:	89 08                	mov    %ecx,(%eax)
f0101025:	8b 02                	mov    (%edx),%eax
f0101027:	8b 52 04             	mov    0x4(%edx),%edx
f010102a:	eb 22                	jmp    f010104e <getuint+0x38>
	else if (lflag)
f010102c:	85 d2                	test   %edx,%edx
f010102e:	74 10                	je     f0101040 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101030:	8b 10                	mov    (%eax),%edx
f0101032:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101035:	89 08                	mov    %ecx,(%eax)
f0101037:	8b 02                	mov    (%edx),%eax
f0101039:	ba 00 00 00 00       	mov    $0x0,%edx
f010103e:	eb 0e                	jmp    f010104e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101040:	8b 10                	mov    (%eax),%edx
f0101042:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101045:	89 08                	mov    %ecx,(%eax)
f0101047:	8b 02                	mov    (%edx),%eax
f0101049:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010104e:	5d                   	pop    %ebp
f010104f:	c3                   	ret    

f0101050 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101050:	55                   	push   %ebp
f0101051:	89 e5                	mov    %esp,%ebp
f0101053:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101056:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010105a:	8b 10                	mov    (%eax),%edx
f010105c:	3b 50 04             	cmp    0x4(%eax),%edx
f010105f:	73 0a                	jae    f010106b <sprintputch+0x1b>
		*b->buf++ = ch;
f0101061:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101064:	89 08                	mov    %ecx,(%eax)
f0101066:	8b 45 08             	mov    0x8(%ebp),%eax
f0101069:	88 02                	mov    %al,(%edx)
}
f010106b:	5d                   	pop    %ebp
f010106c:	c3                   	ret    

f010106d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010106d:	55                   	push   %ebp
f010106e:	89 e5                	mov    %esp,%ebp
f0101070:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0101073:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101076:	50                   	push   %eax
f0101077:	ff 75 10             	pushl  0x10(%ebp)
f010107a:	ff 75 0c             	pushl  0xc(%ebp)
f010107d:	ff 75 08             	pushl  0x8(%ebp)
f0101080:	e8 05 00 00 00       	call   f010108a <vprintfmt>
	va_end(ap);
}
f0101085:	83 c4 10             	add    $0x10,%esp
f0101088:	c9                   	leave  
f0101089:	c3                   	ret    

f010108a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010108a:	55                   	push   %ebp
f010108b:	89 e5                	mov    %esp,%ebp
f010108d:	57                   	push   %edi
f010108e:	56                   	push   %esi
f010108f:	53                   	push   %ebx
f0101090:	83 ec 2c             	sub    $0x2c,%esp
f0101093:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101096:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101099:	eb 03                	jmp    f010109e <vprintfmt+0x14>
			break;

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f010109b:	89 75 10             	mov    %esi,0x10(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag, precedeflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010109e:	8b 45 10             	mov    0x10(%ebp),%eax
f01010a1:	8d 70 01             	lea    0x1(%eax),%esi
f01010a4:	0f b6 00             	movzbl (%eax),%eax
f01010a7:	83 f8 25             	cmp    $0x25,%eax
f01010aa:	74 27                	je     f01010d3 <vprintfmt+0x49>
			if (ch == '\0')
f01010ac:	85 c0                	test   %eax,%eax
f01010ae:	75 0d                	jne    f01010bd <vprintfmt+0x33>
f01010b0:	e9 7f 04 00 00       	jmp    f0101534 <vprintfmt+0x4aa>
f01010b5:	85 c0                	test   %eax,%eax
f01010b7:	0f 84 77 04 00 00    	je     f0101534 <vprintfmt+0x4aa>
				return;
			putch(ch, putdat);
f01010bd:	83 ec 08             	sub    $0x8,%esp
f01010c0:	53                   	push   %ebx
f01010c1:	50                   	push   %eax
f01010c2:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag, precedeflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01010c4:	83 c6 01             	add    $0x1,%esi
f01010c7:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f01010cb:	83 c4 10             	add    $0x10,%esp
f01010ce:	83 f8 25             	cmp    $0x25,%eax
f01010d1:	75 e2                	jne    f01010b5 <vprintfmt+0x2b>
			padc = '0';
			goto reswitch;

		//flag to precede the result with '+' for positive numbers
		case '+':
			precedeflag = 1;
f01010d3:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f01010d7:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f01010de:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01010e5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01010ec:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01010f3:	ba 00 00 00 00       	mov    $0x0,%edx
f01010f8:	eb 07                	jmp    f0101101 <vprintfmt+0x77>
		precision = -1;
		lflag = 0;
		altflag = 0;
		precedeflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010fa:	8b 75 10             	mov    0x10(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01010fd:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
		precision = -1;
		lflag = 0;
		altflag = 0;
		precedeflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101101:	8d 46 01             	lea    0x1(%esi),%eax
f0101104:	89 45 10             	mov    %eax,0x10(%ebp)
f0101107:	0f b6 06             	movzbl (%esi),%eax
f010110a:	0f b6 c8             	movzbl %al,%ecx
f010110d:	83 e8 23             	sub    $0x23,%eax
f0101110:	3c 55                	cmp    $0x55,%al
f0101112:	0f 87 dd 03 00 00    	ja     f01014f5 <vprintfmt+0x46b>
f0101118:	0f b6 c0             	movzbl %al,%eax
f010111b:	ff 24 85 14 24 10 f0 	jmp    *-0xfefdbec(,%eax,4)
f0101122:	8b 75 10             	mov    0x10(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101125:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0101129:	eb d6                	jmp    f0101101 <vprintfmt+0x77>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010112b:	8d 41 d0             	lea    -0x30(%ecx),%eax
f010112e:	89 45 d0             	mov    %eax,-0x30(%ebp)
				ch = *fmt;
f0101131:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0101135:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0101138:	83 f9 09             	cmp    $0x9,%ecx
f010113b:	77 6e                	ja     f01011ab <vprintfmt+0x121>
f010113d:	8b 75 10             	mov    0x10(%ebp),%esi
f0101140:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101143:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101146:	eb 0c                	jmp    f0101154 <vprintfmt+0xca>
		precision = -1;
		lflag = 0;
		altflag = 0;
		precedeflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101148:	8b 75 10             	mov    0x10(%ebp),%esi
			padc = '0';
			goto reswitch;

		//flag to precede the result with '+' for positive numbers
		case '+':
			precedeflag = 1;
f010114b:	c7 45 cc 01 00 00 00 	movl   $0x1,-0x34(%ebp)
			goto reswitch;
f0101152:	eb ad                	jmp    f0101101 <vprintfmt+0x77>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101154:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0101157:	8d 14 92             	lea    (%edx,%edx,4),%edx
f010115a:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f010115e:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0101161:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0101164:	83 f9 09             	cmp    $0x9,%ecx
f0101167:	76 eb                	jbe    f0101154 <vprintfmt+0xca>
f0101169:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010116c:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010116f:	eb 3d                	jmp    f01011ae <vprintfmt+0x124>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101171:	8b 45 14             	mov    0x14(%ebp),%eax
f0101174:	8d 48 04             	lea    0x4(%eax),%ecx
f0101177:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010117a:	8b 00                	mov    (%eax),%eax
f010117c:	89 45 d0             	mov    %eax,-0x30(%ebp)
		precision = -1;
		lflag = 0;
		altflag = 0;
		precedeflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010117f:	8b 75 10             	mov    0x10(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101182:	eb 2a                	jmp    f01011ae <vprintfmt+0x124>
f0101184:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101187:	85 c0                	test   %eax,%eax
f0101189:	b9 00 00 00 00       	mov    $0x0,%ecx
f010118e:	0f 49 c8             	cmovns %eax,%ecx
f0101191:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		precision = -1;
		lflag = 0;
		altflag = 0;
		precedeflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101194:	8b 75 10             	mov    0x10(%ebp),%esi
f0101197:	e9 65 ff ff ff       	jmp    f0101101 <vprintfmt+0x77>
f010119c:	8b 75 10             	mov    0x10(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010119f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01011a6:	e9 56 ff ff ff       	jmp    f0101101 <vprintfmt+0x77>
		precision = -1;
		lflag = 0;
		altflag = 0;
		precedeflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011ab:	8b 75 10             	mov    0x10(%ebp),%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01011ae:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01011b2:	0f 89 49 ff ff ff    	jns    f0101101 <vprintfmt+0x77>
				width = precision, precision = -1;
f01011b8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01011bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011be:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01011c5:	e9 37 ff ff ff       	jmp    f0101101 <vprintfmt+0x77>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01011ca:	83 c2 01             	add    $0x1,%edx
		precision = -1;
		lflag = 0;
		altflag = 0;
		precedeflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011cd:	8b 75 10             	mov    0x10(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01011d0:	e9 2c ff ff ff       	jmp    f0101101 <vprintfmt+0x77>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01011d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d8:	8d 50 04             	lea    0x4(%eax),%edx
f01011db:	89 55 14             	mov    %edx,0x14(%ebp)
f01011de:	83 ec 08             	sub    $0x8,%esp
f01011e1:	53                   	push   %ebx
f01011e2:	ff 30                	pushl  (%eax)
f01011e4:	ff d7                	call   *%edi
			break;
f01011e6:	83 c4 10             	add    $0x10,%esp
f01011e9:	e9 b0 fe ff ff       	jmp    f010109e <vprintfmt+0x14>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01011ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f1:	8d 50 04             	lea    0x4(%eax),%edx
f01011f4:	89 55 14             	mov    %edx,0x14(%ebp)
f01011f7:	8b 00                	mov    (%eax),%eax
f01011f9:	99                   	cltd   
f01011fa:	31 d0                	xor    %edx,%eax
f01011fc:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01011fe:	83 f8 06             	cmp    $0x6,%eax
f0101201:	7f 0b                	jg     f010120e <vprintfmt+0x184>
f0101203:	8b 14 85 6c 25 10 f0 	mov    -0xfefda94(,%eax,4),%edx
f010120a:	85 d2                	test   %edx,%edx
f010120c:	75 15                	jne    f0101223 <vprintfmt+0x199>
				printfmt(putch, putdat, "error %d", err);
f010120e:	50                   	push   %eax
f010120f:	68 21 23 10 f0       	push   $0xf0102321
f0101214:	53                   	push   %ebx
f0101215:	57                   	push   %edi
f0101216:	e8 52 fe ff ff       	call   f010106d <printfmt>
f010121b:	83 c4 10             	add    $0x10,%esp
f010121e:	e9 7b fe ff ff       	jmp    f010109e <vprintfmt+0x14>
			else
				printfmt(putch, putdat, "%s", p);
f0101223:	52                   	push   %edx
f0101224:	68 2a 23 10 f0       	push   $0xf010232a
f0101229:	53                   	push   %ebx
f010122a:	57                   	push   %edi
f010122b:	e8 3d fe ff ff       	call   f010106d <printfmt>
f0101230:	83 c4 10             	add    $0x10,%esp
f0101233:	e9 66 fe ff ff       	jmp    f010109e <vprintfmt+0x14>
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101238:	8b 45 14             	mov    0x14(%ebp),%eax
f010123b:	8d 50 04             	lea    0x4(%eax),%edx
f010123e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101241:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f0101243:	85 c0                	test   %eax,%eax
f0101245:	b9 1a 23 10 f0       	mov    $0xf010231a,%ecx
f010124a:	0f 45 c8             	cmovne %eax,%ecx
f010124d:	89 4d cc             	mov    %ecx,-0x34(%ebp)
			if (width > 0 && padc != '-')
f0101250:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101254:	7e 06                	jle    f010125c <vprintfmt+0x1d2>
f0101256:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010125a:	75 19                	jne    f0101275 <vprintfmt+0x1eb>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010125c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010125f:	8d 70 01             	lea    0x1(%eax),%esi
f0101262:	0f b6 00             	movzbl (%eax),%eax
f0101265:	0f be d0             	movsbl %al,%edx
f0101268:	85 d2                	test   %edx,%edx
f010126a:	0f 85 9f 00 00 00    	jne    f010130f <vprintfmt+0x285>
f0101270:	e9 8c 00 00 00       	jmp    f0101301 <vprintfmt+0x277>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101275:	83 ec 08             	sub    $0x8,%esp
f0101278:	ff 75 d0             	pushl  -0x30(%ebp)
f010127b:	ff 75 cc             	pushl  -0x34(%ebp)
f010127e:	e8 1c 04 00 00       	call   f010169f <strnlen>
f0101283:	29 45 e4             	sub    %eax,-0x1c(%ebp)
f0101286:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101289:	83 c4 10             	add    $0x10,%esp
f010128c:	85 c9                	test   %ecx,%ecx
f010128e:	0f 8e 87 02 00 00    	jle    f010151b <vprintfmt+0x491>
					putch(padc, putdat);
f0101294:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101298:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010129b:	89 cb                	mov    %ecx,%ebx
f010129d:	83 ec 08             	sub    $0x8,%esp
f01012a0:	ff 75 0c             	pushl  0xc(%ebp)
f01012a3:	56                   	push   %esi
f01012a4:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01012a6:	83 c4 10             	add    $0x10,%esp
f01012a9:	83 eb 01             	sub    $0x1,%ebx
f01012ac:	75 ef                	jne    f010129d <vprintfmt+0x213>
f01012ae:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01012b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01012b4:	e9 62 02 00 00       	jmp    f010151b <vprintfmt+0x491>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01012b9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01012bd:	74 1b                	je     f01012da <vprintfmt+0x250>
f01012bf:	0f be c0             	movsbl %al,%eax
f01012c2:	83 e8 20             	sub    $0x20,%eax
f01012c5:	83 f8 5e             	cmp    $0x5e,%eax
f01012c8:	76 10                	jbe    f01012da <vprintfmt+0x250>
					putch('?', putdat);
f01012ca:	83 ec 08             	sub    $0x8,%esp
f01012cd:	ff 75 0c             	pushl  0xc(%ebp)
f01012d0:	6a 3f                	push   $0x3f
f01012d2:	ff 55 08             	call   *0x8(%ebp)
f01012d5:	83 c4 10             	add    $0x10,%esp
f01012d8:	eb 0d                	jmp    f01012e7 <vprintfmt+0x25d>
				else
					putch(ch, putdat);
f01012da:	83 ec 08             	sub    $0x8,%esp
f01012dd:	ff 75 0c             	pushl  0xc(%ebp)
f01012e0:	52                   	push   %edx
f01012e1:	ff 55 08             	call   *0x8(%ebp)
f01012e4:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01012e7:	83 ef 01             	sub    $0x1,%edi
f01012ea:	83 c6 01             	add    $0x1,%esi
f01012ed:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f01012f1:	0f be d0             	movsbl %al,%edx
f01012f4:	85 d2                	test   %edx,%edx
f01012f6:	75 31                	jne    f0101329 <vprintfmt+0x29f>
f01012f8:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01012fb:	8b 7d 08             	mov    0x8(%ebp),%edi
f01012fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101301:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101304:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101308:	7f 33                	jg     f010133d <vprintfmt+0x2b3>
f010130a:	e9 8f fd ff ff       	jmp    f010109e <vprintfmt+0x14>
f010130f:	89 7d 08             	mov    %edi,0x8(%ebp)
f0101312:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101315:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101318:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010131b:	eb 0c                	jmp    f0101329 <vprintfmt+0x29f>
f010131d:	89 7d 08             	mov    %edi,0x8(%ebp)
f0101320:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101323:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101326:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101329:	85 db                	test   %ebx,%ebx
f010132b:	78 8c                	js     f01012b9 <vprintfmt+0x22f>
f010132d:	83 eb 01             	sub    $0x1,%ebx
f0101330:	79 87                	jns    f01012b9 <vprintfmt+0x22f>
f0101332:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0101335:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101338:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010133b:	eb c4                	jmp    f0101301 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010133d:	83 ec 08             	sub    $0x8,%esp
f0101340:	53                   	push   %ebx
f0101341:	6a 20                	push   $0x20
f0101343:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101345:	83 c4 10             	add    $0x10,%esp
f0101348:	83 ee 01             	sub    $0x1,%esi
f010134b:	75 f0                	jne    f010133d <vprintfmt+0x2b3>
f010134d:	e9 4c fd ff ff       	jmp    f010109e <vprintfmt+0x14>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101352:	83 fa 01             	cmp    $0x1,%edx
f0101355:	7e 16                	jle    f010136d <vprintfmt+0x2e3>
		return va_arg(*ap, long long);
f0101357:	8b 45 14             	mov    0x14(%ebp),%eax
f010135a:	8d 50 08             	lea    0x8(%eax),%edx
f010135d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101360:	8b 50 04             	mov    0x4(%eax),%edx
f0101363:	8b 00                	mov    (%eax),%eax
f0101365:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101368:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010136b:	eb 32                	jmp    f010139f <vprintfmt+0x315>
	else if (lflag)
f010136d:	85 d2                	test   %edx,%edx
f010136f:	74 18                	je     f0101389 <vprintfmt+0x2ff>
		return va_arg(*ap, long);
f0101371:	8b 45 14             	mov    0x14(%ebp),%eax
f0101374:	8d 50 04             	lea    0x4(%eax),%edx
f0101377:	89 55 14             	mov    %edx,0x14(%ebp)
f010137a:	8b 30                	mov    (%eax),%esi
f010137c:	89 75 d0             	mov    %esi,-0x30(%ebp)
f010137f:	89 f0                	mov    %esi,%eax
f0101381:	c1 f8 1f             	sar    $0x1f,%eax
f0101384:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101387:	eb 16                	jmp    f010139f <vprintfmt+0x315>
	else
		return va_arg(*ap, int);
f0101389:	8b 45 14             	mov    0x14(%ebp),%eax
f010138c:	8d 50 04             	lea    0x4(%eax),%edx
f010138f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101392:	8b 30                	mov    (%eax),%esi
f0101394:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0101397:	89 f0                	mov    %esi,%eax
f0101399:	c1 f8 1f             	sar    $0x1f,%eax
f010139c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010139f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01013a2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01013a5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01013a8:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
f01013ab:	85 d2                	test   %edx,%edx
f01013ad:	79 28                	jns    f01013d7 <vprintfmt+0x34d>
				putch('-', putdat);
f01013af:	83 ec 08             	sub    $0x8,%esp
f01013b2:	53                   	push   %ebx
f01013b3:	6a 2d                	push   $0x2d
f01013b5:	ff d7                	call   *%edi
				num = -(long long) num;
f01013b7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01013ba:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01013bd:	f7 d8                	neg    %eax
f01013bf:	83 d2 00             	adc    $0x0,%edx
f01013c2:	f7 da                	neg    %edx
f01013c4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01013c7:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01013ca:	83 c4 10             	add    $0x10,%esp
			}else if(precedeflag){
				putch('+', putdat);
			}
			base = 10;
f01013cd:	b8 0a 00 00 00       	mov    $0xa,%eax
f01013d2:	e9 99 00 00 00       	jmp    f0101470 <vprintfmt+0x3e6>
f01013d7:	b8 0a 00 00 00       	mov    $0xa,%eax
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}else if(precedeflag){
f01013dc:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01013e0:	0f 84 8a 00 00 00    	je     f0101470 <vprintfmt+0x3e6>
				putch('+', putdat);
f01013e6:	83 ec 08             	sub    $0x8,%esp
f01013e9:	53                   	push   %ebx
f01013ea:	6a 2b                	push   $0x2b
f01013ec:	ff d7                	call   *%edi
f01013ee:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01013f1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01013f6:	eb 78                	jmp    f0101470 <vprintfmt+0x3e6>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01013f8:	8d 45 14             	lea    0x14(%ebp),%eax
f01013fb:	e8 16 fc ff ff       	call   f0101016 <getuint>
f0101400:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101403:	89 55 dc             	mov    %edx,-0x24(%ebp)
			base = 10;
f0101406:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010140b:	eb 63                	jmp    f0101470 <vprintfmt+0x3e6>
			// display a number in octal form and the form should begin with '0'
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;*/
			num = getuint(&ap, lflag);
f010140d:	8d 45 14             	lea    0x14(%ebp),%eax
f0101410:	e8 01 fc ff ff       	call   f0101016 <getuint>
f0101415:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101418:	89 55 dc             	mov    %edx,-0x24(%ebp)
			putch('0', putdat);
f010141b:	83 ec 08             	sub    $0x8,%esp
f010141e:	53                   	push   %ebx
f010141f:	6a 30                	push   $0x30
f0101421:	ff d7                	call   *%edi
			base = 8;
			goto number;
f0101423:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
			putch('X', putdat);
			break;*/
			num = getuint(&ap, lflag);
			putch('0', putdat);
			base = 8;
f0101426:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f010142b:	eb 43                	jmp    f0101470 <vprintfmt+0x3e6>

		// pointer
		case 'p':
			putch('0', putdat);
f010142d:	83 ec 08             	sub    $0x8,%esp
f0101430:	53                   	push   %ebx
f0101431:	6a 30                	push   $0x30
f0101433:	ff d7                	call   *%edi
			putch('x', putdat);
f0101435:	83 c4 08             	add    $0x8,%esp
f0101438:	53                   	push   %ebx
f0101439:	6a 78                	push   $0x78
f010143b:	ff d7                	call   *%edi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010143d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101440:	8d 50 04             	lea    0x4(%eax),%edx
f0101443:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101446:	8b 00                	mov    (%eax),%eax
f0101448:	ba 00 00 00 00       	mov    $0x0,%edx
f010144d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101450:	89 55 dc             	mov    %edx,-0x24(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101453:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101456:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010145b:	eb 13                	jmp    f0101470 <vprintfmt+0x3e6>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010145d:	8d 45 14             	lea    0x14(%ebp),%eax
f0101460:	e8 b1 fb ff ff       	call   f0101016 <getuint>
f0101465:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101468:	89 55 dc             	mov    %edx,-0x24(%ebp)
			base = 16;
f010146b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101470:	83 ec 0c             	sub    $0xc,%esp
f0101473:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101477:	56                   	push   %esi
f0101478:	ff 75 e4             	pushl  -0x1c(%ebp)
f010147b:	50                   	push   %eax
f010147c:	ff 75 dc             	pushl  -0x24(%ebp)
f010147f:	ff 75 d8             	pushl  -0x28(%ebp)
f0101482:	89 da                	mov    %ebx,%edx
f0101484:	89 f8                	mov    %edi,%eax
f0101486:	e8 93 f9 ff ff       	call   f0100e1e <printnum>
			break;
f010148b:	83 c4 20             	add    $0x20,%esp
f010148e:	e9 0b fc ff ff       	jmp    f010109e <vprintfmt+0x14>
            const char *null_error = "\nerror! writing through NULL pointer! (%n argument)\n";
            const char *overflow_error = "\nwarning! The value %n argument pointed to has been overflowed!\n";

            // Your code here
						//putdat is stored with little-endian,so char & int are the same if the num < 127
						char * target = va_arg(ap, char *);
f0101493:	8b 45 14             	mov    0x14(%ebp),%eax
f0101496:	8d 50 04             	lea    0x4(%eax),%edx
f0101499:	89 55 14             	mov    %edx,0x14(%ebp)
f010149c:	8b 30                	mov    (%eax),%esi
						if(target == NULL)
f010149e:	85 f6                	test   %esi,%esi
f01014a0:	75 19                	jne    f01014bb <vprintfmt+0x431>
							printfmt(putch, putdat, "%s", null_error);
f01014a2:	68 98 23 10 f0       	push   $0xf0102398
f01014a7:	68 2a 23 10 f0       	push   $0xf010232a
f01014ac:	53                   	push   %ebx
f01014ad:	57                   	push   %edi
f01014ae:	e8 ba fb ff ff       	call   f010106d <printfmt>
f01014b3:	83 c4 10             	add    $0x10,%esp
f01014b6:	e9 e3 fb ff ff       	jmp    f010109e <vprintfmt+0x14>
						else if(*(int*)putdat > 127){
f01014bb:	83 3b 7f             	cmpl   $0x7f,(%ebx)
f01014be:	7e 1c                	jle    f01014dc <vprintfmt+0x452>
							printfmt(putch, putdat, "%s", overflow_error);
f01014c0:	68 d0 23 10 f0       	push   $0xf01023d0
f01014c5:	68 2a 23 10 f0       	push   $0xf010232a
f01014ca:	53                   	push   %ebx
f01014cb:	57                   	push   %edi
f01014cc:	e8 9c fb ff ff       	call   f010106d <printfmt>
							*target = -1;
f01014d1:	c6 06 ff             	movb   $0xff,(%esi)
f01014d4:	83 c4 10             	add    $0x10,%esp
f01014d7:	e9 c2 fb ff ff       	jmp    f010109e <vprintfmt+0x14>
						}else{
							*target = *(char*)putdat;
f01014dc:	0f b6 03             	movzbl (%ebx),%eax
f01014df:	88 06                	mov    %al,(%esi)
f01014e1:	e9 b8 fb ff ff       	jmp    f010109e <vprintfmt+0x14>
            break;
        }

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01014e6:	83 ec 08             	sub    $0x8,%esp
f01014e9:	53                   	push   %ebx
f01014ea:	51                   	push   %ecx
f01014eb:	ff d7                	call   *%edi
			break;
f01014ed:	83 c4 10             	add    $0x10,%esp
f01014f0:	e9 a9 fb ff ff       	jmp    f010109e <vprintfmt+0x14>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01014f5:	83 ec 08             	sub    $0x8,%esp
f01014f8:	53                   	push   %ebx
f01014f9:	6a 25                	push   $0x25
f01014fb:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01014fd:	83 c4 10             	add    $0x10,%esp
f0101500:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101504:	0f 84 91 fb ff ff    	je     f010109b <vprintfmt+0x11>
f010150a:	83 ee 01             	sub    $0x1,%esi
f010150d:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101511:	75 f7                	jne    f010150a <vprintfmt+0x480>
f0101513:	89 75 10             	mov    %esi,0x10(%ebp)
f0101516:	e9 83 fb ff ff       	jmp    f010109e <vprintfmt+0x14>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010151b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010151e:	8d 70 01             	lea    0x1(%eax),%esi
f0101521:	0f b6 00             	movzbl (%eax),%eax
f0101524:	0f be d0             	movsbl %al,%edx
f0101527:	85 d2                	test   %edx,%edx
f0101529:	0f 85 ee fd ff ff    	jne    f010131d <vprintfmt+0x293>
f010152f:	e9 6a fb ff ff       	jmp    f010109e <vprintfmt+0x14>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f0101534:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101537:	5b                   	pop    %ebx
f0101538:	5e                   	pop    %esi
f0101539:	5f                   	pop    %edi
f010153a:	5d                   	pop    %ebp
f010153b:	c3                   	ret    

f010153c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010153c:	55                   	push   %ebp
f010153d:	89 e5                	mov    %esp,%ebp
f010153f:	83 ec 18             	sub    $0x18,%esp
f0101542:	8b 45 08             	mov    0x8(%ebp),%eax
f0101545:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101548:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010154b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010154f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101552:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101559:	85 c0                	test   %eax,%eax
f010155b:	74 26                	je     f0101583 <vsnprintf+0x47>
f010155d:	85 d2                	test   %edx,%edx
f010155f:	7e 22                	jle    f0101583 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101561:	ff 75 14             	pushl  0x14(%ebp)
f0101564:	ff 75 10             	pushl  0x10(%ebp)
f0101567:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010156a:	50                   	push   %eax
f010156b:	68 50 10 10 f0       	push   $0xf0101050
f0101570:	e8 15 fb ff ff       	call   f010108a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101575:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101578:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010157b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010157e:	83 c4 10             	add    $0x10,%esp
f0101581:	eb 05                	jmp    f0101588 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101583:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101588:	c9                   	leave  
f0101589:	c3                   	ret    

f010158a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010158a:	55                   	push   %ebp
f010158b:	89 e5                	mov    %esp,%ebp
f010158d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101590:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101593:	50                   	push   %eax
f0101594:	ff 75 10             	pushl  0x10(%ebp)
f0101597:	ff 75 0c             	pushl  0xc(%ebp)
f010159a:	ff 75 08             	pushl  0x8(%ebp)
f010159d:	e8 9a ff ff ff       	call   f010153c <vsnprintf>
	va_end(ap);

	return rc;
}
f01015a2:	c9                   	leave  
f01015a3:	c3                   	ret    

f01015a4 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01015a4:	55                   	push   %ebp
f01015a5:	89 e5                	mov    %esp,%ebp
f01015a7:	57                   	push   %edi
f01015a8:	56                   	push   %esi
f01015a9:	53                   	push   %ebx
f01015aa:	83 ec 0c             	sub    $0xc,%esp
f01015ad:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01015b0:	85 c0                	test   %eax,%eax
f01015b2:	74 11                	je     f01015c5 <readline+0x21>
		cprintf("%s", prompt);
f01015b4:	83 ec 08             	sub    $0x8,%esp
f01015b7:	50                   	push   %eax
f01015b8:	68 2a 23 10 f0       	push   $0xf010232a
f01015bd:	e8 c8 f4 ff ff       	call   f0100a8a <cprintf>
f01015c2:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01015c5:	83 ec 0c             	sub    $0xc,%esp
f01015c8:	6a 00                	push   $0x0
f01015ca:	e8 d9 f0 ff ff       	call   f01006a8 <iscons>
f01015cf:	89 c7                	mov    %eax,%edi
f01015d1:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01015d4:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01015d9:	e8 b9 f0 ff ff       	call   f0100697 <getchar>
f01015de:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01015e0:	85 c0                	test   %eax,%eax
f01015e2:	79 18                	jns    f01015fc <readline+0x58>
			cprintf("read error: %e\n", c);
f01015e4:	83 ec 08             	sub    $0x8,%esp
f01015e7:	50                   	push   %eax
f01015e8:	68 88 25 10 f0       	push   $0xf0102588
f01015ed:	e8 98 f4 ff ff       	call   f0100a8a <cprintf>
			return NULL;
f01015f2:	83 c4 10             	add    $0x10,%esp
f01015f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01015fa:	eb 79                	jmp    f0101675 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01015fc:	83 f8 08             	cmp    $0x8,%eax
f01015ff:	0f 94 c2             	sete   %dl
f0101602:	83 f8 7f             	cmp    $0x7f,%eax
f0101605:	0f 94 c0             	sete   %al
f0101608:	08 c2                	or     %al,%dl
f010160a:	74 1a                	je     f0101626 <readline+0x82>
f010160c:	85 f6                	test   %esi,%esi
f010160e:	7e 16                	jle    f0101626 <readline+0x82>
			if (echoing)
f0101610:	85 ff                	test   %edi,%edi
f0101612:	74 0d                	je     f0101621 <readline+0x7d>
				cputchar('\b');
f0101614:	83 ec 0c             	sub    $0xc,%esp
f0101617:	6a 08                	push   $0x8
f0101619:	e8 69 f0 ff ff       	call   f0100687 <cputchar>
f010161e:	83 c4 10             	add    $0x10,%esp
			i--;
f0101621:	83 ee 01             	sub    $0x1,%esi
f0101624:	eb b3                	jmp    f01015d9 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101626:	83 fb 1f             	cmp    $0x1f,%ebx
f0101629:	7e 23                	jle    f010164e <readline+0xaa>
f010162b:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101631:	7f 1b                	jg     f010164e <readline+0xaa>
			if (echoing)
f0101633:	85 ff                	test   %edi,%edi
f0101635:	74 0c                	je     f0101643 <readline+0x9f>
				cputchar(c);
f0101637:	83 ec 0c             	sub    $0xc,%esp
f010163a:	53                   	push   %ebx
f010163b:	e8 47 f0 ff ff       	call   f0100687 <cputchar>
f0101640:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101643:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101649:	8d 76 01             	lea    0x1(%esi),%esi
f010164c:	eb 8b                	jmp    f01015d9 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010164e:	83 fb 0a             	cmp    $0xa,%ebx
f0101651:	74 05                	je     f0101658 <readline+0xb4>
f0101653:	83 fb 0d             	cmp    $0xd,%ebx
f0101656:	75 81                	jne    f01015d9 <readline+0x35>
			if (echoing)
f0101658:	85 ff                	test   %edi,%edi
f010165a:	74 0d                	je     f0101669 <readline+0xc5>
				cputchar('\n');
f010165c:	83 ec 0c             	sub    $0xc,%esp
f010165f:	6a 0a                	push   $0xa
f0101661:	e8 21 f0 ff ff       	call   f0100687 <cputchar>
f0101666:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101669:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f0101670:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101675:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101678:	5b                   	pop    %ebx
f0101679:	5e                   	pop    %esi
f010167a:	5f                   	pop    %edi
f010167b:	5d                   	pop    %ebp
f010167c:	c3                   	ret    

f010167d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010167d:	55                   	push   %ebp
f010167e:	89 e5                	mov    %esp,%ebp
f0101680:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101683:	80 3a 00             	cmpb   $0x0,(%edx)
f0101686:	74 10                	je     f0101698 <strlen+0x1b>
f0101688:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f010168d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101690:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101694:	75 f7                	jne    f010168d <strlen+0x10>
f0101696:	eb 05                	jmp    f010169d <strlen+0x20>
f0101698:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f010169d:	5d                   	pop    %ebp
f010169e:	c3                   	ret    

f010169f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010169f:	55                   	push   %ebp
f01016a0:	89 e5                	mov    %esp,%ebp
f01016a2:	53                   	push   %ebx
f01016a3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016a6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01016a9:	85 c9                	test   %ecx,%ecx
f01016ab:	74 1c                	je     f01016c9 <strnlen+0x2a>
f01016ad:	80 3b 00             	cmpb   $0x0,(%ebx)
f01016b0:	74 1e                	je     f01016d0 <strnlen+0x31>
f01016b2:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01016b7:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01016b9:	39 ca                	cmp    %ecx,%edx
f01016bb:	74 18                	je     f01016d5 <strnlen+0x36>
f01016bd:	83 c2 01             	add    $0x1,%edx
f01016c0:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01016c5:	75 f0                	jne    f01016b7 <strnlen+0x18>
f01016c7:	eb 0c                	jmp    f01016d5 <strnlen+0x36>
f01016c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01016ce:	eb 05                	jmp    f01016d5 <strnlen+0x36>
f01016d0:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01016d5:	5b                   	pop    %ebx
f01016d6:	5d                   	pop    %ebp
f01016d7:	c3                   	ret    

f01016d8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01016d8:	55                   	push   %ebp
f01016d9:	89 e5                	mov    %esp,%ebp
f01016db:	53                   	push   %ebx
f01016dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01016df:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01016e2:	89 c2                	mov    %eax,%edx
f01016e4:	83 c2 01             	add    $0x1,%edx
f01016e7:	83 c1 01             	add    $0x1,%ecx
f01016ea:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01016ee:	88 5a ff             	mov    %bl,-0x1(%edx)
f01016f1:	84 db                	test   %bl,%bl
f01016f3:	75 ef                	jne    f01016e4 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01016f5:	5b                   	pop    %ebx
f01016f6:	5d                   	pop    %ebp
f01016f7:	c3                   	ret    

f01016f8 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01016f8:	55                   	push   %ebp
f01016f9:	89 e5                	mov    %esp,%ebp
f01016fb:	56                   	push   %esi
f01016fc:	53                   	push   %ebx
f01016fd:	8b 75 08             	mov    0x8(%ebp),%esi
f0101700:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101703:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101706:	85 db                	test   %ebx,%ebx
f0101708:	74 17                	je     f0101721 <strncpy+0x29>
f010170a:	01 f3                	add    %esi,%ebx
f010170c:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f010170e:	83 c1 01             	add    $0x1,%ecx
f0101711:	0f b6 02             	movzbl (%edx),%eax
f0101714:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101717:	80 3a 01             	cmpb   $0x1,(%edx)
f010171a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010171d:	39 cb                	cmp    %ecx,%ebx
f010171f:	75 ed                	jne    f010170e <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101721:	89 f0                	mov    %esi,%eax
f0101723:	5b                   	pop    %ebx
f0101724:	5e                   	pop    %esi
f0101725:	5d                   	pop    %ebp
f0101726:	c3                   	ret    

f0101727 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101727:	55                   	push   %ebp
f0101728:	89 e5                	mov    %esp,%ebp
f010172a:	56                   	push   %esi
f010172b:	53                   	push   %ebx
f010172c:	8b 75 08             	mov    0x8(%ebp),%esi
f010172f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101732:	8b 55 10             	mov    0x10(%ebp),%edx
f0101735:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101737:	85 d2                	test   %edx,%edx
f0101739:	74 35                	je     f0101770 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010173b:	89 d0                	mov    %edx,%eax
f010173d:	83 e8 01             	sub    $0x1,%eax
f0101740:	74 25                	je     f0101767 <strlcpy+0x40>
f0101742:	0f b6 0b             	movzbl (%ebx),%ecx
f0101745:	84 c9                	test   %cl,%cl
f0101747:	74 22                	je     f010176b <strlcpy+0x44>
f0101749:	8d 53 01             	lea    0x1(%ebx),%edx
f010174c:	01 c3                	add    %eax,%ebx
f010174e:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
f0101750:	83 c0 01             	add    $0x1,%eax
f0101753:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101756:	39 da                	cmp    %ebx,%edx
f0101758:	74 13                	je     f010176d <strlcpy+0x46>
f010175a:	83 c2 01             	add    $0x1,%edx
f010175d:	0f b6 4a ff          	movzbl -0x1(%edx),%ecx
f0101761:	84 c9                	test   %cl,%cl
f0101763:	75 eb                	jne    f0101750 <strlcpy+0x29>
f0101765:	eb 06                	jmp    f010176d <strlcpy+0x46>
f0101767:	89 f0                	mov    %esi,%eax
f0101769:	eb 02                	jmp    f010176d <strlcpy+0x46>
f010176b:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f010176d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101770:	29 f0                	sub    %esi,%eax
}
f0101772:	5b                   	pop    %ebx
f0101773:	5e                   	pop    %esi
f0101774:	5d                   	pop    %ebp
f0101775:	c3                   	ret    

f0101776 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101776:	55                   	push   %ebp
f0101777:	89 e5                	mov    %esp,%ebp
f0101779:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010177c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010177f:	0f b6 01             	movzbl (%ecx),%eax
f0101782:	84 c0                	test   %al,%al
f0101784:	74 15                	je     f010179b <strcmp+0x25>
f0101786:	3a 02                	cmp    (%edx),%al
f0101788:	75 11                	jne    f010179b <strcmp+0x25>
		p++, q++;
f010178a:	83 c1 01             	add    $0x1,%ecx
f010178d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101790:	0f b6 01             	movzbl (%ecx),%eax
f0101793:	84 c0                	test   %al,%al
f0101795:	74 04                	je     f010179b <strcmp+0x25>
f0101797:	3a 02                	cmp    (%edx),%al
f0101799:	74 ef                	je     f010178a <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010179b:	0f b6 c0             	movzbl %al,%eax
f010179e:	0f b6 12             	movzbl (%edx),%edx
f01017a1:	29 d0                	sub    %edx,%eax
}
f01017a3:	5d                   	pop    %ebp
f01017a4:	c3                   	ret    

f01017a5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01017a5:	55                   	push   %ebp
f01017a6:	89 e5                	mov    %esp,%ebp
f01017a8:	56                   	push   %esi
f01017a9:	53                   	push   %ebx
f01017aa:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01017ad:	8b 55 0c             	mov    0xc(%ebp),%edx
f01017b0:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01017b3:	85 f6                	test   %esi,%esi
f01017b5:	74 29                	je     f01017e0 <strncmp+0x3b>
f01017b7:	0f b6 03             	movzbl (%ebx),%eax
f01017ba:	84 c0                	test   %al,%al
f01017bc:	74 30                	je     f01017ee <strncmp+0x49>
f01017be:	3a 02                	cmp    (%edx),%al
f01017c0:	75 2c                	jne    f01017ee <strncmp+0x49>
f01017c2:	8d 43 01             	lea    0x1(%ebx),%eax
f01017c5:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01017c7:	89 c3                	mov    %eax,%ebx
f01017c9:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01017cc:	39 c6                	cmp    %eax,%esi
f01017ce:	74 17                	je     f01017e7 <strncmp+0x42>
f01017d0:	0f b6 08             	movzbl (%eax),%ecx
f01017d3:	84 c9                	test   %cl,%cl
f01017d5:	74 17                	je     f01017ee <strncmp+0x49>
f01017d7:	83 c0 01             	add    $0x1,%eax
f01017da:	3a 0a                	cmp    (%edx),%cl
f01017dc:	74 e9                	je     f01017c7 <strncmp+0x22>
f01017de:	eb 0e                	jmp    f01017ee <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01017e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01017e5:	eb 0f                	jmp    f01017f6 <strncmp+0x51>
f01017e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01017ec:	eb 08                	jmp    f01017f6 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01017ee:	0f b6 03             	movzbl (%ebx),%eax
f01017f1:	0f b6 12             	movzbl (%edx),%edx
f01017f4:	29 d0                	sub    %edx,%eax
}
f01017f6:	5b                   	pop    %ebx
f01017f7:	5e                   	pop    %esi
f01017f8:	5d                   	pop    %ebp
f01017f9:	c3                   	ret    

f01017fa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01017fa:	55                   	push   %ebp
f01017fb:	89 e5                	mov    %esp,%ebp
f01017fd:	53                   	push   %ebx
f01017fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101801:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	for (; *s; s++)
f0101804:	0f b6 10             	movzbl (%eax),%edx
f0101807:	84 d2                	test   %dl,%dl
f0101809:	74 1d                	je     f0101828 <strchr+0x2e>
f010180b:	89 d9                	mov    %ebx,%ecx
		if (*s == c)
f010180d:	38 d3                	cmp    %dl,%bl
f010180f:	75 06                	jne    f0101817 <strchr+0x1d>
f0101811:	eb 1a                	jmp    f010182d <strchr+0x33>
f0101813:	38 ca                	cmp    %cl,%dl
f0101815:	74 16                	je     f010182d <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101817:	83 c0 01             	add    $0x1,%eax
f010181a:	0f b6 10             	movzbl (%eax),%edx
f010181d:	84 d2                	test   %dl,%dl
f010181f:	75 f2                	jne    f0101813 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101821:	b8 00 00 00 00       	mov    $0x0,%eax
f0101826:	eb 05                	jmp    f010182d <strchr+0x33>
f0101828:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010182d:	5b                   	pop    %ebx
f010182e:	5d                   	pop    %ebp
f010182f:	c3                   	ret    

f0101830 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101830:	55                   	push   %ebp
f0101831:	89 e5                	mov    %esp,%ebp
f0101833:	53                   	push   %ebx
f0101834:	8b 45 08             	mov    0x8(%ebp),%eax
f0101837:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010183a:	0f b6 18             	movzbl (%eax),%ebx
		if (*s == c)
f010183d:	38 d3                	cmp    %dl,%bl
f010183f:	74 14                	je     f0101855 <strfind+0x25>
f0101841:	89 d1                	mov    %edx,%ecx
f0101843:	84 db                	test   %bl,%bl
f0101845:	74 0e                	je     f0101855 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101847:	83 c0 01             	add    $0x1,%eax
f010184a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010184d:	38 ca                	cmp    %cl,%dl
f010184f:	74 04                	je     f0101855 <strfind+0x25>
f0101851:	84 d2                	test   %dl,%dl
f0101853:	75 f2                	jne    f0101847 <strfind+0x17>
			break;
	return (char *) s;
}
f0101855:	5b                   	pop    %ebx
f0101856:	5d                   	pop    %ebp
f0101857:	c3                   	ret    

f0101858 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101858:	55                   	push   %ebp
f0101859:	89 e5                	mov    %esp,%ebp
f010185b:	57                   	push   %edi
f010185c:	56                   	push   %esi
f010185d:	53                   	push   %ebx
f010185e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101861:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101864:	85 c9                	test   %ecx,%ecx
f0101866:	74 36                	je     f010189e <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101868:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010186e:	75 28                	jne    f0101898 <memset+0x40>
f0101870:	f6 c1 03             	test   $0x3,%cl
f0101873:	75 23                	jne    f0101898 <memset+0x40>
		c &= 0xFF;
f0101875:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101879:	89 d3                	mov    %edx,%ebx
f010187b:	c1 e3 08             	shl    $0x8,%ebx
f010187e:	89 d6                	mov    %edx,%esi
f0101880:	c1 e6 18             	shl    $0x18,%esi
f0101883:	89 d0                	mov    %edx,%eax
f0101885:	c1 e0 10             	shl    $0x10,%eax
f0101888:	09 f0                	or     %esi,%eax
f010188a:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010188c:	89 d8                	mov    %ebx,%eax
f010188e:	09 d0                	or     %edx,%eax
f0101890:	c1 e9 02             	shr    $0x2,%ecx
f0101893:	fc                   	cld    
f0101894:	f3 ab                	rep stos %eax,%es:(%edi)
f0101896:	eb 06                	jmp    f010189e <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101898:	8b 45 0c             	mov    0xc(%ebp),%eax
f010189b:	fc                   	cld    
f010189c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010189e:	89 f8                	mov    %edi,%eax
f01018a0:	5b                   	pop    %ebx
f01018a1:	5e                   	pop    %esi
f01018a2:	5f                   	pop    %edi
f01018a3:	5d                   	pop    %ebp
f01018a4:	c3                   	ret    

f01018a5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01018a5:	55                   	push   %ebp
f01018a6:	89 e5                	mov    %esp,%ebp
f01018a8:	57                   	push   %edi
f01018a9:	56                   	push   %esi
f01018aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01018ad:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018b0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01018b3:	39 c6                	cmp    %eax,%esi
f01018b5:	73 35                	jae    f01018ec <memmove+0x47>
f01018b7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01018ba:	39 d0                	cmp    %edx,%eax
f01018bc:	73 2e                	jae    f01018ec <memmove+0x47>
		s += n;
		d += n;
f01018be:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018c1:	89 d6                	mov    %edx,%esi
f01018c3:	09 fe                	or     %edi,%esi
f01018c5:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01018cb:	75 13                	jne    f01018e0 <memmove+0x3b>
f01018cd:	f6 c1 03             	test   $0x3,%cl
f01018d0:	75 0e                	jne    f01018e0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01018d2:	83 ef 04             	sub    $0x4,%edi
f01018d5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01018d8:	c1 e9 02             	shr    $0x2,%ecx
f01018db:	fd                   	std    
f01018dc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01018de:	eb 09                	jmp    f01018e9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01018e0:	83 ef 01             	sub    $0x1,%edi
f01018e3:	8d 72 ff             	lea    -0x1(%edx),%esi
f01018e6:	fd                   	std    
f01018e7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01018e9:	fc                   	cld    
f01018ea:	eb 1d                	jmp    f0101909 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018ec:	89 f2                	mov    %esi,%edx
f01018ee:	09 c2                	or     %eax,%edx
f01018f0:	f6 c2 03             	test   $0x3,%dl
f01018f3:	75 0f                	jne    f0101904 <memmove+0x5f>
f01018f5:	f6 c1 03             	test   $0x3,%cl
f01018f8:	75 0a                	jne    f0101904 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01018fa:	c1 e9 02             	shr    $0x2,%ecx
f01018fd:	89 c7                	mov    %eax,%edi
f01018ff:	fc                   	cld    
f0101900:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101902:	eb 05                	jmp    f0101909 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101904:	89 c7                	mov    %eax,%edi
f0101906:	fc                   	cld    
f0101907:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101909:	5e                   	pop    %esi
f010190a:	5f                   	pop    %edi
f010190b:	5d                   	pop    %ebp
f010190c:	c3                   	ret    

f010190d <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f010190d:	55                   	push   %ebp
f010190e:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101910:	ff 75 10             	pushl  0x10(%ebp)
f0101913:	ff 75 0c             	pushl  0xc(%ebp)
f0101916:	ff 75 08             	pushl  0x8(%ebp)
f0101919:	e8 87 ff ff ff       	call   f01018a5 <memmove>
}
f010191e:	c9                   	leave  
f010191f:	c3                   	ret    

f0101920 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101920:	55                   	push   %ebp
f0101921:	89 e5                	mov    %esp,%ebp
f0101923:	57                   	push   %edi
f0101924:	56                   	push   %esi
f0101925:	53                   	push   %ebx
f0101926:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101929:	8b 75 0c             	mov    0xc(%ebp),%esi
f010192c:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010192f:	85 c0                	test   %eax,%eax
f0101931:	74 39                	je     f010196c <memcmp+0x4c>
f0101933:	8d 78 ff             	lea    -0x1(%eax),%edi
		if (*s1 != *s2)
f0101936:	0f b6 13             	movzbl (%ebx),%edx
f0101939:	0f b6 0e             	movzbl (%esi),%ecx
f010193c:	38 ca                	cmp    %cl,%dl
f010193e:	75 17                	jne    f0101957 <memcmp+0x37>
f0101940:	b8 00 00 00 00       	mov    $0x0,%eax
f0101945:	eb 1a                	jmp    f0101961 <memcmp+0x41>
f0101947:	0f b6 54 03 01       	movzbl 0x1(%ebx,%eax,1),%edx
f010194c:	83 c0 01             	add    $0x1,%eax
f010194f:	0f b6 0c 06          	movzbl (%esi,%eax,1),%ecx
f0101953:	38 ca                	cmp    %cl,%dl
f0101955:	74 0a                	je     f0101961 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0101957:	0f b6 c2             	movzbl %dl,%eax
f010195a:	0f b6 c9             	movzbl %cl,%ecx
f010195d:	29 c8                	sub    %ecx,%eax
f010195f:	eb 10                	jmp    f0101971 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101961:	39 f8                	cmp    %edi,%eax
f0101963:	75 e2                	jne    f0101947 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101965:	b8 00 00 00 00       	mov    $0x0,%eax
f010196a:	eb 05                	jmp    f0101971 <memcmp+0x51>
f010196c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101971:	5b                   	pop    %ebx
f0101972:	5e                   	pop    %esi
f0101973:	5f                   	pop    %edi
f0101974:	5d                   	pop    %ebp
f0101975:	c3                   	ret    

f0101976 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101976:	55                   	push   %ebp
f0101977:	89 e5                	mov    %esp,%ebp
f0101979:	53                   	push   %ebx
f010197a:	8b 55 08             	mov    0x8(%ebp),%edx
	const void *ends = (const char *) s + n;
f010197d:	89 d0                	mov    %edx,%eax
f010197f:	03 45 10             	add    0x10(%ebp),%eax
	for (; s < ends; s++)
f0101982:	39 c2                	cmp    %eax,%edx
f0101984:	73 1d                	jae    f01019a3 <memfind+0x2d>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101986:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
f010198a:	0f b6 0a             	movzbl (%edx),%ecx
f010198d:	39 d9                	cmp    %ebx,%ecx
f010198f:	75 09                	jne    f010199a <memfind+0x24>
f0101991:	eb 14                	jmp    f01019a7 <memfind+0x31>
f0101993:	0f b6 0a             	movzbl (%edx),%ecx
f0101996:	39 d9                	cmp    %ebx,%ecx
f0101998:	74 11                	je     f01019ab <memfind+0x35>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010199a:	83 c2 01             	add    $0x1,%edx
f010199d:	39 d0                	cmp    %edx,%eax
f010199f:	75 f2                	jne    f0101993 <memfind+0x1d>
f01019a1:	eb 0a                	jmp    f01019ad <memfind+0x37>
f01019a3:	89 d0                	mov    %edx,%eax
f01019a5:	eb 06                	jmp    f01019ad <memfind+0x37>
		if (*(const unsigned char *) s == (unsigned char) c)
f01019a7:	89 d0                	mov    %edx,%eax
f01019a9:	eb 02                	jmp    f01019ad <memfind+0x37>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01019ab:	89 d0                	mov    %edx,%eax
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01019ad:	5b                   	pop    %ebx
f01019ae:	5d                   	pop    %ebp
f01019af:	c3                   	ret    

f01019b0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01019b0:	55                   	push   %ebp
f01019b1:	89 e5                	mov    %esp,%ebp
f01019b3:	57                   	push   %edi
f01019b4:	56                   	push   %esi
f01019b5:	53                   	push   %ebx
f01019b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01019b9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019bc:	0f b6 01             	movzbl (%ecx),%eax
f01019bf:	3c 20                	cmp    $0x20,%al
f01019c1:	74 04                	je     f01019c7 <strtol+0x17>
f01019c3:	3c 09                	cmp    $0x9,%al
f01019c5:	75 0e                	jne    f01019d5 <strtol+0x25>
		s++;
f01019c7:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019ca:	0f b6 01             	movzbl (%ecx),%eax
f01019cd:	3c 20                	cmp    $0x20,%al
f01019cf:	74 f6                	je     f01019c7 <strtol+0x17>
f01019d1:	3c 09                	cmp    $0x9,%al
f01019d3:	74 f2                	je     f01019c7 <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01019d5:	3c 2b                	cmp    $0x2b,%al
f01019d7:	75 0a                	jne    f01019e3 <strtol+0x33>
		s++;
f01019d9:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01019dc:	bf 00 00 00 00       	mov    $0x0,%edi
f01019e1:	eb 11                	jmp    f01019f4 <strtol+0x44>
f01019e3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01019e8:	3c 2d                	cmp    $0x2d,%al
f01019ea:	75 08                	jne    f01019f4 <strtol+0x44>
		s++, neg = 1;
f01019ec:	83 c1 01             	add    $0x1,%ecx
f01019ef:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01019f4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01019fa:	75 15                	jne    f0101a11 <strtol+0x61>
f01019fc:	80 39 30             	cmpb   $0x30,(%ecx)
f01019ff:	75 10                	jne    f0101a11 <strtol+0x61>
f0101a01:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101a05:	75 7c                	jne    f0101a83 <strtol+0xd3>
		s += 2, base = 16;
f0101a07:	83 c1 02             	add    $0x2,%ecx
f0101a0a:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101a0f:	eb 16                	jmp    f0101a27 <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101a11:	85 db                	test   %ebx,%ebx
f0101a13:	75 12                	jne    f0101a27 <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101a15:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101a1a:	80 39 30             	cmpb   $0x30,(%ecx)
f0101a1d:	75 08                	jne    f0101a27 <strtol+0x77>
		s++, base = 8;
f0101a1f:	83 c1 01             	add    $0x1,%ecx
f0101a22:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101a27:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a2c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101a2f:	0f b6 11             	movzbl (%ecx),%edx
f0101a32:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101a35:	89 f3                	mov    %esi,%ebx
f0101a37:	80 fb 09             	cmp    $0x9,%bl
f0101a3a:	77 08                	ja     f0101a44 <strtol+0x94>
			dig = *s - '0';
f0101a3c:	0f be d2             	movsbl %dl,%edx
f0101a3f:	83 ea 30             	sub    $0x30,%edx
f0101a42:	eb 22                	jmp    f0101a66 <strtol+0xb6>
		else if (*s >= 'a' && *s <= 'z')
f0101a44:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101a47:	89 f3                	mov    %esi,%ebx
f0101a49:	80 fb 19             	cmp    $0x19,%bl
f0101a4c:	77 08                	ja     f0101a56 <strtol+0xa6>
			dig = *s - 'a' + 10;
f0101a4e:	0f be d2             	movsbl %dl,%edx
f0101a51:	83 ea 57             	sub    $0x57,%edx
f0101a54:	eb 10                	jmp    f0101a66 <strtol+0xb6>
		else if (*s >= 'A' && *s <= 'Z')
f0101a56:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101a59:	89 f3                	mov    %esi,%ebx
f0101a5b:	80 fb 19             	cmp    $0x19,%bl
f0101a5e:	77 16                	ja     f0101a76 <strtol+0xc6>
			dig = *s - 'A' + 10;
f0101a60:	0f be d2             	movsbl %dl,%edx
f0101a63:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101a66:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101a69:	7d 0b                	jge    f0101a76 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0101a6b:	83 c1 01             	add    $0x1,%ecx
f0101a6e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101a72:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101a74:	eb b9                	jmp    f0101a2f <strtol+0x7f>

	if (endptr)
f0101a76:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101a7a:	74 0d                	je     f0101a89 <strtol+0xd9>
		*endptr = (char *) s;
f0101a7c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101a7f:	89 0e                	mov    %ecx,(%esi)
f0101a81:	eb 06                	jmp    f0101a89 <strtol+0xd9>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101a83:	85 db                	test   %ebx,%ebx
f0101a85:	74 98                	je     f0101a1f <strtol+0x6f>
f0101a87:	eb 9e                	jmp    f0101a27 <strtol+0x77>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101a89:	89 c2                	mov    %eax,%edx
f0101a8b:	f7 da                	neg    %edx
f0101a8d:	85 ff                	test   %edi,%edi
f0101a8f:	0f 45 c2             	cmovne %edx,%eax
}
f0101a92:	5b                   	pop    %ebx
f0101a93:	5e                   	pop    %esi
f0101a94:	5f                   	pop    %edi
f0101a95:	5d                   	pop    %ebp
f0101a96:	c3                   	ret    
f0101a97:	66 90                	xchg   %ax,%ax
f0101a99:	66 90                	xchg   %ax,%ax
f0101a9b:	66 90                	xchg   %ax,%ax
f0101a9d:	66 90                	xchg   %ax,%ax
f0101a9f:	90                   	nop

f0101aa0 <__udivdi3>:
f0101aa0:	55                   	push   %ebp
f0101aa1:	57                   	push   %edi
f0101aa2:	56                   	push   %esi
f0101aa3:	53                   	push   %ebx
f0101aa4:	83 ec 1c             	sub    $0x1c,%esp
f0101aa7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0101aab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0101aaf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101ab3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101ab7:	85 f6                	test   %esi,%esi
f0101ab9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101abd:	89 ca                	mov    %ecx,%edx
f0101abf:	89 f8                	mov    %edi,%eax
f0101ac1:	75 3d                	jne    f0101b00 <__udivdi3+0x60>
f0101ac3:	39 cf                	cmp    %ecx,%edi
f0101ac5:	0f 87 c5 00 00 00    	ja     f0101b90 <__udivdi3+0xf0>
f0101acb:	85 ff                	test   %edi,%edi
f0101acd:	89 fd                	mov    %edi,%ebp
f0101acf:	75 0b                	jne    f0101adc <__udivdi3+0x3c>
f0101ad1:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ad6:	31 d2                	xor    %edx,%edx
f0101ad8:	f7 f7                	div    %edi
f0101ada:	89 c5                	mov    %eax,%ebp
f0101adc:	89 c8                	mov    %ecx,%eax
f0101ade:	31 d2                	xor    %edx,%edx
f0101ae0:	f7 f5                	div    %ebp
f0101ae2:	89 c1                	mov    %eax,%ecx
f0101ae4:	89 d8                	mov    %ebx,%eax
f0101ae6:	89 cf                	mov    %ecx,%edi
f0101ae8:	f7 f5                	div    %ebp
f0101aea:	89 c3                	mov    %eax,%ebx
f0101aec:	89 d8                	mov    %ebx,%eax
f0101aee:	89 fa                	mov    %edi,%edx
f0101af0:	83 c4 1c             	add    $0x1c,%esp
f0101af3:	5b                   	pop    %ebx
f0101af4:	5e                   	pop    %esi
f0101af5:	5f                   	pop    %edi
f0101af6:	5d                   	pop    %ebp
f0101af7:	c3                   	ret    
f0101af8:	90                   	nop
f0101af9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b00:	39 ce                	cmp    %ecx,%esi
f0101b02:	77 74                	ja     f0101b78 <__udivdi3+0xd8>
f0101b04:	0f bd fe             	bsr    %esi,%edi
f0101b07:	83 f7 1f             	xor    $0x1f,%edi
f0101b0a:	0f 84 98 00 00 00    	je     f0101ba8 <__udivdi3+0x108>
f0101b10:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101b15:	89 f9                	mov    %edi,%ecx
f0101b17:	89 c5                	mov    %eax,%ebp
f0101b19:	29 fb                	sub    %edi,%ebx
f0101b1b:	d3 e6                	shl    %cl,%esi
f0101b1d:	89 d9                	mov    %ebx,%ecx
f0101b1f:	d3 ed                	shr    %cl,%ebp
f0101b21:	89 f9                	mov    %edi,%ecx
f0101b23:	d3 e0                	shl    %cl,%eax
f0101b25:	09 ee                	or     %ebp,%esi
f0101b27:	89 d9                	mov    %ebx,%ecx
f0101b29:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b2d:	89 d5                	mov    %edx,%ebp
f0101b2f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101b33:	d3 ed                	shr    %cl,%ebp
f0101b35:	89 f9                	mov    %edi,%ecx
f0101b37:	d3 e2                	shl    %cl,%edx
f0101b39:	89 d9                	mov    %ebx,%ecx
f0101b3b:	d3 e8                	shr    %cl,%eax
f0101b3d:	09 c2                	or     %eax,%edx
f0101b3f:	89 d0                	mov    %edx,%eax
f0101b41:	89 ea                	mov    %ebp,%edx
f0101b43:	f7 f6                	div    %esi
f0101b45:	89 d5                	mov    %edx,%ebp
f0101b47:	89 c3                	mov    %eax,%ebx
f0101b49:	f7 64 24 0c          	mull   0xc(%esp)
f0101b4d:	39 d5                	cmp    %edx,%ebp
f0101b4f:	72 10                	jb     f0101b61 <__udivdi3+0xc1>
f0101b51:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101b55:	89 f9                	mov    %edi,%ecx
f0101b57:	d3 e6                	shl    %cl,%esi
f0101b59:	39 c6                	cmp    %eax,%esi
f0101b5b:	73 07                	jae    f0101b64 <__udivdi3+0xc4>
f0101b5d:	39 d5                	cmp    %edx,%ebp
f0101b5f:	75 03                	jne    f0101b64 <__udivdi3+0xc4>
f0101b61:	83 eb 01             	sub    $0x1,%ebx
f0101b64:	31 ff                	xor    %edi,%edi
f0101b66:	89 d8                	mov    %ebx,%eax
f0101b68:	89 fa                	mov    %edi,%edx
f0101b6a:	83 c4 1c             	add    $0x1c,%esp
f0101b6d:	5b                   	pop    %ebx
f0101b6e:	5e                   	pop    %esi
f0101b6f:	5f                   	pop    %edi
f0101b70:	5d                   	pop    %ebp
f0101b71:	c3                   	ret    
f0101b72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101b78:	31 ff                	xor    %edi,%edi
f0101b7a:	31 db                	xor    %ebx,%ebx
f0101b7c:	89 d8                	mov    %ebx,%eax
f0101b7e:	89 fa                	mov    %edi,%edx
f0101b80:	83 c4 1c             	add    $0x1c,%esp
f0101b83:	5b                   	pop    %ebx
f0101b84:	5e                   	pop    %esi
f0101b85:	5f                   	pop    %edi
f0101b86:	5d                   	pop    %ebp
f0101b87:	c3                   	ret    
f0101b88:	90                   	nop
f0101b89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b90:	89 d8                	mov    %ebx,%eax
f0101b92:	f7 f7                	div    %edi
f0101b94:	31 ff                	xor    %edi,%edi
f0101b96:	89 c3                	mov    %eax,%ebx
f0101b98:	89 d8                	mov    %ebx,%eax
f0101b9a:	89 fa                	mov    %edi,%edx
f0101b9c:	83 c4 1c             	add    $0x1c,%esp
f0101b9f:	5b                   	pop    %ebx
f0101ba0:	5e                   	pop    %esi
f0101ba1:	5f                   	pop    %edi
f0101ba2:	5d                   	pop    %ebp
f0101ba3:	c3                   	ret    
f0101ba4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ba8:	39 ce                	cmp    %ecx,%esi
f0101baa:	72 0c                	jb     f0101bb8 <__udivdi3+0x118>
f0101bac:	31 db                	xor    %ebx,%ebx
f0101bae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101bb2:	0f 87 34 ff ff ff    	ja     f0101aec <__udivdi3+0x4c>
f0101bb8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0101bbd:	e9 2a ff ff ff       	jmp    f0101aec <__udivdi3+0x4c>
f0101bc2:	66 90                	xchg   %ax,%ax
f0101bc4:	66 90                	xchg   %ax,%ax
f0101bc6:	66 90                	xchg   %ax,%ax
f0101bc8:	66 90                	xchg   %ax,%ax
f0101bca:	66 90                	xchg   %ax,%ax
f0101bcc:	66 90                	xchg   %ax,%ax
f0101bce:	66 90                	xchg   %ax,%ax

f0101bd0 <__umoddi3>:
f0101bd0:	55                   	push   %ebp
f0101bd1:	57                   	push   %edi
f0101bd2:	56                   	push   %esi
f0101bd3:	53                   	push   %ebx
f0101bd4:	83 ec 1c             	sub    $0x1c,%esp
f0101bd7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0101bdb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101bdf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101be3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101be7:	85 d2                	test   %edx,%edx
f0101be9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101bed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101bf1:	89 f3                	mov    %esi,%ebx
f0101bf3:	89 3c 24             	mov    %edi,(%esp)
f0101bf6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101bfa:	75 1c                	jne    f0101c18 <__umoddi3+0x48>
f0101bfc:	39 f7                	cmp    %esi,%edi
f0101bfe:	76 50                	jbe    f0101c50 <__umoddi3+0x80>
f0101c00:	89 c8                	mov    %ecx,%eax
f0101c02:	89 f2                	mov    %esi,%edx
f0101c04:	f7 f7                	div    %edi
f0101c06:	89 d0                	mov    %edx,%eax
f0101c08:	31 d2                	xor    %edx,%edx
f0101c0a:	83 c4 1c             	add    $0x1c,%esp
f0101c0d:	5b                   	pop    %ebx
f0101c0e:	5e                   	pop    %esi
f0101c0f:	5f                   	pop    %edi
f0101c10:	5d                   	pop    %ebp
f0101c11:	c3                   	ret    
f0101c12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101c18:	39 f2                	cmp    %esi,%edx
f0101c1a:	89 d0                	mov    %edx,%eax
f0101c1c:	77 52                	ja     f0101c70 <__umoddi3+0xa0>
f0101c1e:	0f bd ea             	bsr    %edx,%ebp
f0101c21:	83 f5 1f             	xor    $0x1f,%ebp
f0101c24:	75 5a                	jne    f0101c80 <__umoddi3+0xb0>
f0101c26:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0101c2a:	0f 82 e0 00 00 00    	jb     f0101d10 <__umoddi3+0x140>
f0101c30:	39 0c 24             	cmp    %ecx,(%esp)
f0101c33:	0f 86 d7 00 00 00    	jbe    f0101d10 <__umoddi3+0x140>
f0101c39:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101c3d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101c41:	83 c4 1c             	add    $0x1c,%esp
f0101c44:	5b                   	pop    %ebx
f0101c45:	5e                   	pop    %esi
f0101c46:	5f                   	pop    %edi
f0101c47:	5d                   	pop    %ebp
f0101c48:	c3                   	ret    
f0101c49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101c50:	85 ff                	test   %edi,%edi
f0101c52:	89 fd                	mov    %edi,%ebp
f0101c54:	75 0b                	jne    f0101c61 <__umoddi3+0x91>
f0101c56:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c5b:	31 d2                	xor    %edx,%edx
f0101c5d:	f7 f7                	div    %edi
f0101c5f:	89 c5                	mov    %eax,%ebp
f0101c61:	89 f0                	mov    %esi,%eax
f0101c63:	31 d2                	xor    %edx,%edx
f0101c65:	f7 f5                	div    %ebp
f0101c67:	89 c8                	mov    %ecx,%eax
f0101c69:	f7 f5                	div    %ebp
f0101c6b:	89 d0                	mov    %edx,%eax
f0101c6d:	eb 99                	jmp    f0101c08 <__umoddi3+0x38>
f0101c6f:	90                   	nop
f0101c70:	89 c8                	mov    %ecx,%eax
f0101c72:	89 f2                	mov    %esi,%edx
f0101c74:	83 c4 1c             	add    $0x1c,%esp
f0101c77:	5b                   	pop    %ebx
f0101c78:	5e                   	pop    %esi
f0101c79:	5f                   	pop    %edi
f0101c7a:	5d                   	pop    %ebp
f0101c7b:	c3                   	ret    
f0101c7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c80:	8b 34 24             	mov    (%esp),%esi
f0101c83:	bf 20 00 00 00       	mov    $0x20,%edi
f0101c88:	89 e9                	mov    %ebp,%ecx
f0101c8a:	29 ef                	sub    %ebp,%edi
f0101c8c:	d3 e0                	shl    %cl,%eax
f0101c8e:	89 f9                	mov    %edi,%ecx
f0101c90:	89 f2                	mov    %esi,%edx
f0101c92:	d3 ea                	shr    %cl,%edx
f0101c94:	89 e9                	mov    %ebp,%ecx
f0101c96:	09 c2                	or     %eax,%edx
f0101c98:	89 d8                	mov    %ebx,%eax
f0101c9a:	89 14 24             	mov    %edx,(%esp)
f0101c9d:	89 f2                	mov    %esi,%edx
f0101c9f:	d3 e2                	shl    %cl,%edx
f0101ca1:	89 f9                	mov    %edi,%ecx
f0101ca3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101ca7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101cab:	d3 e8                	shr    %cl,%eax
f0101cad:	89 e9                	mov    %ebp,%ecx
f0101caf:	89 c6                	mov    %eax,%esi
f0101cb1:	d3 e3                	shl    %cl,%ebx
f0101cb3:	89 f9                	mov    %edi,%ecx
f0101cb5:	89 d0                	mov    %edx,%eax
f0101cb7:	d3 e8                	shr    %cl,%eax
f0101cb9:	89 e9                	mov    %ebp,%ecx
f0101cbb:	09 d8                	or     %ebx,%eax
f0101cbd:	89 d3                	mov    %edx,%ebx
f0101cbf:	89 f2                	mov    %esi,%edx
f0101cc1:	f7 34 24             	divl   (%esp)
f0101cc4:	89 d6                	mov    %edx,%esi
f0101cc6:	d3 e3                	shl    %cl,%ebx
f0101cc8:	f7 64 24 04          	mull   0x4(%esp)
f0101ccc:	39 d6                	cmp    %edx,%esi
f0101cce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101cd2:	89 d1                	mov    %edx,%ecx
f0101cd4:	89 c3                	mov    %eax,%ebx
f0101cd6:	72 08                	jb     f0101ce0 <__umoddi3+0x110>
f0101cd8:	75 11                	jne    f0101ceb <__umoddi3+0x11b>
f0101cda:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101cde:	73 0b                	jae    f0101ceb <__umoddi3+0x11b>
f0101ce0:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101ce4:	1b 14 24             	sbb    (%esp),%edx
f0101ce7:	89 d1                	mov    %edx,%ecx
f0101ce9:	89 c3                	mov    %eax,%ebx
f0101ceb:	8b 54 24 08          	mov    0x8(%esp),%edx
f0101cef:	29 da                	sub    %ebx,%edx
f0101cf1:	19 ce                	sbb    %ecx,%esi
f0101cf3:	89 f9                	mov    %edi,%ecx
f0101cf5:	89 f0                	mov    %esi,%eax
f0101cf7:	d3 e0                	shl    %cl,%eax
f0101cf9:	89 e9                	mov    %ebp,%ecx
f0101cfb:	d3 ea                	shr    %cl,%edx
f0101cfd:	89 e9                	mov    %ebp,%ecx
f0101cff:	d3 ee                	shr    %cl,%esi
f0101d01:	09 d0                	or     %edx,%eax
f0101d03:	89 f2                	mov    %esi,%edx
f0101d05:	83 c4 1c             	add    $0x1c,%esp
f0101d08:	5b                   	pop    %ebx
f0101d09:	5e                   	pop    %esi
f0101d0a:	5f                   	pop    %edi
f0101d0b:	5d                   	pop    %ebp
f0101d0c:	c3                   	ret    
f0101d0d:	8d 76 00             	lea    0x0(%esi),%esi
f0101d10:	29 f9                	sub    %edi,%ecx
f0101d12:	19 d6                	sbb    %edx,%esi
f0101d14:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d18:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101d1c:	e9 18 ff ff ff       	jmp    f0101c39 <__umoddi3+0x69>
