module Heap;

import std.stdio;
import core.exception;



class Heap(T, alias less = "a < b") {
	import std.functional : binaryFun;


	@property bool empty() const {
		return length == 0;
	}



	@property size_t length() const {
		return data.length;
	}



	@property T front() const {
		assert(!empty, "Cannot call front on an empty heap.");
		return data[0];
	}



	void insert(T e) {
		data ~= e;
		indexOf[e] = data.length - 1;
		bubbleUp(data.length - 1);
	}



	void removeFront() {
		assert(!empty, "Cannot call removeFront on an empty heap.");
		indexOf.remove(data[0]);
		data[0] = data[data.length - 1];
		indexOf[data[0]] = 0;
		data.length--;
		bubbleDown(0);
	}



	T removeAny() {
		T e = front();
		removeFront();
		return e;
	}



	string toString() const {
		import std.conv : to;
		return to!string(data);
	}



	void rebuild() {
		if (data.length <= 1)
			return;

		/* This loop is all shifted by 1 so that the condition "i > 0"
		 * works with size_t which is unsigned. */
		for (size_t i = data.length / 2; i > 0; i--)
			bubbleDown(i - 1);
	}



	void update(T e) {
		if (e !in indexOf)
			return;

		size_t idx = indexOf[e];
		size_t parentIdx = (idx - 1) / 2;

		if (idx > 0 && comp(data[parentIdx], data[idx]))
			bubbleUp(idx);
		else
			bubbleDown(idx);
	}



	/* Take a heap with the last element violating the Heap invariant and
	 * restore it. */
	private void bubbleUp(size_t idx) {
		size_t parentIdx = (idx - 1) / 2;

		while (idx > 0 && comp(data[parentIdx], data[idx])) {
			swapAt(parentIdx, idx);
			idx = parentIdx;
			parentIdx = (idx - 1) / 2;
		}
	}



	/* Take a heap with the first element violating the Heap invariant and
	 * restore it. */
	private void bubbleDown(size_t idx) {
		size_t leftIdx = 2 * idx + 1;
		size_t rightIdx = leftIdx + 1;

		while (leftIdx < data.length) {
			bool l, r, swapright;

			l = comp(data[idx], data[leftIdx]);
			if (rightIdx < data.length)
				r = comp(data[idx], data[rightIdx]);

			if (l && r && comp(data[leftIdx], data[rightIdx]))
				swapright = true;

			if (!l && r)
				swapright = true;

			if (!l && !r)
				break;

			if (swapright) {
				swapAt(idx, rightIdx);
				idx = rightIdx;
			} else {
				swapAt(idx, leftIdx);
				idx = leftIdx;
			}

			leftIdx = 2 * idx + 1;
			rightIdx = leftIdx + 1;
		}
	}



	private void swapAt(size_t a, size_t b) {
		swap(data[a], data[b]);
		indexOf[data[a]] = a;
		indexOf[data[b]] = b;
	}



	private void swap(E)(ref E a, ref E b) {
		E tmp = a;
		a = b;
		b = tmp;
	}



	/* Used for debugging. */
	private void assertHeap() const {
		if (data.length <= 1)
			return;

		for (size_t i = 0; i <= (data.length - 2) / 2; i++) {
			assert(!comp(data[i], data[2 * i + 1]));

			if (2 * i + 2 < data.length)
				assert(!comp(data[i], data[2 * i + 2]));
		}
	}



	private void assertIndexOf() const {
		foreach (i, e; data)
			assert(indexOf[e] == i);
	}



	private T[] data;
	private size_t[T] indexOf;
	private alias comp = binaryFun!less;
}
