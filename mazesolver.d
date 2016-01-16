import std.stdio;
import std.math;
import std.datetime;
import core.time;
import std.algorithm;
import std.traits;
import std.conv : to;

import gui;
import heap.binary;
import heap.pairing;
import binarizer;




class MazeSolver {
	public Gui gui;



	@property Coord2D startCoord() {
		return maze.start;
	}



	@property Coord2D startCoord(Coord2D c) {
		return maze.start = c;
	}



	@property Coord2D endCoord() {
		return maze.end;
	}



	@property Coord2D endCoord(Coord2D c) {
		return maze.end = c;
	}



	void stop() {
		wantStop = true;
	}



	void setMap(const bool[][] map) {
		maze.grid.length = 0;
		maze.grid.length = map.length;

		foreach (y; 0 .. map.length) {
			maze.grid[y].length = map[y].length;

			foreach (x; 0 .. map[y].length)
				maze.grid[y][x].isWall = !map[y][x];
		}
	}



	void run() {
		StopWatch timer;
		Duration dur;
		real dursec;

		wantStop = false;
		initMaze();
		timer.start();
		solveMaze();
		timer.stop();
		dur = cast(Duration)timer.peek;
		dursec = dur.total!"hnsecs" / cast(real)(seconds(1).total!"hnsecs");

		if (wantStop)
			gui.displayMessage("Stopped after " ~ to!string(dursec) ~ " seconds", 0);
		else
			gui.displayMessage("Done in " ~ to!string(dursec) ~ " seconds", 0);

		/* One last screen update. */
		gui.updateDisplay(true, false);
	}



	private void tracePath() {
		Coord2D here;

		here = maze.end;
		gui.pixelPath(here);

		while (here != maze.start) {
			here = maze.grid[here.y][here.x].prev;
			gui.pixelPath(here);
			gui.updateDisplay();
		}
		gui.updateDisplay(true);
	}



	private bool dirIsDiagonal(Coord2DDir dir) {
		final switch (dir) {
			case Coord2DDir.NORTHEAST:
			case Coord2DDir.NORTHWEST:
			case Coord2DDir.SOUTHWEST:
			case Coord2DDir.SOUTHEAST:
				return true;
			case Coord2DDir.EAST:
			case Coord2DDir.NORTH:
			case Coord2DDir.WEST:
			case Coord2DDir.SOUTH:
				return false;
		}
	}



	private Coord2D move(Coord2D coord, Coord2DDir dir) {
		final switch (dir) {
		case Coord2DDir.EAST:
			coord.x++;
			break;

		case Coord2DDir.NORTHEAST:
			coord.x++;
			coord.y--;
			break;

		case Coord2DDir.NORTH:
			coord.y--;
			break;

		case Coord2DDir.NORTHWEST:
			coord.x--;
			coord.y--;
			break;

		case Coord2DDir.WEST:
			coord.x--;
			break;

		case Coord2DDir.SOUTHWEST:
			coord.x--;
			coord.y++;
			break;

		case Coord2DDir.SOUTH:
			coord.y++;
			break;

		case Coord2DDir.SOUTHEAST:
			coord.x++;
			coord.y++;
			break;
		}

		return coord;
	}



	private bool canMove(Coord2D coord, Coord2DDir dir) {
		/* The coordinates are unsigned and may wrap. */
		static assert(isUnsigned!(typeof(coord.x)));
		static assert(isUnsigned!(typeof(coord.y)));

		Coord2D c = move(coord, dir);

		/* Since the coordinate wrap instead of going negative, the
		 * test is simpler. */
		if (c.y >= maze.grid.length)
			return false;
		if (c.x >= maze.grid[c.y].length)
			return false;

		if (maze.grid[c.y][c.x].isWall)
			return false;

		/* This test actually work for all 8 directions. */
		if (maze.grid[c.y][coord.x].isWall ||
		    maze.grid[coord.y][c.x].isWall)
			return false;

		return true;
	}



	/* Insert the neighbor cell in the heap if needed. */
	private void addNeighbor(Coord2D me, Coord2D other, HeapCoord2D pending, uint dist) {
		const Node* nme = &maze.grid[me.y][me.x];
		Node* nother = &maze.grid[other.y][other.x];

		if (nother.dist <= nme.dist + dist)
			return;

		assert(nother.state != NodeVisitState.VISITED, "Node already visited");

		nother.dist = nme.dist + dist;
		nother.prev = me;

		if (nother.state == NodeVisitState.UNVISITED) {
			nother.addtime = maze.time++;
			nother.state = NodeVisitState.PENDING;
			pending.insert(other);
			gui.pixelPending(other);
		} else {
			pending.update(other);
		}
	}



	private void solveMaze() {
		bool cmpcoord(Coord2D a, Coord2D b) {
			Node na, nb;
			na = maze.grid[a.y][a.x];
			nb = maze.grid[b.y][b.x];
			if (na.dist + na.heuristic != nb.dist + nb.heuristic)
				return na.dist + na.heuristic > nb.dist + nb.heuristic;

			return na.addtime < nb.addtime;
		}

		alias BinaryHeapCoord2D = BinaryHeap!(Coord2D, cmpcoord);
		alias PairingHeapCoord2D = PairingHeap!(Coord2D, cmpcoord);
		bool solved = false;
		HeapCoord2D pending = new PairingHeapCoord2D();

		pending.insert(maze.start);

		maze.grid[maze.start.y][maze.start.x].dist = 0;
		maze.grid[maze.start.y][maze.start.x].state = NodeVisitState.PENDING;

		while (!pending.empty && !wantStop) {
			Coord2D me = pending.removeAny();

			if (me == maze.end) {
				solved = true;
				break;
			}

			maze.grid[me.y][me.x].state = NodeVisitState.VISITED;

			foreach (dir; Coord2DDir.min .. Coord2DDir.max + 1) {
				Coord2DDir d = cast(Coord2DDir)dir;
				Coord2D other;

				if (!canMove(me, d))
					continue;

				other = move(me, d);

				// sqrt(2) is 1.4142135623
				if (dirIsDiagonal(d))
					addNeighbor(me, other, pending, 14);
				else
					addNeighbor(me, other, pending, 10);
			}

			gui.pixelVisited(me);
			gui.handlePendingEvents();
			gui.updateDisplay();
		}

		if (solved)
			tracePath();
	}



