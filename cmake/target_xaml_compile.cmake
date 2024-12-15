include(compile_xaml)
include(require_arguments)

# Compile .xaml file in TARGET's sources.
# Automatically extracts .xaml sources from TARGET and includes generated files for compilation,
# making it more convenient than raw compile_xaml().
#
# TARGET - Target to compile .xaml files for.
# Single-value arguments:
# OUTPUT_PATH - Directory to write output files to
# NAMESPACE - XAML namespace
# PCH - Precompiled header
# WINSDK_VERSION - Used SDK version
# MERGED_WINMD_DIR - Directory with merged .winmd file, file must be named <NAMESPACE>.winmd
# XBF_DIR_VAR - Optional, name of variable receiving directory with generated .xbf files
# XBF_FILES_VAR - Optional, name of variable receiving list of generated .xbf files, relative to XBF_DIR_VAR
# Multi-value arguments:
# REF_WINMD - List of reference .winmds (App SDK, Platform SDK .winmds)
function(target_xaml_compile TARGET)
    cmake_parse_arguments(target_xaml_compile "" "OUTPUT_PATH;NAMESPACE;PCH;WINSDK_VERSION;MERGED_WINMD_DIR;XBF_DIR_VAR;XBF_FILES_VAR" "REF_WINMD" ${ARGV})
    require_arguments(target_xaml_compile OUTPUT_PATH NAMESPACE PCH WINSDK_VERSION MERGED_WINMD_DIR)

    # Obtain XAML sources from target
    set(xaml_apps "")
    set(xaml_pages "")
    get_target_property(target_src ${TARGET} SOURCES)
    foreach(src IN LISTS target_src)
        get_filename_component(src_ext "${src}" EXT)
        string(TOLOWER "${src_ext}" src_ext)
        if(NOT src_ext STREQUAL ".xaml")
            continue()
        endif()
        get_source_file_property(xaml_type "${src}" VS_XAML_TYPE)
        if(xaml_type STREQUAL "ApplicationDefinition")
            list(APPEND xaml_apps "${src}")
        else()
            list(APPEND xaml_pages "${src}")
        endif()
    endforeach()

    if(${CMAKE_GENERATOR} MATCHES "Visual Studio")
        # VS generator: Add the necessary stuff to use MSBuild XAML compiler
        set(merged_winmd_path "${target_xaml_compile_MERGED_WINMD_DIR}/${target_xaml_compile_NAMESPACE}.winmd")
        set(app_sdk_props "${Microsoft_WindowsAppSDK_PATH}/build/native/Microsoft.WindowsAppSDK.props")
        set(app_sdk_targets "${Microsoft_WindowsAppSDK_PATH}/build/native/Microsoft.WindowsAppSDK.targets")
        set_target_properties(${TARGET} PROPERTIES VS_PROJECT_IMPORT "${app_sdk_props};${app_sdk_targets}")
        # Set a bunch of properties so XAML compilation works properly
        set_target_properties(${TARGET} PROPERTIES
            VS_GLOBAL_ROOTNAMESPACE "${target_xaml_compile_NAMESPACE}"
            VS_GLOBAL_AppContainerApplication "false"
            VS_GLOBAL_ApplicationType "Windows Store"
            VS_GLOBAL_AppxPackage "false"
            VS_GLOBAL_CustomAfterMicrosoftCommonTargets "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/target_xaml_compile_filter.targets" # Avoid assemblies being copied
            VS_GLOBAL_DisableXbfLineInfo "false"
            VS_GLOBAL_IntermediateOutputPath "${CMAKE_CURRENT_BINARY_DIR}" # for XamlSaveStateFile
            VS_GLOBAL_GeneratedFilesDir "${target_xaml_compile_OUTPUT_PATH}/"
            VS_GLOBAL_ManagedAssembly "false" # Inhibits .xr.xml files. Not sure why explicitly required.
            VS_GLOBAL_UseWinUI "true"
            VS_GLOBAL_WindowsPackageType "None"
            VS_GLOBAL_WindowsAppSdkBootstrapInitialize "false"
            VS_GLOBAL_XamlLanguage "CppWinRT"
            VS_GLOBAL_XamlLocalAssembly "${merged_winmd_path}"
            VS_WINRT_REFERENCES "${target_xaml_compile_REF_WINMD};${merged_winmd_path}"
            )
        # Note: Not using VS_WINRT_COMPONENT, as this enables a bunch of additional stuff we don't want

        # Also generate .xbf files list
        if(target_xaml_compile_XBF_DIR_VAR)
            set(${target_xaml_compile_XBF_DIR_VAR} "${target_xaml_compile_OUTPUT_PATH}" PARENT_SCOPE)
        endif()
        if(target_xaml_compile_XBF_FILES_VAR)
            _generated_xbf_files(xbf_files ${xaml_apps} ${xaml_pages})
            set(${target_xaml_compile_XBF_FILES_VAR} "${xbf_files}" PARENT_SCOPE)
        endif()
    else()
        # Other generators: Manually run XamlCompiler through compile_xaml
        set(compile_xaml_args "")
        foreach(arg IN ITEMS XBF_DIR_VAR XBF_FILES_VAR REF_WINMD)
            if(target_xaml_compile_${arg})
                list(APPEND compile_xaml_args ${arg} "${target_xaml_compile_${arg}}")
            endif()
        endforeach()
        compile_xaml(TARGET ${TARGET}_generate_xaml
                    OUTPUT_PATH "${target_xaml_compile_OUTPUT_PATH}"
                    NAMESPACE "${target_xaml_compile_NAMESPACE}"
                    PCH "${target_xaml_compile_PCH}"
                    WINSDK_VERSION "${target_xaml_compile_WINSDK_VERSION}"
                    MERGED_WINMD_DIR "${target_xaml_compile_MERGED_WINMD_DIR}"
                    GENERATED_SOURCES xaml_generated
                    XAML_APPS "${xaml_apps}"
                    XAML_PAGES "${xaml_pages}"
                    ${compile_xaml_args}
                    )
        foreach(output_arg IN ITEMS XBF_DIR_VAR XBF_FILES_VAR GENERATED_SOURCES)
            if(target_xaml_compile_${output_arg})
                set(${target_xaml_compile_${output_arg}} "${${target_xaml_compile_${output_arg}}}" PARENT_SCOPE)
            endif()
        endforeach()

        # Add generated sources to target
        target_sources(${TARGET} PRIVATE ${xaml_generated})
    endif()
endfunction()
