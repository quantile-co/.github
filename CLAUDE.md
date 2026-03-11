# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Repository Purpose

This is the `.github` organization profile repository for quantile-co. It
contains the organization profile README displayed on the GitHub organization
page.

## Structure

```text
profile/
└── README.md       # Organization profile (displayed at github.com/quantile-co)
```

## Development

This repo uses:

- **Nix** for reproducible development environment
- **direnv** for automatic environment activation
- **lefthook** for Git hooks
- **Task** for task automation

### Setup

```bash
direnv allow  # Activate Nix development shell
```

### Tasks

```bash
task --list   # Show all available tasks
```

## Static Analysis

Pre-push hooks run automatically via lefthook:

- Markdown linting (markdownlint-cli2)
- Editor config checking (editorconfig-checker)
- File sorting (keep-sorted)

Run all checks manually:

```bash
task analyze:check
```

Auto-fix issues:

```bash
task analyze:fix
```

## Philosophy

Keep this repo minimal - it's just for the organization profile README.
