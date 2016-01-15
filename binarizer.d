module binarizer;

/* Needed for Color struct only */
import gui;


/* Binarize an image. */
interface Binarizer {
	/* Set the image to be binarized. */
	void setImage(const(Color[][]) image);

	/* Get the binarized image. */
	const(bool[][]) getBinaryImage();

	/* Return the binarization threshold determined by otsu's method. */
	@property ubyte otsuThreshold();

	/* Get the threshold. The default value is the one computed by Otsu's method */
	@property ubyte threshold();

	/* Set binarization the threshold. */
	@property ubyte threshold(ubyte value);
}




class OtsuBinarizer : Binarizer {
	import std.typecons : Rebindable, rebindable;

	void setImage(const(Color[][]) image) {
		srcimg = rebindable(image);
		binimg = null;
		hasOtsuThresh = false;
		hasThresh = false;
	}



	const(bool[][]) getBinaryImage() {
		ubyte t;

		if (binimg != null)
			return binimg;

		t = threshold();
		binimg.length = srcimg.length;

		foreach (y; 0 .. srcimg.length) {
			binimg[y].length = srcimg[y].length;

			foreach (x; 0 .. srcimg[y].length)
				binimg[y][x] = (greyScale(srcimg[y][x]) >= t);
		}

		return binimg;
	}



	@property ubyte otsuThreshold() {
		if (!hasOtsuThresh)
			computeOtsuThreshold();
		return otsuThresh;
	}



	@property ubyte threshold() {
		if (!hasThresh) {
			if (!hasOtsuThresh)
				computeOtsuThreshold();

			thresh = otsuThresh;
			hasThresh = true;
		}

		return thresh;
	}



	@property ubyte threshold(ubyte value) {
		if (value != thresh)
			binimg = null;

		thresh = value;
		hasThresh = true;
		return thresh;
	}



	void computeOtsuThreshold() {
		uint[256] histo;
		ulong total, itotal;
		ulong w0, w1, sum0, sum1;
		double m0, m1, between, maxVal = 0.0;
		ubyte maxIdx;

		foreach (y; 0 .. srcimg.length) {
			foreach (x; 0 .. srcimg[y].length)
				histo[greyScale(srcimg[y][x])]++;
		}

		foreach (ubyte i; 0 .. 256) {
			total += histo[i];
			itotal += i * histo[i];
		}

		foreach (ubyte i; 0 .. 256) {
			w0 += histo[i];
			if (w0 == 0)
				continue;

			w1 = total - w0;
			if (w1 == 0)
				break;

			sum0 += i * histo[i];
			sum1 = itotal - sum0;
			m0 = cast(double)sum0 / cast(double)w0;
			m1 = cast(double)sum1 / cast(double)w1;
			between = w0 * w1 * (m0 - m1) ^^ 2;

			if (between > maxVal) {
				maxIdx = i;
				maxVal = between;
			}
		}

		otsuThresh = cast(ubyte)(maxIdx + 1);
		hasOtsuThresh = true;
	}



	private static ubyte greyScale(Color c) {
		return (c.r + c.g + c.b) / 3;
	}


	private Rebindable!(const(Color[][])) srcimg;
	private bool[][] binimg;
	private bool hasThresh;
	private ubyte thresh;
	private bool hasOtsuThresh;
	private ubyte otsuThresh;
}
