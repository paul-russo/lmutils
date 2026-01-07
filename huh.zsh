huh() {
    local file_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat <<'EOF'
Usage: huh <file>

Summarize the contents of a file using AI.

Arguments:
  file    Path to the file to summarize

Options:
  -h, --help    Show this help message

Examples:
  huh README.md
  huh src/main.py
  huh ~/Documents/notes.txt

Requires:
  - llm CLI tool with an API key configured
EOF
                return 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use 'huh --help' for usage information" >&2
                return 1
                ;;
            *)
                if [[ -z "$file_path" ]]; then
                    file_path="$1"
                else
                    echo "Error: Multiple files not supported" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Check if file path provided
    if [[ -z "$file_path" ]]; then
        echo "Error: No file specified" >&2
        echo "Use 'huh --help' for usage information" >&2
        return 1
    fi

    # Check if file exists
    if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found: $file_path" >&2
        return 1
    fi

    # Check if file is readable
    if [[ ! -r "$file_path" ]]; then
        echo "Error: Cannot read file: $file_path" >&2
        return 1
    fi

    # Get the filename for context
    local filename=$(basename "$file_path")

    # Summarize the file
    cat "$file_path" | llm --system "Summarize the following file ($filename). Provide a concise summary of what this file contains, its purpose, and key details. Keep the summary brief but informative."
}
