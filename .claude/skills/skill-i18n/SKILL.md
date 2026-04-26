---
name: skill-i18n
description: |
  将 skill 转换为双语版本（SKILL.md 英文 + zh-CN.md 中文）。当用户说「翻译 skill」「skill 双语」「生成 zh-CN」「i18n skill」「translate skill」时触发。
  支持单个或多个 skill 路径，自动检测原始语言，按 nvim-lsp-init 的双语格式生成。
argument-hint: "<skill路径> [skill路径2] ..."
---

# skill-i18n

将 ai-kit 项目中的 skill 转换为双语版本：SKILL.md（英文）+ zh-CN.md（中文）。

## 参数解析

`$ARGUMENTS` 支持以下输入：

| 形式 | 示例 | 解析方式 |
|------|------|---------|
| 目录路径 | `plugins/code-kit/skills/fix-review` | 读取目录下的 SKILL.md |
| 文件路径 | `plugins/code-kit/skills/fix-review/SKILL.md` | 直接读取 |
| 多个路径 | `plugins/code-kit/skills/fix-review plugins/tmux/skills/tmux-send` | 逐个处理 |

如果传入目录，自动查找其中的 SKILL.md。

## 双语格式规范

以 nvim-lsp-init 为参照模板，两个文件的格式如下：

### SKILL.md（英文版）

```yaml
---
name: <skill-name>
description: <中文触发词>。<English description of what the skill does>
argument-hint: "<参数说明>"
---
```

- frontmatter `description`：先写中文触发短语（当用户说「...」时触发），再写英文功能描述
- body 全部用英文
- 代码块、命令、路径保持原样

### zh-CN.md（中文版）

```yaml
---
name: <skill-name>
description: <English description of what the skill does>
when_to_use: |
  当用户说「...」「...」时触发。
argument-hint: "<参数说明>"
---
```

- frontmatter `description`：纯英文功能描述
- frontmatter `when_to_use`：中文触发场景
- body 全部用中文
- section 标题保持英文（如 `## Overview`、`### 1. Detect environment`）
- 代码块、命令、路径、变量名保持原样

## 执行步骤

### 1. 读取原始 skill

1. 解析参数，定位每个 SKILL.md
2. 读取完整内容，解析 frontmatter 和 body

### 2. 检测语言

判断 body 的主要语言：

- 中文字符占比 > 30% → 原始语言为中文
- 否则 → 原始语言为英文

### 3. 生成双语版本

#### 原始为中文

1. **SKILL.md**（英文版）：
   - 翻译 body 为英文
   - 保留所有代码块、命令、路径、表格结构不变
   - frontmatter description：保留原始中文触发词 + 翻译英文功能描述
   - section 标题翻译为英文

2. **zh-CN.md**（中文版）：
   - body 保留原始中文内容
   - section 标题翻译为英文（与 SKILL.md 一致）
   - frontmatter 按 zh-CN.md 格式重组（description 英文、when_to_use 中文）

#### 原始为英文

1. **SKILL.md**（英文版）：
   - body 保留原始英文内容
   - frontmatter description：添加中文触发词 + 保留英文描述

2. **zh-CN.md**（中文版）：
   - 翻译 body 为中文
   - section 标题保持英文
   - 保留所有代码块、命令、路径、表格结构不变
   - frontmatter 按 zh-CN.md 格式重组

### 4. 翻译原则

- 技术术语保持原文：LSP、PATH、frontmatter、skill、plugin 等
- 代码块内容不翻译，代码注释翻译
- 表格结构保持一致，只翻译文字内容
- markdown 格式标记保持不变
- 如果原始 SKILL.md 已有 zh-CN.md，读取现有翻译作为参考，避免术语不一致

### 5. 写入文件

将两个文件写入原始 skill 的同一目录：

```
plugins/code-kit/skills/fix-review/
├── SKILL.md      # 英文版（新生成或更新）
└── zh-CN.md      # 中文版（新生成或更新）
```

### 6. 输出确认

对每个处理的 skill 显示：

```
skill-i18n: fix-review
  原始语言: 中文
  SKILL.md: 已生成（英文）
  zh-CN.md: 已生成（中文）
```

多个 skill 时汇总：

```
完成 3 个 skill 的双语转换：
  - fix-review ✅
  - fix-review-all ✅
  - tmux-send ✅
```

## 与 skill-creator 的协作

当用户通过 `skill-creator` skill 创建或修改了某个 skill 后，应同步触发 `skill-i18n` 更新对应的翻译文档。

### 流程

1. 用户使用 `skill-creator` 完成 skill 的创建或迭代
2. skill-creator 流程结束后，提醒用户：「是否同步生成/更新双语版本？」
3. 如果用户同意，按本 skill 的执行步骤处理刚创建/修改的 skill

### 翻译文档的创建方式

翻译文档（zh-CN.md）应通过 `skill-creator` skill 来创建，而非手动编写。具体做法：

1. 将已生成的 SKILL.md（英文版）作为输入
2. 使用 `skill-creator` 创建 zh-CN.md，遵循本 skill 定义的双语格式规范
3. `skill-creator` 的迭代和评估流程同样适用于翻译文档的质量把控

这样翻译文档也能经过 skill-creator 的测试和评估循环，确保翻译质量。

## 边界情况

- **已有双语文件** → 提示用户是否覆盖，默认覆盖
- **SKILL.md 中混合中英文** → 以占比高的语言为原始语言
- **frontmatter 中有非标准字段** → 原样保留，不删除
- **body 中有引用其他文件的相对路径** → 保持不变
- **参数为空** → 提示用法
