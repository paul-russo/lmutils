# zfns

Some useful (to me) little ZSH functions that wrap the LLM CLI.

## Prerequisites
- [llm](https://github.com/simonw/llm) tool installed (with Anthropic API key set if you want to use `ctok`)
- [jq](https://github.com/jqlang/jq) for JSON processing

## Installation

```zsh
zinit light paul-russo/zfns
```

## Functions

### ctok

Count tokens in text using Anthropic's token counting API.

**Usage:**
```
ctok [OPTIONS]
```

Reads text from stdin.

**Options:**
- `-m, --model MODEL` - Specify model to count tokens for (fuzzy match)
  - Default: claude-sonnet-4-5-20250929

**Examples:**
```zsh
echo "Hello world" | ctok
cat file.txt | ctok
ctok -m opus < input.txt
ctok --model haiku <<< "Short text"
```

### gvc

AI-powered git commit with automatic message generation (vibe commit).

**Usage:**
```
gvc [OPTIONS]
```

Generates a commit message for staged changes using AI, prompts for approval, commits, and pushes.

**Options:**
- `--no-push` - Skip the git push step after committing

**Examples:**
```zsh
git add .
gvc                  # Generate message, commit, and push
gvc --no-push        # Generate message and commit without pushing
```
