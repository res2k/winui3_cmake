# Funtion to run cppwinrt, generating headers from .winmd files
include_guard()

include(check_nuget_package)
check_nuget_package(Microsoft.Windows.CppWinRT REQUIRED)

# Run cppwinrt, generating headers from .winmd files
# (and other things)
#
# Single-value arguments:
# TARGET - Name of CMake target to generate
# OUT - Output directory
# PCH - Optional name of precompiled header
# COMPONENT - Optional component directory
# COMPONENT_NAME - Optional component name
#
# IN - List of input .winmd files
# REF - List of reference .winmd files
#
# OVERWRITE - Pass '-overwrite' argument to cppwinrt
# OPTIMIZE - Pass '-optimize' argument to cppwinrt
# PREFIX - Pass '-prefix' argument to cppwinrt
function(run_cppwinrt)
    set(cppwinrt_path "${Microsoft_Windows_CppWinRT_PATH}/bin/cppwinrt.exe")

    cmake_parse_arguments(CPPWINRT "OVERWRITE;OPTIMIZE;PREFIX" "TARGET;OUT;PCH;COMPONENT;COMPONENT_NAME;GENERATED_SOURCES;NAMESPACE;WINSDK_VERSION" "IN;REF" ${ARGV})
    # NAMESPACE, WINSDK_VERSION are unused and only here so "common arguments" can be added
    string(MAKE_C_IDENTIFIER "${CPPWINRT_TARGET}" target_ident)
    set(cppwinrt_args "")
    foreach(input_arg ${CPPWINRT_IN})
        list(APPEND cppwinrt_args "-in" "${input_arg}")
    endforeach()
    foreach(ref_arg ${CPPWINRT_REF})
        list(APPEND cppwinrt_args "-ref" "${ref_arg}")
    endforeach()
    if(CPPWINRT_OUT)
        list(APPEND cppwinrt_args "-out" "${CPPWINRT_OUT}")
    endif()
    if(CPPWINRT_COMPONENT)
        list(APPEND cppwinrt_args "-comp" "${CPPWINRT_COMPONENT}")
        if(CPPWINRT_COMPONENT_NAME)
            list(APPEND cppwinrt_args "-name" "${CPPWINRT_COMPONENT_NAME}")
        endif()
    endif()
    if(CPPWINRT_PCH)
        list(APPEND cppwinrt_args "-pch" "${CPPWINRT_PCH}")
    endif()
    if(CPPWINRT_OVERWRITE)
        list(APPEND cppwinrt_args "-overwrite")
    endif()
    if(CPPWINRT_OPTIMIZE)
        list(APPEND cppwinrt_args "-optimize")
    endif()
    if(CPPWINRT_PREFIX)
        list(APPEND cppwinrt_args "-prefix")
    endif()

    set(generated_sources "")
    if(CPPWINRT_COMPONENT)
        list(APPEND generated_sources "${CPPWINRT_OUT}/module.g.cpp")
    endif()

    set(stamp_file "${CPPWINRT_OUT}/.${target_ident}.stamp")
    add_custom_command(OUTPUT "${stamp_file}" ${generated_sources}
                       COMMAND "${cppwinrt_path}" ${cppwinrt_args}
                       COMMAND "${CMAKE_COMMAND}" -E touch "${stamp_file}"
                       DEPENDS ${CPPWINRT_IN} ${CPPWINRT_REF}
                       COMMENT "Running cppwinrt for ${CPPWINRT_TARGET}")
    add_custom_target(${CPPWINRT_TARGET} DEPENDS "${stamp_file}")

    if(CPPWINRT_GENERATED_SOURCES)
        set(${CPPWINRT_GENERATED_SOURCES} "${generated_sources}" PARENT_SCOPE)
    endif()
endfunction()
