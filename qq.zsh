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

Quick query tool - a lightweight wrapper around an command-line agent that makes it easy to ask
questions without wrapping input in quotes. The tool automatically instructs the model
to provide concise responses.

Arguments:
  message    Your question or request (all arguments are joined together)

Options:
  -h, --help           Show this help message
  --model MODEL        Pass through to command-line agent if supported (e.g., llm)
  --system PROMPT      Override the default system prompt (prepended to message)

Examples:
  qq explain how git rebase works
  qq what is the difference between map and filter in javascript
  qq write a function to sort an array
  qq --model gpt-5.2 explain quantum computing
  qq --model claude-opus-4.5 explain recursion
  qq --system "Be verbose and detailed" explain how git works

Requires:
  - command-line agent (default: agent -p). Override with LMUTILS_CMD (e.g., "llm")
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
    
    # Prepend system prompt
    local -a _lm_cmd=(${=LMUTILS_CMD:-agent -p})
    local -a llm_args=()
    if [[ -n "$model" ]]; then
        llm_args+=("--model" "$model")
    fi
    
    printf '%s\n\n%s' "$system_prompt" "$message" | "${_lm_cmd[@]}" "${llm_args[@]}"
}
