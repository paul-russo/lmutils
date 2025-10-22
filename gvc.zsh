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
  echo "\nSuggested commit message:"
  echo "  $message"
  echo -n "\nCommit with this message? (y/n): "
  read -r response

  if [[ "$response" != "y" ]]; then
    echo "Commit aborted"
    return 0
  fi

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
