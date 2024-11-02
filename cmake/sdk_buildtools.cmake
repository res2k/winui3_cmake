# Get path to a tool in the Microsoft.Windows.SDK.BuildTools package
include_guard()

include(arch_name)
include(check_nuget_package)
check_nuget_package(Microsoft.Windows.SDK.BuildTools REQUIRED)

# Get path to a tool in the Microsoft.Windows.SDK.BuildTools package
#
# VAR - Variable receiving path to tool
# NAME - Name of tool
# REQUIRED - (optional) Indicates a required tool
function(find_sdk_buildtool VAR NAME)
    # Below ${Microsoft_Windows_SDK_BuildTools_PATH}/bin is a subdir with the version number
    set(bindir "${Microsoft_Windows_SDK_BuildTools_PATH}/bin")
    file(GLOB bindirs LIST_DIRECTORIES TRUE CONFIGURE_DEPENDS "${bindir}/*")
    list(GET bindirs 0 bindir)

    get_host_system_arch_name(arch)
    set(bindir "${bindir}/${arch}")

    set(find_args "")
    list(APPEND find_args "${VAR}")
    list(APPEND find_args "${NAME}")
    list(APPEND find_args PATHS "${bindir}")
    list(APPEND find_args NO_DEFAULT_PATH)
    if(REQUIRED IN_LIST ARGV)
        list(APPEND find_args REQUIRED)
    endif()
    find_program(${find_args})
    set(${VAR} "${${VAR}}" PARENT_SCOPE)
endfunction()
