// zxingcpp.BarcodeWriter: the writer of zxing-cpp's new backend for Android, from the otok recipe of zxing-cpp; its
// native side (ZXingCppWriter.cpp) is in libzxingcpp_android.so with the reader of zxing-cpp's Android wrapper.
// The names follow the writer of zxing-cpp's Kotlin/Native wrapper (wrappers/kn).
// SPDX-License-Identifier: CC0-1.0

package zxingcpp

import android.graphics.Bitmap

public class BarcodeWritingException(message: String?) : Exception("Failed to write barcode: $message")

// What to create: the format, one of BarcodeReader.Format that zxing-cpp can create, and options of that format
// as zxing-cpp's CreatorOptions takes them: "key=value" pairs separated by commas, or a JSON object
// ("ecLevel=30%, gs1"; ecLevel, eci, gs1, readerInit, forceSquare, columns, rows, version, dataMask).
public data class CreatorOptions @JvmOverloads constructor(
	var format: BarcodeReader.Format,
	var options: String = "",
)

// How to draw it: scale, the size of a module in pixels (negative: the barcode fits abs(scale) pixels as close as
// possible); rotate, by 0, 90, 180 or 270 degrees; addHRT, the human readable text below a linear barcode;
// addQuietZones, the margins the format requires.
public data class WriterOptions @JvmOverloads constructor(
	var scale: Int = 1,
	var rotate: Int = 0,
	var addHRT: Boolean = false,
	var addQuietZones: Boolean = true,
)

public object BarcodeWriter {
	init {
		System.loadLibrary("zxingcpp_android")
	}

	// A barcode of the bytes, as an opaque ARGB_8888 bitmap (black modules on white).
	@JvmStatic
	@JvmOverloads
	public fun write(bytes: ByteArray, creator: CreatorOptions, writer: WriterOptions = WriterOptions()): Bitmap =
		writeBitmap(bytes, false, creator, writer)

	// A barcode of the text (encoded as UTF-8, with the ECI the format needs for it).
	@JvmStatic
	@JvmOverloads
	public fun write(text: String, creator: CreatorOptions, writer: WriterOptions = WriterOptions()): Bitmap =
		writeBitmap(text.toByteArray(Charsets.UTF_8), true, creator, writer)

	// The barcode of the bytes as an SVG document.
	@JvmStatic
	@JvmOverloads
	public fun writeSvg(bytes: ByteArray, creator: CreatorOptions, writer: WriterOptions = WriterOptions()): String =
		writeSvg(bytes, false, creator, writer)

	// The barcode of the text as an SVG document.
	@JvmStatic
	@JvmOverloads
	public fun writeSvg(text: String, creator: CreatorOptions, writer: WriterOptions = WriterOptions()): String =
		writeSvg(text.toByteArray(Charsets.UTF_8), true, creator, writer)

	private fun writeBitmap(contents: ByteArray, text: Boolean, creator: CreatorOptions, writer: WriterOptions): Bitmap =
		nativeWriteBitmap(contents, text, creator.format.value, creator.options,
			writer.scale, writer.rotate, writer.addHRT, writer.addQuietZones)

	private fun writeSvg(contents: ByteArray, text: Boolean, creator: CreatorOptions, writer: WriterOptions): String =
		String(nativeWriteSvg(contents, text, creator.format.value, creator.options,
			writer.scale, writer.rotate, writer.addHRT, writer.addQuietZones), Charsets.UTF_8)

	// the parameters as values: the native side reads no Kotlin objects; failures throw BarcodeWritingException
	private external fun nativeWriteBitmap(
		contents: ByteArray, text: Boolean, format: Int, options: String,
		scale: Int, rotate: Int, addHRT: Boolean, addQuietZones: Boolean,
	): Bitmap

	private external fun nativeWriteSvg(
		contents: ByteArray, text: Boolean, format: Int, options: String,
		scale: Int, rotate: Int, addHRT: Boolean, addQuietZones: Boolean,
	): ByteArray
}
