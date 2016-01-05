module heap.pairing;

import std.container.dlist;
import std.range;

public import heap.heap;



class PairingHeap(T, alias less = "a < b") : Heap!T {
	import std.functional : binaryFun;


	@property bool empty() const {
		return length == 0;
	}



	@property size_t length() const {
		return size;
	}



	@property T front() const {
		assert(!empty, "Cannot call front on an empty heap.");
		return root.elem;
	}



	void insert(T e) {
		RealHeap* n = new RealHeap(e);
		root = merge(root, n);
		size++;
		assert(root.parent == null);
	}



	void removeFront() {
		assert(!empty, "Cannot call removeFront on an empty heap.");
		lookup.remove(root.elem);
		root = mergePairs();
		if (root != null)
			root.parent = null;
		size--;
	}



	T removeAny() {
		T e = front();
		removeFront();
		return e;
	}



	void rebuild() {
		RealHeap*[] pending;
		RealHeap* newroot = null;

		lookup = lookup.init;
		size = 0;

		if (root == null)
			return;

		pending ~= root;
		root = null;

		while (pending.length > 0) {
			RealHeap* n = pending[$ - 1];
			pending.length--;

			foreach (h; n.subheap)
				pending ~= h;

			n.subheap.clear();

			root = merge(root, n);
			size++;
		}
	}



	void update(T e) {
		assert(!empty);

		if (root.elem == e)
			return;

		RealHeap* h;
		DListHeapPtr p = lookup[e];
		h = p.front;

		if (comp(h.parent.elem, h.elem)) {
			lookup.remove(e);
			h.parent.subheap.remove(p.source);
			h.parent = null;
			root = merge(root, h);
		}

		/* TODO: Check for increased key? */
	}



	/* Merge the other heap into the current one and acquire the pointer. */
	private RealHeap* merge(RealHeap *me, RealHeap* other) {
		if (other == null)
			return me;

		if (me == null)
			return other;

		/* Only merge one root into one root. */
		assert(other.elem !in lookup, "other in lookup");
		assert(me.elem !in lookup, "me in lookup");

		if (comp(me.elem, other.elem)) {
			other.subheap.insertFront(me);
			me.parent = other;
			lookup[me.elem] = other.subheap[].take(1);
			return other;
		} else {
			me.subheap.insertFront(other);
			other.parent = me;
			lookup[other.elem] = me.subheap[].take(1);
			return me;
		}
	}



	private RealHeap* mergePairs() {
		RealHeap*[] tmp;
		RealHeap* res;

		if (empty)
			return null;

		if (root.subheap.empty())
			return null;

		DListHeap.Range r = root.subheap[];
		foreach(ha, hb; zip(StoppingPolicy.longest, r.stride(2), r.drop(1).stride(2))) {
			lookup.remove(ha.elem);
			ha.parent = null;

			if (hb != null) {
				lookup.remove(hb.elem);
				hb.parent = null;
			}

			tmp ~= merge(ha, hb);
		}

		root.subheap.clear();

		foreach (h; tmp)
			res = merge(res, h);

		return res;
	}



	private alias comp = binaryFun!less;
	private alias DListHeap = DList!(RealHeap*);
	private alias DListHeapPtr = Take!(DListHeap.Range);

	private struct RealHeap {
		T elem;
		RealHeap* parent;
		DListHeap subheap;
	}

	size_t size;
	RealHeap* root;
	DListHeapPtr[T] lookup;
}
