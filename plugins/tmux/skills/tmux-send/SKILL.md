---
name: tmux-send
model: haiku
description: |
  将内容发送到指定的 tmux pane 并自动执行。只要用户提到要在 tmux 面板里运行命令、发送内容到终端、在某个 pane 执行代码，就应该使用此 skill。包括但不限于：「发送到 tmux」、「在那个面板运行」、「在 tmux 执行」、「send to pane」、「run in tmux」、「paste to terminal」等场景。
argument-hint: "[<pane_id>] [<内容>]"
---

# tmux-send

将内容发送到指定的 tmux pane，并自动按下 Enter。

## 工作流程

优先检查 `$ARGUMENTS`，否则从自然语言中解析：

1. `$ARGUMENTS` 同时包含 pane_id 和内容（如 `%7 ls` 或 `7 ls`）→ 直接发送
2. `$ARGUMENTS` 只有 pane_id（无后续内容）→ 询问用户要发送的内容
3. `$ARGUMENTS` 为空 → 从对话上下文中提取 pane_id 和内容；用户可能说「把刚才那段代码发到 7」、「将你修改的内容发送到 %3」等，此时内容来自对话中已有的代码或文本
4. pane_id 仍未知 → 询问用户（纯文本，不显示选项列表）

## 发送内容

使用脚本 `scripts/tmux_send.sh` 发送内容：

```bash
# 方式 1：直接传内容
bash scripts/tmux_send.sh "<pane_id>" "<内容>"

# 方式 2：传文件路径（适合长内容）
bash scripts/tmux_send.sh "<pane_id>" "/tmp/message.txt"
```
