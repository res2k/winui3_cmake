# Misc. CMake JSON helpers
include_guard()

# Escape a string to JSON
function(json_string_escape VAR STR)
    # From https://gist.github.com/tniessen/77bd09fca3c15104d4bdfb4ec9f4ba1c
    string(JSON tmp_json SET "{}" "${STR}" "0")
    string(REGEX REPLACE "^\\{[ \t\r\n]*" "" tmp_json "${tmp_json}")
    string(REGEX REPLACE "[ \t\r\n]*:[ \t\r\n]*0[ \t\r\n]*\\}$" "" tmp_json "${tmp_json}")
    if(NOT "${tmp_json}" MATCHES "^\"[^\n]*\"")
        message(FATAL_ERROR "Internal error: unexpected output: '${tmp_json}'")
    endif()
    set(${VAR} "${tmp_json}" PARENT_SCOPE)
endfunction()

# "Create" an empty JSON object
function(json_obj_new JSON)
    set(${JSON} "{}" PARENT_SCOPE)
endfunction()

# Set a value in a JSON object
function(json_obj_set JSON KEY VALUE)
    string(JSON ${JSON} SET "${${JSON}}" "${KEY}" "${VALUE}")
    set(${JSON} "${${JSON}}" PARENT_SCOPE)
endfunction()

# Set a string value in a JSON object
function(json_obj_set_str JSON KEY VALUE)
    json_string_escape(value_escaped "${VALUE}")
    json_obj_set(${JSON} "${KEY}" "${value_escaped}")
    set(${JSON} "${${JSON}}" PARENT_SCOPE)
endfunction()

# "Create" an empty JSON array
function(json_array_new JSON)
    set(${JSON} "[]" PARENT_SCOPE)
endfunction()

# Append a value to a JSON array
function(json_array_append JSON VALUE)
    string(JSON ${JSON} SET "${${JSON}}" 999999999 "${VALUE}")
    set(${JSON} "${${JSON}}" PARENT_SCOPE)
endfunction()

# Append a string value to a JSON array
function(json_array_append_str JSON VALUE)
    json_string_escape(value_escaped "${VALUE}")
    json_array_append(${JSON} "${value_escaped}")
    set(${JSON} "${${JSON}}" PARENT_SCOPE)
endfunction()

# Do some tests if running with 'cmake -P'
if(CMAKE_SCRIPT_MODE_FILE)
    # Tests taken verbatim from https://gist.github.com/tniessen/77bd09fca3c15104d4bdfb4ec9f4ba1c
    function(test_str_equal DESCR ACTUAL EXPECTED)
        message(CHECK_START "Test ${DESCR}")
        if("${ACTUAL}" STREQUAL "${EXPECTED}")
            message(CHECK_PASS "pass")
        else()
            message(CHECK_FAIL "fail (expected ${EXPECTED}, got ${ACTUAL})")
        endif()
    endfunction()

    function(test_json_esc input expected_output)
        json_string_escape(actual_output "${input}")
        test_str_equal("JSON escaping: ${expected_output}" "${actual_output}" "${expected_output}")
    endfunction()

    test_json_esc("" "\"\"")
    test_json_esc("foo" "\"foo\"")
    test_json_esc("\"foo\"" "\"\\\"foo\\\"\"")
    test_json_esc("\"foo\n" "\"\\\"foo\\n\"")
    test_json_esc("\t.\r.\n.\"[]\\" "\"\\t.\\r.\\n.\\\"[]\\\\\"")
    test_json_esc(" abc def " "\" abc def \"")
    test_json_esc("{\"foo\": [\"bar\"]}" "\"{\\\"foo\\\": [\\\"bar\\\"]}\"")

    json_obj_new(json_empty)
    test_str_equal("json_obj_new" "${json_empty}" "{}")
    json_obj_new(json_int)
    json_obj_set(json_int "foo" "42")
    test_str_equal("json_obj_set with int" "${json_int}" "{\n  \"foo\" : 42\n}")
    json_obj_new(json_str)
    json_obj_set_str(json_str "foo" "42")
    test_str_equal("json_obj_set with string" "${json_str}" "{\n  \"foo\" : \"42\"\n}")
endif()
