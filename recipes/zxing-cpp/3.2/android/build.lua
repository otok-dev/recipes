-- The CMake project of the reader (with `writers`, the writer too): libZXing.a or libZXing.so and include/ZXing/; or,
-- with `jni`, as the library ZXing, libzxingcpp_android.so, the reader of the Android wrapper (with `writers`, the
-- recipe's writer too) from android/CMakeLists.txt of the recipe, which has no install rules: the library is copied
-- into the prefix.
function build(slice, options, deps)
    if options.jni then
        if slice.linkage ~= "dynamic" then
            error("jni builds a shared object, which Java loads: it needs linkage = \"dynamic\"")
        end
        otok.cmake{
            source = slice.recipe .. "/android",
            defines = {
                ZXING_SOURCE = slice.source,
                ZXING_WRITERS = options.writers and "NEW" or "OFF",
                -- the reader goes into the JNI library, which leaves a release build without the debug information
                -- of the NDK's C++ runtime, as the wrapper's AAR has it
                BUILD_SHARED_LIBS = false,
                CMAKE_SHARED_LINKER_FLAGS_RELEASE = slice.configuration == "release" and "-s" or "",
            },
            targets = { "zxingcpp_android" },
            install = false,
        }
        local p = slice.prefix
        otok.copy(slice.build .. "/libzxingcpp_android.so", p .. "/lib/libzxingcpp_android.so")
        otok.copy(slice.source .. "/wrappers/android/zxingcpp/src/main/java/zxingcpp/BarcodeReader.kt", p .. "/share/BarcodeReader.kt")
        local data = { ["BarcodeReader.kt"] = p .. "/share/BarcodeReader.kt" }
        if options.writers then
            otok.copy(slice.recipe .. "/android/BarcodeWriter.kt", p .. "/share/BarcodeWriter.kt")
            data["BarcodeWriter.kt"] = p .. "/share/BarcodeWriter.kt"
        end
        -- the library ZXing of the product, under the name Java loads; Java calls it: no headers
        otok.mkdir(p .. "/include")
        return {
            libraries = { ZXing = p .. "/lib/libzxingcpp_android.so" },
            headers = p .. "/include",
            data = data,
        }
    end
    -- the project of core/, as the wrappers build it: the top one adds, with the C API, the C wrapper's test
    -- program, for which it fetches stb; the writer's libzint is the submodule zint/ beside core/
    otok.cmake{
        source = slice.source .. "/core",
        defines = { ZXING_READERS = true, ZXING_WRITERS = options.writers and "NEW" or "OFF", ZXING_C_API = true },
    }
    local p = slice.prefix
    local library = p .. (slice.linkage == "static" and "/lib/libZXing.a" or "/lib/libZXing.so")
    return { libraries = { ZXing = library }, headers = p .. "/include" }
end
