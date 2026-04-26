# Codex AI Install Runbook

这份文档写给 AI 执行，不写给人读。

目标：

1. 个人安装 `ai-kit` 仓库中已经具备 Codex manifest 的插件
2. 安装本仓库提供的 custom agents
3. 可选：把本仓库所有 plugin skills 暴露到 `~/.agents/skills/`，让 `list skills` 能直接看到这些 skill

不要安装到项目级 `.codex/agents/`。  
统一使用个人目录：

- `~/.codex/plugins/`
- `~/.agents/plugins/marketplace.json`
- `~/.codex/agents/`
- `~/.agents/skills/`

官方依据：

- <https://developers.openai.com/codex/plugins>
- <https://developers.openai.com/codex/plugins/build>
- <https://developers.openai.com/codex/subagents>
- <https://developers.openai.com/codex/skills>

## 当前项目状态

截至本文档更新时：

- `plugins/git/.codex-plugin/plugin.json` 存在，可作为 Codex plugin 安装
- `plugins/tmux/.codex-plugin/plugin.json` 存在，可作为 Codex plugin 安装
- `plugins/agentflow`、`plugins/code-kit`、`plugins/learning`、`plugins/self-learn` 目前没有 `.codex-plugin/plugin.json`，不要写入 Codex marketplace
- `scripts/install_codex_agents.sh` 会扫描 `plugins/*/skills/*`，默认把所有 skill 以 symlink 形式链接到 `~/.agents/skills/`
- `scripts/install_codex_agents.sh` 还会把 `plugins/*/agents/*.md` 转成 Codex custom agent TOML，并安装到 `~/.codex/agents/`

重要区别：

- Codex plugin 安装链路依赖 `.codex-plugin/plugin.json` 和 `~/.agents/plugins/marketplace.json`
- Codex skill 本地发现链路依赖 `~/.agents/skills/`、仓库 `.agents/skills/` 等 skill 扫描目录
- 插件安装后，Codex 会从 `~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/` 加载安装副本；更新本地插件目录后需要重启 Codex，并可能需要重新安装或禁用再启用插件

## 安装

按顺序执行下面操作。

### 1. 准备目录

```bash
mkdir -p ~/.codex/plugins ~/.codex/agents ~/.agents/plugins ~/.agents/skills
```

### 2. 克隆或更新仓库

```bash
if [ -d ~/.codex/plugins/ai-kit-repo/.git ]; then
  git -C ~/.codex/plugins/ai-kit-repo pull --ff-only
else
  git clone https://github.com/fingergohappy/ai-kit.git ~/.codex/plugins/ai-kit-repo
fi
```

### 3. 同步 Codex-ready 插件目录

只复制存在 `.codex-plugin/plugin.json` 的插件。

```bash
for plugin in git tmux; do
  rm -rf "${HOME}/.codex/plugins/${plugin}"
  cp -R "${HOME}/.codex/plugins/ai-kit-repo/plugins/${plugin}" "${HOME}/.codex/plugins/${plugin}"
done
```

不要把没有 `.codex-plugin/plugin.json` 的目录写入 marketplace。当前不要写入：

- `agentflow`
- `code-kit`
- `learning`
- `self-learn`

### 4. 合并个人 marketplace 配置

执行下面脚本。它会创建或更新 `~/.agents/plugins/marketplace.json`，保留其他已有插件条目，只替换 `git`、`tmux` 这两个 Codex-ready 插件条目。

```bash
python3 - <<'PY'
from pathlib import Path
import json

path = Path.home() / ".agents" / "plugins" / "marketplace.json"
path.parent.mkdir(parents=True, exist_ok=True)

payload = {
    "name": "ai-kit",
    "interface": {
        "displayName": "ai-kit",
    },
    "plugins": [],
}

if path.exists():
    with path.open() as f:
        payload = json.load(f)

payload.setdefault("name", "ai-kit")
payload.setdefault("interface", {})
payload["interface"].setdefault("displayName", "ai-kit")
payload.setdefault("plugins", [])

entries = [
    {
        "name": "git",
        "source": {
            "source": "local",
            "path": "./.codex/plugins/git",
        },
        "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
        },
        "category": "Coding",
    },
    {
        "name": "tmux",
        "source": {
            "source": "local",
            "path": "./.codex/plugins/tmux",
        },
        "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
        },
        "category": "Developer Tools",
    },
]

managed = {entry["name"] for entry in entries}
payload["plugins"] = [
    item
    for item in payload["plugins"]
    if not (isinstance(item, dict) and item.get("name") in managed)
]
payload["plugins"].extend(entries)

with path.open("w") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")

print(path)
PY
```

官方规则要点：

- 个人 marketplace 文件使用 `~/.agents/plugins/marketplace.json`
- 个人本地插件通常放在 `~/.codex/plugins/`
- `source.path` 必须相对 marketplace root，使用 `./` 开头，并保持在该 root 内
- 本地 plugin entry 仍需要 `policy.installation`、`policy.authentication`、`category`

### 5. 安装 custom agents，并可选暴露本仓库 skills

默认执行：

```bash
cd ~/.codex/plugins/ai-kit-repo
bash scripts/install_codex_agents.sh
```

这个脚本默认会做两件事：

1. 生成 custom agents 到 `~/.codex/agents/`
2. 为 `plugins/*/skills/*` 在 `~/.agents/skills/` 下创建同名 symlink

