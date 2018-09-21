
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
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 68 32 00 00       	call   f01032c5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 37 10 f0       	push   $0xf0103760
f010006f:	e8 a8 27 00 00       	call   f010281c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 91 10 00 00       	call   f010110a <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 52 07 00 00       	call   f01007d8 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 7b 37 10 f0       	push   $0xf010377b
f01000b5:	e8 62 27 00 00       	call   f010281c <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 32 27 00 00       	call   f01027f6 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 75 3f 10 f0 	movl   $0xf0103f75,(%esp)
f01000cb:	e8 4c 27 00 00       	call   f010281c <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 fb 06 00 00       	call   f01007d8 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 93 37 10 f0       	push   $0xf0103793
f01000f7:	e8 20 27 00 00       	call   f010281c <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 ee 26 00 00       	call   f01027f6 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 75 3f 10 f0 	movl   $0xf0103f75,(%esp)
f010010f:	e8 08 27 00 00       	call   f010281c <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 00 39 10 f0 	movzbl -0xfefc700(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 00 39 10 f0 	movzbl -0xfefc700(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a 00 38 10 f0 	movzbl -0xfefc800(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d e0 37 10 f0 	mov    -0xfefc820(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 ad 37 10 f0       	push   $0xf01037ad
f010026d:	e8 aa 25 00 00       	call   f010281c <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 f1 2e 00 00       	call   f0103312 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004c3:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004d4:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 b9 37 10 f0       	push   $0xf01037b9
f01005f0:	e8 27 22 00 00       	call   f010281c <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 00 3a 10 f0       	push   $0xf0103a00
f0100636:	68 1e 3a 10 f0       	push   $0xf0103a1e
f010063b:	68 23 3a 10 f0       	push   $0xf0103a23
f0100640:	e8 d7 21 00 00       	call   f010281c <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 d8 3a 10 f0       	push   $0xf0103ad8
f010064d:	68 2c 3a 10 f0       	push   $0xf0103a2c
f0100652:	68 23 3a 10 f0       	push   $0xf0103a23
f0100657:	e8 c0 21 00 00       	call   f010281c <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 00 3b 10 f0       	push   $0xf0103b00
f0100664:	68 35 3a 10 f0       	push   $0xf0103a35
f0100669:	68 23 3a 10 f0       	push   $0xf0103a23
f010066e:	e8 a9 21 00 00       	call   f010281c <cprintf>
	return 0;
}
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100680:	68 3f 3a 10 f0       	push   $0xf0103a3f
f0100685:	e8 92 21 00 00       	call   f010281c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 30 3b 10 f0       	push   $0xf0103b30
f0100697:	e8 80 21 00 00       	call   f010281c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 58 3b 10 f0       	push   $0xf0103b58
f01006ae:	e8 69 21 00 00       	call   f010281c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 51 37 10 00       	push   $0x103751
f01006bb:	68 51 37 10 f0       	push   $0xf0103751
f01006c0:	68 7c 3b 10 f0       	push   $0xf0103b7c
f01006c5:	e8 52 21 00 00       	call   f010281c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 73 11 00       	push   $0x117300
f01006d2:	68 00 73 11 f0       	push   $0xf0117300
f01006d7:	68 a0 3b 10 f0       	push   $0xf0103ba0
f01006dc:	e8 3b 21 00 00       	call   f010281c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 70 79 11 00       	push   $0x117970
f01006e9:	68 70 79 11 f0       	push   $0xf0117970
f01006ee:	68 c4 3b 10 f0       	push   $0xf0103bc4
f01006f3:	e8 24 21 00 00       	call   f010281c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006fd:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100702:	83 c4 08             	add    $0x8,%esp
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	50                   	push   %eax
f0100719:	68 e8 3b 10 f0       	push   $0xf0103be8
f010071e:	e8 f9 20 00 00       	call   f010281c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100723:	b8 00 00 00 00       	mov    $0x0,%eax
f0100728:	c9                   	leave  
f0100729:	c3                   	ret    

f010072a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072a:	55                   	push   %ebp
f010072b:	89 e5                	mov    %esp,%ebp
f010072d:	57                   	push   %edi
f010072e:	56                   	push   %esi
f010072f:	53                   	push   %ebx
f0100730:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100733:	89 ee                	mov    %ebp,%esi
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");
f0100735:	68 58 3a 10 f0       	push   $0xf0103a58
f010073a:	e8 dd 20 00 00       	call   f010281c <cprintf>

	while(ebp) {
f010073f:	83 c4 10             	add    $0x10,%esp
f0100742:	eb 7f                	jmp    f01007c3 <mon_backtrace+0x99>
		cprintf("ebp %08x ", ebp);
f0100744:	83 ec 08             	sub    $0x8,%esp
f0100747:	56                   	push   %esi
f0100748:	68 6a 3a 10 f0       	push   $0xf0103a6a
f010074d:	e8 ca 20 00 00       	call   f010281c <cprintf>
		cprintf("eip %08x args", ebp[1]);
f0100752:	83 c4 08             	add    $0x8,%esp
f0100755:	ff 76 04             	pushl  0x4(%esi)
f0100758:	68 74 3a 10 f0       	push   $0xf0103a74
f010075d:	e8 ba 20 00 00       	call   f010281c <cprintf>
f0100762:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100765:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100768:	83 c4 10             	add    $0x10,%esp
		for(int i = 2; i <= 6; i++)
			cprintf(" %08x", ebp[i]);
f010076b:	83 ec 08             	sub    $0x8,%esp
f010076e:	ff 33                	pushl  (%ebx)
f0100770:	68 82 3a 10 f0       	push   $0xf0103a82
f0100775:	e8 a2 20 00 00       	call   f010281c <cprintf>
f010077a:	83 c3 04             	add    $0x4,%ebx
	cprintf("Stack backtrace:\n");

	while(ebp) {
		cprintf("ebp %08x ", ebp);
		cprintf("eip %08x args", ebp[1]);
		for(int i = 2; i <= 6; i++)
f010077d:	83 c4 10             	add    $0x10,%esp
f0100780:	39 fb                	cmp    %edi,%ebx
f0100782:	75 e7                	jne    f010076b <mon_backtrace+0x41>
			cprintf(" %08x", ebp[i]);
		cprintf("\n");
f0100784:	83 ec 0c             	sub    $0xc,%esp
f0100787:	68 75 3f 10 f0       	push   $0xf0103f75
f010078c:	e8 8b 20 00 00       	call   f010281c <cprintf>

		unsigned int eip = ebp[1];
f0100791:	8b 5e 04             	mov    0x4(%esi),%ebx
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100794:	83 c4 08             	add    $0x8,%esp
f0100797:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010079a:	50                   	push   %eax
f010079b:	53                   	push   %ebx
f010079c:	e8 85 21 00 00       	call   f0102926 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f01007a1:	83 c4 08             	add    $0x8,%esp
f01007a4:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f01007a7:	53                   	push   %ebx
f01007a8:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ab:	ff 75 dc             	pushl  -0x24(%ebp)
f01007ae:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007b1:	ff 75 d0             	pushl  -0x30(%ebp)
f01007b4:	68 88 3a 10 f0       	push   $0xf0103a88
f01007b9:	e8 5e 20 00 00       	call   f010281c <cprintf>
		info.eip_file, info.eip_line,
		info.eip_fn_namelen, info.eip_fn_name,
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
f01007be:	8b 36                	mov    (%esi),%esi
f01007c0:	83 c4 20             	add    $0x20,%esp
{
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");

	while(ebp) {
f01007c3:	85 f6                	test   %esi,%esi
f01007c5:	0f 85 79 ff ff ff    	jne    f0100744 <mon_backtrace+0x1a>
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
	}
	return 0;
}
f01007cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007d3:	5b                   	pop    %ebx
f01007d4:	5e                   	pop    %esi
f01007d5:	5f                   	pop    %edi
f01007d6:	5d                   	pop    %ebp
f01007d7:	c3                   	ret    

f01007d8 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007d8:	55                   	push   %ebp
f01007d9:	89 e5                	mov    %esp,%ebp
f01007db:	57                   	push   %edi
f01007dc:	56                   	push   %esi
f01007dd:	53                   	push   %ebx
f01007de:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007e1:	68 14 3c 10 f0       	push   $0xf0103c14
f01007e6:	e8 31 20 00 00       	call   f010281c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007eb:	c7 04 24 38 3c 10 f0 	movl   $0xf0103c38,(%esp)
f01007f2:	e8 25 20 00 00       	call   f010281c <cprintf>
f01007f7:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007fa:	83 ec 0c             	sub    $0xc,%esp
f01007fd:	68 99 3a 10 f0       	push   $0xf0103a99
f0100802:	e8 67 28 00 00       	call   f010306e <readline>
f0100807:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100809:	83 c4 10             	add    $0x10,%esp
f010080c:	85 c0                	test   %eax,%eax
f010080e:	74 ea                	je     f01007fa <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100810:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100817:	be 00 00 00 00       	mov    $0x0,%esi
f010081c:	eb 0a                	jmp    f0100828 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010081e:	c6 03 00             	movb   $0x0,(%ebx)
f0100821:	89 f7                	mov    %esi,%edi
f0100823:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100826:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100828:	0f b6 03             	movzbl (%ebx),%eax
f010082b:	84 c0                	test   %al,%al
f010082d:	74 63                	je     f0100892 <monitor+0xba>
f010082f:	83 ec 08             	sub    $0x8,%esp
f0100832:	0f be c0             	movsbl %al,%eax
f0100835:	50                   	push   %eax
f0100836:	68 9d 3a 10 f0       	push   $0xf0103a9d
f010083b:	e8 48 2a 00 00       	call   f0103288 <strchr>
f0100840:	83 c4 10             	add    $0x10,%esp
f0100843:	85 c0                	test   %eax,%eax
f0100845:	75 d7                	jne    f010081e <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100847:	80 3b 00             	cmpb   $0x0,(%ebx)
f010084a:	74 46                	je     f0100892 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010084c:	83 fe 0f             	cmp    $0xf,%esi
f010084f:	75 14                	jne    f0100865 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100851:	83 ec 08             	sub    $0x8,%esp
f0100854:	6a 10                	push   $0x10
f0100856:	68 a2 3a 10 f0       	push   $0xf0103aa2
f010085b:	e8 bc 1f 00 00       	call   f010281c <cprintf>
f0100860:	83 c4 10             	add    $0x10,%esp
f0100863:	eb 95                	jmp    f01007fa <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100865:	8d 7e 01             	lea    0x1(%esi),%edi
f0100868:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010086c:	eb 03                	jmp    f0100871 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010086e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100871:	0f b6 03             	movzbl (%ebx),%eax
f0100874:	84 c0                	test   %al,%al
f0100876:	74 ae                	je     f0100826 <monitor+0x4e>
f0100878:	83 ec 08             	sub    $0x8,%esp
f010087b:	0f be c0             	movsbl %al,%eax
f010087e:	50                   	push   %eax
f010087f:	68 9d 3a 10 f0       	push   $0xf0103a9d
f0100884:	e8 ff 29 00 00       	call   f0103288 <strchr>
f0100889:	83 c4 10             	add    $0x10,%esp
f010088c:	85 c0                	test   %eax,%eax
f010088e:	74 de                	je     f010086e <monitor+0x96>
f0100890:	eb 94                	jmp    f0100826 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100892:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100899:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010089a:	85 f6                	test   %esi,%esi
f010089c:	0f 84 58 ff ff ff    	je     f01007fa <monitor+0x22>
f01008a2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a7:	83 ec 08             	sub    $0x8,%esp
f01008aa:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ad:	ff 34 85 60 3c 10 f0 	pushl  -0xfefc3a0(,%eax,4)
f01008b4:	ff 75 a8             	pushl  -0x58(%ebp)
f01008b7:	e8 6e 29 00 00       	call   f010322a <strcmp>
f01008bc:	83 c4 10             	add    $0x10,%esp
f01008bf:	85 c0                	test   %eax,%eax
f01008c1:	75 21                	jne    f01008e4 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008c3:	83 ec 04             	sub    $0x4,%esp
f01008c6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c9:	ff 75 08             	pushl  0x8(%ebp)
f01008cc:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008cf:	52                   	push   %edx
f01008d0:	56                   	push   %esi
f01008d1:	ff 14 85 68 3c 10 f0 	call   *-0xfefc398(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d8:	83 c4 10             	add    $0x10,%esp
f01008db:	85 c0                	test   %eax,%eax
f01008dd:	78 25                	js     f0100904 <monitor+0x12c>
f01008df:	e9 16 ff ff ff       	jmp    f01007fa <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008e4:	83 c3 01             	add    $0x1,%ebx
f01008e7:	83 fb 03             	cmp    $0x3,%ebx
f01008ea:	75 bb                	jne    f01008a7 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008ec:	83 ec 08             	sub    $0x8,%esp
f01008ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01008f2:	68 bf 3a 10 f0       	push   $0xf0103abf
f01008f7:	e8 20 1f 00 00       	call   f010281c <cprintf>
f01008fc:	83 c4 10             	add    $0x10,%esp
f01008ff:	e9 f6 fe ff ff       	jmp    f01007fa <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100904:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100907:	5b                   	pop    %ebx
f0100908:	5e                   	pop    %esi
f0100909:	5f                   	pop    %edi
f010090a:	5d                   	pop    %ebp
f010090b:	c3                   	ret    

f010090c <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010090c:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100913:	75 60                	jne    f0100975 <boot_alloc+0x69>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100915:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f010091a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100920:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0) {
f0100926:	85 c0                	test   %eax,%eax
f0100928:	74 42                	je     f010096c <boot_alloc+0x60>
		result = nextfree;
f010092a:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
		nextfree = ROUNDUP((char*)(nextfree+n), PGSIZE);
f0100930:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100937:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010093d:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
		if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
f0100943:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100949:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010094e:	c1 e0 0c             	shl    $0xc,%eax
f0100951:	39 c2                	cmp    %eax,%edx
f0100953:	76 1d                	jbe    f0100972 <boot_alloc+0x66>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100955:	55                   	push   %ebp
f0100956:	89 e5                	mov    %esp,%ebp
f0100958:	83 ec 0c             	sub    $0xc,%esp
	// LAB 2: Your code here.
	if(n > 0) {
		result = nextfree;
		nextfree = ROUNDUP((char*)(nextfree+n), PGSIZE);
		if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
			panic("Out Of Memory!\n");
f010095b:	68 84 3c 10 f0       	push   $0xf0103c84
f0100960:	6a 6a                	push   $0x6a
f0100962:	68 94 3c 10 f0       	push   $0xf0103c94
f0100967:	e8 1f f7 ff ff       	call   f010008b <_panic>
//		cprintf("allocate %d bytes, update nextfree to %x\n", n, nextfree);
		return result;
	}
	else if(n == 0)
		return nextfree;
f010096c:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f0100971:	c3                   	ret    
		result = nextfree;
		nextfree = ROUNDUP((char*)(nextfree+n), PGSIZE);
		if((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
			panic("Out Of Memory!\n");
//		cprintf("allocate %d bytes, update nextfree to %x\n", n, nextfree);
		return result;
f0100972:	89 c8                	mov    %ecx,%eax
f0100974:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n > 0) {
f0100975:	85 c0                	test   %eax,%eax
f0100977:	75 b1                	jne    f010092a <boot_alloc+0x1e>
f0100979:	eb f1                	jmp    f010096c <boot_alloc+0x60>

f010097b <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010097b:	89 d1                	mov    %edx,%ecx
f010097d:	c1 e9 16             	shr    $0x16,%ecx
f0100980:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100983:	a8 01                	test   $0x1,%al
f0100985:	74 52                	je     f01009d9 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100987:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010098c:	89 c1                	mov    %eax,%ecx
f010098e:	c1 e9 0c             	shr    $0xc,%ecx
f0100991:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100997:	72 1b                	jb     f01009b4 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100999:	55                   	push   %ebp
f010099a:	89 e5                	mov    %esp,%ebp
f010099c:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010099f:	50                   	push   %eax
f01009a0:	68 a8 3f 10 f0       	push   $0xf0103fa8
f01009a5:	68 e4 02 00 00       	push   $0x2e4
f01009aa:	68 94 3c 10 f0       	push   $0xf0103c94
f01009af:	e8 d7 f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009b4:	c1 ea 0c             	shr    $0xc,%edx
f01009b7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009bd:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009c4:	89 c2                	mov    %eax,%edx
f01009c6:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009c9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009ce:	85 d2                	test   %edx,%edx
f01009d0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009d5:	0f 44 c2             	cmove  %edx,%eax
f01009d8:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009de:	c3                   	ret    

f01009df <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009df:	55                   	push   %ebp
f01009e0:	89 e5                	mov    %esp,%ebp
f01009e2:	57                   	push   %edi
f01009e3:	56                   	push   %esi
f01009e4:	53                   	push   %ebx
f01009e5:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009e8:	84 c0                	test   %al,%al
f01009ea:	0f 85 af 02 00 00    	jne    f0100c9f <check_page_free_list+0x2c0>
f01009f0:	e9 bc 02 00 00       	jmp    f0100cb1 <check_page_free_list+0x2d2>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009f5:	83 ec 04             	sub    $0x4,%esp
f01009f8:	68 cc 3f 10 f0       	push   $0xf0103fcc
f01009fd:	68 22 02 00 00       	push   $0x222
f0100a02:	68 94 3c 10 f0       	push   $0xf0103c94
f0100a07:	e8 7f f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		cprintf("before hanling low memory question, page_free_list is %x now\n", page_free_list);
f0100a0c:	83 ec 08             	sub    $0x8,%esp
f0100a0f:	50                   	push   %eax
f0100a10:	68 f0 3f 10 f0       	push   $0xf0103ff0
f0100a15:	e8 02 1e 00 00       	call   f010281c <cprintf>
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a1a:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100a1d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100a20:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100a23:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a26:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100a2b:	83 c4 10             	add    $0x10,%esp
f0100a2e:	eb 20                	jmp    f0100a50 <check_page_free_list+0x71>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a30:	89 c2                	mov    %eax,%edx
f0100a32:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100a38:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a3e:	0f 95 c2             	setne  %dl
f0100a41:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a44:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a48:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a4a:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		cprintf("before hanling low memory question, page_free_list is %x now\n", page_free_list);
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a4e:	8b 00                	mov    (%eax),%eax
f0100a50:	85 c0                	test   %eax,%eax
f0100a52:	75 dc                	jne    f0100a30 <check_page_free_list+0x51>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a57:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a5d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a60:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a63:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a65:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a68:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a6d:	be 01 00 00 00       	mov    $0x1,%esi
		*tp[1] = 0;
		*tp[0] = pp2;
		page_free_list = pp1;
}

	cprintf("after hanling low memory question, page_free_list is %x now\n", page_free_list);
f0100a72:	83 ec 08             	sub    $0x8,%esp
f0100a75:	ff 35 3c 75 11 f0    	pushl  0xf011753c
f0100a7b:	68 30 40 10 f0       	push   $0xf0104030
f0100a80:	e8 97 1d 00 00       	call   f010281c <cprintf>

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a85:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a8b:	83 c4 10             	add    $0x10,%esp
f0100a8e:	eb 53                	jmp    f0100ae3 <check_page_free_list+0x104>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a90:	89 d8                	mov    %ebx,%eax
f0100a92:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a98:	c1 f8 03             	sar    $0x3,%eax
f0100a9b:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a9e:	89 c2                	mov    %eax,%edx
f0100aa0:	c1 ea 16             	shr    $0x16,%edx
f0100aa3:	39 f2                	cmp    %esi,%edx
f0100aa5:	73 3a                	jae    f0100ae1 <check_page_free_list+0x102>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aa7:	89 c2                	mov    %eax,%edx
f0100aa9:	c1 ea 0c             	shr    $0xc,%edx
f0100aac:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ab2:	72 12                	jb     f0100ac6 <check_page_free_list+0xe7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ab4:	50                   	push   %eax
f0100ab5:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0100aba:	6a 52                	push   $0x52
f0100abc:	68 a0 3c 10 f0       	push   $0xf0103ca0
f0100ac1:	e8 c5 f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100ac6:	83 ec 04             	sub    $0x4,%esp
f0100ac9:	68 80 00 00 00       	push   $0x80
f0100ace:	68 97 00 00 00       	push   $0x97
f0100ad3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ad8:	50                   	push   %eax
f0100ad9:	e8 e7 27 00 00       	call   f01032c5 <memset>
f0100ade:	83 c4 10             	add    $0x10,%esp

	cprintf("after hanling low memory question, page_free_list is %x now\n", page_free_list);

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ae1:	8b 1b                	mov    (%ebx),%ebx
f0100ae3:	85 db                	test   %ebx,%ebx
f0100ae5:	75 a9                	jne    f0100a90 <check_page_free_list+0xb1>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ae7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aec:	e8 1b fe ff ff       	call   f010090c <boot_alloc>
f0100af1:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100af4:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100afa:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100b00:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100b05:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b08:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b0b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b0e:	be 00 00 00 00       	mov    $0x0,%esi
f0100b13:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b16:	e9 30 01 00 00       	jmp    f0100c4b <check_page_free_list+0x26c>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b1b:	39 ca                	cmp    %ecx,%edx
f0100b1d:	73 19                	jae    f0100b38 <check_page_free_list+0x159>
f0100b1f:	68 ae 3c 10 f0       	push   $0xf0103cae
f0100b24:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100b29:	68 3f 02 00 00       	push   $0x23f
f0100b2e:	68 94 3c 10 f0       	push   $0xf0103c94
f0100b33:	e8 53 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b38:	39 fa                	cmp    %edi,%edx
f0100b3a:	72 19                	jb     f0100b55 <check_page_free_list+0x176>
f0100b3c:	68 cf 3c 10 f0       	push   $0xf0103ccf
f0100b41:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100b46:	68 40 02 00 00       	push   $0x240
f0100b4b:	68 94 3c 10 f0       	push   $0xf0103c94
f0100b50:	e8 36 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b55:	89 d0                	mov    %edx,%eax
f0100b57:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b5a:	a8 07                	test   $0x7,%al
f0100b5c:	74 19                	je     f0100b77 <check_page_free_list+0x198>
f0100b5e:	68 70 40 10 f0       	push   $0xf0104070
f0100b63:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100b68:	68 41 02 00 00       	push   $0x241
f0100b6d:	68 94 3c 10 f0       	push   $0xf0103c94
f0100b72:	e8 14 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b77:	c1 f8 03             	sar    $0x3,%eax
f0100b7a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b7d:	85 c0                	test   %eax,%eax
f0100b7f:	75 19                	jne    f0100b9a <check_page_free_list+0x1bb>
f0100b81:	68 e3 3c 10 f0       	push   $0xf0103ce3
f0100b86:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100b8b:	68 44 02 00 00       	push   $0x244
f0100b90:	68 94 3c 10 f0       	push   $0xf0103c94
f0100b95:	e8 f1 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b9a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b9f:	75 19                	jne    f0100bba <check_page_free_list+0x1db>
f0100ba1:	68 f4 3c 10 f0       	push   $0xf0103cf4
f0100ba6:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100bab:	68 45 02 00 00       	push   $0x245
f0100bb0:	68 94 3c 10 f0       	push   $0xf0103c94
f0100bb5:	e8 d1 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bba:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bbf:	75 19                	jne    f0100bda <check_page_free_list+0x1fb>
f0100bc1:	68 a4 40 10 f0       	push   $0xf01040a4
f0100bc6:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100bcb:	68 46 02 00 00       	push   $0x246
f0100bd0:	68 94 3c 10 f0       	push   $0xf0103c94
f0100bd5:	e8 b1 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bda:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bdf:	75 19                	jne    f0100bfa <check_page_free_list+0x21b>
f0100be1:	68 0d 3d 10 f0       	push   $0xf0103d0d
f0100be6:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100beb:	68 47 02 00 00       	push   $0x247
f0100bf0:	68 94 3c 10 f0       	push   $0xf0103c94
f0100bf5:	e8 91 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bfa:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bff:	76 3f                	jbe    f0100c40 <check_page_free_list+0x261>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c01:	89 c3                	mov    %eax,%ebx
f0100c03:	c1 eb 0c             	shr    $0xc,%ebx
f0100c06:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c09:	77 12                	ja     f0100c1d <check_page_free_list+0x23e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c0b:	50                   	push   %eax
f0100c0c:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0100c11:	6a 52                	push   $0x52
f0100c13:	68 a0 3c 10 f0       	push   $0xf0103ca0
f0100c18:	e8 6e f4 ff ff       	call   f010008b <_panic>
f0100c1d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c22:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c25:	76 1e                	jbe    f0100c45 <check_page_free_list+0x266>
f0100c27:	68 c8 40 10 f0       	push   $0xf01040c8
f0100c2c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100c31:	68 48 02 00 00       	push   $0x248
f0100c36:	68 94 3c 10 f0       	push   $0xf0103c94
f0100c3b:	e8 4b f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c40:	83 c6 01             	add    $0x1,%esi
f0100c43:	eb 04                	jmp    f0100c49 <check_page_free_list+0x26a>
		else
			++nfree_extmem;
f0100c45:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c49:	8b 12                	mov    (%edx),%edx
f0100c4b:	85 d2                	test   %edx,%edx
f0100c4d:	0f 85 c8 fe ff ff    	jne    f0100b1b <check_page_free_list+0x13c>
f0100c53:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c56:	85 f6                	test   %esi,%esi
f0100c58:	7f 19                	jg     f0100c73 <check_page_free_list+0x294>
f0100c5a:	68 27 3d 10 f0       	push   $0xf0103d27
f0100c5f:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100c64:	68 50 02 00 00       	push   $0x250
f0100c69:	68 94 3c 10 f0       	push   $0xf0103c94
f0100c6e:	e8 18 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c73:	85 db                	test   %ebx,%ebx
f0100c75:	7f 19                	jg     f0100c90 <check_page_free_list+0x2b1>
f0100c77:	68 39 3d 10 f0       	push   $0xf0103d39
f0100c7c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0100c81:	68 51 02 00 00       	push   $0x251
f0100c86:	68 94 3c 10 f0       	push   $0xf0103c94
f0100c8b:	e8 fb f3 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100c90:	83 ec 0c             	sub    $0xc,%esp
f0100c93:	68 10 41 10 f0       	push   $0xf0104110
f0100c98:	e8 7f 1b 00 00       	call   f010281c <cprintf>
}
f0100c9d:	eb 29                	jmp    f0100cc8 <check_page_free_list+0x2e9>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c9f:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100ca4:	85 c0                	test   %eax,%eax
f0100ca6:	0f 85 60 fd ff ff    	jne    f0100a0c <check_page_free_list+0x2d>
f0100cac:	e9 44 fd ff ff       	jmp    f01009f5 <check_page_free_list+0x16>
f0100cb1:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100cb8:	0f 84 37 fd ff ff    	je     f01009f5 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cbe:	be 00 04 00 00       	mov    $0x400,%esi
f0100cc3:	e9 aa fd ff ff       	jmp    f0100a72 <check_page_free_list+0x93>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100cc8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ccb:	5b                   	pop    %ebx
f0100ccc:	5e                   	pop    %esi
f0100ccd:	5f                   	pop    %edi
f0100cce:	5d                   	pop    %ebp
f0100ccf:	c3                   	ret    

f0100cd0 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cd0:	55                   	push   %ebp
f0100cd1:	89 e5                	mov    %esp,%ebp
f0100cd3:	57                   	push   %edi
f0100cd4:	56                   	push   %esi
f0100cd5:	53                   	push   %ebx
f0100cd6:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f0100cd9:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0100ce0:	00 00 00 

	
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
f0100ce3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ce8:	e8 1f fc ff ff       	call   f010090c <boot_alloc>
f0100ced:	05 00 00 00 10       	add    $0x10000000,%eax
f0100cf2:	c1 e8 0c             	shr    $0xc,%eax
	
	int num_iohole = 96;

	pages[0].pp_ref = 1;
f0100cf5:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100cfb:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	for(i = 1; i < npages_basemem; i++)
f0100d01:	8b 35 40 75 11 f0    	mov    0xf0117540,%esi
f0100d07:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d0c:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d11:	ba 01 00 00 00       	mov    $0x1,%edx
f0100d16:	eb 27                	jmp    f0100d3f <page_init+0x6f>
	{
		pages[i].pp_ref = 0;
f0100d18:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100d1f:	89 cb                	mov    %ecx,%ebx
f0100d21:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
f0100d27:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0100d2d:	89 3b                	mov    %edi,(%ebx)
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	
	int num_iohole = 96;

	pages[0].pp_ref = 1;
	for(i = 1; i < npages_basemem; i++)
f0100d2f:	83 c2 01             	add    $0x1,%edx
	{
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100d32:	89 cf                	mov    %ecx,%edi
f0100d34:	03 3d 6c 79 11 f0    	add    0xf011796c,%edi
f0100d3a:	b9 01 00 00 00       	mov    $0x1,%ecx
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	
	int num_iohole = 96;

	pages[0].pp_ref = 1;
	for(i = 1; i < npages_basemem; i++)
f0100d3f:	39 f2                	cmp    %esi,%edx
f0100d41:	72 d5                	jb     f0100d18 <page_init+0x48>
f0100d43:	84 c9                	test   %cl,%cl
f0100d45:	74 06                	je     f0100d4d <page_init+0x7d>
f0100d47:	89 3d 3c 75 11 f0    	mov    %edi,0xf011753c
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
		pages[i].pp_ref = 1;
f0100d4d:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
	
	int num_iohole = 96;

	pages[0].pp_ref = 1;
	for(i = 1; i < npages_basemem; i++)
f0100d53:	89 f2                	mov    %esi,%edx
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
f0100d55:	8d 44 30 60          	lea    0x60(%eax,%esi,1),%eax
f0100d59:	eb 0a                	jmp    f0100d65 <page_init+0x95>
		pages[i].pp_ref = 1;
f0100d5b:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
f0100d62:	83 c2 01             	add    $0x1,%edx
f0100d65:	39 c2                	cmp    %eax,%edx
f0100d67:	72 f2                	jb     f0100d5b <page_init+0x8b>
f0100d69:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d6f:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f0100d76:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d7b:	eb 23                	jmp    f0100da0 <page_init+0xd0>
		pages[i].pp_ref = 1;
	for(; i < npages; i++)
	{
		pages[i].pp_ref = 0;
f0100d7d:	89 c1                	mov    %eax,%ecx
f0100d7f:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100d85:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d8b:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100d8d:	89 c3                	mov    %eax,%ebx
f0100d8f:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
		page_free_list = &pages[i];
	}

	for(i = npages_basemem; i < npages_basemem + num_iohole + num_alloc; i++)
		pages[i].pp_ref = 1;
	for(; i < npages; i++)
f0100d95:	83 c2 01             	add    $0x1,%edx
f0100d98:	83 c0 08             	add    $0x8,%eax
f0100d9b:	b9 01 00 00 00       	mov    $0x1,%ecx
f0100da0:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100da6:	72 d5                	jb     f0100d7d <page_init+0xad>
f0100da8:	84 c9                	test   %cl,%cl
f0100daa:	74 06                	je     f0100db2 <page_init+0xe2>
f0100dac:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
	{
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
}
}
f0100db2:	83 c4 0c             	add    $0xc,%esp
f0100db5:	5b                   	pop    %ebx
f0100db6:	5e                   	pop    %esi
f0100db7:	5f                   	pop    %edi
f0100db8:	5d                   	pop    %ebp
f0100db9:	c3                   	ret    

f0100dba <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100dba:	55                   	push   %ebp
f0100dbb:	89 e5                	mov    %esp,%ebp
f0100dbd:	53                   	push   %ebx
f0100dbe:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(!page_free_list)
f0100dc1:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100dc7:	85 db                	test   %ebx,%ebx
f0100dc9:	74 58                	je     f0100e23 <page_alloc+0x69>
		return NULL;
	struct PageInfo *pp = page_free_list;
	if(alloc_flags & ALLOC_ZERO) {
f0100dcb:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100dcf:	74 45                	je     f0100e16 <page_alloc+0x5c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dd1:	89 d8                	mov    %ebx,%eax
f0100dd3:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100dd9:	c1 f8 03             	sar    $0x3,%eax
f0100ddc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ddf:	89 c2                	mov    %eax,%edx
f0100de1:	c1 ea 0c             	shr    $0xc,%edx
f0100de4:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100dea:	72 12                	jb     f0100dfe <page_alloc+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dec:	50                   	push   %eax
f0100ded:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0100df2:	6a 52                	push   $0x52
f0100df4:	68 a0 3c 10 f0       	push   $0xf0103ca0
f0100df9:	e8 8d f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(pp), 0, PGSIZE);
f0100dfe:	83 ec 04             	sub    $0x4,%esp
f0100e01:	68 00 10 00 00       	push   $0x1000
f0100e06:	6a 00                	push   $0x0
f0100e08:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e0d:	50                   	push   %eax
f0100e0e:	e8 b2 24 00 00       	call   f01032c5 <memset>
f0100e13:	83 c4 10             	add    $0x10,%esp
	}
	page_free_list = pp->pp_link;
f0100e16:	8b 03                	mov    (%ebx),%eax
f0100e18:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	pp->pp_link = 0;
f0100e1d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
return pp;
}
f0100e23:	89 d8                	mov    %ebx,%eax
f0100e25:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e28:	c9                   	leave  
f0100e29:	c3                   	ret    

f0100e2a <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e2a:	55                   	push   %ebp
f0100e2b:	89 e5                	mov    %esp,%ebp
f0100e2d:	83 ec 08             	sub    $0x8,%esp
f0100e30:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
if(pp->pp_ref != 0)
f0100e33:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e38:	74 17                	je     f0100e51 <page_free+0x27>
		panic("pp->pp_ref is nonzero\n");
f0100e3a:	83 ec 04             	sub    $0x4,%esp
f0100e3d:	68 4a 3d 10 f0       	push   $0xf0103d4a
f0100e42:	68 47 01 00 00       	push   $0x147
f0100e47:	68 94 3c 10 f0       	push   $0xf0103c94
f0100e4c:	e8 3a f2 ff ff       	call   f010008b <_panic>
	if(pp->pp_link)
f0100e51:	83 38 00             	cmpl   $0x0,(%eax)
f0100e54:	74 17                	je     f0100e6d <page_free+0x43>
		panic("pp->pp_link is not NULL\n");
f0100e56:	83 ec 04             	sub    $0x4,%esp
f0100e59:	68 61 3d 10 f0       	push   $0xf0103d61
f0100e5e:	68 49 01 00 00       	push   $0x149
f0100e63:	68 94 3c 10 f0       	push   $0xf0103c94
f0100e68:	e8 1e f2 ff ff       	call   f010008b <_panic>

	pp->pp_link = page_free_list;
f0100e6d:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e73:	89 10                	mov    %edx,(%eax)
page_free_list = pp;
f0100e75:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e7a:	c9                   	leave  
f0100e7b:	c3                   	ret    

f0100e7c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e7c:	55                   	push   %ebp
f0100e7d:	89 e5                	mov    %esp,%ebp
f0100e7f:	83 ec 08             	sub    $0x8,%esp
f0100e82:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e85:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e89:	83 e8 01             	sub    $0x1,%eax
f0100e8c:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e90:	66 85 c0             	test   %ax,%ax
f0100e93:	75 0c                	jne    f0100ea1 <page_decref+0x25>
		page_free(pp);
f0100e95:	83 ec 0c             	sub    $0xc,%esp
f0100e98:	52                   	push   %edx
f0100e99:	e8 8c ff ff ff       	call   f0100e2a <page_free>
f0100e9e:	83 c4 10             	add    $0x10,%esp
}
f0100ea1:	c9                   	leave  
f0100ea2:	c3                   	ret    

f0100ea3 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ea3:	55                   	push   %ebp
f0100ea4:	89 e5                	mov    %esp,%ebp
f0100ea6:	56                   	push   %esi
f0100ea7:	53                   	push   %ebx
f0100ea8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pde_t pde = pgdir[PDX(va)];
f0100eab:	89 de                	mov    %ebx,%esi
f0100ead:	c1 ee 16             	shr    $0x16,%esi
f0100eb0:	c1 e6 02             	shl    $0x2,%esi
f0100eb3:	03 75 08             	add    0x8(%ebp),%esi
f0100eb6:	8b 06                	mov    (%esi),%eax
	pte_t * result;
	if(pde & PTE_P)
f0100eb8:	a8 01                	test   $0x1,%al
f0100eba:	74 39                	je     f0100ef5 <pgdir_walk+0x52>
	{
		pte_t * pg_table_p = KADDR(PTE_ADDR(pde));
f0100ebc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ec1:	89 c2                	mov    %eax,%edx
f0100ec3:	c1 ea 0c             	shr    $0xc,%edx
f0100ec6:	39 15 64 79 11 f0    	cmp    %edx,0xf0117964
f0100ecc:	77 15                	ja     f0100ee3 <pgdir_walk+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ece:	50                   	push   %eax
f0100ecf:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0100ed4:	68 78 01 00 00       	push   $0x178
f0100ed9:	68 94 3c 10 f0       	push   $0xf0103c94
f0100ede:	e8 a8 f1 ff ff       	call   f010008b <_panic>
		result = pg_table_p + PTX(va);
f0100ee3:	c1 eb 0a             	shr    $0xa,%ebx
f0100ee6:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
		return result;
f0100eec:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100ef3:	eb 7b                	jmp    f0100f70 <pgdir_walk+0xcd>
	}
	else if(!create)
f0100ef5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ef9:	74 69                	je     f0100f64 <pgdir_walk+0xc1>
		return NULL;
	else
	{
		struct PageInfo *pp = page_alloc(1);
f0100efb:	83 ec 0c             	sub    $0xc,%esp
f0100efe:	6a 01                	push   $0x1
f0100f00:	e8 b5 fe ff ff       	call   f0100dba <page_alloc>
		if(!pp)
f0100f05:	83 c4 10             	add    $0x10,%esp
f0100f08:	85 c0                	test   %eax,%eax
f0100f0a:	74 5f                	je     f0100f6b <pgdir_walk+0xc8>
			return NULL;
		else
		{
			pp->pp_ref++;
f0100f0c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W;
f0100f11:	89 c2                	mov    %eax,%edx
f0100f13:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100f19:	c1 fa 03             	sar    $0x3,%edx
f0100f1c:	c1 e2 0c             	shl    $0xc,%edx
f0100f1f:	83 ca 03             	or     $0x3,%edx
f0100f22:	89 16                	mov    %edx,(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f24:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100f2a:	c1 f8 03             	sar    $0x3,%eax
f0100f2d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f30:	89 c2                	mov    %eax,%edx
f0100f32:	c1 ea 0c             	shr    $0xc,%edx
f0100f35:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f3b:	72 15                	jb     f0100f52 <pgdir_walk+0xaf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f3d:	50                   	push   %eax
f0100f3e:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0100f43:	68 87 01 00 00       	push   $0x187
f0100f48:	68 94 3c 10 f0       	push   $0xf0103c94
f0100f4d:	e8 39 f1 ff ff       	call   f010008b <_panic>
			pte_t * pg_table_p = KADDR(page2pa(pp));
			result = pg_table_p + PTX(va);
f0100f52:	c1 eb 0a             	shr    $0xa,%ebx
f0100f55:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
			return result;
f0100f5b:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100f62:	eb 0c                	jmp    f0100f70 <pgdir_walk+0xcd>
		pte_t * pg_table_p = KADDR(PTE_ADDR(pde));
		result = pg_table_p + PTX(va);
		return result;
	}
	else if(!create)
		return NULL;
f0100f64:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f69:	eb 05                	jmp    f0100f70 <pgdir_walk+0xcd>
	else
	{
		struct PageInfo *pp = page_alloc(1);
		if(!pp)
			return NULL;
f0100f6b:	b8 00 00 00 00       	mov    $0x0,%eax
			pte_t * pg_table_p = KADDR(page2pa(pp));
			result = pg_table_p + PTX(va);
			return result;
		}
	}
}
f0100f70:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f73:	5b                   	pop    %ebx
f0100f74:	5e                   	pop    %esi
f0100f75:	5d                   	pop    %ebp
f0100f76:	c3                   	ret    

f0100f77 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f77:	55                   	push   %ebp
f0100f78:	89 e5                	mov    %esp,%ebp
f0100f7a:	57                   	push   %edi
f0100f7b:	56                   	push   %esi
f0100f7c:	53                   	push   %ebx
f0100f7d:	83 ec 1c             	sub    $0x1c,%esp
f0100f80:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f83:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f86:	c1 e9 0c             	shr    $0xc,%ecx
f0100f89:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100f8c:	89 c3                	mov    %eax,%ebx
f0100f8e:	be 00 00 00 00       	mov    $0x0,%esi
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
f0100f93:	89 d7                	mov    %edx,%edi
f0100f95:	29 c7                	sub    %eax,%edi
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
f0100f97:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f9a:	83 c8 01             	or     $0x1,%eax
f0100f9d:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100fa0:	eb 3f                	jmp    f0100fe1 <boot_map_region+0x6a>
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
f0100fa2:	83 ec 04             	sub    $0x4,%esp
f0100fa5:	6a 01                	push   $0x1
f0100fa7:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100faa:	50                   	push   %eax
f0100fab:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fae:	e8 f0 fe ff ff       	call   f0100ea3 <pgdir_walk>
        if (!pte) panic("boot_map_region panic, out of memory");
f0100fb3:	83 c4 10             	add    $0x10,%esp
f0100fb6:	85 c0                	test   %eax,%eax
f0100fb8:	75 17                	jne    f0100fd1 <boot_map_region+0x5a>
f0100fba:	83 ec 04             	sub    $0x4,%esp
f0100fbd:	68 34 41 10 f0       	push   $0xf0104134
f0100fc2:	68 a0 01 00 00       	push   $0x1a0
f0100fc7:	68 94 3c 10 f0       	push   $0xf0103c94
f0100fcc:	e8 ba f0 ff ff       	call   f010008b <_panic>
        *pte = pa | perm | PTE_P;
f0100fd1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fd4:	09 da                	or     %ebx,%edx
f0100fd6:	89 10                	mov    %edx,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
int i;
    for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100fd8:	83 c6 01             	add    $0x1,%esi
f0100fdb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100fe1:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100fe4:	75 bc                	jne    f0100fa2 <boot_map_region+0x2b>
        pte_t *pte = pgdir_walk(pgdir, (void *) va, 1); //create
        if (!pte) panic("boot_map_region panic, out of memory");
        *pte = pa | perm | PTE_P;
    }
}
f0100fe6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fe9:	5b                   	pop    %ebx
f0100fea:	5e                   	pop    %esi
f0100feb:	5f                   	pop    %edi
f0100fec:	5d                   	pop    %ebp
f0100fed:	c3                   	ret    

f0100fee <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fee:	55                   	push   %ebp
f0100fef:	89 e5                	mov    %esp,%ebp
f0100ff1:	53                   	push   %ebx
f0100ff2:	83 ec 08             	sub    $0x8,%esp
f0100ff5:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 0);
f0100ff8:	6a 00                	push   $0x0
f0100ffa:	ff 75 0c             	pushl  0xc(%ebp)
f0100ffd:	ff 75 08             	pushl  0x8(%ebp)
f0101000:	e8 9e fe ff ff       	call   f0100ea3 <pgdir_walk>
	if(ptep && ((*ptep) & PTE_P)) {
f0101005:	83 c4 10             	add    $0x10,%esp
f0101008:	85 c0                	test   %eax,%eax
f010100a:	74 38                	je     f0101044 <page_lookup+0x56>
f010100c:	89 c1                	mov    %eax,%ecx
f010100e:	8b 10                	mov    (%eax),%edx
f0101010:	f6 c2 01             	test   $0x1,%dl
f0101013:	74 36                	je     f010104b <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101015:	c1 ea 0c             	shr    $0xc,%edx
f0101018:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010101e:	72 14                	jb     f0101034 <page_lookup+0x46>
		panic("pa2page called with invalid pa");
f0101020:	83 ec 04             	sub    $0x4,%esp
f0101023:	68 5c 41 10 f0       	push   $0xf010415c
f0101028:	6a 4b                	push   $0x4b
f010102a:	68 a0 3c 10 f0       	push   $0xf0103ca0
f010102f:	e8 57 f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0101034:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101039:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		physaddr_t pa = PTE_ADDR(*ptep);
		struct PageInfo * result = pa2page(pa);
		if(pte_store)
f010103c:	85 db                	test   %ebx,%ebx
f010103e:	74 10                	je     f0101050 <page_lookup+0x62>
			*pte_store = ptep;
f0101040:	89 0b                	mov    %ecx,(%ebx)
f0101042:	eb 0c                	jmp    f0101050 <page_lookup+0x62>
		return result;
	}
	return NULL;
f0101044:	b8 00 00 00 00       	mov    $0x0,%eax
f0101049:	eb 05                	jmp    f0101050 <page_lookup+0x62>
f010104b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101050:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101053:	c9                   	leave  
f0101054:	c3                   	ret    

f0101055 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101055:	55                   	push   %ebp
f0101056:	89 e5                	mov    %esp,%ebp
f0101058:	53                   	push   %ebx
f0101059:	83 ec 18             	sub    $0x18,%esp
f010105c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t * ptep;
	struct PageInfo *pp = page_lookup(pgdir, va, &ptep);
f010105f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101062:	50                   	push   %eax
f0101063:	53                   	push   %ebx
f0101064:	ff 75 08             	pushl  0x8(%ebp)
f0101067:	e8 82 ff ff ff       	call   f0100fee <page_lookup>
	if(!pp || !(*ptep & PTE_P))
f010106c:	83 c4 10             	add    $0x10,%esp
f010106f:	85 c0                	test   %eax,%eax
f0101071:	74 20                	je     f0101093 <page_remove+0x3e>
f0101073:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101076:	f6 02 01             	testb  $0x1,(%edx)
f0101079:	74 18                	je     f0101093 <page_remove+0x3e>
		return;
	page_decref(pp);		// the ref count of the physical page should decrement
f010107b:	83 ec 0c             	sub    $0xc,%esp
f010107e:	50                   	push   %eax
f010107f:	e8 f8 fd ff ff       	call   f0100e7c <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101084:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);	// the TLB must be invalidated if you remove an entry from the page table
	*ptep = 0;
