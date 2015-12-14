/* Header code adapted from SDL_event.h */
module sdl.keyboard;

import core.stdc.stdint;

public import sdl.keysym;

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

/** @file SDL_keyboard.h
 *  Include file for SDL keyboard event handling
 */

/** Keysym structure
 *
 *  - The scancode is hardware dependent, and should not be used by general
 *    applications.  If no hardware scancode is available, it will be 0.
 *
 *  - The 'unicode' translated character is only available when character
 *    translation is enabled by the SDL_EnableUNICODE() API.  If non-zero,
 *    this is a UNICODE character corresponding to the keypress.  If the
 *    high 9 bits of the character are 0, then this maps to the equivalent
 *    ASCII character:
 *      @code
 *	char ch;
 *	if ( (keysym.unicode & 0xFF80) == 0 ) {
 *		ch = keysym.unicode & 0x7F;
 *	} else {
 *		An international character..
 *	}
 *      @endcode
 */
struct SDL_keysym {
	uint8_t scancode;		/**< hardware specific scancode */
	SDLKey sym;			/**< SDL virtual keysym */
	SDLMod mod;			/**< current key modifiers */
	uint16_t unicode;		/**< translated character */
};

/** This is the mask which refers to all hotkey bindings */
enum SDL_ALL_HOTKEYS = 0xFFFFFFFF;

/* Function prototypes */
/**
 * Enable/Disable UNICODE translation of keyboard input.
 *
 * This translation has some overhead, so translation defaults off.
 *
 * @param[in] enable
 * If 'enable' is 1, translation is enabled.
 * If 'enable' is 0, translation is disabled.
 * If 'enable' is -1, the translation state is not changed.
 *
 * @return It returns the previous state of keyboard translation.
 */
int SDL_EnableUNICODE(int enable);

enum SDL_DEFAULT_REPEAT_DELAY = 500;
enum SDL_DEFAULT_REPEAT_INTERVAL = 30;
/**
 * Enable/Disable keyboard repeat.  Keyboard repeat defaults to off.
 *
 *  @param[in] delay
 *  'delay' is the initial delay in ms between the time when a key is
 *  pressed, and keyboard repeat begins.
 *
 *  @param[in] interval
 *  'interval' is the time in ms between keyboard repeat events.
 *
 *  If 'delay' is set to 0, keyboard repeat is disabled.
 */
int SDL_EnableKeyRepeat(int delay, int interval);
void SDL_GetKeyRepeat(int *delay, int *interval);

/**
 * Get a snapshot of the current state of the keyboard.
 * Returns an array of keystates, indexed by the SDLK_* syms.
 * Usage:
 *	@code
 * 	uint8_t *keystate = SDL_GetKeyState(NULL);
 *	if ( keystate[SDLK_RETURN] ) //... \<RETURN> is pressed.
 *	@endcode
 */
uint8_t * SDL_GetKeyState(int *numkeys);

/**
 * Get the current key modifier state
 */
SDLMod SDL_GetModState();

/**
 * Set the current key modifier state.
 * This does not change the keyboard state, only the key modifier flags.
 */
void SDL_SetModState(SDLMod modstate);

/**
 * Get the name of an SDL virtual keysym
 */
char * SDL_GetKeyName(SDLKey key);
}
