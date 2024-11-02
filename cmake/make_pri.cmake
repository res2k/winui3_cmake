# Generate a .pri file from a list of files
include_guard()

include(sdk_buildtools)
find_sdk_buildtool(MAKEPRI makepri REQUIRED)

# Helper: Generate file with each item in LIST being a separate line
function(_file_generate_from_list FILE LIST)
    list(JOIN LIST "\n" joined)
    file(GENERATE OUTPUT "${FILE}" CONTENT "${joined}")
endfunction()

# Generate a .pri file
#
# OUTPUT - Name of .pri to generate
# DIRECTORY - Directory containing files to include in .pri
# FILES - Files include in .pri
function(make_pri)
    cmake_parse_arguments(makepri "" "OUTPUT;DIRECTORY" "FILES" ${ARGV})

    set(resfiles_path "${makepri_OUTPUT}.resfiles")
    _file_generate_from_list("${resfiles_path}" "${makepri_FILES}")

    set(priconfig_path "${makepri_OUTPUT}.xml")
    set(priconfig_contents "")
    list(APPEND priconfig_contents "<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    list(APPEND priconfig_contents "<resources targetOsVersion=\"10.0.0\" majorVersion=\"1\">")

    list(APPEND priconfig_contents "<index root=\"${makepri_DIRECTORY}\" startIndexAt=\"${resfiles_path}\">")
    list(APPEND priconfig_contents "<default>")
    list(APPEND priconfig_contents "<qualifier name=\"Language\" value=\"en-US\" />")
    list(APPEND priconfig_contents "<qualifier name=\"Contrast\" value=\"standard\" />")
    list(APPEND priconfig_contents "<qualifier name=\"Scale\" value=\"200\" />")
    list(APPEND priconfig_contents "<qualifier name=\"HomeRegion\" value=\"001\" />")
    list(APPEND priconfig_contents "<qualifier name=\"TargetSize\" value=\"256\" />")
    list(APPEND priconfig_contents "<qualifier name=\"LayoutDirection\" value=\"LTR\" />")
    list(APPEND priconfig_contents "<qualifier name=\"DXFeatureLevel\" value=\"DX9\" />")
    list(APPEND priconfig_contents "<qualifier name=\"Configuration\" value=\"\" />")
    list(APPEND priconfig_contents "<qualifier name=\"AlternateForm\" value=\"\" />")
    list(APPEND priconfig_contents "<qualifier name=\"Platform\" value=\"UAP\" />")
    list(APPEND priconfig_contents "</default>")
    list(APPEND priconfig_contents "<indexer-config type=\"RESFILES\" qualifierDelimiter=\".\" />")
    list(APPEND priconfig_contents "<indexer-config type=\"EMBEDFILES\" />")
    list(APPEND priconfig_contents "</index>")

    list(APPEND priconfig_contents "</resources>")
    _file_generate_from_list("${priconfig_path}" "${priconfig_contents}")

    set(depend_paths "")
    foreach(file ${makepri_FILES})
        list(APPEND depend_paths "${makepri_DIRECTORY}/${file}")
    endforeach()

    add_custom_command(OUTPUT "${makepri_OUTPUT}"
                       COMMAND powershell "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/wrap_makepri.ps1" "'${MAKEPRI}' new /cf '${priconfig_path}' /pr '${CMAKE_CURRENT_SOURCE_DIR}' /o /of '${makepri_OUTPUT}'"
                       DEPENDS ${depend_paths}
                      )
endfunction()
