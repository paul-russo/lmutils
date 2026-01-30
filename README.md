# lmutils

Some useful (to me) little ZSH functions that wrap the command-line agent.

## Prerequisites
- A command-line agent (default: `agent -p`). Override with `LMUTILS_CMD`.
- [jq](https://github.com/jqlang/jq) for JSON processing (for `ctok`)
- [llm](https://github.com/simonw/llm) with Anthropic API key for `ctok` (uses llm-specific subcommands for key/model lookup)

## Installation

```zsh
zinit light paul-russo/lmutils
```

## Configuration

Set `LMUTILS_CMD` to use a different command-line agent. Default is `agent -p`.

```zsh
export LMUTILS_CMD="llm"           # Use llm instead
export LMUTILS_CMD="agent -p"      # Explicit default
```

The command should read from stdin. The system prompt is prepended to the user message.

**Note:** `ctok` uses llm-specific subcommands (`llm keys get`, `llm models list`) and is not affected by `LMUTILS_CMD`.

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
- `-h, --help` - Show help message
- `--no-push` - Skip the git push step after committing

**Examples:**
```zsh
git add .
gvc                  # Generate message, commit, and push
gvc --no-push        # Generate message and commit without pushing
```

### huh

Summarize the contents of one or more files using AI.

**Usage:**
```
huh [OPTIONS] <file> [file...]
```

**Options:**
- `-h, --help` - Show help message

When multiple files are provided, outputs an overall summary followed by individual summaries for each file under headers.

**Examples:**
```zsh
huh README.md
huh src/main.py
huh *.zsh
huh src/api.py src/models.py src/utils.py
```

### ado

Generate a command suggestion based on a natural language request using AI.

**Usage:**
```
ado [OPTIONS] <request>
```

Takes a natural language description and suggests an appropriate command to accomplish the task. If multiple valid approaches exist, all options will be presented for selection. By default, the selected command will be executed after confirmation.

**Options:**
- `-h, --help` - Show help message
- `--no-run` - Print the command instead of running it

**Examples:**
```zsh
ado resize an image to half size
ado find all python files modified in the last week
ado convert a video to mp4 format
ado list all running docker containers
ado --no-run resize an image to half size
```

### qq

Quick query tool - a lightweight wrapper around an command-line agent that makes it easy to ask questions without wrapping input in quotes. Automatically instructs the model to provide concise responses.

**Usage:**
```
qq [OPTIONS] <message>
```

Takes all arguments as a single message and passes them to the command-line agent with a prepended system prompt requesting concise responses.

**Options:**
- `-h, --help` - Show help message
- `--model MODEL` - Pass through to command-line agent if supported (e.g., `llm`; `agent -p` may ignore)
- `--system PROMPT` - Override the default system prompt (prepended to your message)

**Examples:**
```zsh
qq explain how git rebase works
qq what is the difference between map and filter in javascript
qq write a function to sort an array
qq --model gpt-5.2 explain quantum computing
qq --model claude-opus-4.5 explain recursion
qq --system "Be verbose and detailed" explain how git works
```
