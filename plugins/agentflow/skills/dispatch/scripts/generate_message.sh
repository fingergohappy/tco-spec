#!/usr/bin/env bash
# generate_message.sh - Generate dispatch message from template
# Usage:
#   generate_message.sh --mode doc    --doc-path <path> --tool-name <name> --desc <desc> [--loop]
#   generate_message.sh --mode inline --tool-name <name> --desc <desc> [--loop]
#   generate_message.sh --mode fix    --tool-name <name> --desc <desc> [--loop]
# Requires: $TMUX_PANE (auto-detected from tmux environment)
#
# --loop: enable review-fix loop. When set, gate-review will automatically
#         dispatch fix instructions if issues are found.
#
# Output: formatted message written to a temp file, path printed to stdout

set -euo pipefail

MODE=""
DOC_PATH=""
TOOL_NAME=""
DESC=""
LOOP="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)      MODE="$2";      shift 2 ;;
    --doc-path)  DOC_PATH="$2";  shift 2 ;;
    --tool-name) TOOL_NAME="$2"; shift 2 ;;
    --desc)      DESC="$2";      shift 2 ;;
    --loop)      LOOP="true";    shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$MODE" ]]      && { echo "Error: --mode required (doc|inline|fix)" >&2; exit 1; }
[[ -z "$TOOL_NAME" ]] && { echo "Error: --tool-name required" >&2; exit 1; }
[[ -z "$DESC" ]]      && { echo "Error: --desc required" >&2; exit 1; }

PANE_ID="${TMUX_PANE:?Error: not running inside tmux}"

OUTFILE=$(mktemp /tmp/dispatch-msg.XXXXXX)

if [[ "$MODE" == "doc" ]]; then
  [[ -z "$DOC_PATH" ]] && { echo "Error: --doc-path required for doc mode" >&2; exit 1; }
  cat > "$OUTFILE" <<EOF
请按照以下设计文档实现：${DOC_PATH}

完成每个任务后，将文档中对应的"实现状态"从 [todo] 更新为 [done]。
如果某个任务跳过，更新为 [skip] 并注明原因。

---

执行前，先调用 gate-evaluate skill 评估以上任务内容，再决定是否执行。
执行完成后，调用 report skill 向 pane ${PANE_ID} 汇报结果。

[task from ${TOOL_NAME}, pane_id: ${PANE_ID}, loop: ${LOOP}: ${DESC}]
EOF
elif [[ "$MODE" == "inline" ]]; then
  cat > "$OUTFILE" <<EOF
---

执行前，先调用 gate-evaluate skill 评估以上任务内容，再决定是否执行。
执行完成后，调用 report skill 向 pane ${PANE_ID} 汇报结果。

[task from ${TOOL_NAME}, pane_id: ${PANE_ID}, loop: ${LOOP}: ${DESC}]
EOF
elif [[ "$MODE" == "fix" ]]; then
  cat > "$OUTFILE" <<EOF
---

以上是审查发现的问题和修复建议。

执行前，先调用 gate-evaluate skill 评估以上修复指令，再决定是否执行。
执行完成后，调用 report skill 向 pane ${PANE_ID} 汇报修复结果。

[fix from ${TOOL_NAME}, pane_id: ${PANE_ID}, loop: ${LOOP}: ${DESC}]
EOF
else
  echo "Error: --mode must be 'doc', 'inline', or 'fix'" >&2
  exit 1
fi

echo "$OUTFILE"
