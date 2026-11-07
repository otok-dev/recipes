// BarcodeReader: the reader of zxing-cpp for Swift, over its C API (ZXingC.h, the module CZXing), from the otok recipe
// of zxing-cpp. The names follow zxingcpp.BarcodeReader of zxing-cpp's Android wrapper.
// SPDX-License-Identifier: CC0-1.0

import CZXing
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreVideo)
import CoreVideo
#endif

public struct BarcodeReadingError: Error, CustomStringConvertible {
    public let message: String
    public var description: String { "Failed to read barcode: \(message)" }
}

public final class BarcodeReader {
    // The barcode formats of zxing-cpp, with the values of its BarcodeFormat (BarcodeFormat.h).
    public enum Format: UInt32, CaseIterable, Sendable {
        case none           = 0x0000
        case all            = 0x2A2A
        case allReadable    = 0x722A
        case allCreatable   = 0x772A
        case allLinear      = 0x6C2A
        case allMatrix      = 0x6D2A
        case allGS1         = 0x472A
        case allRetail      = 0x522A
        case allIndustrial  = 0x492A
        case codabar        = 0x2046
        case code39         = 0x2041
        case code39Std      = 0x7341
        case code39Ext      = 0x6541
        case code32         = 0x3241
        case pzn            = 0x7041
        case code93         = 0x2047
        case code128        = 0x2043
        case itf            = 0x2049
        case itf14          = 0x3449
        case dataBar        = 0x2065
        case dataBarOmni    = 0x6F65
        case dataBarStk     = 0x7365
        case dataBarStkOmni = 0x4F65
        case dataBarLtd     = 0x6C65
        case dataBarExp     = 0x6565
        case dataBarExpStk  = 0x4565
        case eanUPC         = 0x2045
        case ean13          = 0x3145
        case ean8           = 0x3845
        case ean5           = 0x3545
        case ean2           = 0x3245
        case isbn           = 0x6945
        case upcA           = 0x6145
        case upcE           = 0x6545
        case telepen        = 0x2042
        case telepenAlpha   = 0x3042
        case telepenNumeric = 0x3142
        case otherBarcode   = 0x2058
        case dxFilmEdge     = 0x7858
        case pdf417         = 0x204C
        case compactPDF417  = 0x634C
        case microPDF417    = 0x6D4C
        case aztec          = 0x207A
        case aztecCode      = 0x637A
        case aztecRune      = 0x727A
        case qrCode         = 0x2051
        case qrCodeModel1   = 0x3151
        case qrCodeModel2   = 0x3251
        case microQRCode    = 0x6D51
        case rmqrCode       = 0x7251
        case dataMatrix     = 0x2064
        case maxiCode       = 0x2055

        var cValue: ZXing_BarcodeFormat { ZXing_BarcodeFormat(rawValue: numericCast(rawValue)) }
    }

    // the cases in the order of the C API's enums
    public enum ContentType: Int, Sendable { case text, binary, mixed, gs1, iso15434, unknownECI }
    public enum Binarizer: Int, Sendable { case localAverage, globalHistogram, fixedThreshold, boolCast }
    public enum EanAddOnSymbol: Int, Sendable { case ignore, read, require }
    public enum TextMode: Int, Sendable { case plain, eci, hri, escaped, hex, hexECI }
    public enum ErrorType: Int, Sendable { case none, format, checksum, unsupported }

    public struct Options: Sendable {
        public var formats: Set<Format> = []  // empty: all
        public var tryHarder = false
        public var tryRotate = false
        public var tryInvert = false
        public var tryDownscale = false
        public var isPure = false
        public var binarizer = Binarizer.localAverage
        public var minLineCount = 2
        public var maxNumberOfSymbols = 0xff
        public var validateOptionalChecksum = false
        public var returnErrors = false
        public var eanAddOnSymbol = EanAddOnSymbol.ignore
        public var textMode = TextMode.hri

        public init() {}
    }

    public struct Error: Sendable {
        public let type: ErrorType
        public let message: String
    }

