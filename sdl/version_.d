/* Header code adapted from SDL_version.h */
module sdl.version_;

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

/** @file SDL_version.h
 *  This header defines the current SDL version
 */

/** @name Version Number
 *  Printable format: "%d.%d.%d", MAJOR, MINOR, PATCHLEVEL
 */
/*@{*/
enum SDL_Version
{
	MAJOR_VERSION = 1,
	MINOR_VERSION = 2,
	PATCHLEVEL = 15
}
/*@}*/

struct SDL_version {
	uint8_t major;
	uint8_t minor;
	uint8_t patch;
}

/**
 * This macro can be used to fill a version structure with the compile-time
 * version of the SDL library.
 */
void SDL_VERSION(SDL_version *v)
{
	v.major = SDL_Version.MAJOR_VERSION;
	v.minor = SDL_Version.MINOR_VERSION;
	v.patch = SDL_Version.PATCHLEVEL;
}

/** This macro turns the version numbers into a numeric value:
 *  (1,2,3) -> (1203)
 *  This assumes that there will never be more than 100 patchlevels
 */
int SDL_VERSIONNUM(int X, int Y, int Z) {
	return X * 1000 + Y * 100 + Z;
}

/** This is the version number macro for the current SDL version */
int SDL_COMPILEDVERSION()
{
	with (SDL_Version)
		return SDL_VERSIONNUM(MAJOR_VERSION, MINOR_VERSION, PATCHLEVEL);
}

/** This macro will evaluate to true if compiled with SDL at least X.Y.Z */
bool SDL_VERSION_ATLEAST(int X, int Y, int Z) {
	return SDL_COMPILEDVERSION() >= SDL_VERSIONNUM(X, Y, Z);
}

/** This function gets the version of the dynamically linked SDL library.
 *  it should NOT be used to fill a version structure, instead you should
 *  use the SDL_Version() macro.
 */
//const SDL_version *SDL_Linked_Version(void);

}
