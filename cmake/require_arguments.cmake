# Helper: Check for "required" function arguments
include_guard()

# Helper: Check for "required" function arguments
#
# PREFIX - prefix passed to cmake_parse_arguments()
# extra arguments - names of required arguments
macro(require_arguments PREFIX)
    set(_require_arguments_argn "${ARGN}")
    foreach(arg IN LISTS _require_arguments_argn)
        if(NOT ${PREFIX}_${arg})
            message(FATAL_ERROR "${arg} not set")
        endif()
    endforeach()
endmacro()
