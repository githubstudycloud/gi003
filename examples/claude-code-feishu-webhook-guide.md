# Claude Code 配置 Webhook 调用飞书 MCP 汇报任务

本指南介绍如何在 Claude Code 任务结束时自动通过飞书 MCP 发送任务汇报。

## 架构概述

```
Claude Code 任务完成
    ↓
Stop/SessionEnd Hook 触发
    ↓
执行 Shell 脚本
    ↓
解析任务信息（从 stdin JSON）
    ↓
调用飞书 MCP 工具
    ↓
发送消息到飞书群聊/个人
```

## 前置条件

1. **Claude Code** 已安装并配置
2. **飞书 MCP Server** 已配置（mcp-feishu）
3. **Node.js** 或 **Python** 环境（用于执行 MCP 调用）
4. 飞书应用凭证（tenant_access_token 或 user_access_token）

## 配置步骤

### 1. 创建 Hook 脚本

在项目根目录或全局位置创建 `feishu-report-hook.sh`（或 `.bat` for Windows）：

#### Linux/Mac 版本 (feishu-report-hook.sh)

```bash
#!/bin/bash

# 读取 Claude Code 提供的 hook 数据（从 stdin）
HOOK_DATA=$(cat)

# 解析关键信息
SESSION_ID=$(echo "$HOOK_DATA" | jq -r '.session_id')
TRANSCRIPT_PATH=$(echo "$HOOK_DATA" | jq -r '.transcript_path')
CWD=$(echo "$HOOK_DATA" | jq -r '.cwd')
HOOK_EVENT=$(echo "$HOOK_DATA" | jq -r '.hook_event_name')

# 读取对话历史获取任务摘要
if [ -f "$TRANSCRIPT_PATH" ]; then
    # 提取最后几条消息作为任务摘要
    TASK_SUMMARY=$(jq -r '.messages[-5:] | map(select(.role == "user" or .role == "assistant") | .content[0].text // .content[0].type) | join("\n---\n")' "$TRANSCRIPT_PATH")
else
    TASK_SUMMARY="无法读取任务历史"
fi

# 获取当前时间
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 构建飞书消息内容
MESSAGE_CONTENT=$(cat <<EOF
{
  "msg_type": "interactive",
  "content": "{\"elements\":[{\"tag\":\"markdown\",\"content\":\"📋 **Claude Code 任务完成报告**\\n\\n**会话ID:** $SESSION_ID\\n**完成时间:** $TIMESTAMP\\n**工作目录:** $CWD\\n**Hook事件:** $HOOK_EVENT\\n\\n---\\n\\n**任务摘要:**\\n$TASK_SUMMARY\"}]}"
}
EOF
)

# 调用 MCP 工具发送飞书消息
# 方法1: 使用 npx 直接调用 MCP（如果支持 CLI）
# npx @modelcontextprotocol/server-feishu send-message \
#   --receive_id "your_chat_id" \
#   --content "$MESSAGE_CONTENT"

# 方法2: 使用 Node.js 脚本调用 MCP
node "$(dirname "$0")/send-feishu-message.js" \
  --session_id "$SESSION_ID" \
  --summary "$TASK_SUMMARY" \
  --timestamp "$TIMESTAMP" \
  --cwd "$CWD"

# 方法3: 使用 Python 脚本
# python3 "$(dirname "$0")/send_feishu_message.py" \
#   --session_id "$SESSION_ID" \
#   --summary "$TASK_SUMMARY"

exit 0
```

#### Windows 版本 (feishu-report-hook.bat)

```batch
@echo off
setlocal enabledelayedexpansion

REM 读取 stdin 到临时文件
set TEMP_FILE=%TEMP%\claude_hook_data.json
type > %TEMP_FILE%

REM 使用 PowerShell 解析 JSON 并调用脚本
powershell -ExecutionPolicy Bypass -File "%~dp0\send-feishu-message.ps1" -HookDataFile "%TEMP_FILE%"

del %TEMP_FILE%
exit /b 0
```

### 2. 创建飞书消息发送脚本

#### Node.js 版本 (send-feishu-message.js)