当前会链接的 skill 包括：

- `task`
- `dispatch`
- `gate-evaluate`
- `report`
- `gate-review`
- `evaluate`
- `fix-review`
- `fix-review-all`
- `nvim-lsp-init`
- `review-init`
- `review-report`
- `commit`
- `rebase-to-root`
- `learn`
- `take-note`
- `learn-from-mistake`
- `agent-tmux`
- `tmux-send`

如果只想安装 custom agents，不想改动 `~/.agents/skills/` 下的 skill symlink，执行：

```bash
cd ~/.codex/plugins/ai-kit-repo
bash scripts/install_codex_agents.sh --no-skill-links
```

注意：

- `ln -sfn` 会覆盖同名 symlink 目标
- 如果 `~/.agents/skills/<skill-name>` 是真实目录，不是 symlink，安装前先人工确认，不要直接覆盖
- Codex 支持 symlinked skill folders，会跟随 symlink target 扫描

### 6. 提示用户完成 Codex 内操作

执行完上面命令后，告诉用户：

1. 重启 Codex
2. 运行 `list skills` 或 `/skills` 检查本地 skills 是否出现
3. 打开 Codex CLI plugin directory：

```text
codex
/plugins
```

4. 在 `ai-kit` marketplace 中安装或启用：
   - `git`
   - `tmux`

注意：

- `list skills`、`/skills`、`$skill-name` 主要依赖 skill 扫描目录
- `@plugin` 入口和 Plugins UI 依赖插件 marketplace 安装状态
- 插件安装与本地 skill symlink 是相关但不等价的两条链路

## 更新

更新仓库、同步 Codex-ready 插件，并刷新 custom agents：

```bash
git -C ~/.codex/plugins/ai-kit-repo pull --ff-only

for plugin in git tmux; do
  rm -rf "${HOME}/.codex/plugins/${plugin}"
  cp -R "${HOME}/.codex/plugins/ai-kit-repo/plugins/${plugin}" "${HOME}/.codex/plugins/${plugin}"
done

cd ~/.codex/plugins/ai-kit-repo
bash scripts/install_codex_agents.sh
```

如果不想刷新 `~/.agents/skills/`：

```bash
cd ~/.codex/plugins/ai-kit-repo
bash scripts/install_codex_agents.sh --no-skill-links
```

然后告诉用户：

1. 重启 Codex
2. 用 `list skills` 或 `/skills` 确认 skill 是否刷新
3. 如果 plugin 内容还是旧的，在 Plugins UI 中禁用并重新启用对应插件
4. 如果还不生效，卸载后重新安装对应插件
5. 如果 `readlink ~/.agents/skills/<skill-name>` 仍指向旧路径，再确认是否需要执行不带 `--no-skill-links` 的安装脚本刷新 skill 链接目标

## 验证

执行：

```bash
test -f ~/.agents/plugins/marketplace.json
test -f ~/.codex/plugins/git/.codex-plugin/plugin.json
test -f ~/.codex/plugins/tmux/.codex-plugin/plugin.json
grep -q '"skills": "./skills/"' ~/.codex/plugins/git/.codex-plugin/plugin.json
grep -q '"skills": "./skills/"' ~/.codex/plugins/tmux/.codex-plugin/plugin.json
test -d ~/.codex/plugins/git/skills
test -d ~/.codex/plugins/tmux/skills
test -f ~/.codex/agents/git-operator.toml
test -f ~/.codex/agents/tmux-operator.toml
```

如果执行过不带 `--no-skill-links` 的安装脚本，再验证：

```bash
test -L ~/.agents/skills/task
test -L ~/.agents/skills/tmux-send
test -L ~/.agents/skills/commit
test -L ~/.agents/skills/review-init
test -L ~/.agents/skills/evaluate
```

安装完成后：

- `list skills` 或 `/skills` 应该能看到已链接到 `~/.agents/skills/` 的 skill
- prompt 中可直接显式调用：
  - `$task`
  - `$dispatch`
  - `$tmux-send`
  - `$commit`
  - `$review-init`
  - `$evaluate`
- 如果 `git`、`tmux` 也在 Codex Plugins UI 中完成 install/enable，则插件命名空间应为：
  - `git:*`
  - `tmux:*`

## 常见问题

### `agentflow` 没出现在 Codex Plugins UI

当前 `plugins/agentflow` 没有 `.codex-plugin/plugin.json`，所以不要把它写入 Codex marketplace。
如果需要在 Codex Plugins UI 中安装它，先为该插件补齐 `.codex-plugin/plugin.json`，再更新本文档中的插件列表和 marketplace entries。

### `list skills` 能看到 skill，但 Plugins UI 看不到对应插件

这是正常的。`~/.agents/skills/` 是 Codex 的本地 skill 发现路径；Plugins UI 只展示 marketplace 中具备 Codex plugin manifest 的插件。

### Plugins UI 已安装，但 skill 内容仍旧

Codex 安装插件后会使用 cache 中的安装副本。更新本地插件目录后，重启 Codex；必要时禁用再启用，或卸载后重新安装插件。

### 不想覆盖个人 skill

执行：

```bash
bash scripts/install_codex_agents.sh --no-skill-links
```

这只安装 custom agents，不刷新 `~/.agents/skills/` 下的 symlink。
