module emmintrin;

import core.simd;

version (D_SIMD) {
	/* Use what's defined in core.simd */
} else version (GNU) {
	version (X86)
		version = INLINE_ASM;
	else version (X86_64)
		version = INLINE_ASM;
	else
		static assert(0, "Can't use SIMD on this target.");
} else {
	static assert(0, "Can't use SIMD with that compiler.");
}



version (D_SIMD) {
	/* Map The template we use to the core.simd builtins. */
	pure nothrow @safe @nogc void16 __simd(XMM opcode, alias void16 op1, alias void16 op2)() {
		return __simd(opcode, op1, op2);
	}

	nothrow @safe @nogc void16 __simd(XMM opcode, alias void16 op1, alias void16 op2, ubyte imm8)() {
		return __simd(opcode, op1, op2, imm8);
	}

	pure nothrow @safe @nogc void16 __simd_ib(XMM opcode, alias void16 op1, ubyte imm8)() {
		return __simd_ib(opcode, op1, imm8);
	}

} else version (INLINE_ASM) {
	/* Redefine the __simd* builtins to inline assembly for GCC. */


	/* List directly copied from core.simd */
	enum XMM
	{
		ADDSS = 0xF30F58,
		ADDSD = 0xF20F58,
		ADDPS = 0x000F58,
		ADDPD = 0x660F58,
		PADDB = 0x660FFC,
		PADDW = 0x660FFD,
		PADDD = 0x660FFE,
		PADDQ = 0x660FD4,

		SUBSS = 0xF30F5C,
		SUBSD = 0xF20F5C,
		SUBPS = 0x000F5C,
		SUBPD = 0x660F5C,
		PSUBB = 0x660FF8,
		PSUBW = 0x660FF9,
		PSUBD = 0x660FFA,
		PSUBQ = 0x660FFB,

		MULSS = 0xF30F59,
		MULSD = 0xF20F59,
		MULPS = 0x000F59,
		MULPD = 0x660F59,
		PMULLW = 0x660FD5,

		DIVSS = 0xF30F5E,
		DIVSD = 0xF20F5E,
		DIVPS = 0x000F5E,
		DIVPD = 0x660F5E,

		PAND  = 0x660FDB,
		POR   = 0x660FEB,

		UCOMISS = 0x000F2E,
		UCOMISD = 0x660F2E,

		XORPS = 0x000F57,
		XORPD = 0x660F57,

		// Use STO and LOD instead of MOV to distinguish the direction
		STOSS  = 0xF30F11,
		STOSD  = 0xF20F11,
		STOAPS = 0x000F29,
		STOAPD = 0x660F29,
		STODQA = 0x660F7F,
		STOD   = 0x660F7E,        // MOVD reg/mem64, xmm   66 0F 7E /r
		STOQ   = 0x660FD6,

		LODSS  = 0xF30F10,
		LODSD  = 0xF20F10,
		LODAPS = 0x000F28,
		LODAPD = 0x660F28,
		LODDQA = 0x660F6F,
		LODD   = 0x660F6E,        // MOVD xmm, reg/mem64   66 0F 6E /r
		LODQ   = 0xF30F7E,

		LODDQU   = 0xF30F6F,      // MOVDQU xmm1, xmm2/mem128  F3 0F 6F /r
		STODQU   = 0xF30F7F,      // MOVDQU xmm1/mem128, xmm2  F3 0F 7F /r
		MOVDQ2Q  = 0xF20FD6,      // MOVDQ2Q mmx, xmm          F2 0F D6 /r
		MOVHLPS  = 0x0F12,        // MOVHLPS xmm1, xmm2        0F 12 /r
		LODHPD   = 0x660F16,
		STOHPD   = 0x660F17,      // MOVHPD mem64, xmm         66 0F 17 /r
		LODHPS   = 0x0F16,
		STOHPS   = 0x0F17,
		MOVLHPS  = 0x0F16,
		LODLPD   = 0x660F12,
		STOLPD   = 0x660F13,
		LODLPS   = 0x0F12,
		STOLPS   = 0x0F13,
		MOVMSKPD = 0x660F50,
		MOVMSKPS = 0x0F50,
		MOVNTDQ  = 0x660FE7,
		MOVNTI   = 0x0FC3,
		MOVNTPD  = 0x660F2B,
		MOVNTPS  = 0x0F2B,
		MOVNTQ   = 0x0FE7,
		MOVQ2DQ  = 0xF30FD6,
		LODUPD   = 0x660F10,
		STOUPD   = 0x660F11,
		LODUPS   = 0x0F10,
		STOUPS   = 0x0F11,

		PACKSSDW = 0x660F6B,
		PACKSSWB = 0x660F63,
		PACKUSWB = 0x660F67,
		PADDSB = 0x660FEC,
		PADDSW = 0x660FED,
		PADDUSB = 0x660FDC,
		PADDUSW = 0x660FDD,
		PANDN = 0x660FDF,
		PCMPEQB = 0x660F74,
		PCMPEQD = 0x660F76,
		PCMPEQW = 0x660F75,
		PCMPGTB = 0x660F64,
		PCMPGTD = 0x660F66,
		PCMPGTW = 0x660F65,
		PMADDWD = 0x660FF5,
		PSLLW = 0x660FF1,
		PSLLD = 0x660FF2,
		PSLLQ = 0x660FF3,
		PSRAW = 0x660FE1,
		PSRAD = 0x660FE2,
		PSRLW = 0x660FD1,
		PSRLD = 0x660FD2,
		PSRLQ = 0x660FD3,
		PSUBSB = 0x660FE8,
		PSUBSW = 0x660FE9,
		PSUBUSB = 0x660FD8,
		PSUBUSW = 0x660FD9,
		PUNPCKHBW = 0x660F68,
		PUNPCKHDQ = 0x660F6A,
		PUNPCKHWD = 0x660F69,
		PUNPCKLBW = 0x660F60,
		PUNPCKLDQ = 0x660F62,
		PUNPCKLWD = 0x660F61,
		PXOR = 0x660FEF,
		ANDPD = 0x660F54,
		ANDPS = 0x0F54,
		ANDNPD = 0x660F55,
		ANDNPS = 0x0F55,
		CMPPS = 0x0FC2,
		CMPPD = 0x660FC2,
		CMPSD = 0xF20FC2,
		CMPSS = 0xF30FC2,
		COMISD = 0x660F2F,
		COMISS = 0x0F2F,
		CVTDQ2PD = 0xF30FE6,
		CVTDQ2PS = 0x0F5B,
		CVTPD2DQ = 0xF20FE6,
		CVTPD2PI = 0x660F2D,
		CVTPD2PS = 0x660F5A,
		CVTPI2PD = 0x660F2A,
		CVTPI2PS = 0x0F2A,
		CVTPS2DQ = 0x660F5B,
		CVTPS2PD = 0x0F5A,
		CVTPS2PI = 0x0F2D,
		CVTSD2SI = 0xF20F2D,
		CVTSD2SS = 0xF20F5A,
		CVTSI2SD = 0xF20F2A,
		CVTSI2SS = 0xF30F2A,
		CVTSS2SD = 0xF30F5A,
		CVTSS2SI = 0xF30F2D,
		CVTTPD2PI = 0x660F2C,
		CVTTPD2DQ = 0x660FE6,
		CVTTPS2DQ = 0xF30F5B,
		CVTTPS2PI = 0x0F2C,
		CVTTSD2SI = 0xF20F2C,
		CVTTSS2SI = 0xF30F2C,
		MASKMOVDQU = 0x660FF7,
		MASKMOVQ = 0x0FF7,
		MAXPD = 0x660F5F,
		MAXPS = 0x0F5F,
		MAXSD = 0xF20F5F,
		MAXSS = 0xF30F5F,
		MINPD = 0x660F5D,
		MINPS = 0x0F5D,
		MINSD = 0xF20F5D,
		MINSS = 0xF30F5D,
		ORPD = 0x660F56,
		ORPS = 0x0F56,
		PAVGB = 0x660FE0,
		PAVGW = 0x660FE3,
		PMAXSW = 0x660FEE,
		//PINSRW = 0x660FC4,
		PMAXUB = 0x660FDE,
		PMINSW = 0x660FEA,
		PMINUB = 0x660FDA,
		//PMOVMSKB = 0x660FD7,
		PMULHUW = 0x660FE4,
		PMULHW = 0x660FE5,
		PMULUDQ = 0x660FF4,
		PSADBW = 0x660FF6,
		PUNPCKHQDQ = 0x660F6D,
		PUNPCKLQDQ = 0x660F6C,
		RCPPS = 0x0F53,
		RCPSS = 0xF30F53,
		RSQRTPS = 0x0F52,
		RSQRTSS = 0xF30F52,
		SQRTPD = 0x660F51,
		SHUFPD = 0x660FC6,
		SHUFPS = 0x0FC6,
		SQRTPS = 0x0F51,
		SQRTSD = 0xF20F51,
		SQRTSS = 0xF30F51,
		UNPCKHPD = 0x660F15,
		UNPCKHPS = 0x0F15,
		UNPCKLPD = 0x660F14,
		UNPCKLPS = 0x0F14,

		PSHUFD = 0x660F70,
		PSHUFHW = 0xF30F70,
		PSHUFLW = 0xF20F70,
		PSHUFW = 0x0F70,
		PSLLDQ = 0x07660F73,
		PSRLDQ = 0x03660F73,

		//PREFETCH = 0x0F18,

		// SSE3 Pentium 4 (Prescott)

		ADDSUBPD = 0x660FD0,
		ADDSUBPS = 0xF20FD0,
		HADDPD   = 0x660F7C,
		HADDPS   = 0xF20F7C,
		HSUBPD   = 0x660F7D,
		HSUBPS   = 0xF20F7D,
		MOVDDUP  = 0xF20F12,
		MOVSHDUP = 0xF30F16,
		MOVSLDUP = 0xF30F12,
		LDDQU    = 0xF20FF0,
		MONITOR  = 0x0F01C8,
		MWAIT    = 0x0F01C9,

		// SSSE3
		PALIGNR = 0x660F3A0F,
		PHADDD = 0x660F3802,
		PHADDW = 0x660F3801,
		PHADDSW = 0x660F3803,
		PABSB = 0x660F381C,
		PABSD = 0x660F381E,
		PABSW = 0x660F381D,
		PSIGNB = 0x660F3808,
		PSIGND = 0x660F380A,
		PSIGNW = 0x660F3809,
		PSHUFB = 0x660F3800,
		PMADDUBSW = 0x660F3804,
		PMULHRSW = 0x660F380B,
		PHSUBD = 0x660F3806,
		PHSUBW = 0x660F3805,
		PHSUBSW = 0x660F3807,

		// SSE4.1

		BLENDPD   = 0x660F3A0D,
		BLENDPS   = 0x660F3A0C,
		BLENDVPD  = 0x660F3815,
		BLENDVPS  = 0x660F3814,
		DPPD      = 0x660F3A41,
		DPPS      = 0x660F3A40,
		EXTRACTPS = 0x660F3A17,
		INSERTPS  = 0x660F3A21,
		MPSADBW   = 0x660F3A42,
		PBLENDVB  = 0x660F3810,
		PBLENDW   = 0x660F3A0E,
		PEXTRD    = 0x660F3A16,
		PEXTRQ    = 0x660F3A16,
		PINSRB    = 0x660F3A20,
		PINSRD    = 0x660F3A22,
		PINSRQ    = 0x660F3A22,

		MOVNTDQA = 0x660F382A,
		PACKUSDW = 0x660F382B,
		PCMPEQQ = 0x660F3829,
		PEXTRB = 0x660F3A14,
		PHMINPOSUW = 0x660F3841,
		PMAXSB = 0x660F383C,
		PMAXSD = 0x660F383D,
		PMAXUD = 0x660F383F,
		PMAXUW = 0x660F383E,
		PMINSB = 0x660F3838,
		PMINSD = 0x660F3839,
		PMINUD = 0x660F383B,
		PMINUW = 0x660F383A,
		PMOVSXBW = 0x660F3820,
		PMOVSXBD = 0x660F3821,
		PMOVSXBQ = 0x660F3822,
		PMOVSXWD = 0x660F3823,
		PMOVSXWQ = 0x660F3824,
		PMOVSXDQ = 0x660F3825,
		PMOVZXBW = 0x660F3830,
		PMOVZXBD = 0x660F3831,
		PMOVZXBQ = 0x660F3832,
		PMOVZXWD = 0x660F3833,
		PMOVZXWQ = 0x660F3834,
		PMOVZXDQ = 0x660F3835,
		PMULDQ   = 0x660F3828,
		PMULLD   = 0x660F3840,
		PTEST    = 0x660F3817,

		ROUNDPD = 0x660F3A09,
		ROUNDPS = 0x660F3A08,
		ROUNDSD = 0x660F3A0B,
		ROUNDSS = 0x660F3A0A,

		// SSE4.2
		PCMPESTRI  = 0x660F3A61,
		PCMPESTRM  = 0x660F3A60,
		PCMPISTRI  = 0x660F3A63,
		PCMPISTRM  = 0x660F3A62,
		PCMPGTQ    = 0x660F3837,
		//CRC32

		// SSE4a (AMD only)
		// EXTRQ,INSERTQ,MOVNTSD,MOVNTSS

		// POPCNT and LZCNT (have their own CPUID bits)
		POPCNT     = 0xF30FB8,
		// LZCNT
	}

	/* Quick and dirty way to convert the enum XMM name to an assembly
	 * mnemonic. (The actual numeric value is not used.) */
	pure @safe static string mnemonic(XMM opcode)() {
		import std.conv : to;
		import std.string;
		if (opcode == XMM.LODDQU || opcode == XMM.STODQU)
			return "movdqu";
		return to!string(opcode).toLower;
	}

	pure nothrow @safe @nogc void16 __simd(XMM opcode, alias void16 op1, uint line = __LINE__)() {
		void16 ret = void;
		enum string ins = "\"" ~ mnemonic!opcode ~ "\"";

		asm pure nothrow @nogc @trusted {
			/* Empty leading string needed for the parser to
			 * recognize this as a GCC inline asm and not D inline
			 * asm. */
			"" ~ mixin(ins) ~ " %1, %0\n\t"
			: "=x"(ret)
			: "x"(op1)
			;
		}
		return ret;
	}

	pure nothrow @safe @nogc void16 __simd(XMM opcode, alias void16 op1, alias void16 op2, uint line = __LINE__)() {
		void16 ret = void;
		enum string ins = "\"" ~ mnemonic!opcode ~ "\"";

		asm pure nothrow @nogc @trusted {
			"" ~ mixin(ins) ~ " %2, %0\n\t"
			: "=x"(ret)
			: "0"(op1), "x"(op2)
			;
		}
		return ret;
	}

	/* This variation is not pure as it modify its first operand. */
	nothrow @safe @nogc void16 __simd(XMM opcode, alias void16 op1, alias void16 op2, ubyte imm8, uint line = __LINE__)() {
		enum string ins = "\"" ~ mnemonic!opcode ~ "\"";

		asm pure nothrow @nogc @trusted {
			"" ~ mixin(ins) ~ " %2, %1, %0\n\t"
			: "+x"(op1)
			: "x"(op2), "i"(imm8)
			;
		}
		return op1;
	}

	pure nothrow @safe @nogc void16 __simd_ib(XMM opcode, alias void16 op1, ubyte imm8, uint line = __LINE__)() {
		void16 ret = void;
		enum string ins = "\"" ~ mnemonic!opcode ~ "\"";

		asm pure nothrow @nogc @trusted {
			"" ~ mixin(ins) ~ " %2, %0\n\t"
			: "=x"(ret)
			: "0"(op1), "i"(imm8)
			;
		}
		return ret;
	}
}



