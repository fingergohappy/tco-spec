---
name: extract-before-duplicate
description: |
  修改分支逻辑（if/else、switch、match）时，防止在多个分支中复制粘贴相同代码。
  当你要在分支的每个路径中写相同或高度相似的操作时，先停下来，把差异提取为变量，公共操作放到分支外面。
  在编写或修改任何包含分支结构的代码时都应检查此 skill。
---

# extract-before-duplicate

## 错误模式

修改分支逻辑时，只关注新增的功能点，把新逻辑直接塞进每个分支，导致公共操作被复制多份。

```bash
# 错误：load-buffer 调用在两个分支中重复
if [[ -f "$CONTENT" ]]; then
  BODY=$(cat "$CONTENT")
  tmux load-buffer - <<< "${BODY}[tag]"
else
  tmux load-buffer - <<< "${CONTENT}[tag]"
fi
```

## 正确做法

先让分支只负责解析差异（赋值变量），公共操作提到分支外面。

```bash
# 正确：分支只解析 BODY，load-buffer 只写一次
if [[ -f "$CONTENT" ]]; then
  BODY=$(cat "$CONTENT")
else
  BODY="$CONTENT"
fi
tmux load-buffer - <<< "${BODY}[tag]"
```

## 检查步骤

1. 写完分支代码后，对比每个分支的内容
2. 如果有相同或高度相似的行，提取为变量或函数
3. 分支内只保留真正有差异的部分
