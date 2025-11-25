# Claude Code 完整使用指南

## 目录
- [概述](#概述)
- [安装与配置](#安装与配置)
- [基础用法](#基础用法)
- [高级功能](#高级功能)
- [CLI参考](#cli参考)
- [快捷键大全](#快捷键大全)
- [自定义与扩展](#自定义与扩展)
- [最佳实践](#最佳实践)
- [实战技巧](#实战技巧)

---

## 概述

### 什么是Claude Code?

Claude Code是Anthropic官方推出的AI编程助手,集成在命令行和IDE中:
- 🤖 基于Claude 3.5 Sonnet及最新模型
- 💻 原生终端体验
- 🔧 深度工具集成
- 🎯 专注代码质量

### 核心特性

| 特性 | 说明 |
|------|------|
| **200K上下文窗口** | 稳定的超大上下文,适合大型项目 |
| **深度代码推理** | 卓越的代码质量和架构理解 |
| **Plan模式** | Extended Thinking用于复杂任务规划 |
| **MCP集成** | 可扩展工具协议 |
| **Sub-Agents** | 专用子代理处理特定任务 |
| **自定义命令** | Slash命令系统 |

### 与Aider对比

| 维度 | Claude Code | Aider |
|------|-------------|-------|
| 开发商 | Anthropic官方 | 开源社区 |
| 价格 | $20-100/月 | 免费(付API费) |
| 上下文 | 200K稳定 | 依模型而定 |
| 模型支持 | Claude系列 | 多模型 |
| Git集成 | 标准 | 深度集成 |
| 扩展性 | MCP协议 | 有限 |

---

## 安装与配置

### 安装Claude Code

```bash
# macOS (Homebrew)
brew install anthropics/claude/claude

# 或使用安装脚本
curl -fsSL https://claude.ai/install.sh | sh

# Windows (通过安装器)
# 从 https://claude.ai/download 下载

# Linux
curl -fsSL https://claude.ai/install.sh | sh
```

### 初次配置

```bash
# 1. 登录认证
claude auth login

# 2. 验证安装
claude --version

# 3. 查看帮助
claude --help
```

### API密钥配置

```bash
# 设置API密钥
export ANTHROPIC_API_KEY=sk-ant-xxxxx

# 或使用配置文件
claude config set api_key sk-ant-xxxxx

# 查看当前配置
claude config list
```

### 全局配置

创建 `~/.claude/settings.json`:
```json
{
  "apiKey": "sk-ant-xxxxx",
  "defaultModel": "claude-3-5-sonnet-20250219",
  "autoAccept": false,
  "theme": "dark",
  "cachePrompts": true,
  "verbose": false
}
```

### 项目级配置

创建项目根目录的 `.claude/settings.json`:
```json
{
  "rules": "遵循Python PEP 8规范",
  "testFramework": "pytest",
  "language": "zh-CN",
  "hooks": {
    "pre-edit": "npm run lint",
    "post-edit": "npm test"
  }
}
```

### 配置层级

优先级: **本地项目 > 项目 > 用户全局**

```
~/.claude/settings.json          # 用户全局
  └─ project/.claude/settings.json    # 项目级
      └─ project/.claude/settings.local.json  # 本地(不提交git)
```

---

## 基础用法

### 启动Claude Code

```bash
# 1. 基本启动
claude

# 2. 带提示词直接执行
claude -p "添加用户认证功能"

# 3. Headless模式(无交互界面)
claude -p "修复lint错误" --headless

# 4. 指定文件
claude --files src/auth.py,src/models.py

# 5. 跳过权限确认(危险)
claude --dangerously-skip-permissions -p "重构代码"
```

### 基本对话流程

```bash
$ claude

# Claude启动,显示欢迎信息

You: 分析src/api.py的性能瓶颈

# Claude分析代码并回复

Claude: 我发现以下性能问题:
1. N+1查询问题
2. 缺少数据库索引
3. 未使用缓存

是否要我修复这些问题?

You: 是的,修复N+1查询

# Claude会请求权限编辑文件
# 按Enter确认或输入"skip"跳过
```

### 文件引用

```bash
# 方式1: @符号引用文件
You: 重构 @src/auth.py 使用async/await

# 方式2: 拖放文件(GUI终端)
# 直接将文件拖到终端

# 方式3: 引用文件夹
You: 优化 @src/services/ 下的所有文件

# 方式4: 引用URL
You: 根据 @https://docs.python.org/3/library/asyncio.html 实现异步任务队列
```

### 图片输入

```bash
# macOS截图快捷键
Cmd+Ctrl+Shift+4  # 截图到剪贴板

# 在Claude中粘贴(注意是Ctrl+V不是Cmd+V)
You: Ctrl+V
     根据这个设计图实现UI

# 或拖放图片文件
# 将PNG/JPG文件拖到终端
```

---

## 高级功能

### 1. Plan模式(Extended Thinking)

Plan模式让Claude进行深度思考后再执行。

#### 触发Plan模式

```bash
# 方式1: 使用关键词
You: think 如何重构这个复杂的认证系统?

# 方式2: 更深度思考
You: think hard 设计一个高可用的分布式缓存架构

# 方式3: 极限思考(消耗更多tokens)
You: ultrathink 从零设计整个微服务架构
```

#### Plan模式工作流

```bash
You: think hard 优化整个数据库层

# Claude进入Plan模式:
# - 分析当前架构
# - 识别问题
# - 设计解决方案
# - 制定实施步骤

Claude: [Plan Mode]
正在深度分析...
问题识别:
1. 缺少连接池
2. N+1查询
3. 无读写分离
...

解决方案:
1. 引入SQLAlchemy连接池
2. 实现eager loading
3. 配置主从复制

是否按此计划执行?

You: 是的,开始执行

# Claude会逐步实施计划
```

#### 退出Plan模式

```bash
# Plan模式完成后自动退出
# 或手动退出
You: 退出plan模式
```

### 2. Sub-Agents(子代理)

Sub-agents是专用的AI助手,每个有独立的上下文和工具。

#### 内置Sub-Agents

| Sub-Agent | 用途 | 何时使用 |
|-----------|------|---------|
| **Explore** | 代码库探索 | 理解项目结构 |
| **Debug** | 调试问题 | 修复bug |
| **Review** | 代码审查 | 检查代码质量 |
| **Test** | 测试生成 | 创建测试用例 |
| **Docs** | 文档编写 | 生成文档 |

#### 使用Sub-Agent

```bash
# 自动触发(Claude判断)
You: 探索这个项目的架构

# Claude会自动启动Explore sub-agent

# 手动指定sub-agent(如果支持)
You: @explore 找到所有API端点
You: @review 审查src/api.py
You: @test 为auth模块生成测试
```

#### 并行Sub-Agents

```bash
# 开启2-3个Claude实例
# Terminal 1
$ claude
You: 实现用户认证

# Terminal 2
$ claude
You: 实现支付集成

# Terminal 3
$ claude
You: 编写API文档

# 各实例独立工作,互不干扰
```

### 3. MCP集成(Model Context Protocol)

MCP让Claude连接外部工具和服务。

#### 配置MCP Server

创建 `.mcp.json` 在项目根目录:
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://..."
      }
    },
    "sentry": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sentry"],
      "env": {
        "SENTRY_ORG": "my-org",
        "SENTRY_PROJECT": "my-project",
        "SENTRY_AUTH_TOKEN": "..."
      }
    },
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    }
  }
}
```

#### 使用MCP工具

```bash
You: 查询数据库中活跃用户数量

# Claude使用postgres MCP server

Claude: 执行查询... 当前有1,234个活跃用户

You: 查看Sentry中最近的错误

# Claude使用sentry MCP server

Claude: 最近7天有23个错误,最频繁的是...

You: 打开example.com并截图

# Claude使用puppeteer MCP server

Claude: [截图显示]
```

#### 自定义MCP Server

```typescript
// my-custom-server.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";

const server = new Server({
  name: "my-custom-server",
  version: "1.0.0"
});

server.tool("custom_action", async (args) => {
  // 实现自定义功能
  return { result: "..." };
});

server.start();
```

注册到 `.mcp.json`:
```json
{
  "mcpServers": {
    "custom": {
      "command": "node",
      "args": ["my-custom-server.js"]
    }
  }
}
```

### 4. Hooks(钩子)

Hooks在特定事件时自动执行shell命令。

#### 配置Hooks

在 `.claude/settings.json`:
```json
{
  "hooks": {
    "user-prompt-submit": "echo '执行prompt前的检查'",
    "pre-edit": "npm run lint",
    "post-edit": "npm test",
    "before-commit": "pytest tests/"
  }
}
```

#### Hook类型

| Hook | 触发时机 | 用途 |
|------|---------|------|
| `user-prompt-submit` | 提交prompt前 | 验证输入 |
| `pre-edit` | 编辑文件前 | Lint检查 |
| `post-edit` | 编辑文件后 | 运行测试 |
| `before-commit` | Git提交前 | 完整性检查 |

#### Hook失败处理

```json
{
  "hooks": {
    "pre-edit": {
      "command": "npm run lint",
      "onFailure": "warn"  // "warn", "error", "ignore"
    }
  }
}
```

### 5. 自定义Slash命令

创建可重用的prompt模板。

#### 创建Slash命令

创建 `.claude/commands/review.md`:
```markdown
---
name: review
description: 审查代码并提供改进建议
---

请审查以下代码:

$ARGUMENTS

检查项:
1. 代码风格和可读性
2. 性能问题
3. 安全漏洞
4. 最佳实践
5. 测试覆盖率

提供具体的改进建议和示例代码。
```

#### 使用Slash命令

```bash
# 在Claude中使用
You: /review src/auth.py

# 等价于完整prompt
You: 请审查以下代码: src/auth.py
     检查项:...
```

#### 更多Slash命令示例

`.claude/commands/optimize.md`:
```markdown
---
name: optimize
description: 优化代码性能
---

分析并优化以下代码的性能:

$ARGUMENTS

关注:
- 算法复杂度
- 数据库查询
- 内存使用
- 并发处理

提供优化后的代码和性能提升预估。
```

`.claude/commands/fix-types.md`:
```markdown
---
name: fix-types
description: 修复TypeScript类型错误
---

修复以下文件的所有TypeScript类型错误:

$ARGUMENTS

要求:
- 使用strict模式
- 添加必要的类型注解
- 不使用any类型
- 保持代码功能不变
```

#### 列出可用命令

```bash
# 输入/后按Tab
You: /<Tab>

# 显示:
# /review    - 审查代码
# /optimize  - 优化性能
# /fix-types - 修复类型错误
# /test      - 生成测试
```

---

## CLI参考

### 命令行参数

```bash
# 基本用法
claude [OPTIONS] [COMMAND]

# 常用选项
-p, --prompt <TEXT>              # 直接执行prompt
-f, --files <FILES>              # 指定文件(逗号分隔)
--headless                        # 无交互模式
--dangerously-skip-permissions   # 跳过权限确认
--model <MODEL>                  # 指定模型
--verbose                        # 详细输出
--debug                          # 调试模式
--mcp-debug                      # MCP调试
--output <FILE>                  # 输出到文件
```

### 子命令

```bash
# 认证
claude auth login                # 登录
claude auth logout               # 登出
claude auth status               # 查看状态

# 配置
claude config set <KEY> <VALUE>  # 设置配置
claude config get <KEY>          # 获取配置
claude config list               # 列出所有配置
claude config reset              # 重置配置

# MCP管理
claude mcp add <SERVER>          # 添加MCP server
claude mcp list                  # 列出MCP servers
claude mcp remove <SERVER>       # 移除MCP server

# 工具
claude check                     # 健康检查
claude update                    # 更新Claude Code
claude version                   # 显示版本
```

### 环境变量

```bash
# API密钥
export ANTHROPIC_API_KEY=sk-ant-xxxxx

# 配置路径
export CLAUDE_CONFIG_PATH=~/.claude

# 默认模型
export CLAUDE_MODEL=claude-3-5-sonnet-20250219

# 日志级别
export CLAUDE_LOG_LEVEL=debug

# 禁用遥测
export CLAUDE_DISABLE_TELEMETRY=1
```

---

## 快捷键大全

### 导航快捷键

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Esc` | 停止 | 停止当前操作 |
| `Esc Esc` | 历史 | 显示可搜索的消息历史 |
| `↑` | 上一条 | 浏览历史prompt |
| `↓` | 下一条 | 浏览历史prompt |
| `Ctrl+C` | 中断 | 中断长时间运行的任务 |

### 编辑快捷键

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Ctrl+V` (Mac) | 粘贴图片 | 从剪贴板粘贴图片 |
| `Shift+拖放` | 引用文件 | 拖放文件到终端 |

### 模式切换

| 快捷键 | 功能 | 说明 |
|--------|------|------|
| `Shift+Tab` | 循环模式 | 循环切换auto-accept等模式 |

### 自定义快捷键

在 `~/.claude/keybindings.json`:
```json
{
  "ctrl+r": "/review $CURRENT_FILE",
  "ctrl+t": "/test $CURRENT_FILE",
  "ctrl+d": "/docs $CURRENT_FILE"
}
```

---

## 最佳实践

### 1. 3-File规则

**原则**: 同时只包含3个直接相关的文件

**❌ 错误**:
```bash
You: @src/ 重构整个项目
# 太多文件,上下文混乱
```

**✅ 正确**:
```bash
You: @src/auth.py @src/models/user.py @src/config.py
     重构认证系统
```

### 2. 上下文管理

```bash
# 检查上下文使用
You: /tokens

# 当接近上限时,使用/compact
You: /compact 保留最近3次对话

# 或完全清空
You: /clear

# 重新开始新任务
You: /reset
```

### 3. 增量开发

```bash
# ❌ 避免
You: 实现完整的电商系统

# ✅ 推荐
You: 第一步,创建Product模型
# 完成后
You: 第二步,实现Product的CRUD API
# 完成后
You: 第三步,添加购物车功能
```

### 4. 文档引用策略

**❌ 低效**:
```bash
You: @https://docs.example.com/api.html
     实现API客户端
```

**✅ 高效**:
```bash
You: 我需要实现example.com的API客户端
     核心要求:
     - 认证使用JWT
     - 重试3次失败请求
     - 支持异步

     请先阅读 @https://docs.example.com/api.html
     理解认证流程,然后实现
```

**原理**: 给Claude明确的目标,而不是让它盲目阅读文档

### 5. Plan模式使用时机

| 何时使用Plan | 何时不用 |
|-------------|---------|
| 架构设计 | 简单重构 |
| 复杂重构 | 明确的小任务 |
| 新功能规划 | Bug修复 |
| 性能优化 | 代码格式化 |
| 技术选型 | 添加注释 |

### 6. 错误处理最佳实践

```bash
# 遇到错误时
You: 上面的实现有错误,pytest失败了

     错误信息:
     [粘贴完整的错误堆栈]

     预期行为:
     [描述期望的结果]

     请分析原因并修复

# 提供完整上下文帮助Claude快速定位问题
```

### 7. 代码审查工作流

```bash
# 1. 先让Claude审查
You: /review @src/api.py

# 2. 根据建议修复
You: 根据审查建议修复issue #2和#3

# 3. 验证
You: 运行测试确认修复
     /run pytest tests/test_api.py

# 4. 提交
$ git add src/api.py
$ git commit -m "fix: 根据代码审查修复API问题"
```

### 8. 多实例协作

```bash
# Terminal 1 - 后端开发
$ claude
You: 实现用户认证API

# Terminal 2 - 前端开发
$ claude
You: 实现登录UI组件

# Terminal 3 - 测试
$ claude
You: 编写集成测试

# 各实例独立工作,最后整合
```

---

## 实战技巧

### 技巧1: 渐进式重构

```bash
# 大型重构任务

You: think hard 我需要将同步代码改为异步
     项目使用Flask + SQLAlchemy
     有100+个路由

     给我一个安全的迁移方案

# Claude生成详细计划

You: 好的,先执行步骤1: 迁移数据库层

# 完成后测试

You: 继续步骤2: 迁移API路由(从最简单的开始)

# 逐步完成,每步都测试
```

### 技巧2: 使用.clinerules(如果适用)

虽然这是Cline的功能,但概念可借鉴:

创建 `.claude/rules.md`:
```markdown
# 项目规范

## 代码风格
- Python使用PEP 8
- 单引号优于双引号
- 每行最多88字符

## 测试
- 所有公共函数必须有测试
- 使用pytest
- 覆盖率>80%

## Git提交
- 遵循Conventional Commits
- 中文commit消息

## 安全
- 不要在代码中硬编码密钥
- 使用环境变量
```

然后提醒Claude:
```bash
You: 遵循.claude/rules.md中的规范
     实现用户注册功能
```

### 技巧3: 模板化Prompt

创建常用prompt模板文件:

`templates/new-api.txt`:
```
实现以下REST API端点:

端点: {{endpoint}}
方法: {{method}}
功能: {{description}}

要求:
- 使用FastAPI
- 添加Pydantic模型验证
- 添加OpenAPI文档
- 添加单元测试(pytest)
- 添加错误处理
- 返回JSON响应

参考现有端点: @src/api/users.py
```

使用:
```bash
$ cat templates/new-api.txt | sed 's/{{endpoint}}/\/posts/' | sed 's/{{method}}/POST/' | claude -p -
```

### 技巧4: 批量操作脚本

```bash
#!/bin/bash
# batch-fix.sh

files=(
  "src/api/users.py"
  "src/api/posts.py"
  "src/api/comments.py"
)

for file in "${files[@]}"; do
  echo "处理 $file..."

  claude --headless \
         --dangerously-skip-permissions \
         -p "修复 @$file 的所有类型错误,添加类型注解" \
         > logs/$file.log

  if [ $? -eq 0 ]; then
    echo "✓ $file 完成"
  else
    echo "✗ $file 失败"
  fi
done
```

### 技巧5: 调试辅助

```bash
# 启用详细输出
You: /verbose on

# 现在会看到:
# - 完整的API请求
# - Token使用详情
# - 工具调用细节

# 调试MCP问题
$ claude --mcp-debug

# 调试权限问题
$ claude --debug
```

### 技巧6: 成本优化

```bash
# 1. 启用prompt缓存
# ~/.claude/settings.json
{
  "cachePrompts": true
}

# 2. 使用/compact而不是/clear
You: /compact 只保留核心对话

# 3. 移除不必要的文件引用
You: 不再需要 @old-file.py 了

# 4. 对简单任务使用Haiku(如果支持)
$ claude --model claude-3-haiku-20250219 -p "格式化代码"
```

### 技巧7: 并行任务处理

```bash
# 场景: 需要同时进行多个独立任务

# 启动多个Claude实例
# Session 1
$ cd /project && claude
You: 实现功能A

# Session 2
$ cd /project && claude
You: 实现功能B

# Session 3
$ cd /project && claude
You: 编写文档

# 各自完成后手动整合
$ git merge feature-a feature-b
```

### 技巧8: 代码审查清单

创建 `.claude/commands/review-checklist.md`:
```markdown
---
name: review-checklist
description: 详细的代码审查清单
---

请审查 $ARGUMENTS 并检查:

## 功能性
- [ ] 代码实现了需求
- [ ] 边界情况处理正确
- [ ] 错误处理完整

## 代码质量
- [ ] 命名清晰
- [ ] 函数职责单一
- [ ] 避免代码重复
- [ ] 注释充分

## 性能
- [ ] 没有N+1查询
- [ ] 算法复杂度合理
- [ ] 资源正确释放

## 安全
- [ ] 输入验证
- [ ] SQL注入防护
- [ ] XSS防护
- [ ] 敏感信息保护

## 测试
- [ ] 有单元测试
- [ ] 测试覆盖核心逻辑
- [ ] 边界情况有测试

为每项打分(1-5),给出具体建议。
```

---

## 故障排查

### 问题1: 权限拒绝

**症状**: Claude无法编辑文件

**解决**:
```bash
# 检查文件权限
$ ls -la src/file.py

# 修复权限
$ chmod +rw src/file.py

# 或使用危险模式(仅测试环境)
$ claude --dangerously-skip-permissions
```

### 问题2: MCP服务器连接失败

**症状**: MCP工具不可用

**解决**:
```bash
# 启用MCP调试
$ claude --mcp-debug

# 检查.mcp.json配置
$ cat .mcp.json

# 测试MCP服务器
$ npx -y @modelcontextprotocol/server-postgres
```

### 问题3: 上下文窗口溢出

**症状**: "Context too large"错误

**解决**:
```bash
# 方案1: 压缩历史
You: /compact 保留最近5次对话

# 方案2: 清空并重新开始
You: /clear

# 方案3: 减少文件引用
You: 移除 @large-file.py
```

### 问题4: 响应缓慢

**解决**:
```bash
# 检查网络
$ ping claude.ai

# 减少上下文
You: /clear

# 使用更快的模型(如果可用)
$ claude --model claude-3-haiku-20250219

# 检查API状态
$ curl https://status.anthropic.com/api/v2/status.json
```

### 问题5: Hook执行失败

**症状**: 编辑被hook阻止

**解决**:
```bash
# 检查hook配置
$ cat .claude/settings.json

# 手动运行hook命令测试
$ npm run lint

# 临时禁用hook
{
  "hooks": {
    "pre-edit": {
      "command": "npm run lint",
      "enabled": false
    }
  }
}
```

---

## 快速参考

### 常用命令

```bash
# 启动
claude                           # 交互模式
claude -p "task"                # 直接执行
claude --headless -p "task"     # 无交互

# 文件引用
@file.py                        # 引用文件
@folder/                        # 引用文件夹
@https://url                    # 引用URL

# 模式
think                           # Plan模式
think hard                      # 深度思考
ultrathink                      # 极限思考

# 上下文管理
/clear                          # 清空历史
/compact                        # 压缩历史
/reset                          # 完全重置
/tokens                         # 查看token使用

# Slash命令
/review file                    # 审查代码
/test file                      # 生成测试
/docs file                      # 生成文档
/optimize file                  # 优化性能
```

### 配置文件速查

```json
// ~/.claude/settings.json
{
  "apiKey": "sk-ant-xxxxx",
  "defaultModel": "claude-3-5-sonnet-20250219",
  "cachePrompts": true,
  "autoAccept": false,
  "theme": "dark"
}

// .claude/settings.json (项目级)
{
  "rules": "项目规范",
  "hooks": {
    "pre-edit": "npm run lint",
    "post-edit": "npm test"
  }
}

// .mcp.json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"]
    }
  }
}
```

---

## 总结

### Claude Code适合什么?

✅ **最适合**:
- 代码质量要求高
- 大型复杂代码库
- 需要深度推理
- 愿意付费获得最佳体验

✅ **优势**:
- 200K稳定上下文
- 卓越的代码质量
- 官方支持
- Plan模式强大
- MCP扩展性

⚠️ **限制**:
- 仅支持Claude模型
- 需要付费订阅
- 相对较新,生态待完善

### 与其他工具对比

| 选择Claude Code | 选择Aider | 选择Cursor |
|----------------|-----------|------------|
| 代码质量优先 | 开源/免费优先 | IDE集成优先 |
| 大型项目 | 小型项目 | 图形界面需求 |
| 深度推理 | 多模型需求 | Agent模式需求 |
| 官方支持 | 社区支持 | 灵活性 |

---

*参考资源*:
- 官方文档: https://docs.claude.com/claude-code
- GitHub: https://github.com/anthropics/claude-code
- 最佳实践: https://www.anthropic.com/engineering/claude-code-best-practices
