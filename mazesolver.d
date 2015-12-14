import std.stdio;
import std.math;
import std.container.array;
import std.container.binaryheap;
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



void tracePath(ref Gui gui, Maze maze) {
	Coord2D here;

	here = maze.end;
	gui.pixelColor(here, colorpath);

	while (here != maze.start) {
		here = maze.grid[here.y][here.x].prev;
		gui.pixelColor(here, colorpath);
	}
}



void solveMaze(ref Gui gui, Maze maze) {
	bool cmpcoord(Coord2D a, Coord2D b) {
		Node na, nb;
		na = maze.grid[a.y][a.x];
		nb = maze.grid[b.y][b.x];
		if (na.dist + na.heuristic != nb.dist + nb.heuristic)
			return na.dist + na.heuristic > nb.dist + nb.heuristic;

		return na.addtime < nb.addtime;
	}

	bool addNeighbor(Coord2D me, Coord2D other) {
		bool add;

		if (other.y >= maze.grid.length)
			return false;
		if (other.x >= maze.grid[other.y].length)
			return false;

		const Node* nme = &maze.grid[me.y][me.x];
		Node* nother = &maze.grid[other.y][other.x];

		if (nother.isWall)
			return false;

		if (nother.dist <= nme.dist + 1)
			return false;

		assert(nother.state != NodeVisitState.VISITED);

		nother.dist = nme.dist + 1;
		nother.prev = me;

		if (nother.state == NodeVisitState.UNVISITED) {
			nother.addtime = maze.time++;
			nother.state = NodeVisitState.PENDING;
			return true;
		}

		return false;
	}

	alias ArrayCoord2D = Array!Coord2D;
	alias HeapCoord2D = Heap!(Coord2D, cmpcoord);
	bool solved = false;
	//ArrayCoord2D store = [maze.start];
	HeapCoord2D pending = new HeapCoord2D();

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
		if (addNeighbor(me, other)) {
			pending.insert(other);
			gui.pixelColor(other, colorpending);
		}
		pending.update(other);

		other = Coord2D(me.x, me.y + 1);
		if (addNeighbor(me, other)) {
			pending.insert(other);
			gui.pixelColor(other, colorpending);
		}
		pending.update(other);

		other = Coord2D(me.x - 1, me.y);
		if (addNeighbor(me, other)) {
			pending.insert(other);
			gui.pixelColor(other, colorpending);
		}
		pending.update(other);

		other = Coord2D(me.x + 1, me.y);
		if (addNeighbor(me, other)) {
			pending.insert(other);
			gui.pixelColor(other, colorpending);
		}
		pending.update(other);

		gui.pixelColor(me, colorvisited);
		gui.handlePendingEvents();
		gui.updateDisplay();
	}

	if (solved)
		tracePath(gui, maze);

	gui.updateDisplay(true, false);
	writeln("Done");
}



uint distance(Coord2D a, Coord2D b) {
	real dx = cast(real)a.x - cast(real)b.x;
	real dy = cast(real)a.y - cast(real)b.y;
	return cast(uint)hypot(dx, dy);
}



void dostuff(ref Gui gui) {
	MouseButtonEvent *mbe;
	Maze maze;
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

	solveMaze(gui, maze);
}

int main(string[] args) {
	string filename;
	Gui gui;

	if (args.length < 2) {
		stderr.writefln("usage: %s image", args[0]);
		return 1;
	}

	filename = args[1];

	gui = new SDLGui();
	gui.loadImage(filename);
	gui.start();
	dostuff(gui);
	gui.handlePendingEventsWait();
	gui.finish();

	return 0;
}
