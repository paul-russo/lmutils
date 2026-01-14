qq() {
    local -a args=()
    local model=""
    local system_prompt="Be very concise in your response. Provide only the essential information without unnecessary elaboration."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat <<'EOF'
Usage: qq [OPTIONS] <message>

Quick query tool - a lightweight wrapper around llm that makes it easy to ask questions
without wrapping input in quotes. The tool automatically instructs the model to provide
concise responses.

Arguments:
  message    Your question or request (all arguments are joined together)

Options:
  -h, --help           Show this help message
  --model MODEL        Specify the model to use
  --system PROMPT      Override the default system prompt

Examples:
  qq explain how git rebase works
  qq what is the difference between map and filter in javascript
  qq write a function to sort an array
  qq --model gpt-5.2 explain quantum computing
  qq --model claude-opus-4.5 explain recursion
  qq --system "Be verbose and detailed" explain how git works

Requires:
  - llm CLI tool with an API key configured
EOF
                return 0
                ;;
            --model)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --model requires a value" >&2
                    return 1
                fi
                model="$2"
                shift 2
                ;;
            --system)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --system requires a value" >&2
                    return 1
                fi
                system_prompt="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use 'qq --help' for usage information" >&2
                return 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    # Check if any arguments provided
    if [[ ${#args[@]} -eq 0 ]]; then
        echo "Error: No message specified" >&2
        echo "Use 'qq --help' for usage information" >&2
        return 1
    fi

    # Join all arguments into a single message
    local message="${args[*]}"
    
    # Build llm command arguments
    local -a llm_args=("--system" "$system_prompt")
    if [[ -n "$model" ]]; then
        llm_args+=("--model" "$model")
    fi
    
    # Call LLM with system prompt and user message
    echo "$message" | llm "${llm_args[@]}"
}
