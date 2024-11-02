# Generate XamlMetaDataProvider files
include_guard()

include(require_arguments)

# Generate XamlMetaDataProvider files
#
# OUTDIR - Output directory
# IDL_VAR - Variable to receive path of generated .idl
# CPP_VAR - Variable to receive path of generated .cpp
# PCH - Precompiled header (included in .cpp)
# NAMESPACE - XAML namespace (used in .idl)
function(generate_XamlMetaDataProvider)
    cmake_parse_arguments(generate "" "OUTDIR;IDL_VAR;CPP_VAR;PCH;NAMESPACE;WINSDK_VERSION" "" ${ARGV})
    # WINSDK_VERSION is unused and only here so "common arguments" can be added
    require_arguments(generate OUTDIR IDL_VAR CPP_VAR NAMESPACE)

    set(NAMESPACE "${generate_NAMESPACE}")
    set(XAML_NAMESPACE "Microsoft.UI.Xaml")
    if(generate_PCH)
        set(XAML_META_DATA_PROVIDER_PCH "#include \"${generate_PCH}\"")
    endif()

    set(out_idl "${generate_OUTDIR}/XamlMetaDataProvider.idl")
    set(out_cpp "${generate_OUTDIR}/XamlMetaDataProvider.cpp")
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/XamlMetaDataProvider.idl.template" "${out_idl}" @ONLY)
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/XamlMetaDataProvider.cpp.template" "${out_cpp}" @ONLY)

    set_source_files_properties("${out_idl}" PROPERTIES GENERATED ON)
    set_source_files_properties("${out_cpp}" PROPERTIES GENERATED ON)

    set(${generate_IDL_VAR} "${out_idl}" PARENT_SCOPE)
    set(${generate_CPP_VAR} "${out_cpp}" PARENT_SCOPE)
endfunction()
