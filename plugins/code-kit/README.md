# code-kit

代码工具集插件 — 根据项目特征生成定制化的代码审查 skills。

## 功能

分析项目技术栈、依赖和结构，自动生成多角度的 review skills，通过子代理并行执行审查并汇总结果。

| Skill | 说明 |
|-------|------|
| `review-init` | 分析项目，生成定制化的 review skills |
| `fix-review` | 修复审查报告中的问题，自动更新报告状态 |
| `fix-review-all` | 并行修复审查报告中所有待处理问题 |
| `nvim-lsp-init` | 分析项目技术栈，生成 Neovim LSP 环境初始化脚本 |

### 生成物（项目 `.claude/skills/`）

| 生成的 Skill | 说明 |
|-------------|------|
| `review-{角度}` × N | 每个角度一个独立的 review skill |
| `review-full` | 全量审查，子代理并行调用所有 review skill |
| `review-diff` | 增量审查，基于 git diff 变更文件 |

## 工作流

```
1. 初始化 review
   /code-kit:review-init          # 分析项目，选择审查角度，生成 skills

2. 全量审查
   /review-full                   # 扫描整个项目

3. 增量审查
   /review-diff                   # 只审查 git diff 变更

4. 修复问题
   /code-kit:fix-review docs/review/2026-04-26_full_review.md:69  # 按报告行号定位修复
   /code-kit:fix-review 修复变量未加引号的问题                      # 按描述搜索修复
   /code-kit:fix-review-all docs/review/2026-04-26_full_review.md  # 并行修复所有问题

5. 生成 LSP 脚本
   /code-kit:nvim-lsp-init        # 分析技术栈，生成 scripts/env-lsp.sh
```

## 安装

### Claude Code

```
/plugin marketplace add fingergohappy/ai-kit
/plugin install code-kit@ai-kit
```

安装后重启 Claude Code，skill 以 `code-kit:` 前缀调用：

```
/code-kit:review-init
```

生成的 review skills 为项目级 skill，直接调用：

```
/review-full
/review-diff
```

LSP 脚本生成：

```
/code-kit:nvim-lsp-init              # 默认输出到 scripts/env-lsp.sh
/code-kit:nvim-lsp-init scripts/vim-init.sh  # 指定输出路径
```

### 本地开发

```bash
claude --plugin-dir /path/to/ai-kit/plugins/code-kit
```

## License

MIT
