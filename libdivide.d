/* Ported from libdivide.h to D by Celelibi. */

module libdivide;
/* libdivide.h
   Copyright 2010 ridiculous_fish
*/


public import core.stdc.stdint : int8_t, uint8_t, int32_t, uint32_t, int64_t, uint64_t;
import core.stdc.stdlib;

version (Win32) {
	version = LIBDIVIDE_WINDOWS;
}

version (LIBDIVIDE_USE_SSE2) {
	import emmintrin;
}

version (D_LP64) {
	version = HAS_INT128_T;
}

version (Win64) {
	version = LIBDIVIDE_IS_X86_64;
}

version (X86_64) {
	version = LIBDIVIDE_IS_X86_64;
}

version (X86) {
	version = LIBDIVIDE_IS_i386;
}

version (GNU) {
	version = LIBDIVIDE_GCC_STYLE_ASM;
}

version (LDC) {
	version = LIBDIVIDE_GCC_STYLE_ASM;
}

version (LIBDIVIDE_GCC_STYLE_ASM) {
	version (LIBDIVIDE_IS_i386) {
		version = X86_GCC_ASM;
	}

	version (LIBDIVIDE_IS_X86_64) {
		version = X86_GCC_ASM;
		version = X64_GCC_ASM;
	}
}

/* libdivide may use the pmuldq (vector signed 32x32->64 mult instruction) which is in SSE 4.1.  However, signed multiplication can be emulated efficiently with unsigned multiplication, and SSE 4.1 is currently rare, so it is OK to not turn this on */
version (LIBDIVIDE_USE_SSE4_1) {
	import emmintrin;
}

/* Explanation of "more" field: bit 6 is whether to use shift path.  If we are using the shift path, bit 7 is whether the divisor is negative in the signed case; in the unsigned case it is 0.   Bits 0-4 is shift value (for shift path or mult path).  In 32 bit case, bit 5 is always 0.  We use bit 7 as the "negative divisor indicator" so that we can use sign extension to efficiently go to a full-width -1.


u32: [0-4] shift value
     [5] ignored
     [6] add indicator
     [7] shift path

s32: [0-4] shift value
     [5] shift path
     [6] add indicator
     [7] indicates negative divisor

u64: [0-5] shift value
     [6] add indicator
     [7] shift path

s64: [0-5] shift value
     [6] add indicator
     [7] indicates negative divisor
     magic number of 0 indicates shift path (we ran out of bits!)
*/

enum {
    LIBDIVIDE_32_SHIFT_MASK = 0x1F,
    LIBDIVIDE_64_SHIFT_MASK = 0x3F,
    LIBDIVIDE_ADD_MARKER = 0x40,
    LIBDIVIDE_U32_SHIFT_PATH = 0x80,
    LIBDIVIDE_U64_SHIFT_PATH = 0x80,
    LIBDIVIDE_S32_SHIFT_PATH = 0x20,
    LIBDIVIDE_NEGATIVE_DIVISOR = 0x80
};


struct libdivide_u32_t {
    uint32_t magic;
    uint8_t more;
};

struct libdivide_s32_t {
    int32_t magic;
    uint8_t more;
};

struct libdivide_u64_t {
    uint64_t magic;
    uint8_t more;
};

struct libdivide_s64_t {
    int64_t magic;
    uint8_t more;
};



libdivide_s32_t libdivide_s32_gen(int32_t y);
libdivide_u32_t libdivide_u32_gen(uint32_t y);
libdivide_s64_t libdivide_s64_gen(int64_t y);
libdivide_u64_t libdivide_u64_gen(uint64_t y);

int32_t  libdivide_s32_do(int32_t numer, const libdivide_s32_t *denom);
uint32_t libdivide_u32_do(uint32_t numer, const libdivide_u32_t *denom);
int64_t  libdivide_s64_do(int64_t numer, const libdivide_s64_t *denom);
uint64_t libdivide_u64_do(uint64_t y, const libdivide_u64_t *denom);

int libdivide_u32_get_algorithm(const libdivide_u32_t *denom);
uint32_t libdivide_u32_do_alg0(uint32_t numer, const libdivide_u32_t *denom);
uint32_t libdivide_u32_do_alg1(uint32_t numer, const libdivide_u32_t *denom);
uint32_t libdivide_u32_do_alg2(uint32_t numer, const libdivide_u32_t *denom);

int libdivide_u64_get_algorithm(const libdivide_u64_t *denom);
uint64_t libdivide_u64_do_alg0(uint64_t numer, const libdivide_u64_t *denom);
uint64_t libdivide_u64_do_alg1(uint64_t numer, const libdivide_u64_t *denom);
uint64_t libdivide_u64_do_alg2(uint64_t numer, const libdivide_u64_t *denom);

int libdivide_s32_get_algorithm(const libdivide_s32_t *denom);
int32_t libdivide_s32_do_alg0(int32_t numer, const libdivide_s32_t *denom);
int32_t libdivide_s32_do_alg1(int32_t numer, const libdivide_s32_t *denom);
int32_t libdivide_s32_do_alg2(int32_t numer, const libdivide_s32_t *denom);
int32_t libdivide_s32_do_alg3(int32_t numer, const libdivide_s32_t *denom);
int32_t libdivide_s32_do_alg4(int32_t numer, const libdivide_s32_t *denom);

int libdivide_s64_get_algorithm(const libdivide_s64_t *denom);
int64_t libdivide_s64_do_alg0(int64_t numer, const libdivide_s64_t *denom);
int64_t libdivide_s64_do_alg1(int64_t numer, const libdivide_s64_t *denom);
int64_t libdivide_s64_do_alg2(int64_t numer, const libdivide_s64_t *denom);
int64_t libdivide_s64_do_alg3(int64_t numer, const libdivide_s64_t *denom);
int64_t libdivide_s64_do_alg4(int64_t numer, const libdivide_s64_t *denom);

version (LIBDIVIDE_USE_SSE2) {
	__m128i libdivide_u32_do_vector(__m128i numers, const libdivide_u32_t * denom);
	__m128i libdivide_s32_do_vector(__m128i numers, const libdivide_s32_t * denom);
	__m128i libdivide_u64_do_vector(__m128i numers, const libdivide_u64_t * denom);
	__m128i libdivide_s64_do_vector(__m128i numers, const libdivide_s64_t * denom);

	__m128i libdivide_u32_do_vector_alg0(__m128i numers, const libdivide_u32_t * denom);
	__m128i libdivide_u32_do_vector_alg1(__m128i numers, const libdivide_u32_t * denom);
	__m128i libdivide_u32_do_vector_alg2(__m128i numers, const libdivide_u32_t * denom);

	__m128i libdivide_s32_do_vector_alg0(__m128i numers, const libdivide_s32_t * denom);
	__m128i libdivide_s32_do_vector_alg1(__m128i numers, const libdivide_s32_t * denom);
	__m128i libdivide_s32_do_vector_alg2(__m128i numers, const libdivide_s32_t * denom);
	__m128i libdivide_s32_do_vector_alg3(__m128i numers, const libdivide_s32_t * denom);
	__m128i libdivide_s32_do_vector_alg4(__m128i numers, const libdivide_s32_t * denom);

	__m128i libdivide_u64_do_vector_alg0(__m128i numers, const libdivide_u64_t * denom);
	__m128i libdivide_u64_do_vector_alg1(__m128i numers, const libdivide_u64_t * denom);
	__m128i libdivide_u64_do_vector_alg2(__m128i numers, const libdivide_u64_t * denom);

	__m128i libdivide_s64_do_vector_alg0(__m128i numers, const libdivide_s64_t * denom);
	__m128i libdivide_s64_do_vector_alg1(__m128i numers, const libdivide_s64_t * denom);
	__m128i libdivide_s64_do_vector_alg2(__m128i numers, const libdivide_s64_t * denom);
	__m128i libdivide_s64_do_vector_alg3(__m128i numers, const libdivide_s64_t * denom);
	__m128i libdivide_s64_do_vector_alg4(__m128i numers, const libdivide_s64_t * denom);
}

//////// Internal Utility Functions

static uint32_t libdivide__mullhi_u32(uint32_t x, uint32_t y) {
    uint64_t xl = x, yl = y;
    uint64_t rl = xl * yl;
    return cast(uint32_t)(rl >> 32);
}

