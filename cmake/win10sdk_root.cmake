# Get path to Windows 10 SDK root
include_guard()

cmake_host_system_information(RESULT WIN10SDK_ROOT QUERY WINDOWS_REGISTRY "HKLM/SOFTWARE/Microsoft/Windows Kits/Installed Roots" VALUE "KitsRoot10")
