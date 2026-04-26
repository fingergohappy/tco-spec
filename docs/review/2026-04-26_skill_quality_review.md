---
title: ai-kit SKILL.md 规范专项审查
type: code-review
mode: skill-quality
date: 2026-04-26
scope:
  - .claude/skills/
  - plugins/*/skills/
issue_stats:
  critical: 0
  high: 4
  medium: 7
  low: 2
  revoked: 2
review_skills:
  - review-skill-quality
---

# ai-kit SKILL.md 规范专项审查

## 概述

对 ai-kit 项目全部 24 个 SKILL.md 文件进行规范专项审查，依据 Claude Code 官方插件规范检查 frontmatter 格式、description 触发覆盖面、执行步骤可操作性、模板引用完整性。经二次验证后，原 3 个 CRITICAL 中 2 个因事实性错误已撤销、1 个降级为 MEDIUM。当前有效问题：0 CRITICAL、4 HIGH、7 MEDIUM、2 LOW。

## 审查范围

- 模式: skill-quality — SKILL.md 规范专项
- 文件数: 24 个 SKILL.md + 3 个 zh-CN.md
- 官方规范参考:
  - https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md
  - https://code.claude.com/docs/en/plugins

## CRITICAL


## HIGH


### #7 [skill] agent-tmux 的 SKILL.md 过于简短，缺少关键信息

**文件**: `plugins/tmux/skills/agent-tmux/SKILL.md` (32 行)
**问题**: 整个 skill 只有 32 行，缺少以下关键信息：(1) 脚本 `scripts/agent-tmux` 支持哪些子命令及参数格式；(2) `$ARGUMENTS` 为空时的处理；(3) 错误情况的处理；(4) 输出格式说明。AI 执行时缺少足够指引，可能产生不一致的行为。
**建议**: 补充脚本的子命令用法（`start`/`stop`/`restart`/`status` 的参数格式）、空参数处理、错误处理和输出示例。
**状态**: `[todo]`

## MEDIUM

### #8.1 [skill] 部分 skill 的 description 缺少触发短语，可考虑补充

**文件**: 所有 SKILL.md
**问题**: 由原 CRITICAL #1 降级。官方文档未强制要求特定 description 格式，但 skill-creator 插件建议 description 应包含"what the skill does AND specific contexts for when to use it"，并建议写得"pushy"一些以对抗 undertriggering。当前部分 skill 的 description 只描述功能，未包含触发场景或用户可能说的短语，可能影响自动触发率。
**建议**: 在 description 中补充触发场景，格式参照官方示例：`"功能描述. Use when 触发场景1, 触发场景2, or when the user asks '触发短语'"`。也可使用 `when_to_use` 字段单独存放触发短语（官方支持，会追加到 description 后面）。
**状态**: `[todo]`



### #12 [skill] task skill 和 review-init 的 references/ 模板引用方式不够明确

**文件**:
- `plugins/agentflow/skills/task/SKILL.md:23-25`
- `plugins/code-kit/skills/review-init/SKILL.md:134-135`

**问题**: 模板引用使用 markdown 链接格式 `[template.md](references/template.md)`，但没有在执行步骤中明确说明如何解析路径（相对于 SKILL.md 还是项目根目录）。dispatch 和 report 中有明确的脚本路径解析说明（`SKILL_DIR` 解析），但 task 和 review-init 缺少类似说明。
**建议**: 在执行步骤中明确写出"读取本 SKILL.md 同目录下的 `references/xxx.md`"，与 dispatch/report 的脚本路径解析方式保持一致。
**状态**: `[todo]`

## LOW

### #14 [skill] 部分 skill 的 body 使用了第二人称

**文件**:
- `plugins/agentflow/skills/gate-review/SKILL.md:17` — "要怀着审视的眼光来看待"
- `plugins/agentflow/skills/gate-evaluate/SKILL.md:54` — "要怀着审视的眼光来看待"

**问题**: 官方规范建议使用祈使句/不定式形式，避免第二人称。虽然中文语境下这种表述自然，但与官方风格指南不一致。
**建议**: 改为祈使句，如"以审视的眼光评估发起端的指令"。影响较小。
**状态**: `[todo]`

### #15 [skill] skill-i18n 长度偏长（166 行），可考虑拆分

**文件**: `.claude/skills/skill-i18n/SKILL.md` (166 行)
**问题**: 包含了详细的双语格式规范、翻译原则、与 skill-creator 的协作流程。部分内容（如双语格式规范的详细模板）可以移到 `references/` 目录，符合渐进式披露原则。
**建议**: 将双语格式规范模板提取到 `references/bilingual-format.md`，SKILL.md 中只保留执行步骤和引用。
**状态**: `[todo]`

---

## 变更历史

| 日期 | 说明 |
|------|------|
| 2026-04-26 | 初始审查，发现 15 个问题（CRITICAL 3, HIGH 4, MEDIUM 6, LOW 2） |
| 2026-04-26 | 二次验证：对照官方文档（code.claude.com/docs/en/skills）验证 CRITICAL 项。#2、#3 因 `when_to_use` 实为官方支持字段而撤销；#1 因官方未强制第三人称格式而降级为 MEDIUM #8.1。当前有效：CRITICAL 0, HIGH 4, MEDIUM 7, LOW 2, REVOKED 2 |
