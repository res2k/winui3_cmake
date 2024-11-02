include_guard()

# Helper: Check if we have a path to a NuGet package.
# Emit a message otherwise.
#
# PACKAGE_ID - ID of NuGet package to check for
function(check_nuget_package PACKAGE_ID)
    # FIXME: Avoid warning about the same missing package multiple times
    string(MAKE_C_IDENTIFIER "${PACKAGE_ID}" VARNAME)
    set(VARNAME "${VARNAME}_PATH")
    if(NOT ${VARNAME})
        set(msg "No path for ${PACKAGE_ID} NuGet package.\n* Does it appear in packages.config?\n* Did you call nuget_install()?")
        if(REQUIRED IN_LIST ARGV)
            message(FATAL_ERROR "${msg}")
        else()
            message(WARNING "${msg}")
        endif()
    endif()
endfunction()
