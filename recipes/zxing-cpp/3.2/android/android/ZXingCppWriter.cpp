// The native side of zxingcpp.BarcodeWriter (BarcodeWriter.kt): the writer of zxing-cpp's new backend
// (CreateBarcode.h, WriteBarcode.h) for Android, built by the otok recipe of zxing-cpp into libzxingcpp_android.so
// beside the reader of zxing-cpp's Android wrapper (CMakeLists.txt).
// SPDX-License-Identifier: CC0-1.0

#include "CreateBarcode.h"
#include "WriteBarcode.h"

#include <android/bitmap.h>
#include <jni.h>

#include <cstdint>
#include <exception>
#include <stdexcept>
#include <string>

using namespace ZXing;

namespace {

// zxingcpp.BarcodeWritingException with the message, unless a Java exception is already pending
void throw_writing_exception(JNIEnv* env, char const* message)
{
    if (env->ExceptionCheck()) return;
    if (jclass const c = env->FindClass("zxingcpp/BarcodeWritingException")) env->ThrowNew(c, message);
}

// a Java exception thrown by a JNI call below ends the call through this, the C++ one is turned into a Java one
struct java_exception
{
};

void check(JNIEnv* env)
{
    if (env->ExceptionCheck()) throw java_exception{};
}

std::string string_of(JNIEnv* env, jstring s)
{
    if (s == nullptr) return {};
    // the options are ASCII ("ecLevel=30%, gs1"), in which modified UTF-8 is UTF-8
    char const* const chars = env->GetStringUTFChars(s, nullptr);
    check(env);
    std::string r{chars};
    env->ReleaseStringUTFChars(s, chars);
    return r;
}

// contents: the bytes to encode, or with text its UTF-8 (Kotlin encodes it: JNI strings are modified UTF-8)
Barcode create(JNIEnv* env, jbyteArray contents, jboolean text, jint format, jstring options)
{
    CreatorOptions creator{static_cast<BarcodeFormat>(format), string_of(env, options)};
    jsize const size = env->GetArrayLength(contents);
    std::string data(static_cast<std::size_t>(size), '\0');
    env->GetByteArrayRegion(contents, 0, size, reinterpret_cast<jbyte*>(data.data()));
    check(env);
    return text ? CreateBarcodeFromText(data, creator) : CreateBarcodeFromBytes(data.data(), size, creator);
}

WriterOptions writer_options(jint scale, jint rotate, jboolean add_hrt, jboolean add_quiet_zones)
{
    return WriterOptions().scale(scale).rotate(rotate).addHRT(add_hrt).addQuietZones(add_quiet_zones);
}

// an ARGB_8888 bitmap of the image the writer made, opaque: a gray level per pixel
jobject bitmap_of(JNIEnv* env, Image const& image)
{
    if (image.format() != ImageFormat::Lum) throw std::runtime_error("the writer made an image that is not grayscale");
    jclass const config_class = env->FindClass("android/graphics/Bitmap$Config");
    check(env);
    jfieldID const argb = env->GetStaticFieldID(config_class, "ARGB_8888", "Landroid/graphics/Bitmap$Config;");
    check(env);
    jobject const config = env->GetStaticObjectField(config_class, argb);
    jclass const bitmap_class = env->FindClass("android/graphics/Bitmap");
    check(env);
    jmethodID const create_bitmap =
        env->GetStaticMethodID(bitmap_class, "createBitmap", "(IILandroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;");
    check(env);
    jobject const bitmap = env->CallStaticObjectMethod(bitmap_class, create_bitmap, image.width(), image.height(), config);
    check(env);

    AndroidBitmapInfo info;
    void* pixels = nullptr;
    if (AndroidBitmap_getInfo(env, bitmap, &info) != ANDROID_BITMAP_RESULT_SUCCESS
        || AndroidBitmap_lockPixels(env, bitmap, &pixels) != ANDROID_BITMAP_RESULT_SUCCESS) {
        throw std::runtime_error("cannot write the pixels of the bitmap");
    }
    for (int y = 0; y < image.height(); ++y) {
        auto* const row = reinterpret_cast<std::uint32_t*>(static_cast<std::uint8_t*>(pixels) + y * info.stride);
        for (int x = 0; x < image.width(); ++x) {
            std::uint32_t const gray = *image.data(x, y);
            row[x] = 0xff000000u | gray << 16 | gray << 8 | gray;  // the byte order of R, G and B does not matter
        }
    }
    AndroidBitmap_unlockPixels(env, bitmap);
    return bitmap;
}

template <typename F>
auto guarded(JNIEnv* env, F f) -> decltype(f())
{
    try {
        return f();
    } catch (java_exception const&) {
    } catch (std::exception const& e) {
        throw_writing_exception(env, e.what());
    } catch (...) {
        throw_writing_exception(env, "unknown error");
    }
    return nullptr;
}

} // namespace

extern "C" JNIEXPORT jobject JNICALL Java_zxingcpp_BarcodeWriter_nativeWriteBitmap(JNIEnv* env, jobject, jbyteArray contents,
    jboolean text, jint format, jstring options, jint scale, jint rotate, jboolean add_hrt, jboolean add_quiet_zones)
{
    return guarded(env, [&]() -> jobject {
        Barcode const barcode = create(env, contents, text, format, options);
        return bitmap_of(env, WriteBarcodeToImage(barcode, writer_options(scale, rotate, add_hrt, add_quiet_zones)));
    });
}

// the UTF-8 of the SVG, which Kotlin decodes (the human readable text may be any Unicode)
extern "C" JNIEXPORT jbyteArray JNICALL Java_zxingcpp_BarcodeWriter_nativeWriteSvg(JNIEnv* env, jobject, jbyteArray contents,
    jboolean text, jint format, jstring options, jint scale, jint rotate, jboolean add_hrt, jboolean add_quiet_zones)
{
    return guarded(env, [&]() -> jbyteArray {
        Barcode const barcode = create(env, contents, text, format, options);
        std::string const svg = WriteBarcodeToSVG(barcode, writer_options(scale, rotate, add_hrt, add_quiet_zones));
        jbyteArray const bytes = env->NewByteArray(static_cast<jsize>(svg.size()));
        check(env);
        env->SetByteArrayRegion(bytes, 0, static_cast<jsize>(svg.size()), reinterpret_cast<jbyte const*>(svg.data()));
        check(env);
        return bytes;
    });
}
