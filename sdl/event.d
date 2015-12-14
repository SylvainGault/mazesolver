/* Header code adapted from SDL_event.h */
module sdl.event;

import core.stdc.stdint;

public import sdl.keyboard;

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

/**
 *  @file SDL_events.h
 *  Include file for SDL event handling
 */

/** @name General keyboard/mouse state definitions */
/*@{*/
enum SDL_ButtonState : uint8_t {
	RELEASED = 0,
	PRESSED = 1
}
/*@}*/

/** Event enumerations */
enum SDL_EventType : uint8_t {
	NOEVENT = 0,			/**< Unused (do not remove) */
	ACTIVEEVENT,			/**< Application loses/gains visibility */
	KEYDOWN,			/**< Keys pressed */
	KEYUP,				/**< Keys released */
	MOUSEMOTION,			/**< Mouse moved */
	MOUSEBUTTONDOWN,		/**< Mouse button pressed */
	MOUSEBUTTONUP,			/**< Mouse button released */
	JOYAXISMOTION,			/**< Joystick axis motion */
	JOYBALLMOTION,			/**< Joystick trackball motion */
	JOYHATMOTION,			/**< Joystick hat position change */
	JOYBUTTONDOWN,			/**< Joystick button pressed */
	JOYBUTTONUP,			/**< Joystick button released */
	QUIT,				/**< User-requested quit */
	SYSWMEVENT,			/**< System specific event */
	EVENT_RESERVEDA,		/**< Reserved for future use.. */
	EVENT_RESERVEDB,		/**< Reserved for future use.. */
	VIDEORESIZE,			/**< User resized video mode */
	VIDEOEXPOSE,			/**< Screen needs to be redrawn */
	EVENT_RESERVED2,		/**< Reserved for future use.. */
	EVENT_RESERVED3,		/**< Reserved for future use.. */
	EVENT_RESERVED4,		/**< Reserved for future use.. */
	EVENT_RESERVED5,		/**< Reserved for future use.. */
	EVENT_RESERVED6,		/**< Reserved for future use.. */
	EVENT_RESERVED7,		/**< Reserved for future use.. */
	/** Events SDL_USEREVENT through SDL_MAXEVENTS-1 are for your use */
	USEREVENT = 24,
	/** This last event is only for bounding internal arrays
	 *  It is the number of bits in the event mask datatype -- uint32_t
	 */
	NUMEVENTS = 32
};

/** @name Predefined event masks */
/*@{*/
int SDL_EVENTMASK(SDL_EventType X) {
	return 1 << X;
}

enum SDL_EventMask {
	ACTIVEEVENTMASK	= SDL_EVENTMASK(SDL_EventType.ACTIVEEVENT),
	KEYDOWNMASK		= SDL_EVENTMASK(SDL_EventType.KEYDOWN),
	KEYUPMASK		= SDL_EVENTMASK(SDL_EventType.KEYUP),
	KEYEVENTMASK	= SDL_EVENTMASK(SDL_EventType.KEYDOWN)|
	                      SDL_EVENTMASK(SDL_EventType.KEYUP),
	MOUSEMOTIONMASK	= SDL_EVENTMASK(SDL_EventType.MOUSEMOTION),
	MOUSEBUTTONDOWNMASK	= SDL_EVENTMASK(SDL_EventType.MOUSEBUTTONDOWN),
	MOUSEBUTTONUPMASK	= SDL_EVENTMASK(SDL_EventType.MOUSEBUTTONUP),
	MOUSEEVENTMASK	= SDL_EVENTMASK(SDL_EventType.MOUSEMOTION)|
	                      SDL_EVENTMASK(SDL_EventType.MOUSEBUTTONDOWN)|
	                      SDL_EVENTMASK(SDL_EventType.MOUSEBUTTONUP),
	JOYAXISMOTIONMASK	= SDL_EVENTMASK(SDL_EventType.JOYAXISMOTION),
	JOYBALLMOTIONMASK	= SDL_EVENTMASK(SDL_EventType.JOYBALLMOTION),
	JOYHATMOTIONMASK	= SDL_EVENTMASK(SDL_EventType.JOYHATMOTION),
	JOYBUTTONDOWNMASK	= SDL_EVENTMASK(SDL_EventType.JOYBUTTONDOWN),
	JOYBUTTONUPMASK	= SDL_EVENTMASK(SDL_EventType.JOYBUTTONUP),
	JOYEVENTMASK	= SDL_EVENTMASK(SDL_EventType.JOYAXISMOTION)|
	                      SDL_EVENTMASK(SDL_EventType.JOYBALLMOTION)|
	                      SDL_EVENTMASK(SDL_EventType.JOYHATMOTION)|
	                      SDL_EVENTMASK(SDL_EventType.JOYBUTTONDOWN)|
	                      SDL_EVENTMASK(SDL_EventType.JOYBUTTONUP),
	VIDEORESIZEMASK	= SDL_EVENTMASK(SDL_EventType.VIDEORESIZE),
	VIDEOEXPOSEMASK	= SDL_EVENTMASK(SDL_EventType.VIDEOEXPOSE),
	QUITMASK		= SDL_EVENTMASK(SDL_EventType.QUIT),
	SYSWMEVENTMASK	= SDL_EVENTMASK(SDL_EventType.SYSWMEVENT),
	ALLEVENTS		= 0xFFFFFFFF
};
/*@}*/

