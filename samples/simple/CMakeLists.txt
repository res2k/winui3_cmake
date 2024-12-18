include(compile_xaml)
include(find_platform_winmds)
include(generate_winappsdk)
include(generate_XamlMetaDataProvider)
include(make_pri)
include(merge_winmds)
include(run_cppwinrt)
include(winmd_from_idl)

set(ROOT_NAMESPACE "winui3_cmake_simple") # must match XAML class namespaces etc.

# Arguments that are shared by multiple functions
set(common_args
    WINSDK_VERSION 10.0.17763.0
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


compile_xaml(TARGET simple_generate_xaml
             OUTPUT_PATH "${CMAKE_CURRENT_BINARY_DIR}/generated"
             MERGED_WINMD_DIR "${CMAKE_CURRENT_BINARY_DIR}/winmd_merged"
             REF_WINMD ${WINMD_PATHS}
             XAML_APPS "${CMAKE_CURRENT_SOURCE_DIR}/App.xaml"
             XAML_PAGES "${CMAKE_CURRENT_SOURCE_DIR}/MainWindow.xaml"
             XBF_DIR_VAR xbf_dir
             XBF_FILES_VAR xbf_files
             GENERATED_SOURCES xaml_generated
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

set(pri_file "${CMAKE_CURRENT_BINARY_DIR}/resources.pri")
make_pri(OUTPUT "${pri_file}"
         DIRECTORY "${xbf_dir}"
         FILES "${xbf_files}")
add_custom_target(simple_pri DEPENDS "${pri_file}")

add_executable(simple WIN32)
add_dependencies(simple simple_generate_winappsdk)
add_dependencies(simple simple_pri)
target_sources(simple PRIVATE
               "app.manifest"
               "App.xaml"
               "App.xaml.cpp"
               "App.xaml.h"
               "MainWindow.xaml"
               "MainWindow.xaml.cpp"
               "MainWindow.xaml.h"
               "${cppwinrt_generated}"
               "${xaml_generated}"
               "${XamlMetaDataProvider_CPP}"

               "${Microsoft_WindowsAppSDK_PATH}/include/MddBootstrapAutoInitializer.cpp"
               )
target_include_directories(simple PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated")
target_include_directories(simple PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_include_directories(simple PRIVATE "${Microsoft_Windows_ImplementationLibrary_PATH}/include")
target_include_directories(simple PRIVATE "${Microsoft_WindowsAppSDK_PATH}/include")
target_link_libraries(simple PRIVATE "${Microsoft_WindowsAppSDK_PATH}/lib/win10-x64/Microsoft.WindowsAppRuntime.Bootstrap.lib")
target_precompile_headers(simple PRIVATE pch.h)
add_custom_command(TARGET simple
                   POST_BUILD
                   COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${Microsoft_WindowsAppSDK_PATH}/runtimes/win-x64/native/Microsoft.WindowsAppRuntime.Bootstrap.dll" "$<TARGET_FILE_DIR:simple>")
add_custom_command(TARGET simple
                   POST_BUILD
                   COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${pri_file}" "$<TARGET_FILE_DIR:simple>/simple.pri")
