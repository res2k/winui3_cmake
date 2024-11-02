# Find .winmd files for AppSDK packages
include_guard()

include(check_nuget_package)
check_nuget_package(Microsoft.WindowsAppSDK REQUIRED)

# Get list of uap* directories to search for .winmd files
function(_appsdk_uap_paths PATHS WINSDK_VERSION)
    set(${PATHS} "")
    set(lib_path "${Microsoft_WindowsAppSDK_PATH}/lib")
    file(GLOB candidates LIST_DIRECTORIES TRUE RELATIVE "${lib_path}" CONFIGURE_DEPENDS "${lib_path}/uap*")
    # Find uap* directory with the smallest version component that is larger or equal to WINSDK_VERSION
    set(SMALLEST_VER "")
    set(SMALLEST_VER_PATH "")
    foreach(subdir IN LISTS candidates)
        string(REGEX MATCH "uap([0-9]+\\.[0-9]+(\\.[0-9]+)?)" uap_version "${subdir}")
        if(NOT CMAKE_MATCH_2)
            # "Major version" directory (ie uap10.0 for 10.0.x versions)
            list(APPEND ${PATHS} "${lib_path}/${subdir}")
            continue()
        endif()
        if(CMAKE_MATCH_1 VERSION_LESS WINSDK_VERSION)
            continue()
        endif()
        if(NOT SMALLEST_VER OR CMAKE_MATCH_1 VERSION_LESS SMALLEST_VER)
            set(SMALLEST_VER "${CMAKE_MATCH_1}")
            set(SMALLEST_VER_PATH "${subdir}")
        endif()
    endforeach()
    if(SMALLEST_VER_PATH)
        list(INSERT ${PATHS} 0 "${lib_path}/${SMALLEST_VER_PATH}")
    endif()
    set(${PATHS} ${${PATHS}} PARENT_SCOPE)
endfunction()

# Find a single .winmd in a list of path candidates
function(_find_appsdk_winmd VAR PATHS WINMD_NAME)
    foreach(test_dir IN LISTS PATHS)
        set(test_path "${test_dir}/${WINMD_NAME}")
        if(EXISTS "${test_path}")
            set(${VAR} "${test_path}" PARENT_SCOPE)
            return()
        endif()
    endforeach()
    set(${VAR} "${test_path}" NOTFOUND)
endfunction()

# Find .winmd files for AppSDK packages.
#
# PATHS_VAR - Variable to receive paths with WinMDs
# WINSDK_VERSION - SDK version to locate .winmds in
# PACKAGES - One or more packages to locate .winmds for
function(find_appsdk_winmds)
    cmake_parse_arguments(appsdk_winmd "" "PATHS_VAR;WINSDK_VERSION" "PACKAGES" ${ARGV})
    if(NOT appsdk_winmd_PATHS_VAR)
        message(FATAL_ERROR "PATHS_VAR argument missing")
    endif()
    if(NOT appsdk_winmd_WINSDK_VERSION)
        message(FATAL_ERROR "WINSDK_VERSION argument missing")
    endif()
    set(${appsdk_winmd_PATHS_VAR} "")

    _appsdk_uap_paths(paths ${appsdk_winmd_WINSDK_VERSION})
    foreach(appsdk_winmd IN LISTS appsdk_winmd_PACKAGES)
        _find_appsdk_winmd(winmd_path "${paths}" "${appsdk_winmd}.winmd")
        if(NOT winmd_path)
            message(WARNING "Could not find .winmd for ${appsdk_winmd}")
            continue()
        endif()
        list(APPEND ${appsdk_winmd_PATHS_VAR} "${winmd_path}")
    endforeach()

    set(${appsdk_winmd_PATHS_VAR} ${${appsdk_winmd_PATHS_VAR}} PARENT_SCOPE)
endfunction()
