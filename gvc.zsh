gvc() {
  # Parse flags
  local no_push=false
  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        cat <<'EOF'
Usage: gvc [OPTIONS]

AI-powered git commit with automatic message generation (vibe commit).
Generates a commit message for staged changes using AI, prompts for approval,
commits, and pushes.

Options:
  -h, --help     Show this help message
  --no-push      Skip the git push step after committing

Examples:
  git add .
  gvc                  # Generate message, commit, and push
  gvc --no-push        # Generate message and commit without pushing

Requires:
  - command-line agent (default: agent -p). Override with LMUTILS_CMD (e.g., "llm")
EOF
        return 0
        ;;
      --no-push)
        no_push=true
        ;;
    esac
  done

  # Check for staged changes
  if git diff --cached --quiet; then
    echo "Error: No staged changes to commit"
    return 1
  fi

  # Generate commit message (prepend prompt)
  echo "Generating commit message..."
  local -a _lm_cmd=(${=LMUTILS_CMD:-agent -p})
  local system_prompt="Provide a one-line commit message for the following staged changes. Wrap your suggested commit message in <message> tags so it can be extracted.

Do not make any tool calls or perform any searches unless absolutely necessary to create a good commit message. Respond quickly using only the diff provided.

Example:
<message>Add user authentication module</message>"
  local response
  response=$({ echo "$system_prompt"; echo; git diff --staged } | "${_lm_cmd[@]}")

  if [[ $? -ne 0 ]] || [[ -z "$response" ]]; then
    echo "Error: Failed to generate commit message"
    return 1
  fi

  # Extract message from <message> tags
  local message=""
  if [[ "$response" == *"<message>"*"</message>"* ]]; then
    message="${response#*<message>}"
    message="${message%%</message>*}"
    message="${message##[[:space:]]##}"
    message="${message%%[[:space:]]##}"
  fi
  if [[ -z "$message" ]]; then
    message="$response"
  fi

  # Display message and prompt for approval
  local color_yellow="\033[1;33m"
  local color_reset="\033[0m"
  while true; do
    echo "\nSuggested commit message:"
    echo "  ${color_yellow}${message}${color_reset}"
    echo -n "\nCommit with this message? (\033[1my\033[0mes/\033[1mn\033[0mo/\033[1me\033[0mdit): "
    read -r response

    # Get first character of response (case-insensitive)
    local first_char="${response:0:1}"
    first_char="${first_char:l}"  # Convert to lowercase

    if [[ "$first_char" == "n" ]]; then
      echo "Commit aborted"
      return 0
    elif [[ "$first_char" == "e" ]]; then
      local tmpfile
      tmpfile=$(mktemp)
      echo "$message" > "$tmpfile"
      ${EDITOR:-vi} "$tmpfile"
      message=$(cat "$tmpfile")
      rm "$tmpfile"
      # Continue loop to show new message and prompt again
    elif [[ "$first_char" == "y" ]]; then
      break
    else
      echo "Please answer yes, no, or edit."
    fi
  done

  # Commit
  git commit -m "$message"
  if [[ $? -ne 0 ]]; then
    echo "Error: Commit failed"
    return 1
  fi

  # Push (unless --no-push flag)
  if [[ "$no_push" == false ]]; then
    git push
  fi
}
