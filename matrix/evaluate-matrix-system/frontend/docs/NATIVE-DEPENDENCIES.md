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

## 解决方案

### 方案1：使用 .npmrc 配置（推荐）

本项目已配置 `.npmrc` 文件，跳过可选依赖：

```ini
# .npmrc
optional=false
omit=optional
```

**效果**：`npm install` 时不会尝试下载原生模块，使用纯 JavaScript 版本。

### 方案2：安装时指定参数

```bash
# 跳过可选依赖
npm install --omit=optional

# 或者
npm install --no-optional
```

### 方案3：使用国内镜像

如果只是网络问题，可以使用淘宝镜像：

```bash
# 临时使用
npm install --registry=https://registry.npmmirror.com

# 永久配置
npm config set registry https://registry.npmmirror.com
```

### 方案4：手动下载并放置

如果必须使用原生模块以获得最佳性能：

1. 在有网络的机器上下载对应的包
2. 拷贝到 `node_modules/@rollup/` 目录下
3. 或者使用私有 npm 仓库

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
| JS 回退 | ⭐⭐⭐ | 较慢，但功能完全相同 |

**结论**：对于开发环境，JS 回退版本完全够用，性能差异在可接受范围内。

## 验证配置

安装后可以检查是否跳过了原生模块：

```bash
# 检查 node_modules 中是否有 rollup 原生模块
ls node_modules/@rollup/

# 如果配置正确，应该不会看到 rollup-win32-* 等目录
```

## 相关链接

- [Rollup 官方文档](https://rollupjs.org/)
- [Vite 官方文档](https://vitejs.dev/)
- [npm .npmrc 配置](https://docs.npmjs.com/cli/v9/configuring-npm/npmrc)

---

**更新时间**: 2025-12-06  
**版本**: 1.0

