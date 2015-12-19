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

	/* Display a message to the user. */
	void displayMessage(string msg);

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
import sdl.ttf;

class SDLGui : Gui {
	this() {
		int err;

		wantquit = false;

		err = SDL_Init(SDL_InitFlags.VIDEO);
		sdl_enforce(err == 0);

		err = TTF_Init();
		sdl_enforce(err == 0);
	}



	~this() {
		if (image != null)
			SDL_FreeSurface(image);
		image = null;

		if (font != null)
			TTF_CloseFont(font);
		font = null;

		IMG_Quit();
		TTF_Quit();
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



	void displayMessage(string msg) {
		int err;

		if (textSurf != null) {
			/* Clear any previous text. */
			err = SDL_BlitSurface(scratch, null, screen, null);
			sdl_enforce(err == 0);

			/* Say we've modified the area were was the text. */
			mergeUpdate(textPos, Coord2D(textSurf.w, textSurf.h));

			SDL_FreeSurface(textSurf);
			textSurf = null;
		}

		textSurf = TTF_RenderUTF8_Blended(font, msg.toStringz, textColor);
		sdl_enforce(textSurf != null);

		/* /!\ Do not optimize textSurf as it contains an alpha channel. */

		mergeUpdate(textPos, Coord2D(textSurf.w, textSurf.h));
		updateDisplay(true, true);
	}



	void loadImage(string filename) {
		image = IMG_Load(filename.toStringz);
		sdl_enforce(image != null);
	}



	void start() {
		int err;

		screen = SDL_SetVideoMode(image.w, image.h,
		                          image.format.BitsPerPixel,
		                          SDL_InternalFlags.ANYFORMAT);
		sdl_enforce(screen != null);

		font = TTF_OpenFont("data/DejaVuSansMono-Bold.ttf", fontSize);
		sdl_enforce(font != null);

		/*
		 * Optimize the image now we have a display (and avoid unaligned
		 * memory access).
		 */
		image = optimizeSurface(image);
		sdl_enforce(image != null);

		/* No need to optimize scratch. */
		scratch = SDL_ConvertSurface(image, image.format, image.flags);
		sdl_enforce(scratch != null);

		err = SDL_BlitSurface(scratch, null, screen, null);
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
		immutable ubyte bytepp = scratch.format.BytesPerPixel;

		assert(bytepp <= typeof(pixel).sizeof);
		assert(coord.x < scratch.w);
		assert(coord.y < scratch.h);

		pixel = SDL_MapRGB(scratch.format, color.r, color.g, color.b);

		SDL_LockSurface(scratch);
		pixeldata = scratch.pixels;
		pixeldata += (coord.y * scratch.w + coord.x) * bytepp;
		*cast(typeof(pixel)*)pixeldata = pixel;
		SDL_UnlockSurface(scratch);

		mergeUpdate(coord, Coord2D(1, 1));
	}



	void updateDisplay(bool forced = false, bool selective = true) {
		SDL_Rect rect;
		uint32_t now;
		int err;

		now = SDL_GetTicks();
		if (!forced && now < lastupdate + 1000 / FPS)
			return;

		if (selective) {
			if (updateMax.x == 0 || updateMax.y == 0)
				return;

			rect.x = cast(typeof(rect.x))updateMin.x;
			rect.y = cast(typeof(rect.y))updateMin.y;
			rect.w = cast(typeof(rect.w))(updateMax.x - updateMin.x);
			rect.h = cast(typeof(rect.h))(updateMax.y - updateMin.y);
		} else {
			rect.x = 0;
			rect.y = 0;
			rect.w = cast(typeof(rect.w))screen.w;
			rect.h = cast(typeof(rect.w))screen.h;
		}


		err = SDL_BlitSurface(scratch, &rect, screen, &rect);
		sdl_enforce(err == 0);

		if (textSurf != null) {
			SDL_Rect textRect;
			textRect.x = cast(typeof(textRect.x))textPos.x;
			textRect.y = cast(typeof(textRect.y))textPos.y;
			textRect.w = cast(typeof(textRect.w))textSurf.w;
			textRect.h = cast(typeof(textRect.h))textSurf.h;

			if (intersectRect(&textRect, &rect)) {
				err = SDL_BlitSurface(textSurf, &textRect, screen, null);
				sdl_enforce(err == 0);
			}
		}

		SDL_UpdateRect(screen, rect.x, rect.y, rect.w, rect.h);

		updateMin = typeof(updateMin).init;
		updateMax = typeof(updateMax).init;
		lastupdate = now;
	}



	private static SDL_Surface* optimizeSurface(SDL_Surface* input) {
		SDL_Surface* output;
		output = SDL_DisplayFormat(input);
		sdl_enforce(output != null);

		SDL_FreeSurface(input);
		return output;
	}



	private static bool intersectRect(const SDL_Rect *r1, const SDL_Rect *r2) {
		static bool intersect1D(int a1, int a2, int b1, int b2) {
			return b1 < a2 && b2 > a1;
		}

		if (!intersect1D(r1.x, r1.x + r1.w, r2.x, r2.x + r2.w))
			return false;

		return intersect1D(r1.y, r1.y + r1.h, r2.y, r2.y + r2.h);
	}



	private void mergeUpdate(Coord2D coord, Coord2D size) {
		assert(size.x > 0);
		assert(size.y > 0);

		/* Empty new update zone. */
		if (size.x == 0 || size.y == 0)
			return;

		/* Empty current update zone. */
		if (updateMin.x == updateMax.x || updateMin.y == updateMax.y) {
			updateMin = coord;
			updateMax.x = coord.x + size.x;
			updateMax.y = coord.y + size.y;
			return;
		}

		/* General case. */
		updateMin.x = min(updateMin.x, coord.x);
		updateMin.y = min(updateMin.y, coord.y);
		updateMax.x = max(updateMax.x, coord.x + size.x);
		updateMax.y = max(updateMax.y, coord.y + size.y);
	}



	private static void sdl_enforce(bool cond) {
		assert(cond, SDL_GetError().fromStringz);
	}



	private static immutable int FPS = 60;
	private static immutable SDL_Color textColor = SDL_Color(0, 0, 127);
	private static immutable Coord2D textPos = Coord2D(0, 0);
	private static immutable int fontSize = 18;

	private bool wantquit;
	private MouseButtonEvent* buttonevent;
	private Coord2D updateMin, updateMax;
	private uint32_t lastupdate;
	private TTF_Font* font;

	/* Input image. */
	private SDL_Surface* image;

	/* Input image + progression. */
	private SDL_Surface* scratch;

	/* Surface for the text to be displayed. */
	private SDL_Surface* textSurf;

	/* Merge all the surfaces to be displayed. */
	private SDL_Surface* screen;
}
