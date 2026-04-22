---
name: spec-implement
model: haiku
description: |
  将设计文档发送到指定 tmux pane 执行。执行完成后会通过 spec-feedback 反馈结果。
  只要用户提到「发过去」、「send 过去」、「开始干」、「implement」、「发到某个 pane 执行」，就应该使用此 skill。
argument-hint: "[<target_pane_id>] [<文档路径或内联任务>]"
context: fork
---

# spec-implement

将设计文档或任务内容发送到指定 tmux pane 执行，执行完成后由目标 pane 通过 spec-feedback 反馈结果。

## 工作流程

优先检查 `$ARGUMENTS`，否则从对话上下文中解析：

1. `$ARGUMENTS` 同时包含 target_pane_id 和文档路径/内容 → 直接执行
2. `$ARGUMENTS` 只有 target_pane_id → 询问用户文档路径或任务内容
3. `$ARGUMENTS` 只有文档路径/内容，未指定 target_pane_id → 列出可用 pane 供用户选择：
   ```bash
   tmux list-panes -F "#{pane_id}: #{pane_current_command} [#{pane_width}x#{pane_height}]"
   ```
4. `$ARGUMENTS` 为空 → 从对话上下文提取；用户可能说「把这个发到 7」，此时文档路径或内容来自对话中已有内容
5. target_pane_id 仍未知 → 询问用户（纯文本，不显示选项列表）

## 执行步骤

1. 获取 this_pane_id：
   ```bash
   echo $TMUX_PANE
   ```
2. 确定 target_pane_id（见工作流程）
3. 若参数是文件路径，读取文档内容；若文档有 frontmatter，将 `status` 从 `draft` 改为 `doing`
4. 按下方格式生成消息，通过 tmux-send skill 发送到 target_pane_id

## 发送格式

### 文档路径：

```
请按照以下设计文档实现：{文档路径}

完成每个任务后，将文档中对应的"实现状态"从 [todo] 更新为 [done]。
如果某个任务跳过，更新为 [skip] 并注明原因。

---

执行完成后，调用 spec-feedback skill 向 pane {this_pane_id} 反馈结果。

[task from {当前AI工具名称}, pane_id: {this_pane_id}: {简要描述}]
```

### 内联任务（直接将内容发送，末尾附加）：

```
---

执行完成后，调用 spec-feedback skill 向 pane {this_pane_id} 反馈结果。

[task from {当前AI工具名称}, pane_id: {this_pane_id}: {简要描述}]
```
