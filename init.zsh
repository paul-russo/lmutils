# Source all utility functions
for script in ${0:h}/*.zsh(N); do
  [[ $script != */init.zsh ]] && source $script
done
