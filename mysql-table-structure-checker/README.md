# MySQL 5.7 表结构检查和修复工具

这是一个用于检查和修复 MySQL 5.7 数据库中表结构不一致问题的工具集。主要用于确保具有相同前缀的表拥有完全一致的表结构。

> **📢 新版本发布**: v2.0 版本现已发布！支持任意前缀、增强的字段显示和汇总报告。详见 [README_v2.md](README_v2.md)

## 📁 文件说明

| 文件名 | 版本 | 说明 |
|--------|------|------|
| `check_table_structure.sql` | v1.0 | 原始版本，基础功能 |
| `check_table_structure_v2.sql` | v2.0 | **推荐** 增强版，支持任意前缀，完整7步骤流程 |
| `README.md` | - | 本说明文档 |
| `README_v2.md` | - | v2.0详细使用文档 |

## 功能特性

- 查找所有以指定前缀开头的表（支持 aa、bb、user、order 等任意前缀）
- 对比标准表结构，找出缺少字段的表
- 统计每个表缺少的字段数量
- 自动生成 ALTER TABLE 修复语句
- 支持保留字段位置的修复语句生成（使用 AFTER 子句）
- **v2.0新增**: 状态标识、汇总报告、增强的字段信息显示

## 使用场景

适用于以下场景：
- 分表场景中，确保所有分表结构一致（如 aa_001, aa_002, aa_003）
- 数据库升级后的结构校验
- 多环境数据库结构同步检查
- 表结构标准化管理

## 前置条件

- MySQL 5.7 或更高版本
- 拥有 information_schema 的查询权限
- 拥有目标数据库的 ALTER TABLE 权限（执行修复时需要）

## 快速开始

### 1. 配置参数

打开 [check_table_structure.sql](check_table_structure.sql) 文件，修改以下参数：

```sql
USE your_database_name;  -- 修改为实际的数据库名

-- 在查询中修改以下参数：
-- 表前缀：将 'aa%' 修改为实际的前缀（如 'user%', 'order%' 等）
-- 标准表名：将 'aa_example' 修改为实际的标准表名
```

### 2. 执行步骤

按顺序执行 SQL 文件中的各个步骤：

#### 步骤 1: 查找所有匹配前缀的表
```sql
SELECT TABLE_NAME, TABLE_TYPE, ENGINE, TABLE_ROWS, CREATE_TIME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME LIKE 'aa%'
ORDER BY TABLE_NAME;
```

**输出示例：**
| 表名 | 表类型 | 引擎 | 行数 | 创建时间 |
|------|--------|------|------|----------|
| aa_example | BASE TABLE | InnoDB | 1000 | 2024-01-01 |
| aa_user_001 | BASE TABLE | InnoDB | 500 | 2024-01-02 |
| aa_user_002 | BASE TABLE | InnoDB | 300 | 2024-01-03 |

#### 步骤 2: 获取标准表的字段信息
查看标准表（aa_example）的完整字段结构，作为对比基准。

**输出示例：**
| 字段名 | 字段类型 | 可为空 | 默认值 | 注释 | 位置 |
|--------|----------|--------|--------|------|------|
| id | int(11) | NO | NULL | 主键ID | 1 |
| name | varchar(100) | NO | NULL | 用户名 | 2 |
| email | varchar(100) | YES | NULL | 邮箱 | 3 |
| created_at | datetime | NO | CURRENT_TIMESTAMP | 创建时间 | 4 |

#### 步骤 3: 对比找出缺少的字段
显示所有表中缺少的字段详情。

**输出示例：**
| 表名 | 缺少的字段 | 字段类型 | 可为空 | 默认值 | 注释 |
|------|-----------|----------|--------|--------|------|
| aa_user_001 | email | varchar(100) | YES | NULL | 邮箱 |
| aa_user_002 | email | varchar(100) | YES | NULL | 邮箱 |
| aa_user_002 | created_at | datetime | NO | CURRENT_TIMESTAMP | 创建时间 |

#### 步骤 4: 统计缺失字段数量
汇总每个表缺少的字段数量，快速定位问题表。

**输出示例：**
| 表名 | 缺少字段数量 |
|------|--------------|
| aa_user_002 | 2 |
| aa_user_001 | 1 |

#### 步骤 5: 检查特定表（可选）
针对单个表进行详细检查。

#### 步骤 6: 生成修复语句（基础版）
生成简单的 ALTER TABLE 语句，字段会被添加到表末尾。

