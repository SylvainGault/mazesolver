/* Header code adapted from SDL_video.h */
module sdl.error;

import core.stdc.stdint;

extern (C) {
/*
 * SDL - Simple DirectMedia Layer
 * Copyright (C) 1997-2012 Sam Lantinga
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Sam Lantinga
 * slouken@libsdl.org
 */

/**
 *  @file SDL_error.h
 *  Simple error message routines for SDL
 */

/**
 *  @name Public functions
 */
/*@{*/
void SDL_SetError(const char *fmt, ...);
char *SDL_GetError();
void SDL_ClearError();
/*@}*/

/**
 *  @name Private functions
 *  @internal Private error message function - used internally
 */
/*@{*/
void SDL_OutOfMemory() { return SDL_Error(SDL_errorcode.ENOMEM);}
void SDL_Unsupported() { return SDL_Error(SDL_errorcode.UNSUPPORTED);}
enum SDL_errorcode {
	ENOMEM,
	EFREAD,
	EFWRITE,
	EFSEEK,
	UNSUPPORTED,
	LASTERROR
};
void SDL_Error(SDL_errorcode code);
/*@}*/
}
