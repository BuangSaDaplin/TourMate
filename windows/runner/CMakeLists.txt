cmake_minimum_required(VERSION 3.10)

project(Runner)

set(CMAKE_CXX_STANDARD 17)

# Add source files
add_executable(Runner
  main.cpp
  flutter_window.cpp
  win32_window.cpp
  resource.h
  Runner.rc
)

# Flutter
target_link_libraries(Runner PRIVATE flutter)

# Plugins
target_link_libraries(Runner PRIVATE flutter_plugins)

# Resources
target_link_libraries(Runner PRIVATE flutter_windows)

# Compile definitions
target_compile_definitions(Runner PRIVATE NOMINMAX UNICODE _UNICODE)

# Include directories
target_include_directories(Runner PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${FLUTTER_ROOT}/packages/flutter_windows/cpp/public
)

# Post-build commands
add_custom_command(
    TARGET Runner POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${FLUTTER_ROOT}/packages/flutter_windows/flutter/flutter_windows.dll"
        "$<TARGET_FILE_DIR:Runner>/"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${FLUTTER_ROOT}/packages/flutter_windows/flutter/flutter_windows.dll.pdb"
        "$<TARGET_FILE_DIR:Runner>/"
)