f0101087:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010108a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101090:	83 c4 10             	add    $0x10,%esp
}
f0101093:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101096:	c9                   	leave  
f0101097:	c3                   	ret    

f0101098 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101098:	55                   	push   %ebp
f0101099:	89 e5                	mov    %esp,%ebp
f010109b:	57                   	push   %edi
f010109c:	56                   	push   %esi
f010109d:	53                   	push   %ebx
f010109e:	83 ec 10             	sub    $0x10,%esp
f01010a1:	8b 75 08             	mov    0x8(%ebp),%esi
f01010a4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 1);
f01010a7:	6a 01                	push   $0x1
f01010a9:	ff 75 10             	pushl  0x10(%ebp)
f01010ac:	56                   	push   %esi
f01010ad:	e8 f1 fd ff ff       	call   f0100ea3 <pgdir_walk>
	if(ptep == NULL)
f01010b2:	83 c4 10             	add    $0x10,%esp
f01010b5:	85 c0                	test   %eax,%eax
f01010b7:	74 44                	je     f01010fd <page_insert+0x65>
f01010b9:	89 c7                	mov    %eax,%edi
		return -E_NO_MEM;

	pp->pp_ref++;
f01010bb:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*ptep) & PTE_P)
f01010c0:	f6 00 01             	testb  $0x1,(%eax)
f01010c3:	74 0f                	je     f01010d4 <page_insert+0x3c>
		page_remove(pgdir, va);
f01010c5:	83 ec 08             	sub    $0x8,%esp
f01010c8:	ff 75 10             	pushl  0x10(%ebp)
f01010cb:	56                   	push   %esi
f01010cc:	e8 84 ff ff ff       	call   f0101055 <page_remove>
f01010d1:	83 c4 10             	add    $0x10,%esp

	*ptep  = page2pa(pp) | PTE_P | perm;
f01010d4:	2b 1d 6c 79 11 f0    	sub    0xf011796c,%ebx
f01010da:	c1 fb 03             	sar    $0x3,%ebx
f01010dd:	c1 e3 0c             	shl    $0xc,%ebx
f01010e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e3:	83 c8 01             	or     $0x1,%eax
f01010e6:	09 c3                	or     %eax,%ebx
f01010e8:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;    //when permission of PTE changes, PDE should also change
f01010ea:	8b 45 10             	mov    0x10(%ebp),%eax
f01010ed:	c1 e8 16             	shr    $0x16,%eax
f01010f0:	8b 55 14             	mov    0x14(%ebp),%edx
f01010f3:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f01010f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01010fb:	eb 05                	jmp    f0101102 <page_insert+0x6a>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t * ptep = pgdir_walk(pgdir, va, 1);
	if(ptep == NULL)
		return -E_NO_MEM;
f01010fd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);

	*ptep  = page2pa(pp) | PTE_P | perm;
	pgdir[PDX(va)] |= perm;    //when permission of PTE changes, PDE should also change
	return 0;
}
f0101102:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101105:	5b                   	pop    %ebx
f0101106:	5e                   	pop    %esi
f0101107:	5f                   	pop    %edi
f0101108:	5d                   	pop    %ebp
f0101109:	c3                   	ret    

f010110a <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010110a:	55                   	push   %ebp
f010110b:	89 e5                	mov    %esp,%ebp
f010110d:	57                   	push   %edi
f010110e:	56                   	push   %esi
f010110f:	53                   	push   %ebx
f0101110:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101113:	6a 15                	push   $0x15
f0101115:	e8 9b 16 00 00       	call   f01027b5 <mc146818_read>
f010111a:	89 c3                	mov    %eax,%ebx
f010111c:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101123:	e8 8d 16 00 00       	call   f01027b5 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101128:	c1 e0 08             	shl    $0x8,%eax
f010112b:	09 d8                	or     %ebx,%eax
f010112d:	c1 e0 0a             	shl    $0xa,%eax
f0101130:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101136:	85 c0                	test   %eax,%eax
f0101138:	0f 48 c2             	cmovs  %edx,%eax
f010113b:	c1 f8 0c             	sar    $0xc,%eax
f010113e:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101143:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010114a:	e8 66 16 00 00       	call   f01027b5 <mc146818_read>
f010114f:	89 c3                	mov    %eax,%ebx
f0101151:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101158:	e8 58 16 00 00       	call   f01027b5 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010115d:	c1 e0 08             	shl    $0x8,%eax
f0101160:	09 d8                	or     %ebx,%eax
f0101162:	c1 e0 0a             	shl    $0xa,%eax
f0101165:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f010116b:	83 c4 10             	add    $0x10,%esp
f010116e:	85 c0                	test   %eax,%eax
f0101170:	0f 49 d8             	cmovns %eax,%ebx
f0101173:	c1 fb 0c             	sar    $0xc,%ebx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101176:	85 db                	test   %ebx,%ebx
f0101178:	74 0d                	je     f0101187 <mem_init+0x7d>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010117a:	8d 83 00 01 00 00    	lea    0x100(%ebx),%eax
f0101180:	a3 64 79 11 f0       	mov    %eax,0xf0117964
f0101185:	eb 0a                	jmp    f0101191 <mem_init+0x87>
	else
		npages = npages_basemem;
