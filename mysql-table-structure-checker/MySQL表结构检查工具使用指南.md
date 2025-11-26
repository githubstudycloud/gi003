# MySQL 5.7 表结构检查与修复工具完整使用指南

> 版本: 2.0  
> 更新日期: 2025-11-26  
> 适用版本: MySQL 5.7+

## 📖 概述

本工具用于解决以下场景：**数据库中以相同前缀开头的表（如 `aa_001`, `aa_002`, `aa_user` 等）应该拥有完全一致的表结构，但由于各种原因，部分表可能存在字段缺失**。

本工具能够：
1. 自动识别所有匹配前缀的表
2. 以指定的标准表为基准进行对比
3. 找出哪些表缺少哪些字段
4. 自动生成可执行的 `ALTER TABLE ADD COLUMN` 语句

## 📁 文件清单

| 文件名 | 说明 |
|--------|------|
| `check_table_structure.sql` | v1.0 基础版本 |
| `check_table_structure_v2.sql` | v2.0 增强版本（推荐使用） |
| `README.md` | 基础说明文档 |
| `README_v2.md` | v2.0 详细使用文档 |
| `MySQL表结构检查工具使用指南.md` | 本完整使用指南 |

---

## 🚀 快速使用（3步完成）

### 步骤1: 修改配置

打开 `check_table_structure_v2.sql`，修改配置区的 **3个变量**：

```sql
SET @db_name = 'your_database_name';  -- ① 改为你的数据库名
SET @table_prefix = 'aa';              -- ② 改为表前缀（如 aa、user、order 等）
SET @standard_table = 'aa_example';    -- ③ 改为标准表名（字段完整的参考表）
```

### 步骤2: 执行SQL文件

```bash
# 方式一：命令行
mysql -u username -p < check_table_structure_v2.sql

# 方式二：MySQL客户端中执行
mysql> source /path/to/check_table_structure_v2.sql

# 方式三：图形化工具（Navicat/DBeaver/DataGrip等）
# 直接打开文件执行全部SQL
```

### 步骤3: 复制修复SQL并执行

从输出的 **步骤5** 或 **步骤6** 中复制生成的 ALTER TABLE 语句，执行即可修复。

---

## 📋 详细执行流程与输出说明

执行SQL文件后，会按顺序输出以下7个步骤的结果：

### 步骤1: 查询所有匹配前缀的表

**作用**：列出数据库中所有以指定前缀开头的表

**输出示例**：
| 表名 | 存储引擎 | 估计行数 | 数据大小(MB) | 创建时间 |
|------|----------|----------|--------------|----------|
| aa_example | InnoDB | 1000 | 0.05 | 2025-01-01 |
| aa_user_001 | InnoDB | 5000 | 0.25 | 2025-01-02 |
| aa_user_002 | InnoDB | 3000 | 0.15 | 2025-01-03 |
| aa_order | InnoDB | 8000 | 0.40 | 2025-01-04 |

---

### 步骤2: 查看标准表的完整字段结构

**作用**：展示参考表的所有字段，这是对比的基准

**输出示例**：
| 字段序号 | 字段名 | 字段类型 | 是否可空 | 默认值 | 额外属性 | 字段注释 |
|----------|--------|----------|----------|--------|----------|----------|
| 1 | id | int(11) | NO | (无默认值) | auto_increment | 主键ID |
| 2 | name | varchar(100) | NO | (无默认值) | | 名称 |
| 3 | email | varchar(150) | YES | NULL | | 邮箱 |
| 4 | status | tinyint(1) | NO | 1 | | 状态 |
| 5 | created_at | datetime | NO | CURRENT_TIMESTAMP | | 创建时间 |
| 6 | updated_at | datetime | YES | NULL | ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

---

### 步骤3: 统计每个表缺少的字段数量

**作用**：快速定位哪些表有问题，问题严重程度如何

**输出示例**：
| 表名 | 标准表字段数 | 当前表字段数 | 缺少字段数 | 状态 |
|------|--------------|--------------|------------|------|
| aa_order | 6 | 3 | 3 | ✗ 严重缺失 |
| aa_user_002 | 6 | 4 | 2 | ✗ 严重缺失 |
| aa_user_001 | 6 | 5 | 1 | ⚠ 少量缺失 |

**状态说明**：
- `✓ 正常` - 0个字段缺失
- `⚠ 少量缺失` - 1-2个字段缺失
- `✗ 严重缺失` - 3个以上字段缺失

---

### 步骤4: 查看缺失字段详情

**作用**：详细列出每个表具体缺少哪些字段

**输出示例**：
| 表名 | 字段序号 | 缺少的字段 | 字段类型 | 是否可空 | 默认值 | 字段注释 |
|------|----------|------------|----------|----------|--------|----------|
| aa_user_001 | 3 | email | varchar(150) | YES | NULL | 邮箱 |
| aa_user_002 | 3 | email | varchar(150) | YES | NULL | 邮箱 |
| aa_user_002 | 6 | updated_at | datetime | YES | NULL | 更新时间 |
| aa_order | 3 | email | varchar(150) | YES | NULL | 邮箱 |
| aa_order | 4 | status | tinyint(1) | NO | 1 | 状态 |
| aa_order | 6 | updated_at | datetime | YES | NULL | 更新时间 |

