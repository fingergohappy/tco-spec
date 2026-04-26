---
name: agent-tmux
model: haiku
description: |
  Start, restart, stop, or inspect long-running commands in a shared tmux session.
  Auto-isolates by project path and git branch to prevent conflicts.
argument-hint: <path> [--cmd <command>]
context: fork
disable-model-invocation: false
---

# agent-tmux

Manage long-running services in a shared tmux session, automatically isolating windows by project directory and git branch.

## Script Location

`plugins/tmux/skills/agent-tmux/scripts/agent-tmux`

## Command Constraints

- Pass the raw command directly after `--cmd`. Do not wrap the input command with `sh -lc ...` or `bash -lc ...`.

## Workflow

1. Call `status` first to check the current running state.
2. Based on the state and user intent, decide the operation:
   - To start a new service: already running -> `restart`, not running -> `start`
   - To stop a service: `stop`
   - To check status: report the `status` output directly
3. Report the script output to the user.

