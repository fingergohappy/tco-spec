# ai-kit

Multi-agent collaboration plugin for AI coding tools — task-driven workflow via tmux.

## Overview

ai-kit coordinates multiple AI agents (Claude Code, Codex, OpenCode, etc.) working in separate tmux panes through a structured task-driven workflow. Instead of ad-hoc communication, agents exchange structured messages with task labels and report tags, creating a traceable collaboration loop.

```
┌─────────────┐    task from     ┌─────────────┐
│  Agent A     │ ───────────────→ │  Agent B     │
│  (Sender)    │                  │  (Receiver)  │
│              │ ←─────────────── │              │
└─────────────┘   report from    └─────────────┘
```

## Installation

### Claude Code

Register this repository as a plugin marketplace, then install:

```
/plugin marketplace add fingergohappy/ai-kit
```

Install the plugin:

```
/plugin install agentflow@ai-kit
/plugin install tmux@ai-kit
/plugin install git@ai-kit
```

After installation, restart Claude Code. Skills will be available with the plugin prefix:

```
/agentflow:task login-system
/agentflow:dispatch %7 docs/tasks/login_feature.md
/git:commit
/tmux:tmux-send %7 "hello"
```

<details>
<summary>Alternative: local development</summary>

```bash
claude --plugin-dir /path/to/ai-kit
```

</details>

### Codex (OpenAI)

This repository includes Codex plugin manifests for `agentflow`, `tmux`, and `git`.

Detailed guide:

- [`docs/codex_plugin_install_update.md`](docs/codex_plugin_install_update.md)

## Plugins

### agentflow

Agent collaboration loop: task → dispatch → evaluate → report → review → redo.

| Skill | Purpose |
|-------|---------|
| `agentflow:task` | Generate structured task documents (feature / change / task) |
| `agentflow:dispatch` | Send task or fix instructions to a tmux pane for execution |
| `agentflow:gate-evaluate` | Receiver-side input guard — evaluate incoming tasks before execution |
| `agentflow:report` | Report execution results back to the sender |
| `agentflow:gate-review` | Sender-side output guard — review work results, decide pass or redo |

### tmux

Tmux infrastructure utilities for inter-pane communication and long-running service management.

| Skill | Purpose |
|-------|---------|
| `tmux:tmux-send` | Send text content to a tmux pane |
| `tmux:agent-tmux` | Start/restart/stop long-running commands in shared tmux session (auto-isolates by project/branch) |

### git

Git worktree and branching utilities.

| Skill | Purpose |
|-------|---------|
| `git:rebase-to-root` | Rebase worktree feature branch back to root's current branch (supports both worktree and root invocation) |
| `git:commit` | Create atomic git commits with validation and conventional commit messages |

## Workflow

### 1. Design Phase

```
/agentflow:task <task-name>
```

Enter design discussion mode — discuss without writing code, generate document when ready. Outputs to `docs/tasks/`.

### 2. Dispatch Phase

```
/agentflow:dispatch [loop] <pane_id> <doc-path>
```

Send the task document to another agent's tmux pane. The receiving agent gets a `[task from ...]` labeled message. Add `loop` to enable automatic review-fix cycling.

### 3. Execution & Report

The receiver evaluates the task via `gate-evaluate`, executes, then calls `report` to send results back:

```
[report from Claude Code, pane_id: %5, loop: true: completed 3 tasks]
```

### 4. Review & Fix

The sender receives the report and `gate-review` triggers:

- Reviews work against original design
- If `loop: true` + issues found → auto-dispatches fix instructions (up to 3 rounds)
- If `loop: false` + issues found → outputs conclusions, user decides next step
- If all passed → done

## Message Protocol

### Task Dispatch

```
[task from {agent-name}, pane_id: {pane_id}, loop: {true|false}: {task-summary}]
```

### Fix Dispatch

```
[fix from {agent-name}, pane_id: {pane_id}, loop: {true|false}: {fix-summary}]
```

### Execution Report

```
[report from {agent-name}, pane_id: {pane_id}, loop: {true|false}: {result-summary}]
```

Agents use these tags to identify message types and route responses correctly.

## Requirements

- tmux session with multiple panes
- AI coding tool running in each pane (Claude Code, Codex, OpenCode, etc.)
- `tmux:tmux-send` skill available for inter-pane communication

### rebase-to-root

No extra dependencies — uses native `git worktree` and `git rebase` commands (requires git 2.5+).

Supports two invocation modes:
- In a worktree: auto-detects current branch and rebases back to root
- In root: lists all worktrees for selection

```
/git:rebase-to-root                    # auto-detect or select worktree
/git:rebase-to-root my-feature         # specify feature name
```

## License

MIT
