module gui;


enum ButtonState : ubyte {
	RELEASED,
	PRESSED
}

struct Coord2D {
	uint x, y;
}

struct MouseButtonEvent {
	byte button;
	ButtonState state;
	Coord2D coord;
}

struct Color {
	ubyte r, g, b;
}

interface Gui {
	/* Get / set the window title. */
	@property string windowTitle() const;
	@property string windowTitle(string title);

	/* Load an image. */
	void loadImage(string filename);

	/* Display a window with the image. */
	void start();

	/* Close the window. */
	void finish();

	/* Handle one event and return. Just return if there's no event. */
	void handleOneEvent();

	/* Handle one pending event or wait for an event to come. */
	void handleOneEventWait();

	/* Handle all pending events and return immediately. */
	void handlePendingEvents();

	/* Handle all pending events and wait for new ones. */
	void handlePendingEventsWait();

	/* Call start(), handlePendingEventsWait(), finish(). */
	void run();

	/* Indicate whether the user want to quit. */
	@property bool quit();

	/* Return the informations about the last click performed. */
	MouseButtonEvent *lastClick();

	/* Return the image size as a coordinate. */
	Coord2D imageSize();

	/* Return the color of a pixel in the image. */
	Color pixelColor(Coord2D coord);

	/* Set the color of a pixel in the image. */
	void pixelColor(Coord2D coord, Color color);

	/* Update the displayed. */
	void updateDisplay(bool forced = false, bool selective = true);
}


import std.stdio;
import std.algorithm : min, max;
import std.string : toStringz, fromStringz;
import std.conv : to;
import sdl.sdl;
import sdl.image;

class SDLGui : Gui {
	this() {
		int err = SDL_Init(SDL_InitFlags.VIDEO);
		sdl_enforce(err == 0);
		wantquit = false;
	}



	~this() {
		if (image != null)
			SDL_FreeSurface(image);
		image = null;
		IMG_Quit();
		SDL_Quit();
	}



	@property string windowTitle() const {
		char *title;
		string retval;
		SDL_WM_GetCaption(&title, null);
		return title.fromStringz.idup;
	}



	@property string windowTitle(string title) {
		SDL_WM_SetCaption(title.toStringz, null);
		return title;
	}



	void loadImage(string filename) {
		image = IMG_Load(filename.toStringz);
		sdl_enforce(image != null);
	}



	void start() {
		SDL_Surface *tmp;
		int err;

		screen = SDL_SetVideoMode(image.w, image.h,
		                          image.format.BitsPerPixel,
		                          SDL_InternalFlags.ANYFORMAT);
		sdl_enforce(screen != null);

		/*
		 * Optimize the image now we have a display (and avoid unaligned
		 * memory access).
		 */
		tmp = image;
		image = SDL_DisplayFormat(tmp);
		sdl_enforce(image != null);

		SDL_FreeSurface(tmp);

		err = SDL_BlitSurface(image, null, screen, null);
		sdl_enforce(err == 0);

		updateDisplay(true, false);
	}



	void finish() {
		SDL_FreeSurface(screen);
		screen = null;
	}



	void handleOneEvent() {
		SDL_Event e;
		if (SDL_PollEvent(&e))
			handle_event(e);
	}



	void handleOneEventWait() {
		SDL_Event e;
		int err = SDL_WaitEvent(&e);

		sdl_enforce(err == 1);

		if (err)
			handle_event(e);
	}



	void handlePendingEvents() {
		SDL_Event e;

		while (SDL_PollEvent(&e))
			handle_event(e);
	}



	void handlePendingEventsWait() {
		SDL_Event e;

		while (!quit && SDL_WaitEvent(&e))
			handle_event(e);

		sdl_enforce(quit);
	}



	void run() {
		start();
		handlePendingEventsWait();
		finish();
	}



