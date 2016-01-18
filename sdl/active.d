/* Header code adapted from SDL_active.h */
module sdl.active;

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
 *  @file SDL_active.h
 *  Include file for SDL application focus event handling
 */

/** @name The available application states */
/*@{*/
enum SDL_AppState : uint8_t {
	MOUSEFOCUS	= 0x01,		/**< The app has mouse coverage */
	INPUTFOCUS	= 0x02,		/**< The app has input focus */
	ACTIVE		= 0x04		/**< The application is active */
}
/*@}*/

/* Function prototypes */
/** 
 * This function returns the current state of the application, which is a
 * bitwise combination of SDL_APPMOUSEFOCUS, SDL_APPINPUTFOCUS, and
 * SDL_APPACTIVE.  If SDL_APPACTIVE is set, then the user is able to
 * see your application, otherwise it has been iconified or disabled.
 */
SDL_AppState SDL_GetAppState();
}
