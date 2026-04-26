#!/usr/bin/env bash
# generate_message.sh - Generate full report message
# Usage:
#   generate_message.sh --tool-name <name> --loop <true|false> --desc <desc> \
#     --original-task <doc_path_or_content> --completed <n> --skipped <n> \
#     [--unprocessed <n>] [--evaluate <text>] [--skip-reasons <text>] [--issues <text>]
#
# Requires: $TMUX_PANE (auto-detected from tmux environment)
#
# Optional sections (evaluate, skip-reasons, issues) accept string args.
# Empty or omitted = section not included in output.
#
# Output: full message written to a temp file, path printed to stdout

set -euo pipefail

TOOL_NAME=""
LOOP="false"
DESC=""
ORIGINAL_TASK=""
COMPLETED=0
SKIPPED=0
UNPROCESSED=""
EVALUATE=""
SKIP_REASONS=""
ISSUES=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool-name)      TOOL_NAME="$2";      shift 2 ;;
    --loop)           LOOP="$2";           shift 2 ;;
    --desc)           DESC="$2";           shift 2 ;;
    --original-task)  ORIGINAL_TASK="$2";  shift 2 ;;
    --completed)      COMPLETED="$2";      shift 2 ;;
    --skipped)        SKIPPED="$2";        shift 2 ;;
    --unprocessed)    UNPROCESSED="$2";    shift 2 ;;
    --evaluate)       EVALUATE="$2";       shift 2 ;;
    --skip-reasons)   SKIP_REASONS="$2";   shift 2 ;;
    --issues)         ISSUES="$2";         shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$TOOL_NAME" ]]     && { echo "Error: --tool-name required" >&2; exit 1; }
[[ -z "$DESC" ]]           && { echo "Error: --desc required" >&2; exit 1; }
[[ -z "$ORIGINAL_TASK" ]]  && { echo "Error: --original-task required" >&2; exit 1; }

PANE_ID="${TMUX_PANE:?Error: not running inside tmux}"

OUTFILE=$(mktemp /tmp/report-msg.XXXXXX)

# --- 原始任务 ---
cat > "$OUTFILE" <<EOF
## 原始任务

${ORIGINAL_TASK}

---

## 执行汇报

EOF

# --- gate-evaluate 评估结论（可选）---
if [[ -n "$EVALUATE" ]]; then
  {
    echo "### gate-evaluate 评估结论"
    echo ""
    echo "$EVALUATE"
    echo ""
  } >> "$OUTFILE"
fi

# --- 完成情况 ---
{
  echo "### 完成情况"
  echo ""
  echo "- 已完成: ${COMPLETED} 项"
  echo "- 已跳过: ${SKIPPED} 项"
  if [[ -n "$UNPROCESSED" && "$UNPROCESSED" != "0" ]]; then
    echo "- 未处理: ${UNPROCESSED} 项"
  fi
  echo ""
} >> "$OUTFILE"

# --- 跳过项说明（可选）---
if [[ -n "$SKIP_REASONS" ]]; then
  {
    echo "### 跳过项说明"
    echo ""
    echo "$SKIP_REASONS"
    echo ""
  } >> "$OUTFILE"
fi

# --- 遗留问题（可选）---
if [[ -n "$ISSUES" ]]; then
  {
    echo "### 遗留问题"
    echo ""
    echo "$ISSUES"
    echo ""
  } >> "$OUTFILE"
fi

# --- 尾部标签 ---
if [[ "$LOOP" == "true" ]]; then
  cat >> "$OUTFILE" <<EOF

---

请调用 gate-review skill 审查以上汇报。如果审查发现问题，请使用 dispatch skill 将修复指令发回接收端。

[report from ${TOOL_NAME}, pane_id: ${PANE_ID}, loop: ${LOOP}: ${DESC}]
EOF
else
  cat >> "$OUTFILE" <<EOF

---

请调用 gate-review skill 审查以上汇报。

[report from ${TOOL_NAME}, pane_id: ${PANE_ID}, loop: ${LOOP}: ${DESC}]
EOF
fi

echo "$OUTFILE"