	private uint distance(Coord2D a, Coord2D b) {
		uint dx = abs(cast(int)a.x - cast(int)b.x);
		uint dy = abs(cast(int)a.y - cast(int)b.y);
		return 14 * min(dx, dy) + 10 * (max(dx, dy) - min(dx, dy));
	}



	private void initMaze() {
		foreach (y; 0 .. maze.grid.length) {
			foreach (x; 0 .. maze.grid[y].length) {
				Coord2D c = Coord2D(cast(uint)x, cast(uint)y);
				/* Reinit everything except isWall. */
				bool isWall = maze.grid[y][x].isWall;
				maze.grid[y][x] = maze.grid[y][x].init;
				maze.grid[y][x].isWall = isWall;
				maze.grid[y][x].heuristic = distance(c, maze.end);
			}
		}
	}






	private alias HeapCoord2D = Heap!Coord2D;

	private enum NodeVisitState : ubyte {
		UNVISITED,
		PENDING,
		VISITED
	}

	private enum Coord2DDir {
		EAST, NORTHEAST, NORTH, NORTHWEST, WEST, SOUTHWEST, SOUTH, SOUTHEAST
	}

	private struct Node {
		bool isWall;
		Coord2D prev;
		uint dist = uint.max;
		uint heuristic;
		NodeVisitState state = NodeVisitState.UNVISITED;
		uint addtime;
	}

	private struct Maze {
		Node[][] grid;
		Coord2D start;
		Coord2D end;
		uint time;
	}



	private Maze maze;
	private bool wantStop;
}



class MainCoordinator : GuiCallbacks {
	public MazeSolver solver;
	public Gui gui;
	public Binarizer binarizer;



	/* GUI Callbacks */
	void startCoord(Coord2D coord) {
		string msg;

		hasStart = true;
		solver.startCoord = coord;

		msg = "Start: " ~ to!string(coord.x);
		msg ~= ", " ~ to!string(coord.y);
		gui.displayMessage(msg);
		gui.updateDisplay(true);
	}

	void endCoord(Coord2D coord) {
		string msg;

		hasEnd = true;
		solver.endCoord = coord;

		msg = "Destination: " ~ to!string(coord.x);
		msg ~= ", " ~ to!string(coord.y);
		gui.displayMessage(msg);
		gui.updateDisplay(true);
	}

	void start() {
		if (!hasStart || !hasEnd || running) {
			help();
			return;
		}

		wantStart = true;
	}

	void stop() {
		solver.stop();
	}

	void quit() {
		solver.stop();
		wantQuit = true;
	}

	void reset() {
		solver.stop();
		/*
		 * Do not reset "running", it will reset itself when the solver
		 * actually stop.
		 * Do not reset "wantQuit" either as we should quit anyway even
		 * if by mistake we process a reset event while we already know
		 * we want to quit.
		 */
		wantStart = false;
		hasStart = false;
		hasEnd = false;
		disabled = false;
		gui.reset();

		if (!running)
			gui.displayMessage("Reset");

		gui.updateDisplay(true);
	}

	void unhandledKey() {
		help();
	}

	private void help() {
		if (disabled) {
			if (running)
				gui.displayMessage("Press ESC to stop or Q to quit or R to reset");
			else
				gui.displayMessage("Press Q to quit or R to reset");
		} else {
			if (!hasStart)
				gui.displayMessage("Press S");
			else if (!hasEnd)
				gui.displayMessage("Press E");
			else
				gui.displayMessage("Press SPACE or ENTER");
		}
		gui.updateDisplay(true);
	}



	/* Only public method of MainCoordinator */
	int run(string[] args) {
		string filename;

		if (args.length < 2) {
			stderr.writefln("usage: %s image", args[0]);
			return 1;
		}

		filename = args[1];

		gui.windowTitle = "Maze Solver";
		gui.loadImage(filename);
		gui.start();

		binarizer.setImage(gui.getImage());
		solver.setMap(binarizer.getBinaryImage());
		gui.setBinaryImage(binarizer.getBinaryImage());


		while (!wantQuit) {
			gui.updateDisplay(true);
			gui.handleOneEventWait();

			if (wantStart) {
				wantStart = false;
				gui.disable();
				disabled = true;

				gui.displayMessage("Searching...");
				gui.updateDisplay(true);

				running = true;
				solver.run();
				running = false;
			}
		}

		gui.finish();

		return 0;
	}



	private bool hasStart;
	private bool hasEnd;
	private bool wantStart;
	private bool wantQuit;
	private bool running;
	private bool disabled;
}



int main(string[] args) {
	SDLGui gui;
	MazeSolver solver;
	Binarizer binarizer;
	MainCoordinator coordinator;

	/* Instanciate the components. */
	gui = new SDLGui();
	solver = new MazeSolver();
	binarizer = new OtsuBinarizer();
	coordinator = new MainCoordinator();

	/* Connect the components. */
	solver.gui = gui;
	coordinator.solver = solver;
	coordinator.gui = gui;
	coordinator.binarizer = binarizer;
	gui.callbacks = coordinator;

	/* Run the main components. */
	return coordinator.run(args);
}
