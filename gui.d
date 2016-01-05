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

	/* Display a message to the user for a given time in ms (0 = infinite). */
	void displayMessage(string msg, uint time = 3000);

	/* Remove the currently displayed message. */
	void removeMessage();

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

	/* Return the image size as a coordinate. */
	Coord2D imageSize();

	/* Return the color of a pixel in the image. */
	Color pixelColor(Coord2D coord);

	/* Set the color of a pixel to mark it pending. */
	void pixelPending(Coord2D coord);

	/* Set the color of a pixel to mark as visited. */
	void pixelVisited(Coord2D coord);

	/* Set the color of a pixel to mark it as part of the shortest path. */
	void pixelPath(Coord2D coord);

	/* Update the displayed. */
	void updateDisplay(bool forced = false, bool selective = true);
}



interface GuiCallbacks {
	void startCoord(Coord2D coord);
	void endCoord(Coord2D coord);
	void start();
	void stop();
	void quit();
}



import std.stdio;
import std.algorithm : min, max;
import std.string : toStringz, fromStringz;
import std.conv : to;
import sdl.sdl;
import sdl.image;
import sdl.ttf;

class SDLGui : Gui {
	public GuiCallbacks callbacks;



	this() {
		int err;

		wantQuit = false;

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



	void displayMessage(string msg, uint time = 3000) {
		removeMessage();

		textSurf = TTF_RenderUTF8_Blended(font, msg.toStringz, textColor);
		sdl_enforce(textSurf != null);

		/* /!\ Do not optimize textSurf as it contains an alpha channel. */

		mergeUpdate(textPos, Coord2D(textSurf.w, textSurf.h));
		updateDisplay();

		/* Remember to remove that text (or not). */

		if (time == 0) {
			textHasTimeout = false;
			return;
		}

		textHasTimeout = true;
		textTimeout = SDL_GetTicks() + time;
	}



	void removeMessage() {
		int err;
		SDL_Rect rect;

		if (textSurf == null)
			return;

		rect.x = cast(typeof(rect.x))textPos.x;
		rect.y = cast(typeof(rect.y))textPos.y;
		rect.w = cast(typeof(rect.w))textSurf.w;
		rect.h = cast(typeof(rect.h))textSurf.h;

		/* Clear any previous text. */
		err = SDL_BlitSurface(scratch, &rect, screen, &rect);
		sdl_enforce(err == 0);

		/* Say we've modified the area where was the text. */
		mergeUpdate(textPos, Coord2D(textSurf.w, textSurf.h));

		SDL_FreeSurface(textSurf);
		textSurf = null;
		textTimeout = 0;
		textHasTimeout = false;
	}



	void loadImage(string filename) {
		image = IMG_Load(filename.toStringz);
		sdl_enforce(image != null);
	}



	void start() {
		int err;

		screen = SDL_SetVideoMode(image.w, image.h, 0,
		                          SDL_VideoFlags.ANYFORMAT);
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

		uint32_t now;

		now = SDL_GetTicks();
		if (now < lastPoll + 1000 / FPS)
			return;

		/* Consider text timeout as an event. */
		if (SDL_PollEvent(&e)) {
			/*
			 * Don't reset the timer when an event has been
			 * received so that queued events won't be throttled.
			 */
			handleEvent(e);
		} else {
			lastPoll = now;
			checkTimeoutText();
		}
	}



	void handleOneEventWait() {
		SDL_Event e;
		int err;

		if (textHasTimeout)
			err = waitEventTimeout(&e, textTimeout);
		else
			err = SDL_WaitEvent(&e);

		sdl_enforce(err != 0);

		/* An event arrived. */
		if (err == 1)
			handleEvent(e);

		/* Text has timeouted. */
		if (err == -1)
			checkTimeoutText();
	}



	void handlePendingEvents() {
		SDL_Event e;
		uint32_t now;

		now = SDL_GetTicks();
		if (now < lastPoll + 1000 / FPS)
			return;

		while (SDL_PollEvent(&e))
			handleEvent(e);

		lastPoll = now;
		checkTimeoutText();
	}



	void handlePendingEventsWait() {
		SDL_Event e;
		int err;

		while (!wantQuit) {
			if (textHasTimeout)
				err = waitEventTimeout(&e, textTimeout);
			else
				err = SDL_WaitEvent(&e);

			sdl_enforce(err != 0);

			if (err == 1)
				handleEvent(e);

			if (err == -1)
				checkTimeoutText();

			/* Special case because this loop never return. */
			updateDisplay(true);
		}
	}



	void run() {
		start();
		handlePendingEventsWait();
		finish();
	}



	private void handleEventMouseUp(ref SDL_MouseButtonEvent e) {
		Coord2D coord = Coord2D(e.x, e.y);

		switch (state) {
		case State.START_COORD:
			removeMessage();
			callbacks.startCoord(coord);
			state = State.NONE;
			break;

		case State.END_COORD:
			removeMessage();
			callbacks.endCoord(coord);
			state = State.NONE;
			break;

		case State.NONE:
		default:
			break;
		}
	}



	private void handleEventKeyUp(ref SDL_KeyboardEvent e) {
		switch (e.keysym.sym) {
		/* Quit */
		case SDLKey.SDLK_q:
			wantQuit = true;
			callbacks.quit();
			break;

		/* Stop search */
		case SDLKey.SDLK_ESCAPE:
			callbacks.stop();
			break;

		/* Start and destination coordinate */
		case SDLKey.SDLK_s:
			displayMessage("Click starting point");
			state = State.START_COORD;
			break;

		case SDLKey.SDLK_e:
			displayMessage("Click destination point");
			state = State.END_COORD;
			break;

		case SDLKey.SDLK_SPACE:
		case SDLKey.SDLK_RETURN:
			callbacks.start();
			break;

		default:
			/* TODO: Print help? */
			break;
		}
	}



	private void handleEvent(ref SDL_Event event) {
		switch (event.type) {
		case SDL_EventType.QUIT:
			wantQuit = true;
			callbacks.quit();
			break;

		case SDL_EventType.MOUSEBUTTONUP:
			handleEventMouseUp(event.button);
			break;

		case SDL_EventType.KEYUP:
			handleEventKeyUp(event.key);
			break;

		default:
			break;
		}
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



	void pixelPending(Coord2D coord) {
		pixelColor(coord, colorPending);
	}



	void pixelVisited(Coord2D coord) {
		pixelColor(coord, colorVisited);
	}



	void pixelPath(Coord2D coord) {
		pixelColor(coord, colorPath);
	}



	void updateDisplay(bool forced = false, bool selective = true) {
		SDL_Rect rect;
		uint32_t now;
		int err;

		now = SDL_GetTicks();
		if (!forced && now < lastFrame + 1000 / FPS)
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
		lastFrame = now;
	}



	private static SDL_Surface* optimizeSurface(SDL_Surface* input) {
		SDL_Surface* output;
		output = SDL_DisplayFormat(input);
		sdl_enforce(output != null);

		SDL_FreeSurface(input);
		return output;
	}



	private void pixelColor(Coord2D coord, Color color) {
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



	private void checkTimeoutText() {
		if (textHasTimeout && SDL_GetTicks() > textTimeout)
			removeMessage();
	}



	private int waitEventTimeout(SDL_Event* e, uint timeout) {
		int err;

		while (SDL_GetTicks() < timeout) {
			err = SDL_PollEvent(e);
			if (err == 1)
				return 1;
			SDL_Delay(10);
		}

		return -1;
	}



	private static void sdl_enforce(bool cond) {
		assert(cond, SDL_GetError().fromStringz);
	}



	private enum State {NONE, START_COORD, END_COORD, DISABLED};



	private static immutable int FPS = 60;
	private static immutable Color colorPending = Color(127, 127, 255);
	private static immutable Color colorVisited = Color(230, 230, 230);
	private static immutable Color colorPath = Color(255, 0, 0);
	private static immutable SDL_Color textColor = SDL_Color(0, 0, 127);
	private static immutable Coord2D textPos = Coord2D(0, 0);
	private static immutable int fontSize = 18;

	private bool wantQuit;
	private Coord2D updateMin, updateMax;
	private uint32_t lastFrame, lastPoll;
	private TTF_Font* font;
	private bool textHasTimeout;
	private uint textTimeout;
	private State state;

	/* Input image. */
	private SDL_Surface* image;

	/* Input image + progression. */
	private SDL_Surface* scratch;

	/* Surface for the text to be displayed. */
	private SDL_Surface* textSurf;

	/* Merge all the surfaces to be displayed. */
	private SDL_Surface* screen;
}