/* The type used for every integer instruction. */
union __m128i {
	void16   v16;
	byte16   b16;
	ubyte16 ub16;
	short8    s8;
	ushort8  us8;
	int4      i4;
	uint4    ui4;
	long2     l2;
	ulong2   ul2;
}

nothrow:
@safe:
@nogc:

/* Equivalent to the macro. */
ubyte _MM_SHUFFLE(ubyte fp3, ubyte fp2, ubyte fp1, ubyte fp0) {
	return cast(ubyte)((fp3 << 6) | (fp2 << 4) | (fp1 << 2) | fp0);
}


/* A few intrinsics used by libdivide.d. */

/* Set */
__m128i _mm_set_epi32(alias a, alias b, alias c, alias d, uint line = __LINE__)()
if (is(typeof(a) : int) && is(typeof(b) : int) && is(typeof(c) : int) && is(typeof(d) : int)) {
	__m128i ret = void;
	ret.i4 = [d, b, c, a];
	return ret;
}

__m128i _mm_set1_epi32(alias a, uint line = __LINE__)()
if (is(typeof(a) : int)) {
	return _mm_set_epi32!(a, a, a, a, line);
}

__m128i _mm_setzero_si128(uint line = __LINE__)() {
	return _mm_set1_epi32!(0, line);
}

