cmake_minimum_required(VERSION 3.15)

# Wrapper build for Dear ImGui.
#
# Upstream ImGui ships no CMakeLists.txt and no install rules: it is a
# source-only library meant to be compiled into the consuming application.
# This wrapper compiles the core plus the Win32 + DirectX 11 backends into a
# static library and installs a uniform include/ + libs/ layout, matching the
# other libraries in this repository.

project(imgui_build CXX)

set(IMGUI_SRC "${CMAKE_CURRENT_SOURCE_DIR}/imgui1.93.0" CACHE PATH "Dear ImGui source directory")

if(NOT EXISTS "${IMGUI_SRC}/imgui.h")
  message(FATAL_ERROR "Dear ImGui source not found: ${IMGUI_SRC}")
endif()

# Keep the dynamic CRT (/MD, /MDd) to match the other libraries in this repo.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

option(IMGUI_BUILD_DEMO "Compile imgui_demo.cpp into the static library" ON)

set(IMGUI_SOURCES
  "${IMGUI_SRC}/imgui.cpp"
  "${IMGUI_SRC}/imgui_draw.cpp"
  "${IMGUI_SRC}/imgui_tables.cpp"
  "${IMGUI_SRC}/imgui_widgets.cpp"
  "${IMGUI_SRC}/backends/imgui_impl_win32.cpp"
  "${IMGUI_SRC}/backends/imgui_impl_dx11.cpp"
)
if(IMGUI_BUILD_DEMO)
  list(APPEND IMGUI_SOURCES "${IMGUI_SRC}/imgui_demo.cpp")
endif()

add_library(imgui STATIC ${IMGUI_SOURCES})

target_include_directories(imgui PUBLIC
  "${IMGUI_SRC}"
  "${IMGUI_SRC}/backends"
)
# Avoid the min/max macros from <windows.h> leaking into the backends.
target_compile_definitions(imgui PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
set_target_properties(imgui PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
)

install(TARGETS imgui ARCHIVE DESTINATION libs)

install(FILES
  "${IMGUI_SRC}/imgui.h"
  "${IMGUI_SRC}/imgui_internal.h"
  "${IMGUI_SRC}/imconfig.h"
  "${IMGUI_SRC}/imstb_rectpack.h"
  "${IMGUI_SRC}/imstb_textedit.h"
  "${IMGUI_SRC}/imstb_truetype.h"
  DESTINATION include
)

install(FILES
  "${IMGUI_SRC}/backends/imgui_impl_win32.h"
  "${IMGUI_SRC}/backends/imgui_impl_dx11.h"
  DESTINATION include/backends
)
