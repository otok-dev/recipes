# libzxingcpp_android.so as zxing-cpp's Android wrapper builds it (wrappers/android/zxingcpp/src/main/cpp/CMakeLists.txt
# of ZXING_SOURCE, the source of zxing-cpp), and with ZXING_WRITERS = NEW also the writer of the otok recipe
# (ZXingCppWriter.cpp, the native side of BarcodeWriter.kt): one library, so the app carries one copy of zxing-cpp.
# SPDX-License-Identifier: CC0-1.0
cmake_minimum_required(VERSION 3.16)
project(ZXingCppAndroid)

set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

set(ZXING_READERS ON)
if (NOT DEFINED ZXING_WRITERS)
    set(ZXING_WRITERS OFF)
endif()

set(ZXING_EXPERIMENTAL_API ON CACHE BOOL "Enable ZXing experimental API (hardcoded for this wrapper)")

add_subdirectory(${ZXING_SOURCE}/core ZXing EXCLUDE_FROM_ALL)

add_library(zxingcpp_android SHARED ${ZXING_SOURCE}/wrappers/android/zxingcpp/src/main/cpp/ZXingCpp.cpp)
if (ZXING_WRITERS STREQUAL "NEW")
    target_sources(zxingcpp_android PRIVATE ZXingCppWriter.cpp)
endif()

target_link_options(zxingcpp_android PRIVATE "-Wl,-z,max-page-size=16384")
target_link_libraries(zxingcpp_android PRIVATE ZXing::ZXing log jnigraphics)
