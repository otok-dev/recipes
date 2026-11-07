// BarcodeWriter: the writer of zxing-cpp's new backend for Swift, over its C API (ZXingC.h, the module CZXing), from
// the otok recipe of zxing-cpp. The names follow zxingcpp.BarcodeWriter of the recipe's Android writer (android/) and
// the writer of zxing-cpp's Kotlin/Native wrapper.
// SPDX-License-Identifier: CC0-1.0

import CZXing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

// only with the option writers: the C API of a library without the writer fails every call
#if OTOK_OPTION_WRITERS

public struct BarcodeWritingError: Error, CustomStringConvertible {
    public let message: String
    public var description: String { "Failed to write barcode: \(message)" }
}

// What to create: the format, one that zxing-cpp can create, and options of that format as zxing-cpp's CreatorOptions
// takes them: "key=value" pairs separated by commas, or a JSON object ("ecLevel=30%, gs1"; ecLevel, eci, gs1,
// readerInit, forceSquare, columns, rows, version, dataMask).
public struct CreatorOptions: Sendable {
    public var format: BarcodeReader.Format
    public var options: String

    public init(format: BarcodeReader.Format, options: String = "") {
        self.format = format
        self.options = options
    }
}

// How to draw it: scale, the size of a module in pixels (negative: the barcode fits abs(scale) pixels as close as
// possible); rotate, by 0, 90, 180 or 270 degrees; addHRT, the human readable text below a linear barcode;
// addQuietZones, the margins the format requires.
public struct WriterOptions: Sendable {
    public var scale: Int
    public var rotate: Int
    public var addHRT: Bool
    public var addQuietZones: Bool

    public init(scale: Int = 1, rotate: Int = 0, addHRT: Bool = false, addQuietZones: Bool = true) {
        self.scale = scale
        self.rotate = rotate
        self.addHRT = addHRT
        self.addQuietZones = addQuietZones
    }
}

public enum BarcodeWriter {
    #if canImport(CoreGraphics)
    // A barcode of the bytes, as a grayscale image (black modules on white).
    public static func write(_ bytes: Data, creator: CreatorOptions, writer: WriterOptions = WriterOptions()) throws -> CGImage {
        try withBarcode(bytes, text: false, creator) { try image(of: $0, writer) }
    }

    // A barcode of the text (encoded as UTF-8, with the ECI the format needs for it).
    public static func write(_ text: String, creator: CreatorOptions, writer: WriterOptions = WriterOptions()) throws -> CGImage {
        try withBarcode(Data(text.utf8), text: true, creator) { try image(of: $0, writer) }
    }
    #endif

    // The barcode of the bytes as an SVG document.
    public static func writeSVG(_ bytes: Data, creator: CreatorOptions, writer: WriterOptions = WriterOptions()) throws -> String {
        try withBarcode(bytes, text: false, creator) { try svg(of: $0, writer) }
    }

    // The barcode of the text as an SVG document.
    public static func writeSVG(_ text: String, creator: CreatorOptions, writer: WriterOptions = WriterOptions()) throws -> String {
        try withBarcode(Data(text.utf8), text: true, creator) { try svg(of: $0, writer) }
    }

    private static func withBarcode<R>(_ contents: Data, text: Bool, _ creator: CreatorOptions,
                                       _ body: (OpaquePointer) throws -> R) throws -> R {
        let creatorOptions = ZXing_CreatorOptions_new(creator.format.cValue)
        defer { ZXing_CreatorOptions_delete(creatorOptions) }
        ZXing_CreatorOptions_setOptions(creatorOptions, creator.options)
        let barcode = contents.withUnsafeBytes { buffer in
            text ? ZXing_CreateBarcodeFromText(buffer.baseAddress?.assumingMemoryBound(to: CChar.self), CInt(buffer.count), creatorOptions)
                 : ZXing_CreateBarcodeFromBytes(buffer.baseAddress, CInt(buffer.count), creatorOptions)
        }
        guard let barcode else { throw BarcodeWritingError(message: lastErrorMessage()) }
        defer { ZXing_Barcode_delete(barcode) }
        return try body(barcode)
    }

    private static func withWriterOptions<R>(_ writer: WriterOptions, _ body: (OpaquePointer?) throws -> R) rethrows -> R {
        let o = ZXing_WriterOptions_new()
        defer { ZXing_WriterOptions_delete(o) }
        ZXing_WriterOptions_setScale(o, CInt(writer.scale))
        ZXing_WriterOptions_setRotate(o, CInt(writer.rotate))
        ZXing_WriterOptions_setAddHRT(o, writer.addHRT)
        ZXing_WriterOptions_setAddQuietZones(o, writer.addQuietZones)
        return try body(o)
    }

    #if canImport(CoreGraphics)
    private static func image(of barcode: OpaquePointer, _ writer: WriterOptions) throws -> CGImage {
        guard let image = withWriterOptions(writer, { ZXing_WriteBarcodeToImage(barcode, $0) }) else {
            throw BarcodeWritingError(message: lastErrorMessage())
        }
        defer { ZXing_Image_delete(image) }
        let width = Int(ZXing_Image_width(image)), height = Int(ZXing_Image_height(image))
        guard ZXing_Image_format(image) == ZXing_ImageFormat_Lum, let pixels = ZXing_Image_data(image) else {
            throw BarcodeWritingError(message: "the writer made an image that is not grayscale")
        }
        // a copy: the image of the C API is freed here
        guard let provider = CGDataProvider(data: Data(bytes: pixels, count: width * height) as CFData),
              let result = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width,
                                   space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                                   provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            throw BarcodeWritingError(message: "cannot make the image")
        }
        return result
    }
    #endif

    private static func svg(of barcode: OpaquePointer, _ writer: WriterOptions) throws -> String {
        guard let chars = withWriterOptions(writer, { ZXing_WriteBarcodeToSVG(barcode, $0) }) else {
            throw BarcodeWritingError(message: lastErrorMessage())
        }
        return string(taking: chars)
    }
}

#endif