f0101187:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f010118c:	a3 64 79 11 f0       	mov    %eax,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101191:	89 d8                	mov    %ebx,%eax
f0101193:	c1 e0 0c             	shl    $0xc,%eax
f0101196:	c1 e8 0a             	shr    $0xa,%eax
f0101199:	50                   	push   %eax
f010119a:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f010119f:	c1 e0 0c             	shl    $0xc,%eax
f01011a2:	c1 e8 0a             	shr    $0xa,%eax
f01011a5:	50                   	push   %eax
f01011a6:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01011ab:	c1 e0 0c             	shl    $0xc,%eax
f01011ae:	c1 e8 0a             	shr    $0xa,%eax
f01011b1:	50                   	push   %eax
f01011b2:	68 7c 41 10 f0       	push   $0xf010417c
f01011b7:	e8 60 16 00 00       	call   f010281c <cprintf>
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
cprintf("npages is %u, npages_basemem is %u, npages_extmem is %u\n", npages, npages_basemem, npages_extmem);
f01011bc:	53                   	push   %ebx
f01011bd:	ff 35 40 75 11 f0    	pushl  0xf0117540
f01011c3:	ff 35 64 79 11 f0    	pushl  0xf0117964
f01011c9:	68 b8 41 10 f0       	push   $0xf01041b8
f01011ce:	e8 49 16 00 00       	call   f010281c <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01011d3:	83 c4 20             	add    $0x20,%esp
f01011d6:	b8 00 10 00 00       	mov    $0x1000,%eax
f01011db:	e8 2c f7 ff ff       	call   f010090c <boot_alloc>
f01011e0:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f01011e5:	83 ec 04             	sub    $0x4,%esp
f01011e8:	68 00 10 00 00       	push   $0x1000
f01011ed:	6a 00                	push   $0x0
f01011ef:	50                   	push   %eax
f01011f0:	e8 d0 20 00 00       	call   f01032c5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01011f5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01011fa:	83 c4 10             	add    $0x10,%esp
f01011fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101202:	77 15                	ja     f0101219 <mem_init+0x10f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101204:	50                   	push   %eax
f0101205:	68 f4 41 10 f0       	push   $0xf01041f4
f010120a:	68 96 00 00 00       	push   $0x96
f010120f:	68 94 3c 10 f0       	push   $0xf0103c94
f0101214:	e8 72 ee ff ff       	call   f010008b <_panic>
f0101219:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010121f:	83 ca 05             	or     $0x5,%edx
f0101222:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101228:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010122d:	c1 e0 03             	shl    $0x3,%eax
f0101230:	e8 d7 f6 ff ff       	call   f010090c <boot_alloc>
f0101235:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010123a:	83 ec 04             	sub    $0x4,%esp
f010123d:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101243:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010124a:	52                   	push   %edx
f010124b:	6a 00                	push   $0x0
f010124d:	50                   	push   %eax
f010124e:	e8 72 20 00 00       	call   f01032c5 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101253:	e8 78 fa ff ff       	call   f0100cd0 <page_init>

	check_page_free_list(1);
f0101258:	b8 01 00 00 00       	mov    $0x1,%eax
f010125d:	e8 7d f7 ff ff       	call   f01009df <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101262:	83 c4 10             	add    $0x10,%esp
f0101265:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f010126c:	75 17                	jne    f0101285 <mem_init+0x17b>
		panic("'pages' is a null pointer!");
f010126e:	83 ec 04             	sub    $0x4,%esp
f0101271:	68 7a 3d 10 f0       	push   $0xf0103d7a
f0101276:	68 64 02 00 00       	push   $0x264
f010127b:	68 94 3c 10 f0       	push   $0xf0103c94
f0101280:	e8 06 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101285:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010128a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010128f:	eb 05                	jmp    f0101296 <mem_init+0x18c>
		++nfree;
f0101291:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101294:	8b 00                	mov    (%eax),%eax
f0101296:	85 c0                	test   %eax,%eax
f0101298:	75 f7                	jne    f0101291 <mem_init+0x187>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010129a:	83 ec 0c             	sub    $0xc,%esp
f010129d:	6a 00                	push   $0x0
f010129f:	e8 16 fb ff ff       	call   f0100dba <page_alloc>
f01012a4:	89 c7                	mov    %eax,%edi
f01012a6:	83 c4 10             	add    $0x10,%esp
f01012a9:	85 c0                	test   %eax,%eax
f01012ab:	75 19                	jne    f01012c6 <mem_init+0x1bc>
f01012ad:	68 95 3d 10 f0       	push   $0xf0103d95
f01012b2:	68 ba 3c 10 f0       	push   $0xf0103cba
f01012b7:	68 6c 02 00 00       	push   $0x26c
f01012bc:	68 94 3c 10 f0       	push   $0xf0103c94
f01012c1:	e8 c5 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01012c6:	83 ec 0c             	sub    $0xc,%esp
f01012c9:	6a 00                	push   $0x0
f01012cb:	e8 ea fa ff ff       	call   f0100dba <page_alloc>
f01012d0:	89 c6                	mov    %eax,%esi
f01012d2:	83 c4 10             	add    $0x10,%esp
f01012d5:	85 c0                	test   %eax,%eax
f01012d7:	75 19                	jne    f01012f2 <mem_init+0x1e8>
f01012d9:	68 ab 3d 10 f0       	push   $0xf0103dab
f01012de:	68 ba 3c 10 f0       	push   $0xf0103cba
f01012e3:	68 6d 02 00 00       	push   $0x26d
f01012e8:	68 94 3c 10 f0       	push   $0xf0103c94
f01012ed:	e8 99 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01012f2:	83 ec 0c             	sub    $0xc,%esp
f01012f5:	6a 00                	push   $0x0
f01012f7:	e8 be fa ff ff       	call   f0100dba <page_alloc>
f01012fc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012ff:	83 c4 10             	add    $0x10,%esp
f0101302:	85 c0                	test   %eax,%eax
f0101304:	75 19                	jne    f010131f <mem_init+0x215>
f0101306:	68 c1 3d 10 f0       	push   $0xf0103dc1
f010130b:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101310:	68 6e 02 00 00       	push   $0x26e
f0101315:	68 94 3c 10 f0       	push   $0xf0103c94
f010131a:	e8 6c ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010131f:	39 f7                	cmp    %esi,%edi
f0101321:	75 19                	jne    f010133c <mem_init+0x232>
f0101323:	68 d7 3d 10 f0       	push   $0xf0103dd7
f0101328:	68 ba 3c 10 f0       	push   $0xf0103cba
f010132d:	68 71 02 00 00       	push   $0x271
f0101332:	68 94 3c 10 f0       	push   $0xf0103c94
f0101337:	e8 4f ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010133c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010133f:	39 c6                	cmp    %eax,%esi
f0101341:	74 04                	je     f0101347 <mem_init+0x23d>
f0101343:	39 c7                	cmp    %eax,%edi
f0101345:	75 19                	jne    f0101360 <mem_init+0x256>
f0101347:	68 18 42 10 f0       	push   $0xf0104218
f010134c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101351:	68 72 02 00 00       	push   $0x272
f0101356:	68 94 3c 10 f0       	push   $0xf0103c94
f010135b:	e8 2b ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101360:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101366:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f010136c:	c1 e2 0c             	shl    $0xc,%edx
f010136f:	89 f8                	mov    %edi,%eax
f0101371:	29 c8                	sub    %ecx,%eax
f0101373:	c1 f8 03             	sar    $0x3,%eax
f0101376:	c1 e0 0c             	shl    $0xc,%eax
f0101379:	39 d0                	cmp    %edx,%eax
f010137b:	72 19                	jb     f0101396 <mem_init+0x28c>
f010137d:	68 e9 3d 10 f0       	push   $0xf0103de9
f0101382:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101387:	68 73 02 00 00       	push   $0x273
f010138c:	68 94 3c 10 f0       	push   $0xf0103c94
f0101391:	e8 f5 ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101396:	89 f0                	mov    %esi,%eax
f0101398:	29 c8                	sub    %ecx,%eax
f010139a:	c1 f8 03             	sar    $0x3,%eax
f010139d:	c1 e0 0c             	shl    $0xc,%eax
f01013a0:	39 c2                	cmp    %eax,%edx
f01013a2:	77 19                	ja     f01013bd <mem_init+0x2b3>
f01013a4:	68 06 3e 10 f0       	push   $0xf0103e06
f01013a9:	68 ba 3c 10 f0       	push   $0xf0103cba
f01013ae:	68 74 02 00 00       	push   $0x274
f01013b3:	68 94 3c 10 f0       	push   $0xf0103c94
f01013b8:	e8 ce ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013c0:	29 c8                	sub    %ecx,%eax
f01013c2:	c1 f8 03             	sar    $0x3,%eax
f01013c5:	c1 e0 0c             	shl    $0xc,%eax
f01013c8:	39 c2                	cmp    %eax,%edx
f01013ca:	77 19                	ja     f01013e5 <mem_init+0x2db>
f01013cc:	68 23 3e 10 f0       	push   $0xf0103e23
f01013d1:	68 ba 3c 10 f0       	push   $0xf0103cba
f01013d6:	68 75 02 00 00       	push   $0x275
f01013db:	68 94 3c 10 f0       	push   $0xf0103c94
f01013e0:	e8 a6 ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01013e5:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01013ea:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01013ed:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01013f4:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013f7:	83 ec 0c             	sub    $0xc,%esp
f01013fa:	6a 00                	push   $0x0
f01013fc:	e8 b9 f9 ff ff       	call   f0100dba <page_alloc>
f0101401:	83 c4 10             	add    $0x10,%esp
f0101404:	85 c0                	test   %eax,%eax
f0101406:	74 19                	je     f0101421 <mem_init+0x317>
f0101408:	68 40 3e 10 f0       	push   $0xf0103e40
f010140d:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101412:	68 7c 02 00 00       	push   $0x27c
f0101417:	68 94 3c 10 f0       	push   $0xf0103c94
f010141c:	e8 6a ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101421:	83 ec 0c             	sub    $0xc,%esp
f0101424:	57                   	push   %edi
f0101425:	e8 00 fa ff ff       	call   f0100e2a <page_free>
	page_free(pp1);
f010142a:	89 34 24             	mov    %esi,(%esp)
f010142d:	e8 f8 f9 ff ff       	call   f0100e2a <page_free>
	page_free(pp2);
f0101432:	83 c4 04             	add    $0x4,%esp
f0101435:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101438:	e8 ed f9 ff ff       	call   f0100e2a <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010143d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101444:	e8 71 f9 ff ff       	call   f0100dba <page_alloc>
f0101449:	89 c6                	mov    %eax,%esi
f010144b:	83 c4 10             	add    $0x10,%esp
f010144e:	85 c0                	test   %eax,%eax
f0101450:	75 19                	jne    f010146b <mem_init+0x361>
f0101452:	68 95 3d 10 f0       	push   $0xf0103d95
f0101457:	68 ba 3c 10 f0       	push   $0xf0103cba
f010145c:	68 83 02 00 00       	push   $0x283
f0101461:	68 94 3c 10 f0       	push   $0xf0103c94
f0101466:	e8 20 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010146b:	83 ec 0c             	sub    $0xc,%esp
f010146e:	6a 00                	push   $0x0
f0101470:	e8 45 f9 ff ff       	call   f0100dba <page_alloc>
f0101475:	89 c7                	mov    %eax,%edi
f0101477:	83 c4 10             	add    $0x10,%esp
f010147a:	85 c0                	test   %eax,%eax
f010147c:	75 19                	jne    f0101497 <mem_init+0x38d>
f010147e:	68 ab 3d 10 f0       	push   $0xf0103dab
f0101483:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101488:	68 84 02 00 00       	push   $0x284
f010148d:	68 94 3c 10 f0       	push   $0xf0103c94
f0101492:	e8 f4 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101497:	83 ec 0c             	sub    $0xc,%esp
f010149a:	6a 00                	push   $0x0
f010149c:	e8 19 f9 ff ff       	call   f0100dba <page_alloc>
f01014a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014a4:	83 c4 10             	add    $0x10,%esp
f01014a7:	85 c0                	test   %eax,%eax
f01014a9:	75 19                	jne    f01014c4 <mem_init+0x3ba>
f01014ab:	68 c1 3d 10 f0       	push   $0xf0103dc1
f01014b0:	68 ba 3c 10 f0       	push   $0xf0103cba
f01014b5:	68 85 02 00 00       	push   $0x285
f01014ba:	68 94 3c 10 f0       	push   $0xf0103c94
f01014bf:	e8 c7 eb ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014c4:	39 fe                	cmp    %edi,%esi
f01014c6:	75 19                	jne    f01014e1 <mem_init+0x3d7>
f01014c8:	68 d7 3d 10 f0       	push   $0xf0103dd7
f01014cd:	68 ba 3c 10 f0       	push   $0xf0103cba
f01014d2:	68 87 02 00 00       	push   $0x287
f01014d7:	68 94 3c 10 f0       	push   $0xf0103c94
f01014dc:	e8 aa eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014e4:	39 c7                	cmp    %eax,%edi
f01014e6:	74 04                	je     f01014ec <mem_init+0x3e2>
f01014e8:	39 c6                	cmp    %eax,%esi
f01014ea:	75 19                	jne    f0101505 <mem_init+0x3fb>
f01014ec:	68 18 42 10 f0       	push   $0xf0104218
f01014f1:	68 ba 3c 10 f0       	push   $0xf0103cba
f01014f6:	68 88 02 00 00       	push   $0x288
f01014fb:	68 94 3c 10 f0       	push   $0xf0103c94
f0101500:	e8 86 eb ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101505:	83 ec 0c             	sub    $0xc,%esp
f0101508:	6a 00                	push   $0x0
f010150a:	e8 ab f8 ff ff       	call   f0100dba <page_alloc>
f010150f:	83 c4 10             	add    $0x10,%esp
f0101512:	85 c0                	test   %eax,%eax
f0101514:	74 19                	je     f010152f <mem_init+0x425>
f0101516:	68 40 3e 10 f0       	push   $0xf0103e40
f010151b:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101520:	68 89 02 00 00       	push   $0x289
f0101525:	68 94 3c 10 f0       	push   $0xf0103c94
f010152a:	e8 5c eb ff ff       	call   f010008b <_panic>
f010152f:	89 f0                	mov    %esi,%eax
f0101531:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101537:	c1 f8 03             	sar    $0x3,%eax
f010153a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010153d:	89 c2                	mov    %eax,%edx
f010153f:	c1 ea 0c             	shr    $0xc,%edx
f0101542:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101548:	72 12                	jb     f010155c <mem_init+0x452>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010154a:	50                   	push   %eax
f010154b:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0101550:	6a 52                	push   $0x52
f0101552:	68 a0 3c 10 f0       	push   $0xf0103ca0
f0101557:	e8 2f eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010155c:	83 ec 04             	sub    $0x4,%esp
f010155f:	68 00 10 00 00       	push   $0x1000
f0101564:	6a 01                	push   $0x1
f0101566:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010156b:	50                   	push   %eax
f010156c:	e8 54 1d 00 00       	call   f01032c5 <memset>
	page_free(pp0);
f0101571:	89 34 24             	mov    %esi,(%esp)
f0101574:	e8 b1 f8 ff ff       	call   f0100e2a <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101579:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101580:	e8 35 f8 ff ff       	call   f0100dba <page_alloc>
f0101585:	83 c4 10             	add    $0x10,%esp
f0101588:	85 c0                	test   %eax,%eax
f010158a:	75 19                	jne    f01015a5 <mem_init+0x49b>
f010158c:	68 4f 3e 10 f0       	push   $0xf0103e4f
f0101591:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101596:	68 8e 02 00 00       	push   $0x28e
f010159b:	68 94 3c 10 f0       	push   $0xf0103c94
f01015a0:	e8 e6 ea ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01015a5:	39 c6                	cmp    %eax,%esi
f01015a7:	74 19                	je     f01015c2 <mem_init+0x4b8>
f01015a9:	68 6d 3e 10 f0       	push   $0xf0103e6d
f01015ae:	68 ba 3c 10 f0       	push   $0xf0103cba
f01015b3:	68 8f 02 00 00       	push   $0x28f
f01015b8:	68 94 3c 10 f0       	push   $0xf0103c94
f01015bd:	e8 c9 ea ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015c2:	89 f0                	mov    %esi,%eax
f01015c4:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01015ca:	c1 f8 03             	sar    $0x3,%eax
f01015cd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015d0:	89 c2                	mov    %eax,%edx
f01015d2:	c1 ea 0c             	shr    $0xc,%edx
f01015d5:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01015db:	72 12                	jb     f01015ef <mem_init+0x4e5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015dd:	50                   	push   %eax
f01015de:	68 a8 3f 10 f0       	push   $0xf0103fa8
f01015e3:	6a 52                	push   $0x52
f01015e5:	68 a0 3c 10 f0       	push   $0xf0103ca0
f01015ea:	e8 9c ea ff ff       	call   f010008b <_panic>
f01015ef:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01015f5:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01015fb:	80 38 00             	cmpb   $0x0,(%eax)
f01015fe:	74 19                	je     f0101619 <mem_init+0x50f>
f0101600:	68 7d 3e 10 f0       	push   $0xf0103e7d
f0101605:	68 ba 3c 10 f0       	push   $0xf0103cba
f010160a:	68 92 02 00 00       	push   $0x292
f010160f:	68 94 3c 10 f0       	push   $0xf0103c94
f0101614:	e8 72 ea ff ff       	call   f010008b <_panic>
f0101619:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010161c:	39 d0                	cmp    %edx,%eax
f010161e:	75 db                	jne    f01015fb <mem_init+0x4f1>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101620:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101623:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101628:	83 ec 0c             	sub    $0xc,%esp
f010162b:	56                   	push   %esi
f010162c:	e8 f9 f7 ff ff       	call   f0100e2a <page_free>
	page_free(pp1);
f0101631:	89 3c 24             	mov    %edi,(%esp)
f0101634:	e8 f1 f7 ff ff       	call   f0100e2a <page_free>
	page_free(pp2);
f0101639:	83 c4 04             	add    $0x4,%esp
f010163c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010163f:	e8 e6 f7 ff ff       	call   f0100e2a <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101644:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101649:	83 c4 10             	add    $0x10,%esp
f010164c:	eb 05                	jmp    f0101653 <mem_init+0x549>
		--nfree;
f010164e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101651:	8b 00                	mov    (%eax),%eax
f0101653:	85 c0                	test   %eax,%eax
f0101655:	75 f7                	jne    f010164e <mem_init+0x544>
		--nfree;
	assert(nfree == 0);
