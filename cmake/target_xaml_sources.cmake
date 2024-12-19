# Helper: Create a hardlink ${CMAKE_CURRENT_BINARY_DIR}/<path> linking to ${CMAKE_CURRENT_SOURCE_DIR}/<path>
function(_maybe_link_into_binary result_path_var path)
    cmake_path(ABSOLUTE_PATH path NORMALIZE OUTPUT_VARIABLE path_abs)
    cmake_path(RELATIVE_PATH path_abs OUTPUT_VARIABLE path_rel)
    cmake_path(ABSOLUTE_PATH path_rel BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" OUTPUT_VARIABLE path_dst)
    if(EXISTS "${path_dst}")
        file(REMOVE "${path_dst}")
    endif()
    execute_process(COMMAND "${CMAKE_COMMAND}" -E create_hardlink "${path_abs}" "${path_rel}"
                    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
                    RESULT_VARIABLE link_res)
    if(link_res EQUAL 0)
        set(${result_path_var} "${path_dst}" PARENT_SCOPE)
    else()
        # Fallback: original value
        set(${result_path_var} "${path}" PARENT_SCOPE)
    endif()
endfunction()

# Add XAML sources to a target.
# Contains some workarounds for VS to ensure "Just My XAML" and Hot Reload work.
#
# TARGET - Target to add sources to
# VS_XAML_TYPE - Optional XAML source type. Typically used to set ApplicationDefition for app XAML.
# Other arguments are passed through to target_sources().
function(target_xaml_sources TARGET)
    cmake_parse_arguments(txs "" "VS_XAML_TYPE" "" ${ARGN})

    set(new_args "")
    set(new_sources "")
    foreach(maybe_src IN LISTS txs_UNPARSED_ARGUMENTS)
        # Only look for potential XAML files
        if(NOT maybe_src MATCHES "\.[Xx][Aa][Mm][Ll]$")
            list(APPEND new_args "${maybe_src}")
            continue()
        endif()

        # For VS' "Just My XAML" and Hot Reload to work, some apparently very specific
        # requirements for the XAML source locations have to be met; chiefly, it seems
        # the file(s) have to be located below the project file's locations (perhaps the
        # subdirectories mirroring the name hierarchy).
        # To achieve that create hardlinks to the original file location, to both fulfill
        # the requirements for "Just My XAML" and Hot Reload, while allowing the user to
        # place them as they desire.

        # The "relative source location" hackery is only useful for VS, skip in all other cases
        if(NOT ${CMAKE_GENERATOR} MATCHES "Visual Studio")
            list(APPEND new_args "${maybe_src}")
            list(APPEND new_sources "${maybe_src}")
            foreach(candidate_file IN ITEMS "${maybe_src}.cpp" "${maybe_src}.h")
                cmake_path(ABSOLUTE_PATH candidate_file NORMALIZE OUTPUT_VARIABLE candidate_abs)
                if(NOT EXISTS "${candidate_abs}")
                    continue()
                endif()
                list(APPEND new_args "${candidate_file}")
            endforeach()
            continue()
        endif()

        # Source file: use links to "hack" in source locations relative to project
        _maybe_link_into_binary(xaml_path "${maybe_src}")
        list(APPEND new_args "${xaml_path}")
        list(APPEND new_sources "${xaml_path}")

        # .xaml.h needs to be placed alongside .xaml so C++ generation works correctly.
        # .xaml.cpp is here for good measure.
        foreach(candidate_file IN ITEMS "${maybe_src}.cpp" "${maybe_src}.h")
            cmake_path(ABSOLUTE_PATH candidate_file NORMALIZE OUTPUT_VARIABLE candidate_abs)
            if(NOT EXISTS "${candidate_abs}")
                continue()
            endif()

            _maybe_link_into_binary(candidate_path "${candidate_abs}")
            list(APPEND new_args "${candidate_path}")
        endforeach()
    endforeach()

    target_sources(${TARGET} ${new_args})
    if(txs_VS_XAML_TYPE)
        set_source_files_properties(${new_sources} PROPERTIES VS_XAML_TYPE ${txs_VS_XAML_TYPE})
    endif()
endfunction()
