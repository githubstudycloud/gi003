# Claude Code 飞书 Webhook 示例

本目录包含配置 Claude Code 在任务结束时调用飞书 MCP 发送通知的完整示例。

## 📁 文件说明

| 文件 | 说明 | 平台 |
|------|------|------|
| `feishu-report-hook.sh` | Hook 主脚本 | Linux/Mac |
| `feishu-report-hook.bat` | Hook 主脚本 | Windows |
| `send-feishu-message.js` | 飞书消息发送脚本 | 跨平台 |
| `settings.json` | Claude Code 配置示例 | 跨平台 |
| `.env.example` | 环境变量配置模板 | 跨平台 |
| `QUICKSTART.md` | 快速入门指南 | - |

## 🚀 快速开始

**初次使用？** 请先阅读 [QUICKSTART.md](QUICKSTART.md)

### 30秒快速配置

```bash
# 1. 复制环境变量配置
cp .env.example .env

# 2. 编辑 .env，填入飞书凭证
nano .env  # 或使用你喜欢的编辑器

# 3. 设置执行权限（Linux/Mac）
chmod +x feishu-report-hook.sh send-feishu-message.js

# 4. 测试脚本
echo '{"session_id":"test","cwd":"'$(pwd)'","hook_event_name":"Stop"}' | ./feishu-report-hook.sh

# 5. 配置 Claude Code
# 将 settings.json 中的内容添加到你的 Claude Code 配置文件
```

## 📋 配置检查清单

在开始之前，确保你已完成：

- [ ] 创建飞书应用并获取 App ID 和 App Secret
- [ ] 将机器人添加到目标群聊
- [ ] 获取群聊的 Chat ID
- [ ] 配置应用权限（im:message, im:message:send_as_bot）
- [ ] 安装 Node.js (v16+)
- [ ] 安装 jq 工具（Linux/Mac）

## 🔧 使用方法

### 方式一：用户级别配置（全局生效）

编辑 `~/.config/claude-code/settings.json`（Linux/Mac）或
`%APPDATA%\claude-code\settings.json`（Windows）：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/feishu-report-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### 方式二：项目级别配置（仅当前项目）

在项目根目录创建 `.claude/settings.json`：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "./examples/feishu-report-hook.sh"
          }
        ]
      }
    ]
  }
}
```

## 🎯 Hook 事件类型

根据需求选择合适的 Hook 事件：

### Stop
- **触发时机**: 每次任务完成后
- **适用场景**: 实时任务进度通知
- **频率**: 高（每个任务都会触发）

```json
"Stop": [...]
```

### SessionEnd
- **触发时机**: 会话结束时
- **适用场景**: 会话级别的总结报告
- **频率**: 低（仅会话结束时）

```json
"SessionEnd": [...]
```

### SubagentStop
- **触发时机**: 子 Agent 完成任务
- **适用场景**: 追踪子任务进度
- **频率**: 中等

```json
"SubagentStop": [...]
```

### PostToolUse
- **触发时机**: 每次工具调用后
- **适用场景**: 详细的工具使用日志
- **频率**: 非常高

```json
"PostToolUse": [
  {
    "matcher": "Write|Edit",  // 仅监控写入和编辑操作
    "hooks": [...]
  }
]
```

## 📊 消息格式

### 文本消息
```
📋 Claude Code 任务完成

会话ID: abc123
完成时间: 2025-01-15 14:30:00
Hook事件: Stop
工作目录: /path/to/project

━━━━━━━━━━━━━━━━

任务摘要:
👤 用户: 创建一个计算器应用
🤖 Claude: 已创建 calculator.js...
```

### 卡片消息
![卡片消息示例](https://via.placeholder.com/600x400?text=Feishu+Card+Message)

设置 `FEISHU_USE_CARD=true` 启用卡片消息。

## 🐛 故障排查

### 检查 Hook 是否执行

```bash
# 查看日志
tail -f /tmp/claude-feishu-hook.log
```

### 手动测试 Hook 脚本

```bash
# 模拟 Claude Code 的输入
cat > /tmp/test-hook-input.json << 'EOF'
{
  "session_id": "test-session-123",
  "cwd": "/path/to/project",
  "hook_event_name": "Stop",
  "transcript_path": ""
}
EOF

# 运行 Hook
cat /tmp/test-hook-input.json | ./feishu-report-hook.sh
```

### 检查环境变量

```bash
# Linux/Mac
env | grep FEISHU

# Windows
set | findstr FEISHU
```

### 验证飞书 API 连接

```bash
# 测试获取 token
curl -X POST https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal \
  -H "Content-Type: application/json" \
  -d '{
    "app_id": "'"$FEISHU_APP_ID"'",
    "app_secret": "'"$FEISHU_APP_SECRET"'"
  }'
```

## 🔒 安全建议

1. **不要在代码中硬编码凭证**
   - 使用环境变量或密钥管理工具
   - 将 `.env` 添加到 `.gitignore`

2. **限制 Hook 权限**
   - 脚本应以最小必要权限运行
   - 避免在 Hook 中执行危险命令

3. **数据脱敏**
   - 检查任务摘要中是否包含敏感信息
   - 考虑添加过滤逻辑

```javascript
// 在 send-feishu-message.js 中添加
function sanitizeSummary(summary) {
  return summary
    .replace(/password[=:]\s*\S+/gi, 'password=***')
    .replace(/token[=:]\s*\S+/gi, 'token=***')
    .replace(/secret[=:]\s*\S+/gi, 'secret=***');
}
```

4. **代码审查**
   - 使用第三方脚本前务必审查代码
   - 定期更新依赖项

## 📈 高级用例

### 1. 发送到多个群聊

```bash
# .env
FEISHU_CHAT_IDS=oc_chat1,oc_chat2,oc_chat3
```

### 2. 条件触发（只在构建任务时通知）

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'if echo $HOOK_DATA | jq -r .tool_name | grep -q build; then /path/to/hook.sh; fi'"
          }
        ]
      }
    ]
  }
}
```

### 3. 智能摘要（使用 AI）

在 `feishu-report-hook.sh` 中添加：

```bash
# 使用 Claude API 生成简洁摘要
SMART_SUMMARY=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "max_tokens": 200,
    "messages": [{
      "role": "user",
      "content": "用3句话总结：'"$TASK_SUMMARY"'"
    }]
  }' | jq -r '.content[0].text')
```

### 4. 添加任务统计

```javascript
// 在 send-feishu-message.js 中添加
const stats = {
  totalMessages: transcript.messages.length,
  toolCalls: transcript.messages.filter(m => m.tool_calls).length,
  duration: calculateDuration(transcript)
};
```

## 🔗 相关资源

- [Claude Code Hooks 文档](https://code.claude.com/docs/en/hooks.md)
- [飞书开放平台](https://open.feishu.cn/document)
- [MCP 协议规范](https://modelcontextprotocol.io)
- [完整配置指南](../claude-code-feishu-webhook-guide.md)

## 💡 提示

- 建议先在测试群聊中验证
- 使用 `Stop` Hook 可能产生大量通知，考虑添加过滤条件
- Windows 用户可以使用 PowerShell 脚本替代 .bat
- 可以结合 GitHub Actions 实现 CI/CD 通知

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可

MIT License
