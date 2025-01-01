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
    lib/lua/*.c
)
message(STATUS "Lua sources: ${LUA_SOURCES}")

add_library(Lua STATIC ${LUA_SOURCES})
set_target_properties(Lua PROPERTIES LINKER_LANGUAGE C)

# Create the dynamic libraries
add_library(SteakEngine SHARED ${SOURCES})


target_include_directories(SteakEngine PRIVATE ${CMAKE_SOURCE_DIR}/utils)
target_include_directories(SteakEngine PRIVATE ${CMAKE_SOURCE_DIR}/libs/lua)

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
