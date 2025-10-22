ctok() {
    local model="claude-sonnet-4-5-20250929"
    local model_query=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--model)
                model_query="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # If model query specified, fuzzy match it
    if [[ -n "$model_query" ]]; then
        model=$(llm models list -q anthropic | grep -i "$model_query" | tail -1 | awk '{print $3}' | sed 's/^anthropic\///')
        if [[ -z "$model" ]]; then
            echo "No model matching '$model_query' found" >&2
            return 1
        fi
    fi

    # Check if stdin is a terminal (no pipe) or if we should read from stdin
    local input=""
    if [[ ! -t 0 ]]; then
        input=$(cat)
    fi

    # Show usage if no input
    if [[ -z "$input" ]]; then
        cat <<'EOF'
Usage: ctok [OPTIONS]

Count tokens in text using Anthropic's token counting API.
Reads text from stdin.

Options:
  -m, --model MODEL    Specify model to count tokens for (fuzzy match)
                       Default: claude-sonnet-4-5-20250929

Examples:
  echo "Hello world" | ctok
  cat file.txt | ctok
  ctok -m opus < input.txt
  ctok --model haiku <<< "Short text"

Requires:
  - llm CLI tool with Anthropic API key set (llm keys set anthropic)
  - jq for JSON processing
EOF
        return 0
    fi

    # Get API key
    local api_key=$(llm keys get anthropic 2>/dev/null)
    if [[ -z "$api_key" ]]; then
        echo "No Anthropic API key found. Set it with: llm keys set anthropic" >&2
        return 1
    fi

    # Build JSON request
    local json_payload=$(jq -n \
        --arg model "$model" \
        --arg system "$input" \
        '{
            model: $model,
            system: $system,
            messages: [{role: "user", content: "."}]
        }')

    # Call API
    local response=$(curl -s https://api.anthropic.com/v1/messages/count_tokens \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "$json_payload")

    # Parse and output token count
    local token_count=$(echo "$response" | jq -r '.input_tokens')

    if [[ "$token_count" == "null" ]] || [[ -z "$token_count" ]]; then
        echo "Error counting tokens: $(echo "$response" | jq -r '.error.message // "Unknown error"')" >&2
        return 1
    fi

    echo "$token_count"
}
