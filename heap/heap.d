module heap.heap;



interface Heap(T) {
	/* Return true if the heap is empty. */
	@property bool empty() const;

	/* Return the number of elements in the heap. */
	@property size_t length() const;

	/* Return the largest element in the heap. */
	@property T front() const;

	/* Insert a new element in the heap. */
	void insert(T e);

	/* Remove the front element in the heap. */
	void removeFront();

	/* Return the front element of the heap and remove it. */
	T removeAny();

	/* Make sure the heap structure is correct. */
	void rebuild();

	/* Move an element in the heap so that the heap structure still hold. */
	void update(T e);
}