/** Application visibility event structure */
struct SDL_ActiveEvent {
	SDL_EventType type;	/**< SDL_ACTIVEEVENT */
	uint8_t gain;		/**< Whether given states were gained or lost (1/0) */
	uint8_t state;		/**< A mask of the focus states */
};

/** Keyboard event structure */
struct SDL_KeyboardEvent {
	SDL_EventType type;	/**< SDL_KEYDOWN or SDL_KEYUP */
	uint8_t which;		/**< The keyboard device index */
	SDL_ButtonState state;	/**< SDL_PRESSED or SDL_RELEASED */
	SDL_keysym keysym;
};

/** Mouse motion event structure */
struct SDL_MouseMotionEvent {
	SDL_EventType type;	/**< SDL_MOUSEMOTION */
	uint8_t which;		/**< The mouse device index */
	uint8_t state;		/**< The current button state */
	uint16_t x, y;		/**< The X/Y coordinates of the mouse */
	int16_t xrel;		/**< The relative motion in the X direction */
	int16_t yrel;		/**< The relative motion in the Y direction */
};

/** Mouse button event structure */
struct SDL_MouseButtonEvent {
	SDL_EventType type;	/**< SDL_MOUSEBUTTONDOWN or SDL_MOUSEBUTTONUP */
	uint8_t which;		/**< The mouse device index */
	uint8_t button;		/**< The mouse button index */
	SDL_ButtonState state;	/**< SDL_PRESSED or SDL_RELEASED */
	uint16_t x, y;		/**< The X/Y coordinates of the mouse at press time */
};

/** Joystick axis motion event structure */
struct SDL_JoyAxisEvent {
	SDL_EventType type;	/**< SDL_JOYAXISMOTION */
	uint8_t which;		/**< The joystick device index */
	uint8_t axis;		/**< The joystick axis index */
	int16_t value;		/**< The axis value (range: -32768 to 32767) */
};

/** Joystick trackball motion event structure */
struct SDL_JoyBallEvent {
	SDL_EventType type;	/**< SDL_JOYBALLMOTION */
	uint8_t which;		/**< The joystick device index */
	uint8_t ball;		/**< The joystick trackball index */
	int16_t xrel;		/**< The relative motion in the X direction */
	int16_t yrel;		/**< The relative motion in the Y direction */
};

/** Joystick hat position change event structure */
struct SDL_JoyHatEvent {
	SDL_EventType type;	/**< SDL_JOYHATMOTION */
	uint8_t which;		/**< The joystick device index */
	uint8_t hat;		/**< The joystick hat index */
	uint8_t value;		/**< The hat position value:
				 *   SDL_HAT_LEFTUP   SDL_HAT_UP       SDL_HAT_RIGHTUP
				 *   SDL_HAT_LEFT     SDL_HAT_CENTERED SDL_HAT_RIGHT
				 *   SDL_HAT_LEFTDOWN SDL_HAT_DOWN     SDL_HAT_RIGHTDOWN
				 *  Note that zero means the POV is centered.
				 */
};

/** Joystick button event structure */
struct SDL_JoyButtonEvent {
	SDL_EventType type;	/**< SDL_JOYBUTTONDOWN or SDL_JOYBUTTONUP */
	uint8_t which;		/**< The joystick device index */
	uint8_t button;		/**< The joystick button index */
	SDL_ButtonState state;	/**< SDL_PRESSED or SDL_RELEASED */
};

/** The "window resized" event
 *  When you get this event, you are responsible for setting a new video
 *  mode with the new width and height.
 */
struct SDL_ResizeEvent {
	SDL_EventType type;	/**< SDL_VIDEORESIZE */
	int w;		/**< New width */
	int h;		/**< New height */
};

/** The "screen redraw" event */
struct SDL_ExposeEvent {
	SDL_EventType type;	/**< SDL_VIDEOEXPOSE */
};

/** The "quit requested" event */
struct SDL_QuitEvent {
	SDL_EventType type;	/**< SDL_QUIT */
};

/** A user-defined event type */
struct SDL_UserEvent {
	SDL_EventType type;	/**< SDL_USEREVENT through SDL_NUMEVENTS-1 */
	int code;		/**< User defined event code */
	void *data1;		/**< User defined data pointer */
	void *data2;		/**< User defined data pointer */
};

