# AGENTS.md

## Repository Purpose

This repository contains small ZSH utility scripts designed to be installed via zinit. The scripts provide reusable functions for CLI workflows.

## Architecture

### Zinit Installation Pattern

This repo follows zinit plugin conventions:
- Functions should be in `.zsh` files in the root directory or organized in subdirectories
- Zinit will source these files when the plugin is loaded
- Users install with: `zinit light paul-russo/lmutils`

### File Organization

- Individual utility functions should be in separate `.zsh` files or grouped logically
- Each function file should be self-contained and independently sourceable
- Function names should be descriptive and avoid conflicts with common commands
