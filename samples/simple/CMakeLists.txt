include(find_platform_winmds)
include(generate_winappsdk)
include(generate_XamlMetaDataProvider)
include(make_pri)
include(merge_winmds)
include(run_cppwinrt)
include(target_xaml_compile)
include(target_xaml_sources)
include(winmd_from_idl)

set(ROOT_NAMESPACE "winui3_cmake_simple") # must match XAML class namespaces etc.

# Arguments that are shared by multiple functions
set(WINSDK_VERSION 10.0.17763.0)
set(common_args
    WINSDK_VERSION ${WINSDK_VERSION}
    NAMESPACE "winui3_cmake_simple"
    PCH "pch.h")

generate_XamlMetaDataProvider(OUTDIR "${CMAKE_CURRENT_BINARY_DIR}/XamlMetaDataProvider"
                              IDL_VAR XamlMetaDataProvider_IDL
                              CPP_VAR XamlMetaDataProvider_CPP
                              ${common_args})


generate_winappsdk(TARGET simple_generate_winappsdk OUT "${CMAKE_CURRENT_BINARY_DIR}/generated" WINMDS WINMD_PATHS ${common_args})

set(XamlMetaDataProvider_WINMD "${CMAKE_CURRENT_BINARY_DIR}/winmd_unmerged/XamlMetaDataProvider.winmd")
winmd_from_idl(OUT "${CMAKE_CURRENT_BINARY_DIR}/winmd_unmerged/MainWindow.winmd"
               IN "${CMAKE_CURRENT_SOURCE_DIR}/MainWindow.idl"
               REF ${WINMD_PATHS}
               ${common_args})
winmd_from_idl(OUT "${XamlMetaDataProvider_WINMD}"
               IN "${XamlMetaDataProvider_IDL}"
               REF ${WINMD_PATHS}
               ${common_args})

merge_winmds(TARGET simple_merge_winmds
             OUTDIR "${CMAKE_CURRENT_BINARY_DIR}/winmd_merged"
             IN "${CMAKE_CURRENT_BINARY_DIR}/winmd_unmerged/MainWindow.winmd" "${XamlMetaDataProvider_WINMD}"
             REF ${WINMD_PATHS}
             ${common_args})


run_cppwinrt(TARGET simple_generate_cppwinrt
             IN "${CMAKE_CURRENT_BINARY_DIR}/winmd_merged/${ROOT_NAMESPACE}.winmd"
             OUT "${CMAKE_CURRENT_BINARY_DIR}/generated"
             COMPONENT "${CMAKE_CURRENT_BINARY_DIR}/generated/sources"
             COMPONENT_NAME "${ROOT_NAMESPACE}"
             PREFIX OPTIMIZE OVERWRITE
             REF ${WINMD_PATHS}
             GENERATED_SOURCES cppwinrt_generated
             ${common_args})

add_executable(simple WIN32)
add_dependencies(simple simple_generate_winappsdk)
add_dependencies(simple simple_merge_winmds) # Avoids a warning in XAML compilation
target_sources(simple PRIVATE
               "app.manifest"
               "${cppwinrt_generated}"
               "${XamlMetaDataProvider_CPP}"

               "${Microsoft_WindowsAppSDK_PATH}/include/MddBootstrapAutoInitializer.cpp"
               )
target_xaml_sources(simple PRIVATE "App.xaml" VS_XAML_TYPE ApplicationDefinition)
target_xaml_sources(simple PRIVATE "MainWindow.xaml")
target_compile_definitions(simple PRIVATE UNICODE _UNICODE)
set_target_properties(simple PROPERTIES VS_WINDOWS_TARGET_PLATFORM_MIN_VERSION ${WINSDK_VERSION})
target_include_directories(simple PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated")
target_include_directories(simple PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_include_directories(simple PRIVATE "${Microsoft_Windows_ImplementationLibrary_PATH}/include")
target_include_directories(simple PRIVATE "${Microsoft_WindowsAppSDK_PATH}/include")
target_link_libraries(simple PRIVATE "${Microsoft_WindowsAppSDK_PATH}/lib/win10-x64/Microsoft.WindowsAppRuntime.Bootstrap.lib")
target_precompile_headers(simple PRIVATE pch.h)
target_xaml_compile(simple
                    OUTPUT_PATH "${CMAKE_CURRENT_BINARY_DIR}/generated"
                    MERGED_WINMD_DIR "${CMAKE_CURRENT_BINARY_DIR}/winmd_merged"
                    REF_WINMD ${WINMD_PATHS}
                    XBF_DIR_VAR xbf_dir
                    XBF_FILES_VAR xbf_files
                    ${common_args})
add_custom_command(TARGET simple
                   POST_BUILD
                   COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${Microsoft_WindowsAppSDK_PATH}/runtimes/win-x64/native/Microsoft.WindowsAppRuntime.Bootstrap.dll" "$<TARGET_FILE_DIR:simple>")

set(pri_file "${CMAKE_CURRENT_BINARY_DIR}/resources.pri")
make_pri_postbuild(simple
                   OUTPUT "${pri_file}"
                   DIRECTORY "${xbf_dir}"
                   FILES "${xbf_files}")
add_custom_command(TARGET simple
                   POST_BUILD
                   COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${pri_file}" "$<TARGET_FILE_DIR:simple>/simple.pri")
