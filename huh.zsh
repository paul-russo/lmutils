huh() {
    local -a files=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat <<'EOF'
Usage: huh <file> [file...]

Summarize the contents of one or more files using AI.

Arguments:
  file    Path(s) to the file(s) to summarize

Options:
  -h, --help    Show this help message

When multiple files are provided, outputs an overall summary followed by
individual summaries for each file under headers.

Examples:
  huh README.md
  huh src/main.py
  huh *.zsh
  huh src/api.py src/models.py src/utils.py

Requires:
  - command-line agent (default: agent -p). Override with LMUTILS_CMD (e.g., "llm")
EOF
                return 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use 'huh --help' for usage information" >&2
                return 1
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # Check if any files provided
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "Error: No file specified" >&2
        echo "Use 'huh --help' for usage information" >&2
        return 1
    fi

    # Validate all files exist and are readable
    for file_path in "${files[@]}"; do
        if [[ ! -f "$file_path" ]]; then
            echo "Error: File not found: $file_path" >&2
            return 1
        fi
        if [[ ! -r "$file_path" ]]; then
            echo "Error: Cannot read file: $file_path" >&2
            return 1
        fi
    done

    # Single file case - simpler prompt (prepend)
    if [[ ${#files[@]} -eq 1 ]]; then
        local -a _lm_cmd=(${=LMUTILS_CMD:-agent -p})
        local filename=$(basename "${files[1]}")
        local system_prompt="Summarize the following file ($filename). Provide a concise summary of what this file contains, its purpose, and key details. Keep the summary brief but informative."
        { echo "$system_prompt"; echo; cat "${files[1]}" } | "${_lm_cmd[@]}"
        return 0
    fi

    # Multiple files - build combined input
    local combined=""
    for file_path in "${files[@]}"; do
        local filename=$(basename "$file_path")
        combined+="=== FILE: $filename ===
"
        combined+="$(cat "$file_path")"
        combined+="

"
    done

    # Build file list for prompt
    local file_list=""
    for file_path in "${files[@]}"; do
        file_list+="- $(basename "$file_path")
"
    done

    # Summarize with multi-file prompt (prepend)
    local -a _lm_cmd=(${=LMUTILS_CMD:-agent -p})
    local system_prompt="You are summarizing multiple files. The files are:
$file_list
First, provide an **Overall Summary** that describes the common themes, patterns, or relationships between these files.

Then, provide individual summaries for each file under a markdown header with the filename (e.g., ## filename.ext).

Keep summaries concise but informative."
    { echo "$system_prompt"; echo; echo "$combined" } | "${_lm_cmd[@]}"
}