f0101657:	85 db                	test   %ebx,%ebx
f0101659:	74 19                	je     f0101674 <mem_init+0x56a>
f010165b:	68 87 3e 10 f0       	push   $0xf0103e87
f0101660:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101665:	68 9f 02 00 00       	push   $0x29f
f010166a:	68 94 3c 10 f0       	push   $0xf0103c94
f010166f:	e8 17 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101674:	83 ec 0c             	sub    $0xc,%esp
f0101677:	68 38 42 10 f0       	push   $0xf0104238
f010167c:	e8 9b 11 00 00       	call   f010281c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101681:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101688:	e8 2d f7 ff ff       	call   f0100dba <page_alloc>
f010168d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101690:	83 c4 10             	add    $0x10,%esp
f0101693:	85 c0                	test   %eax,%eax
f0101695:	75 19                	jne    f01016b0 <mem_init+0x5a6>
f0101697:	68 95 3d 10 f0       	push   $0xf0103d95
f010169c:	68 ba 3c 10 f0       	push   $0xf0103cba
f01016a1:	68 f8 02 00 00       	push   $0x2f8
f01016a6:	68 94 3c 10 f0       	push   $0xf0103c94
f01016ab:	e8 db e9 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01016b0:	83 ec 0c             	sub    $0xc,%esp
f01016b3:	6a 00                	push   $0x0
f01016b5:	e8 00 f7 ff ff       	call   f0100dba <page_alloc>
f01016ba:	89 c3                	mov    %eax,%ebx
f01016bc:	83 c4 10             	add    $0x10,%esp
f01016bf:	85 c0                	test   %eax,%eax
f01016c1:	75 19                	jne    f01016dc <mem_init+0x5d2>
f01016c3:	68 ab 3d 10 f0       	push   $0xf0103dab
f01016c8:	68 ba 3c 10 f0       	push   $0xf0103cba
f01016cd:	68 f9 02 00 00       	push   $0x2f9
f01016d2:	68 94 3c 10 f0       	push   $0xf0103c94
f01016d7:	e8 af e9 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01016dc:	83 ec 0c             	sub    $0xc,%esp
f01016df:	6a 00                	push   $0x0
f01016e1:	e8 d4 f6 ff ff       	call   f0100dba <page_alloc>
f01016e6:	89 c6                	mov    %eax,%esi
f01016e8:	83 c4 10             	add    $0x10,%esp
f01016eb:	85 c0                	test   %eax,%eax
f01016ed:	75 19                	jne    f0101708 <mem_init+0x5fe>
f01016ef:	68 c1 3d 10 f0       	push   $0xf0103dc1
f01016f4:	68 ba 3c 10 f0       	push   $0xf0103cba
f01016f9:	68 fa 02 00 00       	push   $0x2fa
f01016fe:	68 94 3c 10 f0       	push   $0xf0103c94
f0101703:	e8 83 e9 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101708:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010170b:	75 19                	jne    f0101726 <mem_init+0x61c>
f010170d:	68 d7 3d 10 f0       	push   $0xf0103dd7
f0101712:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101717:	68 fd 02 00 00       	push   $0x2fd
f010171c:	68 94 3c 10 f0       	push   $0xf0103c94
f0101721:	e8 65 e9 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101726:	39 c3                	cmp    %eax,%ebx
f0101728:	74 05                	je     f010172f <mem_init+0x625>
f010172a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010172d:	75 19                	jne    f0101748 <mem_init+0x63e>
f010172f:	68 18 42 10 f0       	push   $0xf0104218
f0101734:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101739:	68 fe 02 00 00       	push   $0x2fe
f010173e:	68 94 3c 10 f0       	push   $0xf0103c94
f0101743:	e8 43 e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101748:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010174d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101750:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101757:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010175a:	83 ec 0c             	sub    $0xc,%esp
f010175d:	6a 00                	push   $0x0
f010175f:	e8 56 f6 ff ff       	call   f0100dba <page_alloc>
f0101764:	83 c4 10             	add    $0x10,%esp
f0101767:	85 c0                	test   %eax,%eax
f0101769:	74 19                	je     f0101784 <mem_init+0x67a>
f010176b:	68 40 3e 10 f0       	push   $0xf0103e40
f0101770:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101775:	68 05 03 00 00       	push   $0x305
f010177a:	68 94 3c 10 f0       	push   $0xf0103c94
f010177f:	e8 07 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101784:	83 ec 04             	sub    $0x4,%esp
f0101787:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010178a:	50                   	push   %eax
f010178b:	6a 00                	push   $0x0
f010178d:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101793:	e8 56 f8 ff ff       	call   f0100fee <page_lookup>
f0101798:	83 c4 10             	add    $0x10,%esp
f010179b:	85 c0                	test   %eax,%eax
f010179d:	74 19                	je     f01017b8 <mem_init+0x6ae>
f010179f:	68 58 42 10 f0       	push   $0xf0104258
f01017a4:	68 ba 3c 10 f0       	push   $0xf0103cba
f01017a9:	68 08 03 00 00       	push   $0x308
f01017ae:	68 94 3c 10 f0       	push   $0xf0103c94
f01017b3:	e8 d3 e8 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01017b8:	6a 02                	push   $0x2
f01017ba:	6a 00                	push   $0x0
f01017bc:	53                   	push   %ebx
f01017bd:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01017c3:	e8 d0 f8 ff ff       	call   f0101098 <page_insert>
f01017c8:	83 c4 10             	add    $0x10,%esp
f01017cb:	85 c0                	test   %eax,%eax
f01017cd:	78 19                	js     f01017e8 <mem_init+0x6de>
f01017cf:	68 90 42 10 f0       	push   $0xf0104290
f01017d4:	68 ba 3c 10 f0       	push   $0xf0103cba
f01017d9:	68 0b 03 00 00       	push   $0x30b
f01017de:	68 94 3c 10 f0       	push   $0xf0103c94
f01017e3:	e8 a3 e8 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01017e8:	83 ec 0c             	sub    $0xc,%esp
f01017eb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017ee:	e8 37 f6 ff ff       	call   f0100e2a <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01017f3:	6a 02                	push   $0x2
f01017f5:	6a 00                	push   $0x0
f01017f7:	53                   	push   %ebx
f01017f8:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01017fe:	e8 95 f8 ff ff       	call   f0101098 <page_insert>
f0101803:	83 c4 20             	add    $0x20,%esp
f0101806:	85 c0                	test   %eax,%eax
f0101808:	74 19                	je     f0101823 <mem_init+0x719>
f010180a:	68 c0 42 10 f0       	push   $0xf01042c0
f010180f:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101814:	68 0f 03 00 00       	push   $0x30f
f0101819:	68 94 3c 10 f0       	push   $0xf0103c94
f010181e:	e8 68 e8 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101823:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101829:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010182e:	89 c1                	mov    %eax,%ecx
f0101830:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101833:	8b 17                	mov    (%edi),%edx
f0101835:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010183b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010183e:	29 c8                	sub    %ecx,%eax
f0101840:	c1 f8 03             	sar    $0x3,%eax
f0101843:	c1 e0 0c             	shl    $0xc,%eax
f0101846:	39 c2                	cmp    %eax,%edx
f0101848:	74 19                	je     f0101863 <mem_init+0x759>
f010184a:	68 f0 42 10 f0       	push   $0xf01042f0
f010184f:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101854:	68 10 03 00 00       	push   $0x310
f0101859:	68 94 3c 10 f0       	push   $0xf0103c94
f010185e:	e8 28 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101863:	ba 00 00 00 00       	mov    $0x0,%edx
f0101868:	89 f8                	mov    %edi,%eax
f010186a:	e8 0c f1 ff ff       	call   f010097b <check_va2pa>
f010186f:	89 da                	mov    %ebx,%edx
f0101871:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101874:	c1 fa 03             	sar    $0x3,%edx
f0101877:	c1 e2 0c             	shl    $0xc,%edx
f010187a:	39 d0                	cmp    %edx,%eax
f010187c:	74 19                	je     f0101897 <mem_init+0x78d>
f010187e:	68 18 43 10 f0       	push   $0xf0104318
f0101883:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101888:	68 11 03 00 00       	push   $0x311
f010188d:	68 94 3c 10 f0       	push   $0xf0103c94
f0101892:	e8 f4 e7 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101897:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010189c:	74 19                	je     f01018b7 <mem_init+0x7ad>
f010189e:	68 92 3e 10 f0       	push   $0xf0103e92
f01018a3:	68 ba 3c 10 f0       	push   $0xf0103cba
f01018a8:	68 12 03 00 00       	push   $0x312
f01018ad:	68 94 3c 10 f0       	push   $0xf0103c94
f01018b2:	e8 d4 e7 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01018b7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018ba:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01018bf:	74 19                	je     f01018da <mem_init+0x7d0>
f01018c1:	68 a3 3e 10 f0       	push   $0xf0103ea3
f01018c6:	68 ba 3c 10 f0       	push   $0xf0103cba
f01018cb:	68 13 03 00 00       	push   $0x313
f01018d0:	68 94 3c 10 f0       	push   $0xf0103c94
f01018d5:	e8 b1 e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018da:	6a 02                	push   $0x2
f01018dc:	68 00 10 00 00       	push   $0x1000
f01018e1:	56                   	push   %esi
f01018e2:	57                   	push   %edi
f01018e3:	e8 b0 f7 ff ff       	call   f0101098 <page_insert>
f01018e8:	83 c4 10             	add    $0x10,%esp
f01018eb:	85 c0                	test   %eax,%eax
f01018ed:	74 19                	je     f0101908 <mem_init+0x7fe>
f01018ef:	68 48 43 10 f0       	push   $0xf0104348
f01018f4:	68 ba 3c 10 f0       	push   $0xf0103cba
f01018f9:	68 16 03 00 00       	push   $0x316
f01018fe:	68 94 3c 10 f0       	push   $0xf0103c94
f0101903:	e8 83 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101908:	ba 00 10 00 00       	mov    $0x1000,%edx
f010190d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101912:	e8 64 f0 ff ff       	call   f010097b <check_va2pa>
f0101917:	89 f2                	mov    %esi,%edx
f0101919:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010191f:	c1 fa 03             	sar    $0x3,%edx
f0101922:	c1 e2 0c             	shl    $0xc,%edx
f0101925:	39 d0                	cmp    %edx,%eax
f0101927:	74 19                	je     f0101942 <mem_init+0x838>
f0101929:	68 84 43 10 f0       	push   $0xf0104384
f010192e:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101933:	68 17 03 00 00       	push   $0x317
f0101938:	68 94 3c 10 f0       	push   $0xf0103c94
f010193d:	e8 49 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101942:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101947:	74 19                	je     f0101962 <mem_init+0x858>
f0101949:	68 b4 3e 10 f0       	push   $0xf0103eb4
f010194e:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101953:	68 18 03 00 00       	push   $0x318
f0101958:	68 94 3c 10 f0       	push   $0xf0103c94
f010195d:	e8 29 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101962:	83 ec 0c             	sub    $0xc,%esp
f0101965:	6a 00                	push   $0x0
f0101967:	e8 4e f4 ff ff       	call   f0100dba <page_alloc>
f010196c:	83 c4 10             	add    $0x10,%esp
f010196f:	85 c0                	test   %eax,%eax
f0101971:	74 19                	je     f010198c <mem_init+0x882>
f0101973:	68 40 3e 10 f0       	push   $0xf0103e40
f0101978:	68 ba 3c 10 f0       	push   $0xf0103cba
f010197d:	68 1b 03 00 00       	push   $0x31b
f0101982:	68 94 3c 10 f0       	push   $0xf0103c94
f0101987:	e8 ff e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010198c:	6a 02                	push   $0x2
f010198e:	68 00 10 00 00       	push   $0x1000
f0101993:	56                   	push   %esi
f0101994:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010199a:	e8 f9 f6 ff ff       	call   f0101098 <page_insert>
f010199f:	83 c4 10             	add    $0x10,%esp
f01019a2:	85 c0                	test   %eax,%eax
f01019a4:	74 19                	je     f01019bf <mem_init+0x8b5>
f01019a6:	68 48 43 10 f0       	push   $0xf0104348
f01019ab:	68 ba 3c 10 f0       	push   $0xf0103cba
f01019b0:	68 1e 03 00 00       	push   $0x31e
f01019b5:	68 94 3c 10 f0       	push   $0xf0103c94
f01019ba:	e8 cc e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019bf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019c4:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019c9:	e8 ad ef ff ff       	call   f010097b <check_va2pa>
f01019ce:	89 f2                	mov    %esi,%edx
f01019d0:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01019d6:	c1 fa 03             	sar    $0x3,%edx
f01019d9:	c1 e2 0c             	shl    $0xc,%edx
f01019dc:	39 d0                	cmp    %edx,%eax
f01019de:	74 19                	je     f01019f9 <mem_init+0x8ef>
f01019e0:	68 84 43 10 f0       	push   $0xf0104384
f01019e5:	68 ba 3c 10 f0       	push   $0xf0103cba
f01019ea:	68 1f 03 00 00       	push   $0x31f
f01019ef:	68 94 3c 10 f0       	push   $0xf0103c94
f01019f4:	e8 92 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019f9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019fe:	74 19                	je     f0101a19 <mem_init+0x90f>
f0101a00:	68 b4 3e 10 f0       	push   $0xf0103eb4
f0101a05:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101a0a:	68 20 03 00 00       	push   $0x320
f0101a0f:	68 94 3c 10 f0       	push   $0xf0103c94
f0101a14:	e8 72 e6 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a19:	83 ec 0c             	sub    $0xc,%esp
f0101a1c:	6a 00                	push   $0x0
f0101a1e:	e8 97 f3 ff ff       	call   f0100dba <page_alloc>
f0101a23:	83 c4 10             	add    $0x10,%esp
f0101a26:	85 c0                	test   %eax,%eax
f0101a28:	74 19                	je     f0101a43 <mem_init+0x939>
f0101a2a:	68 40 3e 10 f0       	push   $0xf0103e40
f0101a2f:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101a34:	68 24 03 00 00       	push   $0x324
f0101a39:	68 94 3c 10 f0       	push   $0xf0103c94
f0101a3e:	e8 48 e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a43:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101a49:	8b 02                	mov    (%edx),%eax
f0101a4b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a50:	89 c1                	mov    %eax,%ecx
f0101a52:	c1 e9 0c             	shr    $0xc,%ecx
f0101a55:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101a5b:	72 15                	jb     f0101a72 <mem_init+0x968>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a5d:	50                   	push   %eax
f0101a5e:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0101a63:	68 27 03 00 00       	push   $0x327
f0101a68:	68 94 3c 10 f0       	push   $0xf0103c94
f0101a6d:	e8 19 e6 ff ff       	call   f010008b <_panic>
f0101a72:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a77:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a7a:	83 ec 04             	sub    $0x4,%esp
f0101a7d:	6a 00                	push   $0x0
f0101a7f:	68 00 10 00 00       	push   $0x1000
f0101a84:	52                   	push   %edx
f0101a85:	e8 19 f4 ff ff       	call   f0100ea3 <pgdir_walk>
f0101a8a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101a8d:	8d 51 04             	lea    0x4(%ecx),%edx
f0101a90:	83 c4 10             	add    $0x10,%esp
f0101a93:	39 d0                	cmp    %edx,%eax
f0101a95:	74 19                	je     f0101ab0 <mem_init+0x9a6>
f0101a97:	68 b4 43 10 f0       	push   $0xf01043b4
f0101a9c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101aa1:	68 28 03 00 00       	push   $0x328
f0101aa6:	68 94 3c 10 f0       	push   $0xf0103c94
f0101aab:	e8 db e5 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101ab0:	6a 06                	push   $0x6
f0101ab2:	68 00 10 00 00       	push   $0x1000
f0101ab7:	56                   	push   %esi
f0101ab8:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101abe:	e8 d5 f5 ff ff       	call   f0101098 <page_insert>
f0101ac3:	83 c4 10             	add    $0x10,%esp
f0101ac6:	85 c0                	test   %eax,%eax
f0101ac8:	74 19                	je     f0101ae3 <mem_init+0x9d9>
f0101aca:	68 f4 43 10 f0       	push   $0xf01043f4
f0101acf:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101ad4:	68 2b 03 00 00       	push   $0x32b
f0101ad9:	68 94 3c 10 f0       	push   $0xf0103c94
f0101ade:	e8 a8 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ae3:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101ae9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aee:	89 f8                	mov    %edi,%eax
f0101af0:	e8 86 ee ff ff       	call   f010097b <check_va2pa>
f0101af5:	89 f2                	mov    %esi,%edx
f0101af7:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101afd:	c1 fa 03             	sar    $0x3,%edx
f0101b00:	c1 e2 0c             	shl    $0xc,%edx
f0101b03:	39 d0                	cmp    %edx,%eax
f0101b05:	74 19                	je     f0101b20 <mem_init+0xa16>
f0101b07:	68 84 43 10 f0       	push   $0xf0104384
f0101b0c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101b11:	68 2c 03 00 00       	push   $0x32c
f0101b16:	68 94 3c 10 f0       	push   $0xf0103c94
f0101b1b:	e8 6b e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101b20:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b25:	74 19                	je     f0101b40 <mem_init+0xa36>
f0101b27:	68 b4 3e 10 f0       	push   $0xf0103eb4
f0101b2c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101b31:	68 2d 03 00 00       	push   $0x32d
f0101b36:	68 94 3c 10 f0       	push   $0xf0103c94
f0101b3b:	e8 4b e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b40:	83 ec 04             	sub    $0x4,%esp
f0101b43:	6a 00                	push   $0x0
f0101b45:	68 00 10 00 00       	push   $0x1000
f0101b4a:	57                   	push   %edi
f0101b4b:	e8 53 f3 ff ff       	call   f0100ea3 <pgdir_walk>
f0101b50:	83 c4 10             	add    $0x10,%esp
f0101b53:	f6 00 04             	testb  $0x4,(%eax)
f0101b56:	75 19                	jne    f0101b71 <mem_init+0xa67>
f0101b58:	68 34 44 10 f0       	push   $0xf0104434
f0101b5d:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101b62:	68 2e 03 00 00       	push   $0x32e
f0101b67:	68 94 3c 10 f0       	push   $0xf0103c94
f0101b6c:	e8 1a e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b71:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b76:	f6 00 04             	testb  $0x4,(%eax)
f0101b79:	75 19                	jne    f0101b94 <mem_init+0xa8a>
f0101b7b:	68 c5 3e 10 f0       	push   $0xf0103ec5
f0101b80:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101b85:	68 2f 03 00 00       	push   $0x32f
f0101b8a:	68 94 3c 10 f0       	push   $0xf0103c94
f0101b8f:	e8 f7 e4 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b94:	6a 02                	push   $0x2
f0101b96:	68 00 10 00 00       	push   $0x1000
f0101b9b:	56                   	push   %esi
f0101b9c:	50                   	push   %eax
f0101b9d:	e8 f6 f4 ff ff       	call   f0101098 <page_insert>
f0101ba2:	83 c4 10             	add    $0x10,%esp
f0101ba5:	85 c0                	test   %eax,%eax
f0101ba7:	74 19                	je     f0101bc2 <mem_init+0xab8>
f0101ba9:	68 48 43 10 f0       	push   $0xf0104348
f0101bae:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101bb3:	68 32 03 00 00       	push   $0x332
f0101bb8:	68 94 3c 10 f0       	push   $0xf0103c94
f0101bbd:	e8 c9 e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bc2:	83 ec 04             	sub    $0x4,%esp
f0101bc5:	6a 00                	push   $0x0
f0101bc7:	68 00 10 00 00       	push   $0x1000
f0101bcc:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101bd2:	e8 cc f2 ff ff       	call   f0100ea3 <pgdir_walk>
f0101bd7:	83 c4 10             	add    $0x10,%esp
f0101bda:	f6 00 02             	testb  $0x2,(%eax)
f0101bdd:	75 19                	jne    f0101bf8 <mem_init+0xaee>
f0101bdf:	68 68 44 10 f0       	push   $0xf0104468
f0101be4:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101be9:	68 33 03 00 00       	push   $0x333
f0101bee:	68 94 3c 10 f0       	push   $0xf0103c94
f0101bf3:	e8 93 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bf8:	83 ec 04             	sub    $0x4,%esp
f0101bfb:	6a 00                	push   $0x0
f0101bfd:	68 00 10 00 00       	push   $0x1000
f0101c02:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c08:	e8 96 f2 ff ff       	call   f0100ea3 <pgdir_walk>
f0101c0d:	83 c4 10             	add    $0x10,%esp
f0101c10:	f6 00 04             	testb  $0x4,(%eax)
f0101c13:	74 19                	je     f0101c2e <mem_init+0xb24>
f0101c15:	68 9c 44 10 f0       	push   $0xf010449c
f0101c1a:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101c1f:	68 34 03 00 00       	push   $0x334
f0101c24:	68 94 3c 10 f0       	push   $0xf0103c94
f0101c29:	e8 5d e4 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c2e:	6a 02                	push   $0x2
f0101c30:	68 00 00 40 00       	push   $0x400000
f0101c35:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101c38:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c3e:	e8 55 f4 ff ff       	call   f0101098 <page_insert>
f0101c43:	83 c4 10             	add    $0x10,%esp
f0101c46:	85 c0                	test   %eax,%eax
f0101c48:	78 19                	js     f0101c63 <mem_init+0xb59>
f0101c4a:	68 d4 44 10 f0       	push   $0xf01044d4
f0101c4f:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101c54:	68 37 03 00 00       	push   $0x337
f0101c59:	68 94 3c 10 f0       	push   $0xf0103c94
f0101c5e:	e8 28 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c63:	6a 02                	push   $0x2
f0101c65:	68 00 10 00 00       	push   $0x1000
f0101c6a:	53                   	push   %ebx
f0101c6b:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c71:	e8 22 f4 ff ff       	call   f0101098 <page_insert>
f0101c76:	83 c4 10             	add    $0x10,%esp
f0101c79:	85 c0                	test   %eax,%eax
f0101c7b:	74 19                	je     f0101c96 <mem_init+0xb8c>
f0101c7d:	68 0c 45 10 f0       	push   $0xf010450c
f0101c82:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101c87:	68 3a 03 00 00       	push   $0x33a
f0101c8c:	68 94 3c 10 f0       	push   $0xf0103c94
f0101c91:	e8 f5 e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c96:	83 ec 04             	sub    $0x4,%esp
f0101c99:	6a 00                	push   $0x0
f0101c9b:	68 00 10 00 00       	push   $0x1000
f0101ca0:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ca6:	e8 f8 f1 ff ff       	call   f0100ea3 <pgdir_walk>
f0101cab:	83 c4 10             	add    $0x10,%esp
f0101cae:	f6 00 04             	testb  $0x4,(%eax)
f0101cb1:	74 19                	je     f0101ccc <mem_init+0xbc2>
f0101cb3:	68 9c 44 10 f0       	push   $0xf010449c
f0101cb8:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101cbd:	68 3b 03 00 00       	push   $0x33b
f0101cc2:	68 94 3c 10 f0       	push   $0xf0103c94
f0101cc7:	e8 bf e3 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ccc:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101cd2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cd7:	89 f8                	mov    %edi,%eax
f0101cd9:	e8 9d ec ff ff       	call   f010097b <check_va2pa>
f0101cde:	89 c1                	mov    %eax,%ecx
f0101ce0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ce3:	89 d8                	mov    %ebx,%eax
f0101ce5:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101ceb:	c1 f8 03             	sar    $0x3,%eax
f0101cee:	c1 e0 0c             	shl    $0xc,%eax
f0101cf1:	39 c1                	cmp    %eax,%ecx
f0101cf3:	74 19                	je     f0101d0e <mem_init+0xc04>
f0101cf5:	68 48 45 10 f0       	push   $0xf0104548
f0101cfa:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101cff:	68 3e 03 00 00       	push   $0x33e
f0101d04:	68 94 3c 10 f0       	push   $0xf0103c94
f0101d09:	e8 7d e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d0e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d13:	89 f8                	mov    %edi,%eax
f0101d15:	e8 61 ec ff ff       	call   f010097b <check_va2pa>
f0101d1a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d1d:	74 19                	je     f0101d38 <mem_init+0xc2e>
f0101d1f:	68 74 45 10 f0       	push   $0xf0104574
f0101d24:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101d29:	68 3f 03 00 00       	push   $0x33f
f0101d2e:	68 94 3c 10 f0       	push   $0xf0103c94
f0101d33:	e8 53 e3 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d38:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101d3d:	74 19                	je     f0101d58 <mem_init+0xc4e>
f0101d3f:	68 db 3e 10 f0       	push   $0xf0103edb
f0101d44:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101d49:	68 41 03 00 00       	push   $0x341
f0101d4e:	68 94 3c 10 f0       	push   $0xf0103c94
f0101d53:	e8 33 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d58:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d5d:	74 19                	je     f0101d78 <mem_init+0xc6e>
f0101d5f:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101d64:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101d69:	68 42 03 00 00       	push   $0x342
f0101d6e:	68 94 3c 10 f0       	push   $0xf0103c94
f0101d73:	e8 13 e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d78:	83 ec 0c             	sub    $0xc,%esp
f0101d7b:	6a 00                	push   $0x0
f0101d7d:	e8 38 f0 ff ff       	call   f0100dba <page_alloc>
f0101d82:	83 c4 10             	add    $0x10,%esp
f0101d85:	85 c0                	test   %eax,%eax
f0101d87:	74 04                	je     f0101d8d <mem_init+0xc83>
f0101d89:	39 c6                	cmp    %eax,%esi
f0101d8b:	74 19                	je     f0101da6 <mem_init+0xc9c>
f0101d8d:	68 a4 45 10 f0       	push   $0xf01045a4
f0101d92:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101d97:	68 45 03 00 00       	push   $0x345
f0101d9c:	68 94 3c 10 f0       	push   $0xf0103c94
f0101da1:	e8 e5 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101da6:	83 ec 08             	sub    $0x8,%esp
f0101da9:	6a 00                	push   $0x0
f0101dab:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101db1:	e8 9f f2 ff ff       	call   f0101055 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101db6:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101dbc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc1:	89 f8                	mov    %edi,%eax
f0101dc3:	e8 b3 eb ff ff       	call   f010097b <check_va2pa>
f0101dc8:	83 c4 10             	add    $0x10,%esp
f0101dcb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dce:	74 19                	je     f0101de9 <mem_init+0xcdf>
f0101dd0:	68 c8 45 10 f0       	push   $0xf01045c8
f0101dd5:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101dda:	68 49 03 00 00       	push   $0x349
f0101ddf:	68 94 3c 10 f0       	push   $0xf0103c94
f0101de4:	e8 a2 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101de9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dee:	89 f8                	mov    %edi,%eax
f0101df0:	e8 86 eb ff ff       	call   f010097b <check_va2pa>
f0101df5:	89 da                	mov    %ebx,%edx
f0101df7:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101dfd:	c1 fa 03             	sar    $0x3,%edx
f0101e00:	c1 e2 0c             	shl    $0xc,%edx
f0101e03:	39 d0                	cmp    %edx,%eax
f0101e05:	74 19                	je     f0101e20 <mem_init+0xd16>
f0101e07:	68 74 45 10 f0       	push   $0xf0104574
f0101e0c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101e11:	68 4a 03 00 00       	push   $0x34a
f0101e16:	68 94 3c 10 f0       	push   $0xf0103c94
f0101e1b:	e8 6b e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101e20:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e25:	74 19                	je     f0101e40 <mem_init+0xd36>
f0101e27:	68 92 3e 10 f0       	push   $0xf0103e92
f0101e2c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101e31:	68 4b 03 00 00       	push   $0x34b
f0101e36:	68 94 3c 10 f0       	push   $0xf0103c94
f0101e3b:	e8 4b e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e40:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e45:	74 19                	je     f0101e60 <mem_init+0xd56>
f0101e47:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101e4c:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101e51:	68 4c 03 00 00       	push   $0x34c
f0101e56:	68 94 3c 10 f0       	push   $0xf0103c94
f0101e5b:	e8 2b e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e60:	6a 00                	push   $0x0
f0101e62:	68 00 10 00 00       	push   $0x1000
f0101e67:	53                   	push   %ebx
f0101e68:	57                   	push   %edi
f0101e69:	e8 2a f2 ff ff       	call   f0101098 <page_insert>
f0101e6e:	83 c4 10             	add    $0x10,%esp
f0101e71:	85 c0                	test   %eax,%eax
f0101e73:	74 19                	je     f0101e8e <mem_init+0xd84>
f0101e75:	68 ec 45 10 f0       	push   $0xf01045ec
f0101e7a:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101e7f:	68 4f 03 00 00       	push   $0x34f
f0101e84:	68 94 3c 10 f0       	push   $0xf0103c94
f0101e89:	e8 fd e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101e8e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e93:	75 19                	jne    f0101eae <mem_init+0xda4>
f0101e95:	68 fd 3e 10 f0       	push   $0xf0103efd
f0101e9a:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101e9f:	68 50 03 00 00       	push   $0x350
f0101ea4:	68 94 3c 10 f0       	push   $0xf0103c94
f0101ea9:	e8 dd e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101eae:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101eb1:	74 19                	je     f0101ecc <mem_init+0xdc2>
f0101eb3:	68 09 3f 10 f0       	push   $0xf0103f09
f0101eb8:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101ebd:	68 51 03 00 00       	push   $0x351
f0101ec2:	68 94 3c 10 f0       	push   $0xf0103c94
f0101ec7:	e8 bf e1 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ecc:	83 ec 08             	sub    $0x8,%esp
f0101ecf:	68 00 10 00 00       	push   $0x1000
f0101ed4:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101eda:	e8 76 f1 ff ff       	call   f0101055 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101edf:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101ee5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101eea:	89 f8                	mov    %edi,%eax
f0101eec:	e8 8a ea ff ff       	call   f010097b <check_va2pa>
f0101ef1:	83 c4 10             	add    $0x10,%esp
f0101ef4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ef7:	74 19                	je     f0101f12 <mem_init+0xe08>
f0101ef9:	68 c8 45 10 f0       	push   $0xf01045c8
f0101efe:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101f03:	68 55 03 00 00       	push   $0x355
f0101f08:	68 94 3c 10 f0       	push   $0xf0103c94
f0101f0d:	e8 79 e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f12:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f17:	89 f8                	mov    %edi,%eax
f0101f19:	e8 5d ea ff ff       	call   f010097b <check_va2pa>
f0101f1e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f21:	74 19                	je     f0101f3c <mem_init+0xe32>
f0101f23:	68 24 46 10 f0       	push   $0xf0104624
f0101f28:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101f2d:	68 56 03 00 00       	push   $0x356
f0101f32:	68 94 3c 10 f0       	push   $0xf0103c94
f0101f37:	e8 4f e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101f3c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f41:	74 19                	je     f0101f5c <mem_init+0xe52>
f0101f43:	68 1e 3f 10 f0       	push   $0xf0103f1e
f0101f48:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101f4d:	68 57 03 00 00       	push   $0x357
f0101f52:	68 94 3c 10 f0       	push   $0xf0103c94
f0101f57:	e8 2f e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101f5c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f61:	74 19                	je     f0101f7c <mem_init+0xe72>
f0101f63:	68 ec 3e 10 f0       	push   $0xf0103eec
f0101f68:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101f6d:	68 58 03 00 00       	push   $0x358
f0101f72:	68 94 3c 10 f0       	push   $0xf0103c94
f0101f77:	e8 0f e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f7c:	83 ec 0c             	sub    $0xc,%esp
f0101f7f:	6a 00                	push   $0x0
f0101f81:	e8 34 ee ff ff       	call   f0100dba <page_alloc>
f0101f86:	83 c4 10             	add    $0x10,%esp
f0101f89:	39 c3                	cmp    %eax,%ebx
f0101f8b:	75 04                	jne    f0101f91 <mem_init+0xe87>
f0101f8d:	85 c0                	test   %eax,%eax
f0101f8f:	75 19                	jne    f0101faa <mem_init+0xea0>
f0101f91:	68 4c 46 10 f0       	push   $0xf010464c
f0101f96:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101f9b:	68 5b 03 00 00       	push   $0x35b
f0101fa0:	68 94 3c 10 f0       	push   $0xf0103c94
f0101fa5:	e8 e1 e0 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101faa:	83 ec 0c             	sub    $0xc,%esp
f0101fad:	6a 00                	push   $0x0
f0101faf:	e8 06 ee ff ff       	call   f0100dba <page_alloc>
f0101fb4:	83 c4 10             	add    $0x10,%esp
f0101fb7:	85 c0                	test   %eax,%eax
f0101fb9:	74 19                	je     f0101fd4 <mem_init+0xeca>
f0101fbb:	68 40 3e 10 f0       	push   $0xf0103e40
f0101fc0:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101fc5:	68 5e 03 00 00       	push   $0x35e
f0101fca:	68 94 3c 10 f0       	push   $0xf0103c94
f0101fcf:	e8 b7 e0 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fd4:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101fda:	8b 11                	mov    (%ecx),%edx
f0101fdc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fe2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe5:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101feb:	c1 f8 03             	sar    $0x3,%eax
f0101fee:	c1 e0 0c             	shl    $0xc,%eax
f0101ff1:	39 c2                	cmp    %eax,%edx
f0101ff3:	74 19                	je     f010200e <mem_init+0xf04>
f0101ff5:	68 f0 42 10 f0       	push   $0xf01042f0
f0101ffa:	68 ba 3c 10 f0       	push   $0xf0103cba
f0101fff:	68 61 03 00 00       	push   $0x361
f0102004:	68 94 3c 10 f0       	push   $0xf0103c94
f0102009:	e8 7d e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010200e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102014:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102017:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010201c:	74 19                	je     f0102037 <mem_init+0xf2d>
f010201e:	68 a3 3e 10 f0       	push   $0xf0103ea3
f0102023:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102028:	68 63 03 00 00       	push   $0x363
f010202d:	68 94 3c 10 f0       	push   $0xf0103c94
f0102032:	e8 54 e0 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102037:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010203a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102040:	83 ec 0c             	sub    $0xc,%esp
f0102043:	50                   	push   %eax
f0102044:	e8 e1 ed ff ff       	call   f0100e2a <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102049:	83 c4 0c             	add    $0xc,%esp
f010204c:	6a 01                	push   $0x1
f010204e:	68 00 10 40 00       	push   $0x401000
f0102053:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102059:	e8 45 ee ff ff       	call   f0100ea3 <pgdir_walk>
f010205e:	89 c7                	mov    %eax,%edi
f0102060:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102063:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102068:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010206b:	8b 40 04             	mov    0x4(%eax),%eax
f010206e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102073:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0102079:	89 c2                	mov    %eax,%edx
f010207b:	c1 ea 0c             	shr    $0xc,%edx
f010207e:	83 c4 10             	add    $0x10,%esp
f0102081:	39 ca                	cmp    %ecx,%edx
f0102083:	72 15                	jb     f010209a <mem_init+0xf90>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102085:	50                   	push   %eax
f0102086:	68 a8 3f 10 f0       	push   $0xf0103fa8
f010208b:	68 6a 03 00 00       	push   $0x36a
f0102090:	68 94 3c 10 f0       	push   $0xf0103c94
f0102095:	e8 f1 df ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f010209a:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010209f:	39 c7                	cmp    %eax,%edi
f01020a1:	74 19                	je     f01020bc <mem_init+0xfb2>
f01020a3:	68 2f 3f 10 f0       	push   $0xf0103f2f
f01020a8:	68 ba 3c 10 f0       	push   $0xf0103cba
f01020ad:	68 6b 03 00 00       	push   $0x36b
f01020b2:	68 94 3c 10 f0       	push   $0xf0103c94
f01020b7:	e8 cf df ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f01020bc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01020bf:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01020c6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020c9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01020cf:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01020d5:	c1 f8 03             	sar    $0x3,%eax
f01020d8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01020db:	89 c2                	mov    %eax,%edx
f01020dd:	c1 ea 0c             	shr    $0xc,%edx
f01020e0:	39 d1                	cmp    %edx,%ecx
f01020e2:	77 12                	ja     f01020f6 <mem_init+0xfec>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020e4:	50                   	push   %eax
f01020e5:	68 a8 3f 10 f0       	push   $0xf0103fa8
f01020ea:	6a 52                	push   $0x52
f01020ec:	68 a0 3c 10 f0       	push   $0xf0103ca0
f01020f1:	e8 95 df ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020f6:	83 ec 04             	sub    $0x4,%esp
f01020f9:	68 00 10 00 00       	push   $0x1000
f01020fe:	68 ff 00 00 00       	push   $0xff
f0102103:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102108:	50                   	push   %eax
f0102109:	e8 b7 11 00 00       	call   f01032c5 <memset>
	page_free(pp0);
