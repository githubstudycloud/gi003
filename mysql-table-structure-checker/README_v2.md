# MySQL 5.7 表结构检查和修复工具 v2.0

> 完整的表结构一致性检查与修复解决方案，支持任意前缀的分表场景

## 📋 目录

- [功能概述](#功能概述)
- [快速开始](#快速开始)
- [详细使用说明](#详细使用说明)
- [SQL文件说明](#sql文件说明)
- [使用场景示例](#使用场景示例)
- [常见问题](#常见问题)
- [注意事项](#注意事项)

---

## 功能概述

### 核心功能

1. **查询匹配表** - 查找所有以指定前缀开头的表
2. **展示标准结构** - 显示参考表的完整字段信息
3. **统计缺失字段** - 汇总每个表缺少的字段数量
4. **详细差异分析** - 列出每个表具体缺少哪些字段
5. **生成修复SQL** - 自动生成 ALTER TABLE ADD COLUMN 语句
6. **保持字段顺序** - 支持使用 AFTER 子句保持字段顺序一致

### 适用场景

| 场景 | 描述 |
|------|------|
| 分表管理 | 确保 aa_001, aa_002, aa_003 等分表结构一致 |
| 数据库升级 | 新增字段后检查所有相关表是否同步更新 |
| 多环境同步 | 检查开发、测试、生产环境的表结构差异 |
| 结构标准化 | 统一管理具有相同前缀的表结构 |

---

## 快速开始

### 第一步：配置参数

打开 `check_table_structure_v2.sql` 文件，修改配置区的三个变量：

```sql
SET @db_name = 'your_database_name';  -- 你的数据库名
SET @table_prefix = 'aa';              -- 表前缀（支持任意前缀）
SET @standard_table = 'aa_example';    -- 标准表（字段完整的参考表）
```

### 第二步：执行SQL

在 MySQL 客户端执行整个 SQL 文件：

```bash
# 方法1：命令行执行
mysql -u username -p database_name < check_table_structure_v2.sql

# 方法2：在 MySQL 客户端中执行
mysql> source /path/to/check_table_structure_v2.sql
```

### 第三步：复制修复语句并执行

从步骤5或步骤6的输出中复制 ALTER TABLE 语句，执行修复。

---

## 详细使用说明

### 步骤1：查询所有匹配前缀的表

**功能**：列出数据库中所有以指定前缀开头的表

**输出示例**：

| 表名 | 存储引擎 | 估计行数 | 数据大小(MB) | 创建时间 | 最后更新时间 |
|------|----------|----------|--------------|----------|--------------|
| aa_example | InnoDB | 1000 | 0.05 | 2025-01-01 | 2025-01-15 |
| aa_user_001 | InnoDB | 5000 | 0.25 | 2025-01-02 | 2025-01-16 |
| aa_user_002 | InnoDB | 3000 | 0.15 | 2025-01-03 | 2025-01-16 |

---

### 步骤2：查看标准表的完整字段结构

**功能**：展示参考表的所有字段信息，作为对比基准

**输出示例**：

| 字段序号 | 字段名 | 字段类型 | 是否可空 | 默认值 | 额外属性 | 字段注释 |
|----------|--------|----------|----------|--------|----------|----------|
| 1 | id | int(11) | NO | (无默认值) | auto_increment | 主键ID |
| 2 | name | varchar(100) | NO | (无默认值) | | 用户名 |
| 3 | email | varchar(150) | YES | (无) | | 邮箱地址 |
| 4 | status | tinyint(1) | NO | 1 | | 状态 |
| 5 | created_at | datetime | NO | CURRENT_TIMESTAMP | | 创建时间 |
| 6 | updated_at | datetime | YES | (无) | ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

---

### 步骤3：统计每个表缺少的字段数量

**功能**：汇总显示哪些表存在字段缺失，以及缺失数量

**输出示例**：

| 表名 | 标准表字段数 | 当前表字段数 | 缺少字段数 | 状态 |
|------|--------------|--------------|------------|------|
| aa_user_002 | 6 | 4 | 2 | ✗ 严重缺失 |
| aa_user_001 | 6 | 5 | 1 | ⚠ 少量缺失 |

---

### 步骤4：查看缺失字段详情

**功能**：详细列出每个表缺少的具体字段信息

**输出示例**：

| 表名 | 字段序号 | 缺少的字段 | 字段类型 | 是否可空 | 默认值 | 字段注释 |
|------|----------|------------|----------|----------|--------|----------|
| aa_user_001 | 3 | email | varchar(150) | YES | (无) | 邮箱地址 |
| aa_user_002 | 3 | email | varchar(150) | YES | (无) | 邮箱地址 |
| aa_user_002 | 6 | updated_at | datetime | YES | (无) | 更新时间 |

---

### 步骤5：生成修复SQL语句（基础版）

**功能**：生成 ALTER TABLE ADD COLUMN 语句（字段添加到表末尾）

**输出示例**：

```sql
ALTER TABLE `aa_user_001` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱地址';
ALTER TABLE `aa_user_002` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱地址';
ALTER TABLE `aa_user_002` ADD COLUMN `updated_at` datetime NULL DEFAULT NULL COMMENT '更新时间';
```

---

### 步骤6：生成修复SQL语句（推荐版-保持字段顺序）

**功能**：生成带 AFTER 子句的 ALTER TABLE 语句，确保字段顺序与标准表一致

**输出示例**：

```sql
ALTER TABLE `aa_user_001` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱地址' AFTER `name`;
ALTER TABLE `aa_user_002` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱地址' AFTER `name`;
ALTER TABLE `aa_user_002` ADD COLUMN `updated_at` datetime NULL DEFAULT NULL COMMENT '更新时间' AFTER `created_at`;
```

---

### 步骤7：汇总报告

**功能**：显示修复操作的统计信息

**输出示例**：

| 统计项 | 需要修复的表数 | 需要添加的字段数 |
|--------|----------------|------------------|
| 总计 | 2 | 3 |

---

## SQL文件说明

| 文件名 | 版本 | 说明 |
|--------|------|------|
| `check_table_structure.sql` | v1.0 | 原始版本，基础功能 |
| `check_table_structure_v2.sql` | v2.0 | 增强版，支持任意前缀，完整的7步骤流程 |

### v2.0 新增特性

- ✅ 支持任意表前缀（aa、bb、user、order 等）
- ✅ 增强的字段信息显示（包含序号、额外属性等）
- ✅ 状态标识（正常/少量缺失/严重缺失）
- ✅ 汇总报告统计
- ✅ 更完善的默认值处理
- ✅ 支持 CURRENT_TIMESTAMP 等特殊默认值
- ✅ 支持字段注释中的特殊字符转义

---

## 使用场景示例

### 示例1：以 `aa` 前缀开头的分表

```sql
SET @db_name = 'mydb';
SET @table_prefix = 'aa';
SET @standard_table = 'aa_example';
```

### 示例2：以 `user_` 前缀开头的用户表

```sql
SET @db_name = 'user_center';
SET @table_prefix = 'user_';
SET @standard_table = 'user_master';
```

### 示例3：以 `order` 前缀开头的订单表

```sql
SET @db_name = 'order_db';
SET @table_prefix = 'order';
SET @standard_table = 'order_template';
```

### 示例4：以 `log_` 前缀开头的日志表

```sql
SET @db_name = 'log_center';
SET @table_prefix = 'log_';
SET @standard_table = 'log_base';
```

---

## 常见问题

### Q1: 查询结果为空怎么办？

**可能原因**：
- 数据库名配置错误
- 表前缀不匹配
- 标准表不存在
- 没有 information_schema 查询权限

**解决方案**：
```sql
-- 检查数据库是否存在
SHOW DATABASES LIKE 'your_database_name';

-- 检查表是否存在
SHOW TABLES FROM your_database_name LIKE 'aa%';

-- 检查权限
SHOW GRANTS;
```

### Q2: 生成的ALTER语句执行失败？

**可能原因**：
- 字段已存在（并发执行导致）
- 权限不足
- 字段类型不兼容

**解决方案**：
```sql
-- 检查字段是否已存在
DESCRIBE your_table_name;

-- 检查ALTER权限
SHOW GRANTS;

-- 如果字段已存在，可以忽略该语句
```

### Q3: 如何只检查不修复？

只执行步骤1-4，跳过步骤5-6的输出即可。

### Q4: 如何排除某些表？

在SQL中添加排除条件：
```sql
AND t.TABLE_NAME NOT IN ('aa_temp', 'aa_backup', 'aa_archive')
```

---

## 注意事项

### ⚠️ 安全建议

1. **先备份** - 执行修复前务必备份数据库
2. **测试环境验证** - 先在测试环境执行验证无误
3. **低峰期操作** - 在业务低峰期执行 ALTER TABLE
4. **分批执行** - 对于大量表，建议分批执行

### ⚠️ 性能影响

- ALTER TABLE 会锁表，对于大表可能需要较长时间
- 建议使用 pt-online-schema-change 进行在线变更
- 监控数据库负载，避免影响业务

### ⚠️ 已知限制

| 限制项 | 说明 |
|--------|------|
| 索引 | 不支持复制索引定义 |
| 外键 | 不支持复制外键约束 |
| 触发器 | 不支持复制触发器 |
| 数据 | 仅复制结构，不复制数据 |

---

## 版本兼容性

| 数据库版本 | 支持状态 |
|------------|----------|
| MySQL 5.7 | ✅ 完全支持 |
| MySQL 8.0+ | ✅ 完全支持 |
| MariaDB 10.2+ | ✅ 完全支持 |

---

## 更新日志

### v2.0.0 (2025-11-26)
- 🆕 支持任意表前缀
- 🆕 增强字段信息显示
- 🆕 添加状态标识
- 🆕 添加汇总报告
- 🔧 优化默认值处理
- 🔧 改进特殊字符转义

### v1.0.0 (2025-11-26)
- 初始版本发布
- 支持字段缺失检测
- 支持 ALTER TABLE 语句生成

---

## 许可证

MIT License

## 作者

Created by Claude Code