    public struct Point: Sendable, Equatable {
        public let x: Int
        public let y: Int
    }

    public struct Position: Sendable {
        public let topLeft: Point
        public let topRight: Point
        public let bottomRight: Point
        public let bottomLeft: Point
    }

    public struct Result: Sendable {
        public let format: Format
        public let bytes: Data
        public let text: String
        public let contentType: ContentType
        public let position: Position
        public let orientation: Int  // degrees
        public let symbologyIdentifier: String
        public let sequenceSize: Int
        public let sequenceIndex: Int
        public let sequenceId: String
        public let hasECI: Bool
        public let isInverted: Bool
        public let isMirrored: Bool
        public let lineCount: Int
        public let error: Error?  // with Options.returnErrors
    }

    public var options: Options

    public init(options: Options = Options()) {
        self.options = options
    }

    // A grayscale image: a byte a pixel, rows of rowStride bytes (0: width).
    public func read(luminance: UnsafeRawBufferPointer, width: Int, height: Int, rowStride: Int = 0) throws -> [Result] {
        guard let pixels = luminance.baseAddress, luminance.count >= (rowStride == 0 ? width : rowStride) * height else {
            throw BarcodeReadingError(message: "the buffer is smaller than the image")
        }
        return try read(pixels, width: width, height: height, format: ZXing_ImageFormat_Lum, rowStride: rowStride, pixStride: 1)
    }

    #if canImport(CoreGraphics)
    // An image of any pixel format, drawn into a grayscale bitmap first.
    public func read(_ image: CGImage) throws -> [Result] {
        let width = image.width, height = image.height
        var gray = [UInt8](repeating: 0, count: width * height)
        try gray.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
                throw BarcodeReadingError(message: "cannot draw the image")
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return try gray.withUnsafeBytes { try read(luminance: $0, width: width, height: height) }
    }
    #endif

    #if canImport(CoreVideo)
    // A frame of the camera: YpCbCr (its luma plane), BGRA, ARGB or one component of 8 bits.
    public func read(_ pixelBuffer: CVPixelBuffer) throws -> [Result] {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        let format: ZXing_ImageFormat, pixStride: Int
        switch CVPixelBufferGetPixelFormatType(pixelBuffer) {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
             kCVPixelFormatType_420YpCbCr8Planar, kCVPixelFormatType_420YpCbCr8PlanarFullRange:
            guard let luma = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
                throw BarcodeReadingError(message: "the pixel buffer has no pixels")
            }
            return try read(luma, width: CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
                            height: CVPixelBufferGetHeightOfPlane(pixelBuffer, 0), format: ZXing_ImageFormat_Lum,
                            rowStride: CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0), pixStride: 1)
        case kCVPixelFormatType_32BGRA: (format, pixStride) = (ZXing_ImageFormat_BGRA, 4)
        case kCVPixelFormatType_32ARGB: (format, pixStride) = (ZXing_ImageFormat_ARGB, 4)
        case kCVPixelFormatType_OneComponent8: (format, pixStride) = (ZXing_ImageFormat_Lum, 1)
        default:
            throw BarcodeReadingError(message: "unsupported pixel format of the pixel buffer")
        }
        guard let pixels = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw BarcodeReadingError(message: "the pixel buffer has no pixels")
        }
        return try read(pixels, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer),
                        format: format, rowStride: CVPixelBufferGetBytesPerRow(pixelBuffer), pixStride: pixStride)
    }
    #endif

    private func read(_ pixels: UnsafeRawPointer, width: Int, height: Int, format: ZXing_ImageFormat, rowStride: Int,
                      pixStride: Int) throws -> [Result] {
        guard let view = ZXing_ImageView_new(pixels.assumingMemoryBound(to: UInt8.self), CInt(width), CInt(height), format,
                                             CInt(rowStride), CInt(pixStride)) else {
            throw BarcodeReadingError(message: lastErrorMessage())
        }
        defer { ZXing_ImageView_delete(view) }
        let readerOptions = makeOptions()
        defer { ZXing_ReaderOptions_delete(readerOptions) }
        guard let barcodes = ZXing_ReadBarcodes(view, readerOptions) else {
            throw BarcodeReadingError(message: lastErrorMessage())
        }
        defer { ZXing_Barcodes_delete(barcodes) }
        return (0..<ZXing_Barcodes_size(barcodes)).compactMap { i in ZXing_Barcodes_at(barcodes, i).map(Result.init) }
    }

    private func makeOptions() -> OpaquePointer? {
        let o = ZXing_ReaderOptions_new()
        ZXing_ReaderOptions_setTryHarder(o, options.tryHarder)
        ZXing_ReaderOptions_setTryRotate(o, options.tryRotate)
        ZXing_ReaderOptions_setTryInvert(o, options.tryInvert)
        ZXing_ReaderOptions_setTryDownscale(o, options.tryDownscale)
        ZXing_ReaderOptions_setIsPure(o, options.isPure)
        ZXing_ReaderOptions_setBinarizer(o, ZXing_Binarizer(rawValue: numericCast(options.binarizer.rawValue)))
        ZXing_ReaderOptions_setMinLineCount(o, CInt(options.minLineCount))
        ZXing_ReaderOptions_setMaxNumberOfSymbols(o, CInt(options.maxNumberOfSymbols))
        ZXing_ReaderOptions_setValidateOptionalChecksum(o, options.validateOptionalChecksum)
        ZXing_ReaderOptions_setReturnErrors(o, options.returnErrors)
        ZXing_ReaderOptions_setEanAddOnSymbol(o, ZXing_EanAddOnSymbol(rawValue: numericCast(options.eanAddOnSymbol.rawValue)))
        ZXing_ReaderOptions_setTextMode(o, ZXing_TextMode(rawValue: numericCast(options.textMode.rawValue)))
        let formats = options.formats.map(\.cValue)
        ZXing_ReaderOptions_setFormats(o, formats, CInt(formats.count))
        return o
    }
}

