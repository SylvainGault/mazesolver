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

			if (n.subheap != null) {
				RealHeap* h = n.subheap;
				do {
					RealHeap* futureh = h.next;
					h.next = h;
					h.prev = h;
					pending ~= h;
					h = futureh;
				} while (h != n.subheap);

				n.subheap = null;
			}

			n.parent = null;
			lookup[n.elem] = n;
			newroot = merge(newroot, n);
			size++;
		}

		root = newroot;
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
			if (other.subheap != null) {
				me.next = other.subheap;
				me.prev = other.subheap.prev;
				other.subheap.prev.next = me;
				other.subheap.prev = me;
			} else {
				other.subheap = me;
			}

			me.parent = other;
			return other;
		} else {
			if (me.subheap != null) {
				other.next = me.subheap;
				other.prev = me.subheap.prev;
				me.subheap.prev.next = other;
				me.subheap.prev = other;
			} else {
				me.subheap = other;
			}

			other.parent = me;
			return me;
		}
	}



	private RealHeap* mergePairs() {
		RealHeap*[] tmp;
		RealHeap* ha, hb, res;

		if (empty)
			return null;

		if (root.subheap == null)
			return root;

		ha = root.subheap;
		do {
			hb = ha.next;

			ha.prev = ha;
			ha.next = ha;
			ha.parent = null;

			if (hb == root.subheap) {
				tmp ~= ha;
				break;
			} else {
				RealHeap* futureha = hb.next;
				hb.next = hb;
				hb.prev = hb;
				hb.parent = null;
				tmp ~= merge(ha, hb);
				ha = futureha;
			}
		} while (ha != root.subheap);

		foreach (h; tmp)
			res = merge(res, h);

		return res;
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
