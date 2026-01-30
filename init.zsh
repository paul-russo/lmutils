# Configurable command-line agent - override with LMUTILS_CMD (e.g., "llm" or "agent -p")
: ${LMUTILS_CMD:=agent -p}

# Source all utility functions
for script in ${0:h}/*.zsh(N); do
  [[ $script != */init.zsh ]] && source $script
done
