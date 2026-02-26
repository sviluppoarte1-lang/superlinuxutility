cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

apply_standard_settings(${BINARY_NAME})
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
pkg_check_modules(GDK_PIXBUF REQUIRED gdk-pixbuf-2.0)
target_link_libraries(${BINARY_NAME} PRIVATE ${GDK_PIXBUF_LIBRARIES})
target_include_directories(${BINARY_NAME} PRIVATE ${GDK_PIXBUF_INCLUDE_DIRS})

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