**输出示例：**
```sql
ALTER TABLE `aa_user_001` ADD COLUMN `email` varchar(100) NULL COMMENT '邮箱';
ALTER TABLE `aa_user_002` ADD COLUMN `email` varchar(100) NULL COMMENT '邮箱';
ALTER TABLE `aa_user_002` ADD COLUMN `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间';
```

#### 步骤 7: 生成带位置的修复语句（推荐）
生成带有字段位置信息的 ALTER TABLE 语句，确保字段顺序与标准表一致。

**输出示例：**
```sql
ALTER TABLE `aa_user_001` ADD COLUMN `email` varchar(100) NULL COMMENT '邮箱' AFTER `name`;
ALTER TABLE `aa_user_002` ADD COLUMN `email` varchar(100) NULL COMMENT '邮箱' AFTER `name`;
ALTER TABLE `aa_user_002` ADD COLUMN `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' AFTER `email`;
```

### 3. 执行修复

1. 复制步骤 7 生成的 ALTER TABLE 语句
2. 在测试环境先执行验证
3. 确认无误后在生产环境执行
4. 执行后重新运行步骤 3 和步骤 4 确认修复完成

## 注意事项

### 安全提示
- **务必先在测试环境验证**
- 执行前备份数据库
- 建议在业务低峰期执行
- 对于大表，ALTER TABLE 可能需要较长时间

### 字段默认值处理
工具会自动处理以下字段类型的默认值：
- 字符串类型（varchar, char, text）：自动添加引号
- 日期时间类型（date, datetime, timestamp）：支持特殊值如 CURRENT_TIMESTAMP
- 数字类型（int, bigint, decimal）：直接使用原值

### 已知限制
- 不支持复制索引定义
- 不支持复制外键约束
- 仅复制字段结构，不复制数据
- 对于 ENUM 和 SET 类型需要注意引号转义

## 自定义使用

### 修改表前缀
将所有 SQL 中的 `'aa%'` 替换为你的前缀，例如：
```sql
-- 查找所有以 user_ 开头的表
WHERE TABLE_NAME LIKE 'user_%'

-- 查找所有以 order 开头的表
WHERE TABLE_NAME LIKE 'order%'
```

### 修改标准表
将所有 SQL 中的 `'aa_example'` 替换为你的标准表名，例如：
```sql
-- 使用 user_master 作为标准表
AND TABLE_NAME = 'user_master'
```

### 排除特定表
在查询条件中添加排除条件：
```sql
WHERE TABLE_NAME LIKE 'aa%'
  AND TABLE_NAME NOT IN ('aa_temp', 'aa_backup')  -- 排除临时表
```

## 高级用法

### 批量修复脚本
将步骤 7 的输出导出到文件：
```bash
mysql -u username -p database_name < check_table_structure.sql > repair_statements.sql
```

### 自动化执行
结合 shell 脚本实现自动化：
```bash
#!/bin/bash
# 生成修复语句
mysql -u root -p your_db < check_table_structure.sql > repair.sql

# 执行修复
mysql -u root -p your_db < repair.sql

# 验证结果
mysql -u root -p your_db -e "SELECT COUNT(*) as missing_fields FROM (步骤4的SQL) as t;"
```

## 故障排查

### 常见问题

**Q: 查询结果为空**
- 检查数据库连接是否正确
- 确认表前缀和标准表名是否正确
- 验证是否有查询 information_schema 的权限

**Q: 生成的 ALTER 语句执行失败**
- 检查字段类型是否兼容
- 确认是否有 ALTER TABLE 权限
- 查看 MySQL 错误日志获取详细信息

**Q: 字段位置不正确**
- 使用步骤 7（带位置的语句）而非步骤 6
- 确认标准表的字段顺序正确

## 版本兼容性

- MySQL 5.7：完全支持
- MySQL 8.0+：完全支持
- MariaDB 10.2+：完全支持

## 性能优化建议

对于大量表的情况：
1. 分批执行查询和修复
2. 在业务低峰期执行
3. 考虑使用 pt-online-schema-change 工具进行在线变更

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工具。

## 许可证

MIT License

## 作者

Created by Claude Code

## 更新日志

### v1.0.0 (2025-11-26)
- 初始版本发布
- 支持字段缺失检测
- 支持 ALTER TABLE 语句生成
- 支持字段位置保持
