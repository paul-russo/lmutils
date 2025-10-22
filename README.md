# zfns

Small ZSH utility scripts designed to be installed via zinit.

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

**Requirements:**
- llm CLI tool with Anthropic API key set (`llm keys set anthropic`)
- jq for JSON processing
