#!/bin/bash
#
# Claude Code Feishu Report Hook
# 在 Claude Code 任务完成时通过飞书 MCP 发送汇报
#
# 使用方法:
# 1. 修改此脚本中的配置项
# 2. 赋予执行权限: chmod +x feishu-report-hook.sh
# 3. 在 Claude Code settings.json 中配置此脚本路径
#

set -e

# ============ 配置区域 ============

# 脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Node.js 发送脚本路径
SEND_SCRIPT="$SCRIPT_DIR/send-feishu-message.js"

# 日志文件路径（可选，用于调试）
LOG_FILE="/tmp/claude-feishu-hook.log"

# 是否启用调试日志
DEBUG=true

# ============ 主逻辑 ============

# 日志函数
log() {
    if [ "$DEBUG" = true ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

log "========== Hook 开始执行 =========="

# 读取 Claude Code 提供的 hook 数据（从 stdin）
HOOK_DATA=$(cat)

log "收到 Hook 数据"

# 检查是否安装了 jq
if ! command -v jq &> /dev/null; then
    log "错误: jq 未安装，请先安装 jq"
    echo "错误: 需要安装 jq 工具。请运行: sudo apt install jq (Linux) 或 brew install jq (Mac)" >&2
    exit 1
fi

# 解析关键信息
SESSION_ID=$(echo "$HOOK_DATA" | jq -r '.session_id // "unknown"')
TRANSCRIPT_PATH=$(echo "$HOOK_DATA" | jq -r '.transcript_path // ""')
CWD=$(echo "$HOOK_DATA" | jq -r '.cwd // ""')
HOOK_EVENT=$(echo "$HOOK_DATA" | jq -r '.hook_event_name // "unknown"')

log "解析信息 - Session: $SESSION_ID, Event: $HOOK_EVENT"

# 读取对话历史获取任务摘要
TASK_SUMMARY="无法读取任务历史"

if [ -f "$TRANSCRIPT_PATH" ]; then
    log "读取 transcript 文件: $TRANSCRIPT_PATH"

    # 提取最后几条消息作为任务摘要
    # 这里提取最后 3 条用户和助手的消息
    TASK_SUMMARY=$(jq -r '
        .messages[-6:]
        | map(
            select(.role == "user" or .role == "assistant")
            | if .role == "user" then "👤 用户: " else "🤖 Claude: " end
            + (
                if .content | type == "array"
                then .content[0].text // .content[0].type // ""
                else .content // ""
                end
            )
        )
        | join("\n\n")
    ' "$TRANSCRIPT_PATH" 2>/dev/null || echo "解析 transcript 失败")

    # 限制摘要长度（防止过长）
    TASK_SUMMARY=$(echo "$TASK_SUMMARY" | head -c 1000)

    log "提取任务摘要成功，长度: ${#TASK_SUMMARY}"
else
    log "警告: Transcript 文件不存在: $TRANSCRIPT_PATH"
fi

# 获取当前时间
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 检查 Node.js 发送脚本是否存在
if [ ! -f "$SEND_SCRIPT" ]; then
    log "错误: 发送脚本不存在: $SEND_SCRIPT"
    echo "错误: 找不到发送脚本 $SEND_SCRIPT" >&2
    exit 1
fi

# 调用 Node.js 脚本发送飞书消息
log "调用发送脚本..."

node "$SEND_SCRIPT" \
    --session_id "$SESSION_ID" \
    --summary "$TASK_SUMMARY" \
    --timestamp "$TIMESTAMP" \
    --cwd "$CWD" \
    --event "$HOOK_EVENT" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    log "飞书消息发送成功"
else
    log "飞书消息发送失败，退出码: $EXIT_CODE"
fi

log "========== Hook 执行完成 =========="

exit $EXIT_CODE
