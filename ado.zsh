ado() {
    local -a args=()
    local no_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat <<'EOF'
Usage: ado <request>

Generate a command suggestion based on a natural language request using AI.

Arguments:
  request    Natural language description of what command you want to run

Options:
  -h, --help       Show this help message
  --no-run         Print the command instead of running it

The tool will analyze your request and suggest an appropriate command to run.
If multiple valid approaches exist, you will be presented with all options and can select one.

Examples:
  ado resize an image to half size
  ado find all python files modified in the last week
  ado convert a video to mp4 format
  ado list all running docker containers
  ado --no-run resize an image to half size

Requires:
  - llm CLI tool with an API key configured
EOF
                return 0
                ;;
            --no-run)
                no_run=true
                shift
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use 'ado --help' for usage information" >&2
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
        echo "Error: No request specified" >&2
        echo "Use 'ado --help' for usage information" >&2
        return 1
    fi

    # Join all arguments into a single request string
    local request="${args[*]}"

    # System prompt instructing the LLM to wrap the command in XML tags
    local system_prompt="You are a command-line assistant. The user will describe what they want to do, and you should suggest an appropriate command to accomplish that task. 

Your response should contain ONLY the suggested command(s) wrapped in <suggestion> tags. Do not include any explanation, commentary, or additional text outside the tags.

Each <suggestion> tag must include a brief description attribute that explains what the command does or why this approach was chosen.

If there are multiple valid approaches or the request could be interpreted in different ways, you may provide multiple suggestions, each wrapped in its own <suggestion> tags.

Example format (single suggestion):
<suggestion description=\"Resize image using ImageMagick convert command\">convert input.jpg -resize 50% output.jpg</suggestion>

Example format (multiple suggestions):
<suggestion description=\"Resize image using ImageMagick convert command\">convert input.jpg -resize 50% output.jpg</suggestion>
<suggestion description=\"Resize image using ImageMagick magick command (newer syntax)\">magick input.jpg -resize 50% output.jpg</suggestion>