static uint64_t libdivide__mullhi_u64(uint64_t x, uint64_t y) {
	version (HAS_INT128_T) {
		__uint128_t xl = x, yl = y;
		__uint128_t rl = xl * yl;
		return cast(uint64_t)(rl >> 64);
	} else {
		//full 128 bits are x0 * y0 + (x0 * y1 << 32) + (x1 * y0 << 32) + (x1 * y1 << 64)
		const uint32_t mask = 0xFFFFFFFF;
		const uint32_t x0 = cast(uint32_t)(x & mask), x1 = cast(uint32_t)(x >> 32);
		const uint32_t y0 = cast(uint32_t)(y & mask), y1 = cast(uint32_t)(y >> 32);
		const uint32_t x0y0_hi = libdivide__mullhi_u32(x0, y0);
		const uint64_t x0y1 = x0 * cast(uint64_t)y1;
		const uint64_t x1y0 = x1 * cast(uint64_t)y0;
		const uint64_t x1y1 = x1 * cast(uint64_t)y1;

		uint64_t temp = x1y0 + x0y0_hi;
		uint64_t temp_lo = temp & mask, temp_hi = temp >> 32;
		return x1y1 + temp_hi + ((temp_lo + x0y1) >> 32);
	}
}

static int64_t libdivide__mullhi_s64(int64_t x, int64_t y) {
	version (HAS_INT128_T) {
		__int128_t xl = x, yl = y;
		__int128_t rl = xl * yl;
		return cast(int64_t)(rl >> 64);
	} else {
		//full 128 bits are x0 * y0 + (x0 * y1 << 32) + (x1 * y0 << 32) + (x1 * y1 << 64)
		const uint32_t mask = 0xFFFFFFFF;
		const uint32_t x0 = cast(uint32_t)(x & mask), y0 = cast(uint32_t)(y & mask);
		const int32_t x1 = cast(int32_t)(x >> 32), y1 = cast(int32_t)(y >> 32);
		const uint32_t x0y0_hi = libdivide__mullhi_u32(x0, y0);
		const int64_t t = x1*cast(int64_t)y0 + x0y0_hi;
		const int64_t w1 = x0*cast(int64_t)y1 + (t & mask);
		return x1*cast(int64_t)y1 + (t >> 32) + (w1 >> 32);
	}
}

version (LIBDIVIDE_USE_SSE2) {

	static __m128i libdivide__u64_to_m128(uint64_t x) {
		return _mm_set1_epi64x!(x);
	}

	static __m128i libdivide_get_FFFFFFFF00000000() {
		//returns the same as _mm_set1_epi64(0xFFFFFFFF00000000ULL) without touching memory
		__m128i result = _mm_set1_epi8!(cast(byte)-1);
		return _mm_slli_epi64!(result, 32);
	}

	static __m128i libdivide_get_00000000FFFFFFFF() {
		//returns the same as _mm_set1_epi64(0x00000000FFFFFFFFULL) without touching memory
		__m128i result = _mm_set1_epi8!(cast(byte)-1); //optimizes to pcmpeqd on OS X
		result = _mm_srli_epi64!(result, 32);
		return result;
	}

	static __m128i libdivide_get_0000FFFF() {
		//returns the same as _mm_set1_epi32!(0x0000FFFFULL) without touching memory
		__m128i result = void; //we don't care what its contents are
		result = _mm_cmpeq_epi8!(result, result); //all 1s
		result = _mm_srli_epi32!(result, 16);
		return result;
	}

	static __m128i libdivide_s64_signbits(__m128i v) {
		//we want to compute v >> 63, that is, _mm_srai_epi64(v, 63).  But there is no 64 bit shift right arithmetic instruction in SSE2.  So we have to fake it by first duplicating the high 32 bit values, and then using a 32 bit shift.  Another option would be to use _mm_srli_epi64!(v, 63) and then subtract that from 0, but that approach appears to be substantially slower for unknown reasons
		__m128i hiBitsDuped = _mm_shuffle_epi32!(v, _MM_SHUFFLE(3, 3, 1, 1));
		__m128i signBits = _mm_srai_epi32!(hiBitsDuped, 31);
		return signBits;
	}

	/* Returns an __m128i whose low 32 bits are equal to amt and has zero elsewhere. */
	static __m128i libdivide_u32_to_m128i(uint32_t amt) {
		int amti = cast(int)amt;
		return _mm_set_epi32!(0, 0, 0, amti);
	}

	static __m128i libdivide_s64_shift_right_vector(__m128i v, int amt) {
		//implementation of _mm_sra_epi64.  Here we have two 64 bit values which are shifted right to logically become (64 - amt) values, and are then sign extended from a (64 - amt) bit number.
		const int b = 64 - amt;
		__m128i m = libdivide__u64_to_m128(1UL << (b - 1));
		__m128i n = libdivide_u32_to_m128i(amt);
		__m128i x = _mm_srl_epi64!(v, n);
		__m128i y = _mm_xor_si128!(x, m);
		__m128i result = _mm_sub_epi64!(y, m); //result = x^m - m
		return result;
	}

	/* Here, b is assumed to contain one 32 bit value repeated four times.  If it did not, the function would not work. */
	static __m128i libdivide__mullhi_u32_flat_vector(__m128i a, __m128i b) {
		__m128i x = _mm_mul_epu32!(a, b);
		__m128i hi_product_0Z2Z = _mm_srli_epi64!(x, 32);
		__m128i a1X3X = _mm_srli_epi64!(a, 32);
		__m128i y = libdivide_get_FFFFFFFF00000000();
		__m128i z = _mm_mul_epu32!(a1X3X, b);
		__m128i hi_product_Z1Z3 = _mm_and_si128!(z, y);
		return _mm_or_si128!(hi_product_0Z2Z, hi_product_Z1Z3); // = hi_product_0123
	}


	/* Here, y is assumed to contain one 64 bit value repeated twice. */
	static __m128i libdivide_mullhi_u64_flat_vector(__m128i x, __m128i y) {
		//full 128 bits are x0 * y0 + (x0 * y1 << 32) + (x1 * y0 << 32) + (x1 * y1 << 64)
		const __m128i mask = libdivide_get_00000000FFFFFFFF();
		const __m128i x0 = _mm_and_si128!(x, mask), x1 = _mm_srli_epi64!(x, 32); //x0 is low half of 2 64 bit values, x1 is high half in low slots
		const __m128i y0 = _mm_and_si128!(y, mask), y1 = _mm_srli_epi64!(y, 32);
		const __m128i a = _mm_mul_epu32!(x0, y0);
		const __m128i x0y0_hi = _mm_srli_epi64!(a, 32); //x0 happens to have the low half of the two 64 bit values in 32 bit slots 0 and 2, so _mm_mul_epu32! computes their full product, and then we shift right by 32 to get just the high values
		const __m128i x0y1 = _mm_mul_epu32!(x0, y1);
		const __m128i x1y0 = _mm_mul_epu32!(x1, y0);
		const __m128i x1y1 = _mm_mul_epu32!(x1, y1);

		const __m128i temp = _mm_add_epi64!(x1y0, x0y0_hi);
		__m128i temp_lo = _mm_and_si128!(temp, mask), temp_hi = _mm_srli_epi64!(temp, 32);
		const __m128i b = _mm_add_epi64!(temp_lo, x0y1);
		temp_lo = _mm_srli_epi64!(b, 32);
		temp_hi = _mm_add_epi64!(x1y1, temp_hi);

		return _mm_add_epi64!(temp_lo, temp_hi);
	}

	/* y is one 64 bit value repeated twice */
	static __m128i libdivide_mullhi_s64_flat_vector(__m128i x, __m128i y) {
		__m128i p = libdivide_mullhi_u64_flat_vector(x, y);
		__m128i a = libdivide_s64_signbits(x);
		__m128i t1 = _mm_and_si128!(a, y);
		p = _mm_sub_epi64!(p, t1);
		__m128i b = libdivide_s64_signbits(y);
		__m128i t2 = _mm_and_si128!(b, x);
		p = _mm_sub_epi64!(p, t2);
		return p;
	}

	version (LIBDIVIDE_USE_SSE4_1) {

		/* b is one 32 bit value repeated four times. */
		static __m128i libdivide_mullhi_s32_flat_vector(__m128i a, __m128i b) {
			__m128i x = _mm_mul_epi32!(a, b);
			__m128i hi_product_0Z2Z = _mm_srli_epi64!(x, 32);
			__m128i a1X3X = _mm_srli_epi64!(a, 32);
			__m128i y = _mm_mul_epi32!(a1X3X, b);
			__m128i z = libdivide_get_FFFFFFFF00000000();
			__m128i hi_product_Z1Z3 = _mm_and_si128!(y, z);
			return _mm_or_si128!(hi_product_0Z2Z, hi_product_Z1Z3); // = hi_product_0123
		}

	} else {

		/* SSE2 does not have a signed multiplication instruction, but we can convert unsigned to signed pretty efficiently.  Again, b is just a 32 bit value repeated four times. */
		static __m128i libdivide_mullhi_s32_flat_vector(__m128i a, __m128i b) {
			__m128i p = libdivide__mullhi_u32_flat_vector(a, b);
			__m128i x = _mm_srai_epi32!(a, 31);
			__m128i t1 = _mm_and_si128!(x, b); //t1 = (a >> 31) & y, arithmetic shift
			__m128i y = _mm_srai_epi32!(b, 31);
			__m128i t2 = _mm_and_si128!(y, a);
			p = _mm_sub_epi32!(p, t1);
			p = _mm_sub_epi32!(p, t2);
			return p;
		}
	}
}

