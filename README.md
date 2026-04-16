# ai-kit

Multi-agent collaboration plugin for AI coding tools — spec-driven workflow via tmux.

## Overview

ai-kit coordinates multiple AI agents (Claude Code, Codex, OpenCode, etc.) working in separate tmux panes through a structured spec-driven workflow. Instead of ad-hoc communication, agents exchange structured messages with task labels and feedback tags, creating a traceable collaboration loop.

```
┌─────────────┐    task from     ┌─────────────┐
│  Agent A     │ ───────────────→ │  Agent B     │
│  (Designer)  │                  │  (Implementer)│
│              │ ←─────────────── │              │
└─────────────┘  feedback from   └─────────────┘
                  ┌─────────────┐
                  │  Agent C     │
                  │  (Reviewer)  │
                  └─────────────┘
```

## Installation

### Claude Code

Register this repository as a plugin marketplace, then install:

```
/plugin marketplace add fingergohappy/ai-kit
```

Install the plugin:

```
/plugin install ai-kit@ai-kit
```

After installation, restart Claude Code. Skills will be available with the `ai-kit:` prefix:

```
/ai-kit:spec-feature login-system
/ai-kit:spec-implement docs/spec/login_feature.md
```

<details>
<summary>Alternative: local development</summary>

```bash
claude --plugin-dir /path/to/ai-kit
```

</details>

### Codex (OpenAI)

Use the built-in `$skill-installer` inside Codex to install from GitHub:

```
$skill-installer install https://github.com/fingergohappy/ai-kit/tree/main/skills/spec-feature
```

Repeat for each skill you need, or install all at once by cloning:

```bash
# User scope (available across all projects)
git clone https://github.com/fingergohappy/ai-kit.git ~/.agents/skills/ai-kit

# Project scope (shared with team)
git clone https://github.com/fingergohappy/ai-kit.git .agents/skills/ai-kit
```

After installation, restart Codex. Skills auto-discover on startup and can be invoked by name:

```
$spec-feature login-system
$spec-implement docs/spec/login_feature.md
```

## Skills

| Skill | Purpose |
|-------|---------|
| `ai-kit:spec-feature` | Generate feature design documents from discussions |
| `ai-kit:spec-change` | Generate change documents for refactoring/modifications |
| `ai-kit:spec-implement` | Dispatch tasks to a remote agent's tmux pane |
| `ai-kit:spec-review` | Review code against design documents |
| `ai-kit:spec-feedback` | Send execution results back to the task originator |
| `ai-kit:spec-handle-feedback` | Process feedback, trigger review, and decide next steps |
| `ai-kit:spec-check-review` | Verify review document accuracy and fix code |
| `ai-kit:spec-fix-review` | Send review document to another agent for verification and fix |
| `ai-kit:tmux-send` | Send text content to a tmux pane |
| `ai-kit:rebase-to-root` | Rebase worktree feature branch back to root's current branch |

## Workflow

### 1. Design Phase

```
/ai-kit:spec-feature <feature-name>   # or /ai-kit:spec-change <change-name>
```

Enter design discussion mode — discuss without writing code, generate document when ready.

### 2. Implementation Phase

```
/ai-kit:spec-implement <doc-path>
```

Send the design document to another agent's tmux pane. The receiving agent gets a `[task from ...]` labeled message with clear instructions and a feedback directive.

### 3. Feedback Loop

The implementer completes work and calls `ai-kit:spec-feedback` to send results back:

```
[feedback from Claude Code: implemented 3 tasks, pane_id: %5]
```

### 4. Review & Fix

The originator receives feedback and `ai-kit:spec-handle-feedback` triggers automatically:

- Calls `ai-kit:spec-review` to review the code
- If issues found → sends fix tasks back via `ai-kit:spec-implement` (up to 3 rounds)
- If all passed → done

```
/ai-kit:spec-fix-review <review-doc>   # Send review to another agent for fix
```

## Message Protocol

### Task Dispatch

```
[task from {agent-name}: {task-summary}, pane_id: {pane_id}]
```

### Execution Feedback

```
[feedback from {agent-name}: {result-summary}, pane_id: {pane_id}]
```

Agents use these tags to identify message types and route responses correctly.

## Requirements

- tmux session with multiple panes
- AI coding tool running in each pane (Claude Code, Codex, OpenCode, etc.)
- `ai-kit:tmux-send` skill available for inter-pane communication

### rebase-to-root

No extra dependencies — uses native `git worktree` and `git rebase` commands (requires git 2.5+).

Usage:

```
/ai-kit:rebase-to-root                    # auto-detect current worktree
/ai-kit:rebase-to-root my-feature         # specify feature name
```

## License

MIT
