cmake_minimum_required(VERSION 3.14)
project(SteakEngine VERSION 1.0 LANGUAGES OBJCXX CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Include CPM
include(cmake/CPM.cmake)

# Define the source files for each library
set(SOURCES
    src/main.mm
)

# cant use add_subdirectory cause lua doesnt use cmake
file(GLOB LUA_SOURCES
    lib/lua/lapi.c
    lib/lua/lauxlib.c
    lib/lua/lbaselib.c
    lib/lua/lcode.c
    lib/lua/ldblib.c
    lib/lua/ldebug.c
    lib/lua/ldo.c
    lib/lua/ldump.c
    lib/lua/lfunc.c
    lib/lua/lgc.c
    lib/lua/linit.c
    lib/lua/liolib.c
    lib/lua/llex.c
    lib/lua/lmathlib.c
    lib/lua/lmem.c
    lib/lua/loadlib.c
    lib/lua/lobject.c
    lib/lua/lopcodes.c
    lib/lua/loslib.c
    lib/lua/lparser.c
    lib/lua/lstate.c
    lib/lua/lstring.c
    lib/lua/lstrlib.c
    lib/lua/ltable.c
    lib/lua/ltablib.c
    lib/lua/ltm.c
    lib/lua/lundump.c
    lib/lua/lvm.c
    lib/lua/lzio.c
    lib/lua/lutf8lib.c  
    lib/lua/lctype.c  
    lib/lua/lcorolib.c 
)

add_library(Lua STATIC ${LUA_SOURCES})
set_target_properties(Lua PROPERTIES LINKER_LANGUAGE C)

# Create the dynamic libraries
add_library(SteakEngine SHARED ${SOURCES})


target_include_directories(SteakEngine PRIVATE ${CMAKE_SOURCE_DIR}/utils)
target_include_directories(SteakEngine PRIVATE ${CMAKE_SOURCE_DIR}/lib/lua)

# Set target properties for iOS
set_target_properties(SteakEngine PROPERTIES
    FRAMEWORK FALSE
    PLATFORM "iOS"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    OUTPUT_NAME "SteakEngine"
)


if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CMAKE_OSX_SYSROOT /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk)
    set(CMAKE_OSX_ARCHITECTURES arm64)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "16.0")

    # Add necessary frameworks for iOS
    target_link_libraries(SteakEngine
        "-framework UIKit"
        "-framework Foundation"
        Lua
    )
endif()