static int32_t libdivide__count_trailing_zeros32(uint32_t val) {
	import core.bitop : bsf;
	return bsf(val);
}

static int32_t libdivide__count_trailing_zeros64(uint64_t val) {
	import core.bitop : bsf;

	static if (typeof(val).sizeof <= size_t.sizeof) {
		return bsf(val);
	} else {
		/* Pretty good way to count trailing zeros.  Note that this hangs for val = 0! */
		uint32_t lo = val & 0xFFFFFFFF;
		if (lo != 0) return libdivide__count_trailing_zeros32(lo);
		return 32 + libdivide__count_trailing_zeros32(val >> 32);
	}
}

static int32_t libdivide__count_leading_zeros32(uint32_t val) {
	import core.bitop : bsr;
	return 31 - bsr(val);
}

static int32_t libdivide__count_leading_zeros64(uint64_t val) {
	import core.bitop : bsr;

	static if (typeof(val).sizeof <= size_t.sizeof) {
		return bsr(val);
	} else {
		uint32_t hi = val >> 32;
		if (hi != 0) return libdivide__count_leading_zeros32(hi);
		return 32 + libdivide__count_leading_zeros32(val & 0xFFFFFFFF);
	}
}

//libdivide_64_div_32_to_32: divides a 64 bit uint {u1, u0} by a 32 bit uint {v}.  The result must fit in 32 bits.  Returns the quotient directly and the remainder in *r
version (X86_GCC_ASM) {
	static uint32_t libdivide_64_div_32_to_32(uint32_t u1, uint32_t u0, uint32_t v, uint32_t *r) {
		uint32_t result;
		asm {
			"divl %[v]"
			: "=a"(result), "=d"(*r)
			: [v] "r"(v), "a"(u0), "d"(u1)
			;
		}
		return result;
	}
} else {
	static uint32_t libdivide_64_div_32_to_32(uint32_t u1, uint32_t u0, uint32_t v, uint32_t *r) {
		uint64_t n = ((cast(uint64_t)u1) << 32) | u0;
		uint32_t result = cast(uint32_t)(n / v);
		*r = cast(uint32_t)(n - result * cast(uint64_t)v);
		return result;
	}
}

version (X64_GCC_ASM) {
	static uint64_t libdivide_128_div_64_to_64(uint64_t u1, uint64_t u0, uint64_t v, uint64_t *r) {
		//u0 -> rax
		//u1 -> rdx
		//divq
		uint64_t result;
		asm {
			"divq %[v]"
			: "=a"(result), "=d"(*r)
			: [v] "r"(v), "a"(u0), "d"(u1)
			;
		}
		return result;

	}
} else {

	/* Code taken from Hacker's Delight, http://www.hackersdelight.org/HDcode/divlu.c .  License permits inclusion here per http://www.hackersdelight.org/permissions.htm
	 */
	static uint64_t libdivide_128_div_64_to_64(uint64_t u1, uint64_t u0, uint64_t v, uint64_t *r) {
		const uint64_t b = (1UL << 32); // Number base (16 bits).
		uint64_t un1, un0,        // Norm. dividend LSD's.
			 vn1, vn0,        // Norm. divisor digits.
			 q1, q0,          // Quotient digits.
			 un64, un21, un10,// Dividend digit pairs.
			 rhat;            // A remainder.
		int s;                  // Shift amount for norm.

		if (u1 >= v) {            // If overflow, set rem.
			if (r != null)         // to an impossible value,
				*r = cast(uint64_t)(-1);    // and return the largest
			return cast(uint64_t)(-1);}    // possible quotient.

		/* count leading zeros */
		s = libdivide__count_leading_zeros64(v); // 0 <= s <= 63.
		if (s > 0) {
			v = v << s;           // Normalize divisor.
			un64 = (u1 << s) | ((u0 >> (64 - s)) & (-s >> 31));
			un10 = u0 << s;       // Shift dividend left.
		} else {
			// Avoid undefined behavior.
			un64 = u1 | u0;
			un10 = u0;
		}

		vn1 = v >> 32;            // Break divisor up into
		vn0 = v & 0xFFFFFFFF;     // two 32-bit digits.

		un1 = un10 >> 32;         // Break right half of
		un0 = un10 & 0xFFFFFFFF;  // dividend into two digits.

		q1 = un64/vn1;            // Compute the first
		rhat = un64 - q1*vn1;     // quotient digit, q1.
again1:
		if (q1 >= b || q1*vn0 > b*rhat + un1) {
			q1 = q1 - 1;
			rhat = rhat + vn1;
			if (rhat < b) goto again1;}

		un21 = un64*b + un1 - q1*v;  // Multiply and subtract.

		q0 = un21/vn1;            // Compute the second
		rhat = un21 - q0*vn1;     // quotient digit, q0.
again2:
		if (q0 >= b || q0*vn0 > b*rhat + un0) {
			q0 = q0 - 1;
			rhat = rhat + vn1;
			if (rhat < b) goto again2;}

		if (r != null)            // If remainder is wanted,
			*r = (un21*b + un0 - q0*v) >> s;     // return it.
		return q1*b + q0;
	}
}

void LIBDIVIDE_ASSERT(bool x) {
	version (LIBDIVIDE_ASSERTIONS_ON) {
		enforce(x);
	}
	x = x; // Shut gcc up.
}

