# Merge multiple .winmd files
include_guard()

include(require_arguments)
include(sdk_buildtools)
find_sdk_buildtool(MDMERGE mdmerge REQUIRED)

# Merge multiple .winmd files
#
# TARGET - Target for .winmd merging
# OUTDIR - Output directory
# NAMESPACE - Namespace of declarations in .winmds
# IN - .winmds to merge
# REF - Reference .winmd files to use
function(merge_winmds)
    cmake_parse_arguments(merge_winmds "" "TARGET;OUTDIR;NAMESPACE;WINSDK_VERSION;PCH" "IN;REF" ${ARGV})
    # WINSDK_VERSION, PCH are unused and only here so "common arguments" can be added
    require_arguments(merge_winmds TARGET OUTDIR NAMESPACE)

    set(winmd_ref_paths "")
    foreach(ref_path IN LISTS merge_winmds_REF)
        cmake_path(GET ref_path PARENT_PATH ref_path)
        cmake_path(CONVERT "${ref_path}" TO_NATIVE_PATH_LIST ref_path_native)
        list(APPEND winmd_ref_paths "${ref_path_native}")
    endforeach()
    # mdmerge produces errors if duplicate metadata_dirs are passed
    list(REMOVE_DUPLICATES winmd_ref_paths)
    set(winmd_args "")
    foreach(ref_path IN LISTS winmd_ref_paths)
        set(winmd_args "${winmd_args} -metadata_dir \"${ref_path}\"")
    endforeach()
    foreach(in_path IN LISTS merge_winmds_IN)
        set(winmd_args "${winmd_args} -i \"${in_path}\"")
    endforeach()
    set(outfile "${merge_winmds_OUTDIR}/${merge_winmds_NAMESPACE}.winmd")
    add_custom_command(OUTPUT "${outfile}"
                       COMMAND "${MDMERGE}" -o "${merge_winmds_OUTDIR}" ${winmd_args} -partial -n:1
                       DEPENDS ${merge_winmds_IN})
    add_custom_target(${merge_winmds_TARGET}
                      DEPENDS "${outfile}")
endfunction(merge_winmds)
