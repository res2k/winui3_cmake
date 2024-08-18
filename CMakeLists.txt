cmake_minimum_required (VERSION 3.24...3.25)
project ("winui3_cmake")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(nuget)
nuget_install()

add_subdirectory(samples)
