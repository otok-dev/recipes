-- OpenCV's CMake project as one library, opencv_world, with core, the modules of the option and the modules they need.
-- Everything OpenCV can find on the machine or download is given or switched off: the codecs of deps as the option asks,
-- zlib of the SDK, protobuf of deps for dnn (its messages generated anew by that protobuf's protoc), KleidiCV from the
-- recipe's resource on arm64, AVFoundation for videoio where it captures, FFmpeg of deps for videoio as the option
-- ffmpeg asks, and none of IPP, TBB, Eigen, LAPACK, OpenCL, CUDA, GStreamer or the GUI toolkits.
-- Of OpenCV's own copies of libraries only HarfBuzz, the subset it keeps for putText, which needs it since 5.0, and on
-- arm64 macOS carotene. What it installs: libopencv_world.a (static, the static libraries of those copies and of KleidiCV
-- merged into it by libtool, so that the library is one file), or libopencv_world.dylib with its links.

-- static libraries added to another, so that consumers link one file: Xcode's libtool, beside its ar
local function merge_archives(slice, lib, extra)
    local libtool = slice.toolchain.ar:gsub("[^/]*$", "libtool")
    local argv = { libtool, "-static", "-no_warning_for_no_symbols", "-o", lib, lib }
    for _, f in ipairs(extra) do argv[#argv + 1] = f end
    otok.run(argv)
end

-- the platforms where OpenCV's AVFoundation backend builds: it needs AVCaptureSession (and visionOS lacks the presets and
-- the synchronous AVAsset calls it uses)
local capture = { macosx = true, catalyst = true, ios = true, iossim = true }
-- the UI framework of the image conversions of imgcodecs (UIImage, NSImage); watchOS has neither
local kit = { macosx = "AppKit", catalyst = "UIKit", ios = "UIKit", iossim = "UIKit", tvos = "UIKit", tvossim = "UIKit",
              xros = "UIKit", xrossim = "UIKit" }

-- FFmpeg of deps as the backend of videoio, in place of OpenCV's search for it (pkg-config, or on Windows a prebuilt
-- DLL it downloads): its headers and libraries given to OpenCV's target of it. A dynamic opencv_world links FFmpeg's
-- libraries, which must then be dynamic too: the static ones would need their own dependencies (dav1d), which this
-- recipe does not see.
local function use_ffmpeg(slice, chosen, ffmpeg)
    if not chosen.videoio then error("the option ffmpeg needs videoio in the option modules") end
    if ffmpeg.linkage == "static" and slice.linkage == "dynamic" then
        error("a dynamic opencv needs a dynamic ffmpeg: choose linkage = \"dynamic\" for ffmpeg")
    end
    local function cmake_path(p) return (p:gsub("\\", "/")) end
    local libs = {}
    for _, name in ipairs({ "avformat", "avcodec", "swscale", "avutil" }) do
        libs[#libs + 1] = "\"" .. cmake_path(ffmpeg.libraries[name]) .. "\""
    end
    otok.write(slice.source .. "/modules/videoio/cmake/detect_ffmpeg.cmake", table.concat({
        "set(HAVE_FFMPEG TRUE)",
        "set(libs " .. table.concat(libs, " ") .. ")",
        "ocv_add_external_target(ffmpeg \"" .. cmake_path(ffmpeg.include) .. "\" \"${libs}\" \"HAVE_FFMPEG\")", "" }, "\n"))
end

function build(slice, options, deps)
    local static = slice.linkage == "static"
    local chosen, codec = {}, {}
    for _, m in ipairs(options.modules) do chosen[m] = true end
    for _, c in ipairs(options.codecs) do codec[c] = true end
    local list = { "core", "world" }
    for _, m in ipairs(options.modules) do list[#list + 1] = m end
    local kleidicv = slice.resources.kleidicv
    -- OpenCV adds the directories of what it links to the LC_RPATH of its libraries, which would name otok's cache
    local layout = slice.source .. "/cmake/OpenCVInstallLayout.cmake"
    local text, n = otok.read(layout):gsub("set%(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE%)", "set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)")
    if n ~= 1 then error("no CMAKE_INSTALL_RPATH_USE_LINK_PATH in " .. layout) end
    otok.write(layout, text)
    -- the frameworks of the AVFoundation backend, those its code uses, on every platform (OpenCV names AVFoundation and
    -- QuartzCore for iOS, and Cocoa, which Mac Catalyst lacks, for the rest)
    otok.write(slice.source .. "/modules/videoio/cmake/detect_avfoundation.cmake", table.concat({
        "set(HAVE_AVFOUNDATION TRUE)",
        "set(libs \"-framework AVFoundation\" \"-framework CoreMedia\" \"-framework CoreVideo\" \"-framework CoreGraphics\" \"-framework Foundation\")",
        "ocv_add_external_target(avfoundation \"\" \"${libs}\" \"HAVE_AVFOUNDATION\")", "" }, "\n"))

    -- OpenCV takes AppKit's conversions for every Apple platform but iOS and visionOS: chosen by the platform instead
    local codecs_cmake = slice.source .. "/modules/imgcodecs/CMakeLists.txt"
    local codecs_text = otok.read(codecs_cmake)
    local function choose(condition, wanted)
        local n
        codecs_text, n = codecs_text:gsub(condition, kit[slice.platform] == wanted and "if(TRUE)" or "if(FALSE)")
        if n ~= 1 then error("no '" .. condition .. "' in " .. codecs_cmake) end
    end
    choose("if%(IOS OR XROS%)", "UIKit")
    choose("if%(APPLE AND %(NOT IOS%) AND %(NOT XROS%)%)", "AppKit")
    otok.write(codecs_cmake, codecs_text)

    local defines = {
        BUILD_LIST = table.concat(list, ","), BUILD_opencv_world = true,
        -- a dynamic library finds those of its dependencies beside it (OpenCV would name the prefix it is installed in)
        CMAKE_INSTALL_RPATH = "@loader_path",
        BUILD_SHARED_LIBS = not static,
        BUILD_TESTS = false, BUILD_PERF_TESTS = false, BUILD_EXAMPLES = false, BUILD_DOCS = false, BUILD_opencv_apps = false,
        BUILD_JAVA = false, BUILD_OBJC = false, BUILD_opencv_python3 = false, BUILD_opencv_js = false, BUILD_PACKAGE = false,
        INSTALL_TESTS = false, INSTALL_C_EXAMPLES = false, INSTALL_PYTHON_EXAMPLES = false,
        OPENCV_GENERATE_SETUPVARS = false, OPENCV_GENERATE_PKGCONFIG = false, ENABLE_PRECOMPILED_HEADERS = false,
        ENABLE_CCACHE = false, OPENCV_ENABLE_NONFREE = false, INSTALL_TO_MANGLED_PATHS = false,
        OPENCV_LIB_INSTALL_PATH = "lib", OPENCV_LIB_ARCHIVE_INSTALL_PATH = "lib", OPENCV_3P_LIB_INSTALL_PATH = "lib/3rdparty",
        OPENCV_BIN_INSTALL_PATH = "bin", OPENCV_INCLUDE_INSTALL_PATH = "include",
        OPENCV_CONFIG_INSTALL_PATH = "lib/cmake/opencv5", OPENCV_OTHER_INSTALL_PATH = "share/opencv5",
        OPENCV_LICENSES_INSTALL_PATH = "share/licenses/opencv5",
        -- OpenCV's own copies of libraries: HarfBuzz only
        BUILD_ZLIB = false, BUILD_TIFF = false, BUILD_OPENJPEG = false, BUILD_JASPER = false, BUILD_JPEG = false,
        BUILD_PNG = false, BUILD_WEBP = false, BUILD_HARFBUZZ = true, BUILD_TBB = false, BUILD_IPP_IW = false,
        BUILD_ITT = false, BUILD_CLAPACK = false, BUILD_PROTOBUF = false,
        -- what OpenCV would find on the machine or download
        WITH_IPP = false, WITH_ITT = false, WITH_TBB = false, WITH_OPENMP = false, WITH_EIGEN = false, WITH_LAPACK = false,
        WITH_CUDA = false, WITH_OPENCL = false, WITH_VULKAN = false, WITH_OPENVINO = false, WITH_ONNXRUNTIME = false,
        WITH_WEBNN = false, WITH_TIMVX = false, WITH_CANN = false, WITH_VA = false, WITH_VA_INTEL = false, WITH_MFX = false,
        WITH_NVCUVID = false, WITH_NVCUVENC = false, WITH_ARMPL = false, WITH_FASTCV = false,
        WITH_KLEIDICV = kleidicv ~= nil, KLEIDICV_SOURCE_PATH = kleidicv,
        WITH_FFMPEG = deps.ffmpeg ~= nil, VIDEOIO_ENABLE_PLUGINS = false,
        WITH_GSTREAMER = false, WITH_GTK = false, WITH_QT = false, WITH_WAYLAND = false,
        WITH_FRAMEBUFFER = false, WITH_OPENGL = false, WITH_VTK = false, WITH_1394 = false, WITH_OPENNI = false,
        WITH_OPENNI2 = false, WITH_PVAPI = false, WITH_ARAVIS = false, WITH_XIMEA = false, WITH_UEYE = false,
        WITH_LIBREALSENSE = false, WITH_COCOA = false, WITH_GPHOTO2 = false, WITH_OBSENSOR = false, WITH_GDAL = false, WITH_GDCM = false,
        WITH_OPENEXR = false, WITH_JASPER = false, WITH_OPENJPEG = codec.jpeg2000 == true, WITH_AVIF = codec.avif == true, WITH_JPEGXL = codec.jpegxl == true,
        WITH_SPNG = false, WITH_HARFBUZZ = true, WITH_ZLIB_NG = false, WITH_UNIFONT = false, WITH_ITALICFONT = false,
        WITH_V4L = false, WITH_CAP_IOS = false, WITH_AVFOUNDATION = chosen.videoio == true and capture[slice.platform] == true,
        WITH_PROTOBUF = chosen.dnn == true, WITH_FLATBUFFERS = chosen.dnn == true,
        WITH_JPEG = codec.jpeg == true, WITH_PNG = codec.png == true, WITH_TIFF = codec.tiff == true,
        WITH_WEBP = codec.webp == true,
    }
    defines.ZLIB_INCLUDE_DIR = slice.apple.sdk_path .. "/usr/include"
    defines.ZLIB_LIBRARY = slice.apple.sdk_path .. "/usr/lib/libz.tbd"
    if codec.jpeg then
        local jpeg = deps["libjpeg-turbo"]
        defines.JPEG_INCLUDE_DIR = jpeg.include
        defines.JPEG_LIBRARY = jpeg.libraries.jpeg
    end
    if codec.png then
        local png = deps.libpng
        defines.PNG_PNG_INCLUDE_DIR = png.include
        defines.PNG_LIBRARY = png.libraries.png16
    end
    if codec.tiff then
        local tiff = deps.libtiff
        defines.TIFF_INCLUDE_DIR = tiff.include
        defines.TIFF_LIBRARY = tiff.libraries.tiff
    end
    if codec.avif then
        -- libavif's headers and library in place of OpenCV's search (its CMake package, installed with a dynamic libavif
        -- only, is left aside); a static libavif needs dav1d beside it in a dynamic opencv_world
        local avif = deps.libavif
        defines.CMAKE_DISABLE_FIND_PACKAGE_libavif = true
        defines.AVIF_INCLUDE_DIR = avif.include
        local libs = { avif.libraries.avif }
        if avif.linkage == "static" then libs[2] = deps.dav1d.libraries.dav1d end
        defines.AVIF_LIBRARY = table.concat(libs, ";")
    end
    if codec.jpegxl then
        -- libjxl of deps in place of OpenCV's search for it (pkg-config and the libraries it would find anywhere): its
        -- headers and libraries, a static libjxl with Brotli and Highway, which it links
        local jxl = deps.libjxl
        local function cmake_path(p) return (p:gsub("\\", "/")) end
        local libs = { jxl.libraries.jxl, jxl.libraries.jxl_threads, jxl.libraries.jxl_cms }
        if jxl.linkage == "static" then
            for _, name in ipairs{ "brotlienc", "brotlidec", "brotlicommon" } do libs[#libs + 1] = deps.brotli.libraries[name] end
            libs[#libs + 1] = deps.highway.libraries.hwy
        end
        for i, lib in ipairs(libs) do libs[i] = "\"" .. cmake_path(lib) .. "\"" end
        otok.write(slice.source .. "/cmake/OpenCVFindJPEGXL.cmake", table.concat({
            "set(JPEGXL_FOUND TRUE)",
            "set(JPEGXL_VERSION \"" .. jxl.version .. "\")",
            "set(JPEGXL_INCLUDE_DIRS \"" .. cmake_path(jxl.include) .. "\")",
            "set(JPEGXL_LIBRARIES " .. table.concat(libs, " ") .. ")",
            "set(JPEGXL_LIBRARY ${JPEGXL_LIBRARIES})", "" }, "\n"))
    end
    if codec.jpeg2000 then
        -- OpenJPEG's own CMake package, which OpenCV reads (without it, OpenCV would build its copy)
        defines.OpenJPEG_DIR = deps.openjpeg.prefix .. "/lib/cmake/openjpeg-2.5"
    end
    if codec.webp then
        local webp = deps.libwebp
        defines.WEBP_INCLUDE_DIR = webp.include
        defines.WEBP_LIBRARY = webp.libraries.webp
        defines.WEBP_MUX_LIBRARY = webp.libraries.webpmux
        defines.WEBP_DEMUX_LIBRARY = webp.libraries.webpdemux
    end
    if chosen.dnn then
        defines.PROTOBUF_UPDATE_FILES = true
        defines.Protobuf_PROTOC_EXECUTABLE = slice.toolchains.protoc
        defines.protobuf_DIR = deps.protobuf.prefix .. "/lib/cmake/protobuf"
        defines.absl_DIR = deps.abseil.prefix .. "/lib/cmake/absl"
        defines.utf8_range_DIR = deps.protobuf.prefix .. "/lib/cmake/utf8_range"
    end
    if deps.ffmpeg then use_ffmpeg(slice, chosen, deps.ffmpeg) end
    otok.cmake{ defines = defines }

    local p = slice.prefix
    if static then
        local lib = p .. "/lib/libopencv_world.a"
        local extra = otok.glob("lib/3rdparty/*.a", p)
        if #extra > 0 then merge_archives(slice, lib, extra) end
        return { libraries = { opencv_world = lib }, headers = p .. "/include" }
    end
    return { libraries = { opencv_world = p .. "/lib/libopencv_world.dylib" }, headers = p .. "/include" }
end