```javascript
#!/usr/bin/env node

const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');

async function sendFeishuReport() {
  // 解析命令行参数
  const args = process.argv.slice(2);
  const params = {};
  for (let i = 0; i < args.length; i += 2) {
    params[args[i].replace('--', '')] = args[i + 1];
  }

  // 创建 MCP 客户端连接到飞书 MCP Server
  const transport = new StdioClientTransport({
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-feishu']
  });

  const client = new Client({
    name: 'claude-code-webhook',
    version: '1.0.0'
  }, {
    capabilities: {}
  });

  await client.connect(transport);

  try {
    // 调用飞书 MCP 的发送消息工具
    const result = await client.callTool({
      name: 'mcp__mcp-feishu__im_v1_message_create',
      arguments: {
        params: {
          receive_id_type: 'chat_id' // 或 'open_id' 发给个人
        },
        data: {
          receive_id: process.env.FEISHU_CHAT_ID || 'your_chat_id_here',
          msg_type: 'text',
          content: JSON.stringify({
            text: `📋 Claude Code 任务完成\n\n` +
                  `会话: ${params.session_id}\n` +
                  `时间: ${params.timestamp}\n` +
                  `目录: ${params.cwd}\n\n` +
                  `摘要:\n${params.summary}`
          })
        }
      }
    });

    console.log('飞书消息发送成功:', result);
  } catch (error) {
    console.error('发送失败:', error);
    process.exit(1);
  } finally {
    await client.close();
  }
}

sendFeishuReport().catch(console.error);
```

#### Python 版本 (send_feishu_message.py)

```python
#!/usr/bin/env python3

import sys
import json
import argparse
import subprocess
from datetime import datetime

def send_feishu_message(session_id, summary, timestamp, cwd):
    """通过飞书 MCP 发送任务报告"""

    # 构建消息内容
    message_text = f"""📋 Claude Code 任务完成报告

会话ID: {session_id}
完成时间: {timestamp}
工作目录: {cwd}

任务摘要:
{summary}
"""

    # 构建 MCP 工具调用参数
    mcp_request = {
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "mcp__mcp-feishu__im_v1_message_create",
            "arguments": {
                "params": {
                    "receive_id_type": "chat_id"
                },
                "data": {
                    "receive_id": "your_chat_id_here",  # 替换为实际的群聊ID
                    "msg_type": "text",
                    "content": json.dumps({"text": message_text})
                }
            }
        },
        "id": 1
    }

    # 调用 MCP Server（通过 stdio）
    # 注意: 这里需要根据实际的 MCP Server 启动方式调整
    try:
        result = subprocess.run(
            ['npx', '-y', '@modelcontextprotocol/server-feishu'],
            input=json.dumps(mcp_request),
            capture_output=True,
            text=True,
            timeout=30
        )

        print(f"飞书消息发送成功: {result.stdout}")
        return 0
    except Exception as e:
        print(f"发送失败: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Send Feishu notification')
    parser.add_argument('--session_id', required=True)
    parser.add_argument('--summary', required=True)
    parser.add_argument('--timestamp', required=True)
    parser.add_argument('--cwd', required=True)

    args = parser.parse_args()

    exit_code = send_feishu_message(
        args.session_id,
        args.summary,
        args.timestamp,
        args.cwd
    )
    sys.exit(exit_code)
```

### 3. 配置 Claude Code Settings

在 Claude Code 的配置文件中添加 Hook 配置。可以在以下位置之一配置：

- **用户级别**: `~/.config/claude-code/settings.json` (Linux/Mac) 或 `%APPDATA%\claude-code\settings.json` (Windows)
- **项目级别**: `.claude/settings.json`
- **本地级别**: `.claude/local_settings.json`

#### settings.json 配置示例

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/feishu-report-hook.sh",
            "timeout": 30000
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/feishu-report-hook.sh",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

**Windows 配置示例**:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "E:\\scripts\\feishu-report-hook.bat",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

### 4. 环境变量配置

在 `.env` 文件或系统环境变量中配置：

```bash
# 飞书应用凭证
FEISHU_APP_ID=cli_xxxxxxxxxxxxxxxx
FEISHU_APP_SECRET=xxxxxxxxxxxxxxxxxxxxxxxx

# 接收消息的群聊ID或用户ID
FEISHU_CHAT_ID=oc_xxxxxxxxxxxxxxxx

# 或者接收消息的用户 open_id
FEISHU_USER_OPEN_ID=ou_xxxxxxxxxxxxxxxx
```

### 5. 赋予执行权限（Linux/Mac）

```bash
chmod +x feishu-report-hook.sh
chmod +x send-feishu-message.js
chmod +x send_feishu_message.py
```

