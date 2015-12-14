/* Header code adapted from SDL_rwops.h */
module sdl.rwops;

import core.stdc.stdint;

extern (C) {
/*
    SDL - Simple DirectMedia Layer
    Copyright (C) 1997-2012 Sam Lantinga

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

    Sam Lantinga
    slouken@libsdl.org
*/

/** @file SDL_rwops.h
 *  This file provides a general interface for SDL to read and write
 *  data sources.  It can easily be extended to files, memory, etc.
 */

/* Won't be used. */
struct FILE;

/** This is the read/write operation structure -- very basic */

struct SDL_RWops {
	/** Seek to 'offset' relative to whence, one of stdio's whence values:
	 *	SEEK_SET, SEEK_CUR, SEEK_END
	 *  Returns the final offset in the data source.
	 */
	int function(SDL_RWops *context, int offset, int whence) seek;

	/** Read up to 'maxnum' objects each of size 'size' from the data
	 *  source to the area pointed at by 'ptr'.
	 *  Returns the number of objects read, or -1 if the read failed.
	 */
	int function(SDL_RWops *context, void *ptr, int size, int maxnum) read;

	/** Write exactly 'num' objects each of size 'objsize' from the area
	 *  pointed at by 'ptr' to data source.
	 *  Returns 'num', or -1 if the write failed.
	 */
	int function(SDL_RWops *context, const void *ptr, int size, int num) write;

	/** Close and free an allocated SDL_FSops structure */
	int function(SDL_RWops *context) close;

	uint32_t type;
	union {
		struct {
			int autoclose;
			FILE *fp;
		} /*stdio*/;

		struct {
			uint8_t *base;
			uint8_t *here;
			uint8_t *stop;
		} /*mem*/;
		struct {
			void *data1;
		} /*unknown*/;
	} /*hidden*/;
};


/** @name Functions to create SDL_RWops structures from various data sources */
/*@{*/

SDL_RWops *SDL_RWFromFile(const char *file, const char *mode);

SDL_RWops *SDL_RWFromFP(FILE *fp, int autoclose);

SDL_RWops *SDL_RWFromMem(void *mem, int size);
SDL_RWops *SDL_RWFromConstMem(const void *mem, int size);

SDL_RWops *SDL_AllocRW();
void SDL_FreeRW(SDL_RWops *area);

/*@}*/

/** @name Seek Reference Points */
/*@{*/
enum SDL_RWSeek {
	SET = 0, /**< Seek from the beginning of data */
	CUR = 1, /**< Seek relative to current read point */
	END = 2  /**< Seek relative to the end of data */
}
/*@}*/

/** @name Macros to easily read and write from an SDL_RWops structure */
/*@{*/
int SDL_RWseek(SDL_RWops *ctx, int offset, int whence) {
	return ctx.seek(ctx, offset, whence);
}
int SDL_RWtell(SDL_RWops *ctx) {
	return ctx.seek(ctx, 0, SDL_RWSeek.CUR);
}
int SDL_RWread(SDL_RWops *ctx, void *ptr, int size, int n) {
	return ctx.read(ctx, ptr, size, n);
}
int SDL_RWwrite(SDL_RWops *ctx, const void *ptr, int size, int n) {
	return ctx.write(ctx, ptr, size, n);
}
int SDL_RWclose(SDL_RWops *ctx) {
	return ctx.close(ctx);
}
/*@}*/

/** @name Read an item of the specified endianness and return in native format */
/*@{*/
uint16_t SDL_ReadLE16(SDL_RWops *src);
uint16_t SDL_ReadBE16(SDL_RWops *src);
uint32_t SDL_ReadLE32(SDL_RWops *src);
uint32_t SDL_ReadBE32(SDL_RWops *src);
uint64_t SDL_ReadLE64(SDL_RWops *src);
uint64_t SDL_ReadBE64(SDL_RWops *src);
/*@}*/

/** @name Write an item of native format to the specified endianness */
/*@{*/
int SDL_WriteLE16(SDL_RWops *dst, uint16_t value);
int SDL_WriteBE16(SDL_RWops *dst, uint16_t value);
int SDL_WriteLE32(SDL_RWops *dst, uint32_t value);
int SDL_WriteBE32(SDL_RWops *dst, uint32_t value);
int SDL_WriteLE64(SDL_RWops *dst, uint64_t value);
int SDL_WriteBE64(SDL_RWops *dst, uint64_t value);
/*@}*/
}
