# 原生依赖说明文档

## 问题背景

在使用 `npm install` 安装依赖时，Vite/Rollup 会尝试下载平台特定的原生二进制模块：

```
@rollup/rollup-win32-x64-msvc      # Windows x64
@rollup/rollup-win32-ia32-msvc     # Windows x86
@rollup/rollup-darwin-x64          # macOS Intel
@rollup/rollup-darwin-arm64        # macOS Apple Silicon
@rollup/rollup-linux-x64-gnu       # Linux x64
...
```

这些模块用于加速打包过程，使用 Rust 编写的原生代码替代纯 JavaScript 实现。

## 问题现象

在内网环境或网络受限的情况下，可能出现以下错误：

```bash
npm ERR! network request to https://registry.npmjs.org/@rollup/rollup-win32-x64-msvc failed

# 或者
npm WARN optional SKIPPING OPTIONAL DEPENDENCY: @rollup/rollup-win32-x64-msvc
```

## 重要说明 ⚠️

**不能完全排除原生依赖！**

Rollup 运行时需要原生模块，如果使用 `package.json` 的 `overrides` 完全排除所有原生模块，
会导致 Vite 无法启动，报错：

```
Error: Cannot find module @rollup/rollup-win32-x64-msvc
```

正确的做法是：**让 npm 在安装时跳过无法下载的可选依赖，但保留当前平台的模块**。

## 本项目的解决方案

### 方案1：.npmrc 配置（已配置 ✅ 推荐）

本项目配置了 `.npmrc` 文件：

```ini
# .npmrc
optional=false
omit=optional
```

**效果**：
- 安装时不会强制要求下载所有平台的原生模块
- 当前平台的模块如果能下载就会安装，不能下载会跳过
- Rollup 会自动回退使用 JavaScript 版本（性能略低但功能完全相同）

### 方案2：安装时指定参数

```bash
# 跳过可选依赖
npm install --omit=optional

# 或者
npm install --no-optional
```

### 方案3：使用国内镜像（网络问题推荐）

如果只是网络问题，使用淘宝镜像可以正常下载原生模块：

```bash
# 临时使用
npm install --registry=https://registry.npmmirror.com

# 永久配置
npm config set registry https://registry.npmmirror.com
```

### 方案4：预先下载原生模块（内网推荐）

在有网络的环境下载原生模块，然后拷贝到内网：

```bash
# 1. 在有网络的机器上，正常安装
npm install

# 2. 打包整个 node_modules 目录
tar -czvf node_modules.tar.gz node_modules/

# 3. 拷贝到内网机器，解压
tar -xzvf node_modules.tar.gz

# 4. 直接运行，无需再 npm install
npm run dev
```

### 方案5：使用私有 npm 仓库

配置 `.npmrc` 使用私有仓库：

```ini
# .npmrc
registry=http://your-internal-npm-registry.com/
```

## 原生模块列表

| 包名 | 平台 | 架构 |
|------|------|------|
| `@rollup/rollup-win32-x64-msvc` | Windows | x64 |
| `@rollup/rollup-win32-ia32-msvc` | Windows | x86 |
| `@rollup/rollup-win32-arm64-msvc` | Windows | ARM64 |
| `@rollup/rollup-darwin-x64` | macOS | Intel |
| `@rollup/rollup-darwin-arm64` | macOS | Apple Silicon |
| `@rollup/rollup-linux-x64-gnu` | Linux | x64 (glibc) |
| `@rollup/rollup-linux-x64-musl` | Linux | x64 (musl) |
| `@rollup/rollup-linux-arm64-gnu` | Linux | ARM64 |

## 性能影响

| 模式 | 性能 | 说明 |
|------|------|------|
| 原生模块 | ⭐⭐⭐⭐⭐ | 最快，使用 Rust 编译的原生代码 |
| JS 回退 | ⭐⭐⭐ | 较慢（约慢 2-3 倍），但功能完全相同 |

**结论**：对于开发环境，JS 回退版本完全够用，性能差异在可接受范围内（几百毫秒级别）。

## 内网部署完整步骤

```bash
# === 在有网络的机器上 ===

# 1. 克隆项目
git clone <repository-url>
cd matrix/evaluate-matrix-system/frontend

# 2. 安装依赖（会下载原生模块）
npm install

# 3. 打包依赖
tar -czvf frontend-deps.tar.gz node_modules/

# 4. 拷贝以下文件到内网：
#    - 项目源代码
#    - frontend-deps.tar.gz

# === 在内网机器上 ===

# 5. 解压依赖
tar -xzvf frontend-deps.tar.gz

# 6. 启动开发服务器
npm run dev

# 7. 或构建生产版本
npm run build
```

## 验证配置

```bash
# 检查是否安装了原生模块
npm ls @rollup/rollup-win32-x64-msvc

# 正常情况会显示已安装或 (empty)
# 如果显示 (empty)，Rollup 会使用 JS 回退版本
```

## 常见问题

### Q: 为什么不能用 overrides 排除原生模块？

A: Rollup 的 `native.js` 会尝试加载原生模块，如果完全排除会导致模块找不到的错误。
   正确做法是让 npm 跳过下载，而不是从依赖树中移除。

### Q: 没有原生模块能正常运行吗？

A: 可以。Rollup 会检测到原生模块不可用，自动回退到 JavaScript 实现。
   开发环境完全可用，只是打包速度稍慢。

### Q: 生产环境建议？

A: 生产环境建议使用原生模块以获得最佳性能，可以通过以下方式：
   - 使用国内镜像
   - 配置私有 npm 仓库
   - 预先打包 node_modules

---

**更新时间**: 2025-12-06  
**版本**: 1.1
