cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 20)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(vulkan-engine)

option(VULKAN_BUILD_THIRDPARTY "Build thirdparty" ON)

if(WIN32)
    add_definitions(-DUNICODE)
    add_definitions(-D_UNICODE)
endif()


if(VULKAN_BUILD_THIRDPARTY)
    add_subdirectory(thirdparty)
endif()

find_package(Vulkan REQUIRED)

# 添加src目录
add_subdirectory(example)