__m128i _mm_set1_epi64x(alias x, uint line = __LINE__)()
if (is(typeof(x) : ulong)) {
	__m128i ret = void;
	ret.ul2 = [x, x];
	return ret;
}

__m128i _mm_set1_epi8(alias x, uint line = __LINE__)()
if (is(typeof(x) : byte)) {
	__m128i ret = void;
	ret.b16 = [x, x, x, x, x, x, x, x, x, x, x, x, x, x, x, x];
	return ret;
}

__m128i _mm_loadu_si128(alias p, uint line = __LINE__)()
if (is(typeof(p) : const __m128i*)) {
	__m128i ret = void;
	void16 retv16 = void;
	void16 pv16 = p.v16;
	ret.v16 = __simd!(XMM.LODDQU, retv16, pv16, line);
	return ret;
}

/* Shuffle */
__m128i _mm_shuffle_epi32(alias a, ubyte b, uint line = __LINE__)()
if (is(typeof(a) : __m128i)) {
	__m128i ret = void;
	void16 retv16 = void;
	void16 av16 = a.v16;
	ret.v16 = __simd!(XMM.PSHUFD, retv16, av16, b, line);
	return ret;
}

/* Shift left */
__m128i _mm_slli_epi64(alias a, ubyte b, uint line = __LINE__)()
if (is(typeof(a) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	ret.v16 = __simd_ib!(XMM.PSLLQ, av16, b, line);
	return ret;
}

/* Shift right */
__m128i _mm_srli_epi64(alias a, ubyte b, uint line = __LINE__)()
if (is(typeof(a) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	ret.v16 = __simd_ib!(XMM.PSRLQ, av16, b, line);
	return ret;
}

__m128i _mm_srli_epi32(alias a, ubyte b, uint line = __LINE__)()
if (is(typeof(a) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	ret.v16 = __simd_ib!(XMM.PSRLD, av16, b, line);
	return ret;
}

__m128i _mm_srl_epi64(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PSRLQ, av16, bv16, line);
	return ret;
}

__m128i _mm_srl_epi32(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PSRLD, av16, bv16, line);
	return ret;
}

__m128i _mm_srai_epi32(alias a, ubyte b, uint line = __LINE__)()
if (is(typeof(a) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	ret.v16 = __simd_ib!(XMM.PSRAD, av16, b, line);
	return ret;
}

__m128i _mm_sra_epi32(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PSRAD, av16, bv16, line);
	return ret;
}

/* Add */
__m128i _mm_add_epi32(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PADDD, av16, bv16, line);
	return ret;
}

__m128i _mm_add_epi64(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PADDQ, av16, bv16, line);
	return ret;
}

/* Subtract */
__m128i _mm_sub_epi32(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PSUBD, av16, bv16, line);
	return ret;
}

__m128i _mm_sub_epi64(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PSUBQ, av16, bv16, line);
	return ret;
}

/* Multiply */
__m128i _mm_mul_epi32(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PMULDQ, av16, bv16, line);
	return ret;
}
__m128i _mm_mul_epu32(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PMULUDQ, av16, bv16, line);
	return ret;
}

/* Compare */
__m128i _mm_cmpeq_epi8(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PCMPEQB, av16, bv16, line);
	return ret;
}

/* And */
__m128i _mm_and_si128(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PAND, av16, bv16, line);
	return ret;
}

/* Or */
__m128i _mm_or_si128(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.POR, av16, bv16, line);
	return ret;
}

/* Xor */
__m128i _mm_xor_si128(alias a, alias b, uint line = __LINE__)()
if (is(typeof(a) : __m128i) && is(typeof(b) : __m128i)) {
	__m128i ret = void;
	void16 av16 = a.v16;
	void16 bv16 = b.v16;
	ret.v16 = __simd!(XMM.PXOR, av16, bv16, line);
	return ret;
}
