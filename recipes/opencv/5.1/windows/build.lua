-- OpenCV's CMake project as one library, opencv_world, with core, the modules of the option and the modules they need.
-- Everything OpenCV can find on the machine or download is given or switched off: the codecs of deps as the option asks,
-- zlib of deps, protobuf of deps for dnn (its messages generated anew by that protobuf's protoc), FFmpeg of deps for
-- videoio as the option ffmpeg asks, and none of IPP, TBB, Eigen, OpenCL, CUDA, GStreamer or the GUI toolkits.
-- Of OpenCV's own copies of libraries only HarfBuzz, the subset
-- it keeps for putText, which needs it since 5.0. What it installs: opencv_world510.lib (static, the static libraries of
-- that copy merged into it, so that the library is one file), or that import library with opencv_world510.dll (with a d
-- before the extension in debug).

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

    local defines = {
        BUILD_LIST = table.concat(list, ","), BUILD_opencv_world = true,
        BUILD_SHARED_LIBS = not static, BUILD_WITH_STATIC_CRT = false,
        BUILD_TESTS = false, BUILD_PERF_TESTS = false, BUILD_EXAMPLES = false, BUILD_DOCS = false, BUILD_opencv_apps = false,
        BUILD_JAVA = false, BUILD_OBJC = false, BUILD_opencv_python3 = false, BUILD_opencv_js = false, BUILD_PACKAGE = false,
        INSTALL_TESTS = false, INSTALL_C_EXAMPLES = false, INSTALL_PYTHON_EXAMPLES = false,
        OPENCV_GENERATE_SETUPVARS = false, OPENCV_GENERATE_PKGCONFIG = false, ENABLE_PRECOMPILED_HEADERS = false,
        ENABLE_CCACHE = false, OPENCV_ENABLE_NONFREE = false,
        OPENCV_INSTALL_BINARIES_PREFIX = "", OPENCV_LIB_INSTALL_PATH = "lib", OPENCV_LIB_ARCHIVE_INSTALL_PATH = "lib",
        OPENCV_3P_LIB_INSTALL_PATH = "lib/3rdparty", OPENCV_BIN_INSTALL_PATH = "bin", OPENCV_INCLUDE_INSTALL_PATH = "include",
        OPENCV_CONFIG_INSTALL_PATH = "lib/cmake/opencv5", OPENCV_OTHER_INSTALL_PATH = "share/opencv5",
        OPENCV_LICENSES_INSTALL_PATH = "share/licenses/opencv5",
        -- OpenCV's own copies of libraries: none
        BUILD_ZLIB = false, BUILD_TIFF = false, BUILD_OPENJPEG = false, BUILD_JASPER = false, BUILD_JPEG = false,
        BUILD_PNG = false, BUILD_WEBP = false, BUILD_HARFBUZZ = true, BUILD_TBB = false, BUILD_IPP_IW = false,
        BUILD_ITT = false, BUILD_CLAPACK = false, BUILD_PROTOBUF = false,
        -- what OpenCV would find on the machine or download
        WITH_IPP = false, WITH_ITT = false, WITH_TBB = false, WITH_OPENMP = false, WITH_EIGEN = false, WITH_LAPACK = false,
        WITH_CUDA = false, WITH_OPENCL = false, WITH_VULKAN = false, WITH_OPENVINO = false, WITH_ONNXRUNTIME = false,
        WITH_DIRECTX = false, WITH_DIRECTML = false, WITH_OPENCL_D3D11_NV = false, WITH_WEBNN = false, WITH_TIMVX = false,
        WITH_CANN = false, WITH_VA = false, WITH_VA_INTEL = false, WITH_MFX = false, WITH_NVCUVID = false,
        WITH_NVCUVENC = false, WITH_ARMPL = false, WITH_FASTCV = false, WITH_KLEIDICV = false, WITH_CAROTENE = false,
        WITH_FFMPEG = deps.ffmpeg ~= nil, VIDEOIO_ENABLE_PLUGINS = false,
        WITH_GSTREAMER = false, WITH_GTK = false, WITH_QT = false, WITH_WIN32UI = false,
        WITH_OPENGL = false, WITH_VTK = false, WITH_1394 = false, WITH_OPENNI = false, WITH_OPENNI2 = false,
        WITH_PVAPI = false, WITH_ARAVIS = false, WITH_XIMEA = false, WITH_UEYE = false, WITH_LIBREALSENSE = false,
        WITH_GPHOTO2 = false, WITH_OBSENSOR = false, WITH_GDAL = false, WITH_GDCM = false, WITH_OPENEXR = false,
        WITH_JASPER = false, WITH_OPENJPEG = codec.jpeg2000 == true, WITH_AVIF = false, WITH_JPEGXL = false, WITH_SPNG = false, WITH_HARFBUZZ = true,
        WITH_ZLIB_NG = false, WITH_UNIFONT = false, WITH_ITALICFONT = false,
        WITH_DSHOW = chosen.videoio == true, WITH_MSMF = chosen.videoio == true, WITH_MSMF_DXVA = false,
        WITH_PROTOBUF = chosen.dnn == true, WITH_FLATBUFFERS = chosen.dnn == true,
        WITH_JPEG = codec.jpeg == true, WITH_PNG = codec.png == true, WITH_TIFF = codec.tiff == true,
        WITH_WEBP = codec.webp == true,
    }
    local z = deps.zlib
    defines.ZLIB_USE_STATIC_LIBS = z.linkage == "static"
    defines.ZLIB_INCLUDE_DIR = z.include
    defines.ZLIB_LIBRARY = z.libraries.z
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
    local lib = otok.glob("lib/opencv_world*.lib", p)[1]
    -- OpenCV installs the static libraries of its copies of libraries beside it, which consumers would have to name
    local extra = static and otok.glob("lib/3rdparty/*.lib", p) or {}
    if #extra > 0 then
        local argv = { slice.toolchain.ar, "/NOLOGO", "/OUT:" .. lib, lib }
        for _, f in ipairs(extra) do argv[#argv + 1] = f end
        otok.run(argv)
    end
    local libraries
    if static then
        libraries = { opencv_world = lib }
    else
        libraries = { opencv_world = { link = lib, runtime = otok.glob("bin/opencv_world*.dll", p)[1] } }
    end
    return { libraries = libraries, headers = p .. "/include" }
end
