import std.stdio;
import std.math;
import std.datetime;
import core.time;
import std.algorithm;

import gui;
import heap;




enum Color colorvisited = Color(230, 230, 230);
enum Color colorpending = Color(127, 127, 255);
enum Color colorpath = Color(255, 0, 0);


enum NodeVisitState : ubyte {
	UNVISITED,
	PENDING,
	VISITED
}

struct Node {
	bool isWall;
	Coord2D prev;
	uint dist = uint.max;
	uint heuristic;
	NodeVisitState state = NodeVisitState.UNVISITED;
	uint addtime;
}



struct Maze {
	Node[][] grid;
	Coord2D start;
	Coord2D end;
	uint time;
}



class MazeSolver {
	public Gui gui;



	private void tracePath() {
		Coord2D here;

		here = maze.end;
		gui.pixelColor(here, colorpath);

		while (here != maze.start) {
			here = maze.grid[here.y][here.x].prev;
			gui.pixelColor(here, colorpath);
		}
	}



	/* Insert the neighbor cell in the heap if needed. */
	private void addNeighbor(Coord2D me, Coord2D other, HeapCoord2D pending) {
		bool add;

		if (other.y >= maze.grid.length)
			return;
		if (other.x >= maze.grid[other.y].length)
			return;

		const Node* nme = &maze.grid[me.y][me.x];
		Node* nother = &maze.grid[other.y][other.x];

		if (nother.isWall)
			return;

		if (nother.dist <= nme.dist + 1)
			return;

		assert(nother.state != NodeVisitState.VISITED);

		nother.dist = nme.dist + 1;
		nother.prev = me;

		if (nother.state == NodeVisitState.UNVISITED) {
			nother.addtime = maze.time++;
			nother.state = NodeVisitState.PENDING;
			pending.insert(other);
			gui.pixelColor(other, colorpending);
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
		bool solved = false;
		HeapCoord2D pending = new BinaryHeapCoord2D();

		pending.insert(maze.start);

		maze.grid[maze.start.y][maze.start.x].dist = 0;
		maze.grid[maze.start.y][maze.start.x].state = NodeVisitState.PENDING;

		while (pending.length > 0 && !gui.quit) {
			Coord2D me = pending.removeAny();
			Coord2D other;

			if (me == maze.end) {
				solved = true;
				break;
			}

			maze.grid[me.y][me.x].state = NodeVisitState.VISITED;

			other = Coord2D(me.x, me.y - 1);
			addNeighbor(me, other, pending);

			other = Coord2D(me.x, me.y + 1);
			addNeighbor(me, other, pending);

			other = Coord2D(me.x - 1, me.y);
			addNeighbor(me, other, pending);

			other = Coord2D(me.x + 1, me.y);
			addNeighbor(me, other, pending);

			gui.pixelColor(me, colorvisited);
			gui.handlePendingEvents();
			gui.updateDisplay();
		}

		if (solved)
			tracePath();

		gui.updateDisplay(true, false);
		writeln("Done");
	}



	private uint distance(Coord2D a, Coord2D b) {
		real dx = cast(real)a.x - cast(real)b.x;
		real dy = cast(real)a.y - cast(real)b.y;
		return cast(uint)hypot(dx, dy);
	}



	private void initMaze() {
		MouseButtonEvent *mbe;
		Color cs, ce;
		Coord2D size;

		writeln("Click starting point");
		while ((mbe = gui.lastClick()) == null && !gui.quit)
			gui.handleOneEventWait();

		if (gui.quit)
			return;

		maze.start = mbe.coord;
		maze.start.writeln;

		writeln("Click destination point");
		while ((mbe = gui.lastClick()) == null && !gui.quit)
			gui.handleOneEventWait();

		if (gui.quit)
			return;

		maze.end = mbe.coord;
		maze.end.writeln;

		cs = gui.pixelColor(maze.start);
		ce = gui.pixelColor(maze.end);

		assert(cs == ce);

		size = gui.imageSize();

		maze.grid.length = size.y;
		foreach (y; 0 .. size.y) {
			maze.grid[y].length = size.x;

			foreach (x; 0 .. size.x) {
				Coord2D c = Coord2D(x, y);
				maze.grid[y][x].isWall = (gui.pixelColor(c) != cs);
				maze.grid[y][x].heuristic = distance(c, maze.end);
			}
		}
	}



	private void dostuff() {
		StopWatch timer;
		Duration dur;

		initMaze();
		timer.start();
		solveMaze();
		timer.stop();
		dur = cast(Duration)timer.peek;
		writeln(dur.total!"hnsecs" / cast(real)(seconds(1).total!"hnsecs"));
	}



	int run(string[] args) {
		string filename;

		if (args.length < 2) {
			stderr.writefln("usage: %s image", args[0]);
			return 1;
		}

		filename = args[1];

		gui.setTitle("Maze Solver");
		gui.loadImage(filename);
		gui.start();
		dostuff();
		gui.handlePendingEventsWait();
		gui.finish();

		return 0;
	}



	private alias HeapCoord2D = Heap!Coord2D;

	private Maze maze;
}



int main(string[] args) {
	Gui gui;
	MazeSolver solver;

	/* Instanciate the components. */
	gui = new SDLGui();
	solver = new MazeSolver();

	/* Connect the components. */
	solver.gui = gui;

	/* Run the main components. */
	return solver.run(args);
}