/** If you want to use this event, you should include SDL_syswm.h */
struct SDL_SysWMmsg;
struct SDL_SysWMEvent {
	SDL_EventType type;
	SDL_SysWMmsg *msg;
};

/** General event structure */
union SDL_Event {
	SDL_EventType type;
	SDL_ActiveEvent active;
	SDL_KeyboardEvent key;
	SDL_MouseMotionEvent motion;
	SDL_MouseButtonEvent button;
	SDL_JoyAxisEvent jaxis;
	SDL_JoyBallEvent jball;
	SDL_JoyHatEvent jhat;
	SDL_JoyButtonEvent jbutton;
	SDL_ResizeEvent resize;
	SDL_ExposeEvent expose;
	SDL_QuitEvent quit;
	SDL_UserEvent user;
	SDL_SysWMEvent syswm;
};


/* Function prototypes */

/** Pumps the event loop, gathering events from the input devices.
 *  This function updates the event queue and internal input device state.
 *  This should only be run in the thread that sets the video mode.
 */
void SDL_PumpEvents();

enum SDL_eventaction {
	SDL_ADDEVENT,
	SDL_PEEKEVENT,
	SDL_GETEVENT
};

/**
 *  Checks the event queue for messages and optionally returns them.
 *
 *  If 'action' is SDL_ADDEVENT, up to 'numevents' events will be added to
 *  the back of the event queue.
 *  If 'action' is SDL_PEEKEVENT, up to 'numevents' events at the front
 *  of the event queue, matching 'mask', will be returned and will not
 *  be removed from the queue.
 *  If 'action' is SDL_GETEVENT, up to 'numevents' events at the front 
 *  of the event queue, matching 'mask', will be returned and will be
 *  removed from the queue.
 *
 *  @return
 *  This function returns the number of events actually stored, or -1
 *  if there was an error.
 *
 *  This function is thread-safe.
 */
int SDL_PeepEvents(SDL_Event *events, int numevents,
				SDL_eventaction action, uint32_t mask);

/** Polls for currently pending events, and returns 1 if there are any pending
 *  events, or 0 if there are none available.  If 'event' is not NULL, the next
 *  event is removed from the queue and stored in that area.
 */
int SDL_PollEvent(SDL_Event *event);

/** Waits indefinitely for the next available event, returning 1, or 0 if there
 *  was an error while waiting for events.  If 'event' is not NULL, the next
 *  event is removed from the queue and stored in that area.
 */
int SDL_WaitEvent(SDL_Event *event);

/** Add an event to the event queue.
 *  This function returns 0 on success, or -1 if the event queue was full
 *  or there was some other error.
 */
int SDL_PushEvent(SDL_Event *event);

/** @name Event Filtering */
/*@{*/
alias SDL_EventFilter = int function(const SDL_Event *event);
/**
 *  This function sets up a filter to process all events before they
 *  change internal state and are posted to the internal event queue.
 *
 *  The filter is protypted as:
 *      @code typedef int (*SDL_EventFilter)(const SDL_Event *event); @endcode
 *
 * If the filter returns 1, then the event will be added to the internal queue.
 * If it returns 0, then the event will be dropped from the queue, but the 
 * internal state will still be updated.  This allows selective filtering of
 * dynamically arriving events.
 *
 * @warning  Be very careful of what you do in the event filter function, as 
 *           it may run in a different thread!
 *
 * There is one caveat when dealing with the SDL_QUITEVENT event type.  The
 * event filter is only called when the window manager desires to close the
 * application window.  If the event filter returns 1, then the window will
 * be closed, otherwise the window will remain open if possible.
 * If the quit event is generated by an interrupt signal, it will bypass the
 * internal queue and be delivered to the application at the next event poll.
 */
void SDL_SetEventFilter(SDL_EventFilter filter);

/**
 *  Return the current event filter - can be used to "chain" filters.
 *  If there is no event filter set, this function returns NULL.
 */
SDL_EventFilter SDL_GetEventFilter();
/*@}*/

/** @name Event State */
/*@{*/
enum SDL_EventStateName {
	QUERY	= -1,
	IGNORE	=  0,
	DISABLE	=  0,
	ENABLE	=  1
};
/*@}*/

/**
* This function allows you to set the state of processing certain events.
* If 'state' is set to SDL_IGNORE, that event will be automatically dropped
* from the event queue and will not event be filtered.
* If 'state' is set to SDL_ENABLE, that event will be processed normally.
* If 'state' is set to SDL_QUERY, SDL_EventState() will return the 
* current processing state of the specified event.
*/
uint8_t SDL_EventState(uint8_t type, int state);
}
