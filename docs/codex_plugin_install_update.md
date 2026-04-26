# Codex AI Install Runbook

这份文档写给 AI 执行，不写给人读。

目标：

1. 安装 `ai-kit` 仓库中的全部插件
2. 安装本仓库提供的 custom agents
3. 暴露本仓库所有 plugin skills 到 `~/.agents/skills/`，让 `list skills` 能直接看到这些 skill

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

### 3. 同步全部插件目录

```bash
for plugin_dir in "${HOME}/.codex/plugins/ai-kit-repo/plugins"/*; do
  [ -d "${plugin_dir}" ] || continue
  plugin="$(basename "${plugin_dir}")"
  rm -rf "${HOME}/.codex/plugins/${plugin}"
  cp -R "${plugin_dir}" "${HOME}/.codex/plugins/${plugin}"
done
```

### 4. 合并个人 marketplace 配置

执行下面脚本。它会创建或更新 `~/.agents/plugins/marketplace.json`，保留其他已有插件条目，只替换 `ai-kit` 管理的插件条目。

```bash
python3 - <<'PY'
from pathlib import Path
import json

repo_plugins = Path.home() / ".codex" / "plugins" / "ai-kit-repo" / "plugins"
marketplace_path = Path.home() / ".agents" / "plugins" / "marketplace.json"
marketplace_path.parent.mkdir(parents=True, exist_ok=True)

payload = {
    "name": "ai-kit",
    "interface": {
        "displayName": "ai-kit",
    },
    "plugins": [],
}

if marketplace_path.exists():
    with marketplace_path.open() as f:
        payload = json.load(f)

payload.setdefault("name", "ai-kit")
payload.setdefault("interface", {})
payload["interface"].setdefault("displayName", "ai-kit")
payload.setdefault("plugins", [])

categories = {
    "agentflow": "Productivity",
    "code-kit": "Coding",
    "git": "Coding",
    "learning": "Productivity",
    "self-learn": "Productivity",
    "tmux": "Developer Tools",
}

plugin_names = sorted(
    item.name
    for item in repo_plugins.iterdir()
    if item.is_dir()
)

entries = [
    {
        "name": name,
        "source": {
            "source": "local",
            "path": f"./.codex/plugins/{name}",
        },
        "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
        },
        "category": categories.get(name, "Productivity"),
    }
    for name in plugin_names
]

managed = set(plugin_names)
payload["plugins"] = [
    item
    for item in payload["plugins"]
    if not (isinstance(item, dict) and item.get("name") in managed)
]
payload["plugins"].extend(entries)

with marketplace_path.open("w") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")

print(marketplace_path)
print("installed marketplace entries:", ", ".join(plugin_names))
PY
```

官方规则要点：

- 个人 marketplace 文件使用 `~/.agents/plugins/marketplace.json`
- 个人本地插件通常放在 `~/.codex/plugins/`
- `source.path` 必须相对 marketplace root，使用 `./` 开头，并保持在该 root 内
- 本地 plugin entry 需要 `policy.installation`、`policy.authentication`、`category`

### 5. 安装 custom agents，并暴露全部 plugin skills

```bash
cd ~/.codex/plugins/ai-kit-repo
bash scripts/install_codex_agents.sh
```

这个脚本会做两件事：

1. 生成 custom agents 到 `~/.codex/agents/`
2. 为 `plugins/*/skills/*` 在 `~/.agents/skills/` 下创建同名 symlink

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

4. 在 `ai-kit` marketplace 中安装或启用全部插件：
   - `agentflow`
   - `code-kit`
   - `git`
   - `learning`
   - `self-learn`
   - `tmux`

注意：

- `list skills`、`/skills`、`$skill-name` 主要依赖 skill 扫描目录
- `@plugin` 入口和 Plugins UI 依赖插件 marketplace 安装状态
- 插件安装与本地 skill symlink 是相关但不等价的两条链路

## 更新

更新仓库、同步全部插件，并刷新 custom agents 和 skills：

```bash
git -C ~/.codex/plugins/ai-kit-repo pull --ff-only

for plugin_dir in "${HOME}/.codex/plugins/ai-kit-repo/plugins"/*; do
  [ -d "${plugin_dir}" ] || continue
  plugin="$(basename "${plugin_dir}")"
  rm -rf "${HOME}/.codex/plugins/${plugin}"
  cp -R "${plugin_dir}" "${HOME}/.codex/plugins/${plugin}"
done

python3 - <<'PY'
from pathlib import Path
import json

repo_plugins = Path.home() / ".codex" / "plugins" / "ai-kit-repo" / "plugins"
marketplace_path = Path.home() / ".agents" / "plugins" / "marketplace.json"
marketplace_path.parent.mkdir(parents=True, exist_ok=True)

payload = {
    "name": "ai-kit",
    "interface": {
        "displayName": "ai-kit",
    },
    "plugins": [],
}

if marketplace_path.exists():
    with marketplace_path.open() as f:
        payload = json.load(f)

payload.setdefault("name", "ai-kit")
payload.setdefault("interface", {})
payload["interface"].setdefault("displayName", "ai-kit")
payload.setdefault("plugins", [])

categories = {
    "agentflow": "Productivity",
    "code-kit": "Coding",
    "git": "Coding",
    "learning": "Productivity",
    "self-learn": "Productivity",
    "tmux": "Developer Tools",
}

plugin_names = sorted(
    item.name
    for item in repo_plugins.iterdir()
    if item.is_dir()
)

entries = [
    {
        "name": name,
        "source": {
            "source": "local",
            "path": f"./.codex/plugins/{name}",
        },
        "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
        },
        "category": categories.get(name, "Productivity"),
    }
    for name in plugin_names
]

managed = set(plugin_names)
payload["plugins"] = [
    item
    for item in payload["plugins"]
    if not (isinstance(item, dict) and item.get("name") in managed)
]
payload["plugins"].extend(entries)

with marketplace_path.open("w") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")

print(marketplace_path)
print("updated marketplace entries:", ", ".join(plugin_names))
PY

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
3. 在 Plugins UI 中安装或启用全部插件
4. 如果 plugin 内容还是旧的，在 Plugins UI 中禁用并重新启用全部插件
5. 如果还不生效，卸载后重新安装全部插件
6. 如果 `readlink ~/.agents/skills/<skill-name>` 仍指向旧路径，再确认是否需要执行不带 `--no-skill-links` 的安装脚本刷新 skill 链接目标
