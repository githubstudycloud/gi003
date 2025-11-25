# Cline与其他CLI工具快速指南

## 目录
- [Cline完整指南](#cline完整指南)
- [Codex CLI快速参考](#codex-cli快速参考)
- [Gemini CLI快速参考](#gemini-cli快速参考)
- [GitHub Copilot CLI快速参考](#github-copilot-cli快速参考)
- [工具对比总结](#工具对比总结)

---

## Cline完整指南

### 概述

**Cline**(前身Roo Coder)是VSCode扩展,作为自主AI编码代理:
- 🤖 支持多种AI模型(Anthropic, OpenAI, Gemini, DeepSeek)
- 🔧 可执行终端命令、浏览网页、编辑文件
- 👤 人机协作循环(需要批准每个操作)
- 📊 成本追踪
- 🔄 工作区快照与回滚

### 安装

```bash
# 方式1: VSCode扩展商店
# 搜索 "Cline" 或 ID: saoudrizwan.claude-dev

# 方式2: 命令行安装
code --install-extension saoudrizwan.claude-dev

# 方式3: JetBrains(如果支持)
# 从插件市场搜索Cline
```

### 首次配置

1. **安装后重启VSCode**
2. **打开Cline侧边栏**(左侧图标)
3. **选择AI提供商**:
   - Anthropic (推荐)
   - OpenAI
   - Google Gemini
   - AWS Bedrock
   - OpenRouter
   - 本地模型(Ollama/LM Studio)

4. **输入API密钥**

### 基本使用

#### 启动任务

```
1. 点击Cline侧边栏
2. 在输入框描述任务:
   "添加用户认证功能"
3. 可选: 添加图片(截图、设计图)
4. 按Enter发送
```

#### 审批工作流

```
Cline: 我将执行以下操作:
  1. 创建 src/auth.py
  2. 修改 src/app.py
  3. 运行 pip install pyjwt

[Approve] [Reject] [Edit]
```

点击 **[Approve]** 批准,或 **[Reject]** 拒绝。

#### 工作区快照

每个步骤Cline都会创建快照:
- 点击 **[Compare]** 查看diff
- 点击 **[Restore]** 回滚到该步骤

### Auto-Approve配置

#### 打开Auto-Approve设置

1. 点击Cline界面的 **"Auto Approve"** 区域
2. 配置以下选项:

#### Auto-Approve选项

```json
{
  "autoApprove": {
    "readFiles": true,           // 自动批准读取文件
    "editFiles": false,          // 需要批准编辑
    "executeCommands": false,    // 需要批准命令执行
    "useBrowser": true,          // 自动批准浏览器操作
    "useMCP": true,              // 自动批准MCP工具
    "maxApiRequests": 30         // 连续请求上限
  }
}
```

#### 推荐配置级别

**保守模式**(新手):
```json
{
  "readFiles": true,
  "editFiles": false,
  "executeCommands": false,
  "maxApiRequests": 10
}
```

**平衡模式**:
```json
{
  "readFiles": true,
  "editFiles": true,
  "executeCommands": false,
  "maxApiRequests": 30
}
```

**完全自主模式**(仅沙箱环境):
```json
{
  "readFiles": true,
  "editFiles": true,
  "executeCommands": true,
  "useBrowser": true,
  "useMCP": true,
  "maxApiRequests": 999
}
```

### Cline Rules(.clinerules)

定义项目级别的持久性指导规则。

#### 方式1: 单文件

创建 `.clinerules` (项目根目录):
```
项目使用Python 3.11+ 和FastAPI

代码规范:
- 遵循PEP 8
- 使用类型注解
- Docstring使用Google风格

测试:
- 使用pytest
- 覆盖率要求>80%

Git:
- Commit消息遵循Conventional Commits
- 中文描述
```

#### 方式2: 多文件

创建 `.clinerules/` 目录:

`.clinerules/style.md`:
```markdown
# 代码风格

- Python: PEP 8
- 单引号优于双引号
- 每行最多88字符
```

`.clinerules/testing.md`:
```markdown
# 测试规范

- 框架: pytest
- 覆盖率: >80%
- 所有公共函数必须有测试
```

`.clinerules/security.md`:
```markdown
# 安全规范

- 不在代码中硬编码密钥
- 使用环境变量
- 输入验证
```

### Plan & Act模式

**启用Plan & Act**:
```
设置 -> Cline -> Workflow Mode -> "Plan & Act"
```

**工作流**:
1. **Planning阶段**: Cline分析任务,生成详细计划
2. **Review阶段**: 你审查计划,批准/修改
3. **Execution阶段**: Cline执行计划

**优势**:
- 代码质量更高
- 提前发现问题
- 明确的执行路径

### MCP集成

Cline支持Model Context Protocol,可连接外部工具。

#### 配置MCP Server

在VSCode设置中配置MCP服务器:

```json
{
  "cline.mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://..."
      }
    }
  }
}
```

#### 使用MCP工具

```
You: 查询数据库中所有活跃用户

Cline会自动使用postgres MCP server执行查询
```

#### 创建自定义MCP工具

```
You: 添加一个工具来检查API健康状态

Cline: 我将创建MCP工具...
[创建custom-health-check.js]
```

### 快捷操作

#### 星标快速切换

使用"星"图标快速切换auto-approve设置:
- ⭐ 启用
- ☆ 禁用

#### 快速命令

在Cline输入框:
- `@file.py` - 引用文件
- `@folder/` - 引用文件夹
- 拖放文件到输入框

### 成本管理

Cline显示实时成本追踪:
```
当前任务:
- Tokens: 45,230
- 估计成本: $0.68
- API调用: 12次
```

**降低成本**:
1. 设置 `maxApiRequests` 限制
2. 使用较便宜的模型(如GPT-3.5-turbo)
3. 及时结束不需要的任务
4. 使用本地模型(Ollama)

### Cline CLI(实验性)

某些版本支持CLI模式:
```bash
# 如果可用
cline --auto-approve-all "添加用户认证"

# 或通过VSCode命令行
code --command cline.execute "任务描述"
```

### 常见问题

#### Q: Cline卡住不动?
**A**: 检查是否在等待批准。查看Cline界面是否有 [Approve] 按钮。

#### Q: 如何撤销Cline的更改?
**A**: 使用工作区快照的 [Restore] 按钮,或使用Git回滚。

#### Q: Cline费用太高?
**A**:
1. 设置 `maxApiRequests` 限制
2. 使用Plan & Act模式减少迭代
3. 切换到更便宜的模型

#### Q: 如何在团队中共享Cline配置?
**A**: 将 `.clinerules` 提交到git仓库,团队成员会自动使用。

### 最佳实践

1. **从小任务开始**: 测试Cline的能力
2. **使用Cline Rules**: 确保一致的代码风格
3. **Plan & Act模式**: 复杂任务使用规划模式
4. **监控成本**: 设置请求上限
5. **Git保护**: 始终用Git管理代码
6. **审查更改**: 不要盲目批准所有操作

---

## Codex CLI快速参考

### 概述

OpenAI的官方CLI编码代理,轻量级且强大。

### 安装

```bash
# 通过npm安装
npm install -g @openai/codex-cli

# 或使用npx(无需安装)
npx @openai/codex-cli
```

### 基本用法

```bash
# 启动Codex
codex

# 直接执行任务
codex -p "添加用户认证功能"

# 指定文件
codex --files src/auth.py,src/models.py -p "重构认证系统"
```

### 沙箱模式

| 模式 | 权限 | 网络 | 使用场景 |
|------|------|------|---------|
| `balanced` | 只读当前目录 | ❌ | 默认,最安全 |
| `workspace-write` | 读写工作区 | ✅ | 开发环境 |
| `danger-full-access` | 全系统访问 | ✅ | 仅容器 |

```bash
# 指定沙箱模式
codex --sandbox workspace-write

# 工作区自动模式
codex -a never -s workspace-write -p "任务"

# 完全危险模式(仅容器)
codex --dangerously-bypass-approvals-and-sandbox -p "任务"
```

### 审批策略

```bash
# 总是询问(默认)
codex --ask-for-approval always

# 从不询问
codex --ask-for-approval never
codex -a never

# 失败时询问
codex --ask-for-approval on-failure

# 完全自动(工作区)
codex --full-auto
# 等价于: -a on-failure -s workspace-write
```

### 配置文件

`~/.config/codex/config.yaml`:
```yaml
# 审批策略
approval_policy: always  # always, never, on-failure

# 沙箱模式
sandbox_mode: balanced   # balanced, workspace-write, danger-full-access

# 默认模型
model: gpt-4o

# 日志级别
log_level: info
```

### 测试沙箱

```bash
# 测试命令在沙箱中的行为
codex sandbox macos "ls -la"
codex sandbox linux "cat /etc/passwd"
```

### 最佳实践

```bash
# ✅ 推荐: 开发环境
codex -a never -s workspace-write

# ✅ CI/CD
codex --full-auto -p "运行测试"

# ❌ 避免: 生产环境
codex --dangerously-bypass-approvals-and-sandbox
```

---

## Gemini CLI快速参考

### 概述

Google的官方CLI工具,**完全免费开源**。

### 安装

```bash
# 自动安装(推荐)
curl -fsSL https://gemini.google.com/install.sh | bash

# 或使用npm
npm install -g @google/gemini-cli

# 在Google Cloud Shell中预装
# 无需安装,直接使用
```

### 基本用法

```bash
# 启动Gemini CLI
gemini

# 直接执行任务
gemini "添加用户认证功能"

# 自动确认模式
gemini -y "修复所有lint错误"

# 指定文件
gemini --files src/auth.py "重构这个文件"
```

### GEMINI.md文件

项目级别的持久性上下文。

创建 `GEMINI.md` (项目根目录):
```markdown
# 项目上下文

这是一个FastAPI项目,使用PostgreSQL数据库。

## 代码规范
- Python 3.11+
- 类型注解必须
- Docstring使用Google风格

## 测试
- pytest框架
- 覆盖率>80%

## 常用命令
- 运行: `uvicorn main:app --reload`
- 测试: `pytest tests/`
- Lint: `ruff check .`
```

Gemini会自动读取并遵循这些规则。

### Memory管理

```bash
# 添加到Gemini的记忆
gemini
> /memory add 数据库端口是5432
> /memory add API密钥存储在.env文件

# 查看记忆
> /memory list

# 这些信息会在后续对话中使用
```

### 搜索功能

```bash
# 使用内置@search工具
> @search 如何使用FastAPI的依赖注入?

# 搜索GitHub issues
> @search github:fastapi/fastapi dependency injection

# 网页搜索
> @search web:python async best practices
```

### JSON输出(脚本化)

```bash
# 结构化输出
gemini --output-format json "分析src/api.py的问题"

# 输出示例:
# {
#   "issues": [
#     {"type": "performance", "line": 42, "description": "N+1 query"},
#     {"type": "security", "line": 58, "description": "SQL injection risk"}
#   ]
# }

# 在脚本中解析
result=$(gemini --output-format json "..." | jq '.issues | length')
echo "发现 $result 个问题"
```

### 项目上下文

```bash
# 确保在项目目录中运行
cd /path/to/project

# Gemini会:
# 1. 自动加载GEMINI.md
# 2. 分析项目结构
# 3. 理解依赖关系
gemini "添加新功能"
```

### Gemini 3 Pro功能

使用最新的Gemini 3 Pro模型:

```bash
# 指定模型(如果支持)
gemini --model gemini-3-pro "复杂的架构设计任务"
```

**Gemini 3 Pro优势**:
- 更强的推理能力
- 更好的代码理解
- 支持更复杂的工具使用
- Agentic coding能力

### 自托管

Gemini CLI完全开源,可以自托管:

```bash
# Clone仓库
git clone https://github.com/google-gemini/gemini-cli
cd gemini-cli

# 安装依赖
npm install

# 配置API密钥
export GEMINI_API_KEY=your-key

# 运行
npm start
```

### 最佳实践

1. **创建GEMINI.md**: 提供项目上下文
2. **使用/memory**: 记录重要信息
3. **在项目目录运行**: 让Gemini理解项目结构
4. **使用@search**: 查找最新信息
5. **JSON输出**: 脚本化集成

---

## GitHub Copilot CLI快速参考

### 概述

GitHub官方CLI工具,与Copilot集成。

### 安装

```bash
# 安装GitHub CLI(如果未安装)
brew install gh  # macOS
# 或访问 https://cli.github.com/

# 安装Copilot扩展
gh extension install github/gh-copilot

# 更新到最新版
gh extension upgrade gh-copilot
```

### 认证

```bash
# 登录GitHub
gh auth login

# 验证Copilot访问
gh copilot --version
```

### 基本用法

```bash
# 方式1: 解释命令
gh copilot explain "tar -xzf file.tar.gz"

# 方式2: 建议命令
gh copilot suggest "如何查找大于100MB的文件"

# 输出:
# 建议: find . -type f -size +100M
# [执行] [复制] [解释] [重新生成]
```

### 编程任务

```bash
# 代码生成建议
gh copilot suggest "Python函数计算斐波那契数列"

# Shell命令建议
gh copilot suggest -t shell "批量重命名文件"

# Git命令建议
gh copilot suggest -t git "撤销最近3次提交"
```

### 自动审批模式

```bash
# 允许所有工具
gh copilot --allow-all-tools -p "任务描述"

# 允许所有路径
gh copilot --allow-all-paths -p "任务描述"

# 完全自动(CI/CD)
gh copilot --allow-all-tools --allow-all-paths -p "运行测试并生成报告"
```

### 信任目录

```bash
# 添加信任目录
gh copilot trust add /path/to/project

# 列出信任目录
gh copilot trust list

# 移除信任
gh copilot trust remove /path/to/project

# 在信任目录中自动运行
cd /trusted/project
gh copilot --allow-all-tools -p "任务"
```

### 配置

```bash
# 查看配置
gh copilot config

# 设置编辑器
gh copilot config set editor vim

# 设置模型(如果可选)
gh copilot config set model gpt-4
```

### 交互模式

```bash
# 进入交互式会话
gh copilot

# 在会话中:
> 如何优化Docker镜像大小?
> 给我一个GitHub Actions工作流模板
> 解释git rebase的工作原理
```

### 最佳实践

1. **信任目录**: 对常用项目添加信任
2. **类型提示**: 使用 `-t` 指定命令类型
3. **CI/CD**: 使用 `--allow-all-*` 用于自动化
4. **安全**: 仅在安全环境使用自动审批

---

## 工具对比总结

### 快速选择指南

| 需求 | 推荐工具 | 理由 |
|------|---------|------|
| **开源免费** | Aider | 完全开源,功能强大 |
| **完全免费** | Gemini CLI | Google提供,无需付费 |
| **代码质量优先** | Claude Code | 最佳代码质量 |
| **IDE集成** | Cline | VSCode原生体验 |
| **CLI重度用户** | Aider | 最佳CLI体验 |
| **GitHub生态** | Copilot CLI | 无缝集成 |
| **企业/合规** | Codex CLI | OpenAI官方支持 |

### 功能对比矩阵

| 功能 | Aider | Claude Code | Cline | Codex | Gemini | Copilot |
|------|-------|-------------|-------|-------|--------|---------|
| **开源** | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ |
| **免费** | ✅(付API) | ❌ | ✅(付API) | ❌ | ✅ | ❌ |
| **多模型** | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ |
| **Git集成** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **IDE集成** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **CLI体验** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **上下文窗口** | 依模型 | 200K稳定 | 依模型 | 128K | 1M(Gemini 1.5) | 依模型 |
| **自动化** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

### 成本对比(月均)

| 工具 | 个人用户 | 团队(10人) | 说明 |
|------|---------|-----------|------|
| **Aider** | $10-30 | $100-300 | 仅API费用 |
| **Claude Code** | $20-100 | $200-1000 | 订阅制 |
| **Cline** | $10-50 | $100-500 | 仅API费用 |
| **Codex CLI** | $20 | $200 | OpenAI订阅 |
| **Gemini CLI** | $0 | $0 | 完全免费 |
| **Copilot CLI** | $10-19 | $190 | GitHub订阅 |

### 使用场景推荐

#### 个人开发者

```
预算充足: Claude Code
预算有限: Aider + DeepSeek
完全免费: Gemini CLI
```

#### 小团队(2-10人)

```
快速迭代: Cline(VSCode)
代码质量: Claude Code
成本敏感: Aider + 自选模型
```

#### 大团队(10+人)

```
标准化: GitHub Copilot CLI
企业合规: Codex CLI
混合方案: Aider + Claude Code
```

#### CI/CD集成

```
最佳: Aider(脚本化能力强)
备选: Codex CLI, Gemini CLI
```

---

## 总结

### 工具矩阵

**开源免费**: Aider, Cline, Gemini CLI
**付费订阅**: Claude Code, Codex CLI, Copilot CLI
**CLI优先**: Aider, Codex, Gemini
**IDE优先**: Cline, Copilot
**代码质量**: Claude Code > Aider > Cline
**性价比**: Gemini CLI (免费) > Aider > Cline

### 学习路径

1. **入门**: 从Gemini CLI或Aider开始
2. **进阶**: 尝试Claude Code的Plan模式
3. **专业**: 根据工作流选择合适工具
4. **混合**: 多工具组合使用

### 混合使用策略

```bash
# 日常开发: Cline(IDE内)
# 批量任务: Aider(命令行)
# 复杂架构: Claude Code(深度推理)
# 快速查询: Gemini CLI(免费)
# Git操作: Copilot CLI(GitHub集成)
```

---

*更新时间: 2025年1月*