f010210e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102111:	89 3c 24             	mov    %edi,(%esp)
f0102114:	e8 11 ed ff ff       	call   f0100e2a <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102119:	83 c4 0c             	add    $0xc,%esp
f010211c:	6a 01                	push   $0x1
f010211e:	6a 00                	push   $0x0
f0102120:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102126:	e8 78 ed ff ff       	call   f0100ea3 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010212b:	89 fa                	mov    %edi,%edx
f010212d:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102133:	c1 fa 03             	sar    $0x3,%edx
f0102136:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102139:	89 d0                	mov    %edx,%eax
f010213b:	c1 e8 0c             	shr    $0xc,%eax
f010213e:	83 c4 10             	add    $0x10,%esp
f0102141:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102147:	72 12                	jb     f010215b <mem_init+0x1051>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102149:	52                   	push   %edx
f010214a:	68 a8 3f 10 f0       	push   $0xf0103fa8
f010214f:	6a 52                	push   $0x52
f0102151:	68 a0 3c 10 f0       	push   $0xf0103ca0
f0102156:	e8 30 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f010215b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102161:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102164:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010216a:	f6 00 01             	testb  $0x1,(%eax)
f010216d:	74 19                	je     f0102188 <mem_init+0x107e>
f010216f:	68 47 3f 10 f0       	push   $0xf0103f47
f0102174:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102179:	68 75 03 00 00       	push   $0x375
f010217e:	68 94 3c 10 f0       	push   $0xf0103c94
f0102183:	e8 03 df ff ff       	call   f010008b <_panic>
f0102188:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010218b:	39 d0                	cmp    %edx,%eax
f010218d:	75 db                	jne    f010216a <mem_init+0x1060>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010218f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102194:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010219a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010219d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021a3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01021a6:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f01021ac:	83 ec 0c             	sub    $0xc,%esp
f01021af:	50                   	push   %eax
f01021b0:	e8 75 ec ff ff       	call   f0100e2a <page_free>
	page_free(pp1);
f01021b5:	89 1c 24             	mov    %ebx,(%esp)
f01021b8:	e8 6d ec ff ff       	call   f0100e2a <page_free>
	page_free(pp2);
f01021bd:	89 34 24             	mov    %esi,(%esp)
f01021c0:	e8 65 ec ff ff       	call   f0100e2a <page_free>

cprintf("check_page() succeeded!\n");
f01021c5:	c7 04 24 5e 3f 10 f0 	movl   $0xf0103f5e,(%esp)
f01021cc:	e8 4b 06 00 00       	call   f010281c <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01021d1:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021d6:	83 c4 10             	add    $0x10,%esp
f01021d9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021de:	77 15                	ja     f01021f5 <mem_init+0x10eb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021e0:	50                   	push   %eax
f01021e1:	68 f4 41 10 f0       	push   $0xf01041f4
f01021e6:	68 b8 00 00 00       	push   $0xb8
f01021eb:	68 94 3c 10 f0       	push   $0xf0103c94
f01021f0:	e8 96 de ff ff       	call   f010008b <_panic>
f01021f5:	83 ec 08             	sub    $0x8,%esp
f01021f8:	6a 04                	push   $0x4
f01021fa:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ff:	50                   	push   %eax
f0102200:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102205:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010220a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010220f:	e8 63 ed ff ff       	call   f0100f77 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102214:	83 c4 10             	add    $0x10,%esp
f0102217:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f010221c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102221:	77 15                	ja     f0102238 <mem_init+0x112e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102223:	50                   	push   %eax
f0102224:	68 f4 41 10 f0       	push   $0xf01041f4
f0102229:	68 c4 00 00 00       	push   $0xc4
f010222e:	68 94 3c 10 f0       	push   $0xf0103c94
f0102233:	e8 53 de ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102238:	83 ec 08             	sub    $0x8,%esp
f010223b:	6a 02                	push   $0x2
f010223d:	68 00 d0 10 00       	push   $0x10d000
f0102242:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102247:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010224c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102251:	e8 21 ed ff ff       	call   f0100f77 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f0102256:	83 c4 08             	add    $0x8,%esp
f0102259:	6a 02                	push   $0x2
f010225b:	6a 00                	push   $0x0
f010225d:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102262:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102267:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010226c:	e8 06 ed ff ff       	call   f0100f77 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102271:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102277:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010227c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010227f:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102286:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010228b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010228e:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102294:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102297:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010229a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010229f:	eb 55                	jmp    f01022f6 <mem_init+0x11ec>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022a1:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01022a7:	89 f0                	mov    %esi,%eax
f01022a9:	e8 cd e6 ff ff       	call   f010097b <check_va2pa>
f01022ae:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01022b5:	77 15                	ja     f01022cc <mem_init+0x11c2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022b7:	57                   	push   %edi
f01022b8:	68 f4 41 10 f0       	push   $0xf01041f4
f01022bd:	68 b7 02 00 00       	push   $0x2b7
f01022c2:	68 94 3c 10 f0       	push   $0xf0103c94
f01022c7:	e8 bf dd ff ff       	call   f010008b <_panic>
f01022cc:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01022d3:	39 c2                	cmp    %eax,%edx
f01022d5:	74 19                	je     f01022f0 <mem_init+0x11e6>
f01022d7:	68 70 46 10 f0       	push   $0xf0104670
f01022dc:	68 ba 3c 10 f0       	push   $0xf0103cba
f01022e1:	68 b7 02 00 00       	push   $0x2b7
f01022e6:	68 94 3c 10 f0       	push   $0xf0103c94
f01022eb:	e8 9b dd ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022f0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022f6:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01022f9:	77 a6                	ja     f01022a1 <mem_init+0x1197>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022fb:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01022fe:	c1 e7 0c             	shl    $0xc,%edi
f0102301:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102306:	eb 30                	jmp    f0102338 <mem_init+0x122e>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102308:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010230e:	89 f0                	mov    %esi,%eax
f0102310:	e8 66 e6 ff ff       	call   f010097b <check_va2pa>
f0102315:	39 c3                	cmp    %eax,%ebx
f0102317:	74 19                	je     f0102332 <mem_init+0x1228>
f0102319:	68 a4 46 10 f0       	push   $0xf01046a4
f010231e:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102323:	68 bc 02 00 00       	push   $0x2bc
f0102328:	68 94 3c 10 f0       	push   $0xf0103c94
f010232d:	e8 59 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102332:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102338:	39 fb                	cmp    %edi,%ebx
f010233a:	72 cc                	jb     f0102308 <mem_init+0x11fe>
f010233c:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102341:	89 da                	mov    %ebx,%edx
f0102343:	89 f0                	mov    %esi,%eax
f0102345:	e8 31 e6 ff ff       	call   f010097b <check_va2pa>
f010234a:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f0102350:	39 c2                	cmp    %eax,%edx
f0102352:	74 19                	je     f010236d <mem_init+0x1263>
f0102354:	68 cc 46 10 f0       	push   $0xf01046cc
f0102359:	68 ba 3c 10 f0       	push   $0xf0103cba
f010235e:	68 c0 02 00 00       	push   $0x2c0
f0102363:	68 94 3c 10 f0       	push   $0xf0103c94
f0102368:	e8 1e dd ff ff       	call   f010008b <_panic>
f010236d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102373:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102379:	75 c6                	jne    f0102341 <mem_init+0x1237>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010237b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102380:	89 f0                	mov    %esi,%eax
f0102382:	e8 f4 e5 ff ff       	call   f010097b <check_va2pa>
f0102387:	83 f8 ff             	cmp    $0xffffffff,%eax
f010238a:	74 51                	je     f01023dd <mem_init+0x12d3>
f010238c:	68 14 47 10 f0       	push   $0xf0104714
f0102391:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102396:	68 c1 02 00 00       	push   $0x2c1
f010239b:	68 94 3c 10 f0       	push   $0xf0103c94
f01023a0:	e8 e6 dc ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01023a5:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01023aa:	72 36                	jb     f01023e2 <mem_init+0x12d8>
f01023ac:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01023b1:	76 07                	jbe    f01023ba <mem_init+0x12b0>
f01023b3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023b8:	75 28                	jne    f01023e2 <mem_init+0x12d8>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01023ba:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01023be:	0f 85 83 00 00 00    	jne    f0102447 <mem_init+0x133d>
f01023c4:	68 77 3f 10 f0       	push   $0xf0103f77
f01023c9:	68 ba 3c 10 f0       	push   $0xf0103cba
f01023ce:	68 c9 02 00 00       	push   $0x2c9
f01023d3:	68 94 3c 10 f0       	push   $0xf0103c94
f01023d8:	e8 ae dc ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023dd:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01023e2:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023e7:	76 3f                	jbe    f0102428 <mem_init+0x131e>
				assert(pgdir[i] & PTE_P);
f01023e9:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01023ec:	f6 c2 01             	test   $0x1,%dl
f01023ef:	75 19                	jne    f010240a <mem_init+0x1300>
f01023f1:	68 77 3f 10 f0       	push   $0xf0103f77
f01023f6:	68 ba 3c 10 f0       	push   $0xf0103cba
f01023fb:	68 cd 02 00 00       	push   $0x2cd
f0102400:	68 94 3c 10 f0       	push   $0xf0103c94
f0102405:	e8 81 dc ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f010240a:	f6 c2 02             	test   $0x2,%dl
f010240d:	75 38                	jne    f0102447 <mem_init+0x133d>
f010240f:	68 88 3f 10 f0       	push   $0xf0103f88
f0102414:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102419:	68 ce 02 00 00       	push   $0x2ce
f010241e:	68 94 3c 10 f0       	push   $0xf0103c94
f0102423:	e8 63 dc ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102428:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010242c:	74 19                	je     f0102447 <mem_init+0x133d>
f010242e:	68 99 3f 10 f0       	push   $0xf0103f99
f0102433:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102438:	68 d0 02 00 00       	push   $0x2d0
f010243d:	68 94 3c 10 f0       	push   $0xf0103c94
f0102442:	e8 44 dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102447:	83 c0 01             	add    $0x1,%eax
f010244a:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010244f:	0f 86 50 ff ff ff    	jbe    f01023a5 <mem_init+0x129b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102455:	83 ec 0c             	sub    $0xc,%esp
f0102458:	68 44 47 10 f0       	push   $0xf0104744
f010245d:	e8 ba 03 00 00       	call   f010281c <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102462:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102467:	83 c4 10             	add    $0x10,%esp
f010246a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010246f:	77 15                	ja     f0102486 <mem_init+0x137c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102471:	50                   	push   %eax
f0102472:	68 f4 41 10 f0       	push   $0xf01041f4
f0102477:	68 d8 00 00 00       	push   $0xd8
f010247c:	68 94 3c 10 f0       	push   $0xf0103c94
f0102481:	e8 05 dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102486:	05 00 00 00 10       	add    $0x10000000,%eax
f010248b:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010248e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102493:	e8 47 e5 ff ff       	call   f01009df <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102498:	0f 20 c0             	mov    %cr0,%eax
f010249b:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010249e:	0d 23 00 05 80       	or     $0x80050023,%eax
f01024a3:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01024a6:	83 ec 0c             	sub    $0xc,%esp
f01024a9:	6a 00                	push   $0x0
f01024ab:	e8 0a e9 ff ff       	call   f0100dba <page_alloc>
f01024b0:	89 c3                	mov    %eax,%ebx
f01024b2:	83 c4 10             	add    $0x10,%esp
f01024b5:	85 c0                	test   %eax,%eax
f01024b7:	75 19                	jne    f01024d2 <mem_init+0x13c8>
f01024b9:	68 95 3d 10 f0       	push   $0xf0103d95
f01024be:	68 ba 3c 10 f0       	push   $0xf0103cba
f01024c3:	68 90 03 00 00       	push   $0x390
f01024c8:	68 94 3c 10 f0       	push   $0xf0103c94
f01024cd:	e8 b9 db ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01024d2:	83 ec 0c             	sub    $0xc,%esp
f01024d5:	6a 00                	push   $0x0
f01024d7:	e8 de e8 ff ff       	call   f0100dba <page_alloc>
f01024dc:	89 c7                	mov    %eax,%edi
f01024de:	83 c4 10             	add    $0x10,%esp
f01024e1:	85 c0                	test   %eax,%eax
f01024e3:	75 19                	jne    f01024fe <mem_init+0x13f4>
f01024e5:	68 ab 3d 10 f0       	push   $0xf0103dab
f01024ea:	68 ba 3c 10 f0       	push   $0xf0103cba
f01024ef:	68 91 03 00 00       	push   $0x391
f01024f4:	68 94 3c 10 f0       	push   $0xf0103c94
f01024f9:	e8 8d db ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01024fe:	83 ec 0c             	sub    $0xc,%esp
f0102501:	6a 00                	push   $0x0
f0102503:	e8 b2 e8 ff ff       	call   f0100dba <page_alloc>
f0102508:	89 c6                	mov    %eax,%esi
f010250a:	83 c4 10             	add    $0x10,%esp
f010250d:	85 c0                	test   %eax,%eax
f010250f:	75 19                	jne    f010252a <mem_init+0x1420>
f0102511:	68 c1 3d 10 f0       	push   $0xf0103dc1
f0102516:	68 ba 3c 10 f0       	push   $0xf0103cba
f010251b:	68 92 03 00 00       	push   $0x392
f0102520:	68 94 3c 10 f0       	push   $0xf0103c94
f0102525:	e8 61 db ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010252a:	83 ec 0c             	sub    $0xc,%esp
f010252d:	53                   	push   %ebx
f010252e:	e8 f7 e8 ff ff       	call   f0100e2a <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102533:	89 f8                	mov    %edi,%eax
f0102535:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010253b:	c1 f8 03             	sar    $0x3,%eax
f010253e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102541:	89 c2                	mov    %eax,%edx
f0102543:	c1 ea 0c             	shr    $0xc,%edx
f0102546:	83 c4 10             	add    $0x10,%esp
f0102549:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010254f:	72 12                	jb     f0102563 <mem_init+0x1459>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102551:	50                   	push   %eax
f0102552:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0102557:	6a 52                	push   $0x52
f0102559:	68 a0 3c 10 f0       	push   $0xf0103ca0
f010255e:	e8 28 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102563:	83 ec 04             	sub    $0x4,%esp
f0102566:	68 00 10 00 00       	push   $0x1000
f010256b:	6a 01                	push   $0x1
f010256d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102572:	50                   	push   %eax
f0102573:	e8 4d 0d 00 00       	call   f01032c5 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102578:	89 f0                	mov    %esi,%eax
f010257a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102580:	c1 f8 03             	sar    $0x3,%eax
f0102583:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102586:	89 c2                	mov    %eax,%edx
f0102588:	c1 ea 0c             	shr    $0xc,%edx
f010258b:	83 c4 10             	add    $0x10,%esp
f010258e:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102594:	72 12                	jb     f01025a8 <mem_init+0x149e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102596:	50                   	push   %eax
f0102597:	68 a8 3f 10 f0       	push   $0xf0103fa8
f010259c:	6a 52                	push   $0x52
f010259e:	68 a0 3c 10 f0       	push   $0xf0103ca0
f01025a3:	e8 e3 da ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01025a8:	83 ec 04             	sub    $0x4,%esp
f01025ab:	68 00 10 00 00       	push   $0x1000
f01025b0:	6a 02                	push   $0x2
f01025b2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025b7:	50                   	push   %eax
f01025b8:	e8 08 0d 00 00       	call   f01032c5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01025bd:	6a 02                	push   $0x2
f01025bf:	68 00 10 00 00       	push   $0x1000
f01025c4:	57                   	push   %edi
f01025c5:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01025cb:	e8 c8 ea ff ff       	call   f0101098 <page_insert>
	assert(pp1->pp_ref == 1);
f01025d0:	83 c4 20             	add    $0x20,%esp
f01025d3:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01025d8:	74 19                	je     f01025f3 <mem_init+0x14e9>
f01025da:	68 92 3e 10 f0       	push   $0xf0103e92
f01025df:	68 ba 3c 10 f0       	push   $0xf0103cba
f01025e4:	68 97 03 00 00       	push   $0x397
f01025e9:	68 94 3c 10 f0       	push   $0xf0103c94
f01025ee:	e8 98 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01025f3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01025fa:	01 01 01 
f01025fd:	74 19                	je     f0102618 <mem_init+0x150e>
f01025ff:	68 64 47 10 f0       	push   $0xf0104764
f0102604:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102609:	68 98 03 00 00       	push   $0x398
f010260e:	68 94 3c 10 f0       	push   $0xf0103c94
f0102613:	e8 73 da ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102618:	6a 02                	push   $0x2
f010261a:	68 00 10 00 00       	push   $0x1000
f010261f:	56                   	push   %esi
f0102620:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0102626:	e8 6d ea ff ff       	call   f0101098 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010262b:	83 c4 10             	add    $0x10,%esp
f010262e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102635:	02 02 02 
f0102638:	74 19                	je     f0102653 <mem_init+0x1549>
f010263a:	68 88 47 10 f0       	push   $0xf0104788
f010263f:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102644:	68 9a 03 00 00       	push   $0x39a
f0102649:	68 94 3c 10 f0       	push   $0xf0103c94
f010264e:	e8 38 da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102653:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102658:	74 19                	je     f0102673 <mem_init+0x1569>
f010265a:	68 b4 3e 10 f0       	push   $0xf0103eb4
f010265f:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102664:	68 9b 03 00 00       	push   $0x39b
f0102669:	68 94 3c 10 f0       	push   $0xf0103c94
f010266e:	e8 18 da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102673:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102678:	74 19                	je     f0102693 <mem_init+0x1589>
f010267a:	68 1e 3f 10 f0       	push   $0xf0103f1e
f010267f:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102684:	68 9c 03 00 00       	push   $0x39c
f0102689:	68 94 3c 10 f0       	push   $0xf0103c94
f010268e:	e8 f8 d9 ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102693:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010269a:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010269d:	89 f0                	mov    %esi,%eax
f010269f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01026a5:	c1 f8 03             	sar    $0x3,%eax
f01026a8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026ab:	89 c2                	mov    %eax,%edx
f01026ad:	c1 ea 0c             	shr    $0xc,%edx
f01026b0:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01026b6:	72 12                	jb     f01026ca <mem_init+0x15c0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026b8:	50                   	push   %eax
f01026b9:	68 a8 3f 10 f0       	push   $0xf0103fa8
f01026be:	6a 52                	push   $0x52
f01026c0:	68 a0 3c 10 f0       	push   $0xf0103ca0
f01026c5:	e8 c1 d9 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01026ca:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01026d1:	03 03 03 
f01026d4:	74 19                	je     f01026ef <mem_init+0x15e5>
f01026d6:	68 ac 47 10 f0       	push   $0xf01047ac
f01026db:	68 ba 3c 10 f0       	push   $0xf0103cba
f01026e0:	68 9e 03 00 00       	push   $0x39e
f01026e5:	68 94 3c 10 f0       	push   $0xf0103c94
f01026ea:	e8 9c d9 ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01026ef:	83 ec 08             	sub    $0x8,%esp
f01026f2:	68 00 10 00 00       	push   $0x1000
f01026f7:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01026fd:	e8 53 e9 ff ff       	call   f0101055 <page_remove>
	assert(pp2->pp_ref == 0);
