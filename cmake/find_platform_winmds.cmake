# Obtain list of UAP platform .winmds
include_guard()

include(require_arguments)
include(win10sdk_root)

# Obtain list of UAP platform .winmds
#
# PATHS_VAR - Variable to receive list of platform .winmds
# WINSDK_VERSION - SDK version to locate .winmds in
function(find_platform_winmds)
    cmake_parse_arguments(platform_winmd "" "PATHS_VAR;WINSDK_VERSION" "" ${ARGV})
    if(NOT WIN10SDK_ROOT)
        message(FATAL_ERROR "WIN10SDK_ROOT not set")
    endif()
    require_arguments(platform_winmd PATHS_VAR WINSDK_VERSION)

    set(${platform_winmd_PATHS_VAR} "")

    set(platform_package_regex "ApiContract name=\"(.*)\" version=\"([0-9\.]*)\"")
    file(STRINGS "${WIN10SDK_ROOT}/Platforms/UAP/${platform_winmd_WINSDK_VERSION}/Platform.xml" platform_packages REGEX ${platform_package_regex})
    
    set(winsdk_references "${WIN10SDK_ROOT}/References/${platform_winmd_WINSDK_VERSION}")
    foreach(package IN LISTS platform_packages)
        string(REGEX MATCH "${platform_package_regex}" PACKAGE_MATCH "${package}")
        set(package_name "${CMAKE_MATCH_1}")
        set(package_version "${CMAKE_MATCH_2}")
    
        set(package_path "${winsdk_references}/${package_name}/${package_version}/${package_name}.winmd")
        list(APPEND ${platform_winmd_PATHS_VAR} ${package_path})
    endforeach()

    cmake_path(CONVERT "${${platform_winmd_PATHS_VAR}}" TO_NATIVE_PATH_LIST ${platform_winmd_PATHS_VAR})
    set(${platform_winmd_PATHS_VAR} "${${platform_winmd_PATHS_VAR}}" PARENT_SCOPE)
endfunction()

# Obtain path for a specific UAP platform package
#
# PACKAGE - Name of package to locate .winmd for
# PATH_VAR - Variable to receive path to platform .winmds
# WINSDK_VERSION - SDK version to locate .winmds in
function(find_platform_package_dir)
    cmake_parse_arguments(platform_winmd "" "PACKAGE;PATH_VAR;WINSDK_VERSION" "" ${ARGV})
    if(NOT WIN10SDK_ROOT)
        message(FATAL_ERROR "WIN10SDK_ROOT not set")
    endif()
    if(NOT platform_winmd_PATH_VAR)
        message(FATAL_ERROR "PATH_VAR argument missing")
    endif()
    if(NOT platform_winmd_PACKAGE)
        message(FATAL_ERROR "PACKAGE argument missing")
    endif()
    if(NOT platform_winmd_WINSDK_VERSION)
        message(FATAL_ERROR "WINSDK_VERSION argument missing")
    endif()

    cmake_path(CONVERT "${WIN10SDK_ROOT}/References/${platform_winmd_WINSDK_VERSION}" TO_CMAKE_PATH_LIST winsdk_references)
    set(package_dir "${winsdk_references}/${platform_winmd_PACKAGE}")
    file(GLOB package_versions LIST_DIRECTORIES TRUE RELATIVE "${package_dir}" CONFIGURE_DEPENDS "${package_dir}/*")
    list(GET package_versions 0 package_version)
    cmake_path(CONVERT "${package_dir}/${package_version}" TO_NATIVE_PATH_LIST ${platform_winmd_PATH_VAR})
    set(${platform_winmd_PATH_VAR} "${${platform_winmd_PATH_VAR}}" PARENT_SCOPE)
endfunction()
