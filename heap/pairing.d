module heap.pairing;

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
		n.next = n.prev = n;
		lookup[e] = n;
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
			RealHeap* h;
			RealHeap* n = pending[$ - 1];
			pending.length--;

			while ((h = removeSubheap(n)) != null)
				pending ~= h;

			lookup[n.elem] = n;
			root = merge(root, n);
			size++;
		}
	}



	void update(T e) {
		RealHeap *h = lookup[e];

		if (h.parent == null)
			return;

		if (comp(h.parent.elem, h.elem)) {
			if (h.next == h) {
				h.parent.subheap = null;
			} else {
				if (h.parent.subheap == h)
					h.parent.subheap = h.next;

				h.prev.next = h.next;
				h.next.prev = h.prev;
				h.next = h;
				h.prev = h;
			}

			h.parent = null;
			root = merge(root, h);
			return;
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
		assert(me.next == me && me.prev == me);
		assert(other.next == other && other.prev == other);

		if (comp(me.elem, other.elem)) {
			insertSubheap(other, me);
			return other;
		} else {
			insertSubheap(me, other);
			return me;
		}
	}



	private RealHeap* mergePairs() {
		RealHeap*[] tmp;
		RealHeap* ha, hb, res;

		if (empty)
			return null;

		if (root.subheap == null)
			return null;

		while ((ha = removeSubheap(root)) != null) {
			hb = removeSubheap(root);
			tmp ~= merge(ha, hb);
		}

		foreach (h; tmp)
			res = merge(res, h);

		return res;
	}



	private static void insertSubheap(RealHeap* parent, RealHeap* child) {
		/* Only unlinked child. */
		assert(child.next == child && child.prev == child);

		if (parent.subheap != null) {
			child.next = parent.subheap;
			child.prev = parent.subheap.prev;
			parent.subheap.prev.next = child;
			parent.subheap.prev = child;
		} else {
			parent.subheap = child;
		}

		child.parent = parent;
	}



	private static RealHeap* removeSubheap(RealHeap* parent) {
		RealHeap* child;
		if (parent.subheap == null)
			return null;

		child = parent.subheap;
		child.parent = null;

		/* Only child. */
		if (child.next == child) {
			assert(child.prev == child);
			parent.subheap = null;
			return child;
		}

		child.prev.next = child.next;
		child.next.prev = child.prev;
		parent.subheap = child.next;

		child.next = child.prev = child;

		return child;
	}



	private alias comp = binaryFun!less;

	private struct RealHeap {
		T elem;
		RealHeap* parent;
		RealHeap* next, prev;
		RealHeap* subheap;
	}

	size_t size;
	RealHeap* root;
	RealHeap*[T] lookup;
}
