# Translate CMAKE_(HOST_)SYSTEM_PROCESSOR values to "arch" names used by Windows SDK & friends
include_guard()

# Translate a value of CMAKE_(HOST_)SYSTEM_PROCESSOR to an "arch" name
# used by Windows SDK & friends for directory names.
#
# VAR - Variable to receive translated "arch"
# PROCESSOR - "Processor" value to translate
function(translate_system_processor VAR PROCESSOR)
    if(PROCESSOR MATCHES "[xX]86")
        set(arch "x86")
    elseif(PROCESSOR MATCHES "[aA][mM][dD]64" OR PROCESSOR MATCHES "[xX]64")
        set(arch "x64")
    else()
        message(FATAL_ERROR "Unknown PROCESSOR ${PROCESSOR}, please fix")
    endif()
    set(${VAR} "${arch}" PARENT_SCOPE)
endfunction()

# Convenience: get value of CMAKE_SYSTEM_PROCESSOR as "arch" name
# used by Windows SDK & friends for directory names.
#
# VAR - Variable to receive translated "arch"
function(get_system_arch_name VAR)
    translate_system_processor(${VAR} "${CMAKE_SYSTEM_PROCESSOR}")
    set(${VAR} "${${VAR}}" PARENT_SCOPE)
endfunction()

# Convenience: get value of CMAKE_HOST_SYSTEM_PROCESSOR as "arch" name
# used by Windows SDK & friends for directory names.
#
# VAR - Variable to receive translated "arch"
function(get_host_system_arch_name VAR)
    translate_system_processor(${VAR} "${CMAKE_HOST_SYSTEM_PROCESSOR}")
    set(${VAR} "${${VAR}}" PARENT_SCOPE)
endfunction()
