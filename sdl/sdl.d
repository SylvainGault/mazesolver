/* Header code adapted from SDL_sdl.h */
module sdl.sdl;

import core.stdc.stdint;

public import sdl.error;
public import sdl.event;
public import sdl.rwops;
public import sdl.timer;
public import sdl.video;
public import sdl.version_;

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

/** @file SDL.h
 *  Main include header for the SDL library
 */
/** @file SDL.h
 *  @note As of version 0.5, SDL is loaded dynamically into the application
 */

/** @name SDL_INIT Flags
 *  These are the flags which may be passed to SDL_Init() -- you should
 *  specify the subsystems which you will be using in your application.
 */
/*@{*/
enum SDL_InitFlags {
	TIMER       = 0x00000001,
	AUDIO       = 0x00000010,
	VIDEO       = 0x00000020,
	CDROM       = 0x00000100,
	JOYSTICK    = 0x00000200,
	NOPARACHUTE = 0x00100000,	/**< Don't catch fatal signals */
	EVENTTHREAD = 0x01000000,	/**< Not supported on all OS's */
	EVERYTHING  = 0x0000FFFF
}
/*@}*/

/** This function loads the SDL dynamically linked library and initializes 
 *  the subsystems specified by 'flags' (and those satisfying dependencies)
 *  Unless the SDL_INIT_NOPARACHUTE flag is set, it will install cleanup
 *  signal handlers for some commonly ignored fatal signals (like SIGSEGV)
 */
int SDL_Init(uint32_t flags);

/** This function initializes specific SDL subsystems */
int SDL_InitSubSystem(uint32_t flags);

/** This function cleans up specific SDL subsystems */
void SDL_QuitSubSystem(uint32_t flags);

/** This function returns mask of the specified subsystems which have
 *  been initialized.
 *  If 'flags' is 0, it returns a mask of all initialized subsystems.
 */
uint32_t SDL_WasInit(uint32_t flags);

/** This function cleans up all initialized subsystems and unloads the
 *  dynamically linked library.  You should call it upon all exit conditions.
 */
void SDL_Quit();
}