f0102702:	83 c4 10             	add    $0x10,%esp
f0102705:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010270a:	74 19                	je     f0102725 <mem_init+0x161b>
f010270c:	68 ec 3e 10 f0       	push   $0xf0103eec
f0102711:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102716:	68 a0 03 00 00       	push   $0x3a0
f010271b:	68 94 3c 10 f0       	push   $0xf0103c94
f0102720:	e8 66 d9 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102725:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f010272b:	8b 11                	mov    (%ecx),%edx
f010272d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102733:	89 d8                	mov    %ebx,%eax
f0102735:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010273b:	c1 f8 03             	sar    $0x3,%eax
f010273e:	c1 e0 0c             	shl    $0xc,%eax
f0102741:	39 c2                	cmp    %eax,%edx
f0102743:	74 19                	je     f010275e <mem_init+0x1654>
f0102745:	68 f0 42 10 f0       	push   $0xf01042f0
f010274a:	68 ba 3c 10 f0       	push   $0xf0103cba
f010274f:	68 a3 03 00 00       	push   $0x3a3
f0102754:	68 94 3c 10 f0       	push   $0xf0103c94
f0102759:	e8 2d d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010275e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102764:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102769:	74 19                	je     f0102784 <mem_init+0x167a>
f010276b:	68 a3 3e 10 f0       	push   $0xf0103ea3
f0102770:	68 ba 3c 10 f0       	push   $0xf0103cba
f0102775:	68 a5 03 00 00       	push   $0x3a5
f010277a:	68 94 3c 10 f0       	push   $0xf0103c94
f010277f:	e8 07 d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102784:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010278a:	83 ec 0c             	sub    $0xc,%esp
f010278d:	53                   	push   %ebx
f010278e:	e8 97 e6 ff ff       	call   f0100e2a <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102793:	c7 04 24 d8 47 10 f0 	movl   $0xf01047d8,(%esp)
f010279a:	e8 7d 00 00 00       	call   f010281c <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010279f:	83 c4 10             	add    $0x10,%esp
f01027a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027a5:	5b                   	pop    %ebx
f01027a6:	5e                   	pop    %esi
f01027a7:	5f                   	pop    %edi
f01027a8:	5d                   	pop    %ebp
f01027a9:	c3                   	ret    

f01027aa <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01027aa:	55                   	push   %ebp
f01027ab:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01027ad:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027b0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01027b3:	5d                   	pop    %ebp
f01027b4:	c3                   	ret    

f01027b5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01027b5:	55                   	push   %ebp
f01027b6:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01027b8:	ba 70 00 00 00       	mov    $0x70,%edx
f01027bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01027c0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01027c1:	ba 71 00 00 00       	mov    $0x71,%edx
f01027c6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01027c7:	0f b6 c0             	movzbl %al,%eax
}
f01027ca:	5d                   	pop    %ebp
f01027cb:	c3                   	ret    

f01027cc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01027cc:	55                   	push   %ebp
f01027cd:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01027cf:	ba 70 00 00 00       	mov    $0x70,%edx
f01027d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01027d7:	ee                   	out    %al,(%dx)
f01027d8:	ba 71 00 00 00       	mov    $0x71,%edx
f01027dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027e0:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01027e1:	5d                   	pop    %ebp
f01027e2:	c3                   	ret    

f01027e3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01027e3:	55                   	push   %ebp
f01027e4:	89 e5                	mov    %esp,%ebp
f01027e6:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01027e9:	ff 75 08             	pushl  0x8(%ebp)
f01027ec:	e8 0f de ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01027f1:	83 c4 10             	add    $0x10,%esp
f01027f4:	c9                   	leave  
f01027f5:	c3                   	ret    

f01027f6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01027f6:	55                   	push   %ebp
f01027f7:	89 e5                	mov    %esp,%ebp
f01027f9:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01027fc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102803:	ff 75 0c             	pushl  0xc(%ebp)
f0102806:	ff 75 08             	pushl  0x8(%ebp)
f0102809:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010280c:	50                   	push   %eax
f010280d:	68 e3 27 10 f0       	push   $0xf01027e3
f0102812:	e8 42 04 00 00       	call   f0102c59 <vprintfmt>
	return cnt;
}
f0102817:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010281a:	c9                   	leave  
f010281b:	c3                   	ret    

f010281c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010281c:	55                   	push   %ebp
f010281d:	89 e5                	mov    %esp,%ebp
f010281f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102822:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102825:	50                   	push   %eax
f0102826:	ff 75 08             	pushl  0x8(%ebp)
f0102829:	e8 c8 ff ff ff       	call   f01027f6 <vcprintf>
	va_end(ap);

	return cnt;
}
f010282e:	c9                   	leave  
f010282f:	c3                   	ret    

f0102830 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102830:	55                   	push   %ebp
f0102831:	89 e5                	mov    %esp,%ebp
f0102833:	57                   	push   %edi
f0102834:	56                   	push   %esi
f0102835:	53                   	push   %ebx
f0102836:	83 ec 14             	sub    $0x14,%esp
f0102839:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010283c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010283f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102842:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102845:	8b 1a                	mov    (%edx),%ebx
f0102847:	8b 01                	mov    (%ecx),%eax
f0102849:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010284c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102853:	eb 7f                	jmp    f01028d4 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102855:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102858:	01 d8                	add    %ebx,%eax
f010285a:	89 c6                	mov    %eax,%esi
f010285c:	c1 ee 1f             	shr    $0x1f,%esi
f010285f:	01 c6                	add    %eax,%esi
f0102861:	d1 fe                	sar    %esi
f0102863:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102866:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102869:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010286c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010286e:	eb 03                	jmp    f0102873 <stab_binsearch+0x43>
			m--;
f0102870:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102873:	39 c3                	cmp    %eax,%ebx
f0102875:	7f 0d                	jg     f0102884 <stab_binsearch+0x54>
f0102877:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010287b:	83 ea 0c             	sub    $0xc,%edx
f010287e:	39 f9                	cmp    %edi,%ecx
f0102880:	75 ee                	jne    f0102870 <stab_binsearch+0x40>
f0102882:	eb 05                	jmp    f0102889 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102884:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102887:	eb 4b                	jmp    f01028d4 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102889:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010288c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010288f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102893:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102896:	76 11                	jbe    f01028a9 <stab_binsearch+0x79>
			*region_left = m;
f0102898:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010289b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010289d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01028a0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01028a7:	eb 2b                	jmp    f01028d4 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01028a9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01028ac:	73 14                	jae    f01028c2 <stab_binsearch+0x92>
			*region_right = m - 1;
f01028ae:	83 e8 01             	sub    $0x1,%eax
f01028b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01028b4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01028b7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01028b9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01028c0:	eb 12                	jmp    f01028d4 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01028c2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028c5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01028c7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01028cb:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01028cd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01028d4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01028d7:	0f 8e 78 ff ff ff    	jle    f0102855 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01028dd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01028e1:	75 0f                	jne    f01028f2 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01028e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028e6:	8b 00                	mov    (%eax),%eax
f01028e8:	83 e8 01             	sub    $0x1,%eax
f01028eb:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01028ee:	89 06                	mov    %eax,(%esi)
f01028f0:	eb 2c                	jmp    f010291e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01028f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028f5:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01028f7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028fa:	8b 0e                	mov    (%esi),%ecx
f01028fc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01028ff:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102902:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102905:	eb 03                	jmp    f010290a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102907:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010290a:	39 c8                	cmp    %ecx,%eax
f010290c:	7e 0b                	jle    f0102919 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010290e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102912:	83 ea 0c             	sub    $0xc,%edx
f0102915:	39 df                	cmp    %ebx,%edi
f0102917:	75 ee                	jne    f0102907 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102919:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010291c:	89 06                	mov    %eax,(%esi)
	}
}
f010291e:	83 c4 14             	add    $0x14,%esp
f0102921:	5b                   	pop    %ebx
f0102922:	5e                   	pop    %esi
f0102923:	5f                   	pop    %edi
f0102924:	5d                   	pop    %ebp
f0102925:	c3                   	ret    

f0102926 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102926:	55                   	push   %ebp
f0102927:	89 e5                	mov    %esp,%ebp
f0102929:	57                   	push   %edi
f010292a:	56                   	push   %esi
f010292b:	53                   	push   %ebx
f010292c:	83 ec 3c             	sub    $0x3c,%esp
f010292f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102932:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102935:	c7 03 04 48 10 f0    	movl   $0xf0104804,(%ebx)
	info->eip_line = 0;
f010293b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102942:	c7 43 08 04 48 10 f0 	movl   $0xf0104804,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102949:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102950:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102953:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010295a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102960:	76 11                	jbe    f0102973 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102962:	b8 93 c1 10 f0       	mov    $0xf010c193,%eax
f0102967:	3d f1 a3 10 f0       	cmp    $0xf010a3f1,%eax
f010296c:	77 19                	ja     f0102987 <debuginfo_eip+0x61>
f010296e:	e9 a1 01 00 00       	jmp    f0102b14 <debuginfo_eip+0x1ee>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102973:	83 ec 04             	sub    $0x4,%esp
f0102976:	68 0e 48 10 f0       	push   $0xf010480e
f010297b:	6a 7f                	push   $0x7f
f010297d:	68 1b 48 10 f0       	push   $0xf010481b
f0102982:	e8 04 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102987:	80 3d 92 c1 10 f0 00 	cmpb   $0x0,0xf010c192
f010298e:	0f 85 87 01 00 00    	jne    f0102b1b <debuginfo_eip+0x1f5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102994:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010299b:	b8 f0 a3 10 f0       	mov    $0xf010a3f0,%eax
f01029a0:	2d 38 4a 10 f0       	sub    $0xf0104a38,%eax
f01029a5:	c1 f8 02             	sar    $0x2,%eax
f01029a8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01029ae:	83 e8 01             	sub    $0x1,%eax
f01029b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01029b4:	83 ec 08             	sub    $0x8,%esp
f01029b7:	56                   	push   %esi
f01029b8:	6a 64                	push   $0x64
f01029ba:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01029bd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01029c0:	b8 38 4a 10 f0       	mov    $0xf0104a38,%eax
f01029c5:	e8 66 fe ff ff       	call   f0102830 <stab_binsearch>
	if (lfile == 0)
f01029ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029cd:	83 c4 10             	add    $0x10,%esp
f01029d0:	85 c0                	test   %eax,%eax
f01029d2:	0f 84 4a 01 00 00    	je     f0102b22 <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01029d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01029db:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029de:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01029e1:	83 ec 08             	sub    $0x8,%esp
f01029e4:	56                   	push   %esi
f01029e5:	6a 24                	push   $0x24
f01029e7:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01029ea:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01029ed:	b8 38 4a 10 f0       	mov    $0xf0104a38,%eax
f01029f2:	e8 39 fe ff ff       	call   f0102830 <stab_binsearch>

	if (lfun <= rfun) {
f01029f7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01029fa:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01029fd:	83 c4 10             	add    $0x10,%esp
f0102a00:	39 d0                	cmp    %edx,%eax
f0102a02:	7f 40                	jg     f0102a44 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102a04:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102a07:	c1 e1 02             	shl    $0x2,%ecx
f0102a0a:	8d b9 38 4a 10 f0    	lea    -0xfefb5c8(%ecx),%edi
f0102a10:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102a13:	8b b9 38 4a 10 f0    	mov    -0xfefb5c8(%ecx),%edi
f0102a19:	b9 93 c1 10 f0       	mov    $0xf010c193,%ecx
f0102a1e:	81 e9 f1 a3 10 f0    	sub    $0xf010a3f1,%ecx
f0102a24:	39 cf                	cmp    %ecx,%edi
f0102a26:	73 09                	jae    f0102a31 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102a28:	81 c7 f1 a3 10 f0    	add    $0xf010a3f1,%edi
f0102a2e:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102a31:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102a34:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102a37:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102a3a:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102a3c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102a3f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102a42:	eb 0f                	jmp    f0102a53 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102a44:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102a47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a4a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102a4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a50:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102a53:	83 ec 08             	sub    $0x8,%esp
f0102a56:	6a 3a                	push   $0x3a
f0102a58:	ff 73 08             	pushl  0x8(%ebx)
f0102a5b:	e8 49 08 00 00       	call   f01032a9 <strfind>
f0102a60:	2b 43 08             	sub    0x8(%ebx),%eax
f0102a63:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102a66:	83 c4 08             	add    $0x8,%esp
f0102a69:	56                   	push   %esi
f0102a6a:	6a 44                	push   $0x44
f0102a6c:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102a6f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102a72:	b8 38 4a 10 f0       	mov    $0xf0104a38,%eax
f0102a77:	e8 b4 fd ff ff       	call   f0102830 <stab_binsearch>
info->eip_line = stabs[lline].n_desc;
f0102a7c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102a7f:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a82:	8d 04 85 38 4a 10 f0 	lea    -0xfefb5c8(,%eax,4),%eax
f0102a89:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0102a8d:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102a90:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102a93:	83 c4 10             	add    $0x10,%esp
f0102a96:	eb 06                	jmp    f0102a9e <debuginfo_eip+0x178>
f0102a98:	83 ea 01             	sub    $0x1,%edx
f0102a9b:	83 e8 0c             	sub    $0xc,%eax
f0102a9e:	39 d6                	cmp    %edx,%esi
f0102aa0:	7f 34                	jg     f0102ad6 <debuginfo_eip+0x1b0>
	       && stabs[lline].n_type != N_SOL
f0102aa2:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102aa6:	80 f9 84             	cmp    $0x84,%cl
f0102aa9:	74 0b                	je     f0102ab6 <debuginfo_eip+0x190>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102aab:	80 f9 64             	cmp    $0x64,%cl
f0102aae:	75 e8                	jne    f0102a98 <debuginfo_eip+0x172>
f0102ab0:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102ab4:	74 e2                	je     f0102a98 <debuginfo_eip+0x172>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102ab6:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102ab9:	8b 14 85 38 4a 10 f0 	mov    -0xfefb5c8(,%eax,4),%edx
f0102ac0:	b8 93 c1 10 f0       	mov    $0xf010c193,%eax
f0102ac5:	2d f1 a3 10 f0       	sub    $0xf010a3f1,%eax
f0102aca:	39 c2                	cmp    %eax,%edx
f0102acc:	73 08                	jae    f0102ad6 <debuginfo_eip+0x1b0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102ace:	81 c2 f1 a3 10 f0    	add    $0xf010a3f1,%edx
f0102ad4:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ad6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ad9:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102adc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ae1:	39 f2                	cmp    %esi,%edx
f0102ae3:	7d 49                	jge    f0102b2e <debuginfo_eip+0x208>
		for (lline = lfun + 1;
f0102ae5:	83 c2 01             	add    $0x1,%edx
f0102ae8:	89 d0                	mov    %edx,%eax
f0102aea:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102aed:	8d 14 95 38 4a 10 f0 	lea    -0xfefb5c8(,%edx,4),%edx
f0102af4:	eb 04                	jmp    f0102afa <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102af6:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102afa:	39 c6                	cmp    %eax,%esi
f0102afc:	7e 2b                	jle    f0102b29 <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102afe:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102b02:	83 c0 01             	add    $0x1,%eax
f0102b05:	83 c2 0c             	add    $0xc,%edx
f0102b08:	80 f9 a0             	cmp    $0xa0,%cl
f0102b0b:	74 e9                	je     f0102af6 <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b0d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b12:	eb 1a                	jmp    f0102b2e <debuginfo_eip+0x208>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102b14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b19:	eb 13                	jmp    f0102b2e <debuginfo_eip+0x208>
f0102b1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b20:	eb 0c                	jmp    f0102b2e <debuginfo_eip+0x208>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102b22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b27:	eb 05                	jmp    f0102b2e <debuginfo_eip+0x208>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b29:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b2e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b31:	5b                   	pop    %ebx
f0102b32:	5e                   	pop    %esi
f0102b33:	5f                   	pop    %edi
f0102b34:	5d                   	pop    %ebp
f0102b35:	c3                   	ret    

f0102b36 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102b36:	55                   	push   %ebp
f0102b37:	89 e5                	mov    %esp,%ebp
f0102b39:	57                   	push   %edi
f0102b3a:	56                   	push   %esi
f0102b3b:	53                   	push   %ebx
f0102b3c:	83 ec 1c             	sub    $0x1c,%esp
f0102b3f:	89 c7                	mov    %eax,%edi
f0102b41:	89 d6                	mov    %edx,%esi
f0102b43:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b46:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102b49:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102b4c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102b4f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102b52:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102b57:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102b5a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102b5d:	39 d3                	cmp    %edx,%ebx
f0102b5f:	72 05                	jb     f0102b66 <printnum+0x30>
f0102b61:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102b64:	77 45                	ja     f0102bab <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102b66:	83 ec 0c             	sub    $0xc,%esp
f0102b69:	ff 75 18             	pushl  0x18(%ebp)
f0102b6c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b6f:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102b72:	53                   	push   %ebx
f0102b73:	ff 75 10             	pushl  0x10(%ebp)
f0102b76:	83 ec 08             	sub    $0x8,%esp
f0102b79:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b7c:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b7f:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b82:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b85:	e8 46 09 00 00       	call   f01034d0 <__udivdi3>
f0102b8a:	83 c4 18             	add    $0x18,%esp
f0102b8d:	52                   	push   %edx
f0102b8e:	50                   	push   %eax
f0102b8f:	89 f2                	mov    %esi,%edx
f0102b91:	89 f8                	mov    %edi,%eax
f0102b93:	e8 9e ff ff ff       	call   f0102b36 <printnum>
f0102b98:	83 c4 20             	add    $0x20,%esp
f0102b9b:	eb 18                	jmp    f0102bb5 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102b9d:	83 ec 08             	sub    $0x8,%esp
f0102ba0:	56                   	push   %esi
f0102ba1:	ff 75 18             	pushl  0x18(%ebp)
f0102ba4:	ff d7                	call   *%edi
f0102ba6:	83 c4 10             	add    $0x10,%esp
f0102ba9:	eb 03                	jmp    f0102bae <printnum+0x78>
f0102bab:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102bae:	83 eb 01             	sub    $0x1,%ebx
f0102bb1:	85 db                	test   %ebx,%ebx
f0102bb3:	7f e8                	jg     f0102b9d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102bb5:	83 ec 08             	sub    $0x8,%esp
f0102bb8:	56                   	push   %esi
f0102bb9:	83 ec 04             	sub    $0x4,%esp
f0102bbc:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102bbf:	ff 75 e0             	pushl  -0x20(%ebp)
f0102bc2:	ff 75 dc             	pushl  -0x24(%ebp)
f0102bc5:	ff 75 d8             	pushl  -0x28(%ebp)
f0102bc8:	e8 33 0a 00 00       	call   f0103600 <__umoddi3>
f0102bcd:	83 c4 14             	add    $0x14,%esp
f0102bd0:	0f be 80 29 48 10 f0 	movsbl -0xfefb7d7(%eax),%eax
f0102bd7:	50                   	push   %eax
f0102bd8:	ff d7                	call   *%edi
}
f0102bda:	83 c4 10             	add    $0x10,%esp
f0102bdd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102be0:	5b                   	pop    %ebx
f0102be1:	5e                   	pop    %esi
f0102be2:	5f                   	pop    %edi
f0102be3:	5d                   	pop    %ebp
f0102be4:	c3                   	ret    

f0102be5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102be5:	55                   	push   %ebp
f0102be6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102be8:	83 fa 01             	cmp    $0x1,%edx
f0102beb:	7e 0e                	jle    f0102bfb <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102bed:	8b 10                	mov    (%eax),%edx
f0102bef:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102bf2:	89 08                	mov    %ecx,(%eax)
f0102bf4:	8b 02                	mov    (%edx),%eax
f0102bf6:	8b 52 04             	mov    0x4(%edx),%edx
f0102bf9:	eb 22                	jmp    f0102c1d <getuint+0x38>
	else if (lflag)
f0102bfb:	85 d2                	test   %edx,%edx
f0102bfd:	74 10                	je     f0102c0f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102bff:	8b 10                	mov    (%eax),%edx
f0102c01:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102c04:	89 08                	mov    %ecx,(%eax)
f0102c06:	8b 02                	mov    (%edx),%eax
f0102c08:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c0d:	eb 0e                	jmp    f0102c1d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102c0f:	8b 10                	mov    (%eax),%edx
f0102c11:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102c14:	89 08                	mov    %ecx,(%eax)
f0102c16:	8b 02                	mov    (%edx),%eax
f0102c18:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102c1d:	5d                   	pop    %ebp
f0102c1e:	c3                   	ret    

f0102c1f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102c1f:	55                   	push   %ebp
f0102c20:	89 e5                	mov    %esp,%ebp
f0102c22:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102c25:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102c29:	8b 10                	mov    (%eax),%edx
f0102c2b:	3b 50 04             	cmp    0x4(%eax),%edx
f0102c2e:	73 0a                	jae    f0102c3a <sprintputch+0x1b>
		*b->buf++ = ch;
f0102c30:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102c33:	89 08                	mov    %ecx,(%eax)
f0102c35:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c38:	88 02                	mov    %al,(%edx)
}
f0102c3a:	5d                   	pop    %ebp
f0102c3b:	c3                   	ret    

f0102c3c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102c3c:	55                   	push   %ebp
f0102c3d:	89 e5                	mov    %esp,%ebp
f0102c3f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102c42:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102c45:	50                   	push   %eax
f0102c46:	ff 75 10             	pushl  0x10(%ebp)
f0102c49:	ff 75 0c             	pushl  0xc(%ebp)
f0102c4c:	ff 75 08             	pushl  0x8(%ebp)
f0102c4f:	e8 05 00 00 00       	call   f0102c59 <vprintfmt>
	va_end(ap);
}
f0102c54:	83 c4 10             	add    $0x10,%esp
f0102c57:	c9                   	leave  
f0102c58:	c3                   	ret    

f0102c59 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102c59:	55                   	push   %ebp
f0102c5a:	89 e5                	mov    %esp,%ebp
f0102c5c:	57                   	push   %edi
f0102c5d:	56                   	push   %esi
f0102c5e:	53                   	push   %ebx
f0102c5f:	83 ec 2c             	sub    $0x2c,%esp
f0102c62:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c65:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c68:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102c6b:	eb 12                	jmp    f0102c7f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102c6d:	85 c0                	test   %eax,%eax
f0102c6f:	0f 84 89 03 00 00    	je     f0102ffe <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102c75:	83 ec 08             	sub    $0x8,%esp
f0102c78:	53                   	push   %ebx
f0102c79:	50                   	push   %eax
f0102c7a:	ff d6                	call   *%esi
f0102c7c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102c7f:	83 c7 01             	add    $0x1,%edi
f0102c82:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c86:	83 f8 25             	cmp    $0x25,%eax
f0102c89:	75 e2                	jne    f0102c6d <vprintfmt+0x14>
f0102c8b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102c8f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102c96:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c9d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102ca4:	ba 00 00 00 00       	mov    $0x0,%edx
f0102ca9:	eb 07                	jmp    f0102cb2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cab:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102cae:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cb2:	8d 47 01             	lea    0x1(%edi),%eax
f0102cb5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102cb8:	0f b6 07             	movzbl (%edi),%eax
f0102cbb:	0f b6 c8             	movzbl %al,%ecx
f0102cbe:	83 e8 23             	sub    $0x23,%eax
f0102cc1:	3c 55                	cmp    $0x55,%al
f0102cc3:	0f 87 1a 03 00 00    	ja     f0102fe3 <vprintfmt+0x38a>
f0102cc9:	0f b6 c0             	movzbl %al,%eax
f0102ccc:	ff 24 85 b4 48 10 f0 	jmp    *-0xfefb74c(,%eax,4)
f0102cd3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102cd6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102cda:	eb d6                	jmp    f0102cb2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cdc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cdf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ce4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102ce7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102cea:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102cee:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102cf1:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102cf4:	83 fa 09             	cmp    $0x9,%edx
f0102cf7:	77 39                	ja     f0102d32 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102cf9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102cfc:	eb e9                	jmp    f0102ce7 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102cfe:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d01:	8d 48 04             	lea    0x4(%eax),%ecx
f0102d04:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102d07:	8b 00                	mov    (%eax),%eax
f0102d09:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102d0f:	eb 27                	jmp    f0102d38 <vprintfmt+0xdf>
f0102d11:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d14:	85 c0                	test   %eax,%eax
f0102d16:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d1b:	0f 49 c8             	cmovns %eax,%ecx
f0102d1e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d24:	eb 8c                	jmp    f0102cb2 <vprintfmt+0x59>
f0102d26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102d29:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102d30:	eb 80                	jmp    f0102cb2 <vprintfmt+0x59>
f0102d32:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102d35:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102d38:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d3c:	0f 89 70 ff ff ff    	jns    f0102cb2 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102d42:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d45:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d48:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d4f:	e9 5e ff ff ff       	jmp    f0102cb2 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102d54:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102d5a:	e9 53 ff ff ff       	jmp    f0102cb2 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102d5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d62:	8d 50 04             	lea    0x4(%eax),%edx
f0102d65:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d68:	83 ec 08             	sub    $0x8,%esp
f0102d6b:	53                   	push   %ebx
f0102d6c:	ff 30                	pushl  (%eax)
f0102d6e:	ff d6                	call   *%esi
			break;
