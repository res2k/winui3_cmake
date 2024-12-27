# nuget support
include_guard()

find_program(NUGET nuget REQUIRED)

# Runs 'nuget install', provides variables with available packages
#
# Arguments:
# PACKAGES_CONFIG - Optional packages config path. Defaults to ${CMAKE_CURRENT_SOURCE_DIR}/packages.config
# PACKAGES_DIR - Optional package dir. Defaults to ${CMAKE_CURRENT_BINARY_DIR}/packages
#
# Output variables:
# <package>_PATH - Location of a package. <package> is the package name, with MAKE_C_IDENTIFIER applied.
function(nuget_install)
    cmake_parse_arguments(nuget "" "PACKAGES_CONFIG;PACKAGES_DIR" "" ${ARGV})
    # Apply defaults for arguments
    if(NOT nuget_PACKAGES_CONFIG)
        set(nuget_PACKAGES_CONFIG "${CMAKE_CURRENT_SOURCE_DIR}/packages.config")
    endif()
    if(NOT nuget_PACKAGES_DIR)
        set(nuget_PACKAGES_DIR "${CMAKE_CURRENT_BINARY_DIR}/packages")
    endif()

    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${nuget_PACKAGES_CONFIG}")

    # Run 'nuget install'
    execute_process(COMMAND "${NUGET}" install "${nuget_PACKAGES_CONFIG}" -OutputDirectory "${nuget_PACKAGES_DIR}" -NonInteractive)

    # Extract package infos
    set(nuget_package_regex "package id=\"(.*)\" version=\"([0-9A-Za-z\.\-]*)\"")
    file(STRINGS "${nuget_PACKAGES_CONFIG}" NUGET_PACKAGES REGEX ${nuget_package_regex})
    foreach(package IN LISTS NUGET_PACKAGES)
        string(REGEX MATCH "${nuget_package_regex}" PACKAGE_MATCH "${package}")
        set(package_name "${CMAKE_MATCH_1}")
        set(package_version "${CMAKE_MATCH_2}")
    
        set(package_path "${nuget_PACKAGES_DIR}/${package_name}.${package_version}")
        string(MAKE_C_IDENTIFIER "${package_name}" VARNAME)
        set(VARNAME "${VARNAME}_PATH")
        set(${VARNAME} "${package_path}" PARENT_SCOPE)
    endforeach()
endfunction()