If the request is unclear or ambiguous, provide the most likely command(s) the user wants, still wrapped in <suggestion> tags with description attributes."

    # Call LLM with system prompt and user request
    local response
    response=$(echo "$request" | llm --system "$system_prompt")

    if [[ $? -ne 0 ]] || [[ -z "$response" ]]; then
        echo "Error: Failed to generate command suggestion" >&2
        return 1
    fi

    # Extract all commands and descriptions from <suggestion> tags
    local -a commands=()
    local -a descriptions=()
    
    # Use a more reliable extraction method
    # Extract tags using grep and then parse with sed/pattern matching
    local -a suggestion_tags=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && suggestion_tags+=("$line")
    done < <(echo "$response" | grep -o '<suggestion[^>]*>.*</suggestion>')
    
    # Parse each suggestion tag
    for suggestion_tag in "${suggestion_tags[@]}"; do
        [[ -z "$suggestion_tag" ]] && continue
        
        # Extract description attribute using sed (more reliable than zsh regex)
        local description=""
        # Try double quotes first - extract everything between the quotes
        description=$(echo "$suggestion_tag" | sed -n 's/.*description="\([^"]*\)".*/\1/p')
        # If empty, try single quotes
        if [[ -z "$description" ]]; then
            description=$(echo "$suggestion_tag" | sed -n "s/.*description='\([^']*\)'.*/\1/p")
        fi
        
        # Extract command content (text between > and </suggestion>)
        local command=""
        command=$(echo "$suggestion_tag" | sed -n 's/.*>\(.*\)<\/suggestion>/\1/p')
        
        # Only add if we have a command
        if [[ -n "$command" ]]; then
            commands+=("$command")
            descriptions+=("${description:-}")
        fi
    done
    
    # Fallback: if no tags found, try a manual extraction approach
    # This handles cases where grep might not capture the full tag
    if [[ ${#commands[@]} -eq 0 ]]; then
        local remaining="$response"
        while [[ "$remaining" == *"<suggestion"* ]]; do
            # Find the start of a suggestion tag
            local after_start="${remaining#*<suggestion}"
            
            # Extract everything up to the closing tag
            local tag_content="${after_start%%</suggestion>*}"
            
            # Find the opening tag's end (first >)
            local before_gt="${tag_content%%>*}"
            local after_gt="${tag_content#*>}"
            
            # Extract attributes (everything between <suggestion and >)
            local attrs="$before_gt"
            
            # Extract command content (everything after >)
            local command="$after_gt"
            
            # Extract description from attributes using sed
            local description=""
            description=$(echo "$attrs" | sed -n 's/.*description="\([^"]*\)".*/\1/p')
            if [[ -z "$description" ]]; then
                description=$(echo "$attrs" | sed -n "s/.*description='\([^']*\)'.*/\1/p")
            fi
            
            if [[ -n "$command" ]]; then
                commands+=("$command")
                descriptions+=("${description:-}")
            fi
            
            # Move past this tag
            remaining="${remaining#*</suggestion>}"
        done
    fi

    # If no tags found, fallback to raw response
    if [[ ${#commands[@]} -eq 0 ]]; then
        echo "$response"
        return 0
    fi

    # If only one suggestion, show it and ask for confirmation before running
    if [[ ${#commands[@]} -eq 1 ]]; then
        local cmd="${commands[1]}"
        local desc="${descriptions[1]}"
        local color_reset="\033[0m"
        local color_command="\033[1;36m"  # Bright cyan/bold
        local color_description="\033[1;90m"  # Bright gray
        
        if [[ -n "$desc" ]]; then
            echo "${color_command}${cmd}${color_reset}"
            echo "${color_description}${desc}${color_reset}"
        else
            echo "${color_command}${cmd}${color_reset}"
        fi
        if [[ "$no_run" == true ]]; then
            # Just output the command
            echo "$cmd"
            return 0
        fi
        
        echo ""
        echo -n "Run this command? (\033[1my\033[0mes/\033[1mn\033[0mo): "
        read -r response
        
        # Get first character of response (case-insensitive)
        local first_char="${response:0:1}"
        first_char="${first_char:l}"  # Convert to lowercase
        
        if [[ "$first_char" != "y" ]]; then
            echo "Cancelled"
            return 0
        fi
        
        eval "$cmd"
        return $?
    fi

    # Multiple suggestions - present them and let user pick
    # Define colors (using ANSI escape codes)
    local color_reset="\033[0m"
    local color_command="\033[1;36m"  # Bright cyan/bold
    local color_description="\033[1;90m"  # Bright gray
    
    echo "Multiple suggestions found:"
    echo ""
    local i=1
    for idx in {1..${#commands[@]}}; do
        local desc="${descriptions[$idx]}"
        local cmd="${commands[$idx]}"
        if [[ -n "$desc" ]]; then
            echo "  $i) ${color_command}${cmd}${color_reset}"
            echo "     ${color_description}${desc}${color_reset}"
        else
            echo "  $i) ${color_command}${cmd}${color_reset}"
        fi
        ((i++))
    done
    echo ""
    echo -n "Select a command (1-${#commands[@]}) or 'q' to quit: "
    read -r selection

    # Handle quit
    if [[ "$selection" == "q" ]] || [[ "$selection" == "Q" ]]; then
        echo "Cancelled"
        return 0
    fi

    # Validate selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#commands[@]} ]]; then
        echo "Invalid selection" >&2
        return 1
    fi

    # Get the selected command
    local selected_cmd="${commands[$selection]}"
    
    # Execute or output the selected command
    if [[ "$no_run" == true ]]; then
        # Just output the command
        echo "$selected_cmd"
        return 0
    fi
    
    # Execute the selected command
    eval "$selected_cmd"
    return $?
}
