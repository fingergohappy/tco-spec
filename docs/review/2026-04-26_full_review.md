---
title: ai-kit 全量代码审查
type: code-review
mode: full
date: 2026-04-26
scope:
  - plugins/
  - .claude/skills/
  - scripts/
  - docs/
issue_stats:
  critical: 0
  high: 9
  medium: 9
  low: 6
review_skills:
  - review-shell
  - review-architecture
  - review-skill-quality
---

# ai-kit 全量代码审查

## 概述

对 ai-kit 项目进行全量审查，从 shell 脚本质量、架构、skill 规范三个角度检查。发现 0 个 CRITICAL、9 个 HIGH、9 个 MEDIUM、6 个 LOW 问题。

## 审查范围

- 模式: full — 全量
- 文件数: 38 个
- 审查角度: review-shell, review-architecture, review-skill-quality

## 问题汇总

| 级别 | 数量 |
|------|------|
| CRITICAL | 0 |
| HIGH | 9 |
| MEDIUM | 9 |
| LOW | 6 |

## HIGH



### #3 [shell] here-string 中变量未加引号，外部内容有展开风险

**文件**: `plugins/tmux/skills/tmux-send/scripts/tmux_send.sh:30`
**问题**: `${BODY}` 来自外部文件或用户传入参数，内容不受控。在 here-string 中若包含反斜杠序列或特殊字符，行为依赖 shell 解释，存在内容被意外展开的风险。
**建议**: 通过 `printf '%s\n' "$BODY"` 写入临时文件再用 `tmux load-buffer` 读取，避免 here-string 对内容的隐式处理。

### #4 [skill] `when_to_use` 非标准字段，触发词不生效

**文件**: `plugins/code-kit/skills/nvim-lsp-init/SKILL.md`
**问题**: frontmatter 中触发条件写在 `when_to_use` 字段而非 `description` 字段。`when_to_use` 不是 SKILL.md 规范字段，Claude Code 不会读取它来判断触发时机，导致中文触发词实际不生效。
**建议**: 将 `when_to_use` 内容合并进 `description` 字段，删除 `when_to_use`。

### #5 [skill] 缺少 `argument-hint`，description 无触发条件

**文件**: `.claude/skills/extract-before-duplicate/SKILL.md`
**问题**: frontmatter 缺少 `argument-hint` 字段。description 描述的是被动检查规则，但没有说明用户说什么话时会触发，也没有"不触发"边界说明。
**建议**: 补充 `argument-hint: ""`；在 description 中明确触发词或说明这是防护性 skill。

### #6 [skill] description 触发词覆盖面不足

**文件**: `plugins/git/skills/commit/SKILL.md`
**问题**: description 只列了「提交」、「commit」、「commit一下」三个触发词，缺少常见变体如「帮我提交」「git commit」「提交代码」等口语化表达。
**建议**: 补充 3-5 个更多触发短语，覆盖中英文和口语化场景。

### #7 [skill+arch] ~~脚本相对路径无工作目录说明，安装后会失效~~ ✅ 已修复

**文件**: `plugins/tmux/skills/tmux-send/SKILL.md`、`plugins/agentflow/skills/dispatch/SKILL.md`、`plugins/agentflow/skills/report/SKILL.md`
**问题**: 步骤中调用 `bash scripts/xxx.sh` 使用相对路径，但没有说明执行时的工作目录。skill 被安装后实际运行时的 cwd 是用户项目根目录，路径会解析到错误位置。
**建议**: 明确脚本路径的基准目录，或改为从 SKILL.md 所在位置推导的路径写法。
**修复**: 在三个 SKILL.md 中新增「脚本路径」段落，要求通过 `SKILL_DIR` 变量解析为绝对路径，所有代码示例从裸 `scripts/xxx.sh` 改为 `"$SKILL_DIR/scripts/xxx.sh"`。

### #8 [skill] `$ARGUMENTS` 为空时无处理说明

**文件**: `plugins/agentflow/skills/gate-evaluate/SKILL.md`
**问题**: 步骤写"从对话上下文或 `$ARGUMENTS` 获取待评估的内容"，但没有说明当两者都为空时如何处理。
**建议**: 补充：若 `$ARGUMENTS` 为空且对话上下文中无待评估内容，则提示用户提供内容后再触发。

### #9 [arch] 跨插件调用用裸名而非命名空间名称

**文件**: `plugins/agentflow/skills/dispatch/SKILL.md`、`plugins/agentflow/skills/report/SKILL.md`
**问题**: 通过 `/tmux-send` 调用 tmux 插件的 skill，按插件安装约定应使用 `/tmux:tmux-send`。裸名称只在 symlink 场景下有效，在 Claude Code 插件环境下会找不到。
**建议**: 统一使用 `/tmux:tmux-send`，或在 skill 中注明两种环境下的调用差异。

## MEDIUM

### #1 [shell] `cat` 命令替换丢失尾部换行

**文件**: `plugins/tmux/skills/tmux-send/scripts/tmux_send.sh:25`
**问题**: `BODY=$(cat "$CONTENT")` 使用命令替换，shell 会自动剥离输出末尾的所有换行符。如果文件末尾有意义的空行，会被静默丢弃。
**建议**: 改用临时文件直接传递，不经过命令替换。