f0102d70:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102d76:	e9 04 ff ff ff       	jmp    f0102c7f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d7e:	8d 50 04             	lea    0x4(%eax),%edx
f0102d81:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d84:	8b 00                	mov    (%eax),%eax
f0102d86:	99                   	cltd   
f0102d87:	31 d0                	xor    %edx,%eax
f0102d89:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102d8b:	83 f8 06             	cmp    $0x6,%eax
f0102d8e:	7f 0b                	jg     f0102d9b <vprintfmt+0x142>
f0102d90:	8b 14 85 0c 4a 10 f0 	mov    -0xfefb5f4(,%eax,4),%edx
f0102d97:	85 d2                	test   %edx,%edx
f0102d99:	75 18                	jne    f0102db3 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102d9b:	50                   	push   %eax
f0102d9c:	68 41 48 10 f0       	push   $0xf0104841
f0102da1:	53                   	push   %ebx
f0102da2:	56                   	push   %esi
f0102da3:	e8 94 fe ff ff       	call   f0102c3c <printfmt>
f0102da8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102dae:	e9 cc fe ff ff       	jmp    f0102c7f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102db3:	52                   	push   %edx
f0102db4:	68 cc 3c 10 f0       	push   $0xf0103ccc
f0102db9:	53                   	push   %ebx
f0102dba:	56                   	push   %esi
f0102dbb:	e8 7c fe ff ff       	call   f0102c3c <printfmt>
f0102dc0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dc6:	e9 b4 fe ff ff       	jmp    f0102c7f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dcb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dce:	8d 50 04             	lea    0x4(%eax),%edx
f0102dd1:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dd4:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102dd6:	85 ff                	test   %edi,%edi
f0102dd8:	b8 3a 48 10 f0       	mov    $0xf010483a,%eax
f0102ddd:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102de0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102de4:	0f 8e 94 00 00 00    	jle    f0102e7e <vprintfmt+0x225>
f0102dea:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102dee:	0f 84 98 00 00 00    	je     f0102e8c <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102df4:	83 ec 08             	sub    $0x8,%esp
f0102df7:	ff 75 d0             	pushl  -0x30(%ebp)
f0102dfa:	57                   	push   %edi
f0102dfb:	e8 5f 03 00 00       	call   f010315f <strnlen>
f0102e00:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102e03:	29 c1                	sub    %eax,%ecx
f0102e05:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102e08:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102e0b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102e0f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102e12:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102e15:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e17:	eb 0f                	jmp    f0102e28 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102e19:	83 ec 08             	sub    $0x8,%esp
f0102e1c:	53                   	push   %ebx
f0102e1d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e20:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e22:	83 ef 01             	sub    $0x1,%edi
f0102e25:	83 c4 10             	add    $0x10,%esp
f0102e28:	85 ff                	test   %edi,%edi
f0102e2a:	7f ed                	jg     f0102e19 <vprintfmt+0x1c0>
f0102e2c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e2f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102e32:	85 c9                	test   %ecx,%ecx
f0102e34:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e39:	0f 49 c1             	cmovns %ecx,%eax
f0102e3c:	29 c1                	sub    %eax,%ecx
f0102e3e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e41:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e44:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e47:	89 cb                	mov    %ecx,%ebx
f0102e49:	eb 4d                	jmp    f0102e98 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102e4b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102e4f:	74 1b                	je     f0102e6c <vprintfmt+0x213>
f0102e51:	0f be c0             	movsbl %al,%eax
f0102e54:	83 e8 20             	sub    $0x20,%eax
f0102e57:	83 f8 5e             	cmp    $0x5e,%eax
f0102e5a:	76 10                	jbe    f0102e6c <vprintfmt+0x213>
					putch('?', putdat);
f0102e5c:	83 ec 08             	sub    $0x8,%esp
f0102e5f:	ff 75 0c             	pushl  0xc(%ebp)
f0102e62:	6a 3f                	push   $0x3f
f0102e64:	ff 55 08             	call   *0x8(%ebp)
f0102e67:	83 c4 10             	add    $0x10,%esp
f0102e6a:	eb 0d                	jmp    f0102e79 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102e6c:	83 ec 08             	sub    $0x8,%esp
f0102e6f:	ff 75 0c             	pushl  0xc(%ebp)
f0102e72:	52                   	push   %edx
f0102e73:	ff 55 08             	call   *0x8(%ebp)
f0102e76:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102e79:	83 eb 01             	sub    $0x1,%ebx
f0102e7c:	eb 1a                	jmp    f0102e98 <vprintfmt+0x23f>
f0102e7e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e81:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e84:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e87:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e8a:	eb 0c                	jmp    f0102e98 <vprintfmt+0x23f>
f0102e8c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e8f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e92:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e95:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e98:	83 c7 01             	add    $0x1,%edi
f0102e9b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102e9f:	0f be d0             	movsbl %al,%edx
f0102ea2:	85 d2                	test   %edx,%edx
f0102ea4:	74 23                	je     f0102ec9 <vprintfmt+0x270>
f0102ea6:	85 f6                	test   %esi,%esi
f0102ea8:	78 a1                	js     f0102e4b <vprintfmt+0x1f2>
f0102eaa:	83 ee 01             	sub    $0x1,%esi
f0102ead:	79 9c                	jns    f0102e4b <vprintfmt+0x1f2>
f0102eaf:	89 df                	mov    %ebx,%edi
f0102eb1:	8b 75 08             	mov    0x8(%ebp),%esi
f0102eb4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102eb7:	eb 18                	jmp    f0102ed1 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102eb9:	83 ec 08             	sub    $0x8,%esp
f0102ebc:	53                   	push   %ebx
f0102ebd:	6a 20                	push   $0x20
f0102ebf:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102ec1:	83 ef 01             	sub    $0x1,%edi
f0102ec4:	83 c4 10             	add    $0x10,%esp
f0102ec7:	eb 08                	jmp    f0102ed1 <vprintfmt+0x278>
f0102ec9:	89 df                	mov    %ebx,%edi
f0102ecb:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ece:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ed1:	85 ff                	test   %edi,%edi
f0102ed3:	7f e4                	jg     f0102eb9 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ed5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ed8:	e9 a2 fd ff ff       	jmp    f0102c7f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102edd:	83 fa 01             	cmp    $0x1,%edx
f0102ee0:	7e 16                	jle    f0102ef8 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102ee2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ee5:	8d 50 08             	lea    0x8(%eax),%edx
f0102ee8:	89 55 14             	mov    %edx,0x14(%ebp)
f0102eeb:	8b 50 04             	mov    0x4(%eax),%edx
f0102eee:	8b 00                	mov    (%eax),%eax
f0102ef0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ef3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102ef6:	eb 32                	jmp    f0102f2a <vprintfmt+0x2d1>
	else if (lflag)
f0102ef8:	85 d2                	test   %edx,%edx
f0102efa:	74 18                	je     f0102f14 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102efc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eff:	8d 50 04             	lea    0x4(%eax),%edx
f0102f02:	89 55 14             	mov    %edx,0x14(%ebp)
f0102f05:	8b 00                	mov    (%eax),%eax
f0102f07:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f0a:	89 c1                	mov    %eax,%ecx
f0102f0c:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f0f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f12:	eb 16                	jmp    f0102f2a <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102f14:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f17:	8d 50 04             	lea    0x4(%eax),%edx
f0102f1a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102f1d:	8b 00                	mov    (%eax),%eax
f0102f1f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f22:	89 c1                	mov    %eax,%ecx
f0102f24:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f27:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102f2a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102f2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102f30:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102f35:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102f39:	79 74                	jns    f0102faf <vprintfmt+0x356>
				putch('-', putdat);
f0102f3b:	83 ec 08             	sub    $0x8,%esp
f0102f3e:	53                   	push   %ebx
f0102f3f:	6a 2d                	push   $0x2d
f0102f41:	ff d6                	call   *%esi
				num = -(long long) num;
f0102f43:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102f46:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102f49:	f7 d8                	neg    %eax
f0102f4b:	83 d2 00             	adc    $0x0,%edx
f0102f4e:	f7 da                	neg    %edx
f0102f50:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102f53:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102f58:	eb 55                	jmp    f0102faf <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102f5a:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f5d:	e8 83 fc ff ff       	call   f0102be5 <getuint>
			base = 10;
f0102f62:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102f67:	eb 46                	jmp    f0102faf <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			  num = getuint(&ap, lflag);
f0102f69:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f6c:	e8 74 fc ff ff       	call   f0102be5 <getuint>
			  base = 8;
f0102f71:	b9 08 00 00 00       	mov    $0x8,%ecx
			  goto number;
f0102f76:	eb 37                	jmp    f0102faf <vprintfmt+0x356>
		// pointer
		case 'p':
			putch('0', putdat);
f0102f78:	83 ec 08             	sub    $0x8,%esp
f0102f7b:	53                   	push   %ebx
f0102f7c:	6a 30                	push   $0x30
f0102f7e:	ff d6                	call   *%esi
			putch('x', putdat);
f0102f80:	83 c4 08             	add    $0x8,%esp
f0102f83:	53                   	push   %ebx
f0102f84:	6a 78                	push   $0x78
f0102f86:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f88:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f8b:	8d 50 04             	lea    0x4(%eax),%edx
f0102f8e:	89 55 14             	mov    %edx,0x14(%ebp)
			  goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102f91:	8b 00                	mov    (%eax),%eax
f0102f93:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f98:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102f9b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102fa0:	eb 0d                	jmp    f0102faf <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102fa2:	8d 45 14             	lea    0x14(%ebp),%eax
f0102fa5:	e8 3b fc ff ff       	call   f0102be5 <getuint>
			base = 16;
f0102faa:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102faf:	83 ec 0c             	sub    $0xc,%esp
f0102fb2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102fb6:	57                   	push   %edi
f0102fb7:	ff 75 e0             	pushl  -0x20(%ebp)
f0102fba:	51                   	push   %ecx
f0102fbb:	52                   	push   %edx
f0102fbc:	50                   	push   %eax
f0102fbd:	89 da                	mov    %ebx,%edx
f0102fbf:	89 f0                	mov    %esi,%eax
f0102fc1:	e8 70 fb ff ff       	call   f0102b36 <printnum>
			break;
f0102fc6:	83 c4 20             	add    $0x20,%esp
f0102fc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102fcc:	e9 ae fc ff ff       	jmp    f0102c7f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102fd1:	83 ec 08             	sub    $0x8,%esp
f0102fd4:	53                   	push   %ebx
f0102fd5:	51                   	push   %ecx
f0102fd6:	ff d6                	call   *%esi
			break;
f0102fd8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fdb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102fde:	e9 9c fc ff ff       	jmp    f0102c7f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102fe3:	83 ec 08             	sub    $0x8,%esp
f0102fe6:	53                   	push   %ebx
f0102fe7:	6a 25                	push   $0x25
f0102fe9:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102feb:	83 c4 10             	add    $0x10,%esp
f0102fee:	eb 03                	jmp    f0102ff3 <vprintfmt+0x39a>
f0102ff0:	83 ef 01             	sub    $0x1,%edi
f0102ff3:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ff7:	75 f7                	jne    f0102ff0 <vprintfmt+0x397>
f0102ff9:	e9 81 fc ff ff       	jmp    f0102c7f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ffe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103001:	5b                   	pop    %ebx
f0103002:	5e                   	pop    %esi
f0103003:	5f                   	pop    %edi
f0103004:	5d                   	pop    %ebp
f0103005:	c3                   	ret    

f0103006 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103006:	55                   	push   %ebp
f0103007:	89 e5                	mov    %esp,%ebp
f0103009:	83 ec 18             	sub    $0x18,%esp
f010300c:	8b 45 08             	mov    0x8(%ebp),%eax
f010300f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103012:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103015:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103019:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010301c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103023:	85 c0                	test   %eax,%eax
f0103025:	74 26                	je     f010304d <vsnprintf+0x47>
f0103027:	85 d2                	test   %edx,%edx
f0103029:	7e 22                	jle    f010304d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010302b:	ff 75 14             	pushl  0x14(%ebp)
f010302e:	ff 75 10             	pushl  0x10(%ebp)
f0103031:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103034:	50                   	push   %eax
f0103035:	68 1f 2c 10 f0       	push   $0xf0102c1f
f010303a:	e8 1a fc ff ff       	call   f0102c59 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010303f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103042:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103045:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103048:	83 c4 10             	add    $0x10,%esp
f010304b:	eb 05                	jmp    f0103052 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010304d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103052:	c9                   	leave  
f0103053:	c3                   	ret    

f0103054 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103054:	55                   	push   %ebp
f0103055:	89 e5                	mov    %esp,%ebp
f0103057:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010305a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010305d:	50                   	push   %eax
f010305e:	ff 75 10             	pushl  0x10(%ebp)
f0103061:	ff 75 0c             	pushl  0xc(%ebp)
f0103064:	ff 75 08             	pushl  0x8(%ebp)
f0103067:	e8 9a ff ff ff       	call   f0103006 <vsnprintf>
	va_end(ap);

	return rc;
}
f010306c:	c9                   	leave  
f010306d:	c3                   	ret    

f010306e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010306e:	55                   	push   %ebp
f010306f:	89 e5                	mov    %esp,%ebp
f0103071:	57                   	push   %edi
f0103072:	56                   	push   %esi
f0103073:	53                   	push   %ebx
f0103074:	83 ec 0c             	sub    $0xc,%esp
f0103077:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010307a:	85 c0                	test   %eax,%eax
f010307c:	74 11                	je     f010308f <readline+0x21>
		cprintf("%s", prompt);
f010307e:	83 ec 08             	sub    $0x8,%esp
f0103081:	50                   	push   %eax
f0103082:	68 cc 3c 10 f0       	push   $0xf0103ccc
f0103087:	e8 90 f7 ff ff       	call   f010281c <cprintf>
f010308c:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010308f:	83 ec 0c             	sub    $0xc,%esp
f0103092:	6a 00                	push   $0x0
f0103094:	e8 88 d5 ff ff       	call   f0100621 <iscons>
f0103099:	89 c7                	mov    %eax,%edi
f010309b:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010309e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01030a3:	e8 68 d5 ff ff       	call   f0100610 <getchar>
f01030a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01030aa:	85 c0                	test   %eax,%eax
f01030ac:	79 18                	jns    f01030c6 <readline+0x58>
			cprintf("read error: %e\n", c);
f01030ae:	83 ec 08             	sub    $0x8,%esp
f01030b1:	50                   	push   %eax
f01030b2:	68 28 4a 10 f0       	push   $0xf0104a28
f01030b7:	e8 60 f7 ff ff       	call   f010281c <cprintf>
			return NULL;
f01030bc:	83 c4 10             	add    $0x10,%esp
f01030bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01030c4:	eb 79                	jmp    f010313f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01030c6:	83 f8 08             	cmp    $0x8,%eax
f01030c9:	0f 94 c2             	sete   %dl
f01030cc:	83 f8 7f             	cmp    $0x7f,%eax
f01030cf:	0f 94 c0             	sete   %al
f01030d2:	08 c2                	or     %al,%dl
f01030d4:	74 1a                	je     f01030f0 <readline+0x82>
f01030d6:	85 f6                	test   %esi,%esi
f01030d8:	7e 16                	jle    f01030f0 <readline+0x82>
			if (echoing)
f01030da:	85 ff                	test   %edi,%edi
f01030dc:	74 0d                	je     f01030eb <readline+0x7d>
				cputchar('\b');
f01030de:	83 ec 0c             	sub    $0xc,%esp
f01030e1:	6a 08                	push   $0x8
f01030e3:	e8 18 d5 ff ff       	call   f0100600 <cputchar>
f01030e8:	83 c4 10             	add    $0x10,%esp
			i--;
f01030eb:	83 ee 01             	sub    $0x1,%esi
f01030ee:	eb b3                	jmp    f01030a3 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01030f0:	83 fb 1f             	cmp    $0x1f,%ebx
f01030f3:	7e 23                	jle    f0103118 <readline+0xaa>
f01030f5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01030fb:	7f 1b                	jg     f0103118 <readline+0xaa>
			if (echoing)
f01030fd:	85 ff                	test   %edi,%edi
f01030ff:	74 0c                	je     f010310d <readline+0x9f>
				cputchar(c);
f0103101:	83 ec 0c             	sub    $0xc,%esp
f0103104:	53                   	push   %ebx
f0103105:	e8 f6 d4 ff ff       	call   f0100600 <cputchar>
f010310a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010310d:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0103113:	8d 76 01             	lea    0x1(%esi),%esi
f0103116:	eb 8b                	jmp    f01030a3 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103118:	83 fb 0a             	cmp    $0xa,%ebx
f010311b:	74 05                	je     f0103122 <readline+0xb4>
f010311d:	83 fb 0d             	cmp    $0xd,%ebx
f0103120:	75 81                	jne    f01030a3 <readline+0x35>
			if (echoing)
f0103122:	85 ff                	test   %edi,%edi
f0103124:	74 0d                	je     f0103133 <readline+0xc5>
				cputchar('\n');
f0103126:	83 ec 0c             	sub    $0xc,%esp
f0103129:	6a 0a                	push   $0xa
f010312b:	e8 d0 d4 ff ff       	call   f0100600 <cputchar>
f0103130:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103133:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010313a:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f010313f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103142:	5b                   	pop    %ebx
f0103143:	5e                   	pop    %esi
f0103144:	5f                   	pop    %edi
f0103145:	5d                   	pop    %ebp
f0103146:	c3                   	ret    

f0103147 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103147:	55                   	push   %ebp
f0103148:	89 e5                	mov    %esp,%ebp
f010314a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010314d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103152:	eb 03                	jmp    f0103157 <strlen+0x10>
		n++;
f0103154:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103157:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010315b:	75 f7                	jne    f0103154 <strlen+0xd>
		n++;
	return n;
}
f010315d:	5d                   	pop    %ebp
f010315e:	c3                   	ret    

f010315f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010315f:	55                   	push   %ebp
f0103160:	89 e5                	mov    %esp,%ebp
f0103162:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103165:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103168:	ba 00 00 00 00       	mov    $0x0,%edx
f010316d:	eb 03                	jmp    f0103172 <strnlen+0x13>
		n++;
f010316f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103172:	39 c2                	cmp    %eax,%edx
f0103174:	74 08                	je     f010317e <strnlen+0x1f>
f0103176:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010317a:	75 f3                	jne    f010316f <strnlen+0x10>
f010317c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010317e:	5d                   	pop    %ebp
f010317f:	c3                   	ret    

f0103180 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103180:	55                   	push   %ebp
f0103181:	89 e5                	mov    %esp,%ebp
f0103183:	53                   	push   %ebx
f0103184:	8b 45 08             	mov    0x8(%ebp),%eax
f0103187:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010318a:	89 c2                	mov    %eax,%edx
f010318c:	83 c2 01             	add    $0x1,%edx
f010318f:	83 c1 01             	add    $0x1,%ecx
f0103192:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103196:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103199:	84 db                	test   %bl,%bl
f010319b:	75 ef                	jne    f010318c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010319d:	5b                   	pop    %ebx
f010319e:	5d                   	pop    %ebp
f010319f:	c3                   	ret    

f01031a0 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01031a0:	55                   	push   %ebp
f01031a1:	89 e5                	mov    %esp,%ebp
f01031a3:	53                   	push   %ebx
f01031a4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01031a7:	53                   	push   %ebx
f01031a8:	e8 9a ff ff ff       	call   f0103147 <strlen>
f01031ad:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01031b0:	ff 75 0c             	pushl  0xc(%ebp)
f01031b3:	01 d8                	add    %ebx,%eax
f01031b5:	50                   	push   %eax
f01031b6:	e8 c5 ff ff ff       	call   f0103180 <strcpy>
	return dst;
}
f01031bb:	89 d8                	mov    %ebx,%eax
f01031bd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01031c0:	c9                   	leave  
f01031c1:	c3                   	ret    

f01031c2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01031c2:	55                   	push   %ebp
f01031c3:	89 e5                	mov    %esp,%ebp
f01031c5:	56                   	push   %esi
f01031c6:	53                   	push   %ebx
f01031c7:	8b 75 08             	mov    0x8(%ebp),%esi
f01031ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031cd:	89 f3                	mov    %esi,%ebx
f01031cf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031d2:	89 f2                	mov    %esi,%edx
f01031d4:	eb 0f                	jmp    f01031e5 <strncpy+0x23>
		*dst++ = *src;
f01031d6:	83 c2 01             	add    $0x1,%edx
f01031d9:	0f b6 01             	movzbl (%ecx),%eax
f01031dc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01031df:	80 39 01             	cmpb   $0x1,(%ecx)
f01031e2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031e5:	39 da                	cmp    %ebx,%edx
f01031e7:	75 ed                	jne    f01031d6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01031e9:	89 f0                	mov    %esi,%eax
f01031eb:	5b                   	pop    %ebx
f01031ec:	5e                   	pop    %esi
f01031ed:	5d                   	pop    %ebp
f01031ee:	c3                   	ret    

f01031ef <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01031ef:	55                   	push   %ebp
f01031f0:	89 e5                	mov    %esp,%ebp
f01031f2:	56                   	push   %esi
f01031f3:	53                   	push   %ebx
f01031f4:	8b 75 08             	mov    0x8(%ebp),%esi
f01031f7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031fa:	8b 55 10             	mov    0x10(%ebp),%edx
f01031fd:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01031ff:	85 d2                	test   %edx,%edx
f0103201:	74 21                	je     f0103224 <strlcpy+0x35>
f0103203:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103207:	89 f2                	mov    %esi,%edx
f0103209:	eb 09                	jmp    f0103214 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010320b:	83 c2 01             	add    $0x1,%edx
f010320e:	83 c1 01             	add    $0x1,%ecx
f0103211:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103214:	39 c2                	cmp    %eax,%edx
f0103216:	74 09                	je     f0103221 <strlcpy+0x32>
f0103218:	0f b6 19             	movzbl (%ecx),%ebx
f010321b:	84 db                	test   %bl,%bl
f010321d:	75 ec                	jne    f010320b <strlcpy+0x1c>
f010321f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103221:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103224:	29 f0                	sub    %esi,%eax
}
f0103226:	5b                   	pop    %ebx
f0103227:	5e                   	pop    %esi
f0103228:	5d                   	pop    %ebp
f0103229:	c3                   	ret    

f010322a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010322a:	55                   	push   %ebp
f010322b:	89 e5                	mov    %esp,%ebp
f010322d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103230:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103233:	eb 06                	jmp    f010323b <strcmp+0x11>
		p++, q++;
f0103235:	83 c1 01             	add    $0x1,%ecx
f0103238:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010323b:	0f b6 01             	movzbl (%ecx),%eax
f010323e:	84 c0                	test   %al,%al
f0103240:	74 04                	je     f0103246 <strcmp+0x1c>
f0103242:	3a 02                	cmp    (%edx),%al
f0103244:	74 ef                	je     f0103235 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103246:	0f b6 c0             	movzbl %al,%eax
f0103249:	0f b6 12             	movzbl (%edx),%edx
f010324c:	29 d0                	sub    %edx,%eax
}
f010324e:	5d                   	pop    %ebp
f010324f:	c3                   	ret    

f0103250 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103250:	55                   	push   %ebp
f0103251:	89 e5                	mov    %esp,%ebp
f0103253:	53                   	push   %ebx
f0103254:	8b 45 08             	mov    0x8(%ebp),%eax
f0103257:	8b 55 0c             	mov    0xc(%ebp),%edx
f010325a:	89 c3                	mov    %eax,%ebx
f010325c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010325f:	eb 06                	jmp    f0103267 <strncmp+0x17>
		n--, p++, q++;
f0103261:	83 c0 01             	add    $0x1,%eax
f0103264:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103267:	39 d8                	cmp    %ebx,%eax
f0103269:	74 15                	je     f0103280 <strncmp+0x30>
f010326b:	0f b6 08             	movzbl (%eax),%ecx
f010326e:	84 c9                	test   %cl,%cl
f0103270:	74 04                	je     f0103276 <strncmp+0x26>
f0103272:	3a 0a                	cmp    (%edx),%cl
f0103274:	74 eb                	je     f0103261 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103276:	0f b6 00             	movzbl (%eax),%eax
f0103279:	0f b6 12             	movzbl (%edx),%edx
f010327c:	29 d0                	sub    %edx,%eax
f010327e:	eb 05                	jmp    f0103285 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103280:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103285:	5b                   	pop    %ebx
f0103286:	5d                   	pop    %ebp
f0103287:	c3                   	ret    

f0103288 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103288:	55                   	push   %ebp
f0103289:	89 e5                	mov    %esp,%ebp
f010328b:	8b 45 08             	mov    0x8(%ebp),%eax
f010328e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103292:	eb 07                	jmp    f010329b <strchr+0x13>
		if (*s == c)
f0103294:	38 ca                	cmp    %cl,%dl
f0103296:	74 0f                	je     f01032a7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103298:	83 c0 01             	add    $0x1,%eax
f010329b:	0f b6 10             	movzbl (%eax),%edx
f010329e:	84 d2                	test   %dl,%dl
f01032a0:	75 f2                	jne    f0103294 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01032a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032a7:	5d                   	pop    %ebp
f01032a8:	c3                   	ret    

f01032a9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01032a9:	55                   	push   %ebp
f01032aa:	89 e5                	mov    %esp,%ebp
f01032ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01032af:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01032b3:	eb 03                	jmp    f01032b8 <strfind+0xf>
f01032b5:	83 c0 01             	add    $0x1,%eax
f01032b8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01032bb:	38 ca                	cmp    %cl,%dl
f01032bd:	74 04                	je     f01032c3 <strfind+0x1a>
f01032bf:	84 d2                	test   %dl,%dl
f01032c1:	75 f2                	jne    f01032b5 <strfind+0xc>
			break;
	return (char *) s;
}
f01032c3:	5d                   	pop    %ebp
f01032c4:	c3                   	ret    

f01032c5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01032c5:	55                   	push   %ebp
f01032c6:	89 e5                	mov    %esp,%ebp
f01032c8:	57                   	push   %edi
f01032c9:	56                   	push   %esi
f01032ca:	53                   	push   %ebx
f01032cb:	8b 7d 08             	mov    0x8(%ebp),%edi
f01032ce:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01032d1:	85 c9                	test   %ecx,%ecx
f01032d3:	74 36                	je     f010330b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01032d5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01032db:	75 28                	jne    f0103305 <memset+0x40>
f01032dd:	f6 c1 03             	test   $0x3,%cl
f01032e0:	75 23                	jne    f0103305 <memset+0x40>
		c &= 0xFF;
