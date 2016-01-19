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

	/* Retrive a pointer to a the loaded image. */
	const(Color[][]) getImage();

	/* Set the binary image to display. */
	void setBinaryImage(const bool[][] img);

	/* Get / set the threshold cursor. */
	@property ubyte binThreshold() const;
	@property ubyte binThreshold(ubyte value);

	/* Display a window with the image. */
	void start();

	/* Close the window. */
	void finish();

	/* Disable all the constrols beside quit, stop and reset. */
	void disable();

	/* Reset the GUI display and re-enable controls. */
	void reset();

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
	void reset();
	void unhandledKey();
	void thresholdChange(ubyte value);
}



import std.stdio;
import std.algorithm : min, max, canFind;
import std.string : toStringz, fromStringz;
import std.exception : enforce;
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
		if (textSurf != null)
			SDL_FreeSurface(textSurf);
		textSurf = null;

		if (image != null)
			SDL_FreeSurface(image);
		image = null;

		if (imageBin != null)
			SDL_FreeSurface(imageBin);
		imageBin = null;

		if (scratch != null)
			SDL_FreeSurface(scratch);
		scratch = null;

		if (screen != null)
			SDL_FreeSurface(screen);
		screen = null;

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

		if (textSurf == null)
			return;

		/* Say we've modified the area where was the text. */
		mergeUpdate(textPos, Coord2D(textSurf.w, textSurf.h));

		SDL_FreeSurface(textSurf);
		textSurf = null;
		textTimeout = 0;
		textHasTimeout = false;
	}



	void loadImage(string filename) {
		import core.bitop : bsf;

		static uint32_t colorToUint(Color c) {
			static assert(uint32_t.sizeof >= Color.sizeof);
			uint32_t res;
			*cast(Color*)&res = c;
			return res;
		}

		SDL_Surface* image888;
		SDL_PixelFormat format;
		Color* ptr;
		ubyte* line;
		immutable uint32_t rmask = colorToUint(Color(255, 0, 0));
		immutable uint32_t gmask = colorToUint(Color(0, 255, 0));
		immutable uint32_t bmask = colorToUint(Color(0, 0, 255));

		image = IMG_Load(filename.toStringz);
		sdl_enforce(image != null);

		/*
		 * Convert the pixels data to an array of struct Color once for
		 * all.
		 */
		format.BytesPerPixel = Color.sizeof;
		format.BitsPerPixel = Color.sizeof * 8;
		format.Rmask = rmask;
		format.Gmask = gmask;
		format.Bmask = bmask;
		format.Rshift = cast(typeof(format.Rshift))bsf(format.Rmask);
		format.Gshift = cast(typeof(format.Gshift))bsf(format.Gmask);
		format.Bshift = cast(typeof(format.Bshift))bsf(format.Bmask);

		image888 = SDL_ConvertSurface(image, &format, 0);
		sdl_enforce(image888 != null);


		SDL_LockSurface(image888);

		line = cast(typeof(line))image888.pixels;

		imageData.length = image888.h;
		foreach (y; 0 .. image888.h) {
			imageData[y].length = image888.w;

			ptr = cast(typeof(ptr))line;

			foreach (x; 0 .. image888.w) {
				imageData[y][x] = *ptr;
				ptr++;
			}

			line += image888.pitch;
		}

		SDL_UnlockSurface(image888);
		SDL_FreeSurface(image888);
	}



	const(Color[][]) getImage() {
		return imageData;
	}



	void setBinaryImage(const bool[][] img) {
		ubyte* line, ptr;
		uint black, white;

		SDL_LockSurface(imageBin);
		black = SDL_MapRGB(imageBin.format, 0, 0, 0);
		white = SDL_MapRGB(imageBin.format, 255, 255, 255);

		line = cast(typeof(line))imageBin.pixels;

		assert(img.length == imageBin.h);
		foreach (y; 0 .. imageBin.h) {
			assert(img[y].length == imageBin.w);

			ptr = line;

			foreach (x; 0 .. imageBin.w) {
				if (img[y][x])
					*cast(typeof(white)*)ptr = white;
				else
					*cast(typeof(black)*)ptr = black;

				ptr += imageBin.format.BytesPerPixel;
			}

			line += imageBin.pitch;
		}

		SDL_UnlockSurface(imageBin);

		/* We've modified everything. */
		mergeUpdateSurface(imageBin, Coord2D(0, 0), imageSize());
	}



	@property ubyte binThreshold() const {
		return thresh;
	}



	@property ubyte binThreshold(ubyte value) {
		thresh = value;
		return value;
	}



	void start() {
		int err;

		err = SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);
		sdl_enforce(err == 0);

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

		imageBin = SDL_ConvertSurface(image, image.format, image.flags);
		sdl_enforce(imageBin != null);

		/* Show scratch by default */
		showSurface(scratch);
	}



	void finish() {
		if (textSurf != null)
			SDL_FreeSurface(textSurf);
		textSurf = null;

		SDL_FreeSurface(image);
		image = null;

		SDL_FreeSurface(imageBin);
		imageBin = null;

		SDL_FreeSurface(scratch);
		scratch = null;

		SDL_FreeSurface(screen);
		screen = null;

		TTF_CloseFont(font);
		font = null;

	}



	void disable() {
		state = State.DISABLED;
		showBin = false;
		showSurface(scratch);
	}



	void reset() {
		int err;

		err = SDL_BlitSurface(image, null, scratch, null);
		sdl_enforce(err == 0);

		mergeUpdateSurface(scratch, Coord2D(0, 0), imageSize());

		state = State.NONE;
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
			checkTimeout();
		}
	}



	void handleOneEventWait() {
		SDL_Event e;
		int err;

		err = waitEventTimeout(&e);
		sdl_enforce(err != 0);

		/* An event arrived. */
		if (err == 1)
			handleEvent(e);

		/* Text has timeouted. */
		if (err == -1)
			checkTimeout();
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
		checkTimeout();
	}



	void handlePendingEventsWait() {
		SDL_Event e;
		int err;

		while (!wantQuit) {
			err = waitEventTimeout(&e);
			sdl_enforce(err != 0);

			if (err == 1)
				handleEvent(e);

			if (err == -1)
				checkTimeout();

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



	private void handleEventKeyDown(ref SDL_KeyboardEvent e) {
		enum alwaysAllowed = [
			SDLKey.SDLK_q,
			SDLKey.SDLK_ESCAPE,
			SDLKey.SDLK_r
		];

		if (state == State.DISABLED && !alwaysAllowed.canFind(e.keysym.sym)) {
			callbacks.unhandledKey();
			return;
		}

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

		/* Reset solve */
		case SDLKey.SDLK_r:
			callbacks.reset();
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

		case SDLKey.SDLK_b:
			showBin = !showBin;
			binHasTimeout = false;
			binTimeout = 0;

			if (showBin)
				showSurface(imageBin);
			else
				showSurface(scratch);

			break;

		case SDLKey.SDLK_LEFT:
			if (thresh > 0)
				eventChangeThreshold(cast(ubyte)(thresh - 1));
			break;

		case SDLKey.SDLK_RIGHT:
			if (thresh < 255)
				eventChangeThreshold(cast(ubyte)(thresh + 1));
			break;

		default:
			callbacks.unhandledKey();
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

		case SDL_EventType.KEYDOWN:
			handleEventKeyDown(event.key);
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
		assert(coord.x < image.w);
		assert(coord.y < image.h);

		return imageData[coord.y][coord.x];
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


		err = SDL_BlitSurface(surfInScreen, &rect, screen, &rect);
		sdl_enforce(err == 0);

		if (textSurf != null) {
			SDL_Rect textRect;
			textRect.x = cast(typeof(textRect.x))textPos.x;
			textRect.y = cast(typeof(textRect.y))textPos.y;
			textRect.w = cast(typeof(textRect.w))textSurf.w;
			textRect.h = cast(typeof(textRect.h))textSurf.h;

			if (intersectRect(&textRect, &rect)) {
				err = SDL_BlitSurface(textSurf, null, screen, &textRect);
				sdl_enforce(err == 0);
			}
		}

		SDL_UpdateRect(screen, rect.x, rect.y, rect.w, rect.h);

		updateMin = typeof(updateMin).init;
		updateMax = typeof(updateMax).init;
		lastFrame = now;
	}



	private void showSurface(SDL_Surface* surf) {
		if (surf == surfInScreen)
			return;

		surfInScreen = surf;
		mergeUpdate(Coord2D(0, 0), imageSize());
	}



	private static SDL_Surface* optimizeSurface(SDL_Surface* input) {
		SDL_Surface* output;
		output = SDL_DisplayFormat(input);
		sdl_enforce(output != null);

		SDL_FreeSurface(input);
		return output;
	}



	private void pixelColor(Coord2D coord, Color color) {
		void* pixeldata;
		uint pixel;
		immutable ubyte bytepp = scratch.format.BytesPerPixel;

		assert(bytepp <= typeof(pixel).sizeof);
		assert(coord.x < scratch.w);
		assert(coord.y < scratch.h);

		pixel = SDL_MapRGB(scratch.format, color.r, color.g, color.b);

		SDL_LockSurface(scratch);
		pixeldata = scratch.pixels;
		pixeldata += coord.y * scratch.pitch + coord.x * bytepp;
		*cast(typeof(pixel)*)pixeldata = pixel;
		SDL_UnlockSurface(scratch);

		mergeUpdateSurface(scratch, coord, Coord2D(1, 1));
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



	private void mergeUpdateSurface(SDL_Surface* s, Coord2D c, Coord2D sz) {
		if (s != surfInScreen)
			return;
		mergeUpdate(c, sz);
	}



	private void checkTimeout() {
		uint32_t now = SDL_GetTicks();

		if (textHasTimeout && now > textTimeout)
			removeMessage();

		if (binHasTimeout && now > binTimeout) {
			binHasTimeout = false;
			binTimeout = 0;
			showBin = false;
			showSurface(scratch);
		}
	}



	private int waitEventTimeout(SDL_Event* e) {
		int err;
		uint32_t timeout;

		if (!textHasTimeout && !binHasTimeout)
			return SDL_WaitEvent(e);

		if (textHasTimeout && !binHasTimeout)
			timeout = textTimeout;
		else if (!textTimeout && binHasTimeout)
			timeout = binTimeout;
		else
			timeout = min(textTimeout, binTimeout);

		while (SDL_GetTicks() < timeout) {
			err = SDL_PollEvent(e);
			if (err == 1)
				return 1;
			SDL_Delay(10);
		}

		/* return -1 in case of timeout */
		return -1;
	}



	private void eventChangeThreshold(ubyte value) {
		thresh = value;
		if (!showBin || binHasTimeout) {
			binTimeout = SDL_GetTicks() + BINTIMEOUT;
			binHasTimeout = true;
			showBin = true;
			showSurface(imageBin);
		}
		callbacks.thresholdChange(thresh);
	}



	private static void sdl_enforce(bool cond) {
		enforce(cond, SDL_GetError().fromStringz);
	}



	private enum State {NONE, START_COORD, END_COORD, DISABLED};



	private static immutable int FPS = 60;
	private static immutable Color colorPending = Color(127, 127, 255);
	private static immutable Color colorVisited = Color(230, 230, 230);
	private static immutable Color colorPath = Color(255, 0, 0);
	private static immutable SDL_Color textColor = SDL_Color(0, 0, 127);
	private static immutable Coord2D textPos = Coord2D(0, 0);
	private static immutable int fontSize = 18;
	private static immutable BINTIMEOUT = 3000;

	private bool wantQuit;
	private Coord2D updateMin, updateMax;
	private uint32_t lastFrame, lastPoll;
	private TTF_Font* font;
	private bool textHasTimeout;
	private uint32_t textTimeout;
	private bool showBin;
	private bool binHasTimeout;
	private uint32_t binTimeout;
	private ubyte thresh;
	private State state;

	/* Input image. */
	private SDL_Surface* image;
	private Color[][] imageData;

	/* Binarized image. */
	private SDL_Surface* imageBin;

	/* Input image + progression. */
	private SDL_Surface* scratch;

	/* Surface for the text to be displayed. */
	private SDL_Surface* textSurf;

	/* Pointer to the surface blitted in screen. */
	private SDL_Surface* surfInScreen;

	/* Merge all the surfaces to be displayed. */
	private SDL_Surface* screen;
}