---

### 步骤5: 生成修复SQL语句（基础版）

**作用**：生成 `ALTER TABLE ADD COLUMN` 语句，字段添加到表末尾

**输出示例**：
```sql
ALTER TABLE `aa_user_001` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱';
ALTER TABLE `aa_user_002` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱';
ALTER TABLE `aa_user_002` ADD COLUMN `updated_at` datetime NULL DEFAULT NULL COMMENT '更新时间';
ALTER TABLE `aa_order` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱';
ALTER TABLE `aa_order` ADD COLUMN `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态';
ALTER TABLE `aa_order` ADD COLUMN `updated_at` datetime NULL DEFAULT NULL COMMENT '更新时间';
```

---

### 步骤6: 生成修复SQL语句（推荐版-保持字段顺序）

**作用**：生成带 `AFTER` 子句的语句，确保新增字段的位置与标准表一致

**输出示例**：
```sql
ALTER TABLE `aa_user_001` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱' AFTER `name`;
ALTER TABLE `aa_user_002` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱' AFTER `name`;
ALTER TABLE `aa_user_002` ADD COLUMN `updated_at` datetime NULL DEFAULT NULL COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `aa_order` ADD COLUMN `email` varchar(150) NULL DEFAULT NULL COMMENT '邮箱' AFTER `name`;
ALTER TABLE `aa_order` ADD COLUMN `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态' AFTER `email`;
ALTER TABLE `aa_order` ADD COLUMN `updated_at` datetime NULL DEFAULT NULL COMMENT '更新时间' AFTER `created_at`;
```

> **推荐使用步骤6的输出**：字段顺序与标准表保持一致，便于维护和代码映射。

---

### 步骤7: 汇总报告

**作用**：显示修复操作的总体统计

**输出示例**：
| 统计项 | 需要修复的表数 | 需要添加的字段数 |
|--------|----------------|------------------|
| 总计 | 3 | 6 |

---

## 📌 使用场景示例

### 场景1：分表结构同步

```sql
-- 有100张分表：aa_001, aa_002, ..., aa_100
-- aa_example 是标准表
SET @db_name = 'order_db';
SET @table_prefix = 'aa';
SET @standard_table = 'aa_example';
```

### 场景2：用户表分表检查

```sql
-- 用户分表：user_2024_01, user_2024_02, ...
-- user_template 是标准表
SET @db_name = 'user_db';
SET @table_prefix = 'user';
SET @standard_table = 'user_template';
```

### 场景3：订单表按地区分表

```sql
-- 地区订单表：order_beijing, order_shanghai, order_guangzhou...
-- order_master 是标准表
SET @db_name = 'sales_db';
SET @table_prefix = 'order';
SET @standard_table = 'order_master';
```

---

## ⚠️ 注意事项

### 执行前必读

1. **备份数据库** - 执行 ALTER TABLE 前务必备份
   ```bash
   mysqldump -u username -p database_name > backup_$(date +%Y%m%d).sql
   ```

2. **测试环境先行** - 先在测试环境验证生成的SQL

3. **业务低峰期执行** - ALTER TABLE 会锁表，选择低峰期执行

4. **大表谨慎操作** - 对于百万级以上的大表，考虑使用 pt-online-schema-change

### 常见问题

**Q: 如何确定哪个表是标准表？**  
A: 选择字段最完整、最新创建的表作为标准表，或者从建表DDL中选择原始定义。

**Q: 执行修复SQL报错怎么办？**  
A: 
- 检查字段是否已存在（Duplicate column name）
- 检查默认值语法是否正确
- 检查是否有外键约束影响

**Q: 为什么步骤6比步骤5更推荐？**  
A: 步骤6使用 AFTER 子句，能保证新增字段的位置与标准表一致，便于后续维护和ORM映射。

---

## 🔧 工具原理

本工具通过查询 MySQL 的 `information_schema.COLUMNS` 和 `information_schema.TABLES` 系统表来：

1. 获取指定前缀的所有表名
2. 获取标准表的完整字段定义
3. 对比其他表与标准表的字段差异
4. 根据差异自动拼接 ALTER TABLE 语句

**核心查询逻辑**：
```sql
-- 找出某表缺少的字段（存在于标准表但不存在于目标表）
SELECT ref.COLUMN_NAME
FROM information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_NAME = '目标表' AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE ref.TABLE_NAME = '标准表'
    AND exist.COLUMN_NAME IS NULL;
```

---

## 📝 更新日志

### v2.0 (2025-11-26)
- ✅ 支持任意前缀（不再局限于 aa）
- ✅ 增加字段顺序保持功能（AFTER子句）
- ✅ 增加状态标识（正常/少量缺失/严重缺失）
- ✅ 增加汇总报告
- ✅ 增强字段信息显示（包含序号、额外属性等）
- ✅ 优化SQL注释和输出格式

### v1.0 (初始版本)
- 基础的表结构检查功能
- 生成简单的 ALTER TABLE 语句

---

## 📄 License

MIT License - 可自由使用和修改