extension BarcodeReader.Result {
    init(_ barcode: OpaquePointer) {
        format = BarcodeReader.Format(rawValue: numericCast(ZXing_Barcode_format(barcode).rawValue)) ?? .none
        var count: CInt = 0
        if let chars = ZXing_Barcode_bytes(barcode, &count) {
            bytes = Data(bytes: chars, count: Int(count))
            ZXing_free(chars)
        } else {
            bytes = Data()
        }
        text = string(taking: ZXing_Barcode_text(barcode))
        contentType = BarcodeReader.ContentType(rawValue: numericCast(ZXing_Barcode_contentType(barcode).rawValue)) ?? .unknownECI
        let p = ZXing_Barcode_position(barcode)
        position = BarcodeReader.Position(topLeft: .init(p.topLeft), topRight: .init(p.topRight),
                                          bottomRight: .init(p.bottomRight), bottomLeft: .init(p.bottomLeft))
        orientation = Int(ZXing_Barcode_orientation(barcode))
        symbologyIdentifier = string(taking: ZXing_Barcode_symbologyIdentifier(barcode))
        sequenceSize = Int(ZXing_Barcode_sequenceSize(barcode))
        sequenceIndex = Int(ZXing_Barcode_sequenceIndex(barcode))
        sequenceId = string(taking: ZXing_Barcode_sequenceId(barcode))
        hasECI = ZXing_Barcode_hasECI(barcode)
        isInverted = ZXing_Barcode_isInverted(barcode)
        isMirrored = ZXing_Barcode_isMirrored(barcode)
        lineCount = Int(ZXing_Barcode_lineCount(barcode))
        let errorType = BarcodeReader.ErrorType(rawValue: numericCast(ZXing_Barcode_errorType(barcode).rawValue)) ?? .none
        error = errorType == .none ? nil
            : BarcodeReader.Error(type: errorType, message: string(taking: ZXing_Barcode_errorMsg(barcode)))
    }
}

extension BarcodeReader.Point {
    init(_ p: ZXing_PointI) {
        self.init(x: Int(p.x), y: Int(p.y))
    }
}
