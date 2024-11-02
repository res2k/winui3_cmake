# Generate header(s) for WinAppSDK
include_guard()

include(find_appsdk_winmds)
include(find_platform_winmds)
include(run_cppwinrt)

# Generate header(s) for WinAppSDK
#
# TARGET - Target for header generation
# OUT - Output directory
# WINSDK_VERSION - SDK version to use .winmds from
# WINMDS - Variable receiving .winmds headers were generated from
function(generate_winappsdk)
    cmake_parse_arguments(generate_was "" "TARGET;OUT;WINSDK_VERSION;WINMDS;NAMESPACE;PCH" "" ${ARGV})
    # NAMESPACE, PCH are unused and only here so "common arguments" can be added
    require_arguments(generate_was TARGET OUT WINSDK_VERSION WINMDS)

    find_platform_winmds(PATHS_VAR PLATFORM_WINMD_PATHS WINSDK_VERSION ${generate_was_WINSDK_VERSION})

    set(WINAPPSDK_WINMDS
        Microsoft.Foundation
        Microsoft.Graphics
        Microsoft.UI.Text
        Microsoft.UI
        Microsoft.UI.Xaml
        Microsoft.Windows.ApplicationModel.DynamicDependency
        Microsoft.Windows.ApplicationModel.Resources
        Microsoft.Windows.ApplicationModel.WindowsAppRuntime
        Microsoft.Windows.AppLifecycle
        Microsoft.Windows.AppNotifications.Builder
        Microsoft.Windows.AppNotifications
        Microsoft.Windows.Management.Deployment
        Microsoft.Windows.PushNotifications
        Microsoft.Windows.Security.AccessControl
        Microsoft.Windows.System.Power
        Microsoft.Windows.System
        Microsoft.Windows.Widgets
        )

    find_appsdk_winmds(PATHS_VAR WINAPPSDK_WINMD_PATHS WINSDK_VERSION ${generate_was_WINSDK_VERSION} PACKAGES ${WINAPPSDK_WINMDS})

    set(WEBVIEW2_WINMD_PATHS
        "${Microsoft_Web_WebView2_PATH}/lib/Microsoft.Web.WebView2.Core.winmd"
        )

    run_cppwinrt(TARGET ${generate_was_TARGET}_platform OUT "${generate_was_OUT}" IN ${PLATFORM_WINMD_PATHS})
    run_cppwinrt(TARGET ${generate_was_TARGET}_webview2 OUT "${generate_was_OUT}" IN ${WEBVIEW2_WINMD_PATHS} REF ${PLATFORM_WINMD_PATHS})
    add_dependencies(${generate_was_TARGET}_webview2 ${generate_was_TARGET}_platform)
    run_cppwinrt(TARGET ${generate_was_TARGET} OUT "${generate_was_OUT}" IN ${WINAPPSDK_WINMD_PATHS} REF ${PLATFORM_WINMD_PATHS} ${WEBVIEW2_WINMD_PATHS})
    add_dependencies(${generate_was_TARGET} ${generate_was_TARGET}_platform ${generate_was_TARGET}_webview2)

    set(winmds "")
    list(APPEND winmds ${WINAPPSDK_WINMD_PATHS} ${PLATFORM_WINMD_PATHS} ${WEBVIEW2_WINMD_PATHS})
    set(${generate_was_WINMDS} "${winmds}" PARENT_SCOPE)
endfunction()
