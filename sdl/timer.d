/* Header code adapted from SDL_timer.h */
module sdl.timer;

public import core.stdc.stdint : uint32_t;

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

/** This is the OS scheduler timeslice, in milliseconds */
enum SDL_TIMESLICE = 10;

/** This is the maximum resolution of the SDL timer on all platforms */
enum TIMER_RESOLUTION = 10;	/**< Experimentally determined */

/**
 * Get the number of milliseconds since the SDL library initialization.
 * Note that this value wraps if the program runs for more than ~49 days.
 */ 
uint32_t SDL_GetTicks();

/** Wait a specified number of milliseconds before returning */
void SDL_Delay(uint32_t ms);

/** Function prototype for the timer callback function */
alias SDL_TimerCallback = uint32_t function(uint32_t interval);

/**
 * Set a callback to run after the specified number of milliseconds has
 * elapsed. The callback function is passed the current timer interval
 * and returns the next timer interval.  If the returned value is the 
 * same as the one passed in, the periodic alarm continues, otherwise a
 * new alarm is scheduled.  If the callback returns 0, the periodic alarm
 * is cancelled.
 *
 * To cancel a currently running timer, call SDL_SetTimer(0, NULL);
 *
 * The timer callback function may run in a different thread than your
 * main code, and so shouldn't call any functions from within itself.
 *
 * The maximum resolution of this timer is 10 ms, which means that if
 * you request a 16 ms timer, your callback will run approximately 20 ms
 * later on an unloaded system.  If you wanted to set a flag signaling
 * a frame update at 30 frames per second (every 33 ms), you might set a 
 * timer for 30 ms:
 *   @code SDL_SetTimer((33/10)*10, flag_update); @endcode
 *
 * If you use this function, you need to pass SDL_INIT_TIMER to SDL_Init().
 *
 * Under UNIX, you should not use raise or use SIGALRM and this function
 * in the same program, as it is implemented using setitimer().  You also
 * should not use this function in multi-threaded applications as signals
 * to multi-threaded apps have undefined behavior in some implementations.
 *
 * This function returns 0 if successful, or -1 if there was an error.
 */
int SDL_SetTimer(uint32_t interval, SDL_TimerCallback callback);

/** @name New timer API
 * New timer API, supports multiple timers
 * Written by Stephane Peter <megastep@lokigames.com>
 */
/*@{*/

/**
 * Function prototype for the new timer callback function.
 * The callback function is passed the current timer interval and returns
 * the next timer interval.  If the returned value is the same as the one
 * passed in, the periodic alarm continues, otherwise a new alarm is
 * scheduled.  If the callback returns 0, the periodic alarm is cancelled.
 */
alias SDL_NewTimerCallback = uint32_t function(uint32_t interval, void *param);

/** Definition of the timer ID type */
struct _SDL_TimerID;
alias SDL_TimerID = _SDL_TimerID*;

/** Add a new timer to the pool of timers already running.
 *  Returns a timer ID, or NULL when an error occurs.
 */
SDL_TimerID SDL_AddTimer(uint32_t interval, SDL_NewTimerCallback callback, void *param);

/**
 * Remove one of the multiple timers knowing its ID.
 * Returns a boolean value indicating success.
 */
bool SDL_RemoveTimer(SDL_TimerID t);

/*@}*/

}
