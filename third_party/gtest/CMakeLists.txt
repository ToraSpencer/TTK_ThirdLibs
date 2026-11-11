cmake_minimum_required(VERSION 3.15)

# Wrapper build for Google Test 1.5.0.
#
# The upstream CMakeLists.txt of 1.5.0 has no install rules and rewrites /MD
# to /MT, which is incompatible with the other libraries in this repository.
# This wrapper compiles the same sources with the default dynamic CRT and
# installs a uniform include/ + libs/ layout.

project(gtest_build CXX)

set(GTEST_SRC "${CMAKE_CURRENT_SOURCE_DIR}/gtest1.5.0" CACHE PATH "Google Test source directory")

if(NOT EXISTS "${GTEST_SRC}/src/gtest-all.cc")
  message(FATAL_ERROR "Google Test source not found: ${GTEST_SRC}")
endif()

set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

add_library(gtest STATIC "${GTEST_SRC}/src/gtest-all.cc")
target_include_directories(gtest PUBLIC "${GTEST_SRC}/include" PRIVATE "${GTEST_SRC}")

add_library(gtest_main STATIC "${GTEST_SRC}/src/gtest_main.cc")
target_link_libraries(gtest_main PUBLIC gtest)

install(TARGETS gtest gtest_main ARCHIVE DESTINATION libs)
install(DIRECTORY "${GTEST_SRC}/include/" DESTINATION include)
