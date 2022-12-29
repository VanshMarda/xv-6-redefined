
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b2013103          	ld	sp,-1248(sp) # 80008b20 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	8bc78793          	addi	a5,a5,-1860 # 80006920 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	9dc080e7          	jalr	-1572(ra) # 80002b08 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7f4080e7          	jalr	2036(ra) # 800019b8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	52e080e7          	jalr	1326(ra) # 80002702 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00003097          	auipc	ra,0x3
    80000214:	8a2080e7          	jalr	-1886(ra) # 80002ab2 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	86c080e7          	jalr	-1940(ra) # 80002b5e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	448080e7          	jalr	1096(ra) # 8000288e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	cf078793          	addi	a5,a5,-784 # 80023168 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	fee080e7          	jalr	-18(ra) # 8000288e <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	dd6080e7          	jalr	-554(ra) # 80002702 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00027797          	auipc	a5,0x27
    80000a10:	5f478793          	addi	a5,a5,1524 # 80028000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00027517          	auipc	a0,0x27
    80000ae0:	52450513          	addi	a0,a0,1316 # 80028000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e1e080e7          	jalr	-482(ra) # 8000199c <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	dec080e7          	jalr	-532(ra) # 8000199c <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	de0080e7          	jalr	-544(ra) # 8000199c <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc8080e7          	jalr	-568(ra) # 8000199c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d88080e7          	jalr	-632(ra) # 8000199c <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d5c080e7          	jalr	-676(ra) # 8000199c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	af6080e7          	jalr	-1290(ra) # 8000198c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ada080e7          	jalr	-1318(ra) # 8000198c <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	26a080e7          	jalr	618(ra) # 8000313e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	a84080e7          	jalr	-1404(ra) # 80006960 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	682080e7          	jalr	1666(ra) # 80002566 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	32a080e7          	jalr	810(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	070080e7          	jalr	112(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	998080e7          	jalr	-1640(ra) # 800018dc <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	1ca080e7          	jalr	458(ra) # 80003116 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	1ea080e7          	jalr	490(ra) # 8000313e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00006097          	auipc	ra,0x6
    80000f60:	9ee080e7          	jalr	-1554(ra) # 8000694a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00006097          	auipc	ra,0x6
    80000f68:	9fc080e7          	jalr	-1540(ra) # 80006960 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	bda080e7          	jalr	-1062(ra) # 80003b46 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	26a080e7          	jalr	618(ra) # 800041de <iinit>
    queuetableinit();// Initializes the queues for the MLFQ scheduler
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	fa4080e7          	jalr	-92(ra) # 80001f20 <queuetableinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	20c080e7          	jalr	524(ra) # 80005190 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00006097          	auipc	ra,0x6
    80000f90:	af6080e7          	jalr	-1290(ra) # 80006a82 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d52080e7          	jalr	-686(ra) # 80001ce6 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	5fe080e7          	jalr	1534(ra) # 80001846 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001846:	7139                	addi	sp,sp,-64
    80001848:	fc06                	sd	ra,56(sp)
    8000184a:	f822                	sd	s0,48(sp)
    8000184c:	f426                	sd	s1,40(sp)
    8000184e:	f04a                	sd	s2,32(sp)
    80001850:	ec4e                	sd	s3,24(sp)
    80001852:	e852                	sd	s4,16(sp)
    80001854:	e456                	sd	s5,8(sp)
    80001856:	e05a                	sd	s6,0(sp)
    80001858:	0080                	addi	s0,sp,64
    8000185a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00010497          	auipc	s1,0x10
    80001860:	e7448493          	addi	s1,s1,-396 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	00017a17          	auipc	s4,0x17
    8000187a:	c5aa0a13          	addi	s4,s4,-934 # 800184d0 <queuetable>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if(pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	858d                	srai	a1,a1,0x3
    80001890:	000ab783          	ld	a5,0(s5)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	854e                	mv	a0,s3
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8b0080e7          	jalr	-1872(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	1b848493          	addi	s1,s1,440
    800018b4:	fd4495e3          	bne	s1,s4,8000187e <proc_mapstacks+0x38>
  }
}
    800018b8:	70e2                	ld	ra,56(sp)
    800018ba:	7442                	ld	s0,48(sp)
    800018bc:	74a2                	ld	s1,40(sp)
    800018be:	7902                	ld	s2,32(sp)
    800018c0:	69e2                	ld	s3,24(sp)
    800018c2:	6a42                	ld	s4,16(sp)
    800018c4:	6aa2                	ld	s5,8(sp)
    800018c6:	6b02                	ld	s6,0(sp)
    800018c8:	6121                	addi	sp,sp,64
    800018ca:	8082                	ret
      panic("kalloc");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	90c50513          	addi	a0,a0,-1780 # 800081d8 <digits+0x198>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018dc:	7139                	addi	sp,sp,-64
    800018de:	fc06                	sd	ra,56(sp)
    800018e0:	f822                	sd	s0,48(sp)
    800018e2:	f426                	sd	s1,40(sp)
    800018e4:	f04a                	sd	s2,32(sp)
    800018e6:	ec4e                	sd	s3,24(sp)
    800018e8:	e852                	sd	s4,16(sp)
    800018ea:	e456                	sd	s5,8(sp)
    800018ec:	e05a                	sd	s6,0(sp)
    800018ee:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018f0:	00007597          	auipc	a1,0x7
    800018f4:	8f058593          	addi	a1,a1,-1808 # 800081e0 <digits+0x1a0>
    800018f8:	00010517          	auipc	a0,0x10
    800018fc:	9a850513          	addi	a0,a0,-1624 # 800112a0 <pid_lock>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	254080e7          	jalr	596(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8e058593          	addi	a1,a1,-1824 # 800081e8 <digits+0x1a8>
    80001910:	00010517          	auipc	a0,0x10
    80001914:	9a850513          	addi	a0,a0,-1624 # 800112b8 <wait_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00010497          	auipc	s1,0x10
    80001924:	db048493          	addi	s1,s1,-592 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001928:	00007b17          	auipc	s6,0x7
    8000192c:	8d0b0b13          	addi	s6,s6,-1840 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001930:	8aa6                	mv	s5,s1
    80001932:	00006a17          	auipc	s4,0x6
    80001936:	6cea0a13          	addi	s4,s4,1742 # 80008000 <etext>
    8000193a:	04000937          	lui	s2,0x4000
    8000193e:	197d                	addi	s2,s2,-1
    80001940:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001942:	00017997          	auipc	s3,0x17
    80001946:	b8e98993          	addi	s3,s3,-1138 # 800184d0 <queuetable>
      initlock(&p->lock, "proc");
    8000194a:	85da                	mv	a1,s6
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	206080e7          	jalr	518(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001956:	415487b3          	sub	a5,s1,s5
    8000195a:	878d                	srai	a5,a5,0x3
    8000195c:	000a3703          	ld	a4,0(s4)
    80001960:	02e787b3          	mul	a5,a5,a4
    80001964:	2785                	addiw	a5,a5,1
    80001966:	00d7979b          	slliw	a5,a5,0xd
    8000196a:	40f907b3          	sub	a5,s2,a5
    8000196e:	ecbc                	sd	a5,88(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	1b848493          	addi	s1,s1,440
    80001974:	fd349be3          	bne	s1,s3,8000194a <procinit+0x6e>
  }
}
    80001978:	70e2                	ld	ra,56(sp)
    8000197a:	7442                	ld	s0,48(sp)
    8000197c:	74a2                	ld	s1,40(sp)
    8000197e:	7902                	ld	s2,32(sp)
    80001980:	69e2                	ld	s3,24(sp)
    80001982:	6a42                	ld	s4,16(sp)
    80001984:	6aa2                	ld	s5,8(sp)
    80001986:	6b02                	ld	s6,0(sp)
    80001988:	6121                	addi	sp,sp,64
    8000198a:	8082                	ret

000000008000198c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000198c:	1141                	addi	sp,sp,-16
    8000198e:	e422                	sd	s0,8(sp)
    80001990:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001992:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001994:	2501                	sext.w	a0,a0
    80001996:	6422                	ld	s0,8(sp)
    80001998:	0141                	addi	sp,sp,16
    8000199a:	8082                	ret

000000008000199c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
    800019a2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a4:	2781                	sext.w	a5,a5
    800019a6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a8:	00010517          	auipc	a0,0x10
    800019ac:	92850513          	addi	a0,a0,-1752 # 800112d0 <cpus>
    800019b0:	953e                	add	a0,a0,a5
    800019b2:	6422                	ld	s0,8(sp)
    800019b4:	0141                	addi	sp,sp,16
    800019b6:	8082                	ret

00000000800019b8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b8:	1101                	addi	sp,sp,-32
    800019ba:	ec06                	sd	ra,24(sp)
    800019bc:	e822                	sd	s0,16(sp)
    800019be:	e426                	sd	s1,8(sp)
    800019c0:	1000                	addi	s0,sp,32
  push_off();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	1d6080e7          	jalr	470(ra) # 80000b98 <push_off>
    800019ca:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019cc:	2781                	sext.w	a5,a5
    800019ce:	079e                	slli	a5,a5,0x7
    800019d0:	00010717          	auipc	a4,0x10
    800019d4:	8d070713          	addi	a4,a4,-1840 # 800112a0 <pid_lock>
    800019d8:	97ba                	add	a5,a5,a4
    800019da:	7b84                	ld	s1,48(a5)
  pop_off();
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	25c080e7          	jalr	604(ra) # 80000c38 <pop_off>
  return p;
}
    800019e4:	8526                	mv	a0,s1
    800019e6:	60e2                	ld	ra,24(sp)
    800019e8:	6442                	ld	s0,16(sp)
    800019ea:	64a2                	ld	s1,8(sp)
    800019ec:	6105                	addi	sp,sp,32
    800019ee:	8082                	ret

00000000800019f0 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019f0:	1141                	addi	sp,sp,-16
    800019f2:	e406                	sd	ra,8(sp)
    800019f4:	e022                	sd	s0,0(sp)
    800019f6:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f8:	00000097          	auipc	ra,0x0
    800019fc:	fc0080e7          	jalr	-64(ra) # 800019b8 <myproc>
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	298080e7          	jalr	664(ra) # 80000c98 <release>

  if (first) {
    80001a08:	00007797          	auipc	a5,0x7
    80001a0c:	fa87a783          	lw	a5,-88(a5) # 800089b0 <first.1808>
    80001a10:	eb89                	bnez	a5,80001a22 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a12:	00001097          	auipc	ra,0x1
    80001a16:	744080e7          	jalr	1860(ra) # 80003156 <usertrapret>
}
    80001a1a:	60a2                	ld	ra,8(sp)
    80001a1c:	6402                	ld	s0,0(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret
    first = 0;
    80001a22:	00007797          	auipc	a5,0x7
    80001a26:	f807a723          	sw	zero,-114(a5) # 800089b0 <first.1808>
    fsinit(ROOTDEV);
    80001a2a:	4505                	li	a0,1
    80001a2c:	00002097          	auipc	ra,0x2
    80001a30:	732080e7          	jalr	1842(ra) # 8000415e <fsinit>
    80001a34:	bff9                	j	80001a12 <forkret+0x22>

0000000080001a36 <allocpid>:
allocpid() {
    80001a36:	1101                	addi	sp,sp,-32
    80001a38:	ec06                	sd	ra,24(sp)
    80001a3a:	e822                	sd	s0,16(sp)
    80001a3c:	e426                	sd	s1,8(sp)
    80001a3e:	e04a                	sd	s2,0(sp)
    80001a40:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a42:	00010917          	auipc	s2,0x10
    80001a46:	85e90913          	addi	s2,s2,-1954 # 800112a0 <pid_lock>
    80001a4a:	854a                	mv	a0,s2
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	198080e7          	jalr	408(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a54:	00007797          	auipc	a5,0x7
    80001a58:	f6078793          	addi	a5,a5,-160 # 800089b4 <nextpid>
    80001a5c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5e:	0014871b          	addiw	a4,s1,1
    80001a62:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a64:	854a                	mv	a0,s2
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	232080e7          	jalr	562(ra) # 80000c98 <release>
}
    80001a6e:	8526                	mv	a0,s1
    80001a70:	60e2                	ld	ra,24(sp)
    80001a72:	6442                	ld	s0,16(sp)
    80001a74:	64a2                	ld	s1,8(sp)
    80001a76:	6902                	ld	s2,0(sp)
    80001a78:	6105                	addi	sp,sp,32
    80001a7a:	8082                	ret

0000000080001a7c <proc_pagetable>:
{
    80001a7c:	1101                	addi	sp,sp,-32
    80001a7e:	ec06                	sd	ra,24(sp)
    80001a80:	e822                	sd	s0,16(sp)
    80001a82:	e426                	sd	s1,8(sp)
    80001a84:	e04a                	sd	s2,0(sp)
    80001a86:	1000                	addi	s0,sp,32
    80001a88:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	8b8080e7          	jalr	-1864(ra) # 80001342 <uvmcreate>
    80001a92:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a94:	c121                	beqz	a0,80001ad4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a96:	4729                	li	a4,10
    80001a98:	00005697          	auipc	a3,0x5
    80001a9c:	56868693          	addi	a3,a3,1384 # 80007000 <_trampoline>
    80001aa0:	6605                	lui	a2,0x1
    80001aa2:	040005b7          	lui	a1,0x4000
    80001aa6:	15fd                	addi	a1,a1,-1
    80001aa8:	05b2                	slli	a1,a1,0xc
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	60e080e7          	jalr	1550(ra) # 800010b8 <mappages>
    80001ab2:	02054863          	bltz	a0,80001ae2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab6:	4719                	li	a4,6
    80001ab8:	07893683          	ld	a3,120(s2)
    80001abc:	6605                	lui	a2,0x1
    80001abe:	020005b7          	lui	a1,0x2000
    80001ac2:	15fd                	addi	a1,a1,-1
    80001ac4:	05b6                	slli	a1,a1,0xd
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	5f0080e7          	jalr	1520(ra) # 800010b8 <mappages>
    80001ad0:	02054163          	bltz	a0,80001af2 <proc_pagetable+0x76>
}
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	60e2                	ld	ra,24(sp)
    80001ad8:	6442                	ld	s0,16(sp)
    80001ada:	64a2                	ld	s1,8(sp)
    80001adc:	6902                	ld	s2,0(sp)
    80001ade:	6105                	addi	sp,sp,32
    80001ae0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae2:	4581                	li	a1,0
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	00000097          	auipc	ra,0x0
    80001aea:	a58080e7          	jalr	-1448(ra) # 8000153e <uvmfree>
    return 0;
    80001aee:	4481                	li	s1,0
    80001af0:	b7d5                	j	80001ad4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af2:	4681                	li	a3,0
    80001af4:	4605                	li	a2,1
    80001af6:	040005b7          	lui	a1,0x4000
    80001afa:	15fd                	addi	a1,a1,-1
    80001afc:	05b2                	slli	a1,a1,0xc
    80001afe:	8526                	mv	a0,s1
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	77e080e7          	jalr	1918(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b08:	4581                	li	a1,0
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	a32080e7          	jalr	-1486(ra) # 8000153e <uvmfree>
    return 0;
    80001b14:	4481                	li	s1,0
    80001b16:	bf7d                	j	80001ad4 <proc_pagetable+0x58>

0000000080001b18 <proc_freepagetable>:
{
    80001b18:	1101                	addi	sp,sp,-32
    80001b1a:	ec06                	sd	ra,24(sp)
    80001b1c:	e822                	sd	s0,16(sp)
    80001b1e:	e426                	sd	s1,8(sp)
    80001b20:	e04a                	sd	s2,0(sp)
    80001b22:	1000                	addi	s0,sp,32
    80001b24:	84aa                	mv	s1,a0
    80001b26:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b28:	4681                	li	a3,0
    80001b2a:	4605                	li	a2,1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	74a080e7          	jalr	1866(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	020005b7          	lui	a1,0x2000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b6                	slli	a1,a1,0xd
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	734080e7          	jalr	1844(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b52:	85ca                	mv	a1,s2
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	9e8080e7          	jalr	-1560(ra) # 8000153e <uvmfree>
}
    80001b5e:	60e2                	ld	ra,24(sp)
    80001b60:	6442                	ld	s0,16(sp)
    80001b62:	64a2                	ld	s1,8(sp)
    80001b64:	6902                	ld	s2,0(sp)
    80001b66:	6105                	addi	sp,sp,32
    80001b68:	8082                	ret

0000000080001b6a <freeproc>:
{
    80001b6a:	1101                	addi	sp,sp,-32
    80001b6c:	ec06                	sd	ra,24(sp)
    80001b6e:	e822                	sd	s0,16(sp)
    80001b70:	e426                	sd	s1,8(sp)
    80001b72:	1000                	addi	s0,sp,32
    80001b74:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b76:	7d28                	ld	a0,120(a0)
    80001b78:	c509                	beqz	a0,80001b82 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	e7e080e7          	jalr	-386(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b82:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001b86:	78a8                	ld	a0,112(s1)
    80001b88:	c511                	beqz	a0,80001b94 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b8a:	70ac                	ld	a1,96(s1)
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	f8c080e7          	jalr	-116(ra) # 80001b18 <proc_freepagetable>
  p->pagetable = 0;
    80001b94:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001b98:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001b9c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba0:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001ba4:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001ba8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bac:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb4:	0004ac23          	sw	zero,24(s1)
}
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6105                	addi	sp,sp,32
    80001bc0:	8082                	ret

0000000080001bc2 <allocproc>:
{
    80001bc2:	1101                	addi	sp,sp,-32
    80001bc4:	ec06                	sd	ra,24(sp)
    80001bc6:	e822                	sd	s0,16(sp)
    80001bc8:	e426                	sd	s1,8(sp)
    80001bca:	e04a                	sd	s2,0(sp)
    80001bcc:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bce:	00010497          	auipc	s1,0x10
    80001bd2:	b0248493          	addi	s1,s1,-1278 # 800116d0 <proc>
    80001bd6:	00017917          	auipc	s2,0x17
    80001bda:	8fa90913          	addi	s2,s2,-1798 # 800184d0 <queuetable>
    acquire(&p->lock);
    80001bde:	8526                	mv	a0,s1
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	004080e7          	jalr	4(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be8:	4c9c                	lw	a5,24(s1)
    80001bea:	cf81                	beqz	a5,80001c02 <allocproc+0x40>
      release(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	0aa080e7          	jalr	170(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf6:	1b848493          	addi	s1,s1,440
    80001bfa:	ff2492e3          	bne	s1,s2,80001bde <allocproc+0x1c>
  return 0;
    80001bfe:	4481                	li	s1,0
    80001c00:	a065                	j	80001ca8 <allocproc+0xe6>
  p->pid = allocpid();
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	e34080e7          	jalr	-460(ra) # 80001a36 <allocpid>
    80001c0a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c0c:	4785                	li	a5,1
    80001c0e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	ee4080e7          	jalr	-284(ra) # 80000af4 <kalloc>
    80001c18:	892a                	mv	s2,a0
    80001c1a:	fca8                	sd	a0,120(s1)
    80001c1c:	cd49                	beqz	a0,80001cb6 <allocproc+0xf4>
  p->pagetable = proc_pagetable(p);
    80001c1e:	8526                	mv	a0,s1
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e5c080e7          	jalr	-420(ra) # 80001a7c <proc_pagetable>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001c2c:	c14d                	beqz	a0,80001cce <allocproc+0x10c>
  memset(&p->context, 0, sizeof(p->context));
    80001c2e:	07000613          	li	a2,112
    80001c32:	4581                	li	a1,0
    80001c34:	08048513          	addi	a0,s1,128
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	0a8080e7          	jalr	168(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c40:	00000797          	auipc	a5,0x0
    80001c44:	db078793          	addi	a5,a5,-592 # 800019f0 <forkret>
    80001c48:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c4a:	6cbc                	ld	a5,88(s1)
    80001c4c:	6705                	lui	a4,0x1
    80001c4e:	97ba                	add	a5,a5,a4
    80001c50:	e4dc                	sd	a5,136(s1)
  p->createtime = ticks;
    80001c52:	00007797          	auipc	a5,0x7
    80001c56:	3e67a783          	lw	a5,998(a5) # 80009038 <ticks>
    80001c5a:	d4fc                	sw	a5,108(s1)
  p->staticpriority = 60;
    80001c5c:	03c00713          	li	a4,60
    80001c60:	d8d8                	sw	a4,52(s1)
  p->tracemask = 0;
    80001c62:	0604a423          	sw	zero,104(s1)
  p->scheduletick = 0;
    80001c66:	0204ac23          	sw	zero,56(s1)
  p->runningticks = 0;
    80001c6a:	0204ae23          	sw	zero,60(s1)
  p->sleepingticks = 0;
    80001c6e:	0404a023          	sw	zero,64(s1)
  p->schedulecount = 0;
    80001c72:	0404a423          	sw	zero,72(s1)
  p->totalrtime = 0;
    80001c76:	0404a223          	sw	zero,68(s1)
  p->queuelevel = 0;
    80001c7a:	1804a623          	sw	zero,396(s1)
  p->queuestate = NOTQUEUED;
    80001c7e:	4705                	li	a4,1
    80001c80:	18e4a423          	sw	a4,392(s1)
  p->queueentertime = 0;
    80001c84:	1804aa23          	sw	zero,404(s1)
  p->rtime = 0;
    80001c88:	1a04a623          	sw	zero,428(s1)
  p->etime = 0;
    80001c8c:	1a04aa23          	sw	zero,436(s1)
  p->ctime = ticks;
    80001c90:	1af4a823          	sw	a5,432(s1)
    p->q[i] = 0;
    80001c94:	1804ac23          	sw	zero,408(s1)
    80001c98:	1804ae23          	sw	zero,412(s1)
    80001c9c:	1a04a023          	sw	zero,416(s1)
    80001ca0:	1a04a223          	sw	zero,420(s1)
    80001ca4:	1a04a423          	sw	zero,424(s1)
}
    80001ca8:	8526                	mv	a0,s1
    80001caa:	60e2                	ld	ra,24(sp)
    80001cac:	6442                	ld	s0,16(sp)
    80001cae:	64a2                	ld	s1,8(sp)
    80001cb0:	6902                	ld	s2,0(sp)
    80001cb2:	6105                	addi	sp,sp,32
    80001cb4:	8082                	ret
    freeproc(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	eb2080e7          	jalr	-334(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	fd6080e7          	jalr	-42(ra) # 80000c98 <release>
    return 0;
    80001cca:	84ca                	mv	s1,s2
    80001ccc:	bff1                	j	80001ca8 <allocproc+0xe6>
    freeproc(p);
    80001cce:	8526                	mv	a0,s1
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	e9a080e7          	jalr	-358(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	fbe080e7          	jalr	-66(ra) # 80000c98 <release>
    return 0;
    80001ce2:	84ca                	mv	s1,s2
    80001ce4:	b7d1                	j	80001ca8 <allocproc+0xe6>

0000000080001ce6 <userinit>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	ed2080e7          	jalr	-302(ra) # 80001bc2 <allocproc>
    80001cf8:	84aa                	mv	s1,a0
  initproc = p;
    80001cfa:	00007797          	auipc	a5,0x7
    80001cfe:	32a7bb23          	sd	a0,822(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d02:	03400613          	li	a2,52
    80001d06:	00007597          	auipc	a1,0x7
    80001d0a:	cba58593          	addi	a1,a1,-838 # 800089c0 <initcode>
    80001d0e:	7928                	ld	a0,112(a0)
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	660080e7          	jalr	1632(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001d18:	6785                	lui	a5,0x1
    80001d1a:	f0bc                	sd	a5,96(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d1c:	7cb8                	ld	a4,120(s1)
    80001d1e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d22:	7cb8                	ld	a4,120(s1)
    80001d24:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d26:	4641                	li	a2,16
    80001d28:	00006597          	auipc	a1,0x6
    80001d2c:	4d858593          	addi	a1,a1,1240 # 80008200 <digits+0x1c0>
    80001d30:	17848513          	addi	a0,s1,376
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	0fe080e7          	jalr	254(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d3c:	00006517          	auipc	a0,0x6
    80001d40:	4d450513          	addi	a0,a0,1236 # 80008210 <digits+0x1d0>
    80001d44:	00003097          	auipc	ra,0x3
    80001d48:	e48080e7          	jalr	-440(ra) # 80004b8c <namei>
    80001d4c:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d50:	478d                	li	a5,3
    80001d52:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d54:	8526                	mv	a0,s1
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	f42080e7          	jalr	-190(ra) # 80000c98 <release>
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret

0000000080001d68 <growproc>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	e04a                	sd	s2,0(sp)
    80001d72:	1000                	addi	s0,sp,32
    80001d74:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	c42080e7          	jalr	-958(ra) # 800019b8 <myproc>
    80001d7e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d80:	712c                	ld	a1,96(a0)
    80001d82:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d86:	00904f63          	bgtz	s1,80001da4 <growproc+0x3c>
  } else if(n < 0){
    80001d8a:	0204cc63          	bltz	s1,80001dc2 <growproc+0x5a>
  p->sz = sz;
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	06c93023          	sd	a2,96(s2)
  return 0;
    80001d96:	4501                	li	a0,0
}
    80001d98:	60e2                	ld	ra,24(sp)
    80001d9a:	6442                	ld	s0,16(sp)
    80001d9c:	64a2                	ld	s1,8(sp)
    80001d9e:	6902                	ld	s2,0(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001da4:	9e25                	addw	a2,a2,s1
    80001da6:	1602                	slli	a2,a2,0x20
    80001da8:	9201                	srli	a2,a2,0x20
    80001daa:	1582                	slli	a1,a1,0x20
    80001dac:	9181                	srli	a1,a1,0x20
    80001dae:	7928                	ld	a0,112(a0)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	67a080e7          	jalr	1658(ra) # 8000142a <uvmalloc>
    80001db8:	0005061b          	sext.w	a2,a0
    80001dbc:	fa69                	bnez	a2,80001d8e <growproc+0x26>
      return -1;
    80001dbe:	557d                	li	a0,-1
    80001dc0:	bfe1                	j	80001d98 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dc2:	9e25                	addw	a2,a2,s1
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	1582                	slli	a1,a1,0x20
    80001dca:	9181                	srli	a1,a1,0x20
    80001dcc:	7928                	ld	a0,112(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	614080e7          	jalr	1556(ra) # 800013e2 <uvmdealloc>
    80001dd6:	0005061b          	sext.w	a2,a0
    80001dda:	bf55                	j	80001d8e <growproc+0x26>

0000000080001ddc <fork>:
{
    80001ddc:	7179                	addi	sp,sp,-48
    80001dde:	f406                	sd	ra,40(sp)
    80001de0:	f022                	sd	s0,32(sp)
    80001de2:	ec26                	sd	s1,24(sp)
    80001de4:	e84a                	sd	s2,16(sp)
    80001de6:	e44e                	sd	s3,8(sp)
    80001de8:	e052                	sd	s4,0(sp)
    80001dea:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	bcc080e7          	jalr	-1076(ra) # 800019b8 <myproc>
    80001df4:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	dcc080e7          	jalr	-564(ra) # 80001bc2 <allocproc>
    80001dfe:	10050f63          	beqz	a0,80001f1c <fork+0x140>
    80001e02:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e04:	06093603          	ld	a2,96(s2)
    80001e08:	792c                	ld	a1,112(a0)
    80001e0a:	07093503          	ld	a0,112(s2)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	768080e7          	jalr	1896(ra) # 80001576 <uvmcopy>
    80001e16:	04054a63          	bltz	a0,80001e6a <fork+0x8e>
  np->sz = p->sz;
    80001e1a:	06093783          	ld	a5,96(s2)
    80001e1e:	06f9b023          	sd	a5,96(s3)
  np->tracemask = p->tracemask;
    80001e22:	06892783          	lw	a5,104(s2)
    80001e26:	06f9a423          	sw	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e2a:	07893683          	ld	a3,120(s2)
    80001e2e:	87b6                	mv	a5,a3
    80001e30:	0789b703          	ld	a4,120(s3)
    80001e34:	12068693          	addi	a3,a3,288
    80001e38:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e3c:	6788                	ld	a0,8(a5)
    80001e3e:	6b8c                	ld	a1,16(a5)
    80001e40:	6f90                	ld	a2,24(a5)
    80001e42:	01073023          	sd	a6,0(a4)
    80001e46:	e708                	sd	a0,8(a4)
    80001e48:	eb0c                	sd	a1,16(a4)
    80001e4a:	ef10                	sd	a2,24(a4)
    80001e4c:	02078793          	addi	a5,a5,32
    80001e50:	02070713          	addi	a4,a4,32
    80001e54:	fed792e3          	bne	a5,a3,80001e38 <fork+0x5c>
  np->trapframe->a0 = 0;
    80001e58:	0789b783          	ld	a5,120(s3)
    80001e5c:	0607b823          	sd	zero,112(a5)
    80001e60:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80001e64:	17000a13          	li	s4,368
    80001e68:	a03d                	j	80001e96 <fork+0xba>
    freeproc(np);
    80001e6a:	854e                	mv	a0,s3
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	cfe080e7          	jalr	-770(ra) # 80001b6a <freeproc>
    release(&np->lock);
    80001e74:	854e                	mv	a0,s3
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
    return -1;
    80001e7e:	5a7d                	li	s4,-1
    80001e80:	a069                	j	80001f0a <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e82:	00003097          	auipc	ra,0x3
    80001e86:	3a0080e7          	jalr	928(ra) # 80005222 <filedup>
    80001e8a:	009987b3          	add	a5,s3,s1
    80001e8e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e90:	04a1                	addi	s1,s1,8
    80001e92:	01448763          	beq	s1,s4,80001ea0 <fork+0xc4>
    if(p->ofile[i])
    80001e96:	009907b3          	add	a5,s2,s1
    80001e9a:	6388                	ld	a0,0(a5)
    80001e9c:	f17d                	bnez	a0,80001e82 <fork+0xa6>
    80001e9e:	bfcd                	j	80001e90 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001ea0:	17093503          	ld	a0,368(s2)
    80001ea4:	00002097          	auipc	ra,0x2
    80001ea8:	4f4080e7          	jalr	1268(ra) # 80004398 <idup>
    80001eac:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eb0:	4641                	li	a2,16
    80001eb2:	17890593          	addi	a1,s2,376
    80001eb6:	17898513          	addi	a0,s3,376
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	f78080e7          	jalr	-136(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001ec2:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ec6:	854e                	mv	a0,s3
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dd0080e7          	jalr	-560(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ed0:	0000f497          	auipc	s1,0xf
    80001ed4:	3e848493          	addi	s1,s1,1000 # 800112b8 <wait_lock>
    80001ed8:	8526                	mv	a0,s1
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	d0a080e7          	jalr	-758(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ee2:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    80001ee6:	8526                	mv	a0,s1
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	db0080e7          	jalr	-592(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ef0:	854e                	mv	a0,s3
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	cf2080e7          	jalr	-782(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001efa:	478d                	li	a5,3
    80001efc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f00:	854e                	mv	a0,s3
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	d96080e7          	jalr	-618(ra) # 80000c98 <release>
}
    80001f0a:	8552                	mv	a0,s4
    80001f0c:	70a2                	ld	ra,40(sp)
    80001f0e:	7402                	ld	s0,32(sp)
    80001f10:	64e2                	ld	s1,24(sp)
    80001f12:	6942                	ld	s2,16(sp)
    80001f14:	69a2                	ld	s3,8(sp)
    80001f16:	6a02                	ld	s4,0(sp)
    80001f18:	6145                	addi	sp,sp,48
    80001f1a:	8082                	ret
    return -1;
    80001f1c:	5a7d                	li	s4,-1
    80001f1e:	b7f5                	j	80001f0a <fork+0x12e>

0000000080001f20 <queuetableinit>:
queuetableinit(void) {
    80001f20:	1141                	addi	sp,sp,-16
    80001f22:	e422                	sd	s0,8(sp)
    80001f24:	0800                	addi	s0,sp,16
    queuetable[i].front = 0;
    80001f26:	00016797          	auipc	a5,0x16
    80001f2a:	5aa78793          	addi	a5,a5,1450 # 800184d0 <queuetable>
    80001f2e:	0007a023          	sw	zero,0(a5)
    queuetable[i].back = 0;
    80001f32:	0007a223          	sw	zero,4(a5)
    queuetable[i].front = 0;
    80001f36:	2007a823          	sw	zero,528(a5)
    queuetable[i].back = 0;
    80001f3a:	2007aa23          	sw	zero,532(a5)
    queuetable[i].front = 0;
    80001f3e:	4207a023          	sw	zero,1056(a5)
    queuetable[i].back = 0;
    80001f42:	4207a223          	sw	zero,1060(a5)
    queuetable[i].front = 0;
    80001f46:	6207a823          	sw	zero,1584(a5)
    queuetable[i].back = 0;
    80001f4a:	6207aa23          	sw	zero,1588(a5)
    queuetable[i].front = 0;
    80001f4e:	00017797          	auipc	a5,0x17
    80001f52:	58278793          	addi	a5,a5,1410 # 800194d0 <bcache+0x598>
    80001f56:	8407a023          	sw	zero,-1984(a5)
    queuetable[i].back = 0;
    80001f5a:	8407a223          	sw	zero,-1980(a5)
}
    80001f5e:	6422                	ld	s0,8(sp)
    80001f60:	0141                	addi	sp,sp,16
    80001f62:	8082                	ret

0000000080001f64 <updatetime>:
updatetime() {
    80001f64:	7139                	addi	sp,sp,-64
    80001f66:	fc06                	sd	ra,56(sp)
    80001f68:	f822                	sd	s0,48(sp)
    80001f6a:	f426                	sd	s1,40(sp)
    80001f6c:	f04a                	sd	s2,32(sp)
    80001f6e:	ec4e                	sd	s3,24(sp)
    80001f70:	e852                	sd	s4,16(sp)
    80001f72:	e456                	sd	s5,8(sp)
    80001f74:	e05a                	sd	s6,0(sp)
    80001f76:	0080                	addi	s0,sp,64
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f78:	0000f497          	auipc	s1,0xf
    80001f7c:	75848493          	addi	s1,s1,1880 # 800116d0 <proc>
    if (p->state == RUNNING) {
    80001f80:	4a91                	li	s5,4
    if (p->state == SLEEPING)
    80001f82:	4b09                	li	s6,2
    if (schedulingpolicy == 3 && p->queuestate == QUEUED) {
    80001f84:	00007a17          	auipc	s4,0x7
    80001f88:	0a4a0a13          	addi	s4,s4,164 # 80009028 <schedulingpolicy>
    80001f8c:	498d                	li	s3,3
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f8e:	00016917          	auipc	s2,0x16
    80001f92:	54290913          	addi	s2,s2,1346 # 800184d0 <queuetable>
    80001f96:	a80d                	j	80001fc8 <updatetime+0x64>
      p->runningticks++;
    80001f98:	5cdc                	lw	a5,60(s1)
    80001f9a:	2785                	addiw	a5,a5,1
    80001f9c:	dcdc                	sw	a5,60(s1)
      p->rtime++;
    80001f9e:	1ac4a783          	lw	a5,428(s1)
    80001fa2:	2785                	addiw	a5,a5,1
    80001fa4:	1af4a623          	sw	a5,428(s1)
      p->totalrtime++;
    80001fa8:	40fc                	lw	a5,68(s1)
    80001faa:	2785                	addiw	a5,a5,1
    80001fac:	c0fc                	sw	a5,68(s1)
    if (schedulingpolicy == 3 && p->queuestate == QUEUED) {
    80001fae:	000a2783          	lw	a5,0(s4)
    80001fb2:	03378963          	beq	a5,s3,80001fe4 <updatetime+0x80>
    release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	ce0080e7          	jalr	-800(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001fc0:	1b848493          	addi	s1,s1,440
    80001fc4:	05248263          	beq	s1,s2,80002008 <updatetime+0xa4>
    acquire(&p->lock);
    80001fc8:	8526                	mv	a0,s1
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	c1a080e7          	jalr	-998(ra) # 80000be4 <acquire>
    if (p->state == RUNNING) {
    80001fd2:	4c9c                	lw	a5,24(s1)
    80001fd4:	fd5782e3          	beq	a5,s5,80001f98 <updatetime+0x34>
    if (p->state == SLEEPING)
    80001fd8:	fd679be3          	bne	a5,s6,80001fae <updatetime+0x4a>
      p->sleepingticks++;
    80001fdc:	40bc                	lw	a5,64(s1)
    80001fde:	2785                	addiw	a5,a5,1
    80001fe0:	c0bc                	sw	a5,64(s1)
    80001fe2:	b7f1                	j	80001fae <updatetime+0x4a>
    if (schedulingpolicy == 3 && p->queuestate == QUEUED) {
    80001fe4:	1884a783          	lw	a5,392(s1)
    80001fe8:	f7f9                	bnez	a5,80001fb6 <updatetime+0x52>
      p->queueruntime++;
    80001fea:	1904a783          	lw	a5,400(s1)
    80001fee:	2785                	addiw	a5,a5,1
    80001ff0:	18f4a823          	sw	a5,400(s1)
      p->q[p->queuelevel]++;
    80001ff4:	18c4a783          	lw	a5,396(s1)
    80001ff8:	078a                	slli	a5,a5,0x2
    80001ffa:	97a6                	add	a5,a5,s1
    80001ffc:	1987a703          	lw	a4,408(a5)
    80002000:	2705                	addiw	a4,a4,1
    80002002:	18e7ac23          	sw	a4,408(a5)
    80002006:	bf45                	j	80001fb6 <updatetime+0x52>
}
    80002008:	70e2                	ld	ra,56(sp)
    8000200a:	7442                	ld	s0,48(sp)
    8000200c:	74a2                	ld	s1,40(sp)
    8000200e:	7902                	ld	s2,32(sp)
    80002010:	69e2                	ld	s3,24(sp)
    80002012:	6a42                	ld	s4,16(sp)
    80002014:	6aa2                	ld	s5,8(sp)
    80002016:	6b02                	ld	s6,0(sp)
    80002018:	6121                	addi	sp,sp,64
    8000201a:	8082                	ret

000000008000201c <getpreempted>:
  for (int i = 0; i < level; i++) {
    8000201c:	08a05063          	blez	a0,8000209c <getpreempted+0x80>
getpreempted(int level) {
    80002020:	dc010113          	addi	sp,sp,-576
    80002024:	22113c23          	sd	ra,568(sp)
    80002028:	22813823          	sd	s0,560(sp)
    8000202c:	22913423          	sd	s1,552(sp)
    80002030:	23213023          	sd	s2,544(sp)
    80002034:	21313c23          	sd	s3,536(sp)
    80002038:	0480                	addi	s0,sp,576
    8000203a:	892a                	mv	s2,a0
  for (int i = 0; i < level; i++) {
    8000203c:	4481                	li	s1,0
    if (!empty(queuetable[i])) {
    8000203e:	00016997          	auipc	s3,0x16
    80002042:	49298993          	addi	s3,s3,1170 # 800184d0 <queuetable>
    80002046:	00549793          	slli	a5,s1,0x5
    8000204a:	97a6                	add	a5,a5,s1
    8000204c:	0792                	slli	a5,a5,0x4
    8000204e:	97ce                	add	a5,a5,s3
    80002050:	dc040713          	addi	a4,s0,-576
    80002054:	21078313          	addi	t1,a5,528
    80002058:	0007b883          	ld	a7,0(a5)
    8000205c:	0087b803          	ld	a6,8(a5)
    80002060:	6b88                	ld	a0,16(a5)
    80002062:	6f8c                	ld	a1,24(a5)
    80002064:	7390                	ld	a2,32(a5)
    80002066:	7794                	ld	a3,40(a5)
    80002068:	01173023          	sd	a7,0(a4)
    8000206c:	01073423          	sd	a6,8(a4)
    80002070:	eb08                	sd	a0,16(a4)
    80002072:	ef0c                	sd	a1,24(a4)
    80002074:	f310                	sd	a2,32(a4)
    80002076:	f714                	sd	a3,40(a4)
    80002078:	03078793          	addi	a5,a5,48
    8000207c:	03070713          	addi	a4,a4,48
    80002080:	fc679ce3          	bne	a5,t1,80002058 <getpreempted+0x3c>
    80002084:	dc040513          	addi	a0,s0,-576
    80002088:	00001097          	auipc	ra,0x1
    8000208c:	000080e7          	jalr	ra # 80003088 <empty>
    80002090:	c901                	beqz	a0,800020a0 <getpreempted+0x84>
  for (int i = 0; i < level; i++) {
    80002092:	2485                	addiw	s1,s1,1
    80002094:	fa9919e3          	bne	s2,s1,80002046 <getpreempted+0x2a>
  return 0;
    80002098:	4501                	li	a0,0
    8000209a:	a021                	j	800020a2 <getpreempted+0x86>
    8000209c:	4501                	li	a0,0
}
    8000209e:	8082                	ret
      return 1;
    800020a0:	4505                	li	a0,1
}
    800020a2:	23813083          	ld	ra,568(sp)
    800020a6:	23013403          	ld	s0,560(sp)
    800020aa:	22813483          	ld	s1,552(sp)
    800020ae:	22013903          	ld	s2,544(sp)
    800020b2:	21813983          	ld	s3,536(sp)
    800020b6:	24010113          	addi	sp,sp,576
    800020ba:	8082                	ret

00000000800020bc <runprocess>:
runprocess(struct proc* p, struct cpu* c) {
    800020bc:	7179                	addi	sp,sp,-48
    800020be:	f406                	sd	ra,40(sp)
    800020c0:	f022                	sd	s0,32(sp)
    800020c2:	ec26                	sd	s1,24(sp)
    800020c4:	e84a                	sd	s2,16(sp)
    800020c6:	e44e                	sd	s3,8(sp)
    800020c8:	1800                	addi	s0,sp,48
    800020ca:	84aa                	mv	s1,a0
    800020cc:	892e                	mv	s2,a1
  p->scheduletick = ticks;
    800020ce:	00007997          	auipc	s3,0x7
    800020d2:	f6a98993          	addi	s3,s3,-150 # 80009038 <ticks>
    800020d6:	0009a783          	lw	a5,0(s3)
    800020da:	dd1c                	sw	a5,56(a0)
  p->queueentertime = ticks;
    800020dc:	18f52a23          	sw	a5,404(a0)
  p->queueruntime = 0;
    800020e0:	18052823          	sw	zero,400(a0)
  p->state = RUNNING;
    800020e4:	4791                	li	a5,4
    800020e6:	cd1c                	sw	a5,24(a0)
  p->runningticks = 0;
    800020e8:	02052e23          	sw	zero,60(a0)
  p->sleepingticks = 0;
    800020ec:	04052023          	sw	zero,64(a0)
  p->schedulecount++;
    800020f0:	453c                	lw	a5,72(a0)
    800020f2:	2785                	addiw	a5,a5,1
    800020f4:	c53c                	sw	a5,72(a0)
  c->proc = p;
    800020f6:	e188                	sd	a0,0(a1)
  swtch(&c->context, &p->context);
    800020f8:	08050593          	addi	a1,a0,128
    800020fc:	00890513          	addi	a0,s2,8
    80002100:	00001097          	auipc	ra,0x1
    80002104:	fac080e7          	jalr	-84(ra) # 800030ac <swtch>
  p->queueentertime = ticks;
    80002108:	0009a783          	lw	a5,0(s3)
    8000210c:	18f4aa23          	sw	a5,404(s1)
  c->proc = 0;
    80002110:	00093023          	sd	zero,0(s2)
}
    80002114:	70a2                	ld	ra,40(sp)
    80002116:	7402                	ld	s0,32(sp)
    80002118:	64e2                	ld	s1,24(sp)
    8000211a:	6942                	ld	s2,16(sp)
    8000211c:	69a2                	ld	s3,8(sp)
    8000211e:	6145                	addi	sp,sp,48
    80002120:	8082                	ret

0000000080002122 <defaultsched>:
defaultsched(struct cpu* c) {
    80002122:	7179                	addi	sp,sp,-48
    80002124:	f406                	sd	ra,40(sp)
    80002126:	f022                	sd	s0,32(sp)
    80002128:	ec26                	sd	s1,24(sp)
    8000212a:	e84a                	sd	s2,16(sp)
    8000212c:	e44e                	sd	s3,8(sp)
    8000212e:	e052                	sd	s4,0(sp)
    80002130:	1800                	addi	s0,sp,48
    80002132:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++) {
    80002134:	0000f497          	auipc	s1,0xf
    80002138:	59c48493          	addi	s1,s1,1436 # 800116d0 <proc>
    if (p->state == RUNNABLE) {
    8000213c:	498d                	li	s3,3
  for (p = proc; p < &proc[NPROC]; p++) {
    8000213e:	00016917          	auipc	s2,0x16
    80002142:	39290913          	addi	s2,s2,914 # 800184d0 <queuetable>
    80002146:	a005                	j	80002166 <defaultsched+0x44>
      runprocess(p, c);
    80002148:	85d2                	mv	a1,s4
    8000214a:	8526                	mv	a0,s1
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	f70080e7          	jalr	-144(ra) # 800020bc <runprocess>
    release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b42080e7          	jalr	-1214(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    8000215e:	1b848493          	addi	s1,s1,440
    80002162:	01248b63          	beq	s1,s2,80002178 <defaultsched+0x56>
    acquire(&p->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	a7c080e7          	jalr	-1412(ra) # 80000be4 <acquire>
    if (p->state == RUNNABLE) {
    80002170:	4c9c                	lw	a5,24(s1)
    80002172:	ff3791e3          	bne	a5,s3,80002154 <defaultsched+0x32>
    80002176:	bfc9                	j	80002148 <defaultsched+0x26>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <fcfssched>:
fcfssched(struct cpu* c) {
    80002188:	7139                	addi	sp,sp,-64
    8000218a:	fc06                	sd	ra,56(sp)
    8000218c:	f822                	sd	s0,48(sp)
    8000218e:	f426                	sd	s1,40(sp)
    80002190:	f04a                	sd	s2,32(sp)
    80002192:	ec4e                	sd	s3,24(sp)
    80002194:	e852                	sd	s4,16(sp)
    80002196:	e456                	sd	s5,8(sp)
    80002198:	0080                	addi	s0,sp,64
    8000219a:	8aaa                	mv	s5,a0
  struct proc *p, *bestproc = 0;
    8000219c:	4901                	li	s2,0
  for (p = proc; p < &proc[NPROC]; p++) {
    8000219e:	0000f497          	auipc	s1,0xf
    800021a2:	53248493          	addi	s1,s1,1330 # 800116d0 <proc>
    if (p->state == RUNNABLE) {
    800021a6:	4a0d                	li	s4,3
  for (p = proc; p < &proc[NPROC]; p++) {
    800021a8:	00016997          	auipc	s3,0x16
    800021ac:	32898993          	addi	s3,s3,808 # 800184d0 <queuetable>
    800021b0:	a811                	j	800021c4 <fcfssched+0x3c>
      release(&p->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	ae4080e7          	jalr	-1308(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800021bc:	1b848493          	addi	s1,s1,440
    800021c0:	03348a63          	beq	s1,s3,800021f4 <fcfssched+0x6c>
    acquire(&p->lock);
    800021c4:	8526                	mv	a0,s1
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	a1e080e7          	jalr	-1506(ra) # 80000be4 <acquire>
    if (p->state == RUNNABLE) {
    800021ce:	4c9c                	lw	a5,24(s1)
    800021d0:	ff4791e3          	bne	a5,s4,800021b2 <fcfssched+0x2a>
      if (bestproc == 0) {
    800021d4:	00090e63          	beqz	s2,800021f0 <fcfssched+0x68>
        if (p->createtime < bestproc->createtime){
    800021d8:	54f8                	lw	a4,108(s1)
    800021da:	06c92783          	lw	a5,108(s2)
    800021de:	fcf77ae3          	bgeu	a4,a5,800021b2 <fcfssched+0x2a>
          release(&bestproc->lock);
    800021e2:	854a                	mv	a0,s2
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	ab4080e7          	jalr	-1356(ra) # 80000c98 <release>
    800021ec:	8926                	mv	s2,s1
    800021ee:	b7f9                	j	800021bc <fcfssched+0x34>
    800021f0:	8926                	mv	s2,s1
    800021f2:	b7e9                	j	800021bc <fcfssched+0x34>
  if (bestproc == 0) return;
    800021f4:	00090d63          	beqz	s2,8000220e <fcfssched+0x86>
  runprocess(bestproc, c);
    800021f8:	85d6                	mv	a1,s5
    800021fa:	854a                	mv	a0,s2
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	ec0080e7          	jalr	-320(ra) # 800020bc <runprocess>
  release(&bestproc->lock);
    80002204:	854a                	mv	a0,s2
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
}
    8000220e:	70e2                	ld	ra,56(sp)
    80002210:	7442                	ld	s0,48(sp)
    80002212:	74a2                	ld	s1,40(sp)
    80002214:	7902                	ld	s2,32(sp)
    80002216:	69e2                	ld	s3,24(sp)
    80002218:	6a42                	ld	s4,16(sp)
    8000221a:	6aa2                	ld	s5,8(sp)
    8000221c:	6121                	addi	sp,sp,64
    8000221e:	8082                	ret

0000000080002220 <ageprocesses>:
ageprocesses(void) {
    80002220:	7139                	addi	sp,sp,-64
    80002222:	fc06                	sd	ra,56(sp)
    80002224:	f822                	sd	s0,48(sp)
    80002226:	f426                	sd	s1,40(sp)
    80002228:	f04a                	sd	s2,32(sp)
    8000222a:	ec4e                	sd	s3,24(sp)
    8000222c:	e852                	sd	s4,16(sp)
    8000222e:	e456                	sd	s5,8(sp)
    80002230:	e05a                	sd	s6,0(sp)
    80002232:	0080                	addi	s0,sp,64
  for (p = proc; p < &proc[NPROC]; p++) {
    80002234:	0000f497          	auipc	s1,0xf
    80002238:	49c48493          	addi	s1,s1,1180 # 800116d0 <proc>
    if (p->state == RUNNABLE && ticks >= p->queueentertime + AGE) {
    8000223c:	498d                	li	s3,3
    8000223e:	00007a17          	auipc	s4,0x7
    80002242:	dfaa0a13          	addi	s4,s4,-518 # 80009038 <ticks>
      remove(&queuetable[p->queuelevel], p);
    80002246:	00016a97          	auipc	s5,0x16
    8000224a:	28aa8a93          	addi	s5,s5,650 # 800184d0 <queuetable>
      p->queuelevel = max(0, p->queuelevel - 1);
    8000224e:	4b05                	li	s6,1
  for (p = proc; p < &proc[NPROC]; p++) {
    80002250:	00016917          	auipc	s2,0x16
    80002254:	28090913          	addi	s2,s2,640 # 800184d0 <queuetable>
    80002258:	a821                	j	80002270 <ageprocesses+0x50>
      p->queuelevel = max(0, p->queuelevel - 1);
    8000225a:	37fd                	addiw	a5,a5,-1
    8000225c:	18f4a623          	sw	a5,396(s1)
      p->queueentertime = ticks;
    80002260:	000a2783          	lw	a5,0(s4)
    80002264:	18f4aa23          	sw	a5,404(s1)
  for (p = proc; p < &proc[NPROC]; p++) {
    80002268:	1b848493          	addi	s1,s1,440
    8000226c:	05248063          	beq	s1,s2,800022ac <ageprocesses+0x8c>
    if (p->state == RUNNABLE && ticks >= p->queueentertime + AGE) {
    80002270:	4c9c                	lw	a5,24(s1)
    80002272:	ff379be3          	bne	a5,s3,80002268 <ageprocesses+0x48>
    80002276:	1944a783          	lw	a5,404(s1)
    8000227a:	27d1                	addiw	a5,a5,20
    8000227c:	000a2703          	lw	a4,0(s4)
    80002280:	fef764e3          	bltu	a4,a5,80002268 <ageprocesses+0x48>
      remove(&queuetable[p->queuelevel], p);
    80002284:	18c4a783          	lw	a5,396(s1)
    80002288:	00579513          	slli	a0,a5,0x5
    8000228c:	953e                	add	a0,a0,a5
    8000228e:	0512                	slli	a0,a0,0x4
    80002290:	85a6                	mv	a1,s1
    80002292:	9556                	add	a0,a0,s5
    80002294:	00001097          	auipc	ra,0x1
    80002298:	d7a080e7          	jalr	-646(ra) # 8000300e <remove>
      p->queuelevel = max(0, p->queuelevel - 1);
    8000229c:	18c4a783          	lw	a5,396(s1)
    800022a0:	0007871b          	sext.w	a4,a5
    800022a4:	fae04be3          	bgtz	a4,8000225a <ageprocesses+0x3a>
    800022a8:	87da                	mv	a5,s6
    800022aa:	bf45                	j	8000225a <ageprocesses+0x3a>
}
    800022ac:	70e2                	ld	ra,56(sp)
    800022ae:	7442                	ld	s0,48(sp)
    800022b0:	74a2                	ld	s1,40(sp)
    800022b2:	7902                	ld	s2,32(sp)
    800022b4:	69e2                	ld	s3,24(sp)
    800022b6:	6a42                	ld	s4,16(sp)
    800022b8:	6aa2                	ld	s5,8(sp)
    800022ba:	6b02                	ld	s6,0(sp)
    800022bc:	6121                	addi	sp,sp,64
    800022be:	8082                	ret

00000000800022c0 <mlfqsched>:
mlfqsched(struct cpu* c) {
    800022c0:	d9010113          	addi	sp,sp,-624
    800022c4:	26113423          	sd	ra,616(sp)
    800022c8:	26813023          	sd	s0,608(sp)
    800022cc:	24913c23          	sd	s1,600(sp)
    800022d0:	25213823          	sd	s2,592(sp)
    800022d4:	25313423          	sd	s3,584(sp)
    800022d8:	25413023          	sd	s4,576(sp)
    800022dc:	23513c23          	sd	s5,568(sp)
    800022e0:	23613823          	sd	s6,560(sp)
    800022e4:	23713423          	sd	s7,552(sp)
    800022e8:	23813023          	sd	s8,544(sp)
    800022ec:	21913c23          	sd	s9,536(sp)
    800022f0:	1c80                	addi	s0,sp,624
    800022f2:	8c2a                	mv	s8,a0
  ageprocesses();
    800022f4:	00000097          	auipc	ra,0x0
    800022f8:	f2c080e7          	jalr	-212(ra) # 80002220 <ageprocesses>
  for (p = proc; p < &proc[NPROC]; p++) {
    800022fc:	0000f497          	auipc	s1,0xf
    80002300:	3d448493          	addi	s1,s1,980 # 800116d0 <proc>
    if (p->state == RUNNABLE && p->queuestate == NOTQUEUED) {
    80002304:	498d                	li	s3,3
    80002306:	4a05                	li	s4,1
      push(&queuetable[p->queuelevel], p);
    80002308:	00016a97          	auipc	s5,0x16
    8000230c:	1c8a8a93          	addi	s5,s5,456 # 800184d0 <queuetable>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002310:	00016917          	auipc	s2,0x16
    80002314:	1c090913          	addi	s2,s2,448 # 800184d0 <queuetable>
    80002318:	a00d                	j	8000233a <mlfqsched+0x7a>
      push(&queuetable[p->queuelevel], p);
    8000231a:	18c4a783          	lw	a5,396(s1)
    8000231e:	00579513          	slli	a0,a5,0x5
    80002322:	953e                	add	a0,a0,a5
    80002324:	0512                	slli	a0,a0,0x4
    80002326:	85a6                	mv	a1,s1
    80002328:	9556                	add	a0,a0,s5
    8000232a:	00001097          	auipc	ra,0x1
    8000232e:	c68080e7          	jalr	-920(ra) # 80002f92 <push>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002332:	1b848493          	addi	s1,s1,440
    80002336:	01248a63          	beq	s1,s2,8000234a <mlfqsched+0x8a>
    if (p->state == RUNNABLE && p->queuestate == NOTQUEUED) {
    8000233a:	4c9c                	lw	a5,24(s1)
    8000233c:	ff379be3          	bne	a5,s3,80002332 <mlfqsched+0x72>
    80002340:	1884a783          	lw	a5,392(s1)
    80002344:	ff4797e3          	bne	a5,s4,80002332 <mlfqsched+0x72>
    80002348:	bfc9                	j	8000231a <mlfqsched+0x5a>
    8000234a:	00016b97          	auipc	s7,0x16
    8000234e:	186b8b93          	addi	s7,s7,390 # 800184d0 <queuetable>
  for (int i = 0; i < QCOUNT; i++) {
    80002352:	4b01                	li	s6,0
    while (!empty(queuetable[i])) {
    80002354:	8a5e                	mv	s4,s7
      if (p->state == RUNNABLE) {
    80002356:	4a8d                	li	s5,3
  for (int i = 0; i < QCOUNT; i++) {
    80002358:	4c95                	li	s9,5
    8000235a:	a031                	j	80002366 <mlfqsched+0xa6>
    8000235c:	2b05                	addiw	s6,s6,1
    8000235e:	210b8b93          	addi	s7,s7,528
    80002362:	099b0263          	beq	s6,s9,800023e6 <mlfqsched+0x126>
      struct proc *p = pop(&queuetable[i]);
    80002366:	89de                	mv	s3,s7
    while (!empty(queuetable[i])) {
    80002368:	005b1913          	slli	s2,s6,0x5
    8000236c:	995a                	add	s2,s2,s6
    8000236e:	0912                	slli	s2,s2,0x4
    80002370:	012a07b3          	add	a5,s4,s2
    80002374:	d9040713          	addi	a4,s0,-624
    80002378:	21078313          	addi	t1,a5,528
    8000237c:	0007b883          	ld	a7,0(a5)
    80002380:	0087b803          	ld	a6,8(a5)
    80002384:	6b88                	ld	a0,16(a5)
    80002386:	6f8c                	ld	a1,24(a5)
    80002388:	7390                	ld	a2,32(a5)
    8000238a:	7794                	ld	a3,40(a5)
    8000238c:	01173023          	sd	a7,0(a4)
    80002390:	01073423          	sd	a6,8(a4)
    80002394:	eb08                	sd	a0,16(a4)
    80002396:	ef0c                	sd	a1,24(a4)
    80002398:	f310                	sd	a2,32(a4)
    8000239a:	f714                	sd	a3,40(a4)
    8000239c:	03078793          	addi	a5,a5,48
    800023a0:	03070713          	addi	a4,a4,48
    800023a4:	fc679ce3          	bne	a5,t1,8000237c <mlfqsched+0xbc>
    800023a8:	d9040513          	addi	a0,s0,-624
    800023ac:	00001097          	auipc	ra,0x1
    800023b0:	cdc080e7          	jalr	-804(ra) # 80003088 <empty>
    800023b4:	f545                	bnez	a0,8000235c <mlfqsched+0x9c>
      struct proc *p = pop(&queuetable[i]);
    800023b6:	854e                	mv	a0,s3
    800023b8:	00001097          	auipc	ra,0x1
    800023bc:	c18080e7          	jalr	-1000(ra) # 80002fd0 <pop>
    800023c0:	84aa                	mv	s1,a0
      if (p->state == RUNNABLE) {
    800023c2:	4d1c                	lw	a5,24(a0)
    800023c4:	fb5796e3          	bne	a5,s5,80002370 <mlfqsched+0xb0>
  acquire(&pp->lock);
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	81c080e7          	jalr	-2020(ra) # 80000be4 <acquire>
  runprocess(pp, c);
    800023d0:	85e2                	mv	a1,s8
    800023d2:	8526                	mv	a0,s1
    800023d4:	00000097          	auipc	ra,0x0
    800023d8:	ce8080e7          	jalr	-792(ra) # 800020bc <runprocess>
  release(&pp->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ba080e7          	jalr	-1862(ra) # 80000c98 <release>
}
    800023e6:	26813083          	ld	ra,616(sp)
    800023ea:	26013403          	ld	s0,608(sp)
    800023ee:	25813483          	ld	s1,600(sp)
    800023f2:	25013903          	ld	s2,592(sp)
    800023f6:	24813983          	ld	s3,584(sp)
    800023fa:	24013a03          	ld	s4,576(sp)
    800023fe:	23813a83          	ld	s5,568(sp)
    80002402:	23013b03          	ld	s6,560(sp)
    80002406:	22813b83          	ld	s7,552(sp)
    8000240a:	22013c03          	ld	s8,544(sp)
    8000240e:	21813c83          	ld	s9,536(sp)
    80002412:	27010113          	addi	sp,sp,624
    80002416:	8082                	ret

0000000080002418 <dynamicpriority>:
dynamicpriority(struct proc* p) {
    80002418:	1141                	addi	sp,sp,-16
    8000241a:	e422                	sd	s0,8(sp)
    8000241c:	0800                	addi	s0,sp,16
  uint totalticks = p->runningticks + p->sleepingticks;
    8000241e:	4134                	lw	a3,64(a0)
    80002420:	5d58                	lw	a4,60(a0)
    80002422:	9f35                	addw	a4,a4,a3
    80002424:	0007061b          	sext.w	a2,a4
  int nice = 5;
    80002428:	4795                	li	a5,5
  if (totalticks != 0)
    8000242a:	ca01                	beqz	a2,8000243a <dynamicpriority+0x22>
    nice = (p->sleepingticks * 10) / totalticks;
    8000242c:	0026979b          	slliw	a5,a3,0x2
    80002430:	9fb5                	addw	a5,a5,a3
    80002432:	0017979b          	slliw	a5,a5,0x1
    80002436:	02e7d7bb          	divuw	a5,a5,a4
  int a = min(p->staticpriority - nice + 5, 100);
    8000243a:	5948                	lw	a0,52(a0)
    8000243c:	9d1d                	subw	a0,a0,a5
    8000243e:	0005071b          	sext.w	a4,a0
    80002442:	05f00793          	li	a5,95
    80002446:	00e7d463          	bge	a5,a4,8000244e <dynamicpriority+0x36>
    8000244a:	05f00513          	li	a0,95
    8000244e:	2515                	addiw	a0,a0,5
  int b = max(0, a);
    80002450:	0005079b          	sext.w	a5,a0
    80002454:	fff7c793          	not	a5,a5
    80002458:	97fd                	srai	a5,a5,0x3f
    8000245a:	8d7d                	and	a0,a0,a5
}
    8000245c:	2501                	sext.w	a0,a0
    8000245e:	6422                	ld	s0,8(sp)
    80002460:	0141                	addi	sp,sp,16
    80002462:	8082                	ret

0000000080002464 <pbsswap>:
int pbsswap(struct proc* p, struct proc *q) {
    80002464:	7179                	addi	sp,sp,-48
    80002466:	f406                	sd	ra,40(sp)
    80002468:	f022                	sd	s0,32(sp)
    8000246a:	ec26                	sd	s1,24(sp)
    8000246c:	e84a                	sd	s2,16(sp)
    8000246e:	e44e                	sd	s3,8(sp)
    80002470:	1800                	addi	s0,sp,48
    80002472:	89aa                	mv	s3,a0
    80002474:	892e                	mv	s2,a1
  int dynamiccurrent = dynamicpriority(p);
    80002476:	00000097          	auipc	ra,0x0
    8000247a:	fa2080e7          	jalr	-94(ra) # 80002418 <dynamicpriority>
    8000247e:	84aa                	mv	s1,a0
  int dynamicbest = dynamicpriority(q);
    80002480:	854a                	mv	a0,s2
    80002482:	00000097          	auipc	ra,0x0
    80002486:	f96080e7          	jalr	-106(ra) # 80002418 <dynamicpriority>
  if (dynamiccurrent < dynamicbest) {
    8000248a:	02a4ce63          	blt	s1,a0,800024c6 <pbsswap+0x62>
    8000248e:	87aa                	mv	a5,a0
  return 0;
    80002490:	4501                	li	a0,0
  else if (dynamiccurrent == dynamicbest && p->schedulecount < q->schedulecount) {
    80002492:	00f48963          	beq	s1,a5,800024a4 <pbsswap+0x40>
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6145                	addi	sp,sp,48
    800024a2:	8082                	ret
  else if (dynamiccurrent == dynamicbest && p->schedulecount < q->schedulecount) {
    800024a4:	0489a703          	lw	a4,72(s3)
    800024a8:	04892783          	lw	a5,72(s2)
    return 1;
    800024ac:	4505                	li	a0,1
  else if (dynamiccurrent == dynamicbest && p->schedulecount < q->schedulecount) {
    800024ae:	fef744e3          	blt	a4,a5,80002496 <pbsswap+0x32>
  return 0;
    800024b2:	4501                	li	a0,0
  else if (dynamiccurrent == dynamicbest && p->schedulecount == q->schedulecount && p->createtime < q->createtime) {
    800024b4:	fef711e3          	bne	a4,a5,80002496 <pbsswap+0x32>
    800024b8:	06c9a503          	lw	a0,108(s3)
    800024bc:	06c92783          	lw	a5,108(s2)
    return 1;
    800024c0:	00f53533          	sltu	a0,a0,a5
    800024c4:	bfc9                	j	80002496 <pbsswap+0x32>
    800024c6:	4505                	li	a0,1
    800024c8:	b7f9                	j	80002496 <pbsswap+0x32>

00000000800024ca <pbssched>:
pbssched(struct cpu* c) {
    800024ca:	7139                	addi	sp,sp,-64
    800024cc:	fc06                	sd	ra,56(sp)
    800024ce:	f822                	sd	s0,48(sp)
    800024d0:	f426                	sd	s1,40(sp)
    800024d2:	f04a                	sd	s2,32(sp)
    800024d4:	ec4e                	sd	s3,24(sp)
    800024d6:	e852                	sd	s4,16(sp)
    800024d8:	e456                	sd	s5,8(sp)
    800024da:	0080                	addi	s0,sp,64
    800024dc:	8aaa                	mv	s5,a0
  struct proc *p, *bestproc = 0;
    800024de:	4901                	li	s2,0
  for (p = proc; p < &proc[NPROC]; p++) {
    800024e0:	0000f497          	auipc	s1,0xf
    800024e4:	1f048493          	addi	s1,s1,496 # 800116d0 <proc>
    if (p->state == RUNNABLE) {
    800024e8:	4a0d                	li	s4,3
  for (p = proc; p < &proc[NPROC]; p++) {
    800024ea:	00016997          	auipc	s3,0x16
    800024ee:	fe698993          	addi	s3,s3,-26 # 800184d0 <queuetable>
    800024f2:	a811                	j	80002506 <pbssched+0x3c>
      release(&p->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7a2080e7          	jalr	1954(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800024fe:	1b848493          	addi	s1,s1,440
    80002502:	03348c63          	beq	s1,s3,8000253a <pbssched+0x70>
    acquire(&p->lock);
    80002506:	8526                	mv	a0,s1
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	6dc080e7          	jalr	1756(ra) # 80000be4 <acquire>
    if (p->state == RUNNABLE) {
    80002510:	4c9c                	lw	a5,24(s1)
    80002512:	ff4791e3          	bne	a5,s4,800024f4 <pbssched+0x2a>
      if (bestproc == 0) {
    80002516:	02090063          	beqz	s2,80002536 <pbssched+0x6c>
        if (pbsswap(p, bestproc)) {
    8000251a:	85ca                	mv	a1,s2
    8000251c:	8526                	mv	a0,s1
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	f46080e7          	jalr	-186(ra) # 80002464 <pbsswap>
    80002526:	d579                	beqz	a0,800024f4 <pbssched+0x2a>
          release(&bestproc->lock);
    80002528:	854a                	mv	a0,s2
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	76e080e7          	jalr	1902(ra) # 80000c98 <release>
    80002532:	8926                	mv	s2,s1
    80002534:	b7e9                	j	800024fe <pbssched+0x34>
    80002536:	8926                	mv	s2,s1
    80002538:	b7d9                	j	800024fe <pbssched+0x34>
  if (bestproc == 0) return;
    8000253a:	00090d63          	beqz	s2,80002554 <pbssched+0x8a>
  runprocess(bestproc, c);
    8000253e:	85d6                	mv	a1,s5
    80002540:	854a                	mv	a0,s2
    80002542:	00000097          	auipc	ra,0x0
    80002546:	b7a080e7          	jalr	-1158(ra) # 800020bc <runprocess>
  release(&bestproc->lock);
    8000254a:	854a                	mv	a0,s2
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	74c080e7          	jalr	1868(ra) # 80000c98 <release>
}
    80002554:	70e2                	ld	ra,56(sp)
    80002556:	7442                	ld	s0,48(sp)
    80002558:	74a2                	ld	s1,40(sp)
    8000255a:	7902                	ld	s2,32(sp)
    8000255c:	69e2                	ld	s3,24(sp)
    8000255e:	6a42                	ld	s4,16(sp)
    80002560:	6aa2                	ld	s5,8(sp)
    80002562:	6121                	addi	sp,sp,64
    80002564:	8082                	ret

0000000080002566 <scheduler>:
{
    80002566:	7139                	addi	sp,sp,-64
    80002568:	fc06                	sd	ra,56(sp)
    8000256a:	f822                	sd	s0,48(sp)
    8000256c:	f426                	sd	s1,40(sp)
    8000256e:	f04a                	sd	s2,32(sp)
    80002570:	ec4e                	sd	s3,24(sp)
    80002572:	e852                	sd	s4,16(sp)
    80002574:	e456                	sd	s5,8(sp)
    80002576:	0080                	addi	s0,sp,64
    80002578:	8792                	mv	a5,tp
  int id = r_tp();
    8000257a:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    8000257c:	079e                	slli	a5,a5,0x7
    8000257e:	0000f497          	auipc	s1,0xf
    80002582:	d5248493          	addi	s1,s1,-686 # 800112d0 <cpus>
    80002586:	94be                	add	s1,s1,a5
  c->proc = 0;
    80002588:	0000f717          	auipc	a4,0xf
    8000258c:	d1870713          	addi	a4,a4,-744 # 800112a0 <pid_lock>
    80002590:	97ba                	add	a5,a5,a4
    80002592:	0207b823          	sd	zero,48(a5)
    if (schedulingpolicy == 1) fcfssched(c);
    80002596:	00007997          	auipc	s3,0x7
    8000259a:	a9298993          	addi	s3,s3,-1390 # 80009028 <schedulingpolicy>
    8000259e:	4905                	li	s2,1
    else if (schedulingpolicy == 2) pbssched(c);
    800025a0:	4a09                	li	s4,2
    else if (schedulingpolicy == 3) mlfqsched(c);
    800025a2:	4a8d                	li	s5,3
    800025a4:	a015                	j	800025c8 <scheduler+0x62>
    if (schedulingpolicy == 1) fcfssched(c);
    800025a6:	8526                	mv	a0,s1
    800025a8:	00000097          	auipc	ra,0x0
    800025ac:	be0080e7          	jalr	-1056(ra) # 80002188 <fcfssched>
    800025b0:	a821                	j	800025c8 <scheduler+0x62>
    else if (schedulingpolicy == 2) pbssched(c);
    800025b2:	8526                	mv	a0,s1
    800025b4:	00000097          	auipc	ra,0x0
    800025b8:	f16080e7          	jalr	-234(ra) # 800024ca <pbssched>
    800025bc:	a031                	j	800025c8 <scheduler+0x62>
    else defaultsched(c);
    800025be:	8526                	mv	a0,s1
    800025c0:	00000097          	auipc	ra,0x0
    800025c4:	b62080e7          	jalr	-1182(ra) # 80002122 <defaultsched>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025d0:	10079073          	csrw	sstatus,a5
    if (schedulingpolicy == 1) fcfssched(c);
    800025d4:	0009a783          	lw	a5,0(s3)
    800025d8:	fd2787e3          	beq	a5,s2,800025a6 <scheduler+0x40>
    else if (schedulingpolicy == 2) pbssched(c);
    800025dc:	fd478be3          	beq	a5,s4,800025b2 <scheduler+0x4c>
    else if (schedulingpolicy == 3) mlfqsched(c);
    800025e0:	fd579fe3          	bne	a5,s5,800025be <scheduler+0x58>
    800025e4:	8526                	mv	a0,s1
    800025e6:	00000097          	auipc	ra,0x0
    800025ea:	cda080e7          	jalr	-806(ra) # 800022c0 <mlfqsched>
    800025ee:	bfe9                	j	800025c8 <scheduler+0x62>

00000000800025f0 <sched>:
{
    800025f0:	7179                	addi	sp,sp,-48
    800025f2:	f406                	sd	ra,40(sp)
    800025f4:	f022                	sd	s0,32(sp)
    800025f6:	ec26                	sd	s1,24(sp)
    800025f8:	e84a                	sd	s2,16(sp)
    800025fa:	e44e                	sd	s3,8(sp)
    800025fc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800025fe:	fffff097          	auipc	ra,0xfffff
    80002602:	3ba080e7          	jalr	954(ra) # 800019b8 <myproc>
    80002606:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	562080e7          	jalr	1378(ra) # 80000b6a <holding>
    80002610:	c93d                	beqz	a0,80002686 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002612:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002614:	2781                	sext.w	a5,a5
    80002616:	079e                	slli	a5,a5,0x7
    80002618:	0000f717          	auipc	a4,0xf
    8000261c:	c8870713          	addi	a4,a4,-888 # 800112a0 <pid_lock>
    80002620:	97ba                	add	a5,a5,a4
    80002622:	0a87a703          	lw	a4,168(a5)
    80002626:	4785                	li	a5,1
    80002628:	06f71763          	bne	a4,a5,80002696 <sched+0xa6>
  if(p->state == RUNNING)
    8000262c:	4c98                	lw	a4,24(s1)
    8000262e:	4791                	li	a5,4
    80002630:	06f70b63          	beq	a4,a5,800026a6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002634:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002638:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000263a:	efb5                	bnez	a5,800026b6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000263c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000263e:	0000f917          	auipc	s2,0xf
    80002642:	c6290913          	addi	s2,s2,-926 # 800112a0 <pid_lock>
    80002646:	2781                	sext.w	a5,a5
    80002648:	079e                	slli	a5,a5,0x7
    8000264a:	97ca                	add	a5,a5,s2
    8000264c:	0ac7a983          	lw	s3,172(a5)
    80002650:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002652:	2781                	sext.w	a5,a5
    80002654:	079e                	slli	a5,a5,0x7
    80002656:	0000f597          	auipc	a1,0xf
    8000265a:	c8258593          	addi	a1,a1,-894 # 800112d8 <cpus+0x8>
    8000265e:	95be                	add	a1,a1,a5
    80002660:	08048513          	addi	a0,s1,128
    80002664:	00001097          	auipc	ra,0x1
    80002668:	a48080e7          	jalr	-1464(ra) # 800030ac <swtch>
    8000266c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000266e:	2781                	sext.w	a5,a5
    80002670:	079e                	slli	a5,a5,0x7
    80002672:	97ca                	add	a5,a5,s2
    80002674:	0b37a623          	sw	s3,172(a5)
}
    80002678:	70a2                	ld	ra,40(sp)
    8000267a:	7402                	ld	s0,32(sp)
    8000267c:	64e2                	ld	s1,24(sp)
    8000267e:	6942                	ld	s2,16(sp)
    80002680:	69a2                	ld	s3,8(sp)
    80002682:	6145                	addi	sp,sp,48
    80002684:	8082                	ret
    panic("sched p->lock");
    80002686:	00006517          	auipc	a0,0x6
    8000268a:	b9250513          	addi	a0,a0,-1134 # 80008218 <digits+0x1d8>
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	eb0080e7          	jalr	-336(ra) # 8000053e <panic>
    panic("sched locks");
    80002696:	00006517          	auipc	a0,0x6
    8000269a:	b9250513          	addi	a0,a0,-1134 # 80008228 <digits+0x1e8>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
    panic("sched running");
    800026a6:	00006517          	auipc	a0,0x6
    800026aa:	b9250513          	addi	a0,a0,-1134 # 80008238 <digits+0x1f8>
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>
    panic("sched interruptible");
    800026b6:	00006517          	auipc	a0,0x6
    800026ba:	b9250513          	addi	a0,a0,-1134 # 80008248 <digits+0x208>
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	e80080e7          	jalr	-384(ra) # 8000053e <panic>

00000000800026c6 <yield>:
{
    800026c6:	1101                	addi	sp,sp,-32
    800026c8:	ec06                	sd	ra,24(sp)
    800026ca:	e822                	sd	s0,16(sp)
    800026cc:	e426                	sd	s1,8(sp)
    800026ce:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	2e8080e7          	jalr	744(ra) # 800019b8 <myproc>
    800026d8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	50a080e7          	jalr	1290(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800026e2:	478d                	li	a5,3
    800026e4:	cc9c                	sw	a5,24(s1)
  sched();
    800026e6:	00000097          	auipc	ra,0x0
    800026ea:	f0a080e7          	jalr	-246(ra) # 800025f0 <sched>
  release(&p->lock);
    800026ee:	8526                	mv	a0,s1
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	5a8080e7          	jalr	1448(ra) # 80000c98 <release>
}
    800026f8:	60e2                	ld	ra,24(sp)
    800026fa:	6442                	ld	s0,16(sp)
    800026fc:	64a2                	ld	s1,8(sp)
    800026fe:	6105                	addi	sp,sp,32
    80002700:	8082                	ret

0000000080002702 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002702:	7179                	addi	sp,sp,-48
    80002704:	f406                	sd	ra,40(sp)
    80002706:	f022                	sd	s0,32(sp)
    80002708:	ec26                	sd	s1,24(sp)
    8000270a:	e84a                	sd	s2,16(sp)
    8000270c:	e44e                	sd	s3,8(sp)
    8000270e:	1800                	addi	s0,sp,48
    80002710:	89aa                	mv	s3,a0
    80002712:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	2a4080e7          	jalr	676(ra) # 800019b8 <myproc>
    8000271c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	4c6080e7          	jalr	1222(ra) # 80000be4 <acquire>
  release(lk);
    80002726:	854a                	mv	a0,s2
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	570080e7          	jalr	1392(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002730:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002734:	4789                	li	a5,2
    80002736:	cc9c                	sw	a5,24(s1)

  sched();
    80002738:	00000097          	auipc	ra,0x0
    8000273c:	eb8080e7          	jalr	-328(ra) # 800025f0 <sched>

  // Tidy up.
  p->chan = 0;
    80002740:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	552080e7          	jalr	1362(ra) # 80000c98 <release>
  acquire(lk);
    8000274e:	854a                	mv	a0,s2
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	494080e7          	jalr	1172(ra) # 80000be4 <acquire>
}
    80002758:	70a2                	ld	ra,40(sp)
    8000275a:	7402                	ld	s0,32(sp)
    8000275c:	64e2                	ld	s1,24(sp)
    8000275e:	6942                	ld	s2,16(sp)
    80002760:	69a2                	ld	s3,8(sp)
    80002762:	6145                	addi	sp,sp,48
    80002764:	8082                	ret

0000000080002766 <wait>:
{
    80002766:	715d                	addi	sp,sp,-80
    80002768:	e486                	sd	ra,72(sp)
    8000276a:	e0a2                	sd	s0,64(sp)
    8000276c:	fc26                	sd	s1,56(sp)
    8000276e:	f84a                	sd	s2,48(sp)
    80002770:	f44e                	sd	s3,40(sp)
    80002772:	f052                	sd	s4,32(sp)
    80002774:	ec56                	sd	s5,24(sp)
    80002776:	e85a                	sd	s6,16(sp)
    80002778:	e45e                	sd	s7,8(sp)
    8000277a:	e062                	sd	s8,0(sp)
    8000277c:	0880                	addi	s0,sp,80
    8000277e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002780:	fffff097          	auipc	ra,0xfffff
    80002784:	238080e7          	jalr	568(ra) # 800019b8 <myproc>
    80002788:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000278a:	0000f517          	auipc	a0,0xf
    8000278e:	b2e50513          	addi	a0,a0,-1234 # 800112b8 <wait_lock>
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	452080e7          	jalr	1106(ra) # 80000be4 <acquire>
    havekids = 0;
    8000279a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000279c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000279e:	00016997          	auipc	s3,0x16
    800027a2:	d3298993          	addi	s3,s3,-718 # 800184d0 <queuetable>
        havekids = 1;
    800027a6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027a8:	0000fc17          	auipc	s8,0xf
    800027ac:	b10c0c13          	addi	s8,s8,-1264 # 800112b8 <wait_lock>
    havekids = 0;
    800027b0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027b2:	0000f497          	auipc	s1,0xf
    800027b6:	f1e48493          	addi	s1,s1,-226 # 800116d0 <proc>
    800027ba:	a0bd                	j	80002828 <wait+0xc2>
          pid = np->pid;
    800027bc:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027c0:	000b0e63          	beqz	s6,800027dc <wait+0x76>
    800027c4:	4691                	li	a3,4
    800027c6:	02c48613          	addi	a2,s1,44
    800027ca:	85da                	mv	a1,s6
    800027cc:	07093503          	ld	a0,112(s2)
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	eaa080e7          	jalr	-342(ra) # 8000167a <copyout>
    800027d8:	02054563          	bltz	a0,80002802 <wait+0x9c>
          freeproc(np);
    800027dc:	8526                	mv	a0,s1
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	38c080e7          	jalr	908(ra) # 80001b6a <freeproc>
          release(&np->lock);
    800027e6:	8526                	mv	a0,s1
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	4b0080e7          	jalr	1200(ra) # 80000c98 <release>
          release(&wait_lock);
    800027f0:	0000f517          	auipc	a0,0xf
    800027f4:	ac850513          	addi	a0,a0,-1336 # 800112b8 <wait_lock>
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	4a0080e7          	jalr	1184(ra) # 80000c98 <release>
          return pid;
    80002800:	a09d                	j	80002866 <wait+0x100>
            release(&np->lock);
    80002802:	8526                	mv	a0,s1
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	494080e7          	jalr	1172(ra) # 80000c98 <release>
            release(&wait_lock);
    8000280c:	0000f517          	auipc	a0,0xf
    80002810:	aac50513          	addi	a0,a0,-1364 # 800112b8 <wait_lock>
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	484080e7          	jalr	1156(ra) # 80000c98 <release>
            return -1;
    8000281c:	59fd                	li	s3,-1
    8000281e:	a0a1                	j	80002866 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002820:	1b848493          	addi	s1,s1,440
    80002824:	03348463          	beq	s1,s3,8000284c <wait+0xe6>
      if(np->parent == p){
    80002828:	68bc                	ld	a5,80(s1)
    8000282a:	ff279be3          	bne	a5,s2,80002820 <wait+0xba>
        acquire(&np->lock);
    8000282e:	8526                	mv	a0,s1
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	3b4080e7          	jalr	948(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002838:	4c9c                	lw	a5,24(s1)
    8000283a:	f94781e3          	beq	a5,s4,800027bc <wait+0x56>
        release(&np->lock);
    8000283e:	8526                	mv	a0,s1
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	458080e7          	jalr	1112(ra) # 80000c98 <release>
        havekids = 1;
    80002848:	8756                	mv	a4,s5
    8000284a:	bfd9                	j	80002820 <wait+0xba>
    if(!havekids || p->killed){
    8000284c:	c701                	beqz	a4,80002854 <wait+0xee>
    8000284e:	02892783          	lw	a5,40(s2)
    80002852:	c79d                	beqz	a5,80002880 <wait+0x11a>
      release(&wait_lock);
    80002854:	0000f517          	auipc	a0,0xf
    80002858:	a6450513          	addi	a0,a0,-1436 # 800112b8 <wait_lock>
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	43c080e7          	jalr	1084(ra) # 80000c98 <release>
      return -1;
    80002864:	59fd                	li	s3,-1
}
    80002866:	854e                	mv	a0,s3
    80002868:	60a6                	ld	ra,72(sp)
    8000286a:	6406                	ld	s0,64(sp)
    8000286c:	74e2                	ld	s1,56(sp)
    8000286e:	7942                	ld	s2,48(sp)
    80002870:	79a2                	ld	s3,40(sp)
    80002872:	7a02                	ld	s4,32(sp)
    80002874:	6ae2                	ld	s5,24(sp)
    80002876:	6b42                	ld	s6,16(sp)
    80002878:	6ba2                	ld	s7,8(sp)
    8000287a:	6c02                	ld	s8,0(sp)
    8000287c:	6161                	addi	sp,sp,80
    8000287e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002880:	85e2                	mv	a1,s8
    80002882:	854a                	mv	a0,s2
    80002884:	00000097          	auipc	ra,0x0
    80002888:	e7e080e7          	jalr	-386(ra) # 80002702 <sleep>
    havekids = 0;
    8000288c:	b715                	j	800027b0 <wait+0x4a>

000000008000288e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000288e:	7139                	addi	sp,sp,-64
    80002890:	fc06                	sd	ra,56(sp)
    80002892:	f822                	sd	s0,48(sp)
    80002894:	f426                	sd	s1,40(sp)
    80002896:	f04a                	sd	s2,32(sp)
    80002898:	ec4e                	sd	s3,24(sp)
    8000289a:	e852                	sd	s4,16(sp)
    8000289c:	e456                	sd	s5,8(sp)
    8000289e:	0080                	addi	s0,sp,64
    800028a0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800028a2:	0000f497          	auipc	s1,0xf
    800028a6:	e2e48493          	addi	s1,s1,-466 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800028aa:	4989                	li	s3,2
        p->state = RUNNABLE;
    800028ac:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800028ae:	00016917          	auipc	s2,0x16
    800028b2:	c2290913          	addi	s2,s2,-990 # 800184d0 <queuetable>
    800028b6:	a821                	j	800028ce <wakeup+0x40>
        p->state = RUNNABLE;
    800028b8:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	3da080e7          	jalr	986(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800028c6:	1b848493          	addi	s1,s1,440
    800028ca:	03248463          	beq	s1,s2,800028f2 <wakeup+0x64>
    if(p != myproc()){
    800028ce:	fffff097          	auipc	ra,0xfffff
    800028d2:	0ea080e7          	jalr	234(ra) # 800019b8 <myproc>
    800028d6:	fea488e3          	beq	s1,a0,800028c6 <wakeup+0x38>
      acquire(&p->lock);
    800028da:	8526                	mv	a0,s1
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800028e4:	4c9c                	lw	a5,24(s1)
    800028e6:	fd379be3          	bne	a5,s3,800028bc <wakeup+0x2e>
    800028ea:	709c                	ld	a5,32(s1)
    800028ec:	fd4798e3          	bne	a5,s4,800028bc <wakeup+0x2e>
    800028f0:	b7e1                	j	800028b8 <wakeup+0x2a>
    }
  }
}
    800028f2:	70e2                	ld	ra,56(sp)
    800028f4:	7442                	ld	s0,48(sp)
    800028f6:	74a2                	ld	s1,40(sp)
    800028f8:	7902                	ld	s2,32(sp)
    800028fa:	69e2                	ld	s3,24(sp)
    800028fc:	6a42                	ld	s4,16(sp)
    800028fe:	6aa2                	ld	s5,8(sp)
    80002900:	6121                	addi	sp,sp,64
    80002902:	8082                	ret

0000000080002904 <reparent>:
{
    80002904:	7179                	addi	sp,sp,-48
    80002906:	f406                	sd	ra,40(sp)
    80002908:	f022                	sd	s0,32(sp)
    8000290a:	ec26                	sd	s1,24(sp)
    8000290c:	e84a                	sd	s2,16(sp)
    8000290e:	e44e                	sd	s3,8(sp)
    80002910:	e052                	sd	s4,0(sp)
    80002912:	1800                	addi	s0,sp,48
    80002914:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002916:	0000f497          	auipc	s1,0xf
    8000291a:	dba48493          	addi	s1,s1,-582 # 800116d0 <proc>
      pp->parent = initproc;
    8000291e:	00006a17          	auipc	s4,0x6
    80002922:	712a0a13          	addi	s4,s4,1810 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002926:	00016997          	auipc	s3,0x16
    8000292a:	baa98993          	addi	s3,s3,-1110 # 800184d0 <queuetable>
    8000292e:	a029                	j	80002938 <reparent+0x34>
    80002930:	1b848493          	addi	s1,s1,440
    80002934:	01348d63          	beq	s1,s3,8000294e <reparent+0x4a>
    if(pp->parent == p){
    80002938:	68bc                	ld	a5,80(s1)
    8000293a:	ff279be3          	bne	a5,s2,80002930 <reparent+0x2c>
      pp->parent = initproc;
    8000293e:	000a3503          	ld	a0,0(s4)
    80002942:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    80002944:	00000097          	auipc	ra,0x0
    80002948:	f4a080e7          	jalr	-182(ra) # 8000288e <wakeup>
    8000294c:	b7d5                	j	80002930 <reparent+0x2c>
}
    8000294e:	70a2                	ld	ra,40(sp)
    80002950:	7402                	ld	s0,32(sp)
    80002952:	64e2                	ld	s1,24(sp)
    80002954:	6942                	ld	s2,16(sp)
    80002956:	69a2                	ld	s3,8(sp)
    80002958:	6a02                	ld	s4,0(sp)
    8000295a:	6145                	addi	sp,sp,48
    8000295c:	8082                	ret

000000008000295e <exit>:
{
    8000295e:	7179                	addi	sp,sp,-48
    80002960:	f406                	sd	ra,40(sp)
    80002962:	f022                	sd	s0,32(sp)
    80002964:	ec26                	sd	s1,24(sp)
    80002966:	e84a                	sd	s2,16(sp)
    80002968:	e44e                	sd	s3,8(sp)
    8000296a:	e052                	sd	s4,0(sp)
    8000296c:	1800                	addi	s0,sp,48
    8000296e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002970:	fffff097          	auipc	ra,0xfffff
    80002974:	048080e7          	jalr	72(ra) # 800019b8 <myproc>
    80002978:	89aa                	mv	s3,a0
  if(p == initproc)
    8000297a:	00006797          	auipc	a5,0x6
    8000297e:	6b67b783          	ld	a5,1718(a5) # 80009030 <initproc>
    80002982:	0f050493          	addi	s1,a0,240
    80002986:	17050913          	addi	s2,a0,368
    8000298a:	02a79363          	bne	a5,a0,800029b0 <exit+0x52>
    panic("init exiting");
    8000298e:	00006517          	auipc	a0,0x6
    80002992:	8d250513          	addi	a0,a0,-1838 # 80008260 <digits+0x220>
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>
      fileclose(f);
    8000299e:	00003097          	auipc	ra,0x3
    800029a2:	8d6080e7          	jalr	-1834(ra) # 80005274 <fileclose>
      p->ofile[fd] = 0;
    800029a6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800029aa:	04a1                	addi	s1,s1,8
    800029ac:	01248563          	beq	s1,s2,800029b6 <exit+0x58>
    if(p->ofile[fd]){
    800029b0:	6088                	ld	a0,0(s1)
    800029b2:	f575                	bnez	a0,8000299e <exit+0x40>
    800029b4:	bfdd                	j	800029aa <exit+0x4c>
  begin_op();
    800029b6:	00002097          	auipc	ra,0x2
    800029ba:	3f2080e7          	jalr	1010(ra) # 80004da8 <begin_op>
  iput(p->cwd);
    800029be:	1709b503          	ld	a0,368(s3)
    800029c2:	00002097          	auipc	ra,0x2
    800029c6:	bce080e7          	jalr	-1074(ra) # 80004590 <iput>
  end_op();
    800029ca:	00002097          	auipc	ra,0x2
    800029ce:	45e080e7          	jalr	1118(ra) # 80004e28 <end_op>
  p->cwd = 0;
    800029d2:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800029d6:	0000f497          	auipc	s1,0xf
    800029da:	8e248493          	addi	s1,s1,-1822 # 800112b8 <wait_lock>
    800029de:	8526                	mv	a0,s1
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	204080e7          	jalr	516(ra) # 80000be4 <acquire>
  reparent(p);
    800029e8:	854e                	mv	a0,s3
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	f1a080e7          	jalr	-230(ra) # 80002904 <reparent>
  wakeup(p->parent);
    800029f2:	0509b503          	ld	a0,80(s3)
    800029f6:	00000097          	auipc	ra,0x0
    800029fa:	e98080e7          	jalr	-360(ra) # 8000288e <wakeup>
  acquire(&p->lock);
    800029fe:	854e                	mv	a0,s3
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	1e4080e7          	jalr	484(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a08:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002a0c:	4795                	li	a5,5
    80002a0e:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002a12:	00006797          	auipc	a5,0x6
    80002a16:	6267a783          	lw	a5,1574(a5) # 80009038 <ticks>
    80002a1a:	1af9aa23          	sw	a5,436(s3)
  release(&wait_lock);
    80002a1e:	8526                	mv	a0,s1
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	278080e7          	jalr	632(ra) # 80000c98 <release>
  sched();
    80002a28:	00000097          	auipc	ra,0x0
    80002a2c:	bc8080e7          	jalr	-1080(ra) # 800025f0 <sched>
  panic("zombie exit");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	84050513          	addi	a0,a0,-1984 # 80008270 <digits+0x230>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b06080e7          	jalr	-1274(ra) # 8000053e <panic>

0000000080002a40 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a40:	7179                	addi	sp,sp,-48
    80002a42:	f406                	sd	ra,40(sp)
    80002a44:	f022                	sd	s0,32(sp)
    80002a46:	ec26                	sd	s1,24(sp)
    80002a48:	e84a                	sd	s2,16(sp)
    80002a4a:	e44e                	sd	s3,8(sp)
    80002a4c:	1800                	addi	s0,sp,48
    80002a4e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a50:	0000f497          	auipc	s1,0xf
    80002a54:	c8048493          	addi	s1,s1,-896 # 800116d0 <proc>
    80002a58:	00016997          	auipc	s3,0x16
    80002a5c:	a7898993          	addi	s3,s3,-1416 # 800184d0 <queuetable>
    acquire(&p->lock);
    80002a60:	8526                	mv	a0,s1
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	182080e7          	jalr	386(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002a6a:	589c                	lw	a5,48(s1)
    80002a6c:	01278d63          	beq	a5,s2,80002a86 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a70:	8526                	mv	a0,s1
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	226080e7          	jalr	550(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a7a:	1b848493          	addi	s1,s1,440
    80002a7e:	ff3491e3          	bne	s1,s3,80002a60 <kill+0x20>
  }
  return -1;
    80002a82:	557d                	li	a0,-1
    80002a84:	a829                	j	80002a9e <kill+0x5e>
      p->killed = 1;
    80002a86:	4785                	li	a5,1
    80002a88:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002a8a:	4c98                	lw	a4,24(s1)
    80002a8c:	4789                	li	a5,2
    80002a8e:	00f70f63          	beq	a4,a5,80002aac <kill+0x6c>
      release(&p->lock);
    80002a92:	8526                	mv	a0,s1
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	204080e7          	jalr	516(ra) # 80000c98 <release>
      return 0;
    80002a9c:	4501                	li	a0,0
}
    80002a9e:	70a2                	ld	ra,40(sp)
    80002aa0:	7402                	ld	s0,32(sp)
    80002aa2:	64e2                	ld	s1,24(sp)
    80002aa4:	6942                	ld	s2,16(sp)
    80002aa6:	69a2                	ld	s3,8(sp)
    80002aa8:	6145                	addi	sp,sp,48
    80002aaa:	8082                	ret
        p->state = RUNNABLE;
    80002aac:	478d                	li	a5,3
    80002aae:	cc9c                	sw	a5,24(s1)
    80002ab0:	b7cd                	j	80002a92 <kill+0x52>

0000000080002ab2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002ab2:	7179                	addi	sp,sp,-48
    80002ab4:	f406                	sd	ra,40(sp)
    80002ab6:	f022                	sd	s0,32(sp)
    80002ab8:	ec26                	sd	s1,24(sp)
    80002aba:	e84a                	sd	s2,16(sp)
    80002abc:	e44e                	sd	s3,8(sp)
    80002abe:	e052                	sd	s4,0(sp)
    80002ac0:	1800                	addi	s0,sp,48
    80002ac2:	84aa                	mv	s1,a0
    80002ac4:	892e                	mv	s2,a1
    80002ac6:	89b2                	mv	s3,a2
    80002ac8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	eee080e7          	jalr	-274(ra) # 800019b8 <myproc>
  if(user_dst){
    80002ad2:	c08d                	beqz	s1,80002af4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002ad4:	86d2                	mv	a3,s4
    80002ad6:	864e                	mv	a2,s3
    80002ad8:	85ca                	mv	a1,s2
    80002ada:	7928                	ld	a0,112(a0)
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	b9e080e7          	jalr	-1122(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002ae4:	70a2                	ld	ra,40(sp)
    80002ae6:	7402                	ld	s0,32(sp)
    80002ae8:	64e2                	ld	s1,24(sp)
    80002aea:	6942                	ld	s2,16(sp)
    80002aec:	69a2                	ld	s3,8(sp)
    80002aee:	6a02                	ld	s4,0(sp)
    80002af0:	6145                	addi	sp,sp,48
    80002af2:	8082                	ret
    memmove((char *)dst, src, len);
    80002af4:	000a061b          	sext.w	a2,s4
    80002af8:	85ce                	mv	a1,s3
    80002afa:	854a                	mv	a0,s2
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	244080e7          	jalr	580(ra) # 80000d40 <memmove>
    return 0;
    80002b04:	8526                	mv	a0,s1
    80002b06:	bff9                	j	80002ae4 <either_copyout+0x32>

0000000080002b08 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b08:	7179                	addi	sp,sp,-48
    80002b0a:	f406                	sd	ra,40(sp)
    80002b0c:	f022                	sd	s0,32(sp)
    80002b0e:	ec26                	sd	s1,24(sp)
    80002b10:	e84a                	sd	s2,16(sp)
    80002b12:	e44e                	sd	s3,8(sp)
    80002b14:	e052                	sd	s4,0(sp)
    80002b16:	1800                	addi	s0,sp,48
    80002b18:	892a                	mv	s2,a0
    80002b1a:	84ae                	mv	s1,a1
    80002b1c:	89b2                	mv	s3,a2
    80002b1e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	e98080e7          	jalr	-360(ra) # 800019b8 <myproc>
  if(user_src){
    80002b28:	c08d                	beqz	s1,80002b4a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002b2a:	86d2                	mv	a3,s4
    80002b2c:	864e                	mv	a2,s3
    80002b2e:	85ca                	mv	a1,s2
    80002b30:	7928                	ld	a0,112(a0)
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	bd4080e7          	jalr	-1068(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002b3a:	70a2                	ld	ra,40(sp)
    80002b3c:	7402                	ld	s0,32(sp)
    80002b3e:	64e2                	ld	s1,24(sp)
    80002b40:	6942                	ld	s2,16(sp)
    80002b42:	69a2                	ld	s3,8(sp)
    80002b44:	6a02                	ld	s4,0(sp)
    80002b46:	6145                	addi	sp,sp,48
    80002b48:	8082                	ret
    memmove(dst, (char*)src, len);
    80002b4a:	000a061b          	sext.w	a2,s4
    80002b4e:	85ce                	mv	a1,s3
    80002b50:	854a                	mv	a0,s2
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	1ee080e7          	jalr	494(ra) # 80000d40 <memmove>
    return 0;
    80002b5a:	8526                	mv	a0,s1
    80002b5c:	bff9                	j	80002b3a <either_copyin+0x32>

0000000080002b5e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002b5e:	7159                	addi	sp,sp,-112
    80002b60:	f486                	sd	ra,104(sp)
    80002b62:	f0a2                	sd	s0,96(sp)
    80002b64:	eca6                	sd	s1,88(sp)
    80002b66:	e8ca                	sd	s2,80(sp)
    80002b68:	e4ce                	sd	s3,72(sp)
    80002b6a:	e0d2                	sd	s4,64(sp)
    80002b6c:	fc56                	sd	s5,56(sp)
    80002b6e:	f85a                	sd	s6,48(sp)
    80002b70:	f45e                	sd	s7,40(sp)
    80002b72:	f062                	sd	s8,32(sp)
    80002b74:	ec66                	sd	s9,24(sp)
    80002b76:	e86a                	sd	s10,16(sp)
    80002b78:	e46e                	sd	s11,8(sp)
    80002b7a:	1880                	addi	s0,sp,112
  [ZOMBIE]    "zombie  "
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b7c:	00005517          	auipc	a0,0x5
    80002b80:	54c50513          	addi	a0,a0,1356 # 800080c8 <digits+0x88>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	a04080e7          	jalr	-1532(ra) # 80000588 <printf>
  //Printing headers
  printf("PID\t");
    80002b8c:	00005517          	auipc	a0,0x5
    80002b90:	6fc50513          	addi	a0,a0,1788 # 80008288 <digits+0x248>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9f4080e7          	jalr	-1548(ra) # 80000588 <printf>
  if (schedulingpolicy == 2 || schedulingpolicy == 3) {
    80002b9c:	00006797          	auipc	a5,0x6
    80002ba0:	48c7a783          	lw	a5,1164(a5) # 80009028 <schedulingpolicy>
    80002ba4:	37f9                	addiw	a5,a5,-2
    80002ba6:	4705                	li	a4,1
    80002ba8:	08f77063          	bgeu	a4,a5,80002c28 <procdump+0xca>
    printf("Priority\t");
  }
  printf("State\t");
    80002bac:	00005517          	auipc	a0,0x5
    80002bb0:	6f450513          	addi	a0,a0,1780 # 800082a0 <digits+0x260>
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	9d4080e7          	jalr	-1580(ra) # 80000588 <printf>
  if (schedulingpolicy == 2 || schedulingpolicy == 3) {
    80002bbc:	00006797          	auipc	a5,0x6
    80002bc0:	46c7a783          	lw	a5,1132(a5) # 80009028 <schedulingpolicy>
    80002bc4:	37f9                	addiw	a5,a5,-2
    80002bc6:	4705                	li	a4,1
    80002bc8:	06f77963          	bgeu	a4,a5,80002c3a <procdump+0xdc>
    printf("\trtime\twtime\tnrun\t");
  }
  if (schedulingpolicy == 3) {
    80002bcc:	00006717          	auipc	a4,0x6
    80002bd0:	45c72703          	lw	a4,1116(a4) # 80009028 <schedulingpolicy>
    80002bd4:	478d                	li	a5,3
    80002bd6:	06f70b63          	beq	a4,a5,80002c4c <procdump+0xee>
    for (int i = 0; i < QCOUNT; i++) {
      printf("q%d\t", i);
    }
  }
  printf("\n");
    80002bda:	00005517          	auipc	a0,0x5
    80002bde:	4ee50513          	addi	a0,a0,1262 # 800080c8 <digits+0x88>
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	9a6080e7          	jalr	-1626(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002bea:	0000f497          	auipc	s1,0xf
    80002bee:	ae648493          	addi	s1,s1,-1306 # 800116d0 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bf2:	4b95                	li	s7,5
      state = states[p->state];
    else
      state = "???";
    80002bf4:	00005b17          	auipc	s6,0x5
    80002bf8:	68cb0b13          	addi	s6,s6,1676 # 80008280 <digits+0x240>
    printf("%d\t", p->pid);
    80002bfc:	00005997          	auipc	s3,0x5
    80002c00:	6cc98993          	addi	s3,s3,1740 # 800082c8 <digits+0x288>
    if (schedulingpolicy == 2) {
    80002c04:	00006917          	auipc	s2,0x6
    80002c08:	42490913          	addi	s2,s2,1060 # 80009028 <schedulingpolicy>
    80002c0c:	4a89                	li	s5,2
      int priority = (p->queuelevel == NOTQUEUED) ? -1 : p->queuelevel;
      printf("%d\t\t", priority);
    }
    printf("%s\t", state);
    if (schedulingpolicy == 2 || schedulingpolicy == 3) {
      uint waittime = (schedulingpolicy == 2) ? (ticks - p->createtime - p->totalrtime) : (ticks - p->queueentertime);
    80002c0e:	00006c97          	auipc	s9,0x6
    80002c12:	42ac8c93          	addi	s9,s9,1066 # 80009038 <ticks>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c16:	00005c17          	auipc	s8,0x5
    80002c1a:	72ac0c13          	addi	s8,s8,1834 # 80008340 <states.1845>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c1e:	00016a17          	auipc	s4,0x16
    80002c22:	8b2a0a13          	addi	s4,s4,-1870 # 800184d0 <queuetable>
    80002c26:	a04d                	j	80002cc8 <procdump+0x16a>
    printf("Priority\t");
    80002c28:	00005517          	auipc	a0,0x5
    80002c2c:	66850513          	addi	a0,a0,1640 # 80008290 <digits+0x250>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	958080e7          	jalr	-1704(ra) # 80000588 <printf>
    80002c38:	bf95                	j	80002bac <procdump+0x4e>
    printf("\trtime\twtime\tnrun\t");
    80002c3a:	00005517          	auipc	a0,0x5
    80002c3e:	66e50513          	addi	a0,a0,1646 # 800082a8 <digits+0x268>
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	946080e7          	jalr	-1722(ra) # 80000588 <printf>
    80002c4a:	b749                	j	80002bcc <procdump+0x6e>
    for (int i = 0; i < QCOUNT; i++) {
    80002c4c:	4481                	li	s1,0
      printf("q%d\t", i);
    80002c4e:	00005997          	auipc	s3,0x5
    80002c52:	67298993          	addi	s3,s3,1650 # 800082c0 <digits+0x280>
    for (int i = 0; i < QCOUNT; i++) {
    80002c56:	4915                	li	s2,5
      printf("q%d\t", i);
    80002c58:	85a6                	mv	a1,s1
    80002c5a:	854e                	mv	a0,s3
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	92c080e7          	jalr	-1748(ra) # 80000588 <printf>
    for (int i = 0; i < QCOUNT; i++) {
    80002c64:	2485                	addiw	s1,s1,1
    80002c66:	ff2499e3          	bne	s1,s2,80002c58 <procdump+0xfa>
    80002c6a:	bf85                	j	80002bda <procdump+0x7c>
    printf("%d\t", p->pid);
    80002c6c:	588c                	lw	a1,48(s1)
    80002c6e:	854e                	mv	a0,s3
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	918080e7          	jalr	-1768(ra) # 80000588 <printf>
    if (schedulingpolicy == 2) {
    80002c78:	00092783          	lw	a5,0(s2)
    80002c7c:	07578563          	beq	a5,s5,80002ce6 <procdump+0x188>
    else if (schedulingpolicy == 3) {
    80002c80:	470d                	li	a4,3
    80002c82:	08e78163          	beq	a5,a4,80002d04 <procdump+0x1a6>
    printf("%s\t", state);
    80002c86:	85ea                	mv	a1,s10
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	65050513          	addi	a0,a0,1616 # 800082d8 <digits+0x298>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	8f8080e7          	jalr	-1800(ra) # 80000588 <printf>
    if (schedulingpolicy == 2 || schedulingpolicy == 3) {
    80002c98:	00092783          	lw	a5,0(s2)
    80002c9c:	ffe7869b          	addiw	a3,a5,-2
    80002ca0:	4705                	li	a4,1
    80002ca2:	08d77163          	bgeu	a4,a3,80002d24 <procdump+0x1c6>
      printf("%d\t%d\t%d\t", p->totalrtime, waittime, p->schedulecount);
    }
    if (schedulingpolicy == 3) {
    80002ca6:	00092703          	lw	a4,0(s2)
    80002caa:	478d                	li	a5,3
    80002cac:	0af70563          	beq	a4,a5,80002d56 <procdump+0x1f8>
      for (int i = 0; i < QCOUNT; i++) {
        printf("%d\t", p->q[i]);
      }
    }
    printf("\n");
    80002cb0:	00005517          	auipc	a0,0x5
    80002cb4:	41850513          	addi	a0,a0,1048 # 800080c8 <digits+0x88>
    80002cb8:	ffffe097          	auipc	ra,0xffffe
    80002cbc:	8d0080e7          	jalr	-1840(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002cc0:	1b848493          	addi	s1,s1,440
    80002cc4:	0b448863          	beq	s1,s4,80002d74 <procdump+0x216>
    if(p->state == UNUSED)
    80002cc8:	4c9c                	lw	a5,24(s1)
    80002cca:	dbfd                	beqz	a5,80002cc0 <procdump+0x162>
      state = "???";
    80002ccc:	8d5a                	mv	s10,s6
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cce:	f8fbefe3          	bltu	s7,a5,80002c6c <procdump+0x10e>
    80002cd2:	1782                	slli	a5,a5,0x20
    80002cd4:	9381                	srli	a5,a5,0x20
    80002cd6:	078e                	slli	a5,a5,0x3
    80002cd8:	97e2                	add	a5,a5,s8
    80002cda:	0007bd03          	ld	s10,0(a5)
    80002cde:	f80d17e3          	bnez	s10,80002c6c <procdump+0x10e>
      state = "???";
    80002ce2:	8d5a                	mv	s10,s6
    80002ce4:	b761                	j	80002c6c <procdump+0x10e>
      printf("%d\t\t", dynamicpriority(p));
    80002ce6:	8526                	mv	a0,s1
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	730080e7          	jalr	1840(ra) # 80002418 <dynamicpriority>
    80002cf0:	85aa                	mv	a1,a0
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	5de50513          	addi	a0,a0,1502 # 800082d0 <digits+0x290>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	88e080e7          	jalr	-1906(ra) # 80000588 <printf>
    80002d02:	b751                	j	80002c86 <procdump+0x128>
      int priority = (p->queuelevel == NOTQUEUED) ? -1 : p->queuelevel;
    80002d04:	18c4a583          	lw	a1,396(s1)
    80002d08:	4785                	li	a5,1
    80002d0a:	00f58b63          	beq	a1,a5,80002d20 <procdump+0x1c2>
      printf("%d\t\t", priority);
    80002d0e:	00005517          	auipc	a0,0x5
    80002d12:	5c250513          	addi	a0,a0,1474 # 800082d0 <digits+0x290>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	872080e7          	jalr	-1934(ra) # 80000588 <printf>
    80002d1e:	b7a5                	j	80002c86 <procdump+0x128>
      int priority = (p->queuelevel == NOTQUEUED) ? -1 : p->queuelevel;
    80002d20:	55fd                	li	a1,-1
    80002d22:	b7f5                	j	80002d0e <procdump+0x1b0>
      uint waittime = (schedulingpolicy == 2) ? (ticks - p->createtime - p->totalrtime) : (ticks - p->queueentertime);
    80002d24:	03578263          	beq	a5,s5,80002d48 <procdump+0x1ea>
    80002d28:	000ca603          	lw	a2,0(s9)
    80002d2c:	1944a783          	lw	a5,404(s1)
    80002d30:	9e1d                	subw	a2,a2,a5
      printf("%d\t%d\t%d\t", p->totalrtime, waittime, p->schedulecount);
    80002d32:	44b4                	lw	a3,72(s1)
    80002d34:	40ec                	lw	a1,68(s1)
    80002d36:	00005517          	auipc	a0,0x5
    80002d3a:	5aa50513          	addi	a0,a0,1450 # 800082e0 <digits+0x2a0>
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	84a080e7          	jalr	-1974(ra) # 80000588 <printf>
    80002d46:	b785                	j	80002ca6 <procdump+0x148>
      uint waittime = (schedulingpolicy == 2) ? (ticks - p->createtime - p->totalrtime) : (ticks - p->queueentertime);
    80002d48:	54f0                	lw	a2,108(s1)
    80002d4a:	40fc                	lw	a5,68(s1)
    80002d4c:	9fb1                	addw	a5,a5,a2
    80002d4e:	000ca603          	lw	a2,0(s9)
    80002d52:	9e1d                	subw	a2,a2,a5
    80002d54:	bff9                	j	80002d32 <procdump+0x1d4>
    80002d56:	19848d13          	addi	s10,s1,408
      for (int i = 0; i < QCOUNT; i++) {
    80002d5a:	1ac48d93          	addi	s11,s1,428
        printf("%d\t", p->q[i]);
    80002d5e:	000d2583          	lw	a1,0(s10)
    80002d62:	854e                	mv	a0,s3
    80002d64:	ffffe097          	auipc	ra,0xffffe
    80002d68:	824080e7          	jalr	-2012(ra) # 80000588 <printf>
      for (int i = 0; i < QCOUNT; i++) {
    80002d6c:	0d11                	addi	s10,s10,4
    80002d6e:	ffbd18e3          	bne	s10,s11,80002d5e <procdump+0x200>
    80002d72:	bf3d                	j	80002cb0 <procdump+0x152>
  }
}
    80002d74:	70a6                	ld	ra,104(sp)
    80002d76:	7406                	ld	s0,96(sp)
    80002d78:	64e6                	ld	s1,88(sp)
    80002d7a:	6946                	ld	s2,80(sp)
    80002d7c:	69a6                	ld	s3,72(sp)
    80002d7e:	6a06                	ld	s4,64(sp)
    80002d80:	7ae2                	ld	s5,56(sp)
    80002d82:	7b42                	ld	s6,48(sp)
    80002d84:	7ba2                	ld	s7,40(sp)
    80002d86:	7c02                	ld	s8,32(sp)
    80002d88:	6ce2                	ld	s9,24(sp)
    80002d8a:	6d42                	ld	s10,16(sp)
    80002d8c:	6da2                	ld	s11,8(sp)
    80002d8e:	6165                	addi	sp,sp,112
    80002d90:	8082                	ret

0000000080002d92 <changepriority>:


int
changepriority(int new_priority, int pid, int* old_dp) {
    80002d92:	7139                	addi	sp,sp,-64
    80002d94:	fc06                	sd	ra,56(sp)
    80002d96:	f822                	sd	s0,48(sp)
    80002d98:	f426                	sd	s1,40(sp)
    80002d9a:	f04a                	sd	s2,32(sp)
    80002d9c:	ec4e                	sd	s3,24(sp)
    80002d9e:	e852                	sd	s4,16(sp)
    80002da0:	e456                	sd	s5,8(sp)
    80002da2:	0080                	addi	s0,sp,64
    80002da4:	8aaa                	mv	s5,a0
    80002da6:	892e                	mv	s2,a1
    80002da8:	8a32                	mv	s4,a2
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++) {
    80002daa:	0000f497          	auipc	s1,0xf
    80002dae:	92648493          	addi	s1,s1,-1754 # 800116d0 <proc>
    80002db2:	00015997          	auipc	s3,0x15
    80002db6:	71e98993          	addi	s3,s3,1822 # 800184d0 <queuetable>
    int toyield = 0;
    acquire(&p->lock);
    80002dba:	8526                	mv	a0,s1
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	e28080e7          	jalr	-472(ra) # 80000be4 <acquire>
    if (p->pid == pid) {
    80002dc4:	589c                	lw	a5,48(s1)
    80002dc6:	01278d63          	beq	a5,s2,80002de0 <changepriority+0x4e>

      release(&p->lock);
      if (toyield) yield();
      return old_priority;
    }
    release(&p->lock);
    80002dca:	8526                	mv	a0,s1
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002dd4:	1b848493          	addi	s1,s1,440
    80002dd8:	ff3491e3          	bne	s1,s3,80002dba <changepriority+0x28>
  }
  return -1;
    80002ddc:	59fd                	li	s3,-1
    80002dde:	a0a9                	j	80002e28 <changepriority+0x96>
      int old_priority = p->staticpriority;
    80002de0:	0344a983          	lw	s3,52(s1)
      *old_dp = dynamicpriority(p);
    80002de4:	8526                	mv	a0,s1
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	632080e7          	jalr	1586(ra) # 80002418 <dynamicpriority>
    80002dee:	00aa2023          	sw	a0,0(s4)
      p->staticpriority = min(100, new_priority);
    80002df2:	87d6                	mv	a5,s5
    80002df4:	06400713          	li	a4,100
    80002df8:	01575463          	bge	a4,s5,80002e00 <changepriority+0x6e>
    80002dfc:	06400793          	li	a5,100
    80002e00:	d8dc                	sw	a5,52(s1)
      p->runningticks = 0;
    80002e02:	0204ae23          	sw	zero,60(s1)
      p->sleepingticks = 0;
    80002e06:	0404a023          	sw	zero,64(s1)
      if (dynamicpriority(p) < *old_dp) {
    80002e0a:	8526                	mv	a0,s1
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	60c080e7          	jalr	1548(ra) # 80002418 <dynamicpriority>
    80002e14:	892a                	mv	s2,a0
    80002e16:	000a2a03          	lw	s4,0(s4)
      release(&p->lock);
    80002e1a:	8526                	mv	a0,s1
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	e7c080e7          	jalr	-388(ra) # 80000c98 <release>
      if (toyield) yield();
    80002e24:	01494c63          	blt	s2,s4,80002e3c <changepriority+0xaa>
}
    80002e28:	854e                	mv	a0,s3
    80002e2a:	70e2                	ld	ra,56(sp)
    80002e2c:	7442                	ld	s0,48(sp)
    80002e2e:	74a2                	ld	s1,40(sp)
    80002e30:	7902                	ld	s2,32(sp)
    80002e32:	69e2                	ld	s3,24(sp)
    80002e34:	6a42                	ld	s4,16(sp)
    80002e36:	6aa2                	ld	s5,8(sp)
    80002e38:	6121                	addi	sp,sp,64
    80002e3a:	8082                	ret
      if (toyield) yield();
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	88a080e7          	jalr	-1910(ra) # 800026c6 <yield>
    80002e44:	b7d5                	j	80002e28 <changepriority+0x96>

0000000080002e46 <waitx>:
int
waitx(uint64 addr, uint* rtime, uint* wtime)
{
    80002e46:	711d                	addi	sp,sp,-96
    80002e48:	ec86                	sd	ra,88(sp)
    80002e4a:	e8a2                	sd	s0,80(sp)
    80002e4c:	e4a6                	sd	s1,72(sp)
    80002e4e:	e0ca                	sd	s2,64(sp)
    80002e50:	fc4e                	sd	s3,56(sp)
    80002e52:	f852                	sd	s4,48(sp)
    80002e54:	f456                	sd	s5,40(sp)
    80002e56:	f05a                	sd	s6,32(sp)
    80002e58:	ec5e                	sd	s7,24(sp)
    80002e5a:	e862                	sd	s8,16(sp)
    80002e5c:	e466                	sd	s9,8(sp)
    80002e5e:	e06a                	sd	s10,0(sp)
    80002e60:	1080                	addi	s0,sp,96
    80002e62:	8b2a                	mv	s6,a0
    80002e64:	8c2e                	mv	s8,a1
    80002e66:	8bb2                	mv	s7,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	b50080e7          	jalr	-1200(ra) # 800019b8 <myproc>
    80002e70:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002e72:	0000e517          	auipc	a0,0xe
    80002e76:	44650513          	addi	a0,a0,1094 # 800112b8 <wait_lock>
    80002e7a:	ffffe097          	auipc	ra,0xffffe
    80002e7e:	d6a080e7          	jalr	-662(ra) # 80000be4 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002e82:	4c81                	li	s9,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002e84:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002e86:	00015997          	auipc	s3,0x15
    80002e8a:	64a98993          	addi	s3,s3,1610 # 800184d0 <queuetable>
        havekids = 1;
    80002e8e:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002e90:	0000ed17          	auipc	s10,0xe
    80002e94:	428d0d13          	addi	s10,s10,1064 # 800112b8 <wait_lock>
    havekids = 0;
    80002e98:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002e9a:	0000f497          	auipc	s1,0xf
    80002e9e:	83648493          	addi	s1,s1,-1994 # 800116d0 <proc>
    80002ea2:	a059                	j	80002f28 <waitx+0xe2>
          pid = np->pid;
    80002ea4:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002ea8:	1ac4a703          	lw	a4,428(s1)
    80002eac:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002eb0:	1b04a783          	lw	a5,432(s1)
    80002eb4:	9f3d                	addw	a4,a4,a5
    80002eb6:	1b44a783          	lw	a5,436(s1)
    80002eba:	9f99                	subw	a5,a5,a4
    80002ebc:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002ec0:	000b0e63          	beqz	s6,80002edc <waitx+0x96>
    80002ec4:	4691                	li	a3,4
    80002ec6:	02c48613          	addi	a2,s1,44
    80002eca:	85da                	mv	a1,s6
    80002ecc:	07093503          	ld	a0,112(s2)
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	7aa080e7          	jalr	1962(ra) # 8000167a <copyout>
    80002ed8:	02054563          	bltz	a0,80002f02 <waitx+0xbc>
          freeproc(np);
    80002edc:	8526                	mv	a0,s1
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	c8c080e7          	jalr	-884(ra) # 80001b6a <freeproc>
          release(&np->lock);
    80002ee6:	8526                	mv	a0,s1
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	db0080e7          	jalr	-592(ra) # 80000c98 <release>
          release(&wait_lock);
    80002ef0:	0000e517          	auipc	a0,0xe
    80002ef4:	3c850513          	addi	a0,a0,968 # 800112b8 <wait_lock>
    80002ef8:	ffffe097          	auipc	ra,0xffffe
    80002efc:	da0080e7          	jalr	-608(ra) # 80000c98 <release>
          return pid;
    80002f00:	a09d                	j	80002f66 <waitx+0x120>
            release(&np->lock);
    80002f02:	8526                	mv	a0,s1
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	d94080e7          	jalr	-620(ra) # 80000c98 <release>
            release(&wait_lock);
    80002f0c:	0000e517          	auipc	a0,0xe
    80002f10:	3ac50513          	addi	a0,a0,940 # 800112b8 <wait_lock>
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	d84080e7          	jalr	-636(ra) # 80000c98 <release>
            return -1;
    80002f1c:	59fd                	li	s3,-1
    80002f1e:	a0a1                	j	80002f66 <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){
    80002f20:	1b848493          	addi	s1,s1,440
    80002f24:	03348463          	beq	s1,s3,80002f4c <waitx+0x106>
      if(np->parent == p){
    80002f28:	68bc                	ld	a5,80(s1)
    80002f2a:	ff279be3          	bne	a5,s2,80002f20 <waitx+0xda>
        acquire(&np->lock);
    80002f2e:	8526                	mv	a0,s1
    80002f30:	ffffe097          	auipc	ra,0xffffe
    80002f34:	cb4080e7          	jalr	-844(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002f38:	4c9c                	lw	a5,24(s1)
    80002f3a:	f74785e3          	beq	a5,s4,80002ea4 <waitx+0x5e>
        release(&np->lock);
    80002f3e:	8526                	mv	a0,s1
    80002f40:	ffffe097          	auipc	ra,0xffffe
    80002f44:	d58080e7          	jalr	-680(ra) # 80000c98 <release>
        havekids = 1;
    80002f48:	8756                	mv	a4,s5
    80002f4a:	bfd9                	j	80002f20 <waitx+0xda>
    if(!havekids || p->killed){
    80002f4c:	c701                	beqz	a4,80002f54 <waitx+0x10e>
    80002f4e:	02892783          	lw	a5,40(s2)
    80002f52:	cb8d                	beqz	a5,80002f84 <waitx+0x13e>
      release(&wait_lock);
    80002f54:	0000e517          	auipc	a0,0xe
    80002f58:	36450513          	addi	a0,a0,868 # 800112b8 <wait_lock>
    80002f5c:	ffffe097          	auipc	ra,0xffffe
    80002f60:	d3c080e7          	jalr	-708(ra) # 80000c98 <release>
      return -1;
    80002f64:	59fd                	li	s3,-1
  }
    80002f66:	854e                	mv	a0,s3
    80002f68:	60e6                	ld	ra,88(sp)
    80002f6a:	6446                	ld	s0,80(sp)
    80002f6c:	64a6                	ld	s1,72(sp)
    80002f6e:	6906                	ld	s2,64(sp)
    80002f70:	79e2                	ld	s3,56(sp)
    80002f72:	7a42                	ld	s4,48(sp)
    80002f74:	7aa2                	ld	s5,40(sp)
    80002f76:	7b02                	ld	s6,32(sp)
    80002f78:	6be2                	ld	s7,24(sp)
    80002f7a:	6c42                	ld	s8,16(sp)
    80002f7c:	6ca2                	ld	s9,8(sp)
    80002f7e:	6d02                	ld	s10,0(sp)
    80002f80:	6125                	addi	sp,sp,96
    80002f82:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002f84:	85ea                	mv	a1,s10
    80002f86:	854a                	mv	a0,s2
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	77a080e7          	jalr	1914(ra) # 80002702 <sleep>
    havekids = 0;
    80002f90:	b721                	j	80002e98 <waitx+0x52>

0000000080002f92 <push>:
#include "proc.h"
#include "defs.h"

void
push(struct PriorityQueue* q, struct proc* p) {
  q->queue[q->front++] = p;
    80002f92:	411c                	lw	a5,0(a0)
    80002f94:	00379713          	slli	a4,a5,0x3
    80002f98:	972a                	add	a4,a4,a0
    80002f9a:	e70c                	sd	a1,8(a4)
    80002f9c:	2785                	addiw	a5,a5,1
  q->front %= QSIZE;
    80002f9e:	04100713          	li	a4,65
    80002fa2:	02e7e7bb          	remw	a5,a5,a4
    80002fa6:	0007871b          	sext.w	a4,a5
    80002faa:	c11c                	sw	a5,0(a0)
  if (q->front == q->back) {
    80002fac:	415c                	lw	a5,4(a0)
    80002fae:	00e78563          	beq	a5,a4,80002fb8 <push+0x26>
    panic("Full queue push");
  }
  p->queuestate = QUEUED;
    80002fb2:	1805a423          	sw	zero,392(a1)
    80002fb6:	8082                	ret
push(struct PriorityQueue* q, struct proc* p) {
    80002fb8:	1141                	addi	sp,sp,-16
    80002fba:	e406                	sd	ra,8(sp)
    80002fbc:	e022                	sd	s0,0(sp)
    80002fbe:	0800                	addi	s0,sp,16
    panic("Full queue push");
    80002fc0:	00005517          	auipc	a0,0x5
    80002fc4:	3b050513          	addi	a0,a0,944 # 80008370 <states.1845+0x30>
    80002fc8:	ffffd097          	auipc	ra,0xffffd
    80002fcc:	576080e7          	jalr	1398(ra) # 8000053e <panic>

0000000080002fd0 <pop>:
}

struct proc*
pop(struct PriorityQueue* q)
{
  if (q->back == q->front) {
    80002fd0:	4158                	lw	a4,4(a0)
    80002fd2:	4114                	lw	a3,0(a0)
    80002fd4:	02e68163          	beq	a3,a4,80002ff6 <pop+0x26>
    80002fd8:	87aa                	mv	a5,a0
    panic("Empty queue pop");
  }
  struct proc* p = q->queue[q->back];
    80002fda:	070e                	slli	a4,a4,0x3
    80002fdc:	972a                	add	a4,a4,a0
    80002fde:	6708                	ld	a0,8(a4)
  p->queuestate = NOTQUEUED;
    80002fe0:	4705                	li	a4,1
    80002fe2:	18e52423          	sw	a4,392(a0)
  q->back++;
    80002fe6:	43d8                	lw	a4,4(a5)
    80002fe8:	2705                	addiw	a4,a4,1
  q->back %= QSIZE;
    80002fea:	04100693          	li	a3,65
    80002fee:	02d7673b          	remw	a4,a4,a3
    80002ff2:	c3d8                	sw	a4,4(a5)
  return p;
}
    80002ff4:	8082                	ret
{
    80002ff6:	1141                	addi	sp,sp,-16
    80002ff8:	e406                	sd	ra,8(sp)
    80002ffa:	e022                	sd	s0,0(sp)
    80002ffc:	0800                	addi	s0,sp,16
    panic("Empty queue pop");
    80002ffe:	00005517          	auipc	a0,0x5
    80003002:	38250513          	addi	a0,a0,898 # 80008380 <states.1845+0x40>
    80003006:	ffffd097          	auipc	ra,0xffffd
    8000300a:	538080e7          	jalr	1336(ra) # 8000053e <panic>

000000008000300e <remove>:

void
remove(struct PriorityQueue* q, struct proc* p) {
    8000300e:	1141                	addi	sp,sp,-16
    80003010:	e422                	sd	s0,8(sp)
    80003012:	0800                	addi	s0,sp,16
  if (p->queuestate == NOTQUEUED) return;
    80003014:	1885a703          	lw	a4,392(a1)
    80003018:	4785                	li	a5,1
    8000301a:	06f70463          	beq	a4,a5,80003082 <remove+0x74>
  for (int i = q->back; i != q->front; i = (i + 1) % QSIZE) {
    8000301e:	415c                	lw	a5,4(a0)
    80003020:	4114                	lw	a3,0(a0)
    80003022:	06d78063          	beq	a5,a3,80003082 <remove+0x74>
    80003026:	04100613          	li	a2,65
    if (q->queue[i] == p) {
    8000302a:	00379713          	slli	a4,a5,0x3
    8000302e:	972a                	add	a4,a4,a0
    80003030:	6718                	ld	a4,8(a4)
    80003032:	00b70863          	beq	a4,a1,80003042 <remove+0x34>
  for (int i = q->back; i != q->front; i = (i + 1) % QSIZE) {
    80003036:	2785                	addiw	a5,a5,1
    80003038:	02c7e7bb          	remw	a5,a5,a2
    8000303c:	fed797e3          	bne	a5,a3,8000302a <remove+0x1c>
    80003040:	a089                	j	80003082 <remove+0x74>
      p->queuestate = NOTQUEUED;
    80003042:	4705                	li	a4,1
    80003044:	18e5a423          	sw	a4,392(a1)
      for (int j = i + 1; j != q->front; j = (j + 1) % QSIZE) {
    80003048:	2785                	addiw	a5,a5,1
    8000304a:	410c                	lw	a1,0(a0)
    8000304c:	02b78463          	beq	a5,a1,80003074 <remove+0x66>
        q->queue[(j - 1 + QSIZE) % QSIZE] = q->queue[j];
    80003050:	04100693          	li	a3,65
    80003054:	00379713          	slli	a4,a5,0x3
    80003058:	972a                	add	a4,a4,a0
    8000305a:	6710                	ld	a2,8(a4)
    8000305c:	0407871b          	addiw	a4,a5,64
    80003060:	02d7673b          	remw	a4,a4,a3
    80003064:	070e                	slli	a4,a4,0x3
    80003066:	972a                	add	a4,a4,a0
    80003068:	e710                	sd	a2,8(a4)
      for (int j = i + 1; j != q->front; j = (j + 1) % QSIZE) {
    8000306a:	2785                	addiw	a5,a5,1
    8000306c:	02d7e7bb          	remw	a5,a5,a3
    80003070:	feb792e3          	bne	a5,a1,80003054 <remove+0x46>
      }
      q->front = (q->front - 1 + QSIZE) % QSIZE;
    80003074:	0405859b          	addiw	a1,a1,64
    80003078:	04100793          	li	a5,65
    8000307c:	02f5e5bb          	remw	a1,a1,a5
    80003080:	c10c                	sw	a1,0(a0)
      break;
    }
  }
}
    80003082:	6422                	ld	s0,8(sp)
    80003084:	0141                	addi	sp,sp,16
    80003086:	8082                	ret

0000000080003088 <empty>:

int
empty(struct PriorityQueue q) {
    80003088:	1141                	addi	sp,sp,-16
    8000308a:	e422                	sd	s0,8(sp)
    8000308c:	0800                	addi	s0,sp,16
  return (q.front - q.back + QSIZE) % QSIZE == 0;
    8000308e:	411c                	lw	a5,0(a0)
    80003090:	4148                	lw	a0,4(a0)
    80003092:	40a7853b          	subw	a0,a5,a0
    80003096:	0415051b          	addiw	a0,a0,65
    8000309a:	04100793          	li	a5,65
    8000309e:	02f5653b          	remw	a0,a0,a5
}
    800030a2:	00153513          	seqz	a0,a0
    800030a6:	6422                	ld	s0,8(sp)
    800030a8:	0141                	addi	sp,sp,16
    800030aa:	8082                	ret

00000000800030ac <swtch>:
    800030ac:	00153023          	sd	ra,0(a0)
    800030b0:	00253423          	sd	sp,8(a0)
    800030b4:	e900                	sd	s0,16(a0)
    800030b6:	ed04                	sd	s1,24(a0)
    800030b8:	03253023          	sd	s2,32(a0)
    800030bc:	03353423          	sd	s3,40(a0)
    800030c0:	03453823          	sd	s4,48(a0)
    800030c4:	03553c23          	sd	s5,56(a0)
    800030c8:	05653023          	sd	s6,64(a0)
    800030cc:	05753423          	sd	s7,72(a0)
    800030d0:	05853823          	sd	s8,80(a0)
    800030d4:	05953c23          	sd	s9,88(a0)
    800030d8:	07a53023          	sd	s10,96(a0)
    800030dc:	07b53423          	sd	s11,104(a0)
    800030e0:	0005b083          	ld	ra,0(a1)
    800030e4:	0085b103          	ld	sp,8(a1)
    800030e8:	6980                	ld	s0,16(a1)
    800030ea:	6d84                	ld	s1,24(a1)
    800030ec:	0205b903          	ld	s2,32(a1)
    800030f0:	0285b983          	ld	s3,40(a1)
    800030f4:	0305ba03          	ld	s4,48(a1)
    800030f8:	0385ba83          	ld	s5,56(a1)
    800030fc:	0405bb03          	ld	s6,64(a1)
    80003100:	0485bb83          	ld	s7,72(a1)
    80003104:	0505bc03          	ld	s8,80(a1)
    80003108:	0585bc83          	ld	s9,88(a1)
    8000310c:	0605bd03          	ld	s10,96(a1)
    80003110:	0685bd83          	ld	s11,104(a1)
    80003114:	8082                	ret

0000000080003116 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003116:	1141                	addi	sp,sp,-16
    80003118:	e406                	sd	ra,8(sp)
    8000311a:	e022                	sd	s0,0(sp)
    8000311c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000311e:	00005597          	auipc	a1,0x5
    80003122:	27258593          	addi	a1,a1,626 # 80008390 <states.1845+0x50>
    80003126:	00016517          	auipc	a0,0x16
    8000312a:	dfa50513          	addi	a0,a0,-518 # 80018f20 <tickslock>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	a26080e7          	jalr	-1498(ra) # 80000b54 <initlock>
}
    80003136:	60a2                	ld	ra,8(sp)
    80003138:	6402                	ld	s0,0(sp)
    8000313a:	0141                	addi	sp,sp,16
    8000313c:	8082                	ret

000000008000313e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000313e:	1141                	addi	sp,sp,-16
    80003140:	e422                	sd	s0,8(sp)
    80003142:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003144:	00003797          	auipc	a5,0x3
    80003148:	74c78793          	addi	a5,a5,1868 # 80006890 <kernelvec>
    8000314c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003150:	6422                	ld	s0,8(sp)
    80003152:	0141                	addi	sp,sp,16
    80003154:	8082                	ret

0000000080003156 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003156:	1141                	addi	sp,sp,-16
    80003158:	e406                	sd	ra,8(sp)
    8000315a:	e022                	sd	s0,0(sp)
    8000315c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000315e:	fffff097          	auipc	ra,0xfffff
    80003162:	85a080e7          	jalr	-1958(ra) # 800019b8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003166:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000316a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000316c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003170:	00004617          	auipc	a2,0x4
    80003174:	e9060613          	addi	a2,a2,-368 # 80007000 <_trampoline>
    80003178:	00004697          	auipc	a3,0x4
    8000317c:	e8868693          	addi	a3,a3,-376 # 80007000 <_trampoline>
    80003180:	8e91                	sub	a3,a3,a2
    80003182:	040007b7          	lui	a5,0x4000
    80003186:	17fd                	addi	a5,a5,-1
    80003188:	07b2                	slli	a5,a5,0xc
    8000318a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000318c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003190:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003192:	180026f3          	csrr	a3,satp
    80003196:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003198:	7d38                	ld	a4,120(a0)
    8000319a:	6d34                	ld	a3,88(a0)
    8000319c:	6585                	lui	a1,0x1
    8000319e:	96ae                	add	a3,a3,a1
    800031a0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800031a2:	7d38                	ld	a4,120(a0)
    800031a4:	00000697          	auipc	a3,0x0
    800031a8:	14668693          	addi	a3,a3,326 # 800032ea <usertrap>
    800031ac:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800031ae:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800031b0:	8692                	mv	a3,tp
    800031b2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031b4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800031b8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800031bc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031c0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800031c4:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031c6:	6f18                	ld	a4,24(a4)
    800031c8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800031cc:	792c                	ld	a1,112(a0)
    800031ce:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800031d0:	00004717          	auipc	a4,0x4
    800031d4:	ec070713          	addi	a4,a4,-320 # 80007090 <userret>
    800031d8:	8f11                	sub	a4,a4,a2
    800031da:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800031dc:	577d                	li	a4,-1
    800031de:	177e                	slli	a4,a4,0x3f
    800031e0:	8dd9                	or	a1,a1,a4
    800031e2:	02000537          	lui	a0,0x2000
    800031e6:	157d                	addi	a0,a0,-1
    800031e8:	0536                	slli	a0,a0,0xd
    800031ea:	9782                	jalr	a5
}
    800031ec:	60a2                	ld	ra,8(sp)
    800031ee:	6402                	ld	s0,0(sp)
    800031f0:	0141                	addi	sp,sp,16
    800031f2:	8082                	ret

00000000800031f4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800031f4:	1101                	addi	sp,sp,-32
    800031f6:	ec06                	sd	ra,24(sp)
    800031f8:	e822                	sd	s0,16(sp)
    800031fa:	e426                	sd	s1,8(sp)
    800031fc:	e04a                	sd	s2,0(sp)
    800031fe:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003200:	00016917          	auipc	s2,0x16
    80003204:	d2090913          	addi	s2,s2,-736 # 80018f20 <tickslock>
    80003208:	854a                	mv	a0,s2
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	9da080e7          	jalr	-1574(ra) # 80000be4 <acquire>
  ticks++;
    80003212:	00006497          	auipc	s1,0x6
    80003216:	e2648493          	addi	s1,s1,-474 # 80009038 <ticks>
    8000321a:	409c                	lw	a5,0(s1)
    8000321c:	2785                	addiw	a5,a5,1
    8000321e:	c09c                	sw	a5,0(s1)
  updatetime();
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	d44080e7          	jalr	-700(ra) # 80001f64 <updatetime>
  wakeup(&ticks);
    80003228:	8526                	mv	a0,s1
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	664080e7          	jalr	1636(ra) # 8000288e <wakeup>
  release(&tickslock);
    80003232:	854a                	mv	a0,s2
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	a64080e7          	jalr	-1436(ra) # 80000c98 <release>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6902                	ld	s2,0(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret

0000000080003248 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003248:	1101                	addi	sp,sp,-32
    8000324a:	ec06                	sd	ra,24(sp)
    8000324c:	e822                	sd	s0,16(sp)
    8000324e:	e426                	sd	s1,8(sp)
    80003250:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003252:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003256:	00074d63          	bltz	a4,80003270 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000325a:	57fd                	li	a5,-1
    8000325c:	17fe                	slli	a5,a5,0x3f
    8000325e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003260:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003262:	06f70363          	beq	a4,a5,800032c8 <devintr+0x80>
  }
}
    80003266:	60e2                	ld	ra,24(sp)
    80003268:	6442                	ld	s0,16(sp)
    8000326a:	64a2                	ld	s1,8(sp)
    8000326c:	6105                	addi	sp,sp,32
    8000326e:	8082                	ret
     (scause & 0xff) == 9){
    80003270:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003274:	46a5                	li	a3,9
    80003276:	fed792e3          	bne	a5,a3,8000325a <devintr+0x12>
    int irq = plic_claim();
    8000327a:	00003097          	auipc	ra,0x3
    8000327e:	71e080e7          	jalr	1822(ra) # 80006998 <plic_claim>
    80003282:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003284:	47a9                	li	a5,10
    80003286:	02f50763          	beq	a0,a5,800032b4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000328a:	4785                	li	a5,1
    8000328c:	02f50963          	beq	a0,a5,800032be <devintr+0x76>
    return 1;
    80003290:	4505                	li	a0,1
    } else if(irq){
    80003292:	d8f1                	beqz	s1,80003266 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003294:	85a6                	mv	a1,s1
    80003296:	00005517          	auipc	a0,0x5
    8000329a:	10250513          	addi	a0,a0,258 # 80008398 <states.1845+0x58>
    8000329e:	ffffd097          	auipc	ra,0xffffd
    800032a2:	2ea080e7          	jalr	746(ra) # 80000588 <printf>
      plic_complete(irq);
    800032a6:	8526                	mv	a0,s1
    800032a8:	00003097          	auipc	ra,0x3
    800032ac:	714080e7          	jalr	1812(ra) # 800069bc <plic_complete>
    return 1;
    800032b0:	4505                	li	a0,1
    800032b2:	bf55                	j	80003266 <devintr+0x1e>
      uartintr();
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	6f4080e7          	jalr	1780(ra) # 800009a8 <uartintr>
    800032bc:	b7ed                	j	800032a6 <devintr+0x5e>
      virtio_disk_intr();
    800032be:	00004097          	auipc	ra,0x4
    800032c2:	bde080e7          	jalr	-1058(ra) # 80006e9c <virtio_disk_intr>
    800032c6:	b7c5                	j	800032a6 <devintr+0x5e>
    if(cpuid() == 0){
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	6c4080e7          	jalr	1732(ra) # 8000198c <cpuid>
    800032d0:	c901                	beqz	a0,800032e0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800032d2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800032d6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800032d8:	14479073          	csrw	sip,a5
    return 2;
    800032dc:	4509                	li	a0,2
    800032de:	b761                	j	80003266 <devintr+0x1e>
      clockintr();
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	f14080e7          	jalr	-236(ra) # 800031f4 <clockintr>
    800032e8:	b7ed                	j	800032d2 <devintr+0x8a>

00000000800032ea <usertrap>:
{
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	e426                	sd	s1,8(sp)
    800032f2:	e04a                	sd	s2,0(sp)
    800032f4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032f6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800032fa:	1007f793          	andi	a5,a5,256
    800032fe:	e3ad                	bnez	a5,80003360 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003300:	00003797          	auipc	a5,0x3
    80003304:	59078793          	addi	a5,a5,1424 # 80006890 <kernelvec>
    80003308:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	6ac080e7          	jalr	1708(ra) # 800019b8 <myproc>
    80003314:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003316:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003318:	14102773          	csrr	a4,sepc
    8000331c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000331e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003322:	47a1                	li	a5,8
    80003324:	04f71c63          	bne	a4,a5,8000337c <usertrap+0x92>
    if(p->killed)
    80003328:	551c                	lw	a5,40(a0)
    8000332a:	e3b9                	bnez	a5,80003370 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000332c:	7cb8                	ld	a4,120(s1)
    8000332e:	6f1c                	ld	a5,24(a4)
    80003330:	0791                	addi	a5,a5,4
    80003332:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003334:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003338:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000333c:	10079073          	csrw	sstatus,a5
    syscall();
    80003340:	00000097          	auipc	ra,0x0
    80003344:	390080e7          	jalr	912(ra) # 800036d0 <syscall>
  if(p->killed)
    80003348:	549c                	lw	a5,40(s1)
    8000334a:	e3f1                	bnez	a5,8000340e <usertrap+0x124>
  usertrapret();
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	e0a080e7          	jalr	-502(ra) # 80003156 <usertrapret>
}
    80003354:	60e2                	ld	ra,24(sp)
    80003356:	6442                	ld	s0,16(sp)
    80003358:	64a2                	ld	s1,8(sp)
    8000335a:	6902                	ld	s2,0(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret
    panic("usertrap: not from user mode");
    80003360:	00005517          	auipc	a0,0x5
    80003364:	05850513          	addi	a0,a0,88 # 800083b8 <states.1845+0x78>
    80003368:	ffffd097          	auipc	ra,0xffffd
    8000336c:	1d6080e7          	jalr	470(ra) # 8000053e <panic>
      exit(-1);
    80003370:	557d                	li	a0,-1
    80003372:	fffff097          	auipc	ra,0xfffff
    80003376:	5ec080e7          	jalr	1516(ra) # 8000295e <exit>
    8000337a:	bf4d                	j	8000332c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	ecc080e7          	jalr	-308(ra) # 80003248 <devintr>
    80003384:	892a                	mv	s2,a0
    80003386:	c501                	beqz	a0,8000338e <usertrap+0xa4>
  if(p->killed)
    80003388:	549c                	lw	a5,40(s1)
    8000338a:	c3a1                	beqz	a5,800033ca <usertrap+0xe0>
    8000338c:	a815                	j	800033c0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000338e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003392:	5890                	lw	a2,48(s1)
    80003394:	00005517          	auipc	a0,0x5
    80003398:	04450513          	addi	a0,a0,68 # 800083d8 <states.1845+0x98>
    8000339c:	ffffd097          	auipc	ra,0xffffd
    800033a0:	1ec080e7          	jalr	492(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033a4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800033a8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800033ac:	00005517          	auipc	a0,0x5
    800033b0:	05c50513          	addi	a0,a0,92 # 80008408 <states.1845+0xc8>
    800033b4:	ffffd097          	auipc	ra,0xffffd
    800033b8:	1d4080e7          	jalr	468(ra) # 80000588 <printf>
    p->killed = 1;
    800033bc:	4785                	li	a5,1
    800033be:	d49c                	sw	a5,40(s1)
    exit(-1);
    800033c0:	557d                	li	a0,-1
    800033c2:	fffff097          	auipc	ra,0xfffff
    800033c6:	59c080e7          	jalr	1436(ra) # 8000295e <exit>
  if(which_dev == 2) {
    800033ca:	4789                	li	a5,2
    800033cc:	f8f910e3          	bne	s2,a5,8000334c <usertrap+0x62>
    if (schedulingpolicy == 0)
    800033d0:	00006797          	auipc	a5,0x6
    800033d4:	c587a783          	lw	a5,-936(a5) # 80009028 <schedulingpolicy>
    800033d8:	cf8d                	beqz	a5,80003412 <usertrap+0x128>
    else if (schedulingpolicy == 3) {
    800033da:	470d                	li	a4,3
    800033dc:	f6e798e3          	bne	a5,a4,8000334c <usertrap+0x62>
      struct proc *p = myproc();
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	5d8080e7          	jalr	1496(ra) # 800019b8 <myproc>
    800033e8:	84aa                	mv	s1,a0
      if (p->runningticks >= (1 << p->queuelevel)) {
    800033ea:	18c52703          	lw	a4,396(a0)
    800033ee:	5d5c                	lw	a5,60(a0)
    800033f0:	00e7d7bb          	srlw	a5,a5,a4
    800033f4:	e785                	bnez	a5,8000341c <usertrap+0x132>
      if (getpreempted(p->queuelevel)) {
    800033f6:	18c4a503          	lw	a0,396(s1)
    800033fa:	fffff097          	auipc	ra,0xfffff
    800033fe:	c22080e7          	jalr	-990(ra) # 8000201c <getpreempted>
    80003402:	d529                	beqz	a0,8000334c <usertrap+0x62>
        yield();
    80003404:	fffff097          	auipc	ra,0xfffff
    80003408:	2c2080e7          	jalr	706(ra) # 800026c6 <yield>
    8000340c:	b781                	j	8000334c <usertrap+0x62>
  int which_dev = 0;
    8000340e:	4901                	li	s2,0
    80003410:	bf45                	j	800033c0 <usertrap+0xd6>
      yield();
    80003412:	fffff097          	auipc	ra,0xfffff
    80003416:	2b4080e7          	jalr	692(ra) # 800026c6 <yield>
    8000341a:	bf0d                	j	8000334c <usertrap+0x62>
        p->queuelevel = min(p->queuelevel + 1, QCOUNT);
    8000341c:	87ba                	mv	a5,a4
    8000341e:	4691                	li	a3,4
    80003420:	00e6d363          	bge	a3,a4,80003426 <usertrap+0x13c>
    80003424:	4791                	li	a5,4
    80003426:	2785                	addiw	a5,a5,1
    80003428:	18f4a623          	sw	a5,396(s1)
        yield();
    8000342c:	fffff097          	auipc	ra,0xfffff
    80003430:	29a080e7          	jalr	666(ra) # 800026c6 <yield>
    80003434:	b7c9                	j	800033f6 <usertrap+0x10c>

0000000080003436 <kerneltrap>:
{
    80003436:	7179                	addi	sp,sp,-48
    80003438:	f406                	sd	ra,40(sp)
    8000343a:	f022                	sd	s0,32(sp)
    8000343c:	ec26                	sd	s1,24(sp)
    8000343e:	e84a                	sd	s2,16(sp)
    80003440:	e44e                	sd	s3,8(sp)
    80003442:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003444:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003448:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000344c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003450:	1004f793          	andi	a5,s1,256
    80003454:	cb85                	beqz	a5,80003484 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003456:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000345a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000345c:	ef85                	bnez	a5,80003494 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	dea080e7          	jalr	-534(ra) # 80003248 <devintr>
    80003466:	cd1d                	beqz	a0,800034a4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80003468:	4789                	li	a5,2
    8000346a:	06f50a63          	beq	a0,a5,800034de <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000346e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003472:	10049073          	csrw	sstatus,s1
}
    80003476:	70a2                	ld	ra,40(sp)
    80003478:	7402                	ld	s0,32(sp)
    8000347a:	64e2                	ld	s1,24(sp)
    8000347c:	6942                	ld	s2,16(sp)
    8000347e:	69a2                	ld	s3,8(sp)
    80003480:	6145                	addi	sp,sp,48
    80003482:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	fa450513          	addi	a0,a0,-92 # 80008428 <states.1845+0xe8>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	0b2080e7          	jalr	178(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003494:	00005517          	auipc	a0,0x5
    80003498:	fbc50513          	addi	a0,a0,-68 # 80008450 <states.1845+0x110>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	0a2080e7          	jalr	162(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800034a4:	85ce                	mv	a1,s3
    800034a6:	00005517          	auipc	a0,0x5
    800034aa:	fca50513          	addi	a0,a0,-54 # 80008470 <states.1845+0x130>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	0da080e7          	jalr	218(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034b6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800034ba:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	fc250513          	addi	a0,a0,-62 # 80008480 <states.1845+0x140>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	0c2080e7          	jalr	194(ra) # 80000588 <printf>
    panic("kerneltrap");
    800034ce:	00005517          	auipc	a0,0x5
    800034d2:	fca50513          	addi	a0,a0,-54 # 80008498 <states.1845+0x158>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	068080e7          	jalr	104(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    800034de:	ffffe097          	auipc	ra,0xffffe
    800034e2:	4da080e7          	jalr	1242(ra) # 800019b8 <myproc>
    800034e6:	d541                	beqz	a0,8000346e <kerneltrap+0x38>
    800034e8:	ffffe097          	auipc	ra,0xffffe
    800034ec:	4d0080e7          	jalr	1232(ra) # 800019b8 <myproc>
    800034f0:	4d18                	lw	a4,24(a0)
    800034f2:	4791                	li	a5,4
    800034f4:	f6f71de3          	bne	a4,a5,8000346e <kerneltrap+0x38>
    if (schedulingpolicy == 0)
    800034f8:	00006797          	auipc	a5,0x6
    800034fc:	b307a783          	lw	a5,-1232(a5) # 80009028 <schedulingpolicy>
    80003500:	cb9d                	beqz	a5,80003536 <kerneltrap+0x100>
    else if (schedulingpolicy == 3) {
    80003502:	470d                	li	a4,3
    80003504:	f6e795e3          	bne	a5,a4,8000346e <kerneltrap+0x38>
      struct proc *p = myproc();
    80003508:	ffffe097          	auipc	ra,0xffffe
    8000350c:	4b0080e7          	jalr	1200(ra) # 800019b8 <myproc>
    80003510:	89aa                	mv	s3,a0
      if (p->runningticks >= (1 << p->queuelevel)) {
    80003512:	18c52703          	lw	a4,396(a0)
    80003516:	5d5c                	lw	a5,60(a0)
    80003518:	00e7d7bb          	srlw	a5,a5,a4
    8000351c:	e395                	bnez	a5,80003540 <kerneltrap+0x10a>
      if (getpreempted(p->queuelevel)) {
    8000351e:	18c9a503          	lw	a0,396(s3)
    80003522:	fffff097          	auipc	ra,0xfffff
    80003526:	afa080e7          	jalr	-1286(ra) # 8000201c <getpreempted>
    8000352a:	d131                	beqz	a0,8000346e <kerneltrap+0x38>
        yield();
    8000352c:	fffff097          	auipc	ra,0xfffff
    80003530:	19a080e7          	jalr	410(ra) # 800026c6 <yield>
    80003534:	bf2d                	j	8000346e <kerneltrap+0x38>
      yield();
    80003536:	fffff097          	auipc	ra,0xfffff
    8000353a:	190080e7          	jalr	400(ra) # 800026c6 <yield>
    8000353e:	bf05                	j	8000346e <kerneltrap+0x38>
        p->queuelevel = min(p->queuelevel + 1, QCOUNT);
    80003540:	87ba                	mv	a5,a4
    80003542:	4691                	li	a3,4
    80003544:	00e6d363          	bge	a3,a4,8000354a <kerneltrap+0x114>
    80003548:	4791                	li	a5,4
    8000354a:	2785                	addiw	a5,a5,1
    8000354c:	18f9a623          	sw	a5,396(s3)
        yield();
    80003550:	fffff097          	auipc	ra,0xfffff
    80003554:	176080e7          	jalr	374(ra) # 800026c6 <yield>
    80003558:	b7d9                	j	8000351e <kerneltrap+0xe8>

000000008000355a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000355a:	1101                	addi	sp,sp,-32
    8000355c:	ec06                	sd	ra,24(sp)
    8000355e:	e822                	sd	s0,16(sp)
    80003560:	e426                	sd	s1,8(sp)
    80003562:	1000                	addi	s0,sp,32
    80003564:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003566:	ffffe097          	auipc	ra,0xffffe
    8000356a:	452080e7          	jalr	1106(ra) # 800019b8 <myproc>
  switch (n) {
    8000356e:	4795                	li	a5,5
    80003570:	0497e163          	bltu	a5,s1,800035b2 <argraw+0x58>
    80003574:	048a                	slli	s1,s1,0x2
    80003576:	00005717          	auipc	a4,0x5
    8000357a:	04a70713          	addi	a4,a4,74 # 800085c0 <states.1845+0x280>
    8000357e:	94ba                	add	s1,s1,a4
    80003580:	409c                	lw	a5,0(s1)
    80003582:	97ba                	add	a5,a5,a4
    80003584:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003586:	7d3c                	ld	a5,120(a0)
    80003588:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000358a:	60e2                	ld	ra,24(sp)
    8000358c:	6442                	ld	s0,16(sp)
    8000358e:	64a2                	ld	s1,8(sp)
    80003590:	6105                	addi	sp,sp,32
    80003592:	8082                	ret
    return p->trapframe->a1;
    80003594:	7d3c                	ld	a5,120(a0)
    80003596:	7fa8                	ld	a0,120(a5)
    80003598:	bfcd                	j	8000358a <argraw+0x30>
    return p->trapframe->a2;
    8000359a:	7d3c                	ld	a5,120(a0)
    8000359c:	63c8                	ld	a0,128(a5)
    8000359e:	b7f5                	j	8000358a <argraw+0x30>
    return p->trapframe->a3;
    800035a0:	7d3c                	ld	a5,120(a0)
    800035a2:	67c8                	ld	a0,136(a5)
    800035a4:	b7dd                	j	8000358a <argraw+0x30>
    return p->trapframe->a4;
    800035a6:	7d3c                	ld	a5,120(a0)
    800035a8:	6bc8                	ld	a0,144(a5)
    800035aa:	b7c5                	j	8000358a <argraw+0x30>
    return p->trapframe->a5;
    800035ac:	7d3c                	ld	a5,120(a0)
    800035ae:	6fc8                	ld	a0,152(a5)
    800035b0:	bfe9                	j	8000358a <argraw+0x30>
  panic("argraw");
    800035b2:	00005517          	auipc	a0,0x5
    800035b6:	ef650513          	addi	a0,a0,-266 # 800084a8 <states.1845+0x168>
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	f84080e7          	jalr	-124(ra) # 8000053e <panic>

00000000800035c2 <fetchaddr>:
{
    800035c2:	1101                	addi	sp,sp,-32
    800035c4:	ec06                	sd	ra,24(sp)
    800035c6:	e822                	sd	s0,16(sp)
    800035c8:	e426                	sd	s1,8(sp)
    800035ca:	e04a                	sd	s2,0(sp)
    800035cc:	1000                	addi	s0,sp,32
    800035ce:	84aa                	mv	s1,a0
    800035d0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800035d2:	ffffe097          	auipc	ra,0xffffe
    800035d6:	3e6080e7          	jalr	998(ra) # 800019b8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800035da:	713c                	ld	a5,96(a0)
    800035dc:	02f4f863          	bgeu	s1,a5,8000360c <fetchaddr+0x4a>
    800035e0:	00848713          	addi	a4,s1,8
    800035e4:	02e7e663          	bltu	a5,a4,80003610 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800035e8:	46a1                	li	a3,8
    800035ea:	8626                	mv	a2,s1
    800035ec:	85ca                	mv	a1,s2
    800035ee:	7928                	ld	a0,112(a0)
    800035f0:	ffffe097          	auipc	ra,0xffffe
    800035f4:	116080e7          	jalr	278(ra) # 80001706 <copyin>
    800035f8:	00a03533          	snez	a0,a0
    800035fc:	40a00533          	neg	a0,a0
}
    80003600:	60e2                	ld	ra,24(sp)
    80003602:	6442                	ld	s0,16(sp)
    80003604:	64a2                	ld	s1,8(sp)
    80003606:	6902                	ld	s2,0(sp)
    80003608:	6105                	addi	sp,sp,32
    8000360a:	8082                	ret
    return -1;
    8000360c:	557d                	li	a0,-1
    8000360e:	bfcd                	j	80003600 <fetchaddr+0x3e>
    80003610:	557d                	li	a0,-1
    80003612:	b7fd                	j	80003600 <fetchaddr+0x3e>

0000000080003614 <fetchstr>:
{
    80003614:	7179                	addi	sp,sp,-48
    80003616:	f406                	sd	ra,40(sp)
    80003618:	f022                	sd	s0,32(sp)
    8000361a:	ec26                	sd	s1,24(sp)
    8000361c:	e84a                	sd	s2,16(sp)
    8000361e:	e44e                	sd	s3,8(sp)
    80003620:	1800                	addi	s0,sp,48
    80003622:	892a                	mv	s2,a0
    80003624:	84ae                	mv	s1,a1
    80003626:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003628:	ffffe097          	auipc	ra,0xffffe
    8000362c:	390080e7          	jalr	912(ra) # 800019b8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003630:	86ce                	mv	a3,s3
    80003632:	864a                	mv	a2,s2
    80003634:	85a6                	mv	a1,s1
    80003636:	7928                	ld	a0,112(a0)
    80003638:	ffffe097          	auipc	ra,0xffffe
    8000363c:	15a080e7          	jalr	346(ra) # 80001792 <copyinstr>
  if(err < 0)
    80003640:	00054763          	bltz	a0,8000364e <fetchstr+0x3a>
  return strlen(buf);
    80003644:	8526                	mv	a0,s1
    80003646:	ffffe097          	auipc	ra,0xffffe
    8000364a:	81e080e7          	jalr	-2018(ra) # 80000e64 <strlen>
}
    8000364e:	70a2                	ld	ra,40(sp)
    80003650:	7402                	ld	s0,32(sp)
    80003652:	64e2                	ld	s1,24(sp)
    80003654:	6942                	ld	s2,16(sp)
    80003656:	69a2                	ld	s3,8(sp)
    80003658:	6145                	addi	sp,sp,48
    8000365a:	8082                	ret

000000008000365c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000365c:	1101                	addi	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	e426                	sd	s1,8(sp)
    80003664:	1000                	addi	s0,sp,32
    80003666:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	ef2080e7          	jalr	-270(ra) # 8000355a <argraw>
    80003670:	c088                	sw	a0,0(s1)
  return 0;
}
    80003672:	4501                	li	a0,0
    80003674:	60e2                	ld	ra,24(sp)
    80003676:	6442                	ld	s0,16(sp)
    80003678:	64a2                	ld	s1,8(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret

000000008000367e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000367e:	1101                	addi	sp,sp,-32
    80003680:	ec06                	sd	ra,24(sp)
    80003682:	e822                	sd	s0,16(sp)
    80003684:	e426                	sd	s1,8(sp)
    80003686:	1000                	addi	s0,sp,32
    80003688:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	ed0080e7          	jalr	-304(ra) # 8000355a <argraw>
    80003692:	e088                	sd	a0,0(s1)
  return 0;
}
    80003694:	4501                	li	a0,0
    80003696:	60e2                	ld	ra,24(sp)
    80003698:	6442                	ld	s0,16(sp)
    8000369a:	64a2                	ld	s1,8(sp)
    8000369c:	6105                	addi	sp,sp,32
    8000369e:	8082                	ret

00000000800036a0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800036a0:	1101                	addi	sp,sp,-32
    800036a2:	ec06                	sd	ra,24(sp)
    800036a4:	e822                	sd	s0,16(sp)
    800036a6:	e426                	sd	s1,8(sp)
    800036a8:	e04a                	sd	s2,0(sp)
    800036aa:	1000                	addi	s0,sp,32
    800036ac:	84ae                	mv	s1,a1
    800036ae:	8932                	mv	s2,a2
  *ip = argraw(n);
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	eaa080e7          	jalr	-342(ra) # 8000355a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800036b8:	864a                	mv	a2,s2
    800036ba:	85a6                	mv	a1,s1
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	f58080e7          	jalr	-168(ra) # 80003614 <fetchstr>
}
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	6442                	ld	s0,16(sp)
    800036c8:	64a2                	ld	s1,8(sp)
    800036ca:	6902                	ld	s2,0(sp)
    800036cc:	6105                	addi	sp,sp,32
    800036ce:	8082                	ret

00000000800036d0 <syscall>:
[SYS_set_priority] 2,
};

void
syscall(void)
{
    800036d0:	7139                	addi	sp,sp,-64
    800036d2:	fc06                	sd	ra,56(sp)
    800036d4:	f822                	sd	s0,48(sp)
    800036d6:	f426                	sd	s1,40(sp)
    800036d8:	f04a                	sd	s2,32(sp)
    800036da:	ec4e                	sd	s3,24(sp)
    800036dc:	e852                	sd	s4,16(sp)
    800036de:	e456                	sd	s5,8(sp)
    800036e0:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    800036e2:	ffffe097          	auipc	ra,0xffffe
    800036e6:	2d6080e7          	jalr	726(ra) # 800019b8 <myproc>
    800036ea:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800036ec:	7d3c                	ld	a5,120(a0)
    800036ee:	77dc                	ld	a5,168(a5)
    800036f0:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800036f4:	37fd                	addiw	a5,a5,-1
    800036f6:	475d                	li	a4,23
    800036f8:	0ef76463          	bltu	a4,a5,800037e0 <syscall+0x110>
    800036fc:	00391713          	slli	a4,s2,0x3
    80003700:	00005797          	auipc	a5,0x5
    80003704:	ed878793          	addi	a5,a5,-296 # 800085d8 <syscalls>
    80003708:	97ba                	add	a5,a5,a4
    8000370a:	0007b983          	ld	s3,0(a5)
    8000370e:	0c098963          	beqz	s3,800037e0 <syscall+0x110>
  *ip = argraw(n);
    80003712:	4501                	li	a0,0
    80003714:	00000097          	auipc	ra,0x0
    80003718:	e46080e7          	jalr	-442(ra) # 8000355a <argraw>
    8000371c:	8aaa                	mv	s5,a0
    int firstarg;
    if (argint(0, &firstarg) < 0) {
      return;
    }
    p->trapframe->a0 = syscalls[num]();
    8000371e:	0784ba03          	ld	s4,120(s1)
    80003722:	9982                	jalr	s3
    80003724:	06aa3823          	sd	a0,112(s4)
    if ((p->tracemask) & (1 << num)) {
    80003728:	54bc                	lw	a5,104(s1)
    8000372a:	4127d7bb          	sraw	a5,a5,s2
    8000372e:	8b85                	andi	a5,a5,1
    80003730:	c7f9                	beqz	a5,800037fe <syscall+0x12e>
      printf("%d: syscall %s (", p->pid, syscallnames[num]);
    80003732:	00005997          	auipc	s3,0x5
    80003736:	2c698993          	addi	s3,s3,710 # 800089f8 <syscallnames>
    8000373a:	00391793          	slli	a5,s2,0x3
    8000373e:	97ce                	add	a5,a5,s3
    80003740:	6390                	ld	a2,0(a5)
    80003742:	588c                	lw	a1,48(s1)
    80003744:	00005517          	auipc	a0,0x5
    80003748:	d6c50513          	addi	a0,a0,-660 # 800084b0 <states.1845+0x170>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	e3c080e7          	jalr	-452(ra) # 80000588 <printf>
      for (int i = 0; i < syscallargc[num]; i++) {
    80003754:	00291793          	slli	a5,s2,0x2
    80003758:	99be                	add	s3,s3,a5
    8000375a:	0c09a783          	lw	a5,192(s3)
    8000375e:	06f05163          	blez	a5,800037c0 <syscall+0xf0>
    80003762:	4481                	li	s1,0
        int argument;
        if (argint(i, &argument) < 0) {
          break;
        }
        if (i == 0) argument = firstarg;
    80003764:	89d6                	mv	s3,s5
        printf("%d", argument);
    80003766:	00005a17          	auipc	s4,0x5
    8000376a:	d62a0a13          	addi	s4,s4,-670 # 800084c8 <states.1845+0x188>
        // Don't print space if it's the last argument
        if (i != syscallargc[num] - 1)
    8000376e:	090a                	slli	s2,s2,0x2
    80003770:	00005797          	auipc	a5,0x5
    80003774:	28878793          	addi	a5,a5,648 # 800089f8 <syscallnames>
    80003778:	993e                	add	s2,s2,a5
          printf(" ");
    8000377a:	00005a97          	auipc	s5,0x5
    8000377e:	d56a8a93          	addi	s5,s5,-682 # 800084d0 <states.1845+0x190>
    80003782:	a819                	j	80003798 <syscall+0xc8>
    80003784:	8556                	mv	a0,s5
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	e02080e7          	jalr	-510(ra) # 80000588 <printf>
      for (int i = 0; i < syscallargc[num]; i++) {
    8000378e:	2485                	addiw	s1,s1,1
    80003790:	0c092783          	lw	a5,192(s2)
    80003794:	02f4d663          	bge	s1,a5,800037c0 <syscall+0xf0>
  *ip = argraw(n);
    80003798:	8526                	mv	a0,s1
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	dc0080e7          	jalr	-576(ra) # 8000355a <argraw>
        if (i == 0) argument = firstarg;
    800037a2:	e091                	bnez	s1,800037a6 <syscall+0xd6>
    800037a4:	854e                	mv	a0,s3
        printf("%d", argument);
    800037a6:	0005059b          	sext.w	a1,a0
    800037aa:	8552                	mv	a0,s4
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	ddc080e7          	jalr	-548(ra) # 80000588 <printf>
        if (i != syscallargc[num] - 1)
    800037b4:	0c092783          	lw	a5,192(s2)
    800037b8:	37fd                	addiw	a5,a5,-1
    800037ba:	fc978ae3          	beq	a5,s1,8000378e <syscall+0xbe>
    800037be:	b7d9                	j	80003784 <syscall+0xb4>
  *ip = argraw(n);
    800037c0:	4501                	li	a0,0
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	d98080e7          	jalr	-616(ra) # 8000355a <argraw>
      }
      int returnvalue;
      if (argint(0, &returnvalue) < 0) {
        return;
      }
      printf(") -> %d\n", returnvalue);
    800037ca:	0005059b          	sext.w	a1,a0
    800037ce:	00005517          	auipc	a0,0x5
    800037d2:	d0a50513          	addi	a0,a0,-758 # 800084d8 <states.1845+0x198>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	db2080e7          	jalr	-590(ra) # 80000588 <printf>
    800037de:	a005                	j	800037fe <syscall+0x12e>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    800037e0:	86ca                	mv	a3,s2
    800037e2:	17848613          	addi	a2,s1,376
    800037e6:	588c                	lw	a1,48(s1)
    800037e8:	00005517          	auipc	a0,0x5
    800037ec:	d0050513          	addi	a0,a0,-768 # 800084e8 <states.1845+0x1a8>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	d98080e7          	jalr	-616(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800037f8:	7cbc                	ld	a5,120(s1)
    800037fa:	577d                	li	a4,-1
    800037fc:	fbb8                	sd	a4,112(a5)
  }
}
    800037fe:	70e2                	ld	ra,56(sp)
    80003800:	7442                	ld	s0,48(sp)
    80003802:	74a2                	ld	s1,40(sp)
    80003804:	7902                	ld	s2,32(sp)
    80003806:	69e2                	ld	s3,24(sp)
    80003808:	6a42                	ld	s4,16(sp)
    8000380a:	6aa2                	ld	s5,8(sp)
    8000380c:	6121                	addi	sp,sp,64
    8000380e:	8082                	ret

0000000080003810 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003810:	1101                	addi	sp,sp,-32
    80003812:	ec06                	sd	ra,24(sp)
    80003814:	e822                	sd	s0,16(sp)
    80003816:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003818:	fec40593          	addi	a1,s0,-20
    8000381c:	4501                	li	a0,0
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	e3e080e7          	jalr	-450(ra) # 8000365c <argint>
    return -1;
    80003826:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003828:	00054963          	bltz	a0,8000383a <sys_exit+0x2a>
  exit(n);
    8000382c:	fec42503          	lw	a0,-20(s0)
    80003830:	fffff097          	auipc	ra,0xfffff
    80003834:	12e080e7          	jalr	302(ra) # 8000295e <exit>
  return 0;  // not reached
    80003838:	4781                	li	a5,0
}
    8000383a:	853e                	mv	a0,a5
    8000383c:	60e2                	ld	ra,24(sp)
    8000383e:	6442                	ld	s0,16(sp)
    80003840:	6105                	addi	sp,sp,32
    80003842:	8082                	ret

0000000080003844 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003844:	1141                	addi	sp,sp,-16
    80003846:	e406                	sd	ra,8(sp)
    80003848:	e022                	sd	s0,0(sp)
    8000384a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000384c:	ffffe097          	auipc	ra,0xffffe
    80003850:	16c080e7          	jalr	364(ra) # 800019b8 <myproc>
}
    80003854:	5908                	lw	a0,48(a0)
    80003856:	60a2                	ld	ra,8(sp)
    80003858:	6402                	ld	s0,0(sp)
    8000385a:	0141                	addi	sp,sp,16
    8000385c:	8082                	ret

000000008000385e <sys_fork>:

uint64
sys_fork(void)
{
    8000385e:	1141                	addi	sp,sp,-16
    80003860:	e406                	sd	ra,8(sp)
    80003862:	e022                	sd	s0,0(sp)
    80003864:	0800                	addi	s0,sp,16
  return fork();
    80003866:	ffffe097          	auipc	ra,0xffffe
    8000386a:	576080e7          	jalr	1398(ra) # 80001ddc <fork>
}
    8000386e:	60a2                	ld	ra,8(sp)
    80003870:	6402                	ld	s0,0(sp)
    80003872:	0141                	addi	sp,sp,16
    80003874:	8082                	ret

0000000080003876 <sys_wait>:

uint64
sys_wait(void)
{
    80003876:	1101                	addi	sp,sp,-32
    80003878:	ec06                	sd	ra,24(sp)
    8000387a:	e822                	sd	s0,16(sp)
    8000387c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000387e:	fe840593          	addi	a1,s0,-24
    80003882:	4501                	li	a0,0
    80003884:	00000097          	auipc	ra,0x0
    80003888:	dfa080e7          	jalr	-518(ra) # 8000367e <argaddr>
    8000388c:	87aa                	mv	a5,a0
    return -1;
    8000388e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003890:	0007c863          	bltz	a5,800038a0 <sys_wait+0x2a>
  return wait(p);
    80003894:	fe843503          	ld	a0,-24(s0)
    80003898:	fffff097          	auipc	ra,0xfffff
    8000389c:	ece080e7          	jalr	-306(ra) # 80002766 <wait>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	6105                	addi	sp,sp,32
    800038a6:	8082                	ret

00000000800038a8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800038a8:	7179                	addi	sp,sp,-48
    800038aa:	f406                	sd	ra,40(sp)
    800038ac:	f022                	sd	s0,32(sp)
    800038ae:	ec26                	sd	s1,24(sp)
    800038b0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800038b2:	fdc40593          	addi	a1,s0,-36
    800038b6:	4501                	li	a0,0
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	da4080e7          	jalr	-604(ra) # 8000365c <argint>
    800038c0:	87aa                	mv	a5,a0
    return -1;
    800038c2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800038c4:	0207c063          	bltz	a5,800038e4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800038c8:	ffffe097          	auipc	ra,0xffffe
    800038cc:	0f0080e7          	jalr	240(ra) # 800019b8 <myproc>
    800038d0:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    800038d2:	fdc42503          	lw	a0,-36(s0)
    800038d6:	ffffe097          	auipc	ra,0xffffe
    800038da:	492080e7          	jalr	1170(ra) # 80001d68 <growproc>
    800038de:	00054863          	bltz	a0,800038ee <sys_sbrk+0x46>
    return -1;
  return addr;
    800038e2:	8526                	mv	a0,s1
}
    800038e4:	70a2                	ld	ra,40(sp)
    800038e6:	7402                	ld	s0,32(sp)
    800038e8:	64e2                	ld	s1,24(sp)
    800038ea:	6145                	addi	sp,sp,48
    800038ec:	8082                	ret
    return -1;
    800038ee:	557d                	li	a0,-1
    800038f0:	bfd5                	j	800038e4 <sys_sbrk+0x3c>

00000000800038f2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800038f2:	7139                	addi	sp,sp,-64
    800038f4:	fc06                	sd	ra,56(sp)
    800038f6:	f822                	sd	s0,48(sp)
    800038f8:	f426                	sd	s1,40(sp)
    800038fa:	f04a                	sd	s2,32(sp)
    800038fc:	ec4e                	sd	s3,24(sp)
    800038fe:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003900:	fcc40593          	addi	a1,s0,-52
    80003904:	4501                	li	a0,0
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	d56080e7          	jalr	-682(ra) # 8000365c <argint>
    return -1;
    8000390e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003910:	06054563          	bltz	a0,8000397a <sys_sleep+0x88>
  acquire(&tickslock);
    80003914:	00015517          	auipc	a0,0x15
    80003918:	60c50513          	addi	a0,a0,1548 # 80018f20 <tickslock>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	2c8080e7          	jalr	712(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003924:	00005917          	auipc	s2,0x5
    80003928:	71492903          	lw	s2,1812(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    8000392c:	fcc42783          	lw	a5,-52(s0)
    80003930:	cf85                	beqz	a5,80003968 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003932:	00015997          	auipc	s3,0x15
    80003936:	5ee98993          	addi	s3,s3,1518 # 80018f20 <tickslock>
    8000393a:	00005497          	auipc	s1,0x5
    8000393e:	6fe48493          	addi	s1,s1,1790 # 80009038 <ticks>
    if(myproc()->killed){
    80003942:	ffffe097          	auipc	ra,0xffffe
    80003946:	076080e7          	jalr	118(ra) # 800019b8 <myproc>
    8000394a:	551c                	lw	a5,40(a0)
    8000394c:	ef9d                	bnez	a5,8000398a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000394e:	85ce                	mv	a1,s3
    80003950:	8526                	mv	a0,s1
    80003952:	fffff097          	auipc	ra,0xfffff
    80003956:	db0080e7          	jalr	-592(ra) # 80002702 <sleep>
  while(ticks - ticks0 < n){
    8000395a:	409c                	lw	a5,0(s1)
    8000395c:	412787bb          	subw	a5,a5,s2
    80003960:	fcc42703          	lw	a4,-52(s0)
    80003964:	fce7efe3          	bltu	a5,a4,80003942 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003968:	00015517          	auipc	a0,0x15
    8000396c:	5b850513          	addi	a0,a0,1464 # 80018f20 <tickslock>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	328080e7          	jalr	808(ra) # 80000c98 <release>
  return 0;
    80003978:	4781                	li	a5,0
}
    8000397a:	853e                	mv	a0,a5
    8000397c:	70e2                	ld	ra,56(sp)
    8000397e:	7442                	ld	s0,48(sp)
    80003980:	74a2                	ld	s1,40(sp)
    80003982:	7902                	ld	s2,32(sp)
    80003984:	69e2                	ld	s3,24(sp)
    80003986:	6121                	addi	sp,sp,64
    80003988:	8082                	ret
      release(&tickslock);
    8000398a:	00015517          	auipc	a0,0x15
    8000398e:	59650513          	addi	a0,a0,1430 # 80018f20 <tickslock>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	306080e7          	jalr	774(ra) # 80000c98 <release>
      return -1;
    8000399a:	57fd                	li	a5,-1
    8000399c:	bff9                	j	8000397a <sys_sleep+0x88>

000000008000399e <sys_kill>:

uint64
sys_kill(void)
{
    8000399e:	1101                	addi	sp,sp,-32
    800039a0:	ec06                	sd	ra,24(sp)
    800039a2:	e822                	sd	s0,16(sp)
    800039a4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800039a6:	fec40593          	addi	a1,s0,-20
    800039aa:	4501                	li	a0,0
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	cb0080e7          	jalr	-848(ra) # 8000365c <argint>
    800039b4:	87aa                	mv	a5,a0
    return -1;
    800039b6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800039b8:	0007c863          	bltz	a5,800039c8 <sys_kill+0x2a>
  return kill(pid);
    800039bc:	fec42503          	lw	a0,-20(s0)
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	080080e7          	jalr	128(ra) # 80002a40 <kill>
}
    800039c8:	60e2                	ld	ra,24(sp)
    800039ca:	6442                	ld	s0,16(sp)
    800039cc:	6105                	addi	sp,sp,32
    800039ce:	8082                	ret

00000000800039d0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800039d0:	1101                	addi	sp,sp,-32
    800039d2:	ec06                	sd	ra,24(sp)
    800039d4:	e822                	sd	s0,16(sp)
    800039d6:	e426                	sd	s1,8(sp)
    800039d8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800039da:	00015517          	auipc	a0,0x15
    800039de:	54650513          	addi	a0,a0,1350 # 80018f20 <tickslock>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	202080e7          	jalr	514(ra) # 80000be4 <acquire>
  xticks = ticks;
    800039ea:	00005497          	auipc	s1,0x5
    800039ee:	64e4a483          	lw	s1,1614(s1) # 80009038 <ticks>
  release(&tickslock);
    800039f2:	00015517          	auipc	a0,0x15
    800039f6:	52e50513          	addi	a0,a0,1326 # 80018f20 <tickslock>
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	29e080e7          	jalr	670(ra) # 80000c98 <release>
  return xticks;
}
    80003a02:	02049513          	slli	a0,s1,0x20
    80003a06:	9101                	srli	a0,a0,0x20
    80003a08:	60e2                	ld	ra,24(sp)
    80003a0a:	6442                	ld	s0,16(sp)
    80003a0c:	64a2                	ld	s1,8(sp)
    80003a0e:	6105                	addi	sp,sp,32
    80003a10:	8082                	ret

0000000080003a12 <sys_trace>:

uint64
sys_trace(void)
{
    80003a12:	1141                	addi	sp,sp,-16
    80003a14:	e406                	sd	ra,8(sp)
    80003a16:	e022                	sd	s0,0(sp)
    80003a18:	0800                	addi	s0,sp,16
    if (argint(0, &(myproc()->tracemask)) < 0) {
    80003a1a:	ffffe097          	auipc	ra,0xffffe
    80003a1e:	f9e080e7          	jalr	-98(ra) # 800019b8 <myproc>
    80003a22:	06850593          	addi	a1,a0,104
    80003a26:	4501                	li	a0,0
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	c34080e7          	jalr	-972(ra) # 8000365c <argint>
        return -1;
    }
    return 0;
}
    80003a30:	957d                	srai	a0,a0,0x3f
    80003a32:	60a2                	ld	ra,8(sp)
    80003a34:	6402                	ld	s0,0(sp)
    80003a36:	0141                	addi	sp,sp,16
    80003a38:	8082                	ret

0000000080003a3a <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003a3a:	1101                	addi	sp,sp,-32
    80003a3c:	ec06                	sd	ra,24(sp)
    80003a3e:	e822                	sd	s0,16(sp)
    80003a40:	1000                	addi	s0,sp,32
  int new_priority = 0, pid = 0;
    80003a42:	fe042623          	sw	zero,-20(s0)
    80003a46:	fe042423          	sw	zero,-24(s0)
  if (argint(0, &new_priority) < 0) {
    80003a4a:	fec40593          	addi	a1,s0,-20
    80003a4e:	4501                	li	a0,0
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	c0c080e7          	jalr	-1012(ra) # 8000365c <argint>
    return -1;
    80003a58:	57fd                	li	a5,-1
  if (argint(0, &new_priority) < 0) {
    80003a5a:	02054a63          	bltz	a0,80003a8e <sys_set_priority+0x54>
  }
  if (argint(1, &pid) < 0) {
    80003a5e:	fe840593          	addi	a1,s0,-24
    80003a62:	4505                	li	a0,1
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	bf8080e7          	jalr	-1032(ra) # 8000365c <argint>
    return -1;
    80003a6c:	57fd                	li	a5,-1
  if (argint(1, &pid) < 0) {
    80003a6e:	02054063          	bltz	a0,80003a8e <sys_set_priority+0x54>
  }
  int old_dp = 0;
    80003a72:	fe042223          	sw	zero,-28(s0)
  changepriority(new_priority, pid, &old_dp);
    80003a76:	fe440613          	addi	a2,s0,-28
    80003a7a:	fe842583          	lw	a1,-24(s0)
    80003a7e:	fec42503          	lw	a0,-20(s0)
    80003a82:	fffff097          	auipc	ra,0xfffff
    80003a86:	310080e7          	jalr	784(ra) # 80002d92 <changepriority>
  return old_dp;
    80003a8a:	fe442783          	lw	a5,-28(s0)
}
    80003a8e:	853e                	mv	a0,a5
    80003a90:	60e2                	ld	ra,24(sp)
    80003a92:	6442                	ld	s0,16(sp)
    80003a94:	6105                	addi	sp,sp,32
    80003a96:	8082                	ret

0000000080003a98 <sys_waitx>:
uint64
sys_waitx(void)
{
    80003a98:	7139                	addi	sp,sp,-64
    80003a9a:	fc06                	sd	ra,56(sp)
    80003a9c:	f822                	sd	s0,48(sp)
    80003a9e:	f426                	sd	s1,40(sp)
    80003aa0:	f04a                	sd	s2,32(sp)
    80003aa2:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80003aa4:	fd840593          	addi	a1,s0,-40
    80003aa8:	4501                	li	a0,0
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	bd4080e7          	jalr	-1068(ra) # 8000367e <argaddr>
    return -1;
    80003ab2:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80003ab4:	08054063          	bltz	a0,80003b34 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003ab8:	fd040593          	addi	a1,s0,-48
    80003abc:	4505                	li	a0,1
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	bc0080e7          	jalr	-1088(ra) # 8000367e <argaddr>
    return -1;
    80003ac6:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80003ac8:	06054663          	bltz	a0,80003b34 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80003acc:	fc840593          	addi	a1,s0,-56
    80003ad0:	4509                	li	a0,2
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	bac080e7          	jalr	-1108(ra) # 8000367e <argaddr>
    return -1;
    80003ada:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80003adc:	04054c63          	bltz	a0,80003b34 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80003ae0:	fc040613          	addi	a2,s0,-64
    80003ae4:	fc440593          	addi	a1,s0,-60
    80003ae8:	fd843503          	ld	a0,-40(s0)
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	35a080e7          	jalr	858(ra) # 80002e46 <waitx>
    80003af4:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003af6:	ffffe097          	auipc	ra,0xffffe
    80003afa:	ec2080e7          	jalr	-318(ra) # 800019b8 <myproc>
    80003afe:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003b00:	4691                	li	a3,4
    80003b02:	fc440613          	addi	a2,s0,-60
    80003b06:	fd043583          	ld	a1,-48(s0)
    80003b0a:	7928                	ld	a0,112(a0)
    80003b0c:	ffffe097          	auipc	ra,0xffffe
    80003b10:	b6e080e7          	jalr	-1170(ra) # 8000167a <copyout>
    return -1;
    80003b14:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003b16:	00054f63          	bltz	a0,80003b34 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003b1a:	4691                	li	a3,4
    80003b1c:	fc040613          	addi	a2,s0,-64
    80003b20:	fc843583          	ld	a1,-56(s0)
    80003b24:	78a8                	ld	a0,112(s1)
    80003b26:	ffffe097          	auipc	ra,0xffffe
    80003b2a:	b54080e7          	jalr	-1196(ra) # 8000167a <copyout>
    80003b2e:	00054a63          	bltz	a0,80003b42 <sys_waitx+0xaa>
    return -1;
  return ret;
    80003b32:	87ca                	mv	a5,s2
}
    80003b34:	853e                	mv	a0,a5
    80003b36:	70e2                	ld	ra,56(sp)
    80003b38:	7442                	ld	s0,48(sp)
    80003b3a:	74a2                	ld	s1,40(sp)
    80003b3c:	7902                	ld	s2,32(sp)
    80003b3e:	6121                	addi	sp,sp,64
    80003b40:	8082                	ret
    return -1;
    80003b42:	57fd                	li	a5,-1
    80003b44:	bfc5                	j	80003b34 <sys_waitx+0x9c>

0000000080003b46 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003b46:	7179                	addi	sp,sp,-48
    80003b48:	f406                	sd	ra,40(sp)
    80003b4a:	f022                	sd	s0,32(sp)
    80003b4c:	ec26                	sd	s1,24(sp)
    80003b4e:	e84a                	sd	s2,16(sp)
    80003b50:	e44e                	sd	s3,8(sp)
    80003b52:	e052                	sd	s4,0(sp)
    80003b54:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003b56:	00005597          	auipc	a1,0x5
    80003b5a:	b4a58593          	addi	a1,a1,-1206 # 800086a0 <syscalls+0xc8>
    80003b5e:	00015517          	auipc	a0,0x15
    80003b62:	3da50513          	addi	a0,a0,986 # 80018f38 <bcache>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	fee080e7          	jalr	-18(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003b6e:	0001d797          	auipc	a5,0x1d
    80003b72:	3ca78793          	addi	a5,a5,970 # 80020f38 <bcache+0x8000>
    80003b76:	0001d717          	auipc	a4,0x1d
    80003b7a:	62a70713          	addi	a4,a4,1578 # 800211a0 <bcache+0x8268>
    80003b7e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003b82:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b86:	00015497          	auipc	s1,0x15
    80003b8a:	3ca48493          	addi	s1,s1,970 # 80018f50 <bcache+0x18>
    b->next = bcache.head.next;
    80003b8e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003b90:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003b92:	00005a17          	auipc	s4,0x5
    80003b96:	b16a0a13          	addi	s4,s4,-1258 # 800086a8 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003b9a:	2b893783          	ld	a5,696(s2)
    80003b9e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003ba0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003ba4:	85d2                	mv	a1,s4
    80003ba6:	01048513          	addi	a0,s1,16
    80003baa:	00001097          	auipc	ra,0x1
    80003bae:	4bc080e7          	jalr	1212(ra) # 80005066 <initsleeplock>
    bcache.head.next->prev = b;
    80003bb2:	2b893783          	ld	a5,696(s2)
    80003bb6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003bb8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003bbc:	45848493          	addi	s1,s1,1112
    80003bc0:	fd349de3          	bne	s1,s3,80003b9a <binit+0x54>
  }
}
    80003bc4:	70a2                	ld	ra,40(sp)
    80003bc6:	7402                	ld	s0,32(sp)
    80003bc8:	64e2                	ld	s1,24(sp)
    80003bca:	6942                	ld	s2,16(sp)
    80003bcc:	69a2                	ld	s3,8(sp)
    80003bce:	6a02                	ld	s4,0(sp)
    80003bd0:	6145                	addi	sp,sp,48
    80003bd2:	8082                	ret

0000000080003bd4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003bd4:	7179                	addi	sp,sp,-48
    80003bd6:	f406                	sd	ra,40(sp)
    80003bd8:	f022                	sd	s0,32(sp)
    80003bda:	ec26                	sd	s1,24(sp)
    80003bdc:	e84a                	sd	s2,16(sp)
    80003bde:	e44e                	sd	s3,8(sp)
    80003be0:	1800                	addi	s0,sp,48
    80003be2:	89aa                	mv	s3,a0
    80003be4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003be6:	00015517          	auipc	a0,0x15
    80003bea:	35250513          	addi	a0,a0,850 # 80018f38 <bcache>
    80003bee:	ffffd097          	auipc	ra,0xffffd
    80003bf2:	ff6080e7          	jalr	-10(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003bf6:	0001d497          	auipc	s1,0x1d
    80003bfa:	5fa4b483          	ld	s1,1530(s1) # 800211f0 <bcache+0x82b8>
    80003bfe:	0001d797          	auipc	a5,0x1d
    80003c02:	5a278793          	addi	a5,a5,1442 # 800211a0 <bcache+0x8268>
    80003c06:	02f48f63          	beq	s1,a5,80003c44 <bread+0x70>
    80003c0a:	873e                	mv	a4,a5
    80003c0c:	a021                	j	80003c14 <bread+0x40>
    80003c0e:	68a4                	ld	s1,80(s1)
    80003c10:	02e48a63          	beq	s1,a4,80003c44 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003c14:	449c                	lw	a5,8(s1)
    80003c16:	ff379ce3          	bne	a5,s3,80003c0e <bread+0x3a>
    80003c1a:	44dc                	lw	a5,12(s1)
    80003c1c:	ff2799e3          	bne	a5,s2,80003c0e <bread+0x3a>
      b->refcnt++;
    80003c20:	40bc                	lw	a5,64(s1)
    80003c22:	2785                	addiw	a5,a5,1
    80003c24:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003c26:	00015517          	auipc	a0,0x15
    80003c2a:	31250513          	addi	a0,a0,786 # 80018f38 <bcache>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	06a080e7          	jalr	106(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003c36:	01048513          	addi	a0,s1,16
    80003c3a:	00001097          	auipc	ra,0x1
    80003c3e:	466080e7          	jalr	1126(ra) # 800050a0 <acquiresleep>
      return b;
    80003c42:	a8b9                	j	80003ca0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003c44:	0001d497          	auipc	s1,0x1d
    80003c48:	5a44b483          	ld	s1,1444(s1) # 800211e8 <bcache+0x82b0>
    80003c4c:	0001d797          	auipc	a5,0x1d
    80003c50:	55478793          	addi	a5,a5,1364 # 800211a0 <bcache+0x8268>
    80003c54:	00f48863          	beq	s1,a5,80003c64 <bread+0x90>
    80003c58:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003c5a:	40bc                	lw	a5,64(s1)
    80003c5c:	cf81                	beqz	a5,80003c74 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003c5e:	64a4                	ld	s1,72(s1)
    80003c60:	fee49de3          	bne	s1,a4,80003c5a <bread+0x86>
  panic("bget: no buffers");
    80003c64:	00005517          	auipc	a0,0x5
    80003c68:	a4c50513          	addi	a0,a0,-1460 # 800086b0 <syscalls+0xd8>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	8d2080e7          	jalr	-1838(ra) # 8000053e <panic>
      b->dev = dev;
    80003c74:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003c78:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003c7c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003c80:	4785                	li	a5,1
    80003c82:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003c84:	00015517          	auipc	a0,0x15
    80003c88:	2b450513          	addi	a0,a0,692 # 80018f38 <bcache>
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	00c080e7          	jalr	12(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003c94:	01048513          	addi	a0,s1,16
    80003c98:	00001097          	auipc	ra,0x1
    80003c9c:	408080e7          	jalr	1032(ra) # 800050a0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003ca0:	409c                	lw	a5,0(s1)
    80003ca2:	cb89                	beqz	a5,80003cb4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003ca4:	8526                	mv	a0,s1
    80003ca6:	70a2                	ld	ra,40(sp)
    80003ca8:	7402                	ld	s0,32(sp)
    80003caa:	64e2                	ld	s1,24(sp)
    80003cac:	6942                	ld	s2,16(sp)
    80003cae:	69a2                	ld	s3,8(sp)
    80003cb0:	6145                	addi	sp,sp,48
    80003cb2:	8082                	ret
    virtio_disk_rw(b, 0);
    80003cb4:	4581                	li	a1,0
    80003cb6:	8526                	mv	a0,s1
    80003cb8:	00003097          	auipc	ra,0x3
    80003cbc:	f0e080e7          	jalr	-242(ra) # 80006bc6 <virtio_disk_rw>
    b->valid = 1;
    80003cc0:	4785                	li	a5,1
    80003cc2:	c09c                	sw	a5,0(s1)
  return b;
    80003cc4:	b7c5                	j	80003ca4 <bread+0xd0>

0000000080003cc6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003cc6:	1101                	addi	sp,sp,-32
    80003cc8:	ec06                	sd	ra,24(sp)
    80003cca:	e822                	sd	s0,16(sp)
    80003ccc:	e426                	sd	s1,8(sp)
    80003cce:	1000                	addi	s0,sp,32
    80003cd0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003cd2:	0541                	addi	a0,a0,16
    80003cd4:	00001097          	auipc	ra,0x1
    80003cd8:	466080e7          	jalr	1126(ra) # 8000513a <holdingsleep>
    80003cdc:	cd01                	beqz	a0,80003cf4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003cde:	4585                	li	a1,1
    80003ce0:	8526                	mv	a0,s1
    80003ce2:	00003097          	auipc	ra,0x3
    80003ce6:	ee4080e7          	jalr	-284(ra) # 80006bc6 <virtio_disk_rw>
}
    80003cea:	60e2                	ld	ra,24(sp)
    80003cec:	6442                	ld	s0,16(sp)
    80003cee:	64a2                	ld	s1,8(sp)
    80003cf0:	6105                	addi	sp,sp,32
    80003cf2:	8082                	ret
    panic("bwrite");
    80003cf4:	00005517          	auipc	a0,0x5
    80003cf8:	9d450513          	addi	a0,a0,-1580 # 800086c8 <syscalls+0xf0>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	842080e7          	jalr	-1982(ra) # 8000053e <panic>

0000000080003d04 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003d04:	1101                	addi	sp,sp,-32
    80003d06:	ec06                	sd	ra,24(sp)
    80003d08:	e822                	sd	s0,16(sp)
    80003d0a:	e426                	sd	s1,8(sp)
    80003d0c:	e04a                	sd	s2,0(sp)
    80003d0e:	1000                	addi	s0,sp,32
    80003d10:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003d12:	01050913          	addi	s2,a0,16
    80003d16:	854a                	mv	a0,s2
    80003d18:	00001097          	auipc	ra,0x1
    80003d1c:	422080e7          	jalr	1058(ra) # 8000513a <holdingsleep>
    80003d20:	c92d                	beqz	a0,80003d92 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003d22:	854a                	mv	a0,s2
    80003d24:	00001097          	auipc	ra,0x1
    80003d28:	3d2080e7          	jalr	978(ra) # 800050f6 <releasesleep>

  acquire(&bcache.lock);
    80003d2c:	00015517          	auipc	a0,0x15
    80003d30:	20c50513          	addi	a0,a0,524 # 80018f38 <bcache>
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	eb0080e7          	jalr	-336(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003d3c:	40bc                	lw	a5,64(s1)
    80003d3e:	37fd                	addiw	a5,a5,-1
    80003d40:	0007871b          	sext.w	a4,a5
    80003d44:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003d46:	eb05                	bnez	a4,80003d76 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003d48:	68bc                	ld	a5,80(s1)
    80003d4a:	64b8                	ld	a4,72(s1)
    80003d4c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003d4e:	64bc                	ld	a5,72(s1)
    80003d50:	68b8                	ld	a4,80(s1)
    80003d52:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003d54:	0001d797          	auipc	a5,0x1d
    80003d58:	1e478793          	addi	a5,a5,484 # 80020f38 <bcache+0x8000>
    80003d5c:	2b87b703          	ld	a4,696(a5)
    80003d60:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003d62:	0001d717          	auipc	a4,0x1d
    80003d66:	43e70713          	addi	a4,a4,1086 # 800211a0 <bcache+0x8268>
    80003d6a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003d6c:	2b87b703          	ld	a4,696(a5)
    80003d70:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003d72:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003d76:	00015517          	auipc	a0,0x15
    80003d7a:	1c250513          	addi	a0,a0,450 # 80018f38 <bcache>
    80003d7e:	ffffd097          	auipc	ra,0xffffd
    80003d82:	f1a080e7          	jalr	-230(ra) # 80000c98 <release>
}
    80003d86:	60e2                	ld	ra,24(sp)
    80003d88:	6442                	ld	s0,16(sp)
    80003d8a:	64a2                	ld	s1,8(sp)
    80003d8c:	6902                	ld	s2,0(sp)
    80003d8e:	6105                	addi	sp,sp,32
    80003d90:	8082                	ret
    panic("brelse");
    80003d92:	00005517          	auipc	a0,0x5
    80003d96:	93e50513          	addi	a0,a0,-1730 # 800086d0 <syscalls+0xf8>
    80003d9a:	ffffc097          	auipc	ra,0xffffc
    80003d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>

0000000080003da2 <bpin>:

void
bpin(struct buf *b) {
    80003da2:	1101                	addi	sp,sp,-32
    80003da4:	ec06                	sd	ra,24(sp)
    80003da6:	e822                	sd	s0,16(sp)
    80003da8:	e426                	sd	s1,8(sp)
    80003daa:	1000                	addi	s0,sp,32
    80003dac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003dae:	00015517          	auipc	a0,0x15
    80003db2:	18a50513          	addi	a0,a0,394 # 80018f38 <bcache>
    80003db6:	ffffd097          	auipc	ra,0xffffd
    80003dba:	e2e080e7          	jalr	-466(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003dbe:	40bc                	lw	a5,64(s1)
    80003dc0:	2785                	addiw	a5,a5,1
    80003dc2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003dc4:	00015517          	auipc	a0,0x15
    80003dc8:	17450513          	addi	a0,a0,372 # 80018f38 <bcache>
    80003dcc:	ffffd097          	auipc	ra,0xffffd
    80003dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
}
    80003dd4:	60e2                	ld	ra,24(sp)
    80003dd6:	6442                	ld	s0,16(sp)
    80003dd8:	64a2                	ld	s1,8(sp)
    80003dda:	6105                	addi	sp,sp,32
    80003ddc:	8082                	ret

0000000080003dde <bunpin>:

void
bunpin(struct buf *b) {
    80003dde:	1101                	addi	sp,sp,-32
    80003de0:	ec06                	sd	ra,24(sp)
    80003de2:	e822                	sd	s0,16(sp)
    80003de4:	e426                	sd	s1,8(sp)
    80003de6:	1000                	addi	s0,sp,32
    80003de8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003dea:	00015517          	auipc	a0,0x15
    80003dee:	14e50513          	addi	a0,a0,334 # 80018f38 <bcache>
    80003df2:	ffffd097          	auipc	ra,0xffffd
    80003df6:	df2080e7          	jalr	-526(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003dfa:	40bc                	lw	a5,64(s1)
    80003dfc:	37fd                	addiw	a5,a5,-1
    80003dfe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003e00:	00015517          	auipc	a0,0x15
    80003e04:	13850513          	addi	a0,a0,312 # 80018f38 <bcache>
    80003e08:	ffffd097          	auipc	ra,0xffffd
    80003e0c:	e90080e7          	jalr	-368(ra) # 80000c98 <release>
}
    80003e10:	60e2                	ld	ra,24(sp)
    80003e12:	6442                	ld	s0,16(sp)
    80003e14:	64a2                	ld	s1,8(sp)
    80003e16:	6105                	addi	sp,sp,32
    80003e18:	8082                	ret

0000000080003e1a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003e1a:	1101                	addi	sp,sp,-32
    80003e1c:	ec06                	sd	ra,24(sp)
    80003e1e:	e822                	sd	s0,16(sp)
    80003e20:	e426                	sd	s1,8(sp)
    80003e22:	e04a                	sd	s2,0(sp)
    80003e24:	1000                	addi	s0,sp,32
    80003e26:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003e28:	00d5d59b          	srliw	a1,a1,0xd
    80003e2c:	0001d797          	auipc	a5,0x1d
    80003e30:	7e87a783          	lw	a5,2024(a5) # 80021614 <sb+0x1c>
    80003e34:	9dbd                	addw	a1,a1,a5
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	d9e080e7          	jalr	-610(ra) # 80003bd4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003e3e:	0074f713          	andi	a4,s1,7
    80003e42:	4785                	li	a5,1
    80003e44:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003e48:	14ce                	slli	s1,s1,0x33
    80003e4a:	90d9                	srli	s1,s1,0x36
    80003e4c:	00950733          	add	a4,a0,s1
    80003e50:	05874703          	lbu	a4,88(a4)
    80003e54:	00e7f6b3          	and	a3,a5,a4
    80003e58:	c69d                	beqz	a3,80003e86 <bfree+0x6c>
    80003e5a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003e5c:	94aa                	add	s1,s1,a0
    80003e5e:	fff7c793          	not	a5,a5
    80003e62:	8ff9                	and	a5,a5,a4
    80003e64:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003e68:	00001097          	auipc	ra,0x1
    80003e6c:	118080e7          	jalr	280(ra) # 80004f80 <log_write>
  brelse(bp);
    80003e70:	854a                	mv	a0,s2
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	e92080e7          	jalr	-366(ra) # 80003d04 <brelse>
}
    80003e7a:	60e2                	ld	ra,24(sp)
    80003e7c:	6442                	ld	s0,16(sp)
    80003e7e:	64a2                	ld	s1,8(sp)
    80003e80:	6902                	ld	s2,0(sp)
    80003e82:	6105                	addi	sp,sp,32
    80003e84:	8082                	ret
    panic("freeing free block");
    80003e86:	00005517          	auipc	a0,0x5
    80003e8a:	85250513          	addi	a0,a0,-1966 # 800086d8 <syscalls+0x100>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	6b0080e7          	jalr	1712(ra) # 8000053e <panic>

0000000080003e96 <balloc>:
{
    80003e96:	711d                	addi	sp,sp,-96
    80003e98:	ec86                	sd	ra,88(sp)
    80003e9a:	e8a2                	sd	s0,80(sp)
    80003e9c:	e4a6                	sd	s1,72(sp)
    80003e9e:	e0ca                	sd	s2,64(sp)
    80003ea0:	fc4e                	sd	s3,56(sp)
    80003ea2:	f852                	sd	s4,48(sp)
    80003ea4:	f456                	sd	s5,40(sp)
    80003ea6:	f05a                	sd	s6,32(sp)
    80003ea8:	ec5e                	sd	s7,24(sp)
    80003eaa:	e862                	sd	s8,16(sp)
    80003eac:	e466                	sd	s9,8(sp)
    80003eae:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003eb0:	0001d797          	auipc	a5,0x1d
    80003eb4:	74c7a783          	lw	a5,1868(a5) # 800215fc <sb+0x4>
    80003eb8:	cbd1                	beqz	a5,80003f4c <balloc+0xb6>
    80003eba:	8baa                	mv	s7,a0
    80003ebc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003ebe:	0001db17          	auipc	s6,0x1d
    80003ec2:	73ab0b13          	addi	s6,s6,1850 # 800215f8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ec6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003ec8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003eca:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003ecc:	6c89                	lui	s9,0x2
    80003ece:	a831                	j	80003eea <balloc+0x54>
    brelse(bp);
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	e32080e7          	jalr	-462(ra) # 80003d04 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003eda:	015c87bb          	addw	a5,s9,s5
    80003ede:	00078a9b          	sext.w	s5,a5
    80003ee2:	004b2703          	lw	a4,4(s6)
    80003ee6:	06eaf363          	bgeu	s5,a4,80003f4c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003eea:	41fad79b          	sraiw	a5,s5,0x1f
    80003eee:	0137d79b          	srliw	a5,a5,0x13
    80003ef2:	015787bb          	addw	a5,a5,s5
    80003ef6:	40d7d79b          	sraiw	a5,a5,0xd
    80003efa:	01cb2583          	lw	a1,28(s6)
    80003efe:	9dbd                	addw	a1,a1,a5
    80003f00:	855e                	mv	a0,s7
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	cd2080e7          	jalr	-814(ra) # 80003bd4 <bread>
    80003f0a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f0c:	004b2503          	lw	a0,4(s6)
    80003f10:	000a849b          	sext.w	s1,s5
    80003f14:	8662                	mv	a2,s8
    80003f16:	faa4fde3          	bgeu	s1,a0,80003ed0 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003f1a:	41f6579b          	sraiw	a5,a2,0x1f
    80003f1e:	01d7d69b          	srliw	a3,a5,0x1d
    80003f22:	00c6873b          	addw	a4,a3,a2
    80003f26:	00777793          	andi	a5,a4,7
    80003f2a:	9f95                	subw	a5,a5,a3
    80003f2c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003f30:	4037571b          	sraiw	a4,a4,0x3
    80003f34:	00e906b3          	add	a3,s2,a4
    80003f38:	0586c683          	lbu	a3,88(a3)
    80003f3c:	00d7f5b3          	and	a1,a5,a3
    80003f40:	cd91                	beqz	a1,80003f5c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f42:	2605                	addiw	a2,a2,1
    80003f44:	2485                	addiw	s1,s1,1
    80003f46:	fd4618e3          	bne	a2,s4,80003f16 <balloc+0x80>
    80003f4a:	b759                	j	80003ed0 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003f4c:	00004517          	auipc	a0,0x4
    80003f50:	7a450513          	addi	a0,a0,1956 # 800086f0 <syscalls+0x118>
    80003f54:	ffffc097          	auipc	ra,0xffffc
    80003f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003f5c:	974a                	add	a4,a4,s2
    80003f5e:	8fd5                	or	a5,a5,a3
    80003f60:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003f64:	854a                	mv	a0,s2
    80003f66:	00001097          	auipc	ra,0x1
    80003f6a:	01a080e7          	jalr	26(ra) # 80004f80 <log_write>
        brelse(bp);
    80003f6e:	854a                	mv	a0,s2
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	d94080e7          	jalr	-620(ra) # 80003d04 <brelse>
  bp = bread(dev, bno);
    80003f78:	85a6                	mv	a1,s1
    80003f7a:	855e                	mv	a0,s7
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	c58080e7          	jalr	-936(ra) # 80003bd4 <bread>
    80003f84:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003f86:	40000613          	li	a2,1024
    80003f8a:	4581                	li	a1,0
    80003f8c:	05850513          	addi	a0,a0,88
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	d50080e7          	jalr	-688(ra) # 80000ce0 <memset>
  log_write(bp);
    80003f98:	854a                	mv	a0,s2
    80003f9a:	00001097          	auipc	ra,0x1
    80003f9e:	fe6080e7          	jalr	-26(ra) # 80004f80 <log_write>
  brelse(bp);
    80003fa2:	854a                	mv	a0,s2
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	d60080e7          	jalr	-672(ra) # 80003d04 <brelse>
}
    80003fac:	8526                	mv	a0,s1
    80003fae:	60e6                	ld	ra,88(sp)
    80003fb0:	6446                	ld	s0,80(sp)
    80003fb2:	64a6                	ld	s1,72(sp)
    80003fb4:	6906                	ld	s2,64(sp)
    80003fb6:	79e2                	ld	s3,56(sp)
    80003fb8:	7a42                	ld	s4,48(sp)
    80003fba:	7aa2                	ld	s5,40(sp)
    80003fbc:	7b02                	ld	s6,32(sp)
    80003fbe:	6be2                	ld	s7,24(sp)
    80003fc0:	6c42                	ld	s8,16(sp)
    80003fc2:	6ca2                	ld	s9,8(sp)
    80003fc4:	6125                	addi	sp,sp,96
    80003fc6:	8082                	ret

0000000080003fc8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003fc8:	7179                	addi	sp,sp,-48
    80003fca:	f406                	sd	ra,40(sp)
    80003fcc:	f022                	sd	s0,32(sp)
    80003fce:	ec26                	sd	s1,24(sp)
    80003fd0:	e84a                	sd	s2,16(sp)
    80003fd2:	e44e                	sd	s3,8(sp)
    80003fd4:	e052                	sd	s4,0(sp)
    80003fd6:	1800                	addi	s0,sp,48
    80003fd8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003fda:	47ad                	li	a5,11
    80003fdc:	04b7fe63          	bgeu	a5,a1,80004038 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003fe0:	ff45849b          	addiw	s1,a1,-12
    80003fe4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003fe8:	0ff00793          	li	a5,255
    80003fec:	0ae7e363          	bltu	a5,a4,80004092 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ff0:	08052583          	lw	a1,128(a0)
    80003ff4:	c5ad                	beqz	a1,8000405e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003ff6:	00092503          	lw	a0,0(s2)
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	bda080e7          	jalr	-1062(ra) # 80003bd4 <bread>
    80004002:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004004:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80004008:	02049593          	slli	a1,s1,0x20
    8000400c:	9181                	srli	a1,a1,0x20
    8000400e:	058a                	slli	a1,a1,0x2
    80004010:	00b784b3          	add	s1,a5,a1
    80004014:	0004a983          	lw	s3,0(s1)
    80004018:	04098d63          	beqz	s3,80004072 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000401c:	8552                	mv	a0,s4
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	ce6080e7          	jalr	-794(ra) # 80003d04 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004026:	854e                	mv	a0,s3
    80004028:	70a2                	ld	ra,40(sp)
    8000402a:	7402                	ld	s0,32(sp)
    8000402c:	64e2                	ld	s1,24(sp)
    8000402e:	6942                	ld	s2,16(sp)
    80004030:	69a2                	ld	s3,8(sp)
    80004032:	6a02                	ld	s4,0(sp)
    80004034:	6145                	addi	sp,sp,48
    80004036:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80004038:	02059493          	slli	s1,a1,0x20
    8000403c:	9081                	srli	s1,s1,0x20
    8000403e:	048a                	slli	s1,s1,0x2
    80004040:	94aa                	add	s1,s1,a0
    80004042:	0504a983          	lw	s3,80(s1)
    80004046:	fe0990e3          	bnez	s3,80004026 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000404a:	4108                	lw	a0,0(a0)
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	e4a080e7          	jalr	-438(ra) # 80003e96 <balloc>
    80004054:	0005099b          	sext.w	s3,a0
    80004058:	0534a823          	sw	s3,80(s1)
    8000405c:	b7e9                	j	80004026 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000405e:	4108                	lw	a0,0(a0)
    80004060:	00000097          	auipc	ra,0x0
    80004064:	e36080e7          	jalr	-458(ra) # 80003e96 <balloc>
    80004068:	0005059b          	sext.w	a1,a0
    8000406c:	08b92023          	sw	a1,128(s2)
    80004070:	b759                	j	80003ff6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80004072:	00092503          	lw	a0,0(s2)
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	e20080e7          	jalr	-480(ra) # 80003e96 <balloc>
    8000407e:	0005099b          	sext.w	s3,a0
    80004082:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80004086:	8552                	mv	a0,s4
    80004088:	00001097          	auipc	ra,0x1
    8000408c:	ef8080e7          	jalr	-264(ra) # 80004f80 <log_write>
    80004090:	b771                	j	8000401c <bmap+0x54>
  panic("bmap: out of range");
    80004092:	00004517          	auipc	a0,0x4
    80004096:	67650513          	addi	a0,a0,1654 # 80008708 <syscalls+0x130>
    8000409a:	ffffc097          	auipc	ra,0xffffc
    8000409e:	4a4080e7          	jalr	1188(ra) # 8000053e <panic>

00000000800040a2 <iget>:
{
    800040a2:	7179                	addi	sp,sp,-48
    800040a4:	f406                	sd	ra,40(sp)
    800040a6:	f022                	sd	s0,32(sp)
    800040a8:	ec26                	sd	s1,24(sp)
    800040aa:	e84a                	sd	s2,16(sp)
    800040ac:	e44e                	sd	s3,8(sp)
    800040ae:	e052                	sd	s4,0(sp)
    800040b0:	1800                	addi	s0,sp,48
    800040b2:	89aa                	mv	s3,a0
    800040b4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800040b6:	0001d517          	auipc	a0,0x1d
    800040ba:	56250513          	addi	a0,a0,1378 # 80021618 <itable>
    800040be:	ffffd097          	auipc	ra,0xffffd
    800040c2:	b26080e7          	jalr	-1242(ra) # 80000be4 <acquire>
  empty = 0;
    800040c6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800040c8:	0001d497          	auipc	s1,0x1d
    800040cc:	56848493          	addi	s1,s1,1384 # 80021630 <itable+0x18>
    800040d0:	0001f697          	auipc	a3,0x1f
    800040d4:	ff068693          	addi	a3,a3,-16 # 800230c0 <log>
    800040d8:	a039                	j	800040e6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800040da:	02090b63          	beqz	s2,80004110 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800040de:	08848493          	addi	s1,s1,136
    800040e2:	02d48a63          	beq	s1,a3,80004116 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800040e6:	449c                	lw	a5,8(s1)
    800040e8:	fef059e3          	blez	a5,800040da <iget+0x38>
    800040ec:	4098                	lw	a4,0(s1)
    800040ee:	ff3716e3          	bne	a4,s3,800040da <iget+0x38>
    800040f2:	40d8                	lw	a4,4(s1)
    800040f4:	ff4713e3          	bne	a4,s4,800040da <iget+0x38>
      ip->ref++;
    800040f8:	2785                	addiw	a5,a5,1
    800040fa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800040fc:	0001d517          	auipc	a0,0x1d
    80004100:	51c50513          	addi	a0,a0,1308 # 80021618 <itable>
    80004104:	ffffd097          	auipc	ra,0xffffd
    80004108:	b94080e7          	jalr	-1132(ra) # 80000c98 <release>
      return ip;
    8000410c:	8926                	mv	s2,s1
    8000410e:	a03d                	j	8000413c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004110:	f7f9                	bnez	a5,800040de <iget+0x3c>
    80004112:	8926                	mv	s2,s1
    80004114:	b7e9                	j	800040de <iget+0x3c>
  if(empty == 0)
    80004116:	02090c63          	beqz	s2,8000414e <iget+0xac>
  ip->dev = dev;
    8000411a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000411e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004122:	4785                	li	a5,1
    80004124:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004128:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000412c:	0001d517          	auipc	a0,0x1d
    80004130:	4ec50513          	addi	a0,a0,1260 # 80021618 <itable>
    80004134:	ffffd097          	auipc	ra,0xffffd
    80004138:	b64080e7          	jalr	-1180(ra) # 80000c98 <release>
}
    8000413c:	854a                	mv	a0,s2
    8000413e:	70a2                	ld	ra,40(sp)
    80004140:	7402                	ld	s0,32(sp)
    80004142:	64e2                	ld	s1,24(sp)
    80004144:	6942                	ld	s2,16(sp)
    80004146:	69a2                	ld	s3,8(sp)
    80004148:	6a02                	ld	s4,0(sp)
    8000414a:	6145                	addi	sp,sp,48
    8000414c:	8082                	ret
    panic("iget: no inodes");
    8000414e:	00004517          	auipc	a0,0x4
    80004152:	5d250513          	addi	a0,a0,1490 # 80008720 <syscalls+0x148>
    80004156:	ffffc097          	auipc	ra,0xffffc
    8000415a:	3e8080e7          	jalr	1000(ra) # 8000053e <panic>

000000008000415e <fsinit>:
fsinit(int dev) {
    8000415e:	7179                	addi	sp,sp,-48
    80004160:	f406                	sd	ra,40(sp)
    80004162:	f022                	sd	s0,32(sp)
    80004164:	ec26                	sd	s1,24(sp)
    80004166:	e84a                	sd	s2,16(sp)
    80004168:	e44e                	sd	s3,8(sp)
    8000416a:	1800                	addi	s0,sp,48
    8000416c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000416e:	4585                	li	a1,1
    80004170:	00000097          	auipc	ra,0x0
    80004174:	a64080e7          	jalr	-1436(ra) # 80003bd4 <bread>
    80004178:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000417a:	0001d997          	auipc	s3,0x1d
    8000417e:	47e98993          	addi	s3,s3,1150 # 800215f8 <sb>
    80004182:	02000613          	li	a2,32
    80004186:	05850593          	addi	a1,a0,88
    8000418a:	854e                	mv	a0,s3
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	bb4080e7          	jalr	-1100(ra) # 80000d40 <memmove>
  brelse(bp);
    80004194:	8526                	mv	a0,s1
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	b6e080e7          	jalr	-1170(ra) # 80003d04 <brelse>
  if(sb.magic != FSMAGIC)
    8000419e:	0009a703          	lw	a4,0(s3)
    800041a2:	102037b7          	lui	a5,0x10203
    800041a6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800041aa:	02f71263          	bne	a4,a5,800041ce <fsinit+0x70>
  initlog(dev, &sb);
    800041ae:	0001d597          	auipc	a1,0x1d
    800041b2:	44a58593          	addi	a1,a1,1098 # 800215f8 <sb>
    800041b6:	854a                	mv	a0,s2
    800041b8:	00001097          	auipc	ra,0x1
    800041bc:	b4c080e7          	jalr	-1204(ra) # 80004d04 <initlog>
}
    800041c0:	70a2                	ld	ra,40(sp)
    800041c2:	7402                	ld	s0,32(sp)
    800041c4:	64e2                	ld	s1,24(sp)
    800041c6:	6942                	ld	s2,16(sp)
    800041c8:	69a2                	ld	s3,8(sp)
    800041ca:	6145                	addi	sp,sp,48
    800041cc:	8082                	ret
    panic("invalid file system");
    800041ce:	00004517          	auipc	a0,0x4
    800041d2:	56250513          	addi	a0,a0,1378 # 80008730 <syscalls+0x158>
    800041d6:	ffffc097          	auipc	ra,0xffffc
    800041da:	368080e7          	jalr	872(ra) # 8000053e <panic>

00000000800041de <iinit>:
{
    800041de:	7179                	addi	sp,sp,-48
    800041e0:	f406                	sd	ra,40(sp)
    800041e2:	f022                	sd	s0,32(sp)
    800041e4:	ec26                	sd	s1,24(sp)
    800041e6:	e84a                	sd	s2,16(sp)
    800041e8:	e44e                	sd	s3,8(sp)
    800041ea:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800041ec:	00004597          	auipc	a1,0x4
    800041f0:	55c58593          	addi	a1,a1,1372 # 80008748 <syscalls+0x170>
    800041f4:	0001d517          	auipc	a0,0x1d
    800041f8:	42450513          	addi	a0,a0,1060 # 80021618 <itable>
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	958080e7          	jalr	-1704(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004204:	0001d497          	auipc	s1,0x1d
    80004208:	43c48493          	addi	s1,s1,1084 # 80021640 <itable+0x28>
    8000420c:	0001f997          	auipc	s3,0x1f
    80004210:	ec498993          	addi	s3,s3,-316 # 800230d0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004214:	00004917          	auipc	s2,0x4
    80004218:	53c90913          	addi	s2,s2,1340 # 80008750 <syscalls+0x178>
    8000421c:	85ca                	mv	a1,s2
    8000421e:	8526                	mv	a0,s1
    80004220:	00001097          	auipc	ra,0x1
    80004224:	e46080e7          	jalr	-442(ra) # 80005066 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004228:	08848493          	addi	s1,s1,136
    8000422c:	ff3498e3          	bne	s1,s3,8000421c <iinit+0x3e>
}
    80004230:	70a2                	ld	ra,40(sp)
    80004232:	7402                	ld	s0,32(sp)
    80004234:	64e2                	ld	s1,24(sp)
    80004236:	6942                	ld	s2,16(sp)
    80004238:	69a2                	ld	s3,8(sp)
    8000423a:	6145                	addi	sp,sp,48
    8000423c:	8082                	ret

000000008000423e <ialloc>:
{
    8000423e:	715d                	addi	sp,sp,-80
    80004240:	e486                	sd	ra,72(sp)
    80004242:	e0a2                	sd	s0,64(sp)
    80004244:	fc26                	sd	s1,56(sp)
    80004246:	f84a                	sd	s2,48(sp)
    80004248:	f44e                	sd	s3,40(sp)
    8000424a:	f052                	sd	s4,32(sp)
    8000424c:	ec56                	sd	s5,24(sp)
    8000424e:	e85a                	sd	s6,16(sp)
    80004250:	e45e                	sd	s7,8(sp)
    80004252:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004254:	0001d717          	auipc	a4,0x1d
    80004258:	3b072703          	lw	a4,944(a4) # 80021604 <sb+0xc>
    8000425c:	4785                	li	a5,1
    8000425e:	04e7fa63          	bgeu	a5,a4,800042b2 <ialloc+0x74>
    80004262:	8aaa                	mv	s5,a0
    80004264:	8bae                	mv	s7,a1
    80004266:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004268:	0001da17          	auipc	s4,0x1d
    8000426c:	390a0a13          	addi	s4,s4,912 # 800215f8 <sb>
    80004270:	00048b1b          	sext.w	s6,s1
    80004274:	0044d593          	srli	a1,s1,0x4
    80004278:	018a2783          	lw	a5,24(s4)
    8000427c:	9dbd                	addw	a1,a1,a5
    8000427e:	8556                	mv	a0,s5
    80004280:	00000097          	auipc	ra,0x0
    80004284:	954080e7          	jalr	-1708(ra) # 80003bd4 <bread>
    80004288:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000428a:	05850993          	addi	s3,a0,88
    8000428e:	00f4f793          	andi	a5,s1,15
    80004292:	079a                	slli	a5,a5,0x6
    80004294:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004296:	00099783          	lh	a5,0(s3)
    8000429a:	c785                	beqz	a5,800042c2 <ialloc+0x84>
    brelse(bp);
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	a68080e7          	jalr	-1432(ra) # 80003d04 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800042a4:	0485                	addi	s1,s1,1
    800042a6:	00ca2703          	lw	a4,12(s4)
    800042aa:	0004879b          	sext.w	a5,s1
    800042ae:	fce7e1e3          	bltu	a5,a4,80004270 <ialloc+0x32>
  panic("ialloc: no inodes");
    800042b2:	00004517          	auipc	a0,0x4
    800042b6:	4a650513          	addi	a0,a0,1190 # 80008758 <syscalls+0x180>
    800042ba:	ffffc097          	auipc	ra,0xffffc
    800042be:	284080e7          	jalr	644(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800042c2:	04000613          	li	a2,64
    800042c6:	4581                	li	a1,0
    800042c8:	854e                	mv	a0,s3
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	a16080e7          	jalr	-1514(ra) # 80000ce0 <memset>
      dip->type = type;
    800042d2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800042d6:	854a                	mv	a0,s2
    800042d8:	00001097          	auipc	ra,0x1
    800042dc:	ca8080e7          	jalr	-856(ra) # 80004f80 <log_write>
      brelse(bp);
    800042e0:	854a                	mv	a0,s2
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	a22080e7          	jalr	-1502(ra) # 80003d04 <brelse>
      return iget(dev, inum);
    800042ea:	85da                	mv	a1,s6
    800042ec:	8556                	mv	a0,s5
    800042ee:	00000097          	auipc	ra,0x0
    800042f2:	db4080e7          	jalr	-588(ra) # 800040a2 <iget>
}
    800042f6:	60a6                	ld	ra,72(sp)
    800042f8:	6406                	ld	s0,64(sp)
    800042fa:	74e2                	ld	s1,56(sp)
    800042fc:	7942                	ld	s2,48(sp)
    800042fe:	79a2                	ld	s3,40(sp)
    80004300:	7a02                	ld	s4,32(sp)
    80004302:	6ae2                	ld	s5,24(sp)
    80004304:	6b42                	ld	s6,16(sp)
    80004306:	6ba2                	ld	s7,8(sp)
    80004308:	6161                	addi	sp,sp,80
    8000430a:	8082                	ret

000000008000430c <iupdate>:
{
    8000430c:	1101                	addi	sp,sp,-32
    8000430e:	ec06                	sd	ra,24(sp)
    80004310:	e822                	sd	s0,16(sp)
    80004312:	e426                	sd	s1,8(sp)
    80004314:	e04a                	sd	s2,0(sp)
    80004316:	1000                	addi	s0,sp,32
    80004318:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000431a:	415c                	lw	a5,4(a0)
    8000431c:	0047d79b          	srliw	a5,a5,0x4
    80004320:	0001d597          	auipc	a1,0x1d
    80004324:	2f05a583          	lw	a1,752(a1) # 80021610 <sb+0x18>
    80004328:	9dbd                	addw	a1,a1,a5
    8000432a:	4108                	lw	a0,0(a0)
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	8a8080e7          	jalr	-1880(ra) # 80003bd4 <bread>
    80004334:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004336:	05850793          	addi	a5,a0,88
    8000433a:	40c8                	lw	a0,4(s1)
    8000433c:	893d                	andi	a0,a0,15
    8000433e:	051a                	slli	a0,a0,0x6
    80004340:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004342:	04449703          	lh	a4,68(s1)
    80004346:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000434a:	04649703          	lh	a4,70(s1)
    8000434e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004352:	04849703          	lh	a4,72(s1)
    80004356:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000435a:	04a49703          	lh	a4,74(s1)
    8000435e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004362:	44f8                	lw	a4,76(s1)
    80004364:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004366:	03400613          	li	a2,52
    8000436a:	05048593          	addi	a1,s1,80
    8000436e:	0531                	addi	a0,a0,12
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	9d0080e7          	jalr	-1584(ra) # 80000d40 <memmove>
  log_write(bp);
    80004378:	854a                	mv	a0,s2
    8000437a:	00001097          	auipc	ra,0x1
    8000437e:	c06080e7          	jalr	-1018(ra) # 80004f80 <log_write>
  brelse(bp);
    80004382:	854a                	mv	a0,s2
    80004384:	00000097          	auipc	ra,0x0
    80004388:	980080e7          	jalr	-1664(ra) # 80003d04 <brelse>
}
    8000438c:	60e2                	ld	ra,24(sp)
    8000438e:	6442                	ld	s0,16(sp)
    80004390:	64a2                	ld	s1,8(sp)
    80004392:	6902                	ld	s2,0(sp)
    80004394:	6105                	addi	sp,sp,32
    80004396:	8082                	ret

0000000080004398 <idup>:
{
    80004398:	1101                	addi	sp,sp,-32
    8000439a:	ec06                	sd	ra,24(sp)
    8000439c:	e822                	sd	s0,16(sp)
    8000439e:	e426                	sd	s1,8(sp)
    800043a0:	1000                	addi	s0,sp,32
    800043a2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800043a4:	0001d517          	auipc	a0,0x1d
    800043a8:	27450513          	addi	a0,a0,628 # 80021618 <itable>
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
  ip->ref++;
    800043b4:	449c                	lw	a5,8(s1)
    800043b6:	2785                	addiw	a5,a5,1
    800043b8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800043ba:	0001d517          	auipc	a0,0x1d
    800043be:	25e50513          	addi	a0,a0,606 # 80021618 <itable>
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	8d6080e7          	jalr	-1834(ra) # 80000c98 <release>
}
    800043ca:	8526                	mv	a0,s1
    800043cc:	60e2                	ld	ra,24(sp)
    800043ce:	6442                	ld	s0,16(sp)
    800043d0:	64a2                	ld	s1,8(sp)
    800043d2:	6105                	addi	sp,sp,32
    800043d4:	8082                	ret

00000000800043d6 <ilock>:
{
    800043d6:	1101                	addi	sp,sp,-32
    800043d8:	ec06                	sd	ra,24(sp)
    800043da:	e822                	sd	s0,16(sp)
    800043dc:	e426                	sd	s1,8(sp)
    800043de:	e04a                	sd	s2,0(sp)
    800043e0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800043e2:	c115                	beqz	a0,80004406 <ilock+0x30>
    800043e4:	84aa                	mv	s1,a0
    800043e6:	451c                	lw	a5,8(a0)
    800043e8:	00f05f63          	blez	a5,80004406 <ilock+0x30>
  acquiresleep(&ip->lock);
    800043ec:	0541                	addi	a0,a0,16
    800043ee:	00001097          	auipc	ra,0x1
    800043f2:	cb2080e7          	jalr	-846(ra) # 800050a0 <acquiresleep>
  if(ip->valid == 0){
    800043f6:	40bc                	lw	a5,64(s1)
    800043f8:	cf99                	beqz	a5,80004416 <ilock+0x40>
}
    800043fa:	60e2                	ld	ra,24(sp)
    800043fc:	6442                	ld	s0,16(sp)
    800043fe:	64a2                	ld	s1,8(sp)
    80004400:	6902                	ld	s2,0(sp)
    80004402:	6105                	addi	sp,sp,32
    80004404:	8082                	ret
    panic("ilock");
    80004406:	00004517          	auipc	a0,0x4
    8000440a:	36a50513          	addi	a0,a0,874 # 80008770 <syscalls+0x198>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	130080e7          	jalr	304(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004416:	40dc                	lw	a5,4(s1)
    80004418:	0047d79b          	srliw	a5,a5,0x4
    8000441c:	0001d597          	auipc	a1,0x1d
    80004420:	1f45a583          	lw	a1,500(a1) # 80021610 <sb+0x18>
    80004424:	9dbd                	addw	a1,a1,a5
    80004426:	4088                	lw	a0,0(s1)
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	7ac080e7          	jalr	1964(ra) # 80003bd4 <bread>
    80004430:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004432:	05850593          	addi	a1,a0,88
    80004436:	40dc                	lw	a5,4(s1)
    80004438:	8bbd                	andi	a5,a5,15
    8000443a:	079a                	slli	a5,a5,0x6
    8000443c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000443e:	00059783          	lh	a5,0(a1)
    80004442:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004446:	00259783          	lh	a5,2(a1)
    8000444a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000444e:	00459783          	lh	a5,4(a1)
    80004452:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004456:	00659783          	lh	a5,6(a1)
    8000445a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000445e:	459c                	lw	a5,8(a1)
    80004460:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004462:	03400613          	li	a2,52
    80004466:	05b1                	addi	a1,a1,12
    80004468:	05048513          	addi	a0,s1,80
    8000446c:	ffffd097          	auipc	ra,0xffffd
    80004470:	8d4080e7          	jalr	-1836(ra) # 80000d40 <memmove>
    brelse(bp);
    80004474:	854a                	mv	a0,s2
    80004476:	00000097          	auipc	ra,0x0
    8000447a:	88e080e7          	jalr	-1906(ra) # 80003d04 <brelse>
    ip->valid = 1;
    8000447e:	4785                	li	a5,1
    80004480:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004482:	04449783          	lh	a5,68(s1)
    80004486:	fbb5                	bnez	a5,800043fa <ilock+0x24>
      panic("ilock: no type");
    80004488:	00004517          	auipc	a0,0x4
    8000448c:	2f050513          	addi	a0,a0,752 # 80008778 <syscalls+0x1a0>
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	0ae080e7          	jalr	174(ra) # 8000053e <panic>

0000000080004498 <iunlock>:
{
    80004498:	1101                	addi	sp,sp,-32
    8000449a:	ec06                	sd	ra,24(sp)
    8000449c:	e822                	sd	s0,16(sp)
    8000449e:	e426                	sd	s1,8(sp)
    800044a0:	e04a                	sd	s2,0(sp)
    800044a2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800044a4:	c905                	beqz	a0,800044d4 <iunlock+0x3c>
    800044a6:	84aa                	mv	s1,a0
    800044a8:	01050913          	addi	s2,a0,16
    800044ac:	854a                	mv	a0,s2
    800044ae:	00001097          	auipc	ra,0x1
    800044b2:	c8c080e7          	jalr	-884(ra) # 8000513a <holdingsleep>
    800044b6:	cd19                	beqz	a0,800044d4 <iunlock+0x3c>
    800044b8:	449c                	lw	a5,8(s1)
    800044ba:	00f05d63          	blez	a5,800044d4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800044be:	854a                	mv	a0,s2
    800044c0:	00001097          	auipc	ra,0x1
    800044c4:	c36080e7          	jalr	-970(ra) # 800050f6 <releasesleep>
}
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	64a2                	ld	s1,8(sp)
    800044ce:	6902                	ld	s2,0(sp)
    800044d0:	6105                	addi	sp,sp,32
    800044d2:	8082                	ret
    panic("iunlock");
    800044d4:	00004517          	auipc	a0,0x4
    800044d8:	2b450513          	addi	a0,a0,692 # 80008788 <syscalls+0x1b0>
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	062080e7          	jalr	98(ra) # 8000053e <panic>

00000000800044e4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800044e4:	7179                	addi	sp,sp,-48
    800044e6:	f406                	sd	ra,40(sp)
    800044e8:	f022                	sd	s0,32(sp)
    800044ea:	ec26                	sd	s1,24(sp)
    800044ec:	e84a                	sd	s2,16(sp)
    800044ee:	e44e                	sd	s3,8(sp)
    800044f0:	e052                	sd	s4,0(sp)
    800044f2:	1800                	addi	s0,sp,48
    800044f4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800044f6:	05050493          	addi	s1,a0,80
    800044fa:	08050913          	addi	s2,a0,128
    800044fe:	a021                	j	80004506 <itrunc+0x22>
    80004500:	0491                	addi	s1,s1,4
    80004502:	01248d63          	beq	s1,s2,8000451c <itrunc+0x38>
    if(ip->addrs[i]){
    80004506:	408c                	lw	a1,0(s1)
    80004508:	dde5                	beqz	a1,80004500 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000450a:	0009a503          	lw	a0,0(s3)
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	90c080e7          	jalr	-1780(ra) # 80003e1a <bfree>
      ip->addrs[i] = 0;
    80004516:	0004a023          	sw	zero,0(s1)
    8000451a:	b7dd                	j	80004500 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000451c:	0809a583          	lw	a1,128(s3)
    80004520:	e185                	bnez	a1,80004540 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004522:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004526:	854e                	mv	a0,s3
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	de4080e7          	jalr	-540(ra) # 8000430c <iupdate>
}
    80004530:	70a2                	ld	ra,40(sp)
    80004532:	7402                	ld	s0,32(sp)
    80004534:	64e2                	ld	s1,24(sp)
    80004536:	6942                	ld	s2,16(sp)
    80004538:	69a2                	ld	s3,8(sp)
    8000453a:	6a02                	ld	s4,0(sp)
    8000453c:	6145                	addi	sp,sp,48
    8000453e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004540:	0009a503          	lw	a0,0(s3)
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	690080e7          	jalr	1680(ra) # 80003bd4 <bread>
    8000454c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000454e:	05850493          	addi	s1,a0,88
    80004552:	45850913          	addi	s2,a0,1112
    80004556:	a811                	j	8000456a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004558:	0009a503          	lw	a0,0(s3)
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	8be080e7          	jalr	-1858(ra) # 80003e1a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004564:	0491                	addi	s1,s1,4
    80004566:	01248563          	beq	s1,s2,80004570 <itrunc+0x8c>
      if(a[j])
    8000456a:	408c                	lw	a1,0(s1)
    8000456c:	dde5                	beqz	a1,80004564 <itrunc+0x80>
    8000456e:	b7ed                	j	80004558 <itrunc+0x74>
    brelse(bp);
    80004570:	8552                	mv	a0,s4
    80004572:	fffff097          	auipc	ra,0xfffff
    80004576:	792080e7          	jalr	1938(ra) # 80003d04 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000457a:	0809a583          	lw	a1,128(s3)
    8000457e:	0009a503          	lw	a0,0(s3)
    80004582:	00000097          	auipc	ra,0x0
    80004586:	898080e7          	jalr	-1896(ra) # 80003e1a <bfree>
    ip->addrs[NDIRECT] = 0;
    8000458a:	0809a023          	sw	zero,128(s3)
    8000458e:	bf51                	j	80004522 <itrunc+0x3e>

0000000080004590 <iput>:
{
    80004590:	1101                	addi	sp,sp,-32
    80004592:	ec06                	sd	ra,24(sp)
    80004594:	e822                	sd	s0,16(sp)
    80004596:	e426                	sd	s1,8(sp)
    80004598:	e04a                	sd	s2,0(sp)
    8000459a:	1000                	addi	s0,sp,32
    8000459c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000459e:	0001d517          	auipc	a0,0x1d
    800045a2:	07a50513          	addi	a0,a0,122 # 80021618 <itable>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	63e080e7          	jalr	1598(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800045ae:	4498                	lw	a4,8(s1)
    800045b0:	4785                	li	a5,1
    800045b2:	02f70363          	beq	a4,a5,800045d8 <iput+0x48>
  ip->ref--;
    800045b6:	449c                	lw	a5,8(s1)
    800045b8:	37fd                	addiw	a5,a5,-1
    800045ba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800045bc:	0001d517          	auipc	a0,0x1d
    800045c0:	05c50513          	addi	a0,a0,92 # 80021618 <itable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	6d4080e7          	jalr	1748(ra) # 80000c98 <release>
}
    800045cc:	60e2                	ld	ra,24(sp)
    800045ce:	6442                	ld	s0,16(sp)
    800045d0:	64a2                	ld	s1,8(sp)
    800045d2:	6902                	ld	s2,0(sp)
    800045d4:	6105                	addi	sp,sp,32
    800045d6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800045d8:	40bc                	lw	a5,64(s1)
    800045da:	dff1                	beqz	a5,800045b6 <iput+0x26>
    800045dc:	04a49783          	lh	a5,74(s1)
    800045e0:	fbf9                	bnez	a5,800045b6 <iput+0x26>
    acquiresleep(&ip->lock);
    800045e2:	01048913          	addi	s2,s1,16
    800045e6:	854a                	mv	a0,s2
    800045e8:	00001097          	auipc	ra,0x1
    800045ec:	ab8080e7          	jalr	-1352(ra) # 800050a0 <acquiresleep>
    release(&itable.lock);
    800045f0:	0001d517          	auipc	a0,0x1d
    800045f4:	02850513          	addi	a0,a0,40 # 80021618 <itable>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	6a0080e7          	jalr	1696(ra) # 80000c98 <release>
    itrunc(ip);
    80004600:	8526                	mv	a0,s1
    80004602:	00000097          	auipc	ra,0x0
    80004606:	ee2080e7          	jalr	-286(ra) # 800044e4 <itrunc>
    ip->type = 0;
    8000460a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000460e:	8526                	mv	a0,s1
    80004610:	00000097          	auipc	ra,0x0
    80004614:	cfc080e7          	jalr	-772(ra) # 8000430c <iupdate>
    ip->valid = 0;
    80004618:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000461c:	854a                	mv	a0,s2
    8000461e:	00001097          	auipc	ra,0x1
    80004622:	ad8080e7          	jalr	-1320(ra) # 800050f6 <releasesleep>
    acquire(&itable.lock);
    80004626:	0001d517          	auipc	a0,0x1d
    8000462a:	ff250513          	addi	a0,a0,-14 # 80021618 <itable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	5b6080e7          	jalr	1462(ra) # 80000be4 <acquire>
    80004636:	b741                	j	800045b6 <iput+0x26>

0000000080004638 <iunlockput>:
{
    80004638:	1101                	addi	sp,sp,-32
    8000463a:	ec06                	sd	ra,24(sp)
    8000463c:	e822                	sd	s0,16(sp)
    8000463e:	e426                	sd	s1,8(sp)
    80004640:	1000                	addi	s0,sp,32
    80004642:	84aa                	mv	s1,a0
  iunlock(ip);
    80004644:	00000097          	auipc	ra,0x0
    80004648:	e54080e7          	jalr	-428(ra) # 80004498 <iunlock>
  iput(ip);
    8000464c:	8526                	mv	a0,s1
    8000464e:	00000097          	auipc	ra,0x0
    80004652:	f42080e7          	jalr	-190(ra) # 80004590 <iput>
}
    80004656:	60e2                	ld	ra,24(sp)
    80004658:	6442                	ld	s0,16(sp)
    8000465a:	64a2                	ld	s1,8(sp)
    8000465c:	6105                	addi	sp,sp,32
    8000465e:	8082                	ret

0000000080004660 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004660:	1141                	addi	sp,sp,-16
    80004662:	e422                	sd	s0,8(sp)
    80004664:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004666:	411c                	lw	a5,0(a0)
    80004668:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000466a:	415c                	lw	a5,4(a0)
    8000466c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000466e:	04451783          	lh	a5,68(a0)
    80004672:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004676:	04a51783          	lh	a5,74(a0)
    8000467a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000467e:	04c56783          	lwu	a5,76(a0)
    80004682:	e99c                	sd	a5,16(a1)
}
    80004684:	6422                	ld	s0,8(sp)
    80004686:	0141                	addi	sp,sp,16
    80004688:	8082                	ret

000000008000468a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000468a:	457c                	lw	a5,76(a0)
    8000468c:	0ed7e963          	bltu	a5,a3,8000477e <readi+0xf4>
{
    80004690:	7159                	addi	sp,sp,-112
    80004692:	f486                	sd	ra,104(sp)
    80004694:	f0a2                	sd	s0,96(sp)
    80004696:	eca6                	sd	s1,88(sp)
    80004698:	e8ca                	sd	s2,80(sp)
    8000469a:	e4ce                	sd	s3,72(sp)
    8000469c:	e0d2                	sd	s4,64(sp)
    8000469e:	fc56                	sd	s5,56(sp)
    800046a0:	f85a                	sd	s6,48(sp)
    800046a2:	f45e                	sd	s7,40(sp)
    800046a4:	f062                	sd	s8,32(sp)
    800046a6:	ec66                	sd	s9,24(sp)
    800046a8:	e86a                	sd	s10,16(sp)
    800046aa:	e46e                	sd	s11,8(sp)
    800046ac:	1880                	addi	s0,sp,112
    800046ae:	8baa                	mv	s7,a0
    800046b0:	8c2e                	mv	s8,a1
    800046b2:	8ab2                	mv	s5,a2
    800046b4:	84b6                	mv	s1,a3
    800046b6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800046b8:	9f35                	addw	a4,a4,a3
    return 0;
    800046ba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800046bc:	0ad76063          	bltu	a4,a3,8000475c <readi+0xd2>
  if(off + n > ip->size)
    800046c0:	00e7f463          	bgeu	a5,a4,800046c8 <readi+0x3e>
    n = ip->size - off;
    800046c4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046c8:	0a0b0963          	beqz	s6,8000477a <readi+0xf0>
    800046cc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800046ce:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800046d2:	5cfd                	li	s9,-1
    800046d4:	a82d                	j	8000470e <readi+0x84>
    800046d6:	020a1d93          	slli	s11,s4,0x20
    800046da:	020ddd93          	srli	s11,s11,0x20
    800046de:	05890613          	addi	a2,s2,88
    800046e2:	86ee                	mv	a3,s11
    800046e4:	963a                	add	a2,a2,a4
    800046e6:	85d6                	mv	a1,s5
    800046e8:	8562                	mv	a0,s8
    800046ea:	ffffe097          	auipc	ra,0xffffe
    800046ee:	3c8080e7          	jalr	968(ra) # 80002ab2 <either_copyout>
    800046f2:	05950d63          	beq	a0,s9,8000474c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800046f6:	854a                	mv	a0,s2
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	60c080e7          	jalr	1548(ra) # 80003d04 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004700:	013a09bb          	addw	s3,s4,s3
    80004704:	009a04bb          	addw	s1,s4,s1
    80004708:	9aee                	add	s5,s5,s11
    8000470a:	0569f763          	bgeu	s3,s6,80004758 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000470e:	000ba903          	lw	s2,0(s7)
    80004712:	00a4d59b          	srliw	a1,s1,0xa
    80004716:	855e                	mv	a0,s7
    80004718:	00000097          	auipc	ra,0x0
    8000471c:	8b0080e7          	jalr	-1872(ra) # 80003fc8 <bmap>
    80004720:	0005059b          	sext.w	a1,a0
    80004724:	854a                	mv	a0,s2
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	4ae080e7          	jalr	1198(ra) # 80003bd4 <bread>
    8000472e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004730:	3ff4f713          	andi	a4,s1,1023
    80004734:	40ed07bb          	subw	a5,s10,a4
    80004738:	413b06bb          	subw	a3,s6,s3
    8000473c:	8a3e                	mv	s4,a5
    8000473e:	2781                	sext.w	a5,a5
    80004740:	0006861b          	sext.w	a2,a3
    80004744:	f8f679e3          	bgeu	a2,a5,800046d6 <readi+0x4c>
    80004748:	8a36                	mv	s4,a3
    8000474a:	b771                	j	800046d6 <readi+0x4c>
      brelse(bp);
    8000474c:	854a                	mv	a0,s2
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	5b6080e7          	jalr	1462(ra) # 80003d04 <brelse>
      tot = -1;
    80004756:	59fd                	li	s3,-1
  }
  return tot;
    80004758:	0009851b          	sext.w	a0,s3
}
    8000475c:	70a6                	ld	ra,104(sp)
    8000475e:	7406                	ld	s0,96(sp)
    80004760:	64e6                	ld	s1,88(sp)
    80004762:	6946                	ld	s2,80(sp)
    80004764:	69a6                	ld	s3,72(sp)
    80004766:	6a06                	ld	s4,64(sp)
    80004768:	7ae2                	ld	s5,56(sp)
    8000476a:	7b42                	ld	s6,48(sp)
    8000476c:	7ba2                	ld	s7,40(sp)
    8000476e:	7c02                	ld	s8,32(sp)
    80004770:	6ce2                	ld	s9,24(sp)
    80004772:	6d42                	ld	s10,16(sp)
    80004774:	6da2                	ld	s11,8(sp)
    80004776:	6165                	addi	sp,sp,112
    80004778:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000477a:	89da                	mv	s3,s6
    8000477c:	bff1                	j	80004758 <readi+0xce>
    return 0;
    8000477e:	4501                	li	a0,0
}
    80004780:	8082                	ret

0000000080004782 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004782:	457c                	lw	a5,76(a0)
    80004784:	10d7e863          	bltu	a5,a3,80004894 <writei+0x112>
{
    80004788:	7159                	addi	sp,sp,-112
    8000478a:	f486                	sd	ra,104(sp)
    8000478c:	f0a2                	sd	s0,96(sp)
    8000478e:	eca6                	sd	s1,88(sp)
    80004790:	e8ca                	sd	s2,80(sp)
    80004792:	e4ce                	sd	s3,72(sp)
    80004794:	e0d2                	sd	s4,64(sp)
    80004796:	fc56                	sd	s5,56(sp)
    80004798:	f85a                	sd	s6,48(sp)
    8000479a:	f45e                	sd	s7,40(sp)
    8000479c:	f062                	sd	s8,32(sp)
    8000479e:	ec66                	sd	s9,24(sp)
    800047a0:	e86a                	sd	s10,16(sp)
    800047a2:	e46e                	sd	s11,8(sp)
    800047a4:	1880                	addi	s0,sp,112
    800047a6:	8b2a                	mv	s6,a0
    800047a8:	8c2e                	mv	s8,a1
    800047aa:	8ab2                	mv	s5,a2
    800047ac:	8936                	mv	s2,a3
    800047ae:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800047b0:	00e687bb          	addw	a5,a3,a4
    800047b4:	0ed7e263          	bltu	a5,a3,80004898 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800047b8:	00043737          	lui	a4,0x43
    800047bc:	0ef76063          	bltu	a4,a5,8000489c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800047c0:	0c0b8863          	beqz	s7,80004890 <writei+0x10e>
    800047c4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800047c6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800047ca:	5cfd                	li	s9,-1
    800047cc:	a091                	j	80004810 <writei+0x8e>
    800047ce:	02099d93          	slli	s11,s3,0x20
    800047d2:	020ddd93          	srli	s11,s11,0x20
    800047d6:	05848513          	addi	a0,s1,88
    800047da:	86ee                	mv	a3,s11
    800047dc:	8656                	mv	a2,s5
    800047de:	85e2                	mv	a1,s8
    800047e0:	953a                	add	a0,a0,a4
    800047e2:	ffffe097          	auipc	ra,0xffffe
    800047e6:	326080e7          	jalr	806(ra) # 80002b08 <either_copyin>
    800047ea:	07950263          	beq	a0,s9,8000484e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800047ee:	8526                	mv	a0,s1
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	790080e7          	jalr	1936(ra) # 80004f80 <log_write>
    brelse(bp);
    800047f8:	8526                	mv	a0,s1
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	50a080e7          	jalr	1290(ra) # 80003d04 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004802:	01498a3b          	addw	s4,s3,s4
    80004806:	0129893b          	addw	s2,s3,s2
    8000480a:	9aee                	add	s5,s5,s11
    8000480c:	057a7663          	bgeu	s4,s7,80004858 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004810:	000b2483          	lw	s1,0(s6)
    80004814:	00a9559b          	srliw	a1,s2,0xa
    80004818:	855a                	mv	a0,s6
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	7ae080e7          	jalr	1966(ra) # 80003fc8 <bmap>
    80004822:	0005059b          	sext.w	a1,a0
    80004826:	8526                	mv	a0,s1
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	3ac080e7          	jalr	940(ra) # 80003bd4 <bread>
    80004830:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004832:	3ff97713          	andi	a4,s2,1023
    80004836:	40ed07bb          	subw	a5,s10,a4
    8000483a:	414b86bb          	subw	a3,s7,s4
    8000483e:	89be                	mv	s3,a5
    80004840:	2781                	sext.w	a5,a5
    80004842:	0006861b          	sext.w	a2,a3
    80004846:	f8f674e3          	bgeu	a2,a5,800047ce <writei+0x4c>
    8000484a:	89b6                	mv	s3,a3
    8000484c:	b749                	j	800047ce <writei+0x4c>
      brelse(bp);
    8000484e:	8526                	mv	a0,s1
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	4b4080e7          	jalr	1204(ra) # 80003d04 <brelse>
  }

  if(off > ip->size)
    80004858:	04cb2783          	lw	a5,76(s6)
    8000485c:	0127f463          	bgeu	a5,s2,80004864 <writei+0xe2>
    ip->size = off;
    80004860:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004864:	855a                	mv	a0,s6
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	aa6080e7          	jalr	-1370(ra) # 8000430c <iupdate>

  return tot;
    8000486e:	000a051b          	sext.w	a0,s4
}
    80004872:	70a6                	ld	ra,104(sp)
    80004874:	7406                	ld	s0,96(sp)
    80004876:	64e6                	ld	s1,88(sp)
    80004878:	6946                	ld	s2,80(sp)
    8000487a:	69a6                	ld	s3,72(sp)
    8000487c:	6a06                	ld	s4,64(sp)
    8000487e:	7ae2                	ld	s5,56(sp)
    80004880:	7b42                	ld	s6,48(sp)
    80004882:	7ba2                	ld	s7,40(sp)
    80004884:	7c02                	ld	s8,32(sp)
    80004886:	6ce2                	ld	s9,24(sp)
    80004888:	6d42                	ld	s10,16(sp)
    8000488a:	6da2                	ld	s11,8(sp)
    8000488c:	6165                	addi	sp,sp,112
    8000488e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004890:	8a5e                	mv	s4,s7
    80004892:	bfc9                	j	80004864 <writei+0xe2>
    return -1;
    80004894:	557d                	li	a0,-1
}
    80004896:	8082                	ret
    return -1;
    80004898:	557d                	li	a0,-1
    8000489a:	bfe1                	j	80004872 <writei+0xf0>
    return -1;
    8000489c:	557d                	li	a0,-1
    8000489e:	bfd1                	j	80004872 <writei+0xf0>

00000000800048a0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800048a0:	1141                	addi	sp,sp,-16
    800048a2:	e406                	sd	ra,8(sp)
    800048a4:	e022                	sd	s0,0(sp)
    800048a6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800048a8:	4639                	li	a2,14
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	50e080e7          	jalr	1294(ra) # 80000db8 <strncmp>
}
    800048b2:	60a2                	ld	ra,8(sp)
    800048b4:	6402                	ld	s0,0(sp)
    800048b6:	0141                	addi	sp,sp,16
    800048b8:	8082                	ret

00000000800048ba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800048ba:	7139                	addi	sp,sp,-64
    800048bc:	fc06                	sd	ra,56(sp)
    800048be:	f822                	sd	s0,48(sp)
    800048c0:	f426                	sd	s1,40(sp)
    800048c2:	f04a                	sd	s2,32(sp)
    800048c4:	ec4e                	sd	s3,24(sp)
    800048c6:	e852                	sd	s4,16(sp)
    800048c8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800048ca:	04451703          	lh	a4,68(a0)
    800048ce:	4785                	li	a5,1
    800048d0:	00f71a63          	bne	a4,a5,800048e4 <dirlookup+0x2a>
    800048d4:	892a                	mv	s2,a0
    800048d6:	89ae                	mv	s3,a1
    800048d8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800048da:	457c                	lw	a5,76(a0)
    800048dc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800048de:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048e0:	e79d                	bnez	a5,8000490e <dirlookup+0x54>
    800048e2:	a8a5                	j	8000495a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800048e4:	00004517          	auipc	a0,0x4
    800048e8:	eac50513          	addi	a0,a0,-340 # 80008790 <syscalls+0x1b8>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	c52080e7          	jalr	-942(ra) # 8000053e <panic>
      panic("dirlookup read");
    800048f4:	00004517          	auipc	a0,0x4
    800048f8:	eb450513          	addi	a0,a0,-332 # 800087a8 <syscalls+0x1d0>
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	c42080e7          	jalr	-958(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004904:	24c1                	addiw	s1,s1,16
    80004906:	04c92783          	lw	a5,76(s2)
    8000490a:	04f4f763          	bgeu	s1,a5,80004958 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000490e:	4741                	li	a4,16
    80004910:	86a6                	mv	a3,s1
    80004912:	fc040613          	addi	a2,s0,-64
    80004916:	4581                	li	a1,0
    80004918:	854a                	mv	a0,s2
    8000491a:	00000097          	auipc	ra,0x0
    8000491e:	d70080e7          	jalr	-656(ra) # 8000468a <readi>
    80004922:	47c1                	li	a5,16
    80004924:	fcf518e3          	bne	a0,a5,800048f4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004928:	fc045783          	lhu	a5,-64(s0)
    8000492c:	dfe1                	beqz	a5,80004904 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000492e:	fc240593          	addi	a1,s0,-62
    80004932:	854e                	mv	a0,s3
    80004934:	00000097          	auipc	ra,0x0
    80004938:	f6c080e7          	jalr	-148(ra) # 800048a0 <namecmp>
    8000493c:	f561                	bnez	a0,80004904 <dirlookup+0x4a>
      if(poff)
    8000493e:	000a0463          	beqz	s4,80004946 <dirlookup+0x8c>
        *poff = off;
    80004942:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004946:	fc045583          	lhu	a1,-64(s0)
    8000494a:	00092503          	lw	a0,0(s2)
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	754080e7          	jalr	1876(ra) # 800040a2 <iget>
    80004956:	a011                	j	8000495a <dirlookup+0xa0>
  return 0;
    80004958:	4501                	li	a0,0
}
    8000495a:	70e2                	ld	ra,56(sp)
    8000495c:	7442                	ld	s0,48(sp)
    8000495e:	74a2                	ld	s1,40(sp)
    80004960:	7902                	ld	s2,32(sp)
    80004962:	69e2                	ld	s3,24(sp)
    80004964:	6a42                	ld	s4,16(sp)
    80004966:	6121                	addi	sp,sp,64
    80004968:	8082                	ret

000000008000496a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000496a:	711d                	addi	sp,sp,-96
    8000496c:	ec86                	sd	ra,88(sp)
    8000496e:	e8a2                	sd	s0,80(sp)
    80004970:	e4a6                	sd	s1,72(sp)
    80004972:	e0ca                	sd	s2,64(sp)
    80004974:	fc4e                	sd	s3,56(sp)
    80004976:	f852                	sd	s4,48(sp)
    80004978:	f456                	sd	s5,40(sp)
    8000497a:	f05a                	sd	s6,32(sp)
    8000497c:	ec5e                	sd	s7,24(sp)
    8000497e:	e862                	sd	s8,16(sp)
    80004980:	e466                	sd	s9,8(sp)
    80004982:	1080                	addi	s0,sp,96
    80004984:	84aa                	mv	s1,a0
    80004986:	8b2e                	mv	s6,a1
    80004988:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000498a:	00054703          	lbu	a4,0(a0)
    8000498e:	02f00793          	li	a5,47
    80004992:	02f70363          	beq	a4,a5,800049b8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004996:	ffffd097          	auipc	ra,0xffffd
    8000499a:	022080e7          	jalr	34(ra) # 800019b8 <myproc>
    8000499e:	17053503          	ld	a0,368(a0)
    800049a2:	00000097          	auipc	ra,0x0
    800049a6:	9f6080e7          	jalr	-1546(ra) # 80004398 <idup>
    800049aa:	89aa                	mv	s3,a0
  while(*path == '/')
    800049ac:	02f00913          	li	s2,47
  len = path - s;
    800049b0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800049b2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800049b4:	4c05                	li	s8,1
    800049b6:	a865                	j	80004a6e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800049b8:	4585                	li	a1,1
    800049ba:	4505                	li	a0,1
    800049bc:	fffff097          	auipc	ra,0xfffff
    800049c0:	6e6080e7          	jalr	1766(ra) # 800040a2 <iget>
    800049c4:	89aa                	mv	s3,a0
    800049c6:	b7dd                	j	800049ac <namex+0x42>
      iunlockput(ip);
    800049c8:	854e                	mv	a0,s3
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	c6e080e7          	jalr	-914(ra) # 80004638 <iunlockput>
      return 0;
    800049d2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800049d4:	854e                	mv	a0,s3
    800049d6:	60e6                	ld	ra,88(sp)
    800049d8:	6446                	ld	s0,80(sp)
    800049da:	64a6                	ld	s1,72(sp)
    800049dc:	6906                	ld	s2,64(sp)
    800049de:	79e2                	ld	s3,56(sp)
    800049e0:	7a42                	ld	s4,48(sp)
    800049e2:	7aa2                	ld	s5,40(sp)
    800049e4:	7b02                	ld	s6,32(sp)
    800049e6:	6be2                	ld	s7,24(sp)
    800049e8:	6c42                	ld	s8,16(sp)
    800049ea:	6ca2                	ld	s9,8(sp)
    800049ec:	6125                	addi	sp,sp,96
    800049ee:	8082                	ret
      iunlock(ip);
    800049f0:	854e                	mv	a0,s3
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	aa6080e7          	jalr	-1370(ra) # 80004498 <iunlock>
      return ip;
    800049fa:	bfe9                	j	800049d4 <namex+0x6a>
      iunlockput(ip);
    800049fc:	854e                	mv	a0,s3
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	c3a080e7          	jalr	-966(ra) # 80004638 <iunlockput>
      return 0;
    80004a06:	89d2                	mv	s3,s4
    80004a08:	b7f1                	j	800049d4 <namex+0x6a>
  len = path - s;
    80004a0a:	40b48633          	sub	a2,s1,a1
    80004a0e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004a12:	094cd463          	bge	s9,s4,80004a9a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004a16:	4639                	li	a2,14
    80004a18:	8556                	mv	a0,s5
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	326080e7          	jalr	806(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004a22:	0004c783          	lbu	a5,0(s1)
    80004a26:	01279763          	bne	a5,s2,80004a34 <namex+0xca>
    path++;
    80004a2a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004a2c:	0004c783          	lbu	a5,0(s1)
    80004a30:	ff278de3          	beq	a5,s2,80004a2a <namex+0xc0>
    ilock(ip);
    80004a34:	854e                	mv	a0,s3
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	9a0080e7          	jalr	-1632(ra) # 800043d6 <ilock>
    if(ip->type != T_DIR){
    80004a3e:	04499783          	lh	a5,68(s3)
    80004a42:	f98793e3          	bne	a5,s8,800049c8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004a46:	000b0563          	beqz	s6,80004a50 <namex+0xe6>
    80004a4a:	0004c783          	lbu	a5,0(s1)
    80004a4e:	d3cd                	beqz	a5,800049f0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004a50:	865e                	mv	a2,s7
    80004a52:	85d6                	mv	a1,s5
    80004a54:	854e                	mv	a0,s3
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	e64080e7          	jalr	-412(ra) # 800048ba <dirlookup>
    80004a5e:	8a2a                	mv	s4,a0
    80004a60:	dd51                	beqz	a0,800049fc <namex+0x92>
    iunlockput(ip);
    80004a62:	854e                	mv	a0,s3
    80004a64:	00000097          	auipc	ra,0x0
    80004a68:	bd4080e7          	jalr	-1068(ra) # 80004638 <iunlockput>
    ip = next;
    80004a6c:	89d2                	mv	s3,s4
  while(*path == '/')
    80004a6e:	0004c783          	lbu	a5,0(s1)
    80004a72:	05279763          	bne	a5,s2,80004ac0 <namex+0x156>
    path++;
    80004a76:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004a78:	0004c783          	lbu	a5,0(s1)
    80004a7c:	ff278de3          	beq	a5,s2,80004a76 <namex+0x10c>
  if(*path == 0)
    80004a80:	c79d                	beqz	a5,80004aae <namex+0x144>
    path++;
    80004a82:	85a6                	mv	a1,s1
  len = path - s;
    80004a84:	8a5e                	mv	s4,s7
    80004a86:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004a88:	01278963          	beq	a5,s2,80004a9a <namex+0x130>
    80004a8c:	dfbd                	beqz	a5,80004a0a <namex+0xa0>
    path++;
    80004a8e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004a90:	0004c783          	lbu	a5,0(s1)
    80004a94:	ff279ce3          	bne	a5,s2,80004a8c <namex+0x122>
    80004a98:	bf8d                	j	80004a0a <namex+0xa0>
    memmove(name, s, len);
    80004a9a:	2601                	sext.w	a2,a2
    80004a9c:	8556                	mv	a0,s5
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	2a2080e7          	jalr	674(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004aa6:	9a56                	add	s4,s4,s5
    80004aa8:	000a0023          	sb	zero,0(s4)
    80004aac:	bf9d                	j	80004a22 <namex+0xb8>
  if(nameiparent){
    80004aae:	f20b03e3          	beqz	s6,800049d4 <namex+0x6a>
    iput(ip);
    80004ab2:	854e                	mv	a0,s3
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	adc080e7          	jalr	-1316(ra) # 80004590 <iput>
    return 0;
    80004abc:	4981                	li	s3,0
    80004abe:	bf19                	j	800049d4 <namex+0x6a>
  if(*path == 0)
    80004ac0:	d7fd                	beqz	a5,80004aae <namex+0x144>
  while(*path != '/' && *path != 0)
    80004ac2:	0004c783          	lbu	a5,0(s1)
    80004ac6:	85a6                	mv	a1,s1
    80004ac8:	b7d1                	j	80004a8c <namex+0x122>

0000000080004aca <dirlink>:
{
    80004aca:	7139                	addi	sp,sp,-64
    80004acc:	fc06                	sd	ra,56(sp)
    80004ace:	f822                	sd	s0,48(sp)
    80004ad0:	f426                	sd	s1,40(sp)
    80004ad2:	f04a                	sd	s2,32(sp)
    80004ad4:	ec4e                	sd	s3,24(sp)
    80004ad6:	e852                	sd	s4,16(sp)
    80004ad8:	0080                	addi	s0,sp,64
    80004ada:	892a                	mv	s2,a0
    80004adc:	8a2e                	mv	s4,a1
    80004ade:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ae0:	4601                	li	a2,0
    80004ae2:	00000097          	auipc	ra,0x0
    80004ae6:	dd8080e7          	jalr	-552(ra) # 800048ba <dirlookup>
    80004aea:	e93d                	bnez	a0,80004b60 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004aec:	04c92483          	lw	s1,76(s2)
    80004af0:	c49d                	beqz	s1,80004b1e <dirlink+0x54>
    80004af2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004af4:	4741                	li	a4,16
    80004af6:	86a6                	mv	a3,s1
    80004af8:	fc040613          	addi	a2,s0,-64
    80004afc:	4581                	li	a1,0
    80004afe:	854a                	mv	a0,s2
    80004b00:	00000097          	auipc	ra,0x0
    80004b04:	b8a080e7          	jalr	-1142(ra) # 8000468a <readi>
    80004b08:	47c1                	li	a5,16
    80004b0a:	06f51163          	bne	a0,a5,80004b6c <dirlink+0xa2>
    if(de.inum == 0)
    80004b0e:	fc045783          	lhu	a5,-64(s0)
    80004b12:	c791                	beqz	a5,80004b1e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b14:	24c1                	addiw	s1,s1,16
    80004b16:	04c92783          	lw	a5,76(s2)
    80004b1a:	fcf4ede3          	bltu	s1,a5,80004af4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004b1e:	4639                	li	a2,14
    80004b20:	85d2                	mv	a1,s4
    80004b22:	fc240513          	addi	a0,s0,-62
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	2ce080e7          	jalr	718(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004b2e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b32:	4741                	li	a4,16
    80004b34:	86a6                	mv	a3,s1
    80004b36:	fc040613          	addi	a2,s0,-64
    80004b3a:	4581                	li	a1,0
    80004b3c:	854a                	mv	a0,s2
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	c44080e7          	jalr	-956(ra) # 80004782 <writei>
    80004b46:	872a                	mv	a4,a0
    80004b48:	47c1                	li	a5,16
  return 0;
    80004b4a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b4c:	02f71863          	bne	a4,a5,80004b7c <dirlink+0xb2>
}
    80004b50:	70e2                	ld	ra,56(sp)
    80004b52:	7442                	ld	s0,48(sp)
    80004b54:	74a2                	ld	s1,40(sp)
    80004b56:	7902                	ld	s2,32(sp)
    80004b58:	69e2                	ld	s3,24(sp)
    80004b5a:	6a42                	ld	s4,16(sp)
    80004b5c:	6121                	addi	sp,sp,64
    80004b5e:	8082                	ret
    iput(ip);
    80004b60:	00000097          	auipc	ra,0x0
    80004b64:	a30080e7          	jalr	-1488(ra) # 80004590 <iput>
    return -1;
    80004b68:	557d                	li	a0,-1
    80004b6a:	b7dd                	j	80004b50 <dirlink+0x86>
      panic("dirlink read");
    80004b6c:	00004517          	auipc	a0,0x4
    80004b70:	c4c50513          	addi	a0,a0,-948 # 800087b8 <syscalls+0x1e0>
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	9ca080e7          	jalr	-1590(ra) # 8000053e <panic>
    panic("dirlink");
    80004b7c:	00004517          	auipc	a0,0x4
    80004b80:	d4450513          	addi	a0,a0,-700 # 800088c0 <syscalls+0x2e8>
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	9ba080e7          	jalr	-1606(ra) # 8000053e <panic>

0000000080004b8c <namei>:

struct inode*
namei(char *path)
{
    80004b8c:	1101                	addi	sp,sp,-32
    80004b8e:	ec06                	sd	ra,24(sp)
    80004b90:	e822                	sd	s0,16(sp)
    80004b92:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004b94:	fe040613          	addi	a2,s0,-32
    80004b98:	4581                	li	a1,0
    80004b9a:	00000097          	auipc	ra,0x0
    80004b9e:	dd0080e7          	jalr	-560(ra) # 8000496a <namex>
}
    80004ba2:	60e2                	ld	ra,24(sp)
    80004ba4:	6442                	ld	s0,16(sp)
    80004ba6:	6105                	addi	sp,sp,32
    80004ba8:	8082                	ret

0000000080004baa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004baa:	1141                	addi	sp,sp,-16
    80004bac:	e406                	sd	ra,8(sp)
    80004bae:	e022                	sd	s0,0(sp)
    80004bb0:	0800                	addi	s0,sp,16
    80004bb2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004bb4:	4585                	li	a1,1
    80004bb6:	00000097          	auipc	ra,0x0
    80004bba:	db4080e7          	jalr	-588(ra) # 8000496a <namex>
}
    80004bbe:	60a2                	ld	ra,8(sp)
    80004bc0:	6402                	ld	s0,0(sp)
    80004bc2:	0141                	addi	sp,sp,16
    80004bc4:	8082                	ret

0000000080004bc6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004bc6:	1101                	addi	sp,sp,-32
    80004bc8:	ec06                	sd	ra,24(sp)
    80004bca:	e822                	sd	s0,16(sp)
    80004bcc:	e426                	sd	s1,8(sp)
    80004bce:	e04a                	sd	s2,0(sp)
    80004bd0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004bd2:	0001e917          	auipc	s2,0x1e
    80004bd6:	4ee90913          	addi	s2,s2,1262 # 800230c0 <log>
    80004bda:	01892583          	lw	a1,24(s2)
    80004bde:	02892503          	lw	a0,40(s2)
    80004be2:	fffff097          	auipc	ra,0xfffff
    80004be6:	ff2080e7          	jalr	-14(ra) # 80003bd4 <bread>
    80004bea:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004bec:	02c92683          	lw	a3,44(s2)
    80004bf0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004bf2:	02d05763          	blez	a3,80004c20 <write_head+0x5a>
    80004bf6:	0001e797          	auipc	a5,0x1e
    80004bfa:	4fa78793          	addi	a5,a5,1274 # 800230f0 <log+0x30>
    80004bfe:	05c50713          	addi	a4,a0,92
    80004c02:	36fd                	addiw	a3,a3,-1
    80004c04:	1682                	slli	a3,a3,0x20
    80004c06:	9281                	srli	a3,a3,0x20
    80004c08:	068a                	slli	a3,a3,0x2
    80004c0a:	0001e617          	auipc	a2,0x1e
    80004c0e:	4ea60613          	addi	a2,a2,1258 # 800230f4 <log+0x34>
    80004c12:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004c14:	4390                	lw	a2,0(a5)
    80004c16:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004c18:	0791                	addi	a5,a5,4
    80004c1a:	0711                	addi	a4,a4,4
    80004c1c:	fed79ce3          	bne	a5,a3,80004c14 <write_head+0x4e>
  }
  bwrite(buf);
    80004c20:	8526                	mv	a0,s1
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	0a4080e7          	jalr	164(ra) # 80003cc6 <bwrite>
  brelse(buf);
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	fffff097          	auipc	ra,0xfffff
    80004c30:	0d8080e7          	jalr	216(ra) # 80003d04 <brelse>
}
    80004c34:	60e2                	ld	ra,24(sp)
    80004c36:	6442                	ld	s0,16(sp)
    80004c38:	64a2                	ld	s1,8(sp)
    80004c3a:	6902                	ld	s2,0(sp)
    80004c3c:	6105                	addi	sp,sp,32
    80004c3e:	8082                	ret

0000000080004c40 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c40:	0001e797          	auipc	a5,0x1e
    80004c44:	4ac7a783          	lw	a5,1196(a5) # 800230ec <log+0x2c>
    80004c48:	0af05d63          	blez	a5,80004d02 <install_trans+0xc2>
{
    80004c4c:	7139                	addi	sp,sp,-64
    80004c4e:	fc06                	sd	ra,56(sp)
    80004c50:	f822                	sd	s0,48(sp)
    80004c52:	f426                	sd	s1,40(sp)
    80004c54:	f04a                	sd	s2,32(sp)
    80004c56:	ec4e                	sd	s3,24(sp)
    80004c58:	e852                	sd	s4,16(sp)
    80004c5a:	e456                	sd	s5,8(sp)
    80004c5c:	e05a                	sd	s6,0(sp)
    80004c5e:	0080                	addi	s0,sp,64
    80004c60:	8b2a                	mv	s6,a0
    80004c62:	0001ea97          	auipc	s5,0x1e
    80004c66:	48ea8a93          	addi	s5,s5,1166 # 800230f0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c6a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c6c:	0001e997          	auipc	s3,0x1e
    80004c70:	45498993          	addi	s3,s3,1108 # 800230c0 <log>
    80004c74:	a035                	j	80004ca0 <install_trans+0x60>
      bunpin(dbuf);
    80004c76:	8526                	mv	a0,s1
    80004c78:	fffff097          	auipc	ra,0xfffff
    80004c7c:	166080e7          	jalr	358(ra) # 80003dde <bunpin>
    brelse(lbuf);
    80004c80:	854a                	mv	a0,s2
    80004c82:	fffff097          	auipc	ra,0xfffff
    80004c86:	082080e7          	jalr	130(ra) # 80003d04 <brelse>
    brelse(dbuf);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	fffff097          	auipc	ra,0xfffff
    80004c90:	078080e7          	jalr	120(ra) # 80003d04 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c94:	2a05                	addiw	s4,s4,1
    80004c96:	0a91                	addi	s5,s5,4
    80004c98:	02c9a783          	lw	a5,44(s3)
    80004c9c:	04fa5963          	bge	s4,a5,80004cee <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004ca0:	0189a583          	lw	a1,24(s3)
    80004ca4:	014585bb          	addw	a1,a1,s4
    80004ca8:	2585                	addiw	a1,a1,1
    80004caa:	0289a503          	lw	a0,40(s3)
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	f26080e7          	jalr	-218(ra) # 80003bd4 <bread>
    80004cb6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004cb8:	000aa583          	lw	a1,0(s5)
    80004cbc:	0289a503          	lw	a0,40(s3)
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	f14080e7          	jalr	-236(ra) # 80003bd4 <bread>
    80004cc8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004cca:	40000613          	li	a2,1024
    80004cce:	05890593          	addi	a1,s2,88
    80004cd2:	05850513          	addi	a0,a0,88
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	06a080e7          	jalr	106(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004cde:	8526                	mv	a0,s1
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	fe6080e7          	jalr	-26(ra) # 80003cc6 <bwrite>
    if(recovering == 0)
    80004ce8:	f80b1ce3          	bnez	s6,80004c80 <install_trans+0x40>
    80004cec:	b769                	j	80004c76 <install_trans+0x36>
}
    80004cee:	70e2                	ld	ra,56(sp)
    80004cf0:	7442                	ld	s0,48(sp)
    80004cf2:	74a2                	ld	s1,40(sp)
    80004cf4:	7902                	ld	s2,32(sp)
    80004cf6:	69e2                	ld	s3,24(sp)
    80004cf8:	6a42                	ld	s4,16(sp)
    80004cfa:	6aa2                	ld	s5,8(sp)
    80004cfc:	6b02                	ld	s6,0(sp)
    80004cfe:	6121                	addi	sp,sp,64
    80004d00:	8082                	ret
    80004d02:	8082                	ret

0000000080004d04 <initlog>:
{
    80004d04:	7179                	addi	sp,sp,-48
    80004d06:	f406                	sd	ra,40(sp)
    80004d08:	f022                	sd	s0,32(sp)
    80004d0a:	ec26                	sd	s1,24(sp)
    80004d0c:	e84a                	sd	s2,16(sp)
    80004d0e:	e44e                	sd	s3,8(sp)
    80004d10:	1800                	addi	s0,sp,48
    80004d12:	892a                	mv	s2,a0
    80004d14:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004d16:	0001e497          	auipc	s1,0x1e
    80004d1a:	3aa48493          	addi	s1,s1,938 # 800230c0 <log>
    80004d1e:	00004597          	auipc	a1,0x4
    80004d22:	aaa58593          	addi	a1,a1,-1366 # 800087c8 <syscalls+0x1f0>
    80004d26:	8526                	mv	a0,s1
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	e2c080e7          	jalr	-468(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004d30:	0149a583          	lw	a1,20(s3)
    80004d34:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004d36:	0109a783          	lw	a5,16(s3)
    80004d3a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004d3c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004d40:	854a                	mv	a0,s2
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	e92080e7          	jalr	-366(ra) # 80003bd4 <bread>
  log.lh.n = lh->n;
    80004d4a:	4d3c                	lw	a5,88(a0)
    80004d4c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004d4e:	02f05563          	blez	a5,80004d78 <initlog+0x74>
    80004d52:	05c50713          	addi	a4,a0,92
    80004d56:	0001e697          	auipc	a3,0x1e
    80004d5a:	39a68693          	addi	a3,a3,922 # 800230f0 <log+0x30>
    80004d5e:	37fd                	addiw	a5,a5,-1
    80004d60:	1782                	slli	a5,a5,0x20
    80004d62:	9381                	srli	a5,a5,0x20
    80004d64:	078a                	slli	a5,a5,0x2
    80004d66:	06050613          	addi	a2,a0,96
    80004d6a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004d6c:	4310                	lw	a2,0(a4)
    80004d6e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004d70:	0711                	addi	a4,a4,4
    80004d72:	0691                	addi	a3,a3,4
    80004d74:	fef71ce3          	bne	a4,a5,80004d6c <initlog+0x68>
  brelse(buf);
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	f8c080e7          	jalr	-116(ra) # 80003d04 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004d80:	4505                	li	a0,1
    80004d82:	00000097          	auipc	ra,0x0
    80004d86:	ebe080e7          	jalr	-322(ra) # 80004c40 <install_trans>
  log.lh.n = 0;
    80004d8a:	0001e797          	auipc	a5,0x1e
    80004d8e:	3607a123          	sw	zero,866(a5) # 800230ec <log+0x2c>
  write_head(); // clear the log
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	e34080e7          	jalr	-460(ra) # 80004bc6 <write_head>
}
    80004d9a:	70a2                	ld	ra,40(sp)
    80004d9c:	7402                	ld	s0,32(sp)
    80004d9e:	64e2                	ld	s1,24(sp)
    80004da0:	6942                	ld	s2,16(sp)
    80004da2:	69a2                	ld	s3,8(sp)
    80004da4:	6145                	addi	sp,sp,48
    80004da6:	8082                	ret

0000000080004da8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004da8:	1101                	addi	sp,sp,-32
    80004daa:	ec06                	sd	ra,24(sp)
    80004dac:	e822                	sd	s0,16(sp)
    80004dae:	e426                	sd	s1,8(sp)
    80004db0:	e04a                	sd	s2,0(sp)
    80004db2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004db4:	0001e517          	auipc	a0,0x1e
    80004db8:	30c50513          	addi	a0,a0,780 # 800230c0 <log>
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	e28080e7          	jalr	-472(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004dc4:	0001e497          	auipc	s1,0x1e
    80004dc8:	2fc48493          	addi	s1,s1,764 # 800230c0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004dcc:	4979                	li	s2,30
    80004dce:	a039                	j	80004ddc <begin_op+0x34>
      sleep(&log, &log.lock);
    80004dd0:	85a6                	mv	a1,s1
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	ffffe097          	auipc	ra,0xffffe
    80004dd8:	92e080e7          	jalr	-1746(ra) # 80002702 <sleep>
    if(log.committing){
    80004ddc:	50dc                	lw	a5,36(s1)
    80004dde:	fbed                	bnez	a5,80004dd0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004de0:	509c                	lw	a5,32(s1)
    80004de2:	0017871b          	addiw	a4,a5,1
    80004de6:	0007069b          	sext.w	a3,a4
    80004dea:	0027179b          	slliw	a5,a4,0x2
    80004dee:	9fb9                	addw	a5,a5,a4
    80004df0:	0017979b          	slliw	a5,a5,0x1
    80004df4:	54d8                	lw	a4,44(s1)
    80004df6:	9fb9                	addw	a5,a5,a4
    80004df8:	00f95963          	bge	s2,a5,80004e0a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004dfc:	85a6                	mv	a1,s1
    80004dfe:	8526                	mv	a0,s1
    80004e00:	ffffe097          	auipc	ra,0xffffe
    80004e04:	902080e7          	jalr	-1790(ra) # 80002702 <sleep>
    80004e08:	bfd1                	j	80004ddc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004e0a:	0001e517          	auipc	a0,0x1e
    80004e0e:	2b650513          	addi	a0,a0,694 # 800230c0 <log>
    80004e12:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	e84080e7          	jalr	-380(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004e1c:	60e2                	ld	ra,24(sp)
    80004e1e:	6442                	ld	s0,16(sp)
    80004e20:	64a2                	ld	s1,8(sp)
    80004e22:	6902                	ld	s2,0(sp)
    80004e24:	6105                	addi	sp,sp,32
    80004e26:	8082                	ret

0000000080004e28 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004e28:	7139                	addi	sp,sp,-64
    80004e2a:	fc06                	sd	ra,56(sp)
    80004e2c:	f822                	sd	s0,48(sp)
    80004e2e:	f426                	sd	s1,40(sp)
    80004e30:	f04a                	sd	s2,32(sp)
    80004e32:	ec4e                	sd	s3,24(sp)
    80004e34:	e852                	sd	s4,16(sp)
    80004e36:	e456                	sd	s5,8(sp)
    80004e38:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004e3a:	0001e497          	auipc	s1,0x1e
    80004e3e:	28648493          	addi	s1,s1,646 # 800230c0 <log>
    80004e42:	8526                	mv	a0,s1
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	da0080e7          	jalr	-608(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004e4c:	509c                	lw	a5,32(s1)
    80004e4e:	37fd                	addiw	a5,a5,-1
    80004e50:	0007891b          	sext.w	s2,a5
    80004e54:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004e56:	50dc                	lw	a5,36(s1)
    80004e58:	efb9                	bnez	a5,80004eb6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004e5a:	06091663          	bnez	s2,80004ec6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004e5e:	0001e497          	auipc	s1,0x1e
    80004e62:	26248493          	addi	s1,s1,610 # 800230c0 <log>
    80004e66:	4785                	li	a5,1
    80004e68:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	e2c080e7          	jalr	-468(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004e74:	54dc                	lw	a5,44(s1)
    80004e76:	06f04763          	bgtz	a5,80004ee4 <end_op+0xbc>
    acquire(&log.lock);
    80004e7a:	0001e497          	auipc	s1,0x1e
    80004e7e:	24648493          	addi	s1,s1,582 # 800230c0 <log>
    80004e82:	8526                	mv	a0,s1
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	d60080e7          	jalr	-672(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004e8c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004e90:	8526                	mv	a0,s1
    80004e92:	ffffe097          	auipc	ra,0xffffe
    80004e96:	9fc080e7          	jalr	-1540(ra) # 8000288e <wakeup>
    release(&log.lock);
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
}
    80004ea4:	70e2                	ld	ra,56(sp)
    80004ea6:	7442                	ld	s0,48(sp)
    80004ea8:	74a2                	ld	s1,40(sp)
    80004eaa:	7902                	ld	s2,32(sp)
    80004eac:	69e2                	ld	s3,24(sp)
    80004eae:	6a42                	ld	s4,16(sp)
    80004eb0:	6aa2                	ld	s5,8(sp)
    80004eb2:	6121                	addi	sp,sp,64
    80004eb4:	8082                	ret
    panic("log.committing");
    80004eb6:	00004517          	auipc	a0,0x4
    80004eba:	91a50513          	addi	a0,a0,-1766 # 800087d0 <syscalls+0x1f8>
    80004ebe:	ffffb097          	auipc	ra,0xffffb
    80004ec2:	680080e7          	jalr	1664(ra) # 8000053e <panic>
    wakeup(&log);
    80004ec6:	0001e497          	auipc	s1,0x1e
    80004eca:	1fa48493          	addi	s1,s1,506 # 800230c0 <log>
    80004ece:	8526                	mv	a0,s1
    80004ed0:	ffffe097          	auipc	ra,0xffffe
    80004ed4:	9be080e7          	jalr	-1602(ra) # 8000288e <wakeup>
  release(&log.lock);
    80004ed8:	8526                	mv	a0,s1
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	dbe080e7          	jalr	-578(ra) # 80000c98 <release>
  if(do_commit){
    80004ee2:	b7c9                	j	80004ea4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ee4:	0001ea97          	auipc	s5,0x1e
    80004ee8:	20ca8a93          	addi	s5,s5,524 # 800230f0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004eec:	0001ea17          	auipc	s4,0x1e
    80004ef0:	1d4a0a13          	addi	s4,s4,468 # 800230c0 <log>
    80004ef4:	018a2583          	lw	a1,24(s4)
    80004ef8:	012585bb          	addw	a1,a1,s2
    80004efc:	2585                	addiw	a1,a1,1
    80004efe:	028a2503          	lw	a0,40(s4)
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	cd2080e7          	jalr	-814(ra) # 80003bd4 <bread>
    80004f0a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004f0c:	000aa583          	lw	a1,0(s5)
    80004f10:	028a2503          	lw	a0,40(s4)
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	cc0080e7          	jalr	-832(ra) # 80003bd4 <bread>
    80004f1c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004f1e:	40000613          	li	a2,1024
    80004f22:	05850593          	addi	a1,a0,88
    80004f26:	05848513          	addi	a0,s1,88
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	e16080e7          	jalr	-490(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004f32:	8526                	mv	a0,s1
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	d92080e7          	jalr	-622(ra) # 80003cc6 <bwrite>
    brelse(from);
    80004f3c:	854e                	mv	a0,s3
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	dc6080e7          	jalr	-570(ra) # 80003d04 <brelse>
    brelse(to);
    80004f46:	8526                	mv	a0,s1
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	dbc080e7          	jalr	-580(ra) # 80003d04 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004f50:	2905                	addiw	s2,s2,1
    80004f52:	0a91                	addi	s5,s5,4
    80004f54:	02ca2783          	lw	a5,44(s4)
    80004f58:	f8f94ee3          	blt	s2,a5,80004ef4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004f5c:	00000097          	auipc	ra,0x0
    80004f60:	c6a080e7          	jalr	-918(ra) # 80004bc6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004f64:	4501                	li	a0,0
    80004f66:	00000097          	auipc	ra,0x0
    80004f6a:	cda080e7          	jalr	-806(ra) # 80004c40 <install_trans>
    log.lh.n = 0;
    80004f6e:	0001e797          	auipc	a5,0x1e
    80004f72:	1607af23          	sw	zero,382(a5) # 800230ec <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004f76:	00000097          	auipc	ra,0x0
    80004f7a:	c50080e7          	jalr	-944(ra) # 80004bc6 <write_head>
    80004f7e:	bdf5                	j	80004e7a <end_op+0x52>

0000000080004f80 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004f80:	1101                	addi	sp,sp,-32
    80004f82:	ec06                	sd	ra,24(sp)
    80004f84:	e822                	sd	s0,16(sp)
    80004f86:	e426                	sd	s1,8(sp)
    80004f88:	e04a                	sd	s2,0(sp)
    80004f8a:	1000                	addi	s0,sp,32
    80004f8c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004f8e:	0001e917          	auipc	s2,0x1e
    80004f92:	13290913          	addi	s2,s2,306 # 800230c0 <log>
    80004f96:	854a                	mv	a0,s2
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	c4c080e7          	jalr	-948(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004fa0:	02c92603          	lw	a2,44(s2)
    80004fa4:	47f5                	li	a5,29
    80004fa6:	06c7c563          	blt	a5,a2,80005010 <log_write+0x90>
    80004faa:	0001e797          	auipc	a5,0x1e
    80004fae:	1327a783          	lw	a5,306(a5) # 800230dc <log+0x1c>
    80004fb2:	37fd                	addiw	a5,a5,-1
    80004fb4:	04f65e63          	bge	a2,a5,80005010 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004fb8:	0001e797          	auipc	a5,0x1e
    80004fbc:	1287a783          	lw	a5,296(a5) # 800230e0 <log+0x20>
    80004fc0:	06f05063          	blez	a5,80005020 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004fc4:	4781                	li	a5,0
    80004fc6:	06c05563          	blez	a2,80005030 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004fca:	44cc                	lw	a1,12(s1)
    80004fcc:	0001e717          	auipc	a4,0x1e
    80004fd0:	12470713          	addi	a4,a4,292 # 800230f0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004fd4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004fd6:	4314                	lw	a3,0(a4)
    80004fd8:	04b68c63          	beq	a3,a1,80005030 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004fdc:	2785                	addiw	a5,a5,1
    80004fde:	0711                	addi	a4,a4,4
    80004fe0:	fef61be3          	bne	a2,a5,80004fd6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004fe4:	0621                	addi	a2,a2,8
    80004fe6:	060a                	slli	a2,a2,0x2
    80004fe8:	0001e797          	auipc	a5,0x1e
    80004fec:	0d878793          	addi	a5,a5,216 # 800230c0 <log>
    80004ff0:	963e                	add	a2,a2,a5
    80004ff2:	44dc                	lw	a5,12(s1)
    80004ff4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	fffff097          	auipc	ra,0xfffff
    80004ffc:	daa080e7          	jalr	-598(ra) # 80003da2 <bpin>
    log.lh.n++;
    80005000:	0001e717          	auipc	a4,0x1e
    80005004:	0c070713          	addi	a4,a4,192 # 800230c0 <log>
    80005008:	575c                	lw	a5,44(a4)
    8000500a:	2785                	addiw	a5,a5,1
    8000500c:	d75c                	sw	a5,44(a4)
    8000500e:	a835                	j	8000504a <log_write+0xca>
    panic("too big a transaction");
    80005010:	00003517          	auipc	a0,0x3
    80005014:	7d050513          	addi	a0,a0,2000 # 800087e0 <syscalls+0x208>
    80005018:	ffffb097          	auipc	ra,0xffffb
    8000501c:	526080e7          	jalr	1318(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80005020:	00003517          	auipc	a0,0x3
    80005024:	7d850513          	addi	a0,a0,2008 # 800087f8 <syscalls+0x220>
    80005028:	ffffb097          	auipc	ra,0xffffb
    8000502c:	516080e7          	jalr	1302(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80005030:	00878713          	addi	a4,a5,8
    80005034:	00271693          	slli	a3,a4,0x2
    80005038:	0001e717          	auipc	a4,0x1e
    8000503c:	08870713          	addi	a4,a4,136 # 800230c0 <log>
    80005040:	9736                	add	a4,a4,a3
    80005042:	44d4                	lw	a3,12(s1)
    80005044:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005046:	faf608e3          	beq	a2,a5,80004ff6 <log_write+0x76>
  }
  release(&log.lock);
    8000504a:	0001e517          	auipc	a0,0x1e
    8000504e:	07650513          	addi	a0,a0,118 # 800230c0 <log>
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	c46080e7          	jalr	-954(ra) # 80000c98 <release>
}
    8000505a:	60e2                	ld	ra,24(sp)
    8000505c:	6442                	ld	s0,16(sp)
    8000505e:	64a2                	ld	s1,8(sp)
    80005060:	6902                	ld	s2,0(sp)
    80005062:	6105                	addi	sp,sp,32
    80005064:	8082                	ret

0000000080005066 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005066:	1101                	addi	sp,sp,-32
    80005068:	ec06                	sd	ra,24(sp)
    8000506a:	e822                	sd	s0,16(sp)
    8000506c:	e426                	sd	s1,8(sp)
    8000506e:	e04a                	sd	s2,0(sp)
    80005070:	1000                	addi	s0,sp,32
    80005072:	84aa                	mv	s1,a0
    80005074:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005076:	00003597          	auipc	a1,0x3
    8000507a:	7a258593          	addi	a1,a1,1954 # 80008818 <syscalls+0x240>
    8000507e:	0521                	addi	a0,a0,8
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	ad4080e7          	jalr	-1324(ra) # 80000b54 <initlock>
  lk->name = name;
    80005088:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000508c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005090:	0204a423          	sw	zero,40(s1)
}
    80005094:	60e2                	ld	ra,24(sp)
    80005096:	6442                	ld	s0,16(sp)
    80005098:	64a2                	ld	s1,8(sp)
    8000509a:	6902                	ld	s2,0(sp)
    8000509c:	6105                	addi	sp,sp,32
    8000509e:	8082                	ret

00000000800050a0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800050a0:	1101                	addi	sp,sp,-32
    800050a2:	ec06                	sd	ra,24(sp)
    800050a4:	e822                	sd	s0,16(sp)
    800050a6:	e426                	sd	s1,8(sp)
    800050a8:	e04a                	sd	s2,0(sp)
    800050aa:	1000                	addi	s0,sp,32
    800050ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800050ae:	00850913          	addi	s2,a0,8
    800050b2:	854a                	mv	a0,s2
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	b30080e7          	jalr	-1232(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800050bc:	409c                	lw	a5,0(s1)
    800050be:	cb89                	beqz	a5,800050d0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800050c0:	85ca                	mv	a1,s2
    800050c2:	8526                	mv	a0,s1
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	63e080e7          	jalr	1598(ra) # 80002702 <sleep>
  while (lk->locked) {
    800050cc:	409c                	lw	a5,0(s1)
    800050ce:	fbed                	bnez	a5,800050c0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800050d0:	4785                	li	a5,1
    800050d2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	8e4080e7          	jalr	-1820(ra) # 800019b8 <myproc>
    800050dc:	591c                	lw	a5,48(a0)
    800050de:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800050e0:	854a                	mv	a0,s2
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	bb6080e7          	jalr	-1098(ra) # 80000c98 <release>
}
    800050ea:	60e2                	ld	ra,24(sp)
    800050ec:	6442                	ld	s0,16(sp)
    800050ee:	64a2                	ld	s1,8(sp)
    800050f0:	6902                	ld	s2,0(sp)
    800050f2:	6105                	addi	sp,sp,32
    800050f4:	8082                	ret

00000000800050f6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800050f6:	1101                	addi	sp,sp,-32
    800050f8:	ec06                	sd	ra,24(sp)
    800050fa:	e822                	sd	s0,16(sp)
    800050fc:	e426                	sd	s1,8(sp)
    800050fe:	e04a                	sd	s2,0(sp)
    80005100:	1000                	addi	s0,sp,32
    80005102:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005104:	00850913          	addi	s2,a0,8
    80005108:	854a                	mv	a0,s2
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	ada080e7          	jalr	-1318(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80005112:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005116:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000511a:	8526                	mv	a0,s1
    8000511c:	ffffd097          	auipc	ra,0xffffd
    80005120:	772080e7          	jalr	1906(ra) # 8000288e <wakeup>
  release(&lk->lk);
    80005124:	854a                	mv	a0,s2
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	b72080e7          	jalr	-1166(ra) # 80000c98 <release>
}
    8000512e:	60e2                	ld	ra,24(sp)
    80005130:	6442                	ld	s0,16(sp)
    80005132:	64a2                	ld	s1,8(sp)
    80005134:	6902                	ld	s2,0(sp)
    80005136:	6105                	addi	sp,sp,32
    80005138:	8082                	ret

000000008000513a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000513a:	7179                	addi	sp,sp,-48
    8000513c:	f406                	sd	ra,40(sp)
    8000513e:	f022                	sd	s0,32(sp)
    80005140:	ec26                	sd	s1,24(sp)
    80005142:	e84a                	sd	s2,16(sp)
    80005144:	e44e                	sd	s3,8(sp)
    80005146:	1800                	addi	s0,sp,48
    80005148:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000514a:	00850913          	addi	s2,a0,8
    8000514e:	854a                	mv	a0,s2
    80005150:	ffffc097          	auipc	ra,0xffffc
    80005154:	a94080e7          	jalr	-1388(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005158:	409c                	lw	a5,0(s1)
    8000515a:	ef99                	bnez	a5,80005178 <holdingsleep+0x3e>
    8000515c:	4481                	li	s1,0
  release(&lk->lk);
    8000515e:	854a                	mv	a0,s2
    80005160:	ffffc097          	auipc	ra,0xffffc
    80005164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
  return r;
}
    80005168:	8526                	mv	a0,s1
    8000516a:	70a2                	ld	ra,40(sp)
    8000516c:	7402                	ld	s0,32(sp)
    8000516e:	64e2                	ld	s1,24(sp)
    80005170:	6942                	ld	s2,16(sp)
    80005172:	69a2                	ld	s3,8(sp)
    80005174:	6145                	addi	sp,sp,48
    80005176:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005178:	0284a983          	lw	s3,40(s1)
    8000517c:	ffffd097          	auipc	ra,0xffffd
    80005180:	83c080e7          	jalr	-1988(ra) # 800019b8 <myproc>
    80005184:	5904                	lw	s1,48(a0)
    80005186:	413484b3          	sub	s1,s1,s3
    8000518a:	0014b493          	seqz	s1,s1
    8000518e:	bfc1                	j	8000515e <holdingsleep+0x24>

0000000080005190 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005190:	1141                	addi	sp,sp,-16
    80005192:	e406                	sd	ra,8(sp)
    80005194:	e022                	sd	s0,0(sp)
    80005196:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005198:	00003597          	auipc	a1,0x3
    8000519c:	69058593          	addi	a1,a1,1680 # 80008828 <syscalls+0x250>
    800051a0:	0001e517          	auipc	a0,0x1e
    800051a4:	06850513          	addi	a0,a0,104 # 80023208 <ftable>
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	9ac080e7          	jalr	-1620(ra) # 80000b54 <initlock>
}
    800051b0:	60a2                	ld	ra,8(sp)
    800051b2:	6402                	ld	s0,0(sp)
    800051b4:	0141                	addi	sp,sp,16
    800051b6:	8082                	ret

00000000800051b8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800051b8:	1101                	addi	sp,sp,-32
    800051ba:	ec06                	sd	ra,24(sp)
    800051bc:	e822                	sd	s0,16(sp)
    800051be:	e426                	sd	s1,8(sp)
    800051c0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800051c2:	0001e517          	auipc	a0,0x1e
    800051c6:	04650513          	addi	a0,a0,70 # 80023208 <ftable>
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	a1a080e7          	jalr	-1510(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800051d2:	0001e497          	auipc	s1,0x1e
    800051d6:	04e48493          	addi	s1,s1,78 # 80023220 <ftable+0x18>
    800051da:	0001f717          	auipc	a4,0x1f
    800051de:	fe670713          	addi	a4,a4,-26 # 800241c0 <ftable+0xfb8>
    if(f->ref == 0){
    800051e2:	40dc                	lw	a5,4(s1)
    800051e4:	cf99                	beqz	a5,80005202 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800051e6:	02848493          	addi	s1,s1,40
    800051ea:	fee49ce3          	bne	s1,a4,800051e2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800051ee:	0001e517          	auipc	a0,0x1e
    800051f2:	01a50513          	addi	a0,a0,26 # 80023208 <ftable>
    800051f6:	ffffc097          	auipc	ra,0xffffc
    800051fa:	aa2080e7          	jalr	-1374(ra) # 80000c98 <release>
  return 0;
    800051fe:	4481                	li	s1,0
    80005200:	a819                	j	80005216 <filealloc+0x5e>
      f->ref = 1;
    80005202:	4785                	li	a5,1
    80005204:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005206:	0001e517          	auipc	a0,0x1e
    8000520a:	00250513          	addi	a0,a0,2 # 80023208 <ftable>
    8000520e:	ffffc097          	auipc	ra,0xffffc
    80005212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
}
    80005216:	8526                	mv	a0,s1
    80005218:	60e2                	ld	ra,24(sp)
    8000521a:	6442                	ld	s0,16(sp)
    8000521c:	64a2                	ld	s1,8(sp)
    8000521e:	6105                	addi	sp,sp,32
    80005220:	8082                	ret

0000000080005222 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005222:	1101                	addi	sp,sp,-32
    80005224:	ec06                	sd	ra,24(sp)
    80005226:	e822                	sd	s0,16(sp)
    80005228:	e426                	sd	s1,8(sp)
    8000522a:	1000                	addi	s0,sp,32
    8000522c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000522e:	0001e517          	auipc	a0,0x1e
    80005232:	fda50513          	addi	a0,a0,-38 # 80023208 <ftable>
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	9ae080e7          	jalr	-1618(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000523e:	40dc                	lw	a5,4(s1)
    80005240:	02f05263          	blez	a5,80005264 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005244:	2785                	addiw	a5,a5,1
    80005246:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005248:	0001e517          	auipc	a0,0x1e
    8000524c:	fc050513          	addi	a0,a0,-64 # 80023208 <ftable>
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	a48080e7          	jalr	-1464(ra) # 80000c98 <release>
  return f;
}
    80005258:	8526                	mv	a0,s1
    8000525a:	60e2                	ld	ra,24(sp)
    8000525c:	6442                	ld	s0,16(sp)
    8000525e:	64a2                	ld	s1,8(sp)
    80005260:	6105                	addi	sp,sp,32
    80005262:	8082                	ret
    panic("filedup");
    80005264:	00003517          	auipc	a0,0x3
    80005268:	5cc50513          	addi	a0,a0,1484 # 80008830 <syscalls+0x258>
    8000526c:	ffffb097          	auipc	ra,0xffffb
    80005270:	2d2080e7          	jalr	722(ra) # 8000053e <panic>

0000000080005274 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005274:	7139                	addi	sp,sp,-64
    80005276:	fc06                	sd	ra,56(sp)
    80005278:	f822                	sd	s0,48(sp)
    8000527a:	f426                	sd	s1,40(sp)
    8000527c:	f04a                	sd	s2,32(sp)
    8000527e:	ec4e                	sd	s3,24(sp)
    80005280:	e852                	sd	s4,16(sp)
    80005282:	e456                	sd	s5,8(sp)
    80005284:	0080                	addi	s0,sp,64
    80005286:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005288:	0001e517          	auipc	a0,0x1e
    8000528c:	f8050513          	addi	a0,a0,-128 # 80023208 <ftable>
    80005290:	ffffc097          	auipc	ra,0xffffc
    80005294:	954080e7          	jalr	-1708(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005298:	40dc                	lw	a5,4(s1)
    8000529a:	06f05163          	blez	a5,800052fc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000529e:	37fd                	addiw	a5,a5,-1
    800052a0:	0007871b          	sext.w	a4,a5
    800052a4:	c0dc                	sw	a5,4(s1)
    800052a6:	06e04363          	bgtz	a4,8000530c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800052aa:	0004a903          	lw	s2,0(s1)
    800052ae:	0094ca83          	lbu	s5,9(s1)
    800052b2:	0104ba03          	ld	s4,16(s1)
    800052b6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800052ba:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800052be:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800052c2:	0001e517          	auipc	a0,0x1e
    800052c6:	f4650513          	addi	a0,a0,-186 # 80023208 <ftable>
    800052ca:	ffffc097          	auipc	ra,0xffffc
    800052ce:	9ce080e7          	jalr	-1586(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800052d2:	4785                	li	a5,1
    800052d4:	04f90d63          	beq	s2,a5,8000532e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800052d8:	3979                	addiw	s2,s2,-2
    800052da:	4785                	li	a5,1
    800052dc:	0527e063          	bltu	a5,s2,8000531c <fileclose+0xa8>
    begin_op();
    800052e0:	00000097          	auipc	ra,0x0
    800052e4:	ac8080e7          	jalr	-1336(ra) # 80004da8 <begin_op>
    iput(ff.ip);
    800052e8:	854e                	mv	a0,s3
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	2a6080e7          	jalr	678(ra) # 80004590 <iput>
    end_op();
    800052f2:	00000097          	auipc	ra,0x0
    800052f6:	b36080e7          	jalr	-1226(ra) # 80004e28 <end_op>
    800052fa:	a00d                	j	8000531c <fileclose+0xa8>
    panic("fileclose");
    800052fc:	00003517          	auipc	a0,0x3
    80005300:	53c50513          	addi	a0,a0,1340 # 80008838 <syscalls+0x260>
    80005304:	ffffb097          	auipc	ra,0xffffb
    80005308:	23a080e7          	jalr	570(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000530c:	0001e517          	auipc	a0,0x1e
    80005310:	efc50513          	addi	a0,a0,-260 # 80023208 <ftable>
    80005314:	ffffc097          	auipc	ra,0xffffc
    80005318:	984080e7          	jalr	-1660(ra) # 80000c98 <release>
  }
}
    8000531c:	70e2                	ld	ra,56(sp)
    8000531e:	7442                	ld	s0,48(sp)
    80005320:	74a2                	ld	s1,40(sp)
    80005322:	7902                	ld	s2,32(sp)
    80005324:	69e2                	ld	s3,24(sp)
    80005326:	6a42                	ld	s4,16(sp)
    80005328:	6aa2                	ld	s5,8(sp)
    8000532a:	6121                	addi	sp,sp,64
    8000532c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000532e:	85d6                	mv	a1,s5
    80005330:	8552                	mv	a0,s4
    80005332:	00000097          	auipc	ra,0x0
    80005336:	34c080e7          	jalr	844(ra) # 8000567e <pipeclose>
    8000533a:	b7cd                	j	8000531c <fileclose+0xa8>

000000008000533c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000533c:	715d                	addi	sp,sp,-80
    8000533e:	e486                	sd	ra,72(sp)
    80005340:	e0a2                	sd	s0,64(sp)
    80005342:	fc26                	sd	s1,56(sp)
    80005344:	f84a                	sd	s2,48(sp)
    80005346:	f44e                	sd	s3,40(sp)
    80005348:	0880                	addi	s0,sp,80
    8000534a:	84aa                	mv	s1,a0
    8000534c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000534e:	ffffc097          	auipc	ra,0xffffc
    80005352:	66a080e7          	jalr	1642(ra) # 800019b8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005356:	409c                	lw	a5,0(s1)
    80005358:	37f9                	addiw	a5,a5,-2
    8000535a:	4705                	li	a4,1
    8000535c:	04f76763          	bltu	a4,a5,800053aa <filestat+0x6e>
    80005360:	892a                	mv	s2,a0
    ilock(f->ip);
    80005362:	6c88                	ld	a0,24(s1)
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	072080e7          	jalr	114(ra) # 800043d6 <ilock>
    stati(f->ip, &st);
    8000536c:	fb840593          	addi	a1,s0,-72
    80005370:	6c88                	ld	a0,24(s1)
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	2ee080e7          	jalr	750(ra) # 80004660 <stati>
    iunlock(f->ip);
    8000537a:	6c88                	ld	a0,24(s1)
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	11c080e7          	jalr	284(ra) # 80004498 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005384:	46e1                	li	a3,24
    80005386:	fb840613          	addi	a2,s0,-72
    8000538a:	85ce                	mv	a1,s3
    8000538c:	07093503          	ld	a0,112(s2)
    80005390:	ffffc097          	auipc	ra,0xffffc
    80005394:	2ea080e7          	jalr	746(ra) # 8000167a <copyout>
    80005398:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000539c:	60a6                	ld	ra,72(sp)
    8000539e:	6406                	ld	s0,64(sp)
    800053a0:	74e2                	ld	s1,56(sp)
    800053a2:	7942                	ld	s2,48(sp)
    800053a4:	79a2                	ld	s3,40(sp)
    800053a6:	6161                	addi	sp,sp,80
    800053a8:	8082                	ret
  return -1;
    800053aa:	557d                	li	a0,-1
    800053ac:	bfc5                	j	8000539c <filestat+0x60>

00000000800053ae <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800053ae:	7179                	addi	sp,sp,-48
    800053b0:	f406                	sd	ra,40(sp)
    800053b2:	f022                	sd	s0,32(sp)
    800053b4:	ec26                	sd	s1,24(sp)
    800053b6:	e84a                	sd	s2,16(sp)
    800053b8:	e44e                	sd	s3,8(sp)
    800053ba:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800053bc:	00854783          	lbu	a5,8(a0)
    800053c0:	c3d5                	beqz	a5,80005464 <fileread+0xb6>
    800053c2:	84aa                	mv	s1,a0
    800053c4:	89ae                	mv	s3,a1
    800053c6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800053c8:	411c                	lw	a5,0(a0)
    800053ca:	4705                	li	a4,1
    800053cc:	04e78963          	beq	a5,a4,8000541e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053d0:	470d                	li	a4,3
    800053d2:	04e78d63          	beq	a5,a4,8000542c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800053d6:	4709                	li	a4,2
    800053d8:	06e79e63          	bne	a5,a4,80005454 <fileread+0xa6>
    ilock(f->ip);
    800053dc:	6d08                	ld	a0,24(a0)
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	ff8080e7          	jalr	-8(ra) # 800043d6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800053e6:	874a                	mv	a4,s2
    800053e8:	5094                	lw	a3,32(s1)
    800053ea:	864e                	mv	a2,s3
    800053ec:	4585                	li	a1,1
    800053ee:	6c88                	ld	a0,24(s1)
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	29a080e7          	jalr	666(ra) # 8000468a <readi>
    800053f8:	892a                	mv	s2,a0
    800053fa:	00a05563          	blez	a0,80005404 <fileread+0x56>
      f->off += r;
    800053fe:	509c                	lw	a5,32(s1)
    80005400:	9fa9                	addw	a5,a5,a0
    80005402:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005404:	6c88                	ld	a0,24(s1)
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	092080e7          	jalr	146(ra) # 80004498 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000540e:	854a                	mv	a0,s2
    80005410:	70a2                	ld	ra,40(sp)
    80005412:	7402                	ld	s0,32(sp)
    80005414:	64e2                	ld	s1,24(sp)
    80005416:	6942                	ld	s2,16(sp)
    80005418:	69a2                	ld	s3,8(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000541e:	6908                	ld	a0,16(a0)
    80005420:	00000097          	auipc	ra,0x0
    80005424:	3c8080e7          	jalr	968(ra) # 800057e8 <piperead>
    80005428:	892a                	mv	s2,a0
    8000542a:	b7d5                	j	8000540e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000542c:	02451783          	lh	a5,36(a0)
    80005430:	03079693          	slli	a3,a5,0x30
    80005434:	92c1                	srli	a3,a3,0x30
    80005436:	4725                	li	a4,9
    80005438:	02d76863          	bltu	a4,a3,80005468 <fileread+0xba>
    8000543c:	0792                	slli	a5,a5,0x4
    8000543e:	0001e717          	auipc	a4,0x1e
    80005442:	d2a70713          	addi	a4,a4,-726 # 80023168 <devsw>
    80005446:	97ba                	add	a5,a5,a4
    80005448:	639c                	ld	a5,0(a5)
    8000544a:	c38d                	beqz	a5,8000546c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000544c:	4505                	li	a0,1
    8000544e:	9782                	jalr	a5
    80005450:	892a                	mv	s2,a0
    80005452:	bf75                	j	8000540e <fileread+0x60>
    panic("fileread");
    80005454:	00003517          	auipc	a0,0x3
    80005458:	3f450513          	addi	a0,a0,1012 # 80008848 <syscalls+0x270>
    8000545c:	ffffb097          	auipc	ra,0xffffb
    80005460:	0e2080e7          	jalr	226(ra) # 8000053e <panic>
    return -1;
    80005464:	597d                	li	s2,-1
    80005466:	b765                	j	8000540e <fileread+0x60>
      return -1;
    80005468:	597d                	li	s2,-1
    8000546a:	b755                	j	8000540e <fileread+0x60>
    8000546c:	597d                	li	s2,-1
    8000546e:	b745                	j	8000540e <fileread+0x60>

0000000080005470 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005470:	715d                	addi	sp,sp,-80
    80005472:	e486                	sd	ra,72(sp)
    80005474:	e0a2                	sd	s0,64(sp)
    80005476:	fc26                	sd	s1,56(sp)
    80005478:	f84a                	sd	s2,48(sp)
    8000547a:	f44e                	sd	s3,40(sp)
    8000547c:	f052                	sd	s4,32(sp)
    8000547e:	ec56                	sd	s5,24(sp)
    80005480:	e85a                	sd	s6,16(sp)
    80005482:	e45e                	sd	s7,8(sp)
    80005484:	e062                	sd	s8,0(sp)
    80005486:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005488:	00954783          	lbu	a5,9(a0)
    8000548c:	10078663          	beqz	a5,80005598 <filewrite+0x128>
    80005490:	892a                	mv	s2,a0
    80005492:	8aae                	mv	s5,a1
    80005494:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005496:	411c                	lw	a5,0(a0)
    80005498:	4705                	li	a4,1
    8000549a:	02e78263          	beq	a5,a4,800054be <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000549e:	470d                	li	a4,3
    800054a0:	02e78663          	beq	a5,a4,800054cc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800054a4:	4709                	li	a4,2
    800054a6:	0ee79163          	bne	a5,a4,80005588 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800054aa:	0ac05d63          	blez	a2,80005564 <filewrite+0xf4>
    int i = 0;
    800054ae:	4981                	li	s3,0
    800054b0:	6b05                	lui	s6,0x1
    800054b2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800054b6:	6b85                	lui	s7,0x1
    800054b8:	c00b8b9b          	addiw	s7,s7,-1024
    800054bc:	a861                	j	80005554 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800054be:	6908                	ld	a0,16(a0)
    800054c0:	00000097          	auipc	ra,0x0
    800054c4:	22e080e7          	jalr	558(ra) # 800056ee <pipewrite>
    800054c8:	8a2a                	mv	s4,a0
    800054ca:	a045                	j	8000556a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800054cc:	02451783          	lh	a5,36(a0)
    800054d0:	03079693          	slli	a3,a5,0x30
    800054d4:	92c1                	srli	a3,a3,0x30
    800054d6:	4725                	li	a4,9
    800054d8:	0cd76263          	bltu	a4,a3,8000559c <filewrite+0x12c>
    800054dc:	0792                	slli	a5,a5,0x4
    800054de:	0001e717          	auipc	a4,0x1e
    800054e2:	c8a70713          	addi	a4,a4,-886 # 80023168 <devsw>
    800054e6:	97ba                	add	a5,a5,a4
    800054e8:	679c                	ld	a5,8(a5)
    800054ea:	cbdd                	beqz	a5,800055a0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800054ec:	4505                	li	a0,1
    800054ee:	9782                	jalr	a5
    800054f0:	8a2a                	mv	s4,a0
    800054f2:	a8a5                	j	8000556a <filewrite+0xfa>
    800054f4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800054f8:	00000097          	auipc	ra,0x0
    800054fc:	8b0080e7          	jalr	-1872(ra) # 80004da8 <begin_op>
      ilock(f->ip);
    80005500:	01893503          	ld	a0,24(s2)
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	ed2080e7          	jalr	-302(ra) # 800043d6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000550c:	8762                	mv	a4,s8
    8000550e:	02092683          	lw	a3,32(s2)
    80005512:	01598633          	add	a2,s3,s5
    80005516:	4585                	li	a1,1
    80005518:	01893503          	ld	a0,24(s2)
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	266080e7          	jalr	614(ra) # 80004782 <writei>
    80005524:	84aa                	mv	s1,a0
    80005526:	00a05763          	blez	a0,80005534 <filewrite+0xc4>
        f->off += r;
    8000552a:	02092783          	lw	a5,32(s2)
    8000552e:	9fa9                	addw	a5,a5,a0
    80005530:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005534:	01893503          	ld	a0,24(s2)
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	f60080e7          	jalr	-160(ra) # 80004498 <iunlock>
      end_op();
    80005540:	00000097          	auipc	ra,0x0
    80005544:	8e8080e7          	jalr	-1816(ra) # 80004e28 <end_op>

      if(r != n1){
    80005548:	009c1f63          	bne	s8,s1,80005566 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000554c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005550:	0149db63          	bge	s3,s4,80005566 <filewrite+0xf6>
      int n1 = n - i;
    80005554:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005558:	84be                	mv	s1,a5
    8000555a:	2781                	sext.w	a5,a5
    8000555c:	f8fb5ce3          	bge	s6,a5,800054f4 <filewrite+0x84>
    80005560:	84de                	mv	s1,s7
    80005562:	bf49                	j	800054f4 <filewrite+0x84>
    int i = 0;
    80005564:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005566:	013a1f63          	bne	s4,s3,80005584 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000556a:	8552                	mv	a0,s4
    8000556c:	60a6                	ld	ra,72(sp)
    8000556e:	6406                	ld	s0,64(sp)
    80005570:	74e2                	ld	s1,56(sp)
    80005572:	7942                	ld	s2,48(sp)
    80005574:	79a2                	ld	s3,40(sp)
    80005576:	7a02                	ld	s4,32(sp)
    80005578:	6ae2                	ld	s5,24(sp)
    8000557a:	6b42                	ld	s6,16(sp)
    8000557c:	6ba2                	ld	s7,8(sp)
    8000557e:	6c02                	ld	s8,0(sp)
    80005580:	6161                	addi	sp,sp,80
    80005582:	8082                	ret
    ret = (i == n ? n : -1);
    80005584:	5a7d                	li	s4,-1
    80005586:	b7d5                	j	8000556a <filewrite+0xfa>
    panic("filewrite");
    80005588:	00003517          	auipc	a0,0x3
    8000558c:	2d050513          	addi	a0,a0,720 # 80008858 <syscalls+0x280>
    80005590:	ffffb097          	auipc	ra,0xffffb
    80005594:	fae080e7          	jalr	-82(ra) # 8000053e <panic>
    return -1;
    80005598:	5a7d                	li	s4,-1
    8000559a:	bfc1                	j	8000556a <filewrite+0xfa>
      return -1;
    8000559c:	5a7d                	li	s4,-1
    8000559e:	b7f1                	j	8000556a <filewrite+0xfa>
    800055a0:	5a7d                	li	s4,-1
    800055a2:	b7e1                	j	8000556a <filewrite+0xfa>

00000000800055a4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800055a4:	7179                	addi	sp,sp,-48
    800055a6:	f406                	sd	ra,40(sp)
    800055a8:	f022                	sd	s0,32(sp)
    800055aa:	ec26                	sd	s1,24(sp)
    800055ac:	e84a                	sd	s2,16(sp)
    800055ae:	e44e                	sd	s3,8(sp)
    800055b0:	e052                	sd	s4,0(sp)
    800055b2:	1800                	addi	s0,sp,48
    800055b4:	84aa                	mv	s1,a0
    800055b6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800055b8:	0005b023          	sd	zero,0(a1)
    800055bc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800055c0:	00000097          	auipc	ra,0x0
    800055c4:	bf8080e7          	jalr	-1032(ra) # 800051b8 <filealloc>
    800055c8:	e088                	sd	a0,0(s1)
    800055ca:	c551                	beqz	a0,80005656 <pipealloc+0xb2>
    800055cc:	00000097          	auipc	ra,0x0
    800055d0:	bec080e7          	jalr	-1044(ra) # 800051b8 <filealloc>
    800055d4:	00aa3023          	sd	a0,0(s4)
    800055d8:	c92d                	beqz	a0,8000564a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800055da:	ffffb097          	auipc	ra,0xffffb
    800055de:	51a080e7          	jalr	1306(ra) # 80000af4 <kalloc>
    800055e2:	892a                	mv	s2,a0
    800055e4:	c125                	beqz	a0,80005644 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800055e6:	4985                	li	s3,1
    800055e8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800055ec:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800055f0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800055f4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800055f8:	00003597          	auipc	a1,0x3
    800055fc:	f2858593          	addi	a1,a1,-216 # 80008520 <states.1845+0x1e0>
    80005600:	ffffb097          	auipc	ra,0xffffb
    80005604:	554080e7          	jalr	1364(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005608:	609c                	ld	a5,0(s1)
    8000560a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000560e:	609c                	ld	a5,0(s1)
    80005610:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005614:	609c                	ld	a5,0(s1)
    80005616:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000561a:	609c                	ld	a5,0(s1)
    8000561c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005620:	000a3783          	ld	a5,0(s4)
    80005624:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005628:	000a3783          	ld	a5,0(s4)
    8000562c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005630:	000a3783          	ld	a5,0(s4)
    80005634:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005638:	000a3783          	ld	a5,0(s4)
    8000563c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005640:	4501                	li	a0,0
    80005642:	a025                	j	8000566a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005644:	6088                	ld	a0,0(s1)
    80005646:	e501                	bnez	a0,8000564e <pipealloc+0xaa>
    80005648:	a039                	j	80005656 <pipealloc+0xb2>
    8000564a:	6088                	ld	a0,0(s1)
    8000564c:	c51d                	beqz	a0,8000567a <pipealloc+0xd6>
    fileclose(*f0);
    8000564e:	00000097          	auipc	ra,0x0
    80005652:	c26080e7          	jalr	-986(ra) # 80005274 <fileclose>
  if(*f1)
    80005656:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000565a:	557d                	li	a0,-1
  if(*f1)
    8000565c:	c799                	beqz	a5,8000566a <pipealloc+0xc6>
    fileclose(*f1);
    8000565e:	853e                	mv	a0,a5
    80005660:	00000097          	auipc	ra,0x0
    80005664:	c14080e7          	jalr	-1004(ra) # 80005274 <fileclose>
  return -1;
    80005668:	557d                	li	a0,-1
}
    8000566a:	70a2                	ld	ra,40(sp)
    8000566c:	7402                	ld	s0,32(sp)
    8000566e:	64e2                	ld	s1,24(sp)
    80005670:	6942                	ld	s2,16(sp)
    80005672:	69a2                	ld	s3,8(sp)
    80005674:	6a02                	ld	s4,0(sp)
    80005676:	6145                	addi	sp,sp,48
    80005678:	8082                	ret
  return -1;
    8000567a:	557d                	li	a0,-1
    8000567c:	b7fd                	j	8000566a <pipealloc+0xc6>

000000008000567e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000567e:	1101                	addi	sp,sp,-32
    80005680:	ec06                	sd	ra,24(sp)
    80005682:	e822                	sd	s0,16(sp)
    80005684:	e426                	sd	s1,8(sp)
    80005686:	e04a                	sd	s2,0(sp)
    80005688:	1000                	addi	s0,sp,32
    8000568a:	84aa                	mv	s1,a0
    8000568c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000568e:	ffffb097          	auipc	ra,0xffffb
    80005692:	556080e7          	jalr	1366(ra) # 80000be4 <acquire>
  if(writable){
    80005696:	02090d63          	beqz	s2,800056d0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000569a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000569e:	21848513          	addi	a0,s1,536
    800056a2:	ffffd097          	auipc	ra,0xffffd
    800056a6:	1ec080e7          	jalr	492(ra) # 8000288e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800056aa:	2204b783          	ld	a5,544(s1)
    800056ae:	eb95                	bnez	a5,800056e2 <pipeclose+0x64>
    release(&pi->lock);
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffb097          	auipc	ra,0xffffb
    800056b6:	5e6080e7          	jalr	1510(ra) # 80000c98 <release>
    kfree((char*)pi);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffb097          	auipc	ra,0xffffb
    800056c0:	33c080e7          	jalr	828(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800056c4:	60e2                	ld	ra,24(sp)
    800056c6:	6442                	ld	s0,16(sp)
    800056c8:	64a2                	ld	s1,8(sp)
    800056ca:	6902                	ld	s2,0(sp)
    800056cc:	6105                	addi	sp,sp,32
    800056ce:	8082                	ret
    pi->readopen = 0;
    800056d0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800056d4:	21c48513          	addi	a0,s1,540
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	1b6080e7          	jalr	438(ra) # 8000288e <wakeup>
    800056e0:	b7e9                	j	800056aa <pipeclose+0x2c>
    release(&pi->lock);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffb097          	auipc	ra,0xffffb
    800056e8:	5b4080e7          	jalr	1460(ra) # 80000c98 <release>
}
    800056ec:	bfe1                	j	800056c4 <pipeclose+0x46>

00000000800056ee <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800056ee:	7159                	addi	sp,sp,-112
    800056f0:	f486                	sd	ra,104(sp)
    800056f2:	f0a2                	sd	s0,96(sp)
    800056f4:	eca6                	sd	s1,88(sp)
    800056f6:	e8ca                	sd	s2,80(sp)
    800056f8:	e4ce                	sd	s3,72(sp)
    800056fa:	e0d2                	sd	s4,64(sp)
    800056fc:	fc56                	sd	s5,56(sp)
    800056fe:	f85a                	sd	s6,48(sp)
    80005700:	f45e                	sd	s7,40(sp)
    80005702:	f062                	sd	s8,32(sp)
    80005704:	ec66                	sd	s9,24(sp)
    80005706:	1880                	addi	s0,sp,112
    80005708:	84aa                	mv	s1,a0
    8000570a:	8aae                	mv	s5,a1
    8000570c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000570e:	ffffc097          	auipc	ra,0xffffc
    80005712:	2aa080e7          	jalr	682(ra) # 800019b8 <myproc>
    80005716:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffb097          	auipc	ra,0xffffb
    8000571e:	4ca080e7          	jalr	1226(ra) # 80000be4 <acquire>
  while(i < n){
    80005722:	0d405163          	blez	s4,800057e4 <pipewrite+0xf6>
    80005726:	8ba6                	mv	s7,s1
  int i = 0;
    80005728:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000572a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000572c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005730:	21c48c13          	addi	s8,s1,540
    80005734:	a08d                	j	80005796 <pipewrite+0xa8>
      release(&pi->lock);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffb097          	auipc	ra,0xffffb
    8000573c:	560080e7          	jalr	1376(ra) # 80000c98 <release>
      return -1;
    80005740:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005742:	854a                	mv	a0,s2
    80005744:	70a6                	ld	ra,104(sp)
    80005746:	7406                	ld	s0,96(sp)
    80005748:	64e6                	ld	s1,88(sp)
    8000574a:	6946                	ld	s2,80(sp)
    8000574c:	69a6                	ld	s3,72(sp)
    8000574e:	6a06                	ld	s4,64(sp)
    80005750:	7ae2                	ld	s5,56(sp)
    80005752:	7b42                	ld	s6,48(sp)
    80005754:	7ba2                	ld	s7,40(sp)
    80005756:	7c02                	ld	s8,32(sp)
    80005758:	6ce2                	ld	s9,24(sp)
    8000575a:	6165                	addi	sp,sp,112
    8000575c:	8082                	ret
      wakeup(&pi->nread);
    8000575e:	8566                	mv	a0,s9
    80005760:	ffffd097          	auipc	ra,0xffffd
    80005764:	12e080e7          	jalr	302(ra) # 8000288e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005768:	85de                	mv	a1,s7
    8000576a:	8562                	mv	a0,s8
    8000576c:	ffffd097          	auipc	ra,0xffffd
    80005770:	f96080e7          	jalr	-106(ra) # 80002702 <sleep>
    80005774:	a839                	j	80005792 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005776:	21c4a783          	lw	a5,540(s1)
    8000577a:	0017871b          	addiw	a4,a5,1
    8000577e:	20e4ae23          	sw	a4,540(s1)
    80005782:	1ff7f793          	andi	a5,a5,511
    80005786:	97a6                	add	a5,a5,s1
    80005788:	f9f44703          	lbu	a4,-97(s0)
    8000578c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005790:	2905                	addiw	s2,s2,1
  while(i < n){
    80005792:	03495d63          	bge	s2,s4,800057cc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005796:	2204a783          	lw	a5,544(s1)
    8000579a:	dfd1                	beqz	a5,80005736 <pipewrite+0x48>
    8000579c:	0289a783          	lw	a5,40(s3)
    800057a0:	fbd9                	bnez	a5,80005736 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800057a2:	2184a783          	lw	a5,536(s1)
    800057a6:	21c4a703          	lw	a4,540(s1)
    800057aa:	2007879b          	addiw	a5,a5,512
    800057ae:	faf708e3          	beq	a4,a5,8000575e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800057b2:	4685                	li	a3,1
    800057b4:	01590633          	add	a2,s2,s5
    800057b8:	f9f40593          	addi	a1,s0,-97
    800057bc:	0709b503          	ld	a0,112(s3)
    800057c0:	ffffc097          	auipc	ra,0xffffc
    800057c4:	f46080e7          	jalr	-186(ra) # 80001706 <copyin>
    800057c8:	fb6517e3          	bne	a0,s6,80005776 <pipewrite+0x88>
  wakeup(&pi->nread);
    800057cc:	21848513          	addi	a0,s1,536
    800057d0:	ffffd097          	auipc	ra,0xffffd
    800057d4:	0be080e7          	jalr	190(ra) # 8000288e <wakeup>
  release(&pi->lock);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffb097          	auipc	ra,0xffffb
    800057de:	4be080e7          	jalr	1214(ra) # 80000c98 <release>
  return i;
    800057e2:	b785                	j	80005742 <pipewrite+0x54>
  int i = 0;
    800057e4:	4901                	li	s2,0
    800057e6:	b7dd                	j	800057cc <pipewrite+0xde>

00000000800057e8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800057e8:	715d                	addi	sp,sp,-80
    800057ea:	e486                	sd	ra,72(sp)
    800057ec:	e0a2                	sd	s0,64(sp)
    800057ee:	fc26                	sd	s1,56(sp)
    800057f0:	f84a                	sd	s2,48(sp)
    800057f2:	f44e                	sd	s3,40(sp)
    800057f4:	f052                	sd	s4,32(sp)
    800057f6:	ec56                	sd	s5,24(sp)
    800057f8:	e85a                	sd	s6,16(sp)
    800057fa:	0880                	addi	s0,sp,80
    800057fc:	84aa                	mv	s1,a0
    800057fe:	892e                	mv	s2,a1
    80005800:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005802:	ffffc097          	auipc	ra,0xffffc
    80005806:	1b6080e7          	jalr	438(ra) # 800019b8 <myproc>
    8000580a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000580c:	8b26                	mv	s6,s1
    8000580e:	8526                	mv	a0,s1
    80005810:	ffffb097          	auipc	ra,0xffffb
    80005814:	3d4080e7          	jalr	980(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005818:	2184a703          	lw	a4,536(s1)
    8000581c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005820:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005824:	02f71463          	bne	a4,a5,8000584c <piperead+0x64>
    80005828:	2244a783          	lw	a5,548(s1)
    8000582c:	c385                	beqz	a5,8000584c <piperead+0x64>
    if(pr->killed){
    8000582e:	028a2783          	lw	a5,40(s4)
    80005832:	ebc1                	bnez	a5,800058c2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005834:	85da                	mv	a1,s6
    80005836:	854e                	mv	a0,s3
    80005838:	ffffd097          	auipc	ra,0xffffd
    8000583c:	eca080e7          	jalr	-310(ra) # 80002702 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005840:	2184a703          	lw	a4,536(s1)
    80005844:	21c4a783          	lw	a5,540(s1)
    80005848:	fef700e3          	beq	a4,a5,80005828 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000584c:	09505263          	blez	s5,800058d0 <piperead+0xe8>
    80005850:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005852:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005854:	2184a783          	lw	a5,536(s1)
    80005858:	21c4a703          	lw	a4,540(s1)
    8000585c:	02f70d63          	beq	a4,a5,80005896 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005860:	0017871b          	addiw	a4,a5,1
    80005864:	20e4ac23          	sw	a4,536(s1)
    80005868:	1ff7f793          	andi	a5,a5,511
    8000586c:	97a6                	add	a5,a5,s1
    8000586e:	0187c783          	lbu	a5,24(a5)
    80005872:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005876:	4685                	li	a3,1
    80005878:	fbf40613          	addi	a2,s0,-65
    8000587c:	85ca                	mv	a1,s2
    8000587e:	070a3503          	ld	a0,112(s4)
    80005882:	ffffc097          	auipc	ra,0xffffc
    80005886:	df8080e7          	jalr	-520(ra) # 8000167a <copyout>
    8000588a:	01650663          	beq	a0,s6,80005896 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000588e:	2985                	addiw	s3,s3,1
    80005890:	0905                	addi	s2,s2,1
    80005892:	fd3a91e3          	bne	s5,s3,80005854 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005896:	21c48513          	addi	a0,s1,540
    8000589a:	ffffd097          	auipc	ra,0xffffd
    8000589e:	ff4080e7          	jalr	-12(ra) # 8000288e <wakeup>
  release(&pi->lock);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffb097          	auipc	ra,0xffffb
    800058a8:	3f4080e7          	jalr	1012(ra) # 80000c98 <release>
  return i;
}
    800058ac:	854e                	mv	a0,s3
    800058ae:	60a6                	ld	ra,72(sp)
    800058b0:	6406                	ld	s0,64(sp)
    800058b2:	74e2                	ld	s1,56(sp)
    800058b4:	7942                	ld	s2,48(sp)
    800058b6:	79a2                	ld	s3,40(sp)
    800058b8:	7a02                	ld	s4,32(sp)
    800058ba:	6ae2                	ld	s5,24(sp)
    800058bc:	6b42                	ld	s6,16(sp)
    800058be:	6161                	addi	sp,sp,80
    800058c0:	8082                	ret
      release(&pi->lock);
    800058c2:	8526                	mv	a0,s1
    800058c4:	ffffb097          	auipc	ra,0xffffb
    800058c8:	3d4080e7          	jalr	980(ra) # 80000c98 <release>
      return -1;
    800058cc:	59fd                	li	s3,-1
    800058ce:	bff9                	j	800058ac <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058d0:	4981                	li	s3,0
    800058d2:	b7d1                	j	80005896 <piperead+0xae>

00000000800058d4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800058d4:	df010113          	addi	sp,sp,-528
    800058d8:	20113423          	sd	ra,520(sp)
    800058dc:	20813023          	sd	s0,512(sp)
    800058e0:	ffa6                	sd	s1,504(sp)
    800058e2:	fbca                	sd	s2,496(sp)
    800058e4:	f7ce                	sd	s3,488(sp)
    800058e6:	f3d2                	sd	s4,480(sp)
    800058e8:	efd6                	sd	s5,472(sp)
    800058ea:	ebda                	sd	s6,464(sp)
    800058ec:	e7de                	sd	s7,456(sp)
    800058ee:	e3e2                	sd	s8,448(sp)
    800058f0:	ff66                	sd	s9,440(sp)
    800058f2:	fb6a                	sd	s10,432(sp)
    800058f4:	f76e                	sd	s11,424(sp)
    800058f6:	0c00                	addi	s0,sp,528
    800058f8:	84aa                	mv	s1,a0
    800058fa:	dea43c23          	sd	a0,-520(s0)
    800058fe:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005902:	ffffc097          	auipc	ra,0xffffc
    80005906:	0b6080e7          	jalr	182(ra) # 800019b8 <myproc>
    8000590a:	892a                	mv	s2,a0

  begin_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	49c080e7          	jalr	1180(ra) # 80004da8 <begin_op>

  if((ip = namei(path)) == 0){
    80005914:	8526                	mv	a0,s1
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	276080e7          	jalr	630(ra) # 80004b8c <namei>
    8000591e:	c92d                	beqz	a0,80005990 <exec+0xbc>
    80005920:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	ab4080e7          	jalr	-1356(ra) # 800043d6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000592a:	04000713          	li	a4,64
    8000592e:	4681                	li	a3,0
    80005930:	e5040613          	addi	a2,s0,-432
    80005934:	4581                	li	a1,0
    80005936:	8526                	mv	a0,s1
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	d52080e7          	jalr	-686(ra) # 8000468a <readi>
    80005940:	04000793          	li	a5,64
    80005944:	00f51a63          	bne	a0,a5,80005958 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005948:	e5042703          	lw	a4,-432(s0)
    8000594c:	464c47b7          	lui	a5,0x464c4
    80005950:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005954:	04f70463          	beq	a4,a5,8000599c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005958:	8526                	mv	a0,s1
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	cde080e7          	jalr	-802(ra) # 80004638 <iunlockput>
    end_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	4c6080e7          	jalr	1222(ra) # 80004e28 <end_op>
  }
  return -1;
    8000596a:	557d                	li	a0,-1
}
    8000596c:	20813083          	ld	ra,520(sp)
    80005970:	20013403          	ld	s0,512(sp)
    80005974:	74fe                	ld	s1,504(sp)
    80005976:	795e                	ld	s2,496(sp)
    80005978:	79be                	ld	s3,488(sp)
    8000597a:	7a1e                	ld	s4,480(sp)
    8000597c:	6afe                	ld	s5,472(sp)
    8000597e:	6b5e                	ld	s6,464(sp)
    80005980:	6bbe                	ld	s7,456(sp)
    80005982:	6c1e                	ld	s8,448(sp)
    80005984:	7cfa                	ld	s9,440(sp)
    80005986:	7d5a                	ld	s10,432(sp)
    80005988:	7dba                	ld	s11,424(sp)
    8000598a:	21010113          	addi	sp,sp,528
    8000598e:	8082                	ret
    end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	498080e7          	jalr	1176(ra) # 80004e28 <end_op>
    return -1;
    80005998:	557d                	li	a0,-1
    8000599a:	bfc9                	j	8000596c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000599c:	854a                	mv	a0,s2
    8000599e:	ffffc097          	auipc	ra,0xffffc
    800059a2:	0de080e7          	jalr	222(ra) # 80001a7c <proc_pagetable>
    800059a6:	8baa                	mv	s7,a0
    800059a8:	d945                	beqz	a0,80005958 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059aa:	e7042983          	lw	s3,-400(s0)
    800059ae:	e8845783          	lhu	a5,-376(s0)
    800059b2:	c7ad                	beqz	a5,80005a1c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800059b4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059b6:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800059b8:	6c85                	lui	s9,0x1
    800059ba:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800059be:	def43823          	sd	a5,-528(s0)
    800059c2:	a42d                	j	80005bec <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800059c4:	00003517          	auipc	a0,0x3
    800059c8:	ea450513          	addi	a0,a0,-348 # 80008868 <syscalls+0x290>
    800059cc:	ffffb097          	auipc	ra,0xffffb
    800059d0:	b72080e7          	jalr	-1166(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800059d4:	8756                	mv	a4,s5
    800059d6:	012d86bb          	addw	a3,s11,s2
    800059da:	4581                	li	a1,0
    800059dc:	8526                	mv	a0,s1
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	cac080e7          	jalr	-852(ra) # 8000468a <readi>
    800059e6:	2501                	sext.w	a0,a0
    800059e8:	1aaa9963          	bne	s5,a0,80005b9a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800059ec:	6785                	lui	a5,0x1
    800059ee:	0127893b          	addw	s2,a5,s2
    800059f2:	77fd                	lui	a5,0xfffff
    800059f4:	01478a3b          	addw	s4,a5,s4
    800059f8:	1f897163          	bgeu	s2,s8,80005bda <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800059fc:	02091593          	slli	a1,s2,0x20
    80005a00:	9181                	srli	a1,a1,0x20
    80005a02:	95ea                	add	a1,a1,s10
    80005a04:	855e                	mv	a0,s7
    80005a06:	ffffb097          	auipc	ra,0xffffb
    80005a0a:	670080e7          	jalr	1648(ra) # 80001076 <walkaddr>
    80005a0e:	862a                	mv	a2,a0
    if(pa == 0)
    80005a10:	d955                	beqz	a0,800059c4 <exec+0xf0>
      n = PGSIZE;
    80005a12:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005a14:	fd9a70e3          	bgeu	s4,s9,800059d4 <exec+0x100>
      n = sz - i;
    80005a18:	8ad2                	mv	s5,s4
    80005a1a:	bf6d                	j	800059d4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005a1c:	4901                	li	s2,0
  iunlockput(ip);
    80005a1e:	8526                	mv	a0,s1
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	c18080e7          	jalr	-1000(ra) # 80004638 <iunlockput>
  end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	400080e7          	jalr	1024(ra) # 80004e28 <end_op>
  p = myproc();
    80005a30:	ffffc097          	auipc	ra,0xffffc
    80005a34:	f88080e7          	jalr	-120(ra) # 800019b8 <myproc>
    80005a38:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005a3a:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80005a3e:	6785                	lui	a5,0x1
    80005a40:	17fd                	addi	a5,a5,-1
    80005a42:	993e                	add	s2,s2,a5
    80005a44:	757d                	lui	a0,0xfffff
    80005a46:	00a977b3          	and	a5,s2,a0
    80005a4a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a4e:	6609                	lui	a2,0x2
    80005a50:	963e                	add	a2,a2,a5
    80005a52:	85be                	mv	a1,a5
    80005a54:	855e                	mv	a0,s7
    80005a56:	ffffc097          	auipc	ra,0xffffc
    80005a5a:	9d4080e7          	jalr	-1580(ra) # 8000142a <uvmalloc>
    80005a5e:	8b2a                	mv	s6,a0
  ip = 0;
    80005a60:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a62:	12050c63          	beqz	a0,80005b9a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005a66:	75f9                	lui	a1,0xffffe
    80005a68:	95aa                	add	a1,a1,a0
    80005a6a:	855e                	mv	a0,s7
    80005a6c:	ffffc097          	auipc	ra,0xffffc
    80005a70:	bdc080e7          	jalr	-1060(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005a74:	7c7d                	lui	s8,0xfffff
    80005a76:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a78:	e0043783          	ld	a5,-512(s0)
    80005a7c:	6388                	ld	a0,0(a5)
    80005a7e:	c535                	beqz	a0,80005aea <exec+0x216>
    80005a80:	e9040993          	addi	s3,s0,-368
    80005a84:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005a88:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005a8a:	ffffb097          	auipc	ra,0xffffb
    80005a8e:	3da080e7          	jalr	986(ra) # 80000e64 <strlen>
    80005a92:	2505                	addiw	a0,a0,1
    80005a94:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a98:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a9c:	13896363          	bltu	s2,s8,80005bc2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005aa0:	e0043d83          	ld	s11,-512(s0)
    80005aa4:	000dba03          	ld	s4,0(s11)
    80005aa8:	8552                	mv	a0,s4
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	3ba080e7          	jalr	954(ra) # 80000e64 <strlen>
    80005ab2:	0015069b          	addiw	a3,a0,1
    80005ab6:	8652                	mv	a2,s4
    80005ab8:	85ca                	mv	a1,s2
    80005aba:	855e                	mv	a0,s7
    80005abc:	ffffc097          	auipc	ra,0xffffc
    80005ac0:	bbe080e7          	jalr	-1090(ra) # 8000167a <copyout>
    80005ac4:	10054363          	bltz	a0,80005bca <exec+0x2f6>
    ustack[argc] = sp;
    80005ac8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005acc:	0485                	addi	s1,s1,1
    80005ace:	008d8793          	addi	a5,s11,8
    80005ad2:	e0f43023          	sd	a5,-512(s0)
    80005ad6:	008db503          	ld	a0,8(s11)
    80005ada:	c911                	beqz	a0,80005aee <exec+0x21a>
    if(argc >= MAXARG)
    80005adc:	09a1                	addi	s3,s3,8
    80005ade:	fb3c96e3          	bne	s9,s3,80005a8a <exec+0x1b6>
  sz = sz1;
    80005ae2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ae6:	4481                	li	s1,0
    80005ae8:	a84d                	j	80005b9a <exec+0x2c6>
  sp = sz;
    80005aea:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005aec:	4481                	li	s1,0
  ustack[argc] = 0;
    80005aee:	00349793          	slli	a5,s1,0x3
    80005af2:	f9040713          	addi	a4,s0,-112
    80005af6:	97ba                	add	a5,a5,a4
    80005af8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005afc:	00148693          	addi	a3,s1,1
    80005b00:	068e                	slli	a3,a3,0x3
    80005b02:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005b06:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005b0a:	01897663          	bgeu	s2,s8,80005b16 <exec+0x242>
  sz = sz1;
    80005b0e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b12:	4481                	li	s1,0
    80005b14:	a059                	j	80005b9a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005b16:	e9040613          	addi	a2,s0,-368
    80005b1a:	85ca                	mv	a1,s2
    80005b1c:	855e                	mv	a0,s7
    80005b1e:	ffffc097          	auipc	ra,0xffffc
    80005b22:	b5c080e7          	jalr	-1188(ra) # 8000167a <copyout>
    80005b26:	0a054663          	bltz	a0,80005bd2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005b2a:	078ab783          	ld	a5,120(s5)
    80005b2e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005b32:	df843783          	ld	a5,-520(s0)
    80005b36:	0007c703          	lbu	a4,0(a5)
    80005b3a:	cf11                	beqz	a4,80005b56 <exec+0x282>
    80005b3c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005b3e:	02f00693          	li	a3,47
    80005b42:	a039                	j	80005b50 <exec+0x27c>
      last = s+1;
    80005b44:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005b48:	0785                	addi	a5,a5,1
    80005b4a:	fff7c703          	lbu	a4,-1(a5)
    80005b4e:	c701                	beqz	a4,80005b56 <exec+0x282>
    if(*s == '/')
    80005b50:	fed71ce3          	bne	a4,a3,80005b48 <exec+0x274>
    80005b54:	bfc5                	j	80005b44 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005b56:	4641                	li	a2,16
    80005b58:	df843583          	ld	a1,-520(s0)
    80005b5c:	178a8513          	addi	a0,s5,376
    80005b60:	ffffb097          	auipc	ra,0xffffb
    80005b64:	2d2080e7          	jalr	722(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005b68:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005b6c:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005b70:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005b74:	078ab783          	ld	a5,120(s5)
    80005b78:	e6843703          	ld	a4,-408(s0)
    80005b7c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b7e:	078ab783          	ld	a5,120(s5)
    80005b82:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b86:	85ea                	mv	a1,s10
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	f90080e7          	jalr	-112(ra) # 80001b18 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b90:	0004851b          	sext.w	a0,s1
    80005b94:	bbe1                	j	8000596c <exec+0x98>
    80005b96:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005b9a:	e0843583          	ld	a1,-504(s0)
    80005b9e:	855e                	mv	a0,s7
    80005ba0:	ffffc097          	auipc	ra,0xffffc
    80005ba4:	f78080e7          	jalr	-136(ra) # 80001b18 <proc_freepagetable>
  if(ip){
    80005ba8:	da0498e3          	bnez	s1,80005958 <exec+0x84>
  return -1;
    80005bac:	557d                	li	a0,-1
    80005bae:	bb7d                	j	8000596c <exec+0x98>
    80005bb0:	e1243423          	sd	s2,-504(s0)
    80005bb4:	b7dd                	j	80005b9a <exec+0x2c6>
    80005bb6:	e1243423          	sd	s2,-504(s0)
    80005bba:	b7c5                	j	80005b9a <exec+0x2c6>
    80005bbc:	e1243423          	sd	s2,-504(s0)
    80005bc0:	bfe9                	j	80005b9a <exec+0x2c6>
  sz = sz1;
    80005bc2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005bc6:	4481                	li	s1,0
    80005bc8:	bfc9                	j	80005b9a <exec+0x2c6>
  sz = sz1;
    80005bca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005bce:	4481                	li	s1,0
    80005bd0:	b7e9                	j	80005b9a <exec+0x2c6>
  sz = sz1;
    80005bd2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005bd6:	4481                	li	s1,0
    80005bd8:	b7c9                	j	80005b9a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005bda:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005bde:	2b05                	addiw	s6,s6,1
    80005be0:	0389899b          	addiw	s3,s3,56
    80005be4:	e8845783          	lhu	a5,-376(s0)
    80005be8:	e2fb5be3          	bge	s6,a5,80005a1e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005bec:	2981                	sext.w	s3,s3
    80005bee:	03800713          	li	a4,56
    80005bf2:	86ce                	mv	a3,s3
    80005bf4:	e1840613          	addi	a2,s0,-488
    80005bf8:	4581                	li	a1,0
    80005bfa:	8526                	mv	a0,s1
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	a8e080e7          	jalr	-1394(ra) # 8000468a <readi>
    80005c04:	03800793          	li	a5,56
    80005c08:	f8f517e3          	bne	a0,a5,80005b96 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005c0c:	e1842783          	lw	a5,-488(s0)
    80005c10:	4705                	li	a4,1
    80005c12:	fce796e3          	bne	a5,a4,80005bde <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005c16:	e4043603          	ld	a2,-448(s0)
    80005c1a:	e3843783          	ld	a5,-456(s0)
    80005c1e:	f8f669e3          	bltu	a2,a5,80005bb0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005c22:	e2843783          	ld	a5,-472(s0)
    80005c26:	963e                	add	a2,a2,a5
    80005c28:	f8f667e3          	bltu	a2,a5,80005bb6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005c2c:	85ca                	mv	a1,s2
    80005c2e:	855e                	mv	a0,s7
    80005c30:	ffffb097          	auipc	ra,0xffffb
    80005c34:	7fa080e7          	jalr	2042(ra) # 8000142a <uvmalloc>
    80005c38:	e0a43423          	sd	a0,-504(s0)
    80005c3c:	d141                	beqz	a0,80005bbc <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005c3e:	e2843d03          	ld	s10,-472(s0)
    80005c42:	df043783          	ld	a5,-528(s0)
    80005c46:	00fd77b3          	and	a5,s10,a5
    80005c4a:	fba1                	bnez	a5,80005b9a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005c4c:	e2042d83          	lw	s11,-480(s0)
    80005c50:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005c54:	f80c03e3          	beqz	s8,80005bda <exec+0x306>
    80005c58:	8a62                	mv	s4,s8
    80005c5a:	4901                	li	s2,0
    80005c5c:	b345                	j	800059fc <exec+0x128>

0000000080005c5e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c5e:	7179                	addi	sp,sp,-48
    80005c60:	f406                	sd	ra,40(sp)
    80005c62:	f022                	sd	s0,32(sp)
    80005c64:	ec26                	sd	s1,24(sp)
    80005c66:	e84a                	sd	s2,16(sp)
    80005c68:	1800                	addi	s0,sp,48
    80005c6a:	892e                	mv	s2,a1
    80005c6c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005c6e:	fdc40593          	addi	a1,s0,-36
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	9ea080e7          	jalr	-1558(ra) # 8000365c <argint>
    80005c7a:	04054063          	bltz	a0,80005cba <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c7e:	fdc42703          	lw	a4,-36(s0)
    80005c82:	47bd                	li	a5,15
    80005c84:	02e7ed63          	bltu	a5,a4,80005cbe <argfd+0x60>
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	d30080e7          	jalr	-720(ra) # 800019b8 <myproc>
    80005c90:	fdc42703          	lw	a4,-36(s0)
    80005c94:	01e70793          	addi	a5,a4,30
    80005c98:	078e                	slli	a5,a5,0x3
    80005c9a:	953e                	add	a0,a0,a5
    80005c9c:	611c                	ld	a5,0(a0)
    80005c9e:	c395                	beqz	a5,80005cc2 <argfd+0x64>
    return -1;
  if(pfd)
    80005ca0:	00090463          	beqz	s2,80005ca8 <argfd+0x4a>
    *pfd = fd;
    80005ca4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005ca8:	4501                	li	a0,0
  if(pf)
    80005caa:	c091                	beqz	s1,80005cae <argfd+0x50>
    *pf = f;
    80005cac:	e09c                	sd	a5,0(s1)
}
    80005cae:	70a2                	ld	ra,40(sp)
    80005cb0:	7402                	ld	s0,32(sp)
    80005cb2:	64e2                	ld	s1,24(sp)
    80005cb4:	6942                	ld	s2,16(sp)
    80005cb6:	6145                	addi	sp,sp,48
    80005cb8:	8082                	ret
    return -1;
    80005cba:	557d                	li	a0,-1
    80005cbc:	bfcd                	j	80005cae <argfd+0x50>
    return -1;
    80005cbe:	557d                	li	a0,-1
    80005cc0:	b7fd                	j	80005cae <argfd+0x50>
    80005cc2:	557d                	li	a0,-1
    80005cc4:	b7ed                	j	80005cae <argfd+0x50>

0000000080005cc6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005cc6:	1101                	addi	sp,sp,-32
    80005cc8:	ec06                	sd	ra,24(sp)
    80005cca:	e822                	sd	s0,16(sp)
    80005ccc:	e426                	sd	s1,8(sp)
    80005cce:	1000                	addi	s0,sp,32
    80005cd0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005cd2:	ffffc097          	auipc	ra,0xffffc
    80005cd6:	ce6080e7          	jalr	-794(ra) # 800019b8 <myproc>
    80005cda:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005cdc:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd70f0>
    80005ce0:	4501                	li	a0,0
    80005ce2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005ce4:	6398                	ld	a4,0(a5)
    80005ce6:	cb19                	beqz	a4,80005cfc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005ce8:	2505                	addiw	a0,a0,1
    80005cea:	07a1                	addi	a5,a5,8
    80005cec:	fed51ce3          	bne	a0,a3,80005ce4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005cf0:	557d                	li	a0,-1
}
    80005cf2:	60e2                	ld	ra,24(sp)
    80005cf4:	6442                	ld	s0,16(sp)
    80005cf6:	64a2                	ld	s1,8(sp)
    80005cf8:	6105                	addi	sp,sp,32
    80005cfa:	8082                	ret
      p->ofile[fd] = f;
    80005cfc:	01e50793          	addi	a5,a0,30
    80005d00:	078e                	slli	a5,a5,0x3
    80005d02:	963e                	add	a2,a2,a5
    80005d04:	e204                	sd	s1,0(a2)
      return fd;
    80005d06:	b7f5                	j	80005cf2 <fdalloc+0x2c>

0000000080005d08 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005d08:	715d                	addi	sp,sp,-80
    80005d0a:	e486                	sd	ra,72(sp)
    80005d0c:	e0a2                	sd	s0,64(sp)
    80005d0e:	fc26                	sd	s1,56(sp)
    80005d10:	f84a                	sd	s2,48(sp)
    80005d12:	f44e                	sd	s3,40(sp)
    80005d14:	f052                	sd	s4,32(sp)
    80005d16:	ec56                	sd	s5,24(sp)
    80005d18:	0880                	addi	s0,sp,80
    80005d1a:	89ae                	mv	s3,a1
    80005d1c:	8ab2                	mv	s5,a2
    80005d1e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005d20:	fb040593          	addi	a1,s0,-80
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	e86080e7          	jalr	-378(ra) # 80004baa <nameiparent>
    80005d2c:	892a                	mv	s2,a0
    80005d2e:	12050f63          	beqz	a0,80005e6c <create+0x164>
    return 0;

  ilock(dp);
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	6a4080e7          	jalr	1700(ra) # 800043d6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005d3a:	4601                	li	a2,0
    80005d3c:	fb040593          	addi	a1,s0,-80
    80005d40:	854a                	mv	a0,s2
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	b78080e7          	jalr	-1160(ra) # 800048ba <dirlookup>
    80005d4a:	84aa                	mv	s1,a0
    80005d4c:	c921                	beqz	a0,80005d9c <create+0x94>
    iunlockput(dp);
    80005d4e:	854a                	mv	a0,s2
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	8e8080e7          	jalr	-1816(ra) # 80004638 <iunlockput>
    ilock(ip);
    80005d58:	8526                	mv	a0,s1
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	67c080e7          	jalr	1660(ra) # 800043d6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005d62:	2981                	sext.w	s3,s3
    80005d64:	4789                	li	a5,2
    80005d66:	02f99463          	bne	s3,a5,80005d8e <create+0x86>
    80005d6a:	0444d783          	lhu	a5,68(s1)
    80005d6e:	37f9                	addiw	a5,a5,-2
    80005d70:	17c2                	slli	a5,a5,0x30
    80005d72:	93c1                	srli	a5,a5,0x30
    80005d74:	4705                	li	a4,1
    80005d76:	00f76c63          	bltu	a4,a5,80005d8e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005d7a:	8526                	mv	a0,s1
    80005d7c:	60a6                	ld	ra,72(sp)
    80005d7e:	6406                	ld	s0,64(sp)
    80005d80:	74e2                	ld	s1,56(sp)
    80005d82:	7942                	ld	s2,48(sp)
    80005d84:	79a2                	ld	s3,40(sp)
    80005d86:	7a02                	ld	s4,32(sp)
    80005d88:	6ae2                	ld	s5,24(sp)
    80005d8a:	6161                	addi	sp,sp,80
    80005d8c:	8082                	ret
    iunlockput(ip);
    80005d8e:	8526                	mv	a0,s1
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	8a8080e7          	jalr	-1880(ra) # 80004638 <iunlockput>
    return 0;
    80005d98:	4481                	li	s1,0
    80005d9a:	b7c5                	j	80005d7a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005d9c:	85ce                	mv	a1,s3
    80005d9e:	00092503          	lw	a0,0(s2)
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	49c080e7          	jalr	1180(ra) # 8000423e <ialloc>
    80005daa:	84aa                	mv	s1,a0
    80005dac:	c529                	beqz	a0,80005df6 <create+0xee>
  ilock(ip);
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	628080e7          	jalr	1576(ra) # 800043d6 <ilock>
  ip->major = major;
    80005db6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005dba:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005dbe:	4785                	li	a5,1
    80005dc0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005dc4:	8526                	mv	a0,s1
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	546080e7          	jalr	1350(ra) # 8000430c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005dce:	2981                	sext.w	s3,s3
    80005dd0:	4785                	li	a5,1
    80005dd2:	02f98a63          	beq	s3,a5,80005e06 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005dd6:	40d0                	lw	a2,4(s1)
    80005dd8:	fb040593          	addi	a1,s0,-80
    80005ddc:	854a                	mv	a0,s2
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	cec080e7          	jalr	-788(ra) # 80004aca <dirlink>
    80005de6:	06054b63          	bltz	a0,80005e5c <create+0x154>
  iunlockput(dp);
    80005dea:	854a                	mv	a0,s2
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	84c080e7          	jalr	-1972(ra) # 80004638 <iunlockput>
  return ip;
    80005df4:	b759                	j	80005d7a <create+0x72>
    panic("create: ialloc");
    80005df6:	00003517          	auipc	a0,0x3
    80005dfa:	a9250513          	addi	a0,a0,-1390 # 80008888 <syscalls+0x2b0>
    80005dfe:	ffffa097          	auipc	ra,0xffffa
    80005e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005e06:	04a95783          	lhu	a5,74(s2)
    80005e0a:	2785                	addiw	a5,a5,1
    80005e0c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005e10:	854a                	mv	a0,s2
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	4fa080e7          	jalr	1274(ra) # 8000430c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005e1a:	40d0                	lw	a2,4(s1)
    80005e1c:	00003597          	auipc	a1,0x3
    80005e20:	a7c58593          	addi	a1,a1,-1412 # 80008898 <syscalls+0x2c0>
    80005e24:	8526                	mv	a0,s1
    80005e26:	fffff097          	auipc	ra,0xfffff
    80005e2a:	ca4080e7          	jalr	-860(ra) # 80004aca <dirlink>
    80005e2e:	00054f63          	bltz	a0,80005e4c <create+0x144>
    80005e32:	00492603          	lw	a2,4(s2)
    80005e36:	00003597          	auipc	a1,0x3
    80005e3a:	a6a58593          	addi	a1,a1,-1430 # 800088a0 <syscalls+0x2c8>
    80005e3e:	8526                	mv	a0,s1
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	c8a080e7          	jalr	-886(ra) # 80004aca <dirlink>
    80005e48:	f80557e3          	bgez	a0,80005dd6 <create+0xce>
      panic("create dots");
    80005e4c:	00003517          	auipc	a0,0x3
    80005e50:	a5c50513          	addi	a0,a0,-1444 # 800088a8 <syscalls+0x2d0>
    80005e54:	ffffa097          	auipc	ra,0xffffa
    80005e58:	6ea080e7          	jalr	1770(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005e5c:	00003517          	auipc	a0,0x3
    80005e60:	a5c50513          	addi	a0,a0,-1444 # 800088b8 <syscalls+0x2e0>
    80005e64:	ffffa097          	auipc	ra,0xffffa
    80005e68:	6da080e7          	jalr	1754(ra) # 8000053e <panic>
    return 0;
    80005e6c:	84aa                	mv	s1,a0
    80005e6e:	b731                	j	80005d7a <create+0x72>

0000000080005e70 <sys_dup>:
{
    80005e70:	7179                	addi	sp,sp,-48
    80005e72:	f406                	sd	ra,40(sp)
    80005e74:	f022                	sd	s0,32(sp)
    80005e76:	ec26                	sd	s1,24(sp)
    80005e78:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e7a:	fd840613          	addi	a2,s0,-40
    80005e7e:	4581                	li	a1,0
    80005e80:	4501                	li	a0,0
    80005e82:	00000097          	auipc	ra,0x0
    80005e86:	ddc080e7          	jalr	-548(ra) # 80005c5e <argfd>
    return -1;
    80005e8a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e8c:	02054363          	bltz	a0,80005eb2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e90:	fd843503          	ld	a0,-40(s0)
    80005e94:	00000097          	auipc	ra,0x0
    80005e98:	e32080e7          	jalr	-462(ra) # 80005cc6 <fdalloc>
    80005e9c:	84aa                	mv	s1,a0
    return -1;
    80005e9e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005ea0:	00054963          	bltz	a0,80005eb2 <sys_dup+0x42>
  filedup(f);
    80005ea4:	fd843503          	ld	a0,-40(s0)
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	37a080e7          	jalr	890(ra) # 80005222 <filedup>
  return fd;
    80005eb0:	87a6                	mv	a5,s1
}
    80005eb2:	853e                	mv	a0,a5
    80005eb4:	70a2                	ld	ra,40(sp)
    80005eb6:	7402                	ld	s0,32(sp)
    80005eb8:	64e2                	ld	s1,24(sp)
    80005eba:	6145                	addi	sp,sp,48
    80005ebc:	8082                	ret

0000000080005ebe <sys_read>:
{
    80005ebe:	7179                	addi	sp,sp,-48
    80005ec0:	f406                	sd	ra,40(sp)
    80005ec2:	f022                	sd	s0,32(sp)
    80005ec4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ec6:	fe840613          	addi	a2,s0,-24
    80005eca:	4581                	li	a1,0
    80005ecc:	4501                	li	a0,0
    80005ece:	00000097          	auipc	ra,0x0
    80005ed2:	d90080e7          	jalr	-624(ra) # 80005c5e <argfd>
    return -1;
    80005ed6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ed8:	04054163          	bltz	a0,80005f1a <sys_read+0x5c>
    80005edc:	fe440593          	addi	a1,s0,-28
    80005ee0:	4509                	li	a0,2
    80005ee2:	ffffd097          	auipc	ra,0xffffd
    80005ee6:	77a080e7          	jalr	1914(ra) # 8000365c <argint>
    return -1;
    80005eea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eec:	02054763          	bltz	a0,80005f1a <sys_read+0x5c>
    80005ef0:	fd840593          	addi	a1,s0,-40
    80005ef4:	4505                	li	a0,1
    80005ef6:	ffffd097          	auipc	ra,0xffffd
    80005efa:	788080e7          	jalr	1928(ra) # 8000367e <argaddr>
    return -1;
    80005efe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f00:	00054d63          	bltz	a0,80005f1a <sys_read+0x5c>
  return fileread(f, p, n);
    80005f04:	fe442603          	lw	a2,-28(s0)
    80005f08:	fd843583          	ld	a1,-40(s0)
    80005f0c:	fe843503          	ld	a0,-24(s0)
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	49e080e7          	jalr	1182(ra) # 800053ae <fileread>
    80005f18:	87aa                	mv	a5,a0
}
    80005f1a:	853e                	mv	a0,a5
    80005f1c:	70a2                	ld	ra,40(sp)
    80005f1e:	7402                	ld	s0,32(sp)
    80005f20:	6145                	addi	sp,sp,48
    80005f22:	8082                	ret

0000000080005f24 <sys_write>:
{
    80005f24:	7179                	addi	sp,sp,-48
    80005f26:	f406                	sd	ra,40(sp)
    80005f28:	f022                	sd	s0,32(sp)
    80005f2a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f2c:	fe840613          	addi	a2,s0,-24
    80005f30:	4581                	li	a1,0
    80005f32:	4501                	li	a0,0
    80005f34:	00000097          	auipc	ra,0x0
    80005f38:	d2a080e7          	jalr	-726(ra) # 80005c5e <argfd>
    return -1;
    80005f3c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f3e:	04054163          	bltz	a0,80005f80 <sys_write+0x5c>
    80005f42:	fe440593          	addi	a1,s0,-28
    80005f46:	4509                	li	a0,2
    80005f48:	ffffd097          	auipc	ra,0xffffd
    80005f4c:	714080e7          	jalr	1812(ra) # 8000365c <argint>
    return -1;
    80005f50:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f52:	02054763          	bltz	a0,80005f80 <sys_write+0x5c>
    80005f56:	fd840593          	addi	a1,s0,-40
    80005f5a:	4505                	li	a0,1
    80005f5c:	ffffd097          	auipc	ra,0xffffd
    80005f60:	722080e7          	jalr	1826(ra) # 8000367e <argaddr>
    return -1;
    80005f64:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f66:	00054d63          	bltz	a0,80005f80 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005f6a:	fe442603          	lw	a2,-28(s0)
    80005f6e:	fd843583          	ld	a1,-40(s0)
    80005f72:	fe843503          	ld	a0,-24(s0)
    80005f76:	fffff097          	auipc	ra,0xfffff
    80005f7a:	4fa080e7          	jalr	1274(ra) # 80005470 <filewrite>
    80005f7e:	87aa                	mv	a5,a0
}
    80005f80:	853e                	mv	a0,a5
    80005f82:	70a2                	ld	ra,40(sp)
    80005f84:	7402                	ld	s0,32(sp)
    80005f86:	6145                	addi	sp,sp,48
    80005f88:	8082                	ret

0000000080005f8a <sys_close>:
{
    80005f8a:	1101                	addi	sp,sp,-32
    80005f8c:	ec06                	sd	ra,24(sp)
    80005f8e:	e822                	sd	s0,16(sp)
    80005f90:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f92:	fe040613          	addi	a2,s0,-32
    80005f96:	fec40593          	addi	a1,s0,-20
    80005f9a:	4501                	li	a0,0
    80005f9c:	00000097          	auipc	ra,0x0
    80005fa0:	cc2080e7          	jalr	-830(ra) # 80005c5e <argfd>
    return -1;
    80005fa4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005fa6:	02054463          	bltz	a0,80005fce <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005faa:	ffffc097          	auipc	ra,0xffffc
    80005fae:	a0e080e7          	jalr	-1522(ra) # 800019b8 <myproc>
    80005fb2:	fec42783          	lw	a5,-20(s0)
    80005fb6:	07f9                	addi	a5,a5,30
    80005fb8:	078e                	slli	a5,a5,0x3
    80005fba:	97aa                	add	a5,a5,a0
    80005fbc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005fc0:	fe043503          	ld	a0,-32(s0)
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	2b0080e7          	jalr	688(ra) # 80005274 <fileclose>
  return 0;
    80005fcc:	4781                	li	a5,0
}
    80005fce:	853e                	mv	a0,a5
    80005fd0:	60e2                	ld	ra,24(sp)
    80005fd2:	6442                	ld	s0,16(sp)
    80005fd4:	6105                	addi	sp,sp,32
    80005fd6:	8082                	ret

0000000080005fd8 <sys_fstat>:
{
    80005fd8:	1101                	addi	sp,sp,-32
    80005fda:	ec06                	sd	ra,24(sp)
    80005fdc:	e822                	sd	s0,16(sp)
    80005fde:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fe0:	fe840613          	addi	a2,s0,-24
    80005fe4:	4581                	li	a1,0
    80005fe6:	4501                	li	a0,0
    80005fe8:	00000097          	auipc	ra,0x0
    80005fec:	c76080e7          	jalr	-906(ra) # 80005c5e <argfd>
    return -1;
    80005ff0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ff2:	02054563          	bltz	a0,8000601c <sys_fstat+0x44>
    80005ff6:	fe040593          	addi	a1,s0,-32
    80005ffa:	4505                	li	a0,1
    80005ffc:	ffffd097          	auipc	ra,0xffffd
    80006000:	682080e7          	jalr	1666(ra) # 8000367e <argaddr>
    return -1;
    80006004:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006006:	00054b63          	bltz	a0,8000601c <sys_fstat+0x44>
  return filestat(f, st);
    8000600a:	fe043583          	ld	a1,-32(s0)
    8000600e:	fe843503          	ld	a0,-24(s0)
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	32a080e7          	jalr	810(ra) # 8000533c <filestat>
    8000601a:	87aa                	mv	a5,a0
}
    8000601c:	853e                	mv	a0,a5
    8000601e:	60e2                	ld	ra,24(sp)
    80006020:	6442                	ld	s0,16(sp)
    80006022:	6105                	addi	sp,sp,32
    80006024:	8082                	ret

0000000080006026 <sys_link>:
{
    80006026:	7169                	addi	sp,sp,-304
    80006028:	f606                	sd	ra,296(sp)
    8000602a:	f222                	sd	s0,288(sp)
    8000602c:	ee26                	sd	s1,280(sp)
    8000602e:	ea4a                	sd	s2,272(sp)
    80006030:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006032:	08000613          	li	a2,128
    80006036:	ed040593          	addi	a1,s0,-304
    8000603a:	4501                	li	a0,0
    8000603c:	ffffd097          	auipc	ra,0xffffd
    80006040:	664080e7          	jalr	1636(ra) # 800036a0 <argstr>
    return -1;
    80006044:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006046:	10054e63          	bltz	a0,80006162 <sys_link+0x13c>
    8000604a:	08000613          	li	a2,128
    8000604e:	f5040593          	addi	a1,s0,-176
    80006052:	4505                	li	a0,1
    80006054:	ffffd097          	auipc	ra,0xffffd
    80006058:	64c080e7          	jalr	1612(ra) # 800036a0 <argstr>
    return -1;
    8000605c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000605e:	10054263          	bltz	a0,80006162 <sys_link+0x13c>
  begin_op();
    80006062:	fffff097          	auipc	ra,0xfffff
    80006066:	d46080e7          	jalr	-698(ra) # 80004da8 <begin_op>
  if((ip = namei(old)) == 0){
    8000606a:	ed040513          	addi	a0,s0,-304
    8000606e:	fffff097          	auipc	ra,0xfffff
    80006072:	b1e080e7          	jalr	-1250(ra) # 80004b8c <namei>
    80006076:	84aa                	mv	s1,a0
    80006078:	c551                	beqz	a0,80006104 <sys_link+0xde>
  ilock(ip);
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	35c080e7          	jalr	860(ra) # 800043d6 <ilock>
  if(ip->type == T_DIR){
    80006082:	04449703          	lh	a4,68(s1)
    80006086:	4785                	li	a5,1
    80006088:	08f70463          	beq	a4,a5,80006110 <sys_link+0xea>
  ip->nlink++;
    8000608c:	04a4d783          	lhu	a5,74(s1)
    80006090:	2785                	addiw	a5,a5,1
    80006092:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006096:	8526                	mv	a0,s1
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	274080e7          	jalr	628(ra) # 8000430c <iupdate>
  iunlock(ip);
    800060a0:	8526                	mv	a0,s1
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	3f6080e7          	jalr	1014(ra) # 80004498 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800060aa:	fd040593          	addi	a1,s0,-48
    800060ae:	f5040513          	addi	a0,s0,-176
    800060b2:	fffff097          	auipc	ra,0xfffff
    800060b6:	af8080e7          	jalr	-1288(ra) # 80004baa <nameiparent>
    800060ba:	892a                	mv	s2,a0
    800060bc:	c935                	beqz	a0,80006130 <sys_link+0x10a>
  ilock(dp);
    800060be:	ffffe097          	auipc	ra,0xffffe
    800060c2:	318080e7          	jalr	792(ra) # 800043d6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800060c6:	00092703          	lw	a4,0(s2)
    800060ca:	409c                	lw	a5,0(s1)
    800060cc:	04f71d63          	bne	a4,a5,80006126 <sys_link+0x100>
    800060d0:	40d0                	lw	a2,4(s1)
    800060d2:	fd040593          	addi	a1,s0,-48
    800060d6:	854a                	mv	a0,s2
    800060d8:	fffff097          	auipc	ra,0xfffff
    800060dc:	9f2080e7          	jalr	-1550(ra) # 80004aca <dirlink>
    800060e0:	04054363          	bltz	a0,80006126 <sys_link+0x100>
  iunlockput(dp);
    800060e4:	854a                	mv	a0,s2
    800060e6:	ffffe097          	auipc	ra,0xffffe
    800060ea:	552080e7          	jalr	1362(ra) # 80004638 <iunlockput>
  iput(ip);
    800060ee:	8526                	mv	a0,s1
    800060f0:	ffffe097          	auipc	ra,0xffffe
    800060f4:	4a0080e7          	jalr	1184(ra) # 80004590 <iput>
  end_op();
    800060f8:	fffff097          	auipc	ra,0xfffff
    800060fc:	d30080e7          	jalr	-720(ra) # 80004e28 <end_op>
  return 0;
    80006100:	4781                	li	a5,0
    80006102:	a085                	j	80006162 <sys_link+0x13c>
    end_op();
    80006104:	fffff097          	auipc	ra,0xfffff
    80006108:	d24080e7          	jalr	-732(ra) # 80004e28 <end_op>
    return -1;
    8000610c:	57fd                	li	a5,-1
    8000610e:	a891                	j	80006162 <sys_link+0x13c>
    iunlockput(ip);
    80006110:	8526                	mv	a0,s1
    80006112:	ffffe097          	auipc	ra,0xffffe
    80006116:	526080e7          	jalr	1318(ra) # 80004638 <iunlockput>
    end_op();
    8000611a:	fffff097          	auipc	ra,0xfffff
    8000611e:	d0e080e7          	jalr	-754(ra) # 80004e28 <end_op>
    return -1;
    80006122:	57fd                	li	a5,-1
    80006124:	a83d                	j	80006162 <sys_link+0x13c>
    iunlockput(dp);
    80006126:	854a                	mv	a0,s2
    80006128:	ffffe097          	auipc	ra,0xffffe
    8000612c:	510080e7          	jalr	1296(ra) # 80004638 <iunlockput>
  ilock(ip);
    80006130:	8526                	mv	a0,s1
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	2a4080e7          	jalr	676(ra) # 800043d6 <ilock>
  ip->nlink--;
    8000613a:	04a4d783          	lhu	a5,74(s1)
    8000613e:	37fd                	addiw	a5,a5,-1
    80006140:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006144:	8526                	mv	a0,s1
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	1c6080e7          	jalr	454(ra) # 8000430c <iupdate>
  iunlockput(ip);
    8000614e:	8526                	mv	a0,s1
    80006150:	ffffe097          	auipc	ra,0xffffe
    80006154:	4e8080e7          	jalr	1256(ra) # 80004638 <iunlockput>
  end_op();
    80006158:	fffff097          	auipc	ra,0xfffff
    8000615c:	cd0080e7          	jalr	-816(ra) # 80004e28 <end_op>
  return -1;
    80006160:	57fd                	li	a5,-1
}
    80006162:	853e                	mv	a0,a5
    80006164:	70b2                	ld	ra,296(sp)
    80006166:	7412                	ld	s0,288(sp)
    80006168:	64f2                	ld	s1,280(sp)
    8000616a:	6952                	ld	s2,272(sp)
    8000616c:	6155                	addi	sp,sp,304
    8000616e:	8082                	ret

0000000080006170 <sys_unlink>:
{
    80006170:	7151                	addi	sp,sp,-240
    80006172:	f586                	sd	ra,232(sp)
    80006174:	f1a2                	sd	s0,224(sp)
    80006176:	eda6                	sd	s1,216(sp)
    80006178:	e9ca                	sd	s2,208(sp)
    8000617a:	e5ce                	sd	s3,200(sp)
    8000617c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000617e:	08000613          	li	a2,128
    80006182:	f3040593          	addi	a1,s0,-208
    80006186:	4501                	li	a0,0
    80006188:	ffffd097          	auipc	ra,0xffffd
    8000618c:	518080e7          	jalr	1304(ra) # 800036a0 <argstr>
    80006190:	18054163          	bltz	a0,80006312 <sys_unlink+0x1a2>
  begin_op();
    80006194:	fffff097          	auipc	ra,0xfffff
    80006198:	c14080e7          	jalr	-1004(ra) # 80004da8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000619c:	fb040593          	addi	a1,s0,-80
    800061a0:	f3040513          	addi	a0,s0,-208
    800061a4:	fffff097          	auipc	ra,0xfffff
    800061a8:	a06080e7          	jalr	-1530(ra) # 80004baa <nameiparent>
    800061ac:	84aa                	mv	s1,a0
    800061ae:	c979                	beqz	a0,80006284 <sys_unlink+0x114>
  ilock(dp);
    800061b0:	ffffe097          	auipc	ra,0xffffe
    800061b4:	226080e7          	jalr	550(ra) # 800043d6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800061b8:	00002597          	auipc	a1,0x2
    800061bc:	6e058593          	addi	a1,a1,1760 # 80008898 <syscalls+0x2c0>
    800061c0:	fb040513          	addi	a0,s0,-80
    800061c4:	ffffe097          	auipc	ra,0xffffe
    800061c8:	6dc080e7          	jalr	1756(ra) # 800048a0 <namecmp>
    800061cc:	14050a63          	beqz	a0,80006320 <sys_unlink+0x1b0>
    800061d0:	00002597          	auipc	a1,0x2
    800061d4:	6d058593          	addi	a1,a1,1744 # 800088a0 <syscalls+0x2c8>
    800061d8:	fb040513          	addi	a0,s0,-80
    800061dc:	ffffe097          	auipc	ra,0xffffe
    800061e0:	6c4080e7          	jalr	1732(ra) # 800048a0 <namecmp>
    800061e4:	12050e63          	beqz	a0,80006320 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800061e8:	f2c40613          	addi	a2,s0,-212
    800061ec:	fb040593          	addi	a1,s0,-80
    800061f0:	8526                	mv	a0,s1
    800061f2:	ffffe097          	auipc	ra,0xffffe
    800061f6:	6c8080e7          	jalr	1736(ra) # 800048ba <dirlookup>
    800061fa:	892a                	mv	s2,a0
    800061fc:	12050263          	beqz	a0,80006320 <sys_unlink+0x1b0>
  ilock(ip);
    80006200:	ffffe097          	auipc	ra,0xffffe
    80006204:	1d6080e7          	jalr	470(ra) # 800043d6 <ilock>
  if(ip->nlink < 1)
    80006208:	04a91783          	lh	a5,74(s2)
    8000620c:	08f05263          	blez	a5,80006290 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006210:	04491703          	lh	a4,68(s2)
    80006214:	4785                	li	a5,1
    80006216:	08f70563          	beq	a4,a5,800062a0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000621a:	4641                	li	a2,16
    8000621c:	4581                	li	a1,0
    8000621e:	fc040513          	addi	a0,s0,-64
    80006222:	ffffb097          	auipc	ra,0xffffb
    80006226:	abe080e7          	jalr	-1346(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000622a:	4741                	li	a4,16
    8000622c:	f2c42683          	lw	a3,-212(s0)
    80006230:	fc040613          	addi	a2,s0,-64
    80006234:	4581                	li	a1,0
    80006236:	8526                	mv	a0,s1
    80006238:	ffffe097          	auipc	ra,0xffffe
    8000623c:	54a080e7          	jalr	1354(ra) # 80004782 <writei>
    80006240:	47c1                	li	a5,16
    80006242:	0af51563          	bne	a0,a5,800062ec <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006246:	04491703          	lh	a4,68(s2)
    8000624a:	4785                	li	a5,1
    8000624c:	0af70863          	beq	a4,a5,800062fc <sys_unlink+0x18c>
  iunlockput(dp);
    80006250:	8526                	mv	a0,s1
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	3e6080e7          	jalr	998(ra) # 80004638 <iunlockput>
  ip->nlink--;
    8000625a:	04a95783          	lhu	a5,74(s2)
    8000625e:	37fd                	addiw	a5,a5,-1
    80006260:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006264:	854a                	mv	a0,s2
    80006266:	ffffe097          	auipc	ra,0xffffe
    8000626a:	0a6080e7          	jalr	166(ra) # 8000430c <iupdate>
  iunlockput(ip);
    8000626e:	854a                	mv	a0,s2
    80006270:	ffffe097          	auipc	ra,0xffffe
    80006274:	3c8080e7          	jalr	968(ra) # 80004638 <iunlockput>
  end_op();
    80006278:	fffff097          	auipc	ra,0xfffff
    8000627c:	bb0080e7          	jalr	-1104(ra) # 80004e28 <end_op>
  return 0;
    80006280:	4501                	li	a0,0
    80006282:	a84d                	j	80006334 <sys_unlink+0x1c4>
    end_op();
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	ba4080e7          	jalr	-1116(ra) # 80004e28 <end_op>
    return -1;
    8000628c:	557d                	li	a0,-1
    8000628e:	a05d                	j	80006334 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006290:	00002517          	auipc	a0,0x2
    80006294:	63850513          	addi	a0,a0,1592 # 800088c8 <syscalls+0x2f0>
    80006298:	ffffa097          	auipc	ra,0xffffa
    8000629c:	2a6080e7          	jalr	678(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062a0:	04c92703          	lw	a4,76(s2)
    800062a4:	02000793          	li	a5,32
    800062a8:	f6e7f9e3          	bgeu	a5,a4,8000621a <sys_unlink+0xaa>
    800062ac:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800062b0:	4741                	li	a4,16
    800062b2:	86ce                	mv	a3,s3
    800062b4:	f1840613          	addi	a2,s0,-232
    800062b8:	4581                	li	a1,0
    800062ba:	854a                	mv	a0,s2
    800062bc:	ffffe097          	auipc	ra,0xffffe
    800062c0:	3ce080e7          	jalr	974(ra) # 8000468a <readi>
    800062c4:	47c1                	li	a5,16
    800062c6:	00f51b63          	bne	a0,a5,800062dc <sys_unlink+0x16c>
    if(de.inum != 0)
    800062ca:	f1845783          	lhu	a5,-232(s0)
    800062ce:	e7a1                	bnez	a5,80006316 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062d0:	29c1                	addiw	s3,s3,16
    800062d2:	04c92783          	lw	a5,76(s2)
    800062d6:	fcf9ede3          	bltu	s3,a5,800062b0 <sys_unlink+0x140>
    800062da:	b781                	j	8000621a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800062dc:	00002517          	auipc	a0,0x2
    800062e0:	60450513          	addi	a0,a0,1540 # 800088e0 <syscalls+0x308>
    800062e4:	ffffa097          	auipc	ra,0xffffa
    800062e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
    panic("unlink: writei");
    800062ec:	00002517          	auipc	a0,0x2
    800062f0:	60c50513          	addi	a0,a0,1548 # 800088f8 <syscalls+0x320>
    800062f4:	ffffa097          	auipc	ra,0xffffa
    800062f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
    dp->nlink--;
    800062fc:	04a4d783          	lhu	a5,74(s1)
    80006300:	37fd                	addiw	a5,a5,-1
    80006302:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006306:	8526                	mv	a0,s1
    80006308:	ffffe097          	auipc	ra,0xffffe
    8000630c:	004080e7          	jalr	4(ra) # 8000430c <iupdate>
    80006310:	b781                	j	80006250 <sys_unlink+0xe0>
    return -1;
    80006312:	557d                	li	a0,-1
    80006314:	a005                	j	80006334 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006316:	854a                	mv	a0,s2
    80006318:	ffffe097          	auipc	ra,0xffffe
    8000631c:	320080e7          	jalr	800(ra) # 80004638 <iunlockput>
  iunlockput(dp);
    80006320:	8526                	mv	a0,s1
    80006322:	ffffe097          	auipc	ra,0xffffe
    80006326:	316080e7          	jalr	790(ra) # 80004638 <iunlockput>
  end_op();
    8000632a:	fffff097          	auipc	ra,0xfffff
    8000632e:	afe080e7          	jalr	-1282(ra) # 80004e28 <end_op>
  return -1;
    80006332:	557d                	li	a0,-1
}
    80006334:	70ae                	ld	ra,232(sp)
    80006336:	740e                	ld	s0,224(sp)
    80006338:	64ee                	ld	s1,216(sp)
    8000633a:	694e                	ld	s2,208(sp)
    8000633c:	69ae                	ld	s3,200(sp)
    8000633e:	616d                	addi	sp,sp,240
    80006340:	8082                	ret

0000000080006342 <sys_open>:

uint64
sys_open(void)
{
    80006342:	7131                	addi	sp,sp,-192
    80006344:	fd06                	sd	ra,184(sp)
    80006346:	f922                	sd	s0,176(sp)
    80006348:	f526                	sd	s1,168(sp)
    8000634a:	f14a                	sd	s2,160(sp)
    8000634c:	ed4e                	sd	s3,152(sp)
    8000634e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006350:	08000613          	li	a2,128
    80006354:	f5040593          	addi	a1,s0,-176
    80006358:	4501                	li	a0,0
    8000635a:	ffffd097          	auipc	ra,0xffffd
    8000635e:	346080e7          	jalr	838(ra) # 800036a0 <argstr>
    return -1;
    80006362:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006364:	0c054163          	bltz	a0,80006426 <sys_open+0xe4>
    80006368:	f4c40593          	addi	a1,s0,-180
    8000636c:	4505                	li	a0,1
    8000636e:	ffffd097          	auipc	ra,0xffffd
    80006372:	2ee080e7          	jalr	750(ra) # 8000365c <argint>
    80006376:	0a054863          	bltz	a0,80006426 <sys_open+0xe4>

  begin_op();
    8000637a:	fffff097          	auipc	ra,0xfffff
    8000637e:	a2e080e7          	jalr	-1490(ra) # 80004da8 <begin_op>

  if(omode & O_CREATE){
    80006382:	f4c42783          	lw	a5,-180(s0)
    80006386:	2007f793          	andi	a5,a5,512
    8000638a:	cbdd                	beqz	a5,80006440 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000638c:	4681                	li	a3,0
    8000638e:	4601                	li	a2,0
    80006390:	4589                	li	a1,2
    80006392:	f5040513          	addi	a0,s0,-176
    80006396:	00000097          	auipc	ra,0x0
    8000639a:	972080e7          	jalr	-1678(ra) # 80005d08 <create>
    8000639e:	892a                	mv	s2,a0
    if(ip == 0){
    800063a0:	c959                	beqz	a0,80006436 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800063a2:	04491703          	lh	a4,68(s2)
    800063a6:	478d                	li	a5,3
    800063a8:	00f71763          	bne	a4,a5,800063b6 <sys_open+0x74>
    800063ac:	04695703          	lhu	a4,70(s2)
    800063b0:	47a5                	li	a5,9
    800063b2:	0ce7ec63          	bltu	a5,a4,8000648a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800063b6:	fffff097          	auipc	ra,0xfffff
    800063ba:	e02080e7          	jalr	-510(ra) # 800051b8 <filealloc>
    800063be:	89aa                	mv	s3,a0
    800063c0:	10050263          	beqz	a0,800064c4 <sys_open+0x182>
    800063c4:	00000097          	auipc	ra,0x0
    800063c8:	902080e7          	jalr	-1790(ra) # 80005cc6 <fdalloc>
    800063cc:	84aa                	mv	s1,a0
    800063ce:	0e054663          	bltz	a0,800064ba <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800063d2:	04491703          	lh	a4,68(s2)
    800063d6:	478d                	li	a5,3
    800063d8:	0cf70463          	beq	a4,a5,800064a0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800063dc:	4789                	li	a5,2
    800063de:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800063e2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800063e6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800063ea:	f4c42783          	lw	a5,-180(s0)
    800063ee:	0017c713          	xori	a4,a5,1
    800063f2:	8b05                	andi	a4,a4,1
    800063f4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800063f8:	0037f713          	andi	a4,a5,3
    800063fc:	00e03733          	snez	a4,a4
    80006400:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006404:	4007f793          	andi	a5,a5,1024
    80006408:	c791                	beqz	a5,80006414 <sys_open+0xd2>
    8000640a:	04491703          	lh	a4,68(s2)
    8000640e:	4789                	li	a5,2
    80006410:	08f70f63          	beq	a4,a5,800064ae <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006414:	854a                	mv	a0,s2
    80006416:	ffffe097          	auipc	ra,0xffffe
    8000641a:	082080e7          	jalr	130(ra) # 80004498 <iunlock>
  end_op();
    8000641e:	fffff097          	auipc	ra,0xfffff
    80006422:	a0a080e7          	jalr	-1526(ra) # 80004e28 <end_op>

  return fd;
}
    80006426:	8526                	mv	a0,s1
    80006428:	70ea                	ld	ra,184(sp)
    8000642a:	744a                	ld	s0,176(sp)
    8000642c:	74aa                	ld	s1,168(sp)
    8000642e:	790a                	ld	s2,160(sp)
    80006430:	69ea                	ld	s3,152(sp)
    80006432:	6129                	addi	sp,sp,192
    80006434:	8082                	ret
      end_op();
    80006436:	fffff097          	auipc	ra,0xfffff
    8000643a:	9f2080e7          	jalr	-1550(ra) # 80004e28 <end_op>
      return -1;
    8000643e:	b7e5                	j	80006426 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006440:	f5040513          	addi	a0,s0,-176
    80006444:	ffffe097          	auipc	ra,0xffffe
    80006448:	748080e7          	jalr	1864(ra) # 80004b8c <namei>
    8000644c:	892a                	mv	s2,a0
    8000644e:	c905                	beqz	a0,8000647e <sys_open+0x13c>
    ilock(ip);
    80006450:	ffffe097          	auipc	ra,0xffffe
    80006454:	f86080e7          	jalr	-122(ra) # 800043d6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006458:	04491703          	lh	a4,68(s2)
    8000645c:	4785                	li	a5,1
    8000645e:	f4f712e3          	bne	a4,a5,800063a2 <sys_open+0x60>
    80006462:	f4c42783          	lw	a5,-180(s0)
    80006466:	dba1                	beqz	a5,800063b6 <sys_open+0x74>
      iunlockput(ip);
    80006468:	854a                	mv	a0,s2
    8000646a:	ffffe097          	auipc	ra,0xffffe
    8000646e:	1ce080e7          	jalr	462(ra) # 80004638 <iunlockput>
      end_op();
    80006472:	fffff097          	auipc	ra,0xfffff
    80006476:	9b6080e7          	jalr	-1610(ra) # 80004e28 <end_op>
      return -1;
    8000647a:	54fd                	li	s1,-1
    8000647c:	b76d                	j	80006426 <sys_open+0xe4>
      end_op();
    8000647e:	fffff097          	auipc	ra,0xfffff
    80006482:	9aa080e7          	jalr	-1622(ra) # 80004e28 <end_op>
      return -1;
    80006486:	54fd                	li	s1,-1
    80006488:	bf79                	j	80006426 <sys_open+0xe4>
    iunlockput(ip);
    8000648a:	854a                	mv	a0,s2
    8000648c:	ffffe097          	auipc	ra,0xffffe
    80006490:	1ac080e7          	jalr	428(ra) # 80004638 <iunlockput>
    end_op();
    80006494:	fffff097          	auipc	ra,0xfffff
    80006498:	994080e7          	jalr	-1644(ra) # 80004e28 <end_op>
    return -1;
    8000649c:	54fd                	li	s1,-1
    8000649e:	b761                	j	80006426 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800064a0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800064a4:	04691783          	lh	a5,70(s2)
    800064a8:	02f99223          	sh	a5,36(s3)
    800064ac:	bf2d                	j	800063e6 <sys_open+0xa4>
    itrunc(ip);
    800064ae:	854a                	mv	a0,s2
    800064b0:	ffffe097          	auipc	ra,0xffffe
    800064b4:	034080e7          	jalr	52(ra) # 800044e4 <itrunc>
    800064b8:	bfb1                	j	80006414 <sys_open+0xd2>
      fileclose(f);
    800064ba:	854e                	mv	a0,s3
    800064bc:	fffff097          	auipc	ra,0xfffff
    800064c0:	db8080e7          	jalr	-584(ra) # 80005274 <fileclose>
    iunlockput(ip);
    800064c4:	854a                	mv	a0,s2
    800064c6:	ffffe097          	auipc	ra,0xffffe
    800064ca:	172080e7          	jalr	370(ra) # 80004638 <iunlockput>
    end_op();
    800064ce:	fffff097          	auipc	ra,0xfffff
    800064d2:	95a080e7          	jalr	-1702(ra) # 80004e28 <end_op>
    return -1;
    800064d6:	54fd                	li	s1,-1
    800064d8:	b7b9                	j	80006426 <sys_open+0xe4>

00000000800064da <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800064da:	7175                	addi	sp,sp,-144
    800064dc:	e506                	sd	ra,136(sp)
    800064de:	e122                	sd	s0,128(sp)
    800064e0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800064e2:	fffff097          	auipc	ra,0xfffff
    800064e6:	8c6080e7          	jalr	-1850(ra) # 80004da8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800064ea:	08000613          	li	a2,128
    800064ee:	f7040593          	addi	a1,s0,-144
    800064f2:	4501                	li	a0,0
    800064f4:	ffffd097          	auipc	ra,0xffffd
    800064f8:	1ac080e7          	jalr	428(ra) # 800036a0 <argstr>
    800064fc:	02054963          	bltz	a0,8000652e <sys_mkdir+0x54>
    80006500:	4681                	li	a3,0
    80006502:	4601                	li	a2,0
    80006504:	4585                	li	a1,1
    80006506:	f7040513          	addi	a0,s0,-144
    8000650a:	fffff097          	auipc	ra,0xfffff
    8000650e:	7fe080e7          	jalr	2046(ra) # 80005d08 <create>
    80006512:	cd11                	beqz	a0,8000652e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006514:	ffffe097          	auipc	ra,0xffffe
    80006518:	124080e7          	jalr	292(ra) # 80004638 <iunlockput>
  end_op();
    8000651c:	fffff097          	auipc	ra,0xfffff
    80006520:	90c080e7          	jalr	-1780(ra) # 80004e28 <end_op>
  return 0;
    80006524:	4501                	li	a0,0
}
    80006526:	60aa                	ld	ra,136(sp)
    80006528:	640a                	ld	s0,128(sp)
    8000652a:	6149                	addi	sp,sp,144
    8000652c:	8082                	ret
    end_op();
    8000652e:	fffff097          	auipc	ra,0xfffff
    80006532:	8fa080e7          	jalr	-1798(ra) # 80004e28 <end_op>
    return -1;
    80006536:	557d                	li	a0,-1
    80006538:	b7fd                	j	80006526 <sys_mkdir+0x4c>

000000008000653a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000653a:	7135                	addi	sp,sp,-160
    8000653c:	ed06                	sd	ra,152(sp)
    8000653e:	e922                	sd	s0,144(sp)
    80006540:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006542:	fffff097          	auipc	ra,0xfffff
    80006546:	866080e7          	jalr	-1946(ra) # 80004da8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000654a:	08000613          	li	a2,128
    8000654e:	f7040593          	addi	a1,s0,-144
    80006552:	4501                	li	a0,0
    80006554:	ffffd097          	auipc	ra,0xffffd
    80006558:	14c080e7          	jalr	332(ra) # 800036a0 <argstr>
    8000655c:	04054a63          	bltz	a0,800065b0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006560:	f6c40593          	addi	a1,s0,-148
    80006564:	4505                	li	a0,1
    80006566:	ffffd097          	auipc	ra,0xffffd
    8000656a:	0f6080e7          	jalr	246(ra) # 8000365c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000656e:	04054163          	bltz	a0,800065b0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006572:	f6840593          	addi	a1,s0,-152
    80006576:	4509                	li	a0,2
    80006578:	ffffd097          	auipc	ra,0xffffd
    8000657c:	0e4080e7          	jalr	228(ra) # 8000365c <argint>
     argint(1, &major) < 0 ||
    80006580:	02054863          	bltz	a0,800065b0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006584:	f6841683          	lh	a3,-152(s0)
    80006588:	f6c41603          	lh	a2,-148(s0)
    8000658c:	458d                	li	a1,3
    8000658e:	f7040513          	addi	a0,s0,-144
    80006592:	fffff097          	auipc	ra,0xfffff
    80006596:	776080e7          	jalr	1910(ra) # 80005d08 <create>
     argint(2, &minor) < 0 ||
    8000659a:	c919                	beqz	a0,800065b0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000659c:	ffffe097          	auipc	ra,0xffffe
    800065a0:	09c080e7          	jalr	156(ra) # 80004638 <iunlockput>
  end_op();
    800065a4:	fffff097          	auipc	ra,0xfffff
    800065a8:	884080e7          	jalr	-1916(ra) # 80004e28 <end_op>
  return 0;
    800065ac:	4501                	li	a0,0
    800065ae:	a031                	j	800065ba <sys_mknod+0x80>
    end_op();
    800065b0:	fffff097          	auipc	ra,0xfffff
    800065b4:	878080e7          	jalr	-1928(ra) # 80004e28 <end_op>
    return -1;
    800065b8:	557d                	li	a0,-1
}
    800065ba:	60ea                	ld	ra,152(sp)
    800065bc:	644a                	ld	s0,144(sp)
    800065be:	610d                	addi	sp,sp,160
    800065c0:	8082                	ret

00000000800065c2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800065c2:	7135                	addi	sp,sp,-160
    800065c4:	ed06                	sd	ra,152(sp)
    800065c6:	e922                	sd	s0,144(sp)
    800065c8:	e526                	sd	s1,136(sp)
    800065ca:	e14a                	sd	s2,128(sp)
    800065cc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800065ce:	ffffb097          	auipc	ra,0xffffb
    800065d2:	3ea080e7          	jalr	1002(ra) # 800019b8 <myproc>
    800065d6:	892a                	mv	s2,a0
  
  begin_op();
    800065d8:	ffffe097          	auipc	ra,0xffffe
    800065dc:	7d0080e7          	jalr	2000(ra) # 80004da8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800065e0:	08000613          	li	a2,128
    800065e4:	f6040593          	addi	a1,s0,-160
    800065e8:	4501                	li	a0,0
    800065ea:	ffffd097          	auipc	ra,0xffffd
    800065ee:	0b6080e7          	jalr	182(ra) # 800036a0 <argstr>
    800065f2:	04054b63          	bltz	a0,80006648 <sys_chdir+0x86>
    800065f6:	f6040513          	addi	a0,s0,-160
    800065fa:	ffffe097          	auipc	ra,0xffffe
    800065fe:	592080e7          	jalr	1426(ra) # 80004b8c <namei>
    80006602:	84aa                	mv	s1,a0
    80006604:	c131                	beqz	a0,80006648 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006606:	ffffe097          	auipc	ra,0xffffe
    8000660a:	dd0080e7          	jalr	-560(ra) # 800043d6 <ilock>
  if(ip->type != T_DIR){
    8000660e:	04449703          	lh	a4,68(s1)
    80006612:	4785                	li	a5,1
    80006614:	04f71063          	bne	a4,a5,80006654 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006618:	8526                	mv	a0,s1
    8000661a:	ffffe097          	auipc	ra,0xffffe
    8000661e:	e7e080e7          	jalr	-386(ra) # 80004498 <iunlock>
  iput(p->cwd);
    80006622:	17093503          	ld	a0,368(s2)
    80006626:	ffffe097          	auipc	ra,0xffffe
    8000662a:	f6a080e7          	jalr	-150(ra) # 80004590 <iput>
  end_op();
    8000662e:	ffffe097          	auipc	ra,0xffffe
    80006632:	7fa080e7          	jalr	2042(ra) # 80004e28 <end_op>
  p->cwd = ip;
    80006636:	16993823          	sd	s1,368(s2)
  return 0;
    8000663a:	4501                	li	a0,0
}
    8000663c:	60ea                	ld	ra,152(sp)
    8000663e:	644a                	ld	s0,144(sp)
    80006640:	64aa                	ld	s1,136(sp)
    80006642:	690a                	ld	s2,128(sp)
    80006644:	610d                	addi	sp,sp,160
    80006646:	8082                	ret
    end_op();
    80006648:	ffffe097          	auipc	ra,0xffffe
    8000664c:	7e0080e7          	jalr	2016(ra) # 80004e28 <end_op>
    return -1;
    80006650:	557d                	li	a0,-1
    80006652:	b7ed                	j	8000663c <sys_chdir+0x7a>
    iunlockput(ip);
    80006654:	8526                	mv	a0,s1
    80006656:	ffffe097          	auipc	ra,0xffffe
    8000665a:	fe2080e7          	jalr	-30(ra) # 80004638 <iunlockput>
    end_op();
    8000665e:	ffffe097          	auipc	ra,0xffffe
    80006662:	7ca080e7          	jalr	1994(ra) # 80004e28 <end_op>
    return -1;
    80006666:	557d                	li	a0,-1
    80006668:	bfd1                	j	8000663c <sys_chdir+0x7a>

000000008000666a <sys_exec>:

uint64
sys_exec(void)
{
    8000666a:	7145                	addi	sp,sp,-464
    8000666c:	e786                	sd	ra,456(sp)
    8000666e:	e3a2                	sd	s0,448(sp)
    80006670:	ff26                	sd	s1,440(sp)
    80006672:	fb4a                	sd	s2,432(sp)
    80006674:	f74e                	sd	s3,424(sp)
    80006676:	f352                	sd	s4,416(sp)
    80006678:	ef56                	sd	s5,408(sp)
    8000667a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000667c:	08000613          	li	a2,128
    80006680:	f4040593          	addi	a1,s0,-192
    80006684:	4501                	li	a0,0
    80006686:	ffffd097          	auipc	ra,0xffffd
    8000668a:	01a080e7          	jalr	26(ra) # 800036a0 <argstr>
    return -1;
    8000668e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006690:	0c054a63          	bltz	a0,80006764 <sys_exec+0xfa>
    80006694:	e3840593          	addi	a1,s0,-456
    80006698:	4505                	li	a0,1
    8000669a:	ffffd097          	auipc	ra,0xffffd
    8000669e:	fe4080e7          	jalr	-28(ra) # 8000367e <argaddr>
    800066a2:	0c054163          	bltz	a0,80006764 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800066a6:	10000613          	li	a2,256
    800066aa:	4581                	li	a1,0
    800066ac:	e4040513          	addi	a0,s0,-448
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	630080e7          	jalr	1584(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800066b8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800066bc:	89a6                	mv	s3,s1
    800066be:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800066c0:	02000a13          	li	s4,32
    800066c4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800066c8:	00391513          	slli	a0,s2,0x3
    800066cc:	e3040593          	addi	a1,s0,-464
    800066d0:	e3843783          	ld	a5,-456(s0)
    800066d4:	953e                	add	a0,a0,a5
    800066d6:	ffffd097          	auipc	ra,0xffffd
    800066da:	eec080e7          	jalr	-276(ra) # 800035c2 <fetchaddr>
    800066de:	02054a63          	bltz	a0,80006712 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800066e2:	e3043783          	ld	a5,-464(s0)
    800066e6:	c3b9                	beqz	a5,8000672c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800066e8:	ffffa097          	auipc	ra,0xffffa
    800066ec:	40c080e7          	jalr	1036(ra) # 80000af4 <kalloc>
    800066f0:	85aa                	mv	a1,a0
    800066f2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800066f6:	cd11                	beqz	a0,80006712 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800066f8:	6605                	lui	a2,0x1
    800066fa:	e3043503          	ld	a0,-464(s0)
    800066fe:	ffffd097          	auipc	ra,0xffffd
    80006702:	f16080e7          	jalr	-234(ra) # 80003614 <fetchstr>
    80006706:	00054663          	bltz	a0,80006712 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000670a:	0905                	addi	s2,s2,1
    8000670c:	09a1                	addi	s3,s3,8
    8000670e:	fb491be3          	bne	s2,s4,800066c4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006712:	10048913          	addi	s2,s1,256
    80006716:	6088                	ld	a0,0(s1)
    80006718:	c529                	beqz	a0,80006762 <sys_exec+0xf8>
    kfree(argv[i]);
    8000671a:	ffffa097          	auipc	ra,0xffffa
    8000671e:	2de080e7          	jalr	734(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006722:	04a1                	addi	s1,s1,8
    80006724:	ff2499e3          	bne	s1,s2,80006716 <sys_exec+0xac>
  return -1;
    80006728:	597d                	li	s2,-1
    8000672a:	a82d                	j	80006764 <sys_exec+0xfa>
      argv[i] = 0;
    8000672c:	0a8e                	slli	s5,s5,0x3
    8000672e:	fc040793          	addi	a5,s0,-64
    80006732:	9abe                	add	s5,s5,a5
    80006734:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006738:	e4040593          	addi	a1,s0,-448
    8000673c:	f4040513          	addi	a0,s0,-192
    80006740:	fffff097          	auipc	ra,0xfffff
    80006744:	194080e7          	jalr	404(ra) # 800058d4 <exec>
    80006748:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000674a:	10048993          	addi	s3,s1,256
    8000674e:	6088                	ld	a0,0(s1)
    80006750:	c911                	beqz	a0,80006764 <sys_exec+0xfa>
    kfree(argv[i]);
    80006752:	ffffa097          	auipc	ra,0xffffa
    80006756:	2a6080e7          	jalr	678(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000675a:	04a1                	addi	s1,s1,8
    8000675c:	ff3499e3          	bne	s1,s3,8000674e <sys_exec+0xe4>
    80006760:	a011                	j	80006764 <sys_exec+0xfa>
  return -1;
    80006762:	597d                	li	s2,-1
}
    80006764:	854a                	mv	a0,s2
    80006766:	60be                	ld	ra,456(sp)
    80006768:	641e                	ld	s0,448(sp)
    8000676a:	74fa                	ld	s1,440(sp)
    8000676c:	795a                	ld	s2,432(sp)
    8000676e:	79ba                	ld	s3,424(sp)
    80006770:	7a1a                	ld	s4,416(sp)
    80006772:	6afa                	ld	s5,408(sp)
    80006774:	6179                	addi	sp,sp,464
    80006776:	8082                	ret

0000000080006778 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006778:	7139                	addi	sp,sp,-64
    8000677a:	fc06                	sd	ra,56(sp)
    8000677c:	f822                	sd	s0,48(sp)
    8000677e:	f426                	sd	s1,40(sp)
    80006780:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006782:	ffffb097          	auipc	ra,0xffffb
    80006786:	236080e7          	jalr	566(ra) # 800019b8 <myproc>
    8000678a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000678c:	fd840593          	addi	a1,s0,-40
    80006790:	4501                	li	a0,0
    80006792:	ffffd097          	auipc	ra,0xffffd
    80006796:	eec080e7          	jalr	-276(ra) # 8000367e <argaddr>
    return -1;
    8000679a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000679c:	0e054063          	bltz	a0,8000687c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800067a0:	fc840593          	addi	a1,s0,-56
    800067a4:	fd040513          	addi	a0,s0,-48
    800067a8:	fffff097          	auipc	ra,0xfffff
    800067ac:	dfc080e7          	jalr	-516(ra) # 800055a4 <pipealloc>
    return -1;
    800067b0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800067b2:	0c054563          	bltz	a0,8000687c <sys_pipe+0x104>
  fd0 = -1;
    800067b6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800067ba:	fd043503          	ld	a0,-48(s0)
    800067be:	fffff097          	auipc	ra,0xfffff
    800067c2:	508080e7          	jalr	1288(ra) # 80005cc6 <fdalloc>
    800067c6:	fca42223          	sw	a0,-60(s0)
    800067ca:	08054c63          	bltz	a0,80006862 <sys_pipe+0xea>
    800067ce:	fc843503          	ld	a0,-56(s0)
    800067d2:	fffff097          	auipc	ra,0xfffff
    800067d6:	4f4080e7          	jalr	1268(ra) # 80005cc6 <fdalloc>
    800067da:	fca42023          	sw	a0,-64(s0)
    800067de:	06054863          	bltz	a0,8000684e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067e2:	4691                	li	a3,4
    800067e4:	fc440613          	addi	a2,s0,-60
    800067e8:	fd843583          	ld	a1,-40(s0)
    800067ec:	78a8                	ld	a0,112(s1)
    800067ee:	ffffb097          	auipc	ra,0xffffb
    800067f2:	e8c080e7          	jalr	-372(ra) # 8000167a <copyout>
    800067f6:	02054063          	bltz	a0,80006816 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800067fa:	4691                	li	a3,4
    800067fc:	fc040613          	addi	a2,s0,-64
    80006800:	fd843583          	ld	a1,-40(s0)
    80006804:	0591                	addi	a1,a1,4
    80006806:	78a8                	ld	a0,112(s1)
    80006808:	ffffb097          	auipc	ra,0xffffb
    8000680c:	e72080e7          	jalr	-398(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006810:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006812:	06055563          	bgez	a0,8000687c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006816:	fc442783          	lw	a5,-60(s0)
    8000681a:	07f9                	addi	a5,a5,30
    8000681c:	078e                	slli	a5,a5,0x3
    8000681e:	97a6                	add	a5,a5,s1
    80006820:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006824:	fc042503          	lw	a0,-64(s0)
    80006828:	0579                	addi	a0,a0,30
    8000682a:	050e                	slli	a0,a0,0x3
    8000682c:	9526                	add	a0,a0,s1
    8000682e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006832:	fd043503          	ld	a0,-48(s0)
    80006836:	fffff097          	auipc	ra,0xfffff
    8000683a:	a3e080e7          	jalr	-1474(ra) # 80005274 <fileclose>
    fileclose(wf);
    8000683e:	fc843503          	ld	a0,-56(s0)
    80006842:	fffff097          	auipc	ra,0xfffff
    80006846:	a32080e7          	jalr	-1486(ra) # 80005274 <fileclose>
    return -1;
    8000684a:	57fd                	li	a5,-1
    8000684c:	a805                	j	8000687c <sys_pipe+0x104>
    if(fd0 >= 0)
    8000684e:	fc442783          	lw	a5,-60(s0)
    80006852:	0007c863          	bltz	a5,80006862 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006856:	01e78513          	addi	a0,a5,30
    8000685a:	050e                	slli	a0,a0,0x3
    8000685c:	9526                	add	a0,a0,s1
    8000685e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006862:	fd043503          	ld	a0,-48(s0)
    80006866:	fffff097          	auipc	ra,0xfffff
    8000686a:	a0e080e7          	jalr	-1522(ra) # 80005274 <fileclose>
    fileclose(wf);
    8000686e:	fc843503          	ld	a0,-56(s0)
    80006872:	fffff097          	auipc	ra,0xfffff
    80006876:	a02080e7          	jalr	-1534(ra) # 80005274 <fileclose>
    return -1;
    8000687a:	57fd                	li	a5,-1
}
    8000687c:	853e                	mv	a0,a5
    8000687e:	70e2                	ld	ra,56(sp)
    80006880:	7442                	ld	s0,48(sp)
    80006882:	74a2                	ld	s1,40(sp)
    80006884:	6121                	addi	sp,sp,64
    80006886:	8082                	ret
	...

0000000080006890 <kernelvec>:
    80006890:	7111                	addi	sp,sp,-256
    80006892:	e006                	sd	ra,0(sp)
    80006894:	e40a                	sd	sp,8(sp)
    80006896:	e80e                	sd	gp,16(sp)
    80006898:	ec12                	sd	tp,24(sp)
    8000689a:	f016                	sd	t0,32(sp)
    8000689c:	f41a                	sd	t1,40(sp)
    8000689e:	f81e                	sd	t2,48(sp)
    800068a0:	fc22                	sd	s0,56(sp)
    800068a2:	e0a6                	sd	s1,64(sp)
    800068a4:	e4aa                	sd	a0,72(sp)
    800068a6:	e8ae                	sd	a1,80(sp)
    800068a8:	ecb2                	sd	a2,88(sp)
    800068aa:	f0b6                	sd	a3,96(sp)
    800068ac:	f4ba                	sd	a4,104(sp)
    800068ae:	f8be                	sd	a5,112(sp)
    800068b0:	fcc2                	sd	a6,120(sp)
    800068b2:	e146                	sd	a7,128(sp)
    800068b4:	e54a                	sd	s2,136(sp)
    800068b6:	e94e                	sd	s3,144(sp)
    800068b8:	ed52                	sd	s4,152(sp)
    800068ba:	f156                	sd	s5,160(sp)
    800068bc:	f55a                	sd	s6,168(sp)
    800068be:	f95e                	sd	s7,176(sp)
    800068c0:	fd62                	sd	s8,184(sp)
    800068c2:	e1e6                	sd	s9,192(sp)
    800068c4:	e5ea                	sd	s10,200(sp)
    800068c6:	e9ee                	sd	s11,208(sp)
    800068c8:	edf2                	sd	t3,216(sp)
    800068ca:	f1f6                	sd	t4,224(sp)
    800068cc:	f5fa                	sd	t5,232(sp)
    800068ce:	f9fe                	sd	t6,240(sp)
    800068d0:	b67fc0ef          	jal	ra,80003436 <kerneltrap>
    800068d4:	6082                	ld	ra,0(sp)
    800068d6:	6122                	ld	sp,8(sp)
    800068d8:	61c2                	ld	gp,16(sp)
    800068da:	7282                	ld	t0,32(sp)
    800068dc:	7322                	ld	t1,40(sp)
    800068de:	73c2                	ld	t2,48(sp)
    800068e0:	7462                	ld	s0,56(sp)
    800068e2:	6486                	ld	s1,64(sp)
    800068e4:	6526                	ld	a0,72(sp)
    800068e6:	65c6                	ld	a1,80(sp)
    800068e8:	6666                	ld	a2,88(sp)
    800068ea:	7686                	ld	a3,96(sp)
    800068ec:	7726                	ld	a4,104(sp)
    800068ee:	77c6                	ld	a5,112(sp)
    800068f0:	7866                	ld	a6,120(sp)
    800068f2:	688a                	ld	a7,128(sp)
    800068f4:	692a                	ld	s2,136(sp)
    800068f6:	69ca                	ld	s3,144(sp)
    800068f8:	6a6a                	ld	s4,152(sp)
    800068fa:	7a8a                	ld	s5,160(sp)
    800068fc:	7b2a                	ld	s6,168(sp)
    800068fe:	7bca                	ld	s7,176(sp)
    80006900:	7c6a                	ld	s8,184(sp)
    80006902:	6c8e                	ld	s9,192(sp)
    80006904:	6d2e                	ld	s10,200(sp)
    80006906:	6dce                	ld	s11,208(sp)
    80006908:	6e6e                	ld	t3,216(sp)
    8000690a:	7e8e                	ld	t4,224(sp)
    8000690c:	7f2e                	ld	t5,232(sp)
    8000690e:	7fce                	ld	t6,240(sp)
    80006910:	6111                	addi	sp,sp,256
    80006912:	10200073          	sret
    80006916:	00000013          	nop
    8000691a:	00000013          	nop
    8000691e:	0001                	nop

0000000080006920 <timervec>:
    80006920:	34051573          	csrrw	a0,mscratch,a0
    80006924:	e10c                	sd	a1,0(a0)
    80006926:	e510                	sd	a2,8(a0)
    80006928:	e914                	sd	a3,16(a0)
    8000692a:	6d0c                	ld	a1,24(a0)
    8000692c:	7110                	ld	a2,32(a0)
    8000692e:	6194                	ld	a3,0(a1)
    80006930:	96b2                	add	a3,a3,a2
    80006932:	e194                	sd	a3,0(a1)
    80006934:	4589                	li	a1,2
    80006936:	14459073          	csrw	sip,a1
    8000693a:	6914                	ld	a3,16(a0)
    8000693c:	6510                	ld	a2,8(a0)
    8000693e:	610c                	ld	a1,0(a0)
    80006940:	34051573          	csrrw	a0,mscratch,a0
    80006944:	30200073          	mret
	...

000000008000694a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000694a:	1141                	addi	sp,sp,-16
    8000694c:	e422                	sd	s0,8(sp)
    8000694e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006950:	0c0007b7          	lui	a5,0xc000
    80006954:	4705                	li	a4,1
    80006956:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006958:	c3d8                	sw	a4,4(a5)
}
    8000695a:	6422                	ld	s0,8(sp)
    8000695c:	0141                	addi	sp,sp,16
    8000695e:	8082                	ret

0000000080006960 <plicinithart>:

void
plicinithart(void)
{
    80006960:	1141                	addi	sp,sp,-16
    80006962:	e406                	sd	ra,8(sp)
    80006964:	e022                	sd	s0,0(sp)
    80006966:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006968:	ffffb097          	auipc	ra,0xffffb
    8000696c:	024080e7          	jalr	36(ra) # 8000198c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006970:	0085171b          	slliw	a4,a0,0x8
    80006974:	0c0027b7          	lui	a5,0xc002
    80006978:	97ba                	add	a5,a5,a4
    8000697a:	40200713          	li	a4,1026
    8000697e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006982:	00d5151b          	slliw	a0,a0,0xd
    80006986:	0c2017b7          	lui	a5,0xc201
    8000698a:	953e                	add	a0,a0,a5
    8000698c:	00052023          	sw	zero,0(a0)
}
    80006990:	60a2                	ld	ra,8(sp)
    80006992:	6402                	ld	s0,0(sp)
    80006994:	0141                	addi	sp,sp,16
    80006996:	8082                	ret

0000000080006998 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006998:	1141                	addi	sp,sp,-16
    8000699a:	e406                	sd	ra,8(sp)
    8000699c:	e022                	sd	s0,0(sp)
    8000699e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800069a0:	ffffb097          	auipc	ra,0xffffb
    800069a4:	fec080e7          	jalr	-20(ra) # 8000198c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800069a8:	00d5179b          	slliw	a5,a0,0xd
    800069ac:	0c201537          	lui	a0,0xc201
    800069b0:	953e                	add	a0,a0,a5
  return irq;
}
    800069b2:	4148                	lw	a0,4(a0)
    800069b4:	60a2                	ld	ra,8(sp)
    800069b6:	6402                	ld	s0,0(sp)
    800069b8:	0141                	addi	sp,sp,16
    800069ba:	8082                	ret

00000000800069bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800069bc:	1101                	addi	sp,sp,-32
    800069be:	ec06                	sd	ra,24(sp)
    800069c0:	e822                	sd	s0,16(sp)
    800069c2:	e426                	sd	s1,8(sp)
    800069c4:	1000                	addi	s0,sp,32
    800069c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800069c8:	ffffb097          	auipc	ra,0xffffb
    800069cc:	fc4080e7          	jalr	-60(ra) # 8000198c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800069d0:	00d5151b          	slliw	a0,a0,0xd
    800069d4:	0c2017b7          	lui	a5,0xc201
    800069d8:	97aa                	add	a5,a5,a0
    800069da:	c3c4                	sw	s1,4(a5)
}
    800069dc:	60e2                	ld	ra,24(sp)
    800069de:	6442                	ld	s0,16(sp)
    800069e0:	64a2                	ld	s1,8(sp)
    800069e2:	6105                	addi	sp,sp,32
    800069e4:	8082                	ret

00000000800069e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800069e6:	1141                	addi	sp,sp,-16
    800069e8:	e406                	sd	ra,8(sp)
    800069ea:	e022                	sd	s0,0(sp)
    800069ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800069ee:	479d                	li	a5,7
    800069f0:	06a7c963          	blt	a5,a0,80006a62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800069f4:	0001e797          	auipc	a5,0x1e
    800069f8:	60c78793          	addi	a5,a5,1548 # 80025000 <disk>
    800069fc:	00a78733          	add	a4,a5,a0
    80006a00:	6789                	lui	a5,0x2
    80006a02:	97ba                	add	a5,a5,a4
    80006a04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006a08:	e7ad                	bnez	a5,80006a72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006a0a:	00451793          	slli	a5,a0,0x4
    80006a0e:	00020717          	auipc	a4,0x20
    80006a12:	5f270713          	addi	a4,a4,1522 # 80027000 <disk+0x2000>
    80006a16:	6314                	ld	a3,0(a4)
    80006a18:	96be                	add	a3,a3,a5
    80006a1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006a1e:	6314                	ld	a3,0(a4)
    80006a20:	96be                	add	a3,a3,a5
    80006a22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006a26:	6314                	ld	a3,0(a4)
    80006a28:	96be                	add	a3,a3,a5
    80006a2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006a2e:	6318                	ld	a4,0(a4)
    80006a30:	97ba                	add	a5,a5,a4
    80006a32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006a36:	0001e797          	auipc	a5,0x1e
    80006a3a:	5ca78793          	addi	a5,a5,1482 # 80025000 <disk>
    80006a3e:	97aa                	add	a5,a5,a0
    80006a40:	6509                	lui	a0,0x2
    80006a42:	953e                	add	a0,a0,a5
    80006a44:	4785                	li	a5,1
    80006a46:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006a4a:	00020517          	auipc	a0,0x20
    80006a4e:	5ce50513          	addi	a0,a0,1486 # 80027018 <disk+0x2018>
    80006a52:	ffffc097          	auipc	ra,0xffffc
    80006a56:	e3c080e7          	jalr	-452(ra) # 8000288e <wakeup>
}
    80006a5a:	60a2                	ld	ra,8(sp)
    80006a5c:	6402                	ld	s0,0(sp)
    80006a5e:	0141                	addi	sp,sp,16
    80006a60:	8082                	ret
    panic("free_desc 1");
    80006a62:	00002517          	auipc	a0,0x2
    80006a66:	ea650513          	addi	a0,a0,-346 # 80008908 <syscalls+0x330>
    80006a6a:	ffffa097          	auipc	ra,0xffffa
    80006a6e:	ad4080e7          	jalr	-1324(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006a72:	00002517          	auipc	a0,0x2
    80006a76:	ea650513          	addi	a0,a0,-346 # 80008918 <syscalls+0x340>
    80006a7a:	ffffa097          	auipc	ra,0xffffa
    80006a7e:	ac4080e7          	jalr	-1340(ra) # 8000053e <panic>

0000000080006a82 <virtio_disk_init>:
{
    80006a82:	1101                	addi	sp,sp,-32
    80006a84:	ec06                	sd	ra,24(sp)
    80006a86:	e822                	sd	s0,16(sp)
    80006a88:	e426                	sd	s1,8(sp)
    80006a8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a8c:	00002597          	auipc	a1,0x2
    80006a90:	e9c58593          	addi	a1,a1,-356 # 80008928 <syscalls+0x350>
    80006a94:	00020517          	auipc	a0,0x20
    80006a98:	69450513          	addi	a0,a0,1684 # 80027128 <disk+0x2128>
    80006a9c:	ffffa097          	auipc	ra,0xffffa
    80006aa0:	0b8080e7          	jalr	184(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006aa4:	100017b7          	lui	a5,0x10001
    80006aa8:	4398                	lw	a4,0(a5)
    80006aaa:	2701                	sext.w	a4,a4
    80006aac:	747277b7          	lui	a5,0x74727
    80006ab0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006ab4:	0ef71163          	bne	a4,a5,80006b96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006ab8:	100017b7          	lui	a5,0x10001
    80006abc:	43dc                	lw	a5,4(a5)
    80006abe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006ac0:	4705                	li	a4,1
    80006ac2:	0ce79a63          	bne	a5,a4,80006b96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006ac6:	100017b7          	lui	a5,0x10001
    80006aca:	479c                	lw	a5,8(a5)
    80006acc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006ace:	4709                	li	a4,2
    80006ad0:	0ce79363          	bne	a5,a4,80006b96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006ad4:	100017b7          	lui	a5,0x10001
    80006ad8:	47d8                	lw	a4,12(a5)
    80006ada:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006adc:	554d47b7          	lui	a5,0x554d4
    80006ae0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006ae4:	0af71963          	bne	a4,a5,80006b96 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ae8:	100017b7          	lui	a5,0x10001
    80006aec:	4705                	li	a4,1
    80006aee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006af0:	470d                	li	a4,3
    80006af2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006af4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006af6:	c7ffe737          	lui	a4,0xc7ffe
    80006afa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    80006afe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006b00:	2701                	sext.w	a4,a4
    80006b02:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b04:	472d                	li	a4,11
    80006b06:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b08:	473d                	li	a4,15
    80006b0a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006b0c:	6705                	lui	a4,0x1
    80006b0e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006b10:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006b14:	5bdc                	lw	a5,52(a5)
    80006b16:	2781                	sext.w	a5,a5
  if(max == 0)
    80006b18:	c7d9                	beqz	a5,80006ba6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006b1a:	471d                	li	a4,7
    80006b1c:	08f77d63          	bgeu	a4,a5,80006bb6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b20:	100014b7          	lui	s1,0x10001
    80006b24:	47a1                	li	a5,8
    80006b26:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006b28:	6609                	lui	a2,0x2
    80006b2a:	4581                	li	a1,0
    80006b2c:	0001e517          	auipc	a0,0x1e
    80006b30:	4d450513          	addi	a0,a0,1236 # 80025000 <disk>
    80006b34:	ffffa097          	auipc	ra,0xffffa
    80006b38:	1ac080e7          	jalr	428(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006b3c:	0001e717          	auipc	a4,0x1e
    80006b40:	4c470713          	addi	a4,a4,1220 # 80025000 <disk>
    80006b44:	00c75793          	srli	a5,a4,0xc
    80006b48:	2781                	sext.w	a5,a5
    80006b4a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006b4c:	00020797          	auipc	a5,0x20
    80006b50:	4b478793          	addi	a5,a5,1204 # 80027000 <disk+0x2000>
    80006b54:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006b56:	0001e717          	auipc	a4,0x1e
    80006b5a:	52a70713          	addi	a4,a4,1322 # 80025080 <disk+0x80>
    80006b5e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006b60:	0001f717          	auipc	a4,0x1f
    80006b64:	4a070713          	addi	a4,a4,1184 # 80026000 <disk+0x1000>
    80006b68:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006b6a:	4705                	li	a4,1
    80006b6c:	00e78c23          	sb	a4,24(a5)
    80006b70:	00e78ca3          	sb	a4,25(a5)
    80006b74:	00e78d23          	sb	a4,26(a5)
    80006b78:	00e78da3          	sb	a4,27(a5)
    80006b7c:	00e78e23          	sb	a4,28(a5)
    80006b80:	00e78ea3          	sb	a4,29(a5)
    80006b84:	00e78f23          	sb	a4,30(a5)
    80006b88:	00e78fa3          	sb	a4,31(a5)
}
    80006b8c:	60e2                	ld	ra,24(sp)
    80006b8e:	6442                	ld	s0,16(sp)
    80006b90:	64a2                	ld	s1,8(sp)
    80006b92:	6105                	addi	sp,sp,32
    80006b94:	8082                	ret
    panic("could not find virtio disk");
    80006b96:	00002517          	auipc	a0,0x2
    80006b9a:	da250513          	addi	a0,a0,-606 # 80008938 <syscalls+0x360>
    80006b9e:	ffffa097          	auipc	ra,0xffffa
    80006ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006ba6:	00002517          	auipc	a0,0x2
    80006baa:	db250513          	addi	a0,a0,-590 # 80008958 <syscalls+0x380>
    80006bae:	ffffa097          	auipc	ra,0xffffa
    80006bb2:	990080e7          	jalr	-1648(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006bb6:	00002517          	auipc	a0,0x2
    80006bba:	dc250513          	addi	a0,a0,-574 # 80008978 <syscalls+0x3a0>
    80006bbe:	ffffa097          	auipc	ra,0xffffa
    80006bc2:	980080e7          	jalr	-1664(ra) # 8000053e <panic>

0000000080006bc6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006bc6:	7159                	addi	sp,sp,-112
    80006bc8:	f486                	sd	ra,104(sp)
    80006bca:	f0a2                	sd	s0,96(sp)
    80006bcc:	eca6                	sd	s1,88(sp)
    80006bce:	e8ca                	sd	s2,80(sp)
    80006bd0:	e4ce                	sd	s3,72(sp)
    80006bd2:	e0d2                	sd	s4,64(sp)
    80006bd4:	fc56                	sd	s5,56(sp)
    80006bd6:	f85a                	sd	s6,48(sp)
    80006bd8:	f45e                	sd	s7,40(sp)
    80006bda:	f062                	sd	s8,32(sp)
    80006bdc:	ec66                	sd	s9,24(sp)
    80006bde:	e86a                	sd	s10,16(sp)
    80006be0:	1880                	addi	s0,sp,112
    80006be2:	892a                	mv	s2,a0
    80006be4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006be6:	00c52c83          	lw	s9,12(a0)
    80006bea:	001c9c9b          	slliw	s9,s9,0x1
    80006bee:	1c82                	slli	s9,s9,0x20
    80006bf0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006bf4:	00020517          	auipc	a0,0x20
    80006bf8:	53450513          	addi	a0,a0,1332 # 80027128 <disk+0x2128>
    80006bfc:	ffffa097          	auipc	ra,0xffffa
    80006c00:	fe8080e7          	jalr	-24(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006c04:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006c06:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006c08:	0001eb97          	auipc	s7,0x1e
    80006c0c:	3f8b8b93          	addi	s7,s7,1016 # 80025000 <disk>
    80006c10:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006c12:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006c14:	8a4e                	mv	s4,s3
    80006c16:	a051                	j	80006c9a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006c18:	00fb86b3          	add	a3,s7,a5
    80006c1c:	96da                	add	a3,a3,s6
    80006c1e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006c22:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006c24:	0207c563          	bltz	a5,80006c4e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006c28:	2485                	addiw	s1,s1,1
    80006c2a:	0711                	addi	a4,a4,4
    80006c2c:	25548063          	beq	s1,s5,80006e6c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006c30:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006c32:	00020697          	auipc	a3,0x20
    80006c36:	3e668693          	addi	a3,a3,998 # 80027018 <disk+0x2018>
    80006c3a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006c3c:	0006c583          	lbu	a1,0(a3)
    80006c40:	fde1                	bnez	a1,80006c18 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006c42:	2785                	addiw	a5,a5,1
    80006c44:	0685                	addi	a3,a3,1
    80006c46:	ff879be3          	bne	a5,s8,80006c3c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006c4a:	57fd                	li	a5,-1
    80006c4c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006c4e:	02905a63          	blez	s1,80006c82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006c52:	f9042503          	lw	a0,-112(s0)
    80006c56:	00000097          	auipc	ra,0x0
    80006c5a:	d90080e7          	jalr	-624(ra) # 800069e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006c5e:	4785                	li	a5,1
    80006c60:	0297d163          	bge	a5,s1,80006c82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006c64:	f9442503          	lw	a0,-108(s0)
    80006c68:	00000097          	auipc	ra,0x0
    80006c6c:	d7e080e7          	jalr	-642(ra) # 800069e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006c70:	4789                	li	a5,2
    80006c72:	0097d863          	bge	a5,s1,80006c82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006c76:	f9842503          	lw	a0,-104(s0)
    80006c7a:	00000097          	auipc	ra,0x0
    80006c7e:	d6c080e7          	jalr	-660(ra) # 800069e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c82:	00020597          	auipc	a1,0x20
    80006c86:	4a658593          	addi	a1,a1,1190 # 80027128 <disk+0x2128>
    80006c8a:	00020517          	auipc	a0,0x20
    80006c8e:	38e50513          	addi	a0,a0,910 # 80027018 <disk+0x2018>
    80006c92:	ffffc097          	auipc	ra,0xffffc
    80006c96:	a70080e7          	jalr	-1424(ra) # 80002702 <sleep>
  for(int i = 0; i < 3; i++){
    80006c9a:	f9040713          	addi	a4,s0,-112
    80006c9e:	84ce                	mv	s1,s3
    80006ca0:	bf41                	j	80006c30 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006ca2:	20058713          	addi	a4,a1,512
    80006ca6:	00471693          	slli	a3,a4,0x4
    80006caa:	0001e717          	auipc	a4,0x1e
    80006cae:	35670713          	addi	a4,a4,854 # 80025000 <disk>
    80006cb2:	9736                	add	a4,a4,a3
    80006cb4:	4685                	li	a3,1
    80006cb6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006cba:	20058713          	addi	a4,a1,512
    80006cbe:	00471693          	slli	a3,a4,0x4
    80006cc2:	0001e717          	auipc	a4,0x1e
    80006cc6:	33e70713          	addi	a4,a4,830 # 80025000 <disk>
    80006cca:	9736                	add	a4,a4,a3
    80006ccc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006cd0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006cd4:	7679                	lui	a2,0xffffe
    80006cd6:	963e                	add	a2,a2,a5
    80006cd8:	00020697          	auipc	a3,0x20
    80006cdc:	32868693          	addi	a3,a3,808 # 80027000 <disk+0x2000>
    80006ce0:	6298                	ld	a4,0(a3)
    80006ce2:	9732                	add	a4,a4,a2
    80006ce4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006ce6:	6298                	ld	a4,0(a3)
    80006ce8:	9732                	add	a4,a4,a2
    80006cea:	4541                	li	a0,16
    80006cec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006cee:	6298                	ld	a4,0(a3)
    80006cf0:	9732                	add	a4,a4,a2
    80006cf2:	4505                	li	a0,1
    80006cf4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006cf8:	f9442703          	lw	a4,-108(s0)
    80006cfc:	6288                	ld	a0,0(a3)
    80006cfe:	962a                	add	a2,a2,a0
    80006d00:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006d04:	0712                	slli	a4,a4,0x4
    80006d06:	6290                	ld	a2,0(a3)
    80006d08:	963a                	add	a2,a2,a4
    80006d0a:	05890513          	addi	a0,s2,88
    80006d0e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006d10:	6294                	ld	a3,0(a3)
    80006d12:	96ba                	add	a3,a3,a4
    80006d14:	40000613          	li	a2,1024
    80006d18:	c690                	sw	a2,8(a3)
  if(write)
    80006d1a:	140d0063          	beqz	s10,80006e5a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006d1e:	00020697          	auipc	a3,0x20
    80006d22:	2e26b683          	ld	a3,738(a3) # 80027000 <disk+0x2000>
    80006d26:	96ba                	add	a3,a3,a4
    80006d28:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006d2c:	0001e817          	auipc	a6,0x1e
    80006d30:	2d480813          	addi	a6,a6,724 # 80025000 <disk>
    80006d34:	00020517          	auipc	a0,0x20
    80006d38:	2cc50513          	addi	a0,a0,716 # 80027000 <disk+0x2000>
    80006d3c:	6114                	ld	a3,0(a0)
    80006d3e:	96ba                	add	a3,a3,a4
    80006d40:	00c6d603          	lhu	a2,12(a3)
    80006d44:	00166613          	ori	a2,a2,1
    80006d48:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006d4c:	f9842683          	lw	a3,-104(s0)
    80006d50:	6110                	ld	a2,0(a0)
    80006d52:	9732                	add	a4,a4,a2
    80006d54:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d58:	20058613          	addi	a2,a1,512
    80006d5c:	0612                	slli	a2,a2,0x4
    80006d5e:	9642                	add	a2,a2,a6
    80006d60:	577d                	li	a4,-1
    80006d62:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d66:	00469713          	slli	a4,a3,0x4
    80006d6a:	6114                	ld	a3,0(a0)
    80006d6c:	96ba                	add	a3,a3,a4
    80006d6e:	03078793          	addi	a5,a5,48
    80006d72:	97c2                	add	a5,a5,a6
    80006d74:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006d76:	611c                	ld	a5,0(a0)
    80006d78:	97ba                	add	a5,a5,a4
    80006d7a:	4685                	li	a3,1
    80006d7c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d7e:	611c                	ld	a5,0(a0)
    80006d80:	97ba                	add	a5,a5,a4
    80006d82:	4809                	li	a6,2
    80006d84:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006d88:	611c                	ld	a5,0(a0)
    80006d8a:	973e                	add	a4,a4,a5
    80006d8c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d90:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006d94:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d98:	6518                	ld	a4,8(a0)
    80006d9a:	00275783          	lhu	a5,2(a4)
    80006d9e:	8b9d                	andi	a5,a5,7
    80006da0:	0786                	slli	a5,a5,0x1
    80006da2:	97ba                	add	a5,a5,a4
    80006da4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006da8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006dac:	6518                	ld	a4,8(a0)
    80006dae:	00275783          	lhu	a5,2(a4)
    80006db2:	2785                	addiw	a5,a5,1
    80006db4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006db8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006dbc:	100017b7          	lui	a5,0x10001
    80006dc0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006dc4:	00492703          	lw	a4,4(s2)
    80006dc8:	4785                	li	a5,1
    80006dca:	02f71163          	bne	a4,a5,80006dec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006dce:	00020997          	auipc	s3,0x20
    80006dd2:	35a98993          	addi	s3,s3,858 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    80006dd6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006dd8:	85ce                	mv	a1,s3
    80006dda:	854a                	mv	a0,s2
    80006ddc:	ffffc097          	auipc	ra,0xffffc
    80006de0:	926080e7          	jalr	-1754(ra) # 80002702 <sleep>
  while(b->disk == 1) {
    80006de4:	00492783          	lw	a5,4(s2)
    80006de8:	fe9788e3          	beq	a5,s1,80006dd8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006dec:	f9042903          	lw	s2,-112(s0)
    80006df0:	20090793          	addi	a5,s2,512
    80006df4:	00479713          	slli	a4,a5,0x4
    80006df8:	0001e797          	auipc	a5,0x1e
    80006dfc:	20878793          	addi	a5,a5,520 # 80025000 <disk>
    80006e00:	97ba                	add	a5,a5,a4
    80006e02:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006e06:	00020997          	auipc	s3,0x20
    80006e0a:	1fa98993          	addi	s3,s3,506 # 80027000 <disk+0x2000>
    80006e0e:	00491713          	slli	a4,s2,0x4
    80006e12:	0009b783          	ld	a5,0(s3)
    80006e16:	97ba                	add	a5,a5,a4
    80006e18:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006e1c:	854a                	mv	a0,s2
    80006e1e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006e22:	00000097          	auipc	ra,0x0
    80006e26:	bc4080e7          	jalr	-1084(ra) # 800069e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006e2a:	8885                	andi	s1,s1,1
    80006e2c:	f0ed                	bnez	s1,80006e0e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006e2e:	00020517          	auipc	a0,0x20
    80006e32:	2fa50513          	addi	a0,a0,762 # 80027128 <disk+0x2128>
    80006e36:	ffffa097          	auipc	ra,0xffffa
    80006e3a:	e62080e7          	jalr	-414(ra) # 80000c98 <release>
}
    80006e3e:	70a6                	ld	ra,104(sp)
    80006e40:	7406                	ld	s0,96(sp)
    80006e42:	64e6                	ld	s1,88(sp)
    80006e44:	6946                	ld	s2,80(sp)
    80006e46:	69a6                	ld	s3,72(sp)
    80006e48:	6a06                	ld	s4,64(sp)
    80006e4a:	7ae2                	ld	s5,56(sp)
    80006e4c:	7b42                	ld	s6,48(sp)
    80006e4e:	7ba2                	ld	s7,40(sp)
    80006e50:	7c02                	ld	s8,32(sp)
    80006e52:	6ce2                	ld	s9,24(sp)
    80006e54:	6d42                	ld	s10,16(sp)
    80006e56:	6165                	addi	sp,sp,112
    80006e58:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e5a:	00020697          	auipc	a3,0x20
    80006e5e:	1a66b683          	ld	a3,422(a3) # 80027000 <disk+0x2000>
    80006e62:	96ba                	add	a3,a3,a4
    80006e64:	4609                	li	a2,2
    80006e66:	00c69623          	sh	a2,12(a3)
    80006e6a:	b5c9                	j	80006d2c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e6c:	f9042583          	lw	a1,-112(s0)
    80006e70:	20058793          	addi	a5,a1,512
    80006e74:	0792                	slli	a5,a5,0x4
    80006e76:	0001e517          	auipc	a0,0x1e
    80006e7a:	23250513          	addi	a0,a0,562 # 800250a8 <disk+0xa8>
    80006e7e:	953e                	add	a0,a0,a5
  if(write)
    80006e80:	e20d11e3          	bnez	s10,80006ca2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006e84:	20058713          	addi	a4,a1,512
    80006e88:	00471693          	slli	a3,a4,0x4
    80006e8c:	0001e717          	auipc	a4,0x1e
    80006e90:	17470713          	addi	a4,a4,372 # 80025000 <disk>
    80006e94:	9736                	add	a4,a4,a3
    80006e96:	0a072423          	sw	zero,168(a4)
    80006e9a:	b505                	j	80006cba <virtio_disk_rw+0xf4>

0000000080006e9c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006e9c:	1101                	addi	sp,sp,-32
    80006e9e:	ec06                	sd	ra,24(sp)
    80006ea0:	e822                	sd	s0,16(sp)
    80006ea2:	e426                	sd	s1,8(sp)
    80006ea4:	e04a                	sd	s2,0(sp)
    80006ea6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006ea8:	00020517          	auipc	a0,0x20
    80006eac:	28050513          	addi	a0,a0,640 # 80027128 <disk+0x2128>
    80006eb0:	ffffa097          	auipc	ra,0xffffa
    80006eb4:	d34080e7          	jalr	-716(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006eb8:	10001737          	lui	a4,0x10001
    80006ebc:	533c                	lw	a5,96(a4)
    80006ebe:	8b8d                	andi	a5,a5,3
    80006ec0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ec2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ec6:	00020797          	auipc	a5,0x20
    80006eca:	13a78793          	addi	a5,a5,314 # 80027000 <disk+0x2000>
    80006ece:	6b94                	ld	a3,16(a5)
    80006ed0:	0207d703          	lhu	a4,32(a5)
    80006ed4:	0026d783          	lhu	a5,2(a3)
    80006ed8:	06f70163          	beq	a4,a5,80006f3a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006edc:	0001e917          	auipc	s2,0x1e
    80006ee0:	12490913          	addi	s2,s2,292 # 80025000 <disk>
    80006ee4:	00020497          	auipc	s1,0x20
    80006ee8:	11c48493          	addi	s1,s1,284 # 80027000 <disk+0x2000>
    __sync_synchronize();
    80006eec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ef0:	6898                	ld	a4,16(s1)
    80006ef2:	0204d783          	lhu	a5,32(s1)
    80006ef6:	8b9d                	andi	a5,a5,7
    80006ef8:	078e                	slli	a5,a5,0x3
    80006efa:	97ba                	add	a5,a5,a4
    80006efc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006efe:	20078713          	addi	a4,a5,512
    80006f02:	0712                	slli	a4,a4,0x4
    80006f04:	974a                	add	a4,a4,s2
    80006f06:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006f0a:	e731                	bnez	a4,80006f56 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006f0c:	20078793          	addi	a5,a5,512
    80006f10:	0792                	slli	a5,a5,0x4
    80006f12:	97ca                	add	a5,a5,s2
    80006f14:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006f16:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006f1a:	ffffc097          	auipc	ra,0xffffc
    80006f1e:	974080e7          	jalr	-1676(ra) # 8000288e <wakeup>

    disk.used_idx += 1;
    80006f22:	0204d783          	lhu	a5,32(s1)
    80006f26:	2785                	addiw	a5,a5,1
    80006f28:	17c2                	slli	a5,a5,0x30
    80006f2a:	93c1                	srli	a5,a5,0x30
    80006f2c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006f30:	6898                	ld	a4,16(s1)
    80006f32:	00275703          	lhu	a4,2(a4)
    80006f36:	faf71be3          	bne	a4,a5,80006eec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006f3a:	00020517          	auipc	a0,0x20
    80006f3e:	1ee50513          	addi	a0,a0,494 # 80027128 <disk+0x2128>
    80006f42:	ffffa097          	auipc	ra,0xffffa
    80006f46:	d56080e7          	jalr	-682(ra) # 80000c98 <release>
}
    80006f4a:	60e2                	ld	ra,24(sp)
    80006f4c:	6442                	ld	s0,16(sp)
    80006f4e:	64a2                	ld	s1,8(sp)
    80006f50:	6902                	ld	s2,0(sp)
    80006f52:	6105                	addi	sp,sp,32
    80006f54:	8082                	ret
      panic("virtio_disk_intr status");
    80006f56:	00002517          	auipc	a0,0x2
    80006f5a:	a4250513          	addi	a0,a0,-1470 # 80008998 <syscalls+0x3c0>
    80006f5e:	ffff9097          	auipc	ra,0xffff9
    80006f62:	5e0080e7          	jalr	1504(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
