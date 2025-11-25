# 快速开始：配置 Claude Code 飞书通知

本指南帮助你在 5 分钟内完成 Claude Code 到飞书的任务完成通知配置。

## 前置要求

- ✅ 已安装 Claude Code
- ✅ 已安装 Node.js (v16+)
- ✅ 拥有飞书账号和机器人权限

## 步骤 1: 获取飞书应用凭证

### 1.1 创建飞书应用

1. 访问 [飞书开放平台](https://open.feishu.cn/app)
2. 点击"创建企业自建应用"
3. 填写应用名称（如："Claude Code 通知助手"）
4. 上传应用图标（可选）

### 1.2 获取凭证

在应用详情页，找到：
- **App ID**: `cli_xxxxxxxxx`
- **App Secret**: `xxxxxxxxxxxxx`

### 1.3 配置权限

进入"权限管理"，添加以下权限：

- `im:message` - 获取与发送单聊、群组消息
- `im:message:send_as_bot` - 以应用的身份发消息

点击"发布版本"使权限生效。

### 1.4 获取群聊 ID

**方法 1: 通过飞书客户端**

1. 打开要接收通知的群聊
2. 点击右上角 "..." → "群设置"
3. 找到"群ID"或"Chat ID"（格式：`oc_xxxxx`）

**方法 2: 通过 API**

```bash
# 将机器人添加到群聊后，调用以下接口
curl -X GET \
  'https://open.feishu.cn/open-apis/im/v1/chats' \
  -H 'Authorization: Bearer YOUR_TENANT_ACCESS_TOKEN'
```

## 步骤 2: 配置环境变量

复制示例配置文件：

```bash
cp examples/.env.example .env
```

编辑 `.env` 文件，填入你的凭证：

```bash
FEISHU_APP_ID=cli_你的AppID
FEISHU_APP_SECRET=你的AppSecret
FEISHU_CHAT_ID=oc_你的群聊ID
FEISHU_USE_CARD=true
```

**Windows 用户**：也可以在系统环境变量中配置，或使用 PowerShell：

```powershell
$env:FEISHU_APP_ID="cli_你的AppID"
$env:FEISHU_APP_SECRET="你的AppSecret"
$env:FEISHU_CHAT_ID="oc_你的群聊ID"
```

## 步骤 3: 安装依赖

确保项目目录下有 `package.json`，如果没有则创建：

```bash
npm init -y
```

安装必要的依赖（如果使用 Node.js 脚本）：

```bash
# 如果使用 @modelcontextprotocol/sdk
npm install @modelcontextprotocol/sdk

# 或者仅使用 child_process（Node.js 内置，无需安装）
```

## 步骤 4: 设置脚本权限

### Linux/Mac:

```bash
cd examples
chmod +x feishu-report-hook.sh
chmod +x send-feishu-message.js
```

### Windows:

无需额外操作，`.bat` 文件默认可执行。

## 步骤 5: 配置 Claude Code Hooks

### 5.1 找到配置文件位置

**用户级别配置**（推荐）：
- Linux/Mac: `~/.config/claude-code/settings.json`
- Windows: `%APPDATA%\claude-code\settings.json`

**项目级别配置**：
- 在项目根目录创建 `.claude/settings.json`

### 5.2 编辑配置文件

打开 `settings.json`，添加或修改 `hooks` 配置：

**Linux/Mac 示例**:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/你的用户名/path/to/examples/feishu-report-hook.sh",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

**Windows 示例**:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "E:\\path\\to\\examples\\feishu-report-hook.bat",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

⚠️ **重要提示**：
- 路径必须是**绝对路径**
- Windows 路径使用 `\\` 或 `/`
- 确保路径中没有拼写错误

### 5.3 修改脚本中的路径

编辑 `feishu-report-hook.sh` (或 `.bat`)，确保 `SEND_SCRIPT` 路径正确：

```bash
# Linux/Mac
SEND_SCRIPT="$SCRIPT_DIR/send-feishu-message.js"

# Windows (在 .bat 中)
set SEND_SCRIPT=%SCRIPT_DIR%send-feishu-message.js
```

## 步骤 6: 测试配置

### 6.1 手动测试脚本

```bash
# Linux/Mac
cd examples
echo '{"session_id":"test123","cwd":"'$(pwd)'","hook_event_name":"Stop","transcript_path":""}' | ./feishu-report-hook.sh

# Windows
cd examples
echo {"session_id":"test123","cwd":"%CD%","hook_event_name":"Stop","transcript_path":""} | feishu-report-hook.bat
```

如果配置正确，你应该在飞书群聊中收到测试消息。

### 6.2 测试 Claude Code 集成

1. 启动 Claude Code
2. 执行一个简单任务（如："创建一个 hello.txt 文件"）
3. 等待任务完成
4. 检查飞书群聊是否收到通知

## 步骤 7: 调试（如果出现问题）

### 查看日志

```bash
# Linux/Mac
tail -f /tmp/claude-feishu-hook.log

# Windows
type %TEMP%\claude-feishu-hook.log
```

### 常见问题

#### 问题 1: 收不到消息

**检查清单**：
- [ ] 飞书应用是否已添加到目标群聊？
- [ ] 环境变量是否正确设置？
- [ ] Chat ID 是否正确？
- [ ] 应用权限是否已发布？

#### 问题 2: Hook 未执行

**检查清单**：
- [ ] 脚本路径是否为绝对路径？
- [ ] 脚本是否有执行权限？（Linux/Mac）
- [ ] Claude Code 配置文件语法是否正确？
- [ ] 查看 Claude Code 日志

#### 问题 3: jq 命令未找到（Linux/Mac）

```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq

# CentOS/RHEL
sudo yum install jq
```

#### 问题 4: Node.js 版本过低

```bash
# 检查版本
node --version

# 升级 Node.js (使用 nvm)
nvm install 18
nvm use 18
```

## 步骤 8: 高级配置（可选）

### 8.1 只在特定项目启用

在项目根目录创建 `.claude/settings.json`，而不是全局配置。

### 8.2 自定义消息格式

编辑 `send-feishu-message.js` 中的 `buildCardMessage` 或 `buildTextMessage` 函数。

### 8.3 添加条件过滤

只在特定情况下发送通知：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/feishu-report-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### 8.4 多个接收者

修改 `send-feishu-message.js`，支持发送到多个群聊：

```javascript
const chatIds = (process.env.FEISHU_CHAT_IDS || '').split(',');
for (const chatId of chatIds) {
  // 发送消息到每个群聊
}
```

## 完成！🎉

现在，每当 Claude Code 完成任务时，你都会在飞书中收到通知。

## 下一步

- 📖 阅读完整文档：[claude-code-feishu-webhook-guide.md](../claude-code-feishu-webhook-guide.md)
- 🔧 查看更多配置选项
- 🎨 自定义消息样式
- 🔔 配置其他 Hook 事件（SessionEnd、SubagentStop 等）

## 获取帮助

遇到问题？
- 查看 [完整文档](../claude-code-feishu-webhook-guide.md#故障排查)
- 检查日志文件
- 在 Issues 中提问

---

**提示**：建议先在测试群聊中验证配置，确认无误后再应用到正式群聊。
