include(generate_winappsdk)
include(merge_winmds)
include(run_cppwinrt)
include(winmd_from_idl)

set(ROOT_NAMESPACE "MiniWinUITest") # must match XAML class namespaces etc.

# Arguments that are shared by multiple functions
set(common_args
    WINSDK_VERSION 10.0.17763.0
    NAMESPACE "MiniWinUITest"
    PCH "pch.h")

generate_winappsdk(TARGET MinWinUITest_generate_winappsdk OUT "${CMAKE_CURRENT_BINARY_DIR}/generated" WINMDS WINMD_PATHS ${common_args})

winmd_from_idl(OUT "${CMAKE_CURRENT_BINARY_DIR}/winmd_unmerged/MainWindow.winmd"
               IN "${CMAKE_CURRENT_SOURCE_DIR}/MainWindow.idl"
               REF ${WINMD_PATHS}
               ${common_args})
winmd_from_idl(OUT "${CMAKE_CURRENT_BINARY_DIR}/winmd_unmerged/XamlApplication.winmd"
               IN "${CMAKE_CURRENT_SOURCE_DIR}/XamlApplication.idl"
               REF ${WINMD_PATHS}
               ${common_args})

merge_winmds(TARGET MinWinUITest_merge_winmds
             OUTDIR "${CMAKE_CURRENT_BINARY_DIR}/winmd_merged"
             IN "${CMAKE_CURRENT_BINARY_DIR}/winmd_unmerged/MainWindow.winmd" "${CMAKE_CURRENT_BINARY_DIR}/winmd_unmerged/XamlApplication.winmd"
             REF ${WINMD_PATHS}
             ${common_args})


run_cppwinrt(TARGET MinWinUITest_generate_cppwinrt
             IN "${CMAKE_CURRENT_BINARY_DIR}/winmd_merged/${ROOT_NAMESPACE}.winmd"
             OUT "${CMAKE_CURRENT_BINARY_DIR}/generated"
             COMPONENT "${CMAKE_CURRENT_BINARY_DIR}/generated/sources"
             COMPONENT_NAME "${ROOT_NAMESPACE}"
             PREFIX OPTIMIZE OVERWRITE
             REF ${WINMD_PATHS}
             GENERATED_SOURCES cppwinrt_generated
             ${common_args})

add_executable(MinWinUITest WIN32)
add_dependencies(MinWinUITest MinWinUITest_generate_winappsdk)
target_sources(MinWinUITest PRIVATE
               "main.cpp"
               "MainWindow.cpp"
               "MainWindow.h"
               "settings.manifest"
               "XamlApplication.cpp"
               "XamlApplication.h"
               "${cppwinrt_generated}"
               )
target_include_directories(MinWinUITest PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/generated")
target_include_directories(MinWinUITest PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_include_directories(MinWinUITest PRIVATE "${Microsoft_Windows_ImplementationLibrary_PATH}/include")
target_include_directories(MinWinUITest PRIVATE "${Microsoft_WindowsAppSDK_PATH}/include")
target_link_libraries(MinWinUITest PRIVATE "${Microsoft_WindowsAppSDK_PATH}/lib/win10-x64/Microsoft.WindowsAppRuntime.Bootstrap.lib")
target_precompile_headers(MinWinUITest PRIVATE pch.h)
add_custom_command(TARGET MinWinUITest
                   POST_BUILD
                   COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${Microsoft_WindowsAppSDK_PATH}/runtimes/win-x64/native/Microsoft.WindowsAppRuntime.Bootstrap.dll" "$<TARGET_FILE_DIR:MinWinUITest>")
