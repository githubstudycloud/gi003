# MySQL 5.7 表结构一致性检查与修复工具

## 概述

本工具用于检查 MySQL 5.7 数据库中以相同前缀开头的表结构是否一致，并自动生成修复缺失字段的 SQL 语句。

## 适用场景

- 分表场景下，多个以相同前缀（如 `aa_`、`order_`、`user_` 等）开头的表需要保持结构一致
- 表结构变更后，部分表漏改导致字段缺失
- 数据库迁移过程中表结构不完整

## 使用前准备

1. 确定参考表：选择一个字段完整的表作为参考（如 `aa_example`）
2. 确定表前缀：所有需要检查的表的公共前缀（如 `aa`）
3. 确定数据库名：目标数据库的名称

## 文件说明

| 文件名 | 用途 | 执行顺序 |
|--------|------|----------|
| `01_list_tables.sql` | 列出所有以指定前缀开头的表 | 第1步 |
| `02_get_reference_table_columns.sql` | 获取参考表的完整字段信息 | 第2步 |
| `03_compare_columns.sql` | 对比各表与参考表的字段差异 | 第3步 |
| `04_generate_alter_statements.sql` | 生成单独的 ALTER 语句 | 第4步 |
| `05_generate_executable_sql.sql` | 生成最终可执行的 SQL | 第5步（最终） |

## 使用步骤

### 步骤 1：修改配置变量

在每个 SQL 文件中，修改以下变量为实际值：

```sql
SET @db_name = 'your_database_name';     -- 你的数据库名
SET @reference_table = 'aa_example';      -- 字段完整的参考表名
SET @table_prefix = 'aa';                 -- 表前缀
```

### 步骤 2：执行检查脚本

按顺序执行 SQL 文件，了解当前情况：

```bash
# 在 MySQL 命令行中执行
mysql -u username -p database_name < 01_list_tables.sql
mysql -u username -p database_name < 02_get_reference_table_columns.sql
mysql -u username -p database_name < 03_compare_columns.sql
```

或在 MySQL 客户端工具（如 Navicat、DBeaver、MySQL Workbench）中直接执行。

### 步骤 3：生成修复 SQL

执行最终脚本生成可执行的 ALTER 语句：

```bash
mysql -u username -p database_name < 05_generate_executable_sql.sql > fix_tables.sql
```

### 步骤 4：检查并执行修复

1. 打开生成的 `fix_tables.sql` 文件
2. 仔细检查每条 ALTER 语句
3. 在**测试环境**先执行验证
4. 确认无误后在生产环境执行

## 输出示例

### 字段对比结果

```
+------------+-------------+----------+
| 表名       | 当前字段数  | 缺少字段数 |
+------------+-------------+----------+
| aa_order_01 | 15         | 3         |
| aa_order_02 | 16         | 2         |
| aa_order_03 | 17         | 1         |
+------------+-------------+----------+
```

### 生成的 ALTER 语句示例

**方法1：合并语句（每表一条）**

```sql
-- 修复表: aa_order_01 (缺少 3 个字段)
ALTER TABLE `mydb`.`aa_order_01`
  ADD COLUMN `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  ADD COLUMN `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  ADD COLUMN `status` tinyint(4) NOT NULL DEFAULT 0 COMMENT '状态';
```

**方法2：单独语句（每字段一条）**

```sql
ALTER TABLE `mydb`.`aa_order_01` ADD COLUMN `create_time` datetime DEFAULT NULL COMMENT '创建时间';
ALTER TABLE `mydb`.`aa_order_01` ADD COLUMN `update_time` datetime DEFAULT NULL COMMENT '更新时间';
ALTER TABLE `mydb`.`aa_order_01` ADD COLUMN `status` tinyint(4) NOT NULL DEFAULT 0 COMMENT '状态';
```

## 注意事项

1. **备份优先**：执行任何 ALTER 操作前，请先备份数据库
2. **测试验证**：先在测试环境验证 SQL 语句的正确性
3. **锁表影响**：ALTER TABLE 会锁表，大表操作请在低峰期执行
4. **字段顺序**：生成的语句默认添加到表末尾，如需保持字段顺序，请使用 `AFTER` 子句
5. **默认值处理**：
   - 数值类型默认值不带引号
   - 字符串类型默认值带引号
   - NULL 默认值使用 `DEFAULT NULL`

## 常见问题

### Q1: 如何处理索引差异？

本工具仅处理字段差异。如需同步索引，可使用以下查询：

```sql
SELECT
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME
FROM
    information_schema.STATISTICS
WHERE
    TABLE_SCHEMA = 'your_database'
    AND TABLE_NAME = 'your_reference_table';
```

### Q2: 如何处理字段类型不一致？

本工具检查字段是否存在，不检查类型差异。如需检查类型差异，请修改比较条件。

### Q3: 执行 ALTER 失败怎么办？

常见原因：
- 表被锁定：等待或终止锁定的事务
- 磁盘空间不足：清理空间后重试
- 外键约束：临时禁用外键检查

```sql
SET FOREIGN_KEY_CHECKS = 0;
-- 执行 ALTER 语句
SET FOREIGN_KEY_CHECKS = 1;
```

## 版本信息

- 适用 MySQL 版本：5.7.x
- 创建日期：2025-11-26
- 维护者：Claude Code

## License

MIT License
