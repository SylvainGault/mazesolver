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
	void reset(bool walls = false);

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

	/* Set a pixel to be a wall in the initial image. */
	void pixelWall(Coord2D coord);

	/* Update the displayed. */
	void updateDisplay(bool forced = false, bool selective = true);
}



interface GuiCallbacks {
	void startCoord(Coord2D coord);
	void endCoord(Coord2D coord);
	void start();
	void stop();
	void quit();
	void reset(bool hard);
	void unhandledKey();
	void thresholdChange(ubyte value);
	void addWall(Coord2D start, Coord2D end);
}



import std.stdio;
import std.algorithm : min, max, canFind;
import std.string : toStringz, fromStringz;
import std.exception : enforce;
import std.conv : to;
import core.stdc.string : memcpy;
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

		if (binWalls != null)
			SDL_FreeSurface(binWalls);
		binWalls = null;

		if (imageWalls != null)
			SDL_FreeSurface(imageWalls);
		imageWalls = null;

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
		Coord2D size;

		removeMessage();

		textSurf = TTF_RenderUTF8_Blended(font, msg.toStringz, textColor);
		sdl_enforce(textSurf != null);

		/* /!\ Do not optimize textSurf as it contains an alpha channel. */

		size = coordZoomToImage(Coord2D(textSurf.w, textSurf.h));
		mergeUpdate(textPos, size);

		/* Remember to remove that text (or not). */

		if (time == 0) {
			textHasTimeout = false;
			return;
		}

		textHasTimeout = true;
		textTimeout = SDL_GetTicks() + time;
	}



	void removeMessage() {
		Coord2D size;
		int err;

		if (textSurf == null)
			return;

		/* Say we've modified the area where was the text. */
		size = coordZoomToImage(Coord2D(textSurf.w, textSurf.h));
		mergeUpdate(textPos, size);

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
		int err;

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

		err = SDL_BlitSurface(imageBin, null, binWalls, null);
		sdl_enforce(err == 0);

		err = SDL_BlitSurface(imageWalls, null, binWalls, null);
		sdl_enforce(err == 0);

		/* We've modified everything. */
		mergeUpdateSurface(binWalls, Coord2D(0, 0), imageSize());
	}



	@property ubyte binThreshold() const {
		return thresh;
	}



	@property ubyte binThreshold(ubyte value) {
		thresh = value;
		return value;
	}



	void start() {
		uint32_t white;
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

		scratch = cloneSurface(image, true);
		sdl_enforce(scratch != null);

		imageBin = cloneSurface(image, false);
		sdl_enforce(imageBin != null);

		/* Fill the binary image with white by default. */
		white = SDL_MapRGB(imageBin.format, 255, 255, 255);
		err = SDL_FillRect(imageBin, null, white);
		sdl_enforce(err == 0);

		imageWalls = cloneSurface(imageBin, true);
		sdl_enforce(imageWalls != null);

		binWalls = cloneSurface(imageBin, true);
		sdl_enforce(binWalls != null);

		/* White is transparent. */
		err = SDL_SetColorKey(imageWalls, SDL_InternalFlags.SRCCOLORKEY, white);
		sdl_enforce(err == 0);

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

		SDL_FreeSurface(binWalls);
		binWalls = null;

		SDL_FreeSurface(imageWalls);
		imageWalls = null;

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
		drawingWall = false;
		showSurface(scratch);
	}



	void reset(bool walls = false) {
		int err;

		err = SDL_BlitSurface(image, null, scratch, null);
		sdl_enforce(err == 0);

		err = SDL_BlitSurface(imageBin, null, binWalls, null);
		sdl_enforce(err == 0);

		if (walls) {
			/* White is the transparent color-key. */
			uint32_t white;
			white = SDL_MapRGB(imageWalls.format, 255, 255, 255);
			err = SDL_FillRect(imageWalls, null, white);
			sdl_enforce(err == 0);
		} else {
			/*
			 * Only blit the walls onto the scratch and binWalls if
			 * we didn't reset it.
			 */
			err = SDL_BlitSurface(imageWalls, null, scratch, null);
			sdl_enforce(err == 0);

			err = SDL_BlitSurface(imageWalls, null, binWalls, null);
			sdl_enforce(err == 0);
		}

		mergeUpdateSurface(scratch, Coord2D(0, 0), imageSize());
		mergeUpdateSurface(binWalls, Coord2D(0, 0), imageSize());

		state = State.NONE;
	}



	void handleOneEvent() {
		SDL_Event e;

		uint32_t now;

		now = SDL_GetTicks();
		if (now < lastPoll + 1000 / FPS)
			return;

		/* Consider text timeout as an event. */
		if (pollEvent(&e)) {
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

		while (pollEvent(&e))
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



	private void handleActive(ref SDL_ActiveEvent e) {
		with (SDL_AppState) {
			if (e.gain == 0 && (e.state & (INPUTFOCUS | ACTIVE)) != 0)
				drawingWall = false;
		}
	}



	private void handleEventMouseDown(ref SDL_MouseButtonEvent e) {
		Coord2D coord = coordZoomToImage(Coord2D(e.x, e.y));

		switch (state) {
		case State.ADD_WALL:
			drawingWall = true;
			drawWallStart = coord;
			callbacks.addWall(coord, coord);
			break;

		default:
			break;
		}
	}



	private void handleEventMouseUpLeft(ref SDL_MouseButtonEvent e) {
		Coord2D coord = coordZoomToImage(Coord2D(e.x, e.y));

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

		case State.ADD_WALL:
			callbacks.addWall(drawWallStart, coord);
			drawingWall = false;
			break;

		default:
			break;
		}
	}



	private void handleEventMouseUpWheel(ref SDL_MouseButtonEvent e) {
		SDLMod mod = SDL_GetModState();
		int newZoomLevel;
		uint w, h;

		/* Only Ctrl+Wheel does something. */
		if ((mod & SDLMod.KMOD_CTRL) == 0)
			return;

		if (e.button == 4 && zoomLevel > -10)
			newZoomLevel = zoomLevel - 1;
		else if (e.button == 5 && zoomLevel < 10)
			newZoomLevel = zoomLevel + 1;

		if (newZoomLevel >= 0) {
			w = image.w * (1 << newZoomLevel);
			h = image.h * (1 << newZoomLevel);
		} else {
			w = image.w / (1 << -newZoomLevel);
			h = image.h / (1 << -newZoomLevel);
		}

		if (!SDL_VideoModeOK(w, h, screen.format.BitsPerPixel, screen.flags))
			return;

		screen = SDL_SetVideoMode(w, h, 0, screen.flags);
		zoomLevel = newZoomLevel;
		mergeUpdate(Coord2D(0, 0), imageSize());
	}



	private void handleEventMouseUp(ref SDL_MouseButtonEvent e) {
		if (e.button == 1)
			handleEventMouseUpLeft(e);
		else if (e.button == 4 || e.button == 5)
			handleEventMouseUpWheel(e);
	}



	private void handleEventMouseMotion(ref SDL_MouseMotionEvent e) {
		SDL_Event f;
		Coord2D coord;

		while (pollEvent(&f)) {
			SDL_MouseMotionEvent* m = &f.motion;
			if (f.type != e.type || m.which != e.which || m.state != e.state) {
				unpollEvent(&f);
				break;
			}

			e.x = m.x;
			e.y = m.y;
			e.xrel += m.xrel;
			e.yrel += m.yrel;
		}

		coord = coordZoomToImage(Coord2D(e.x, e.y));

		switch (state) {
		case State.ADD_WALL:
			if (drawingWall) {
				callbacks.addWall(drawWallStart, coord);
				drawWallStart = coord;
			}
			break;

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
			bool hard = cast(bool)(e.keysym.mod & SDLMod.KMOD_SHIFT);
			callbacks.reset(hard);
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
				showSurface(binWalls);
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

		case SDLKey.SDLK_w:
			if (state != State.ADD_WALL)
				state = State.ADD_WALL;
			else
				state = State.NONE;

			if (state == State.ADD_WALL)
				displayMessage("Click to add walls");
			else
				displayMessage("No more walls");
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

		case SDL_EventType.ACTIVEEVENT:
			handleActive(event.active);
			break;

		case SDL_EventType.MOUSEBUTTONDOWN:
			handleEventMouseDown(event.button);
			break;

		case SDL_EventType.MOUSEBUTTONUP:
			handleEventMouseUp(event.button);
			break;

		case SDL_EventType.MOUSEMOTION:
			handleEventMouseMotion(event.motion);
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
		pixelColor(scratch, coord, colorPending);
	}



	void pixelVisited(Coord2D coord) {
		pixelColor(scratch, coord, colorVisited);
	}



	void pixelPath(Coord2D coord) {
		pixelColor(scratch, coord, colorPath);
	}



	void pixelWall(Coord2D coord) {
		pixelColor(imageWalls, coord, colorWall);

		/* No need to blit for a single pixel. */
		pixelColor(scratch, coord, colorWall);
		pixelColor(binWalls, coord, colorWall);

		mergeUpdateSurface(scratch, coord, Coord2D(1, 1));
		mergeUpdateSurface(binWalls, coord, Coord2D(1, 1));
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

			if (updateMin.x >= image.w || updateMin.y >= image.h)
				return;

			updateMax.x = min(updateMax.x, image.w);
			updateMax.y = min(updateMax.y, image.h);

			rect.x = cast(typeof(rect.x))updateMin.x;
			rect.y = cast(typeof(rect.y))updateMin.y;
			rect.w = cast(typeof(rect.w))(updateMax.x - updateMin.x);
			rect.h = cast(typeof(rect.h))(updateMax.y - updateMin.y);
		} else {
			rect.x = 0;
			rect.y = 0;
			rect.w = cast(typeof(rect.w))image.w;
			rect.h = cast(typeof(rect.w))image.h;
		}


		err = screenBlitScale(surfInScreen, &rect);
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



	private int screenBlitScale(SDL_Surface* from, SDL_Rect* src) {
		if (zoomLevel == 0)
			return SDL_BlitSurface(from, src, screen, src);
		else if (zoomLevel > 0)
			return screenBlitScaleUp(from, src);
		else {
			return screenBlitScaleDown(from, src);
		}
	}



	/* Assume the source surface has the same format as screen. */
	private int screenBlitScaleDown(SDL_Surface* from, SDL_Rect* src) {
		immutable int factor = 1 << -zoomLevel;
		immutable ubyte bytepp = from.format.BytesPerPixel;
		SDL_Surface* to = screen;
		void* fromline, toline;

		assert(*from.format == *to.format, "Not same format");

		src.x /= factor;
		src.y /= factor;
		src.w /= factor;
		src.h /= factor;

		SDL_LockSurface(from);
		SDL_LockSurface(to);

		fromline = from.pixels + from.pitch * src.y * factor;
		toline = to.pixels + to.pitch * src.y;

		foreach (y; 0 .. src.h) {
			void* frompixel = fromline + bytepp * src.x * factor;
			void* topixel = toline + bytepp * src.x;

			foreach (x; 0 .. src.w) {
				uint32_t value;
				assert(value.sizeof >= bytepp);

				value = pixelAverage(frompixel, from.pitch, from.format);
				memcpy(topixel, &value, bytepp);

				frompixel += bytepp * factor;
				topixel += bytepp;
			}

			fromline += from.pitch * factor;
			toline += to.pitch;
		}

		SDL_UnlockSurface(to);
		SDL_UnlockSurface(from);

		return 0;
	}



	private uint32_t pixelAverage(void* firstpx, uint16_t pitch, SDL_PixelFormat* format) {
		immutable int factor = 1 << -zoomLevel;
		immutable ubyte bytepp = format.BytesPerPixel;
		immutable uint npx = factor * factor;
		uint rsum, gsum, bsum;
		ubyte r, g, b;

		foreach (y; 0 .. factor) {
			void* pixel = firstpx;

			foreach (x; 0 .. factor) {
				SDL_GetRGB(*cast(uint32_t*)pixel, format, &r, &g, &b);
				rsum += r;
				gsum += g;
				bsum += b;

				pixel += bytepp;
			}

			firstpx += pitch;
		}

		r = cast(typeof(r))(rsum / npx);
		g = cast(typeof(g))(gsum / npx);
		b = cast(typeof(b))(bsum / npx);

		return SDL_MapRGB(format, r, g, b);
	}



	private int screenBlitScaleUp(SDL_Surface* from, SDL_Rect* src) {
		immutable int factor = 1 << zoomLevel;
		immutable ubyte bytepp = from.format.BytesPerPixel;
		SDL_Surface* to = screen;
		void* fromline, toline;

		assert(*from.format == *to.format, "Not same format");

		SDL_LockSurface(from);
		SDL_LockSurface(to);

		fromline = from.pixels + from.pitch * src.y;
		toline = to.pixels + to.pitch * src.y * factor;

		foreach (y; 0 .. src.h) {
			void* frompixel = fromline + src.x * bytepp;
			void* topixel = toline + src.x * bytepp * factor;

			foreach (x; 0 .. src.w) {
				uint32_t value;
				assert(value.sizeof >= bytepp);

				memcpy(&value, frompixel, bytepp);
				paintPixel(topixel, to.pitch, value, bytepp);

				frompixel += bytepp;
				topixel += bytepp * factor;
			}

			fromline += from.pitch;
			toline += to.pitch * factor;
		}

		SDL_UnlockSurface(to);
		SDL_UnlockSurface(from);

		src.x *= factor;
		src.y *= factor;
		src.w *= factor;
		src.h *= factor;

		return 0;
	}



	private void paintPixel(void* line, uint16_t pitch, uint32_t value, ubyte bytepp) {
		immutable int factor = 1 << zoomLevel;

		foreach (y; 0 .. factor) {
			void* pixel = line;

			foreach (x; 0 .. factor) {
				memcpy(pixel, &value, bytepp);
				pixel += bytepp;
			}

			line += pitch;
		}
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



	private static SDL_Surface* cloneSurface(SDL_Surface* s, bool data) {
		immutable uint32_t f = s.flags;
		immutable int w = s.w;
		immutable int h = s.h;
		immutable int d = s.format.BitsPerPixel;
		immutable uint32_t r = s.format.Rmask;
		immutable uint32_t g = s.format.Gmask;
		immutable uint32_t b = s.format.Bmask;
		immutable uint32_t a = s.format.Amask;
		SDL_Surface* ret;

		ret = SDL_CreateRGBSurface(f, w, h, d, r, g, b, a);

		/* Clone data with memcpy since the format is the same. */
		if (data) {
			SDL_LockSurface(s);
			SDL_LockSurface(ret);
			memcpy(ret.pixels, s.pixels, s.pitch * s.h);
			SDL_UnlockSurface(ret);
			SDL_UnlockSurface(s);
		}

		return ret;
	}



	private void pixelColor(SDL_Surface* surf, Coord2D coord, Color color) {
		void* pixeldata;
		uint pixel;
		immutable ubyte bytepp = surf.format.BytesPerPixel;

		assert(bytepp <= typeof(pixel).sizeof);
		assert(coord.x < surf.w);
		assert(coord.y < surf.h);

		pixel = SDL_MapRGB(surf.format, color.r, color.g, color.b);

		SDL_LockSurface(surf);
		pixeldata = surf.pixels;
		pixeldata += coord.y * surf.pitch + coord.x * bytepp;
		*cast(typeof(pixel)*)pixeldata = pixel;
		SDL_UnlockSurface(surf);

		mergeUpdateSurface(surf, coord, Coord2D(1, 1));
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



	private int pollEvent(SDL_Event* e) {
		if (!hasBufferedEvent)
			return SDL_PollEvent(e);

		hasBufferedEvent = false;
		*e = bufferedEvent;
		return 1;
	}



	private void unpollEvent(SDL_Event* e) {
		assert(!hasBufferedEvent);

		bufferedEvent = *e;
		hasBufferedEvent = true;
	}



	private int waitEventTimeout(SDL_Event* e) {
		int err;
		uint32_t timeout;

		/* Check for a buffered event before even trying to sleep. */
		if (hasBufferedEvent) {
			pollEvent(e);
			return 1;
		}

		if (!textHasTimeout && !binHasTimeout)
			return SDL_WaitEvent(e);

		if (textHasTimeout && !binHasTimeout)
			timeout = textTimeout;
		else if (!textTimeout && binHasTimeout)
			timeout = binTimeout;
		else
			timeout = min(textTimeout, binTimeout);

		while (SDL_GetTicks() < timeout) {
			err = pollEvent(e);
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
			showSurface(binWalls);
		}
		callbacks.thresholdChange(thresh);
	}



	private Coord2D coordZoomToImage(Coord2D c) {
		Coord2D coord;

		if (zoomLevel >= 0) {
			immutable int factor = 1 << zoomLevel;
			coord = Coord2D(c.x / factor, c.y / factor);
		} else {
			immutable int factor = 1 << -zoomLevel;
			coord = Coord2D(c.x * factor, c.y * factor);
		}

		return coord;
	}



	private static void sdl_enforce(bool cond) {
		enforce(cond, SDL_GetError().fromStringz);
	}



	private enum State {NONE, START_COORD, END_COORD, ADD_WALL, DISABLED};



	private static immutable int FPS = 60;
	private static immutable Color colorPending = Color(127, 127, 255);
	private static immutable Color colorVisited = Color(230, 230, 230);
	private static immutable Color colorPath = Color(255, 0, 0);
	private static immutable Color colorWall = Color(0, 0, 0);
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
	private bool drawingWall;
	private Coord2D drawWallStart;
	private int zoomLevel;
	private State state;

	private bool hasBufferedEvent;
	private SDL_Event bufferedEvent;

	/* Input image. */
	private SDL_Surface* image;
	private Color[][] imageData;

	/* Hand-drawn walls. */
	private SDL_Surface* imageWalls;

	/* Binarized image. */
	private SDL_Surface* imageBin;

	/* Binarized image + hand-drawn walls. */
	private SDL_Surface* binWalls;

	/* Input image + hand-drawn walls + progression. */
	private SDL_Surface* scratch;

	/* Surface for the text to be displayed. */
	private SDL_Surface* textSurf;

	/* Pointer to the surface blitted in screen. */
	private SDL_Surface* surfInScreen;

	/* Merge all the surfaces to be displayed. */
	private SDL_Surface* screen;
}
