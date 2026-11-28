// What BarcodeReader and BarcodeWriter share: the strings the C API of zxing-cpp gives away, its last error.
// From the otok recipe of zxing-cpp.
// SPDX-License-Identifier: CC0-1.0

import CZXing

// a string the C API returned, which the caller frees ("" for none)
func string(taking chars: UnsafeMutablePointer<CChar>?) -> String {
    guard let chars else { return "" }
    defer { ZXing_free(chars) }
    return String(cString: chars)
}

// the message of the C API's last failure on this thread
func lastErrorMessage() -> String {
    let message = string(taking: ZXing_LastErrorMsg())
    return message.isEmpty ? "unknown error" : message
}
