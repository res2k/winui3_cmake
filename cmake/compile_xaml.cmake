# Generate various files from .xaml inputs
include_guard()

include(check_nuget_package)
include(json)
include(require_arguments)
check_nuget_package(Microsoft.WindowsAppSDK REQUIRED)

# Helper: Create JSON representation of MSBuild Item
function(make_msbuild_item JSON)
    cmake_parse_arguments(mbi "" "PATH;DEPENDS" "" ${ARGV})
    require_arguments(mbi PATH)
    cmake_path(CONVERT "${mbi_PATH}" TO_NATIVE_PATH_LIST path)
    json_obj_new(item_json)
    json_obj_set_str(item_json "ItemSpec" "${path}")
    json_obj_set_str(item_json "FullPath" "${path}")
    if(mbi_DEPENDS)
        cmake_path(CONVERT "${mbi_DEPENDS}" TO_NATIVE_PATH_LIST depends)
        json_obj_set_str(item_json "DependentUpon" "${depends}")
    endif()
    set(${JSON} "${item_json}" PARENT_SCOPE)
endfunction()

# Run XAML compiler.
#
# Single-value arguments:
# TARGET - Target to create for compilation (to eg trigger explicitly)
# OUTPUT_PATH - Directory to write output files to
# NAMESPACE - XAML namespace
# PCH - Precompiled header
# WINSDK_VERSION - Used SDK version
# MERGED_WINMD_DIR - Directory with merged .winmd file, file must be named <NAMESPACE>.winmd
# XBF_DIR_VAR - Optional, name of variable receiving directory with generated .xbf files
# XBF_FILES_VAR - Optional, name of variable receiving list of generated .xbf files, relative to XBF_DIR_VAR
# GENERATED_SOURCES - Optional, name of variable receiving generated source files. Should be included in compilation
# Multi-value arguments:
# REF_WINMD - List of reference .winmds (App SDK, Platform SDK .winmds)
# XAML_APPS - List of application .xaml file(s)
# XAML_PAGES - List of page .xaml file(s)
function(compile_xaml)
    cmake_parse_arguments(compile_xaml "" "TARGET;OUTPUT_PATH;NAMESPACE;PCH;WINSDK_VERSION;MERGED_WINMD_DIR;XBF_DIR_VAR;XBF_FILES_VAR;GENERATED_SOURCES" "REF_WINMD;XAML_APPS;XAML_PAGES" ${ARGV})
    require_arguments(compile_xaml TARGET OUTPUT_PATH NAMESPACE PCH WINSDK_VERSION MERGED_WINMD_DIR)

    set(XAMLCOMPILER "${Microsoft_WindowsAppSDK_PATH}/tools/net472/XamlCompiler.exe")
    set(xaml_input_json_path "${CMAKE_CURRENT_BINARY_DIR}/${compile_xaml_TARGET}.pass1.in.json")
    set(xaml_output_json_path "${CMAKE_CURRENT_BINARY_DIR}/${compile_xaml_TARGET}.pass1.out.json")
    json_obj_new(xaml_input_json)
    json_obj_set_str(xaml_input_json "SavedStateFile" "${CMAKE_CURRENT_BINARY_DIR}/XamlCompilerState.xml")
    json_obj_set(xaml_input_json "IsPass1" "true")
    json_obj_set_str(xaml_input_json "Language" "CppWinRT")
    json_obj_set_str(xaml_input_json "ProjectPath" "${CMAKE_CURRENT_LIST_FILE}") # Used to compute some relative paths
    json_obj_set_str(xaml_input_json "LanguageSourceExtension" ".cpp")
    json_obj_set_str(xaml_input_json "OutputPath" "${compile_xaml_OUTPUT_PATH}")
    json_obj_set_str(xaml_input_json "RootNamespace" "${compile_xaml_NAMESPACE}") # Needs to match XAML contents
    json_obj_set_str(xaml_input_json "PrecompiledHeaderFile" "${compile_xaml_PCH}") # ends up in generated code
    json_obj_set_str(xaml_input_json "FeatureControlFlags" "EnableXBindDiagnostics;EnableDefaultValidationContextGeneration;EnableWin32Codegen")
    json_array_new(refassemblies_json)
    foreach(ref_path IN LISTS compile_xaml_REF_WINMD)
        make_msbuild_item(ref_json PATH "${ref_path}")
        json_array_append(refassemblies_json "${ref_json}")
    endforeach()
    json_obj_set(xaml_input_json "ReferenceAssemblies" "${refassemblies_json}")
    json_obj_set(xaml_input_json "ReferenceAssemblyPaths" "[]")
    json_obj_set_str(xaml_input_json "TargetPlatformMinVersion" "${compile_xaml_WINSDK_VERSION}")
    json_array_new(xamlpages_json)
    foreach(xaml_page_src IN LISTS compile_xaml_XAML_PAGES)
        make_msbuild_item(page_json PATH "${xaml_page_src}")
        json_array_append(xamlpages_json "${page_json}")
    endforeach()
    json_obj_set(xaml_input_json "XamlPages" "${xamlpages_json}")
    json_array_new(xamlapps_json)
    foreach(xaml_app_src IN LISTS compile_xaml_XAML_APPS)
        make_msbuild_item(app_json PATH "${xaml_app_src}")
        json_array_append(xamlapps_json "${app_json}")
    endforeach()
    json_obj_set(xaml_input_json "XamlApplications" "${xamlapps_json}")
    json_array_new(cl_include_files_json)
    foreach(xaml_file IN LISTS compile_xaml_XAML_APPS compile_xaml_XAML_PAGES)
        make_msbuild_item(include_file_json PATH "${xaml_file}.h" DEPENDS "${xaml_file}")
        json_array_append(cl_include_files_json "${include_file_json}")
    endforeach()
    json_obj_set(xaml_input_json "ClIncludeFiles" "${cl_include_files_json}")

    set(generated_sources "")

    set(pass1_generated "")
    foreach(xaml_file IN LISTS compile_xaml_XAML_APPS compile_xaml_XAML_PAGES)
        cmake_path(GET xaml_file STEM xaml_stem)
        list(APPEND pass1_generated "${compile_xaml_OUTPUT_PATH}/${xaml_stem}.xaml.g.h")
    endforeach()
    # Is there some way to get these programmatically?
    list(APPEND pass1_generated "${compile_xaml_OUTPUT_PATH}/XamlBindingInfo.xaml.g.h")
    list(APPEND pass1_generated "${compile_xaml_OUTPUT_PATH}/XamlLibMetadataProvider.g.cpp")
    list(APPEND pass1_generated "${compile_xaml_OUTPUT_PATH}/XamlMetaDataProvider.h")
    list(APPEND pass1_generated "${compile_xaml_OUTPUT_PATH}/XamlTypeInfo.Impl.g.cpp")
    list(APPEND pass1_generated "${compile_xaml_OUTPUT_PATH}/XamlTypeInfo.xaml.g.h")

    set(generated_sources "${pass1_generated}")

    file(GENERATE OUTPUT "${xaml_input_json_path}" CONTENT "${xaml_input_json}")
    add_custom_command(
        OUTPUT ${pass1_generated}
        COMMAND "${XAMLCOMPILER}" "${xaml_input_json_path}" "${xaml_output_json_path}"
        DEPENDS "${xaml_input_json_path}" ${compile_xaml_XAML_APPS} ${compile_xaml_XAML_PAGES}
        COMMENT "Running XAML compiler for ${compile_xaml_TARGET}, pass 1")
    add_custom_target(${compile_xaml_TARGET} DEPENDS ${pass1_generated})

    set(merged_winmd_path "${compile_xaml_MERGED_WINMD_DIR}/${compile_xaml_NAMESPACE}.winmd")

    set(xaml_input_json_pass2_path "${CMAKE_CURRENT_BINARY_DIR}/${compile_xaml_TARGET}.pass2.in.json")
    set(xaml_output_json_pass2_path "${CMAKE_CURRENT_BINARY_DIR}/${compile_xaml_TARGET}.pass2.out.json")
    json_obj_set(xaml_input_json "IsPass1" "false")
    json_array_new(localassembly_json)
    make_msbuild_item(winmd_json PATH "${merged_winmd_path}")
    json_array_append(localassembly_json "${winmd_json}")
    json_obj_set(xaml_input_json "LocalAssembly" "${localassembly_json}")
    json_obj_set_str(xaml_input_json "GenXbfPath" "${Microsoft_WindowsAppSDK_PATH}/tools")

    set(pass2_generated "")
    foreach(xaml_file IN LISTS compile_xaml_XAML_APPS compile_xaml_XAML_PAGES)
        cmake_path(GET xaml_file STEM xaml_stem)
        list(APPEND pass2_generated "${compile_xaml_OUTPUT_PATH}/${xaml_stem}.xaml")
        list(APPEND pass2_generated "${compile_xaml_OUTPUT_PATH}/${xaml_stem}.xaml.g.hpp")
        list(APPEND pass2_generated "${compile_xaml_OUTPUT_PATH}/${xaml_stem}.xbf")
        list(APPEND generated_sources "${compile_xaml_OUTPUT_PATH}/${xaml_stem}.xaml.g.hpp")
    endforeach()
    # Is there some way to get these programmatically?
    list(APPEND pass2_generated "${compile_xaml_OUTPUT_PATH}/XamlTypeInfo.g.cpp")
    list(APPEND generated_sources "${compile_xaml_OUTPUT_PATH}/XamlTypeInfo.g.cpp")

    file(GENERATE OUTPUT "${xaml_input_json_pass2_path}" CONTENT "${xaml_input_json}")
    add_custom_command(
        OUTPUT ${pass2_generated}
        COMMAND "${XAMLCOMPILER}" "${xaml_input_json_pass2_path}" "${xaml_output_json_pass2_path}"
        DEPENDS
            "${xaml_input_json_pass2_path}"
            ${compile_xaml_XAML_APPS}
            ${compile_xaml_XAML_PAGES}
            "${merged_winmd_path}"
            ${pass1_generated} # have pass 2 explicitly depend on pass 1
        COMMENT "Running XAML compiler for ${compile_xaml_TARGET}, pass 2")
    add_custom_target(${compile_xaml_TARGET}_pass2 DEPENDS ${pass2_generated})

    if(compile_xaml_XBF_DIR_VAR)
        set(${compile_xaml_XBF_DIR_VAR} "${compile_xaml_OUTPUT_PATH}" PARENT_SCOPE)
    endif()
    if(compile_xaml_XBF_FILES_VAR)
        set(xbf_files "")
        foreach(xaml_file IN LISTS compile_xaml_XAML_APPS compile_xaml_XAML_PAGES)
            cmake_path(GET xaml_file STEM xaml_stem)
            list(APPEND xbf_files "${xaml_stem}.xbf")
        endforeach()
        set(${compile_xaml_XBF_FILES_VAR} "${xbf_files}" PARENT_SCOPE)
    endif()

    if(compile_xaml_GENERATED_SOURCES)
        set(${compile_xaml_GENERATED_SOURCES} "${generated_sources}" PARENT_SCOPE)
    endif()
endfunction()