## Hook 事件选择

根据不同需求选择合适的 Hook 事件：

| Hook 事件 | 触发时机 | 适用场景 |
|-----------|----------|----------|
| **Stop** | 主 Agent 完成响应 | 每次任务完成后汇报 |
| **SubagentStop** | 子 Agent 完成任务 | 需要追踪子任务进度 |
| **SessionEnd** | 会话结束时 | 会话级别的总结报告 |
| **PostToolUse** | 每次工具调用后 | 需要详细的工具使用日志 |

## 高级配置

### 1. 条件触发（只在特定情况下汇报）

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'if [ -f .report-enabled ]; then /path/to/feishu-report-hook.sh; fi'",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

### 2. 使用卡片消息（更美观）

修改 `send-feishu-message.js` 使用交互式卡片：

```javascript
const cardContent = {
  elements: [
    {
      tag: "div",
      text: {
        content: "**📋 Claude Code 任务完成报告**",
        tag: "lark_md"
      }
    },
    {
      tag: "hr"
    },
    {
      tag: "div",
      fields: [
        {
          is_short: true,
          text: {
            content: `**会话ID:**\n${params.session_id}`,
            tag: "lark_md"
          }
        },
        {
          is_short: true,
          text: {
            content: `**完成时间:**\n${params.timestamp}`,
            tag: "lark_md"
          }
        }
      ]
    },
    {
      tag: "div",
      text: {
        content: `**工作目录:**\n${params.cwd}`,
        tag: "lark_md"
      }
    },
    {
      tag: "hr"
    },
    {
      tag: "div",
      text: {
        content: `**任务摘要:**\n${params.summary}`,
        tag: "lark_md"
      }
    }
  ],
  header: {
    template: "blue",
    title: {
      content: "🤖 Claude Code 任务完成",
      tag: "plain_text"
    }
  }
};

// 调用时使用
data: {
  receive_id: process.env.FEISHU_CHAT_ID,
  msg_type: 'interactive',
  content: JSON.stringify(cardContent)
}
```

### 3. 智能摘要（使用 AI 生成简洁摘要）

在 hook 脚本中添加：

```bash
# 使用 Claude API 或本地 LLM 生成摘要
SMART_SUMMARY=$(echo "$TASK_SUMMARY" | \
  curl -s -X POST https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{
      "model": "claude-3-haiku-20240307",
      "max_tokens": 200,
      "messages": [{
        "role": "user",
        "content": "请用3-5句话总结以下任务内容：'"$TASK_SUMMARY"'"
      }]
    }' | jq -r '.content[0].text')
```

## 故障排查

### 1. Hook 未执行

检查：
- Hook 脚本是否有执行权限
- 脚本路径是否为绝对路径
- Claude Code 日志中是否有错误信息

### 2. 飞书消息发送失败

检查：
- 飞书应用凭证是否正确
- Chat ID 或 User Open ID 是否有效
- 网络连接是否正常
- MCP Server 是否正常运行

### 3. 调试模式

在 hook 脚本中添加调试日志：

```bash
# 记录所有输入到日志文件
echo "$HOOK_DATA" >> /tmp/claude-hook-debug.log
echo "---" >> /tmp/claude-hook-debug.log
```

## 安全注意事项

⚠️ **重要提醒**：

1. **凭证安全**: 不要在脚本中硬编码 API 密钥，使用环境变量或密钥管理工具
2. **数据脱敏**: 汇报前检查是否包含敏感信息（密码、密钥等）
3. **权限控制**: Hook 脚本以当前用户权限运行，确保权限最小化
4. **代码审查**: 使用第三方 hook 前务必审查代码

## 完整工作流示例

1. 开发者使用 Claude Code 完成任务
2. Claude Code 触发 `Stop` Hook
3. Hook 脚本读取任务信息并解析
4. 调用飞书 MCP 工具发送消息
5. 团队成员在飞书群收到任务完成通知
6. 点击通知可查看详细的任务摘要

## 参考资源

- [Claude Code Hooks 官方文档](https://code.claude.com/docs/en/hooks.md)
- [飞书开放平台文档](https://open.feishu.cn/document)
- [MCP 协议规范](https://modelcontextprotocol.io)
- [飞书 MCP Server](https://github.com/fankaljead/servers/tree/main/src/feishu)

## 贡献与反馈

如有问题或改进建议，欢迎提交 Issue 或 PR。
