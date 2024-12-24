# Convert an .idl file to .winmd
include_guard()

include(find_platform_winmds)
include(require_arguments)
include(sdk_buildtools)
find_sdk_buildtool(MIDL midl REQUIRED)

# Convert an .idl file to .winmd
#
# OUT - Output .winmd name
# IN - Input .idl name
# WINSDK_VERSION - Windows SDK version used to locate native metadata
# REF - Reference .winmd files to use
function(winmd_from_idl)
    cmake_parse_arguments(winmd_from_idl "" "OUT;IN;WINSDK_VERSION;NAMESPACE;PCH" "REF" ${ARGV})
    # NAMESPACE, PCH are unused and only here so "common arguments" can be added
    require_arguments(winmd_from_idl OUT IN WINSDK_VERSION)

    cmake_path(NATIVE_PATH winmd_from_idl_IN idl_native)
    cmake_path(NATIVE_PATH winmd_from_idl_OUT winmd_native)
    set(midl_args "")
    cmake_path(CONVERT "${winmd_from_idl_REF}" TO_NATIVE_PATH_LIST ref_path_native)
    foreach(ref_path IN LISTS ref_path_native)
        set(midl_args "${midl_args} /reference \"${ref_path}\"")
    endforeach()
    find_platform_package_dir(PACKAGE windows.foundation.foundationcontract PATH_VAR metadata_native WINSDK_VERSION ${winmd_from_idl_WINSDK_VERSION})
    add_custom_command(OUTPUT "${winmd_from_idl_OUT}"
                       COMMAND ${MIDL} ARGS "${idl_native}" /nologo /winrt /winmd "${winmd_native}" /nomidl /h "nul" /metadata_dir "${metadata_native}" ${midl_args}
                       MAIN_DEPENDENCY "${idl_native}"
                       DEPENDS "${idl_native}" "${ref_path_native}"
                       )
endfunction()