	private void handle_event(ref SDL_Event event) {
		switch (event.type) {
		case SDL_EventType.QUIT:
			wantquit = true;
			goto default;

		case SDL_EventType.MOUSEBUTTONUP:
			//writeln(event.type, " ", event.button);

			buttonevent = new MouseButtonEvent();
			buttonevent.button = event.button.button;
			buttonevent.state = cast(ButtonState)event.button.state;
			buttonevent.coord.x = event.button.x;
			buttonevent.coord.y = event.button.y;
			break;

		case SDL_EventType.KEYUP:
			if (event.key.keysym.sym == SDLKey.SDLK_q)
				goto case SDL_EventType.QUIT;
			break;

		default:
			//writeln(event.type);
			break;
		}
	}



	bool quit() {
		return wantquit;
	}


	MouseButtonEvent *lastClick() {
		MouseButtonEvent *ret = buttonevent;
		buttonevent = null;
		return ret;
	}



	Coord2D imageSize() {
		Coord2D ret;
		ret.x = image.w;
		ret.y = image.h;
		return ret;
	}



	Color pixelColor(Coord2D coord) {
		Color c;
		void* pixeldata;
		uint pixel;
		immutable ubyte bytepp = image.format.BytesPerPixel;

		assert(bytepp <= typeof(pixel).sizeof);
		assert(coord.x < image.w);
		assert(coord.y < image.h);

		SDL_LockSurface(image);
		pixeldata = image.pixels;
		pixeldata += (coord.y * image.w + coord.x) * bytepp;
		pixel = *cast(typeof(pixel)*)pixeldata;
		SDL_UnlockSurface(image);

		SDL_GetRGB(pixel, image.format, &c.r, &c.g, &c.b);

		return c;
	}



	void pixelColor(Coord2D coord, Color color) {
		Color c;
		void* pixeldata;
		uint pixel;
		immutable ubyte bytepp = screen.format.BytesPerPixel;

		assert(bytepp <= typeof(pixel).sizeof);
		assert(coord.x < screen.w);
		assert(coord.y < screen.h);

		pixel = SDL_MapRGB(screen.format, color.r, color.g, color.b);

		SDL_LockSurface(screen);
		pixeldata = screen.pixels;
		pixeldata += (coord.y * screen.w + coord.x) * bytepp;
		*cast(typeof(pixel)*)pixeldata = pixel;
		SDL_UnlockSurface(screen);

		mergeUpdate(coord, Coord2D(1, 1));
	}



	void updateDisplay(bool forced = false, bool selective = true) {
		SDL_Rect rect;
		uint32_t now;

		now = SDL_GetTicks();
		if (!forced && now < lastupdate + 1000 / FPS)
			return;

		if (selective) {
			if (updateMax.x == 0 || updateMax.y == 0)
				return;

			rect.x = cast(short)updateMin.x;
			rect.y = cast(short)updateMin.y;
			rect.w = cast(short)(updateMax.x - updateMin.x);
			rect.h = cast(short)(updateMax.y - updateMin.y);
			SDL_UpdateRects(screen, 1, &rect);
		} else {
			SDL_UpdateRect(screen, 0, 0, 0, 0);
		}


		updateMin = typeof(updateMin).init;
		updateMax = typeof(updateMax).init;
		lastupdate = now;
	}



	private void mergeUpdate(Coord2D coord, Coord2D size) {
		assert(size.x > 0);
		assert(size.y > 0);

		updateMin.x = min(updateMin.x, coord.x);
		updateMin.y = min(updateMin.y, coord.y);
		updateMax.x = max(updateMax.x, coord.x + size.x);
		updateMax.y = max(updateMax.y, coord.y + size.y);
	}



	private static void sdl_enforce(bool cond) {
		assert(cond, SDL_GetError().fromStringz);
	}



	private static immutable int FPS = 60;
	private SDL_Surface *image;
	private SDL_Surface *screen;
	private bool wantquit;
	private MouseButtonEvent *buttonevent;
	private Coord2D updateMin, updateMax;
	private uint32_t lastupdate;
}