version (LIBDIVIDE_HEADER_ONLY) {
} else {

////////// UINT32

	libdivide_u32_t libdivide_u32_gen(uint32_t d) {
		libdivide_u32_t result;
		if ((d & (d - 1)) == 0) {
			result.magic = 0;
			result.more = cast(typeof(result.more))(libdivide__count_trailing_zeros32(d) | LIBDIVIDE_U32_SHIFT_PATH);
		}
		else {
			const uint32_t floor_log_2_d = 31 - libdivide__count_leading_zeros32(d);

			uint8_t more;
			uint32_t rem, proposed_m;
			proposed_m = libdivide_64_div_32_to_32(1U << floor_log_2_d, 0, d, &rem);

			LIBDIVIDE_ASSERT(rem > 0 && rem < d);
			const uint32_t e = d - rem;

			/* This power works if e < 2**floor_log_2_d. */
			if (e < (1U << floor_log_2_d)) {
				/* This power works */
				more = cast(typeof(more))floor_log_2_d;
			}
			else {
				/* We have to use the general 33-bit algorithm.  We need to compute (2**power) / d. However, we already have (2**(power-1))/d and its remainder.  By doubling both, and then correcting the remainder, we can compute the larger division. */
				proposed_m += proposed_m; //don't care about overflow here - in fact, we expect it
				const uint32_t twice_rem = rem + rem;
				if (twice_rem >= d || twice_rem < rem) proposed_m += 1;
				more = cast(typeof(more))(floor_log_2_d | LIBDIVIDE_ADD_MARKER);
			}
			result.magic = 1 + proposed_m;
			result.more = more;
			//result.more's shift should in general be ceil_log_2_d.  But if we used the smaller power, we subtract one from the shift because we're using the smaller power. If we're using the larger power, we subtract one from the shift because it's taken care of by the add indicator.  So floor_log_2_d happens to be correct in both cases.

		}
		return result;
	}

	uint32_t libdivide_u32_do(uint32_t numer, const libdivide_u32_t *denom) {
		uint8_t more = denom.more;
		if (more & LIBDIVIDE_U32_SHIFT_PATH) {
			return numer >> (more & LIBDIVIDE_32_SHIFT_MASK);
		}
		else {
			uint32_t q = libdivide__mullhi_u32(denom.magic, numer);
			if (more & LIBDIVIDE_ADD_MARKER) {
				uint32_t t = ((numer - q) >> 1) + q;
				return t >> (more & LIBDIVIDE_32_SHIFT_MASK);
			}
			else {
				return q >> more; //all upper bits are 0 - don't need to mask them off
			}
		}
	}


	int libdivide_u32_get_algorithm(const libdivide_u32_t *denom) {
		uint8_t more = denom.more;
		if (more & LIBDIVIDE_U32_SHIFT_PATH) return 0;
		else if (! (more & LIBDIVIDE_ADD_MARKER)) return 1;
		else return 2;
	}

	uint32_t libdivide_u32_do_alg0(uint32_t numer, const libdivide_u32_t *denom) {
		return numer >> (denom.more & LIBDIVIDE_32_SHIFT_MASK);
	}

	uint32_t libdivide_u32_do_alg1(uint32_t numer, const libdivide_u32_t *denom) {
		uint32_t q = libdivide__mullhi_u32(denom.magic, numer);
		return q >> denom.more;
	}

	uint32_t libdivide_u32_do_alg2(uint32_t numer, const libdivide_u32_t *denom) {
		// denom.add != 0
		uint32_t q = libdivide__mullhi_u32(denom.magic, numer);
		uint32_t t = ((numer - q) >> 1) + q;
		return t >> (denom.more & LIBDIVIDE_32_SHIFT_MASK);
	}




	version (LIBDIVIDE_USE_SSE2) {
		__m128i libdivide_u32_do_vector(__m128i numers, const libdivide_u32_t *denom) {
			uint8_t more = denom.more;
			if (more & LIBDIVIDE_U32_SHIFT_PATH) {
				__m128i a = libdivide_u32_to_m128i(more & LIBDIVIDE_32_SHIFT_MASK);
				return _mm_srl_epi32!(numers, a);
			}
			else {
				uint32_t a = denom.magic;
				__m128i b = _mm_set1_epi32!(a);
				__m128i q = libdivide__mullhi_u32_flat_vector(numers, b);
				if (more & LIBDIVIDE_ADD_MARKER) {
					//uint32_t t = ((numer - q) >> 1) + q;
					//return t >> denom.shift;
					__m128i c = _mm_sub_epi32!(numers, q);
					__m128i d = _mm_srli_epi32!(c, 1);
					__m128i t = _mm_add_epi32!(d, q);
					__m128i e = libdivide_u32_to_m128i(more & LIBDIVIDE_32_SHIFT_MASK);
					return _mm_srl_epi32!(t, e);

				}
				else {
					//q >> denom.shift
					__m128i c = libdivide_u32_to_m128i(more);
					return _mm_srl_epi32!(q, c);
				}
			}
		}

		__m128i libdivide_u32_do_vector_alg0(__m128i numers, const libdivide_u32_t *denom) {
			__m128i a = libdivide_u32_to_m128i(denom.more & LIBDIVIDE_32_SHIFT_MASK);
			return _mm_srl_epi32!(numers, a);
		}

		__m128i libdivide_u32_do_vector_alg1(__m128i numers, const libdivide_u32_t *denom) {
			uint32_t a = denom.magic;
			__m128i b = _mm_set1_epi32!(a);
			__m128i q = libdivide__mullhi_u32_flat_vector(numers, b);
			__m128i c = libdivide_u32_to_m128i(denom.more);
			return _mm_srl_epi32!(q, c);
		}

		__m128i libdivide_u32_do_vector_alg2(__m128i numers, const libdivide_u32_t *denom) {
			uint32_t a = denom.magic;
			__m128i b = _mm_set1_epi32!(a);
			__m128i q = libdivide__mullhi_u32_flat_vector(numers, b);
			__m128i c = _mm_sub_epi32!(numers, q);
			__m128i d = _mm_srli_epi32!(c, 1);
			__m128i t = _mm_add_epi32!(d, q);
			__m128i e = libdivide_u32_to_m128i(denom.more & LIBDIVIDE_32_SHIFT_MASK);
			return _mm_srl_epi32!(t, e);
		}

	}

	/////////// UINT64

	libdivide_u64_t libdivide_u64_gen(uint64_t d) {
		libdivide_u64_t result;
		if ((d & (d - 1)) == 0) {
			result.more = cast(typeof(result.more))(libdivide__count_trailing_zeros64(d) | LIBDIVIDE_U64_SHIFT_PATH);
			result.magic = 0;
		}
		else {
			const uint32_t floor_log_2_d = 63 - libdivide__count_leading_zeros64(d);

			uint64_t proposed_m, rem;
			uint8_t more;
			proposed_m = libdivide_128_div_64_to_64(1UL << floor_log_2_d, 0, d, &rem); //== (1 << (64 + floor_log_2_d)) / d

			LIBDIVIDE_ASSERT(rem > 0 && rem < d);
			const uint64_t e = d - rem;

			/* This power works if e < 2**floor_log_2_d. */
			if (e < (1UL << floor_log_2_d)) {
				/* This power works */
				more = cast(typeof(more))floor_log_2_d;
			}
			else {
				/* We have to use the general 65-bit algorithm.  We need to compute (2**power) / d. However, we already have (2**(power-1))/d and its remainder.  By doubling both, and then correcting the remainder, we can compute the larger division. */
				proposed_m += proposed_m; //don't care about overflow here - in fact, we expect it
				const uint64_t twice_rem = rem + rem;
				if (twice_rem >= d || twice_rem < rem) proposed_m += 1;
				more = cast(typeof(more))(floor_log_2_d | LIBDIVIDE_ADD_MARKER);
			}
			result.magic = 1 + proposed_m;
			result.more = more;
			//result.more's shift should in general be ceil_log_2_d.  But if we used the smaller power, we subtract one from the shift because we're using the smaller power. If we're using the larger power, we subtract one from the shift because it's taken care of by the add indicator.  So floor_log_2_d happens to be correct in both cases, which is why we do it outside of the if statement.
		}
		return result;
	}

	uint64_t libdivide_u64_do(uint64_t numer, const libdivide_u64_t *denom) {
		uint8_t more = denom.more;
		if (more & LIBDIVIDE_U64_SHIFT_PATH) {
			return numer >> (more & LIBDIVIDE_64_SHIFT_MASK);
		}
		else {
			uint64_t q = libdivide__mullhi_u64(denom.magic, numer);
			if (more & LIBDIVIDE_ADD_MARKER) {
				uint64_t t = ((numer - q) >> 1) + q;
				return t >> (more & LIBDIVIDE_64_SHIFT_MASK);
			}
			else {
				return q >> more; //all upper bits are 0 - don't need to mask them off
			}
		}
	}


	int libdivide_u64_get_algorithm(const libdivide_u64_t *denom) {
		uint8_t more = denom.more;
		if (more & LIBDIVIDE_U64_SHIFT_PATH) return 0;
		else if (! (more & LIBDIVIDE_ADD_MARKER)) return 1;
		else return 2;
	}

	uint64_t libdivide_u64_do_alg0(uint64_t numer, const libdivide_u64_t *denom) {
		return numer >> (denom.more & LIBDIVIDE_64_SHIFT_MASK);
	}

	uint64_t libdivide_u64_do_alg1(uint64_t numer, const libdivide_u64_t *denom) {
		uint64_t q = libdivide__mullhi_u64(denom.magic, numer);
		return q >> denom.more;
	}

	uint64_t libdivide_u64_do_alg2(uint64_t numer, const libdivide_u64_t *denom) {
		uint64_t q = libdivide__mullhi_u64(denom.magic, numer);
		uint64_t t = ((numer - q) >> 1) + q;
		return t >> (denom.more & LIBDIVIDE_64_SHIFT_MASK);
	}

	version (LIBDIVIDE_USE_SSE2) {
		__m128i libdivide_u64_do_vector(__m128i numers, const libdivide_u64_t * denom) {
			uint8_t more = denom.more;
			if (more & LIBDIVIDE_U64_SHIFT_PATH) {
				__m128i a = libdivide_u32_to_m128i(more & LIBDIVIDE_64_SHIFT_MASK);
				return _mm_srl_epi64!(numers, a);
			}
			else {
				__m128i q = libdivide_mullhi_u64_flat_vector(numers, libdivide__u64_to_m128(denom.magic));
				if (more & LIBDIVIDE_ADD_MARKER) {
					//uint32_t t = ((numer - q) >> 1) + q;
					//return t >> denom.shift;
					__m128i a = _mm_sub_epi64!(numers, q);
					__m128i b = _mm_srli_epi64!(a, 1);
					__m128i t = _mm_add_epi64!(b, q);
					__m128i c = libdivide_u32_to_m128i(more & LIBDIVIDE_64_SHIFT_MASK);
					return _mm_srl_epi64!(t, c);
				}
				else {
					//q >> denom.shift
					__m128i a = libdivide_u32_to_m128i(more);
					return _mm_srl_epi64!(q, a);
				}
			}
		}

		__m128i libdivide_u64_do_vector_alg0(__m128i numers, const libdivide_u64_t *denom) {
			__m128i a = libdivide_u32_to_m128i(denom.more & LIBDIVIDE_64_SHIFT_MASK);
			return _mm_srl_epi64!(numers, a);
		}

		__m128i libdivide_u64_do_vector_alg1(__m128i numers, const libdivide_u64_t *denom) {
			__m128i q = libdivide_mullhi_u64_flat_vector(numers, libdivide__u64_to_m128(denom.magic));
			__m128i a = libdivide_u32_to_m128i(denom.more);
			return _mm_srl_epi64!(q, a);
		}

		__m128i libdivide_u64_do_vector_alg2(__m128i numers, const libdivide_u64_t *denom) {
			__m128i q = libdivide_mullhi_u64_flat_vector(numers, libdivide__u64_to_m128(denom.magic));
			__m128i a = _mm_sub_epi64!(numers, q);
			__m128i b = _mm_srli_epi64!(a, 1);
			__m128i t = _mm_add_epi64!(b, q);
			__m128i c = libdivide_u32_to_m128i(denom.more & LIBDIVIDE_64_SHIFT_MASK);
			return _mm_srl_epi64!(t, c);
		}


	}

	/////////// SINT32


	static int32_t libdivide__mullhi_s32(int32_t x, int32_t y) {
		int64_t xl = x, yl = y;
		int64_t rl = xl * yl;
		return cast(int32_t)(rl >> 32); //needs to be arithmetic shift
	}

	libdivide_s32_t libdivide_s32_gen(int32_t d) {
		libdivide_s32_t result;

		/* If d is a power of 2, or negative a power of 2, we have to use a shift.  This is especially important because the magic algorithm fails for -1.  To check if d is a power of 2 or its inverse, it suffices to check whether its absolute value has exactly one bit set.  This works even for INT_MIN, because abs(INT_MIN) == INT_MIN, and INT_MIN has one bit set and is a power of 2.  */
		uint32_t absD = cast(uint32_t)(d < 0 ? -d : d); //gcc optimizes this to the fast abs trick
		if ((absD & (absD - 1)) == 0) { //check if exactly one bit is set, don't care if absD is 0 since that's divide by zero
			result.magic = 0;
			result.more = cast(typeof(result.more))(libdivide__count_trailing_zeros32(absD) | (d < 0 ? LIBDIVIDE_NEGATIVE_DIVISOR : 0) | LIBDIVIDE_S32_SHIFT_PATH);
		}
		else {
			const uint32_t floor_log_2_d = 31 - libdivide__count_leading_zeros32(absD);
			LIBDIVIDE_ASSERT(floor_log_2_d >= 1);

			uint8_t more;
			//the dividend here is 2**(floor_log_2_d + 31), so the low 32 bit word is 0 and the high word is floor_log_2_d - 1
			uint32_t rem, proposed_m;
			proposed_m = libdivide_64_div_32_to_32(1U << (floor_log_2_d - 1), 0, absD, &rem);
			const uint32_t e = absD - rem;

			/* We are going to start with a power of floor_log_2_d - 1.  This works if works if e < 2**floor_log_2_d. */
			if (e < (1U << floor_log_2_d)) {
				/* This power works */
				more = cast(typeof(more))(floor_log_2_d - 1);
			}
			else {
				/* We need to go one higher.  This should not make proposed_m overflow, but it will make it negative when interpreted as an int32_t. */
				proposed_m += proposed_m;
				const uint32_t twice_rem = rem + rem;
				if (twice_rem >= absD || twice_rem < rem) proposed_m += 1;
				more = cast(typeof(more))(floor_log_2_d | LIBDIVIDE_ADD_MARKER | (d < 0 ? LIBDIVIDE_NEGATIVE_DIVISOR : 0)); //use the general algorithm
			}
			proposed_m += 1;
			result.magic = (d < 0 ? -cast(int32_t)proposed_m : cast(int32_t)proposed_m);
			result.more = more;

		}
		return result;
	}

	int32_t libdivide_s32_do(int32_t numer, const libdivide_s32_t *denom) {
		uint8_t more = denom.more;
		if (more & LIBDIVIDE_S32_SHIFT_PATH) {
			uint8_t shifter = more & LIBDIVIDE_32_SHIFT_MASK;
			int32_t q = numer + ((numer >> 31) & ((1 << shifter) - 1));
			q = q >> shifter;
			int32_t shiftMask = cast(int8_t)more >> 7; //must be arithmetic shift and then sign-extend
			q = (q ^ shiftMask) - shiftMask;
			return q;
		}
		else {
			int32_t q = libdivide__mullhi_s32(denom.magic, numer);
			if (more & LIBDIVIDE_ADD_MARKER) {
				int32_t sign = cast(int8_t)more >> 7; //must be arithmetic shift and then sign extend
				q += ((numer ^ sign) - sign);
			}
			q >>= more & LIBDIVIDE_32_SHIFT_MASK;
			q += (q < 0);
			return q;
		}
	}

	int libdivide_s32_get_algorithm(const libdivide_s32_t *denom) {
		uint8_t more = denom.more;
		int positiveDivisor = ! (more & LIBDIVIDE_NEGATIVE_DIVISOR);
		if (more & LIBDIVIDE_S32_SHIFT_PATH) return (positiveDivisor ? 0 : 1);
		else if (more & LIBDIVIDE_ADD_MARKER) return (positiveDivisor ? 2 : 3);
		else return 4;
	}

	int32_t libdivide_s32_do_alg0(int32_t numer, const libdivide_s32_t *denom) {
		uint8_t shifter = denom.more & LIBDIVIDE_32_SHIFT_MASK;
		int32_t q = numer + ((numer >> 31) & ((1 << shifter) - 1));
		return q >> shifter;
	}

	int32_t libdivide_s32_do_alg1(int32_t numer, const libdivide_s32_t *denom) {
		uint8_t shifter = denom.more & LIBDIVIDE_32_SHIFT_MASK;
		int32_t q = numer + ((numer >> 31) & ((1 << shifter) - 1));
		return - (q >> shifter);
	}

	int32_t libdivide_s32_do_alg2(int32_t numer, const libdivide_s32_t *denom) {
		int32_t q = libdivide__mullhi_s32(denom.magic, numer);
		q += numer;
		q >>= denom.more & LIBDIVIDE_32_SHIFT_MASK;
		q += (q < 0);
		return q;
	}

	int32_t libdivide_s32_do_alg3(int32_t numer, const libdivide_s32_t *denom) {
		int32_t q = libdivide__mullhi_s32(denom.magic, numer);
		q -= numer;
		q >>= denom.more & LIBDIVIDE_32_SHIFT_MASK;
		q += (q < 0);
		return q;
	}

	int32_t libdivide_s32_do_alg4(int32_t numer, const libdivide_s32_t *denom) {
		int32_t q = libdivide__mullhi_s32(denom.magic, numer);
		q >>= denom.more & LIBDIVIDE_32_SHIFT_MASK;
		q += (q < 0);
		return q;
	}

	version (LIBDIVIDE_USE_SSE2) {
		__m128i libdivide_s32_do_vector(__m128i numers, const libdivide_s32_t * denom) {
			uint8_t more = denom.more;
			if (more & LIBDIVIDE_S32_SHIFT_PATH) {
				uint32_t shifter = more & LIBDIVIDE_32_SHIFT_MASK;
				int a = (1 << shifter) - 1;
				__m128i roundToZeroTweak = _mm_set1_epi32!(a); //could use _mm_srli_epi32! with an all -1 register
				__m128i b = _mm_srai_epi32!(numers, 31);
				__m128i c = _mm_and_si128!(b, roundToZeroTweak);
				__m128i q = _mm_add_epi32!(numers, c); //q = numer + ((numer >> 31) & roundToZeroTweak);
				__m128i d = libdivide_u32_to_m128i(shifter);
				q = _mm_sra_epi32!(q, d); // q = q >> shifter
				uint32_t e = cast(int32_t)(cast(int8_t)more >> 7);
				__m128i shiftMask = _mm_set1_epi32!(e); //set all bits of shift mask = to the sign bit of more
				__m128i f = _mm_xor_si128!(q, shiftMask);
				q = _mm_sub_epi32!(f, shiftMask); //q = (q ^ shiftMask) - shiftMask;
				return q;
			} else {
				uint32_t a = denom.magic;
				__m128i q = libdivide_mullhi_s32_flat_vector(numers, _mm_set1_epi32!(a));
				if (more & LIBDIVIDE_ADD_MARKER) {
					uint32_t b = cast(int32_t)cast(int8_t)more >> 7;
					__m128i sign = _mm_set1_epi32!(b); //must be arithmetic shift
					__m128i c = _mm_xor_si128!(numers, sign);
					__m128i d = _mm_sub_epi32!(c, sign);
					q = _mm_add_epi32!(q, d); // q += ((numer ^ sign) - sign);
				}
				__m128i b = libdivide_u32_to_m128i(more & LIBDIVIDE_32_SHIFT_MASK);
				q = _mm_sra_epi32!(q, b); //q >>= shift
				__m128i c = _mm_srli_epi32!(q, 31);
				q = _mm_add_epi32!(q, c); // q += (q < 0)
				return q;
			}
		}

		__m128i libdivide_s32_do_vector_alg0(__m128i numers, const libdivide_s32_t *denom) {
			uint8_t shifter = denom.more & LIBDIVIDE_32_SHIFT_MASK;
			int a = (1 << shifter) - 1;
			__m128i roundToZeroTweak = _mm_set1_epi32!(a);
			__m128i b = _mm_srai_epi32!(numers, 31);
			__m128i c = _mm_and_si128!(b, roundToZeroTweak);
			__m128i q = _mm_add_epi32!(numers, c);
			__m128i d = libdivide_u32_to_m128i(shifter);
			return _mm_sra_epi32!(q, d);
		}

		__m128i libdivide_s32_do_vector_alg1(__m128i numers, const libdivide_s32_t *denom) {
			uint8_t shifter = denom.more & LIBDIVIDE_32_SHIFT_MASK;
			int a = (1 << shifter) - 1;
			__m128i roundToZeroTweak = _mm_set1_epi32!(a);
			__m128i b = _mm_srai_epi32!(numers, 31);
			__m128i c = _mm_and_si128!(b, roundToZeroTweak);
			__m128i q = _mm_add_epi32!(numers, c);
			__m128i d = libdivide_u32_to_m128i(shifter);
			__m128i e = _mm_sra_epi32!(q, d);
			__m128i z = _mm_setzero_si128!();
			return _mm_sub_epi32!(z, e);
		}

		__m128i libdivide_s32_do_vector_alg2(__m128i numers, const libdivide_s32_t *denom) {
			int a = denom.magic;
			__m128i q = libdivide_mullhi_s32_flat_vector(numers, _mm_set1_epi32!(a));
			q = _mm_add_epi32!(q, numers);
			__m128i b = libdivide_u32_to_m128i(denom.more & LIBDIVIDE_32_SHIFT_MASK);
			q = _mm_sra_epi32!(q, b);
			__m128i c = _mm_srli_epi32!(q, 31);
			q = _mm_add_epi32!(q, c);
			return q;
		}

		__m128i libdivide_s32_do_vector_alg3(__m128i numers, const libdivide_s32_t *denom) {
			int a = denom.magic;
			__m128i q = libdivide_mullhi_s32_flat_vector(numers, _mm_set1_epi32!(a));
			q = _mm_sub_epi32!(q, numers);
			__m128i b = libdivide_u32_to_m128i(denom.more & LIBDIVIDE_32_SHIFT_MASK);
			q = _mm_sra_epi32!(q, b);
			__m128i c = _mm_srli_epi32!(q, 31);
			q = _mm_add_epi32!(q, c);
			return q;
		}

		__m128i libdivide_s32_do_vector_alg4(__m128i numers, const libdivide_s32_t *denom) {
			int a = denom.magic;
			__m128i q = libdivide_mullhi_s32_flat_vector(numers, _mm_set1_epi32!(a));
			__m128i b = libdivide_u32_to_m128i(denom.more);
			q = _mm_sra_epi32!(q, b); //q >>= shift
			__m128i c = _mm_srli_epi32!(q, 31);
			q = _mm_add_epi32!(q, c); // q += (q < 0)
			return q;
		}
	}

	///////////// SINT64


	libdivide_s64_t libdivide_s64_gen(int64_t d) {
		libdivide_s64_t result;

		/* If d is a power of 2, or negative a power of 2, we have to use a shift.  This is especially important because the magic algorithm fails for -1.  To check if d is a power of 2 or its inverse, it suffices to check whether its absolute value has exactly one bit set.  This works even for INT_MIN, because abs(INT_MIN) == INT_MIN, and INT_MIN has one bit set and is a power of 2.  */
		const uint64_t absD = cast(uint64_t)(d < 0 ? -d : d); //gcc optimizes this to the fast abs trick
		if ((absD & (absD - 1)) == 0) { //check if exactly one bit is set, don't care if absD is 0 since that's divide by zero
			result.more = cast(typeof(result.more))(libdivide__count_trailing_zeros64(absD) | (d < 0 ? LIBDIVIDE_NEGATIVE_DIVISOR : 0));
			result.magic = 0;
		}
		else {
			const uint32_t floor_log_2_d = 63 - libdivide__count_leading_zeros64(absD);

			//the dividend here is 2**(floor_log_2_d + 63), so the low 64 bit word is 0 and the high word is floor_log_2_d - 1
			uint8_t more;
			uint64_t rem, proposed_m;
			proposed_m = libdivide_128_div_64_to_64(1UL << (floor_log_2_d - 1), 0, absD, &rem);
			const uint64_t e = absD - rem;

			/* We are going to start with a power of floor_log_2_d - 1.  This works if works if e < 2**floor_log_2_d. */
			if (e < (1UL << floor_log_2_d)) {
				/* This power works */
				more = cast(typeof(more))(floor_log_2_d - 1);
			}
			else {
				/* We need to go one higher.  This should not make proposed_m overflow, but it will make it negative when interpreted as an int32_t. */
				proposed_m += proposed_m;
				const uint64_t twice_rem = rem + rem;
				if (twice_rem >= absD || twice_rem < rem) proposed_m += 1;
				more = cast(typeof(more))(floor_log_2_d | LIBDIVIDE_ADD_MARKER | (d < 0 ? LIBDIVIDE_NEGATIVE_DIVISOR : 0));
			}
			proposed_m += 1;
			result.more = more;
			result.magic = (d < 0 ? -cast(int64_t)proposed_m : cast(int64_t)proposed_m);
		}
		return result;
	}

	int64_t libdivide_s64_do(int64_t numer, const libdivide_s64_t *denom) {
		uint8_t more = denom.more;
		int64_t magic = denom.magic;
		if (magic == 0) { //shift path
			uint32_t shifter = more & LIBDIVIDE_64_SHIFT_MASK;
			int64_t q = numer + ((numer >> 63) & ((1L << shifter) - 1));
			q = q >> shifter;
			int64_t shiftMask = cast(int8_t)more >> 7; //must be arithmetic shift and then sign-extend
			q = (q ^ shiftMask) - shiftMask;
			return q;
		}
		else {
			int64_t q = libdivide__mullhi_s64(magic, numer);
			if (more & LIBDIVIDE_ADD_MARKER) {
				int64_t sign = cast(int8_t)more >> 7; //must be arithmetic shift and then sign extend
				q += ((numer ^ sign) - sign);
			}
			q >>= more & LIBDIVIDE_64_SHIFT_MASK;
			q += (q < 0);
			return q;
		}
	}


	int libdivide_s64_get_algorithm(const libdivide_s64_t *denom) {
		uint8_t more = denom.more;
		int positiveDivisor = ! (more & LIBDIVIDE_NEGATIVE_DIVISOR);
		if (denom.magic == 0) return (positiveDivisor ? 0 : 1); //shift path
		else if (more & LIBDIVIDE_ADD_MARKER) return (positiveDivisor ? 2 : 3);
		else return 4;
	}

	int64_t libdivide_s64_do_alg0(int64_t numer, const libdivide_s64_t *denom) {
		uint32_t shifter = denom.more & LIBDIVIDE_64_SHIFT_MASK;
		int64_t q = numer + ((numer >> 63) & ((1L << shifter) - 1));
		return q >> shifter;
	}

	int64_t libdivide_s64_do_alg1(int64_t numer, const libdivide_s64_t *denom) {
		//denom.shifter != -1 && demo.shiftMask != 0
		uint32_t shifter = denom.more & LIBDIVIDE_64_SHIFT_MASK;
		int64_t q = numer + ((numer >> 63) & ((1L << shifter) - 1));
		return - (q >> shifter);
	}

	int64_t libdivide_s64_do_alg2(int64_t numer, const libdivide_s64_t *denom) {
		int64_t q = libdivide__mullhi_s64(denom.magic, numer);
		q += numer;
		q >>= denom.more & LIBDIVIDE_64_SHIFT_MASK;
		q += (q < 0);
		return q;
	}

	int64_t libdivide_s64_do_alg3(int64_t numer, const libdivide_s64_t *denom) {
		int64_t q = libdivide__mullhi_s64(denom.magic, numer);
		q -= numer;
		q >>= denom.more & LIBDIVIDE_64_SHIFT_MASK;
		q += (q < 0);
		return q;
	}

	int64_t libdivide_s64_do_alg4(int64_t numer, const libdivide_s64_t *denom) {
		int64_t q = libdivide__mullhi_s64(denom.magic, numer);
		q >>= denom.more;
		q += (q < 0);
		return q;
	}


	version (LIBDIVIDE_USE_SSE2) {
		__m128i libdivide_s64_do_vector(__m128i numers, const libdivide_s64_t * denom) {
			uint8_t more = denom.more;
			int64_t magic = denom.magic;
			if (magic == 0) { //shift path
				uint32_t shifter = more & LIBDIVIDE_64_SHIFT_MASK;
				__m128i roundToZeroTweak = libdivide__u64_to_m128((1L << shifter) - 1);
				__m128i a = libdivide_s64_signbits(numers);
				__m128i b = _mm_and_si128!(a, roundToZeroTweak);
				__m128i q = _mm_add_epi64!(numers, b); //q = numer + ((numer >> 63) & roundToZeroTweak);
				q = libdivide_s64_shift_right_vector(q, shifter); // q = q >> shifter
				int c = cast(int32_t)(cast(int8_t)more >> 7);
				__m128i shiftMask = _mm_set1_epi32!(c);
				__m128i d = _mm_xor_si128!(q, shiftMask);
				q = _mm_sub_epi64!(d, shiftMask); //q = (q ^ shiftMask) - shiftMask;
				return q;
			}
			else {
				__m128i q = libdivide_mullhi_s64_flat_vector(numers, libdivide__u64_to_m128(magic));
				if (more & LIBDIVIDE_ADD_MARKER) {
					int a = cast(int32_t)(cast(int8_t)more >> 7);
					__m128i sign = _mm_set1_epi32!(a); //must be arithmetic shift
					__m128i b = _mm_xor_si128!(numers, sign);
					__m128i c = _mm_sub_epi64!(b, sign);
					q = _mm_add_epi64!(q, c); // q += ((numer ^ sign) - sign);
				}
				q = libdivide_s64_shift_right_vector(q, more & LIBDIVIDE_64_SHIFT_MASK); //q >>= denom.mult_path.shift
				__m128i a = _mm_srli_epi64!(q, 63);
				q = _mm_add_epi64!(q, a); // q += (q < 0)
				return q;
			}
		}

		__m128i libdivide_s64_do_vector_alg0(__m128i numers, const libdivide_s64_t *denom) {
			uint32_t shifter = denom.more & LIBDIVIDE_64_SHIFT_MASK;
			__m128i roundToZeroTweak = libdivide__u64_to_m128((1L << shifter) - 1);
			__m128i a = libdivide_s64_signbits(numers);
			__m128i b = _mm_and_si128!(a, roundToZeroTweak);
			__m128i q = _mm_add_epi64!(numers, b);
			q = libdivide_s64_shift_right_vector(q, shifter);
			return q;
		}

		__m128i libdivide_s64_do_vector_alg1(__m128i numers, const libdivide_s64_t *denom) {
			uint32_t shifter = denom.more & LIBDIVIDE_64_SHIFT_MASK;
			__m128i roundToZeroTweak = libdivide__u64_to_m128((1L << shifter) - 1);
			__m128i a = libdivide_s64_signbits(numers);
			__m128i b = _mm_and_si128!(a, roundToZeroTweak);
			__m128i q = _mm_add_epi64!(numers, b);
			q = libdivide_s64_shift_right_vector(q, shifter);
			__m128i z = _mm_setzero_si128!();
			return _mm_sub_epi64!(z, q);
		}

		__m128i libdivide_s64_do_vector_alg2(__m128i numers, const libdivide_s64_t *denom) {
			__m128i q = libdivide_mullhi_s64_flat_vector(numers, libdivide__u64_to_m128(denom.magic));
			q = _mm_add_epi64!(q, numers);
			q = libdivide_s64_shift_right_vector(q, denom.more & LIBDIVIDE_64_SHIFT_MASK);
			__m128i a = _mm_srli_epi64!(q, 63);
			q = _mm_add_epi64!(q, a); // q += (q < 0)
			return q;
		}

		__m128i libdivide_s64_do_vector_alg3(__m128i numers, const libdivide_s64_t *denom) {
			__m128i q = libdivide_mullhi_s64_flat_vector(numers, libdivide__u64_to_m128(denom.magic));
			q = _mm_sub_epi64!(q, numers);
			q = libdivide_s64_shift_right_vector(q, denom.more & LIBDIVIDE_64_SHIFT_MASK);
			__m128i a = _mm_srli_epi64!(q, 63);
			q = _mm_add_epi64!(q, a); // q += (q < 0)
			return q;
		}

		__m128i libdivide_s64_do_vector_alg4(__m128i numers, const libdivide_s64_t *denom) {
			__m128i q = libdivide_mullhi_s64_flat_vector(numers, libdivide__u64_to_m128(denom.magic));
			q = libdivide_s64_shift_right_vector(q, denom.more);
			__m128i a = _mm_srli_epi64!(q, 63);
			q = _mm_add_epi64!(q, a);
			return q;
		}

	}

	/////////// C++ stuff^W^W D stuff

	/* The C++ template design here is a total mess.  This needs to be fixed by someone better at templates than I.  The current design is:

	   - The base is a template divider_base that takes the integer type, the libdivide struct, a generating function, a get algorithm function, a do function, and either a do vector function or a dummy int.
	   - The base has storage for the libdivide struct.  This is the only storage (so the C++ class should be no larger than the libdivide struct).

	   - Above that, there's divider_mid.  This is an empty struct by default, but it is specialized against our four int types.  divider_mid contains a template struct algo, that contains a typedef for a specialization of divider_base.  struct algo is specialized to take an "algorithm number," where -1 means to use the general algorithm.

	   - Publicly we have class divider, which inherits from divider_mid::algo.  This also take an algorithm number, which defaults to -1 (the general algorithm).
	   - divider has a operator / which allows you to use a divider as the divisor in a quotient expression.

	 */

	struct libdivide_internal {
	static:
		version (LIBDIVIDE_USE_SSE2) {
			/* D doesn't allow mixin directly in alias. */
			//alias MAYBE_VECTOR(string x) = mixin(x);
			template Alias(alias x) {alias Alias = x;}
			alias MAYBE_VECTOR(string x) = Alias!(mixin(x));
			alias MAYBE_VECTOR_PARAM(DenomType) = __m128i function(__m128i, const DenomType *);
		} else {
			enum MAYBE_VECTOR(string x) = 0;
			alias MAYBE_VECTOR_PARAM(DenomType) = int;
		}

		/* Some bogus unswitch functions for unsigned types so the same (presumably templated) code can work for both signed and unsigned. */
		uint32_t crash_u32(uint32_t, const libdivide_u32_t *) { abort(); return *cast(uint32_t*)null; }
		uint64_t crash_u64(uint64_t, const libdivide_u64_t *) { abort(); return *cast(uint64_t*)null; }
		version (LIBDIVIDE_USE_SSE2) {
			__m128i crash_u32_vector(__m128i, const libdivide_u32_t *) { abort(); return *cast(__m128i*)null; }
			__m128i crash_u64_vector(__m128i, const libdivide_u64_t *) { abort(); return *cast(__m128i*)null; }
		}

		struct divider_base(IntType, DenomType, alias gen_func, alias get_algo, alias do_func, alias vector_func)
		if (is(typeof(&gen_func) == DenomType function(IntType)) &&
		    is(typeof(&get_algo) == int function(const DenomType *)) &&
		    is(typeof(&do_func) == IntType function(IntType, const DenomType *)) &&
		    (is(typeof(&vector_func) == MAYBE_VECTOR_PARAM!DenomType) || vector_func == 0)) {
			public:
				DenomType denom;
				this(IntType d) { denom = gen_func(d); }
				this(const ref DenomType d) { denom = d; }

				IntType perform_divide(IntType val) const { return do_func(val, &denom); }
				version (LIBDIVIDE_USE_SSE2) {
					__m128i perform_divide_vector(__m128i val) const { return vector_func(val, &denom); }
				}

				int get_algorithm() const { return get_algo(&denom); }
		}


		//struct divider_mid(T) { }

		struct divider_mid(T : uint32_t) {
			alias IntType = uint32_t;
			alias DenomType = libdivide_u32_t;
			struct denom(alias do_func, alias vector_func)
			if (is(typeof(&do_func) == IntType function(IntType, const DenomType *)) &&
			    (is(typeof(&vector_func) == MAYBE_VECTOR_PARAM!DenomType) || vector_func == 0)) {
				alias divider = divider_base!(IntType, DenomType, libdivide_u32_gen, libdivide_u32_get_algorithm, do_func, vector_func);
			}

			//struct algo(int ALGO, int J = 0) { }
			struct algo(int ALGO : -1, int J = 0) { alias divider = denom!(libdivide_u32_do, MAYBE_VECTOR!"libdivide_u32_do_vector").divider; }
			struct algo(int ALGO : 0, int J = 0)  { alias divider = denom!(libdivide_u32_do_alg0, MAYBE_VECTOR!"libdivide_u32_do_vector_alg0").divider; }
			struct algo(int ALGO : 1, int J = 0)  { alias divider = denom!(libdivide_u32_do_alg1, MAYBE_VECTOR!"libdivide_u32_do_vector_alg1").divider; }
			struct algo(int ALGO : 2, int J = 0)  { alias divider = denom!(libdivide_u32_do_alg2, MAYBE_VECTOR!"libdivide_u32_do_vector_alg2").divider; }

			/* Define two more bogus ones so that the same (templated, presumably) code can handle both signed and unsigned */
			struct algo(int ALGO : 3, int J = 0)  { alias divider = denom!(crash_u32, MAYBE_VECTOR!"crash_u32_vector").divider; }
			struct algo(int ALGO : 4, int J = 0)  { alias divider = denom!(crash_u32, MAYBE_VECTOR!"crash_u32_vector").divider; }

		}

		struct divider_mid(T : int32_t) {
			alias IntType = int32_t;
			alias DenomType = libdivide_s32_t;
			struct denom(alias do_func, alias vector_func)
			if (is(typeof(&do_func) == IntType function(IntType, const DenomType *)) &&
			    (is(typeof(&vector_func) == MAYBE_VECTOR_PARAM!DenomType) || vector_func == 0)) {
				alias divider = divider_base!(IntType, DenomType, libdivide_s32_gen, libdivide_s32_get_algorithm, do_func, vector_func);
			}


			//struct algo(int ALGO, int J = 0) { };
			struct algo(int ALGO : -1, int J = 0) { alias divider = denom!(libdivide_s32_do, MAYBE_VECTOR!"libdivide_s32_do_vector").divider; }
			struct algo(int ALGO : 0, int J = 0)  { alias divider = denom!(libdivide_s32_do_alg0, MAYBE_VECTOR!"libdivide_s32_do_vector_alg0").divider; }
			struct algo(int ALGO : 1, int J = 0)  { alias divider = denom!(libdivide_s32_do_alg1, MAYBE_VECTOR!"libdivide_s32_do_vector_alg1").divider; }
			struct algo(int ALGO : 2, int J = 0)  { alias divider = denom!(libdivide_s32_do_alg2, MAYBE_VECTOR!"libdivide_s32_do_vector_alg2").divider; }
			struct algo(int ALGO : 3, int J = 0)  { alias divider = denom!(libdivide_s32_do_alg3, MAYBE_VECTOR!"libdivide_s32_do_vector_alg3").divider; }
			struct algo(int ALGO : 4, int J = 0)  { alias divider = denom!(libdivide_s32_do_alg4, MAYBE_VECTOR!"libdivide_s32_do_vector_alg4").divider; }

		}

		struct divider_mid(T : uint64_t) {
			alias IntType = uint64_t;
			alias DenomType = libdivide_u64_t;
			struct denom(alias do_func, alias vector_func)
			if (is(typeof(&do_func) == IntType function(IntType, const DenomType *)) &&
			    (is(typeof(&vector_func) == MAYBE_VECTOR_PARAM!DenomType) || vector_func == 0)) {
				alias divider = divider_base!(IntType, DenomType, libdivide_u64_gen, libdivide_u64_get_algorithm, do_func, vector_func);
			};

			//struct algo(int ALGO, int J = 0) { };
			struct algo(int ALGO : -1, int J = 0) { alias divider = denom!(libdivide_u64_do, MAYBE_VECTOR!"libdivide_u64_do_vector").divider; }
			struct algo(int ALGO : 0, int J = 0)  { alias divider = denom!(libdivide_u64_do_alg0, MAYBE_VECTOR!"libdivide_u64_do_vector_alg0").divider; }
			struct algo(int ALGO : 1, int J = 0)  { alias divider = denom!(libdivide_u64_do_alg1, MAYBE_VECTOR!"libdivide_u64_do_vector_alg1").divider; }
			struct algo(int ALGO : 2, int J = 0)  { alias divider = denom!(libdivide_u64_do_alg2, MAYBE_VECTOR!"libdivide_u64_do_vector_alg2").divider; }

			/* Define two more bogus ones so that the same (templated, presumably) code can handle both signed and unsigned */
			struct algo(int ALGO : 3, int J = 0)  { alias divider = denom!(crash_u64, MAYBE_VECTOR!"crash_u64_vector").divider; }
			struct algo(int ALGO : 4, int J = 0)  { alias divider = denom!(crash_u64, MAYBE_VECTOR!"crash_u64_vector").divider; }


		}

		struct divider_mid(T : int64_t) {
			alias IntType = int64_t;
			alias DenomType = libdivide_s64_t;
			struct denom(alias do_func, alias vector_func)
			if (is(typeof(&do_func) == IntType function(IntType, const DenomType *)) &&
			    (is(typeof(&vector_func) == MAYBE_VECTOR_PARAM!DenomType) || vector_func == 0)) {
				alias divider = divider_base!(IntType, DenomType, libdivide_s64_gen, libdivide_s64_get_algorithm, do_func, vector_func);
			};

			//struct algo(int ALGO, int J = 0) { };
			struct algo(int ALGO : -1, int J = 0) { alias divider = denom!(libdivide_s64_do, MAYBE_VECTOR!"libdivide_s64_do_vector").divider; }
			struct algo(int ALGO : 0, int J = 0)  { alias divider = denom!(libdivide_s64_do_alg0, MAYBE_VECTOR!"libdivide_s64_do_vector_alg0").divider; }
			struct algo(int ALGO : 1, int J = 0)  { alias divider = denom!(libdivide_s64_do_alg1, MAYBE_VECTOR!"libdivide_s64_do_vector_alg1").divider; }
			struct algo(int ALGO : 2, int J = 0)  { alias divider = denom!(libdivide_s64_do_alg2, MAYBE_VECTOR!"libdivide_s64_do_vector_alg2").divider; }
			struct algo(int ALGO : 3, int J = 0)  { alias divider = denom!(libdivide_s64_do_alg3, MAYBE_VECTOR!"libdivide_s64_do_vector_alg3").divider; }
			struct algo(int ALGO : 4, int J = 0)  { alias divider = denom!(libdivide_s64_do_alg4, MAYBE_VECTOR!"libdivide_s64_do_vector_alg4").divider; }
		}

	}

	struct divider(T, int ALGO = -1)
	{
	private:
		libdivide_internal.divider_mid!T.algo!ALGO.divider sub = typeof(sub)(1);
		divider!(S, NEW_ALGO) unswitch(int NEW_ALGO, S)(const ref divider!(S, -1) d);
		this(const ref libdivide_internal.divider_mid!T.DenomType denom) { sub = typeof(sub)(denom); }

	public:

		/* Ordinary constructor, that takes the divisor as a parameter. */
		this(T n) { sub = typeof(sub)(n); }

		/* Default constructor, that divides by 1 */
		//this() { sub = typeof(sub)(1); }

		/* Divides the parameter by the divisor, returning the quotient */
		T perform_divide(T val) const { return sub.perform_divide(val); }

		version (LIBDIVIDE_USE_SSE2) {
			/* Treats the vector as either two or four packed values (depending on the size), and divides each of them by the divisor, returning the packed quotients. */
			__m128i perform_divide_vector(__m128i val) const { return sub.perform_divide_vector(val); }
		}

		/* Returns the index of algorithm, for use in the unswitch function */
		int get_algorithm() const { return sub.get_algorithm(); } // returns the algorithm for unswitching

		/* operator== */
		bool opEquals(const ref divider!(T, ALGO) him) const { return sub.denom.magic == him.sub.denom.magic && sub.denom.more == him.sub.denom.more; }

		/* Overload of the / operator for scalar division. */
		T opBinaryRight(string op : "/")(T numer) const {
			return perform_divide(numer);
		}

		version (LIBDIVIDE_USE_SSE2) {
			/* Overload of the / operator for vector division. */
			__m128i opBinaryRight(string op : "/")(__m128i numer) const {
				return perform_divide_vector(numer);
			}
		}
	}

	/* Returns a divider specialized for the given algorithm. */
	divider!(S, NEW_ALGO) unswitch(int NEW_ALGO, S)(const ref divider!(S, -1) d) { return divider!(S, NEW_ALGO)(d.sub.denom); }


}
