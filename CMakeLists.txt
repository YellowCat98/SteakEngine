cmake_minimum_required(VERSION 3.14)
project(CharlieEngine VERSION 1.0 LANGUAGES OBJCXX CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Include CPM
include(cmake/CPM.cmake)

include_directories(${CMAKE_SOURCE_DIR}/utils)

# Define the source files for each library
set(INJECT_SOURCES
    inject/main.mm
)

set(LOADER_SOURCES
    loader/entry.mm
)

# Create the dynamic libraries
add_library(CharlieEngineInject SHARED ${INJECT_SOURCES})
add_library(CharlieEngineLoader SHARED ${LOADER_SOURCES})

target_include_directories(CharlieEngineInject PRIVATE ${CMAKE_SOURCE_DIR}/utils)
target_include_directories(CharlieEngineLoader PRIVATE ${CMAKE_SOURCE_DIR}/utils)

# Set target properties for iOS
set_target_properties(CharlieEngineInject PROPERTIES
    FRAMEWORK FALSE
    PLATFORM "iOS"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    OUTPUT_NAME "CharlieEngineInject"
)

set_target_properties(CharlieEngineLoader PROPERTIES
    FRAMEWORK FALSE
    PLATFORM "iOS"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    OUTPUT_NAME "CharlieEngineLoader"
)

# Ensure CMake knows we're targeting iOS
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CMAKE_OSX_SYSROOT /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk)
    set(CMAKE_OSX_ARCHITECTURES arm64)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "16.0")  # Set the minimum iOS version

    # Add necessary frameworks for iOS
    target_link_libraries(CharlieEngineInject
        "-framework UIKit"
        "-framework Foundation"
    )

    target_link_libraries(CharlieEngineLoader
        "-framework UIKit"
        "-framework Foundation"
    )
endif()