### #2 [shell] 路径正则不识别 `../` 开头

**文件**: `plugins/tmux/skills/tmux-send/scripts/tmux_send.sh:23`
**问题**: `[[ "$CONTENT" =~ ^/ ]] || [[ "$CONTENT" =~ ^\./ ]]` 只识别绝对路径和 `./` 开头的相对路径，`../` 开头的路径会被当作文本内容处理。
**建议**: 根据实际需求决定是否支持 `../`，或在文档中明确说明不支持该形式。

### #3 [skill] 模板占位符填充方式未说明

**文件**: `plugins/agentflow/skills/task/SKILL.md`
**问题**: 引用了 `references/feature_template.md` 和 `references/change_template.md`，但没有列出模板中有哪些占位符 `{xxx}` 以及如何填充。
**建议**: 在引用模板处简要列出主要占位符及其来源。

### #4 [skill+arch] 引用不存在的 `skill-creator:skill-creator`

**文件**: `plugins/self-learn/skills/learn-from-mistake/SKILL.md`
**问题**: 步骤 6 调用 `skill-creator:skill-creator` 评估生成的 skill，但当前仓库中未找到该 skill，属于悬空引用。
**建议**: 确认 `skill-creator` 是否存在于其他位置；若不存在，改为内联描述评估标准或移除该步骤。

### #5 [skill] gate-evaluate 与 gate-review 结构不一致

**文件**: `plugins/agentflow/skills/gate-evaluate/SKILL.md` vs `plugins/agentflow/skills/gate-review/SKILL.md`
**问题**: `gate-review` 有详细的"终止条件"章节，`gate-evaluate` 没有。两者都是 agentflow 的守卫 skill，但结构差异较大。
**建议**: 在 `gate-evaluate` 补充边界说明，统一守卫 skill 的结构约定。

### #6 [skill] review-init 生成的 skill description 缺触发词

**文件**: `plugins/code-kit/skills/review-init/SKILL.md`
**问题**: 步骤 4 的 review skill 模板中 description 只写了"接收文件列表作为输入"，缺少触发条件，生成的 skill 天然不满足 review-skill-quality 的标准。
**建议**: 在步骤 4 的模板中补充触发词示例。

### #7 [arch] code-kit 缺 agents/ 目录

**范围**: `plugins/code-kit/`
**问题**: git、tmux 插件均有 `agents/` 目录，code-kit 没有。如果不需要 agent，应在 README 中说明。
**建议**: 明确说明或补充对应的 agent 文件。

### #8 [arch] url-to-skill 硬编码 MCP 工具依赖无降级处理

**文件**: `.claude/skills/url-to-skill/SKILL.md`
**问题**: 硬编码了 `mcp__web_reader__webReader` 工具名，如果该 MCP 工具不可用，skill 会在第一步就失败且没有错误提示。
**建议**: 增加工具可用性检查，或在 description 中注明前置依赖。

### #9 [arch] design.md 声称 spec-workflow 已删除但实际仍存在

**文件**: `docs/drafts/design.md`
**问题**: 文档标注 spec-workflow 已删除，但 git status 显示 `plugins/spec-workflow/` 下仍有被修改的文件。
**建议**: 确认 spec-workflow 是否已完成迁移，更新 design.md 的状态说明。

## LOW

### #1 [shell] 布尔值风格不统一

**文件**: `scripts/install_codex_agents.sh:8-10`
**问题**: 使用 `1`/`0` 表示布尔值，与其他脚本中 `true`/`false` 的风格不统一。
**建议**: 统一使用 `true`/`false` 字符串或提取具名常量。

### #2 [skill] SKILL.md 过短，缺少完整用法示例

**文件**: `plugins/tmux/skills/agent-tmux/SKILL.md`
**问题**: 全文仅 33 行，没有说明脚本支持哪些子命令的完整参数格式。
**建议**: 补充 `start`、`stop`、`restart`、`status` 四个子命令的调用格式。

### #3 [skill] description 缺少 stop/restart 触发词

**文件**: `plugins/tmux/skills/agent-tmux/SKILL.md`
**问题**: 触发词缺少"停止服务"、"重启服务"等，而 Workflow 中明确支持 stop/restart 操作。
**建议**: 补充 stop/restart 相关触发词。

### #4 [skill] review-full/review-diff 报告模板路径未明确

**文件**: `.claude/skills/review-full/SKILL.md`、`.claude/skills/review-diff/SKILL.md`
**问题**: 步骤中"读取报告模板"但未说明模板路径，生成后的文件不包含模板路径信息。
**建议**: 明确报告模板路径，或将报告格式内联定义在 SKILL.md 中。

### #5 [arch] commit skill 引用不存在的 `/code-review`

**文件**: `plugins/git/skills/commit/SKILL.md`
**问题**: 建议后续步骤执行 `/code-review`，但本仓库没有该 skill。
**建议**: 改为 `/review-diff` 或 `/code-kit:review-init`。


## 变更历史

| 日期 | 说明 |
|------|------|
| 2026-04-26 | 初始审查 |
