gvc() {
  # Parse flags
  local no_push=false
  for arg in "$@"; do
    if [[ "$arg" == "--no-push" ]]; then
      no_push=true
    fi
  done

  # Check for staged changes
  if git diff --cached --quiet; then
    echo "Error: No staged changes to commit"
    return 1
  fi

  # Generate commit message
  echo "Generating commit message..."
  local message
  message=$(git diff --staged | llm --system 'please write a one-line commit message for these changes')

  if [[ $? -ne 0 ]] || [[ -z "$message" ]]; then
    echo "Error: Failed to generate commit message"
    return 1
  fi

  # Display message and prompt for approval
  while true; do
    echo "\nSuggested commit message:"
    echo "  $message"
    echo -n "\nCommit with this message? (y/n/e): "
    read -r response

    if [[ "$response" == "n" ]]; then
      echo "Commit aborted"
      return 0
    elif [[ "$response" == "e" ]]; then
      local tmpfile
      tmpfile=$(mktemp)
      echo "$message" > "$tmpfile"
      ${EDITOR:-vi} "$tmpfile"
      message=$(cat "$tmpfile")
      rm "$tmpfile"
      # Continue loop to show new message and prompt again
    elif [[ "$response" == "y" ]]; then
      break
    else
      echo "Please answer y, n, or e."
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
