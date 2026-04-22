---
name: spec-feedback
model: haiku
description: |
  任务执行完成后向发起方 pane 反馈执行结果。
  只要任务完成、收到 [task from ...] 标签、或用户说「反馈结果」、「告诉对方完成了」，就应该使用此 skill。
argument-hint: "[<target_pane_id>]"
context: fork
---

# spec-feedback

任务完成后，向发起方的 tmux pane 反馈执行结果。

## 工作流程

1. 获取 this_pane_id：
   ```bash
   echo $TMUX_PANE
   ```
2. 确定 target_pane_id：
   - 优先从收到的 `[task from ..., pane_id: xxx]` 标签中提取
   - 其次使用 `$ARGUMENTS` 传入的值
   - 仍未知则询问用户
3. 生成反馈消息，通过 tmux-send skill 发送到 target_pane_id

## 反馈格式

根据原始任务类型附上设计上下文：

- **文档路径** → 引用路径
- **内联内容** → 原样附上

```
## 原始设计

{文档路径，或从 implement 发送过来的任务清单}

---

## 执行反馈

### 完成情况

- 已完成: {数量} 项
- 已跳过: {数量} 项
- 未处理: {数量} 项（如有）

### 跳过项说明

- {跳过的任务}: {原因}

### 遗留问题

- {未处理的问题说明}（如有）

---

使用 spec-handle-feedback skill 检查以上反馈。

[feedback from {当前AI工具名称}, pane_id: {this_pane_id}: {执行结果简要描述}]
```

## 生成规则

- 完成情况必须量化
- 跳过的任务必须注明原因
- 全部顺利完成时，省略「跳过项说明」和「遗留问题」部分