f01032e2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01032e6:	89 d3                	mov    %edx,%ebx
f01032e8:	c1 e3 08             	shl    $0x8,%ebx
f01032eb:	89 d6                	mov    %edx,%esi
f01032ed:	c1 e6 18             	shl    $0x18,%esi
f01032f0:	89 d0                	mov    %edx,%eax
f01032f2:	c1 e0 10             	shl    $0x10,%eax
f01032f5:	09 f0                	or     %esi,%eax
f01032f7:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01032f9:	89 d8                	mov    %ebx,%eax
f01032fb:	09 d0                	or     %edx,%eax
f01032fd:	c1 e9 02             	shr    $0x2,%ecx
f0103300:	fc                   	cld    
f0103301:	f3 ab                	rep stos %eax,%es:(%edi)
f0103303:	eb 06                	jmp    f010330b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103305:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103308:	fc                   	cld    
f0103309:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010330b:	89 f8                	mov    %edi,%eax
f010330d:	5b                   	pop    %ebx
f010330e:	5e                   	pop    %esi
f010330f:	5f                   	pop    %edi
f0103310:	5d                   	pop    %ebp
f0103311:	c3                   	ret    

f0103312 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103312:	55                   	push   %ebp
f0103313:	89 e5                	mov    %esp,%ebp
f0103315:	57                   	push   %edi
f0103316:	56                   	push   %esi
f0103317:	8b 45 08             	mov    0x8(%ebp),%eax
f010331a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010331d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103320:	39 c6                	cmp    %eax,%esi
f0103322:	73 35                	jae    f0103359 <memmove+0x47>
f0103324:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103327:	39 d0                	cmp    %edx,%eax
f0103329:	73 2e                	jae    f0103359 <memmove+0x47>
		s += n;
		d += n;
f010332b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010332e:	89 d6                	mov    %edx,%esi
f0103330:	09 fe                	or     %edi,%esi
f0103332:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103338:	75 13                	jne    f010334d <memmove+0x3b>
f010333a:	f6 c1 03             	test   $0x3,%cl
f010333d:	75 0e                	jne    f010334d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010333f:	83 ef 04             	sub    $0x4,%edi
f0103342:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103345:	c1 e9 02             	shr    $0x2,%ecx
f0103348:	fd                   	std    
f0103349:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010334b:	eb 09                	jmp    f0103356 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010334d:	83 ef 01             	sub    $0x1,%edi
f0103350:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103353:	fd                   	std    
f0103354:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103356:	fc                   	cld    
f0103357:	eb 1d                	jmp    f0103376 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103359:	89 f2                	mov    %esi,%edx
f010335b:	09 c2                	or     %eax,%edx
f010335d:	f6 c2 03             	test   $0x3,%dl
f0103360:	75 0f                	jne    f0103371 <memmove+0x5f>
f0103362:	f6 c1 03             	test   $0x3,%cl
f0103365:	75 0a                	jne    f0103371 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103367:	c1 e9 02             	shr    $0x2,%ecx
f010336a:	89 c7                	mov    %eax,%edi
f010336c:	fc                   	cld    
f010336d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010336f:	eb 05                	jmp    f0103376 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103371:	89 c7                	mov    %eax,%edi
f0103373:	fc                   	cld    
f0103374:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103376:	5e                   	pop    %esi
f0103377:	5f                   	pop    %edi
f0103378:	5d                   	pop    %ebp
f0103379:	c3                   	ret    

f010337a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010337a:	55                   	push   %ebp
f010337b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010337d:	ff 75 10             	pushl  0x10(%ebp)
f0103380:	ff 75 0c             	pushl  0xc(%ebp)
f0103383:	ff 75 08             	pushl  0x8(%ebp)
f0103386:	e8 87 ff ff ff       	call   f0103312 <memmove>
}
f010338b:	c9                   	leave  
f010338c:	c3                   	ret    

f010338d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010338d:	55                   	push   %ebp
f010338e:	89 e5                	mov    %esp,%ebp
f0103390:	56                   	push   %esi
f0103391:	53                   	push   %ebx
f0103392:	8b 45 08             	mov    0x8(%ebp),%eax
f0103395:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103398:	89 c6                	mov    %eax,%esi
f010339a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010339d:	eb 1a                	jmp    f01033b9 <memcmp+0x2c>
		if (*s1 != *s2)
f010339f:	0f b6 08             	movzbl (%eax),%ecx
f01033a2:	0f b6 1a             	movzbl (%edx),%ebx
f01033a5:	38 d9                	cmp    %bl,%cl
f01033a7:	74 0a                	je     f01033b3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01033a9:	0f b6 c1             	movzbl %cl,%eax
f01033ac:	0f b6 db             	movzbl %bl,%ebx
f01033af:	29 d8                	sub    %ebx,%eax
f01033b1:	eb 0f                	jmp    f01033c2 <memcmp+0x35>
		s1++, s2++;
f01033b3:	83 c0 01             	add    $0x1,%eax
f01033b6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01033b9:	39 f0                	cmp    %esi,%eax
f01033bb:	75 e2                	jne    f010339f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01033bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033c2:	5b                   	pop    %ebx
f01033c3:	5e                   	pop    %esi
f01033c4:	5d                   	pop    %ebp
f01033c5:	c3                   	ret    

f01033c6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01033c6:	55                   	push   %ebp
f01033c7:	89 e5                	mov    %esp,%ebp
f01033c9:	53                   	push   %ebx
f01033ca:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01033cd:	89 c1                	mov    %eax,%ecx
f01033cf:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01033d2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033d6:	eb 0a                	jmp    f01033e2 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01033d8:	0f b6 10             	movzbl (%eax),%edx
f01033db:	39 da                	cmp    %ebx,%edx
f01033dd:	74 07                	je     f01033e6 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033df:	83 c0 01             	add    $0x1,%eax
f01033e2:	39 c8                	cmp    %ecx,%eax
f01033e4:	72 f2                	jb     f01033d8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01033e6:	5b                   	pop    %ebx
f01033e7:	5d                   	pop    %ebp
f01033e8:	c3                   	ret    

f01033e9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01033e9:	55                   	push   %ebp
f01033ea:	89 e5                	mov    %esp,%ebp
f01033ec:	57                   	push   %edi
f01033ed:	56                   	push   %esi
f01033ee:	53                   	push   %ebx
f01033ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033f2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033f5:	eb 03                	jmp    f01033fa <strtol+0x11>
		s++;
f01033f7:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033fa:	0f b6 01             	movzbl (%ecx),%eax
f01033fd:	3c 20                	cmp    $0x20,%al
f01033ff:	74 f6                	je     f01033f7 <strtol+0xe>
f0103401:	3c 09                	cmp    $0x9,%al
f0103403:	74 f2                	je     f01033f7 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103405:	3c 2b                	cmp    $0x2b,%al
f0103407:	75 0a                	jne    f0103413 <strtol+0x2a>
		s++;
f0103409:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010340c:	bf 00 00 00 00       	mov    $0x0,%edi
f0103411:	eb 11                	jmp    f0103424 <strtol+0x3b>
f0103413:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103418:	3c 2d                	cmp    $0x2d,%al
f010341a:	75 08                	jne    f0103424 <strtol+0x3b>
		s++, neg = 1;
f010341c:	83 c1 01             	add    $0x1,%ecx
f010341f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103424:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010342a:	75 15                	jne    f0103441 <strtol+0x58>
f010342c:	80 39 30             	cmpb   $0x30,(%ecx)
f010342f:	75 10                	jne    f0103441 <strtol+0x58>
f0103431:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103435:	75 7c                	jne    f01034b3 <strtol+0xca>
		s += 2, base = 16;
f0103437:	83 c1 02             	add    $0x2,%ecx
f010343a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010343f:	eb 16                	jmp    f0103457 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103441:	85 db                	test   %ebx,%ebx
f0103443:	75 12                	jne    f0103457 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103445:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010344a:	80 39 30             	cmpb   $0x30,(%ecx)
f010344d:	75 08                	jne    f0103457 <strtol+0x6e>
		s++, base = 8;
f010344f:	83 c1 01             	add    $0x1,%ecx
f0103452:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103457:	b8 00 00 00 00       	mov    $0x0,%eax
f010345c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010345f:	0f b6 11             	movzbl (%ecx),%edx
f0103462:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103465:	89 f3                	mov    %esi,%ebx
f0103467:	80 fb 09             	cmp    $0x9,%bl
f010346a:	77 08                	ja     f0103474 <strtol+0x8b>
			dig = *s - '0';
f010346c:	0f be d2             	movsbl %dl,%edx
f010346f:	83 ea 30             	sub    $0x30,%edx
f0103472:	eb 22                	jmp    f0103496 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103474:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103477:	89 f3                	mov    %esi,%ebx
f0103479:	80 fb 19             	cmp    $0x19,%bl
f010347c:	77 08                	ja     f0103486 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010347e:	0f be d2             	movsbl %dl,%edx
f0103481:	83 ea 57             	sub    $0x57,%edx
f0103484:	eb 10                	jmp    f0103496 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103486:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103489:	89 f3                	mov    %esi,%ebx
f010348b:	80 fb 19             	cmp    $0x19,%bl
f010348e:	77 16                	ja     f01034a6 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103490:	0f be d2             	movsbl %dl,%edx
f0103493:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103496:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103499:	7d 0b                	jge    f01034a6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010349b:	83 c1 01             	add    $0x1,%ecx
f010349e:	0f af 45 10          	imul   0x10(%ebp),%eax
f01034a2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01034a4:	eb b9                	jmp    f010345f <strtol+0x76>

	if (endptr)
f01034a6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01034aa:	74 0d                	je     f01034b9 <strtol+0xd0>
		*endptr = (char *) s;
f01034ac:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034af:	89 0e                	mov    %ecx,(%esi)
f01034b1:	eb 06                	jmp    f01034b9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01034b3:	85 db                	test   %ebx,%ebx
f01034b5:	74 98                	je     f010344f <strtol+0x66>
f01034b7:	eb 9e                	jmp    f0103457 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01034b9:	89 c2                	mov    %eax,%edx
f01034bb:	f7 da                	neg    %edx
f01034bd:	85 ff                	test   %edi,%edi
f01034bf:	0f 45 c2             	cmovne %edx,%eax
}
f01034c2:	5b                   	pop    %ebx
f01034c3:	5e                   	pop    %esi
f01034c4:	5f                   	pop    %edi
f01034c5:	5d                   	pop    %ebp
f01034c6:	c3                   	ret    
f01034c7:	66 90                	xchg   %ax,%ax
f01034c9:	66 90                	xchg   %ax,%ax
f01034cb:	66 90                	xchg   %ax,%ax
f01034cd:	66 90                	xchg   %ax,%ax
f01034cf:	90                   	nop

f01034d0 <__udivdi3>:
f01034d0:	55                   	push   %ebp
f01034d1:	57                   	push   %edi
f01034d2:	56                   	push   %esi
f01034d3:	53                   	push   %ebx
f01034d4:	83 ec 1c             	sub    $0x1c,%esp
f01034d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01034db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01034df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01034e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034e7:	85 f6                	test   %esi,%esi
f01034e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034ed:	89 ca                	mov    %ecx,%edx
f01034ef:	89 f8                	mov    %edi,%eax
f01034f1:	75 3d                	jne    f0103530 <__udivdi3+0x60>
f01034f3:	39 cf                	cmp    %ecx,%edi
f01034f5:	0f 87 c5 00 00 00    	ja     f01035c0 <__udivdi3+0xf0>
f01034fb:	85 ff                	test   %edi,%edi
f01034fd:	89 fd                	mov    %edi,%ebp
f01034ff:	75 0b                	jne    f010350c <__udivdi3+0x3c>
f0103501:	b8 01 00 00 00       	mov    $0x1,%eax
f0103506:	31 d2                	xor    %edx,%edx
f0103508:	f7 f7                	div    %edi
f010350a:	89 c5                	mov    %eax,%ebp
f010350c:	89 c8                	mov    %ecx,%eax
f010350e:	31 d2                	xor    %edx,%edx
f0103510:	f7 f5                	div    %ebp
f0103512:	89 c1                	mov    %eax,%ecx
f0103514:	89 d8                	mov    %ebx,%eax
f0103516:	89 cf                	mov    %ecx,%edi
f0103518:	f7 f5                	div    %ebp
f010351a:	89 c3                	mov    %eax,%ebx
f010351c:	89 d8                	mov    %ebx,%eax
f010351e:	89 fa                	mov    %edi,%edx
f0103520:	83 c4 1c             	add    $0x1c,%esp
f0103523:	5b                   	pop    %ebx
f0103524:	5e                   	pop    %esi
f0103525:	5f                   	pop    %edi
f0103526:	5d                   	pop    %ebp
f0103527:	c3                   	ret    
f0103528:	90                   	nop
f0103529:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103530:	39 ce                	cmp    %ecx,%esi
f0103532:	77 74                	ja     f01035a8 <__udivdi3+0xd8>
f0103534:	0f bd fe             	bsr    %esi,%edi
f0103537:	83 f7 1f             	xor    $0x1f,%edi
f010353a:	0f 84 98 00 00 00    	je     f01035d8 <__udivdi3+0x108>
f0103540:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103545:	89 f9                	mov    %edi,%ecx
f0103547:	89 c5                	mov    %eax,%ebp
f0103549:	29 fb                	sub    %edi,%ebx
f010354b:	d3 e6                	shl    %cl,%esi
f010354d:	89 d9                	mov    %ebx,%ecx
f010354f:	d3 ed                	shr    %cl,%ebp
f0103551:	89 f9                	mov    %edi,%ecx
f0103553:	d3 e0                	shl    %cl,%eax
f0103555:	09 ee                	or     %ebp,%esi
f0103557:	89 d9                	mov    %ebx,%ecx
f0103559:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010355d:	89 d5                	mov    %edx,%ebp
f010355f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103563:	d3 ed                	shr    %cl,%ebp
f0103565:	89 f9                	mov    %edi,%ecx
f0103567:	d3 e2                	shl    %cl,%edx
f0103569:	89 d9                	mov    %ebx,%ecx
f010356b:	d3 e8                	shr    %cl,%eax
f010356d:	09 c2                	or     %eax,%edx
f010356f:	89 d0                	mov    %edx,%eax
f0103571:	89 ea                	mov    %ebp,%edx
f0103573:	f7 f6                	div    %esi
f0103575:	89 d5                	mov    %edx,%ebp
f0103577:	89 c3                	mov    %eax,%ebx
f0103579:	f7 64 24 0c          	mull   0xc(%esp)
f010357d:	39 d5                	cmp    %edx,%ebp
f010357f:	72 10                	jb     f0103591 <__udivdi3+0xc1>
f0103581:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103585:	89 f9                	mov    %edi,%ecx
f0103587:	d3 e6                	shl    %cl,%esi
f0103589:	39 c6                	cmp    %eax,%esi
f010358b:	73 07                	jae    f0103594 <__udivdi3+0xc4>
f010358d:	39 d5                	cmp    %edx,%ebp
f010358f:	75 03                	jne    f0103594 <__udivdi3+0xc4>
f0103591:	83 eb 01             	sub    $0x1,%ebx
f0103594:	31 ff                	xor    %edi,%edi
f0103596:	89 d8                	mov    %ebx,%eax
f0103598:	89 fa                	mov    %edi,%edx
f010359a:	83 c4 1c             	add    $0x1c,%esp
f010359d:	5b                   	pop    %ebx
f010359e:	5e                   	pop    %esi
f010359f:	5f                   	pop    %edi
f01035a0:	5d                   	pop    %ebp
f01035a1:	c3                   	ret    
f01035a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035a8:	31 ff                	xor    %edi,%edi
f01035aa:	31 db                	xor    %ebx,%ebx
f01035ac:	89 d8                	mov    %ebx,%eax
f01035ae:	89 fa                	mov    %edi,%edx
f01035b0:	83 c4 1c             	add    $0x1c,%esp
f01035b3:	5b                   	pop    %ebx
f01035b4:	5e                   	pop    %esi
f01035b5:	5f                   	pop    %edi
f01035b6:	5d                   	pop    %ebp
f01035b7:	c3                   	ret    
f01035b8:	90                   	nop
f01035b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035c0:	89 d8                	mov    %ebx,%eax
f01035c2:	f7 f7                	div    %edi
f01035c4:	31 ff                	xor    %edi,%edi
f01035c6:	89 c3                	mov    %eax,%ebx
f01035c8:	89 d8                	mov    %ebx,%eax
f01035ca:	89 fa                	mov    %edi,%edx
f01035cc:	83 c4 1c             	add    $0x1c,%esp
f01035cf:	5b                   	pop    %ebx
f01035d0:	5e                   	pop    %esi
f01035d1:	5f                   	pop    %edi
f01035d2:	5d                   	pop    %ebp
f01035d3:	c3                   	ret    
f01035d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035d8:	39 ce                	cmp    %ecx,%esi
f01035da:	72 0c                	jb     f01035e8 <__udivdi3+0x118>
f01035dc:	31 db                	xor    %ebx,%ebx
f01035de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01035e2:	0f 87 34 ff ff ff    	ja     f010351c <__udivdi3+0x4c>
f01035e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01035ed:	e9 2a ff ff ff       	jmp    f010351c <__udivdi3+0x4c>
f01035f2:	66 90                	xchg   %ax,%ax
f01035f4:	66 90                	xchg   %ax,%ax
f01035f6:	66 90                	xchg   %ax,%ax
f01035f8:	66 90                	xchg   %ax,%ax
f01035fa:	66 90                	xchg   %ax,%ax
f01035fc:	66 90                	xchg   %ax,%ax
f01035fe:	66 90                	xchg   %ax,%ax

f0103600 <__umoddi3>:
f0103600:	55                   	push   %ebp
f0103601:	57                   	push   %edi
f0103602:	56                   	push   %esi
f0103603:	53                   	push   %ebx
f0103604:	83 ec 1c             	sub    $0x1c,%esp
f0103607:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010360b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010360f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103613:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103617:	85 d2                	test   %edx,%edx
f0103619:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010361d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103621:	89 f3                	mov    %esi,%ebx
f0103623:	89 3c 24             	mov    %edi,(%esp)
f0103626:	89 74 24 04          	mov    %esi,0x4(%esp)
f010362a:	75 1c                	jne    f0103648 <__umoddi3+0x48>
f010362c:	39 f7                	cmp    %esi,%edi
f010362e:	76 50                	jbe    f0103680 <__umoddi3+0x80>
f0103630:	89 c8                	mov    %ecx,%eax
f0103632:	89 f2                	mov    %esi,%edx
f0103634:	f7 f7                	div    %edi
f0103636:	89 d0                	mov    %edx,%eax
f0103638:	31 d2                	xor    %edx,%edx
f010363a:	83 c4 1c             	add    $0x1c,%esp
f010363d:	5b                   	pop    %ebx
f010363e:	5e                   	pop    %esi
f010363f:	5f                   	pop    %edi
f0103640:	5d                   	pop    %ebp
f0103641:	c3                   	ret    
f0103642:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103648:	39 f2                	cmp    %esi,%edx
f010364a:	89 d0                	mov    %edx,%eax
f010364c:	77 52                	ja     f01036a0 <__umoddi3+0xa0>
f010364e:	0f bd ea             	bsr    %edx,%ebp
f0103651:	83 f5 1f             	xor    $0x1f,%ebp
f0103654:	75 5a                	jne    f01036b0 <__umoddi3+0xb0>
f0103656:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010365a:	0f 82 e0 00 00 00    	jb     f0103740 <__umoddi3+0x140>
f0103660:	39 0c 24             	cmp    %ecx,(%esp)
f0103663:	0f 86 d7 00 00 00    	jbe    f0103740 <__umoddi3+0x140>
f0103669:	8b 44 24 08          	mov    0x8(%esp),%eax
f010366d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103671:	83 c4 1c             	add    $0x1c,%esp
f0103674:	5b                   	pop    %ebx
f0103675:	5e                   	pop    %esi
f0103676:	5f                   	pop    %edi
f0103677:	5d                   	pop    %ebp
f0103678:	c3                   	ret    
f0103679:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103680:	85 ff                	test   %edi,%edi
f0103682:	89 fd                	mov    %edi,%ebp
f0103684:	75 0b                	jne    f0103691 <__umoddi3+0x91>
f0103686:	b8 01 00 00 00       	mov    $0x1,%eax
f010368b:	31 d2                	xor    %edx,%edx
f010368d:	f7 f7                	div    %edi
f010368f:	89 c5                	mov    %eax,%ebp
f0103691:	89 f0                	mov    %esi,%eax
f0103693:	31 d2                	xor    %edx,%edx
f0103695:	f7 f5                	div    %ebp
f0103697:	89 c8                	mov    %ecx,%eax
f0103699:	f7 f5                	div    %ebp
f010369b:	89 d0                	mov    %edx,%eax
f010369d:	eb 99                	jmp    f0103638 <__umoddi3+0x38>
f010369f:	90                   	nop
f01036a0:	89 c8                	mov    %ecx,%eax
f01036a2:	89 f2                	mov    %esi,%edx
f01036a4:	83 c4 1c             	add    $0x1c,%esp
f01036a7:	5b                   	pop    %ebx
f01036a8:	5e                   	pop    %esi
f01036a9:	5f                   	pop    %edi
f01036aa:	5d                   	pop    %ebp
f01036ab:	c3                   	ret    
f01036ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01036b0:	8b 34 24             	mov    (%esp),%esi
f01036b3:	bf 20 00 00 00       	mov    $0x20,%edi
f01036b8:	89 e9                	mov    %ebp,%ecx
f01036ba:	29 ef                	sub    %ebp,%edi
f01036bc:	d3 e0                	shl    %cl,%eax
f01036be:	89 f9                	mov    %edi,%ecx
f01036c0:	89 f2                	mov    %esi,%edx
f01036c2:	d3 ea                	shr    %cl,%edx
f01036c4:	89 e9                	mov    %ebp,%ecx
f01036c6:	09 c2                	or     %eax,%edx
f01036c8:	89 d8                	mov    %ebx,%eax
f01036ca:	89 14 24             	mov    %edx,(%esp)
f01036cd:	89 f2                	mov    %esi,%edx
f01036cf:	d3 e2                	shl    %cl,%edx
f01036d1:	89 f9                	mov    %edi,%ecx
f01036d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01036db:	d3 e8                	shr    %cl,%eax
f01036dd:	89 e9                	mov    %ebp,%ecx
f01036df:	89 c6                	mov    %eax,%esi
f01036e1:	d3 e3                	shl    %cl,%ebx
f01036e3:	89 f9                	mov    %edi,%ecx
f01036e5:	89 d0                	mov    %edx,%eax
f01036e7:	d3 e8                	shr    %cl,%eax
f01036e9:	89 e9                	mov    %ebp,%ecx
f01036eb:	09 d8                	or     %ebx,%eax
f01036ed:	89 d3                	mov    %edx,%ebx
f01036ef:	89 f2                	mov    %esi,%edx
f01036f1:	f7 34 24             	divl   (%esp)
f01036f4:	89 d6                	mov    %edx,%esi
f01036f6:	d3 e3                	shl    %cl,%ebx
f01036f8:	f7 64 24 04          	mull   0x4(%esp)
f01036fc:	39 d6                	cmp    %edx,%esi
f01036fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103702:	89 d1                	mov    %edx,%ecx
f0103704:	89 c3                	mov    %eax,%ebx
f0103706:	72 08                	jb     f0103710 <__umoddi3+0x110>
f0103708:	75 11                	jne    f010371b <__umoddi3+0x11b>
f010370a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010370e:	73 0b                	jae    f010371b <__umoddi3+0x11b>
f0103710:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103714:	1b 14 24             	sbb    (%esp),%edx
f0103717:	89 d1                	mov    %edx,%ecx
f0103719:	89 c3                	mov    %eax,%ebx
f010371b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010371f:	29 da                	sub    %ebx,%edx
f0103721:	19 ce                	sbb    %ecx,%esi
f0103723:	89 f9                	mov    %edi,%ecx
f0103725:	89 f0                	mov    %esi,%eax
f0103727:	d3 e0                	shl    %cl,%eax
f0103729:	89 e9                	mov    %ebp,%ecx
f010372b:	d3 ea                	shr    %cl,%edx
f010372d:	89 e9                	mov    %ebp,%ecx
f010372f:	d3 ee                	shr    %cl,%esi
f0103731:	09 d0                	or     %edx,%eax
f0103733:	89 f2                	mov    %esi,%edx
f0103735:	83 c4 1c             	add    $0x1c,%esp
f0103738:	5b                   	pop    %ebx
f0103739:	5e                   	pop    %esi
f010373a:	5f                   	pop    %edi
f010373b:	5d                   	pop    %ebp
f010373c:	c3                   	ret    
f010373d:	8d 76 00             	lea    0x0(%esi),%esi
f0103740:	29 f9                	sub    %edi,%ecx
f0103742:	19 d6                	sbb    %edx,%esi
f0103744:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103748:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010374c:	e9 18 ff ff ff       	jmp    f0103669 <__umoddi3+0x69>
