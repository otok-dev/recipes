# The detours library of the otok recipe: the objects of Detours' src/Makefile (OBJS), static. The disassemblers of
# the other architectures (disol*.cpp) are compiled as the Makefile compiles them, for DetourCopyInstruction's offline
# use. DETOUR_DEBUG is not defined: a debug build of the Makefile traces to the standard output of the process.
cmake_minimum_required(VERSION 3.20)
project(detours VERSION 4.0.1 LANGUAGES CXX)

add_library(detours STATIC
    src/detours.cpp src/modules.cpp src/disasm.cpp src/image.cpp src/creatwth.cpp
    src/disolx86.cpp src/disolx64.cpp src/disolia64.cpp src/disolarm.cpp src/disolarm64.cpp)
# as the Makefile defines them
target_compile_definitions(detours PRIVATE WIN32_LEAN_AND_MEAN _WIN32_WINNT=0x501)

install(TARGETS detours ARCHIVE DESTINATION lib)
install(FILES src/detours.h src/detver.h DESTINATION include/detours)
