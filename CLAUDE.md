# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Tools

- Runtime: Bun 1.2.11

## Common Development Tasks

### Available npm/bun scripts from package.json:

```bash
# Test
bun test

# Type checking
bun run typecheck

# Formatting
bun run format          # Format code with prettier
bun run format:check    # Check code formatting

# Install git hooks
bun run install-hooks
```

## Architecture Overview

This is a GitHub Action that enables Claude to interact with GitHub PRs and issues. It's a fork of the official Claude Code Action with added OAuth authentication support for Claude Max subscribers.

### Action Workflow

1. **Trigger Detection**: Validates human actor and checks for `@claude` mentions (customizable via `trigger_phrase`) or issue assignments
2. **Permission Validation**: Ensures write permissions for the repository
3. **Comment Creation**: Posts initial tracking comment with progress checkboxes
4. **Branch Management**: 
   - Issues: Always creates new branch
   - Open PRs: Pushes to existing branch  
   - Closed PRs: Creates new branch
5. **Context Gathering**: Fetches PR/issue data, comments, files, and reviews
6. **Prompt Generation**: Creates detailed prompt with context and instructions
7. **Claude Execution**: Runs Claude with configured tools and model
8. **Result Updates**: Updates comment with final results and job links

### Key Components

#### Entry Points (`src/entrypoints/`)
- `prepare.ts`: Main orchestrator for the GitHub Action workflow
- `update-comment-link.ts`: Updates comments with job links post-execution

#### GitHub Integration (`src/github/`)
- **API**: Octokit-based client with OIDC token exchange
- **Context**: Parses GitHub event payloads
- **Data**: 
  - `fetcher.ts`: Retrieves PR/issue data, comments, reviews
  - `formatter.ts`: Formats GitHub data for prompt generation
- **Operations**: 
  - Branch creation and management
  - Comment creation and updates with progress tracking
- **Validation**: Human actor verification, permissions, trigger checking

#### Prompt Creation (`src/create-prompt/`)
- Generates context-rich prompts for different event types
- Manages allowed/disallowed tools configuration
- Includes repository-specific instructions from CLAUDE.md

#### MCP Server (`src/mcp/`)
- GitHub file operations server for extended functionality
- Automatic installation and configuration

### Authentication Methods

- **Direct API**: Uses `ANTHROPIC_API_KEY`
- **OAuth**: For Claude Max subscribers (requires `claude_oauth_allowed_emails`)
- **AWS Bedrock**: Via `aws_iam_role` and cross-account assume
- **Google Vertex AI**: Via Workload Identity Federation

### Testing

Tests use Bun's built-in test runner. Key test files:
- `test/trigger-validation.test.ts`: Trigger phrase detection
- `test/permissions.test.ts`: Permission validation logic
- `test/branch-cleanup.test.ts`: Branch name sanitization
- `test/comment-logic.test.ts`: Comment creation/update logic
- `test/create-prompt.test.ts`: Prompt generation
- `test/data-formatter.test.ts`: GitHub data formatting

### Important Implementation Details

- Branch names are sanitized to be GitHub-compatible (alphanumeric, hyphens, underscores)
- Comments use a specific format with `<!-- claude-code:issue-comment:START -->` markers
- Progress is tracked with visual checkboxes that update in real-time
- The action supports custom model selection via `anthropic_model` input
- Tool availability can be controlled via `allowed_tools` and `disallowed_tools` inputs