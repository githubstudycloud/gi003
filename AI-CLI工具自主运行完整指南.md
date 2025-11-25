# AI CLI工具自主运行完整指南

## 目录
- [概述](#概述)
- [各工具自主模式配置](#各工具自主模式配置)
- [安全警告](#安全警告)
- [实战场景配置](#实战场景配置)
- [最佳实践](#最佳实践)

---

## 概述

AI CLI工具默认采用"人机协作"模式,每次操作都需要用户确认。但在某些场景(如CI/CD、自动化测试、批量处理等)下,需要工具完全自主运行直到任务完成。

### ⚠️ 重要提醒

**使用自主模式前必读:**
1. 这些模式通常被称为"危险模式"或"YOLO模式"
2. AI可能执行破坏性操作(删除文件、修改配置、运行命令等)
3. 建议仅在沙箱环境、容器或充分信任的场景下使用
4. 务必先用git管理代码,以便随时回滚

---

## 各工具自主模式配置

### 1. Claude Code

#### 方式一: 命令行标志

```bash
# 完全跳过所有权限检查
claude --dangerously-skip-permissions

# 示例: 使用危险模式执行任务
claude --dangerously-skip-permissions -p "重构整个auth模块"
```

#### 方式二: 交互式切换

在Claude Code运行时:
```
按 Shift+Tab 多次循环切换模式
直到显示: "auto-accept edit on"
```

#### 方式三: 环境变量(如果支持)

```bash
export CLAUDE_AUTO_ACCEPT=true
claude
```

#### 配置说明

| 模式 | 行为 | 使用场景 |
|------|------|---------|
| 默认模式 | 每个操作都需要确认 | 日常开发 |
| Auto-accept模式 | 自动执行所有操作 | CI/CD、批量任务 |

---

### 2. Aider

#### 方式一: 命令行参数

```bash
# 自动确认所有提示
aider --yes-always

# 禁用自动提交(可选,保持灵活控制)
aider --yes-always --no-auto-commits

# 启用自动提交(完全自动化)
aider --yes-always --auto-commits

# 指定文件并自动运行
aider --yes-always --message "添加用户认证功能" src/auth.py
```

#### 方式二: 环境变量

```bash
# 设置环境变量
export AIDER_YES_ALWAYS=true
export AIDER_AUTO_COMMITS=true

# 运行aider
aider
```

#### 方式三: 配置文件

创建 `.aider.conf.yml`:
```yaml
yes-always: true
auto-commits: true
dark-mode: true
```

或使用单行环境变量:
```bash
export AIDER_FLAGS="yes-always,auto-commits,dark-mode"
aider
```

#### 脚本化使用

```bash
#!/bin/bash
# 批量处理脚本

aider --yes-always --message "修复所有类型错误" \
  src/**/*.py
```

#### Aider 参数详解

| 参数 | 说明 | 环境变量 | 默认值 |
|------|------|---------|--------|
| `--yes-always` | 跳过所有确认 | `AIDER_YES_ALWAYS` | false |
| `--auto-commits` | 自动Git提交 | `AIDER_AUTO_COMMITS` | true |
| `--no-auto-commits` | 禁用自动提交 | - | - |
| `--message` | 指定任务描述 | - | - |

---

### 3. Cline (前Roo Coder)

#### VSCode/IDE内配置

1. **打开Cline设置面板**
2. **点击"Auto Approve"区域**
3. **配置以下选项:**

```json
{
  "cline.autoApprove": {
    "readFiles": true,           // 自动批准读取文件
    "editFiles": true,           // 自动批准编辑文件
    "executeCommands": true,     // 自动批准执行命令
    "useBrowser": true,          // 自动批准浏览器操作
    "useMCP": true,              // 自动批准MCP服务器
    "maxApiRequests": 100        // 连续API请求上限
  }
}
```

#### CLI模式(如果支持)

```bash
# Cline主要在IDE内使用,但可以通过配置文件预设
cline --auto-approve-all
```

#### 安全限制器

```json
{
  "cline.autoApprove.maxApiRequests": 50  // 每50次请求后暂停
}
```

#### 推荐配置

**保守模式** (推荐初学者):
```json
{
  "readFiles": true,
  "editFiles": false,           // 仍需确认编辑
  "executeCommands": false,     // 仍需确认命令
  "maxApiRequests": 10
}
```

**平衡模式**:
```json
{
  "readFiles": true,
  "editFiles": true,
  "executeCommands": false,     // 命令仍需确认
  "maxApiRequests": 30
}
```

**完全自主模式** (仅限沙箱):
```json
{
  "readFiles": true,
  "editFiles": true,
  "executeCommands": true,
  "useBrowser": true,
  "useMCP": true,
  "maxApiRequests": 9999        // 实际无限制
}
```

---

### 4. OpenAI Codex CLI

#### 方式一: 危险标志

```bash
# 最危险的方式 - 完全绕过所有限制
codex --dangerously-bypass-approvals-and-sandbox

# 示例
codex --dangerously-bypass-approvals-and-sandbox -p "迁移数据库结构"
```

#### 方式二: 配置文件

创建 `~/.config/codex/config.yaml`:
```yaml
approval_policy: "never"          # 从不询问
sandbox_mode: "danger-full-access"  # 完全访问权限
```

#### 方式三: 参数组合

```bash
# 禁用审批 + 指定沙箱模式
codex --ask-for-approval never --sandbox-mode workspace-write

# 简写
codex -a never -s workspace-write
```

#### Codex 沙箱模式

| 模式 | 说明 | 网络访问 | 文件访问 |
|------|------|---------|---------|
| `balanced` | 默认,无网络 | ❌ | 受限 |
| `workspace-write` | 工作区读写 | ✅ | 工作区 |
| `danger-full-access` | 完全权限 | ✅ | 全系统 |

#### 三种运行策略

**策略1: 平衡模式** (默认)
```bash
codex  # 无网络,仅当前目录
```

**策略2: 工作区自动模式**
```bash
codex -a never -s workspace-write
# 自动运行,仅限工作区,有网络
```

**策略3: 完全自主模式** (最危险)
```bash
codex --dangerously-bypass-approvals-and-sandbox
# 无任何限制,仅用于容器环境
```

---

### 5. Google Gemini CLI

#### 命令行使用

```bash
# 使用 -y 标志跳过确认
gemini -y "生成完整的REST API"

# 示例: 批量处理
gemini -y -f tasks.txt
```

#### 配置文件(如果支持)

```bash
# ~/.geminirc
export GEMINI_AUTO_APPROVE=true
```

#### Gemini CLI 特点

- **完全免费开源**
- **可自托管**
- **支持语音输入**
- **安全性**: 相对较高,但仍需注意自动审批风险

---

### 6. GitHub Copilot CLI

#### 自动批准模式

```bash
# 允许所有工具和路径
copilot --allow-all-tools --allow-all-paths -p "重构代码库"

# 仅允许特定工具
copilot --allow-tools read,write,execute
```

#### 信任目录

```bash
# 添加信任目录
copilot trust add /path/to/project

# 在信任目录内自动运行
cd /path/to/project
copilot --allow-all-tools
```

#### CI/CD使用

```bash
#!/bin/bash
# .github/workflows/copilot-automation.yml

- name: Run Copilot Automation
  run: |
    copilot --allow-all-tools \
            --allow-all-paths \
            --output-format json \
            -p "自动化测试并生成报告"
```

---

### 7. Windsurf (如果支持CLI)

Windsurf主要是IDE,但如果有CLI模式:

```bash
# 可能的命令格式
windsurf --auto-approve --task "完整功能开发"
```

配置通常在IDE内完成。

---

## 安全警告

### ⚠️ 潜在风险

| 风险类型 | 描述 | 可能后果 |
|---------|------|---------|
| **数据丢失** | AI可能删除重要文件 | 代码、配置永久丢失 |
| **系统破坏** | 执行危险命令(rm -rf /) | 系统瘫痪 |
| **安全漏洞** | 安装恶意包,暴露敏感信息 | 数据泄露,被攻击 |
| **资源浪费** | 无限循环,大量API调用 | 高额费用 |
| **代码腐化** | 生成低质量代码 | 技术债务 |

### 🛡️ 安全防护措施

#### 1. 必须使用Git版本控制

```bash
# 每次自动运行前
git add .
git commit -m "运行AI自动化前的快照"

# 运行AI工具
aider --yes-always --message "任务描述"

# 如果出错,立即回滚
git reset --hard HEAD^
```

#### 2. 在沙箱环境运行

**Docker容器方式:**
```dockerfile
# Dockerfile
FROM python:3.11
WORKDIR /workspace
COPY . .
RUN pip install aider-chat

# 运行
docker run --rm -v $(pwd):/workspace my-ai-env \
  aider --yes-always --message "任务"
```

**虚拟机方式:**
```bash
# 使用虚拟机或云环境
# 在非生产环境测试
```

#### 3. 限制文件访问

```bash
# 仅对特定文件运行
aider --yes-always src/specific_file.py

# 避免对整个目录运行
# 避免: aider --yes-always .
```

#### 4. 设置请求限制

对于支持的工具:
```json
{
  "maxApiRequests": 20,  // 限制连续请求
  "timeout": 300          // 超时时间(秒)
}
```

#### 5. 监控日志

```bash
# 记录所有操作
aider --yes-always --message "任务" 2>&1 | tee aider.log

# 实时监控
tail -f aider.log
```

---

## 实战场景配置

### 场景1: CI/CD自动化

**需求**: 在GitHub Actions中自动修复代码问题

```yaml
# .github/workflows/auto-fix.yml
name: AI Auto Fix

on:
  push:
    branches: [develop]

jobs:
  auto-fix:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Aider
        run: pip install aider-chat

      - name: Run Auto Fix
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          aider --yes-always \
                --message "修复所有lint错误和类型问题" \
                src/**/*.py

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          title: "AI自动修复"
          body: "Aider自动生成的代码修复"
```

**使用Claude Code:**
```yaml
- name: Run Claude Code
  run: |
    claude --dangerously-skip-permissions \
           -p "运行测试并修复所有失败"
```

---

### 场景2: 批量重构

**需求**: 重构整个代码库的命名约定

```bash
#!/bin/bash
# refactor-all.sh

# 安全检查
if [ ! -d .git ]; then
    echo "错误: 必须在git仓库中运行"
    exit 1
fi

# 创建备份分支
git checkout -b ai-refactor-backup
git checkout -b ai-refactor

# 运行Aider批量重构
aider --yes-always \
      --message "将所有camelCase变量重构为snake_case,遵循PEP8规范" \
      src/**/*.py

# 运行测试
pytest

if [ $? -eq 0 ]; then
    echo "✓ 重构成功,所有测试通过"
    git add .
    git commit -m "AI批量重构: camelCase -> snake_case"
else
    echo "✗ 测试失败,回滚更改"
    git reset --hard ai-refactor-backup
fi
```

---

### 场景3: 文档自动生成

**需求**: 为所有函数生成文档字符串

```bash
#!/bin/bash
# generate-docs.sh

# 使用Aider批量添加docstrings
aider --yes-always \
      --auto-commits \
      --message "为所有公共函数和类添加详细的docstring,遵循Google风格" \
      $(find src -name "*.py")

# 生成API文档
sphinx-build -b html docs/ docs/_build/
```

**使用Codex CLI:**
```bash
codex -a never \
      -s workspace-write \
      -p "生成完整的API文档,包括所有public方法"
```

---

### 场景4: 代码审查辅助

**需求**: 自动标记潜在问题

```bash
#!/bin/bash
# code-review.sh

# 运行Claude Code进行代码审查
claude --dangerously-skip-permissions \
       -p "审查所有Python文件,标记以下问题:
       1. 潜在的安全漏洞
       2. 性能问题
       3. 代码异味
       4. 不符合最佳实践的代码
       生成review-report.md报告"

# 如果发现问题,创建issue
if [ -f review-report.md ]; then
    gh issue create --title "AI代码审查发现问题" \
                     --body-file review-report.md
fi
```

---

### 场景5: 测试自动生成

**需求**: 为现有代码生成单元测试

```bash
#!/bin/bash
# generate-tests.sh

# 使用Cline (通过配置文件)
# 假设已在IDE中配置auto-approve

# 或使用Aider
for file in src/**/*.py; do
    test_file="tests/test_$(basename $file)"

    aider --yes-always \
          --message "为 $file 生成完整的pytest单元测试,覆盖率>90%" \
          "$file" "$test_file"
done

# 运行所有测试验证
pytest --cov=src tests/
```

---

## 最佳实践

### ✅ 推荐做法

| 实践 | 说明 | 示例 |
|------|------|------|
| **1. 版本控制** | 始终在git仓库中操作 | `git commit -am "AI操作前"`  |
| **2. 小范围测试** | 先在单个文件测试 | `aider --yes-always file.py` |
| **3. 增量运行** | 分阶段执行任务 | 分多次运行,每次一个功能 |
| **4. 日志记录** | 保存所有输出 | `command 2>&1 \| tee log.txt` |
| **5. 设置超时** | 防止无限运行 | `timeout 300 aider ...` |
| **6. 审查结果** | 自动运行后人工检查 | `git diff` + 代码审查 |
| **7. 环境隔离** | 使用容器或虚拟环境 | Docker, virtualenv |
| **8. 限制范围** | 仅对特定目录/文件 | 明确指定文件列表 |

### ❌ 应避免的做法

| 反模式 | 风险 | 替代方案 |
|--------|------|---------|
| **在生产环境直接运行** | 系统崩溃 | 仅在开发/测试环境 |
| **无Git保护** | 无法回滚 | 必须使用版本控制 |
| **无限制运行** | 资源耗尽 | 设置请求限制和超时 |
| **跳过测试** | 引入bug | 自动运行测试套件 |
| **忽略日志** | 难以调试 | 始终记录日志 |
| **过度信任AI** | 低质量代码 | 保持人工审查 |

---

## 工具对比矩阵

### 自主模式功能对比

| 工具 | 自主模式实现 | 易用性 | 安全性 | 适用场景 |
|------|------------|--------|--------|---------|
| **Claude Code** | `--dangerously-skip-permissions` | ⭐⭐⭐⭐⭐ | ⚠️ 中 | 全场景 |
| **Aider** | `--yes-always` | ⭐⭐⭐⭐⭐ | ⚠️ 中 | CLI脚本化 |
| **Cline** | IDE配置界面 | ⭐⭐⭐⭐ | ⚠️⚠️ 较低 | IDE内开发 |
| **Codex CLI** | `--dangerously-bypass-approvals-and-sandbox` | ⭐⭐⭐ | ⚠️⚠️⚠️ 低 | 容器环境 |
| **Gemini CLI** | `-y` | ⭐⭐⭐⭐⭐ | ⚠️ 中 | 轻量任务 |
| **Copilot CLI** | `--allow-all-tools` | ⭐⭐⭐⭐ | ⚠️⚠️ 较低 | GitHub生态 |

---

## 快速参考命令

### 一键启动命令

```bash
# Claude Code - 完全自主
claude --dangerously-skip-permissions -p "你的任务"

# Aider - 自动确认 + 自动提交
aider --yes-always --auto-commits --message "你的任务" file.py

# Aider - 自动确认 + 手动提交
aider --yes-always --no-auto-commits --message "你的任务" file.py

# Codex CLI - 工作区安全模式
codex -a never -s workspace-write -p "你的任务"

# Codex CLI - 完全危险模式(仅容器)
codex --dangerously-bypass-approvals-and-sandbox -p "你的任务"

# Gemini CLI - 自动确认
gemini -y "你的任务"

# Copilot CLI - 完全权限
copilot --allow-all-tools --allow-all-paths -p "你的任务"
```

### 环境变量预配置

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc

# Aider
export AIDER_YES_ALWAYS=true
export AIDER_AUTO_COMMITS=false  # 推荐手动控制提交
export AIDER_DARK_MODE=true

# Claude Code (如果支持)
export CLAUDE_AUTO_ACCEPT=true

# Gemini CLI
export GEMINI_AUTO_APPROVE=true

# 使用别名简化命令
alias aider-auto="aider --yes-always --no-auto-commits"
alias claude-yolo="claude --dangerously-skip-permissions"
alias codex-auto="codex -a never -s workspace-write"
```

---

## 故障排查

### 常见问题

**问题1: 工具卡住不动**

```bash
# 解决方案: 设置超时
timeout 600 aider --yes-always --message "任务"
```

**问题2: 生成代码质量差**

```bash
# 解决方案: 添加更详细的提示词
aider --yes-always --message "
任务: 添加用户认证
要求:
1. 使用JWT令牌
2. 密码必须bcrypt加密
3. 添加完整的单元测试
4. 遵循OWASP安全最佳实践
5. 添加详细注释和文档
" auth.py
```

**问题3: API费用超支**

```bash
# 解决方案: 使用较小模型或设置限制
# Aider使用较便宜的模型
aider --model gpt-3.5-turbo --yes-always ...

# Cline设置请求限制
{
  "maxApiRequests": 20
}
```

**问题4: 权限错误**

```bash
# 解决方案: 检查文件权限
chmod +rw file.py
# 或使用正确的工作目录
cd /correct/path && aider --yes-always ...
```

---

## 总结

### 选择建议

| 如果你需要... | 推荐工具 | 配置 |
|-------------|---------|------|
| **最简单的CLI自动化** | Aider | `--yes-always` |
| **代码质量优先** | Claude Code | `--dangerously-skip-permissions` |
| **IDE内自动化** | Cline | 配置界面设置 |
| **CI/CD集成** | Aider或Claude Code | 环境变量 + 脚本 |
| **完全免费** | Gemini CLI | `-y` |
| **容器化部署** | Codex CLI | `--dangerously-bypass-approvals-and-sandbox` |

### 安全等级建议

| 环境 | 安全等级 | 推荐设置 |
|------|---------|---------|
| **生产环境** | 🔴 禁止自动运行 | 始终人工审批 |
| **测试环境** | 🟡 谨慎使用 | Git保护 + 小范围 |
| **开发环境** | 🟢 可以使用 | Git保护 + 日志记录 |
| **沙箱/容器** | 🟢 安全使用 | 完全自主模式 |
| **CI/CD** | 🟢 适合使用 | 自动化 + PR审查 |

---

## 附录: 完整配置示例

### Aider完整配置 (.aider.conf.yml)

```yaml
# 基本设置
yes-always: true          # 自动确认
auto-commits: false       # 手动控制提交
dark-mode: true

# 模型设置
model: claude-3-5-sonnet-20250219
editor-model: gpt-4o

# Git设置
auto-commits: false
dirty-commits: false
attribute-commits: true

# 输出设置
pretty: true
stream: true
show-diffs: true

# 文件设置
watch-files: true
```

### Cline完整配置 (settings.json)

```json
{
  "cline.autoApprove": {
    "readFiles": true,
    "editFiles": true,
    "executeCommands": false,  // 保守设置
    "useBrowser": true,
    "useMCP": true,
    "maxApiRequests": 30
  },
  "cline.model": "claude-3-5-sonnet-20250219",
  "cline.apiKey": "${ANTHROPIC_API_KEY}"
}
```

### Codex配置 (~/.config/codex/config.yaml)

```yaml
# 保守配置
approval_policy: "always"
sandbox_mode: "balanced"

# 工作区配置
# approval_policy: "never"
# sandbox_mode: "workspace-write"

# 危险配置(仅容器)
# approval_policy: "never"
# sandbox_mode: "danger-full-access"
```

---

*最后更新: 2025年1月*
*警告: 本指南仅供学习参考,使用自主模式需自行承担风险*
